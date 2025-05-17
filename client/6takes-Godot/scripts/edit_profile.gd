extends Control

@onready var player_icon = $EditProfilePanel/MainVertical/HRow/PlayerIcon
@onready var icon_selection = $EditProfilePanel/MainVertical/IconSelection
@onready var save_button = $EditProfilePanel/MainVertical/SaveIconButton
@onready var close_button = $Close
@onready var user_name = $EditProfilePanel/MainVertical/HRow/UserNameLabel
@onready var logout_button = $EditProfilePanel/MainVertical/HRow/LogOutButton
@onready var user_label = $EditProfilePanel/MainVertical/HRow/UserNameLabel
@onready var http_request = $HTTPRequest
@onready var popup_label = $EditProfilePanel/SavePopupLabel
@onready var popup_timer = $EditProfilePanel/PopupTimer
@onready var popup_panel = $popupPanel

var API_URL
var player_id
var selected_icon = "dark_grey.png"  # Default icon
var current_action = ""  # Used to distinguish between "logout" and "update_icon"

const ICON_PATH = "res://assets/images/icons/"
const ICON_FILES = [
	"dark_grey.png", "blue.png", "brown.png", "green.png", 
	"orange.png", "pink.png", "purple.png", "red.png",
	"reversed.png", "cyan.png"
]

func _ready():
	http_request.request_completed.connect(_on_http_request_completed)
	populate_icon_selection()

	save_button.connect("pressed", _on_save_icon)
	close_button.pressed.connect(func(): self.queue_free())
	
	var base_url = get_node("/root/Global").get_base_url()
	var base_http = get_node("/root/Global").get_base_http()
	API_URL = base_http + base_url + "/api/player/logout"
	
	player_id = get_node("/root/Global").get_player_id()
	
	logout_button.connect("pressed", _on_log_out_button_pressed)
	logout_button.mouse_entered.connect(SoundManager.play_hover_sound)
	logout_button.pressed.connect(SoundManager.play_click_sound)
	
	popup_timer.timeout.connect(_on_popup_timer_timeout)
	
	user_name.text = get_node("/root/Global").player_name
	var icon_id = get_node("/root/Global").icon_id
	if icon_id >= 0 and icon_id < ICON_FILES.size():
		selected_icon = ICON_FILES[icon_id]
		player_icon.texture = load(ICON_PATH + selected_icon)

# Dynamically load icons
func populate_icon_selection():
	for icon_file in ICON_FILES:
		var icon_button = Button.new()
		var texture = load(ICON_PATH + icon_file)
		icon_button.icon = texture
		icon_button.custom_minimum_size = Vector2(64, 64)
		icon_button.connect("pressed", _on_icon_selected.bind(icon_file))
		icon_selection.add_child(icon_button)

# When a user clicks an icon button
func _on_icon_selected(icon_name):
	selected_icon = icon_name
	player_icon.texture = load(ICON_PATH + selected_icon)

# Handle Save
func _on_save_icon():
	print("Saving icon:", selected_icon)
	send_icon_to_database(selected_icon)

# Sends icon ID to the backend
func send_icon_to_database(icon_name):
	current_action = "update_icon"
	var icon_id = ICON_FILES.find(icon_name)

	print("DEBUG | Icon name selected:", icon_name)
	print("DEBUG | Icon ID to send:", icon_id)

	var json_body = JSON.stringify({ "icon": icon_id })
	
	var url = get_node("/root/Global").get_base_http() + get_node("/root/Global").get_base_url() + "/api/player/updateProfile"
	var token = get_node("/root/Global").get_saved_token()
	var headers = ["Authorization: Bearer " + token, "Content-Type: application/json"]

	print("Envoi de l'update à :", url)
	print("Payload :", json_body)

	http_request.request(url, headers, HTTPClient.METHOD_POST, json_body)


# Handles logout
func _on_log_out_button_pressed():
	current_action = "logout"
	get_node("/root/Global").load_session()
	var user_token = get_node("/root/Global").get_saved_token()
	var json_body = JSON.stringify(user_token)
	var headers = [get_node("/root/Global").header + user_token]

	http_request.request(API_URL, headers, HTTPClient.METHOD_POST, json_body)

# Handles all responses
func _on_http_request_completed(result, response_code, headers, body):
	print("Réponse HTTP reçue : code =", response_code)
	print("Contenu brut:", body.get_string_from_utf8())
	
	var parsed = JSON.parse_string(body.get_string_from_utf8())

	if current_action == "logout":
		if response_code == 200:
			print("Déconnexion réussie")
			Global.logged_in = false
			get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
		else:
			var popup_message = popup_label.get_node("message")
			if parsed == null or response_code == 0 :
				popup_message.text = "Server Connexion Error"
			else:
				popup_message.text = parsed["message"]
			popup_label.visible = true
			return
			
	elif current_action == "update_icon":
		if response_code == 200:

			var raw_response = body.get_string_from_utf8()
			var result_string = JSON.parse_string(raw_response)

			var new_icon_id = result_string["player"]["icon"]
			var icon_path = ICON_PATH + ICON_FILES[new_icon_id]
			player_icon.texture = load(icon_path)
			
			get_node("/root/Global").icon_id = new_icon_id
			print("Icon updated successfully!")
			show_save_popup()
		else:
			var popup_message = popup_label.get_node("message")
			if parsed == null:
				popup_message.text = "Config File Error"
			else:
				if popup_message:
					popup_message.text = parsed["message"]
			popup_label.visible = true
			print("Erreur serveur lors de la requete")

# Refresh icon in current panel
func update_profile_icon_preview():
	var new_texture = load(ICON_PATH + selected_icon)
	player_icon.texture = new_texture

func show_save_popup():
	popup_label.visible = true
	popup_timer.start()

func _on_popup_timer_timeout():
	popup_label.visible = false
