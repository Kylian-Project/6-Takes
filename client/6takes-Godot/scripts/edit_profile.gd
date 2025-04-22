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
	logout_button.mouse_entered.connect(SoundManager.play_hover_sound)
	logout_button.pressed.connect(SoundManager.play_click_sound)

func populate_icon_selection():
	for icon_file in ICON_FILES:
		var icon_button = Button.new()
		var texture = load(ICON_PATH + icon_file)
		
		icon_button.icon = texture  # Set the texture as the button icon
		icon_button.custom_minimum_size = Vector2(64, 64)  # Adjust size if needed
		icon_button.connect("pressed", _on_icon_selected.bind(icon_file))
		
		icon_selection.add_child(icon_button)

func _on_icon_selected(icon_name):
	selected_icon = icon_name
	player_icon.texture = load(ICON_PATH + selected_icon)

func _on_save_icon():
	print("Saving icon:", selected_icon)
	send_icon_to_database(selected_icon)

func send_icon_to_database(icon_name):
	#Implement database interaction
	print("Icon", icon_name, "sent to database")

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
