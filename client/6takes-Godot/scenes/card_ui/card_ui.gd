class_name CardUI
extends Control

# Méthode pour assigner les données de la carte
func set_card_data(image_path):
	# Je charge l’image depuis le chemin
	var texture = load(image_path)  
	if texture:
		# J'assigne la texture au TextureRect enfant
		$TextureRect.texture = texture  
	else:
		print(" Erreur : Impossible de charger l'image", image_path)

signal reparent_requested(which_card_ui:CardUI)

@onready var color: ColorRect = $color
@onready var state: Label = $state
@onready var drop_point: Area2D=$detector


func _ready() -> void:
	# Vous appelez explicitement la méthode init ici
	
	# Connexion du signal reparent_requested
	reparent_requested.connect(_on_reparent_requested)

	


func _on_reparent_requested(which_card_ui: CardUI) -> void:
	print("Reparenting demandé pour :", which_card_ui)
