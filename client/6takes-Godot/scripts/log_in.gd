extends Control


@onready var username_email_input = $VBoxContainer/username_email_input
@onready var password_input = $VBoxContainer/password_input
@onready var login_button = $LoginButton
@onready var http_request = $HTTPRequest_auth

var jwt_token = null
var ws = WebSocketPeer.new()
var ws_connected = false

const WS_SERVER_URL = "ws://185.155.93.105:14001"
const API_URL = "http://185.155.93.105:14001/api/player/connexion"

func _ready():
	self.visible = true
	#login_button.pressed.connect(_on_login_button_pressed)
	http_request.request_completed.connect(_on_http_request_completed)

func _on_login_button_pressed():
	var username_email = username_email_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	var password_hashed = hash_password(password)
	
	print("HASHED PASSWORD : \n", password_hashed)

	if username_email.is_empty() or password.is_empty():
		print("❌ Les champs ne peuvent pas être vides")
		return
	
	print("	PASSWORD DEBUG ", password)
	var payload = {
		"username": username_email,
		"password": password_hashed
	}

	var json_body = JSON.stringify(payload)
	var headers = ["Content-Type: application/json"]

	print("📡 Envoi de la requête HTTP de connexion à:", API_URL)
	http_request.request(API_URL, headers, HTTPClient.METHOD_POST, json_body)

func _on_http_request_completed(result, response_code, headers, body):
	print("🔁 Réponse HTTP reçue : code =", response_code)
	print("🔁 Contenu brut:", body.get_string_from_utf8())

	if response_code != 200:
		print("❌ Erreur serveur ou identifiants invalides.")
		return

	var json = JSON.parse_string(body.get_string_from_utf8())
	#if json.error != OK:
		#print("❌ Erreur JSON :", json.error_string)
		#return

	var response = json
	if "token" in response:
		jwt_token = response["token"]
		print("✅ Connexion réussie ! Token :", jwt_token)
		_connect_to_websocket()
	else:
		print("❌ Connexion échouée :", response.get("message", "Erreur inconnue"))

func _connect_to_websocket():
	if jwt_token == null:
		print("❌ Aucun token pour la connexion WebSocket")
		return

	var ws_url = WS_SERVER_URL + "?token=" + jwt_token
	print("🔌 Connexion WebSocket à :", ws_url)
	var err = ws.connect_to_url(ws_url)
	if err != OK:
		print("❌ Erreur de connexion WebSocket :", err)
		return

	print("✅ WebSocket initialisé, en attente de connexion...")
	ws_connected = false

func _process(_delta):
	if ws.get_ready_state() == WebSocketPeer.STATE_OPEN and not ws_connected:
		ws_connected = true
		print("✅ WebSocket connecté avec succès !")

	if ws.get_ready_state() in [WebSocketPeer.STATE_CLOSING, WebSocketPeer.STATE_CLOSED]:
		if ws_connected:
			ws_connected = false
			print("🔌 WebSocket déconnecté.")
	
	ws.poll()

	if ws.get_available_packet_count() > 0:
		var data = ws.get_packet().get_string_from_utf8()
		_on_ws_data(data)

func _on_ws_data(data):
	print("📩 Données reçues :", data)
	var response = JSON.parse_string(data)
	if response == null:
		print("⚠️ Donnée non-JSON :", data)
		return




var overlay_opened = false
func show_overlay():
	overlay_opened = true
	self.visible = true 
	
func hide_overlay():
	overlay_opened = false
	self.visible = false 

func _on_cancel_button_pressed() -> void:
	queue_free() 

func _move_to_multiplayer_pressed():
	get_tree().change_scene_to_file("res://scenes/multiplayer_menu.tscn")

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

#
func hash_password(password: String) -> String:
	var ctx = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(password.to_utf8_buffer())  # Convertit en buffer binaire UTF-8
	var hashed_password = ctx.finish()
	
	return hashed_password.hex_encode()  #
	
	
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
