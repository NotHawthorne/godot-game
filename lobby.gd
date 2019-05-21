extends Spatial

func _ready():
	pass

func _on_Button_pressed():
	var lineedit = get_node('PanelContainer/Panel/LineEdit')
	var uname_field = get_node('PanelContainer/Panel/Username')
	var pwd_field = get_node('PanelContainer/Panel/Password')
	var status_field = get_node('PanelContainer/Panel/Status')
	
	var uname = uname_field.text
	var pwd = pwd_field.text
	var ip = lineedit.text

	var http = HTTPClient.new()
	var err = http.connect_to_host("localhost", 3000)
	assert(err == OK)

	while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
		http.poll()
		print("Connecting..")
		OS.delay_msec(500)
	print("Connected!")
	assert(http.get_status() == HTTPClient.STATUS_CONNECTED)
	
#			var body = http.query_string_from_dict({
#				'user': {
#					'handle': login, 
#					'password': password, 
#					'password_confirmation': password_confirmation
#				}
#			})
	var body = str("user[handle]=", uname, "&user[password]=", pwd, "&user[password_confirmation]=", pwd)
	
	err = http.request(
		HTTPClient.METHOD_POST, 
		'/users.json', 
		["Content-Type: application/x-www-form-urlencoded", "Content-Length: " + str(body.length())], 
		body
	)
	assert (err == OK)
	http = HTTPClient.new()
	err = http.connect_to_host("localhost", 3000)
	assert(err == OK)
	while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
		http.poll()
		print("Connecting..")
		OS.delay_msec(500)
	print("Connected!")
	assert(http.get_status() == HTTPClient.STATUS_CONNECTED)
	body = str("server[ip]=", ip)
	
	http.request(
		HTTPClient.METHOD_POST, 
		'/servers.json', 
		["Content-Type: application/x-www-form-urlencoded", "Content-Length: " + str(body.length())], 
		body
	)
	print("GOING")


func _on_boi_request_completed(result, response_code, headers, body):
	var json = JSON.parse(body.get_string_from_utf8())
	print(json.result)
	get_tree().change_scene("res://default_level.tscn")
