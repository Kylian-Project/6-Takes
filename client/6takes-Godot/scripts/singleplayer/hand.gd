class_name Hand
extends Object

var cartes: Array = []

func _init(c: Array):
    cartes = c

func trouver_index(carte) -> int:
    for i in range(cartes.size()):
        if cartes[i].numero == carte.numero:
            return i
    return -1

func jouer_carte(index: int):
    if index >= 0 and index < cartes.size():
        var carte = cartes[index]
        cartes.remove_at(index)
        return carte

    return null

func afficher_hand() -> Array:
    return cartes