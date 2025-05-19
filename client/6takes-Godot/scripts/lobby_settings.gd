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

func _ready() -> void:
	_initialize_settings()
	
# Called when the node enters the scene tree for the first time.
func _initialize_settings() -> void:
	print("GameState values:", GameState.lobby_name, GameState.players_limit, GameState.card_number)
	
	uname = Global.player_name
	 
	lobby_name_field.text = GameState.lobby_name 
	
	var target_value = int(GameState.players_limit)
	var index = player_limit_dropdown.get_item_index(target_value)
	if index != -1:
		player_limit_dropdown.select(index)
		
		# Card number
	var card_value = int(GameState.card_number)
	var card_index = card_number_dropdown.get_item_index(card_value)
	if card_index != -1:
		card_number_dropdown.select(card_index)

	# Round timer
	var round_time_value = int(GameState.timer)
	var round_time_index = round_timer_dropdown.get_item_index(round_time_value)
	if round_time_index != -1:
		round_timer_dropdown.select(round_time_index)
		
	rounds_dropdown.text = str(GameState.rounds)



func _on_save_settings() -> void:
		
	var player_limit = int(player_limit_dropdown.get_item_text(player_limit_dropdown.get_selected()))
	#var rounds = int(rounds_dropdown.get_item_text(rounds_dropdown.get_selected()))
	
	if GameState.players_count > player_limit:
		player_limit = GameState.players_limit
		
	var message = {
		"event": "create-room",
		"username" : uname,
		"lobbyName": lobby_name,
		"playerLimit": player_limit,
		"numberOfCards": int(card_number_dropdown.get_item_text(card_number_dropdown.get_selected())),
		"roundTimer": int(round_timer_dropdown.get_item_text(round_timer_dropdown.get_selected())),
		"endByPoints": int(end_points_dropdown.get_item_text(end_points_dropdown.get_selected())),
		"rounds": GameState.rounds,
	}
	
	SocketManager.emit("update-room-settings", {
		"roomId" : GameState.id_lobby,
		"newSettings" : message
	})


func _on_visibility_changed():
	if visible:
		_initialize_settings()


func _on_close_pressed() -> void:
	self.visible = false
	#queue_free()
