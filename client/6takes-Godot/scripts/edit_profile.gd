extends Control

@onready var player_icon = $EditProfilePanel/MainVertical/HRow/PlayerIcon
@onready var icon_selection = $EditProfilePanel/MainVertical/IconSelection
@onready var save_button = $EditProfilePanel/MainVertical/SaveIconButton
@onready var close_button = $Close
@onready var logout_button = $EditProfilePanel/MainVertical/HRow/LogOutButton

@onready var http_request = $HTTPRequest
var API_URL
var WS_SERVER_URL
var player_id

const ICON_PATH = "res://assets/images/icons/"
const ICON_FILES = [
	"dark_grey.png", "blue.png", "brown.png", "green.png", 
	"orange.png", "pink.png", "purple.png", "red.png",
	"reversed.png", "cyan.png"
]

var selected_icon = "dark_grey.png"  # Default icon
var selected_icon_id = 0  # Default icon ID

func _ready():
	http_request.request_completed.connect(_on_http_request_completed)

	populate_icon_selection()
	save_button.connect("pressed", _on_save_icon)
	close_button.pressed.connect(func():
		self.queue_free()
	)
	
	var base_url = get_node("/root/Global").get_base_url()
	API_URL = "http://" + base_url + "/api/player/logout"
	WS_SERVER_URL = "ws://" + base_url
	
	player_id = get_node("/root/Global").get_player_id()
	print("player id debug", player_id)
	logout_button.connect("pressed", _on_log_out_button_pressed)

func populate_icon_selection():
	var global = get_node("/root/Global")
	
	for icon_id in global.icons.keys():
		var icon_button = Button.new()
		var texture = load(global.icons[icon_id])
		
		icon_button.icon = texture
		icon_button.custom_minimum_size = Vector2(64, 64)
		icon_button.connect("pressed", _on_icon_selected.bind(global.icons[icon_id]))  # Still binding filename for lookup
		
		icon_selection.add_child(icon_button)

func _on_icon_selected(icon_name):
	var global = get_node("/root/Global")
	
	for id in global.icons.keys():
		if global.icons[id].ends_with(icon_name):
			selected_icon_id = id
			player_icon.texture = load(global.icons[id])
			break

func _on_save_icon():
	print("Saving icon ID:", selected_icon_id)
	send_icon_to_database(selected_icon_id)

func send_icon_to_database(icon_id):
	var global = get_node("/root/Global")
	var player_id = global.get_player_id()
	var user_token = global.get_saved_token()
	
	var edit_icon_url = "http://" + global.get_base_url() + "/api/player/editIcon"
	var payload = {"player_id": player_id, "icon_id": icon_id}
	var json_body = JSON.stringify(payload)
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + user_token]
	
	print("Sending icon update to:", edit_icon_url)
	http_request.request(edit_icon_url, headers, HTTPClient.METHOD_POST, json_body)


func _on_close_pressed():
	self.queue_free()


func _on_log_out_button_pressed() -> void:
	#var payload = {player_id}
	get_node("/root/Global").load_session()
	var user_token = get_node("/root/Global").get_saved_token()
	var json_body = JSON.stringify(user_token)
	print("JSON BODY LOG OUT ", json_body)
	
	#var headers = ["Content-Type: application/json"]
	var headers = ["Authorization: Bearer " + user_token]
	
	print(" Envoi de la requête HTTP de connexion à:", API_URL)
	http_request.request(API_URL, headers, HTTPClient.METHOD_POST, json_body)


func _on_http_request_completed(result, response_code, headers, body):
	print("Réponse HTTP reçue : code =", response_code)
	print("Contenu brut:", body.get_string_from_utf8())

	if response_code != 200:
		print(" Erreur serveur ou identifiants invalides.")
		return 
	
	print("User disconnected successefully")
	get_node("/root/Global").set_logged_in(false)
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	return
