@tool
extends MeshInstance3D

@export var size: int

@export_range(4, 1024, 4) var resolution := 32:
	set(new_resolution):
		resolution = new_resolution
		update_mesh()

@export var noise: FastNoiseLite:
	set(new_noise):
		noise = new_noise
		update_mesh()
		if noise:
			noise.changed.connect(update_mesh)

@export_range(4.0, 256.0, 4.0) var height := 64.0:
	set(new_height):
		height = new_height
		update_mesh()

func get_height(x: float, y: float) -> float:
	var raw_height := (noise.get_noise_2d(x, y) * height) / 2

	# Flattening threshold (e.g. 70% of height range)
	var threshold := height * 0.7
	var flat_height := threshold

	# Hard flattening (you can swap this for smooth lerp below)
	#if raw_height > threshold:
	#	return flat_height
	#else:
	#	return raw_height

	# Optional smooth flattening instead of hard cut:
	if raw_height > threshold:
		return lerp(raw_height, flat_height, 0.5)
	else:
		return raw_height

func get_normal(x: float, y: float) -> Vector3:
	var epsilon := size / resolution
	var normal := Vector3(
		(get_height(x + epsilon, y) - get_height(x - epsilon, y)) / (2.0 * epsilon),
		1.0,
		(get_height(x, y + epsilon) - get_height(x, y - epsilon)) / (2.0 * epsilon)
	)
	return normal.normalized()

func update_mesh() -> void:
	var plane := PlaneMesh.new()
	plane.subdivide_depth = resolution
	plane.subdivide_width = resolution
	plane.size = Vector2(size, size)

	var plane_arrays := plane.get_mesh_arrays()
	var vertex_array: PackedVector3Array = plane_arrays[ArrayMesh.ARRAY_VERTEX]
	var normal_array: PackedVector3Array = plane_arrays[ArrayMesh.ARRAY_NORMAL]
	var tangent_array: PackedFloat32Array = plane_arrays[ArrayMesh.ARRAY_TANGENT]

	for i in vertex_array.size():
		var vertex := vertex_array[i]
		var normal := Vector3.UP
		var tangent := Vector3.RIGHT
		if noise:
			vertex.y = get_height(vertex.x, vertex.z)
			normal = get_normal(vertex.x, vertex.z)
			tangent = normal.cross(Vector3.UP)
		vertex_array[i] = vertex
		normal_array[i] = normal
		tangent_array[4 * i] = tangent.x
		tangent_array[4 * i + 1] = tangent.y
		tangent_array[4 * i + 2] = tangent.z

	var array_mesh := ArrayMesh.new()
	array_mesh.add_surface_from_arrays(mesh.PRIMITIVE_TRIANGLES, plane_arrays)
	mesh = array_mesh
