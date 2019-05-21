extends TextEdit

var list_timer	= Timer.new()

func _ready():
	list_timer.set_wait_time(5)
	list_timer.connect("timeout", self, "_on_timeout")
	add_child(list_timer)
	list_timer.start()
	var http = get_node('../../ServersRequest')
	http.request("http://localhost:3000/servers.json")
	
func	_on_timeout():
	var http = get_node('../../ServersRequest')
	http.request("http://localhost:3000/servers.json")
	

func _on_ServersRequest_request_completed(result, response_code, headers, body):
	var json = JSON.parse(body.get_string_from_utf8())
	var ips = []
	print(json.result)
	for server in json.result:
		text = ""
		insert_text_at_cursor(str(server.ip, "\n"))