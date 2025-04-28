class_name Hand
extends Object

var cartes: Array = []

func _init(c: Array):
	cartes = c

func trouver_index(carte) -> int:
	for i in range(cartes.size()):
		if cartes[i].numero == carte.numero:
			return i
	return -1

func jouer_carte(index: int) -> Carte:
	if index >= 0 and index < cartes.size():
		var carte = cartes[index]
		cartes.remove_at(index)  # Retire la carte de la main
		return carte
	else:
		return null  # Si l'index est invalide, retourne null


func afficher_hand() -> String:
	var hand_str = ""
	for carte in cartes:
		hand_str += "Carte " + str(carte.numero) + " - Têtes: " + str(carte.tetes) + "\n"
	return hand_str
