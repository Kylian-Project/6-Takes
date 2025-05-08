extends Control

@onready var pause_overlay = $PauseOverlay
@onready var settings_overlay = $SettingsOverlay

@onready var resume_button = $PauseOverlay/VBoxContainer/resume
@onready var settings_button = $PauseOverlay/VBoxContainer/settings
@onready var leave_button = $PauseOverlay/VBoxContainer/leave
@onready var close_button = $SettingsOverlay/Close

var id_lobby
var username
var is_host

func _ready():
	# Connect buttons
	resume_button.pressed.connect(_on_resume_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	leave_button.pressed.connect(_on_leave_pressed)
	close_button.pressed.connect(_on_close_settings_pressed)
	
	# Show pause overlay by default
	pause_overlay.visible = true
	settings_overlay.visible = false
	
	id_lobby = GameState.id_lobby
	is_host = GameState.is_host
	username = Global.player_name
	

func _on_resume_pressed():
	visible = false  # Hide the entire Screenpause overlay

func _on_settings_pressed():
	pause_overlay.visible = false
	settings_overlay.visible = true

func _on_close_settings_pressed():
	settings_overlay.visible = false
	pause_overlay.visible = true

func _on_leave_pressed():
	if is_host:
		SocketManager.emit("leave-room", { "roomId": id_lobby })
	get_tree().change_scene_to_file("res://scenes/multiplayer_menu.tscn")
