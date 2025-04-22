extends Node

@onready var hover_sound = $HoverSound
@onready var click_sound = $ClickSound
@onready var music = $Music

func _ready():
	# Assign audio buses
	hover_sound.bus = "SFX"
	click_sound.bus = "SFX"
	music.bus = "Music"

func play_hover_sound():
	if hover_sound.playing:
		hover_sound.stop()
	hover_sound.play()

func play_click_sound():
	if click_sound.playing:
		click_sound.stop()
	click_sound.play()

func play_music():
	if not music.playing:
		music.play()

func stop_music():
	if music.playing:
		music.stop()
