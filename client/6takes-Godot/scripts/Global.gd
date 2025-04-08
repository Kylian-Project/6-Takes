extends Node

var logged_in
var saved_token 

func _ready():
	print("Script is running!")
	load_session()
	

func getLogged_in():
	return logged_in
	
func update_token(token ):
	#check_login_status()
	saved_token = token

#script to save sessions token globally (for after quit)
func save_session(token: String):
	var config = ConfigFile.new()
	config.set_value("session", "token", token)
	
	var error = config.save("user://session.cfg")
	if error != OK:
		print("error saving session")

		
#load session data from file on startup
func load_session():
	var config = ConfigFile.new()
	var error = config.load("user://session.cfg")
	if error == OK:
		saved_token = config.get_value("session", "token")
		
		print("---------DEBUG-------------")
		print("saved token ", saved_token)
		#add send token to server for validation
		print("successfully loaded session, now validating")
		return session_validation(saved_token)
	
	else:
		logged_in = false #no valid session found
		return logged_in
		
		
func session_validation(token : String):
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	http_request.request_completed.connect(_on_request_completed)
	
	var url = "http://185.155.93.105:14001/api/player/reconnect"
	var headers = ["Authorization: Bearer " + token]
	
	var json_body = JSON.stringify(token)
	print("TOKEN DEBUG AFFICHAGE \n", json_body)
	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, json_body)
	
	if error != OK:
		print("An error occurred sending the session validation request.")


func _on_request_completed(result, response_code, headers, body):
	print("Réponse HTTP reçue : code =", response_code)
	print("Contenu brut:", body.get_string_from_utf8())
	
	if response_code == 200:
		logged_in = true
		print("Session validated!")
		return logged_in
	else:
		print("Session invalid. Forcing logout.")
		logged_in = false
		return logged_in
