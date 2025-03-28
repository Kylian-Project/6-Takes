extends Control

var login_scene = preload("res://scenes/logIn.tscn") # Load the login scene

@onready var rules = get_node("rules")

func _ready() -> void:
	pass
	

func _on_single_player_button_pressed() -> void:
	pass # Replace with function body.


func _on_multi_player_button_pressed() -> void:
	var login_instance = login_scene.instantiate() # Create instance
	get_tree().current_scene.add_child(login_instance) # Add it to the scene
	login_instance.show_overlay() # Show the overlay


func _on_quit_button_pressed() -> void:
	pass # Replace with function body.


func _on_rules_button_pressed() -> void:
	#rules.visible = true
	#get_tree().paused = true
	var rules_scene = load("res://scenes/rules.tscn")
	var rules_instance = rules_scene.instantiate()
	get_tree().current_scene.add_child(rules_instance)
	


func _on_cancel_button_pressed() -> void:
	queue_free()
	#rules.visible = false
	#get_tree().paused = false
