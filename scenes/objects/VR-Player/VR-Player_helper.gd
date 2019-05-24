extends KinematicBody

# Camera
var	camera_angle		= 0
var	mouse_sensitivity	= 0.3
var action_button_id 	= 15
# Physics
var	velocity			= Vector3()
var	direction			= Vector3()
const	FLY_SPEED		= 40
const	FLY_ACCEL		= 4

# Network
var	control				= false
var	player_id			= 0
var	player_name			= ""
#var	direct				= ["N", "W", "S", "O"]
var	move				= "stop"
#var	step				= 0
#var	pos					= Vector3(10, 1, 10)
#var	rot_l				= 0
#var	rot_r				= 0
#var	id					= {16777232:0, 16777234:1, 16777231:2, 16777233:3}
#var	root				= false
#var	console				= false
var	tree				= {}
var		health			= 100
var		dead			= false

func _ready():
	get_node("Spatial/Viewport-VR/ARVROrigin/C2").connect("button_pressed", self, "_on_button_pressed")

func	_on_button_pressed(p_button):
	if p_button == action_button_id:
		var	bullet_scene	= load("res://scenes/objects/bullet.tscn")
		var	bullet			= bullet_scene.instance()
		bullet.bullet_owner = player_id
		rpc_unreliable("fire_bullet", player_id)
		$"Spatial/Viewport-VR/ARVROrigin/C2/MeshInstance/RayCast".add_child(bullet)
		print("fired!")