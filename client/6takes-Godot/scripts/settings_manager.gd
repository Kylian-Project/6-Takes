extends Node

var config = ConfigFile.new()
const FILE_PATH = "user://settings.cfg"
var native_resolution = Vector2i(0, 0)
var currently_transitioning = false

func _ready():
	native_resolution = DisplayServer.screen_get_size()
	
	if not FileAccess.file_exists(FILE_PATH):
		write_default_settings()
	load_settings()
	
	# Connect to window size changed signal
	get_window().size_changed.connect(_on_window_size_changed)
	
	# Connect to scene change signals
	get_tree().root.connect("ready", _on_scene_ready)

# Called when a new scene becomes active/ready
func _on_scene_ready():
	# Reload settings after a scene change to ensure consistency
	if not currently_transitioning:
		currently_transitioning = true
		call_deferred("reapply_display_settings")

# Reapply current display settings from config
func reapply_display_settings():
	var err = config.load(FILE_PATH)
	if err != OK:
		print("No settings file found when reapplying display settings")
		currently_transitioning = false
		return
	
	var display_mode = config.get_value("Display", "Mode", config.get_value("Default", "Mode", DisplayServer.WINDOW_MODE_FULLSCREEN))
	var resolution = config.get_value("Display", "Resolution", config.get_value("Default", "Resolution", Vector2i(1920, 1080)))
	var vsync = config.get_value("Display", "VSync", config.get_value("Default", "VSync", DisplayServer.VSYNC_ENABLED))
	
	# Apply settings directly without using apply_display_settings to avoid animations or transitions
	var window = get_window()
	
	print("Reapplying display settings after scene change: mode=", display_mode, ", res=", resolution)
	
	if display_mode == Window.MODE_FULLSCREEN:
		window.mode = Window.MODE_FULLSCREEN
	elif display_mode == Window.MODE_EXCLUSIVE_FULLSCREEN:
		window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
	elif display_mode == Window.MODE_MAXIMIZED || resolution == native_resolution:
		window.mode = Window.MODE_MAXIMIZED
	else:
		window.mode = Window.MODE_WINDOWED
		DisplayServer.window_set_size(resolution)
		
		# Center the window
		var screen_size = DisplayServer.screen_get_size()
		var window_position = Vector2i((screen_size.x - resolution.x) / 2, (screen_size.y - resolution.y) / 2)
		DisplayServer.window_set_position(window_position)
	
	DisplayServer.window_set_vsync_mode(vsync)
	
	# Wait a frame to make sure everything is applied
	await get_tree().process_frame
	currently_transitioning = false
	notify_window_settings_changed()

# Load settings from the config file
func load_settings():
	var err = config.load(FILE_PATH)
	if err != OK:
		print("No settings file found, using defaults.")
		return

	# Load Display settings with fallback to Default
	var display_mode = config.get_value("Display", "Mode", config.get_value("Default", "Mode", DisplayServer.WINDOW_MODE_FULLSCREEN))
	var resolution = config.get_value("Display", "Resolution", config.get_value("Default", "Resolution", Vector2i(1920, 1080)))
	var vsync = config.get_value("Display", "VSync", config.get_value("Default", "VSync", DisplayServer.VSYNC_ENABLED))

	apply_display_settings(display_mode, resolution, vsync)

	# Load and apply Audio settings with fallback to Default
	for i in range(3):  # Buses: Master (0), Music (1), SFX (2)
		var volume = config.get_value("Audio", "Bus" + str(i), config.get_value("Default", "Bus" + str(i), 0.5))
		AudioServer.set_bus_volume_db(i, linear_to_db(volume))

# Apply display settings with proper window mode handling
func apply_display_settings(mode, resolution, vsync):
	var window = get_window()
	var current_mode = window.mode
	
	print("Applying display settings: mode=", mode, ", res=", resolution, ", vsync=", vsync, ", current_mode=", current_mode)
	
	# Handle different window modes with better transitions
	if mode == Window.MODE_FULLSCREEN:
		# For fullscreen, set mode directly without changing resolution first
		print("Setting FULLSCREEN mode")
		window.mode = Window.MODE_FULLSCREEN
	elif mode == Window.MODE_EXCLUSIVE_FULLSCREEN:
		# For borderless fullscreen, set mode directly
		print("Setting EXCLUSIVE_FULLSCREEN mode")
		window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
	elif resolution == native_resolution || mode == Window.MODE_MAXIMIZED:
		# For native resolution, maximize the window
		print("Setting MAXIMIZED mode (native resolution)")
		window.mode = Window.MODE_MAXIMIZED
	else:
		# Only reset size if we're not already in windowed mode
		# or if the resolution is different
		if current_mode != Window.MODE_WINDOWED || DisplayServer.window_get_size() != resolution:
			if current_mode != Window.MODE_WINDOWED:
				# Set windowed mode first, then resize
				print("Switching to WINDOWED mode before resizing")
				window.mode = Window.MODE_WINDOWED
				await get_tree().process_frame  # Wait a frame before resizing
			
			# Apply the resolution
			print("Setting resolution to ", resolution)
			DisplayServer.window_set_size(resolution)
			
			# Center the window
			var screen_size = DisplayServer.screen_get_size()
			var window_position = Vector2i((screen_size.x - resolution.x) / 2, (screen_size.y - resolution.y) / 2)
			print("Centering window at position ", window_position)
			DisplayServer.window_set_position(window_position)
		else:
			print("Already in windowed mode with correct resolution")
		
	# Apply vsync last
	print("Setting VSync to ", vsync)
	DisplayServer.window_set_vsync_mode(vsync)
	
	# Log final state
	print("Final window mode: ", get_window().mode, ", resolution: ", DisplayServer.window_get_size())

# Save display settings
func save_display_settings(mode, resolution, vsync):
	config.set_value("Display", "Mode", mode)
	config.set_value("Display", "Resolution", resolution)
	config.set_value("Display", "VSync", vsync)
	config.save(FILE_PATH)

# Save audio settings
func save_audio_settings(idx, volume):
	config.set_value("Audio", "Bus" + str(idx), volume)
	config.save(FILE_PATH)

# Save server settings
func save_server_settings(preset, url, port, http_idx):
	config.set_value("Server", "Preset", preset)
	config.set_value("Server", "SRV_URL", url)
	config.set_value("Server", "SRV_PORT", port)
	config.set_value("Server", "HTTP_IDX", http_idx)
	config.save(FILE_PATH)

func write_default_settings():
	if not config.has_section("Default"):
		config.set_value("Default", "Mode", DisplayServer.WINDOW_MODE_FULLSCREEN)
		config.set_value("Default", "Resolution", Vector2i(1920, 1080))
		config.set_value("Default", "VSync", DisplayServer.VSYNC_ENABLED)
		for i in range(3):
			config.set_value("Default", "Bus" + str(i), 0.5)
		config.save(FILE_PATH)


func reset_to_defaults():
	# Clear Display and Audio sections (if they exist)
	if config.has_section("Display"):
		config.erase_section("Display")
	if config.has_section("Audio"):
		config.erase_section("Audio")
	config.save(FILE_PATH)
	load_settings()
	
func _on_window_size_changed():
	# Skip if we're currently transitioning between scenes
	if currently_transitioning:
		return
		
	# Check current window state
	var window = get_window()
	var current_mode = window.mode
	var current_size = DisplayServer.window_get_size()

	# Handle window state changes
	if current_mode == Window.MODE_MAXIMIZED:
		# User maximized the window manually - update settings to native resolution
		save_display_settings(current_mode, native_resolution, DisplayServer.window_get_vsync_mode())
	elif current_mode == Window.MODE_WINDOWED and current_size != Vector2i(1920, 1080) and current_size != Vector2i(1152, 648):
		# If window size changes to a non-standard resolution in windowed mode
		save_display_settings(current_mode, current_size, DisplayServer.window_get_vsync_mode())
	
	# Always notify UI to update
	notify_window_settings_changed()

func get_native_resolution():
	return native_resolution
	
# Signal to notify UI components about display settings changes
signal display_settings_changed

func notify_window_settings_changed():
	emit_signal("display_settings_changed")
