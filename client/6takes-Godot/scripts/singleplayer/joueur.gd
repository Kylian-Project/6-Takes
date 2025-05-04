

class_name Joueur
extends Object

var nom: String
var hand
var score: int = 0

func _init(_nom: String, _deck, nb_cartes: int):
	nom = _nom
	hand = Hand.new(_deck.distribuer(nb_cartes))
	print("[INIT JOUEUR] %s avec %d cartes." % [nom, hand.cartes.size()])

func update_score(penalite: int):
	score += penalite
	print("[SCORE] %s reçoit %d points de pénalité. Total : %d" % [nom, penalite, score])

func choisir_carte() -> Carte:
	# IA simple : joue la plus petite carte
	if hand.cartes.size() == 0:
		print("[CHOIX CARTE] %s n'a plus de cartes." % nom)
		return null
	var carte_min = hand.cartes[0]
	for carte in hand.cartes:
		if carte.numero < carte_min.numero:
			carte_min = carte
	hand.cartes.erase(carte_min)
	print("[CHOIX CARTE] %s joue la carte %d." % [nom, carte_min.numero])
	return carte_min
