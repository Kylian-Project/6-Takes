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
var clic_valide_effectue := false
var is_card_selected := false
var cartes_choisies_bots = {}

signal carte_moi_attendue()
signal tour_repris(cartes_jouees)

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
	var noms = ["Moi"]
	var bot_count = settings.get("bot_count", 3)
	for i in range(bot_count):
		noms.append("Bot" + str(i + 1))

	var nb_cartes = settings.get("nb_cartes", 10)
	var nb_max_heads = settings.get("nb_max_heads", 66)
	var nb_max_manches = settings.get("nb_max_manches", 5)

	jeu = Jeu6Takes.new(noms.size(), noms, nb_max_manches, nb_max_heads, nb_cartes)
	print("[SP GAME] Jeu lancé avec %d joueurs." % noms.size())

func start_round():
	if jeu.check_end_game():
		end_game()
		return

	print("\n🔁 Nouvelle manche :", current_round)

	attente_joueur = true
	on_tour_en_cours = true
	emit_signal("carte_moi_attendue")

func end_game():
	print("🎉 Partie terminée !")

func joueur_moi_a_choisi(index: int):
	if not clic_valide_effectue:
		print("⛔ Pas de clic détecté, on ignore.")
		return
	clic_valide_effectue = false
	var moi = joueur_moi
	var carte = moi.hand.cartes[index]
	carte_choisie_moi = {"joueur": moi, "carte": carte}
	reprendre_tour()

func reprendre_tour():
	var cartes_choisies = []
	if carte_choisie_moi != null:
		var moi = carte_choisie_moi["joueur"]
		var carte = carte_choisie_moi["carte"]
		moi.hand.cartes.erase(carte)
		cartes_choisies.append({"joueur": moi, "carte": carte})
	else:
		print("❌ Erreur : aucune carte choisie pour le joueur humain.")
		return

	for bot in jeu.joueurs.slice(1, jeu.joueurs.size()):
		var carte = BotLogic.choisir_carte_directe(bot.hand.cartes)
		if carte != null:
			bot.hand.cartes.erase(carte)
			cartes_choisies.append({"joueur": bot, "carte": carte})
			ajouter_carte_choisie(bot, carte)

	afficher_cartes_bots()

	cartes_choisies.sort_custom(func(a, b): return a["carte"].numero < b["carte"].numero)

	for choix in cartes_choisies:
		var joueur = choix["joueur"]
		var carte = choix["carte"]
		var rang_index = jeu.table.trouver_best_rang(carte)

		if rang_index == -1:
			# Aucun rang adapté → choisir un rang aléatoire à ramasser
			var rang_a_ramasser = randi() % jeu.table.rangs.size()
			var cartes_ramassees = jeu.table.ramasser_rang(rang_a_ramasser)
			var total_tetes = 0
			for c in cartes_ramassees:
				total_tetes += c.tetes
			joueur.score += total_tetes
			jeu.table.forcer_nouvelle_rangée(rang_a_ramasser, carte)
			print("[RAMASSAGE AUTO]", joueur.nom, "ramasse le rang", rang_a_ramasser, "et ajoute la carte", carte.numero)
		else:
			jeu.table.ajouter_carte(carte)

	carte_choisie_moi = null
	on_tour_en_cours = false

	var board = get_node_or_null("/root/GameBoardSP")
	if board:
		board._update_plateau()

	emit_signal("tour_repris", cartes_choisies)
	print("🃏 Cartes jouées ce tour :")
	for choix in cartes_choisies:
		print(" -", choix["joueur"].nom, "a joué :", choix["carte"].numero, "(", choix["carte"].tetes, "têtes)")

	if jeu.check_end_manche():
		current_round += 1
		jeu.manche_suivante()
		start_round()
	else:
		start_round()

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
