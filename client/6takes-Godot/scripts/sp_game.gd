extends Node

const Jeu6Takes = preload("res://scripts/singleplayer/jeu6takes.gd")
const BotLogic = preload("res://scripts/singleplayer/bot_logic.gd")

var jeu: Jeu6Takes
var bots = []
var current_round := 1
var joueur_moi = null
var carte_choisie_moi = null
var attente_joueur = false
var on_tour_en_cours = false

signal carte_moi_attendue()

func start_game(settings: Dictionary):
	var noms = ["Moi"]
	var bot_count = settings.get("bot_count", 3)
	for i in range(bot_count):
		noms.append("Bot" + str(i + 1))

	var nb_cartes = settings.get("nb_cartes", 10)
	var nb_max_heads = settings.get("nb_max_heads", 66)
	var nb_max_manches = settings.get("nb_max_manches", 5)

	jeu = Jeu6Takes.new(noms.size(), noms, nb_max_manches, nb_max_heads, nb_cartes)
	bots = jeu.joueurs.slice(1, jeu.joueurs.size())
	current_round = 1
	joueur_moi = jeu.joueurs[0]
	start_round()

func start_round():
	if jeu.check_end_game():
		end_game()
		return

	# Lancer le tour
	attente_joueur = true
	on_tour_en_cours = true
	emit_signal("carte_moi_attendue")

func joueur_moi_a_choisi(index: int):
	if not attente_joueur or not on_tour_en_cours:
		return

	if index >= joueur_moi.hand.cartes.size():
		print("Index de carte invalide")
		return

	var carte = joueur_moi.hand.jouer_carte(index)
	carte_choisie_moi = { "joueur": joueur_moi, "carte": carte }
	attente_joueur = false
	reprendre_tour()

func reprendre_tour():
	var cartes_choisies = [carte_choisie_moi]

	for bot in bots:
		var index = BotLogic.choisir_carte_aleatoire(bot.hand.cartes)
		var carte = bot.hand.jouer_carte(index)
		cartes_choisies.append({ "joueur": bot, "carte": carte })

	cartes_choisies.sort_custom(func(a, b): return a["carte"].numero < b["carte"].numero)

	for choix in cartes_choisies:
		var joueur = choix["joueur"]
		var carte = choix["carte"]
		var res = jeu.jouer_carte(joueur.nom, carte)
		if res == "choix_rang_obligatoire":
			var index = BotLogic.choisir_rang_aleatoire()
			var cartes_ramassees = jeu.table.rangs[index].recuperer_cartes_special_case()
			var penalty = cartes_ramassees.reduce(func(acc, c): return acc + c.tetes, 0)
			joueur.update_score(penalty)
			jeu.table.rangs[index] = Rang.new(carte)

	carte_choisie_moi = null
	on_tour_en_cours = false

	if jeu.check_end_manche():
		current_round += 1
		jeu.manche_suivante()
		start_round()
	else:
		start_round()

func get_etat_plateau():
	return jeu.table.rangs

func get_main_joueur_moi():
	return joueur_moi.hand.cartes

func get_scores():
	return jeu.joueurs

func end_game():
	print("Partie terminée")
