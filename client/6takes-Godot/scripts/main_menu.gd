extends Control

@onready var rules = preload("res://scenes/rules.tscn")
@onready var login_scene = preload("res://scenes/logIn.tscn")

@onready var settings_overlay = $SettingsOverlay
@onready var settings_button = $SettingsButton
@onready var rules_overlay = $RulesOverlay
@onready var singleplayer_button = $VButtons/SinglePlayerButton
@onready var quit_button = $VButtons/QuitButton
@onready var multiplayer_button = $VButtons/MultiPlayerButton

@onready var close_buttons = [
	$SettingsOverlay/Close
]

#validate token 
const API_URL = "http://185.155.93.105:14001/api/player/connexion"

var login_instance = null
var rules_instance = null 
var logged_in 

func _ready() -> void:
	rules_overlay.visible = false
	settings_overlay.visible = false
	singleplayer_button.pressed.connect(go_to_singleplayer)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(quit_game)
	for close_button in close_buttons:
		close_button.pressed.connect(_on_close_overlay_pressed)
		
	#get_node("/root/Global").check_login_status()
	get_node("/root/Global").load_session()
	logged_in = get_node("/root/Global").getLogged_in()
	
	if logged_in == false:
		singleplayer_button.text ="Play As A Guest"
		multiplayer_button.text = "Log In"
	else :
		singleplayer_button.text ="Single Player"
		multiplayer_button.text = "Multi-Player"


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
