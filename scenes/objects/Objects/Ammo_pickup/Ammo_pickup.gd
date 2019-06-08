extends Area
# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var cooldown_time = 10
var ammo_to_add = 25
var capsule
var cooldown		= Timer.new()
var model = load("res://scenes/objects/Objects/Ammo_pickup/Ammo_Capsule.tscn")
# Called when the node enters the scene tree for the first time.
func _ready():
	cooldown.set_one_shot(true)
	cooldown.set_wait_time(cooldown_time)
	cooldown.connect("timeout", self, "flip_cooldown")
	add_child(cooldown)
	capsule = model.instance()
	self.add_child(capsule)
	capsule.connect("body_entered", self, "collided")

func flip_cooldown():
	self.add_child(capsule)

remote func pop_capsule(id) :
	get_parent().get_node(id).remove_child(capsule)
	get_parent().get_node(id).cooldown.start()

func collided(body):
	if body and "ammo" in body :
		if body.ammo + ammo_to_add > body.max_ammo :
			body.ammo = body.max_ammo
		else :
			body.ammo += ammo_to_add
		pop_capsule(self.get_name())
		rpc_unreliable("pop_capsule", self.get_name())
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
# pnode.get_node('Head/gun_container').remove_child(to_remove)
