extends Node

signal profile_fetched  # <--- Add this signal

var logged_in = false
var saved_token 
var player_id
var player_name = ""
var icon_id = 0

var config = ConfigFile.new()
var file_path = "res://config/config.cfg"
var response_load = config.load(file_path)

var BASE_URL := ""
var header := ""

var icons = {
	0: "res://assets/images/icons/dark_grey.png",
	1: "res://assets/images/icons/blue.png",
	2: "res://assets/images/icons/brown.png",
	3: "res://assets/images/icons/cyan.png",
	4: "res://assets/images/icons/pink.png",
	5: "res://assets/images/icons/green.png",
	6: "res://assets/images/icons/orange.png",
	7: "res://assets/images/icons/purple.png",
	8: "res://assets/images/icons/red.png",
	9: "res://assets/images/icons/reversed.png",
}

@onready var http_request = HTTPRequest.new()

func _ready():
	if response_load != OK:
		print("Config error load result: ", response_load)
		return 
	
	var srv_url = config.get_value("DEFAULT", "SRV_URL", "")
	var srv_port = config.get_value("DEFAULT", "SRV_PORT", "")	
	var header_prefix = config.get_value("DEFAULT", "AUTH_HEADER_PREFIX", "")
	
	header = "Authorization: " + header_prefix + " "
	BASE_URL = srv_url + ":" + srv_port 
	
	print("BASE URL ", BASE_URL)
	print("Header ", header)

	add_child(http_request)  # Attach HTTPRequest node
	http_request.request_completed.connect(_on_request_completed)

func get_base_url(): return BASE_URL
func getLogged_in(): return logged_in
func get_player_id(): return player_id
func get_saved_token(): return saved_token
func get_player_name(): return player_name
func get_icon_id(): return icon_id
func set_logged_in(state): logged_in = state

# Save session to file
func save_session(token: String):
	var config = ConfigFile.new()
	config.set_value("session", "token", token)
	var error = config.save("user://session.cfg")
	if error != OK:
		print("error saving session")

# Load session on startup
func load_session():
	var config = ConfigFile.new()
	var error = config.load("user://session.cfg")
	if error == OK:
		saved_token = config.get_value("session", "token")		
		print("successfully loaded session, now validating")
		session_validation(saved_token)
	else:
		logged_in = false # no session found

func session_validation(token: String):
	var headers = ["Authorization: Bearer " + token]
	var json_body = JSON.stringify(token)
	var url = "http://" + BASE_URL + "/api/player/reconnect"
	print("\nValidating session with URL: ", url)
	http_request.request(url, headers, HTTPClient.METHOD_POST, json_body)

# Fetch the current profile
func fetch_user_profile():
	var url = "http://" + BASE_URL + "/api/player/me"
	var headers = ["Authorization: Bearer " + saved_token]
	print("Fetching profile from:", url)
	http_request.request(url, headers)

# Handle responses for session validation and profile fetching
func _on_request_completed(result, response_code, headers, body):
	print("HTTP Response Code:", response_code)
	print("Raw Body:", body.get_string_from_utf8())

	var raw_response = body.get_string_from_utf8()
	var result_string = JSON.parse_string(raw_response)

	if response_code == 200:
		if result_string.has("player"):
			var player_data = result_string["player"]
			player_id = player_data["id"]
			player_name = player_data["name"]
			icon_id = int(player_data["icon"])
			print("Fetched profile:", player_name, "Icon ID:", icon_id)
			emit_signal("profile_fetched")
		else:
			logged_in = true
			player_id = result_string["player"]["id"]
			print("Session validated!")
	else:
		print("Invalid session or fetch failed")
		logged_in = false
