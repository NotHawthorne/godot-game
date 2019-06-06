extends Spatial

var BULLET_SPEED = 50
var BULLET_DAMAGE = 15

const KILL_TIMER = 1
var timer = 0

var hit_something = false
var bullet_owner = ""

var forward_dir
var target
var val = 0

func _ready():
	$Area.connect("body_entered", self, "collided")
	forward_dir = global_transform.basis.z.normalized()


func _physics_process(delta):
	if (!target):
		global_translate(-(forward_dir * BULLET_SPEED * delta))
	else:
		set_global_transform(Transform(get_global_transform().basis, target))
		#print(str(-(forward_dir * BULLET_SPEED * delta)) + "|" + str(-(target * BULLET_SPEED * delta)))
		#get_translation().linear_interpolate(target.get_transform().origin, delta * BULLET_SPEED)
		#set_global_transform(Transform(target * (BULLET_SPEED * delta)))

	timer += delta
	if timer >= KILL_TIMER:
		queue_free()

func set_damage(amt):
	BULLET_DAMAGE = amt


func collided(body):
	if hit_something == false:
		if body.get_name() != str(bullet_owner):
			var node = get_tree().get_root().find_node(body.get_name(), true, false)
			print("AX | " + body.get_name())
			if (node.has_method("_deal_damage")):
				node._deal_damage(body.get_name(), BULLET_DAMAGE)
			queue_free()

func find_node_by_name(root, name):
    if(root.get_name() == name): return root

    for child in root.get_children():
        if(child.get_name() == name):
            return child

        var found = find_node_by_name(child, name)

        if(found): return found

    return null