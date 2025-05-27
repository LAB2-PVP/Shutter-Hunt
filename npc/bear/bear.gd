extends CharacterBody3D

@export var roam_radius: float = 2.0
@export var speed: float = 4.0
@export var wait_time: float = 2.0

var GRAVITY = ProjectSettings.get_setting("physics/3d/default_gravity")
const STOP_DISTANCE = 0.1

@onready var nav_agent: NavigationAgent3D = $NavAgent
@onready var anim_tree: AnimationTree = $AnimationTree

var is_waiting: bool = false
var roam_center: Vector3

func _ready():
	randomize()
	roam_center = global_transform.origin
	roam_to_random_point()

func _physics_process(delta):
	if nav_agent == null:
		return

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0

	if is_waiting:
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		anim_tree.set("parameters/playback/current", "Idle")
		return

	if nav_agent.is_navigation_finished():
		wait_then_roam()
		return

	var next_pos = nav_agent.get_next_path_position()
	var horizontal_pos = Vector3(next_pos.x, global_transform.origin.y, next_pos.z)
	var to_target = horizontal_pos - global_transform.origin
	var distance = to_target.length()

	if distance < STOP_DISTANCE:
		velocity.x = 0
		velocity.z = 0
	else:
		var direction = to_target.normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed

		look_at(horizontal_pos, Vector3.UP)

	move_and_slide()

	if velocity.length() > 0.1:
		anim_tree.set("parameters/playback/current", "Walk")
	else:
		anim_tree.set("parameters/playback/current", "Idle")

func wait_then_roam() -> void:
	if is_waiting:
		return
	is_waiting = true
	velocity.x = 0
	velocity.z = 0
	move_and_slide()
	anim_tree.set("parameters/playback/current", "Idle")
	await get_tree().create_timer(wait_time).timeout
	roam_to_random_point()
	is_waiting = false

func roam_to_random_point():
	if nav_agent == null:
		push_warning("No NavigationAgent3D found; cannot roam.")
		return

	var angle = randf_range(0, TAU)
	var distance = randf_range(0, roam_radius)
	var offset = Vector3(cos(angle), 0, sin(angle)) * distance
	var target_pos = roam_center + offset

	var nav_map = nav_agent.get_navigation_map()
	var closest_point = NavigationServer3D.map_get_closest_point(nav_map, target_pos)

	nav_agent.set_target_position(closest_point)
	print("New roam target at: ", closest_point)
