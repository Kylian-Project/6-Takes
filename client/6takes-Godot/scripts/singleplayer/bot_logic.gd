
class_name BotLogic
extends Object

# Renvoie un index aléatoire dans la main
static func choisir_carte_aleatoire(main: Array) -> int:
	if main.is_empty():
		print("[BOT LOGIC] Erreur : main vide !")
		return -1
	var index = randi() % main.size()
	print("[BOT LOGIC] Index choisi aléatoirement : %d" % index)
	return index

# Renvoie directement une carte choisie aléatoirement (utile pour plus de contrôle)
static func choisir_carte_directe(main: Array):
	if main.is_empty():
		print("[BOT LOGIC] Erreur : main vide !")
		return null
	var index = randi() % main.size()
	var carte = main[index]
	print("[BOT LOGIC] Carte choisie directement : %d (index %d)" % [carte.numero, index])
	return carte

# Simule un délai aléatoire (entre 0 et 1 seconde)
static func delai_aleatoire() -> float:
	var delai = randf()
	print("[BOT LOGIC] Délai simulé : %.2f secondes" % delai)
	return delai
