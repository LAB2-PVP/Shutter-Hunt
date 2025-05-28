extends CharacterBody3D

@export var speed_default : float = 7.0
@export var speed_sprint : float = 14.0
@export var crouch_speed: float = 7.0
@export var accel : float = 0.1
@export var deccel : float = 0.5
@export var jump = 4.5
@export var crouch_height = 1.0
@export var crouch_transition = 8.0
@export var sensitivity = 0.5
@export var min_angle := deg_to_rad(-90.0)
@export var max_angle := deg_to_rad(90.0)
@export var CAMERA_CONTROLLER : Camera3D
@export var inv: Inv
@export var hasCamera: bool = false

var _speed : float
var _mouse_input : bool = false
var _mouse_rotation : Vector3
var _rotation_input : float
var _tilt_input : float
var _player_rotation : Vector3
var _camera_rotation : Vector3

@onready var heldCamera = preload("res://interaction/camera_hd.tscn")
@onready var head = $head
@onready var collision_shape = $CollisionShape3D
@onready var top_cast = $TopCast
@onready var interact_ray = $head/InteractRay
@onready var crosshair = $UI/TextureRect
@onready var crosshairscene = $UI/CanvasLayer/TakePhoto

var held_camera_instance = null

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var look_rot : Vector2
var stand_height : float

# Zoom variables
var zoom_speed: float = 5.0
var min_fov: float = 11.42   # Corresponds to ~120mm
var max_fov: float = 90.0    # Corresponds to ~24mm
var default_fov: float = 37.86  # Corresponds to ~35mm (photo mode default)
var non_photo_fov: float = 70.0  # Default FOV for non-photo mode (wider view)
var sensor_height: float = 24.0  # Full-frame sensor height

# ISO variables
var iso: float = 1000.0  # Default ISO set to 1000 as requested
var iso_step: float = 50.0  # Step size for ISO adjustment
var min_iso: float = 100.0  # Minimum ISO (maps to exposure 0.5)
var max_iso: float = 1600.0  # Maximum ISO (maps to exposure 2.5)

# Store the original environment for non-photo mode
var original_environment: Environment = null

# Signal to notify TakePhoto script of ISO changes
signal iso_updated(new_iso)

# Convert ISO to exposure for camera adjustments
func iso_to_exposure(iso_value: float) -> float:
	return (iso_value - 100.0) / 750.0 + 0.5

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
	# Connect to the InteractRay signal
	interact_ray.connect("camera_updated", _on_camera_updated)
	_speed = speed_default
	
	# Set the default FOV for non-photo mode and store the original environment
	if CAMERA_CONTROLLER:
		CAMERA_CONTROLLER.current = true
		CAMERA_CONTROLLER.fov = non_photo_fov  # Use non-photo FOV at start
		# Store the original environment (could be null if none exists)
		original_environment = CAMERA_CONTROLLER.environment
		if original_environment and original_environment.adjustment_enabled:
			print("Environment exposure (adjustment_brightness): ", original_environment.adjustment_brightness)
		# ISO is set to 1000 as requested
		print("Default ISO set to: ", iso)
		# Update the focal length display initially
		var initial_focal_length = calculate_focal_length(CAMERA_CONTROLLER.fov)
		crosshairscene.update_focal_length(initial_focal_length)
	else:
		print("Error: CAMERA_CONTROLLER not set in the editor")
	
	# Ensure crosshairscene starts invisible
	if crosshairscene:
		crosshairscene.visible = false  # Force invisible at start
		print("Crosshairscene visibility at start: ", crosshairscene.is_visible_in_tree())  # Debug print
		crosshairscene.connect("visibility_changed", _on_crosshairscene_visibility_changed)

func _physics_process(delta: float) -> void:
	GlobalScene.debug.add_property("MovementSpeed", _speed, 2)
	GlobalScene.debug.add_property("hasCamera", hasCamera, 2)
	
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
	
	# Handle zoom and ISO when in photo mode
	if crosshairscene.is_visible_in_tree():
		if Input.is_action_pressed("zoom_in"):
			print("Zoom in key pressed")
			zoom_camera(-zoom_speed * delta)
		if Input.is_action_pressed("zoom_out"):
			print("Zoom out key pressed")
			zoom_camera(zoom_speed * delta)
		# Add ISO controls only in photo mode
		if Input.is_action_just_pressed("increase_exposure"):
			adjust_iso(iso_step)
		if Input.is_action_just_pressed("decrease_exposure"):
			adjust_iso(-iso_step)
	if Input.is_action_pressed("Ryskinti"):
		get_tree().change_scene_to_file("res://ryskinimas.tscn")

func _input(event):
	_mouse_input = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if _mouse_input:
		_rotation_input = -event.relative.x * sensitivity
		_tilt_input = -event.relative.y * sensitivity

	# Toggle crosshair and camera visibility
	if crosshairscene.is_visible_in_tree():
		crosshair.visible = false
		if held_camera_instance:
			held_camera_instance.visible = false
	else:
		crosshair.visible = true
		if held_camera_instance:
			held_camera_instance.visible = true
	
	# Handle zoom only when in photo mode
	if crosshairscene.is_visible_in_tree() and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			print("Scroll wheel up detected")
			zoom_camera(-zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			print("Scroll wheel down detected")
			zoom_camera(zoom_speed)

func zoom_camera(fov_change: float) -> void:
	if CAMERA_CONTROLLER:
		var new_fov = CAMERA_CONTROLLER.fov + fov_change
		CAMERA_CONTROLLER.fov = clamp(new_fov, min_fov, max_fov)
		print("New FOV: ", CAMERA_CONTROLLER.fov)
		# Calculate the new focal length and update the display
		var focal_length = calculate_focal_length(CAMERA_CONTROLLER.fov)
		crosshairscene.update_focal_length(focal_length)

func calculate_focal_length(fov: float) -> float:
	var fov_rad = deg_to_rad(fov)
	var focal_length = sensor_height / (2.0 * tan(fov_rad / 2.0))
	return focal_length

func _on_crosshairscene_visibility_changed():
	if not crosshairscene.is_visible_in_tree() and CAMERA_CONTROLLER:
		CAMERA_CONTROLLER.fov = non_photo_fov  # Reset to non-photo FOV when exiting photo mode
		# Reset ISO to 1000 when exiting photo mode
		iso = 1000.0
		# Restore the original environment to remove any ISO adjustments
		CAMERA_CONTROLLER.environment = original_environment
		emit_signal("iso_updated", iso)  # Update TakePhoto script
		print("Emitting iso_updated signal on visibility change: ", iso)
		var focal_length = calculate_focal_length(CAMERA_CONTROLLER.fov)
		crosshairscene.update_focal_length(focal_length)

func _on_camera_updated(new_camera):
	held_camera_instance = new_camera
	print("Camera updated in Player: ", held_camera_instance.name)

func crouch(delta : float, reverse = false):
	var target_height : float = crouch_height if not reverse else stand_height
	collision_shape.shape.height = target_height
	collision_shape.position.y = target_height * 0.5
	head.position.y = lerp(head.position.y, target_height - 1, crouch_transition * delta)

# Function to adjust ISO
func adjust_iso(change: float) -> void:
	iso = clamp(iso + change, min_iso, max_iso)
	apply_iso_to_camera()
	# Emit signal to update TakePhoto script
	emit_signal("iso_updated", iso)
	print("Emitting iso_updated signal on adjust_iso: ", iso)

# Function to apply ISO to the main camera
func apply_iso_to_camera() -> void:
	if CAMERA_CONTROLLER:
		if crosshairscene.is_visible_in_tree():
			# In photo mode, apply ISO adjustments
			var exposure_value = iso_to_exposure(iso)
			if CAMERA_CONTROLLER.environment:
				CAMERA_CONTROLLER.environment.adjustment_enabled = true
				CAMERA_CONTROLLER.environment.adjustment_brightness = exposure_value
			else:
				var env = Environment.new()
				env.adjustment_enabled = true
				env.adjustment_brightness = exposure_value
				CAMERA_CONTROLLER.environment = env
		else:
			# In non-photo mode, restore the original environment
			CAMERA_CONTROLLER.environment = original_environment
