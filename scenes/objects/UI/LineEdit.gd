extends LineEdit

func _ready():
	pass
	#self.connect("text_entered", self, "_on_text_entered")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _input(event):
	if event is InputEventKey and event.pressed :
		if event.scancode == KEY_ENTER || event.scancode == KEY_ESCAPE:
			if event.scancode == KEY_ENTER and self.get_text() != "" :
				global.player.get_message(global.player_name + ": " + self.get_text())
			#get_node('ChatText').add_text()
			#get_node('ChatText').newline()
			self.clear()
			self.set_process_input(false)
			self.release_focus()
			global.player.control = true

#func _on_text_entered(text) :
#	self.release_focus()
#	global.player.get_message(global.player_name + ": " + text)
#	self.set_editable(false)
#	self.clear()
#	global.player.control = true
