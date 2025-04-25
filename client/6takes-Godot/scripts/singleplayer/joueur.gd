class_name Joueur
extends Object

var nom: String
var score: int = 0
var hand: Hand
var carte_en_attente = null

func _init(n: String, deck, nb_cartes: int):
    nom = n
    hand = Hand.new(deck.distribuer(nb_cartes))

func update_score(points: int):
    score += points

func reset_score():
    score = 0

func get_hand() -> Array:
    return hand.cartes