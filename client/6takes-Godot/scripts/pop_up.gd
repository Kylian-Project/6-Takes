extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.visible = false


func _on_button_pressed() -> void:
	self.visible = false

func make_visible():
	self.visible = true
