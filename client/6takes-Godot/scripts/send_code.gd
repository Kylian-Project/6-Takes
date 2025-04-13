extends Control

@onready var http_request = $HTTPRequest
@onready var code1 = $HBoxContainer/Number1
@onready var code2 = $HBoxContainer/Number2
@onready var code3 = $HBoxContainer/Number3
@onready var code4 = $HBoxContainer/Number4
@onready var resend_button = $VBoxContainer/ResendButton  # bouton "Receive no code?"


var API_VERIFY_URL
var API_RESEND_URL

var code_global
var email_gloabl

func _ready() -> void:
	self.visible = true
	http_request.request_completed.connect(_on_http_request_completed)

	var base_url = get_node("/root/Global").get_base_url()
	API_VERIFY_URL = "http://" + base_url + "/api/player/password/verify"
	API_RESEND_URL = "http://" + base_url + "/api/player/password/request"


func set_email(email):
	email_gloabl = email
	
func show_overlay():
	self.visible = true
	
func _on_enter_pressed() -> void:
	var code = code1.text + code2.text + code3.text + code4.text
	code_global = code
	
	if code.length() != 4:
		print(" Code incomplet")
		return
	
	print("GLOBAL EMAIL ------------", email_gloabl)
	var body = JSON.stringify({
		"email": email_gloabl,
		"code": code
	})
	var headers = ["Content-Type: application/json"]
	http_request.request(API_VERIFY_URL, headers, HTTPClient.METHOD_POST, body)


func _on_http_request_completed(result, response_code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	if response_code == 200:# and json["valid"] == true:
		print("✅ Code valide, aller à newPassword")
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
		print("❌ Erreur : ", json.get("message", "Code incorrect"))


func _on_resend_code_pressed() -> void:
	print(" Renvoi du code à :", email_gloabl)

	var body = JSON.stringify({ "email": email_gloabl })
	var headers = ["Content-Type: application/json"]
	http_request.request(API_RESEND_URL, headers, HTTPClient.METHOD_POST, body)
