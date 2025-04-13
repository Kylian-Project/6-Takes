extends Control

@onready var username_input = $VBoxContainer/username
@onready var email_input = $VBoxContainer/email
@onready var password_input = $VBoxContainer/password
@onready var confirmPassword_input = $VBoxContainer/confirmPassword
@onready var signup_button = $signup
@onready var http_request = $HTTPRequest_auth

var jwt_token = null
var ws = WebSocketPeer.new()
var ws_connected = false

var WS_SERVER_URL
var API_URL

#new password
@onready var new_password = $VBoxContainer/password
@onready var password_confirm = $VBoxContainer/confirmPassword
@onready var confirm_button = $signup

#pop Up panel 
@onready var popup_overlay = $popUp_error
@onready var popup_clear = $popUp_error/Button
@onready var popup_message = $popUp_error/message


func _ready():
	self.visible = false
	signup_button.pressed.connect(_on_signup_pressed)
	http_request.request_completed.connect(_on_http_request_completed)
	
	var base_url = get_node("/root/Global").get_base_url()
	API_URL = "http://" + base_url + "/api/player/inscription"
	WS_SERVER_URL = "ws://" + base_url


func hash_password(password: String) -> String:
	var ctx = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(password.to_utf8_buffer())  # Convertit en buffer binaire UTF-8
	var hashed_password = ctx.finish()
	
	return hashed_password.hex_encode()
	
	
func _on_signup_pressed():
	var username = username_input.text.strip_edges()
	var email = email_input.text.strip_edges() 
	
	if is_valid_email(email_input):
		print("Valid email")
	else:
		popup_message.text = "Invalid Email"
		popup_overlay.visible = true
		return 

	var password = password_input.text.strip_edges()
	var password_confirm = confirmPassword_input.text.strip_edges()
#
	if username.is_empty() or password.is_empty() or email.is_empty() or password_confirm.is_empty():
		popup_overlay.visible = true
		return
#	
	if password != password_confirm :
		popup_message.text = "Passwords don't match"
		popup_overlay.visible = true
		return 
	
	var hashed_password = hash_password(password)
	
	var payload = {
		"username": username,
		"email": email,
		"password": hashed_password #password
	}

	var json_body = JSON.stringify(payload)
	var headers = ["Content-Type: application/json"]

	print(" Envoi de la requête HTTP de connexion à:", API_URL)
	http_request.request(API_URL, headers, HTTPClient.METHOD_POST, json_body)


func _on_http_request_completed(result, response_code, headers, body):
	print(" Réponse HTTP reçue : code =", response_code)
	print(" Contenu brut:", body.get_string_from_utf8())
	var response

	if response_code != 200:
		print(" Erreur serveur ou identifiants invalides.")
		return
	else:
		var json = JSON.parse_string(body.get_string_from_utf8())
		response = json
		self.hide_overlay()
		self._on_log_in_pressed()
		return

	print(" Connexion échouée :", response.get("message", "Erreur inconnue"))


func _connect_to_websocket():
	if jwt_token == null:
		print(" Aucun token pour la connexion WebSocket")
		return

	var ws_url = WS_SERVER_URL + "/?token=" + jwt_token
	var err = ws.connect_to_url(ws_url)
	if err != OK:
		print("!! Erreur de connexion WebSocket :", err)
		return

	print(" WebSocket initialisé, en attente de connexion...")
	ws_connected = false


func _process(_delta):
	if ws.get_ready_state() == WebSocketPeer.STATE_OPEN and not ws_connected:
		ws_connected = true
		print(" WebSocket connecté avec succès !")

	if ws.get_ready_state() in [WebSocketPeer.STATE_CLOSING, WebSocketPeer.STATE_CLOSED]:
		if ws_connected:
			ws_connected = false
			print("WebSocket déconnecté.")
	
	ws.poll()

	if ws.get_available_packet_count() > 0:
		var data = ws.get_packet().get_string_from_utf8()
		_on_ws_data(data)

func _on_ws_data(data):
	print(" Données reçues :", data)
	var response = JSON.parse_string(data)
	if response == null:
		print(" Donnée non-JSON :", data)
		return


var overlay_opened = false
func _proces():
	get_tree().paused = overlay_opened
	
func show_overlay():
	overlay_opened = true
	self.visible = true 
	
func hide_overlay():
	overlay_opened = false
	self.visible = false 
	
func _on_log_in_pressed() -> void:
	var login_scene = load("res://scenes/logIn.tscn")
	if login_scene == null:
		print("couldn't load scene")
		
	var login_instance = login_scene.instantiate()
	if login_instance== null :
		print("couldn't instanciate scene ")
	
	#queue_free()
	get_tree().current_scene.add_child(login_instance)
	login_instance.show_overlay()
	
	queue_free()


func _on_cancel_button_pressed() -> void:
	queue_free() 


func _move_to_multiplayer_pressed():
	get_tree().change_scene_to_file("res://scenes/multiplayer_menu.tscn")


func is_valid_email(email: String) -> bool:
	var regex = RegEx.new()
	var pattern = r"^[\w\.-]+@[\w\.-]+\.\w{2,}$"
	var error = regex.compile(pattern)
	if error != OK:
		print("Regex compile error!")
		return false
	return regex.search(email) != null
