

class_name Hand
extends Object

var cartes: Array = []

func _init(c: Array):
	cartes = c
	print("[INIT HAND] Main initialisée avec %d cartes." % cartes.size())

func trouver_index(carte_id: int) -> int:
	for i in range(cartes.size()):
		if cartes[i].numero == carte_id:
			print("[TROUVER INDEX] Carte %d trouvée à l'index %d." % [carte_id, i])
			return i
	print("[TROUVER INDEX] Carte %d non trouvée." % carte_id)
	return -1

func jouer_carte(index: int) -> Carte:
	if index >= 0 and index < cartes.size():
		var carte = cartes[index]
		cartes.remove_at(index)
		print("[JOUER CARTE] Carte %d jouée depuis l'index %d." % [carte.numero, index])
		return carte
	else:
		print("[ERREUR] Index %d invalide pour jouer une carte." % index)
		return null

func afficher_hand() -> String:
	var hand_str = "[MAIN] Cartes actuelles :\n"
	for carte in cartes:
		hand_str += "Carte " + str(carte.numero) + " - Têtes: " + str(carte.tetes) + "\n"
	return hand_str
