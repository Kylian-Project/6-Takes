extends TabBar

func _ready() -> void:
	# Load saved settings
	SettingsManager.load_settings()

func _on_display_option_item_selected(index: int) -> void:
	match index:
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		2:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

	# Save selection
	SettingsManager.save_display_settings(DisplayServer.window_get_mode(), DisplayServer.window_get_size(), DisplayServer.window_get_vsync_mode())

func _on_resolution_options_item_selected(index: int) -> void:
	var resolution = Vector2i(1920, 1080) if index == 0 else Vector2i(1152, 648)
	DisplayServer.window_set_size(resolution)

	# Save selection
	SettingsManager.save_display_settings(DisplayServer.window_get_mode(), resolution, DisplayServer.window_get_vsync_mode())

func _on_v_sync_options_2_item_selected(index: int) -> void:
	var vsync_mode = DisplayServer.VSYNC_ENABLED if index == 0 else DisplayServer.VSYNC_DISABLED
	DisplayServer.window_set_vsync_mode(vsync_mode)

	# Save selection
	SettingsManager.save_display_settings(DisplayServer.window_get_mode(), DisplayServer.window_get_size(), vsync_mode)
