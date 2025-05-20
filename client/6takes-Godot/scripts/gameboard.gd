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
	$deckContainer/rowsContainer/row1_panel/selectRowButton,
	$deckContainer/rowsContainer/row2_panel/selectRowButton,
	$deckContainer/rowsContainer/row3_panel/selectRowButton,
	$deckContainer/rowsContainer/row4_panel/selectRowButton
]

@onready var row_collision_areas = [
	$deckContainer/rowsContainer/row1_panel/Area2D,
	$deckContainer/rowsContainer/row2_panel/Area2D,
	$deckContainer/rowsContainer/row3_panel/Area2D,
	$deckContainer/rowsContainer/row4_panel/Area2D
]

#players ui
@onready var player_visual_scene = preload("res://scenes/PlayerVisual.tscn")
@onready var left_player_container = $LPlayer_container
@onready var right_player_container = $RPlayer_container
@onready var rows_manager := $deckContainer/rowsContainer
@onready var mssg_panel    = $mssgControl

# Listes de cartes
var all_cards = []  # Liste de toutes les cartes disponibles
var selected_cards = []  # Liste des cartes déjà utilisées
var player_username 
var last_table_state := [[], [], [], []]  # table state of previous round
# Chargement des scènes
@onready var pause_screen_scene = preload("res://scenes/screen_pause.tscn")
@onready var card_ui_scene = preload("res://scenes/card_ui.tscn")  

# Instance de l'écran de pause
var pause_instance = null

var setting_up_deck
var room_id_global
var players_displayed
var cards_animated
var me
var is_host 
var hand_received
var table_received
var turn_emitted 
var turns
var current_turn = 1
var game_ended 
var showing_score
var cards_sorted
var can_select_card
var scores_handled
var played_card_instances := {}  # key: card_id, value: card_instance

# Gestion de la désactivation de la main
@onready var hand_controller = preload("res://scripts/HandController.gd").new()

func _ready():
	_load_cards()
	
	setting_up_deck = false
	player_username = Global.player_name
	room_id_global = GameState.id_lobby
	me = GameState.player_info
	turns = GameState.rounds
	turn_label.text = "Turn " + str(current_turn) + " / " + str(turns)
	
	#setting up row panels
	players_displayed = false
	cards_animated = false 
	hand_received = false
	table_received = false
	turn_emitted = false
	game_ended = false
	showing_score = false
	cards_sorted = false
	

	rows_manager.connect("row_selected", Callable(self, "_on_row_confirmed"))
	#connect to socket
	SocketManager.connect("event_received", Callable(self, "_on_socket_event"))
	# Ecoute la déconnexion du websocket
	SocketManager.connect("disconnected", Callable(self, "_on_socket_disconnected"))
	
	#start game
	is_host = GameState.is_host
	if is_host:
		SocketManager.emit("start-game", room_id_global)
	start_game()
	hand_controller.set_hand_container(hbox_container)
	add_child(hand_controller)


#event listener
func _on_socket_event(event: String, data: Variant, ns: String) -> void:
	match event:
		"your-hand":
			if !hand_received:
				hand_received = true
				_handle_your_hand(data)
				
		"initial-table", "update-table":
			if !table_received:
				table_received = true
				update_table_ui(data, setting_up_deck)
				
		"update-scores":
			if !scores_handled:
				_handle_update_scores(data)
				
		"choix-rangee":
			on_player_selects_row()
			
		"temps-room":
			if !game_ended:
				_handle_timer(data)
			
		"attente-choix-rangee":
			_await_row_selection(data)
			
		"users-in-your-private-room", "users-in-your-public-room":
			setup_players(data)
			
		"fin-tour":
			print("fin tour")
			current_turn +=1
			turn_label.text = "Turn " + str(current_turn) + " / " + str(turns)
		
		"ramassage-rang":
			takes_row(data)

		"cartes-jouees":
			_cards_from_players(data)

		"end-game":
			await get_tree().create_timer(3).timeout
			_handle_end_game(data)
			
		"manche-suivante":
			_handle_next_round(data)
			
		"score-manche":
			show_turn_score(data)
			
		"remove-room":
			_handle_remove_room()
			
		"sorted-cards":
			if !cards_sorted:
				cards_sorted = true
				_handle_your_hand(data, true)
		
		"user-left":
			_handle_user_left(data)
		
		"bot-replaced":
			_switch_player_name(data)

		_:
			print("Unhandled event received: ", event, "data: ", data)
	
	if not turn_emitted and not game_ended:
		turn_emitted = true
		
		scores_handled = false
		if !game_ended:
			_start_turn()


func _handle_remove_room():
	mssg_panel.get_node("mssg").text = "\n Host Left the Game "
	mssg_panel.visible = true
	#game_ended = true
	await get_tree().create_timer(6).timeout
	get_tree().change_scene_to_file("res://scenes/multiplayer_menu.tscn")


func _handle_user_left(data):
	#if data[0].size == 1:
	print("user left , ", data)
	GameState.players_count -= 1
	
	mssg_panel.get_node("mssg").text = "\n Opponent left the game"
	mssg_panel.visible = true
	
	if GameState.is_public:
		SocketManager.emit("users-in-public-room", room_id_global)
	else:
		SocketManager.emit("users-in-private-room", room_id_global)
		
	if GameState.players_count == 1:
		game_ended = true


func _handle_next_round(data):
	await get_tree().create_timer(0.1).timeout
	show_label("Next Round")
	
	cards_sorted = false
	get_node("sortCards").visible = true
	get_node("sortCards").disabled = false
	
	current_turn = str(data[0] +1)
	turn_label.text = "Turn " + current_turn +" / " + str(turns)
	
	
func show_turn_score(data):
	print("turn score received , ", data)
	GameState.rankings = data[0].get("classement")
	showing_score = true
	var score_instance = load("res://scenes/scoreBoard.tscn").instantiate()
	score_instance.get_node("leaveButton").disabled = true
	score_instance.gameboard = self
	await get_tree().create_timer(1.5).timeout

	var overlay_layer = CanvasLayer.new()
	overlay_layer.add_child(score_instance)
	add_child(overlay_layer)
	
	get_tree().current_scene.add_child(score_instance)

	#queue_free()
	
	
func takes_row(data):
	print("takes row event ", data)
	var user_takes = data[0].username
	
	print("player takes ", user_takes)
	if user_takes == player_username:
		show_label("You Take 6 !")
	else:
		show_label(user_takes + " Takes 6!")

func start_game():

	show_label("Game Starting")
	SocketManager.emit("users-in-public-room", {
		"roomId" : room_id_global
	})
	
	SocketManager.emit("users-in-public-room", room_id_global)
	

func _start_turn():
	#cards_sorted = false
	await get_tree().create_timer(0.1).timeout
	can_select_card = true
	rows_manager.reset_selection()
	if room_id_global != null:
		print("emit tour")
		SocketManager.emit("tour", {
			"roomId": room_id_global, 
			"username": player_username
		})
	
	if !cards_sorted:
		get_node("sortCards").disabled = false


func _handle_timer(data):
	var seconds = data[0]
	timer_label.text = "%d s" % seconds


func _handle_update_scores(data):
	scores_handled = true
	turn_emitted = false
	hand_received = false
	table_received = false

	var score = 0
	var scores = data[0]
	for entry in scores:
		if entry["nom"] == player_username:
			score = entry["score"]
			print("player score in data ", score)
	
	score = JSON.stringify(score)
	score_label.text = score


func _await_row_selection(data):
	can_select_card = false
	var player = data[0]["username"]
	show_label(player + " Is Choosing a Row")


# --- Player Actions Signals---
func on_player_selects_row():
	show_label("Choose a row To take")
	print("calling row selection in row manager")
	rows_manager.show_row_selection_ui()
	
# Called when player confirms a row
func _on_row_confirmed(row_index):
	print("Player selected row:", row_index)
	SocketManager.emit("choisir-rangee", {
	"roomId": room_id_global,
	"indexRangee": row_index,
	"username": player_username
	})

func _cards_from_players(data) -> void:
	played_card_instances.clear()
	_clear_card_containers()

	if data.size() == 0:
		push_warning("Received empty data list")
		return

	var players = data[0]
	
	if players == null:
		push_warning("Received empty data list")
		return
		
	for player_data in players:
		var username = player_data.username
		var carte = player_data.carte
		var numero = carte.numero

		var card_info = _find_card_data(numero)
		var target_container = null
		if card_info:
			var card_instance = card_ui_scene.instantiate()
			if left_player_container.has_node(username):
				target_container = left_player_container.get_node(username)
			elif right_player_container.has_node(username):
				target_container = right_player_container.get_node(username)
			else:
				push_warning("No container found for user: %s" % username)
				continue

			target_container.add_child(card_instance)
			card_instance.set_card_data(card_info["path"], numero)
			card_instance.texture_rect.visible = true
			#card_instance.start_flip_timer(2.0)

			played_card_instances[numero] = card_instance


	
func _on_open_pause_button_pressed() -> void:
	
	if pause_instance == null:
		pause_instance = pause_screen_scene.instantiate()

		var overlay_layer = CanvasLayer.new()
		overlay_layer.layer = 10  # Higher layer to make sure it is on top of the cards
		overlay_layer.add_child(pause_instance)
		add_child(overlay_layer)

		await get_tree().process_frame
		#pause_instance.position = pause_instance.size #no longer needed because of canvas layer

	pause_instance.move_to_front()
	pause_instance.visible = true

func _load_cards():
	for i in range(1, 105):  # pour les cartes de 1 à 104
		var path = "res://assets/images/cartes/%d.png" % i
		all_cards.append({"id": i, "path": path})


#utility function 
func _find_card_data(card_id: int) -> Dictionary:
	for card in all_cards:
		if card["id"] == card_id:
			return card
	return {}  

func _switch_player_name(data):
	print(data)
	if data.size() == 0:
		push_warning("Received empty data list")
		return

	var switched_names = data[0]
	var player_left_name = switched_names.username
	var replaced_bot = switched_names.botName

	# Check both containers
	for container in [left_player_container, right_player_container]:
		for child in container.get_children():
			# HBoxContainer is named after the username
			if child.name == player_left_name:
				child.name = replaced_bot
				var player_visual = child.get_node_or_null("PlayerVisual")
				if player_visual:
					# Assuming the PlayerVisual has a label or method to update the name
					player_visual.update_username(replaced_bot)
				else:
					push_warning("No PlayerVisual found in container named %s" % player_left_name)
				return  # Done after replacing
					
	push_warning("Username '%s' not found in player containers." % player_left_name)

# --- UI Update Functions ---

func _handle_your_hand(hand_data, from_sort := false):
	print("Update hand UI ", hand_data)
	for child in hbox_container.get_children():
		child.queue_free()

	var was_first_animation = !cards_animated
	var was_hand_enabled = hand_controller.is_enabled()

	if !cards_animated and !from_sort:
		can_select_card = false
		get_node("sortCards").disabled = true

	for card_id in hand_data[0]:
		var card_info = _find_card_data(card_id)
		var path = card_info["path"]
		
		if card_id:
			var card = card_ui_scene.instantiate()
			hbox_container.add_child(card)
			card.gameboard = self
			card.connect("card_selected", Callable(self, "_on_card_selected"))
			
			card.set_card_data(path, card_id)
			var this_card = card
			
			if !cards_animated:
				card.modulate.a = 0
				card.scale = Vector2(0.5, 0.5)
				var tw = create_tween()
				tw.tween_property(card, "modulate:a", 1.0, 0.25)
				tw.tween_property(card, "scale", Vector2(1,1), 0.25)
				await tw.finished
				this_card = card
				await get_tree().create_timer(0.1).timeout
				if is_instance_valid(this_card) and this_card.is_inside_tree():
					this_card.flip_card()
					await get_tree().create_timer(0.05).timeout
			else:
				card.toggle_texture_visibility(true)
	
	cards_animated = true
	can_select_card = true
	if !cards_sorted:
		get_node("sortCards").disabled = false
	# Désactiver la main tant que l'animation n'est pas finie
	if !from_sort:
		hand_controller.set_hand_enabled(false)
	# Réactiver la main à la fin de l'animation (y compris pour le tout premier tour)
	if was_first_animation and !from_sort:
		await get_tree().create_timer(0.1).timeout
		hand_controller.set_hand_enabled(true)
	elif !cards_animated and !from_sort:
		await get_tree().create_timer(0.1).timeout
		hand_controller.set_hand_enabled(true)
	# Si c'est un tri, on restaure l'état précédent de la main
	if from_sort:
		hand_controller.set_hand_enabled(was_hand_enabled)


func _on_card_selected(card_number):
	var data = {
		"roomId" : room_id_global,
		"card" : card_number,
		"username" : player_username
	} 
	print("emitting card selected event", data)
	SocketManager.emit("play-card", data)
	can_select_card = false
	get_node("sortCards").disabled = true
	

func update_table_ui(table_data, settingup_deck):
	can_select_card = false
	
	var row_containers = [row1, row2, row3, row4]
	var new_cards_global: Array = []

	if table_data.size() > 0:
		var rows = table_data[0]

		for i in range(4):
			var row_data = rows[i]
			var container = row_containers[i]
			var previous_row = last_table_state[i]
			var removed_card_ids = []

			for old_card_id in previous_row:
				if not row_data.has(old_card_id):
					removed_card_ids.append(old_card_id)

			for child in container.get_children():
				if child.has_method("get_card_id") and removed_card_ids.has(child.get_card_id()):
					var tw2 = create_tween()
					tw2.parallel()
					tw2.tween_property(child, "modulate:a", 0.0, 0.2)
					tw2.tween_property(child, "scale", Vector2(0.5, 0.5), 0.2)
					tw2.chain()
					await tw2.finished
					if is_instance_valid(child):
						child.queue_free()

			clear_children_except_buttons(container)

			var cards_to_add := []

			for card_id in row_data:
				var is_new = not previous_row.has(card_id)
				var card_info = _find_card_data(card_id)
				if not card_info:
					continue

				cards_to_add.append({
					"card_id": card_id,
					"card_info": card_info,
					"is_new": is_new
				})

			# Sort cards before adding to ensure correct order
			cards_to_add.sort_custom(func(a, b): return a["card_id"] < b["card_id"])

			for card_data in cards_to_add:
				var card_id = card_data["card_id"]
				var card_info = card_data["card_info"]
				var is_new = card_data["is_new"]

				if is_new and played_card_instances.has(card_id):
					var player_card = played_card_instances[card_id]
					var global_start = player_card.get_global_position()
					var global_target = container.get_global_position()

					player_card.get_parent().remove_child(player_card)
					get_tree().root.add_child(player_card)
					player_card.global_position = global_start

					var tw = create_tween()
					tw.tween_property(player_card, "global_position", global_target, 1.5)
					SoundManager.play_move_card()
					await tw.finished

					get_tree().root.remove_child(player_card)
					container.add_child(player_card)
					player_card.global_position = Vector2.ZERO
					player_card.position = Vector2.ZERO
					player_card.flip_card()

					played_card_instances.erase(card_id)

				elif is_new:
					var card_instance = card_ui_scene.instantiate()
					card_instance.mouse_filter = Control.MOUSE_FILTER_IGNORE
					container.add_child(card_instance)
					card_instance.set_card_data(card_info["path"], card_id)
					card_instance.modulate.a = 0
					card_instance.scale = Vector2(0.5, 0.5)

					new_cards_global.append({
						"card_id": card_id,
						"card_instance": card_instance
					})
				else:
					var card_instance = card_ui_scene.instantiate()
					card_instance.mouse_filter = Control.MOUSE_FILTER_IGNORE
					container.add_child(card_instance)
					card_instance.set_card_data(card_info["path"], card_id)
					card_instance.texture_rect.visible = true

			last_table_state[i] = row_data.duplicate()
			
	can_select_card = false
	if new_cards_global.size() > 0:
		new_cards_global.sort_custom(func(a, b): return a["card_id"] < b["card_id"])
		for card_dict in new_cards_global:
			var card_instance = card_dict["card_instance"]
			card_instance.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var tw = create_tween()
			tw.tween_property(card_instance, "modulate:a", 1.0, 0.25)
			tw.tween_property(card_instance, "scale", Vector2(1, 1), 0.25)
			await tw.finished
			if is_instance_valid(card_instance):
				card_instance.flip_card()
		# Clean up leftover player cards (not placed on table)
	can_select_card = false
	if played_card_instances.size() > 0:
		for leftover_card_id in played_card_instances.keys():
			var leftover_card = played_card_instances[leftover_card_id]
			if is_instance_valid(leftover_card):
				var tw = create_tween()	
				tw.parallel()
				tw.tween_property(leftover_card, "modulate:a", 0.0, 0.2)
				tw.tween_property(leftover_card, "scale", Vector2(0.5, 0.5), 0.2)
				tw.chain()
				await tw.finished
				if is_instance_valid(leftover_card):
					leftover_card.queue_free()

		played_card_instances.clear()
	
	if cards_animated:
		hand_controller.set_hand_enabled(true)
		can_select_card = true
	
func _on_select_row_button_pressed(row_index):
	print("choose row event selected :", row_index)
	_clear_row_selection_ui()
	
	SocketManager.emit("choisir-rangee", {
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
	await get_tree().create_timer(3).timeout
	
	hide_label()

func hide_label() -> void:
	state_label.visible = false


#display players on gameboard
func setup_players(player_data):
	if players_displayed:
		return
	
	# Clear existing visuals
	#print("player data received ", player_data)
	for container in [left_player_container, right_player_container]:
		for child in container.get_children():
			child.queue_free()
	
	var outer = player_data[0]
	var payload : Dictionary

	# Shape A: { "users": { count, users } }
	if outer.has("users") and typeof(outer["users"]) == TYPE_DICTIONARY:
		payload = outer["users"]
	# Shape B: { "count": X, "users": [ … ] }
	elif outer.has("count") and outer.has("users") and typeof(outer["users"]) == TYPE_ARRAY:
		payload = outer
	else:
		push_error("Unrecognized users-in room payload: %s" % outer)
		return

	var players_count = int(payload.get("count", 0))
	var players       = payload.get("users", [])
	
	var users = player_data[0]["users"]
	var user_icon
	var others := []
	var current_player
	
	for user_dict in players:
		var name = user_dict.get("username", "")
		if name == player_username:
			current_player = user_dict
		else:
			others.append(user_dict)
	
	for i in range(others.size()):
		var user = others[i]
		
		if user.username.begins_with("Bot"):
			user_icon = 10
		else:
			user_icon = user.icon if user.has("icon") and user.icon != null else 0

		var player_visual_instance = player_visual_scene.instantiate()
		var vis = player_visual_instance.create_player_visual(user.username, user_icon, false)
		var slot = HBoxContainer.new()
		vis.name = "PlayerVisual"
		slot.name = user.username
		slot.add_child(vis)
		
		if i % 2 == 0:
			left_player_container.add_child(slot)
		else:
			slot.layout_direction = BoxContainer.LAYOUT_DIRECTION_RTL
			right_player_container.add_child(slot)


	if current_player:
		var player_visual_instance = player_visual_scene.instantiate()
		var my_icon = current_player.get("icon", null)
		my_icon = my_icon if my_icon != null else 0
		var me_vis = player_visual_instance.create_player_visual(current_player.get("username",""), my_icon, true)
		var slot = HBoxContainer.new()
		me_vis.name = "PlayerVisual"
		slot.name = current_player.get("username","")
		slot.layout_direction = BoxContainer.LAYOUT_DIRECTION_RTL
		slot.add_child(me_vis)
		right_player_container.add_child(slot)
		
	else:
		print("Couldn’t find current_player in %s" , players)
		return
			
	players_displayed = true


func _handle_end_game(data):
	#clear last card
	await get_tree().create_timer(1).timeout
	for child in hbox_container.get_children():
		child.queue_free()
		
	game_ended = true
	GameState.first_game = false
	GameState.rankings = data[0].get("classement")
	print("Game ended event ", data[0].get("classement"))
	show_label("Game Ended !")
	
	var score_instance = load("res://scenes/scoreBoard.tscn").instantiate()
	score_instance.get_node("closeButton").disabled = true
	score_instance.gameboard = self
	await get_tree().create_timer(3).timeout
	#TRANSITION FIX HERE 
	#var transition_scene = load("res://scenes/Transition.tscn")
	#var transition_instance = transition_scene.instantiate()
	#get_tree().current_scene.add_child(transition_instance)
	var overlay_layer = CanvasLayer.new()
	overlay_layer.add_child(score_instance)
	add_child(overlay_layer)
	
	get_tree().current_scene.add_child(score_instance)

func clear_children_except_buttons(node: Node) -> void:
	for child in node.get_children():
		if child is Button:
			continue
		child.queue_free()

func _clear_card_containers():
	for container in [left_player_container, right_player_container]:
		for player_container in container.get_children():
			if player_container is HBoxContainer:
				for child in player_container.get_children():
				# Keep the base visual, assumed to be named "PlayerVisual"
					if child.name != "PlayerVisual":
						child.queue_free()

func _on_sort_cards_pressed() -> void:
	SocketManager.emit("sort-cards", {
		"roomId" : room_id_global,
		"username" : player_username
	})
	get_node("sortCards").visible = false
	
func _on_close_button_pressed() -> void:
	if game_ended:
		if !is_host:
			get_tree().change_scene_to_file("res://scenes/multiplayer_menu.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/mp_lobby_scene.tscn")
	else:
		mssg_panel.visible = false

# Gestion de la déconnexion websocket
func _on_socket_disconnected():
	if not game_ended:
		var popup_scene = preload("res://scenes/popUp.tscn")
		var popup_instance = popup_scene.instantiate()
		var label = popup_instance.get_node("message")
		if label:
			label.text = "Server connection error"
			get_tree().current_scene.add_child(popup_instance)
			popup_instance.make_visible()
		await get_tree().create_timer(5.0).timeout
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
