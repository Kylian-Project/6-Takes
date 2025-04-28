class_name Deck
extends Object

var cartes: Array = []

func _init(empty := true):
	if empty:
		for i in range(1, 105):
			cartes.append(Carte.new(i))
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
