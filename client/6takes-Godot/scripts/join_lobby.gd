extends Control

@onready var available_rooms_list = $JoinPanel/MainVertical/AvailableOptions/RoomsList  
@onready var join_button = $JoinPanel/MainVertical/JoinCodeContainer/JoinCodeButton
@onready var btn = $JoinPanel/MainVertical/JoinCodeContainer/SpinBox
@onready var refresh = $Button2
var selected_room_id = ""
var room_ids: Array = []  # <-- Contient les roomId réels (ex: "cTjY")
var max_players = 10

var player_name


func _ready():	
	player_name = Global.player_name
	available_rooms_list.custom_minimum_size = Vector2(200, 200)
	
	SocketManager.connect("event_received", Callable(self, "_on_socket_event"))

	join_button.pressed.connect(_on_join_lobby)
	available_rooms_list.item_selected.connect(_on_room_selected)
	refresh.pressed.connect(_on_refresh_lobbies)

	SocketManager.emit("available-rooms", {})


func _on_room_selected(index: int):
	var selected_room_name = available_rooms_list.get_item_text(index)
	var selected_room_id = available_rooms_list.get_item_metadata(index)
	print("Lobby sélectionné : ", selected_room_name)
	print("ID du lobby sélectionné : ", selected_room_id)

	self.selected_room_id = selected_room_id
	#GameState.id_lobby = selected_room_id

	btn.text = selected_room_id


func _on_refresh_lobbies():
	print(" Rafraîchissement des lobbies demandé...")
	SocketManager.emit("available-rooms", {})


func _on_socket_event(event: String, data: Variant, ns: String):
	print("Événement reçu :", event, data)
	if event == "available-rooms":
		available_rooms_list.clear()
		room_ids.clear()

		if typeof(data) == TYPE_ARRAY and data.size() > 0:
			for room_array in data:
				if typeof(room_array) == TYPE_ARRAY:
					for room in room_array:
						if typeof(room) == TYPE_DICTIONARY:
							var room_id = room.get("id", "Unknown")
							var room_name = room.get("name", "Unknown")
							var count = room.get("count", 0)
							var player_limit = room.get("playerLimit", 10)

							var display_text = "%s (%d/%d)" % [room_name, count, player_limit]
							available_rooms_list.add_item(display_text)
							available_rooms_list.set_item_metadata(available_rooms_list.item_count - 1, room_id)

							room_ids.append(room_id)  # Stocke l'ID dans l'ordre
							print("🔹 Lobby ajouté :", room_name, "ID:", room_id)


	if event == "public-room-joined" or event == "private-room-joined" :
		if event == "public-room-joined":
			get_node("/root/GameState").is_public = true
		elif event == "private-room-joined" :
			GameState.is_public = false
			
		if typeof(data) == TYPE_ARRAY and data.size() > 0:
			var room_info = data[0]
			if typeof(room_info) == TYPE_DICTIONARY:
				var count = room_info.get("count", 0)
				var usernames = room_info.get("users", [])
				print("Tu as rejoint le lobby avec :", usernames)
				print("Nombre actuel de joueurs : ", count)

				if self.selected_room_id != "":
					_update_room_in_list(self.selected_room_id, count, usernames)
				
				
				GameState.is_host = false
				GameState.other_players = usernames
				GameState.players_count = count				
				GameState.data = data

				get_tree().change_scene_to_file("res://scenes/mp_lobby_scene.tscn")
		else:
			print("Données vides ou mal formatées pour 'public-room-joined'")
	
	if event == "room-not-found":
		$error_label.visible = true
	else:
		print("unhandled event received ", event, data)


func _update_room_in_list(room_id: String, count: int, usernames: Array):
	var room_found = false
	for i in range(available_rooms_list.item_count):
		var current_room_id = available_rooms_list.get_item_metadata(i)
		if current_room_id == room_id:
			var room_name = available_rooms_list.get_item_text(i).split(" ")[0]
			var updated_display_text = "%s (%d/%d)" % [room_name, count, max_players]
			available_rooms_list.set_item_text(i, updated_display_text)
			room_found = true
			break

	if not room_found:
		print("Lobby non trouvé pour mise à jour :", room_id)

func _on_join_lobby():
	var selected_room_value = btn.text.strip_edges()  # Nettoie les espaces au cas où

	if selected_room_value != "":
		var message = {
			"roomId": selected_room_value,
			"username": player_name
		}
		GameState.id_lobby = selected_room_value
		print("DEBUG ", selected_room_value)
		SocketManager.emit("join-room", message)
		print("jof room sent :", message)
	else:
		print(" Aucun lobby sélectionné ou valeur vide dans le LineEdit.")


func _on_socket_connected(ns: String):
	print("Socket connecté :", ns)

func _on_socket_disconnected():
	print("Socket déconnecté.")


func _on_close_pressed() -> void:
	self.visible = false
	queue_free()
