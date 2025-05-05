extends Control

@onready var pause_overlay = $PauseOverlay
@onready var settings_overlay = $SettingsOverlay

@onready var resume_button = $PauseOverlay/VBoxContainer/resume
@onready var settings_button = $PauseOverlay/VBoxContainer/settings
@onready var leave_button = $PauseOverlay/VBoxContainer/leave
@onready var close_button = $SettingsOverlay/Close

# Référence au gameboard (à assigner depuis gameboardSP)
var game_board : Node = null

func _ready():
	# Connect buttons
	resume_button.pressed.connect(_on_resume_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	leave_button.pressed.connect(_on_leave_pressed)
	close_button.pressed.connect(_on_close_settings_pressed)
	
	# Initial visibility
	pause_overlay.visible = true
	settings_overlay.visible = false

func setup(game_board_ref: Node):
	game_board = game_board_ref

func _on_resume_pressed():
	if game_board:
		game_board.start_timer()  # Redémarre le timer
	queue_free()  # Supprime l'écran de pause

func _on_settings_pressed():
	pause_overlay.visible = false
	settings_overlay.visible = true

func _on_close_settings_pressed():
	settings_overlay.visible = false
	pause_overlay.visible = true

func _on_leave_pressed():
	if game_board:
		game_board.stop_timer()  # Arrête le timer proprement
	get_tree().change_scene_to_file("res://scenes/SPLobbyScene.tscn")
