extends CharacterBody3D


@export var speed_walking = 7.0
@export var speed_sprint = 14.0
@export_range(5, 10, 0.1) var crouch_speed: float = 7.0
@export var accel : float = 0.1
@export var deccel : float = 0.25
@export var jump = 4.5
@export var crouch_height = 1.0
@export var crouch_transition = 8.0
@export var sensitivity = 0.5
@export var min_angle := deg_to_rad(-90.0)
@export var max_angle := deg_to_rad(90.0)
@export var CAMERA_CONTROLLER : Camera3D
@export var inv: Inv

var _speed : float
var _mouse_input : bool = false
var _mouse_rotation : Vector3
var _rotation_input : float
var _tilt_input : float
var _player_rotation : Vector3
var _camera_rotation : Vector3

@onready var head = $head
@onready var collision_shape = $CollisionShape3D
@onready var top_cast = $TopCast
@onready var interact_ray = $head/InteractRay



var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var look_rot : Vector2
var stand_height : float

func _update_camera(delta):
	_mouse_rotation.x += _tilt_input * delta
	_mouse_rotation.x = clamp(_mouse_rotation.x, min_angle, max_angle)
	_mouse_rotation.y += _rotation_input * delta
	
	_player_rotation = Vector3(0.0, _mouse_rotation.y, 0.0)
	_camera_rotation = Vector3(_mouse_rotation.x, 0.0, 0.0)
	
	CAMERA_CONTROLLER.transform.basis = Basis.from_euler(_camera_rotation)
	CAMERA_CONTROLLER.rotation.z = 0.0
	
	interact_ray.rotation = CAMERA_CONTROLLER.rotation
	
	_rotation_input = 0.0
	_tilt_input = 0.0
	
	global_transform.basis = Basis.from_euler(_player_rotation)
	
func _ready() -> void:
	
	GlobalScene.player = self
	
	stand_height = collision_shape.shape.height
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	_speed == speed_walking
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump
		elif Input.is_action_pressed("crouch"):
			_speed = crouch_speed
			crouch(delta)
		else:
			crouch(delta, true)
			
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump

	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = lerp(velocity.x, direction.x * _speed, accel)
		velocity.z = lerp(velocity.z, direction.z * _speed, accel)
	else:
		velocity.x = move_toward(velocity.x, 0.0, deccel)
		velocity.z = move_toward(velocity.z, 0.0, deccel)

	move_and_slide()
	
	_update_camera(delta)

func _input(event):
	_mouse_input = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if _mouse_input:
		_rotation_input = -event.relative.x
		_tilt_input = -event.relative.y
	
func crouch(delta : float, reverse = false):
	var target_height : float = crouch_height if not reverse else stand_height
	
	collision_shape.shape.height = target_height
	collision_shape.position.y = target_height * 0.5
	head.position.y = lerp(head.position.y, target_height - 1, crouch_transition * delta)
	
func set_movement_speed(state: String):
	match state:
		"default":
			_speed = speed_walking
		"crouch":
			_speed = crouch_speed
