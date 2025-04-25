extends Control

@onready var start_button = $BottomButtons/StartButton
@onready var quit_button = $BottomButtons/QuitButton
@onready var settings_button = $BottomButtons/SettingsButton
@onready var settings_overlay = $SettingsOverlay
@onready var settings_close_button = $SettingsOverlay/Close

@onready var player_limit_dropdown = $SettingsOverlay/PanelContainer/MainVertical/AvailableOptions/Choices/PlayerLimitDropdown
@onready var card_number_dropdown = $SettingsOverlay/PanelContainer/MainVertical/AvailableOptions/Choices/CardNumberDropdown
@onready var round_timer_dropdown = $SettingsOverlay/PanelContainer/MainVertical/AvailableOptions/Choices/RoundTimerDropdown
@onready var end_points_dropdown = $SettingsOverlay/PanelContainer/MainVertical/AvailableOptions/Choices/EndPointsDropdown
@onready var rounds_dropdown = $SettingsOverlay/PanelContainer/MainVertical/AvailableOptions/Choices/RoundsDropdown
@onready var max_points_dropdown = $SettingsOverlay/PanelContainer/MainVertical/AvailableOptions/Choices/MaxPointsDropdown

@onready var players_container = $MainVbox
@onready var socket_io = $SocketIO
@onready var player_entry_scene = preload("res://scenes/Player_slot.tscn")

var player_count = 1
var player_username
var bot_count = 0

var BASE_URL

func _ready():
	settings_overlay.visible = false
	
	player_username = get_node("/root/Global").player_name
	
	# Hover sounds
	start_button.mouse_entered.connect(SoundManager.play_hover_sound)
	quit_button.mouse_entered.connect(SoundManager.play_hover_sound)
	settings_button.mouse_entered.connect(SoundManager.play_hover_sound)
	settings_close_button.mouse_entered.connect(SoundManager.play_hover_sound)

	# Click sounds
	start_button.pressed.connect(SoundManager.play_click_sound)
	quit_button.pressed.connect(SoundManager.play_click_sound)
	settings_button.pressed.connect(SoundManager.play_click_sound)
	settings_close_button.pressed.connect(SoundManager.play_click_sound)
	
	# Hover sounds for dropdowns
	player_limit_dropdown.mouse_entered.connect(SoundManager.play_hover_sound)
	card_number_dropdown.mouse_entered.connect(SoundManager.play_hover_sound)
	round_timer_dropdown.mouse_entered.connect(SoundManager.play_hover_sound)
	end_points_dropdown.mouse_entered.connect(SoundManager.play_hover_sound)
	rounds_dropdown.mouse_entered.connect(SoundManager.play_hover_sound)
	max_points_dropdown.mouse_entered.connect(SoundManager.play_hover_sound)
	
	#connect to socket
	BASE_URL = get_node("/root/Global").get_base_url()
	BASE_URL = "http://" + BASE_URL
	socket_io.base_url = BASE_URL
	socket_io.connect_socket()
	socket_io.event_received.connect(_on_socket_event_received)


func _on_socket_event_received(event: String, data: Variant, ns: String):
	match event:
		"users-in-your-private-room", "users-in-your-public-room":
			_refresh_player_list(data)

	
func _refresh_player_list(data):
	players_container.clear()  # remove old entries
	#for user_dict in GameState.other_players:
	for i in data.size():
		var user_dict = data[i]
		var entry = player_entry_scene.instantiate()
		var is_host = (i == 0)
		
		entry.create_player_visual(user_dict.username, user_dict.icon, is_host)
		#entry.get_node("HostBadge").visible = (user_dict.username == GameState.player_info.username and GameState.is_host)
		players_container.add_child(entry)
		

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/gameboard.tscn")
