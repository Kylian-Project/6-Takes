extends Control

@onready var username_email_input = $VBoxContainer/username_email_input
@onready var password_input = $VBoxContainer/password_input
@onready var login_button = $LoginButton
@onready var sign_up_button = $HBoxContainer/SignUp
@onready var forgot_password_button = $ForgotPassword
@onready var cancel_button = $CancelButton

@onready var http_request = $HTTPRequest_auth
@onready var visibility_button = $VBoxContainer/password_input/visibility_button

var jwt_token = null
var player_data = {}

var API_URL  
var login_timeout_timer : Timer
var request_timed_out := false

#pop Up panel 
@onready var popup_overlay = $popUp_error
@onready var popup_clear = $popUp_error/Button
@onready var popup_message = $popUp_error/message

var showing_password1 := false
const ICON_VISIBLE = preload("res://assets/images/visibility/visible.png")
const ICON_INVISIBLE = preload("res://assets/images/visibility/invisible.png")


func _ready():
	self.visible = true
	http_request.request_completed.connect(_on_http_request_completed)
	
	var base_url = Global.get_base_url()
	var base_http = Global.get_base_http()
	API_URL = base_http + base_url + "/api/player/connexion"
	
	# Soundboard
	login_button.mouse_entered.connect(SoundManager.play_hover_sound)
	login_button.pressed.connect(SoundManager.play_click_sound)
	
	sign_up_button.mouse_entered.connect(SoundManager.play_hover_sound)
	sign_up_button.pressed.connect(SoundManager.play_click_sound)

	forgot_password_button.mouse_entered.connect(SoundManager.play_hover_sound)
	forgot_password_button.pressed.connect(SoundManager.play_click_sound)

	cancel_button.mouse_entered.connect(SoundManager.play_hover_sound)
	cancel_button.pressed.connect(SoundManager.play_click_sound)
	
	# Création du timer pour le timeout login
	login_timeout_timer = Timer.new()
	login_timeout_timer.wait_time = 3.0
	login_timeout_timer.one_shot = true
	login_timeout_timer.autostart = false
	add_child(login_timeout_timer)
	login_timeout_timer.timeout.connect(_on_login_timeout)


func _on_signup_placeholder(u_name_placeholder):
	username_email_input.text = u_name_placeholder
	
func _on_login_button_pressed():
	var username_email = username_email_input.text.strip_edges()
	var password = password_input.text.strip_edges()

	
	if username_email.is_empty() or password.is_empty():
		popup_overlay.visible = true
		return
	
	# Récupérer l'ID unique de l'appareil
	var device_id = OS.get_unique_id()
	
	var payload = {
		"username": username_email,
		"password": password,
		"device_id": device_id
	}

	var json_body = JSON.stringify(payload)
	var headers = ["Content-Type: application/json"]

	print(" Envoi de la requête HTTP de connexion à:", API_URL)
	print("ID de l'appareil :", device_id)
	http_request.request(API_URL, headers, HTTPClient.METHOD_POST, json_body)
	request_timed_out = false
	login_timeout_timer.start()


func _on_http_request_completed(result, response_code, headers, body):
	if login_timeout_timer.is_stopped() == false:
		login_timeout_timer.stop()
	if request_timed_out:
		return
		
	var response_str = body.get_string_from_utf8()
	var parsed = JSON.parse_string(response_str)

	print("Réponse HTTP reçue : code =", response_code)
	print("Corps de la réponse :", response_str)

	# Vérification si la réponse est une erreur
	if response_code != 200:
		if parsed == null or response_code == 0:
			popup_message.text = "Server Connexion Error"
		else:
			# Affichage du message d'erreur retourné par le serveur
			popup_message.text = parsed.get("message", "Erreur inconnue")
		popup_overlay.visible = true
		return

	# Si le code est 200 (succès), traiter la connexion
	var json = JSON.parse_string(body.get_string_from_utf8())
	var response = json
	if "token" in response:
		jwt_token = response["token"]
		player_data = response["player"]
		print(" Connexion réussie ! ")


		var player_id = response["player"]["id"]
		var player_name = response["player"]["username"]
		var icon_id = response["player"]["icon"]

		
		Global.save_session(jwt_token, player_id, player_name, icon_id)
		_move_to_multiplayer_pressed()
	else:
		print(" Connexion échouée :", response.get("message", "Erreur inconnue"))


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
		print("❌ Erreur : Impossible de charger la scène SignUp")
		return  # Stop l'exécution ici

	var signup_instance = signup_scene.instantiate()
	
	if signup_instance == null:
		print("❌ Erreur : Impossible d'instancier la scène SignUp")
		return  # Stop l'exécution ici

	get_tree().current_scene.add_child(signup_instance)
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


func _on_visibility_button_pressed() -> void:
	showing_password1 = !showing_password1
	password_input.secret = not showing_password1
	visibility_button.icon = ICON_INVISIBLE if showing_password1 else ICON_VISIBLE

func _on_login_timeout():
	request_timed_out = true
	popup_message.text = "Server Connexion Error"
	popup_overlay.visible = true
