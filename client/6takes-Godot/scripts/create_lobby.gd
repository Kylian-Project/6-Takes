extends Control

@onready var end_points_dropdown = $PanelContainer/MainVertical/AvailableOptions/Choices/EndPointsDropdown
@onready var max_points_label = $PanelContainer/MainVertical/AvailableOptions/Options/MaxPoints
@onready var max_points_dropdown = $PanelContainer/MainVertical/AvailableOptions/Choices/MaxPointsDropdown
@onready var rounds_label = $PanelContainer/MainVertical/AvailableOptions/Options/Rounds
@onready var round_dropdown = $PanelContainer/MainVertical/AvailableOptions/Choices/RoundsDropdown
@onready var private_check_button = $PanelContainer/MainVertical/PublicPrivate/PrivateCheckButton
@onready var create_button = $PanelContainer/MainVertical/CreateLobbyButton


@onready var lobby_name_field = $PanelContainer/MainVertical/AvailableOptions/Choices/EditLobbyName
@onready var player_limit_dropdown = $PanelContainer/MainVertical/AvailableOptions/Choices/PlayerLimitDropdown
@onready var card_number_dropdown = $PanelContainer/MainVertical/AvailableOptions/Choices/CardNumberDropdown
@onready var round_timer_dropdown = $PanelContainer/MainVertical/AvailableOptions/Choices/RoundTimerDropdown
@onready var rounds_dropdown = $PanelContainer/MainVertical/AvailableOptions/Choices/RoundsDropdown

# Pour afficher la liste des lobbies disponibles
#@onready var available_rooms_list = $PanelContainer/MainVertical/AvailableOptions/Choices/RoomsList  # Assurez-vous d'avoir un nœud pour afficher la liste
@onready var client: SocketIO = $"../SocketIO"
var BASE_URL
var lobby_name 

func _ready():
	if client == null:
		print("❌ Le client SocketIO n'a pas pu être instancié.")
		return

	BASE_URL = get_node("/root/Global").get_base_url()
	BASE_URL = "http://" + BASE_URL
	client.base_url = BASE_URL
	client.event_received.connect(_on_event_recu)
	client.socket_connected.connect(_on_socket_connected)
	client.socket_disconnected.connect(_on_socket_disconnected)

	# Connexion du bouton "Créer"
	create_button.pressed.connect(_on_create_lobby)

	# Démarre la connexion
	client.connect_socket() 

	# Demande de la liste des lobbies disponibles
	#client.emit("get-available-rooms", {})  # Demande au serveur de récupérer la liste des lobbies disponibles

func _on_socket_connected(ns: String):
	print(" Socket connecté")

func _on_socket_disconnected():
	print(" Socket déconnecté.")

func _on_create_lobby():
	var visibility = "PRIVATE" if private_check_button.button_pressed else "PUBLIC"
	
	if !lobby_name_field.text.is_empty():
		print("lobby name debug :", lobby_name)
		lobby_name = lobby_name_field.text
		get_node("/root/Global").lobby_name = lobby_name
		
	var message = {
		"event": "create-room",
		"lobbyName": lobby_name,
		"playerLimit": int(player_limit_dropdown.get_item_text(player_limit_dropdown.get_selected())),
		"numberOfCards": int(card_number_dropdown.get_item_text(card_number_dropdown.get_selected())),
		"roundTimer": int(round_timer_dropdown.get_item_text(round_timer_dropdown.get_selected())),
		"endByPoints": int(end_points_dropdown.get_item_text(end_points_dropdown.get_selected())),
		"rounds": int(rounds_dropdown.get_item_text(rounds_dropdown.get_selected())),
		"isPrivate": visibility
	}

	client.emit("create-room", message)  # PAS besoin de JSON.stringify
	print(" Demande de création envoyée :", message)
	

func _on_event_recu(event: String, data: Variant, ns: String):
	print(" Événement reçu :", event)

	if event == "private-room-created" or "public-room-created" :
		print(" Le lobby privé a été créé.")
		
		#set global lobby data
		get_node("/root/GameState").id_lobby = data[0]
		get_node("/root/GameState").is_host = true
		
		GameState.player_info = {
			"username": get_node("/root/Global").player_name,
			 "id": get_node("/root/Global").player_id
			}
	
		get_tree().change_scene_to_file("res://scenes/mp_lobby_scene.tscn")
	
	#elif event == "public-room-created":
		#print("Le lobby public a été créé.")
		#get_tree().change_scene_to_file("res://scenes/mp_lobby_scene.tscn")
	
	elif event == "available-rooms":
		# Traitement des lobbies disponibles
		print(" Lobbies disponibles reçus :", data)
		print(" Liste des lobbies mise à jour.")
