extends TabBar
@onready var master_slider = $HorizontalAlign/VSettings/MsterSlider
@onready var music_slider = $HorizontalAlign/VSettings/MusicSlider
@onready var sfx_slider = $HorizontalAlign/VSettings/SFXSlider

func _ready():
	# Load saved settings
	SettingsManager.load_settings()

	# Load volumes from the settings
	var master_volume = SettingsManager.config.get_value("Audio", "Bus0", 0.5)
	var music_volume = SettingsManager.config.get_value("Audio", "Bus1", 0.5)
	var sfx_volume = SettingsManager.config.get_value("Audio", "Bus2", 0.5)

	# Update slider positions to reflect loaded volume
	master_slider.value = master_volume
	music_slider.value = music_volume
	sfx_slider.value = sfx_volume

func _on_mster_slider_value_changed(value: float) -> void:
	set_volume(0, value)

func _on_music_slider_value_changed(value: float) -> void:
	set_volume(1, value)

func _on_sfx_slider_value_changed(value: float) -> void:
	set_volume(2, value)

func set_volume(idx, value):
	AudioServer.set_bus_volume_db(idx, linear_to_db(value))
	SettingsManager.save_audio_settings(idx, value)
