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
var		max_health		= 200
var		starting_ammo	= 125
var		ammo			= starting_ammo
var		max_ammo		= 250
var		dead			= false
var		to_update		= []
var		weapon			= weapons.pistol
var		can_fire		= true
var		vr_player		= false
var		server_map
var		respawning		= false
var		team			= null
var		is_headless		= false
var		has_flag_dict	= {}
var		anim			= "rifle_idle"
var		bone_transform
var		last_do_move	= null
var		packet_id_cache = {}
var		first_load		= true
const GRAVITY = 9.8
const JUMP_SPEED = 5800
const DASH_SPEED = 150

var update_timer		= Timer.new()
var db_timer			= Timer.new()
var fire_cooldown		= Timer.new()
var message_timer		= Timer.new()

var time_off_ground		= 0

func _ready():
	$"Head/Camera/Viewport-UI/UI/ChatBox/Control/LineEdit".set_process_input(false)
	$Head/Camera/Player_SFX.id = player_id
	update_timer.set_wait_time(1)
	update_timer.connect("timeout", self, "_update")
	add_child(update_timer)
	update_timer.start()
	fire_cooldown.set_wait_time(float(weapon.cooldown / 1000))
	fire_cooldown.one_shot = true
	fire_cooldown.connect("timeout", self, "flip_cooldown")
	add_child(fire_cooldown)
	message_timer.set_wait_time(1)
	message_timer.one_shot = true
	message_timer.connect("timeout", self, "hide_messages")
	add_child(message_timer)
	if (get_tree().is_network_server()):
		db_timer.set_wait_time(10)
		db_timer.connect("timeout", self, "update_stats")
		add_child(db_timer)
		db_timer.start()
	if global.stats_inited == false and player_id == global.player_id:
		global.stats_inited = true
		stats_init()
		set_weapon(player_id, 1)
	if (control == true):
		#var players = get_parent().find_node("network").players
		#for id in players :
		#	print("ttest")
		#	if id != player_id :
		#		print("asking " + str(id) + " for info")
		#		rpc_id(id, "ask_for_health", player_id)
		var bone = $xbot/Skeleton.find_bone('mixamorig_Neck')
		var bone_transform = Transform(Vector3(0,0,0), Vector3(0,0,0), Vector3(0,0,0), Vector3(0,0,0))
		$xbot/Skeleton.set_bone_rest(bone, bone_transform);
		OS.set_window_size(Vector2(1280, 720))
		$"Head/Camera/Viewport-UI/UI/Sprite".visible = true
		$"Head/Camera/Viewport-UI/UI/player_info".visible = true
		$"Head/Camera/Viewport-UI/UI/ChatBox".visible = true
		if (player_id != 1):
			print("name: " + player_name + "team: " + team)
			rpc_id(1, "gamestate_request", player_id)
		if (player_id == 1) :
			get_parent().find_node("mode_manager").start_game()
			get_parent().find_node("mode_manager").add_player(1, player_name, team)
			match_info("start")
	global.first_load = false
	first_load = false
	bone_transform = $xbot/Skeleton.get_bone_custom_pose($xbot/Skeleton.find_bone("mixamorig_Spine1"))

func hide_messages() :
	$"Head/Camera/Viewport-UI/UI/match_messages".visible = false

remote func set_flag_owner(id, flag_team) :
	var pnode = get_parent().get_node(str(id))
	print("setting flag owner: " + pnode.player_name)
	pnode.has_flag_dict[flag_team] = !(pnode.has_flag_dict[flag_team])
	if not (pnode.has_flag_dict["blue"] or pnode.has_flag_dict["red"]) :
		print(pnode.player_name + " dropped all their flags")

remote func drop_flag(id, flag_dict, location) :
	if flag_dict["blue"] :
		set_flag_owner(id, "blue")
		get_parent().get_node("Blue_Flag_Pad").drop_flag(location)
		for p in get_parent().get_node("network").players :
			get_parent().get_node("Blue_Flag_Pad").rpc_id(p, "drop_flag", location)
			rpc_id(p, "set_flag_owner", id, "blue")
	if flag_dict["red"] :
		set_flag_owner(id, "red")
		location.x = location.transform.basis.x - 1
		get_parent().get_node("Red_Flag_Pad").drop_flag(location)
		for p in get_parent().get_node("network").players :
			get_parent().get_node("Red_Flag_Pad").rpc_id(p, "drop_flag", location)
			rpc_id(p, "set_flag_owner", id, "red")

remote func pickup_flag(id, flag_team) :
	set_flag_owner(id, flag_team)
	if flag_team == "blue" :
		play_sound("global", player_name, "play", "blue_flag_taken")
		get_parent().get_node("Blue_Flag_Pad").pop_flag()
		for p in get_parent().get_node("network").players :
			get_parent().get_node("Blue_Flag_Pad").rpc_id(p, "pop_flag")
			rpc_id(p, "set_flag_owner", id, flag_team)
	if flag_team == "red" :
		play_sound("global", player_name, "play", "red_flag_taken")
		get_parent().get_node("Red_Flag_Pad").pop_flag()
		for p in get_parent().get_node("network").players :
			get_parent().get_node("Red_Flag_Pad").rpc_id(p, "pop_flag")
			rpc_id(p, "set_flag_owner", id, flag_team)
	var pnode = get_parent().get_node(str(id))
	print(pnode.player_name + "picked up", flag_team)
	if pnode.has_flag_dict[flag_team] :
		print ("flag in dict")

remote func reset_flag(id, flag_team) :
	print("trying to reset flag")
	if flag_team["blue"] :
		set_flag_owner(id, "blue")
		get_parent().get_node("Blue_Flag_Pad").reset_flag()
		for p in get_parent().get_node("network").players :
			get_parent().get_node("Blue_Flag_Pad").rpc_id(p, "reset_flag")
			rpc_id(p, "set_flag_owner", id, "blue")
	if flag_team["red"] :
		set_flag_owner(id, "red")
		get_parent().get_node("Red_Flag_Pad").reset_flag()
		for p in get_parent().get_node("network").players :
			get_parent().get_node("Red_Flag_Pad").rpc_id(p, "reset_flag")
			rpc_id(p, "set_flag_owner", id, "red")

remote func match_info(message) :
	$"Head/Camera/Viewport-UI/UI/match_messages/round_start".visible = false
	$"Head/Camera/Viewport-UI/UI/match_messages/you_win".visible = false
	$"Head/Camera/Viewport-UI/UI/match_messages/you_lose".visible = false
	$"Head/Camera/Viewport-UI/UI/match_messages/tied_game".visible = false
	if message == "start" :
		$"Head/Camera/Viewport-UI/UI/match_messages/round_start".visible = true
	if message == "win" :
		$"Head/Camera/Viewport-UI/UI/match_messages/you_win".visible = true
	if message == "lose" :
		$"Head/Camera/Viewport-UI/UI/match_messages/you_lose".visible = true
	if message == "tied" :
		$"Head/Camera/Viewport-UI/UI/match_messages/tied_game".visible = true
	$"Head/Camera/Viewport-UI/UI/match_messages".visible = true
	message_timer.start()

func	reset_players() :
	var players = get_parent().get_node('network').players
	for p in players :
		if global.mode == "ctf" :
			var pnode = get_parent().get_node(str(p))
			if pnode.has_flag == true :
				reset_flag(p, pnode.has_flag)
		rpc_id(p, "match_info", "start")
		choose_spawn(p)
	if global.mode == "ctf" and has_flag_dict["red"] or has_flag_dict["blue"] :
		reset_flag(player_id, has_flag_dict)
	choose_spawn(1)
	match_info("start")

func	spawn(id) :
	print("finding spawns")
	var spawns
	var chosen
	if global.teams == false or get_parent().get_node(str(id)).is_headless :
		spawns = get_tree().get_nodes_in_group("spawns")
	elif get_parent().get_node(str(id)).team != null :
		print("teams enabled")
		if get_parent().get_node(str(id)).team == "blue" :
			spawns = get_tree().get_nodes_in_group("b_spawns")
		else :
			spawns = get_tree().get_nodes_in_group("r_spawns")
	chosen = spawns[randi() % spawns.size()]
	return chosen.get_global_transform()

remote func	choose_spawn(id) :
	print("spawning: " + str(id))
	var chosen = spawn(id)
	print("spawn chosen")
	get_parent().get_node(str(id)).set_global_transform(chosen)
	rpc_unreliable("do_update", chosen, id)

remote func		gamestate_update(data):
	print("received update request")
	global.player.get_node('Head/Camera/ChatBox/ChatText').add_text(data.chat_log)
	for player in data.players:
		print("updating player " + str(player.id))
		var pnode = get_parent().get_node(str(player.id))
		pnode.health = player.health

remote func	gamestate_request(pid):
	var gamestate	= {}
	var n_node		= get_parent().get_node('network')
	var players		= n_node.players
	gamestate.players = []
	for peer_id in players:
		var player_data = {}
		var player_node = get_parent().get_node(str(peer_id))
		player_data.id = peer_id
		player_data.health = player_node.health
		gamestate.players.push_back(player_data)
	var server_player = {}
	server_player.id = 1
	server_player.health = global.player.health
	gamestate.players.push_back(server_player)
	for player in gamestate.players:
		print(str(player.id) + ":" + str(player.health))
	gamestate.chat_log = global.player.get_node('Head/Camera/Viewport-UI/UI/ChatBox/ChatText').get_text()
	var pnode = get_parent().get_node(str(pid))
	get_parent().find_node("mode_manager").add_player(pid, pnode.player_name, pnode.team)
	rpc_id(pid, "gamestate_update", gamestate)

remote func leaderboard_add_stat(id, kill, death, cap) :
	get_parent().find_node("mode_manager").add_stat(id, kill, death, cap)

func	_physics_process(delta):
	if (control == true):
		# Reset player direction
		direction	= Vector3()
		if $JumpCast.is_colliding():
			#if time_off_ground > 0 and respawning == false :
			#	print("landed, time off ground: " + str(time_off_ground))
			#	play_sound("play", "landing")
			time_off_ground = 0
			jumps = 0
		if $JumpCast.is_colliding() and respawning == false :
			var col_obj = get_node("JumpCast").get_collider()
			if col_obj.get_name() == "Danger_Zone_Body" :
				ammo = starting_ammo
				respawning = true
				get_message(player_name + " has fallen and they can't get up!")
				update_health(player_id, 100)
				rpc_unreliable("update_health", player_id, 100)
				choose_spawn(player_id)
				respawning = false
				if player_id == 1 :
					get_parent().find_node("mode_manager").add_stat(player_id, 0, 1, 0)
					if has_flag_dict["red"] or has_flag_dict["blue"] :
						reset_flag(player_id, has_flag_dict)
					#if has_flag_dict["red"] or has_flag_dict["blue"] :
					#	drop_flag(player_id, has_flag_dict, self.get_global_transform())
				else :
					rpc_id(1, "leaderboard_add_stat", player_id, 0, 1, 0)
					#if has_flag_dict["red"] or has_flag_dict["blue"] :
					#	rpc_id(1, "drop_flag", player_id, has_flag_dict, self.get_global_transform())
					
					if has_flag_dict["red"] or has_flag_dict["blue"] :
						rpc_id(1, "reset_flag", player_id, has_flag_dict)
		elif !$JumpCast.is_colliding() and respawning == false :
			time_off_ground += delta * 2
		var aim		= $Head/Camera.get_global_transform().basis
		if Input.is_action_pressed("move_forward"):
			direction -= aim.z
			if (anim != "rifle_jump2"):
				anim = "rifle_run_forward"
			if time_off_ground == 0 :
				play_sound("player", player_name, "start", "walk")
		if $JumpCast.is_colliding() :
			if Input.is_action_pressed("move_backward"):
				direction += aim.z
			if Input.is_action_pressed("move_left"):
				direction -= aim.x
			if Input.is_action_pressed("move_right"):
				direction += aim.x
			
			if Input.is_action_pressed("move_backward") and not (Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right") or Input.is_action_pressed("move_forward")):
				play_sound("player", player_name, "start", "walk")
			if Input.is_action_pressed("move_left") and not (Input.is_action_pressed("move_forward") or Input.is_action_pressed("move_right") or Input.is_action_pressed("move_backward")):
				play_sound("player", player_name, "start", "walk")
			if Input.is_action_pressed("move_right") and not (Input.is_action_pressed("move_forward") or Input.is_action_pressed("move_left") or Input.is_action_pressed("move_backward")):
				play_sound("player", player_name, "start", "walk")
		else :
			play_sound("player", player_name, "stop", "walk")
		if Input.is_action_just_released("move_forward") and not (Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right") or Input.is_action_pressed("move_backward")):
			play_sound("player", player_name, "stop", "walk")
		if Input.is_action_just_released("move_backward") and not (Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right") or Input.is_action_pressed("move_forward")):
			play_sound("player", player_name, "stop", "walk")
		if Input.is_action_just_released("move_left") and not (Input.is_action_pressed("move_forward") or Input.is_action_pressed("move_right") or Input.is_action_pressed("move_backward")):
			play_sound("player", player_name, "stop", "walk")
		if Input.is_action_just_released("move_right") and not (Input.is_action_pressed("move_forward") or Input.is_action_pressed("move_left") or Input.is_action_pressed("move_backward")):
			play_sound("player", player_name, "stop", "walk")
		if (Input.is_action_just_pressed("jump")):
			var dashing = false
			if (jumps <= 1):
				play_sound("player", player_name, "stop", "walk")
				if jumps == 0 :
					play_sound("player", player_name, "play", "jump")
				if (anim == "rifle_jump2"):
					$xbot/AnimationPlayer.stop(true)
				anim = "rifle_jump2"
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
				#print("colliding")
			if jumps < 2:
				#print("jumping...")
				direction.y = 1 + (direction.y * delta)
				velocity.y += JUMP_SPEED * delta
				jumps += 1
				time_off_ground = 0
			if jumps == 2:
				if (Input.is_action_pressed("move_forward")):
					play_sound("player", player_name, "play", "dash")
					velocity -= aim.z * DASH_SPEED
					dashing = true
				if (Input.is_action_pressed("move_backward")):
					play_sound("player", player_name, "play", "dash")
					velocity += aim.z * DASH_SPEED
					dashing = true
				if (Input.is_action_pressed("move_left")):
					play_sound("player", player_name, "play", "dash")
					velocity -= aim.x * DASH_SPEED
					dashing = true
				if (Input.is_action_pressed("move_right")):
					play_sound("player", player_name, "play", "dash")
					velocity += aim.x * DASH_SPEED
					dashing = true
				if dashing == true:
					velocity.y -= (JUMP_SPEED * delta) / 2
					jumps += 1
		#direction.y = 0
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
		rpc_unreliable("do_move", velocity, player_id, randi())
		move_and_slide(velocity, Vector3( 0, 0, 0 ), false, 4, 1, true)
	$xbot/AnimationPlayer.play(anim);

func			_update():
	if control == true:
		if global.game_uptime == 0 :
			print("first position update packet! " + str(player_id) + "|" + str(global.player_id))
		global.game_uptime += 1
		if global.player_name != "Headless Server" and global.game_uptime % 10 == 0:
			print("(10 update ticks) position update packet " + str(player_id) + "|" + str(global.player_id))
		if global.player_name == "Headless Server" and global.game_uptime % 20 == 0:
			print("(40 update ticks) headless server update packet " + str(player_id) + "|" + str(global.player_id))
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

remote	func	do_move(position, pid, packet_id):
	var	root	= get_parent()
	var	pnode	= root.get_node(str(pid))
	if packet_id_cache.has("do_move") and packet_id_cache["do_move"] == packet_id :
		return
	else :
		packet_id_cache["do_move"] = packet_id
	if (position != last_do_move):
		pnode.move_and_slide(position)
		anim = "rifle_run_forward"
	else:
		anim = "rifle_idle"
	packet_id_cache[packet_id] = 1;

remote	func	do_rot(headrot, camrot, pid):
	var	root	= get_parent()
	var	pnode	= root.get_node(str(pid))
	var	rot		= Vector3()
	#rot.y = headrot.y
	#rot.x = camrot.x
	#pnode.get_node('Head').set_rotation_degrees(rot)
	var bone = pnode.get_node('xbot').get_node('Skeleton').find_bone('mixamorig_Spine1')
	pnode.get_node('xbot').get_node('Skeleton').set_bone_custom_pose(bone, camrot);
	pnode.get_node('xbot').rotation.y = headrot

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

remote	func	set_weapon(id, wid):
	var pnode = get_parent().get_node(str(id))
	print("SET WEAPON CALLED ON " + str(id))
	if wid == 1:
		var to_remove = pnode.get_node('xbot/Skeleton/BoneAttachment/gun_container').get_child(0)
		var model = load("res://models/pistol.tscn")
		var to_replace = model.instance()
		var old_loc = to_remove.get_global_transform()
		pnode.get_node('xbot/Skeleton/BoneAttachment/gun_container').remove_child(to_remove)
		pnode.get_node('xbot/Skeleton/BoneAttachment/gun_container').add_child(to_replace)
	else:
		print("INVALID WEAPON SET REQUEST")
	pass

remote func		update_health(pid, health) :
	var	root	= get_parent()
	var	pnode	= root.get_node(str(pid))
	print("Setting " + pnode.player_name + " health to " + str(health))
	if (pnode):
		pnode.health = health
	else:
		print("Couldn't update position for " + str(pid))

remote func		sync_health(pid, hp):
	#if get_tree().is_network_server():
	var network_interface = get_parent().find_node("network")
	print("Setting " + get_parent().get_node(str(pid)).player_name + " health to " + str(hp))
	for id in network_interface.players :
		rpc_id(id, "update_health", pid, hp)
	update_health(pid, hp)

remote func		reset_ammo() :
	ammo = starting_ammo

func			_deal_damage(shot, amt):
	if control == true :
		if shot.health - amt <= 0 :
			get_message(shot.player_name + " was fragged by " + player_name + "!")
			global.kills += 1
			print("TRYING TO KILL")
			if (player_id == 1):
				if shot.has_flag_dict["red"] or shot.has_flag_dict["blue"] :
					drop_flag(shot.player_id, shot.has_flag_dict, shot.get_global_transform())
				choose_spawn(shot.player_id)
				sync_health(shot.player_id, 100)
				stats_add_kill(player_id, global.player_id, global.kills)
				get_parent().find_node("mode_manager").add_stat(shot.player_id, 0, 1, 0)
				get_parent().find_node("mode_manager").add_stat(player_id, 1, 0, 0)
			else:
				if shot.has_flag_dict["red"] or shot.has_flag_dict["blue"] :
					rpc_id(1, "drop_flag", shot.player_id, shot.has_flag_dict, shot.get_global_transform())
				rpc_id(1, "choose_spawn", shot.player_id)
				rpc_id(1, "sync_health", shot.player_id, 100)
				rpc_id(1, "stats_add_kill", player_id, global.player_id, global.kills)
				rpc_id(1, "leaderboard_add_stat", shot.player_id, 0, 1, 0)
				rpc_id(1, "leaderboard_add_stat", player_id, 1, 0, 0)
			rpc_id(shot.player_id, "reset_ammo")
		else :
			if (player_id == 1):
				sync_health(shot.player_id, shot.health - amt)
			else:
				rpc_id(1, "sync_health", shot.player_id, shot.health - amt)
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
	global.kills = 0
	return
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
			if (text.result[0] and text.result[0].kills):
				global.kills = text.result[0].kills
			else :
				global.kills = 0
			print("Kills: " + str(global.kills))
	else:
		print("No response...")
	pass

func	get_message(message):
	if player_id == 1 :
		get_parent().find_node('network').send_message(player_id, message)
	else :
		get_parent().find_node('network').rpc_id(1, "send_message", player_id, message)

remote func		display_stats(data, teams) :
	print("got data")
	if control == true:
		var textbox = $Head/Camera/game_stats/stats_text
		textbox.clear()
		textbox.add_text("name			kills			deaths")
		textbox.newline()
		if teams :
			textbox.add_text("BLUE TEAM:")
			textbox.newline()
			textbox.add_text("captures: " + str(data.team_captures["blue"]))
			textbox.newline()
		for pnode1 in data.id :
			if !teams or (teams and get_parent().get_node(str(pnode1)).team == "blue") :
				textbox.add_text(data.players[pnode1] + "			" + str(data.kills[pnode1]) + "				" + str(data.deaths[pnode1]))
				textbox.newline()
		if teams :
			textbox.add_text("RED TEAM:")
			textbox.newline()
			textbox.add_text("captures: " + str(data.team_captures["red"]))
			textbox.newline()
			for pnode2 in data.id :
				if get_parent().get_node(str(pnode2)).team == "red" :
					textbox.add_text(data.players[pnode2] + "			" + str(data.kills[pnode2]) + "				" + str(data.deaths[pnode2]))
					textbox.newline()
		$Head/Camera/game_stats.visible = true

remote func		get_leaderboard(pid) :
	var data = get_parent().find_node("mode_manager").gamestate
	if pid == 1 :
		display_stats(data, global.teams)
	else :
		rpc_id(pid, "display_stats", data, global.teams)

func	get_gamestats(action) :
	if action == "show" :
		if player_id == 1 :
			get_leaderboard(1)
		else :
			rpc_id(1, "get_leaderboard", player_id)
	if action == "hide" :
		$"Head/Camera/Viewport-UI/UI/game_stats".visible = false	

remote func		remote_play_sound(node_type, node_name, id, mode, sound) :
	if node_type == "player" :
		var pnode = get_parent().get_node(str(id))
		var sound_node = pnode.get_node("Head/Camera/Player_SFX")
		if mode == "play" :
			sound_node.play_sound(sound)
		if mode == "start" :
			sound_node.start_sound(sound)
		if mode == "stop" :
			sound_node.stop_sound(sound)
	if node_type == "global" :
		var sound_node = global.player.get_node("Head/Camera/Player_SFX")
		if mode == "play" :
			sound_node.play_sound(sound)
	if node_type == "capsule" :
		if mode == "play" :
			print("playing sound on: " + get_parent().get_node(node_name).get_name())
			get_parent().get_node(node_name).play_sound("pop")

func play_sound(node_type, node_name, mode, sound) :
	if node_type == "player" :
		if mode == "play" :
			$Head/Camera/Player_SFX.play_sound(sound)
		if mode == "start" :
			$Head/Camera/Player_SFX.start_sound(sound)
		if mode == "stop" :
			$Head/Camera/Player_SFX.stop_sound(sound)
	if node_type == "global" :
		var sound_node = global.player.get_node("Head/Camera/Player_SFX")
		if mode == "play" :
			sound_node.play_sound(sound)
	elif node_type == "capsule" :
		if mode == "play" :
			print("playing sound on: " + get_parent().get_node(node_name).get_name())
			get_parent().get_node(node_name).play_sound("pop")
	rpc_unreliable("remote_play_sound", node_type, node_name, player_id, mode, sound)

func	_input(event):
	if event is InputEventMouseMotion and !global.ui_mode and control == true:
		var change = 0
		if control == true:
			$Head.rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
			$xbot.rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
			change = -event.relative.y * mouse_sensitivity
			var bone = $xbot/Skeleton.find_bone('mixamorig_Spine')
			#var bone_transform = $xbot/Skeleton.get_bone_custom_pose(bone)
			print(str(bone_transform))
			if change + camera_angle < 90 and change + camera_angle > -90:
				$Head/Camera.rotate_x(deg2rad(change))
				$Head/gun_container.rotate_x(deg2rad(change))
				var rot_amt = deg2rad(change)
				bone_transform = bone_transform.rotated(Vector3(1, 0, 0).normalized(), (-rot_amt) * 0.25)
				bone_transform = bone_transform.rotated(Vector3(0, 0, 1).normalized(), (rot_amt) * 0.25)
				$xbot/Skeleton.set_bone_custom_pose(bone, bone_transform);
				camera_angle += change
			rpc_unreliable("do_rot", $xbot.rotation.y, bone_transform, global.player_id)
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
	if Input.is_action_just_pressed("ui_focus_next") and control == true and !global.ui_mode :
		get_gamestats("show")
	if Input.is_action_just_released("ui_focus_next") and control == true and !global.ui_mode :
		get_gamestats("hide")
	if Input.is_action_just_pressed("restart") and control == true:
		ammo = starting_ammo
		if player_id == 1 :
			if has_flag_dict["red"] or has_flag_dict["blue"] :
				reset_flag(player_id, has_flag_dict)
			#if has_flag_dict["red"] or has_flag_dict["blue"] :
			#	print("dropping flag")
			#	drop_flag(player_id, has_flag_dict, self.get_global_transform())
			get_parent().find_node("mode_manager").add_stat(player_id, 0, 1, 0)
			choose_spawn(player_id)
			sync_health(player_id, 100)
		else :
			if has_flag_dict["red"] or has_flag_dict["blue"] :
				rpc_id(1, "reset_flag", player_id, has_flag_dict)
			#if has_flag_dict["red"] or has_flag_dict["blue"] :
			#	print("dropping flag")
			#	rpc_id(1, "drop_flag", player_id, has_flag_dict, self.get_global_transform())
			rpc_id(1, "leaderboard_add_stat", player_id, 0, 1, 0)
			rpc_id(1, "choose_spawn", player_id)
			rpc_id(1, "sync_health", player_id, 100)
	if Input.is_action_just_pressed("start_chat") and control == true :
		
		global.player.control = false
		get_tree().set_input_as_handled()
		$"Head/Camera/Viewport-UI/UI/ChatBox/Control/LineEdit".set_editable(true)
		$"Head/Camera/Viewport-UI/UI/ChatBox/Control/LineEdit".set_process_input(true)
		$"Head/Camera/Viewport-UI/UI/ChatBox/Control/LineEdit".grab_focus()
	if Input.is_action_pressed("shoot") and control == true and ammo > 0 and can_fire == true:
		#var	bullet_scene	= load("res://scenes/objects/bullet.tscn")
		#var	bullet			= bullet_scene.instance()
		#bullet.bullet_owner = player_id
		#bullet.set_damage(weapon.damage)
		if ($Head/Camera/CamCast.is_colliding()):
			print($Head/Camera/CamCast.get_collision_normal())
		#bullet.target = $Head/Camera/CamCast.get_collision_point()
		if $Head/Camera/CamCast.get_collider() :
			if $Head/Camera/CamCast.get_collider().has_method("_deal_damage") :
				print("CALLING SEND DAMAGE")
				self._deal_damage($Head/Camera/CamCast.get_collider(), weapon.damage)
			elif $Head/Camera/CamCast.get_collider().get_parent().has_method("pop_capsule") :
				play_sound("capsule", $Head/Camera/CamCast.get_collider().get_parent().get_name(), "play", "pop_capsule")
				$Head/Camera/CamCast.get_collider().get_parent().pop_capsule($Head/Camera/CamCast.get_collider().get_parent().get_name())
				#$Head/Camera/CamCast.get_collider().get_parent().get_node("pop_capsule").play()
		#rpc_unreliable("fire_bullet", player_id, weapon.damage, bullet.target)
		
		#$Head/gun_container.add_child(bullet)
		#can_fire = false
		#fire_cooldown.start()
		play_sound("player", player_name, "play", "shoot")
		ammo -= 1
		print("fired!")
	if Input.is_action_just_pressed("fullscreen") and control == true:
		OS.window_fullscreen = !OS.window_fullscreen
		var size = OS.get_real_window_size()
		OS.set_window_size(Vector2(size.x, size.y))
		$Head/Camera/Sprite.position.x = $Head/Camera/Sprite.get_viewport_rect().size.x / 2
		$Head/Camera/Sprite.position.y = $Head/Camera/Sprite.get_viewport_rect().size.y / 2
	if Input.is_action_just_pressed("Weapon 1") and control == true:
		print("trying to change weapon")
		rpc_unreliable("set_weapon", player_id, 1)
		pass
