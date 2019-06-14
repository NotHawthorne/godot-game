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
var		vr_player		= false
var		server_map
var		respawning		= false
var		team			= null
var		is_headless		= false
var		has_flag		= null
 
const GRAVITY = 9.8
const JUMP_SPEED = 5800
const DASH_SPEED = 80

var update_timer		= Timer.new()
var db_timer			= Timer.new()
var fire_cooldown		= Timer.new()
var message_timer		= Timer.new()

var time_off_ground		= 0

var shoot_sound = AudioStreamPlayer.new()

func _ready():
	$Head/Camera/ChatBox/Control/LineEdit.set_process_input(false)
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
	self.add_child(shoot_sound)
	shoot_sound.stream = load("res://sounds/shoot_sound.wav")
	if (control == true):
		#var players = get_parent().find_node("network").players
		#for id in players :
		#	print("ttest")
		#	if id != player_id :
		#		print("asking " + str(id) + " for info")
		#		rpc_id(id, "ask_for_health", player_id)
		OS.set_window_size(Vector2(1280, 720))
		$Head/Camera/Sprite.visible = true
		$Head/Camera/player_info.visible = true
		$Head/Camera/ChatBox.visible = true
		if (player_id != 1):
			print("name: " + player_name + "team: " + team)
			rpc_id(1, "gamestate_request", player_id)
		if (player_id == 1) :
			get_parent().find_node("mode_manager").start_game()
			get_parent().find_node("mode_manager").add_player(1, player_name, team)
			match_info("start")
	get_node("Spatial/Viewport-VR/ARVROrigin/C2").connect("button_pressed", self, "_on_button_pressed")

func	_on_button_pressed(p_button):
	if	p_button == 15 : #vr trigger is button 15 on oculus
		var	bullet_scene	= load("res://scenes/objects/bullet.tscn")
		var	bullet			= bullet_scene.instance()
		bullet.bullet_owner = player_id
		rpc_unreliable("fire_bullet", player_id)
		$"Spatial/Viewport-VR/ARVROrigin/C2/gun_container/RayCast".add_child(bullet)
		print("fired!")

func hide_messages() :
	$Head/Camera/match_messages.visible = false

remote func set_flag_owner(id, flag_team) :
	var pnode = get_parent().get_node(str(id))
	pnode.has_flag = flag_team

remote func drop_flag(id, flag_team, location) :
	if flag_team == "blue" :
		get_parent().get_node("Blue_Flag_Pad").drop_flag(location)
		get_parent().get_node("Blue_Flag_Pad").rpc_unreliable("drop_flag", location)
	if flag_team == "red" :
		get_parent().get_node("Red_Flag_Pad").drop_flag(location)
		get_parent().get_node("Red_Flag_Pad").rpc_unreliable("drop_flag", location)
	set_flag_owner(id, null)
	rpc_unreliable("set_flag_owner", id, null)

remote func pickup_flag(id, flag_team) :
	if flag_team == "blue" :
		get_parent().get_node("Blue_Flag_Pad").pop_flag()
		get_parent().get_node("Blue_Flag_Pad").rpc_unreliable("pop_flag")
	if flag_team == "red" :
		get_parent().get_node("Red_Flag_Pad").pop_flag()
		get_parent().get_node("Red_Flag_Pad").rpc_unreliable("pop_flag")
	set_flag_owner(id, flag_team)
	rpc_unreliable("set_flag_owner", id, flag_team)

remote func reset_flag(id, flag_team) :
	print("resetting flag")
	if flag_team == "blue" :
		get_parent().get_node("Blue_Flag_Pad").reset_flag()
		get_parent().get_node("Blue_Flag_Pad").rpc_unreliable("reset_flag")
	if flag_team == "red" :
		get_parent().get_node("Red_Flag_Pad").reset_flag()
		get_parent().get_node("Red_Flag_Pad").rpc_unreliable("reset_flag")
	set_flag_owner(id, null)
	rpc_unreliable("set_flag_owner", id, null)

remote func match_info(message) :
	$Head/Camera/match_messages/round_start.visible = false
	$Head/Camera/match_messages/you_win.visible = false
	$Head/Camera/match_messages/you_lose.visible = false
	$Head/Camera/match_messages/tied_game.visible = false
	if message == "start" :
		$Head/Camera/match_messages/round_start.visible = true
	if message == "win" :
		$Head/Camera/match_messages/you_win.visible = true
	if message == "lose" :
		$Head/Camera/match_messages/you_lose.visible = true
	if message == "tied" :
		$Head/Camera/match_messages/tied_game.visible = true
	$Head/Camera/match_messages.visible = true
	message_timer.start()

func	reset_players() :
	var players = get_parent().get_node('network').players
	for p in players :
		choose_spawn(p)
	choose_spawn(1)
	match_info("start")
	rpc_unreliable("match_info", "start")

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
	gamestate.chat_log = global.player.get_node('Head/Camera/ChatBox/ChatText').get_text()
	var pnode = get_parent().get_node(str(pid))
	get_parent().find_node("mode_manager").add_player(pid, pnode.player_name, pnode.team)
	rpc_id(pid, "gamestate_update", gamestate)

remote func leaderboard_add_stat(id, kill, death, cap) :
	get_parent().find_node("mode_manager").add_stat(id, kill, death, cap)

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
	respawning = false

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

remote func		update_health(pid, health) :
	var	root	= get_parent()
	var	pnode	= root.get_node(str(pid))
	if (pnode):
		pnode.health = health
	else:
		print("Couldn't update position for " + str(pid))

remote func		sync_health(pid, hp):
	#if get_tree().is_network_server():
	var network_interface = get_parent().find_node("network")
	print("Setting " + str(pid) + " health to " + str(hp))
	for id in network_interface.players:
		print("yo")
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
				if shot.has_flag != null :
					drop_flag(shot.player_id, shot.has_flag, shot.get_global_transform())
				choose_spawn(shot.player_id)
				sync_health(shot.player_id, 100)
				stats_add_kill(player_id, global.player_id, global.kills)
				get_parent().find_node("mode_manager").add_stat(shot.player_id, 0, 1, 0)
				get_parent().find_node("mode_manager").add_stat(player_id, 1, 0, 0)
			else:
				if shot.has_flag != null :
					rpc_id(1, "drop_flag", shot.player_id, shot.has_flag, shot.get_global_transform())
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
		$Head/Camera/game_stats.visible = false	
