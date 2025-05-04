
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


@onready var hbox_container = $CanvasLayer2/HBoxContainer
@onready var vbox_container = $deckContainer/rowsContainer
@onready var heads_label = $CanvasLayer/top_bar/nbheads


var sp_game: SpGame
var timer_duration := 45
var time_left = 45.0
var bot_display_data: Array = []

func _ready():

	print("🟢 Script prêt.")
	if Global.game_settings == null or not Global.game_settings.has("bot_count"):
		print("🔴 Erreur : paramètres jeu manquants")
		return


	sp_game = SpGame.new()
	add_child(sp_game)
	sp_game.start_game(Global.game_settings)

	_setup_bot_ui()
	_update_hand()
	_update_plateau()
	_update_heads()
	_start_timer()

	sp_game.tour_repris.connect(_on_tour_repris)


	# Démarrer le premier round après avoir tout initialisé
	sp_game.start_round()


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
		name_label.set("theme_override_fonts/font", custom_font)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
	human_name_label.set("theme_override_fonts/font", custom_font)
	human_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	human_box.add_child(human_hbox)
	human_box.add_child(human_name_label)
	spplayerright.add_child(human_box)
	bot_display_data.append({"bot": human, "card_layer": human_card_layer})


	bot_display_data.append({"bot": human, "card_layer": human_card_layer})

func _update_hand():
	for child in hbox_container.get_children():
		child.queue_free()
	var moi = sp_game.jeu.joueurs[0]
	for carte in moi.hand.cartes:
		var card_ui = CARD_UI_SCENE.instantiate()
		hbox_container.add_child(card_ui)
		card_ui.set_card_data("res://assets/images/cartes/%d.png" % carte.numero, carte.numero)
		card_ui.connect("card_selected", Callable(self, "_on_carte_cliquee"))

func _update_plateau():
	for i in range(vbox_container.get_child_count()):
		var row = vbox_container.get_child(i).get_child(0)
		for child in row.get_children():
			child.queue_free()

		for carte in sp_game.jeu.table.rangs[i].cartes:
			var card_ui = CARD_UI_SCENE.instantiate()
			row.add_child(card_ui)
			card_ui.set_card_data("res://assets/images/cartes/%d.png" % carte.numero, carte.numero)



func _on_carte_cliquee(global_card_id):
	if global_card_id == null:
		print("❌ Erreur : global_card_id est null")
		return

	var moi = sp_game.jeu.joueurs[0]
	var index = moi.hand.trouver_index(global_card_id)

	if index == -1 or sp_game.carte_choisie_moi != null:
		print("❌ Carte déjà choisie ou non trouvée (index invalide ou déjà pris)")
		return

	sp_game.carte_choisie_moi = {
		"joueur": moi,
		"carte": moi.hand.cartes[index],
		"index": index
	}

	_place_card_next_to_icon(moi, moi.hand.cartes[index].numero)
	sp_game.attente_joueur = false

	sp_game.reprendre_tour()

func _place_card_next_to_icon(joueur, card_number):
	var layer = get_display_data_for_joueur(joueur)["card_layer"]
	if layer:
		for child in layer.get_children():
			child.queue_free()
		var card_ui = CARD_UI_SCENE.instantiate()
		layer.add_child(card_ui)
		card_ui.set_card_data("res://assets/images/cartes/%d.png" % card_number, card_number)
func afficher_cartes_bots():
	for i in range(1, sp_game.jeu.joueurs.size()):
		var bot = sp_game.jeu.joueurs[i]
		if sp_game.carte_choisie_par(bot):
			_place_card_for_bot(bot, sp_game.carte_choisie_par(bot).numero)

func _place_card_for_bot(bot, card_number):
	var layer = get_display_data_for_joueur(bot)["card_layer"]
	if layer:
		for child in layer.get_children():
			child.queue_free()

		var card_ui = CARD_UI_SCENE.instantiate()
		card_ui.modulate.a = 0.0  # Commence invisible
		layer.add_child(card_ui)
		card_ui.set_card_data("res://assets/images/cartes/%d.png" % card_number, card_number)

		var tween = create_tween()
		tween.tween_property(card_ui, "modulate:a", 10.0, 5.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
func get_display_data_for_joueur(joueur):
	for data in bot_display_data:
		if data["bot"] == joueur:
			return data
	return {}

func _update_heads():
	var moi = sp_game.jeu.joueurs[0]
	heads_label.text = str(moi.score) 

func _start_timer():
	time_left = timer_duration

func _on_tour_repris(cartes_choisies):
	for choix in cartes_choisies:
		var joueur = choix["joueur"]
		var carte = choix["carte"]
		_place_card_next_to_icon(joueur, carte.numero)

	await get_tree().create_timer(1.0).timeout  # délai pour visualiser devant l’icône

	for choix in cartes_choisies:
		var joueur = choix["joueur"]
		var data = get_display_data_for_joueur(joueur)
		var layer = data["card_layer"]
		for child in layer.get_children():
			var tween = create_tween()
			tween.tween_property(child, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			await tween.finished
			child.queue_free()

	# Mettre à jour l’affichage des rangées après la logique
	_update_plateau()

func setup_from_lobby(players: Array):
	Global.game_players = players
	
func _on_attente_choix_rang(rangs_disponibles):
	afficher_boutons_rang(rangs_disponibles)

func afficher_boutons_rang(rangs_disponibles):
	# C’est ici que tu dois générer les boutons pour chaque rang
	# et connecter leur signal pressed à une fonction comme rang_button_pressed(index)
	print("Veuillez choisir un rang parmi:", rangs_disponibles)

func rang_button_pressed(index):
	sp_game.continuer_avec_rang(index)
