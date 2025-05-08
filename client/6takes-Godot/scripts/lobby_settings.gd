extends Control

@onready var end_points_dropdown = $MainVertical/AvailableOptions/Choices/EndPointsDropdown
@onready var max_points_label = $MainVertical/AvailableOptions/Options/MaxPoints
@onready var max_points_dropdown = $MainVertical/AvailableOptions/Choices/MaxPointsDropdown
@onready var rounds_label = $MainVertical/AvailableOptions/Options/Rounds
@onready var round_dropdown = $MainVertical/AvailableOptions/Choices/RoundsDropdown
@onready var create_button = $MainVertical/CreateLobbyButton


@onready var lobby_name_field = $MainVertical/AvailableOptions/Choices/EditLobbyName
@onready var player_limit_dropdown = $MainVertical/AvailableOptions/Choices/PlayerLimitDropdown
@onready var card_number_dropdown = $MainVertical/AvailableOptions/Choices/CardNumberDropdown
@onready var round_timer_dropdown = $MainVertical/AvailableOptions/Choices/RoundTimerDropdown
@onready var rounds_dropdown = $MainVertical/AvailableOptions/Choices/RoundsDropdown

var lobby_name 
var uname

# Called when the node enters the scene tree for the first time.
func _initialize_settings() -> void:
	uname ="neila" #Global.player_name
	
	lobby_name_field.editable = false 
	lobby_name_field.placeholder_text = GameState.lobby_name 
	
	player_limit_dropdown.select(GameState.players_limit - 2)
	#card_number_dropdown.select(GameState.card_number - 1)
	card_number_dropdown.selected = GameState.card_number - 1


func _on_save_settings() -> void:
		
	var player_limit = int(player_limit_dropdown.get_item_text(player_limit_dropdown.get_selected()))
	var rounds = int(rounds_dropdown.get_item_text(rounds_dropdown.get_selected()))
	
	if GameState.players_count - GameState.bot_count > player_limit:
		player_limit =GameState.players_limit
		
	var message = {
		"event": "create-room",
		"username" : uname,
		"lobbyName": lobby_name,
		"playerLimit": player_limit,
		"numberOfCards": int(card_number_dropdown.get_item_text(card_number_dropdown.get_selected())),
		"roundTimer": int(round_timer_dropdown.get_item_text(round_timer_dropdown.get_selected())),
		"endByPoints": int(end_points_dropdown.get_item_text(end_points_dropdown.get_selected())),
		"rounds": rounds,
	}
	
	print("sending setting changed")
	SocketManager.emit("update-room-settings", {
		"roomId" : GameState.id_lobby,
		"newSettings" : message
	})


func _on_visibility_changed():
	if visible:
		_initialize_settings()


func _on_close_pressed() -> void:
	self.visible = false
	queue_free()
