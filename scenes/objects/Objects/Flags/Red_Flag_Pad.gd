extends Area
# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var capsule
var model = load("res://scenes/objects/Objects/Flags/Flag.tscn")
# Called when the node enters the scene tree for the first time.
func _ready():
	capsule = model.instance()
	self.add_child(capsule)
	capsule.connect("body_entered", self, "collided")

remote func reset_flag() :
	print("resetting flag on " + global.player_name + "'s client")
	if self.has_node("Flag") :
		return
	self.add_child(capsule)

remote func pop_flag() :
	get_parent().get_node("Red_Flag_Pad").remove_child(capsule)

func collided(body):
		if "has_flag" in body and body.team == "blue" :
			if global.player_id == 1 :
				global.player.pickup_flag(body.player_id, "red")
			else :
				global.player.rpc_id(1, "pickup_flag", body.player_id, "red")
		elif "has_flag" in body and body.has_flag == "red" and body.team == "red" :
			if global.player_id == 1 :
				global.player.reset_flag(body.player_id, "red")
			else :
				global.player.rpc_id(1, "reset_flag", body.player_id, "red")
		elif "has_flag" in body and body.has_flag == "blue" and body.team == "red" :
			if global.player_id == 1 :
				global.player.reset_flag(body.player_id, "blue")
				global.player.leaderboard_add_stat(body.player_id, 0, 0, 1)
			else :
				global.player.rpc_id(1, "reset_flag", body.player_id, "blue")
				global.player.rpc_id(1, "leaderboard_add_stat", body.player_id, 0, 0, 1)