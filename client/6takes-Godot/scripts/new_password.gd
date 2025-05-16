extends Control

#pop Up panel 
@onready var popup_overlay = $popUp_error
@onready var popup_clear = $popUp_error/Button
@onready var popup_message = $popUp_error/message

#new password
@onready var new_password = $VBoxContainer/password
@onready var password_confirm = $VBoxContainer/confirmPassword
@onready var confirm_button = $confirm
@onready var pass_check = $password_check

#password input visibility
@onready var visibility_button1 = $VBoxContainer/password/visibility_button
@onready var visibility_button2 = $VBoxContainer/confirmPassword/visibility_button2
var showing_password1 := false
var showing_password2 := false
const ICON_VISIBLE = preload("res://assets/images/visibility/visible.png")
const ICON_INVISIBLE = preload("res://assets/images/visibility/invisible.png")

@onready var http_req_newpass = $HTTPRequest_newpass

var base_url
var base_http
var base_ws
var API_URL  
var RESET_SUBMIT_URL
var overlay_opened = false
var global_code 
var global_email


func _ready() -> void:
	self.visible = true
	pass_check.visible = false
	
	http_req_newpass.request_completed.connect(_on_http_request_completed)
	
	base_url = get_node("/root/Global").get_base_url()
	base_http = get_node("/root/Global").get_base_http()
	API_URL = base_http + base_url + "/api/player/password/request"
	RESET_SUBMIT_URL = base_http + base_url + "/api/player/password/reset"
	
	
func set_email(email):
	global_email = email

func set_code(sent_code):
	global_code = sent_code
	
func show_overlay():
	self.visible = true
	
func _on_confirm_pressed() -> void:
	if password_confirm.text.is_empty() or new_password.text.is_empty():
		popup_overlay.visible = true
		return 
		
	var new_password_text = new_password.text.strip_edges()
	var password_confirm_text = password_confirm.text.strip_edges()
	
	if new_password_text != password_confirm_text :
		popup_message.text = "Passwords don't match"
		popup_overlay.visible = true
		return  
	
	if !is_password_secure(new_password_text):
		popup_message.text = "Passwords not secure"
		popup_overlay.visible = true
		return  
		
	var hashed_password = new_password_text
	var payload = {
		"email": global_email,
		"code": global_code,
		"newPassword": hashed_password
	}
	print("EMAIL DEBUG", global_email)
	print("DEBUG CODE", global_code)
	var json_body = JSON.stringify(payload)
	var headers = ["Content-Type: application/json"]
	
	http_req_newpass.request(RESET_SUBMIT_URL, headers, HTTPClient.METHOD_POST, json_body)
	
	
func _on_http_request_completed(result, response_code, headers, body):
	print(" Réponse:", response_code)
	print("Contenu brut:", body.get_string_from_utf8())
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	
	if response_code == 200:
		print(" Mot de passe mis à jour. Redirection...")
		queue_free()
	else:
		if parsed == null or response_code == 0 :
			popup_message.text = "Server Connexion Error"
		else:
			popup_message.text = parsed["message"]
		popup_overlay.visible = true
		return
		
			
func hash_password(password: String) -> String:
	var ctx = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(password.to_utf8_buffer())  # Convertit en buffer binaire UTF-8
	var hashed_password = ctx.finish()
	
	return hashed_password.hex_encode()


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
	new_password.secret = not showing_password1

	visibility_button1.icon = ICON_INVISIBLE if showing_password1 else ICON_VISIBLE


func _on_visibility_button_2_pressed() -> void:
	showing_password2 = !showing_password2
	password_confirm.secret = not showing_password2

	visibility_button2.icon = ICON_INVISIBLE if showing_password2 else ICON_VISIBLE
