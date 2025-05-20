### FICHIER corrigé : carte.gd ###

class_name Carte

var numero: int
var tetes: int
var path: String

func _init(_numero: int, _path: String):
	numero = _numero
	tetes = calculer_tetes()
	path = _path
	print("[INIT CARTE] Carte %d initialisée avec %d têtes." % [numero, tetes])

func calculer_tetes() -> int:
	if numero == 55:
		return 7
	elif numero % 11 == 0:
		return 5
	elif numero % 10 == 0:
		return 3
	elif numero % 5 == 0:
		return 2
	return 1
