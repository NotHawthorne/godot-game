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
	global.player_id = 1;
	spawn_player(1, "Server", global.map)

func			join_server():
	player_name	= global.player_name
	var	host	= NetworkedMultiplayerENet.new()
	
	host.create_client(global.server_selection, DEFAULT_PORT)
	get_tree().set_network_peer(host)
	global.player_id = get_tree().get_network_unique_id()
	
func			_player_connected(id):
	pass

func			_player_disconnected(id):
	unregister_player(id)
	print("PLAYER LEFT")
	rpc("unregister_player", id)

func			_connected_ok(id):
	rpc_id(1, "user_ready", get_tree().get_network_unique_id(), player_name)

remote	func	user_ready(id, player_name):
	if get_tree().is_network_server():
		rpc_id(id, "register_in_game", global.map)

remote	func	register_in_game(curr_map):
	rpc("register_new_player", get_tree().get_network_unique_id(), player_name, curr_map)
	register_new_player(get_tree().get_network_unique_id(), player_name, curr_map)

func			_server_disconnected():
	print("server disconnected!")
	quit_game()

remote	func	register_new_player(id, name, curr_map):
	if get_tree().is_network_server():
		rpc_id(id, "register_new_player", 1, player_name, curr_map)
		for peer_id in players:
			rpc_id(id, "register_new_player", peer_id, players[peer_id], curr_map)
	players[id] = name
	spawn_player(id, name, curr_map)

func			_kill_player(id):
	for peer_id in players:
		var node = get_tree().get_root().find_node(str(peer_id))
		if (node.dead == true):
			rpc_unreliable("do_update", get_tree().get_root().find_node('Spawn').get_global_transform(), peer_id)
			#DOESNT UPDATE SERVER

remote	func	deal_damage(id, tid, amt):
#	if (get_tree().is_network_server()):
#		rpc_id(id, "deal_damage", tid, 15)
#		for peer_id in players:
#			rpc_id(id, "register_new_player", tid, 15)
#	else:
#		rpc_id(1, "deal_damage", tid, amt)
#	var user = get_tree().get_root().find_node(str(tid), true, false)
#	user.health -= 15
#	print("DEALING DAMAGE: " + user.health)
#	if (user.health < 0):
#		user.health = 0;
#		print("USER DIED")
#		user.dead = true;
	pass

#remote	func	register_player(id, name):
#	if get_tree().is_network_server():
#		rpc_id(id, "register_player", 1, player_name)
#		for peer_id in players:
#			rpc_id(id, "register_player", peer_id, players[peer_id])
#			rpc_id(peer_id, "register_player", id, name)
#	players[id] = name

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

func	send_message(message):
	#rpc_id(1, "_broadcast_message", message)
	global.player.get_node('Head/Camera/ChatBox/ChatText').add_text(message)
	global.player.get_node('Head/Camera/ChatBox/ChatText').newline()

func			spawn_player(id, name, map):

	# FIXME:
	# THE BELOW IF CHECK IS A BAND-AID!
	# FOR SOME REASON CLIENTS ARE GETTING MULTIPLE spawn_player RPCS
	# FIX THIS LATER PLEASE
	
	if (get_parent().find_node(str(id), true, false)):
		return
	#if id == get_tree().get_network_unique_id():
	var player_scene
	if global.interface and global.interface.initialize():
		player_scene = load("res://scenes/objects/VR-Player/VR-Player.tscn")
	else:
		player_scene = load("res://scenes/objects/player.tscn")
	var player			= player_scene.instance()
	
	player.set_name(str(id))
	player.player_id	= id
	player.player_name	= name
	player.server_map = map
	print("global map is" + global.lobby_map_selection)
	print("server map is" + map)
	#global.define_level($PanelContainer/Panel/Control.selection)
	#for peer_id in players :

	if id == get_tree().get_network_unique_id():
		player.set_network_master(id)
		player.control		= true
		global.player		= player
	get_parent().add_child(player)
	if (name):
		print(name + " joined!")
	for admin in global.admins :
		if admin == name and global.lobby_map_selection != map:
			rpc_id(1, "_change_map", global.lobby_map_selection)
			_change_map(global.lobby_map_selection)