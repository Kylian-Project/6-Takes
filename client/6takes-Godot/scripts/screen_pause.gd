extends Control

@onready var pause_overlay = $PauseOverlay
@onready var settings_overlay = $SettingsOverlay

@onready var resume_button = $PauseOverlay/VBoxContainer/resume
@onready var settings_button = $PauseOverlay/VBoxContainer/settings
@onready var leave_button = $PauseOverlay/VBoxContainer/leave
@onready var close_button = $SettingsOverlay/Close
@onready var confirm_panel = $ConfirmControl

var id_lobby
var username
var is_host
var scene :Node = null

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
	
	confirm_panel.connect("confirmed", Callable(self, "_on_confirmed"))
	confirm_panel.connect("canceled",  Callable(self, "_on_canceled"))

	

func _on_resume_pressed():
	visible = false  # Hide the entire Screenpause overlay

func _on_settings_pressed():
	pause_overlay.visible = false
	settings_overlay.visible = true

func _on_close_settings_pressed():
	settings_overlay.visible = false
	pause_overlay.visible = true

func _on_leave_pressed():
	#if is_host:
	confirm_panel.action_type = "quit"
	confirm_panel.message = "\n Are you sure you want to leave the game ?"
	confirm_panel.action_payload = { "username": Global.player_name }
	
	#confirm_panel.set_anchors_preset(Control.PRESET_CENTER)
	#confirm_panel.set_size(Vector2(1920, 250))
	
	confirm_panel.show_panel()


func _on_confirmed(action_type:String, payload) -> void:
	if !GameState.is_host:
		SocketManager.emit("leave-room-in-game", { "roomId": id_lobby, "username": Global.player_name })
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	else:
		SocketManager.emit("leave-room", { "roomId": id_lobby })
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	#match action_type:
		#"quit":
			#if !GameState.is_host:
				#SocketManager.emit("leave-room-in-game", { "roomId": id_lobby, "username": Global.player_name })
				#get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
			#else:
				#SocketManager.emit("leave-room", { "roomId": id_lobby })


func _on_canceled():
	pass
