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
	update_add_bot_button()

func add_bot():
	var player_limit = get_current_player_limit()
	if (bot_count + 1) >= player_limit:
		print("Limite de joueurs atteinte (", player_limit, ")")
		return

	bot_count += 1
	update_bot_slots()

func get_current_player_limit() -> int:
	if settings_overlay.has_method("get_settings"):
		return settings_overlay.get_settings()["player_limit"]
	return 9  # fallback par défaut

func update_add_bot_button():
	var player_limit = get_current_player_limit()
	add_bot_button.disabled = (bot_count + 1) >= player_limit

func remove_bot(bot_instance):
	if bot_count > 1:
		bot_count -= 1
		update_bot_slots()
		update_add_bot_button()
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
	add_bot_button.visible = true 
	update_add_bot_button()

# Lancement du jeu avec Bots
func start_game():
	var settings = settings_overlay.get_settings()

	# Sauvegarde des paramètres dans le singleton Global
	Global.game_settings = {
		"nb_cartes": settings["card_number"],
		"nb_max_heads": settings["max_points"] if settings["use_max_points"] else 999,
		"nb_max_manches": settings["rounds"] if not settings["use_max_points"] else 999,
		"bot_count": bot_count,
		"round_timer": settings["round_timer"]
	}

	print("Lancement du jeu solo avec les paramètres :", Global.game_settings)

	# Changer de scène vers GameBoard
	var error = get_tree().change_scene_to_file("res://scenes/gameboard.tscn")
	if error != OK:
		print("Erreur changement de scène :", error)


func return_to_main_menu():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func show_settings():
	settings_overlay.visible = true

func hide_settings():
	settings_overlay.visible = false
