extends Control

var held_object: RigidBody3D = null
var camera: Camera3D
var sub_viewport: SubViewport
var plane: Plane
var original_position: Vector3 = Vector3.ZERO  # Store original position
var original_rotation: Vector3 = Vector3.ZERO  # Store original rotation
var mouse_offset: Vector3 = Vector3.ZERO  # Store offset between mouse and object
var origins = {}
var liquid_in_rysk: float = 0.0  # Liquid level in RyskinimoIndas
var liquid_in_matav: float = 0.0  # Liquid level in MatavimoIndas
var developing_photo: RigidBody3D = null  # Photo being developed
var develop_timer: float = 0.0  # Timer for drying process
var is_developing: bool = false  # Flag to track development state
var rysk_liquid_mesh: CSGBox3D  # Reference to liquid mesh in RyskinimoIndas
var matav_liquid_mesh: CSGBox3D  # Reference to liquid mesh in MatavimoIndas
var wet_material: StandardMaterial3D  # Material for wet photo effect
var progress_bar: ProgressBar  # Reference to the development progress bar

# Path to the user's photo folder (adjust as needed)
var photo_folder_path: String = OS.get_environment("user://screenshots")  # Default to user's Pictures folder

func _ready():
	sub_viewport = $SubViewportContainer/SubViewport
	camera = $SubViewportContainer/SubViewport/Node3D/Camera3D
	plane = Plane(Vector3(0, 0, 1), 0)  # Plane at z=0
	rysk_liquid_mesh = $SubViewportContainer/SubViewport/Node3D/RyskinimoIndas/LiquidMesh
	matav_liquid_mesh = $SubViewportContainer/SubViewport/Node3D/MatavimoIndas/LiquidMesh
	progress_bar = $DevelopProgressBar

	# Initialize progress bar
	progress_bar.min_value = 0
	progress_bar.max_value = 2  # Matches develop_timer duration
	progress_bar.value = 0
	progress_bar.visible = false

	# Set up liquid material (blue, semi-transparent)
	var liquid_material = StandardMaterial3D.new()
	liquid_material.albedo_color = Color(0, 0.5, 1, 0.7)  # Blue, semi-transparent
	rysk_liquid_mesh.material = liquid_material
	matav_liquid_mesh.material = liquid_material

	# Set up wet material for photo during development
	wet_material = StandardMaterial3D.new()
	wet_material.albedo_color = Color(0.8, 0.8, 0.8)  # Slightly darker for wet look
	wet_material.roughness = 0.2  # Glossy effect
	wet_material.metallic = 0.5  # Add some metallic sheen

	# Initialize pickable objects
	for node in get_tree().get_nodes_in_group("pickable"):
		if node is RigidBody3D:
			print(node.global_transform.origin)
			origins[node] = node.global_transform.origin
			# Lock rotation and zero velocities to prevent rotation
			node.lock_rotation = true
			node.angular_velocity = Vector3.ZERO
			node.linear_velocity = Vector3.ZERO
			# Disable gravity and increase mass and damping to prevent pushing
			node.gravity_scale = 0.0
			node.mass = 1000.0  # High mass makes it harder to push
			node.linear_damp = 10.0  # High damping stops movement quickly
			# Set up material for photos
			if node.name in ["polaroidas", "MatavimoIndas", "RyskinimoIndas"]:
				var mesh_instance = node.get_node_or_null("MeshInstance3D")
				if mesh_instance and mesh_instance.material_override == null:
					var material = StandardMaterial3D.new()
					if node.name == "polaroidas":
						material.albedo_color = Color.GRAY  # Blank photo
					else:
						material.albedo_color = Color.WHITE
					mesh_instance.material_override = material

	# Check if the photo folder exists
	if not DirAccess.dir_exists_absolute(photo_folder_path):
		print("Photo folder not found at: ", photo_folder_path)
		# Fallback to a default path or handle error as needed
		photo_folder_path = "user://screenshots"  # Fallback to Godot's user data directory
		DirAccess.make_dir_absolute(photo_folder_path)

func _physics_process(delta):
	# Update liquid heights (assuming max height of the container is 1 unit)
	rysk_liquid_mesh.height = liquid_in_rysk
	matav_liquid_mesh.height = liquid_in_matav

	if held_object:
		var mouse_pos = get_viewport().get_mouse_position()
		var ray_origin = camera.project_ray_origin(mouse_pos)
		var ray_normal = camera.project_ray_normal(mouse_pos)
		var ray_end = ray_origin + ray_normal * 1000
		var intersection = plane.intersects_ray(ray_origin, ray_end)
		if intersection:
			# Constrain to XY plane and keep original rotation
			var new_position = intersection + mouse_offset
			new_position.z = original_position.z  # Keep z constant for 2D movement
			held_object.global_transform.origin = new_position
			held_object.rotation = original_rotation  # Prevent rotation while dragging
			held_object.linear_velocity = Vector3.ZERO
			held_object.angular_velocity = Vector3.ZERO
	else:
		# For all non-held objects, reset their position if pushed
		for node in get_tree().get_nodes_in_group("pickable"):
			if node is RigidBody3D and node != held_object:
				var current_position = node.global_transform.origin
				var original_pos = origins[node]
				# If the object has moved from its original position, snap it back
				if current_position.distance_to(original_pos) > 0.01:  # Small threshold to avoid jitter
					node.global_transform.origin = original_pos
					node.linear_velocity = Vector3.ZERO  # Stop any movement
					node.angular_velocity = Vector3.ZERO
		# Reset velocities for non-held objects to minimize physics movement
		for node in get_tree().get_nodes_in_group("pickable"):
			if node is RigidBody3D and node != held_object:
				node.linear_velocity = Vector3.ZERO
				node.angular_velocity = Vector3.ZERO
		# Handle development timer
		if is_developing and developing_photo:
			develop_timer -= delta
			progress_bar.value = develop_timer  # Update progress bar
			if develop_timer <= 0:
				finish_developing()
	# Handle liquid interactions (e.g., add liquid with 'E' key)
	if Input.is_action_just_pressed("ui_accept"):  # Use 'Enter' key to add liquid
		if held_object and held_object.name == "RyskinimoIndas" and liquid_in_rysk < 1.0:
			liquid_in_rysk += 0.5  # Add 0.5 units of liquid
			print("Added liquid to RyskinimoIndas. Level: ", liquid_in_rysk)
		elif held_object and held_object.name == "MatavimoIndas" and liquid_in_matav < 1.0 and liquid_in_rysk > 0.0:
			var transfer_amount = min(0.5, liquid_in_rysk)  # Transfer up to 0.5 or available liquid
			liquid_in_rysk -= transfer_amount
			liquid_in_matav += transfer_amount
			print("Transferred liquid to MatavimoIndas. RyskinimoIndas: ", liquid_in_rysk, " MatavimoIndas: ", liquid_in_matav)

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var mouse_pos = get_viewport().get_mouse_position()
			var ray_origin = camera.project_ray_origin(mouse_pos)
			var ray_normal = camera.project_ray_normal(mouse_pos)
			var ray_end = ray_origin + ray_normal * 1000
			var space_state = null
			if sub_viewport.world_3d:
				space_state = sub_viewport.world_3d.direct_space_state
			else:
				return
			var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
			query.collision_mask = 0xFFFFFFFF
			var result = space_state.intersect_ray(query)
			if result and result.collider.is_in_group("pickable"):
				held_object = result.collider as RigidBody3D
				original_position = origins[held_object]  # Use original position from origins
				original_rotation = held_object.rotation  # Store current rotation
				plane = Plane(Vector3(0, 0, 1), held_object.global_position.z)
				var pickup_intersection = plane.intersects_ray(ray_origin, ray_end)
				if pickup_intersection:
					mouse_offset = held_object.global_position - pickup_intersection
				held_object.freeze = true
				held_object.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
				# Lock rotation while dragging
				held_object.lock_rotation = true
				held_object.angular_velocity = Vector3.ZERO
				held_object.linear_velocity = Vector3.ZERO
				# Check for dipping action
				if held_object.name == "polaroidas" and liquid_in_matav > 0.0 and not is_developing:
					start_developing()
		else:
			if held_object:
				held_object.set_deferred("position", original_position)
				held_object.global_transform.origin = original_position  # Return to original position
				held_object.rotation = original_rotation  # Restore original rotation
				for node in get_tree().get_nodes_in_group("pickable"):
					if node is RigidBody3D:
						print(origins[node])
				held_object.freeze = false  # Allow physics for collisions but control velocity
				# Ensure no physics movement after release
				held_object.lock_rotation = true
				held_object.angular_velocity = Vector3.ZERO
				held_object.linear_velocity = Vector3.ZERO
				# Now set held_object to null
				held_object = null
				mouse_offset = Vector3.ZERO  # Reset offset
				plane = Plane()  # Reset the plane

func start_developing():
	if held_object and held_object.name == "polaroidas" and liquid_in_matav > 0.0:
		developing_photo = held_object
		is_developing = true
		develop_timer = 2.0  # Set drying time to 2 seconds
		liquid_in_matav -= 0.1  # Consume some liquid
		print("Photo developing started. Time left: ", develop_timer)
		var mesh_instance = developing_photo.get_node_or_null("MeshInstance3D")
		if mesh_instance:
			mesh_instance.material_override = wet_material  # Apply wet material
		progress_bar.visible = true
		progress_bar.value = develop_timer

func finish_developing():
	if developing_photo:
		var mesh_instance = developing_photo.get_node_or_null("MeshInstance3D")
		if mesh_instance and mesh_instance.material_override:
			# Load the last photo from the user's folder
			var last_photo_texture = load_last_photo()
			if last_photo_texture:
				mesh_instance.material_override.albedo_texture = last_photo_texture
				mesh_instance.material_override.albedo_color = Color.WHITE
			else:
				# Fallback if no photo is found
				mesh_instance.material_override.albedo_color = Color.BLACK
			mesh_instance.material_override.roughness = 1.0  # Dry look
			mesh_instance.material_override.metallic = 0.0
		developing_photo = null
		is_developing = false
		print("Photo development complete!")
		progress_bar.visible = false

# Function to load the last photo from the user's folder
func load_last_photo() -> Texture2D:
	var dir = DirAccess.open(photo_folder_path)
	if dir:
		var latest_file: String = ""
		var latest_time: int = 0
		var image_extensions = [".png", ".jpg", ".jpeg"]  # Supported image extensions

		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				var file_path = photo_folder_path + "/" + file_name
				var file_ext = file_name.get_extension().to_lower()
				if file_ext in image_extensions:
					var file_time = FileAccess.get_modified_time(file_path)
					if file_time > latest_time:
						latest_time = file_time
						latest_file = file_path
			file_name = dir.get_next()
		dir.list_dir_end()

		if latest_file != "":
			var image = Image.new()
			var error = image.load(latest_file)
			if error == OK:
				var texture = ImageTexture.create_from_image(image)
				return texture
			else:
				print("Failed to load image: ", latest_file)
		else:
			print("No image files found in folder: ", photo_folder_path)
	else:
		print("Cannot open directory: ", photo_folder_path)
	return null  # Return null if no photo is found
