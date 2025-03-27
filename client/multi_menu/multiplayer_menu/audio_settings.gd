extends TabBar


func _on_mster_slider_value_changed(value: float) -> void:
	set_volume(0,value)


func _on_music_slider_value_changed(value: float) -> void:
	set_volume(1,value)


func _on_sfx_slider_value_changed(value: float) -> void:
	set_volume(2,value)

func set_volume(idx,value):
	AudioServer.set_bus_volume_db(idx,linear_to_db(value))
