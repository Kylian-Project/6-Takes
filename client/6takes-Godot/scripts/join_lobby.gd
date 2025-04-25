extends Control

@onready var available_rooms_list = $JoinPanel/MainVertical/AvailableOptions/RoomsList  
@onready var join_button = $JoinPanel/MainVertical/JoinCodeContainer/JoinCodeButton
@onready var client: SocketIO = $"../SocketIO"
@onready var btn = $JoinPanel/MainVertical/JoinCodeContainer/SpinBox
#@onready var test_button = $JoinPanel/MainVertical/AvailableOptions/TestButton
@onready var refresh = $Button2
var selected_room_id = ""
var room_ids: Array = []  # <-- Contient les roomId réels (ex: "cTjY")
var max_players = 10
var BASE_URL

var player_name

func _ready():
	if client == null:
		print("❌ Le client SocketIO n'est pas instancié.")
		return
	
	player_name = get_node("/root/Global").player_name
	available_rooms_list.custom_minimum_size = Vector2(200, 200)
	
	BASE_URL = get_node("/root/Global").get_base_url()
	BASE_URL = "http://" + BASE_URL
	client.base_url = BASE_URL
	client.socket_connected.connect(_on_socket_connected)
	client.socket_disconnected.connect(_on_socket_disconnected)
	client.event_received.connect(_on_event_recu)
	client.connect_socket()

	join_button.pressed.connect(_on_join_lobby)
	available_rooms_list.item_selected.connect(_on_room_selected)
	refresh.pressed.connect(_on_refresh_lobbies)

	#client.emit("available-rooms", {})


func _on_room_selected(index: int):
	var selected_room_name = available_rooms_list.get_item_text(index)
	var selected_room_id = available_rooms_list.get_item_metadata(index)
	print("Lobby sélectionné : ", selected_room_name)
	print("ID du lobby sélectionné : ", selected_room_id)

	self.selected_room_id = selected_room_id

	btn.text = selected_room_id


func _on_refresh_lobbies():
	print(" Rafraîchissement des lobbies demandé...")
	client.emit("available-rooms", {})
#
	#if selected_room_id != "":
		#var message = {
			#"roomId": selected_room_id,
			#"username": player_name
		#}
		#client.emit("join-room", message)


func _on_event_recu(event: String, data: Variant, ns: String):
	print("Événement reçu :", event)
	if event == "available-rooms":
		print("Lobbies disponibles reçus :", data)
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
		if typeof(data) == TYPE_ARRAY and data.size() > 0:
			var room_info = data[0]
			if typeof(room_info) == TYPE_DICTIONARY:
				var count = room_info.get("count", 0)
				var usernames = room_info.get("usernames", [])
				print("Tu as rejoint le lobby avec :", usernames)
				print("Nombre actuel de joueurs : ", count)

				if self.selected_room_id != "":
					_update_room_in_list(self.selected_room_id, count, usernames)
				else:
					print("❌ Aucune ID de lobby sélectionnée pour mise à jour.")
				
					
				get_node("/root/GameState").id_lobby = selected_room_id
				get_node("/root/GameState").is_host = false
				get_node("/root/GameState").other_players = usernames
				
				get_tree().change_scene_to_file("res://scenes/mp_lobby_scene.tscn")
			else:
				print("Format de données incorrect pour 'public-room-joined' :", room_info)
		else:
			print("Données vides ou mal formatées pour 'public-room-joined'")


func _update_room_in_list(room_id: String, count: int, usernames: Array):
	var room_found = false
	for i in range(available_rooms_list.item_count):
		var current_room_id = available_rooms_list.get_item_metadata(i)
		if current_room_id == room_id:
			var room_name = available_rooms_list.get_item_text(i).split(" ")[0]
			var updated_display_text = "%s (%d/%d)" % [room_name, count, max_players]
			available_rooms_list.set_item_text(i, updated_display_text)
			print("Mise à jour du lobby :", room_name, "nouveau nombre :", count)
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
		client.emit("join-room", message)
		print("join room sent :", message)
	else:
		print(" Aucun lobby sélectionné ou valeur vide dans le LineEdit.")


func _on_socket_connected(ns: String):
	print("Socket connecté :", ns)

func _on_socket_disconnected():
	print("Socket déconnecté.")
