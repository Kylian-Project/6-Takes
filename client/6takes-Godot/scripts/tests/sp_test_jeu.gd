extends Node

const Jeu6Takes = preload("res://scripts/singleplayer/jeu6takes.gd")
const BotLogic = preload("res://scripts/singleplayer/bot_logic.gd")

var jeu: Jeu6Takes
var bots = []

func _ready():
	start_test_game()

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func start_test_game():
	randomize()

	var settings = Global.game_settings
	var bot_count = settings.get("bot_count", 3)
	var noms = ["Moi"]

	for i in range(bot_count):
		noms.append("Bot" + str(i + 1))

	var nb_cartes = settings.get("nb_cartes", 10)
	var nb_max_heads = settings.get("nb_max_heads", 66)
	var nb_max_manches = settings.get("nb_max_manches", 5)

	jeu = Jeu6Takes.new(noms.size(), noms, nb_max_manches, nb_max_heads, nb_cartes)
	bots = jeu.joueurs.slice(1, jeu.joueurs.size())

	print("Partie initialisée avec les joueurs :", noms)

	jouer_manche()

func afficher_mains_joueurs():
	print("Mains des joueurs :")
	for joueur in jeu.joueurs:
		var cartes_text = joueur.hand.cartes.map(func(c): return str(c.numero) + "(" + str(c.tetes) + ")")
		print(joueur.nom, "→", cartes_text)

func afficher_plateau():
	print("Plateau actuel :")
	for i in range(jeu.table.rangs.size()):
		var rang = jeu.table.rangs[i]
		var cartes = rang.cartes.map(func(c): return str(c.numero) + "(" + str(c.tetes) + ")")
		print("g", i+1, ":", ", ".join(cartes))

func jouer_manche():
	var manche = 1
	while not jeu.check_end_game():
		print("Manche", manche)

		while not jeu.check_end_manche():
			print("Nouveau tour")
			afficher_plateau()
			afficher_mains_joueurs()
			await wait(1.0)

			var cartes_choisies = []
			for joueur in jeu.joueurs:
				var carte
				if joueur.nom == "Moi":
					# Choix manuel depuis l'interface (à intégrer côté Godot UI)
					continue # La carte sera transmise via signal ou interaction UI
				else:
					var index = BotLogic.choisir_carte_aleatoire(joueur.hand.cartes)
					carte = joueur.hand.jouer_carte(index)
					print(joueur.nom, "a choisi:", carte.numero, "(", carte.tetes, "têtes)")
					cartes_choisies.append({ "joueur": joueur, "carte": carte })
					await wait(0.5)

			# En attente de la carte de "Moi" via UI avant de trier et jouer
			# cartes_choisies.append({ "joueur": joueur_moi, "carte": carte_choisie })
			cartes_choisies.sort_custom(func(a, b): return a["carte"].numero < b["carte"].numero)

			for choix in cartes_choisies:
				var joueur = choix["joueur"]
				var carte = choix["carte"]
				var best_index = jeu.table.trouver_best_rang(carte)
				await wait(0.8)

				if best_index == -1:
					var rang_index = BotLogic.choisir_rang_aleatoire()
					var cartes_r = jeu.table.rangs[rang_index].recuperer_cartes_special_case()
					var penalty = 0
					for c in cartes_r:
						penalty += c.tetes
					joueur.update_score(penalty)
					print(joueur.nom, "ramasse", cartes_r.size(), "cartes pour", penalty, "têtes.")
					jeu.table.rangs[rang_index] = Rang.new(carte)
				else:
					var rang = jeu.table.rangs[best_index]
					rang.ajouter_carte(carte)
					if rang.est_pleine():
						var cartes_r = rang.recuperer_cartes()
						var penalty = 0
						for c in cartes_r:
							penalty += c.tetes
						joueur.update_score(penalty)
						rang.cartes = [rang.cartes[5]]

				afficher_plateau()
				await wait(1.0)

		print("\nFin de la manche", manche)
		for j in jeu.joueurs:
			print(j.nom, ":", j.score, "points")
		manche += 1
		jeu.manche_suivante()
		await wait(2.0)

	print("\nFin de la partie ! Scores finaux :")
	for j in jeu.joueurs:
		print(j.nom, ":", j.score, "points")
