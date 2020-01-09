extends KinematicBody

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
var		vr_player		= true
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
var		jumping			= false
#var		camera_angle	= 0
const GRAVITY = 9.8
const JUMP_SPEED = 5800
const DASH_SPEED = 150

var update_timer		= Timer.new()
var db_timer			= Timer.new()
var fire_cooldown		= Timer.new()
var message_timer		= Timer.new()

var time_off_ground		= 0

func _ready():
	$"Head/Viewport-VR".size = global.interface.get_render_targetsize()
		
		# Tell our viewport it is the arvr viewport
	$"Head/Viewport-VR".arvr = true
		
		# Uncomment this if you are using an older driver
	$"Head/Viewport-VR".hdr = false
		
		# turn off vsync
	OS.vsync_enabled = false
		
		# change our physics fps
	Engine.target_fps = 90
		
		# Tell our display what we want to display
	$"Head/VR-Viewport-Mirror/Viewport-UI".set_viewport_texture($"Head/Viewport-VR".get_texture())

	get_node("Head/Viewport-VR/ARVROrigin/Right_Hand").connect("button_pressed", self, "_on_button_pressed")
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
		#$"Head/Viewport-VR/ARVROrigin".set_global_transform(self.get_global_transform())
	global.first_load = false
	first_load = false
	#camera_angle = $"Head/Viewport-VR/ARVROrigin/ARVRCamera".get_rotation_degrees().y
	bone_transform = $xbot/Skeleton.get_bone_custom_pose($xbot/Skeleton.find_bone("mixamorig_Spine1"))

func	_on_button_pressed(p_button):
	if	p_button == 15 : #vr trigger is button 15 on oculus
		var	bullet_scene	= load("res://scenes/objects/bullet.tscn")
		var	bullet			= bullet_scene.instance()
		var ray = global.player.get_node('Head/Viewport-VR/ARVROrigin/Right_Hand/gun_container/RayCast')
		bullet.bullet_owner = global.player.player_id
		if (ray == null) :
			return
		
		if (ray.is_colliding()):
			print("hit" + ray.get_collider().get_name())
		#bullet.target = $Head/Camera/CamCast.get_collision_point()
		if (ray.get_collider()) :
			if ray.get_collider().has_method("_deal_damage") :
				print("CALLING SEND DAMAGE")
				self._deal_damage(ray.get_collider(), weapon.damage)
			elif ray.get_collider().get_parent() and ray.get_collider().get_parent().has_method("pop_capsule") :
					var capsule_pad = ray.get_collider().get_parent()
					capsule_pad.play_sound("capsule")
					capsule_pad.pop_capsule()
					capsule_pad.rpc_unreliable("pop_capsule")
		
		
		play_sound("player", player_name, "play", "shoot")
		ammo -= 1
		print("fired!")

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
	var chosen_player = get_parent().get_node(str(id))
	chosen_player.set_global_transform(chosen)
	if (chosen_player.vr_player == true) :
		var transform = chosen_player.get_global_transform()
		transform.basis.y =  Vector3(0, 1, 0)
		chosen_player.get_node("Head/Viewport-VR/ARVROrigin").set_global_transform(transform)
	rpc_unreliable("do_update", chosen, id)

remote func		gamestate_update(data):
	print("received update request")
	global.player.get_node('Head/Camera/Viewport-UI/UI/ChatBox/ChatText').add_text(data.chat_log)
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
		# Reset player directionp-0000000000000000 
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
		
		var controller = $"Head/Viewport-VR/ARVROrigin".get_node("Left_Hand")
		if controller and controller.get_is_active():
			var left_right = controller.get_joystick_axis(0)
			var forwards_backwards = controller.get_joystick_axis(1)
			if (abs(forwards_backwards) > 0.1 or abs(left_right) > 0.1) :



				var aim	= get_node("Head/Viewport-VR/ARVROrigin/ARVRCamera").get_global_transform().basis
				var JumpCast = get_node("JumpCast")
	
				#direction = Vector3()
				if JumpCast.is_colliding() :
					if forwards_backwards < -0.1 :
						direction += aim.z
						#if (anim != "rifle_jump2"):
						anim = "rifle_run_forward"
	
					if  forwards_backwards > 0.1 :
						direction -= aim.z
						anim = "rifle_run_forward"
					if left_right < -0.1 :
						direction -= aim.x
						anim = "rifle_run_forward"
					if left_right > 0.1:
						direction += aim.x
						anim = "rifle_run_forward"
					if time_off_ground == 0 :
						play_sound("player", player_name, "start", "walk")
				else :
					play_sound("player", player_name, "stop", "walk")
				if (Input.is_action_just_pressed("jump")):
					var dashing = false
					if (jumps <= 1):
						play_sound("player", player_name, "stop", "walk")
						if jumps == 0 :
							play_sound("player", player_name, "play", "jump")
						#f (anim == "rifle_jump2"):
							#xbot/AnimationPlayer.stop(true)
							anim = "rifle_jump2"
						if get_node("Head/Camera/WallCast1").is_colliding() or get_node("Head/Camera/WallCast2").is_colliding() or get_node("Head/Camera/WallCast3").is_colliding() or get_node("Head/Camera/WallCast4").is_colliding() :
							print("colliding")
							dashing = true
							velocity.y += (JUMP_SPEED * delta) / 1.9
							velocity -= -aim.z * (DASH_SPEED)
						if get_node("Head/Camera/WallCast1").is_colliding() and left_right < -0.1:
							jumps = 0
							velocity -= aim.x * (DASH_SPEED * 1.2)
						if get_node("Head/Camera/WallCast2").is_colliding() and forwards_backwards > 0.1:
							jumps = 0
							velocity += -aim.z * (DASH_SPEED * 1.2)
						if get_node("Head/Camera/WallCast3").is_colliding() and left_right > 0.1:
							jumps = 0
							velocity += aim.x * (DASH_SPEED * 1.2)
						if get_node("Head/Camera/WallCast4").is_colliding() and forwards_backwards < -0.1:
							jumps = 0
							velocity -= -aim.z * (DASH_SPEED * 1.2)
					if JumpCast.is_colliding():
						jumps = 0
						#print("colliding")
					if jumps < 2:
						#print("jumping...")
						direction.y = 1 + (direction.y * delta)
						velocity.y += JUMP_SPEED * delta
						jumps += 1
						time_off_ground = 0
					if jumps == 2:
						if (forwards_backwards > 0.1):
							play_sound("player", player_name, "play", "dash")
							velocity -= -aim.z * DASH_SPEED
							dashing = true
						if (forwards_backwards < -0.1):
							play_sound("player", player_name, "play", "dash")
							velocity += -aim.z * DASH_SPEED
							dashing = true
						if (left_right < -0.1):
							play_sound("player", player_name, "play", "dash")
							velocity -= aim.x * DASH_SPEED
							dashing = true
						if (left_right > 0.1):
							play_sound("player", player_name, "play", "dash")
							velocity += aim.x * DASH_SPEED
							dashing = true
						if dashing == true:
							velocity.y -= (JUMP_SPEED * delta) / 2
							jumps += 1
					#direction.y = 0
					time_off_ground += (delta * 2)
	velocity.y -= GRAVITY * time_off_ground
	direction = direction.normalized()
	var target = direction * RUN_SPEED
	var accel
	if (RUN_ACCEL * delta > RUN_SPEED):
		accel = RUN_SPEED
	else:
		accel = RUN_ACCEL * delta
	velocity = velocity.linear_interpolate(target, accel)
	rpc_unreliable("do_move", velocity, player_id, randi())
	move_and_slide(velocity, Vector3( 0, 0, 0 ), false, 4, 1, true)
	var pos = self.get_global_transform()
	if (vr_player == true) :
		pos.basis.y =  Vector3(0, 1, 0)
		$"Head/Viewport-VR/ARVROrigin".set_global_transform(pos)
	var rot_x = -(get_node("Head/Viewport-VR/ARVROrigin/ARVRCamera").get_rotation_degrees().x)
	var rot_y = 180 + (get_node("Head/Viewport-VR/ARVROrigin/ARVRCamera").get_rotation_degrees().y)
	get_node("Head").set_rotation_degrees(Vector3(0, rot_y, 0))
	get_node("xbot").set_rotation_degrees(Vector3(0, rot_y, 0))
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
		if (pnode.vr_player == true) :
			var transform = pnode.get_global_transform()
			transform.basis.y =  Vector3(0, 1, 0)
			pnode.get_node("Head/Viewport-VR/ARVROrigin").set_global_transform(transform)
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
		if (pnode.vr_player == true):
			pnode.get_node('Head/Viewport-VR/ARVROrigin/Right_Hand/gun_container', true, false).add_child(bullet)
		else:
			pnode.find_node('gun_container', true, false).add_child(bullet)

remote	func	set_weapon(id, wid):
	var pnode = get_parent().get_node(str(id))
	print("SET WEAPON CALLED ON " + str(id))
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

remote func		stats_add_kill(id, pname, kills):
	var updateReq = {}
	updateReq.name = pname
	updateReq.kills = kills
	for id in to_update:
		if id.name == pname:
			id.kills = kills
			return
	to_update.push_back(updateReq)

func	get_message(message):
	if player_id == 1 :
		get_parent().find_node('network').send_message(player_id, message)
	else :
		get_parent().find_node('network').rpc_id(1, "send_message", player_id, message)

remote func		display_stats(data, teams) :
	print("got data")
	if control == true:
		var textbox = $"Head/Camera/Viewport-UI/UI/game_stats/stats_text"
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
		$"Head/Camera/Viewport-UI/UI/game_stats".visible = true

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
		$Head/Camera/game_stats.visible = false	

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
