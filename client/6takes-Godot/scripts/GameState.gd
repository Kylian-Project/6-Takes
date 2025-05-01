#autoload file to pass lobby info between scenes
extends Node

var id_lobby = ""
var lobby_name = ""
var player_info = {}
var is_host = false
var is_public = true
var players_limit
var players_count = 1
var other_players = []
var data
