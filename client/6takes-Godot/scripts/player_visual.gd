extends Control
class_name Player

# --- Server related variables
var jwt_token = null
var ws = WebSocketPeer.new()
var ws_connected = false
var API_URL

# --- External Data (Need to fecth from server)
var player_id: int
var username: String
var icon_id: int

# --- Game Logic (Fetched from lobby/server)
var cards: Array = []
var selected_card = null
var is_ready: bool = false

# --- Node References
@onready var icon_texture: TextureRect = $Icon
@onready var name_label = $PlayerName
@onready var ready_panel = $ReadyCheck
@onready var http_request: HTTPRequest = $HTTPRequest

#players icons
const ICON_PATH = "res://assets/images/icons/"
const ICON_FILES = [
	"dark_grey.png", "blue.png", "brown.png", "green.png", 
	"orange.png", "pink.png", "purple.png", "red.png",
	"reversed.png", "cyan.png", "bot.png"
]

# Constants
const MAX_CARDS := 10

func _ready():
	var base_url = get_node("/root/Global").get_base_url()
	var base_http = get_node("/root/Global").get_base_http()
	API_URL = base_http + base_url + "/api/player/playerinfo"
	
	#tsester
	#name_label.text = ""
	#update_visuals()
	ready_panel.visible = false 
	# Begin fetching player info
	#_fetch_player_info()

func setup_player(id: int, uname: String, icon: int):#, initial_cards: Array):
	player_id = id
	username = uname
	icon_id = icon

		
func select_card(card):
	if is_ready:
		return
	if card in cards:
		selected_card = card
		# Can add trigger ato UI update or animation
		print("Card selected:", card)

func _fetch_player_info():
	var token = Global.get_saved_token()
	var headers = [Global.header + token]
	var json_body = JSON.stringify({})  # Empty payload if needed

	var err = http_request.request(API_URL, headers, HTTPClient.METHOD_GET, json_body)
	if err != OK:
		print("Error sending request to playerinfo:", err)
		
func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	print("Response Code:", response_code)
	
	if response_code == 200:
		var json = body.get_string_from_utf8()
		var parsed = JSON.parse_string(json)
		
		if parsed:
			_set_player_info(parsed)
		else:
			print("Failed to parse JSON.")
	else:
		print("Server error. Code:", response_code)

func _set_player_info(data: Dictionary):
	player_id = data.get("id", 0)
	username = data.get("username", 1)
	icon_id = data.get("icon_id", 2)

	print("Player Data Set:", player_id, username, icon_id)

	#update_visuals()

func on_round_resolved():
	if is_ready and selected_card:
		cards = cards.filter(func(c): return c["id"] != selected_card["id"])
		selected_card = null
		is_ready = false
		ready_panel.visible = false
		print(" Card removed after round")

func create_player_visual(uname: String, icon_id: int, is_me := false) -> Control:
	var visual = self
	visual.get_node("PlayerName").text = uname
	var icon_path
	
	icon_path = ICON_PATH + ICON_FILES[clamp(icon_id, 0, ICON_FILES.size() - 1)]
		
	visual.get_node("Icon").texture = load(icon_path)

	if is_me:
		visual.add_theme_color_override("font_color", Color(1, 1, 0)) 
	return visual

func update_username(new_name: String) -> void:
	var visual = self
	visual.get_node("PlayerName").text = new_name  # Replace `$NameLabel` with the actual label path
