extends Control

@onready var bot_grid = $MainVbox/BotGrid 
@onready var add_bot_button = $MainVbox/AddBotButton
@onready var sp_start_button = $BottomButtons/SPStartButton
@onready var sp_return_button = $BottomButtons/SPReturnButton
@onready var sp_settings_button = $BottomButtons/SPSettingsButton
@onready var settings_overlay = $SettingsOverlay
@onready var settings_close_button = $SettingsOverlay/Close

@onready var player_limit_dropdown = $SettingsOverlay/PanelContainer/MainVertical/AvailableOptions/Choices/PlayerLimitDropdown
@onready var card_number_dropdown = $SettingsOverlay/PanelContainer/MainVertical/AvailableOptions/Choices/CardNumberDropdown
@onready var round_timer_dropdown = $SettingsOverlay/PanelContainer/MainVertical/AvailableOptions/Choices/RoundTimerDropdown
@onready var end_points_dropdown = $SettingsOverlay/PanelContainer/MainVertical/AvailableOptions/Choices/EndPointsDropdown
@onready var rounds_dropdown = $SettingsOverlay/PanelContainer/MainVertical/AvailableOptions/Choices/RoundsDropdown
@onready var max_points_dropdown = $SettingsOverlay/PanelContainer/MainVertical/AvailableOptions/Choices/MaxPointsDropdown

@export var bot_scene: PackedScene


var bot_count = 1  # Start with 1 bot minimum
	
@onready var socket_io = $SocketIO

func _ready():
	add_bot_button.pressed.connect(add_bot)
	sp_start_button.pressed.connect(start_game)
	sp_return_button.pressed.connect(return_to_main_menu)
	sp_settings_button.pressed.connect(show_settings)
	settings_close_button.pressed.connect(hide_settings)
	settings_overlay.visible = false
	
	# Hover sounds
	add_bot_button.mouse_entered.connect(SoundManager.play_hover_sound)
	sp_start_button.mouse_entered.connect(SoundManager.play_hover_sound)
	sp_return_button.mouse_entered.connect(SoundManager.play_hover_sound)
	sp_settings_button.mouse_entered.connect(SoundManager.play_hover_sound)
	settings_close_button.mouse_entered.connect(SoundManager.play_hover_sound)

	# Click sounds
	add_bot_button.pressed.connect(SoundManager.play_click_sound)
	sp_start_button.pressed.connect(SoundManager.play_click_sound)
	sp_return_button.pressed.connect(SoundManager.play_click_sound)
	sp_settings_button.pressed.connect(SoundManager.play_click_sound)
	settings_close_button.pressed.connect(SoundManager.play_click_sound)
	
	# Hover sounds for dropdowns
	player_limit_dropdown.mouse_entered.connect(SoundManager.play_hover_sound)
	card_number_dropdown.mouse_entered.connect(SoundManager.play_hover_sound)
	round_timer_dropdown.mouse_entered.connect(SoundManager.play_hover_sound)
	end_points_dropdown.mouse_entered.connect(SoundManager.play_hover_sound)
	rounds_dropdown.mouse_entered.connect(SoundManager.play_hover_sound)
	max_points_dropdown.mouse_entered.connect(SoundManager.play_hover_sound)

	update_bot_slots()


func add_bot():
	if bot_count < 9:
		bot_count += 1
		update_bot_slots()

func remove_bot(bot_instance):
	if bot_count > 1:
		bot_count -= 1
		update_bot_slots()
	else:
		print("Cannot remove the last bot!")

func update_bot_slots():
	# Clear existing bot slots
	for child in bot_grid.get_children():
		child.queue_free()

	# Recreate bots with correct numbering
	for i in range(bot_count):
		var bot_instance = bot_scene.instantiate()
		bot_instance.bot_index = i + 1  # Set bot index correctly
		bot_instance.lobby_scene = self  # Provide reference to LobbyScene
		bot_grid.add_child(bot_instance)

	# Ensure bot removal button logic is updated
	for bot in bot_grid.get_children():
		bot.check_bot_removal(bot_count)  # Pass correct bot count

	# Hide Add Bot button if max bots are reached
	add_bot_button.visible = bot_count < 9

func start_game():
	#socket_io.connect_socket()
	print("Starting game with", bot_count, "bots.")
	

func return_to_main_menu():
	get_tree().change_scene_to_file("res://scenes/multiplayer_menu.tscn")

func show_settings():
	settings_overlay.visible = true

func hide_settings():
	settings_overlay.visible = false
