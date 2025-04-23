class_name TCardUI
extends Control

@onready var selection_container = $SelectionConatiner
@onready var select_card = $SelectionConatiner/selectButton
@onready var deselect_card = $SelectionConatiner/deselectButton
@onready var drop_point: Area2D=$detector
@onready var texture_rect = $Front_texture
@onready var back_texture = $Back_texture

@onready var card_control = $"."

var global_card_id 
var original_position := position
var original_scale := scale

signal card_selected

#card animation vars
var orig_tex_pos:   Vector2
var orig_tex_scale: Vector2
var is_lifted = false

# tweak these to taste:
const LIFT_OFFSET   = Vector2(0, -25)     # move up 20px
const SCALE_FACTOR  = 1.2 


func _ready() -> void:
	# cache the TextureRect’s original transform
	orig_tex_pos   = texture_rect.position
	orig_tex_scale = Vector2(1,1)
	
	selection_container.visible = is_lifted
	original_position = card_control.position
	original_scale = card_control.scale
	
	back_texture.visible = false
	

func _process(_delta):
	selection_container.visible = is_lifted
	
	
# Méthode pour assigner les données de la carte
func set_card_data(image_path, card_id):
	global_card_id = card_id
	var texture = load(image_path)  
	if texture:
		$Front_texture.texture = texture  
	else:
		print(" Erreur : Impossible de charger l'image", image_path)


func _on_select_button_pressed() -> void:
	print("emitting card selected signal")
	emit_signal("card_selected", global_card_id)
	is_lifted = false
	self.visible = false
	#_on_deselect_button_pressed()


func _on_deselect_button_pressed() -> void:
	if not is_lifted:
		return
	is_lifted = false
	
	self.position = orig_tex_pos
	self.scale    = orig_tex_scale
	
	selection_container.visible = is_lifted
	

func _on_detector_mouse_entered() -> void:
	if !is_in_hand_grp() or is_lifted:
		return 
	self.scale = Vector2(1.2, 1.2)


func _on_detector_mouse_exited() -> void:
	if  !is_in_hand_grp() or is_lifted:
		return 
	self.scale = Vector2(1, 1)


func _on_detector_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_in_hand_grp():
			if !is_lifted:
				#lift card
				is_lifted = true
				selection_container.visible =	is_lifted
				
				self.position = orig_tex_pos + LIFT_OFFSET
				self.scale = orig_tex_scale * SCALE_FACTOR
				#card_control.position = original_position + LIFT_OFFSET
				#card_control.scale = original_scale * SCALE_FACTOR
				
			else:
				is_lifted = false
				self.position = orig_tex_pos
				self.scale = original_scale
				selection_container.visible = is_lifted 
	else:
		return


func is_in_hand_grp():
	return self.get_parent().is_in_group("hand_grp")


func start_flip_timer(delay_sec: float) -> void:
	await get_tree().create_timer(delay_sec).timeout
	flip_card()
	
func flip_card() -> void:
	back_texture.visible = true
	texture_rect.visible = false
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale:x", 0.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	
	back_texture.visible = false
	texture_rect.visible = true 

	tween = create_tween()
	tween.tween_property(self, "scale:x", 1.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
