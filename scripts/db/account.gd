extends Node

var cmd                   = ""
var login                 = ""
var password              = ""
var password_confirmation = ""
var current_index         = 0

func _ready():
	pass

func _input(event):
	var root    = get_parent()
	var console = root.get_node('console')

	if Input.is_action_just_pressed("ui_accept"):
		console.insert_text_at_cursor("\n")
		
		cmd = cmd.replace('Enter', '')
		
		if current_index == 1:
			login = cmd
			print(login)
			console.insert_text_at_cursor('password: ')
		elif current_index == 2:
			password = cmd
			console.insert_text_at_cursor('password_confirmation: ')
		elif current_index == 3:
			password_confirmation = cmd
			
			var http = HTTPClient.new()
			var err = http.connect_to_host("35.236.33.159", 3000)
			assert(err == OK)

			while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
				http.poll()
				print("Connecting..")
				OS.delay_msec(500)
			print("Connected!")
			assert(http.get_status() == HTTPClient.STATUS_CONNECTED)
			var body = str("user[handle]=", login, "&user[password]=", password, "&user[password_confirmation]=", password_confirmation)
			
			http.request(
				HTTPClient.METHOD_POST, 
				'/users.json', 
				["Content-Type: application/x-www-form-urlencoded", "Content-Length: " + str(body.length())], 
				body
			)
			
		cmd = ""
		current_index += 1

	elif !event.is_pressed() and !event.is_class("InputEventMouseMotion"):
		cmd += event.as_text()


func login():
	get_tree().set_input_as_handled()
	var root    = get_parent()
	var console = root.get_node('console')
	
	console.insert_text_at_cursor('handle: ')