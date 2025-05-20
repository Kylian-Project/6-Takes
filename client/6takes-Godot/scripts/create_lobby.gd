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

var lobby_name 
var uname

func _ready():	
	SocketManager.connect("event_received", Callable(self, "_on_socket_event"))
	uname = Global.player_name
	# Set initial text based on check state
	private_check_button.text = "Private" if private_check_button.button_pressed else "Public"
	create_button.pressed.connect(SoundManager.play_click_sound)
	private_check_button.pressed.connect(SoundManager.play_click_sound)


func _on_socket_connected(ns: String):
	print(" Socket connecté")

func _on_socket_disconnected():
	print(" Socket déconnecté.")

func _on_create_lobby():
	var visibility = "PRIVATE" if private_check_button.button_pressed else "PUBLIC "
	
	if !lobby_name_field.text.is_empty():
		print("lobby name debug :", lobby_name)
		lobby_name = lobby_name_field.text
	else:
		lobby_name = " "
		
	var player_limit = int(player_limit_dropdown.get_item_text(player_limit_dropdown.get_selected()))
	var rounds = int(rounds_dropdown.get_item_text(rounds_dropdown.get_selected()))
	var card_number = int(card_number_dropdown.get_item_text(card_number_dropdown.get_selected()))
	var message = {
		"event": "create-room",
		"username" : uname,
		"lobbyName": lobby_name,
		"playerLimit": player_limit,
		"numberOfCards": card_number,
		"roundTimer": int(round_timer_dropdown.get_item_text(round_timer_dropdown.get_selected())),
		"endByPoints": int(end_points_dropdown.get_item_text(end_points_dropdown.get_selected())),
		"rounds": rounds,
		"isPrivate": visibility
	}
	
	GameState.lobby_name = lobby_name
	GameState.is_host = true
	GameState.is_public = !visibility
	GameState.players_limit = player_limit
	GameState.rounds = rounds
	GameState.card_number = card_number
	
	GameState.player_info = {
		"username": get_node("/root/Global").player_name,
		 "id": get_node("/root/Global").player_id,
		"icon": get_node("/root/Global").icon_id
		}
	
	SocketManager.emit("create-room", message) 
	print("create lobby event sent")

func _on_socket_event(event: String, data: Variant, ns: String):
	print(" Événement reçu :", event)

	if event == "private-room-created" or event == "public-room-created" :
		print(" Le lobby a été créé.")
		GameState.id_lobby = data[0]
		GameState.is_host = true
		
		get_tree().change_scene_to_file("res://scenes/mp_lobby_scene.tscn")

	else :
		print("unhandled event received ,",event, data)


func _on_close_pressed() -> void:
	self.visible = false
	queue_free()

func _on_private_check_button_toggled(button_pressed: bool) -> void:
	private_check_button.text = "Private" if button_pressed else "Public"
