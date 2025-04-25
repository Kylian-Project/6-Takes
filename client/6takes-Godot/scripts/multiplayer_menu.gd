extends Control

@onready var return_button = $MainButtonsBox/ReturnButton
@onready var socket_io: SocketIO = $SocketIO
@onready var settings_overlay = $SettingsOverlay
@onready var create_lobby_overlay = $CreateLobbyOverlay
@onready var join_lobby_overlay = $JoinLobbyOverlay
@onready var rules_overlay = $RulesOverlay
@onready var overlay_layer = $OverlayLayer

@onready var create_lobby_button = $MainButtonsBox/Create_Lobby
@onready var join_lobby_button = $MainButtonsBox/Join_Lobby
@onready var settings_button = $Settings
@onready var profile_button = $Profile
@onready var rules_button = $Rules
@onready var profile = $Profile

@onready var close_buttons = [
	$SettingsOverlay/Close,
	$CreateLobbyOverlay/Close,
	$JoinLobbyOverlay/Close,
	$RulesOverlay/Close
]
#var client = $SocketIO
var BASE_URL 

func _ready():
	return_button.pressed.connect(_on_return_pressed)
	
	##connect to socket
	#BASE_URL = get_node("/root/Global").get_base_url()
	#BASE_URL = "http://" + BASE_URL
	#client.base_url = BASE_URL
	#client.connect_socket()
	#client.event_received.connect(_on_socket_io_event_received)
	
	# Ensure all overlays are hidden at the start
	settings_overlay.visible = false
	create_lobby_overlay.visible = false
	join_lobby_overlay.visible = false
	rules_overlay.visible = false
	profile.pressed.connect(_on_profile_pressed)


	# Connect button signals
	create_lobby_button.pressed.connect(_on_create_lobby_pressed)
	join_lobby_button.pressed.connect(_on_join_lobby_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	rules_button.pressed.connect(_on_rules_pressed)
	profile_button.pressed.connect(_on_profile_pressed)

		# Hover Soundboard
	create_lobby_button.mouse_entered.connect(SoundManager.play_hover_sound)
	join_lobby_button.mouse_entered.connect(SoundManager.play_hover_sound)
	return_button.mouse_entered.connect(SoundManager.play_hover_sound)
	settings_button.mouse_entered.connect(SoundManager.play_hover_sound)
	rules_button.mouse_entered.connect(SoundManager.play_hover_sound)
	profile_button.mouse_entered.connect(SoundManager.play_hover_sound)

	# Click Soundboard
	create_lobby_button.pressed.connect(SoundManager.play_click_sound)
	join_lobby_button.pressed.connect(SoundManager.play_click_sound)
	return_button.pressed.connect(SoundManager.play_click_sound)
	settings_button.pressed.connect(SoundManager.play_click_sound)
	rules_button.pressed.connect(SoundManager.play_click_sound)
	profile_button.pressed.connect(SoundManager.play_click_sound)


	# Connect all close buttons
	for close_button in close_buttons:
		close_button.pressed.connect(_on_close_overlay_pressed)
		close_button.mouse_entered.connect(SoundManager.play_hover_sound)
		close_button.pressed.connect(SoundManager.play_click_sound)
		
		
func _process(_delta):
	overlay_layer.visible = overlay_layer.get_child_count() > 0
	
	
func _on_socket_io_event_received(event: String, data: Variant, ns: String) -> void:
	print("SocketIO event received: name=", event, " --- data = ", data, " --- namespace = ", ns)
	
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
	#client.connect_socket()
	#client.emit("available-rooms", {})
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
	
	# Attendre un frame pour s'assurer que les enfants sont accessibles
	await get_tree().process_frame

	# Récupère les boutons de l'instance ajoutée
	var save_button = edit_profile_instance.get_node("EditProfilePanel/MainVertical/SaveIconButton")
	var close_button = edit_profile_instance.get_node("Close")
	
	if save_button:
		save_button.mouse_entered.connect(SoundManager.play_hover_sound)
		save_button.pressed.connect(SoundManager.play_click_sound)

	if close_button:
		close_button.mouse_entered.connect(SoundManager.play_hover_sound)
		close_button.pressed.connect(SoundManager.play_click_sound)
