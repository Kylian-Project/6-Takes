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
	var display_mode = defaults.get_value("Default", "Mode", 0)
	$TabContainer/MainSettings/HorzontalAlign/VSettings/DisplayOption.select(display_mode)
	DisplayServer.window_set_mode(display_mode)

	var resolution = defaults.get_value("Default", "Resolution", Vector2i(1920, 1080))
	$TabContainer/MainSettings/HorzontalAlign/VSettings/ResolutionOptions.select((0 if resolution == Vector2i(1920, 1080) else 1))
	DisplayServer.window_set_size(resolution)

	var vsync = defaults.get_value("Default", "VSync", 1)
	$TabContainer/MainSettings/HorzontalAlign/VSettings/VSyncOptions.select((0 if vsync == DisplayServer.VSYNC_ENABLED else 1))
	DisplayServer.window_set_vsync_mode(vsync)

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
