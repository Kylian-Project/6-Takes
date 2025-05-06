class_name TCardUI
extends Control

# Déclaration des nœuds avec @onready
@onready var selection_container = $SelectionContainer
@onready var selection_modulate: CanvasItem = $SelectionContainer
@onready var select_card = $SelectionContainer/selectButton
@onready var deselect_card = $SelectionContainer/deselectButton
@onready var drop_point: Area2D = $detector
@onready var texture_rect = $TextureRect
@onready var back_texture = $Back_texture

# Variable pour l'ID de la carte et la position/échelle originale
var global_card_id 
var original_position := position
var original_scale := scale

# Signal pour la sélection de la carte
signal card_selected

# Variables d'animation
var is_hovered: bool = false
var hover_tween: Tween = null

# Variables pour l'animation de la carte (échelle et position)
var orig_tex_pos: Vector2
var orig_tex_scale: Vector2
var is_lifted = false

# Constantes pour l'animation de la carte
const LIFT_OFFSET = Vector2(0, -25)  # Décalage pour l'élévation de la carte
const SCALE_FACTOR = 1.2  # Facteur de mise à l'échelle lors de l'élévation

# Déclaration de la propriété card_index
var card_index: int = -1  # Valeur par défaut -1

# Fonction _ready qui s'exécute au démarrage
func _ready() -> void:
	#set_card_data(image_path, card_id):
	#print("Visibilité du nœud parent:", self.visible)
	#print("Sélection de TextureRect:", texture_rect)
	#print("Sélection de Back_texture:", back_texture)

	# Vérifie que TextureRect et Back_texture existent
	if texture_rect == null:
		print("Erreur : TextureRect est introuvable.")
	#else:
		#print("TextureRect trouvé.")
		
	if back_texture == null:
		print("Erreur : Back_texture est introuvable.")
	#else:
		#print("Back_texture trouvé.")
		
	# Vérifie si SelectionContainer existe et l'initialise
	if selection_container != null:
		selection_container.visible = false
		selection_container.modulate.a = 0.0  # Transparent
	else:
		print("Erreur : SelectionContainer est introuvable.")
		
	# Initialisation des variables de position et d'échelle
	scale = Vector2(1, 1)
	original_position = position
	original_scale = scale
	orig_tex_pos = texture_rect.position
	orig_tex_scale = Vector2(1, 1)

	# Cache la back_texture initialement
	if back_texture != null:
		back_texture.visible = false
	else:
		print("Erreur : Back_texture est introuvable.")

# Fonction _process pour mettre à jour l'état à chaque frame
func _process(_delta):
	# Assurer que le container de sélection est visible lorsqu'une carte est levée
	if selection_container != null:
		selection_container.visible = is_lifted
	
	# Gestion du survol de la souris
	if is_hovered and !is_lifted:
		if not is_mouse_over():
			_on_detector_mouse_exited()

# Méthode pour assigner les données de la carte
func set_card_data(card_path: String, card_id: int) -> void:
	#print("🃏 Appel de set_card_data avec:", card_id)

	if texture_rect == null or back_texture == null:
		push_error("❌ texture_rect ou back_texture est null !")
		return

	var texture = load(card_path)
	if texture is Texture2D:
		texture_rect.texture = texture
	else:
		push_error("❌ Texture non valide pour la carte " + str(card_id))

	self.name = "Card_" + str(card_id)
	self.global_card_id = card_id 

# Fonction pour sélectionner la carte (déclenche le signal)

func _on_select_button_pressed() -> void:
	if global_card_id == null:
		print("❌ Erreur : global_card_id est null avant d’émettre le signal")
		return
	emit_signal("card_selected", global_card_id)
	is_lifted = false
	self.visible = false  # Optionnel : si tu veux cacher la carte après sélection
# Fonction pour désélectionner la carte
func _on_deselect_button_pressed() -> void:
	if not is_lifted:
		return
	is_lifted = false
	
	var cancel_tween = get_tree().create_tween()
	cancel_tween.tween_property(self, "scale", original_scale, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	show_selection_container(false)
	z_index = 0

# Fonction pour gérer l'entrée de la souris sur la carte
func _on_detector_mouse_entered() -> void:
	if !is_in_hand_grp() or is_lifted:
		return 
	
	is_hovered = true
	
	var hover_tween = get_tree().create_tween()
	hover_tween.tween_property(self, "scale", original_scale * 1.1, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

# Fonction pour gérer la sortie de la souris de la carte
func _on_detector_mouse_exited() -> void:
	if !is_in_hand_grp() or is_lifted:
		return 
	
	is_hovered = false
	
	var exit_tween = get_tree().create_tween()
	exit_tween.tween_property(self, "scale", original_scale, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

# Fonction pour gérer l'événement de clic sur la carte
func _on_detector_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_in_hand_grp():
			if !is_lifted:
				is_lifted = true
				show_selection_container(true)
				z_index = 100  # juste pour que la carte soit au-dessus des autres
				
				var lift_tween = get_tree().create_tween()
				lift_tween.tween_property(self, "scale", original_scale * SCALE_FACTOR, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			else:
				is_lifted = false
				show_selection_container(false)
				z_index = 0  # revenir à la normale
				
				var drop_tween = get_tree().create_tween()
				drop_tween.tween_property(self, "scale", original_scale, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

# Fonction pour vérifier si la carte est dans le groupe "hand_grp"
func is_in_hand_grp():
	
	return self.get_parent().is_in_group("hand_grp")

# Fonction pour démarrer un timer avant de faire une rotation de carte
func start_flip_timer(delay_sec: float) -> void:
	await get_tree().create_timer(delay_sec).timeout
	flip_card()

# Fonction pour effectuer le retournement de la carte
func flip_card() -> void:
	if !is_inside_tree() or !is_instance_valid(self):
		return
	if self == null:
		print("this is a null card !!!!")
		return
		
	if back_texture != null:
		back_texture.visible = true
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale:x", 0.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	
	toggle_texture_visibility(true)

	tween = create_tween()
	tween.tween_property(self, "scale:x", 1.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

# Fonction pour basculer la visibilité des textures
func toggle_texture_visibility(boolean):
	if texture_rect != null:
		texture_rect.visible = boolean
	
	if back_texture != null:
		back_texture.visible = !boolean

# Fonction pour afficher/masquer le container de sélection
func show_selection_container(show: bool) -> void:
	# Vérifie que SelectionContainer existe
	if selection_container == null:
		print("Erreur : SelectionContainer est introuvable.")
		return

	var tween = get_tree().create_tween()
	
	if show:
		selection_container.visible = true
		selection_container.position.y += 10
		selection_container.modulate.a = 0.0
		
		# Tween opacity à 1
		tween.tween_property(selection_container, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		# Tween position vers le haut de 10px
		tween.tween_property(selection_container, "position:y", selection_container.position.y - 10, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		# Fade out
		tween.tween_property(selection_container, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_callback(Callable(selection_container, "hide"))  # Masquer après le fade

# Fonction pour vérifier si la carte est la carte la plus en haut
func is_topmost_card() -> bool:
	var parent = get_parent()
	
	for child in parent.get_children():
		if child == self:
			continue
		if child is TCardUI and child.drop_point.get_overlapping_areas().has(drop_point):
			if child.z_index >= self.z_index:
				return false
	return true

# Fonction pour vérifier si la souris est sur la carte
func is_mouse_over() -> bool:
	var mouse_pos = get_global_mouse_position()
	var rect = Rect2(global_position - (size * scale * 0.5), size * scale)
	return rect.has_point(mouse_pos)
