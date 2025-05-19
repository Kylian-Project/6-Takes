extends Node

var logged_in = false
var saved_token 
var player_id
var player_name = ""
var icon_id = 0
var rankings: Array = []   
var ban_info = {
	"banned": false,
	"timeLeft": 0
}

var config = ConfigFile.new()
var file_path = "res://config/config.cfg"
var response_load = config.load(file_path)

var BASE_URL := ""
var BASE_HTTP := ""
var header := ""
@onready var popup_scene = preload("res://scenes/popUp.tscn")

var game_settings = {}
var game_players: Array = []

var icons = {
	# NOTE: optimize using preload or load() caching if performance not good.
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

func _ready():
	if response_load != OK:
		print("Config error load result: ", response_load)
		if response_load == 7:
			print("Config file not found Error")
			var popup_instance = popup_scene.instantiate()
			var label = popup_instance.get_node("message")
			
			if label:
				label.text = "Config File missing"
				await get_tree().create_timer(0.1).timeout
				get_tree().current_scene.add_child(popup_instance)

				popup_instance.make_visible()
			else:
				print("can't get message label in pop up scene ")
				return 
		return 
	
	# --- Gestion des settings serveur ---
	var settings_cfg = ConfigFile.new()
	var preset_idx = 0
	var srv_port = ""
	var header_prefix = ""
	if settings_cfg.load("user://settings.cfg") == OK:
		preset_idx = settings_cfg.get_value("Server", "Preset", 0)
	else:
		preset_idx = 0

	if preset_idx == 2:
		# Custom
		BASE_URL = settings_cfg.get_value("Server", "SRV_URL", "localhost")
		BASE_HTTP = ("https://" if settings_cfg.get_value("Server", "HTTP_IDX", 0) == 0 else "http://")
		srv_port = settings_cfg.get_value("Server", "SRV_PORT", "14001")
	else:
		var section = ("DEFAULT" if preset_idx == 0 else "BASTION")
		BASE_URL = config.get_value(section, "SRV_URL", "")
		BASE_HTTP = config.get_value(section, "SRV_HTTP", "https://")
		srv_port = config.get_value(section, "SRV_PORT", "")

	header_prefix = config.get_value("DEFAULT", "AUTH_HEADER_PREFIX", "Bearer")
	header = "Authorization: " + header_prefix + " "
	if srv_port != "":
		BASE_URL = BASE_URL + ":" + srv_port

	print("BASE URL ", BASE_URL)

	
# Server Info GET
func get_base_url():
	return BASE_URL 
func get_base_http():
	return BASE_HTTP
	
# Server Info SET
func set_base_url(url):
	BASE_URL = url
func set_base_http(http):
	BASE_HTTP = http

func getLogged_in():
	return logged_in
	
func get_player_id():
	return player_id
	
func get_saved_token():
	return saved_token

func save_session(token: String, uid, uname, icon):
	#var config = ConfigFile.new()
	config.set_value("session", "token", token)
	config.set_value("user", "uid", uid)
	config.set_value("user", "username", uname)
	config.set_value("user", "icon", icon)
	
	var error = config.save("user://session.cfg")
	if error != OK:
		print("error saving session")

	saved_token = token
	player_id = uid
	player_name = uname
	icon_id = icon

	logged_in = true

#load session data from file on startup
func load_session():
	#var config = ConfigFile.new()
	var error = config.load("user://session.cfg")
	if error == OK:
		saved_token = config.get_value("session", "token")		
		print("successfully loaded session, now validating")
		if saved_token != "" and saved_token != null:
			print("successfully loaded session, now validating")
			session_validation(saved_token)
		else:
			print("No session token found")
			logged_in = false
			return
	
	else:
		logged_in = false #no valid session found
		
		
func session_validation(token : String):
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	http_request.request_completed.connect(_on_request_completed)

	var headers = ["Authorization: Bearer " + token]
	var json_body = JSON.stringify(token)
	
	var url = BASE_HTTP + BASE_URL + "/api/player/reconnect"
	print("\n url debug ", url)
	var error = http_request.request(url , headers, HTTPClient.METHOD_POST, json_body)
	
	if error != OK:
		print("An error occurred sending the session validation request.")


func _on_request_completed(_result, response_code, _headers, body):
	print("Réponse HTTP reçue : code =", response_code)
	
	var raw_response = body.get_string_from_utf8()
	var result_string = JSON.parse_string(raw_response)

	
	if response_code == 200:
		logged_in = true
		#var data = result_string.result
		var playerIid = result_string["player"]["id"]
		player_name = result_string["player"]["username"]
		icon_id = result_string["player"]["icon"]
		player_id =  playerIid
		
		save_session(saved_token, player_id, player_name, icon_id)
		print("Session validated!")
		
	else:
		print("Session invalid. Forcing logout.")
		logged_in = false

func issue_ban(player_id):
	print("[INFO] Tentative de bannissement du joueur avec l'ID :", player_id)
	var http_request = HTTPRequest.new()
	add_child(http_request)

	var url = BASE_HTTP + BASE_URL + "/api/player/ban-status/" + str(player_id)
	var error = http_request.request(url, [], HTTPClient.METHOD_POST)

	if error != OK:
		print("[ERREUR] Erreur lors de l'envoi de la requête de bannissement :", error)
	else:
		print("[INFO] Requête de bannissement envoyée avec succès pour le joueur ID :", player_id)

func update_ban_info(banned: bool, time_left: int):
	ban_info["banned"] = banned
	ban_info["timeLeft"] = time_left
	print("Ban info updated: ", ban_info)

func is_banned():
	return ban_info.get("banned", false)

func get_ban_time_left():
	return ban_info.get("timeLeft", 0)
