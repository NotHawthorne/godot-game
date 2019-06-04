extends Control

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export (NodePath) var button_path
onready var button = get_node(button_path)
# Called when the node enters the scene tree for the first time.
func _ready():
	button.connect("toggled", self, "on_toggled")
	 # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func on_toggled(pressed) :
	if (pressed) :
		global.vr_selected = true
	else :
		global.vr_selected = false