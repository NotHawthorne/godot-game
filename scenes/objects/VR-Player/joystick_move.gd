extends Node

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var player = global.player
# Called when the node enters the scene tree for the first time.
func _ready():
	#player = global.player
	pass # Replace with function body.

func _physics_process(delta):
	# We should be the child or the controller on which the teleport is implemented
	var controller = get_parent()
	if controller.get_is_active():
		var left_right = controller.get_joystick_axis(0)
		var forwards_backwards = controller.get_joystick_axis(1)
		if ((abs(forwards_backwards) > 0.1 or abs(left_right) > 0.1) and player.control == true) :
			var aim	= player.get_node("Head/Viewport-VR/ARVROrigin/ARVRCamera").get_global_transform().basis
			var JumpCast = player.get_node("JumpCast")

			player.direction = Vector3()
			if JumpCast.is_colliding() :
				if forwards_backwards > 0.1 :
					player.direction += aim.z
					#if (anim != "rifle_jump2"):
					player.anim = "rifle_run_forward"

				if  forwards_backwards < -0.1 :
					player.direction -= aim.z
					player.anim = "rifle_run_forward"
				if left_right < -0.1 :
					player.direction -= aim.x
					player.anim = "rifle_run_forward"
				if left_right > 0.1:
					player.direction += aim.x
					player.anim = "rifle_run_forward"
				if player.time_off_ground == 0 :
					player.play_sound("player", player.player_name, "start", "walk")
			else :
				player.play_sound("player", player.player_name, "stop", "walk")
			if (Input.is_action_just_pressed("jump")):
				var dashing = false
				if (player.jumps <= 1):
					player.play_sound("player", player.player_name, "stop", "walk")
					if player.jumps == 0 :
						player.play_sound("player", player.player_name, "play", "jump")
					#f (anim == "rifle_jump2"):
						#xbot/AnimationPlayer.stop(true)
						player.anim = "rifle_jump2"
					if player.get_node("Head/Camera/WallCast1.is_colliding()") or player.get_node("Head/Camera/WallCast2.is_colliding()") or player.get_node("Head/Camera/WallCast3.is_colliding()") or player.get_node("Head/Camera/WallCast4.is_colliding()") :
						print("colliding")
						dashing = true
						player.velocity.y += (player.JUMP_SPEED * delta) / 1.9
						player.velocity -= -aim.z * (player.DASH_SPEED)
					if player.get_node("Head/Camera/WallCast1.is_colliding()") and left_right < -0.1:
						player.jumps = 0
						player.velocity -= aim.x * (player.DASH_SPEED * 1.2)
					if player.get_node("Head/Camera/WallCast2.is_colliding()") and forwards_backwards < -0.1:
						player.jumps = 0
						player.velocity += -aim.z * (player.DASH_SPEED * 1.2)
					if player.get_node("Head/Camera/WallCast3.is_colliding()") and left_right > 0.1:
						player.jumps = 0
						player.velocity += aim.x * (player.DASH_SPEED * 1.2)
					if player.get_node("Head/Camera/WallCast4.is_colliding()") and forwards_backwards > 0.1:
						player.jumps = 0
						player.velocity -= -aim.z * (player.DASH_SPEED * 1.2)
				if JumpCast.is_colliding():
					player.jumps = 0
					#print("colliding")
				if player.jumps < 2:
					#print("jumping...")
					player.direction.y = 1 + (player.direction.y * delta)
					player.velocity.y += player.JUMP_SPEED * delta
					player.jumps += 1
					player.time_off_ground = 0
				if player.jumps == 2:
					if (forwards_backwards > 0.1):
						player.play_sound("player", player.player_name, "play", "dash")
						player.velocity -= -aim.z * player.DASH_SPEED
						dashing = true
					if (forwards_backwards < -0.1):
						player.play_sound("player", player.player_name, "play", "dash")
						player.velocity += -aim.z * player.DASH_SPEED
						dashing = true
					if (left_right < -0.1):
						player.play_sound("player", player.player_name, "play", "dash")
						player.velocity -= aim.x * player.DASH_SPEED
						dashing = true
					if (left_right > 0.1):
						player.play_sound("player", player.player_name, "play", "dash")
						player.velocity += aim.x * player.DASH_SPEED
						dashing = true
					if dashing == true:
						player.velocity.y -= (player.JUMP_SPEED * delta) / 2
						player.jumps += 1
				#direction.y = 0
				player.time_off_ground += (delta * 2)
				player.velocity.y -= player.GRAVITY * player.time_off_ground
				player.direction = player.direction.normalized()
				var target = player.direction * player.RUN_SPEED
				var accel
				if (player.RUN_ACCEL * delta > player.RUN_SPEED):
					accel = player.RUN_SPEED
				else:
					accel = player.RUN_ACCEL * delta
				player.velocity = player.velocity.linear_interpolate(target, accel)
				var rot_x = -(player.get_node("Head/Viewport-VR/ARVROrigin/ARVRCamera").get_rotation_degrees().x)
				var rot_y = 180 + (player.get_node("Head/Viewport-VR/ARVROrigin/ARVRCamera").get_rotation_degrees().y)
				player.get_node("Head").set_rotation_degrees(Vector3(0, rot_y, 0))
				player.get_node("xbot").set_rotation_degrees(Vector3(0, rot_y, 0))