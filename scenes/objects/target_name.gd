extends Label

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if global.target != null:
		if global.target.get("player_name"):
			self.text = str(global.target.get("player_name"))
		else:
			self.text = ""
	else:
		self.text = ""