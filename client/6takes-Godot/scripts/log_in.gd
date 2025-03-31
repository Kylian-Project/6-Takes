extends Control

@onready var username_email_input = $VBoxContainer/username_email_input
@onready var password_input = $VBoxContainer/password_input
@onready var login_button = $LoginButton
@onready var http_request = $HTTPRequest_auth

var ws = WebSocketPeer.new()
var ws_connected = false
const SERVER_URL = "ws://185.155.93.105:14001/profile"

var overlay_opened = false
var regex = RegEx.new()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.visible = false
	login_button.pressed.connect(_on_login_button_pressed)
	#http_request.request_completed.connect(_on_request_completed)
	
	_connect_to_websocket()


func _proces():
	get_tree().paused = overlay_opened
	ws.poll() 
	
	match ws.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			if not ws_connected:
				ws_connected = true
				print(" WebSocket connecté !")
		WebSocketPeer.STATE_CLOSING, WebSocketPeer.STATE_CLOSED:
			if ws_connected:
				ws_connected = false
				print(" WebSocket déconnecté.")
				_connect_to_websocket()  # Reconnexion automatique

	if ws.get_available_packet_count() > 0:
		var data = ws.get_packet().get_string_from_utf8()
		print("Data received from WebSocket:", data)
		_on_ws_data(data)
	
func show_overlay():
	overlay_opened = true
	self.visible = true 
	
func hide_overlay():
	overlay_opened = false
	self.visible = false 

func _on_cancel_button_pressed() -> void:
	queue_free() 


func _on_sign_up_pressed() -> void:
	var signup_scene = load("res://scenes/signUp.tscn")
	if signup_scene == null:
		print("couldn't load signup scene")
		
	var signup_instance = signup_scene.instantiate() 
	if signup_instance == null :
		print("couldn't instanciate sign up scene")
	
	#queue_free()
	get_tree().current_scene.add_child(signup_instance) # Add it to the scene
	signup_instance.show_overlay()
	
	queue_free()


func _on_forgot_password_pressed() -> void:
	var forgotPass_scene = load("res://scenes/ForgotPassword.tscn")
	if forgotPass_scene == null:
		print("couldn't load scene")
	
	var forgotPass_instance = forgotPass_scene.instantiate()
	if forgotPass_instance == null :
		print("couldn't istantiate forgot pass scene ")
	
	get_tree().current_scene.add_child(forgotPass_instance)
	forgotPass_instance.show_overlay()
	
	queue_free()


func _on_login_button_pressed() -> void:
	if not ws_connected:
		print(" WebSocket n'est pas encore connecté !")
		return
		
	var body = null 
	var headers = ["Content-Type: application/json"]
	
	var password = password_input.text.strip_edges()
	var username_email = username_email_input.text.strip_edges()
	
	if username_email.is_empty() or password.is_empty():
		print(" CANNOT BE EMPTY")
		return 
	
	#detect entry type 
	var username = null
	var email = null 
	
	var res = detect_input_type(username_email)
	
	if res == "invalid":
		print("INVALID ENTRY")
		return
	else:
		if res == "email":
			email = username_email
			body = JSON.stringify({"email": email, "password": password})
			
		elif res == "username":
			username = username_email
			body = JSON.stringify({"username": username, "password": password})

	
	print(body)
	password_input.text = ""
	var error = http_request.request(SERVER_URL + "/profile", headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		print("HTTP REQUEST NOT SENT: ", error)
	
	
func _on_request_completed(result, response_code, headers, body):
	print("Réponse reçue:", response_code)
	print("Headers reçus:", headers)
	
	print(" Corps de la réponse:", body.get_string_from_utf8())
	var response = JSON.parse_string(body.get_string_from_utf8())
	if response == null:
		print(" Invalid response from server")
		return

	if response_code == 200:  # Success
		print(" Success:", response["message"])

		if "token" in response:
			var token = response["token"]
			_save_token(token)

	else:  # Error
		print(" Error:", response["message"])


#not tested yet
func _save_token(token: String):
	pass
	#var file = FileAccess.open("user://auth_token.txt", FileAccess.WRITE)
	#file.store_string(token)
	#file.close()
	#print("🔑 Token saved!")


func detect_input_type(input_text: String) -> String:
	if not regex.is_valid():
		regex.compile("")
	
	#email regex 
	regex.compile("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")
	if regex.search(input_text):
		return "email"
	
	#username regex
	regex.compile("^[a-zA-Z0-9_]+$")
	if regex.search(input_text):
		return "username"
		
	else:
		return "invalid"


func _connect_to_websocket():
	var err = ws.connect_to_url(SERVER_URL)
	if err != OK:
		print("Échec de connexion WebSocket:", err)
		return

	print("WebSocket initialisé, en attente de connexion...")
	ws_connected = false 
	
	
func _on_ws_data(data):
	print(" Données reçues :", data)

	# Vérifier si la réponse est bien du JSON
	var response = JSON.parse_string(data)
	if response == null:
		print("Réponse non JSON :", data)
		return  # Empêche le crash

	# Vérification de la connexion réussie
	if "token" in response:
		print("Connexion réussie ! Token:", response["token"])
	else:
		print(" Connexion échouée:", response.get("login", "Erreur inconnue"))
