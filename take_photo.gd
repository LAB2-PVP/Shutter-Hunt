extends Control

@onready var blink: ColorRect = $TextureRect/AnimationPlayer/ColorRect
@onready var overlay: TextureRect = $TextureRect
@onready var animation_player: AnimationPlayer = $TextureRect/AnimationPlayer
@onready var photo_viewport: SubViewport = $PhotoViewport
@onready var photo_camera: Camera3D = $PhotoViewport/PhotoCamera
@onready var focal_length_label: Label = $TextureRect/FocalLengthLabel
@onready var exposure_label: Label = $TextureRect/ExposureLabel  # Recommend renaming to ISOLabel in scene
@onready var shutter_sound: AudioStreamPlayer = $ShutterSound  # Ensure this node exists in the scene

var is_open: bool = false
var is_animating: bool = false
var iso: float = 1000.0  # Default ISO set to 1000 to match Player script
var is_connected_to_player: bool = false  # Track if we've connected to the player's signal

func _ready() -> void:
	blink.visible = false
	overlay.visible = true
	focal_length_label.visible = false
	exposure_label.visible = false
	
	# Create screenshots directory
	var dir: DirAccess = DirAccess.open("user://")
	dir.make_dir("screenshots")
	
	photo_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	
	blink.material.set_shader_parameter("center", Vector2(0.5, 0.5))
	var viewport_size: Vector2 = get_viewport().size
	blink.material.set_shader_parameter("resolution", viewport_size)
	
	# Initialize the ISO label with the current ISO value
	update_iso_label()
	
	# Try connecting to the player's signal, but we'll also try again in open()
	try_connect_to_player()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("open_camera_window"):
		if is_open:
			close()
		else:
			open()
	
	if Input.is_action_just_pressed("Take_photo") and is_open:
		take_photo_with_transition()

func try_connect_to_player() -> void:
	var player: Node = GlobalScene.player
	if player and not is_connected_to_player:
		var connection_result = player.connect("iso_updated", _on_iso_updated)
		if connection_result != OK:
			print("Error: Failed to connect iso_updated signal: ", connection_result)
		else:
			is_connected_to_player = true
			print("Successfully connected to player's iso_updated signal")
			# Sync ISO immediately after connecting
			iso = player.iso
			update_iso_label()
	else:
		if not player:
			print("Player node not found in GlobalScene during try_connect_to_player")
		elif is_connected_to_player:
			print("Already connected to player's iso_updated signal")

func open() -> void:
	visible = true
	is_open = true
	focal_length_label.visible = true
	exposure_label.visible = true
	
	var player: Node = GlobalScene.player
	if player and player.has_node("head/Camera3D"):
		# Try connecting to the player signal if not already connected
		try_connect_to_player()
		
		var player_camera: Camera3D = player.get_node("head/Camera3D")
		if player_camera:
			player_camera.fov = 37.86
			print("Set FOV to default on entering photo mode: ", player_camera.fov)
			var focal_length = player.calculate_focal_length(player_camera.fov)
			update_focal_length(focal_length)
			# Sync ISO with player's current value
			iso = player.iso
			update_iso_label()
			print("Synced ISO on open: ", iso)
	else:
		print("Error: Player or Camera3D node not found on open")

func close() -> void:
	visible = false
	is_open = false
	focal_length_label.visible = false
	exposure_label.visible = false
	# No need to reset ISO here since Player script handles it

func update_focal_length(focal_length: float) -> void:
	focal_length_label.text = "%.1f mm" % (focal_length*2)

func update_iso_label() -> void:
	if exposure_label:
		exposure_label.text = "ISO: %.0f" % iso
		print("ISO label updated to: ", exposure_label.text)
	else:
		print("Error: Exposure label node not found")

func _on_iso_updated(new_iso: float) -> void:
	iso = new_iso
	update_iso_label()
	# Apply ISO to the photo camera to ensure consistency
	var exposure_value = (iso - 100.0) / 750.0 + 0.5  # Convert ISO back to exposure for camera
	if photo_camera.environment:
		photo_camera.environment.adjustment_enabled = true
		photo_camera.environment.adjustment_brightness = exposure_value
	else:
		var env = Environment.new()
		env.adjustment_enabled = true
		env.adjustment_brightness = exposure_value
		photo_camera.environment = env
	print("ISO updated signal received in TakePhoto: ", iso)

func take_photo_with_transition() -> void:
	var player: Node = GlobalScene.player
	if not player or not player.has_node("head/Camera3D"):
		print("Error: Could not find Player or Camera3D node")
		return
	
	var player_camera: Camera3D = player.get_node("head/Camera3D")
	if not player_camera:
		print("Error: Could not find player's Camera3D")
		return
	
	# Play shutter sound
	if shutter_sound:
		shutter_sound.play()
	
	blink.material.set_shader_parameter("center", Vector2(0.5, 0.5))
	blink.visible = true
	animation_player.play("take_photo")

	photo_camera.global_transform = player_camera.global_transform
	photo_camera.fov = player_camera.fov
	photo_camera.near = player_camera.near
	photo_camera.far = player_camera.far
	photo_camera.cull_mask = player_camera.cull_mask
	

	photo_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	var sshot: Image = photo_viewport.get_texture().get_image()
	
	var timestamp: String = Time.get_datetime_string_from_system(false, true).replace(":", "-")
	sshot.save_png("user://screenshots/ss_" + timestamp + ".png")
	
	await animation_player.animation_finished
	blink.visible = false
