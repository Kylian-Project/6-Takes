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
		print("❌ Erreur : Impossible de charger l'image", image_path)

signal reparent_requested(which_card_ui:CardUI)

@onready var color: ColorRect = $color
@onready var state: Label = $state
@onready var drop_point: Area2D=$detector
@onready var card_state_machine: CardStateMachine = $CardStateMachine as CardStateMachine

func _ready() -> void:
	# Vous appelez explicitement la méthode init ici
	card_state_machine.init(self)
	# Connexion du signal reparent_requested
	reparent_requested.connect(_on_reparent_requested)

	
func _input(event: InputEvent) -> void:
	card_state_machine.on_input(event)
		
func _on_gui_input(event: InputEvent) -> void:
	card_state_machine.on_gui_input(event)
	
func _on_mouse_entered() -> void:
	card_state_machine.on_mouse_entered()
		
func _on_mouse_exited() -> void:
	card_state_machine.on_mouse_exited()
func _on_reparent_requested(which_card_ui: CardUI) -> void:
	print("Reparenting demandé pour :", which_card_ui)
