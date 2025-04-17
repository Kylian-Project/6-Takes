class_name TCardUI
extends Control

@onready var selection_container = $SelectionConatiner
@onready var select_card = $SelectionConatiner/selectButton
@onready var deselect_card = $SelectionConatiner/deselectButton
@onready var drop_point: Area2D=$detector

var selection_visibilty = false 
var global_card_id 

signal card_selected


func _ready() -> void:
	selection_visibilty = false 
	selection_container.visible = selection_visibilty
	
	reparent_requested.connect(_on_reparent_requested)
	

func _process(_delta):
	selection_container.visible = selection_visibilty
	
	
# Méthode pour assigner les données de la carte
func set_card_data(image_path, card_id):
	global_card_id = card_id
	var texture = load(image_path)  
	if texture:
		$TextureRect.texture = texture  
	else:
		print(" Erreur : Impossible de charger l'image", image_path)

signal reparent_requested(which_card_ui:CardUI)


func _on_reparent_requested(which_card_ui: CardUI) -> void:
	print("Reparenting demandé pour :", which_card_ui)


func _on_select_button_pressed() -> void:
	print("emitting card selected signal")
	emit_signal("card_selected", global_card_id)


func _on_deselect_button_pressed() -> void:
	selection_visibilty = false


func _on_detector_mouse_entered() -> void:
	if !is_in_hand_grp():
		return 
	self.scale = Vector2(1.2, 1.2)


func _on_detector_mouse_exited() -> void:
	self.scale = Vector2(1, 1)


func _on_detector_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	print("--- INPUT EVENT ON CARD ---")
	print("  event:", event)
	print("  pressed?:", event is InputEventMouseButton and event.pressed)
	
	print("  in hand grp?:", is_in_hand_grp())
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("group debug : ", is_in_hand_grp())
		if is_in_hand_grp():
			selection_visibilty = !selection_visibilty
			selection_container.visible = selection_visibilty
			print("toggled visibility ")
	else:
		return
			
			
func is_in_hand_grp():
	return self.get_parent().is_in_group("hand_grp")
