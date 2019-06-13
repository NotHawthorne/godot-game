extends Node

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

remote func		spawn_flags() :
	var red_flag_scene = load("res://scenes/objects/Objects/Flags/Red_Flag_Pad.tscn")
	var blue_flag_scene = load("res://scenes/objects/Objects/Flags/Blue_Flag_Pad.tscn")
	var	red_flag = red_flag_scene.instance()
	var blue_flag = blue_flag_scene.instance()
	get_parent().add_child(red_flag)
	get_parent().add_child(blue_flag)
	red_flag.global_translate(Vector3(-12.349, 64.864, 186.285))
	blue_flag.global_translate(Vector3(-3.395, 49.982, -57.952))