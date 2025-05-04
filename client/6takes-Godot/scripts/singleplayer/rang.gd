
class_name Rang
extends Object

var cartes: Array = []

func _init(carte):
	cartes = [carte]
	print("[INIT RANG] Créé avec la carte %d" % carte.numero)

func ajouter_carte(carte: Carte, joueur = null):
	cartes.append(carte)
	print("[AJOUT RANG] Carte %d ajoutée, total cartes maintenant : %d" % [carte.numero, cartes.size()])



func est_pleine() -> bool:
	var pleine = cartes.size() >= 6
	if pleine:
		print("[PLEINE] Rang plein avec %d cartes." % cartes.size())
	return pleine

func recuperer_cartes() -> Array:
	var cartes_a_ramasser = cartes.slice(0, 5)
	cartes = cartes.slice(5)
	print("[RAMASSAGE RANG] %d cartes ramassées, reste : %d" % [cartes_a_ramasser.size(), cartes.size()])
	return cartes_a_ramasser

func recuperer_cartes_special_case() -> Array:
	print("[SPECIAL] Récupération spéciale de toutes les cartes (%d)." % cartes.size())
	return cartes.duplicate()

func total_tetes() -> int:
	var sum = 0
	for c in cartes:
		sum += c.tetes
	print("[SOMME TETES] Total têtes dans le rang : %d" % sum)
	return sum
