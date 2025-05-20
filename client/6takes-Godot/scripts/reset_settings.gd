extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$ResetButton.pressed.connect(_on_reset_button_pressed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_reset_button_pressed():
	SettingsManager.reset_to_defaults()

	# Update UI: reflect default values
	var defaults = SettingsManager.config

	# --- DISPLAY ---
	var display_mode = defaults.get_value("Default", "Mode", DisplayServer.WINDOW_MODE_FULLSCREEN)
	$TabContainer/MainSettings/HorzontalAlign/VSettings/DisplayOption.select(0) # Set to fullscreen (index 0)
	get_window().mode = Window.MODE_FULLSCREEN  # Assurer le passage en fullscreen

	var resolution = defaults.get_value("Default", "Resolution", Vector2i(1920, 1080))
	$TabContainer/MainSettings/HorzontalAlign/VSettings/ResolutionOptions.select(0) # 1920x1080
	# Pas besoin de modifier la résolution en mode fullscreen

	var vsync = defaults.get_value("Default", "VSync", DisplayServer.VSYNC_ENABLED)
	$TabContainer/MainSettings/HorzontalAlign/VSettings/VSyncOptions.select(0) # VSync enabled
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)

	# Désactiver la sélection de résolution en mode fullscreen
	$TabContainer/MainSettings/HorzontalAlign/VSettings/ResolutionOptions.disabled = true
	
	# Enregistrer explicitement les réglages par défaut dans la section Display pour qu'ils persistent aux changements de scène
	SettingsManager.save_display_settings(Window.MODE_FULLSCREEN, Vector2i(1920, 1080), DisplayServer.VSYNC_ENABLED)

	# --- AUDIO ---
	for i in range(3):
		var vol = defaults.get_value("Default", "Bus" + str(i), 0.5)
		AudioServer.set_bus_volume_db(i, linear_to_db(vol))

		match i:
			0: $TabContainer/AudioSettings/HorizontalAlign/VSettings/MsterSlider.value = vol
			1: $TabContainer/AudioSettings/HorizontalAlign/VSettings/MusicSlider.value = vol
			2: $TabContainer/AudioSettings/HorizontalAlign/VSettings/SFXSlider.value = vol
	
	# --- SERVER ---
	# Réinitialiser la section Server uniquement si l'utilisateur N'EST PAS connecté
	if not get_node("/root/Global").logged_in:
		if defaults.has_section("Server"):
			defaults.erase_section("Server")
			defaults.save("user://settings.cfg")

		# Mettre à jour l'UI serveur avec les valeurs par défaut
		$TabContainer/ServerSettings/HorizontalAlign/VSettings/PresetOptionButton.select(0)
		$TabContainer/ServerSettings/HorizontalAlign/VSettings/LineEditSrvURL.text = "localhost"
		$TabContainer/ServerSettings/HorizontalAlign/VSettings/LineEditSrvPORT.value = 80
		$TabContainer/ServerSettings/HorizontalAlign/VSettings/HTTPOption.select(0)
		$TabContainer/ServerSettings/HorizontalAlign/VSettings/LineEditSrvURL.editable = false
		$TabContainer/ServerSettings/HorizontalAlign/VSettings/LineEditSrvPORT.editable = false
		$TabContainer/ServerSettings/HorizontalAlign/VSettings/HTTPOption.disabled = true
