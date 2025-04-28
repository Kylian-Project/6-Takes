class_name Joueur
extends Object

var nom: String
var hand
var score: int = 0

func _init(_nom: String, _deck, nb_cartes: int):
	nom = _nom
	hand = Hand.new(_deck.distribuer(nb_cartes))

func update_score(penalite: int):
	score += penalite

func choisir_carte() -> Carte:
	# IA simple : joue la plus petite carte
	var carte_min = hand.cartes[0]
	for carte in hand.cartes:
		if carte.numero < carte_min.numero:
			carte_min = carte
	hand.cartes.erase(carte_min)
	return carte_min
