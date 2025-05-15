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
var attente_choix_rang := false

signal carte_moi_attendue()
signal tour_repris(cartes_jouees)
signal choix_rang_obligatoire(joueur, carte)
signal tour_avance(current_turn, max_turns)

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
	
var round_started := false
func start_round():
	round_started = true
	if joueur_moi == jeu.joueurs[0]:  # Si c'est le tour du joueur
		var board = get_tree().current_scene
		if board and board.has_method("set_cards_clickable"):
			board.set_cards_clickable(true)  # Réactive les clics
	
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
	
	# Vérifier si on est en mode max_points et si le max n'est pas atteint
	var settings = Global.game_settings
	if settings.get("use_max_points", false):
		var max_points = settings.get("max_points", 999)
		var highest_score = 0
		for player in rankings:
			if player.score > highest_score:
				highest_score = player.score
		
		if highest_score < max_points:
			print("Le score maximum n'est pas encore atteint, la partie continue")
			return  # Ne pas arrêter le jeu
	
	# Si on arrive ici, soit le max_points est atteint, soit ce n'est pas le mode max_points
	var board = get_tree().current_scene
	if board and board.has_method("stop_timer"):
		board.stop_timer()
	
	await get_tree().create_timer(3.0).timeout
	
	if board:
		
		await get_tree().create_timer(1.5).timeout
	
		board.update_game_state("            FINISH")
		board.show_scoreboard(rankings)
		
func joueur_moi_a_choisi(index: int):
	if not clic_valide_effectue:
		print(" Pas de clic détecté, on ignore.")
		return
	clic_valide_effectue = false
	var carte = joueur_moi.hand.cartes[index]
	carte_choisie_moi = { "joueur": joueur_moi, "carte": carte }
	reprendre_tour()

func reprendre_tour():
	
	
	var cartes_choisies = []
	var board = get_tree().current_scene  # Déclaration UNIQUE de board au début
	
	if board and board.has_method("set_cards_clickable"):
		board.set_cards_clickable(false)  # Désactiver les clics
	
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

	# Afficher les cartes devant les icônes
	if board:
		for choix in cartes_choisies:
			board._place_card_next_to_icon(choix["joueur"], choix["carte"].numero)
		
		# Petit délai visuel
		await get_tree().create_timer(1.5).timeout

	# Trier les cartes par numéro croissant
	cartes_choisies.sort_custom(func(a, b): return a["carte"].numero < b["carte"].numero)

	# Jouer les cartes une par une
	
	for choix in cartes_choisies:
		var joueur = choix["joueur"]
		var carte = choix["carte"]
		
		# Animation pour montrer quelle carte est jouée (pour tous les joueurs)
		if board:
			await board._animate_card_play(joueur, carte)
			await get_tree().create_timer(0.5).timeout
		
		var rang_index = jeu.table.trouver_best_rang(carte)
		if rang_index == -1:
			# Cas spécial : choix manuel
			if joueur == joueur_moi:
				emit_signal("choix_rang_obligatoire", joueur, carte)
				
				joueur_en_attente = joueur
				
				carte_en_attente = carte
				
				return
				
				
			else:
				if board:
					await board.update_game_state("            %s Pick a row to take" % [joueur.nom])
					await board.show_label(" %s must take a ranger…" % joueur.nom)
				await get_tree().create_timer(1.5).timeout
				
				
				var rang_a_ramasser = randi() % jeu.table.rangs.size()
				var cartes_ramassees = jeu.table.ramasser_rang(rang_a_ramasser)
				var total_tetes = 0
				for c in cartes_ramassees:
					total_tetes += c.tetes
				joueur.score += total_tetes
				jeu.table.forcer_nouvelle_rangée(rang_a_ramasser, carte)
				await board.move_card_to_row(joueur, carte.numero, rang_index)

				if board:
					await board.update_game_state("            %s chose rank" % [joueur.nom])
					await board.show_label(" %s chose rank %d (+%d têtes)" % [joueur.nom, rang_a_ramasser + 1, total_tetes])
		else:
			# Ajouter la carte avec animation
			
			
			
			jeu.table.ajouter_carte(carte, joueur)
			await board.move_card_to_row(joueur, carte.numero, rang_index)
			
			await board.update_game_state("            Collecting cards...")	
			# Vérifie dépassement
			if jeu.table.rangs[rang_index].est_pleine():
				var cartes_a_ramasser = jeu.table.rangs[rang_index].recuperer_cartes()
				var total_tetes = 0
				for c in cartes_a_ramasser:
					total_tetes += c.tetes
				joueur.score += total_tetes
				jeu.table.forcer_nouvelle_rangée(rang_index, carte)

				# Affiche le message du dépassement
				if board:
					await get_tree().create_timer(0.3).timeout
					await board.update_game_state("              %s put down 6th card" % [joueur.nom])
					
					if joueur == joueur_moi:
						
						await board.show_label("%s put down 6th card → picks up rank %d" % [joueur.nom,rang_index + 1, total_tetes])
						
					
					else:
						
						await board.show_label("%s put down 6th card → picks up rank %d" % [joueur.nom, rang_index + 1, total_tetes])
					await board.update_game_state("             %s put down 6th card" % [joueur.nom])
					
				

	# Terminer le tour
	terminer_tour(cartes_choisies)

func terminer_tour(cartes_choisies):
	# Vérifier fin de manche (toutes mains vides)
	var fin_manche = true
	for joueur in jeu.joueurs:
		if joueur.hand.cartes.size() > 0:
			fin_manche = false
			break
	
	if fin_manche:
		current_round += 1
		jeu.manche_suivante()
		
		# Vérifier fin de partie
		var fin_partie = false
		if Global.game_settings.get("use_max_points", false):
			# Mode Points - vérifier si un joueur a atteint le score max
			fin_partie = jeu.joueurs.any(func(j): return j.score >= jeu.nb_max_heads)
		else:
			# Mode Tours - vérifier si on a atteint le nombre max de manches
			fin_partie = current_round > jeu.nb_max_manches
		
		if fin_partie:
			end_game()
			return
	
	# Continuer le jeu normalement
	carte_choisie_moi = null
	cartes_choisies_bots.clear()
	emit_signal("tour_repris", cartes_choisies)
	
	# Démarrer le prochain tour après un court délai
	await get_tree().create_timer(1.0).timeout
	start_round()
	
func reprendre_avec_rang(rang_index: int):
	var joueur = joueur_en_attente
	var carte = carte_en_attente

	if joueur == null or carte == null:
		print("❌ Erreur : aucun joueur ou carte en attente.")
		return

	# 1. Ramassage des cartes
	var cartes_ramassees = jeu.table.ramasser_rang(rang_index)
	var total_tetes = 0
	for c in cartes_ramassees:
		total_tetes += c.tetes
	joueur.score += total_tetes
	
	# 2. Animation via le gameboard
	var board = get_node_or_null("/root/GameBoardSP")
	if board:
		# Animation complète (disparition carte + ramassage + nouvelle carte)
		await board._animate_full_pickup_sequence(joueur, carte, rang_index, cartes_ramassees)
		
		# Message visuel adapté selon joueur/bot
		await board.show_label(" %s ramasse le rang %d (+%d têtes)" % [joueur.nom, rang_index + 1, total_tetes])
	else:
		# Fallback sans animation
		jeu.table.forcer_nouvelle_rangée(rang_index, carte)

	# 3. Vider les variables d'attente
	joueur_en_attente = null
	carte_en_attente = null
	attente_choix_rang = false  # <-- Ajout ici

	# 4. Continuer avec les autres joueurs
	var cartes_choisies = [{ "joueur": joueur, "carte": carte }]
	for bot in jeu.joueurs.slice(1, jeu.joueurs.size()):
		if carte_choisie_par(bot) != null:
			cartes_choisies.append({ "joueur": bot, "carte": carte_choisie_par(bot) })

	# 5. Trier et jouer les cartes restantes
	cartes_choisies.sort_custom(func(a, b): return a["carte"].numero < b["carte"].numero)
	
	for choix in cartes_choisies.slice(1, cartes_choisies.size()):
		var bot = choix["joueur"]
		var bot_carte = choix["carte"]
		var rang_index_bot = jeu.table.trouver_best_rang(bot_carte)

		if board:
			await board._place_card_next_to_icon(bot, bot_carte.numero)
			await get_tree().create_timer(0.5).timeout

		if rang_index_bot == -1:
			var rang_a_ramasser = randi() % jeu.table.rangs.size()
			var cartes_ramassees_bot = jeu.table.ramasser_rang(rang_a_ramasser)
			var total_tetes_bot = 0
			for c in cartes_ramassees_bot:
				total_tetes_bot += c.tetes
			bot.score += total_tetes_bot
			
			if board:
				await board._animate_full_pickup_sequence(bot, bot_carte, rang_a_ramasser, cartes_ramassees_bot)
				await board.show_label("🤖 %s ramasse le rang %d (+%d têtes)" % [bot.nom, rang_a_ramasser + 1, total_tetes_bot])
			
			jeu.table.forcer_nouvelle_rangée(rang_a_ramasser, bot_carte)
		else:
			jeu.table.ajouter_carte(bot_carte, bot)
			if board:
				await board.move_card_to_row(bot, bot_carte.numero, rang_index_bot)
				  

			
			if jeu.table.rangs[rang_index_bot].est_pleine():
				var cartes_a_ramasser = jeu.table.rangs[rang_index_bot].recuperer_cartes()
				var tetes_ramassees = 0
				for c in cartes_a_ramasser:
					tetes_ramassees += c.tetes
				bot.score += tetes_ramassees
				
				if board:
					await board._animate_full_pickup_sequence(bot, bot_carte, rang_index_bot, cartes_a_ramasser)
					await board.show_label("🤖 %s remplit le rang %d (+%d têtes)" % [bot.nom, rang_index_bot + 1, tetes_ramassees])
				
				jeu.table.forcer_nouvelle_rangée(rang_index_bot, bot_carte)

	# 6. Terminer le tour
	terminer_tour(cartes_choisies)



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

# Ajoutez ces méthodes
# Dans sp_game.gd
func get_players():
	return jeu.get_players() if jeu and jeu.has_method("get_players") else []

func is_game_over() -> bool:
	if not jeu:
		return false
		
	var settings = Global.game_settings
	if settings.get("use_max_points", false):
		var max_points = settings.get("max_points", 999)
		for player in get_players():
			if player.score >= max_points:
				return true
		return false
	
	return jeu.check_end_game()
	
func get_current_player_name() -> String:
	if jeu and jeu.joueurs.size() > 0:
		return jeu.joueurs[jeu.joueur_actif].nom
	return "Bot"
	
func is_player_turn() -> bool:
	# Le joueur humain est toujours à l'index 0
	return true  # Mode solo  toujours le tour du joueur
