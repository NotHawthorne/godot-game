extends Node

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.

var blue_flag_pad_pos = Vector3(166.141, 39.841, -50.969)
var red_flag_pad_pos = Vector3(-12.349, 64.864, 186.285)

var blue_flag_visible = true
var red_flag_visible = true

var blue_flag_pos = Vector3(166.141, 39.841, -50.969)
var red_flag_pos = Vector3(-12.349, 64.864, 186.285)

func _ready():
	pass # Replace with function body.

remote func change_player_team(pid, team) :
	var pnode = get_parent().find_node(str(pid))
	if !pnode or pnode.team == team:
		return
	if global.player_id == 1 :
		if pnode.has_flag_dict["red"] or pnode.has_flag_dict["blue"] :
			global.player.reset_flag(pid, pnode.has_flag_dict)
				#if has_flag_dict["red"] or has_flag_dict["blue"] :
				#	print("dropping flag")
				#	drop_flag(player_id, has_flag_dict, self.get_global_transform())
		get_parent().find_node("mode_manager").add_stat(pid, 0, 1, 0)
		get_parent().find_node("mode_manager").remove_player(pid)
		if pnode.team == "red" :
			pnode.team = "blue"
		if pnode.team == "blue" :
			pnode.team = "red"
		get_parent().find_node("mode_manager").add_player(pid)
		global.player.choose_spawn(pid)
		global.player.sync_health(pid, 100)
		print("tried to switch")
		return
	if pnode.team == "red" :
		pnode.team = "blue"
	if pnode.team == "blue" :
		pnode.team = "red"

func run_command(pid, message, chat_node) :
	var for_everyone = false
	var pnode = get_parent().get_node(str(pid))
	if "/help" in message :
		message = "godot-game made by alkozma and calamber\n/help  - prints this text"
	elif "/change team blue" in message :
		message = get_parent().get_node(str(pid)).player_name + " joined team blue (feature unavailable)"
		for_everyone = true
		change_player_team(pid, "blue")
		rpc_unreliable("change_player_team", pid, "blue")
	elif "/change team red" in message :
		message = get_parent().get_node(str(pid)).player_name + " joined team red"
		for_everyone = true
		change_player_team(pid, "red")
		rpc_unreliable("change_player_team", pid, "red")
	else :
		message = "invalid command!"
	if pid == 1 or for_everyone :
		chat_node.add_text(message)
		chat_node.newline()
	if pid != 1 and !for_everyone :
		rpc_id(pid, "rpc_message", message)
	elif for_everyone :
		rpc_unreliable("rpc_message", message)

remote func		move_flags(red_spawned, red_picked_up, red_loc, blue_spawned, blue_picked_up, blue_loc) :
	var red_flag_pad = get_parent().get_node("Red_Flag_Pad")
	var blue_flag_pad = get_parent().get_node("Blue_Flag_Pad")
	red_flag_pad.pop_flag()
	blue_flag_pad.pop_flag()
	if (red_spawned) :
		red_flag_pad.drop_flag(red_loc)
	if (blue_spawned) :
		blue_flag_pad.drop_flag(blue_loc)
	red_flag_pad.picked_up = red_picked_up
	blue_flag_pad.picked_up = blue_picked_up

remote func		spawn_flags() :
	print("spawning flag")
	var flag_pad_scene = load("res://scenes/objects/Objects/Flags/Flag_Pad.tscn")
	var	red_flag = flag_pad_scene.instance()
	var blue_flag = flag_pad_scene.instance()
	blue_flag.my_team = "blue"
	blue_flag.enemy_team = "red"
	blue_flag.set_name("Blue_Flag_Pad")
	red_flag.my_team = "red"
	red_flag.enemy_team = "blue"
	red_flag.set_name("Red_Flag_Pad")
	get_parent().add_child(red_flag)
	get_parent().add_child(blue_flag)
	red_flag.global_translate(red_flag_pad_pos)
	blue_flag.global_translate(blue_flag_pad_pos)
	red_flag.flag_pos = red_flag.get_global_transform()
	blue_flag.flag_pos = blue_flag.get_global_transform()