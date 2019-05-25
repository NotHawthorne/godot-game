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

var update_timer		= Timer.new()

func _ready():
	update_timer.set_wait_time(1)
	update_timer.connect("timeout", self, "_update")
	add_child(update_timer)
	update_timer.start()
	if global.stats_inited == false and player_id == global.player_id:
		global.stats_inited = true
		stats_init()

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

remote	func	set_vr_mode(id):
	# Get the node of ID and set variable
	pass

remote	func	fire_bullet(id):
	print(str(id) + " fired a bullet")
	if (str(id) != str(player_id)):
		var	bullet_scene	= load("res://scenes/objects/bullet.tscn")
		var	bullet			= bullet_scene.instance()
		var	root			= get_parent()
		var	pnode			= root.get_node(str(id))
		bullet.bullet_owner = id
		pnode.find_node('RayCast', true, false).add_child(bullet)

remote	func	kill(id):
	var pnode = get_parent().get_node(str(id))
	var	parent = get_parent()
	if (!pnode):
		return
	pnode.set_global_transform(get_parent().get_node('Spawn').get_global_transform())
	pnode.health = 100	

remote	func	damage(id, amt):
	print(str(id) + " hit you!")
	health -= 15;
	if (health < 0):
		rpc_unreliable("kill", player_id)
		print("you died!")

func			_deal_damage(id, amt):
	rpc_unreliable("damage", player_id, amt)
	var parent = get_parent()
	var pnode = parent.get_node(str(player_id))
	pnode.health -= 15;
	if (pnode.health < 0):
		global.kills += 1
		print("TRYING TO KILL")
		rpc_id(1, "stats_add_kill", player_id, global.player_name, global.kills) 

remote func			stats_add_kill(id, name, kills):
	var http = HTTPClient.new()
	var err = http.connect_to_host("35.236.33.159", 3000)
	assert(err == OK)

	while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
		http.poll()
		print("Connecting..")
		OS.delay_msec(500)
	print("Connected!")
	assert(http.get_status() == HTTPClient.STATUS_CONNECTED)
	var body = str("stat[handle]=", name, "&stat[level]=", 1, "&stat[kills]=", kills)
	
	http.request(
		http.METHOD_POST, 
		'/stats.json', 
		["Content-Type: application/x-www-form-urlencoded", "Content-Length: " + str(body.length())], 
		body
	)
	while http.get_status() != HTTPClient.STATUS_BODY and http.get_status() != HTTPClient.STATUS_CONNECTED:
		http.poll()
		print("Sending login request...")
		OS.delay_msec(500)
	if (http.has_response()):
			var headers = http.get_response_headers_as_dictionary() # Get response headers.
			print("code: ", http.get_response_code()) # Show response code.
			print("**headers:\\n", headers) # Show headers.
			
			# Getting the HTTP Body
			
			if http.is_response_chunked():
			# Does it use chunks?
				print("Response is Chunked!")
			else:
				# Or just plain Content-Length
				var bl = http.get_response_body_length()
				print("Response Length: ",bl)
			
				# This method works for both anyway
			
			var rb = PoolByteArray() # Array that will hold the data.
			
			while http.get_status() == HTTPClient.STATUS_BODY:
			# While there is body left to be read
				http.poll()
				var chunk = http.read_response_body_chunk() # Get a chunk.
				if chunk.size() == 0:
					# Got nothing, wait for buffers to fill a bit.
					OS.delay_usec(1000)
				else:
			    	rb = rb + chunk # Append to read buffer.
			
			# Done!
			
			print("bytes got: ", rb.size())
			var text = JSON.parse(rb.get_string_from_ascii())
			if text.result and text.result.has("status"):
				print("Error retrieving stats")
				return
			print(text.result)
	print(err)
	assert (err == OK)

func	stats_init():
	print(str(player_id) + "initializing")
	var http = HTTPClient.new()
	var err = http.connect_to_host("35.236.33.159", 3000)
	var headers = [
		"User-Agent: Pirulo/1.0 (Godot)",
		"Accept: */*"
	]
	assert(err == OK)
	while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
		http.poll()
		print("Connecting2..")
		OS.delay_msec(500)
	print("Connected2!")
	assert(http.get_status() == HTTPClient.STATUS_CONNECTED)
	var body = str("stat[handle]=", global.player_name, "&stat[level]=", 1, "&stat[kills]=", 0)
	print("Forming request... ")
	err = http.request(
		HTTPClient.METHOD_POST, 
		'/stats.json', 
		headers,
		body
	)
	assert(err == OK) # Make sure all is OK.
	
	while http.get_status() == HTTPClient.STATUS_REQUESTING:
		# Keep polling for as long as the request is being processed.
		http.poll()
		print("Requesting...")
		if not OS.has_feature("web"):
			OS.delay_msec(500)
		else:
			# Synchronous HTTP requests are not supported on the web,
			# so wait for the next main loop iteration.
			yield(Engine.get_main_loop(), "idle_frame")
	print(str(http.get_status()))
	assert(http.get_status() == HTTPClient.STATUS_BODY or http.get_status() == HTTPClient.STATUS_CONNECTED) # Make sure request finished well.
	print("Checking response...")
	if (http.has_response()):
		print("Response!")
		headers = http.get_response_headers_as_dictionary() # Get response headers.
		print("code: ", http.get_response_code()) # Show response code.
		print("**headers:\\n", headers) # Show headers.
		
		# Getting the HTTP Body
		
		if http.is_response_chunked():
		# Does it use chunks?
			print("Response is Chunked!")
		else:
			# Or just plain Content-Length
			var bl = http.get_response_body_length()
			print("Response Length: ",bl)
		
			# This method works for both anyway
		
		var rb = PoolByteArray() # Array that will hold the data.
		
		while http.get_status() == HTTPClient.STATUS_BODY:
		# While there is body left to be read
			http.poll()
			var chunk = http.read_response_body_chunk() # Get a chunk.
			if chunk.size() == 0:
				# Got nothing, wait for buffers to fill a bit.
				OS.delay_usec(1000)
			else:
		    	rb = rb + chunk # Append to read buffer.
		
		# Done!
		
		print("bytes got: ", rb.size())
		var text = JSON.parse(rb.get_string_from_ascii())
		if text.result and text.result.has("status"):
			print("Error initializing stats!")
			return
		else:
			print(text.result)
			print("Kills: " + str(text.result[0].kills))
	else:
		print("No response...")
	pass

func	_input(event):
	if event is InputEventMouseMotion and !global.ui_mode:
		var change = 0
		if control == true:
			$Head.rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
			change = -event.relative.y * mouse_sensitivity
			if change + camera_angle < 90 and change + camera_angle > -90:
				$Head/Camera.rotate_x(deg2rad(change))
				$Head/gunthing.rotate_x(deg2rad(change))
				camera_angle += change
			rpc_unreliable("do_rot", $Head.get_rotation_degrees(), $Head/Camera.get_rotation_degrees(), global.player_id)
		
		#Detect what we're mousing over
		
		var center_pos = Vector2()
		center_pos.x = $Head/Camera.get_viewport().get_visible_rect().size.x / 2
		center_pos.y = $Head/Camera.get_viewport().get_visible_rect().size.y / 2
		var ray_from = $Head/Camera.project_ray_origin(center_pos)
		var ray_to	 = ray_from + $Head/Camera.project_ray_normal(center_pos) * 500
		var space_state = get_world().direct_space_state
		var selection = space_state.intersect_ray(ray_from, ray_to)
		if (selection.get("collider") && selection.collider.get("player_name") != null):
			global.target = selection.collider
		else:
			global.target = null
			
	if event is InputEventMouseButton and control == true:
		var	bullet_scene	= load("res://scenes/objects/bullet.tscn")
		var	bullet			= bullet_scene.instance()
		bullet.bullet_owner = player_id
		rpc_unreliable("fire_bullet", player_id)
		$Head/Camera/RayCast.add_child(bullet)
		print("fired!")