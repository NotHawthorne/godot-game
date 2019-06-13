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
	get_parent().get_parent().get_node("local_settings").spawn_flags()

func start_game() :
	print("game started")
	game_timer.start()

func finish_endgame() :
	get_parent().reset_game()
	start_game()

func end_game() :
	print("game over!")
	var winner
	var gamestate = get_parent().gamestate
	if gamestate.team_captures["blue"] > gamestate.team_captures["red"] :
		winner = "blue"
	elif gamestate.team_captures["blue"] < gamestate.team_captures["red"] :
		winner = "red"
	else :
		winner = null
	if winner != null :
		print(winner + " won with " + str(gamestate.team_captures[winner]) + " captures!")
		for pnode in gamestate.id :
			if pnode == 1 :
				if gamestate.team[pnode] == winner :
					global.player.match_info("win")
				else :
					global.player.match_info("lose")
			else :
				if gamestate.team[pnode] == winner :
					global.player.rpc_id(pnode, "match_info", "win")
				else :
					global.player.rpc_id(pnode, "match_info", "lose")
	else :
		for pnode in gamestate.id :
			if pnode == 1 :
				global.player.match_info("tied")
			else :
				global.player.rpc_id(pnode, "match_info", "tied")
	message_timer.start()