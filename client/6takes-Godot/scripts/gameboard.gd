extends Node2D

@export var vbox_container: VBoxContainer  # Rows cotainer
@export var hbox_container: HBoxContainer  # Hand Container
@export var top_bar: HBoxContainer  # Conteneur HBox pour les labels

# Listes de cartes
var all_cards = []  # Liste de toutes les cartes disponibles
var selected_cards = []  # Liste des cartes déjà utilisées

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
	GAME_STARTED,
	HAND_RECEIVED
}
var game_state = GameState.WAITING_FOR_LOBBY
var room_id_global

func _ready():
	_load_cards()
	
	#connect to socket
	BASE_URL = get_node("/root/Global").get_base_url()
	BASE_URL = "http://" + BASE_URL
	socket_io.base_url = BASE_URL
	socket_io.connect_socket()
	socket_io.event_received.connect(_on_socket_event_received)
	
	#_assign_vbox_cards()  # Distribuer les 4 cartes de la rangée
	#_assign_hbox_cards() 


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
		"initial-table":
			_handle_table(data)
		_:
			print("Unhandled event received:", event, "data:", data)


func _handle_available_rooms(data):
	print("data received for available rooms", data)
	#create a lobby just to test code 
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
		
	var body = {
		"roomId" : room_id_global,
		"username" : "client"
	}
	game_state = GameState.ROOM_JOINED
	socket_io.emit("join-room", body)
	

func _handle_room_joined(data):
	print("data for signal room joined ", data)
	if game_state != GameState.GAME_STARTED:
		game_state = GameState.GAME_STARTED		
		socket_io.emit("start-game", room_id_global)
	

func _handle_your_hand(data):
	if game_state == GameState.HAND_RECEIVED:
		print("Your hand already processed; ignoring duplicate event.")
		return 
	game_state = GameState.HAND_RECEIVED
	print("Data received on your-hand:", data)
	update_hand_ui(data)
	

func _handle_table(data):
	print("Data received for table:", data)
	update_table_ui(data)


# Example of handling an invalid card event
func _on_invalid_card(message):
	pass

# --- Player Actions Signals---


func on_player_selects_card(card_value):
	pass
	#var payload = {
		#"roomId": room_id,
		#"card": card_value,
		#"username": username
	#}
	#socket_io.emit("play-card", payload)
	#print("Sent play-card event with:", payload)


func on_player_selects_row(row_index):
	pass
	#var payload = {
		#"roomId": room_id,
		#"indexRangee": row_index,
		#"username": username
	#}
	#socket_io.emit("choisir-rangee", payload)
	#print("Sent choisir-rangee event with:", payload)

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
	print("Update hand UI with:", hand_data)
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
					card_instance.set_card_data(path)
				else:
					print("Card instance does not have method 'set_card_data'")
	else:
		print("Unexpected hand_data format:", hand_data)


func update_table_ui(table_data):
	for child in vbox_container.get_children():
		child.queue_free()
		
	if table_data.size() > 0 :
		var cards_list = table_data[0]
		for card_id in cards_list:
			var card_info = _find_card_data(card_id[0])
			if card_info:
				var card_instance = card_ui_scene.instantiate()
				vbox_container.add_child(card_instance)
				if card_instance.has_method("set_card_data"):
					card_instance.set_card_data(card_info["path"])
			else:
				print("No card info found for id:", card_id)
	else:
		print("Unexpected table_data format:", table_data)


#func _assign_vbox_cards(cards):
	#if all_cards.size() < 4:
		#print(" Erreur : Pas assez de cartes pour la rangée !")
		#return
#
	## Nettoyer les anciennes cartes dans vbox_container avant d'ajouter les nouvelles
	#for child in vbox_container.get_children():
		#child.queue_free()
#
	#for card in range(cards):
		#var card_instance = card_ui_scene.instantiate()
		#vbox_container.add_child(card_instance)
		#
		#if card_instance.has_method("set_card_data"):
			#card = all_cards.pop_front()
			#card_instance.set_card_data(card["path"])
			#selected_cards.append(card)
			#
		#else:
			#print("Erreur : L'instance de carte ne possède pas 'set_card_data'.")
#
#
#func _assign_hbox_cards(cards):
	#
	## Nettoyer les anciennes cartes dans hbox_container avant d'ajouter les nouvelles
	#for child in hbox_container.get_children():
		#child.queue_free()
#
	#for card in cards:
		#var card_instance = card_ui_scene.instantiate()
		#hbox_container.add_child(card_instance)
		#
		#if card_instance.has_method("set_card_data"):
			#card = all_cards.pop_front()
			#card_instance.set_card_data(card["path"])
			#selected_cards.append(card)
#
		#else:
			#print(" Erreur : L'instance de carte ne possède pas 'set_card_data'.")
