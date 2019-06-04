extends RichTextLabel

var list_timer	= Timer.new()

func _ready():
	self.add_text("looking for servers...")
	self.set_scroll_follow(true)
	list_timer.set_wait_time(5)
	list_timer.connect("timeout", self, "_on_timeout")
	add_child(list_timer)
	list_timer.start()
	var http = get_node('../../../ServersRequest')
	http.request("http://35.236.33.159:3000/servers.json")
	
func	_on_timeout():
	self.newline()
	self.newline()
	self.add_text("looking for servers...")
	var http = get_node('../../../ServersRequest')
	http.request("http://35.236.33.159:3000/servers.json")

func _on_ServersRequest_request_completed(result, response_code, headers, body):
	#cursor_set_line(get_line_count() + 1, false, true, 10)
	#insert_text_at_cursor("35.236.33.159")
	self.newline()
	self.newline()
	self.add_text("35.236.33.159")