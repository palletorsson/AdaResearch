@tool
extends SoftBody3D

@export var size: float = 1.0:
	set(value):
		size = value
		if is_inside_tree(): _build_mesh()

@export var radius: float = 0.15:
	set(value):
		radius = value
		if is_inside_tree(): _build_mesh()

@export var segments: int = 4:
	set(value):
		segments = value
		if is_inside_tree(): _build_mesh()

@export var base_color: Color = Color(0.3, 0.8, 0.9):
	set(value):
		base_color = value
		if is_inside_tree(): _update_material()

func _ready():
	ray_pickable = false # Disable ray picking to prevent interference
	simulation_precision = 10 # Higher precision for better collision
	collision_layer = 1
	collision_mask = 1
	_build_mesh()

func _build_mesh():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Geometry generation logic ported from RoundedCube
	var half_size = size * 0.5
	var r = clamp(radius, 0.0, half_size * 0.49)
	var divs = segments
	var grid_size = divs * 2 + 1
	
	var vertex_grid = {} # Map grid coord -> vertex index
	var current_vertex_index = 0
	
	# 1. Generate Vertices
	for x_idx in range(grid_size):
		for y_idx in range(grid_size):
			for z_idx in range(grid_size):
				var on_surface = (x_idx == 0 or x_idx == grid_size - 1 or
								  y_idx == 0 or y_idx == grid_size - 1 or
								  z_idx == 0 or z_idx == grid_size - 1)

				if not on_surface:
					continue

				var x = (float(x_idx) / float(grid_size - 1)) * 2.0 - 1.0
				var y = (float(y_idx) / float(grid_size - 1)) * 2.0 - 1.0
				var z = (float(z_idx) / float(grid_size - 1)) * 2.0 - 1.0

				var pos = Vector3(x, y, z) * half_size
				var rounded_pos = _apply_rounding(pos, half_size, r)
				
				# Add vertex to SurfaceTool
				# For smooth shading, normal is normalized position (for sphere) or calculated?
				# For a rounded cube, normal is roughly direction from center, but better computed.
				# Let's just add vertex and let SurfaceTool generate normals if we use smooth groups,
				# or compute them. 
				# Actually, for a rounded cube, the normal is simply the direction of the offset from the inner cube center?
				# Let's rely on generate_normals() with smooth groups or index() later.
				# But wait, we want to add vertices explicitly to keep indices.
				
				st.set_uv(Vector2(x * 0.5 + 0.5, y * 0.5 + 0.5)) # Simple UV
				st.add_vertex(rounded_pos)
				
				vertex_grid[Vector3i(x_idx, y_idx, z_idx)] = current_vertex_index
				current_vertex_index += 1

	# 2. Generate Indices (Faces)
	var faces = []
	
	# Helper to add quad
	var add_quad = func(i, j, get_coords):
		var coords0 = get_coords.call(i, j)
		var coords1 = get_coords.call(i + 1, j)
		var coords2 = get_coords.call(i + 1, j + 1)
		var coords3 = get_coords.call(i, j + 1)

		if (vertex_grid.has(coords0) and vertex_grid.has(coords1) and
			vertex_grid.has(coords2) and vertex_grid.has(coords3)):

			var v0 = vertex_grid[coords0]
			var v1 = vertex_grid[coords1]
			var v2 = vertex_grid[coords2]
			var v3 = vertex_grid[coords3]

			# Triangle 1
			st.add_index(v0)
			st.add_index(v1)
			st.add_index(v2)
			
			# Triangle 2
			st.add_index(v0)
			st.add_index(v2)
			st.add_index(v3)

	# Front (+Z)
	for i in range(divs * 2):
		for j in range(divs * 2):
			add_quad.call(i, j, func(u, v): return Vector3i(u, v, grid_size - 1))

	# Back (-Z)
	for i in range(divs * 2):
		for j in range(divs * 2):
			add_quad.call(i, j, func(u, v): return Vector3i(grid_size - 1 - u, v, 0))
			
	# Top (+Y)
	for i in range(divs * 2):
		for j in range(divs * 2):
			add_quad.call(i, j, func(u, v): return Vector3i(u, grid_size - 1, v))

	# Bottom (-Y)
	for i in range(divs * 2):
		for j in range(divs * 2):
			add_quad.call(i, j, func(u, v): return Vector3i(u, 0, grid_size - 1 - v))

	# Right (+X)
	for i in range(divs * 2):
		for j in range(divs * 2):
			add_quad.call(i, j, func(u, v): return Vector3i(grid_size - 1, v, grid_size - 1 - u))

	# Left (-X)
	for i in range(divs * 2):
		for j in range(divs * 2):
			add_quad.call(i, j, func(u, v): return Vector3i(0, v, u))

	st.generate_normals()
	# st.generate_tangents()
	
	var new_mesh = st.commit()
	self.mesh = new_mesh
	
	# Force update physics server
	if is_inside_tree():
		var rid = get_physics_rid()
		if rid.is_valid():
			PhysicsServer3D.soft_body_set_mesh(rid, new_mesh)
			# Reset simulation to ensure it picks up the new shape
			PhysicsServer3D.soft_body_set_total_mass(rid, total_mass)
			PhysicsServer3D.soft_body_set_simulation_precision(rid, simulation_precision)
			PhysicsServer3D.soft_body_set_linear_stiffness(rid, linear_stiffness)
			PhysicsServer3D.soft_body_set_pressure_coefficient(rid, pressure_coefficient)
			PhysicsServer3D.soft_body_set_damping_coefficient(rid, damping_coefficient)
			PhysicsServer3D.soft_body_set_drag_coefficient(rid, drag_coefficient)
	
	_update_material()

func _update_material():
	var mat = StandardMaterial3D.new()
	mat.albedo_color = base_color
	# Add a grid texture or something if desired, but color is fine
	self.material_override = mat

func _apply_rounding(pos: Vector3, half_size: float, r: float) -> Vector3:
	var x_sign = sign(pos.x) if pos.x != 0 else 1
	var y_sign = sign(pos.y) if pos.y != 0 else 1
	var z_sign = sign(pos.z) if pos.z != 0 else 1

	var ax = abs(pos.x)
	var ay = abs(pos.y)
	var az = abs(pos.z)

	var inner = half_size - r

	var cx = clamp(ax, 0, inner)
	var cy = clamp(ay, 0, inner)
	var cz = clamp(az, 0, inner)

	var dx = ax - inner
	var dy = ay - inner
	var dz = az - inner

	if dx > 0 or dy > 0 or dz > 0:
		dx = max(dx, 0)
		dy = max(dy, 0)
		dz = max(dz, 0)

		var dist = sqrt(dx * dx + dy * dy + dz * dz)
		if dist > 0:
			var scale = min(dist, r) / dist
			dx *= scale
			dy *= scale
			dz *= scale

	return Vector3(
		x_sign * (cx + dx),
		y_sign * (cy + dy),
		z_sign * (cz + dz)
	)
