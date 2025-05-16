extends Control

var held_object: RigidBody3D = null
var camera: Camera3D
var sub_viewport: SubViewport
var plane: Plane
var original_position: Vector3 = Vector3.ZERO  # Store original position

func _ready():
	sub_viewport = $SubViewportContainer/SubViewport
	camera = $SubViewportContainer/SubViewport/Node3D/Camera3D
	plane = Plane(Vector3(0, 0, 1), 0)  # Plane at z=0
	for node in get_tree().get_nodes_in_group("pickable"):
		if node is RigidBody3D:
			print("Found pickable object: ", node.name, " at ", node.global_transform.origin)
	print("Camera position: ", camera.global_transform.origin)
	print("SubViewport size: ", sub_viewport.size)
	print("SubViewport world_3d: ", sub_viewport.world_3d)
	print("Number of pickable objects: ", get_tree().get_nodes_in_group("pickable").size())

func _physics_process(delta):
	if held_object:
		var mouse_pos = get_viewport().get_mouse_position()
		var ray_origin = camera.project_ray_origin(mouse_pos)
		var ray_normal = camera.project_ray_normal(mouse_pos)
		var ray_end = ray_origin + ray_normal * 1000
		var intersection = plane.intersects_ray(ray_origin, ray_end)
		print("Intersection: ", intersection)
		if intersection:
			held_object.global_transform.origin = intersection
			print("New position: ", held_object.global_transform.origin)

func _input(event):
	print("Input event: ", event)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var mouse_pos = get_viewport().get_mouse_position()
			print("Mouse position: ", mouse_pos)
			var ray_origin = camera.project_ray_origin(mouse_pos)
			var ray_normal = camera.project_ray_normal(mouse_pos)
			var ray_end = ray_origin + ray_normal * 1000
			print("Ray origin: ", ray_origin, " Ray end: ", ray_end)
			var space_state = null
			if sub_viewport.world_3d:
				space_state = sub_viewport.world_3d.direct_space_state
			else:
				print("Error: sub_viewport.world_3d is null!")
				return
			var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
			query.collision_mask = 0xFFFFFFFF
			var result = space_state.intersect_ray(query)
			print("Raycast result: ", result)
			if result and result.collider.is_in_group("pickable"):
				held_object = result.collider as RigidBody3D
				original_position = held_object.global_transform.origin  # Store original position
				print("Picked object: ", held_object, " Original position: ", original_position)
				held_object.freeze = true
				held_object.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		else:
			if held_object:
				held_object.global_transform.origin = original_position  # Return to original position
				print("Restored position: ", held_object.global_transform.origin)
				held_object.freeze = false  # Unfreeze after resetting position
				held_object = null
