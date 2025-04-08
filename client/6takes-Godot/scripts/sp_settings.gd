extends Control

@onready var end_points_dropdown = $PanelContainer/MainVertical/AvailableOptions/Choices/EndPointsDropdown
@onready var max_points_label = $PanelContainer/MainVertical/AvailableOptions/Options/MaxPoints
@onready var max_points_dropdown = $PanelContainer/MainVertical/AvailableOptions/Choices/MaxPointsDropdown
@onready var rounds_label = $PanelContainer/MainVertical/AvailableOptions/Options/Rounds
@onready var round_dropdown = $PanelContainer/MainVertical/AvailableOptions/Choices/RoundsDropdown

func _ready():
	# Connect signals
	end_points_dropdown.item_selected.connect(_on_end_points_selected)

# Hide/Unhide elements based on EndPointsDropdown selection
func _on_end_points_selected(index: int):
	if index == 1:  # Assuming "Yes" is at index 1
		max_points_label.visible = true
		max_points_dropdown.visible = true
		rounds_label.visible = false
		round_dropdown.visible = false
	else:
		max_points_label.visible = false
		max_points_dropdown.visible = false
		rounds_label.visible = true
		round_dropdown.visible = true
	
	end_points_dropdown.button_pressed = false 
	
