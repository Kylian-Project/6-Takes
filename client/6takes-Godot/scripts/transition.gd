extends Control

@onready var anim = $AnimationPlayer
@onready var audio_player = $AudioStreamPlayer

signal transition_finished
	
func fade_out(new_scene: String):
	if audio_player:
		audio_player.play()
	anim.play("fade_out")
	await anim.animation_finished
	queue_free() 
	get_tree().change_scene_to_file(new_scene)

func play_fade_in():
	anim.play("fade_in")
	await anim.animation_finished
	queue_free()  
