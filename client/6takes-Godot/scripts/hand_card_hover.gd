extends HBoxContainer

var current_hovered_card: TCardUI = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var mouse_pos = get_global_mouse_position()
	var top_card: TCardUI = null
	var top_z := -1

	for child in get_children():
		if child is TCardUI and child.visible:
			var rect = Rect2(child.global_position - (child.size * child.scale * 0.5), child.size * child.scale)
			if rect.has_point(mouse_pos):
				if child.z_index > top_z:
					top_z = child.z_index
					top_card = child
	
	# Manage hover state
	if current_hovered_card and current_hovered_card != top_card:
		current_hovered_card._on_detector_mouse_exited()
		current_hovered_card = null
	
	if top_card and top_card != current_hovered_card and !top_card.is_lifted:
		top_card._on_detector_mouse_entered()
		current_hovered_card = top_card
