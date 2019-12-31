extends Control

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
#export (NodePath) var button_path
#onready var button = get_node("Button")
#var pressed = false
# Called when the node enters the scene tree for the first time.
func _ready():
	pass
#button.connect("toggled", self, "on_Button_pressed")
	 # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
#func on_toggled(pressed) :
#	if (pressed) :
#		global.vr_selected = true
#		print("vr selected")
#	else :
#		global.vr_selected = false

func _on_checkbox_toggled(button_pressed):
	if (button_pressed) :
		global.vr_selected = true
		print("vr selected")
	else :
		global.vr_selected = false
		print("vr deselected")
