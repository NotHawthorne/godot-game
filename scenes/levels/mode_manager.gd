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

func add_player(id, pname, team) :
	gamestate.id[id] = id
	gamestate.players[id] = pname
	gamestate.kills[id] = 0
	gamestate.deaths[id] = 0
	if team :
		gamestate.team[id] = team

func remove_player(id) :
	print("removing player: " + str(id))
	gamestate.id.erase(id)
	gamestate.players.erase(id)
	gamestate.kills.erase(id)
	gamestate.deaths.erase(id)
	if gamestate.team[id] :
		gamestate.team.erase(id)

func add_stat(id, kill, death, caps) :
	gamestate.kills[id] += kill
	gamestate.deaths[id] += death
	if gamestate.team[id] :
		gamestate.team_kills[gamestate.team[id]] += kill
		gamestate.team_deaths[gamestate.team[id]] += death
		gamestate.team_captures[gamestate.team[id]] += caps
	if death == 1 :
		print(gamestate.players[id] + "'s deaths = " + str(gamestate.deaths[id]))
	if kill == 1 :
		print(gamestate.players[id] + "'s deaths = " + str(gamestate.kills[id]))
	if caps == 1 :
		print(gamestate.players[id] + "scored for team " + gamestate.team[id])

func reset_game() :
	for p in gamestate.id :
		gamestate.kills[p] = 0
		gamestate.deaths[p] = 0
		gamestate.team_kills["red"] = 0
		gamestate.team_kills["blue"] = 0
		gamestate.team_deaths["red"] = 0
		gamestate.team_deaths["blue"] = 0
		gamestate.team_captures["red"] = 0
		gamestate.team_captures["blue"] = 0
	global.player.reset_players()

func start_game() :
	if global.player_id == 1 :
		gamestate.id = {}
		gamestate.players = {}
		gamestate.kills = {}
		gamestate.deaths = {}
		gamestate.team = {}
		gamestate.team_kills = {}
		gamestate.team_deaths = {}
		gamestate.team_captures = {}
		gamestate.team_kills["red"] = 0
		gamestate.team_kills["blue"] = 0
		gamestate.team_deaths["red"] = 0
		gamestate.team_deaths["blue"] = 0
		gamestate.team_captures["red"] = 0
		gamestate.team_captures["blue"] = 0
		if global.mode == "deathmatch" :
			mode = load("res://scenes/modes/deathmatch.tscn")
		if global.mode == "team_deathmatch" :
			mode = load("res://scenes/modes/team_deathmatch.tscn")
		mode_scene = mode.instance()
		self.add_child(mode_scene)
		mode_scene.start_game()

# Replace with function body.
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass