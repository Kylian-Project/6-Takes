extends Control

var top_ranks
var others 
var rankings_list



func _ready():

	top_ranks = [$rankingsControl/Panel/rankingsList/first,
				 $rankingsControl/Panel/rankingsList/second,
				 $rankingsControl/Panel/rankingsList/third]

	others = [$rankingsControl/Panel/rankingsList/player4,
			  $rankingsControl/Panel/rankingsList/player5,
			  $rankingsControl/Panel/rankingsList/player6,
			  $rankingsControl/Panel/rankingsList/player7,
			  $rankingsControl/Panel/rankingsList/player8,
			  $rankingsControl/Panel/rankingsList/player9,
			  $rankingsControl/Panel/rankingsList/player10]
	update_rankings(Global.rankings)
	
func update_rankings(rankings_list):
	var max_slots = top_ranks.size() + others.size()

	for i in range(min(len(rankings_list), max_slots)):
		var player = rankings_list[i]

		var rank_node = null
		if i < top_ranks.size():
			rank_node = top_ranks[i]
		elif i - top_ranks.size() < others.size():
			rank_node = others[i - top_ranks.size()]

		if rank_node == null:
			print("❌ Rank node introuvable à l'index ", i)
			continue

		var name_label = rank_node.get_node_or_null("name")
		var score_label = rank_node.get_node_or_null("score")

		if name_label == null or score_label == null:
			print("❌ Sous-node 'name' ou 'score' manquant dans ", rank_node.name)
			continue

		name_label.text = player.get("nom", "???")
		score_label.text = str(player.get("score", 0))
		rank_node.visible = true

func _on_leave_button_pressed():
	Global.rankings.clear()  # 🧹 Vide le tableau une fois affiché
	get_tree().change_scene_to_file("res://scenes/SPLobbyScene.tscn")
