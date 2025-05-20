extends CardStates


func enter() -> void:
	card_ui.drop_point.monitoring = true



func on_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		transition_requested.emit(self, CardStates.State.DRAGGING)
