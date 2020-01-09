extends Node

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var		server_selection	= "0.0.0.0"
var		player_id			= 1
var		player_name			= "new"
var		ui_mode				= false
var		target
var		interface			= null
var		vr_selected			= false
var		vr_interface		= null
var		player				= null
var		kills				= 0
var		level				= 0
var		stats_inited		= false
var		lobby_map_selection	= ""
var		game_uptime			= 0
var		map					= ""
var		mode				= "ctf"
# set mode to "ctf", "deathmatch", or "team_deathmatch"
var		my_team				= null
var		teams				= false
var		admins				= [ "cam" , "NotHawthorne" , "jeremy" , "testbot" ]
var		first_load			= true
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
