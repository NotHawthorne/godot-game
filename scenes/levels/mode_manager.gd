extends Node

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
var mode = null

func _ready():
	pass

func start_game() :
	if global.player_id == 1 :
		if global.mode == "deathmatch" :
			mode = load("res://scripts/game_modes/deathmatch.gd").new()
			mode.start_game()

# Replace with function body.
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
