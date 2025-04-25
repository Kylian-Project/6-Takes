extends Node2D

const CARD_UI_SCENE = preload("res://scenes/card_ui.tscn")
const ICON_PATH = "res://assets/images/icons/"
const Jeu6Takes = preload("res://scripts/singleplayer/jeu6takes.gd")
const BotLogic = preload("res://scripts/singleplayer/bot_logic.gd")
const SpGame = preload("res://scripts/sp_game.gd")

@onready var hbox_container = $CanvasLayer2/HBoxContainer
@onready var vbox_container = $deckContainer/rowsContainer
@onready var player_icons = $LPlayer_container
@onready var heads_label = $CanvasLayer/top_bar/nbheads
@onready var turn_label = $HBoxContainer/turnLabel

var sp_game: SpGame
var joueur_moi
var jeu: Jeu6Takes
var timer: float = 0.0
var timer_duration := 45
var time_left = 45
var selected_card_node: TCardUI = null

func _ready():
	# Nettoyage
	for child in hbox_container.get_children():
		child.queue_free()
	for row_panel in vbox_container.get_children():
		var row = row_panel.get_child(0)
		for card in row.get_children():
			card.queue_free()

	# Init logique
	sp_game = SpGame.new()
	add_child(sp_game)

	_load_icons()

	var settings = Global.game_settings
	sp_game.start_game({
		"bot_count": settings["bot_count"],
		"nb_cartes": settings["nb_cartes"],
		"nb_max_heads": settings["nb_max_heads"],
		"nb_max_manches": settings["nb_max_manches"],
		"round_timer": settings["round_timer"]
	})

	_update_plateau()


func _process(delta):
	if sp_game and sp_game.attente_joueur:
		time_left -= delta
		$HBoxContainer/timer.text = str(int(time_left)).pad_zeros(2)

func _load_icons():
	var all_icons = [
		"blue.png", "brown.png", "cyan.png", "dark_grey.png",
		"green.png", "orange.png", "pink.png", "purple.png", "red.png"
	]
	all_icons.shuffle()

	player_icons.clear()

	# Ajout de l'icône "Moi"
	var moi_icon = TextureRect.new()
	moi_icon.texture = load(ICON_PATH + "red.png")  # ou "moi.png" si tu l'as
	moi_icon.tooltip_text = "Moi"
	player_icons.add_child(moi_icon)

	for i in range(Global.game_settings["bot_count"]):
		var icon = TextureRect.new()
		icon.texture = load(ICON_PATH + all_icons[i % all_icons.size()])
		icon.tooltip_text = "Bot" + str(i + 1)
		player_icons.add_child(icon)

func _start_timer():
	time_left = timer_duration

func select_card(card_node):
	if selected_card_node:
		deselect_card()
	selected_card_node = card_node
	print("Carte sélectionnée !")

func deselect_card():
	if selected_card_node:
		selected_card_node.deselect()
		selected_card_node = null
		print("Carte désélectionnée")

func _on_GlobalClickCatcher_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if selected_card_node:
			deselect_card()

func _on_carte_cliquee(index, node):
	select_card(node)

func _update_heads():
	heads_label.text = str(joueur_moi.score)

func _update_hand():
	hbox_container.clear()
	for i in range(joueur_moi.hand.cartes.size()):
		var c = joueur_moi.hand.cartes[i]
		var card = CARD_UI_SCENE.instantiate()
		card.set_card_data("res://assets/images/cartes/%d.png" % c.numero)
		card.index = i
		card.connect("carte_cliquee", Callable(self, "_on_carte_choisie"))
		hbox_container.add_child(card)

func _update_plateau():
	for i in range(vbox_container.get_child_count()):
		var row_panel = vbox_container.get_child(i)
		var row = row_panel.get_child(0)
		row.clear()
		for c in jeu.table.rangs[i].cartes:
			var card = CARD_UI_SCENE.instantiate()
			card.set_card_data("res://assets/images/cartes/%d.png" % c.numero)
			row.add_child(card)

func _on_carte_choisie(index):
	if not sp_game.attente_joueur:
		print("Ce n'est pas encore ton tour de choisir.")
		return

	var carte = joueur_moi.hand.jouer_carte(index)
	sp_game.carte_choisie_moi = { "joueur": joueur_moi, "carte": carte }
	sp_game.reprendre_tour()

	_update_hand()
	_update_plateau()
	_update_heads()
	_start_timer()
