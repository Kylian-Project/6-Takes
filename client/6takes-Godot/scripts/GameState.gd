#autoload file to pass lobby info between scenes
extends Node

var id_lobby = ""
var lobby_name = ""
var player_info = {}
var is_host = false
var is_public = true
var players_limit = 10
var players_count = 1
var bot_count = 0
var other_players = []
var card_number = 10
var timer = 45
var data
var rounds
var rankings
var first_game = true
