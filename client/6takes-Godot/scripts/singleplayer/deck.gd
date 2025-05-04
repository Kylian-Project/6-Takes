
class_name Deck
extends Object

var cartes: Array = []

func _init(empty := true):
	if empty:
		for i in range(1, 105):
			var card_path = "res://assets/images/cartes/" + str(i) + ".png"
			cartes.append(Carte.new(i, card_path))
		print("[INIT DECK] Deck initialisé avec %d cartes." % cartes.size())
		# Ne mélange plus ici automatiquement

func melanger():
	print("[MELANGE] Mélange du deck en cours...")
	for i in range(cartes.size() - 1, 0, -1):
		var j = randi() % (i + 1)
		var temp = cartes[i]
		cartes[i] = cartes[j]
		cartes[j] = temp
	print("[MELANGE] Mélange terminé.")

func distribuer(n: int) -> Array:
	if n > cartes.size():
		print("[DISTRIBUER] Demande trop grande : %d cartes demandées, %d disponibles." % [n, cartes.size()])
		n = cartes.size()
	var distrib = cartes.slice(0, n)
	cartes = cartes.slice(n, cartes.size())
	print("[DISTRIBUER] %d cartes distribuées, %d restantes dans le deck." % [distrib.size(), cartes.size()])
	return distrib
