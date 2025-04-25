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
@export var bot_scene: PackedScene = preload("res://scenes/BotSlot.tscn")




var bot_count = 1  # Start with 1 bot minimum

func _ready():
	if bot_scene == null:
		print("Erreur : La scène de bot n'a pas été chargée correctement.")
		return
	update_bot_slots()
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
	if bot_scene == null:
		print("Erreur : bot_scene est nul. Vérifie le préchargement de la scène.")
		return  # Arrêter la fonction si bot_scene est nul

	# Nettoyer les anciens bots
	for child in bot_grid.get_children():
		child.queue_free()

	# Créer de nouveaux slots pour les bots
	for i in range(bot_count):
		var bot_instance = bot_scene.instantiate()  # Crée une nouvelle instance de BotSlot
		bot_instance.bot_index = i + 1  # Attribue l'index du bot (par exemple, Bot 1, Bot 2)
		bot_instance.lobby_scene = self  # Référence à cette scène pour la gestion des bots
		bot_grid.add_child(bot_instance)  # Ajoute le bot à l'interface utilisateur

	# Masquer le bouton d'ajout de bot si on a atteint le maximum
	add_bot_button.visible = bot_count < 9

# Démarrer le jeu
func start_game():
	var player_name = "You"  # ou récupéré depuis un champ de saisie
	print("Starting game for", player_name, "with", bot_count, "bots.")

	var players = []

	# ➕ Ajouter le joueur principal
	players.append(player_name)

	# ➕ Ajouter les bots
	for i in range(bot_count):
		players.append("Bot " + str(i + 1))

	# Charger et instancier la scène GameBoard
	var game_scene = load("res://scenes/gameboard_SP.tscn").instantiate()

	# Passer les noms des joueurs (joueur principal + bots)
	game_scene.setup_from_lobby(players)

	# Ajouter la scène au root et changer de scène
	get_tree().root.add_child(game_scene)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = game_scene


func return_to_main_menu():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func show_settings():
	settings_overlay.visible = true

func hide_settings():
	settings_overlay.visible = false
