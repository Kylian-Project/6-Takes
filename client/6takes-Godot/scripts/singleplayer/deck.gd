class_name Deck
extends Object

var cartes: Array = []

func _init(empty := true):
	if empty:
		for i in range(1, 105):
			# Supposons que les cartes sont stockées sous le format "res://assets/images/cartes/{id}.png"
			var card_path = "res://assets/images/cartes/" + str(i) + ".png"
			cartes.append(Carte.new(i, card_path))  # Passer à la fois l'ID et le chemin de l'image
		melanger()

func melanger():
	for i in range(cartes.size() - 1, 0, -1):
		var j = randi() % (i + 1)
		var temp = cartes[i]
		cartes[i] = cartes[j]
		cartes[j] = temp

func distribuer(n: int) -> Array:
	var distrib = cartes.slice(0, n)
	cartes = cartes.slice(n, cartes.size())
	return distrib
