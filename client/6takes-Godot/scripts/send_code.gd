extends Control

@onready var http_request = $HTTPRequest
@onready var code1 = $HBoxContainer/Number1
@onready var code_fields = [
	$HBoxContainer/code1,
	$HBoxContainer/code2,
	$HBoxContainer/code3,
	$HBoxContainer/code4
]
@onready var resend_button = $VBoxContainer/ResendButton  # bouton "Receive no code?"

#pop Up panel 
@onready var popup_overlay = $popUp_error
@onready var popup_clear = $popUp_error/Button
@onready var popup_message = $popUp_error/message

var API_VERIFY_URL
var API_RESEND_URL

var code_global
var email_gloabl

func _ready() -> void:
	self.visible = true
	http_request.request_completed.connect(_on_http_request_completed)

	var base_url = get_node("/root/Global").get_base_url()
	var base_http = get_node("/root/Global").get_base_http()
	API_VERIFY_URL = base_http + base_url + "/api/player/password/verify"
	API_RESEND_URL = base_http + base_url + "/api/player/password/request"
	
	for i in code_fields.size():
		var input = code_fields[i]
		input.max_length = 1
		#input.clip_text = true
		input.select_all_on_focus = true
		input.text_changed.connect(_on_text_changed.bind(i))


func _on_text_changed(new_text: String, index: int):
	if !new_text.is_valid_int():
		code_fields[index].text = ""
	elif new_text.length() == 1 and index < code_fields.size() - 1:
		code_fields[index + 1].grab_focus()


func set_email(email):
	email_gloabl = email
	
func show_overlay():
	self.visible = true
	
func _on_enter_pressed() -> void:
	for field in code_fields:
		if field.text.is_empty():
			popup_overlay.visible = true
			return
		
	var code: String = ""
	for field in code_fields:
		code += field.text
	
	code_global = code
	
	var body = JSON.stringify({
		"email": email_gloabl,
		"code": code
	})
	var headers = ["Content-Type: application/json"]
	http_request.request(API_VERIFY_URL, headers, HTTPClient.METHOD_POST, body)


func _on_http_request_completed(result, response_code, headers, body):
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	
	if response_code == 200:
		print(" Code valide, aller à newPassword")
		var newPass_scene = load("res://scenes/newPassword.tscn")
		if newPass_scene == null:
			print("couldn't load new pass scene")
			return

		var newPass_instance = newPass_scene.instantiate()
		if newPass_instance == null :
			print("couldn't istantiate new pass scene ")
			return 

		get_tree().current_scene.add_child(newPass_instance)
		newPass_instance.show_overlay()
		newPass_instance.set_code(code_global)
		newPass_instance.set_email(email_gloabl)

		queue_free()
		
	else:
		if parsed == null or response_code == 0 :
			popup_message.text = "Server Connexion Error"
		else:
			popup_message.text = parsed["message"]
		popup_overlay.visible = true
		return


func _on_resend_code_pressed() -> void:
	print(" Renvoi du code à :", email_gloabl)

	var body = JSON.stringify({ "email": email_gloabl })
	var headers = ["Content-Type: application/json"]
	http_request.request(API_RESEND_URL, headers, HTTPClient.METHOD_POST, body)
