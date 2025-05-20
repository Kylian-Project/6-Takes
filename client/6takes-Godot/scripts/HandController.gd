# HandController.gd
# Contrôleur pour activer/désactiver toute la main du joueur
extends Node

var hand_container: HBoxContainer
var is_hand_enabled: bool = true

func _ready():
	pass

func set_hand_container(container: HBoxContainer):
	hand_container = container

func set_hand_enabled(enabled: bool):
	is_hand_enabled = enabled
	if hand_container:
		for child in hand_container.get_children():
			if child.has_method("set_card_enabled"):
				child.set_card_enabled(enabled)

func is_enabled() -> bool:
	return is_hand_enabled
