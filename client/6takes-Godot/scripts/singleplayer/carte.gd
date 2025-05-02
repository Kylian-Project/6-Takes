class_name Carte

var numero: int
var tetes: int
var path: String  # Ajouter cette ligne si vous souhaitez un champ path

func _init(_numero: int, _path: String):
	numero = _numero
	tetes = calculer_tetes()
	path = _path  # Initialiser la propriété 'path' si nécessaire

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
