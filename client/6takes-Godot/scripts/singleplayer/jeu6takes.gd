
class_name Jeu6Takes
extends Object

var deck
var table
var nb_max_manches: int
var nb_max_heads: int
var nb_cartes: int
var nb_joueurs: int
var manche_actuelle: int = 0
var joueurs: Array = []

func _init(nb_j: int, noms: Array, max_manches := 5, max_heads := 66, nb_carte := 10):
	nb_joueurs = nb_j
	nb_max_manches = max_manches
	nb_max_heads = max_heads
	nb_cartes = nb_carte
	deck = Deck.new(true)
	deck.melanger()  # Mélange uniquement ici au départ
	table = Table.new(deck)
	for nom in noms:
		joueurs.append(Joueur.new(nom, deck, nb_cartes))
	print("[INIT] Jeu initialisé avec %d joueurs." % nb_joueurs)

func jouer_tour(carte_joueur):
	var cartes_choisies = []
	cartes_choisies.append({"joueur": joueurs[0], "carte": carte_joueur})
	print("[CHOIX] Joueur %s a choisi la carte %d" % [joueurs[0].nom, carte_joueur.numero])

	for i in range(1, joueurs.size()):
		var bot = joueurs[i]
		var index_carte = BotLogic.choisir_carte_aleatoire(bot.hand.cartes)
		if index_carte != -1:
			var carte_bot = bot.hand.jouer_carte(index_carte)
			cartes_choisies.append({"joueur": bot, "carte": carte_bot})
			print("[CHOIX] Bot %s a choisi la carte %d" % [bot.nom, carte_bot.numero])
		else:
			print("[CHOIX] Bot %s n’a plus de cartes." % bot.nom)

	# Tri des cartes dans l’ordre croissant
	cartes_choisies.sort_custom(func(a, b): return a["carte"].numero < b["carte"].numero)

	for pair in cartes_choisies:
		var joueur = pair["joueur"]
		var carte = pair["carte"]
		print("[PLACEMENT] %s joue la carte %d" % [joueur.nom, carte.numero])
		var rang_index = table.trouver_best_rang(carte)

		if rang_index == -1:
			if joueur == joueurs[0]:
				# 🔴 On ne fait rien pour le joueur humain : on signale à l’interface qu’on attend son choix
				print("[ATTENTE] Joueur humain doit choisir un rang.")
				emit_signal("choix_rang_obligatoire", joueur, carte)
				return  # On arrête ici
			else:
				# Bots → ramassage auto
				var rang_a_ramasser = randi() % table.rangs.size()
				var cartes_ramassees = table.ramasser_rang(rang_a_ramasser)
				var total_tetes = 0
				for c in cartes_ramassees:
					total_tetes += c.tetes
				joueur.update_score(total_tetes)
				table.forcer_nouvelle_rangée(rang_a_ramasser, carte)
				print("[RAMASSAGE AUTO]", joueur.nom, "ramasse le rang", rang_a_ramasser, "et ajoute la carte", carte.numero)
		else:
			table.ajouter_carte(carte)


func check_end_manche() -> bool:
	return joueurs[0].hand.cartes.size() == 0

func check_end_game() -> bool:
	for j in joueurs:
		if j.score >= nb_max_heads:
			return true
	return manche_actuelle >= nb_max_manches

func manche_suivante():
	manche_actuelle += 1
	for joueur in joueurs:
		joueur.hand = Hand.new(deck.distribuer(nb_cartes))

		
func reset_game():
	var noms = []
	for j in joueurs:
		noms.append(j.nom)
	_init(nb_joueurs, noms, nb_max_manches, nb_max_heads, nb_cartes)

func jouer_carte(nom_joueur: String, carte) -> String:
	for joueur in joueurs:
		if joueur.nom == nom_joueur:
			var rang = table.trouver_best_rang(carte)
			if rang == -1:
				return "choix_rang_obligatoire"
			table.ajouter_carte(carte)
			if table.rangs[rang].est_pleine():
				var cartes_ramassees = table.ramasser_rang(rang)
				var penalite = 0
				for c in cartes_ramassees:
					penalite += c.tetes
				joueur.update_score(penalite)
				table.forcer_nouvelle_rangée(rang, carte)
				return "ramassage_rang"
	return "ok"
