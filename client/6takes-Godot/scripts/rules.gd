extends Control
@onready var cancel_button = $MarginContainer/Control/Panel/CancelButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.visible = false
	
	cancel_button.mouse_entered.connect(SoundManager.play_hover_sound)
	cancel_button.pressed.connect(SoundManager.play_click_sound)


func _on_cancel_button_pressed() -> void:
	self.visible = false
