extends Node2D

@export var hbox_container: HBoxContainer  # Hand Container
@export var top_bar: HBoxContainer  # Conteneur HBox pour les labels
@onready var timer_label = $HBoxContainer/timer
@onready var score_label = $CanvasLayer/top_bar/nbheads
@onready var state_label = $State_label

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
@onready var right_player_contaienr = $RPlayer_container

# Listes de cartes
var all_cards = []  # Liste de toutes les cartes disponibles
var selected_cards = []  # Liste des cartes déjà utilisées
var username 

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
	HAND_RECEIVED
}
var game_state 
var room_id_global
var hand_received 

func _ready():
	_load_cards()
	username = get_node("/root/Global").player_name
	game_state = GameState.WAITING_FOR_LOBBY
	
	#setting up row panels
	hand_received = false
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
		"available-rooms":
			_handle_available_rooms(data)
		"private-room-created", "public-room-created":
			_handle_room_created(data)
		"public-room-joined", "private-room-joined":
			_handle_room_joined(data)
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
		"users-in-private-room", "users-in-public-room":
			setup_players(data)
		_:
			print("Unhandled event received: ", event, "data:", data)


func _handle_available_rooms(data):
	if game_state != GameState.WAITING_FOR_LOBBY:
		return 
	print("data received for available rooms:\n", data)
	##create a lobby just to test code 
	if game_state == GameState.WAITING_FOR_LOBBY:
		var lobby = {
			"username" : "tester",
			"isPrivate" : "PUBLIC",
			"lobbyName" : "BestLobby",
			"playerLimit" : 2,
			"numberOfCards": 10,
			"roundTimer": 45,
			"endByPoints": 66,
			"rounds": 2
		}
		game_state = GameState.LOBBY_CREATED	#update game state
		socket_io.emit("create-room", lobby)
		
	else:
		room_id_global = data[0][0]["id"]


func _handle_room_created(data):
	print("on room created ", data )
	
	room_id_global = data[0]
	print("global room id", room_id_global)
		
	var body = {
		"roomId" : room_id_global,
		"username" : username
	}
	game_state = GameState.ROOM_JOINED
	
	await get_tree().create_timer(10).timeout
	print("start game event")
	
	var start_data = {"roomId" : room_id_global}
	
	game_state = GameState.SETTING_UP_DECK
	socket_io.emit("start-game", data[0])
	#_start_turn()	

func _handle_room_joined(data):
	print("data for signal room joined ", data)
	

func _start_turn():
	hand_received = false
	if room_id_global != null:
		socket_io.emit("tour", {
			"roomId": room_id_global, 
			"username": username
		})


func _handle_timer(data):
	var seconds = data[0]
	timer_label.text = "%d s" % seconds


func _handle_update_scores(data):
	print("updata score data ", data)
	var score = 0
	var scores = data[0]
	for entry in scores:
		if entry["nom"] == username:
			score = entry["score"]
			print("player score in data ", score)
	
	score = JSON.stringify(score)
	score_label.text = score
	_start_turn()
	
	
func _handle_your_hand(data):
	if hand_received:
		return
	hand_received = true
	print("Data received on your-hand:", data)
	if game_state == GameState.SETTING_UP_DECK:
		deck_setup_animation()
	
	update_hand_ui(data)
	#game_state = GameState.GAME_STARTED


func _handle_table(data):
	print("Data received for table:", data)
	update_table_ui(data)
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

func update_hand_ui(hand_data):
	print("Update hand UI with:")
	for child in hbox_container.get_children():
		child.queue_free()
	
	if hand_data.size() > 0:
		var cards_list = hand_data[0]
		for card_id in cards_list:
			var card_info = _find_card_data(card_id)
			if !card_info:
				print("No card info found for id:", card_id)
				
			var path = card_info["path"]
			
			if card_id:
				var card_instance = card_ui_scene.instantiate()
				hbox_container.add_child(card_instance)
				if card_instance.has_method("set_card_data"):
					card_instance.set_card_data(path, card_id)
					card_instance.connect("card_selected", Callable(self, "_on_card_selected"))
					
					if game_state == GameState.SETTING_UP_DECK:
						card_instance.start_flip_timer(2.0)
	else:
		print("Unexpected hand_data format:", hand_data)


func _on_card_selected(card_number):
	var data = {
		"roomId" : room_id_global,
		"card" : card_number,
		"username" : "tester"
	} 
	print("emitting card selected event", data)
	socket_io.emit("play-card", data)
	
	
func update_table_ui(table_data):
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
						
						if game_state == GameState.SETTING_UP_DECK:
							card_instance.start_flip_timer(2.0)
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
		"username": username
	})


func _clear_row_selection_ui():
	for i in range(row_panels.size()):
		row_buttons[i].visible = false
		row_panels[i].add_theme_stylebox_override("panel", null)


func deck_setup_animation():
	show_label("Game Start")
	
	
func show_label(text: String) -> void:
	state_label.text = text
	state_label.visible = true
	await get_tree().create_timer(2.0).timeout
	
	hide_label()

func hide_label() -> void:
	state_label.visible = false


#display players on gameboard
func setup_players(player_data):
	var usernames = player_data[0]["usernames"]
	var other_players = []
	
	for username in usernames:
		if username != current_player_username:
			other_players.append(username)

	# Clear existing visuals
	for container in [left_player_container, right_player_container]:
		for child in container.get_children():
			child.queue_free()

	# Add others, alternating left/right
	for i in range(other_players.size()):
		var visual = create_player_visual(other_players[i])
		
		if i % 2 == 0:
			left_player_container.add_child(visual)
		else:
			right_player_container.add_child(visual)

	# Add current player at bottom of left
	var my_visual = create_player_visual(current_player_username, true)
	left_player_container.add_child(my_visual)


func create_player_visual(username: String, is_me := false) -> Node:
	var visual = player_visual_scene.instantiate()
	visual.get_node("UsernameLabel").text = username

	# If you want to give a special icon to yourself:
	if is_me:
		visual.get_node("Avatar").texture = preload("res://assets/my_avatar.png")
	else:
		# You can randomize or use a default icon for others
		visual.get_node("Avatar").texture = preload("res://assets/default_avatar.png")

	return visual
