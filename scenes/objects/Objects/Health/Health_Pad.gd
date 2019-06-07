extends Area
# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var cooldown_time = 10
var health_to_add = 25
var capsule
var cooldown		= Timer.new()
var model = load("res://scenes/objects/Objects/Health/health_capsule.tscn")
# Called when the node enters the scene tree for the first time.
func _ready():
	capsule = model.instance()
	self.add_child(capsule)
	cooldown.set_one_shot(true)
	cooldown.set_wait_time(cooldown_time)
	cooldown.connect("timeout", self, "flip_cooldown")
	add_child(cooldown)
	capsule.connect("body_entered", self, "collided")

func flip_cooldown():
	print("capsule regen")
	self.add_child(capsule)
	capsule = model.instance()
	self.add_child(capsule)
	capsule.connect("body_entered", self, "collided")

func collided(body):
	if body and "health" in body :
		if body.health + health_to_add > body.max_health :
			body.health = body.max_health
		else :
			body.health += health_to_add
		remove_child(capsule)
		capsule = null
		cooldown.start()
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
# pnode.get_node('Head/gun_container').remove_child(to_remove)
