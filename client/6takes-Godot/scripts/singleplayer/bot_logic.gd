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

# Nouvelle fonction pour choisir les cartes du bot
static func choisir_cartes_bots(main: Array) -> Array:
	var cartes_a_jouer = []
	
	# Exemple simple : choisir 2 cartes au hasard
	for i in range(2):
		var index_carte = choisir_carte_aleatoire(main)
		if index_carte != -1:
			cartes_a_jouer.append(main[index_carte])
			main.erase(main[index_carte])  # Utiliser erase() au lieu de remove()
	
	return cartes_a_jouer
