extends Spatial

var BULLET_SPEED = 70
var BULLET_DAMAGE = 15

const KILL_TIMER = 4
var timer = 0

var hit_something = false
var bullet_owner = ""

func _ready():
	$Area.connect("body_entered", self, "collided")
	print("FIRED")


func _physics_process(delta):
    var forward_dir = global_transform.basis.z.normalized()
    global_translate(-(forward_dir * BULLET_SPEED * delta))

    timer += delta
    if timer >= KILL_TIMER:
        queue_free()


func collided(body):
	var node = find_node_by_name(get_tree().get_root(), body.get_name())
	if hit_something == false:
		if "player_id" in node and body.get_name() != str(bullet_owner):
			print("HIT")
			print(body.get_name())
			print(global.player_id)
			print(node.player_id)
			print(bullet_owner)
			rpc_id(1, "deal_damage", BULLET_DAMAGE, str(node.player_id), node.player_id)
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