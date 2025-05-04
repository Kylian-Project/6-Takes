extends Node

const Jeu6Takes = preload("res://scripts/singleplayer/jeu6takes.gd")
const BotLogic = preload("res://scripts/singleplayer/bot_logic.gd")

var jeu: Jeu6Takes
var current_round := 1
var joueur_moi = null
var carte_choisie_moi = null
var attente_joueur = false
var on_tour_en_cours = false
var clic_valide_effectue := false
var cartes_choisies_bots = {}
var joueur_en_attente = null
var carte_en_attente = null

signal carte_moi_attendue()
signal tour_repris(cartes_jouees)
signal choix_rang_obligatoire(joueur, carte)

func ajouter_carte_choisie(bot, carte):
	cartes_choisies_bots[bot] = carte

func carte_choisie_par(bot):
	return cartes_choisies_bots.get(bot, null)

func tous_les_joueurs_ont_choisi() -> bool:
	if carte_choisie_moi == null:
		return false
	for i in range(1, jeu.joueurs.size()):
		var bot = jeu.joueurs[i]
		if carte_choisie_par(bot) == null:
			return false
	return true

func start_game(settings: Dictionary):
	var noms = Global.game_players
	var nb_cartes = settings.get("nb_cartes", 10)
	var nb_max_heads = settings.get("nb_max_heads", 66)
	var nb_max_manches = settings.get("nb_max_manches", 5)

	jeu = Jeu6Takes.new(noms.size(), noms, nb_max_manches, nb_max_heads, nb_cartes)
	joueur_moi = jeu.joueurs[0]
	print("[SP GAME] Jeu lancé avec %d joueurs." % noms.size())

func start_round():
	if jeu.check_end_game():
		end_game()
		return

	print("\n🔁 Nouvelle manche :", current_round)
	for joueur in jeu.joueurs:
		print("🧑 Main de", joueur.nom, ":")
		for c in joueur.hand.cartes:
			print("  -", c.numero, "(", c.tetes, "têtes)")

	print("📦 Plateau :")
	for i in range(jeu.table.rangs.size()):
		var cartes = jeu.table.rangs[i].cartes
		var texte = cartes.map(func(c): return str(c.numero) + "(" + str(c.tetes) + ")")
		print(" Rangée", i + 1, ":", ", ".join(texte))

	attente_joueur = true
	on_tour_en_cours = true
	emit_signal("carte_moi_attendue")

func get_rankings():
	var joueurs = jeu.joueurs.duplicate()
	joueurs.sort_custom(func(a, b): return a.score < b.score)
	var rankings = []
	for j in joueurs:
		rankings.append({ "nom": j.nom, "score": j.score })
	return rankings

func end_game():
	print("🎉 Partie terminée !")
	var rankings = get_rankings()
	await get_tree().create_timer(5.0).timeout
	var board = get_tree().current_scene
	if board:
		board.show_scoreboard(rankings)

func joueur_moi_a_choisi(index: int):
	if not clic_valide_effectue:
		print("⛔ Pas de clic détecté, on ignore.")
		return
	clic_valide_effectue = false
	var carte = joueur_moi.hand.cartes[index]
	carte_choisie_moi = { "joueur": joueur_moi, "carte": carte }
	reprendre_tour()

func reprendre_tour():
	var cartes_choisies = []

	# Joueur humain
	if carte_choisie_moi != null:
		var carte = carte_choisie_moi["carte"]
		joueur_moi.hand.cartes.erase(carte)
		cartes_choisies.append({ "joueur": joueur_moi, "carte": carte })
	else:
		print("❌ Erreur : aucune carte choisie pour le joueur humain.")
		return

	# Bots
	for bot in jeu.joueurs.slice(1, jeu.joueurs.size()):
		var carte = BotLogic.choisir_carte_directe(bot.hand.cartes)
		if carte != null:
			bot.hand.cartes.erase(carte)
			cartes_choisies.append({ "joueur": bot, "carte": carte })
			ajouter_carte_choisie(bot, carte)

	# Afficher les cartes bots visuellement
	afficher_cartes_bots()

	# Trier les cartes par numéro croissant
	cartes_choisies.sort_custom(func(a, b): return a["carte"].numero < b["carte"].numero)

	# Jouer les cartes une par une
	for choix in cartes_choisies:
		var joueur = choix["joueur"]
		var carte = choix["carte"]
		var rang_index = jeu.table.trouver_best_rang(carte)
		var board = get_tree().current_scene

		if rang_index == -1:
			# Cas spécial : choix manuel
			if joueur == joueur_moi:
				emit_signal("choix_rang_obligatoire", joueur, carte)
				joueur_en_attente = joueur
				carte_en_attente = carte
				return
			else:
				if board:
					await board.show_label("🤖 %s doit choisir un rang…" % joueur.nom)
				await get_tree().create_timer(1.5).timeout

				var rang_a_ramasser = randi() % jeu.table.rangs.size()
				var cartes_ramassees = jeu.table.ramasser_rang(rang_a_ramasser)
				var total_tetes = 0
				for c in cartes_ramassees:
					total_tetes += c.tetes
				joueur.score += total_tetes
				jeu.table.forcer_nouvelle_rangée(rang_a_ramasser, carte)

				if board:
					await board.show_label("🤖 %s a pris le rang %d (+%d têtes)" % [joueur.nom, rang_a_ramasser + 1, total_tetes])
		else:
			# Ajouter la carte normalement
			jeu.table.ajouter_carte(carte, joueur)

			# Vérifie dépassement
			if jeu.table.rangs[rang_index].est_pleine():
				var cartes_a_ramasser = jeu.table.rangs[rang_index].recuperer_cartes()
				var total_tetes = 0
				for c in cartes_a_ramasser:
					total_tetes += c.tetes
				joueur.score += total_tetes

				# Remet la carte actuelle seule
				jeu.table.forcer_nouvelle_rangée(rang_index, carte)

				# Affiche le message du dépassement
				if board:
					if joueur == joueur_moi:
						await board.show_label("👤 YOU dépasse → ramasse le rang %d (+%d têtes)" % [rang_index + 1, total_tetes])
					else:
						await board.show_label("🤖 %s dépasse → ramasse le rang %d (+%d têtes)" % [joueur.nom, rang_index + 1, total_tetes])

	# On termine le tour une fois tout joué
	terminer_tour(cartes_choisies)


func terminer_tour(cartes_choisies):
	carte_choisie_moi = null
	on_tour_en_cours = false

	var board = get_node_or_null("/root/GameBoardSP")
	if board:
		board._update_plateau()

	emit_signal("tour_repris", cartes_choisies)

	print("🃏 Cartes jouées ce tour :")
	for choix in cartes_choisies:
		print(" - %s a joué : %d (%d têtes)" % [choix["joueur"].nom, choix["carte"].numero, choix["carte"].tetes])

	print("🎯 Scores actuels :")
	for joueur in jeu.joueurs:
		print(" - %s : %d têtes" % [joueur.nom, joueur.score])

	if jeu.check_end_manche():
		current_round += 1
		jeu.manche_suivante()

	start_round()

func reprendre_avec_rang(rang_index):
	var joueur = joueur_en_attente
	var carte = carte_en_attente

	if joueur == null or carte == null:
		print("❌ Erreur : aucun joueur ou carte en attente.")
		return

	# Ramassage
	var cartes_ramassees = jeu.table.ramasser_rang(rang_index)
	var total_tetes = 0
	for c in cartes_ramassees:
		total_tetes += c.tetes
	joueur.score += total_tetes
	jeu.table.forcer_nouvelle_rangée(rang_index, carte)


	# Vider les variables d’attente
	joueur_en_attente = null
	carte_en_attente = null

	# Afficher le message visuel pour le joueur humain
	var board = get_node_or_null("/root/GameBoardSP")
	if board:
		await board.show_label("👤 YOU a ramassé le rang %d (+%d têtes)" % [rang_index + 1, total_tetes])

	# CONTINUER normalement avec le reste des cartes
	terminer_tour([{ "joueur": joueur, "carte": carte }])


func afficher_cartes_bots():
	var board = get_node_or_null("/root/GameBoardSP")
	if board:
		for i in range(1, jeu.joueurs.size()):
			var bot = jeu.joueurs[i]
			var carte = carte_choisie_par(bot)
			if carte != null:
				board._place_card_next_to_icon(bot, carte.numero)

func get_etat_plateau():
	return jeu.table.rangs

func get_main_joueur_moi():
	return joueur_moi.hand.cartes

func get_scores():
	return jeu.joueurs
