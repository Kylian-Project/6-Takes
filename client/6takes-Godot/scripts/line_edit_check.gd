extends Control

@onready var available_rooms_list = $JoinPanel/MainVertical/AvailableOptions/RoomsList  
@onready var join_button = $JoinPanel/MainVertical/JoinCodeContainer/JoinCodeButton
@onready var client: SocketIO = $"../SocketIO"
@onready var btn = $JoinPanel/MainVertical/JoinCodeContainer/SpinBox
@onready var test_button = $JoinPanel/MainVertical/AvailableOptions/TestButton  # <-- Ajoute ce bouton dans l'éditeur si tu veux tester

var selected_room_id = ""
var room_data = {}  # Mapping pour sauvegarder les infos du lobby
var pending_room_ids: Array = []  # Liste des lobbies en attente de réponse
var max_players = 10  # Nombre max de joueurs

func _ready():
	if client == null:
		print("❌ Le client SocketIO n'est pas instancié.")
		return

	# Forcer une taille temporaire pour l'affichage de la liste
	available_rooms_list.custom_minimum_size = Vector2(200, 200)

	client.socket_connected.connect(_on_socket_connected)
	client.socket_disconnected.connect(_on_socket_disconnected)
	client.event_received.connect(_on_event_recu)
	client.connect_socket()

	# Connexion des signaux
	join_button.pressed.connect(_on_join_lobby)
	available_rooms_list.item_selected.connect(_on_room_selected)

	# (optionnel) bouton de test
	if test_button:
		test_button.pressed.connect(_on_test_button_pressed)

	# Demander les lobbies
	client.emit("available-rooms", {})

# Lorsque l'événement "public-room-joined" est reçu (lorsqu'un joueur rejoint un lobby)
# Lorsque l'utilisateur rejoint un lobby
# Lorsque l'utilisateur rejoint un lobby
# Fonction appelée lorsque l'utilisateur sélectionne un lobby
func _on_room_selected(index: int):
	# Récupère le texte affiché de l'élément sélectionné
	var selected_room_name = available_rooms_list.get_item_text(index)
	print("Lobby sélectionné : ", selected_room_name)

	# Récupère l'ID du lobby qui est stocké dans les métadonnées de l'élément sélectionné
	var selected_room_id = available_rooms_list.get_item_metadata(index)
	print(" ID du lobby sélectionné : ", selected_room_id)

	# Met l'ID du lobby dans le SpinBox
	btn.text = selected_room_id

	# Sauvegarde l'ID du lobby dans la variable de sélection pour l'utiliser plus tard
	self.selected_room_id = selected_room_id  # Utilise `self` pour mettre à jour la variable de l'instance
	print(" ID du lobby sélectionné dans SpinBox : ", self.selected_room_id)

# Lors de la réception de l'événement public-room-joined
# Lors de la réception de l'événement public-room-joined
# Lors de la réception de l'événement public-room-joined
func _on_event_recu(event: String, data: Variant, ns: String):
	print(" Événement reçu :", event)
	if event == "available-rooms":
		print(" Lobbies disponibles reçus :", data)
		available_rooms_list.clear()  # Vider la liste avant d'ajouter de nouveaux lobbies

		# Vérifie que les données sont bien au format attendu
		if typeof(data) == TYPE_ARRAY and data.size() > 0:
			for room_array in data:
				if typeof(room_array) == TYPE_ARRAY:
					for room in room_array:  # Assure-toi que tu traites chaque lobby
						if typeof(room) == TYPE_DICTIONARY:
							var room_id = room.get("id", "Unknown")  # Sécurise l'accès à la clé 'id'
							var room_name = room.get("name", "Unknown")
							var count = room.get("count", 0 )
							var player_limit = room.get("playerLimit", 10)

							# Formatage du texte pour afficher "Nom du lobby (compte joueurs / limite joueurs)"
							var display_text = "%s (%d/%d)" % [room_name, count, player_limit]

							# Ajoute le lobby à la liste dans l'UI
							available_rooms_list.add_item(display_text)
							
							# Sauvegarder l'ID du lobby avec son index dans la liste
							available_rooms_list.set_item_metadata(available_rooms_list.item_count, room_id)

							print("🔹 Lobby ajouté :", room_name, "avec", count, "joueurs.")

	# Mise à jour de l'UI lorsqu'un joueur rejoint ou quitte un lobby
	if event == "public-room-joined":
		if typeof(data) == TYPE_ARRAY and data.size() > 0:
			var room_info = data[0]  # Supposons que les données contiennent les informations du lobby
			if typeof(room_info) == TYPE_DICTIONARY:
				var count = room_info.get("count", 0)
				var usernames = room_info.get("usernames", [])

				# Affichage des informations du lobby après que le joueur ait rejoint
				print("Tu as rejoint le lobby avec les joueurs suivants : ", usernames)
				print(" Nombre actuel de joueurs dans le lobby : ", count)

				# Vérifier si selected_room_id est bien défini avant de mettre à jour la liste
				if self.selected_room_id != "":
					_update_room_in_list(self.selected_room_id, count, usernames)
				else:
					print("❌ Aucune ID de lobby sélectionnée pour mise à jour.")
				
				# Changer de scène vers le gameboard après avoir rejoint le lobby
				print(" Changement de scène vers le GameBoard...")
				get_tree().change_scene_to_file("res://scenes/gameboard.tscn")  # Change la scène
			else:
				print(" Format de données incorrectes pour 'public-room-joined' :", room_info)
		else:
			print(" Données vides ou mal formatées pour 'public-room-joined'")

# Fonction pour mettre à jour un lobby spécifique dans la liste
func _update_room_in_list(room_id: String, count: int, usernames: Array):
	

	# Trouver l'élément de la liste avec l'ID du lobby
	var room_found = false  # Flag pour vérifier si le lobby a été trouvé
	for i in range(available_rooms_list.item_count):
		var current_room_id = available_rooms_list.get_item_metadata(i)
		if current_room_id == room_id:
			# Mettre à jour l'affichage du lobby
			var room_name = available_rooms_list.get_item_text(i).split(" ")[0]  # Extraire le nom du lobby
			var updated_display_text = "%s (%d/%d)" % [room_name, count, max_players]
			available_rooms_list.set_item_text(i, updated_display_text)
			print(" Mise à jour du lobby :", room_name, " nouveau nombre de joueurs : ", count)
			
			# Mettre à jour la liste des joueurs affichés (si nécessaire)
			# Si tu as un autre élément d'interface pour afficher les joueurs, tu peux le mettre à jour ici.

			room_found = true
			break

	if not room_found:
		print(" Lobby non trouvé pour mise à jour :", room_id)

# Lorsque l'utilisateur veut rejoindre un lobby
func _on_join_lobby():
	var selected_room_value = btn.text
	print("Texte du SpinBox saisi : ", selected_room_value)

	if selected_room_value != "":
		var message = {
			"roomId": selected_room_value,
			"username": "mouctar"
		}
		client.emit("join-room", message)
		print(" Demande de rejoindre le lobby envoyée :", message)
	else:
		print(" Aucun lobby sélectionné ou valeur vide dans le SpinBox.")

# Fonction pour la connexion au serveur
func _on_socket_connected(ns: String):
	print(" Socket connecté au namespace :", ns)

# Fonction pour la déconnexion du serveur
func _on_socket_disconnected():
	print(" Socket déconnecté.")

# (optionnel) Pour tester manuellement si la liste fonctionne
func _on_test_button_pressed():
	available_rooms_list.add_item("TEST_LOBBY")
	print(" Test: ajout de 'TEST_LOBBY' dans la liste")
