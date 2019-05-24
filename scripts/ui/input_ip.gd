extends LineEdit

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	var root = get_parent().get_parent()
	var http = root.get_node('HTTPRequest')
	http.request("http://35.236.33.159:3000/ips.json")
	global.server_selection = '35.236.33.159'

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	var json = JSON.parse(body.get_string_from_utf8())
	print(json.result)
	self.text = "35.236.33.159"