extends CardStates

func enter() -> void:
	var ui_layer := get_tree().get_first_node_in_group("ui_layer")
	if ui_layer:
		card_ui.reparent(ui_layer)
	

func on_input(event: InputEvent) -> void:
	var mouse_motion := event is InputEventMouseMotion
	var cancel = event.is_action_pressed("right_mouse")
	var confirm = event.is_action_released("left_mouse") or event.is_action_pressed("left_mouse")

	# Déplacement de la carte avec la souris
	if mouse_motion:
		card_ui.global_position = card_ui.get_global_mouse_position() - card_ui.pivot_offset

	# Annuler avec le clic droit -> Retour à BASE
	if cancel:
		transition_requested.emit(self, CardStates.State.BASE)
	
	# Vérifier où la carte est déposée avant de valider
	elif confirm:
		if card_ui.drop_point.get_overlapping_areas().size() > 0:
			print("Carte déposée dans une zone valide ✅")
			transition_requested.emit(self, CardStates.State.RELEASED)
		else:
			print("Carte déposée en dehors d'une zone valide ❌ -> Retour à BASE")
			transition_requested.emit(self, CardStates.State.BASE)  # Retour à la position initiale
