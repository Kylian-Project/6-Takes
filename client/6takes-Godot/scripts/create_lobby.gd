extends Control

@onready var end_points_dropdown = $PanelContainer/MainVertical/AvailableOptions/Choices/EndPointsDropdown
@onready var max_points_label = $PanelContainer/MainVertical/AvailableOptions/Options/MaxPoints
@onready var max_points_dropdown = $PanelContainer/MainVertical/AvailableOptions/Choices/MaxPointsDropdown
@onready var rounds_label = $PanelContainer/MainVertical/AvailableOptions/Options/Rounds
@onready var round_dropdown = $PanelContainer/MainVertical/AvailableOptions/Choices/RoundsDropdown
@onready var private_check_button = $PanelContainer/MainVertical/PublicPrivate/PrivateCheckButton
@onready var create_button = $PanelContainer/MainVertical/Button

@onready var client: SocketIO = $"../SocketIO"  # Nœud SocketIO déjà connecté dans la scène

func _ready():
	# Vérifie que le client SocketIO existe et est connecté
	if client == null:
		print("❌ Le client SocketIO n'a pas pu être instancié.")
		return
	
	# Connexion manuelle du signal pour la création de lobby
	create_button.pressed.connect(Callable(self, "_on_create_lobby"))

	# Connecte les événements de connexion et de déconnexion de SocketIO
	client.connect("connected", Callable(self, "_on_socket_connected"))
	client.connect("disconnected", Callable(self, "_on_socket_disconnected"))

# Fonction pour gérer la connexion réussie

# Fonction pour créer un lobby
func _on_create_lobby():
	# Créer le message avec les informations minimales
	var message = {
		"event": "create-room",
		"username": "Player1",  # Laisse cette valeur ou récupère un vrai nom de joueur
		"isPrivate": private_check_button.pressed  # Utilise l'état du bouton pour déterminer la valeur de "isPrivate"
	}

	# Convertir le message en JSON et l'envoyer via Socket.IO
	client.emit("create-room", JSON.stringify(message))
	print("📤 Demande de création de salle envoyée :", JSON.stringify(message))

	# Changer de scène après avoir envoyé la demande
	# Remplacer par la scène suivante une fois que tu l'auras définie
	get_tree().change_scene_to_file("res://scenes/gameboard.tscn")

# Fonction appelée lorsque la connexion est prête (optionnel)
func _on_socket_ready():
	print("✅ La connexion Socket.IO est prête et prête à recevoir des messages.")

# Fonction de retour à la scène précédente (exemple de bouton "Retour")
func _on_return_pressed():
	get_tree().change_scene_to_file("res://scenes/gameboard.tscn")  # Change la scène
