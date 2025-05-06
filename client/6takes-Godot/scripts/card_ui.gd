class_name TCardUI
extends Control

@onready var drop_point: Area2D=$detector
@onready var texture_rect = $Front_texture
@onready var back_texture = $Back_texture

@onready var card_control = $"."

var global_card_id 
var original_position := position
var original_scale := scale

signal card_selected

var is_hovered: bool = false
var hover_tween: Tween = null

#card animation vars
var orig_tex_pos:   Vector2
var orig_tex_scale: Vector2
var is_lifted = false

# tweak these to taste:
const LIFT_OFFSET   = Vector2(0, -25)     # move up 20px
const SCALE_FACTOR  = 1.2 


func _ready() -> void:
	# set pivot to center
	pivot_offset = size / 2
	original_position = position
	scale = Vector2(1,1)
	original_scale = scale
	
	orig_tex_pos   = texture_rect.position
	orig_tex_scale = Vector2(1,1)
	
	back_texture.visible = false
	

func _process(_delta):	
# Manual check for hover-exit if card is scaled
	if is_hovered and !is_lifted:
		if not is_mouse_over():
			_on_detector_mouse_exited()
	
	
# Méthode pour assigner les données de la carte
func set_card_data(image_path, card_id):
	global_card_id = card_id
	var texture = load(image_path)  
	if texture:
		$Front_texture.texture = texture  
		texture_rect.visible = false
	else:
		print(" Erreur : Impossible de charger l'image", image_path)


func _on_detector_mouse_entered() -> void:
	if !is_in_hand_grp() or is_lifted:
		return 
		
	is_hovered = true
	
	var hover_tween = get_tree().create_tween()
	hover_tween.tween_property(self, "scale", original_scale * 1.1, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	#self.scale = Vector2(1.2, 1.2)


func _on_detector_mouse_exited() -> void:
	if  !is_in_hand_grp() or is_lifted:
		return 
	
	is_hovered = false
	
	var exit_tween = get_tree().create_tween()
	exit_tween.tween_property(self, "scale", original_scale, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	#self.scale = Vector2(1, 1)


func _on_detector_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_in_hand_grp() and !is_lifted:
			get_parent()._on_card_clicked(self)
		elif is_lifted:
			emit_signal("card_selected", global_card_id)
			is_lifted = false
			self.visible = false


func is_in_hand_grp():
	return self.get_parent().is_in_group("hand_grp")


func start_flip_timer(delay_sec: float) -> void:
	await get_tree().create_timer(delay_sec).timeout
	flip_card()
	
func flip_card() -> void:
	if !is_inside_tree() or !is_instance_valid(self):
		return
	if self == null:
		print("this is a null card !!!!")
		return
		
	back_texture.visible = true
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale:x", 0.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	
	toggle_texture_visibility(true)

	tween = create_tween()
	tween.tween_property(self, "scale:x", 1.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func toggle_texture_visibility(boolean):
	texture_rect.visible = boolean
	back_texture.visible = !boolean


func is_topmost_card() -> bool:
	var parent = get_parent()
	
	for child in parent.get_children():
		if child == self:
			continue
		if child is TCardUI and child.drop_point.get_overlapping_areas().has(drop_point):
			if child.z_index >= self.z_index:
				return false
	return true

func is_mouse_over() -> bool:
	var mouse_pos = get_global_mouse_position()
	var rect = Rect2(global_position - (size * scale * 0.5), size * scale)
	return rect.has_point(mouse_pos)
