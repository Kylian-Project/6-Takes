extends Control

@onready var settings_overlay = $SettingsOverlay
@onready var create_lobby_overlay = $CreateLobbyOverlay
@onready var join_lobby_overlay = $JoinLobbyOverlay

@onready var create_lobby_button = $VBoxContainer/CreateLobby
@onready var join_lobby_button = $VBoxContainer/JoinLobby
@onready var settings_button = $VBoxContainer/Settings

@onready var close_buttons = [
	$SettingsOverlay/CloseButton,
	$CreateLobbyOverlay/CloseButton,
	$JoinLobbyOverlay/CloseButton
]

func _ready():
	# Ensure all overlays are hidden at the start
	settings_overlay.visible = false
	create_lobby_overlay.visible = false
	join_lobby_overlay.visible = false

	# Connect button signals
	create_lobby_button.pressed.connect(_on_create_lobby_pressed)
	join_lobby_button.pressed.connect(_on_join_lobby_pressed)
	settings_button.pressed.connect(_on_settings_pressed)

	# Connect all close buttons
	for close_button in close_buttons:
		close_button.pressed.connect(_on_close_overlay_pressed)

# Function to open a specific overlay and hide the others
func open_overlay(overlay: Control):
	settings_overlay.visible = false
	create_lobby_overlay.visible = false
	join_lobby_overlay.visible = false
	overlay.visible = true  # Show the selected overlay

# Button functions
func _on_create_lobby_pressed():
	open_overlay(create_lobby_overlay)

func _on_join_lobby_pressed():
	open_overlay(join_lobby_overlay)

func _on_settings_pressed():
	open_overlay(settings_overlay)

# Function to close overlays
func _on_close_overlay_pressed():
	settings_overlay.visible = false
	create_lobby_overlay.visible = false
	join_lobby_overlay.visible = false
