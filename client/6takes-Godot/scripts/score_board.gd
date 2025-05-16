extends Control

var top_ranks
var others 
var rankings_list
var gameboard

func _ready():
	top_ranks = [$rankingsControl/Panel/rankingsList/first,
					 $rankingsControl/Panel/rankingsList/second,
					 $rankingsControl/Panel/rankingsList/third
					]
	
	others = [$rankingsControl/Panel/rankingsList/player4,
				$rankingsControl/Panel/rankingsList/player5,
				$rankingsControl/Panel/rankingsList/player6,
				$rankingsControl/Panel/rankingsList/player7,
				$rankingsControl/Panel/rankingsList/player8,
				$rankingsControl/Panel/rankingsList/player9,
				$rankingsControl/Panel/rankingsList/player10
				]

	rankings_list = GameState.rankings
	update_rankings(rankings_list)
	
	if gameboard and !gameboard.game_ended:
		start_auto_close_timer()
	
	if gameboard and gameboard.game_ended:
		start_leave_timer()
			
func update_rankings(rankings_list):
	for i in range(len(rankings_list)):
		var player = rankings_list[i]
		
		if i < 3:
			var rank_node = top_ranks[i]
			var name_label = rank_node.get_node("name")
			var score_label = rank_node.get_node("score")
			name_label.text = player["nom"]
			score_label.text = str(player["score"])
			rank_node.visible = true

		else:
			var rank_node = others[i -3]
			var name_label = rank_node.get_node("name")
			var score_label = rank_node.get_node("score")
			name_label.text = player["nom"]
			score_label.text = str(player["score"])
			others[i -3].visible = true

func _on_leave_button_pressed() -> void:
	reinit_gameState()
	get_tree().change_scene_to_file("res://scenes/multiplayer_menu.tscn")


func _on_close_button_pressed() -> void:
	if is_instance_valid(self):
		queue_free()

func reinit_gameState():
	GameState.players_count = 0
	GameState.data = null
	GameState.id_lobby = ""
	GameState.lobby_name = ""
	GameState.other_players = []
	GameState.rankings = null 

func start_leave_timer():
	await get_tree().create_timer(8).timeout
	if is_instance_valid(self):
		queue_free()
		get_tree().change_scene_to_file("res://scenes/multiplayer_menu.tscn")
		

func start_auto_close_timer():
	await get_tree().create_timer(8).timeout
	if is_instance_valid(self):
		queue_free()
