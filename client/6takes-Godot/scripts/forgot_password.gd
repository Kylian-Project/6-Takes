extends Control

#send code
@onready var email = $email
@onready var send_code_button = $sendCode

#pop Up panel 
@onready var popup_overlay = $popUp_error
@onready var popup_clear = $popUp_error/Button
@onready var popup_message = $popUp_error/message

@onready var cancel_button = $Control/CancelButton
@onready var cancel = $Cancel

@onready var http_request = $HTTPRequest


var WS_SERVER_URL 
var base_url
var base_http
var API_URL  
var RESET_SUBMIT_URL
var overlay_opened = false
var code 
var email_text
	 
func _ready() -> void:
	self.visible = false
	
	if http_request:
		http_request.request_completed.connect(_on_http_request_completed)
	
	base_url = get_node("/root/Global").get_base_url()
	base_http = get_node("/root/Global").get_base_http()
	API_URL = base_http + base_url + "/api/player/password/request"
	RESET_SUBMIT_URL = base_http + base_url + "/api/player/password/reset"
	WS_SERVER_URL = "ws://" + base_url
	
	# Sons pour hover + clic
	cancel_button.mouse_entered.connect(SoundManager.play_hover_sound)
	cancel_button.pressed.connect(SoundManager.play_click_sound)

	cancel.mouse_entered.connect(SoundManager.play_hover_sound)
	cancel.pressed.connect(SoundManager.play_click_sound)

	send_code_button.mouse_entered.connect(SoundManager.play_hover_sound)
	send_code_button.pressed.connect(SoundManager.play_click_sound)



func set_code(sent_code):
	code = sent_code
	
func show_overlay():
	overlay_opened = true
	self.visible = true 
	
func hide_overlay():
	overlay_opened = false
	self.visible = false 

func _on_cancel_pressed() -> void:
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


func _on_send_code_pressed() -> void:
	email_text = email.text.strip_edges()
	
	if email_text.is_empty():
		popup_overlay.visible = true 
		return 
	
	if !is_valid_email(email_text):
		popup_message.text = "Invalid Email"
		popup_overlay.visible = true
		return 
		
	var payload = { "email": email_text }
	var json_body = JSON.stringify(payload)
	var headers = ["Content-Type: application/json"]

	print(" Envoi de requête de reset à :", API_URL)
	http_request.request(API_URL, headers, HTTPClient.METHOD_POST, json_body)
	
	
func _on_http_request_completed(result, response_code, headers, body):
	var response_str = body.get_string_from_utf8()
	var parsed = JSON.parse_string(response_str)
	
	print("Réponse HTTP reçue : code =", response_code)
	print("Contenu brut:", body.get_string_from_utf8())

	if response_code != 200:
		popup_message.text = parsed["message"]
		popup_overlay.visible = true
		return
		
	var sendCode_scene = load("res://scenes/sendCode.tscn")
	if sendCode_scene == null:
		print("couldn't load scene")
		return 
		
	var sendCode_instance = sendCode_scene.instantiate()
	if sendCode_instance== null :
		print("couldn't instanciate scene ")
		return 
	
	#queue_free()
	get_tree().current_scene.add_child(sendCode_instance)
	sendCode_instance.show_overlay()
	sendCode_instance.set_email(email_text)
	
	queue_free()


func is_valid_email(email: String) -> bool:
	var regex = RegEx.new()
	var pattern = r"^[\w\.-]+@[\w\.-]+\.\w{2,}$"
	var error = regex.compile(pattern)
	if error != OK:
		print("Regex compile error!")
		return false
	return regex.search(email) != null
