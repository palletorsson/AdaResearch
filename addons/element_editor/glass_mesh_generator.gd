@tool
class_name GlassMeshGenerator
extends RefCounted
## Procedural mesh generation for glass rack elements.
## All elements generated as single continuous bodies.
##
## Glass Rack uses YZ plane:
##   - Grid X → Z axis (horizontal)
##   - Grid Y → Y axis (vertical)
##   - Tubes lie flat in YZ plane (no X depth)

const DEFAULT_TUBE_RADIUS := 0.015
const TUBE_SEGMENTS := 24
const CURVE_SEGMENTS := 36


static func create_glass_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.85, 0.92, 1.0, 0.4)
	mat.metallic = 0.1
	mat.roughness = 0.05
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


static func create_segment(segment_type: String, width: float, height: float, 
		tube_radius: float = DEFAULT_TUBE_RADIUS, mat: Material = null,
		rotation_deg: int = 0) -> Node3D:
	"""
	Create a glass segment.
	width = size[0] * grid_size (horizontal, maps to Z)
	height = size[1] * grid_size (vertical, maps to Y)
	"""
	if mat == null:
		mat = create_glass_material()
	
	var mesh: ArrayMesh = null
	
	match segment_type:
		"straight":
			if rotation_deg == 90 or rotation_deg == 270:
				# Horizontal tube
				mesh = generate_horizontal_tube(width, height, tube_radius)
			else:
				# Vertical tube
				mesh = generate_vertical_tube(width, height, tube_radius)
		"corner":
			mesh = generate_corner(width, height, tube_radius, rotation_deg)
		"corner45":
			mesh = generate_corner45(width, height, tube_radius, rotation_deg)
		"corner_bl":
			mesh = generate_corner(width, height, tube_radius, 180)  # Bottom-left: ╯ top→left
		"corner_br":
			mesh = generate_corner(width, height, tube_radius, 270)  # Bottom-right: ╰ top→right
		"corner_tr":
			mesh = generate_corner(width, height, tube_radius, 0)  # Top-right: ╭ bottom→right
		"corner_tl":
			mesh = generate_corner(width, height, tube_radius, 90)  # Top-left: ╮ bottom→left
		"sbend":
			mesh = generate_sbend(width, height, tube_radius)
		"wobbly":
			mesh = generate_wobbly(width, height, tube_radius)
		"ubend":
			mesh = generate_ubend(width, height, tube_radius)
		"reducer":
			mesh = generate_reducer(width, height, tube_radius, tube_radius * 0.6)
		"junction":
			mesh = generate_t_junction(width, height, tube_radius)
		"ypipe":
			mesh = generate_y_junction(width, height, tube_radius)
		"cross":
			mesh = generate_cross_junction(width, height, tube_radius)
		"spiral":
			mesh = generate_spiral(width, height, tube_radius)
		"condenser":
			mesh = generate_condenser(width, height, tube_radius)
		"flask":
			mesh = generate_flask(width, height, tube_radius)
		"beaker":
			mesh = generate_beaker(width, height)
		"cap":
			mesh = generate_cap(tube_radius, width)
		"drip":
			mesh = generate_drip(tube_radius, width)
		_:
			mesh = generate_vertical_tube(width, height, tube_radius)
	
	var node := Node3D.new()
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = mat
	node.add_child(mesh_instance)
	
	return node


# ============================================================================
# CORE: Tube Sweeping Along Parametric Curve
# ============================================================================

static func sweep_tube_along_curve(curve_func: Callable, t_min: float, t_max: float, 
		tube_radius: float, curve_segments: int = CURVE_SEGMENTS, 
		tube_segments: int = TUBE_SEGMENTS) -> ArrayMesh:
	"""Generate tube by sweeping circle along parametric curve."""
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var t_step := (t_max - t_min) / float(curve_segments)
	var rings: Array[PackedVector3Array] = []
	var ring_normals: Array[PackedVector3Array] = []
	var prev_normal := Vector3.ZERO
	
	for i in range(curve_segments + 1):
		var t := t_min + i * t_step
		var center: Vector3 = curve_func.call(t)
		
		# Numerical tangent
		var dt := t_step * 0.01
		var p_next: Vector3 = curve_func.call(minf(t + dt, t_max))
		var p_prev: Vector3 = curve_func.call(maxf(t - dt, t_min))
		var tangent := (p_next - p_prev).normalized()
		
		if tangent.length_squared() < 0.001:
			tangent = Vector3.UP
		
		# Build perpendicular frame (minimize twist)
		var normal: Vector3
		var binormal: Vector3
		
		if prev_normal == Vector3.ZERO:
			# First point: use X axis as reference (perpendicular to YZ plane)
			var ref := Vector3.RIGHT
			normal = tangent.cross(ref)
			if normal.length_squared() < 0.001:
				ref = Vector3.UP
				normal = tangent.cross(ref)
			normal = normal.normalized()
		else:
			normal = prev_normal - tangent * tangent.dot(prev_normal)
			if normal.length_squared() < 0.001:
				normal = prev_normal
			else:
				normal = normal.normalized()
		
		binormal = tangent.cross(normal).normalized()
		prev_normal = normal
		
		# Generate ring
		var ring := PackedVector3Array()
		var normals := PackedVector3Array()
		
		for j in range(tube_segments + 1):
			var angle := (float(j) / tube_segments) * TAU
			var offset := (normal * cos(angle) + binormal * sin(angle))
			ring.append(center + offset * tube_radius)
			normals.append(offset)
		
		rings.append(ring)
		ring_normals.append(normals)
	
	# Connect rings
	for i in range(curve_segments):
		for j in range(tube_segments):
			var v0 := rings[i][j]
			var v1 := rings[i + 1][j]
			var v2 := rings[i + 1][j + 1]
			var v3 := rings[i][j + 1]
			
			var n0 := ring_normals[i][j]
			var n1 := ring_normals[i + 1][j]
			var n2 := ring_normals[i + 1][j + 1]
			var n3 := ring_normals[i][j + 1]
			
			st.set_normal(n0); st.add_vertex(v0)
			st.set_normal(n1); st.add_vertex(v1)
			st.set_normal(n2); st.add_vertex(v2)
			
			st.set_normal(n0); st.add_vertex(v0)
			st.set_normal(n2); st.add_vertex(v2)
			st.set_normal(n3); st.add_vertex(v3)
	
	st.generate_tangents()
	return st.commit()


# ============================================================================
# TUBES - Straight segments
# ============================================================================

static func generate_vertical_tube(width: float, height: float, radius: float) -> ArrayMesh:
	"""Vertical tube from Y=0 to Y=height, centered at Z=width/2."""
	var center_z := width / 2.0
	var curve := func(t: float) -> Vector3:
		return Vector3(0, t * height, center_z)
	return sweep_tube_along_curve(curve, 0.0, 1.0, radius, 4, TUBE_SEGMENTS)


static func generate_horizontal_tube(width: float, height: float, radius: float) -> ArrayMesh:
	"""Horizontal tube from Z=0 to Z=width, centered at Y=height/2."""
	var center_y := height / 2.0
	var curve := func(t: float) -> Vector3:
		return Vector3(0, center_y, t * width)
	return sweep_tube_along_curve(curve, 0.0, 1.0, radius, 4, TUBE_SEGMENTS)


# ============================================================================
# BENDS - Corner, S-bend, U-bend
# ============================================================================

static func generate_corner(width: float, height: float, radius: float, rotation_deg: int = 0) -> ArrayMesh:
	"""
	90° corner elbow filling a 2x2 grid cell.
	The corner connects the CENTER of one edge to the CENTER of an adjacent edge.
	
	  ╭ (0°):   bottom-center to right-center
	  ╮ (90°):  bottom-center to left-center
	  ╯ (180°): top-center to left-center
	  ╰ (270°): top-center to right-center
	"""
	var arc_radius := minf(width, height) / 2.0
	var center_y := height / 2.0
	var center_z := width / 2.0
	
	var curve: Callable
	
	match rotation_deg:
		0:  # ╭ Bottom to right
			# Arc from (0, 0, w/2) to (0, h/2, w)
			# Center at (0, h/2, w/2), goes from -90° to 0°
			curve = func(t: float) -> Vector3:
				var angle := (-PI/2.0) + t * (PI/2.0)  # -90° to 0°
				return Vector3(0, center_y + arc_radius * sin(angle), center_z + arc_radius * cos(angle))
		
		90:  # ╮ Bottom to left
			# Arc from (0, 0, w/2) to (0, h/2, 0)
			# Center at (0, h/2, w/2), goes from -90° to 180° (short way = -90° to -180°)
			curve = func(t: float) -> Vector3:
				var angle := (-PI/2.0) - t * (PI/2.0)  # -90° to -180°
				return Vector3(0, center_y + arc_radius * sin(angle), center_z + arc_radius * cos(angle))
		
		180:  # ╯ Top to left
			# Arc from (0, h, w/2) to (0, h/2, 0)
			# Center at (0, h/2, w/2), goes from 90° to 180°
			curve = func(t: float) -> Vector3:
				var angle := (PI/2.0) + t * (PI/2.0)  # 90° to 180°
				return Vector3(0, center_y + arc_radius * sin(angle), center_z + arc_radius * cos(angle))
		
		270, _:  # ╰ Top to right
			# Arc from (0, h, w/2) to (0, h/2, w)
			# Center at (0, h/2, w/2), goes from 90° to 0°
			curve = func(t: float) -> Vector3:
				var angle := (PI/2.0) - t * (PI/2.0)  # 90° to 0°
				return Vector3(0, center_y + arc_radius * sin(angle), center_z + arc_radius * cos(angle))
	
	return sweep_tube_along_curve(curve, 0.0, 1.0, radius, CURVE_SEGMENTS, TUBE_SEGMENTS)


static func generate_corner45(width: float, height: float, radius: float, rotation_deg: int = 0) -> ArrayMesh:
	"""45-degree elbow bend."""
	var arc_radius := maxf(radius * 2.0, minf(width, height) * 0.5)
	var center_z := width / 2.0
	var center_y := arc_radius
	var start_angle := -PI / 2.0
	var end_angle := -PI / 4.0
	
	match rotation_deg:
		90:
			end_angle = -3.0 * PI / 4.0
		180:
			center_y = height - arc_radius
			start_angle = PI / 2.0
			end_angle = 3.0 * PI / 4.0
		270:
			center_y = height - arc_radius
			start_angle = PI / 2.0
			end_angle = PI / 4.0
		_:
			pass
	
	var curve := func(t: float) -> Vector3:
		var angle := lerpf(start_angle, end_angle, t)
		return Vector3(0, center_y + arc_radius * sin(angle), center_z + arc_radius * cos(angle))
	
	return sweep_tube_along_curve(curve, 0.0, 1.0, radius, CURVE_SEGMENTS, TUBE_SEGMENTS)


static func generate_sbend(width: float, height: float, radius: float) -> ArrayMesh:
	"""S-curve: enters at (0, 0, 0), exits at (0, height, width)"""
	var curve := func(t: float) -> Vector3:
		var y := t * height
		var z := width * (0.5 - 0.5 * cos(PI * t))
		return Vector3(0, y, z)
	return sweep_tube_along_curve(curve, 0.0, 1.0, radius, CURVE_SEGMENTS, TUBE_SEGMENTS)


static func generate_wobbly(width: float, height: float, radius: float) -> ArrayMesh:
	"""Vertical tube with sinusoidal horizontal wobble."""
	var center_z := width / 2.0
	var amplitude := maxf(radius * 1.5, width * 0.2)
	var wave_count := maxf(2.0, height / maxf(width * 0.4, 0.001))
	
	var curve := func(t: float) -> Vector3:
		var y := t * height
		var z := center_z + sin(t * TAU * wave_count) * amplitude
		return Vector3(0, y, z)
	
	return sweep_tube_along_curve(curve, 0.0, 1.0, radius, CURVE_SEGMENTS, TUBE_SEGMENTS)


static func generate_ubend(width: float, height: float, radius: float) -> ArrayMesh:
	"""
	U-bend: ∪ shape
	- Two openings at TOP: (0, height, ~radius) and (0, height, width-radius)
	- Curves down to bottom: lowest point near Y=0
	- Spans full width from Z=0 to Z=width
	"""
	# The U is a semicircle in the YZ plane
	var bend_radius := (width - 2*radius) / 2.0  # Radius of the center curve
	var center_z := width / 2.0
	
	var curve := func(t: float) -> Vector3:
		# t goes from 0 to 1
		# Start at left opening (Z = radius), go down and around to right opening (Z = width - radius)
		var angle := PI * t  # 0 to PI (semicircle)
		var y := height - radius - bend_radius * (1.0 - cos(angle))  # Start at top, dip down
		var z := center_z - bend_radius * cos(angle)  # Swing from left to right
		return Vector3(0, maxf(y, radius), z)  # Clamp Y to not go below radius
	
	return sweep_tube_along_curve(curve, 0.0, 1.0, radius, CURVE_SEGMENTS, TUBE_SEGMENTS)


static func generate_reducer(width: float, height: float, radius_in: float, radius_out: float) -> ArrayMesh:
	"""Conical reducer transitioning from a larger to a smaller radius."""
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var center_z := width / 2.0
	var bottom_r := minf(absf(radius_in), width * 0.45)
	var top_r := minf(absf(radius_out), width * 0.45)
	
	for i in range(TUBE_SEGMENTS):
		var t0 := float(i) / TUBE_SEGMENTS
		var t1 := float(i + 1) / TUBE_SEGMENTS
		var theta0 := t0 * TAU
		var theta1 := t1 * TAU
		
		var b0 := Vector3(bottom_r * cos(theta0), 0.0, center_z + bottom_r * sin(theta0))
		var b1 := Vector3(bottom_r * cos(theta1), 0.0, center_z + bottom_r * sin(theta1))
		var t0v := Vector3(top_r * cos(theta0), height, center_z + top_r * sin(theta0))
		var t1v := Vector3(top_r * cos(theta1), height, center_z + top_r * sin(theta1))
		
		st.add_vertex(b0)
		st.add_vertex(t0v)
		st.add_vertex(t1v)
		
		st.add_vertex(b0)
		st.add_vertex(t1v)
		st.add_vertex(b1)
	
	st.generate_normals()
	st.generate_tangents()
	return st.commit()


# ============================================================================
# JUNCTIONS - T, Y, Cross
# ============================================================================

static func generate_t_junction(width: float, height: float, radius: float) -> ArrayMesh:
	"""
	T-junction: vertical main tube with horizontal branch.
	- Main tube: Y=0 to Y=height, at Z=width/2
	- Branch: from center toward Z=width, at Y=height/2
	"""
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var center_z := width / 2.0
	var center_y := height / 2.0
	
	# Main vertical tube
	var vert_curve := func(t: float) -> Vector3:
		return Vector3(0, t * height, center_z)
	var vert_mesh := sweep_tube_along_curve(vert_curve, 0.0, 1.0, radius, 12, TUBE_SEGMENTS)
	_merge_mesh(st, vert_mesh)
	
	# Horizontal branch
	var horiz_curve := func(t: float) -> Vector3:
		return Vector3(0, center_y, center_z + t * (width/2.0 - radius))
	var horiz_mesh := sweep_tube_along_curve(horiz_curve, 0.0, 1.0, radius, 8, TUBE_SEGMENTS)
	_merge_mesh(st, horiz_mesh)
	
	# Junction sphere
	_add_sphere(st, Vector3(0, center_y, center_z), radius * 1.3)
	
	st.generate_normals()
	st.generate_tangents()
	return st.commit()


static func generate_y_junction(width: float, height: float, radius: float) -> ArrayMesh:
	"""
	Y-junction: stem at bottom, two branches diverging to top corners.
	- Stem: Y=0 to Y=height*0.4, at Z=width/2
	- Left branch: to (0, height, radius)
	- Right branch: to (0, height, width-radius)
	"""
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var center_z := width / 2.0
	var split_y := height * 0.35
	var branch_height := height - split_y
	
	# Stem
	var stem_curve := func(t: float) -> Vector3:
		return Vector3(0, t * split_y, center_z)
	var stem_mesh := sweep_tube_along_curve(stem_curve, 0.0, 1.0, radius, 8, TUBE_SEGMENTS)
	_merge_mesh(st, stem_mesh)
	
	# Left branch - curves from center to left-top
	var left_curve := func(t: float) -> Vector3:
		var y := split_y + t * branch_height
		var z := center_z - t * (center_z - radius)
		return Vector3(0, y, z)
	var left_mesh := sweep_tube_along_curve(left_curve, 0.0, 1.0, radius, 12, TUBE_SEGMENTS)
	_merge_mesh(st, left_mesh)
	
	# Right branch - curves from center to right-top
	var right_curve := func(t: float) -> Vector3:
		var y := split_y + t * branch_height
		var z := center_z + t * (width - radius - center_z)
		return Vector3(0, y, z)
	var right_mesh := sweep_tube_along_curve(right_curve, 0.0, 1.0, radius, 12, TUBE_SEGMENTS)
	_merge_mesh(st, right_mesh)
	
	# Junction sphere
	_add_sphere(st, Vector3(0, split_y, center_z), radius * 1.5)
	
	st.generate_normals()
	st.generate_tangents()
	return st.commit()


static func generate_cross_junction(width: float, height: float, radius: float) -> ArrayMesh:
	"""Cross: vertical + horizontal tubes intersecting at center."""
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var center_z := width / 2.0
	var center_y := height / 2.0
	
	# Vertical tube
	var vert_curve := func(t: float) -> Vector3:
		return Vector3(0, t * height, center_z)
	var vert_mesh := sweep_tube_along_curve(vert_curve, 0.0, 1.0, radius, 12, TUBE_SEGMENTS)
	_merge_mesh(st, vert_mesh)
	
	# Horizontal tube
	var horiz_curve := func(t: float) -> Vector3:
		return Vector3(0, center_y, t * width)
	var horiz_mesh := sweep_tube_along_curve(horiz_curve, 0.0, 1.0, radius, 12, TUBE_SEGMENTS)
	_merge_mesh(st, horiz_mesh)
	
	# Junction sphere
	_add_sphere(st, Vector3(0, center_y, center_z), radius * 1.5)
	
	st.generate_normals()
	st.generate_tangents()
	return st.commit()


# ============================================================================
# VESSELS
# ============================================================================

static func generate_flask(width: float, height: float, radius: float) -> ArrayMesh:
	"""Round-bottom flask: bulb at bottom, neck at top."""
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var center_z := width / 2.0
	var bulb_radius := width * 0.35
	var bulb_center_y := bulb_radius
	var neck_start_y := bulb_radius * 1.5
	
	# Bulb (sphere-ish)
	_add_sphere(st, Vector3(0, bulb_center_y, center_z), bulb_radius)
	
	# Neck tube
	var neck_curve := func(t: float) -> Vector3:
		return Vector3(0, neck_start_y + t * (height - neck_start_y), center_z)
	var neck_mesh := sweep_tube_along_curve(neck_curve, 0.0, 1.0, radius, 6, TUBE_SEGMENTS)
	_merge_mesh(st, neck_mesh)
	
	st.generate_normals()
	st.generate_tangents()
	return st.commit()


static func generate_beaker(width: float, height: float) -> ArrayMesh:
	"""Open beaker - tapered cylinder."""
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var center_z := width / 2.0
	var bottom_radius := width * 0.35
	var top_radius := width * 0.4
	var segments := TUBE_SEGMENTS
	var rings := 12
	
	for i in range(rings):
		var t1 := float(i) / rings
		var t2 := float(i + 1) / rings
		var r1 := lerpf(bottom_radius, top_radius, t1)
		var r2 := lerpf(bottom_radius, top_radius, t2)
		var y1 := t1 * height * 0.9
		var y2 := t2 * height * 0.9
		
		for j in range(segments):
			var theta1 := (float(j) / segments) * TAU
			var theta2 := (float(j + 1) / segments) * TAU
			
			var v0 := Vector3(r1 * cos(theta1), y1, center_z + r1 * sin(theta1))
			var v1 := Vector3(r1 * cos(theta2), y1, center_z + r1 * sin(theta2))
			var v2 := Vector3(r2 * cos(theta2), y2, center_z + r2 * sin(theta2))
			var v3 := Vector3(r2 * cos(theta1), y2, center_z + r2 * sin(theta1))
			
			st.add_vertex(v0)
			st.add_vertex(v1)
			st.add_vertex(v2)
			
			st.add_vertex(v0)
			st.add_vertex(v2)
			st.add_vertex(v3)
	
	st.generate_normals()
	st.generate_tangents()
	return st.commit()


static func generate_spiral(width: float, height: float, radius: float) -> ArrayMesh:
	"""Spiral coil condenser."""
	var coil_radius := width * 0.3
	var center_z := width / 2.0
	var turns := 4.0
	
	var curve := func(t: float) -> Vector3:
		var angle := t * turns * TAU
		return Vector3(
			coil_radius * cos(angle),
			t * height,
			center_z + coil_radius * sin(angle)
		)
	
	return sweep_tube_along_curve(curve, 0.0, 1.0, radius, int(turns * 16), TUBE_SEGMENTS)


static func generate_condenser(width: float, height: float, radius: float) -> ArrayMesh:
	"""Jacketed condenser: inner tube + outer jacket."""
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var center_z := width / 2.0
	var jacket_radius := radius * 2.5
	var jacket_height := height * 0.7
	var jacket_start := height * 0.15
	
	# Inner tube
	var inner := sweep_tube_along_curve(
		func(t: float) -> Vector3: return Vector3(0, t * height, center_z),
		0.0, 1.0, radius, 8, TUBE_SEGMENTS)
	_merge_mesh(st, inner)
	
	# Outer jacket
	var jacket := sweep_tube_along_curve(
		func(t: float) -> Vector3: return Vector3(0, jacket_start + t * jacket_height, center_z),
		0.0, 1.0, jacket_radius, 8, TUBE_SEGMENTS)
	_merge_mesh(st, jacket)
	
	st.generate_normals()
	st.generate_tangents()
	return st.commit()


# ============================================================================
# TERMINALS
# ============================================================================

static func generate_cap(radius: float, width: float) -> ArrayMesh:
	"""Hemisphere cap."""
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var center_z := width / 2.0
	_add_hemisphere(st, Vector3(0, 0, center_z), radius * 1.2, true)
	
	st.generate_normals()
	st.generate_tangents()
	return st.commit()


static func generate_drip(radius: float, width: float) -> ArrayMesh:
	"""Tapered drip tip."""
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var center_z := width / 2.0
	var length := radius * 5.0
	var tip_radius := radius * 0.3
	var segments := TUBE_SEGMENTS
	var rings := 8
	
	for i in range(rings):
		var t1 := float(i) / rings
		var t2 := float(i + 1) / rings
		var r1 := lerpf(radius, tip_radius, t1)
		var r2 := lerpf(radius, tip_radius, t2)
		var y1 := -t1 * length
		var y2 := -t2 * length
		
		for j in range(segments):
			var theta1 := (float(j) / segments) * TAU
			var theta2 := (float(j + 1) / segments) * TAU
			
			var v0 := Vector3(r1 * cos(theta1), y1, center_z + r1 * sin(theta1))
			var v1 := Vector3(r1 * cos(theta2), y1, center_z + r1 * sin(theta2))
			var v2 := Vector3(r2 * cos(theta2), y2, center_z + r2 * sin(theta2))
			var v3 := Vector3(r2 * cos(theta1), y2, center_z + r2 * sin(theta1))
			
			st.add_vertex(v0)
			st.add_vertex(v1)
			st.add_vertex(v2)
			
			st.add_vertex(v0)
			st.add_vertex(v2)
			st.add_vertex(v3)
	
	st.generate_normals()
	st.generate_tangents()
	return st.commit()


# ============================================================================
# HELPERS
# ============================================================================

static func _merge_mesh(st: SurfaceTool, mesh: ArrayMesh) -> void:
	if mesh.get_surface_count() == 0:
		return
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for v in vertices:
		st.add_vertex(v)


static func _add_sphere(st: SurfaceTool, center: Vector3, radius: float) -> void:
	var rings := 12
	var segments := TUBE_SEGMENTS
	
	for i in range(rings):
		var phi1 := (float(i) / rings) * PI
		var phi2 := (float(i + 1) / rings) * PI
		
		for j in range(segments):
			var theta1 := (float(j) / segments) * TAU
			var theta2 := (float(j + 1) / segments) * TAU
			
			var v0 := center + _sphere_point(radius, phi1, theta1)
			var v1 := center + _sphere_point(radius, phi1, theta2)
			var v2 := center + _sphere_point(radius, phi2, theta2)
			var v3 := center + _sphere_point(radius, phi2, theta1)
			
			st.add_vertex(v0)
			st.add_vertex(v1)
			st.add_vertex(v2)
			
			st.add_vertex(v0)
			st.add_vertex(v2)
			st.add_vertex(v3)


static func _add_hemisphere(st: SurfaceTool, center: Vector3, radius: float, bottom: bool) -> void:
	var rings := 8
	var segments := TUBE_SEGMENTS
	
	for i in range(rings):
		var phi1 := (float(i) / rings) * PI / 2.0
		var phi2 := (float(i + 1) / rings) * PI / 2.0
		if bottom:
			phi1 = PI / 2.0 + phi1
			phi2 = PI / 2.0 + phi2
		
		for j in range(segments):
			var theta1 := (float(j) / segments) * TAU
			var theta2 := (float(j + 1) / segments) * TAU
			
			var v0 := center + _sphere_point(radius, phi1, theta1)
			var v1 := center + _sphere_point(radius, phi1, theta2)
			var v2 := center + _sphere_point(radius, phi2, theta2)
			var v3 := center + _sphere_point(radius, phi2, theta1)
			
			st.add_vertex(v0)
			st.add_vertex(v1)
			st.add_vertex(v2)
			
			st.add_vertex(v0)
			st.add_vertex(v2)
			st.add_vertex(v3)


static func _sphere_point(radius: float, phi: float, theta: float) -> Vector3:
	return Vector3(
		radius * sin(phi) * cos(theta),
		radius * cos(phi),
		radius * sin(phi) * sin(theta)
	)
