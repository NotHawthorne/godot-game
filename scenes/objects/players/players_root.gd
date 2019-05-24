extends Spatial

var		player_id		= 0
var		player_name		= ""
var		control			= false
#var	direct			= ["N", "W", "S", "O"]
var		move			= "stop"
#var	step			= 0
#var	pos				= Vector3(10, 1, 10)
#var	rot_l			= 0
#var	rot_r			= 0
#var	id				= {16777232:0, 16777234:1, 16777231:2, 16777233:3}
#var	root			= false
#var	console			= false
var		tree			= {}
var		health			= 100
var		dead			= false

var	interface;
var player
# Called when the node enters the scene tree for the first time.
func _ready():
	interface = ARVRServer.find_interface("OpenVR")
	if interface and interface.initialize():
		player = load("res://scenes/objects/players/vr_player.tscn")
	else:
		player = load("res://scenes/objects/players/non-vr_player.tscn")
	var instance = player.instance()
	add_child(instance)
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
