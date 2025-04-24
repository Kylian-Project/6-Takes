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
	table = Table.new(deck)
	for nom in noms:
		joueurs.append(Joueur.new(nom, deck, nb_cartes))

func jouer_carte(nom_joueur: String, carte) -> String:
	for joueur in joueurs:
		if joueur.nom == nom_joueur:
			var rang = table.ajouter_carte(carte)
			if rang == -1:
				return "choix_rang_obligatoire"
			var cartes_ramassees = table.ramasser_cartes()
			var penalite = 0
			for c in cartes_ramassees:
				penalite += c.tetes
			joueur.update_score(penalite)
			if cartes_ramassees.size() > 0:
				return "ramassage_rang"
	return "ok"

func trouver_best_rang(carte):
	var best_index = -1
	var min_diff = 105
	for i in range(table.rangs.size()):
		var derniere = table.rangs[i].cartes.back()
		var diff = carte.numero - derniere.numero
		if diff > 0 and diff < min_diff:
			best_index = i
			min_diff = diff
	return best_index

func check_end_manche() -> bool:
	return joueurs[1].hand.cartes.size() == 0

func check_end_game() -> bool:
	for j in joueurs:
		if j.score >= nb_max_heads:
			return true
	return manche_actuelle >= nb_max_manches

func manche_suivante():
	manche_actuelle += 1
	deck = Deck.new(true)
	table = Table.new(deck)
	for joueur in joueurs:
		joueur.hand = Hand.new(deck.distribuer(nb_cartes))

func reset_game():
	var noms = []
	for j in joueurs:
		noms.append(j.nom)
	_init(nb_joueurs, noms, nb_max_manches, nb_max_heads, nb_cartes)
