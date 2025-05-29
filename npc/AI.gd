extends CharacterBody3D

@export var roam_radius: float = 2.0
@export var speed: float = 4.0
@export var wait_time: float = 2.0

const STOP_DISTANCE = 0.1
var GRAVITY = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var nav_agent: NavigationAgent3D = $NavAgent
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var anim_state = "Idle"
@onready var anim_playback: AnimationNodeStateMachinePlayback = anim_tree.get("parameters/playback")

var is_waiting: bool = false
var roam_center: Vector3

func _ready():
	randomize()
	anim_tree.active = true
	anim_playback.travel("Idle")
	roam_center = global_transform.origin
	roam_to_random_point()

func _physics_process(delta):
	if nav_agent == null:
		return

	apply_gravity(delta)

	if is_waiting:
		stop_movement()
		set_anim("Idle")
		return

	if nav_agent.is_navigation_finished():
		wait_then_roam()
		return

	move_to_target()

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0

func stop_movement():
	velocity.x = 0
	velocity.z = 0
	move_and_slide()

func move_to_target():
	var next_pos = nav_agent.get_next_path_position()
	var flat_target = Vector3(next_pos.x, global_transform.origin.y, next_pos.z)
	var direction = (flat_target - global_transform.origin)
	var distance = direction.length()

	if distance < STOP_DISTANCE:
		stop_movement()
		set_anim("Idle")
		return

	direction = direction.normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	look_at(flat_target, Vector3.UP)
	move_and_slide()

	if Vector2(velocity.x, velocity.z).length() > 0.1:
		set_anim("Walk")
	else:
		set_anim("Idle")

func wait_then_roam() -> void:
	if is_waiting:
		return
	is_waiting = true
	stop_movement()
	set_anim("Idle")
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

func set_anim(name: String):
	if anim_state != name:
		anim_state = name
		anim_playback.travel(name)
