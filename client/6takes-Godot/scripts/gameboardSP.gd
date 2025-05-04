
extends Node2D

@export var top_bar: HBoxContainer
@onready var timer_label = $HBoxContainer/timer
@onready var score_label = $CanvasLayer/top_bar/nbheads
@onready var state_label = $State_label
@onready var turn_label = $HBoxContainer/turnLabel
@onready var pause_screen_scene = preload("res://scenes/screen_pauseSP.tscn")


var pause_instance = null

@onready var row_panels = [
	$deckContainer/rowsContainer/row1_panel,
	$deckContainer/rowsContainer/row2_panel,
	$deckContainer/rowsContainer/row3_panel,
	$deckContainer/rowsContainer/row4_panel
]

@onready var rang_buttons = [
	$"Panel/choix_rang/choose_rang_1",
	$"Panel/choix_rang/choose_rang_2",
	$"Panel/choix_rang/choose_rang_3",
	$"Panel/choix_rang/choose_rang_4"
]
@onready var choix_rang_panel = $"Panel"


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
	
	$ScoreBoard.visible = false
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
	await show_label("Game Start")
	
	sp_game.start_round()
	sp_game.choix_rang_obligatoire.connect(_on_choix_rang_obligatoire)



func show_scoreboard(rankings):
	$ScoreBoard.visible = true
	$ScoreBoard.update_rankings(rankings)

func _on_choix_rang_obligatoire(joueur, carte):
	var rangs_dispo = []
	for i in range(4):
		rangs_dispo.append(i)

	if joueur == sp_game.joueur_moi:
		print("[UI] Joueur humain doit choisir un rang.")
		await show_label("%s must take a ranger" % joueur.nom)
		afficher_boutons_rang(rangs_dispo)
	else:
		print("[UI] Bot %s must take a ranger." % joueur.nom)

		# 👇 Montre d’abord un message indiquant que le bot réfléchit
		await show_label("🤖 %s chose rank…" % joueur.nom)

		# Optionnel : simule un petit délai d’attente (pour le réalisme)
		await get_tree().create_timer(1.0).timeout

		# Le bot choisit un rang aléatoire
		var rang_a_ramasser = randi() % sp_game.jeu.table.rangs.size()
		var cartes_ramassees = sp_game.jeu.table.ramasser_rang(rang_a_ramasser)
		var total_tetes = 0
		for c in cartes_ramassees:
			total_tetes += c.tetes
		joueur.score += total_tetes
		sp_game.jeu.table.forcer_nouvelle_rangée(rang_a_ramasser, carte)

		# 👇 Montre ensuite le message du résultat
		await show_label("🤖 %s took the rank %d (+%d têtes)" % [joueur.nom, rang_a_ramasser + 1, total_tetes])
		
		# Continue le tour après le bot
		sp_game.reprendre_tour()



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

	if moi.score >= 60:
		heads_label.add_theme_color_override("font_color", Color.RED)
	else:
		heads_label.add_theme_color_override("font_color", Color.WHITE)

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
	_update_heads()

  

func show_label(text: String) -> void:
	state_label.text = text
	state_label.visible = true
	await get_tree().create_timer(3).timeout
	hide_label()
	
func hide_label() -> void:
	state_label.visible = false


func hide_label_and_show_panel() -> void:
	state_label.visible = false

	# Montre le panel des choix après disparition du label
	var choix_rang_panel = $Panel/choix_rang
	if choix_rang_panel:
		choix_rang_panel.visible = true
		print("✅ $Panel/choix_rang affiché après label.")
	else:
		print("⚠ Erreur : $Panel/choix_rang introuvable.")




func rang_button_pressed(index):
	print("✅ Joueur a choisi le rang :", index)

	# Déconnecter tous les boutons après le choix
	for i in range(4):
		var bouton = rang_buttons[i]
		if bouton.is_connected("pressed", Callable(self, "rang_button_pressed").bind(i)):
			bouton.pressed.disconnect(rang_button_pressed.bind(i))
		bouton.hide()
		bouton.disabled = true

	# Appeler le jeu pour continuer
	var sp_game = get_node("/root/GameBoardSP").sp_game
	if sp_game:
		sp_game.reprendre_avec_rang(index)

func afficher_boutons_rang(rangs_disponibles):
	choix_rang_panel.visible = true

	var indices = []
	for r in rangs_disponibles:
		if typeof(r) == TYPE_INT:
			indices.append(r)
		elif typeof(r) == TYPE_OBJECT and r.has("index"):
			indices.append(r.index)
		else:
			print("⚠ Attention : élément inattendu dans rangs_disponibles :", r)


	for i in range(4):
		var bouton = rang_buttons[i]
		if bouton:
			if i in indices:
				bouton.show()
				bouton.disabled = false
			else:
				bouton.hide()
				bouton.disabled = true
		else:
			print("⚠ Bouton à l’index", i, "non trouvé (null)")

func setup_from_lobby(players: Array):
	Global.game_players = players
	
func _on_attente_choix_rang(rangs_disponibles):
	afficher_boutons_rang(rangs_disponibles)




func _on_button_pressed() -> void:
	if pause_instance == null:
		pause_instance = pause_screen_scene.instantiate()

		add_child(pause_instance)

		await get_tree().process_frame
		pause_instance.position = pause_instance.size

	pause_instance.move_to_front()
	pause_instance.visible = true


func _on_choose_rang_1_pressed():
	_on_rang_button_pressed(0)

func _on_choose_rang_2_pressed():
	_on_rang_button_pressed(1)

func _on_choose_rang_3_pressed():
	_on_rang_button_pressed(2)

func _on_choose_rang_4_pressed():
	_on_rang_button_pressed(3)

func _on_rang_button_pressed(rang_index):
	print("✅ Joueur a choisi le rang :", rang_index)

	# Cache immédiatement le panel complet
	choix_rang_panel.visible = false

	# Désactive les boutons
	for bouton in rang_buttons:
		if bouton != null:
			bouton.hide()
			bouton.disabled = true

	# Appelle la suite logique du jeu
	if sp_game:
		sp_game.reprendre_avec_rang(rang_index)
