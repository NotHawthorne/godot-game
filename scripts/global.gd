extends Node

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var		server_selection	= "0.0.0.0"
var		player_id			= 0
var		player_name
var		ui_mode				= false
var		target
var		interface			= null
var		vr_selected			= false
var		player
var		kills				= 0
var		level				= 0
var		stats_inited		= false
var		lobby_map_selection	= null
var		map					= "res://scenes/levels/default_level.tscn"
var		mode				= null
var		admins				= [ "cam" , "NotHawthorne" , "jeremy" , "testbot" ]
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
