extends Control

@onready var rules = preload("res://scenes/rules.tscn")
@onready var login_scene = preload("res://scenes/logIn.tscn")

@onready var settings_overlay = $SettingsOverlay
@onready var settings_button = $SettingsButton
@onready var rules_button = $Rules
@onready var rules_overlay = $RulesOverlay
@onready var singleplayer_button = $VButtons/SinglePlayerButton
@onready var quit_button = $VButtons/QuitButton
@onready var multiplayer_button = $VButtons/MultiPlayerButton
@onready var profile_button = $Profile
@onready var overlay_layer = $OverlayLayer
@onready var settings_close_button   = $SettingsOverlay/Close


@onready var close_buttons = [
	$SettingsOverlay/Close,
	$RulesOverlay/MarginContainer/Control/Panel/CancelButton
]

@onready var overlay_buttons = [
	settings_button,
	rules_button,
]


#validate token 
var API_URL 

var login_instance = null
var rules_instance = null 
var logged_in 

func _ready() -> void:
	rules_overlay.visible = false
	settings_overlay.visible = false
	singleplayer_button.pressed.connect(go_to_singleplayer)
	settings_button.pressed.connect(show_settings)
	profile_button.pressed.connect(_on_profile_pressed)
	quit_button.pressed.connect(quit_game)
		
	
	# Hover Soundboard
	singleplayer_button.mouse_entered.connect(SoundManager.play_hover_sound)
	multiplayer_button.mouse_entered.connect(SoundManager.play_hover_sound)
	quit_button.mouse_entered.connect(SoundManager.play_hover_sound)
	settings_button.mouse_entered.connect(SoundManager.play_hover_sound)
	profile_button.mouse_entered.connect(SoundManager.play_hover_sound)
	rules_button.mouse_entered.connect(SoundManager.play_hover_sound)

		
	# Click Soundboard
	singleplayer_button.pressed.connect(SoundManager.play_click_sound)
	multiplayer_button.pressed.connect(SoundManager.play_click_sound)
	quit_button.pressed.connect(SoundManager.play_click_sound)
	settings_button.pressed.connect(SoundManager.play_click_sound)
	profile_button.pressed.connect(SoundManager.play_click_sound)
	rules_button.pressed.connect(SoundManager.play_click_sound)


	for close_button in close_buttons:
		close_button.pressed.connect(hide_settings)
		close_button.mouse_entered.connect(SoundManager.play_hover_sound)
		close_button.pressed.connect(SoundManager.play_click_sound)
		
	# Background Music
	SoundManager.play_music()
	
	
	get_node("/root/Global").load_session()
	logged_in = get_node("/root/Global").getLogged_in()
	
	profile_button.visible = logged_in
	print("visibilty : ", profile_button.visible) 
	
	if logged_in == false:
		singleplayer_button.text ="Play As A Guest"
		multiplayer_button.text = "Log In"
		
	else :
		singleplayer_button.text ="Singleplayer"
		multiplayer_button.text = "Multiplayer"
		

func _process(_delta):
	overlay_layer.visible = overlay_layer.get_child_count() > 0

func _on_multi_player_button_pressed() -> void:
	#get_node("/root/Global").load_session()
	logged_in = get_node("/root/Global").getLogged_in()
	
	if logged_in == true:
		get_tree().change_scene_to_file("res://scenes/multiplayer_menu.tscn")
		
	else:
		if login_instance == null:
			login_instance = login_scene.instantiate()
			add_child(login_instance)

			# Centrer l'écran de pause
			await get_tree().process_frame  
			
		login_instance.move_to_front()  # S'assurer que l'écran de pause est tout en haut
		login_instance.visible = true  # Afficher la pause
	

func go_to_singleplayer():
	get_tree().change_scene_to_file("res://scenes/SPLobbyScene.tscn")

func _on_cancel_button_pressed() -> void:
	rules_overlay.visible = false

func open_overlay(overlay: Control):
# hide any other overlays
	settings_overlay.visible      = false
	rules_overlay.visible         = false
	# show this one
	overlay.visible = true

	# bring the dimmer / layer up if you have one
	overlay_layer.visible = true

	# disable the overlay-open buttons
	for b in overlay_buttons:
		b.disabled = true

func show_settings() -> void:
	settings_overlay.visible = true
	overlay_layer.visible   = true   # make sure your dim-layer shows
	for b in overlay_buttons:
		b.disabled = true

func hide_settings() -> void:
	settings_overlay.visible = false
	overlay_layer.visible   = false
	for b in overlay_buttons:
		b.disabled = false
	
func quit_game():
	get_tree().quit()


func _on_rules_pressed() -> void:
	open_overlay(rules_overlay)
	
	
func _on_profile_pressed():
	var edit_profile_scene = load("res://scenes/edit_profile.tscn")
	var edit_profile_instance = edit_profile_scene.instantiate()

	overlay_layer.add_child(edit_profile_instance)
	overlay_layer.visible = true

	# Attendre un frame pour s'assurer que les noeuds enfants sont accessibles
	await get_tree().process_frame

	# Récupère les boutons de l'instance ajoutée
	var save_button = edit_profile_instance.get_node("EditProfilePanel/MainVertical/SaveIconButton")
	var close_button = edit_profile_instance.get_node("Close")

	# Connecte les sons si les boutons existent
	if save_button:
		save_button.mouse_entered.connect(SoundManager.play_hover_sound)
		save_button.pressed.connect(SoundManager.play_click_sound)

	if close_button:
		close_button.mouse_entered.connect(SoundManager.play_hover_sound)
		close_button.pressed.connect(SoundManager.play_click_sound)
