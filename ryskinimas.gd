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
var liquid_in_new: float = 0.0  # Liquid level in newContainer
var developing_photo: RigidBody3D = null  # Photo being developed
var develop_timer: float = 0.0  # Timer for drying process
var is_developing: bool = false  # Flag to track development state
var rysk_liquid_mesh: CSGBox3D  # Reference to liquid mesh in RyskinimoIndas
var matav_liquid_mesh: CSGBox3D  # Reference to liquid mesh in MatavimoIndas
var new_liquid_mesh: CSGBox3D  # Reference to liquid mesh in newContainer
var wet_material: StandardMaterial3D  # Material for wet photo effect
var progress_bar: ProgressBar  # Reference to the development progress bar
var matavimo_indas: RigidBody3D  # Reference to MatavimoIndas node
var rotation_angle: float = 0.0  # Track rotation angle for RyskinimoIndas
var matav_rotation_angle: float = 0.0  # Track rotation angle for MatavimoIndas
var is_matav_processed: bool = false  # Track if MatavimoIndas has been filled and emptied

# Path to the user's photo folder (adjust as needed)
var photo_folder_path: String = OS.get_environment("user://screenshots")  # Default to user's Pictures folder

func _ready():
	sub_viewport = $SubViewportContainer/SubViewport
	camera = $SubViewportContainer/SubViewport/Node3D/Camera3D
	plane = Plane(Vector3(0, 0, 1), 0)  # Plane at z=0
	rysk_liquid_mesh = $SubViewportContainer/SubViewport/Node3D/RyskinimoIndas/LiquidMesh
	matav_liquid_mesh = $SubViewportContainer/SubViewport/Node3D/MatavimoIndas/LiquidMesh
	new_liquid_mesh = $SubViewportContainer/SubViewport/Node3D/newContainer/LiquidMesh  # Reference to new container's liquid mesh
	print("Debug: new_liquid_mesh initialized as: ", new_liquid_mesh)
	progress_bar = $DevelopProgressBar
	matavimo_indas = $SubViewportContainer/SubViewport/Node3D/MatavimoIndas  # Get reference to MatavimoIndas

	# Initialize progress bar
	progress_bar.min_value = 0
	progress_bar.max_value = 2  # Matches develop_timer duration
	progress_bar.value = 0
	progress_bar.visible = false

	# Set up liquid material (blue, semi-transparent)
	var liquid_material = StandardMaterial3D.new()
	liquid_material.albedo_color = Color(0, 0.5, 1, 0.7)  # Blue, semi-transparent
	if rysk_liquid_mesh:
		rysk_liquid_mesh.material = liquid_material
	else:
		print("Error: RyskinimoIndas/LiquidMesh not found!")
	if matav_liquid_mesh:
		matav_liquid_mesh.material = liquid_material
	else:
		print("Error: MatavimoIndas/LiquidMesh not found!")
	if new_liquid_mesh:
		new_liquid_mesh.material = liquid_material
	else:
		print("Error: newContainer/LiquidMesh not found!")

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
			if node.name in ["polaroidas", "MatavimoIndas", "RyskinimoIndas", "newContainer"]:
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
	if new_liquid_mesh:
		new_liquid_mesh.height = liquid_in_new  # Update new container liquid height
	print("Debug: Current liquid levels - RyskinimoIndas: ", liquid_in_rysk, " MatavimoIndas: ", liquid_in_matav, " NewContainer: ", liquid_in_new)

	if held_object:
		var mouse_pos = get_viewport().get_mouse_position()
		var ray_origin = camera.project_ray_origin(mouse_pos)
		var ray_normal = camera.project_ray_normal(mouse_pos)
		var ray_end = ray_origin + ray_normal * 1000
		var intersection = plane.intersects_ray(ray_origin, ray_end)
		if intersection:
			# Use static offset calculated at pickup
			var new_position = intersection + mouse_offset
			new_position.z = original_position.z  # Keep z constant for 2D movement
			# Apply local rotation around Z-axis without affecting position
			if held_object.name == "RyskinimoIndas":
				held_object.rotation = original_rotation
				held_object.rotate_z(deg_to_rad(rotation_angle))
				if rotation_angle != 0:
					new_position.x -= 8.0
					new_position.y -= 1.0  # Add offset on the Y-axis when rotated
			elif held_object.name == "MatavimoIndas":
				held_object.rotation = original_rotation
				held_object.rotate_z(deg_to_rad(matav_rotation_angle))
				if matav_rotation_angle != 0:
					new_position.x += 2
					new_position.y -= 12  # Add offset on the Y-axis when rotated
			else:
				held_object.rotation = original_rotation
			held_object.global_transform.origin = new_position
			held_object.linear_velocity = Vector3.ZERO
			held_object.angular_velocity = Vector3.ZERO
	else:
		# For all non-held objects, reset their position if pushed
		for node in get_tree().get_nodes_in_group("pickable"):
			if node is RigidBody3D and node != held_object:
				var current_position = node.global_transform.origin
				var original_pos = origins[node]
				if current_position.distance_to(original_pos) > 0.01:  # Small threshold to avoid jitter
					node.global_transform.origin = original_pos
					node.linear_velocity = Vector3.ZERO
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

	# Handle liquid interactions (e.g., add liquid with 'Enter' key)
	if Input.is_action_just_pressed("ui_accept"):
		if held_object and held_object.name == "RyskinimoIndas":
			if rotation_angle == 0 and liquid_in_rysk < 1.0:
				liquid_in_rysk += 0.5
				print("Added liquid to RyskinimoIndas. Level: ", liquid_in_rysk)
			elif rotation_angle != 0 and liquid_in_rysk > 0.0:
				var transfer_amount = liquid_in_rysk
				liquid_in_rysk -= transfer_amount
				liquid_in_matav += transfer_amount
				print("Transferred all liquid to MatavimoIndas. RyskinimoIndas: ", liquid_in_rysk, " MatavimoIndas: ", liquid_in_matav)
				print("Rotation angle before reset: ", rotation_angle)
				held_object.rotation = original_rotation
				rotation_angle = 0
				print("Rotation angle after reset: ", rotation_angle, " Object rotation: ", held_object.rotation)
		elif held_object and held_object.name == "MatavimoIndas":
			print("Debug: MatavimoIndas Enter pressed. Rotation angle: ", matav_rotation_angle, " Liquid in Matav: ", liquid_in_matav, " Liquid in New: ", liquid_in_new)
			if matav_rotation_angle != 0 and liquid_in_matav > 0.0:
				var transfer_amount = liquid_in_matav
				print("Debug: Transfer amount calculated: ", transfer_amount)
				liquid_in_matav -= transfer_amount
				liquid_in_new += transfer_amount  # Transfer to newContainer
				print("Debug: Verified liquid_in_new after transfer: ", liquid_in_new)
				print("Transferred all liquid to newContainer. MatavimoIndas: ", liquid_in_matav, " newContainer: ", liquid_in_new)
				print("Matav rotation angle before reset: ", matav_rotation_angle)
				held_object.rotation = original_rotation
				matav_rotation_angle = 0
				print("Matav rotation angle after reset: ", matav_rotation_angle, " Object rotation: ", held_object.rotation)
				# Mark MatavimoIndas as processed for photo development
				is_matav_processed = true
			else:
				print("Debug: Transfer to newContainer failed. Rotation angle: ", matav_rotation_angle, " Liquid in Matav: ", liquid_in_matav)

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
				print("Space state retrieved: ", space_state != null)
			else:
				print("SubViewport world_3d is null!")
				return
			var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
			query.collision_mask = 0xFFFFFFFF
			var result = space_state.intersect_ray(query)
			if result:
				print("Raycast hit: ", result.collider.name)
				if result.collider.is_in_group("pickable"):
					held_object = result.collider as RigidBody3D
					print("Picked up object: ", held_object.name)
					original_position = origins[held_object]
					original_rotation = held_object.rotation
					plane = Plane(Vector3(0, 0, 1), held_object.global_position.z)
					var pickup_intersection = plane.intersects_ray(ray_origin, ray_end)
					if pickup_intersection:
						mouse_offset = held_object.global_transform.origin - pickup_intersection
						print("Mouse offset: ", mouse_offset)
					held_object.freeze = true
					held_object.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
					held_object.lock_rotation = true
					held_object.angular_velocity = Vector3.ZERO
					held_object.linear_velocity = Vector3.ZERO
					# Check for dipping action only if MatavimoIndas has been processed
					if held_object.name == "polaroidas" and is_matav_processed:
						start_developing()
			else:
				print("Raycast missed!")
		else:
			if held_object:
				held_object.set_deferred("position", original_position)
				held_object.global_transform.origin = original_position
				held_object.rotation = original_rotation
				for node in get_tree().get_nodes_in_group("pickable"):
					if node is RigidBody3D:
						print(origins[node])
				held_object.freeze = false
				held_object.lock_rotation = true
				held_object.angular_velocity = Vector3.ZERO
				held_object.linear_velocity = Vector3.ZERO
				rotation_angle = 0
				matav_rotation_angle = 0
				held_object = null
				mouse_offset = Vector3.ZERO
				plane = Plane()
	# Handle scroll wheel for rotation
	elif event is InputEventMouseButton and (event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		if held_object and held_object.name == "RyskinimoIndas":
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				rotation_angle += 45
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				rotation_angle -= 45
			rotation_angle = clamp(rotation_angle, 0, 180)
			print("Debug: RyskinimoIndas rotation angle updated: ", rotation_angle)
		elif held_object and held_object.name == "MatavimoIndas":
			print("Debug: MatavimoIndas scroll detected. Current angle: ", matav_rotation_angle)
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				matav_rotation_angle += 45
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				matav_rotation_angle -= 45
			matav_rotation_angle = clamp(matav_rotation_angle, 0, 180)
			print("Debug: MatavimoIndas new angle: ", matav_rotation_angle)

func start_developing():
	if held_object and held_object.name == "polaroidas" and is_matav_processed:
		developing_photo = held_object
		is_developing = true
		develop_timer = 2.0
		print("Photo developing started. Time left: ", develop_timer)
		var mesh_instance = developing_photo.get_node_or_null("MeshInstance3D")
		if mesh_instance:
			mesh_instance.material_override = wet_material
		progress_bar.visible = true
		progress_bar.value = develop_timer

func finish_developing():
	if developing_photo:
		var mesh_instance = developing_photo.get_node_or_null("MeshInstance3D")
		if mesh_instance and mesh_instance.material_override:
			var last_photo_texture = load_last_photo()
			if last_photo_texture:
				mesh_instance.material_override.albedo_texture = last_photo_texture
				mesh_instance.material_override.albedo_color = Color.WHITE
			else:
				mesh_instance.material_override.albedo_color = Color.BLACK
			mesh_instance.material_override.roughness = 1.0
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
		var image_extensions = [".png", ".jpg", ".jpeg"]

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
	return null
