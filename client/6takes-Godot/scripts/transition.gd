extends Control

@onready var anim = $AnimationPlayer

signal transition_finished

func fade_to_black_then_change_scene(new_scene: String):
	anim.play("fade_out")
	await anim.animation_finished
	get_tree().change_scene_to_file(new_scene)
	anim.play("fade_in")
	await anim.animation_finished
	emit_signal("transition_finished")
