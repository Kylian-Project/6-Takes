extends Control

@onready var rules = preload("res://scenes/rules.tscn")
@onready var login_scene = preload("res://scenes/logIn.tscn")

@onready var rules_overlay = $rules

var login_instance = null
var rules_instance = null 


func _ready() -> void:
	rules_overlay.visible = false


func _on_multi_player_button_pressed() -> void:
	if login_instance == null:
		login_instance = login_scene.instantiate()
		add_child(login_instance)

		# Centrer l'écran de pause
		await get_tree().process_frame  
		
	login_instance.move_to_front()  # S'assurer que l'écran de pause est tout en haut
	login_instance.visible = true  # Afficher la pause
	


func _on_cancel_button_pressed() -> void:
	rules_overlay.visible = false


func _on_button_pressed() -> void:
	rules_overlay.visible = true
