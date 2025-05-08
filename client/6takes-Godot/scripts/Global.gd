extends Node

var logged_in = false
var saved_token 
var player_id
var player_name = ""
var icon_id = 0

var config = ConfigFile.new()
var file_path = "res://config/config.cfg"
var response_load = config.load(file_path)

var BASE_URL := ""
var BASE_HTTP := ""
var WS_PREFIX := ""
var header := ""
@onready var popup_scene = preload("res://scenes/popUp.tscn")

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
		
	var srv_url = config.get_value("DEFAULT", "SRV_URL", "")
	var srv_http = config.get_value("DEFAULT", "SRV_HTTP", "")
	var srv_port = config.get_value("DEFAULT", "SRV_PORT", "")	
	var ws_prefix = config.get_value("DEFAULT", "WS_PREFIX", "")
	var header_prefix =config.get_value("DEFAULT", "AUTH_HEADER_PREFIX", "")
	
	header = "Authorization: " + header_prefix +" "
	# si un port est spécifié, on l'ajoute à l'url
	if srv_port != "":
		srv_url = srv_url + ":" + srv_port
	
	BASE_URL = srv_url
	BASE_HTTP = srv_http
	WS_PREFIX = ws_prefix
	print("BASE URL ", BASE_URL)

	
# Server Info GET
func get_base_url():
	return BASE_URL 
func get_base_http():
	return BASE_HTTP
func get_ws_prefix():
	return WS_PREFIX
	
# Server Info SET
func set_base_url(url):
	BASE_URL = url
func set_base_http(http):
	BASE_HTTP = http
func set_ws_prefix(prefix):
	WS_PREFIX = prefix

func getLogged_in():
	return logged_in
	
func get_player_id():
	return player_id
	
func get_saved_token():
	return saved_token

func set_logged_in(state):
	logged_in = state

func save_session(token: String, uid, uname, icon):
	#var config = ConfigFile.new()
	config.set_value("session", "token", token)
	config.set_value("user", "uid", uid)
	config.set_value("user", "username", uname)
	config.set_value("user", "icon", icon)
	
	var error = config.save("user://session.cfg")
	if error != OK:
		print("error saving session")

	player_id = uid
	player_name = uname
	icon_id = icon

#load session data from file on startup
func load_session():
	#var config = ConfigFile.new()
	var error = config.load("user://session.cfg")
	if error == OK:
		saved_token = config.get_value("session", "token")		
		print("successfully loaded session, now validating")
		session_validation(saved_token)
	
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


func _on_request_completed(result, response_code, headers, body):
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
