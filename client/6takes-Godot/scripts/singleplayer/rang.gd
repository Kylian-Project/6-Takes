class_name Rang
extends Object

var cartes: Array = []

func _init(carte):
	cartes = [carte]

func ajouter_carte(carte):
	cartes.append(carte)


func est_pleine() -> bool:
	return cartes.size() == 6

func recuperer_cartes() -> Array:
	var cartes_a_ramasser = cartes.slice(0, 5)  # pour la pénalité
	cartes = cartes.slice(5)  # on garde la 6e carte
	return cartes_a_ramasser

func recuperer_cartes_special_case() -> Array:
	return cartes.duplicate()

func total_tetes() -> int:
	var sum = 0
	for c in cartes:
		sum += c.tetes
	return sum
