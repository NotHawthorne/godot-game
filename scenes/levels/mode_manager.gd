extends Node

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
var mode = null
var mode_scene
var gamestate	= {}

func _ready():
	pass

func add_player(id, pname) :
	gamestate.id[id] = id
	gamestate.players[id] = pname
	gamestate.kills[id] = 0
	gamestate.deaths[id] = 0

func add_stat(id, kill, death) :
	gamestate.kills[id] += kill
	gamestate.deaths[id] += death
	if death == 1 :
		print(gamestate.players[id] + "'s deaths = " + str(gamestate.deaths[id]))
	if kill == 1 :
		print(gamestate.players[id] + "'s deaths = " + str(gamestate.kills[id]))

func start_game() :
	if global.player_id == 1 :
		gamestate.id = {}
		gamestate.players = {}
		gamestate.kills = {}
		gamestate.deaths = {}
		if global.mode == "deathmatch" :
			mode = load("res://scenes/modes/deathmatch.tscn")
			mode_scene = mode.instance()
			self.add_child(mode_scene)
			mode_scene.init_game()

# Replace with function body.
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass