extends Node

@onready var hover_sound = $HoverSound
@onready var click_sound = $ClickSound
@onready var music = $Music
@onready var flip_card = $FlipCard
@onready var move_card = $MoveCard
@onready var pause_sound = $PauseButton

func _ready():
	# Assign audio buses
	hover_sound.bus = "SFX"
	click_sound.bus = "SFX"
	music.bus = "Music"
	flip_card.bus = "SFX"
	move_card.bus = "SFX"
	pause_sound.bus = "SFX"

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
		
func play_flip_sound():
	if flip_card.playing:
		flip_card.stop()
	flip_card.play()

func play_move_card():
	if move_card.playing:
		move_card.stop()
	move_card.play()

func play_pause_button():
	if pause_sound.playing:
		pause_sound.stop()
	pause_sound.play()
