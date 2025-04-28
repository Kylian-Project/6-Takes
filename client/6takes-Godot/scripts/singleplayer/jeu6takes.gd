class_name Jeu6Takes
extends Object

var deck
var table
var nb_max_manches: int
var nb_max_heads: int
var nb_cartes: int
var nb_joueurs: int
var manche_actuelle: int = 0
var joueurs: Array = []
var cartes_posées: Array = []
var cartes_sur_table: Array = []  # Nouvelle propriété pour stocker les cartes sur la table
var tour_actuel: int = 0  # Ajoutez une variable pour suivre le tour actuel
var total_turns: int = 0  # Nombre total de tours
var max_turns: int = 20  # Nombre max de tours, ou basé sur un autre critère
var joueur_humain: Joueur = null
var all_cards: Array = []  # Liste de toutes les cartes pour l'UI


func _init(nb_j: int, noms: Array, max_manches := 5, max_heads := 66, nb_carte := 10):
	nb_joueurs = nb_j
	nb_max_manches = max_manches
	nb_max_heads = max_heads
	nb_cartes = nb_carte
	deck = Deck.new(true)
	table = Table.new(deck)
	joueurs.clear()

	# Le joueur humain est le premier, puis les bots sont ajoutés
	joueur_humain = Joueur.new(noms[0], deck, nb_cartes)  # Joueur humain
	joueurs.append(joueur_humain)

	# Ajouter les bots
	for i in range(1, nb_joueurs):
		var nom_bot = "Bot " + str(i)
		var bot = Joueur.new(nom_bot, deck, nb_cartes)  # Créer un bot
		joueurs.append(bot)

	


# La fonction qui gère le changement de tour
func next_turn():
	if tour_actuel < total_turns:
		print("Tour %d/%d" % [tour_actuel + 1, total_turns])
		
		# Gestion du tour (bot ou joueur)
		if tour_actuel % 2 == 0:  # Exemple : les tours pairs sont pour les bots
			print("C'est le tour du bot!")
			bot_play()
		else:
			print("C'est votre tour!")
			joueur_play()  # Vous pouvez ici appeler une méthode pour le joueur humain
		
		# Incrémenter le tour
		tour_actuel += 1
		
		# Si le tour est terminé, mettre à jour l'affichage ou autre
		update_turn_display(tour_actuel)
	else:
		print("Le jeu est terminé!")
		# Vous pouvez ajouter une fonction pour gérer la fin du jeu
		fin_du_jeu()

# Appel du bot pour jouer
func bot_play():
	# Logique du bot pour jouer
	print("Le bot joue...")

# Appel du joueur pour jouer
func joueur_play():
	# Logique pour permettre au joueur de jouer
	print("Le joueur humain choisit une carte...")

# Exemple de fonction pour mettre à jour l'affichage du tour
func update_turn_display(tour):
	# Mettez à jour l'affichage du tour actuel ici
	pass

# Si vous avez une méthode de fin du jeu
func fin_du_jeu():
	# Logique pour la fin du jeu, comme afficher un message ou réinitialiser le jeu
	print("Le jeu est terminé!")


# Exemple d'ajout de cartes sur la table dans une méthode
func ajouter_carte_sur_table(carte: Carte):
	cartes_sur_table.append(carte)  # Ajouter une carte à la table (dans cartes_sur_table)
	print("Carte posée sur la table: ", carte.numero)



# Distribution des cartes aux joueurs
func preparer_cartes_jeu():
	print("📦 Distribution des cartes.")
	for joueur in joueurs:
		joueur.hand = Hand.new(deck.distribuer(nb_cartes))  # Chaque joueur reçoit un certain nombre de cartes

# Fonction pour jouer une carte
func jouer_carte(nom_joueur: String, carte_data: Dictionary) -> String:
	for joueur in joueurs:
		if joueur.nom == nom_joueur:
			var carte = Carte.new(carte_data["numero"])
			var rang = table.ajouter_carte(carte)
			
			# Si la carte ne peut pas être posée, on ramasse une rangée
			if rang == -1:
				var choix_rang = trouver_rang_a_ramasser()
				var cartes_ramassees = table.ramasser_rang(choix_rang)
				var penalite = 0
				for c in cartes_ramassees:
					penalite += c.tetes  # Calcul de la pénalité en fonction des têtes
				joueur.update_score(penalite)
				table.forcer_nouvelle_rangée(choix_rang, carte)
				return "ramassage"
			else:
				return "pose"
	return "erreur"

# Trouver le meilleur rang où poser une carte
func trouver_best_rang(carte_data: Dictionary) -> int:
	var carte = Carte.new(carte_data["numero"])
	var best_index = -1
	var min_diff = INF

	for i in range(table.rangs.size()):
		if table.rangs[i].cartes.size() > 0:
			var derniere_carte = table.rangs[i].cartes.back()
			var diff = carte.numero - derniere_carte.numero
			if diff > 0 and diff < min_diff:
				min_diff = diff
				best_index = i
	return best_index

# Trouver la rangée à ramasser (celle qui a le moins de têtes)
func trouver_rang_a_ramasser() -> int:
	var min_tetes = INF
	var index = 0
	for i in range(table.rangs.size()):
		var total = 0
		for carte in table.rangs[i].cartes:
			total += carte.tetes
		if total < min_tetes:
			min_tetes = total
			index = i
	return index

# Vérifier si la manche est terminée (tous les joueurs ont joué leurs cartes)
func check_end_manche() -> bool:
	return joueurs[0].hand.cartes.size() == 0

# Vérifier si le jeu est terminé (selon les points ou les manches)
func check_end_game() -> bool:
	for j in joueurs:
		if j.score >= nb_max_heads:
			return true
	return manche_actuelle >= nb_max_manches

# Passer à la manche suivante
func manche_suivante():
	manche_actuelle += 1
	deck = Deck.new(true)
	table = Table.new(deck)
	for joueur in joueurs:
		joueur.hand = Hand.new(deck.distribuer(nb_cartes))

# Réinitialiser le jeu avec les paramètres actuels
func reset_game():
	var noms = []
	for j in joueurs:
		noms.append(j.nom)
	_init(nb_joueurs, noms, nb_max_manches, nb_max_heads, nb_cartes)
func initialiser_table():
	print("🛠 Initialisation de la table (côté logique)...")
	
	table.rangs.clear()
	for i in range(4):
		var carte = deck.piocher()
		var nouvelle_rangée = Range.new()
		nouvelle_rangée.ajouter_carte(carte)
		table.rangs.append(nouvelle_rangée)

		# 🛠 C'est ici que tu remplis aussi all_cards pour l'UI si besoin
		var card_data = {
			"id": carte.numero,
			"path": carte.get_image_path()
		}
		all_cards.append(card_data)
