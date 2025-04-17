extends Control

@onready var blink: ColorRect = $TextureRect/AnimationPlayer/ColorRect
@onready var overlay: TextureRect = $TextureRect
@onready var animation_player: AnimationPlayer = $TextureRect/AnimationPlayer
@onready var photo_viewport: SubViewport = $PhotoViewport
@onready var photo_camera: Camera3D = $PhotoViewport/PhotoCamera

var is_open: bool = false
var is_animating: bool = false

func _ready() -> void:
	blink.visible = false
	overlay.visible = true
	close()
	
	# Create screenshots directory if it doesn't exist
	var dir: DirAccess = DirAccess.open("user://")
	dir.make_dir("screenshots")
	
	# Optimize SubViewport updates
	photo_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	
	# Set the shader center to the middle of the screen
	blink.material.set_shader_parameter("center", Vector2(0.5, 0.5))
	
	# Pass the viewport size to the shader for aspect ratio correction
	var viewport_size: Vector2 = get_viewport().size
	blink.material.set_shader_parameter("resolution", viewport_size)

func _process(delta: float) -> void:
	# Handle camera window toggle
	if Input.is_action_just_pressed("open_camera_window"):
		if is_open:
			close()
		else:
			open()
	
	# Handle photo capture
	if Input.is_action_just_pressed("Take_photo") and is_open:
		take_photo_with_transition()

func open() -> void:
	visible = true
	is_open = true

func close() -> void:
	visible = false
	is_open = false

func take_photo_with_transition() -> void:
	var player: Node = GlobalScene.player
	if not player or not player.has_node("head/Camera3D"):
		print("Error: Could not find Player or Camera3D node")
		return
	
	# Ensure the shader center is set to the middle of the screen
	blink.material.set_shader_parameter("center", Vector2(0.5, 0.5))
	
	# Play the animation
	blink.visible = true
	animation_player.play("take_photo")

	# Match the PhotoCamera to the player's camera
	var player_camera: Camera3D = player.get_node("head/Camera3D")
	photo_camera.global_transform = player_camera.global_transform
	photo_camera.fov = player_camera.fov
	photo_camera.near = player_camera.near
	photo_camera.far = player_camera.far
	photo_camera.cull_mask = player_camera.cull_mask
	
	# Render the SubViewport and capture the image
	photo_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	var sshot: Image = photo_viewport.get_texture().get_image()
	
	# Save the image with a timestamp
	var timestamp: String = Time.get_datetime_string_from_system(false, true).replace(":", "-")
	sshot.save_png("user://screenshots/ss_" + timestamp + ".png")
	
	await animation_player.animation_finished
	# Reset animation state
	blink.visible = false
