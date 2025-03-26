extends Control

var login_scene = preload("res://logIn.tscn") # Load the login scene


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_single_player_button_pressed() -> void:
	pass # Replace with function body.


func _on_multi_player_button_pressed() -> void:
	var login_instance = login_scene.instantiate() # Create instance
	get_tree().current_scene.add_child(login_instance) # Add it to the scene
	login_instance.show_overlay() # Show the overlay


func _on_quit_button_pressed() -> void:
	pass # Replace with function body.
