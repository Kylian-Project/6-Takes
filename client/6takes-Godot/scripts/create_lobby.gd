extends Control

@onready var end_points_dropdown = $PanelContainer/MainVertical/AvailableOptions/Choices/EndPointsDropdown
@onready var max_points_label = $PanelContainer/MainVertical/AvailableOptions/Options/MaxPoints
@onready var max_points_dropdown = $PanelContainer/MainVertical/AvailableOptions/Choices/MaxPointsDropdown
@onready var rounds_label = $PanelContainer/MainVertical/AvailableOptions/Options/Rounds
@onready var round_dropdown = $PanelContainer/MainVertical/AvailableOptions/Choices/RoundsDropdown
@onready var private_check_button = $PanelContainer/MainVertical/PublicPrivate/PrivateCheckButton
@onready var create_button = $PanelContainer/MainVertical/Button

# 🔽 Ajoute des envoies au server:
@onready var lobby_name_field = $PanelContainer/MainVertical/AvailableOptions/Choices/EditLobbyName
@onready var player_limit_dropdown = $PanelContainer/MainVertical/AvailableOptions/Choices/PlayerLimitDropdown
@onready var card_number_dropdown = $PanelContainer/MainVertical/AvailableOptions/Choices/CardNumberDropdown
@onready var round_timer_dropdown = $PanelContainer/MainVertical/AvailableOptions/Choices/RoundTimerDropdown
@onready var rounds_dropdown = $PanelContainer/MainVertical/AvailableOptions/Choices/RoundsDropdown

@onready var client: SocketIO = $"../SocketIO"

func _ready():
	# Vérifie que le client SocketIO existe et est connecté
	if client == null:
		print(" Le client SocketIO n'a pas pu être instancié.")
		return
	
	# Connexion manuelle du signal pour la création de lobby
	create_button.pressed.connect(Callable(self, "_on_create_lobby"))

	# Connecte les événements de connexion et de déconnexion de SocketIO
	client.connect("connected", Callable(self, "_on_socket_connected"))
	client.connect("disconnected", Callable(self, "_on_socket_disconnected"))

# Fonction pour gérer la connexion réussie

# Fonction pour créer un lobby
func _on_create_lobby():
	var visibility = "PRIVATE" if private_check_button.button_pressed else "PUBLIC"

	var message = {
		"event": "create-room",
		"lobbyName": lobby_name_field.text,
		"playerLimit": int(player_limit_dropdown.get_item_text(player_limit_dropdown.get_selected())),
		"numberOfCards": int(card_number_dropdown.get_item_text(card_number_dropdown.get_selected())),
		"roundTimer": int(round_timer_dropdown.get_item_text(round_timer_dropdown.get_selected())),
		"endByPoints": int(end_points_dropdown.get_item_text(end_points_dropdown.get_selected())),
		"rounds": int(rounds_dropdown.get_item_text(rounds_dropdown.get_selected())),
		"isPrivate": visibility
	}
	print(visibility)

	client.emit("create-room", JSON.stringify(message))
	print(" Demande envoyée :", JSON.stringify(message))

	get_tree().change_scene_to_file("res://scenes/gameboard.tscn")




# Fonction appelée lorsque la connexion est prête (optionnel)
func _on_socket_ready():
	print("La connexion Socket.IO est prête et prête à recevoir des messages.")

# Fonction de retour à la scène précédente (exemple de bouton "Retour")
func _on_return_pressed():
	get_tree().change_scene_to_file("res://scenes/gameboard.tscn")  # Change la scène
