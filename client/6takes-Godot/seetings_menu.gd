extends PanelContainer

@onready var main_button = $Control/HBoxContainer/MainSettings
@onready var audio_button = $Control/HBoxContainer2/AudioSettings

func _ready():
	# Initialisation : Main Settings actif, Audio Settings inactif
	_set_active_button(main_button, true)
	_set_active_button(audio_button, false)

	# Connecter les boutons
	main_button.pressed.connect(_on_main_button_pressed)
	audio_button.pressed.connect(_on_audio_button_pressed)

# Fonction pour gérer l'affichage du bouton actif/inactif
func _set_active_button(button: Button, is_active: bool):
	var normal_style = StyleBoxFlat.new()
	normal_style.content_margin_left = 30   # Bordure gauche
	normal_style.content_margin_right = 30  # Bordure droite
	if is_active:
		normal_style.bg_color = Color(0, 0, 0, 0)  # Transparent
		button.add_theme_color_override("font_color", Color(1, 1, 1))  # Texte blanc
	else:
		normal_style.bg_color = Color(1, 1, 1)  # Blanc
		button.add_theme_color_override("font_color", Color(0, 0, 0))  # Texte noir
	
	button.add_theme_stylebox_override("normal", normal_style)

# Quand Main Settings est pressé
func _on_main_button_pressed():
	_set_active_button(main_button, true)
	_set_active_button(audio_button, false)

# Quand Audio Settings est pressé
func _on_audio_button_pressed():
	_set_active_button(main_button, false)
	_set_active_button(audio_button, true)
