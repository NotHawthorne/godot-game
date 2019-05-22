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

var update_timer		= Timer.new()

func _ready():
	update_timer.set_wait_time(1)
	update_timer.connect("timeout", self, "_update")
	add_child(update_timer)
	update_timer.start()

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

func			_update():
	if control == true:
		print("Sending position update packet! " + str(player_id) + "|" + str(global.player_id))
		rpc_unreliable("do_update", get_global_transform(), player_id)

remote	func	do_update(_transform, pid):
	var	root	= get_parent()
	var	pnode	= root.get_node(str(pid))
	if (pnode):
		pnode.set_global_transform(_transform)
	else:
		print("Couldn't update position for " + str(pid))

remote	func	do_move(position, pid):
	var	root	= get_parent()
	var	pnode	= root.get_node(str(pid))
	pnode.move_and_slide(position)

remote	func	do_rot(headrot, camrot, pid):
	var	root	= get_parent()
	var	pnode	= root.get_node(str(pid))
	var	rot		= Vector3()
	rot.y = headrot.y
	rot.x = camrot.x
	pnode.get_node('Head').set_rotation_degrees(rot)
	print(str(rot))
	#print(str(pid) + "rot")

remote	func	fire_bullet(id):
	var	bullet_scene	= load("res://bullet.tscn")
	var	bullet			= bullet_scene.instance()
	var	root			= get_parent()
	var	pnode			= root.get_node(str(id))
	bullet.bullet_owner = id
	pnode.get_node('Head/Camera/RayCast').add_child(bullet)
	print(str(id) + " fired a bullet")

func	_input(event):
	if event is InputEventMouseMotion:
		var change = 0
		if control == true:
			$Head.rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
			change = -event.relative.y * mouse_sensitivity
			if change + camera_angle < 90 and change + camera_angle > -90:
				$Head/Camera.rotate_x(deg2rad(change))
				camera_angle += change
			rpc_unreliable("do_rot", $Head.get_rotation_degrees(), $Head/Camera.get_rotation_degrees(), global.player_id)
	if event is InputEventMouseButton and control == true:
		rpc_unreliable("fire_bullet", player_id)