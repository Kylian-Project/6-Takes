extends Node2D

@export var vbox_container: VBoxContainer  # Conteneur des cartes de la rangée
@export var hbox_container: HBoxContainer  # Conteneur des cartes du joueur
@export var top_bar: HBoxContainer  # Conteneur HBox pour les labels
var all_cards = []  # Liste de toutes les cartes disponibles
var selected_cards = []  # Liste des cartes déjà utilisées

# Charger les scènes de cartes
 
var card_ui_scene = preload("res://scenes/card_ui.tscn")  

func _ready():
	if vbox_container == null:
		print("❌ Erreur : vbox_container n'est pas assigné ! Vérifie dans l'inspecteur.")
		return  
	
	if hbox_container == null:
		print("⚠ Attention : hbox_container n'est pas assigné, mais le jeu continue normalement.")
	
	_load_cards()
	_assign_vbox_cards()  # Distribuer les 4 cartes de la rangée
	_assign_hbox_cards()  # Distribuer les 10 cartes au joueur

# Charger toutes les cartes disponibles
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

# Assigner 4 cartes à la rangée (VBox)
# Assigner 4 cartes à la rangée (VBox)
func _assign_vbox_cards():
	if all_cards.size() < 4:
		print("❌ Erreur : Pas assez de cartes pour la rangée !")
		return
	
	# Nettoyer les anciennes cartes dans vbox_container avant d'ajouter les nouvelles
	for child in vbox_container.get_children():
		child.queue_free()
	
	for i in range(4):
		var card_instance = card_ui_scene.instantiate()  # ✅ Correction ici
		vbox_container.add_child(card_instance)
		
		if card_instance.has_method("set_card_data"):
			var card = all_cards.pop_front()
			card_instance.set_card_data(card["path"])
			selected_cards.append(card)
			print("🃏 Carte assignée à la rangée", i, "avec ID", card["id"], ":", card["path"])
		else:
			print("❌ Erreur : L'instance de carte ne possède pas 'set_card_data'.")

# Assigner 10 cartes au joueur (HBox)
func _assign_hbox_cards():
	if all_cards.size() < 10:
		print("❌ Erreur : Pas assez de cartes pour le joueur !")
		return
	
	# Nettoyer les anciennes cartes dans hbox_container avant d'ajouter les nouvelles
	for child in hbox_container.get_children():
		child.queue_free()
	
	for i in range(10):
		var card_instance = card_ui_scene.instantiate()  # Instancier une nouvelle carte
		hbox_container.add_child(card_instance)  # Ajouter au HBoxContainer
		
		if card_instance.has_method("set_card_data"):
			var card = all_cards.pop_front()
			card_instance.set_card_data(card["path"])
			selected_cards.append(card)
			print("🃏 Carte assignée au joueur", i, "avec ID", card["id"], ":", card["path"])
		else:
			print("❌ Erreur : L'instance de carte ne possède pas 'set_card_data'.")
