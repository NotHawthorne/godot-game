extends Spatial

var BULLET_SPEED = 70
var BULLET_DAMAGE = 15

const KILL_TIMER = 4
var timer = 0

var hit_something = false
var bullet_owner = ""

var forward_dir

func _ready():
	$Area.connect("body_entered", self, "collided")
	forward_dir = global_transform.basis.z.normalized()


func _physics_process(delta):
    global_translate(-(forward_dir * BULLET_SPEED * delta))

    timer += delta
    if timer >= KILL_TIMER:
        queue_free()


func collided(body):
	if hit_something == false:
		if body.get_name() != str(bullet_owner):
			var node = get_tree().get_root().find_node(body.get_name(), true, false)
			print("AX | " + body.get_name())
			print("HIT " + node.player_name)
			#rpc_unreliable("deal_damage", BULLET_DAMAGE, str(node.player_id), node.player_id)
			hit_something = true
			queue_free()

func find_node_by_name(root, name):
    if(root.get_name() == name): return root

    for child in root.get_children():
        if(child.get_name() == name):
            return child

        var found = find_node_by_name(child, name)

        if(found): return found

    return null