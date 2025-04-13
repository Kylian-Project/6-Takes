extends Control

#pop Up panel 
@onready var popup_overlay = $popUp_error
@onready var popup_clear = $popUp_error/Button
@onready var popup_message = $popUp_error/message

#new password
@onready var new_password = $VBoxContainer/password
@onready var password_confirm = $VBoxContainer/confirmPassword
@onready var confirm_button = $confirm

@onready var http_req_newpass = $HTTPRequest_newpass

var WS_SERVER_URL 
var base_url
var API_URL  
var RESET_SUBMIT_URL
var overlay_opened = false
var global_code 
var global_email


func _ready() -> void:
	self.visible = false
	
	http_req_newpass.request_completed.connect(_on_http_request_completed)
	
	base_url = get_node("/root/Global").get_base_url()
	API_URL = "http://" + base_url + "/api/player/password/request"
	RESET_SUBMIT_URL = "http://" + base_url + "/api/player/password/reset"
	WS_SERVER_URL = "ws://" + base_url
	
	
func set_email(email):
	global_email = email

func set_code(sent_code):
	global_code = sent_code
	
func show_overlay():
	self.visible = true
	
func _on_confirm_pressed() -> void:
	if new_password.text.strip_edges() != password_confirm.text.strip_edges() :
		popup_message.text = "Passwords don't match"
		popup_overlay.visible = true
		return  
		
	var hashed_password = hash_password(new_password.text)
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

	if response_code == 200:
		print(" Mot de passe mis à jour. Redirection...")
		queue_free()
	else:
		print("Code invalide ou expiré.")
		
			
func hash_password(password: String) -> String:
	var ctx = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(password.to_utf8_buffer())  # Convertit en buffer binaire UTF-8
	var hashed_password = ctx.finish()
	
	return hashed_password.hex_encode()
