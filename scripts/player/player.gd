extends KinematicBody

# Camera
var	camera_angle		= 0
var	mouse_sensitivity	= 0.3

# Physics
var	velocity			= Vector3()
var	direction			= Vector3()
const	RUN_SPEED		= 22.5
const	RUN_ACCEL		= 11.7

# Network
var	control				= false
var	jumps				= 0
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
var		tree			= {}
var		health			= 100
var		dead			= false
var		to_update		= []
var		weapon			= weapons.pistol
var		can_fire		= true
var		vr_player		= false
var		server_map

const GRAVITY = 9.8
const JUMP_SPEED = 5800
const DASH_SPEED = 80

var update_timer		= Timer.new()
var db_timer			= Timer.new()
var fire_cooldown		= Timer.new()

var time_off_ground		= 0

func _ready():
	update_timer.set_wait_time(1)
	update_timer.connect("timeout", self, "_update")
	add_child(update_timer)
	update_timer.start()
	fire_cooldown.set_wait_time(float(weapon.cooldown / 1000))
	fire_cooldown.one_shot = true
	fire_cooldown.connect("timeout", self, "flip_cooldown")
	add_child(fire_cooldown)
	if (get_tree().is_network_server()):
		db_timer.set_wait_time(10)
		db_timer.connect("timeout", self, "update_stats")
		add_child(db_timer)
		db_timer.start()
	if global.stats_inited == false and player_id == global.player_id:
		global.stats_inited = true
		stats_init()
		set_weapon(player_id, 1)

func	_physics_process(delta):
	if (control == true):
		# Reset player direction
		direction	= Vector3()
		if $JumpCast.is_colliding():
			time_off_ground = 0
		var aim		= $Head/Camera.get_global_transform().basis
		if Input.is_action_pressed("move_forward"):
			direction -= aim.z
		if Input.is_action_pressed("move_backward"):
			direction += aim.z
		if Input.is_action_pressed("move_left"):
			direction -= aim.x
		if Input.is_action_pressed("move_right"):
			direction += aim.x
		if (Input.is_action_just_pressed("jump")):
			var dashing = false
			if (jumps <= 1):
				if $Head/Camera/WallCast1.is_colliding() or $Head/Camera/WallCast2.is_colliding() or $Head/Camera/WallCast3.is_colliding() or $Head/Camera/WallCast4.is_colliding():
					print("colliding")
					dashing = true
					velocity.y += (JUMP_SPEED * delta) / 1.9
					velocity -= aim.z * (DASH_SPEED)
				if $Head/Camera/WallCast1.is_colliding() and Input.is_action_pressed("move_left"):
					jumps = 0
					velocity -= aim.x * (DASH_SPEED * 1.2)
				if $Head/Camera/WallCast2.is_colliding() and Input.is_action_pressed("move_backward"):
					jumps = 0
					velocity += aim.z * (DASH_SPEED * 1.2)
				if $Head/Camera/WallCast3.is_colliding() and Input.is_action_pressed("move_right"):
					jumps = 0
					velocity += aim.x * (DASH_SPEED * 1.2)
				if $Head/Camera/WallCast4.is_colliding() and Input.is_action_pressed("move_forward"):
					jumps = 0
					velocity -= aim.z * (DASH_SPEED * 1.2)
			if $JumpCast.is_colliding():
				jumps = 0
				print("colliding")
			if jumps < 2:
				print("jumping...")
				direction.y = 1 + (direction.y * delta)
				velocity.y += JUMP_SPEED * delta
				jumps += 1
				time_off_ground = 0
			if jumps == 2:
				if (Input.is_action_pressed("move_forward")):
					velocity -= aim.z * DASH_SPEED
					dashing = true
				if (Input.is_action_pressed("move_backward")):
					velocity += aim.z * DASH_SPEED
					dashing = true
				if (Input.is_action_pressed("move_left")):
					velocity -= aim.x * DASH_SPEED
					dashing = true
				if (Input.is_action_pressed("move_right")):
					velocity += aim.x * DASH_SPEED
					dashing = true
				if dashing == true:
					velocity.y -= (JUMP_SPEED * delta) / 2
		direction.y = 0
		time_off_ground += (delta * 2)
		velocity.y -= GRAVITY * time_off_ground
		direction	= direction.normalized()
		var target	= direction * RUN_SPEED
		var accel
		if (RUN_ACCEL * delta > RUN_SPEED):
			accel = RUN_SPEED
		else:
			accel = RUN_ACCEL * delta
		velocity	= velocity.linear_interpolate(target, accel)
		rpc_unreliable("do_move", velocity, player_id)
		move_and_slide(velocity, Vector3( 0, 0, 0 ), false, 4, 1, true)

func			_update():
	if control == true:
		print("Sending position update packet! " + str(player_id) + "|" + str(global.player_id))
		rpc_unreliable("do_update", get_global_transform(), player_id)

func			flip_cooldown():
	can_fire = true

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

remote	func	set_vr_mode(id, mode):
	vr_player = mode

remote	func	fire_bullet(id, amt, target):
	print(str(id) + " fired a bullet")
	if (str(id) != str(player_id)):
		var	bullet_scene	= load("res://scenes/objects/bullet.tscn")
		var	bullet			= bullet_scene.instance()
		var	root			= get_parent()
		var	pnode			= root.get_node(str(id))
		bullet.bullet_owner = id
		bullet.target = target
		bullet.set_damage(amt)
		#if (pnode.vr_player == true):
		#	pnode.find_node('RayCast', true, false).add_child(bullet)
		#else:
		pnode.find_node('gun_container', true, false).add_child(bullet)

remote	func	kill(id):
	var pnode = get_parent().get_node(str(id))
	var	parent = get_parent()
	if (!pnode):
		return
	pnode.set_global_transform(get_parent().get_node('Spawn').get_global_transform())
	pnode.health = 100	

remote	func	damage(id, amt):
	print(str(id) + " hit you!")
	health -= amt;
	if (health < 0):
		rpc_unreliable("kill", player_id)
		print("you died!")

remote	func	set_weapon(id, wid):
	var pnode = get_parent().get_node(str(id))
	print("SET WEAPON CALLED ON " + str(id))
	if wid == 1:
		var to_remove = pnode.get_node('Head/gun_container').get_child(0)
		var model = load("res://models/pistol.tscn")
		var to_replace = model.instance()
		var old_loc = to_remove.get_global_transform()
		pnode.get_node('Head/gun_container').remove_child(to_remove)
		pnode.get_node('Head/gun_container').add_child(to_replace)
	else:
		print("INVALID WEAPON SET REQUEST")
	pass

func			_deal_damage(id, amt):
	rpc_unreliable("damage", player_id, amt)
	var parent = get_parent()
	var pnode = parent.get_node(str(player_id))
	pnode.health -= amt;
	if (pnode.health < 0):
		global.kills += 1
		print("TRYING TO KILL")
		rpc_id(1, "stats_add_kill", player_id, global.player_name, global.kills) 

#	STATS_ADD_KILL
#	NEEDS TO NOT UPDATE ON EVERY KILL
#	CAUSES SERVER LAG
#	MAYBE ADD TO COUNTER AND TIMEOUT AN UPDATE FUNCITON?
#	FIXME:

func			update_stats():
	for id in to_update:
		var http = HTTPClient.new()
		var err = http.connect_to_host("35.236.33.159", 3000)
		assert(err == OK)
		while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
			http.poll()
		print("Connected!")
		assert(http.get_status() == HTTPClient.STATUS_CONNECTED)
		var body = str("stat[handle]=", id.name, "&stat[level]=", 1, "&stat[kills]=", id.kills)
		http.request(
			http.METHOD_POST, 
			'/stats.json', 
			["Content-Type: application/x-www-form-urlencoded", "Content-Length: " + str(body.length())], 
			body
		)
		while http.get_status() != HTTPClient.STATUS_BODY and http.get_status() != HTTPClient.STATUS_CONNECTED:
			http.poll()
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
		to_update.erase(id)
	pass

remote func		stats_add_kill(id, pname, kills):
	var updateReq = {}
	updateReq.name = pname
	updateReq.kills = kills
	for id in to_update:
		if id.name == pname:
			id.kills = kills
			return
	to_update.push_back(updateReq)

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
	var body = str("stat[handle]=", global.player_name)
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
			if (text.result[0].kills):
				global.kills = text.result[0].kills
			print("Kills: " + str(text.result[0].kills))
	else:
		print("No response...")
	pass

func	get_message(message):
	get_parent().find_node('network').send_message(message)

func	_input(event):
	if event is InputEventMouseMotion and !global.ui_mode:
		var change = 0
		if control == true:
			$Head.rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
			change = -event.relative.y * mouse_sensitivity
			if change + camera_angle < 90 and change + camera_angle > -90:
				$Head/Camera.rotate_x(deg2rad(change))
				$Head/gun_container.rotate_x(deg2rad(change))
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
	if Input.is_action_just_pressed("restart") :
		self.set_global_transform(get_parent().get_node('Spawn').get_global_transform())
		self.health = 100
	if Input.is_action_just_pressed("start_chat") :
		control = false
		get_node('Head/Camera/ChatBox/Control/LineEdit').grab_focus()
	if event is InputEventMouseButton and control == true and can_fire == true:
		var	bullet_scene	= load("res://scenes/objects/bullet.tscn")
		var	bullet			= bullet_scene.instance()
		bullet.bullet_owner = player_id
		bullet.set_damage(weapon.damage)
		if ($Head/Camera/CamCast.is_colliding()):
			print($Head/Camera/CamCast.get_collision_normal())
		bullet.target = $Head/Camera/CamCast.get_collision_point()
		rpc_unreliable("fire_bullet", player_id, weapon.damage, bullet.target)
		
		$Head/gun_container.add_child(bullet)
		#can_fire = false
		#fire_cooldown.start()
		var shoot_sound = AudioStreamPlayer.new()
		self.add_child(shoot_sound)
		shoot_sound.stream = load("res://sounds/shoot_sound.wav")
		shoot_sound.play()
		print("fired!")
	if Input.is_action_just_pressed("Weapon 1"):
		print("trying to change weapon")
		rpc_unreliable("set_weapon", player_id, 1)
		pass