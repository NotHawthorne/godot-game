extends KinematicBody

# Camera
var	camera_angle		= 0
var	mouse_sensitivity	= 0.3

# Physics
var	velocity			= Vector3()
var	direction			= Vector3()
const	FLY_SPEED		= 40
const	FLY_ACCEL		= 4

# Network
var	control				= false
var	player_id			= 0
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
	pass # Replace with function body.

func	_physics_process(delta):
	if (control == true):
		# Reset player direction
		direction	= Vector3()
		var aim		= $Head/Camera.get_global_transform().basis
		if Input.is_action_pressed("move_forward"):
			direction -= aim.z
		if Input.is_action_pressed("move_backward"):
			direction += aim.z
		if Input.is_action_pressed("move_left"):
			direction -= aim.x
		if Input.is_action_pressed("move_right"):
			direction += aim.x
		direction	= direction.normalized()
		var target	= direction * FLY_SPEED
		velocity	= velocity.linear_interpolate(target, FLY_ACCEL * delta)
		rpc_unreliable("do_move", velocity, player_id)
		move_and_slide(velocity)

remote	func	do_move(position, pid):
	var	root	= get_parent()
	var	pnode	= root.get_node(str(pid))
	pnode.move_and_slide(position)

func	_input(event):
	if event is InputEventMouseMotion and control == true:
		$Head.rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
		var change = -event.relative.y * mouse_sensitivity
		if change + camera_angle < 90 and change + camera_angle > -90:
			$Head/Camera.rotate_x(deg2rad(change))
			camera_angle += change
	if event is InputEventMouseButton and control == true:
		var	bullet_scene	= load("res://bullet.tscn")
		var	bullet			= bullet_scene.instance()
		get_node('Head/Camera/RayCast').add_child(bullet)