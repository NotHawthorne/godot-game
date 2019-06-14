extends Area
# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var capsule
var model = load("res://scenes/objects/Objects/Flags/Red_Flag.tscn")
var picked_up = false
# Called when the node enters the scene tree for the first time.
func _ready():
	capsule = model.instance()
	self.add_child(capsule)
	capsule.connect("body_entered", self, "capsule_collided")
	self.connect("body_entered", self, "pad_collided")

remote func reset_flag() :
	print("resetting flag on " + global.player_name + "'s client")
	if self.has_node("Flag") :
		return
	picked_up = false
	self.add_child(capsule)
	self.get_node("Flag").set_global_transform(self.get_global_transform())

remote func pop_flag() :
	get_parent().get_node("Red_Flag_Pad").remove_child(capsule)

func capsule_collided(body):
	print("colliding with blue flag")
	if "has_flag" in body and body.team == "blue" :
		picked_up = true
		if global.player_id == 1 :
			global.player.pickup_flag(body.player_id, "red")
		else :
			global.player.rpc_id(1, "pickup_flag", body.player_id, "red")

remote func drop_flag(location) :
	self.add_child(capsule)
	self.get_node("Flag").set_global_transform(location)

func pad_collided(body) :
	if picked_up == false :
		if "has_flag" in body and body.has_flag == "blue" and body.team == "red" :
			if global.player_id == 1 :
				global.player.reset_flag(body.player_id, "blue")
				global.player.leaderboard_add_stat(body.player_id, 0, 0, 1)
			else :
				global.player.rpc_id(1, "reset_flag", body.player_id, "blue")
				global.player.rpc_id(1, "leaderboard_add_stat", body.player_id, 0, 0, 1)
	if picked_up == true :
		if "has_flag" in body and body.has_flag == "blue" and body.team == "blue" :
			if global.player_id == 1 :
				global.player.reset_flag(body.player_id, "blue")
			else :
				global.player.rpc_id(1, "reset_flag", body.player_id, "blue")