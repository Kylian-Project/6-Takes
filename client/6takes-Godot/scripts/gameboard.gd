extends Node2D

@export var vbox_container: VBoxContainer  # Référence aux cartes de la rangée
@export var hbox_container: HBoxContainer  # Référence aux cartes du joueur

var all_cards = []  # Liste de toutes les cartes disponibles

func _ready():
	if vbox_container == null:
		print("❌ Erreur : vbox_container n'est pas assigné ! Vérifie dans l'inspecteur.")
		return  

	if hbox_container == null:
		print("⚠️ Attention : hbox_container n'est pas assigné, mais le jeu continue normalement.")

	_load_cards()
	_assign_vbox_cards()  # Distribue les 4 cartes de la rangée
	_assign_hbox_cards()  # Distribue les 10 cartes au joueur

# Charger toutes les cartes disponibles dans res://cartes/
func _load_cards():
	var dir = DirAccess.open("res://cartes/")
	if dir == null:
		print("❌ Erreur : Impossible d'ouvrir le dossier des cartes. Vérifiez le chemin !")
		return

	dir.list_dir_begin()
	print("📂 Exploration du dossier 'res://cartes/'...")

	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".png") and not file_name.ends_with(".import"):  
			all_cards.append("res://cartes/" + file_name)
		file_name = dir.get_next()

	dir.list_dir_end()
	print("✅ Cartes chargées :", all_cards)  # Debug final

# Assigner 4 cartes aléatoires aux 4 emplacements de la rangée
func _assign_vbox_cards():
	if all_cards.size() < 4:
		print("❌ Erreur : Pas assez de cartes pour la rangée !")
		return

	all_cards.shuffle()  # Mélanger les cartes

	for i in range(4):
		var card_instance = vbox_container.get_child(i)
		if card_instance == null:
			print("❌ Erreur : Impossible de trouver l'enfant à l'indice", i)
			continue  

		if card_instance.has_method("set_card_data"):
			var image_path = all_cards.pop_at(0)  # Retire la carte du deck !
			card_instance.set_card_data(image_path)
			print("🎴 Carte assignée à la rangée", i, ":", image_path)
		else:
			print("⚠️ Erreur : L'instance de carte ne possède pas 'set_card_data'.")

# Assigner 10 cartes aléatoires au joueur
func _assign_hbox_cards():
	if all_cards.size() < 10:
		print("❌ Erreur : Pas assez de cartes pour le joueur !")
		return

	all_cards.shuffle()  # Mélanger à nouveau les cartes restantes

	for i in range(10):
		var card_instance = hbox_container.get_child(i)
		if card_instance == null:
			print("❌ Erreur : Impossible de trouver l'enfant à l'indice", i)
			continue  

		if card_instance.has_method("set_card_data"):
			var image_path = all_cards.pop_at(0)  # Retire la carte du deck !
			card_instance.set_card_data(image_path)
			print("🎴 Carte assignée au joueur", i, ":", image_path)
		else:
			print("⚠️ Erreur : L'instance de carte ne possède pas 'set_card_data'.")
