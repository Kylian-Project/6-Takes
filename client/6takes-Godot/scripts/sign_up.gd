extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.visible = false

func show_overlay():
	self.visible = true 
	
func hide_overlay():
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
