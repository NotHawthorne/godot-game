extends Spatial

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
var id
var walk_timer = Timer.new()
var walk_cycle = 1
var play_walk_sound = false

func _ready():
	walk_timer.wait_time = 0.3
	self.add_child(walk_timer)
	walk_timer.connect("timeout", self, "switch_walk_sound")

func play_sound(sound) :
	if sound == "shoot" :
		$shoot.play()

func start_sound(sound) :
	if sound == "walk" and play_walk_sound == false :
		play_walk_sound = true
		$walk_step1.play()
		walk_timer.start()

func switch_walk_sound() :
	if play_walk_sound :
		if walk_cycle == 1 :
			$walk_step2.play()
			walk_cycle = 2
			walk_timer.start()
		elif walk_cycle == 2 :
			$walk_step1.play()
			walk_cycle = 1
			walk_timer.start()

func stop_sound(sound) :
	if sound == "walk" :
		$walk_step2.stop()
		$walk_step1.stop()
		play_walk_sound = false
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
