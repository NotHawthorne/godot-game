extends Control

func _ready():
	$dropdown.add_item("no team")
	$dropdown.add_separator()
	$dropdown.add_item("red team")
	$dropdown.add_item("blue team")
	$dropdown.connect("item_selected", self, "on_item_selected")

func on_item_selected(id):
	
	if str($dropdown.get_item_text(id)) == "red team" :
		global.my_team = "red"
	elif str($dropdown.get_item_text(id)) == "blue team" :
		global.my_team = "blue"
	global.teams = true
	print("selecting item: " + global.my_team)