extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.visible = false

func show_overlay():
	self.visible = true 
	
func hide_overlay():
	self.visible = false 
	

func _on_cancel_button_pressed() -> void:
	queue_free() 


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
	
