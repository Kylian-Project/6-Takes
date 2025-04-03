extends Control

func _ready() -> void:
	self.visible = false  # Cache la fenêtre au démarrage

func _on_close_button_pressed() -> void:
	self.visible = false  # Masque la fenêtre pause


func _on_cancel_button_pressed() -> void:
	self.visible = false 
