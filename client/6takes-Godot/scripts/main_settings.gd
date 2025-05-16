extends TabBar

@onready var display_option = $HorzontalAlign/VSettings/DisplayOption
@onready var resolution_option = $HorzontalAlign/VSettings/ResolutionOptions
@onready var vsync_option = $HorzontalAlign/VSettings/VSyncOptions

func _ready() -> void:
	# Load saved settings
	SettingsManager.load_settings()
	update_ui_from_settings()

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

func update_ui_from_settings():
	var mode = DisplayServer.window_get_mode()
	var resolution = DisplayServer.window_get_size()
	var vsync = DisplayServer.window_get_vsync_mode()
	
	# Set mode index
	match mode:
		DisplayServer.WINDOW_MODE_FULLSCREEN:
			display_option.select(0)
		DisplayServer.WINDOW_MODE_WINDOWED:
			display_option.select(1)
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			display_option.select(2)

	# Set resolution index
	if resolution == Vector2i(1920, 1080):
		resolution_option.select(0)
	elif resolution == Vector2i(1152, 648):
		resolution_option.select(1)

	# Set vsync index
	if vsync == DisplayServer.VSYNC_ENABLED:
		vsync_option.select(0)
	else:
		vsync_option.select(1)
