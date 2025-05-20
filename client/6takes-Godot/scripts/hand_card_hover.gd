extends HBoxContainer

var current_hovered_card: TCardUI = null
var selected_card: TCardUI = null
var hand_controller = null

func _ready():
	# Recherche d'un HandController dans la hiérarchie
	for node in get_tree().get_nodes_in_group("hand_controller_grp"):
		hand_controller = node
		break

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# Si la main est désactivée, on ne fait rien
	if hand_controller and not hand_controller.is_enabled():
		return

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
		if is_instance_valid(current_hovered_card):
			current_hovered_card._on_detector_mouse_exited()
		current_hovered_card = null
	
	if top_card and top_card != current_hovered_card and !top_card.is_lifted:
		top_card._on_detector_mouse_entered()
		current_hovered_card = top_card

func _on_card_clicked(card: TCardUI) -> void:
	if hand_controller and not hand_controller.is_enabled():
		return

	if is_instance_valid(selected_card) and selected_card != card:
		selected_card._on_deselect_card()
	
	if selected_card == card:
		card._on_deselect_card()
		selected_card = null
		
	if card.is_lifted:
		card._on_deselect_card()
		selected_card = null
	else:
		card.is_lifted = true
		card.z_index = 100
		
		#add position scale######
		if not card.has_meta("orig_pos"):
			card.set_meta("orig_pos", card.position)

		var original_pos = card.get_meta("orig_pos")
		var lift_amount = Vector2(0, -50)   # move 20px upward
		var target_pos = original_pos + lift_amount
		
		
		var lift_tween = get_tree().create_tween()
		#lift_tween.tween_property(card, "scale", card.original_scale * card.SCALE_FACTOR, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		lift_tween.tween_property(card, "position", target_pos, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			
		selected_card = card

func on_card_deselected(card: TCardUI) -> void:
	if selected_card == card:
		selected_card = null
