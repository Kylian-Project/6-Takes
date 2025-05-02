extends Node2D


@export var top_bar: HBoxContainer  # Conteneur HBox pour les labels
@onready var timer_label = $HBoxContainer/timer
@onready var score_label = $CanvasLayer/top_bar/nbheads
@onready var state_label = $State_label
@onready var turn_label = $HBoxContainer/turnLabel

#deck ui 
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

#players ui
# Variables pour accéder aux CardLayer des deux côtés
@onready var spplayerleft_card_layer = $spplayerleft/CardLayer
@onready var spplayerright_card_layer = $spplayerright/CardLayer

#players icons
const ICON_PATH = "res://assets/images/icons/"
const ICON_FILES = [
	"dark_grey.png", "blue.png", "brown.png", "green.png", 
	"orange.png", "pink.png", "purple.png", "red.png",
	"reversed.png", "cyan.png"
]

# Listes de cartes
var all_cards = []  # Liste de toutes les cartes disponibles
var selected_cards = []  # Liste des cartes déjà utilisées
var player_username 

# Chargement des scènes
@onready var pause_screen_scene = preload("res://scenes/screen_pause.tscn")
@onready var card_ui_scene = preload("res://scenes/card_ui.tscn")  

# Instance de l'écran de pause
var pause_instance = null

@onready var spplayerleft = $spplayerleft
@onready var spplayerright = $spplayerright

const CARD_UI_SCENE = preload("res://scenes/card_ui.tscn")

const SpGame = preload("res://scripts/sp_game.gd")

@onready var hbox_container = $CanvasLayer2/HBoxContainer
@onready var vbox_container = $deckContainer/rowsContainer

@onready var heads_label = $CanvasLayer/top_bar/nbheads



var sp_game: SpGame
var selected_card_node = null
var timer_duration := 45
var time_left = 45.0
var bot_display_data: Array = []





func _ready():
	print("🟢 Le script est chargé et prêt.")
	

	

	# Nettoyer les enfants existants
	for child in hbox_container.get_children():
		child.queue_free()
	for panel in vbox_container.get_children():
		var row = panel.get_child(0)
		for card in row.get_children():
			card.queue_free()

	# Vérifier si les paramètres du jeu sont bien définis
	if Global.game_settings == null:
		print("🔴 Erreur : Global.game_settings est null !")
		return  # Arrêter l'exécution si les paramètres ne sont pas chargés

	# Vérifier que la clé 'bot_count' existe dans les paramètres
	if not Global.game_settings.has("bot_count"):
		print("🔴 Erreur : 'bot_count' n'existe pas dans Global.game_settings !")
		return  # Arrêter l'exécution si la clé 'bot_count' manque
	
	# Initialiser le jeu solo
	sp_game = SpGame.new()
	add_child(sp_game)

	var settings = Global.game_settings
	var bot_count = settings.get("bot_count", 0)  # Valeur par défaut 0 si la clé n'existe pas
	var nb_cartes = settings.get("nb_cartes", 0)
	var nb_max_heads = settings.get("nb_max_heads", 0)
	var nb_max_manches = settings.get("nb_max_manches", 0)
	var round_timer = settings.get("round_timer", 0)

	sp_game.start_game({
		"bot_count": bot_count,
		"nb_cartes": nb_cartes,
		"nb_max_heads": nb_max_heads,
		"nb_max_manches": nb_max_manches,
		"round_timer": round_timer
	})
	_setup_bot_ui()
	# Charger et mettre à jour les éléments du jeu
	#_load_icons()
	_update_hand()
	_update_plateau()
	_update_heads()
	_start_timer()
	_load_cards()
	_assign_vbox_cards()
	_assign_hbox_cards()
	_on_carte_cliquee(0)
	sp_game.tour_repris.connect(_on_tour_repris)
	# Debugging
	print("🔍 Debug: joueurs =", sp_game.jeu.joueurs)
	print("🔍 Debug: main joueur =", sp_game.jeu.joueurs[0].hand.cartes)
	print("🔍 Debug: rangées =", sp_game.jeu.table.rangs)

	print("🟢 Le script est chargé ")


func _on_tour_repris(cartes_choisies):
	for choix in cartes_choisies:
		var joueur = choix["joueur"]
		var carte = choix["carte"]

		for data in bot_display_data:
			if data["bot"] == joueur:
				var card_layer = data["card_layer"]
				card_layer.clear()

				var card_sprite = TextureRect.new()
				card_sprite.texture = load("res://assets/images/cartes/%d.png" % carte.numero)
				card_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				card_sprite.custom_minimum_size = Vector2(100, 150)
				card_layer.add_child(card_sprite)
				break


func _setup_bot_ui():
	var bot_count = sp_game.jeu.joueurs.size()
	var left_count = 0
	var right_count = 0
	bot_display_data.clear()

	# Liste des icônes pour les bots
	var all_icons = [
		"blue.png", "brown.png", "cyan.png", "dark_grey.png",
		"green.png", "orange.png", "pink.png", "purple.png", "red.png"
	]
	all_icons.shuffle()

	# === BOTS ===
	# Placer d'abord les bots à gauche ou à droite en fonction de leur nombre
	for i in range(1, bot_count):
		var bot = sp_game.jeu.joueurs[i]

		var container_side: VBoxContainer
		if left_count <= right_count:
			container_side = spplayerleft
			left_count += 1
		else:
			container_side = spplayerright
			right_count += 1

		var bot_box = VBoxContainer.new()
		bot_box.name = "Bot" + str(i)

		var bot_hbox = HBoxContainer.new()
		bot_hbox.name = "BotHBox" + str(i)

		var bot_icon = TextureRect.new()
		bot_icon.name = "BotIcon"
		bot_icon.texture = load(ICON_PATH + all_icons[i % all_icons.size()])
		bot_icon.tooltip_text = "Bot " + str(i)
		bot_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		bot_icon.expand = true
		bot_icon.custom_minimum_size = Vector2(150, 150)
		bot_icon.scale = Vector2(0.6, 0.6)

		var card_layer = Control.new()
		card_layer.name = "CardLayer"
		card_layer.custom_minimum_size = Vector2(150, 100)

		# Créer un spacer pour ajouter de l'espacement entre l'icône et les cartes
		var spacer = Control.new()
		spacer.name = "Spacer"
		spacer.custom_minimum_size = Vector2(35, 0)  # L'espacement horizontal entre l'icône et les cartes

		# Inverser l'ordre si à droite (cartes d'abord, puis l'icône)
		if container_side == spplayerleft:
			bot_hbox.add_child(bot_icon)
			bot_hbox.add_child(spacer)  # Ajouter le spacer entre l'icône et les cartes
			bot_hbox.add_child(card_layer)
		else:
			bot_hbox.add_child(card_layer)
			bot_hbox.add_child(spacer)  # Ajouter le spacer entre les cartes et l'icône
			bot_hbox.add_child(bot_icon)

		var name_label = Label.new()
		name_label.name = "name_bot"
		name_label.text = bot.nom if bot.has_method("nom") else "Bot " + str(i)

		bot_box.add_child(bot_hbox)
		bot_box.add_child(name_label)

		container_side.add_child(bot_box)

		bot_display_data.append({
			"bot": bot,
			"card_layer": card_layer
		})

	# === JOUEUR HUMAIN ===
	# Le joueur humain sera toujours ajouté en dernier à droite après les bots
	var human = sp_game.jeu.joueurs[0]
	var human_box = VBoxContainer.new()
	human_box.name = "Human"

	var human_hbox = HBoxContainer.new()
	human_hbox.name = "HumanHBox"

	var human_icon = TextureRect.new()
	human_icon.name = "HumanIcon"
	human_icon.texture = load(ICON_PATH + "red.png")
	human_icon.tooltip_text = "Joueur Humain"
	human_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	human_icon.expand = true
	human_icon.custom_minimum_size = Vector2(150, 150)
	human_icon.scale = Vector2(0.6, 0.6)

	var human_card_layer = Control.new()
	human_card_layer.name = "CardLayer"
	human_card_layer.custom_minimum_size = Vector2(150, 100)

	# Ajouter un spacer pour l'espacement entre l'icône et les cartes du joueur humain
	var human_spacer = Control.new()
	human_spacer.name = "HumanSpacer"
	human_spacer.custom_minimum_size = Vector2(35, 0)  # Espacement horizontal

	# Ajouter l'icône et le spacer, puis la couche des cartes (inversé pour le joueur à droite)
	human_hbox.add_child(human_card_layer)
	human_hbox.add_child(human_spacer)  # Ajouter le spacer entre les cartes et l'icône
	human_hbox.add_child(human_icon)

	var human_name_label = Label.new()
	human_name_label.name = "name_human"
	human_name_label.text = human.nom if human.has_method("nom") else "Moi"

	human_box.add_child(human_hbox)
	human_box.add_child(human_name_label)

	# Ajouter à la droite après les bots
	spplayerright.add_child(human_box)
	bot_display_data.append({
		"bot": human,
		"card_layer": human_card_layer
	})

	# === Afficher les cartes
	for data in bot_display_data:
		display_cards_for_bot(data["bot"], data["card_layer"])

func display_cards_for_bot(bot, card_layer: Control):
	var cartes = bot.hand.cartes
	for i in range(cartes.size()):
		var carte = cartes[i]
		var card_ui = CARD_UI_SCENE.instantiate()
		card_layer.add_child(card_ui)

		var texture_path = "res://assets/cards/" + str(carte.numero) + ".png"
		if card_ui.has_method("set_card_data"):
			card_ui.set_card_data(texture_path, carte.numero)

func _process(delta):
	if sp_game and sp_game.attente_joueur:
		time_left -= delta
		timer_label.text = "00:" + str(int(time_left)).pad_zeros(2)

# Fonction pour charger les icônes des bots et les ajouter à la scène


func _start_timer():
	time_left = timer_duration

func _update_heads():
	var moi = sp_game.jeu.joueurs[0]
	heads_label.text = str(moi.score) + " \uD83D\uDC02"

func _update_hand():
	var moi = sp_game.jeu.joueurs[0]  # Supposons que c'est un joueur
	for i in range(moi.hand.cartes.size()):
		var carte = moi.hand.cartes[i]  # Récupère la carte courante
		var card_ui = CARD_UI_SCENE.instantiate()  # Crée une instance de la scène de carte UI
		hbox_container.add_child(card_ui)  # Ajoute le card_ui à l'UI

		# Passe les données de la carte au TCardUI
		card_ui.set_card_data(carte.path, carte.numero)

		# Attribue l'index à chaque carte (renommé ici pour éviter le conflit)
		card_ui.card_index = i  # Remarquez le changement à card_index au lieu de index

		# Connecte l'événement de sélection de carte
		card_ui.connect("card_selected", Callable(self, "_on_card_selected"))

func _update_plateau():
	for i in range(vbox_container.get_child_count()):
		var row_panel = vbox_container.get_child(i)
		var row = row_panel.get_child(0)  # Assurez-vous que `row` est bien le conteneur où vous voulez ajouter les cartes
		
		for carte in sp_game.jeu.table.rangs[i].cartes:
			var card_ui = CARD_UI_SCENE.instantiate()
			row.add_child(card_ui)
			card_ui.set_card_data("res://assets/images/cartes/%d.png" % carte.numero, carte.numero)

			

func _on_carte_cliquee(index):
	print("🟢 Carte choisie !")

	if not sp_game.attente_joueur:
		print("⛔ Ce n'est pas encore ton tour.")
		return

	var moi = sp_game.jeu.joueurs[0]
	var carte = moi.hand.jouer_carte(index)

	# 🟢 Utilise la scène CARD_UI_SCENE pour instancier une carte
	var card_layer = $spplayerright/HBoxContainer/CardLayer
	if card_layer:
		# Supprimer tous les enfants du card_layer (manuellement)
		for child in card_layer.get_children():
			child.queue_free()  # Supprimer chaque enfant du card_layer

		var card_ui = CARD_UI_SCENE.instantiate()
		card_layer.add_child(card_ui)

		var texture_path = "res://assets/cards/" + str(carte.numero) + ".png"
		if card_ui.has_method("set_card_data"):
			card_ui.set_card_data(texture_path, carte.numero)
			print("🃏 Carte %d placée via CARD_UI_SCENE." % carte.numero)
		else:
			print("❌ card_ui n'a pas de méthode set_card_data()")

	else:
		print("❌ CardLayer introuvable")

	# Supprimer la carte jouée de la main
	if index < hbox_container.get_child_count():
		hbox_container.get_child(index).queue_free()
		print("🧹 Carte %d retirée de la main." % carte.numero)

	sp_game.carte_choisie_moi = {"joueur": moi, "carte": carte}
	sp_game.reprendre_tour()

func setup_from_lobby(players: Array):
	print("🟢 Le script est ")
	# Ici players contient ["You", "Bot 1", "Bot 2", ...]
	print("🎮 Setup depuis le lobby : joueurs =", players)

#Tu pourrais sauvegarder la liste si besoin
	Global.game_players = players

	# (Optionnel) Tu pourrais initialiser certaines infos visuelles ici aussi
# Fonction pour charger les cartes depuis le dossier
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


# Assigner les cartes dans les rangées
func _assign_vbox_cards():
	if all_cards.size() < 4:
		print("❌ Pas assez de cartes pour la rangée.")
		return
		

	var rows = [row1, row2, row3, row4]
	for i in range(4):
		var row = rows[i]
		for child in row.get_children():
			child.queue_free()
			print("B")
		print("ABC")
		# Assigner une carte à chaque rangée
		var card_instance = card_ui_scene.instantiate()
		row.add_child(card_instance)
		
		if card_instance.has_method("set_card_data"):
			var card = all_cards.pop_front()
			card_instance.set_card_data(card["path"], card["id"])
			selected_cards.append(card)
			print("🃏 Carte assignée à la rangée", i, "avec ID", card["id"], ":", card["path"])
		else:
			print("❌ Carte sans méthode 'set_card_data'.")
# Exemple de mise à jour de l'affichage du tour
func update_turn_display(turn_number: int):
	turn_label.text = "Turn : " + str(turn_number)

func _assign_hbox_cards():
	
	update_turn_display(1)
	# Maintenant, on distribue les cartes aux bots
	_distribute_cards_to_bots()


func _distribute_cards_to_bots():
	var cards_per_player = Global.game_settings.get("nb_cartes", 10)
	all_cards.shuffle()

	# Distribution des cartes pour les bots et pour le joueur "Moi"
	for data in bot_display_data:
		# Distribution des cartes pour le joueur humain ("Moi")
		if data["bot"] == sp_game.jeu.joueurs[0]:  # Le joueur humain (Moi)
			var card_layer = hbox_container  # Utilise hbox_container pour le joueur humain
			_distribute_cards_for_player(card_layer, cards_per_player)

		# Distribution des cartes pour les bots
		elif data.has("bot"):
			var bot = data["bot"]
			var card_layer = data["card_layer"]
			_distribute_cards_for_player(card_layer, cards_per_player, bot)

		else:
			print("Erreur : le bot n'existe pas dans les données.", data)

# Fonction auxiliaire pour distribuer les cartes dans le conteneur spécifié
func _distribute_cards_for_player(card_layer: Control, cards_per_player: int, bot = null):
	# Nettoyer les anciennes cartes dans card_layer (le conteneur de cartes)
	for child in card_layer.get_children():
		child.queue_free()

	# Distribuer les cartes
	var cards_assigned = 0
	while cards_assigned < cards_per_player and not all_cards.is_empty():
		var card = all_cards.pop_front()
		var card_instance = card_ui_scene.instantiate()

		# Ajouter la carte dans le conteneur
		card_layer.add_child(card_instance)

		# Assignation de la carte sans `set_card_data`
		card_instance.set_card_data("res://assets/images/cartes/%d.png" % card["id"], card["id"])

		# Mettre la carte dans le bon conteneur et mettre à jour
		print("🃏 Carte:", card["id"], "distribuée à", bot.nom if bot else "Moi")

		cards_assigned += 1
