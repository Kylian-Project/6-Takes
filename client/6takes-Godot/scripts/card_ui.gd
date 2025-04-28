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
# Ajouter une référence au gameboard dans TCardUI
@export var gameboardSP: Node2D  # Référence au gameboard


func _ready() -> void:
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
		texture_rect.visible = true  # Afficher l'image
	else:
		print("❌ Erreur : Impossible de charger l'image", image_path)


func _on_select_button_pressed() -> void:
	emit_signal("card_selected", global_card_id)
	is_lifted = false
	self.visible = false
	
	# Déplacer la carte vers la rangée
	move_card_to_row()

# Méthode pour récupérer la rangée cible depuis le gameboard
func get_target_row() -> Node:
	if gameboardSP == null:
		print("❌ Gameboard non défini!")
		return null

	# Récupérer toutes les rangées à partir du gameboard
	var rows = gameboardSP.get_children()

	for row in rows:
		if row is Rang:  # Supposons que Rang est une classe représentant les rangées
			if not row.est_pleine():  # Vérifier si la rangée n'est pas pleine
				return row

	return null  # Si aucune rangée valide n'est trouvée

# Cette fonction va déplacer la carte vers la rangée spécifiée
# Déplacer la carte dans la rangée cible
# Déplacer la carte dans la rangée cible
func move_card_to_row() -> void:
	if not is_lifted:
		return

	# Trouver la rangée cible via gameboard
	var target_row = get_target_row()

	if target_row == null:
		print("❌ Aucune rangée cible trouvée.")
		return

	# Créer une instance de la carte pour l'ajouter à la rangée
	var card_instance = self.duplicate()

	# Déplacer la carte dans la rangée cible
	target_row.add_child(card_instance)

	# Mettre à jour la position et la visibilité de la carte dans la rangée
	card_instance.position = target_row.get_node("some_position_marker").position  # Remplacer par un marqueur de position dans la rangée
	card_instance.visible = true

	# Optionnel : Animation de déplacement de la carte vers la rangée
	var tween = get_tree().create_tween()
	
	# Crée l'animation pour déplacer la carte vers la nouvelle position
	tween.tween_property(card_instance, "position", target_row.get_node("some_position_marker").position, 0.3)
	
	# Définir la transition et l'easing pour l'animation
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)

	# Retirer la carte de l'ancienne position (si nécessaire)
	self.queue_free()

	print("✅ Carte déplacée vers la rangée.")

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
	if !is_inside_tree() or !is_instance_valid(self):
		return
	if self == null:
		print("this is a null card !!!!")
		return
		
	back_texture.visible = true
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale:x", 0.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	"res://scripts/singleplayer/"
	
	
	toggle_texture_visibility(true)

	tween = create_tween()
	tween.tween_property(self, "scale:x", 1.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func toggle_texture_visibility(is_front_visible: bool) -> void:
	# Logique pour basculer la visibilité entre les textures (recto et verso)
	texture_rect.visible = is_front_visible
	back_texture.visible = !is_front_visible
	
	print("🎴 Front visible?", texture_rect.visible, " / Back visible?", back_texture.visible)
func find_best_row(card_number: int) -> HBoxContainer:
	var rows = [gameboardSP.row1, gameboardSP.row2, gameboardSP.row3, gameboardSP.row4]
	var best_diff = -1
	var best_row = null

	for row in rows:
		if row.get_child_count() == 0:
			continue
		var last_card = row.get_child(row.get_child_count() - 1)
		if last_card is TCardUI:
			var last_card_number = last_card.global_card_id  # Si tu utilises global_card_id ici
			var diff = card_number - last_card_number
			if diff > 0 and (best_diff == -1 or diff < best_diff):
				best_diff = diff
				best_row = row

	return best_row
