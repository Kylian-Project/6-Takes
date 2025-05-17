extends Node

var config = ConfigFile.new()
const FILE_PATH = "user://settings.cfg"

func _ready():
	if not FileAccess.file_exists(FILE_PATH):
		write_default_settings()
	load_settings()

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

	DisplayServer.window_set_mode(display_mode)
	DisplayServer.window_set_size(resolution)
	DisplayServer.window_set_vsync_mode(vsync)

	# Load and apply Audio settings with fallback to Default
	for i in range(3):  # Buses: Master (0), Music (1), SFX (2)
		var volume = config.get_value("Audio", "Bus" + str(i), config.get_value("Default", "Bus" + str(i), 0.5))
		AudioServer.set_bus_volume_db(i, linear_to_db(volume))


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
