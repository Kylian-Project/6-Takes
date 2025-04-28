extends Node2D

# Déclaration des variables @export et @onready en haut de la classe
@export var hbox_container: HBoxContainer
@export var top_bar: HBoxContainer
@onready var label_timer = $HBoxContainer/timer
@onready var score_label = $CanvasLayer/top_bar/nbheads
@onready var state_label = $State_label
@onready var label_turn = $HBoxContainer/turnLabel
var current_selected_card_ui: TCardUI = null  # Carte UI sélectionnée
var current_selected_card_data: Dictionary = {}  # Les données de la carte sélectionnée (id, chemin)

@onready var row1 = $deckContainer/rowsContainer/row1_panel/row1
@onready var row2 = $deckContainer/rowsContainer/row2_panel/row2
@onready var row3 = $deckContainer/rowsContainer/row3_panel/row3
@onready var row4 = $deckContainer/rowsContainer/row4_panel/row4

@onready var row_panels = [
	$deckContainer/rowsContainer/row1_panel,
	$deckContainer/rowsContainer/row2_panel,
	$deckContainer/rowsContainer/row3_panel,
	$deckContainer/rowsContainer/row4_panel
]

@onready var row_buttons = [
	$deckContainer/rowsContainer/row1_panel/row1/selectRowButton,
	$deckContainer/rowsContainer/row2_panel/row2/selectRowButton,
	$deckContainer/rowsContainer/row3_panel/row3/selectRowButton,
	$deckContainer/rowsContainer/row4_panel/row4/selectRowButton
]

@export var spplayerleft : VBoxContainer  # Assurez-vous que spplayerleft est assigné depuis l'éditeur
@export var spplayerright : VBoxContainer

var all_cards = []
var selected_cards = []
var round_duration = Global.game_settings.get("round_timer", 60)
var time_left = round_duration

@onready var pause_screen_scene = preload("res://scenes/screen_pause.tscn")
@onready var card_ui_scene = preload("res://scenes/card_ui.tscn")
@export var bot_scene: PackedScene = preload("res://scenes/BotSlot.tscn")

var pause_instance = null
var bots_info = []
# Carte sélectionnée
var carte_selectionnee = null

var jeu: Jeu6Takes
var table: Table  # Déclare une variable 'table' de type Table
var deck: Deck  # Déclare une variable pour le deck
var cartes_choisies := []
var joueur_en_attente := 0
var nb_joueurs : int 
const BotLogic = preload("res://scripts/singleplayer/bot_logic.gd")
var main_bots = []
var cartes_bots = BotLogic.choisir_cartes_bots(main_bots)

# Fonction _ready()
func _ready():
	deck = Deck.new()  # Initialise le deck
	table = Table.new(deck)  # Initialise la table avec le deck

	if table == null:
		print("❌ Table non initialisée!")
		return
	print("Deck et table initialisés avec succès.")

	# Crée une instance de la carte UI
	var card_instance = card_ui_scene.instantiate()
	card_instance.gameboardSP = self
	print("Référence du gameboardSP:", card_instance.gameboardSP.name)

	print_tree_pretty()

	# Vérification des nœuds essentiels
	if label_timer == null:
		print("❌ Erreur : label_timer est nul.")
		return

	if spplayerleft == null:
		print("❌ Erreur : spplayerleft est nul.")
		return

	if spplayerright == null:
		print("❌ Erreur : spplayerright est nul.")
		return

	# Vérifier que les bons types de conteneurs sont utilisés
	assert(spplayerleft is VBoxContainer, "spplayerleft n'est pas un VBoxContainer !")
	assert(spplayerright is VBoxContainer, "spplayerright n'est pas un VBoxContainer !")

	_load_cards()
	_assign_vbox_cards()
	_assign_hbox_cards()

	# Connexion aux signaux proprement (éviter double connexion)
	for child in hbox_container.get_children():
		if child is TCardUI:
			if not child.is_connected("card_selected", Callable(self, "_on_card_selected")):
				child.connect("card_selected", Callable(self, "_on_card_selected"))

	# 👇 Maintenant, pour créer dynamiquement un nombre variable de joueurs
	var liste_noms = ["Alice", "Bob", "Charlie", "Diana"]  # 👉 Tu mets les noms que tu veux ici
	jeu = Jeu6Takes.new(liste_noms.size(), liste_noms)

	afficher_table()
	afficher_main()


# Exemple d'appel de la fonction
func commencer_tour():
	print("Tous les joueurs ont choisi une carte. Le tour peut commencer.")
	
	# Appel de la fonction determiner_premier_joueur() depuis l'objet Jeu6Takes
	var joueur_avec_plus_petite_carte = jeu.determiner_premier_joueur(cartes_choisies)
	print(joueur_avec_plus_petite_carte, "commence à jouer.")
	
	# Commence à poser les cartes sur les rangs
	jeu.poser_cartes_sur_rangs(cartes_choisies)

# Tour
func update_turn_display(current_turn: int):
	var max_turns = selected_cards.size()
	label_turn.text = "Turn  %d/%d" % [current_turn, max_turns]

# Lobby
func setup_from_lobby(players: Array):
	bots_info.clear()
	for name in players:
		bots_info.append({"bot_name": name})
	display_bots()


func display_bots():
	# Vérifie si spplayerleft et spplayerright sont non null avant d'ajouter des enfants
	if spplayerleft == null or spplayerright == null:
		print("❌ Erreur : spplayerleft ou spplayerright est nul.")
		return

	# Effacer les enfants existants des deux panneaux avant de les remplir
	for child in spplayerleft.get_children():
		child.queue_free()

	for child in spplayerright.get_children():
		child.queue_free()

	# Assurez-vous qu'on a bien des icônes de bots à afficher
	for i in range(bots_info.size()):
		var bot = bots_info[i]
		var bot_icon = create_bot_icon(bot)
		if bot_icon == null:
			continue
		if i % 2 == 0:
			spplayerleft.add_child(bot_icon)
		else:
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

	icon.set_custom_minimum_size(Vector2(0.5, 3))
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return icon

# Pause
func _on_open_pause_button_pressed() -> void:
	if pause_instance == null:
		pause_instance = pause_screen_scene.instantiate()
		add_child(pause_instance)
		await get_tree().process_frame
		pause_instance.position = get_viewport_rect().size / 2 - pause_instance.size / 2
	pause_instance.move_to_front()
	pause_instance.visible = true

# Cartes
func _load_cards():
	var dir_path = "res://assets/images/cartes/"
	var dir = DirAccess.open(dir_path)
	if dir == null:
		print("❌ Erreur : Impossible d'ouvrir le dossier des cartes.")
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".png") and not file_name.ends_with(".import"):
			var card_id = int(file_name.get_basename())
			all_cards.append({"id": card_id, "path": dir_path + file_name})
		file_name = dir.get_next()
	dir.list_dir_end()
	all_cards.shuffle()

func _assign_vbox_cards():
	if all_cards.size() < 4:
		print("❌ Pas assez de cartes pour la rangée.")
		return

	var rows = [row1, row2, row3, row4]
	for i in range(4):
		var row = rows[i]
		for child in row.get_children():
			child.queue_free()

		var card_instance = card_ui_scene.instantiate()
		row.add_child(card_instance)

		if card_instance.has_method("set_card_data"):
			var card = all_cards.pop_front()
			card_instance.set_card_data(card["path"], card["id"])
			selected_cards.append(card)
			print("🃏 Carte assignée à la rangée", i, "avec ID", card["id"], ":", card["path"])
		else:
			print("❌ Carte sans méthode 'set_card_data'.")

func _assign_hbox_cards():
	# Nombre de cartes à attribuer, basé sur la configuration globale ou un fallback
	var cards_to_assign = Global.game_settings.get("nb_cartes", 10)  # fallback à 10 si absent

	if all_cards.size() < cards_to_assign:
		print("❌ Erreur : Pas assez de cartes pour le joueur !")
		return

	# Nettoyer les anciennes cartes dans hbox_container avant d'ajouter les nouvelles
	for child in hbox_container.get_children():
		child.queue_free()

	# Liste des cartes sélectionnées
	selected_cards.clear()  # Assurez-vous de vider la liste avant d'ajouter de nouvelles cartes

	# Assigner les cartes
	for i in range(cards_to_assign):
		var card_instance = card_ui_scene.instantiate()
		hbox_container.add_child(card_instance)
		
		if card_instance.has_method("set_card_data"):
			var card = all_cards.pop_front()
			card_instance.set_card_data(card["path"], card["id"])
			selected_cards.append(card)

			# ➡️ Connecte le signal ici !
			card_instance.connect("card_selected", Callable(self, "_on_card_selected"))
			print("🃏 Carte assignée à la rangée", i, "avec ID", card["id"], ":", card["path"])
		else:
			print("❌ Erreur : L'instance de carte ne possède pas 'set_card_data'.")

	# Après avoir attribué les cartes, mettre à jour l'affichage du tour
	update_turn_display(1)  # Par exemple, on commence au tour 1 (ou à un autre tour selon le jeu)


# Timer
func start_round_timer():
	time_left = round_duration
	label_timer.text = str(time_left)

func _on_timer_timeout():
	time_left -= 1
	label_timer.text = str(time_left) + " s"

# Card flipping utils
@onready var texture_rect = $TextureRect
var card_id

func flip_card():
	toggle_texture_visibility(true)

func toggle_texture_visibility(visible: bool):
	texture_rect.visible = visible

func start_flip_timer(duration: float):
	await get_tree().create_timer(duration).timeout
	flip_card()

func _on_card_pressed():
	emit_signal("card_selected", card_id)

func distribute_cards():
	var cards_to_assign = Global.game_settings.get("nb_cartes", 10)
	var total_players = 1 + Global.game_settings.get("bot_count", 1)  # 1 joueur + le nombre de bots
	var cards_per_player = cards_to_assign / total_players  # On distribue les cartes également entre les joueurs

	# Distribution des cartes
	for i in range(total_players):
		var player_cards = []
		for j in range(cards_per_player):
			if all_cards.size() > 0:
				var card = all_cards.pop_front()
				player_cards.append(card)  # Ajouter la carte dans la main du joueur
				print("🃏 Carte attribuée à", "Bot" if i > 0 else "Joueur", i, "avec ID", card["id"], ":", card["path"])

		# En fonction de l'index du joueur, ajouter ses cartes à l'endroit approprié
		if i == 0:
			# Distribuer les cartes au joueur
			add_cards_to_player(player_cards, spplayerleft)
		else:
			# Distribuer les cartes aux bots
			add_cards_to_player(player_cards, spplayerright)  # Adapte cela pour gérer plusieurs bots si nécessaire

func add_cards_to_player(player_cards: Array, player_node: Node):
	for card in player_cards:
		var card_instance = card_ui_scene.instantiate()
		player_node.add_child(card_instance)
		if card_instance.has_method("set_card_data"):
			card_instance.set_card_data(card["path"], card["id"])
			print("🃏 Carte assignée à", player_node.name, "avec ID", card["id"], ":", card["path"])
		else:
			print("❌ Erreur : L'instance de carte ne possède pas 'set_card_data'.")
# Quand une carte est cliquée
# Fonction appelée lors de la sélection d'une carte par un joueur
func _on_card_selected(card_id):
	print("Carte sélectionnée:", card_id)

	# Trouver la carte sélectionnée dans la main du joueur
	for child in hbox_container.get_children():
		if child is TCardUI and child.global_card_id == card_id:
			current_selected_card_ui = child
			current_selected_card_data = {
				"id": card_id,
				"path": child.get_node("Front_texture").texture.resource_path
			}
			print("✅ Carte sélectionnée:", current_selected_card_data)
			break

	# Ajouter la carte sélectionnée à la liste des cartes choisies
	if current_selected_card_data:
		cartes_choisies.append(current_selected_card_data)
		joueur_en_attente += 1

	# Une fois que tous les joueurs ont choisi leurs cartes, y compris les bots
	if joueur_en_attente == jeu.nb_joueurs:
		print("Tous les joueurs ont choisi leurs cartes.")

		# Appeler la fonction pour que les bots choisissent leurs cartes aussi
		var cartes_bots = BotLogic.choisir_cartes_bots(jeu.joueurs)  # main_bots est un tableau contenant les cartes disponibles pour les bots

		print("Cartes choisies par les bots:", cartes_bots)

		# Ajouter les cartes choisies par les bots à la liste des cartes choisies
		cartes_choisies += cartes_bots

		# Préparer les cartes à jouer pour tous les joueurs
		jeu.preparer_cartes_jeu()  # Appelle la méthode dans Jeu6Takes pour distribuer les cartes et préparer le jeu

		# Commencer le tour du jeu après que tous les joueurs ont choisi leur carte
		commencer_tour()  # Par exemple, une fonction pour commencer le tour de jeu


# Dans le script gameboard

func validate_selected_card():
	if current_selected_card_ui == null:
		print("❌ Aucune carte sélectionnée.")
		return

	if table == null:
		print("❌ Table non initialisée!")
		return

	var carte_instance = Carte.new(current_selected_card_data["id"])

	# Trouver la meilleure rangée pour la carte
	var best_row_index = jeu.trouver_best_rang(carte_instance)
	var index_a_ramasser = -1  # Index pour la rangée à ramasser si nécessaire
	var nb_tetes = 0  # Nombre de têtes des cartes ramassées
	var final_row_index = -1  # Déclarer final_row_index ici pour être accessible partout

	# Si aucune rangée n'est adaptée, il faut ramasser une rangée
	if best_row_index == -1:
		print("😰 Aucune rangée adaptée, il faut ramasser une rangée.")
		
		# Trouver la rangée à ramasser
		index_a_ramasser = jeu.trouver_rang_a_ramasser()

		# Ramasser les cartes et calculer le nombre de têtes
		var cartes_ramassees = table.rangs[index_a_ramasser].recuperer_cartes_special_case()
		
		# Calculer le nombre de têtes des cartes ramassées
		for c in cartes_ramassees:
			nb_tetes += c.tetes

		# Vider la rangée et poser la carte
		table.rangs[index_a_ramasser].cartes.clear()
		table.rangs[index_a_ramasser].ajouter_carte(carte_instance)

		# Nettoyer l'UI de la rangée ramassée (optionnel si tu veux enlever les anciennes cartes visuellement)
		var row_ui = row_panels[index_a_ramasser]  # Utiliser l'index de la rangée
		if row_ui:
			for child in row_ui.get_children():
				child.queue_free()  # Effacer visuellement les anciennes cartes

		# Utiliser le final_row_index pour cette rangée
		final_row_index = index_a_ramasser
	else:
		# Ajouter la carte à la rangée sélectionnée (si une rangée est disponible)
		var best_row = table.rangs[best_row_index]
		best_row.ajouter_carte(carte_instance)
		final_row_index = best_row_index  # Mettre à jour le final_row_index avec la rangée où la carte a été ajoutée

	# Ajouter la carte dans l'UI
	if card_ui_scene != null:
		var card_instance_ui = card_ui_scene.instantiate()

		if card_instance_ui != null:
			# Utiliser le tableau row_panels pour trouver la bonne rangée visuelle
			var row_ui = row_panels[final_row_index]

			if row_ui != null:
				# Ajouter la carte dans la bonne rangée de l'UI
				row_ui.add_child(card_instance_ui)
				if card_instance_ui.has_method("set_card_data"):
					card_instance_ui.set_card_data(current_selected_card_data["path"], current_selected_card_data["id"])
				card_instance_ui.visible = true
			else:
				print("❌ Rangée UI introuvable.")
		else:
			print("❌ Instanciation de la carte UI échouée.")
	else:
		print("❌ Scene UI non définie.")

	# Mettre à jour le label nbheads
	var nbheads_label = get_node("$CanvasLayer/top_bar/nbheads")
	if nbheads_label:
		var current_heads = int(nbheads_label.text)
		nbheads_label.text = str(current_heads + nb_tetes)

	# Après avoir ajouté une carte à la rangée, vérifier si la rangée contient 6 cartes
	var row_ui = row_panels[final_row_index]  # On s'assure de récupérer la bonne rangée
	if row_ui and row_ui.get_child_count() == 6:
		print("🃏 Sixième carte déposée, ramassage de la rangée !")
		
		# Ramasser les cartes de la rangée
		var cartes_ramassees = table.rangs[final_row_index].recuperer_cartes_special_case()
		nb_tetes = 0  # Recalculer le nombre de têtes pour cette rangée
		for c in cartes_ramassees:
			nb_tetes += c.tetes
		print("Nombre de têtes ramassées: ", nb_tetes)

		# Mettre à jour le score (nombre de têtes)
		if nbheads_label:
			var current_heads = int(nbheads_label.text)
			nbheads_label.text = str(current_heads + nb_tetes)

	# Reset la sélection de carte
	current_selected_card_ui = null
	current_selected_card_data = {}

	print("✅ Carte ajoutée et affichée.")



# Quand une carte est cliquée
func _on_card_clicked(card_data):
	carte_selectionnee = card_data
	print("✅ Carte sélectionnée :", carte_selectionnee)

func _on_select_row_button_pressed(row_index: int):
	if current_selected_card_ui == null:
		print("❌ Aucun carte sélectionnée.")
		return

	var row = row_panels[row_index]
	var card_instance = card_ui_scene.instantiate()
	card_instance.set_card_data(current_selected_card_data["path"], current_selected_card_data["id"])
	row.add_child(card_instance)
	# Mettez à jour la rangée dans le modèle de données du jeu
	var rang = table.rangs[row_index]
	rang.ajouter_carte(Carte.new(current_selected_card_data["id"]))
	current_selected_card_ui = null
	current_selected_card_data = {}

func afficher_table():
	# Parcourir jeu.table.rangs et afficher les cartes graphiquement
	pass

func afficher_main():
	# Parcourir jeu.joueurs[0].hand.cartes et afficher la main
	pass

func _on_carte_cliquee(carte):
	# Jouer la carte
	var result = jeu.jouer_carte("Alice", carte)
	if result == "choix_rang_obligatoire":
		# afficher une popup pour demander à choisir un rang
		pass
	# Mettre à jour l'affichage après le coup
	afficher_table()
	afficher_main()
func find_best_row(card_number: int) -> int:
	# Vérifie si table est initialisé
	if table == null:
		print("❌ Table non initialisée!")
		return -1  # Retourne une valeur d'erreur si table est null
	
	# Recherche le meilleur rang en fonction du numéro de carte
	var best_diff = -1
	var best_index = -1
	
	for i in range(table.rangs.size()):
		var rang = table.rangs[i]
		if rang.cartes.size() == 0:  # Si le rang est vide, c'est un bon choix
			best_index = i
			break
		
		var derniere = rang.cartes[-1]
		var diff = card_number - derniere.numero
		
		# Si la carte peut être placée dans la rangée (diff > 0)
		if diff > 0:
			if best_diff == -1 or diff < best_diff:  # Cherche le rang avec l'écart minimum
				best_diff = diff
				best_index = i
	
	return best_index  # Retourne l'indice du meilleur rang

func placer_carte(carte_info):
	var carte_instance = Carte.new(carte_info["id"])

	var best_row_index = jeu.trouver_best_rang(carte_instance)
	var final_row_index = -1

	if best_row_index == -1:
		# Aucune rangée adaptée → ramasser une rangée
		var index_a_ramasser = jeu.trouver_rang_a_ramasser()
		var cartes_ramassees = table.rangs[index_a_ramasser].recuperer_cartes_special_case()

		# Vider la rangée
		table.rangs[index_a_ramasser].cartes.clear()
		table.rangs[index_a_ramasser].ajouter_carte(carte_instance)

		final_row_index = index_a_ramasser

		# Update UI visuelle de la rangée (effacer les anciennes cartes)
		var row_ui = row_panels[index_a_ramasser]
		if row_ui:
			for child in row_ui.get_children():
				child.queue_free()
	else:
		# Rangée trouvée → ajouter la carte
		table.rangs[best_row_index].ajouter_carte(carte_instance)
		final_row_index = best_row_index

	# Update visuel : placer la carte
	var card_instance_ui = card_ui_scene.instantiate()
	var row_ui = row_panels[final_row_index]
	if card_instance_ui and row_ui:
		row_ui.add_child(card_instance_ui)
		if card_instance_ui.has_method("set_card_data"):
			card_instance_ui.set_card_data(carte_info["path"], carte_info["id"])
		card_instance_ui.visible = true

	# Si une rangée atteint 6 cartes → la ramasser
	if row_ui.get_child_count() == 6:
		print("🃏 6 cartes, ramassage obligatoire !")
		var cartes_ramassees = table.rangs[final_row_index].recuperer_cartes_special_case()
		table.rangs[final_row_index].cartes.clear()
		table.rangs[final_row_index].ajouter_carte(carte_instance)

		# (Tu peux ici mettre à jour les points/têtes de boeuf du joueur)

func poser_cartes_en_ordre():
	print("🎯 Toutes les cartes sélectionnées. Placement en cours...")

	# Trier par ID (ordre croissant)
	cartes_choisies.sort_custom(func(a, b): return a["id"] < b["id"])

	# Placer chaque carte
	for carte_info in cartes_choisies:
		placer_carte(carte_info)

	# Reset pour prochaine manche
	cartes_choisies.clear()
	joueur_en_attente = 0
	current_selected_card_ui = null
	current_selected_card_data = {}

func bot_play():
	# Le bot choisit une carte (on peut ajouter une logique plus complexe ici)
	if spplayerright.get_child_count() > 0:  # Vérifier si le bot a des cartes
		var bot_card = spplayerright.get_child(0)  # Sélectionner la première carte
		_on_card_selected(bot_card.global_card_id)  # Marquer la carte comme sélectionnée
		poser_cartes_en_ordre()  # Mettre la carte dans la rangée
		afficher_table()  # Actualiser la table
var current_turn = 1
var total_turns = 10  # Exemple : nombre total de tours

func next_turn():
	if current_turn <= total_turns:
		print("Tour %d/%d" % [current_turn, total_turns])
		current_turn += 1
		# Gérer le tour du bot ou du joueur
		if current_turn % 2 == 0:  # Exemple : les tours pairs sont pour les bots
			bot_play()
		else:
			# Le joueur humain joue
			print("C'est votre tour!")
		# Mettre à jour l'affichage du tour
		update_turn_display(current_turn)
func commencer_partie():
	print("La partie commence avec", jeu.joueurs.size(), "joueurs.")
	for joueur in jeu.joueurs:
		print("Bot:", joueur.nom, "Score:", joueur.score)
