extends PanelContainer

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.scancode == KEY_ENTER || event.scancode == KEY_ESCAPE:
			if event.scancode == KEY_ENTER :
				get_parent().get_parent().get_parent().get_message(get_parent().get_parent().get_parent().player_name + ": " + get_node('Control/LineEdit').get_text())
			#get_node('ChatText').add_text()
			#get_node('ChatText').newline()
			get_node('Control/LineEdit').clear()
			get_node('Control/LineEdit').release_focus()
			get_parent().get_parent().get_parent().control = true