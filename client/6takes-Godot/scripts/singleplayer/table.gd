class_name Table
extends Object

var rangs: Array = []

func _init(deck):
    for i in range(4):
        rangs.append(Rang.new(deck.distribuer(1)[0]))

func trouver_best_rang(carte) -> int:
    var best_index = -1
    var min_diff = 105
    for i in range(rangs.size()):
        var rang = rangs[i]
        var derniere = rang.cartes[-1]
        var diff = carte.numero - derniere.numero
        if diff > 0 and diff < min_diff:
            best_index = i
            min_diff = diff
    return best_index

func ajouter_carte(carte):
    var best_index = trouver_best_rang(carte)
    if best_index != -1:
        rangs[best_index].ajouter_carte(carte)
        return best_index
    return -1

func ramasser_cartes() -> Array:
    for i in range(rangs.size()):
        if rangs[i].est_pleine():
            var cartes_a_ramasser = rangs[i].recuperer_cartes()
            rangs[i] = Rang.new(rangs[i].cartes[0])
            return cartes_a_ramasser
    return []