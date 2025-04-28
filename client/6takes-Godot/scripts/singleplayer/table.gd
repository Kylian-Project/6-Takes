class_name Table
extends Object

var rangs: Array = []

func _init(deck):
	for i in range(4):
		rangs.append(Rang.new(deck.distribuer(1)[0]))

func trouver_best_rang(carte: Carte) -> int:
	var best_index = -1
	var min_diff = 105
	for i in range(rangs.size()):
		var rang = rangs[i]
		var derniere = rang.cartes[-1]
		
		# Assure-toi que 'derniere' est bien une carte avec la propriété 'numero'
		if derniere is Carte:
			var diff = carte.numero - derniere.numero
			if diff > 0 and diff < min_diff:
				best_index = i
				min_diff = diff
	return best_index

# Ajoute une carte à la meilleure rangée
func ajouter_carte(carte: Carte):
	var best_index = trouver_best_rang(carte)
	if best_index != -1:
		rangs[best_index].ajouter_carte(carte)
		return best_index
	return -1

# Ramassage automatique si une rangée est pleine
func ramasser_cartes() -> Array:
	for i in range(rangs.size()):
		if rangs[i].est_pleine():
			var cartes_a_ramasser = rangs[i].recuperer_cartes()
			rangs[i] = Rang.new(rangs[i].cartes[0])
			return cartes_a_ramasser
	return []

# 💥 Ajout important : Ramasser une rangée spécifique (manuellement)
func ramasser_rang(rang_index: int) -> Array:
	if rang_index >= 0 and rang_index < rangs.size():
		var cartes_a_ramasser = rangs[rang_index].cartes.duplicate()
		rangs[rang_index].cartes.clear()
		return cartes_a_ramasser
	else:
		print("❌ Index de rang invalide:", rang_index)
		return []
func forcer_nouvelle_rangée(rang_index: int, carte: Carte) -> void:
	if rang_index >= 0 and rang_index < rangs.size():
		rangs[rang_index] = Rang.new(carte)
	else:
		print("❌ Erreur : Index de rang invalide pour forcer une nouvelle rangée:", rang_index)
