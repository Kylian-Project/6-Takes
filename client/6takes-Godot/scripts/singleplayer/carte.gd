class_name Carte
extends Object

var numero : int
var tetes : int

func _init(_numero : int):
	numero = _numero
	tetes = calculer_tetes()

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
