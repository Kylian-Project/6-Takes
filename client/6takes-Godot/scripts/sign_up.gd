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

const WS_SERVER_URL = "ws://185.155.93.105:14001"
const API_URL = "http://185.155.93.105:14001/api/player/inscription"


func _ready():
	self.visible = false
	signup_button.pressed.connect(_on_signup_pressed)
	http_request.request_completed.connect(_on_http_request_completed)


func hash_password(password: String) -> String:
	var ctx = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(password.to_utf8_buffer())  # Convertit en buffer binaire UTF-8
	var hashed_password = ctx.finish()
	
	return hashed_password.hex_encode()
	
	
func _on_signup_pressed():
	var username = username_input.text.strip_edges()
	var email = email_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	var password_confirm = confirmPassword_input.text.strip_edges()
#
	if username.is_empty() or password.is_empty() or email.is_empty():# or password_confirm.is_empty():
		print("Fill in all fields")
		return
#	
	if password != password_confirm:
		print("passwords don't match")
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

	if response_code != 200:
		print(" Erreur serveur ou identifiants invalides.")
		return

	var json = JSON.parse_string(body.get_string_from_utf8())
	if json.error != OK:
		print(" Erreur JSON :", json.error_string)
		return

	var response = json
	if "token" in response:
		jwt_token = response["token"]
		print("✅ Connexion réussie ! Token :", jwt_token)
		_connect_to_websocket()
		_move_to_multiplayer_pressed()
		
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
