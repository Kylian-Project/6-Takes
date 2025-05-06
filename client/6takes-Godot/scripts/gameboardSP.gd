
extends Node2D

@export var top_bar: HBoxContainer
@onready var timer_label = $HBoxContainer/timer
@onready var game_timer =$Timer
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
const CARD_UI_SCENE = preload("res://scenes/card_uiSP.tscn")
const SpGame = preload("res://scripts/sp_game.gd")


@onready var hbox_container = $CanvasLayer2/HBoxContainer
@onready var vbox_container = $deckContainer/rowsContainer
@onready var heads_label = $CanvasLayer/top_bar/nbheads


var time_left = 0
var max_turns = 0
var current_turn = 0
var timer_active = false
var finish_shown = false
var sp_game: SpGame

var bot_display_data: Array = []

func _ready():
	var left_name = $"spplayerleft/HBoxContainer/icon&name/name_bot"
	var right_name = $"spplayerright/HBoxContainer/icon&name/name_bot"
	
	left_name.custom_minimum_size.x = 20
	right_name.custom_minimum_size.x = 20
	left_name.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	right_name.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	 # Force le positionnement initial à 50px de la gauche
	$HBoxContainer/gameStateLabel.position.x = 450
	$HBoxContainer/gameStateLabel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	
	# Désactive le repositionnement automatique
	$HBoxContainer/gameStateLabel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	# Initialisation des tours
	if game_timer == null:
		game_timer = $Timer  # Assurez-vous que le chemin est correct
		print("Timer initialisé : ", game_timer != null)
		
	
	max_turns = Global.game_settings["nb_cartes"]  # Nombre total de tours = nombre de cartes
	current_turn = 1
	update_turn_label()  # Affiche "1/nb_cartes"
	
	# Initialisation UI
	timer_label.visible = false
	$ScoreBoard.visible = false
	
	# Message de début
	await show_label("Game Start")
	
	# Vérification des paramètres
	if Global.game_settings == null:
		print("🔴 Paramètres de jeu manquants")
		return

	# Initialisation du jeu
	sp_game = SpGame.new()
	add_child(sp_game)
	sp_game.start_game(Global.game_settings)

	# Synchronisation des tours
	if max_turns != sp_game.jeu.nb_cartes:
		max_turns = sp_game.jeu.nb_cartes
		update_turn_label()

	# Initialisation des composants
	_setup_bot_ui()
	_update_hand()
	_update_plateau()
	_update_heads()
	
	# Démarrage du timer
	timer_label.visible = true
	if not game_timer.timeout.is_connected(_on_Timer_timeout):
		game_timer.timeout.connect(_on_Timer_timeout)
	
	# Initialisation du temps
	time_left = Global.game_settings["round_timer"]
	start_timer()
	
	# Connexion des signaux
	sp_game.tour_repris.connect(_on_tour_repris)
	sp_game.choix_rang_obligatoire.connect(_on_choix_rang_obligatoire)
	
	await show_label(" Pick your cards")
	update_game_state("                           Pick your cards")
	await get_tree().create_timer(1.0).timeout
	
	# Début de la partie
	sp_game.start_round()

func _process(delta):
	if not sp_game :
		return
		
	if sp_game.is_game_over():
		update_game_state("            FINISH")
		


		
func show_scoreboard(rankings):
	# Arrêter définitivement le timer
	stop_timer()
	timer_active = false
	
	# Désactiver les interactions
	set_process_input(false)
	
	$ScoreBoard.visible = true
	$ScoreBoard.update_rankings(rankings)
var rang_auto_choisi = false		
signal rang_selectionne(rang_index)
func _on_choix_rang_obligatoire(joueur, carte):
	_place_card_next_to_icon(joueur, carte.numero)

	await get_tree().create_timer(0.3).timeout
	
	if joueur == sp_game.joueur_moi:
		rang_auto_choisi = false  # Reset le flag
		_start_timer_for_rang_choice()  # Démarre un timer pour laisser le temps de choisir
		await _handle_human_choice(joueur, carte)
	else:
		await _handle_bot_choice(joueur, carte)

	choix_rang_panel.visible = false
	sp_game.reprendre_tour()

func _start_timer_for_rang_choice():
	timer_active = true
	game_timer.start()

func _handle_human_choice(joueur, carte):
	"""Gère le choix de rang pour le joueur humain"""
	await show_label("%s must take a ranger" % joueur.nom)
	
	# Afficher les boutons de choix
	var rangs_dispo = []
	for i in range(4):
		rangs_dispo.append(i)
	afficher_boutons_rang(rangs_dispo)
	
	# Attendre la sélection du joueur
	var rang_selectionne = await self.rang_selectionne
	
	# Animation complète
	await _animate_full_pickup_sequence(joueur, carte, rang_selectionne)

func _handle_bot_choice(joueur, carte):
	"""Gère le choix de rang pour un bot"""
	await show_label("%s réfléchit..." % joueur.nom)
	await get_tree().create_timer(1.0).timeout  # Délai plus naturel
	
	var rang_a_ramasser = randi() % sp_game.jeu.table.rangs.size()
	await _animate_full_pickup_sequence(joueur, carte, rang_a_ramasser)
	
	await show_label("%s a choisi le rang %d" % [joueur.nom, rang_a_ramasser + 1])

func _animate_full_pickup_sequence(joueur, carte, rang_index):
	"""Séquence d'animation complète pour le ramassage"""
	# 1. Ramasser les cartes du rang
	var cartes_ramassees = sp_game.jeu.table.ramasser_rang(rang_index)
	
	# 2. Calcul des têtes
	var total_tetes = 0
	for c in cartes_ramassees:
		total_tetes += c.tetes
	
	# 3. Animation des cartes ramassées vers le joueur
	await _animate_cards_to_player(joueur, cartes_ramassees, rang_index)
	
	# 4. Faire disparaître la carte devant l'icône
	await _clear_player_card(joueur)
	
	# 5. Animer la nouvelle carte vers le rang
	await _animate_card_to_row(joueur, carte, rang_index)
	
	# 6. Mise à jour du score
	joueur.score += total_tetes
	
	# 7. Réinitialiser le rang
	sp_game.jeu.table.forcer_nouvelle_rangée(rang_index, carte)
	
	# 8. Mise à jour visuelle
	_update_plateau()
	_update_heads()

func _clear_player_card(joueur):
	var card_layer = get_display_data_for_joueur(joueur)["card_layer"]
	for child in card_layer.get_children():
		var tween = create_tween()
		tween.tween_property(child, "modulate:a", 0, 0.3)
		await tween.finished
		child.queue_free()

func _animate_cards_to_player(joueur, cartes, row_index):
	var start_row = $deckContainer/rowsContainer.get_child(row_index).get_child(0)
	var end_pos = get_display_data_for_joueur(joueur)["card_layer"].global_position
	
	for i in range(cartes.size()):
		var card_ui = start_row.get_child(i) if i < start_row.get_child_count() else null
		if card_ui:
			var anim_card = CARD_UI_SCENE.instantiate()
			add_child(anim_card)
			anim_card.set_card_data("res://assets/images/cartes/%d.png" % cartes[i].numero, cartes[i].numero)
			anim_card.global_position = card_ui.global_position
			anim_card.z_index = 100
			
			var tween = create_tween()
			tween.tween_property(anim_card, "global_position", end_pos, 0.5)
			tween.parallel().tween_property(anim_card, "modulate:a", 0, 0.5)
			await tween.finished
			anim_card.queue_free()
			await get_tree().create_timer(0.1).timeout


	

func _animate_card_to_row(joueur, card_number, row_index):
	var start_layer = get_display_data_for_joueur(joueur)["card_layer"]
	var end_row = vbox_container.get_child(row_index).get_child(0)
	
	# Créer une carte animée
	var anim_card = CARD_UI_SCENE.instantiate()
	add_child(anim_card)
	anim_card.set_card_data("res://assets/images/cartes/%d.png" % card_number, card_number)
	anim_card.global_position = start_layer.global_position
	anim_card.z_index = 100  # S'assurer qu'elle est au-dessus
	
	# Animation vers la rangée
	var tween = create_tween()
	tween.tween_property(anim_card, "global_position", end_row.global_position, 0.5)
	tween.parallel().tween_property(anim_card, "scale", Vector2(0.8, 0.8), 0.5)
	
	await tween.finished
	anim_card.queue_free()
	
	# Mise à jour visuelle
	_update_plateau()





	
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

	# Style minimal pour les noms (sans marges parasites)
	var name_style = StyleBoxFlat.new()
	name_style.bg_color = Color("#E0E0E0")
	name_style.corner_radius_top_left = 4
	name_style.corner_radius_top_right = 4
	name_style.corner_radius_bottom_left = 4
	name_style.corner_radius_bottom_right = 4
	name_style.content_margin_left = 50
	name_style.content_margin_right = 50
	name_style.content_margin_top = 2
	name_style.content_margin_bottom = 2

	# === BOTS ===
	for i in range(1, bot_count):
		var bot = sp_game.jeu.joueurs[i]

		# Choix du côté (gauche/droite)
		var container_side: VBoxContainer
		var is_left: bool
		if left_count <= right_count:
			container_side = spplayerleft
			left_count += 1
			is_left = true
		else:
			container_side = spplayerright
			right_count += 1
			is_left = false

		# -- Conteneur principal --
		var bot_box = VBoxContainer.new()
		bot_box.name = "Bot" + str(i)
		bot_box.alignment = BoxContainer.ALIGNMENT_CENTER
		bot_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		bot_box.custom_minimum_size.x = 60  # Permet au label de rétrécir
		
		# -- Icône + CardLayer --
		var bot_hbox = HBoxContainer.new()
		bot_hbox.name = "BotHBox" + str(i)
		bot_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		bot_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var bot_icon = TextureRect.new()
		bot_icon.name = "BotIcon"
		bot_icon.texture = load(ICON_PATH + all_icons[i % all_icons.size()])
		bot_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		bot_icon.expand = true
		bot_icon.custom_minimum_size = Vector2(100, 100)
		bot_icon.scale = Vector2(0.5, 0.5)  # Taille affichée: 75x75px
		
		var card_layer = Control.new()
		card_layer.name = "CardLayer"
		card_layer.custom_minimum_size = Vector2(150, 100)

		# Créer un spacer pour ajouter de l'espacement entre l'icône et les cartes
		var spacer = Control.new()
		spacer.name = "Spacer"
		spacer.custom_minimum_size = Vector2(20, 0)  # L'espacement horizontal entre l'icône et les cartes
		var spacere = Control.new()
		spacere.name = "Spacer"
		spacere.custom_minimum_size = Vector2(175, 0)  # L'espacement horizontal entre l'icône et les cartes

		# Inverser l'ordre si à droite (cartes d'abord, puis l'icône)
		if container_side == spplayerleft:
			bot_hbox.add_child(spacere)
			bot_hbox.add_child(bot_icon)
			bot_hbox.add_child(spacer)  # Ajouter le spacer entre l'icône et les cartes
			bot_hbox.add_child(card_layer)
		else:
			bot_hbox.add_child(card_layer)
			bot_hbox.add_child(spacer)  # Ajouter le spacer entre les cartes et l'icône
			bot_hbox.add_child(bot_icon)
			bot_hbox.add_child(spacere)

		# -- Label du nom --
		var name_label = Label.new()
		name_label.name = "name_bot"
		name_label.text = bot.nom if bot.has_method("nom") else "Bot " + str(i)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		name_label.custom_minimum_size = Vector2.ZERO  # Force la réduction
		name_label.clip_text = true  # Coupe le texte si trop long
		name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		name_label.add_theme_stylebox_override("normal", name_style)
		name_label.add_theme_color_override("font_color", Color.BLACK)
		name_label.add_theme_font_size_override("font_size", 14)  # Texte plus petit

		# Assemblage final
		bot_box.add_child(bot_hbox)
		bot_box.add_child(name_label)
		container_side.add_child(bot_box)

		bot_display_data.append({
			"bot": bot,
			"card_layer": card_layer
		})

	# === JOUEUR HUMAIN === (mêmes réglages que les bots)
	var human = sp_game.jeu.joueurs[0]
	
	var human_box = VBoxContainer.new()
	human_box.name = "Human"
	human_box.alignment = BoxContainer.ALIGNMENT_CENTER
	human_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	human_box.custom_minimum_size.x = 100

	var human_hbox = HBoxContainer.new()
	human_hbox.name = "HumanHBox"
	human_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	human_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var human_icon = TextureRect.new()
	human_icon.name = "HumanIcon"
	human_icon.texture = load(ICON_PATH + "red.png")
	human_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	human_icon.expand = true
	human_icon.custom_minimum_size = Vector2(100, 100)
	human_icon.scale = Vector2(0.5, 0.5)

	var human_card_layer = Control.new()
	human_card_layer.name = "CardLayer"
	human_card_layer.custom_minimum_size = Vector2(100, 80)
	var human_spacer = Control.new()
	human_spacer.name = "HumanSpacer"
	human_spacer.custom_minimum_size = Vector2(175, 0) 
	
	# Espace de 35px pour le joueur
	var human_flex_spacer = Control.new()
	human_flex_spacer.custom_minimum_size = Vector2(65, 0)
	
	# Structure côté droit
	human_hbox.add_child(human_card_layer)
	human_hbox.add_child(human_flex_spacer) # Espaceur flexible
	human_hbox.add_child(human_icon)
	human_hbox.add_child(human_spacer)  

	var human_name_label = Label.new()
	human_name_label.name = "name_human"
	human_name_label.text = Global.player_name if Global.get("player_name") else "Player"
	human_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	human_name_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	human_name_label.custom_minimum_size = Vector2.ZERO
	human_name_label.clip_text = true
	human_name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	human_name_label.add_theme_stylebox_override("normal", name_style)
	human_name_label.add_theme_color_override("font_color", Color.BLACK)
	human_name_label.add_theme_font_size_override("font_size", 14)

	human_box.add_child(human_hbox)
	human_box.add_child(human_name_label)
	spplayerright.add_child(human_box)

	bot_display_data.append({
		"bot": human,
		"card_layer": human_card_layer
	})
	
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
			card_ui.modulate.a = 1  
			
func move_card_to_row(joueur, card_number, row_index):
	var start_layer = get_display_data_for_joueur(joueur)["card_layer"]
	var end_row = vbox_container.get_child(row_index).get_child(0)
	
	if start_layer and end_row:
		# Supprimer immédiatement la carte devant l'icône (avant l'animation)
		for child in start_layer.get_children():
			child.queue_free()
		
		# Crée une copie animée
		var anim_card = CARD_UI_SCENE.instantiate()
		add_child(anim_card)
		anim_card.set_card_data("res://assets/images/cartes/%d.png" % card_number, card_number)
		anim_card.global_position = start_layer.global_position
		anim_card.z_index = 100
		
		# Calcul position finale
		var card_count = end_row.get_child_count()
		var target_pos = end_row.global_position + Vector2(card_count * 35, 0)
		
		# Animation
		var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(anim_card, "global_position", target_pos, 1.5)
		tween.parallel().tween_property(anim_card, "scale", Vector2(0.8, 0.8), 1.5)
		
		await tween.finished
		anim_card.queue_free()
		
		# Mise à jour réelle du plateau
		_update_plateau()
		
func _on_carte_cliquee(global_card_id):
	update_game_state("            You chose card %d" % global_card_id)
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
		# Nettoyer avant d'ajouter
		for child in layer.get_children():
			child.queue_free()
		
		var card_ui = CARD_UI_SCENE.instantiate()
		layer.add_child(card_ui)
		card_ui.set_card_data("res://assets/images/cartes/%d.png" % card_number, card_number)
		
		# Réduire la taille de la carte ici (par exemple à 70% de sa taille originale)
		card_ui.scale = Vector2(0.5, 0.5)
		
		# Animation d'apparition (1 seconde)
		card_ui.modulate.a = 0
		var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(card_ui, "modulate:a", 1.0, 1.0)
				
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

func start_timer():
	if game_timer != null and not timer_active:
		timer_active = true
		game_timer.start(1.0)
		print("Timer démarré")

func _on_Timer_timeout():
	if not timer_active or $ScoreBoard.visible:  # Ne rien faire si le scoreboard est visible
		return
		
	time_left -= 1
	timer_label.text = str(time_left)
	
	if time_left <= 0:
		timer_timeout()
	else:
		game_timer.start(1.0)
					
func timer_timeout():
	update_game_state("           Times's up chose a random rand or card...")
	timer_active = false
	game_timer.stop()

	if choix_rang_panel.visible and !rang_auto_choisi:
		rang_auto_choisi = true
		choix_rang_auto()

	elif sp_game.carte_choisie_moi == null and sp_game.joueur_moi.hand.cartes.size() > 0:
		var random_index = randi() % sp_game.joueur_moi.hand.cartes.size()
		var random_card = sp_game.joueur_moi.hand.cartes[random_index]

		# Retirer la carte de la main
		sp_game.joueur_moi.hand.cartes.remove_at(random_index)
		_update_hand()

		sp_game.carte_choisie_moi = {
			"joueur": sp_game.joueur_moi,
			"carte": random_card,
			"index": random_index
		}
		_place_card_next_to_icon(sp_game.joueur_moi, random_card.numero)
		sp_game.reprendre_tour()
func choix_rang_auto():
	# Choisir un rang aléatoire
	var rang_index = randi() % vbox_container.get_child_count()
	_on_rang_button_pressed(rang_index)


	
func stop_timer():
	if game_timer != null:
		game_timer.stop()
		timer_active = false
		print("Timer arrêté")
	
func update_turn_label():
	if turn_label == null:
		push_error("Turn Label non trouvé!")
		return
	
	# Formatage sécurisé avec vérification des valeurs
	var display_turn = clamp(current_turn, 1, max_turns)
	turn_label.text = "Turn %d/%d" % [display_turn, max_turns]
	
	# Optionnel : changement de couleur pour le dernier tour
	if current_turn == max_turns:
		turn_label.add_theme_color_override("font_color", Color.GOLD)
	else:
		turn_label.add_theme_color_override("font_color", Color.WHITE)


func _on_tour_repris(cartes_choisies):
	current_turn += 1
	update_turn_label()
	
	update_game_state("            New round")
	await get_tree().create_timer(1.5).timeout
	
	# Mode solo - toujours votre tour
	update_game_state("            Pick your cards")
	
	
	
	# 4. Réinitialiser le timer
	game_timer.stop()
	time_left = Global.game_settings["round_timer"]
	timer_label.text = str(time_left)
	timer_active = true
	game_timer.start(1.0)
	
	# 5. Afficher les cartes devant les icônes
	for choix in cartes_choisies:
		var joueur = choix["joueur"]
		var carte = choix["carte"]
		_place_card_next_to_icon(joueur, carte.numero)
	
	# 6. Petit délai visuel
	await get_tree().create_timer(0.8).timeout
	
	# 7. Faire disparaître les cartes devant les icônes
	for choix in cartes_choisies:
		var joueur = choix["joueur"]
		var layer = get_display_data_for_joueur(joueur)["card_layer"]
		for child in layer.get_children():
			var tween = create_tween()
			tween.tween_property(child, "modulate:a", 0, 0.3)
			await tween.finished
			child.queue_free()
	
	# 8. Mettre à jour l'affichage
	_update_plateau()
	_update_heads()
	
	# 9. Démarrer le nouveau tour
	sp_game.start_round()
	
		

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
	# Sauvegarder le nom du joueur principal
	if players.size() > 0:
		Global.player_name = players[0]
		
func _on_attente_choix_rang(rangs_disponibles):
	afficher_boutons_rang(rangs_disponibles)




func _on_button_pressed() -> void:
	show_pause_menu()

func show_pause_menu():
	# Arrête le timer quand la pause est activée
	stop_timer()
	
	# Crée et affiche l'écran de pause
	var pause_instance = pause_screen_scene.instantiate()
	pause_instance.setup(self)  # Passe la référence au gameboard
	add_child(pause_instance)


func update_game_state(message: String) -> void:
	if has_node("HBoxContainer/gameStateLabel"):
		$HBoxContainer/gameStateLabel.text = message
	else:
		print("Warning: gameStateLabel not found")

func clear_game_state() -> void:
	if has_node("HBoxContainer/gameStateLabel"):
		$HBoxContainer/gameStateLabel.text = ""
		
func show_takes_message(joueur, row_index=null, card_count=null):
	if joueur == sp_game.joueur_moi:
		update_game_state("You take")
		if row_index != null and card_count != null:
			await show_label("You take row %d (%d cards)" % [row_index+1, card_count])
	else:
		update_game_state("%s takes" % joueur.nom)
		if row_index != null and card_count != null:
			await show_label("%s takes row %d (%d cards)" % [joueur.nom, row_index+1, card_count])
			
func _on_choose_rang_1_pressed():
	_on_rang_button_pressed(0)

func _on_choose_rang_2_pressed():
	_on_rang_button_pressed(1)

func _on_choose_rang_3_pressed():
	_on_rang_button_pressed(2)

func _on_choose_rang_4_pressed():
	_on_rang_button_pressed(3)

func _on_rang_button_pressed(rang_index):
	update_game_state("👉 Tu as choisi le rang %d" % (rang_index + 1))
	print("✅ Joueur a choisi le rang :", rang_index)
	choix_rang_panel.visible = false

	# Désactiver les boutons
	for bouton in rang_buttons:
		if bouton != null:
			bouton.hide()
			bouton.disabled = true

	# Informer le jeu
	if sp_game:
		sp_game.reprendre_avec_rang(rang_index)
