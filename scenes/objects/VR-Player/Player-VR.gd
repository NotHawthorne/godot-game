extends Spatial

var interface = null

# Called when the node enters the scene tree for the first time.
func _ready():
	interface = ARVRServer.find_interface("OpenVR")
	if interface and interface.initialize():
		# Make sure Godot knows the size of our viewport, else this is only known inside of the render driver
		
		global.interface = interface
