extends Viewport

export var target_fps = 30

func set_viewport_texture(p_texture):
	$"VR-Preview".texture = p_texture

# Called when the node enters the scene tree for the first time.
func _ready():
	_on_resize()
	get_tree().get_root().connect("size_changed", self, "_on_resize")

func _on_resize():
	size = OS.get_window_size()
