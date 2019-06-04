extends Spatial

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var	cursor_shown	= false;

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$network.start_server()

func _process(delta):
	#if (Input.is_action_just_pressed("ui_cancel")):
	#	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	#	get_tree().quit()
	if (Input.is_action_just_pressed("show_cursor")):
		if (!global.ui_mode):
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		global.ui_mode = !global.ui_mode
	#if (Input.is_action_just_pressed("restart")):
	#	get_tree().reload_current_scene()
