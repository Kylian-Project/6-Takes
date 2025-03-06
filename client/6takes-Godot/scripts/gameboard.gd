extends Node2D

@export var vbox_container: VBoxContainer  # Référence au VBox qui contient les rangées

var all_cards = []  # Liste de toutes les cartes

func _ready():
	if vbox_container == null:
		print("❌ Erreur : vbox_container n'est pas assigné ! Vérifie dans l'inspecteur.")
		return  # Arrête l'exécution si vbox_container est null
	_load_cards()
	_assign_initial_cards()

# Charger toutes les cartes depuis le dossier res://cartes/
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
			var file_path = "res://cartes/" + file_name
			all_cards.append(file_path)
		file_name = dir.get_next()

	dir.list_dir_end()
	print("✅ Cartes chargées :", all_cards)  # Debug final

# Assigner 4 cartes aléatoires aux 4 enfants du VBoxContainer
func _assign_initial_cards():
	if all_cards.size() < 4:
		print("❌ Erreur : Pas assez de cartes pour démarrer !")
		return

	all_cards.shuffle()  # Mélanger les cartes

	for i in range(4):
		var card_instance = vbox_container.get_child(i)  # Récupérer l'instance de la carte
		if card_instance == null:
			print("❌ Erreur : Impossible de trouver l'enfant à l'indice", i)
			continue  # Passe à l'enfant suivant si ce n'est pas trouvé

		if card_instance.has_method("set_card_data"):
			var image_path = all_cards[i]  # Obtenir le chemin de l'image
			card_instance.set_card_data(image_path)  # Passer l'image à la carte
			print("🎴 Carte assignée à la rangée", i, ":", all_cards[i])
		else:
			print("⚠️ Erreur : L'instance de carte ne possède pas la méthode 'set_card_data'.")
