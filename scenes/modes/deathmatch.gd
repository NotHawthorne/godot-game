extends Node

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
var game_timer = Timer.new()
var game_length = 150
var message_timer = Timer.new()
func _ready():
	message_timer.set_wait_time(2)
	message_timer.one_shot = true
	message_timer.connect("timeout", self, "finish_endgame")
	add_child(message_timer)
	game_timer.set_one_shot(true)
	game_timer.set_wait_time(game_length)
	game_timer.connect("timeout", self, "end_game")
	add_child(game_timer)
	pass # Replace with function body.

func start_game() :
	print("game started")
	game_timer.start()

func finish_endgame() :
	get_parent().reset_game()
	start_game()

func end_game() :
	print("game over!")
	var winner_id = 0
	var winner_kills = 0
	var gamestate = get_parent().gamestate
	for pnode in gamestate.id :
		print(gamestate.players[pnode] + " kills: " + str(gamestate.kills[pnode]) + " deaths: " + str(gamestate.deaths[pnode]))
		if gamestate.kills[pnode] > winner_kills :
			winner_kills = gamestate.kills[pnode]
			winner_id = pnode
	if winner_id != 0 :
		print(gamestate.players[winner_id] + " won with " + str(gamestate.kills[winner_id]) + " kills!")
		if winner_id == 1 :
			global.player.match_info("win")
		else :
			global.player.rpc_id(winner_id, "match_info", "win")
	for pnode in gamestate.id :
		if pnode != winner_id :
			if pnode == 1 :
				global.player.match_info("lose")
			else :
				global.player.rpc_id(pnode, "match_info", "lose")
	message_timer.start()
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
