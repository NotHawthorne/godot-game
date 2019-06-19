extends Area
# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var capsule
var model
var picked_up = false
var my_team
var enemy_team
# Called when the node enters the scene tree for the first time.
func _ready():
	if my_team == "red" :
		model = load("res://scenes/objects/Objects/Flags/Red_Flag.tscn")
	else :
		model = load("res://scenes/objects/Objects/Flags/Blue_Flag.tscn")
	capsule = model.instance()
	self.add_child(capsule)
	capsule.connect("body_entered", self, "capsule_collided")
	self.connect("body_entered", self, "pad_collided")

remote func reset_flag() :
	print("trying to reset flag on " + global.player_name + "'s client")
	picked_up = false
	self.add_child(capsule)
	self.get_node("Flag").set_global_transform(self.get_global_transform())

remote func pop_flag() :
	print("flag picked up")
	if my_team == "red" :
		get_parent().get_node("Red_Flag_Pad").remove_child(capsule)
	else :
		get_parent().get_node("Blue_Flag_Pad").remove_child(capsule)

func capsule_collided(body):
	print("colliding with flag: " + my_team)
	if "player_name" in body and body.team == enemy_team and body.health > 0:
		print("trying to pick up flag")
		picked_up = true
		if global.player_id == 1 :
			global.player.pickup_flag(body.player_id, my_team)
		else :
			global.player.rpc_id(1, "pickup_flag", body.player_id, my_team)
	if picked_up == true and "player_name" in body and body.team == my_team :
		if global.player_id == 1 :
			global.player.pickup_flag(body.player_id, my_team)
		else :
			global.player.rpc_id(1, "pickup_flag", body.player_id, my_team)

remote func drop_flag(location) :
	self.add_child(capsule)
	self.get_node("Flag").set_global_transform(location)

func pad_collided(body) :
	print("flag pad collided")
	if picked_up == false :
		if "player_name" in body and body.has_flag_dict[enemy_team] and body.team == my_team :
			print("brought enemy flag to pad")
			if global.player_id == 1 :
				global.player.reset_flag(body.player_id, {enemy_team:true, my_team:false})
				global.player.leaderboard_add_stat(body.player_id, 0, 0, 1)
			else :
				global.player.rpc_id(1, "reset_flag", body.player_id, {enemy_team:true, my_team:false})
				global.player.rpc_id(1, "leaderboard_add_stat", body.player_id, 0, 0, 1)
	if picked_up == true :
		if "player_name" in body and body.has_flag_dict[my_team] and body.team == my_team :
			print("flag returned")
			if global.player_id == 1 :
				global.player.reset_flag(body.player_id, {enemy_team:false, my_team:true})
			else :
				global.player.rpc_id(1, "reset_flag", body.player_id, {enemy_team:false, my_team:true})
