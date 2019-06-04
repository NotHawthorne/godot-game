extends Spatial

func _ready():
	if OS.has_feature("Server"):
		get_tree().change_scene(global.map)

func _on_Button_pressed():
	var lineedit = get_node('PanelContainer/Panel/LineEdit')
	var uname_field = get_node('PanelContainer/Panel/Username')
	var pwd_field = get_node('PanelContainer/Panel/Password')
	var status_field = get_node('PanelContainer/Panel/Status')
	
	var uname = uname_field.text
	var pwd = pwd_field.text
	var ip = lineedit.text

	var http = HTTPClient.new()
	var err = http.connect_to_host("35.236.33.159", 3000)
	assert(err == OK)

	while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
		http.poll()
		print("Connecting..")
		OS.delay_msec(500)
	print("Connected!")
	assert(http.get_status() == HTTPClient.STATUS_CONNECTED)
	var body = str("user[handle]=", uname, "&user[password]=", pwd, "&user[password_confirmation]=", pwd)
	
	http.request(
		http.METHOD_POST, 
		'/users.json', 
		["Content-Type: application/x-www-form-urlencoded", "Content-Length: " + str(body.length())], 
			body
	)
	while http.get_status() != HTTPClient.STATUS_BODY and http.get_status() != HTTPClient.STATUS_CONNECTED:
		http.poll()
		print("Sending login request...")
		OS.delay_msec(500)
	if (http.has_response()):
			var headers = http.get_response_headers_as_dictionary() # Get response headers.
			print("code: ", http.get_response_code()) # Show response code.
			print("**headers:\\n", headers) # Show headers.
			
			# Getting the HTTP Body
			
			if http.is_response_chunked():
			# Does it use chunks?
				print("Response is Chunked!")
			else:
				# Or just plain Content-Length
				var bl = http.get_response_body_length()
				print("Response Length: ",bl)
			
				# This method works for both anyway
			
			var rb = PoolByteArray() # Array that will hold the data.
			
			while http.get_status() == HTTPClient.STATUS_BODY:
			# While there is body left to be read
				http.poll()
				var chunk = http.read_response_body_chunk() # Get a chunk.
				if chunk.size() == 0:
					# Got nothing, wait for buffers to fill a bit.
					OS.delay_usec(1000)
				else:
			    	rb = rb + chunk # Append to read buffer.
			
			# Done!
			
			print("bytes got: ", rb.size())
			var text = JSON.parse(rb.get_string_from_ascii())
			if text.result and text.result.has("status"):
				get_node('PanelContainer/Panel/Status').text = "Error logging in!"
				return
	print(err)
	assert (err == OK)
	http = HTTPClient.new()
	err = http.connect_to_host("35.236.33.159", 3000)
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
	#for player in global.admins :
	#	if (player == uname):
	#		global.define_level($PanelContainer/Panel/Control.selection)
	get_tree().change_scene(global.map)


func _on_boi_request_completed(result, response_code, headers, body):
	var json = JSON.parse(body.get_string_from_utf8())
	print(json.result)
	get_tree().change_scene("res://scenes/levels/default_level.tscn")


func _on_LineEdit_text_changed(new_text):
	global.server_selection = new_text


func _on_Username_text_changed(new_text):
	global.player_name = new_text
