extends TabBar

func _ready() -> void:
	# Set default mode to Fullscreen
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	DisplayServer.window_set_size(Vector2i(1152, 648))  # Default resolution
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)  # Default VSync ON
	
func _on_display_option_item_selected(index: int) -> void:
	match index:
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		2:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN) 


func _on_resolution_options_item_selected(index: int) -> void:
	match index:
		0:
			DisplayServer.window_set_size(Vector2i(1920, 1080))  # Set to 1920x1080
		1:
			DisplayServer.window_set_size(Vector2i(1152, 648))  # Set to 1152x648
			



func _on_v_sync_options_2_item_selected(index: int) -> void:
	match index:
		0:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		1:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)  # Set to 1152x648
