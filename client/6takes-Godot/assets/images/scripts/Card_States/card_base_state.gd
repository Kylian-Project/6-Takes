extends CardStates

var mouse_over_card := false  # Indique si la souris est sur la carte

# Méthode appelée lorsqu'on entre dans l'état "BASE"
func enter() -> void:
	if not card_ui.is_node_ready():
		await card_ui.ready  # S'assurer que le nœud est prêt avant d'exécuter du code

	card_ui.reparent_requested.emit(card_ui)  # Émet le signal de réaffectation
	card_ui.pivot_offset = Vector2.ZERO  # Réinitialise le pivot
# Gestion du clic pour changer d'état
func on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse"):  
		# Déplacement de la carte en fonction de la position de la souris
		card_ui.pivot_offset = card_ui.get_global_mouse_position() - card_ui.global_position
		transition_requested.emit(self, CardStates.State.CLICKED)  # Passe à l'état "CLICKED"

# Méthode appelée lorsque la souris entre dans l'élément
func on_mouse_entered() -> void:
	mouse_over_card = true  # La souris est au-dessus de la carte

# Méthode appelée lorsque la souris quitte l'élément
func on_mouse_exited() -> void:
	mouse_over_card = false  # La souris n'est plus au-dessus de la carte
