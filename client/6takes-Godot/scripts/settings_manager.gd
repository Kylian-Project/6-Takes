extends Node

var config = ConfigFile.new()
const FILE_PATH = "user://settings.cfg"

func _ready():
	load_settings()

# Load settings from the config file
func load_settings():
	var err = config.load(FILE_PATH)
	if err != OK:
		print("No settings file found, using defaults.")
		return
	
	# Load and apply Display settings
	var display_mode = config.get_value("Display", "Mode", DisplayServer.WINDOW_MODE_FULLSCREEN)
	var resolution = config.get_value("Display", "Resolution", Vector2i(1920, 1080))
	var vsync = config.get_value("Display", "VSync", DisplayServer.VSYNC_ENABLED)

	DisplayServer.window_set_mode(display_mode)
	DisplayServer.window_set_size(resolution)
	DisplayServer.window_set_vsync_mode(vsync)

	# Load and apply Audio settings
	for i in range(3):  # Master, Music, SFX
		var volume = config.get_value("Audio", "Bus" + str(i), 0.5)  # Default 50%
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
