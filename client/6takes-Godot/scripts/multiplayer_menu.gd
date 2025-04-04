extends Control

@onready var return_button = $MainButtonsBox/ReturnButton

@onready var settings_overlay = $SettingsOverlay
@onready var create_lobby_overlay = $CreateLobbyOverlay
@onready var join_lobby_overlay = $JoinLobbyOverlay
@onready var rules_overlay = $RulesOverlay

@onready var create_lobby_button = $MainButtonsBox/Create_Lobby
@onready var join_lobby_button = $MainButtonsBox/Join_Lobby
@onready var profile_button = $Profile
@onready var settings_button = $Settings
@onready var rules_button = $Rules
@onready var overlay_layer = $OverlayLayer

@onready var close_buttons = [
	$SettingsOverlay/Close,
	$CreateLobbyOverlay/Close,
	$JoinLobbyOverlay/Close,
	$RulesOverlay/Close
]

func _ready():
	return_button.pressed.connect(_on_return_pressed)
	# Ensure all overlays are hidden at the start
	settings_overlay.visible = false
	create_lobby_overlay.visible = false
	join_lobby_overlay.visible = false
	rules_overlay.visible = false

	# Connect button signals
	create_lobby_button.pressed.connect(_on_create_lobby_pressed)
	join_lobby_button.pressed.connect(_on_join_lobby_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	rules_button.pressed.connect(_on_rules_pressed)
	profile_button.pressed.connect(_on_profile_pressed)

	# Connect all close buttons
	for close_button in close_buttons:
		close_button.pressed.connect(_on_close_overlay_pressed)

func _process(_delta):
	overlay_layer.visible = overlay_layer.get_child_count() > 0

func _on_return_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")  # Change scene
# Function to open a specific overlay and hide the others
func open_overlay(overlay: Control):
	settings_overlay.visible = false
	create_lobby_overlay.visible = false
	join_lobby_overlay.visible = false
	rules_overlay.visible = false
	overlay.visible = true  # Show the selected overlay

# Button functions
func _on_create_lobby_pressed():
	open_overlay(create_lobby_overlay)

func _on_join_lobby_pressed():
	open_overlay(join_lobby_overlay)

func _on_settings_pressed():
	open_overlay(settings_overlay)
	
func _on_rules_pressed():
	open_overlay(rules_overlay)

# Function to close overlays
func _on_close_overlay_pressed():
	settings_overlay.visible = false
	create_lobby_overlay.visible = false
	join_lobby_overlay.visible = false
	rules_overlay.visible = false
	
func _on_profile_pressed():
	var edit_profile_scene = load("res://scenes/edit_profile.tscn")
	var edit_profile_instance = edit_profile_scene.instantiate()
	
	overlay_layer.add_child(edit_profile_instance)
	overlay_layer.visible = true
