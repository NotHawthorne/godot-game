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
	get_tree().connect("server_disconnected", self, "_server_disconnect")

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
	spawn_player(1, "Server")

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
		rpc_id(id, "register_in_game")

remote	func	register_in_game():
	rpc("register_new_player", get_tree().get_network_unique_id(), player_name)
	register_new_player(get_tree().get_network_unique_id(), player_name)

func			_server_disconnected():
	quit_game()

remote	func	register_new_player(id, name):
	if get_tree().is_network_server():
		rpc_id(id, "register_new_player", 1, player_name)
		for peer_id in players:
			rpc_id(id, "register_new_player", peer_id, players[peer_id])
	players[id] = name
	spawn_player(id, name)

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

func			spawn_player(id, name):
	
	# FIXME:
	# THE BELOW IF CHECK IS A BAND-AID!
	# FOR SOME REASON CLIENTS ARE GETTING MULTIPLE spawn_player RPCS
	# FIX THIS LATER PLEASE
	
	if (get_parent().find_node(str(id), true, false)):
		return
	var player_scene
	if global.interface and global.interface.initialize():
		player_scene = load("res://scenes/objects/VR-Player/VR-Player.tscn")
	else:
		player_scene = load("res://scenes/objects/player.tscn")
	var player			= player_scene.instance()
	
	player.set_name(str(id))
	player.player_id	= id
	player.player_name	= name
	if id == get_tree().get_network_unique_id():
		player.set_network_master(id)
		player.control		= true
		global.player		= player
	get_parent().add_child(player)
	if (name):
		print(name + " joined!")