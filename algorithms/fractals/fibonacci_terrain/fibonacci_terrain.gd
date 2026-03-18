extends Node3D

## Fibonacci Terrain Generator
## Starts with a plane, recursively subdivides using golden ratio
## Lifts random non-edge faces to create organic mountain/terrain growth
## Each iteration: subdivide -> select non-edge -> lift -> zoom out -> repeat

@export_group("Terrain Shape")
@export var initial_size := Vector2(8.0, 8.0 / 1.618)  # Golden ratio rectangle
@export var max_iterations := 5
@export var initial_subdivisions := 2  # Start with 2x2 = 4 faces
@export var max_faces := 500  # Safety limit to prevent hanging

@export_group("Growth Parameters")
@export var lift_height_base := 0.5
@export var lift_height_variance := 0.3
@export var subdivision_depth_per_lift := 1  # How many times to subdivide lifted face
@export var faces_to_lift_per_iteration := 2
@export var prefer_center_lift := true  # Bias toward center faces

@export_group("Animation")
@export var animate_growth := true
@export var growth_delay := 0.8  # Seconds between iterations
@export var zoom_out_per_iteration := 1.1  # Camera zoom factor

@export_group("Appearance")
@export var base_color := Color(0.2, 0.5, 0.3)  # Grass green
@export var peak_color := Color(0.9, 0.95, 1.0)  # Snow white
@export var use_golden_spiral_overlay := true

# Internal state
var faces: Array[Dictionary] = []  # {corners: [v0,v1,v2,v3], height: float, subdivisions: int, is_edge: bool}
var current_iteration := 0
var golden_ratio := (1.0 + sqrt(5.0)) / 2.0
var golden_angle := PI * 2.0 / (golden_ratio * golden_ratio)
var growth_timer := 0.0
var is_growing := false
var mesh_instance: MeshInstance3D
var spiral_mesh_instance: MeshInstance3D

signal iteration_complete(iteration: int)
signal terrain_complete()

func _ready() -> void:
	_initialize_terrain()
	if animate_growth:
		is_growing = true
	else:
		_generate_full_terrain()

func _process(delta: float) -> void:
	if not animate_growth or not is_growing:
		return

	growth_timer += delta
	if growth_timer >= growth_delay:
		growth_timer = 0.0
		_perform_growth_iteration()

func _initialize_terrain() -> void:
	"""Create initial subdivided plane"""
	faces.clear()

	var half_w = initial_size.x / 2.0
	var half_h = initial_size.y / 2.0

	# Create initial grid of faces
	var cols = initial_subdivisions
	var rows = initial_subdivisions
	var cell_w = initial_size.x / cols
	var cell_h = initial_size.y / rows

	for row in range(rows):
		for col in range(cols):
			var x0 = -half_w + col * cell_w
			var x1 = x0 + cell_w
			var z0 = -half_h + row * cell_h
			var z1 = z0 + cell_h

			var is_edge = (row == 0 or row == rows - 1 or col == 0 or col == cols - 1)

			faces.append({
				"corners": [
					Vector3(x0, 0, z0),
					Vector3(x1, 0, z0),
					Vector3(x1, 0, z1),
					Vector3(x0, 0, z1)
				],
				"height": 0.0,
				"subdivisions": 0,
				"is_edge": is_edge,
				"center": Vector3((x0 + x1) / 2.0, 0, (z0 + z1) / 2.0)
			})

	_rebuild_mesh()
	print("FibonacciTerrain: Initialized with %d faces" % faces.size())

func _perform_growth_iteration():
	"""One iteration of the growth algorithm"""
	if current_iteration >= max_iterations:
		is_growing = false
		terrain_complete.emit()
		print("FibonacciTerrain: Growth complete after %d iterations" % current_iteration)
		return

	# Safety check - prevent runaway face count
	if faces.size() >= max_faces:
		is_growing = false
		terrain_complete.emit()
		print("FibonacciTerrain: Reached max faces limit (%d)" % max_faces)
		return

	# Find non-edge faces that can be lifted
	var liftable_faces: Array[int] = []
	for i in range(faces.size()):
		if not faces[i].is_edge:
			liftable_faces.append(i)

	if liftable_faces.is_empty():
		# All faces are edge - subdivide everything and recalculate edges
		_subdivide_all_faces()
		_recalculate_edges()
		_rebuild_mesh()
		return

	# Select faces to lift (biased toward center if enabled)
	var faces_to_lift: Array[int] = []
	var num_to_lift = min(faces_to_lift_per_iteration, liftable_faces.size())

	if prefer_center_lift:
		# Sort by distance from center (closest first)
		liftable_faces.sort_custom(func(a, b):
			return faces[a].center.length() < faces[b].center.length()
		)
		# Pick from the closer half with some randomness
		var pool_size = max(1, liftable_faces.size() / 2)
		for i in range(num_to_lift):
			if liftable_faces.is_empty():
				break
			var pick_index = randi() % min(pool_size, liftable_faces.size())
			faces_to_lift.append(liftable_faces[pick_index])
			liftable_faces.remove_at(pick_index)
	else:
		# Random selection
		liftable_faces.shuffle()
		for i in range(num_to_lift):
			faces_to_lift.append(liftable_faces[i])

	# Lift selected faces - process in reverse order to preserve indices
	faces_to_lift.sort()
	faces_to_lift.reverse()
	for face_idx in faces_to_lift:
		_lift_and_subdivide_face(face_idx)

	# Recalculate which faces are edges
	_recalculate_edges()

	# Rebuild the mesh
	_rebuild_mesh()

	current_iteration += 1
	iteration_complete.emit(current_iteration)
	print("FibonacciTerrain: Iteration %d complete, %d faces" % [current_iteration, faces.size()])

func _lift_and_subdivide_face(face_idx: int) -> void:
	"""Lift a face and optionally subdivide it"""
	var face = faces[face_idx]

	# Calculate lift height (using golden ratio scaling)
	var iteration_scale = pow(1.0 / golden_ratio, current_iteration * 0.5)
	var lift = lift_height_base * iteration_scale + randf_range(-lift_height_variance, lift_height_variance) * iteration_scale

	# Lift all corners
	for i in range(4):
		face.corners[i].y += lift
	face.height += lift
	face.center.y += lift

	# Subdivide the lifted face using golden ratio
	if face.subdivisions < subdivision_depth_per_lift + current_iteration:
		_subdivide_face_golden(face_idx)

func _subdivide_face_golden(face_idx: int) -> void:
	"""Subdivide a face using golden ratio proportions"""
	var face = faces[face_idx]
	var corners = face.corners

	# Get face dimensions
	var width = corners[1].distance_to(corners[0])
	var height_dim = corners[3].distance_to(corners[0])

	# Subdivide along the longer dimension using golden ratio
	var new_faces: Array[Dictionary] = []

	if width >= height_dim:
		# Split horizontally (along X)
		var split_ratio = 1.0 / golden_ratio
		var split_x = lerp(corners[0].x, corners[1].x, split_ratio)

		# Left face (smaller, golden ratio)
		var left_corners = [
			corners[0],
			Vector3(split_x, corners[1].y, corners[1].z),
			Vector3(split_x, corners[2].y, corners[2].z),
			corners[3]
		]

		# Right face (larger)
		var right_corners = [
			Vector3(split_x, corners[0].y, corners[0].z),
			corners[1],
			corners[2],
			Vector3(split_x, corners[3].y, corners[3].z)
		]

		new_faces.append(_create_face_dict(left_corners, face.height, face.subdivisions + 1))
		new_faces.append(_create_face_dict(right_corners, face.height, face.subdivisions + 1))
	else:
		# Split vertically (along Z)
		var split_ratio = 1.0 / golden_ratio
		var split_z = lerp(corners[0].z, corners[3].z, split_ratio)

		# Bottom face (smaller)
		var bottom_corners = [
			corners[0],
			corners[1],
			Vector3(corners[2].x, corners[2].y, split_z),
			Vector3(corners[3].x, corners[3].y, split_z)
		]

		# Top face (larger)
		var top_corners = [
			Vector3(corners[0].x, corners[0].y, split_z),
			Vector3(corners[1].x, corners[1].y, split_z),
			corners[2],
			corners[3]
		]

		new_faces.append(_create_face_dict(bottom_corners, face.height, face.subdivisions + 1))
		new_faces.append(_create_face_dict(top_corners, face.height, face.subdivisions + 1))

	# Replace original face with new faces
	faces.remove_at(face_idx)
	for new_face in new_faces:
		faces.insert(face_idx, new_face)

func _create_face_dict(corners: Array, height: float, subdivisions: int) -> Dictionary:
	"""Create a face dictionary from corners"""
	var center = Vector3.ZERO
	for c in corners:
		center += c
	center /= 4.0

	return {
		"corners": corners,
		"height": height,
		"subdivisions": subdivisions,
		"is_edge": false,  # Will be recalculated
		"center": center
	}

func _subdivide_all_faces() -> void:
	"""Subdivide all faces once"""
	# IMPORTANT: Capture the count ONCE before subdividing
	# Each subdivision replaces 1 face with 2, so we need to skip the new ones
	var original_count = faces.size()
	var i = 0
	var faces_processed = 0
	while faces_processed < original_count:
		_subdivide_face_golden(i)
		# After subdivision, the face at i is replaced by 2 new faces
		# Skip both new faces to avoid infinite loop
		i += 2
		faces_processed += 1

func _recalculate_edges() -> void:
	"""Determine which faces are on the edge of the terrain"""
	# Find bounding box
	var min_x = INF
	var max_x = -INF
	var min_z = INF
	var max_z = -INF

	for face in faces:
		for corner in face.corners:
			min_x = min(min_x, corner.x)
			max_x = max(max_x, corner.x)
			min_z = min(min_z, corner.z)
			max_z = max(max_z, corner.z)

	var edge_threshold = 0.01

	for face in faces:
		face.is_edge = false
		for corner in face.corners:
			if abs(corner.x - min_x) < edge_threshold or abs(corner.x - max_x) < edge_threshold:
				face.is_edge = true
				break
			if abs(corner.z - min_z) < edge_threshold or abs(corner.z - max_z) < edge_threshold:
				face.is_edge = true
				break

func _rebuild_mesh() -> void:
	"""Rebuild the terrain mesh from faces"""
	# Remove old mesh
	if mesh_instance:
		mesh_instance.queue_free()

	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Find height range for coloring
	var min_height = 0.0
	var max_height = 0.01
	for face in faces:
		max_height = max(max_height, face.height)

	# Add faces
	for face in faces:
		var corners = face.corners
		var height_ratio = face.height / max_height if max_height > 0 else 0.0
		var color = base_color.lerp(peak_color, height_ratio)

		# Calculate normal
		var v1 = corners[1] - corners[0]
		var v2 = corners[3] - corners[0]
		var normal = v2.cross(v1).normalized()

		surface_tool.set_normal(normal)
		surface_tool.set_color(color)

		# Triangle 1: 0, 1, 2
		surface_tool.add_vertex(corners[0])
		surface_tool.add_vertex(corners[1])
		surface_tool.add_vertex(corners[2])

		# Triangle 2: 0, 2, 3
		surface_tool.add_vertex(corners[0])
		surface_tool.add_vertex(corners[2])
		surface_tool.add_vertex(corners[3])

		# Add sides for lifted faces
		if face.height > 0.01:
			_add_face_sides(surface_tool, face, color)

	var mesh = surface_tool.commit()

	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.name = "TerrainMesh"

	# Material
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_instance.material_override = material

	add_child(mesh_instance)

	# Update golden spiral overlay
	if use_golden_spiral_overlay:
		_update_spiral_overlay()

func _add_face_sides(surface_tool: SurfaceTool, face: Dictionary, top_color: Color) -> void:
	"""Add side walls for a lifted face"""
	var corners = face.corners
	var base_y = 0.0
	var side_color = top_color.darkened(0.3)

	surface_tool.set_color(side_color)

	# Four sides
	for i in range(4):
		var c0 = corners[i]
		var c1 = corners[(i + 1) % 4]
		var b0 = Vector3(c0.x, base_y, c0.z)
		var b1 = Vector3(c1.x, base_y, c1.z)

		var side_normal = (c1 - c0).cross(Vector3.UP).normalized()
		surface_tool.set_normal(side_normal)

		# Triangle 1
		surface_tool.add_vertex(b0)
		surface_tool.add_vertex(c0)
		surface_tool.add_vertex(c1)

		# Triangle 2
		surface_tool.add_vertex(b0)
		surface_tool.add_vertex(c1)
		surface_tool.add_vertex(b1)

func _update_spiral_overlay() -> void:
	"""Draw golden spiral overlay on terrain"""
	if spiral_mesh_instance:
		spiral_mesh_instance.queue_free()

	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_LINE_STRIP)

	surface_tool.set_color(Color(1.0, 0.84, 0.0, 0.8))  # Gold color

	# Generate golden spiral points
	var spiral_points = 100
	var max_radius = min(initial_size.x, initial_size.y) * 0.4

	for i in range(spiral_points):
		var t = float(i) / spiral_points
		var angle = t * PI * 4  # Two full rotations
		var radius = max_radius * pow(golden_ratio, -angle / (PI * 2)) * t

		var x = cos(angle) * radius
		var z = sin(angle) * radius
		var y = _get_terrain_height_at(Vector2(x, z)) + 0.1  # Slightly above terrain

		surface_tool.add_vertex(Vector3(x, y, z))

	var mesh = surface_tool.commit()

	spiral_mesh_instance = MeshInstance3D.new()
	spiral_mesh_instance.mesh = mesh
	spiral_mesh_instance.name = "GoldenSpiral"

	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1.0, 0.84, 0.0)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.84, 0.0) * 0.5
	spiral_mesh_instance.material_override = material

	add_child(spiral_mesh_instance)

func _get_terrain_height_at(pos: Vector2) -> float:
	"""Get terrain height at a given XZ position"""
	for face in faces:
		if _point_in_face(pos, face):
			return face.height
	return 0.0

func _point_in_face(point: Vector2, face: Dictionary) -> bool:
	"""Check if a 2D point is inside a face (XZ plane)"""
	var corners = face.corners
	var min_x = min(corners[0].x, corners[1].x, corners[2].x, corners[3].x)
	var max_x = max(corners[0].x, corners[1].x, corners[2].x, corners[3].x)
	var min_z = min(corners[0].z, corners[1].z, corners[2].z, corners[3].z)
	var max_z = max(corners[0].z, corners[1].z, corners[2].z, corners[3].z)

	return point.x >= min_x and point.x <= max_x and point.y >= min_z and point.y <= max_z

func _generate_full_terrain() -> void:
	"""Generate terrain without animation"""
	for i in range(max_iterations):
		_perform_growth_iteration()
	is_growing = false

# Public API
func regenerate() -> void:
	"""Reset and regenerate terrain"""
	current_iteration = 0
	growth_timer = 0.0
	_initialize_terrain()
	if animate_growth:
		is_growing = true
	else:
		_generate_full_terrain()

func set_iteration(iter: int) -> void:
	"""Set terrain to specific iteration"""
	current_iteration = 0
	_initialize_terrain()
	for i in range(min(iter, max_iterations)):
		_perform_growth_iteration()

func toggle_spiral() -> void:
	"""Toggle golden spiral overlay"""
	use_golden_spiral_overlay = not use_golden_spiral_overlay
	if use_golden_spiral_overlay:
		_update_spiral_overlay()
	elif spiral_mesh_instance:
		spiral_mesh_instance.queue_free()
		spiral_mesh_instance = null

# Grid system integration
func configure(data: Dictionary) -> void:
	"""Configure from grid spawn parameters (e.g., fibonacci_terrain#preset:mountain_peak)"""
	print("FibonacciTerrain: Configuring from Grid JSON: ", data)

	if data.has("preset"):
		apply_preset(str(data["preset"]).to_lower())
		return  # Preset handles regeneration

	if data.has("iterations"):
		max_iterations = int(data["iterations"])

	if data.has("lift"):
		lift_height_base = float(data["lift"])

	if data.has("animate"):
		animate_growth = str(data["animate"]).to_lower() == "true"

	if data.has("spiral"):
		use_golden_spiral_overlay = str(data["spiral"]).to_lower() == "true"

	regenerate()

# Presets
func apply_preset(preset_name: String) -> void:
	"""Apply terrain generation preset"""
	match preset_name:
		"gentle_hills":
			max_iterations = 4
			lift_height_base = 0.3
			faces_to_lift_per_iteration = 3
			prefer_center_lift = false
		"mountain_peak":
			max_iterations = 6
			lift_height_base = 0.8
			faces_to_lift_per_iteration = 1
			prefer_center_lift = true
		"plateau":
			max_iterations = 3
			lift_height_base = 1.0
			faces_to_lift_per_iteration = 4
			prefer_center_lift = true
		"archipelago":
			max_iterations = 5
			lift_height_base = 0.4
			faces_to_lift_per_iteration = 2
			prefer_center_lift = false
			initial_subdivisions = 4
		"fibonacci_spiral":
			max_iterations = 8
			lift_height_base = 0.2
			faces_to_lift_per_iteration = 1
			prefer_center_lift = true
			use_golden_spiral_overlay = true

	regenerate()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
