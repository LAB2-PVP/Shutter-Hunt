extends CharacterBody3D

@onready var agent = $NavAgent
var SPEED = 2.0
var targ: Vector3

var rng = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	targ = Vector3(randf_range(-30,30), 0, randf_range(-30,30))
	updateTargetLocation(targ)
	

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	look_at(targ)
	rotation.x = 0
	rotation.z = 0
	
	if position.distance_to(targ) > 0.5:
		var curLoc = global_transform.origin
		var nextLoc = agent.get_next_path_position()
		var newVel = (nextLoc - curLoc).normalized() * SPEED
		targ.y = position.y
		velocity = newVel
		move_and_slide()
	else:
		rng.randomize()
		targ = Vector3(randf_range(-30,30), 0, randf_range(-30,30))
		updateTargetLocation(targ)

func updateTargetLocation(target):
	agent.set_target_position(target)
