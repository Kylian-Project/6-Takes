extends Node2D

@export var top_bar: HBoxContainer
@onready var timer_label = $HBoxContainer/timer
@onready var score_label = $CanvasLayer/top_bar/nbheads
@onready var state_label = $State_label
@onready var turn_label = $HBoxContainer/turnLabel

@onready var row_panels = [
	$deckContainer/rowsContainer/row1_panel,
	$deckContainer/rowsContainer/row2_panel,
	$deckContainer/rowsContainer/row3_panel,
	$deckContainer/rowsContainer/row4_panel
]

@onready var spplayerleft = $spplayerleft
@onready var spplayerright = $spplayerright

const ICON_PATH = "res://assets/images/icons/"
const CARD_UI_SCENE = preload("res://scenes/card_ui.tscn")
const SpGame = preload("res://scripts/sp_game.gd")

@onready var hbox_container = $CanvasLayer2/HBoxContainer # carte en Main (moi)
@onready var vbox_container = $deckContainer/rowsContainer # rangees sur le plateau
@onready var heads_label = $CanvasLayer/top_bar/nbheads 

var sp_game: SpGame
var timer_duration := 45
var time_left = 45.0
var bot_display_data: Array = []

func _ready():
	print("🟢 Le script est chargé et prêt.")

	for child in hbox_container.get_children():
		child.queue_free()
	for panel in vbox_container.get_children():
		var row = panel.get_child(0)
		for card in row.get_children():
			card.queue_free()

	if Global.game_settings == null:
		print("🔴 Erreur : Global.game_settings est null !")
		return

	if not Global.game_settings.has("bot_count"):
		print("🔴 Erreur : 'bot_count' n'existe pas dans Global.game_settings !")
		return

	sp_game = SpGame.new()
	add_child(sp_game)

	var settings = Global.game_settings
	sp_game.start_game(settings)

	_setup_bot_ui()
	_update_hand()
	_update_plateau()
	_update_heads()
	_start_timer()

	sp_game.tour_repris.connect(_on_tour_repris)

func _on_tour_repris(cartes_choisies):
	for choix in cartes_choisies:
		var joueur = choix["joueur"]
		var carte = choix["carte"]
		for data in bot_display_data:
			if data["bot"] == joueur:
				var card_layer = data["card_layer"]
				#card_layer.clear()
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
	#bot_display_data.clear()

	var all_icons = ["blue.png", "brown.png", "cyan.png", "dark_grey.png", "green.png", "orange.png", "pink.png", "purple.png", "red.png"]
	all_icons.shuffle()

	for i in range(1, bot_count):
		var bot = sp_game.jeu.joueurs[i]
		var container_side = spplayerleft if left_count <= right_count else spplayerright
		if container_side == spplayerleft:
			left_count += 1
		else:
			right_count += 1

		var bot_box = VBoxContainer.new()
		var bot_hbox = HBoxContainer.new()
		var bot_icon = TextureRect.new()
		bot_icon.texture = load(ICON_PATH + all_icons[i % all_icons.size()])
		bot_icon.tooltip_text = "Bot " + str(i)
		bot_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		bot_icon.custom_minimum_size = Vector2(150, 150)
		bot_icon.scale = Vector2(0.6, 0.6)

		var card_layer = Control.new()
		card_layer.custom_minimum_size = Vector2(150, 100)
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(35, 0)

		if container_side == spplayerleft:
			bot_hbox.add_child(bot_icon)
			bot_hbox.add_child(spacer)
			bot_hbox.add_child(card_layer)
		else:
			bot_hbox.add_child(card_layer)
			bot_hbox.add_child(spacer)
			bot_hbox.add_child(bot_icon)

		var name_label = Label.new()
		name_label.text = bot.nom
		bot_box.add_child(bot_hbox)
		bot_box.add_child(name_label)
		container_side.add_child(bot_box)

		bot_display_data.append({"bot": bot, "card_layer": card_layer})

	var human = sp_game.jeu.joueurs[0]
	var human_box = VBoxContainer.new()
	var human_hbox = HBoxContainer.new()
	var human_icon = TextureRect.new()
	human_icon.texture = load(ICON_PATH + "red.png")
	human_icon.tooltip_text = "Joueur Humain"
	human_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	human_icon.custom_minimum_size = Vector2(150, 150)
	human_icon.scale = Vector2(0.6, 0.6)

	var human_card_layer = Control.new()
	human_card_layer.custom_minimum_size = Vector2(150, 100)
	var human_spacer = Control.new()
	human_spacer.custom_minimum_size = Vector2(35, 0)
	human_hbox.add_child(human_card_layer)
	human_hbox.add_child(human_spacer)
	human_hbox.add_child(human_icon)
	var human_name_label = Label.new()
	human_name_label.text = human.nom
	human_box.add_child(human_hbox)
	human_box.add_child(human_name_label)
	spplayerright.add_child(human_box)
	bot_display_data.append({"bot": human, "card_layer": human_card_layer})

	for data in bot_display_data:
		display_cards_for_bot(data["bot"], data["card_layer"])

func display_cards_for_bot(bot, card_layer: Control):
	var cartes = bot.hand.cartes
	for carte in cartes:
		var card_ui = CARD_UI_SCENE.instantiate()
		card_layer.add_child(card_ui)
		card_ui.set_card_data("res://assets/images/cartes/%d.png" % carte.numero, carte.numero)

func _process(delta):
	if sp_game and sp_game.attente_joueur:
		time_left -= delta
		timer_label.text = "00:" + str(int(time_left)).pad_zeros(2)

func _start_timer():
	time_left = timer_duration

func _update_heads():
	var moi = sp_game.jeu.joueurs[0]
	heads_label.text = str(moi.score) + " 🐂"

func _update_hand():
	#hbox_container.clear()
	var moi = sp_game.jeu.joueurs[0]
	for i in range(moi.hand.cartes.size()):
		var carte = moi.hand.cartes[i]
		var card_ui = CARD_UI_SCENE.instantiate()
		hbox_container.add_child(card_ui)
		card_ui.set_card_data("res://assets/images/cartes/%d.png" % carte.numero, carte.numero)
		card_ui.card_index = i
		card_ui.connect("card_selected", Callable(self, "_on_card_selected"))

func _update_plateau():
	for i in range(vbox_container.get_child_count()):
		var row_panel = vbox_container.get_child(i)
		var row = row_panel.get_child(0)
		#row.clear()
		for carte in sp_game.jeu.table.rangs[i].cartes:
			var card_ui = CARD_UI_SCENE.instantiate()
			row.add_child(card_ui)
			card_ui.set_card_data("res://assets/images/cartes/%d.png" % carte.numero, carte.numero)

func _on_carte_cliquee(index):
	if not sp_game.attente_joueur:
		print("⛔ Ce n'est pas encore ton tour.")
		return

	var moi = sp_game.jeu.joueurs[0]
	var carte = moi.hand.jouer_carte(index)
	var card_layer = $spplayerright/HBoxContainer/CardLayer
	if card_layer:
		for child in card_layer.get_children():
			child.queue_free()
		var card_ui = CARD_UI_SCENE.instantiate()
		card_layer.add_child(card_ui)
		card_ui.set_card_data("res://assets/images/cartes/%d.png" % carte.numero, carte.numero)
	else:
		print("❌ CardLayer introuvable")

	if index < hbox_container.get_child_count():
		hbox_container.get_child(index).queue_free()

	sp_game.carte_choisie_moi = {"joueur": moi, "carte": carte}
	sp_game.reprendre_tour()

func setup_from_lobby(players: Array):
	Global.game_players = players
