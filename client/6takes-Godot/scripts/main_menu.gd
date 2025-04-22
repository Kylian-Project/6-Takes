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


@onready var close_buttons = [
	$SettingsOverlay/Close
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
	settings_button.pressed.connect(_on_settings_pressed)
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
		close_button.pressed.connect(_on_close_overlay_pressed)
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
		singleplayer_button.text ="Single Player"
		multiplayer_button.text = "Multi-Player"
		

func _process(_delta):
	overlay_layer.visible = overlay_layer.get_child_count() > 0

func _on_multi_player_button_pressed() -> void:
	get_node("/root/Global").load_session()
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
	settings_overlay.visible = false
	overlay.visible = true

func _on_settings_pressed():
	open_overlay(settings_overlay)

func _on_close_overlay_pressed():
	settings_overlay.visible = false

	
func quit_game():
	get_tree().quit()


func _on_rules_pressed() -> void:
	rules_overlay.visible = true
	
func _on_profile_pressed():
	var edit_profile_scene = load("res://scenes/edit_profile.tscn")
	var edit_profile_instance = edit_profile_scene.instantiate()
	
	overlay_layer.add_child(edit_profile_instance)
	overlay_layer.visible = true
