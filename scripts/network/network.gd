extends Node

const	DEFAULT_PORT	= 4242
const	MAX_PEERS		= 10
var		players			= {}
var		player_name

func			_ready():
	get_tree().connect("network_peer_connected", self, "_connected_ok")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	#get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")

func			start_server():
	player_name = global.player_name;
	var	host	= NetworkedMultiplayerENet.new()
	print("Attempting to connect to " + global.server_selection)
	
	if (global.server_selection != '0.0.0.0'):
		print("Joining server!")
		join_server()
		return
	var	err		= host.create_server(DEFAULT_PORT, MAX_PEERS)
	get_tree().set_network_peer(host)
	print("Starting server!")
	global.player_id = 1
	# uncomment to give headless server a team
	if global.teams and !global.my_team :
		print("server team is blue")
		global.my_team = "blue"
	spawn_player(1, "Server", global.map, global.vr_selected, global.my_team, null)

func			join_server():
	player_name	= global.player_name
	var	host	= NetworkedMultiplayerENet.new()
	
	host.create_client(global.server_selection, DEFAULT_PORT)
	get_tree().set_network_peer(host)
	global.player_id = get_tree().get_network_unique_id()
	
func			_player_connected(id):
	pass

func			_player_disconnected(id):
	if (get_tree().is_network_server()):
		if get_parent().has_node(str(id)) :
			get_parent().get_node("mode_manager").remove_player(id)
		send_message(players[id] + " has left!")
	unregister_player(id)
	print("PLAYER LEFT")
	rpc("unregister_player", id)

func			_connected_ok(id):
	if	global.vr_selected :
		rpc_id(1, "user_ready", get_tree().get_network_unique_id(), player_name, true, global.my_team)
	else :
		rpc_id(1, "user_ready", get_tree().get_network_unique_id(), player_name, false, global.my_team)

remote	func	user_ready(id, p_name, vr, team):
	if get_tree().is_network_server():
		#var state = get_parent().get_node("mode_manager").gamestate
		if global.teams == true :
			#if team == "blue" :
			#	if state.team_size["red"] < 1 :
			#		rpc_id(id, "register_in_game", global.map, vr, "red")
			#	elif state.team_size["blue"] - state.team_size["red"] >= 4 :
			#		rpc_id(id, "register_in_game", global.map, vr, "red")
			#	else :
			#		rpc_id(id, "register_in_game", global.map, vr, team)
			#elif team == "red" :
			#	if state.team_size["blue"] < 1 :
			#		rpc_id(id, "register_in_game", global.map, vr, "blue")
			#	elif state.team_size["red"] - state.team_size["blue"] >= 4 :
			#		rpc_id(id, "register_in_game", global.map, vr, "blue")
			#	else :
			#		rpc_id(id, "register_in_game", global.map, vr, team)
			if team :
				register_new_player(id, p_name, global.map, vr, team, null)
			else :
				register_new_player(id, p_name, global.map, vr, "blue", null)
		else :
			register_new_player(id, p_name, global.map, vr, null, null)

remote	func	register_in_game(curr_map, vr, team):
	rpc_id(1, "register_new_player", get_tree().get_network_unique_id(), player_name, curr_map, vr, team, null)

func			_server_disconnected():
	print("server disconnected!")
	quit_game()

func	choose_spawn_on_join(team) :
	var spawns
	var chosen
	if global.teams == false :
		spawns = get_tree().get_nodes_in_group("spawns")
	elif team != null :
		print("teams enabled")
		if team == "blue" :
			spawns = get_tree().get_nodes_in_group("b_spawns")
		else :
			spawns = get_tree().get_nodes_in_group("r_spawns")
	chosen = spawns[randi() % spawns.size()]
	return chosen.get_global_transform()


remote	func	register_new_player(id, name, curr_map, vr, team, location):
	if get_tree().is_network_server():
		var spawn = choose_spawn_on_join(team)
		rpc_id(id, "register_new_player", id, name, curr_map, vr, team, spawn)
		rpc_id(id, "register_new_player", 1, player_name, global.map, global.vr_selected, global.player.team, global.player.get_global_transform())
		for peer_id in players:
			var pnode = get_parent().get_node(str(peer_id))
			rpc_id(id, "register_new_player", peer_id, players[peer_id], global.map, pnode.vr_player, pnode.team, pnode.get_global_transform)
		players[id] = name
		spawn_player(id, name, global.map, vr, team, spawn)
		return
	players[id] = name
	spawn_player(id, name, global.map, vr, team, location)

remote	func	unregister_player(id):
	if (get_parent().get_node(str(id))):
		get_parent().get_node(str(id)).queue_free()
		players.erase(id)

func			quit_game():
	get_tree().set_network_peer(null)
	players.clear()

func			on_timer_timeout():
	print("trying to switch!")
	get_tree().change_scene(global.map)

remote func		_change_map(map):
	if get_tree().is_network_server():
		print("changing map")
		global.map = map
		global.lobby_map_selection = map
		for peer_id in players :
			if players[peer_id] != global.player_name :
				rpc_id(peer_id, "_change_map", map)
		print("finished sending map change to players")
		_player_disconnected(get_tree().get_network_unique_id())
		global.player = null
		players.clear()
		get_tree().change_scene(global.map)
		return
	print("got change map signal!")
	_player_disconnected(get_tree().get_network_unique_id())
	global.player = null
	global.map = map
	global.lobby_map_selection = map
	var timer = Timer.new()
	timer.set_wait_time( 2 )
	timer.connect("timeout",self,"on_timer_timeout") 
#timeout is what says in docs, in signals
#self is who respond to the callback
#_on_timer_timeout is the callback, can have any name
	add_child(timer) #to process
	timer.start() #to start

#remote func _broadcast_message(message):
#	if get_tree().is_network_server():
#		print("server: " + message)
#		global.player.get_node('Head/Camera/ChatBox/ChatText').add_text(message)
#		global.player.get_node('Head/Camera/ChatBox/ChatText').newline()
#		for peer_id in players :
#			if players[peer_id] != global.player_name :
#				rpc_id(peer_id, "_broadcast_message", message)
#		return
#	print("client: " + message)
#	global.player.get_node('Head/Camera/ChatBox/ChatText').add_text(message)
#	global.player.get_node('Head/Camera/ChatBox/ChatText').newline()

remote func rpc_message(message) :
	var chat_node = global.player.get_node('Head/Camera/ChatBox/ChatText')
	chat_node.add_text(message)
	chat_node.newline()

func	send_message(message):
	var chat_node = global.player.get_node('Head/Camera/ChatBox/ChatText')
	chat_node.add_text(message)
	chat_node.newline()
	rpc_unreliable("rpc_message", message)
	#rpc_id(1, "_broadcast_message", message)

func			spawn_player(id, name, map, vr, team, location):

	# FIXME:
	# THE BELOW IF CHECK IS A BAND-AID!
	# FOR SOME REASON CLIENTS ARE GETTING MULTIPLE spawn_player RPCS
	# FIX THIS LATER PLEASE
	
	if (get_parent().find_node(str(id), true, false)):
		return
	#if id == get_tree().get_network_unique_id():
	var player_scene
	if vr :
		player_scene = load("res://scenes/objects/VR-Player/VR-Player.tscn")
	else:
		player_scene = load("res://scenes/objects/player.tscn")
	var player			= player_scene.instance()
	
	player.set_name(str(id))
	player.player_id	= id
	player.player_name	= name
	player.server_map = map
	player.team = team
	print("global map is" + global.lobby_map_selection)
	print("server map is" + map)
	#global.define_level($PanelContainer/Panel/Control.selection)
	#for peer_id in players :
	if id == get_tree().get_network_unique_id():
		player.set_network_master(id)
		player.control		= true
		global.player		= player
		if OS.has_feature("Server") :
			player.is_headless = true
	get_parent().add_child(player)
	if (name && player.control == true):
		send_message(name + " joined!")
	#for admin in global.admins :
	#	if admin == name and global.lobby_map_selection != map:
	#		rpc_id(1, "_change_map", global.lobby_map_selection)
	#		_change_map(global.lobby_map_selection)
	print("trying to spawn new player")
	if location != null :
		print("transforming player to given position")
		player.set_global_transform(location)
	else :
		if global.player_id == 1 :
			global.player.choose_spawn(player.player_id)
		else :
			player.rpc_id(1, "choose_spawn", player.player_id)
	print("finished spawning new player")