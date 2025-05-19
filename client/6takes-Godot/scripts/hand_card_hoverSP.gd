extends HBoxContainer

var current_hovered_card: TCardUIsp = null
var selected_card: TCardUIsp = null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var mouse_pos = get_global_mouse_position()
	var top_card: TCardUIsp = null
	var top_z := -1

	for child in get_children():
		if child is TCardUIsp and child.visible:
			var rect = Rect2(child.global_position - (child.size * child.scale * 0.5), child.size * child.scale)
			if rect.has_point(mouse_pos):
				if child.z_index > top_z:
					top_z = child.z_index
					top_card = child
	
	# Manage hover state
	if current_hovered_card and current_hovered_card != top_card:
		if is_instance_valid(current_hovered_card):
			current_hovered_card._on_detector_mouse_exited()
		current_hovered_card = null
	
	if top_card and top_card != current_hovered_card and !top_card.is_lifted:
		top_card._on_detector_mouse_entered()
		current_hovered_card = top_card

func _on_card_clicked(card: TCardUIsp) -> void:
	# Désélectionner toute carte précédente
	if is_instance_valid(selected_card) and selected_card != card:
		selected_card._on_deselect_card()
	
	# Basculer l'état
	card.is_lifted = !card.is_lifted
	
	if card.is_lifted:
		# Enregistrer la carte sélectionnée
		selected_card = card
		card.z_index = 100
		if !card.has_meta("orig_pos"):
			card.set_meta("orig_pos", card.position)
		
		# Animation très subtile sans délai
		card.position = card.position + Vector2(0, -40)
	else:
		card._on_deselect_card()
		selected_card = null
		
func on_card_deselected(card: TCardUIsp) -> void:
	if selected_card == card:
		selected_card = null
