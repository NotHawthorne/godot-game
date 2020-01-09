extends Control

export (NodePath) var dropdown_path
onready var dropdown = get_node(dropdown_path)

func _ready():
	dropdown.add_item("level1")
	dropdown.add_separator()
	dropdown.add_item("level2")
	global.lobby_map_selection = "res://scenes/levels/default_level.tscn"
	dropdown.connect("item_selected", self, "on_item_selected")

func on_item_selected(id):
	print("selecting item ")
	if str(dropdown.get_item_text(id)) == "block fortress" :
		global.lobby_map_selection = "res://scenes/levels/default_level.tscn"
	elif str(dropdown.get_item_text(id)) == "space station" :
		global.lobby_map_selection = "res://scenes/levels/space_station.tscn"