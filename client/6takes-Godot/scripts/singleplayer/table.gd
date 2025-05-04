class_name Table
extends Object

var rangs: Array = []

func _init(deck):
	for i in range(4):
		var carte_initiale = deck.distribuer(1)[0]
		rangs.append(Rang.new(carte_initiale))
		print("[INIT] Rang %d initialisé avec la carte %d" % [i + 1, carte_initiale.numero])

func trouver_best_rang(carte: Carte) -> int:
	var best_index = -1
	var min_diff = 105
	for i in range(rangs.size()):
		var rang = rangs[i]
		var derniere = rang.cartes[-1]
		if derniere is Carte:
			var diff = carte.numero - derniere.numero
			if diff > 0 and diff < min_diff:
				best_index = i
				min_diff = diff
	print("[CHOIX RANG] Carte %d choisit rang %d" % [carte.numero, best_index])
	return best_index

# ✅ MODIFIÉ pour accepter joueur
func ajouter_carte(carte: Carte, joueur = null):
	var best_index = trouver_best_rang(carte)
	if best_index != -1:
		rangs[best_index].ajouter_carte(carte, joueur)  # ✅ on passe joueur aussi
		print("[AJOUT] Carte %d ajoutée au rang %d" % [carte.numero, best_index])
		return best_index
	print("[ERREUR] Aucun rang approprié trouvé pour la carte %d" % carte.numero)
	return -1

func ramasser_cartes() -> Array:
	for i in range(rangs.size()):
		if rangs[i].est_pleine():
			print("[RAMASSAGE] Le rang %d est plein, ramassage en cours." % i)
			var cartes_a_ramasser = rangs[i].recuperer_cartes()
			rangs[i] = Rang.new(rangs[i].cartes[0])
			return cartes_a_ramasser
	return []

func ramasser_rang(rang_index: int) -> Array:
	if rang_index >= 0 and rang_index < rangs.size():
		var cartes_a_ramasser = rangs[rang_index].cartes.duplicate()
		rangs[rang_index].cartes.clear()
		print("[RAMASSAGE MANUEL] Rang %d vidé." % rang_index)
		return cartes_a_ramasser
	else:
		print("❌ Index de rang invalide :", rang_index)
		return []

func forcer_nouvelle_rangée(rang_index: int, carte: Carte) -> void:
	if rang_index >= 0 and rang_index < rangs.size():
		rangs[rang_index] = Rang.new(carte)
		print("[FORCE NOUVELLE] Rang %d réinitialisé avec carte %d." % [rang_index, carte.numero])
	else:
		print("❌ Erreur : Index de rang invalide pour forcer une nouvelle rangée :", rang_index)
