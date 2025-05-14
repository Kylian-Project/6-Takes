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

var API_URL
var request_timeout_timer : Timer
var request_timed_out := false
var username_placeholder

#new password
@onready var new_password = $VBoxContainer/password
@onready var password_confirm = $VBoxContainer/confirmPassword
@onready var confirm_button = $signup
@onready var pass_check = $password_check 

#pop Up panel 
@onready var popup_overlay = $popUp_error
@onready var popup_clear = $popUp_error/Button
@onready var popup_message = $popUp_error/message
@onready var notif_label = $SavePopupLabel

#password input visibility
@onready var visibility_button1 = $VBoxContainer/password/visibility_button
@onready var visibility_button2 = $VBoxContainer/confirmPassword/visibility_button2

var showing_password1 := false
var showing_password2 := false
const ICON_VISIBLE = preload("res://assets/images/visibility/visible.png")
const ICON_INVISIBLE = preload("res://assets/images/visibility/invisible.png")

var login_scene = preload("res://scenes/logIn.tscn")
signal account_created(uname : String)

func _ready():
	self.visible = false
	signup_button.pressed.connect(_on_signup_pressed)
	http_request.request_completed.connect(_on_http_request_completed)
	
	var base_url = Global.get_base_url()
	var base_http = Global.get_base_http()
	API_URL = base_http + base_url + "/api/player/inscription"

	request_timeout_timer = Timer.new()
	request_timeout_timer.wait_time = 3.0
	request_timeout_timer.one_shot = true
	request_timeout_timer.autostart = false
	add_child(request_timeout_timer)
	request_timeout_timer.timeout.connect(_on_request_timeout)
	
func _on_signup_pressed():
	var username = username_input.text.strip_edges()
	var email = email_input.text.strip_edges() 
	
	if !is_valid_email(email):
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
	

	var payload = {
		"username": username,
		"email": email,
		"password": password #password
	}
	username_placeholder = username

	var json_body = JSON.stringify(payload)
	var headers = ["Content-Type: application/json"]

	print(" Envoi de la requête HTTP de connexion à:", API_URL)
	http_request.request(API_URL, headers, HTTPClient.METHOD_POST, json_body)
	request_timed_out = false
	request_timeout_timer.start()


func _on_http_request_completed(result, response_code, headers, body):
	if request_timeout_timer.is_stopped() == false:
		request_timeout_timer.stop()
	if request_timed_out:
		return
		
	var response_str = body.get_string_from_utf8()
	var parsed = JSON.parse_string(response_str)
	
	print(" Réponse HTTP reçue : code =", response_code)
	print(" Contenu brut:", response_str)

	if response_code != 200:
		if parsed == null or response_code == 0 :
			popup_message.text = "Server Connexion Error"
		else:
			popup_message.text = parsed["message"]
		popup_overlay.visible = true
		return
		
	##sign up successefuls
	notif_label.visible = true
	await get_tree().create_timer(2).timeout
	notif_label.visible = false
	
	self.hide_overlay()
	self._on_log_in_pressed()
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


func _on_password_text_changed(new_text: String) -> void:
	var is_secure = is_password_secure(new_text)
	var color := Color.RED
	if is_secure:
		color = Color.BLACK
	new_password.add_theme_color_override("font_color", color)
	
	
func is_password_secure(password: String) -> bool:
	if password.length() < 8:
		pass_check.text = "Password must be at least 8 characters long"
		pass_check.visible = true
		return false

	var has_upper := false
	var has_lower := false
	var has_digit := false
	var has_special := false

	for c in password:
		if c >= "A" and c <= "Z":
			has_upper = true
		elif c >= "a" and c <= "z":
			has_lower = true
		elif c >= "0" and c <= "9":
			has_digit = true
		elif "!@#$%^&*()-_=+[]{};:,.<>?/\\|".contains(c):
			has_special = true

	if not has_upper:
		pass_check.text = "Missing an uppercase letter (A-Z)"
	elif not has_lower:
		pass_check.text = "Missing a lowercase letter (a-z)"
	elif not has_digit:
		pass_check.text = "Missing a number (0-9)"
	elif not has_special:
		pass_check.text = "Missing a special character (!@#...)"
	else:
		pass_check.visible = false
		return true

	pass_check.visible = true
	return false
	
	
func _on_visibility_button_pressed() -> void:
	showing_password1 = !showing_password1
	password_input.secret = not showing_password1
	visibility_button1.icon = ICON_INVISIBLE if showing_password1 else ICON_VISIBLE


func _on_visibility_button_2_pressed() -> void:
	showing_password2 = !showing_password2
	password_confirm.secret = not showing_password2
	visibility_button2.icon = ICON_INVISIBLE if showing_password2 else ICON_VISIBLE


func _on_request_timeout():
	request_timed_out = true
	popup_message.text = "Server Connexion Error"
	popup_overlay.visible = true
