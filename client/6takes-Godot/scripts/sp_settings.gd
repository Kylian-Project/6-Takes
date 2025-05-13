extends Control

@onready var end_points_dropdown = $PanelContainer/MainVertical/AvailableOptions/Choices/EndPointsDropdown
@onready var max_points_label = $PanelContainer/MainVertical/AvailableOptions/Options/MaxPoints
@onready var max_points_dropdown = $PanelContainer/MainVertical/AvailableOptions/Choices/MaxPointsDropdown
@onready var rounds_label = $PanelContainer/MainVertical/AvailableOptions/Options/Rounds
@onready var round_dropdown = $PanelContainer/MainVertical/AvailableOptions/Choices/RoundsDropdown

@onready var card_number_dropdown = $PanelContainer/MainVertical/AvailableOptions/Choices/CardNumberDropdown
@onready var round_timer_dropdown = $PanelContainer/MainVertical/AvailableOptions/Choices/RoundTimerDropdown
@onready var player_limit_dropdown = $PanelContainer/MainVertical/AvailableOptions/Choices/PlayerLimitDropdown

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

func get_settings() -> Dictionary:
	var use_max_points = end_points_dropdown.selected == 1
	var selected_rounds = int(round_dropdown.get_item_text(round_dropdown.selected))
	var base_cards = int(card_number_dropdown.get_item_text(card_number_dropdown.selected))
	
	# Nouvelle logique : ne multiplie que si > 1 round
	var total_rounds = base_cards
	if selected_rounds > 1:
		total_rounds = base_cards * selected_rounds
	
	return {
		"use_max_points": use_max_points,
		"max_points": int(max_points_dropdown.get_item_text(max_points_dropdown.selected)),
		"rounds": selected_rounds,  # Nombre de manches choisi (1, 2, 3, etc.)
		"card_number": base_cards,  # Nombre de cartes de base
		"total_rounds": total_rounds,  # Nombre total de tours (cartes × manches si manches > 1)
		"round_timer": int(round_timer_dropdown.get_item_text(round_timer_dropdown.selected)),
		"player_limit": int(player_limit_dropdown.get_item_text(player_limit_dropdown.selected))
	}
