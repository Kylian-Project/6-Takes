extends Node

var logged_in = false
var saved_token 
var player_id

var config = ConfigFile.new()
var file_path = "res://config/config.cfg"
var response_load = config.load(file_path)

var BASE_URL := ""
var header := ""

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
		return 
		
	var srv_url = config.get_value("DEFAULT", "SRV_URL", "")
	var srv_port = config.get_value("DEFAULT", "SRV_PORT", "")	
	var header_prefix =config.get_value("DEFAULT", "AUTH_HEADER_PREFIX", "")
	
	header = "Authorization: " + header_prefix +" "
	BASE_URL = srv_url + ":" + srv_port 
	print("BASE URL ", BASE_URL)
	load_session()
	
	
func get_base_url():
	return BASE_URL 
	
func getLogged_in():
	return logged_in
	
func get_player_id():
	return player_id
	
func get_saved_token():
	return saved_token

func set_logged_in(state):
	logged_in = state
#script to save sessions token globally (for after quit)
func save_session(token: String):
	var config = ConfigFile.new()
	config.set_value("session", "token", token)
	#config.set_value("user", "email", email)
	
	var error = config.save("user://session.cfg")
	if error != OK:
		print("error saving session")

		
#load session data from file on startup
func load_session():
	var config = ConfigFile.new()
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

	var headers = [header+ token]
	var json_body = JSON.stringify(token)
	
	var url = "http://" + BASE_URL+ "/api/player/reconnect"
	var error = http_request.request(url , headers, HTTPClient.METHOD_POST, json_body)
	
	if error != OK:
		print("An error occurred sending the session validation request.")


func _on_request_completed(result, response_code, headers, body):
	print("Réponse HTTP reçue : code =", response_code)
	print("Contenu brut:", body.get_string_from_utf8())
	
	var raw_response = body.get_string_from_utf8()
	var result_string = JSON.parse_string(raw_response)
	
	if response_code == 200:
		logged_in = true
		#var data = result_string.result
		var playerIid = result_string["player"]["id"]
		player_id =  playerIid
		print("Session validated!")
		
	else:
		print("Session invalid. Forcing logout.")
		logged_in = false
		
