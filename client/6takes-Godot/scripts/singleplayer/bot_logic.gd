class_name BotLogic
extends Object

# Renvoie un index de carte aléatoire dans la main
static func choisir_carte_aleatoire(main: Array) -> int:
	if main.size() == 0:
		return -1
	return randi() % main.size()

# Simule un délai aléatoire avant de jouer (entre 0 et 10 secondes)
static func delai_aleatoire() -> float:
	return randf() * 10.0

# Renvoie l'index d'une rangée aléatoire parmi les 4
static func choisir_rang_aleatoire() -> int:
	return randi() % 4
