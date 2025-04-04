extends Control

#send code
@onready var email = $email
@onready var send_code_button = $sendCode

#new password
@onready var new_password = $VBoxContainer/password
@onready var password_confirm = $VBoxContainer/confirmPassword
@onready var confirm_button = $confirm

#pop Up panel 
@onready var popup_overlay = $popUp_error
@onready var popup_clear = $popUp_error/Button
@onready var popup_message = $popUp_error/message

var overlay_opened = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.visible = false

func _proces():
	get_tree().paused = overlay_opened
	
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
	if email.text.is_empty():
		popup_overlay.visible = true 
		return 
	else:
		
		var sendCode_scene = load("res://scenes/sendCode.tscn")
		if sendCode_scene == null:
			print("couldn't load scene")
			
		var sendCode_instance = sendCode_scene.instantiate()
		if sendCode_instance== null :
			print("couldn't instanciate scene ")
		
		#queue_free()
		get_tree().current_scene.add_child(sendCode_instance)
		sendCode_instance.show_overlay()
		
		queue_free()


func _on_enter_pressed() -> void:
	var newPass_scene = load("res://scenes/newPassword.tscn")
	if newPass_scene == null:
		print("couldn't load new pass scene")
	
	var newPass_instance = newPass_scene.instantiate()
	if newPass_instance == null :
		print("couldn't istantiate new pass scene ")
	
	get_tree().current_scene.add_child(newPass_instance)
	newPass_instance.show_overlay()
	
	queue_free()


func _on_resend_code_pressed() -> void:
	var forgotPass_scene = load("res://scenes/ForgotPassword.tscn")
	if forgotPass_scene == null:
		print("couldn't load scene")
	
	var forgotPass_instance = forgotPass_scene.instantiate()
	if forgotPass_instance == null :
		print("couldn't istantiate forgot pass scene ")
	
	get_tree().current_scene.add_child(forgotPass_instance)
	forgotPass_instance.show_overlay()
	
	queue_free()


func _on_confirm_pressed() -> void:
	if new_password.text.strip_edges() == password_confirm.text.strip_edges() :
		_on_cancel_pressed()
	else:
		popup_message.text = "Passwords don't match"
		popup_overlay.visible = true
		return  
