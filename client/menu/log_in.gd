extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.visible = false

func show_overlay():
	self.visible = true 
	
func hide_overlay():
	self.visible = false 
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_cancel_button_pressed() -> void:
	queue_free() 
