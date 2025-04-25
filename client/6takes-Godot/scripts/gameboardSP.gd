extends Node2D
# Conteneurs pour les cartes et la barre du haut
@export var vbox_container: VBoxContainer  # Conteneur des cartes de la rangée
@export var hbox_container: HBoxContainer  # Conteneur des cartes du joueur
@export var top_bar: HBoxContainer  # Conteneur HBox pour les labels

# Listes de cartes
var all_cards = []  # Liste de toutes les cartes disponibles
var selected_cards = []  # Liste des cartes déjà utilisées

# Chargement des scènes
@onready var pause_screen_scene = preload("res://scenes/screen_pause.tscn")
@onready var card_ui_scene = preload("res://scenes/card_ui.tscn")  

# Instance de l'écran de pause
var pause_instance = null



@export var  spplayerleft : VBoxContainer  # Assurez-vous que spplayerleft est assigné depuis l'éditeur

@export var  spplayerright : VBoxContainer

@export var bot_scene: PackedScene = preload("res://scenes/BotSlot.tscn")  # Précharge la scène du bot

var bots_info = []  # Liste des informations des bots à afficher

func _ready():
	if spplayerleft == null:
		print("❌ Erreur : spplayerleft est nul, assurez-vous qu'il est bien assigné dans l'éditeur.")
		return
	if spplayerright == null:
		print("❌ Erreur : spplayerright est nul, assurez-vous qu'il est bien assigné dans l'éditeur.")
		return

	print("Type de spplayerleft : ", spplayerleft.get_class())
	assert(spplayerleft is VBoxContainer, "spplayerleft n'est pas un VBoxContainer !")
	assert(spplayerright is VBoxContainer, "spplayerright n'est pas un VBoxContainer !")

	_load_cards()
	_assign_vbox_cards()  # Distribuer les 4 cartes de la rangée
	_assign_hbox_cards()  # Distribuer les 10 cartes au joueur
	spplayerleft = $spplayerleft
	spplayerright = $spplayerright

	print("spplayerleft:", spplayerleft)
	print("spplayerright:", spplayerright)

	if spplayerleft == null:
		print("❌ Erreur : spplayerleft n'est toujours pas assigné !")
		return

	if spplayerright == null:
		print("❌ Erreur : spplayerright n'est toujours pas assigné !")
		return


func setup_from_lobby(players: Array):
	bots_info.clear()

	for name in players:
		bots_info.append({"bot_name": name})

	display_bots()

# Afficher les icônes des bots dans les panneaux de gauche et droite
# Afficher les icônes des bots dans les panneaux de gauche et droite

func display_bots():
	
	# Vérifier si spplayerleft et spplayerright sont correctement assignés
	if spplayerleft == null:
		print("Erreur : spplayerleft est nul. Vérifie l'assignation dans l'inspecteur.")
		return  # Arrêter la fonction si spplayerleft est nul

	if spplayerright == null:
		print("Erreur : spplayerright est nul. Vérifie l'assignation dans l'inspecteur.")
		return  # Arrêter la fonction si spplayerright est nul

	# Réinitialiser les panneaux avant d'ajouter de nouveaux éléments
	for child in spplayerleft.get_children():
		child.queue_free()

	for child in spplayerright.get_children():
		child.queue_free()

	# Assurez-vous que tu as une méthode pour récupérer une icône de bot basée sur son index
	for i in range(len(bots_info)):
		var bot = bots_info[i]
		var bot_icon = create_bot_icon(bot)

		if i % 2 == 0:  # Par exemple, afficher les bots sur la gauche
			spplayerleft.add_child(bot_icon)
		else:  # Afficher les autres bots sur la droite
			spplayerright.add_child(bot_icon)


func create_bot_icon(bot_info):
	var icon = TextureRect.new()

	const ICON_PATH = "res://assets/images/icons/"
	const ICON_FILES = [
		"dark_grey.png", "blue.png", "brown.png", "green.png", 
		"orange.png", "pink.png", "purple.png", "red.png",
		"reversed.png", "cyan.png"
	]

	var index = bots_info.find(bot_info) % ICON_FILES.size()
	var file_name = ICON_FILES[index]
	var full_path = ICON_PATH + file_name

	var icon_texture = load(full_path)
	if icon_texture:
		icon.texture = icon_texture
	else:
		print("❌ Erreur : Impossible de charger", full_path)
		return null

	# Force une taille réelle (pas scale)
	icon.set_custom_minimum_size(Vector2(0.5, 3))
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	return icon
	

# ==============================
# 🚀 Gestion de l'écran de pause
# ==============================
func _on_open_pause_button_pressed() -> void:
	if pause_instance == null:
		pause_instance = pause_screen_scene.instantiate()
		add_child(pause_instance)

		# Centrer l'écran de pause
		await get_tree().process_frame  # Assurer la mise à jour de la taille
		pause_instance.position = get_viewport_rect().size / 2 - pause_instance.size / 2
		
	pause_instance.move_to_front()  # S'assurer que l'écran de pause est tout en haut
	pause_instance.visible = true  # Afficher la pause

# ==============================
# 🔄 Initialisation
# ==============================
# ==============================
# 🃏 Chargement des cartes
# ==============================
func _load_cards():
	var dir_path = "res://assets/images/cartes/"
	var dir = DirAccess.open(dir_path)
	
	if dir == null:
		print("❌ Erreur : Impossible d'ouvrir le dossier des cartes. Vérifiez le chemin !")
		return

	dir.list_dir_begin()
	print("📂 Exploration du dossier", dir_path)

	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".png") and not file_name.ends_with(".import"):  
			var card_id = int(file_name.get_basename())  # L'ID est le nom du fichier sans l'extension
			var card_path = dir_path + file_name
			all_cards.append({"id": card_id, "path": card_path})
		file_name = dir.get_next()
	
	dir.list_dir_end()
	print("✅ Cartes chargées :", all_cards)

	all_cards.shuffle()  # Mélanger les cartes aléatoirement

# ==============================
# 🎴 Distribution des cartes
# ==============================
func _assign_vbox_cards():
	if all_cards.size() < 4:
		print("❌ Erreur : Pas assez de cartes pour la rangée !")
		return

	# Nettoyer les anciennes cartes dans vbox_container avant d'ajouter les nouvelles
	for child in vbox_container.get_children():
		child.queue_free()

	for i in range(4):
		var card_instance = card_ui_scene.instantiate()
		vbox_container.add_child(card_instance)
		
		if card_instance.has_method("set_card_data"):
			var card = all_cards.pop_front()
			card_instance.set_card_data(card["path"])
			selected_cards.append(card)
			print("🃏 Carte assignée à la rangée", i, "avec ID", card["id"], ":", card["path"])
		else:
			print("❌ Erreur : L'instance de carte ne possède pas 'set_card_data'.")

func _assign_hbox_cards():
	if all_cards.size() < 10:
		print("❌ Erreur : Pas assez de cartes pour le joueur !")
		return

	# Nettoyer les anciennes cartes dans hbox_container avant d'ajouter les nouvelles
	for child in hbox_container.get_children():
		child.queue_free()

	for i in range(10):
		var card_instance = card_ui_scene.instantiate()
		hbox_container.add_child(card_instance)
		
		if card_instance.has_method("set_card_data"):
			var card = all_cards.pop_front()
			card_instance.set_card_data(card["path"])
			selected_cards.append(card)
			print("🃏 Carte assignée au joueur", i, "avec ID", card["id"], ":", card["path"])
		else:
			print("❌ Erreur : L'instance de carte ne possède pas 'set_card_data'.")
