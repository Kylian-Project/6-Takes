extends Control

func _ready() -> void:
	self.visible = false  # Cache la fenêtre au démarrage
	settings_menu.visible = false  # Cache aussi le menu settings

func _on_close_button_pressed() -> void:
	self.visible = false  # Masque la fenêtre pause
	


func _on_cancel_button_pressed() -> void:
	self.visible = false 

func _on_settings_button_pressed() -> void:
	settings_menu.visible = true  # Affiche le menu des paramètres

func _on_settings_close_button_pressed() -> void:
	settings_menu.visible = false  # Cache le menu des paramètres quand on le ferme
