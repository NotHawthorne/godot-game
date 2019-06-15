extends Node

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

remote func		spawn_flags() :
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
	red_flag.global_translate(Vector3(-12.349, 64.864, 186.285))
	blue_flag.global_translate(Vector3(166.141, 39.841, -50.969))