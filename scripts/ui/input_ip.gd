extends LineEdit

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	#var root = get_parent().get_parent()
	#var http = root.get_node('HTTPRequest')
	#http.request("http://35.236.33.159:3000/ips.json")
	connect("focus_entered", self, "_show_keyboard")
	global.server_selection = '0.0.0.0'

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _show_keyboard() :
	if OS.has_virtual_keyboard() :
		OS.show_virtual_keyboard(self.Text)

func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	var json = JSON.parse(body.get_string_from_utf8())
	print(json.result)
	self.text = "0.0.0.0"