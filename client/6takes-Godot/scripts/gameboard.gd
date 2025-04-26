extends Node2D

@export var hbox_container: HBoxContainer  # Hand Container
@export var top_bar: HBoxContainer  # Conteneur HBox pour les labels
@onready var timer_label = $HBoxContainer/timer
@onready var score_label = $CanvasLayer/top_bar/nbheads
@onready var state_label = $State_label
@onready var turn_label = $HBoxContainer/turnLabel

#deck ui 
@onready var row1 = $deckContainer/rowsContainer/row1_panel/row1
@onready var row2 = $deckContainer/rowsContainer/row2_panel/row2
@onready var row3 = $deckContainer/rowsContainer/row3_panel/row3
@onready var row4 = $deckContainer/rowsContainer/row4_panel/row4


@onready var row_panels = [
	$deckContainer/rowsContainer/row1_panel,
	$deckContainer/rowsContainer/row2_panel,
	$deckContainer/rowsContainer/row3_panel,
	$deckContainer/rowsContainer/row4_panel
]

@onready var row_buttons = [
	$deckContainer/rowsContainer/row1_panel/row1/selectRowButton,
	$deckContainer/rowsContainer/row2_panel/row2/selectRowButton,
	$deckContainer/rowsContainer/row3_panel/row3/selectRowButton,
	$deckContainer/rowsContainer/row4_panel/row4/selectRowButton
]

#players ui
@onready var player_visual_scene = preload("res://scenes/PlayerVisual.tscn")
@onready var left_player_container = $LPlayer_container
@onready var right_player_container = $RPlayer_container

#players icons
const ICON_PATH = "res://assets/images/icons/"
const ICON_FILES = [
	"dark_grey.png", "blue.png", "brown.png", "green.png", 
	"orange.png", "pink.png", "purple.png", "red.png",
	"reversed.png", "cyan.png"
]

# Listes de cartes
var all_cards = []  # Liste de toutes les cartes disponibles
var selected_cards = []  # Liste des cartes déjà utilisées
var player_username 

# Chargement des scènes
@onready var pause_screen_scene = preload("res://scenes/screen_pause.tscn")
@onready var card_ui_scene = preload("res://scenes/card_ui.tscn")  

# Instance de l'écran de pause
var pause_instance = null

@onready var socket_io = $SocketIO
var BASE_URL 

enum GameState {
	WAITING_FOR_LOBBY,
	LOBBY_CREATED,
	ROOM_JOINED,
	SETTING_UP_DECK,
	GAME_STARTED,
	HAND_RECEIVED,
	PLAYERS_HANDLED
}

var game_state 
var room_id_global
var players_displayed
var cards_animated

func _ready():
	_load_cards()
	
	game_state = GameState.WAITING_FOR_LOBBY
	player_username = get_node("/root/Global").player_name
	room_id_global = get_node("/root/GameState").id_lobby
	#setting up row panels
	players_displayed = false
	cards_animated = false 
	
	highlight_row(false)
	for i in range(row_buttons.size()):
		var btn = row_buttons[i]
		btn.visible = false
		btn.pressed.connect(_on_select_row_button_pressed.bind(i)) 
	
	#connect to socket
	BASE_URL = get_node("/root/Global").get_base_url()
	BASE_URL = "http://" + BASE_URL
	socket_io.base_url = BASE_URL
	socket_io.connect_socket()
	socket_io.event_received.connect(_on_socket_event_received)


#event listener
func _on_socket_event_received(event: String, data: Variant, ns: String) -> void:
	match event:
		"your-hand":
			_handle_your_hand(data)
		"initial-table", "update-table":
			_handle_table(data)
		"update-scores":
			_handle_update_scores(data)
		"choix-rangee":
			on_player_selects_row(data)
		"temps-room":
			_handle_timer(data)
		"attente-choix-rangee":
			_await_row_selection(data)
		"users-in-your-private-room", "users-in-your-public-room":
			setup_players(data)
		"ramassage_rang":
			_handle_takes(data)
		"fin-tour":
			pass
			#_handle_your_hand(data)
		"ramassage-rang":
			takes_row(data)
		"manche_suivante":
			_handle_next_round(data)
		_:
			print("Unhandled event received: ", event, "data: ", data)


func _handle_next_round(data):
	show_label("Next Round")
	turn_label.text = "Turn " + data[0] +"/" #add total turns
	
	
func takes_row(data):
	var user_takes = data[0].username
	print("player takes ", user_takes)
	if user_takes == player_username:
		show_label("You Take 6 !")
	else:
		show_label(user_takes + " Takes 6!")


func start_game(data):
	var start_data = {"roomId" : room_id_global}
	
	game_state = GameState.SETTING_UP_DECK
	socket_io.emit("start-game", data[0])
	
	show_label("Game Starting")
	socket_io.emit("users-in-public-room", {
		"roomId" : room_id_global
	})
	
	await get_tree().create_timer(1).timeout
	_start_turn()	

func _handle_room_joined(data):
	print("data for event room joined ", data)
	

func _start_turn():
	if room_id_global != null:
		print("emit tour")
		socket_io.emit("tour", {
			"roomId": room_id_global, 
			"username": player_username
		})


func _handle_timer(data):
	var seconds = data[0]
	timer_label.text = "%d s" % seconds


func _handle_update_scores(data):
	print("updata score data ", data)
	var score = 0
	var scores = data[0]
	for entry in scores:
		if entry["nom"] == player_username:
			score = entry["score"]
			print("player score in data ", score)
	
	score = JSON.stringify(score)
	score_label.text = score
	_start_turn()


func _handle_table(data):
	print("Data received for table:", data)
	var animate = (game_state == GameState.SETTING_UP_DECK)
	update_table_ui(data, animate)
	
	game_state = GameState.GAME_STARTED

func _await_row_selection(data):
	var player = data[0]["username"]
	show_label(player + " Is Choosing a Row")

func _on_invalid_card(message):
	pass


# --- Player Actions Signals---
func on_player_selects_row(data):
	print("data received on row choice :", data)
	show_label("Choose a row To take")
	
	highlight_row(true)
	selection_buttons(true)


func _on_open_pause_button_pressed() -> void:
	if pause_instance == null:
		pause_instance = pause_screen_scene.instantiate()
		add_child(pause_instance)

		# Centrer l'écran de pause
		await get_tree().process_frame  # Assurer la mise à jour de la taille
		pause_instance.position = get_viewport_rect().size / 2 - pause_instance.size / 2
		
	pause_instance.move_to_front()  # S'assurer que l'écran de pause est tout en haut
	pause_instance.visible = true  # Afficher la pause



func _load_cards():
	var dir_path = "res://assets/images/cartes/"
	var dir = DirAccess.open(dir_path)
	
	if dir == null:
		print(" Erreur : Impossible d'ouvrir le dossier des cartes. Vérifiez le chemin !")
		return

	dir.list_dir_begin()

	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".png") and not file_name.ends_with(".import"):  
			var card_id = int(file_name.get_basename())  # L'ID est le nom du fichier sans l'extension
			var card_path = dir_path + file_name
			all_cards.append({"id": card_id, "path": card_path})
		file_name = dir.get_next()
	
	dir.list_dir_end()


#utility function 
func _find_card_data(card_id: int) -> Dictionary:
	for card in all_cards:
		if card["id"] == card_id:
			return card
	return {}  


# --- UI Update Functions ---

func _handle_your_hand(hand_data):
	print("Update hand UI ", hand_data)
	for child in hbox_container.get_children():
		child.queue_free()
	
	for card_id in hand_data[0]:
		var card_info = _find_card_data(card_id)
		var path = card_info["path"]
		
		if card_id:
			var card = card_ui_scene.instantiate()
			#card.modulate.a = 0
			#card.scale = Vector2(0.5, 0.5)
			hbox_container.add_child(card)
			card.set_card_data(path, card_id)
		
			if !cards_animated:
				card.modulate.a = 0
				card.scale = Vector2(0.5, 0.5)
			
				var tw = create_tween()
				tw.tween_property(card, "modulate:a", 1.0, 0.25)
				tw.tween_property(card, "scale", Vector2(1,1), 0.25)
				await tw.finished

				#await card.start_flip_timer(0.1)
				var t = get_tree().create_timer(0.1)
				await t.timeout
				
				card.flip_card()
				await get_tree().create_timer(0.05).timeout

			else:
				#card.modulate.a = 1.0
				#card.scale = Vector2(1,1)
				card.toggle_texture_visibility(true)

			card.connect("card_selected", Callable(self, "_on_card_selected"))
	
	cards_animated = true

func _on_card_selected(card_number):
	var data = {
		"roomId" : room_id_global,
		"card" : card_number,
		"username" : "tester"
	} 
	print("emitting card selected event", data)
	socket_io.emit("play-card", data)
	
	
func update_table_ui(table_data, animation):
	for row in [row1, row2, row3, row4]:
		for child in row.get_children():
			if child is not Button:
				child.queue_free()
		
	if table_data.size() > 0 :
		var rows = table_data[0]
		var row_containers = [row1, row2, row3, row4]
		
		for i in range(4):
			var row_data = rows[i]
			var container = row_containers[i]

			for card_id in row_data:				
				var card_info = _find_card_data(card_id)
				if card_info:
					var card_instance = card_ui_scene.instantiate()
					container.add_child(card_instance)
					
					if card_instance.has_method("set_card_data"):
						card_instance.set_card_data(card_info["path"], card_id)
						
						if animation:
							card_instance.start_flip_timer(2.0)
						else:
							card_instance.texture_rect.visible = true
				else:
					print("No card info found for id:", card_id)


func highlight_row(boolean): #, is_selected: bool) -> void:
	var style = StyleBoxFlat.new()
	style.set_border_width_all(4)
	style.bg_color = Color.TRANSPARENT
	
	if boolean:
		style.border_color = Color.BLUE
	else:
		style.border_color = Color.TRANSPARENT
	
	for i in range(row_panels.size()):
		var panel = row_panels[i]
		var btn   = row_buttons[i]
		panel.add_theme_stylebox_override("panel", style)
	selection_buttons(false)
	

func selection_buttons(visibility):
	for i in range(row_buttons.size()):
		var btn = row_buttons[i]
		btn.visible = visibility
	
	
func _on_select_row_button_pressed(row_index):
	print("choose row event selected :", row_index)
	_clear_row_selection_ui()
	
	socket_io.emit("choisir-rangee", {
		"roomId": room_id_global,
		"indexRangee": row_index,
		"username": player_username
	})


func _clear_row_selection_ui():
	for i in range(row_panels.size()):
		row_buttons[i].visible = false
		row_panels[i].add_theme_stylebox_override("panel", null)

	
func show_label(text: String) -> void:
	state_label.text = text
	state_label.visible = true
	await get_tree().create_timer(2.5).timeout
	
	hide_label()

func hide_label() -> void:
	state_label.visible = false


#display players on gameboard
func setup_players(player_data):
	if players_displayed:
		return
	
	# Clear existing visuals
	print("player data received ", player_data)
	for container in [left_player_container, right_player_container]:
		for child in container.get_children():
			child.queue_free()
	
	var players_count = player_data[0]["count"]
	print("players count ", players_count)
	
	var users = player_data[0]["users"]
	var user_icon
	var others := []
	var current_player
	
	for user_dict in users:
		if user_dict.username == player_username:
			current_player = user_dict
		others.append(user_dict)
	
	for i in range(others.size()):
		var user = others[i]
		
		if user.icon:
			user_icon = user.icon
		else:
			user_icon = 0
			
		var vis = create_player_visual(user.username, user_icon, false)
		if i % 2 == 0:
			right_player_container.add_child(vis)
		else:
			left_player_container.add_child(vis)

	
	#for user_dict in users:
		#if user_dict.username == player_username:
	var me_vis = create_player_visual(current_player.username, 0, true)
	right_player_container.add_child(me_vis)
			#break
			
	players_displayed = true
	game_state = GameState.GAME_STARTED


func create_player_visual(uname: String, icon_id: int, is_me := false) -> Control:
	var visual: Control = player_visual_scene.instantiate()

	visual.get_node("PlayerName").text = uname
	var icon_path = ICON_PATH + ICON_FILES[clamp(icon_id, 0, ICON_FILES.size() - 1)]
	visual.get_node("Icon").texture = load(icon_path)

	if is_me:
		visual.add_theme_color_override("font_color", Color(1, 1, 0))  # e.g. yellow
		# Or: visual.modulate = Color(1, 1, 1, 1) to brighten, etc.
	return visual


func _handle_takes(data):
	var player_takes = data[0]["username"]
	if player_takes == player_username:
		show_label("You Take 6!")
	else:
		show_label(player_takes + " Takes 6!")
