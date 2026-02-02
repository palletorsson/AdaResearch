extends Node3D
class_name AudioControllerCableCase

## Cable Case decoration for AudioController
## Creates decorative patch cables around the rack frame like a modular synth

@export var cable_thickness: float = 0.012
@export var cable_color: Color = Color(0.1, 0.1, 0.12)
@export var accent_color: Color = Color(0.2, 0.6, 0.9)
@export var jack_color: Color = Color(0.15, 0.15, 0.18)
@export var glow_intensity: float = 0.3
@export var frame_width: float = 0.52
@export var frame_height: float = 0.52
@export var frame_depth: float = 0.06
@export var tube_sides: int = 8
@export var spline_resolution: int = 12

# Corner jack positions (for patch cable look)
var corner_jacks: Array[MeshInstance3D] = []
var frame_cables: Array[MeshInstance3D] = []

func _ready():
	_create_frame()
	_create_corner_jacks()
	_create_decorative_cables()

func _create_frame():
	"""Create the outer cable frame around the rack"""
	var half_w = frame_width / 2.0
	var half_h = frame_height / 2.0
	var z_front = frame_depth / 2.0 + 0.01

	# Frame corners (for cable routing)
	var corners = [
		Vector3(-half_w, half_h, z_front),   # Top-left
		Vector3(half_w, half_h, z_front),    # Top-right
		Vector3(half_w, -half_h, z_front),   # Bottom-right
		Vector3(-half_w, -half_h, z_front),  # Bottom-left
	]

	# Create frame rails (cables running along edges)
	_create_cable_segment(corners[0], corners[1], accent_color)  # Top
	_create_cable_segment(corners[1], corners[2], cable_color)   # Right
	_create_cable_segment(corners[2], corners[3], accent_color)  # Bottom
	_create_cable_segment(corners[3], corners[0], cable_color)   # Left

func _create_corner_jacks():
	"""Create jack connectors at corners"""
	var half_w = frame_width / 2.0
	var half_h = frame_height / 2.0
	var z_front = frame_depth / 2.0 + 0.015

	var jack_positions = [
		Vector3(-half_w, half_h, z_front),
		Vector3(half_w, half_h, z_front),
		Vector3(half_w, -half_h, z_front),
		Vector3(-half_w, -half_h, z_front),
	]

	for pos in jack_positions:
		var jack = _create_jack(pos)
		corner_jacks.append(jack)

func _create_jack(pos: Vector3) -> MeshInstance3D:
	"""Create a single jack connector"""
	var jack = MeshInstance3D.new()
	jack.name = "Jack"

	# Outer ring
	var torus = TorusMesh.new()
	torus.inner_radius = 0.015
	torus.outer_radius = 0.022
	torus.rings = 12
	torus.ring_segments = 16
	jack.mesh = torus

	var mat = StandardMaterial3D.new()
	mat.albedo_color = jack_color
	mat.metallic = 0.9
	mat.roughness = 0.2
	jack.material_override = mat

	jack.position = pos
	jack.rotation_degrees.x = 90  # Face forward
	add_child(jack)

	# Inner socket
	var socket = MeshInstance3D.new()
	socket.name = "Socket"
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.01
	cyl.bottom_radius = 0.01
	cyl.height = 0.015
	socket.mesh = cyl

	var socket_mat = StandardMaterial3D.new()
	socket_mat.albedo_color = Color(0.05, 0.05, 0.05)
	socket_mat.metallic = 1.0
	socket_mat.roughness = 0.1
	socket.material_override = socket_mat

	socket.rotation_degrees.x = 90
	jack.add_child(socket)

	return jack

func _create_decorative_cables():
	"""Create decorative patch cables connecting various points"""
	var half_w = frame_width / 2.0
	var half_h = frame_height / 2.0
	var z_front = frame_depth / 2.0 + 0.02

	# Decorative cable 1: Top-left to middle-right (accent color, sagging)
	var cable1_start = Vector3(-half_w + 0.05, half_h - 0.02, z_front)
	var cable1_end = Vector3(half_w - 0.02, 0.0, z_front)
	_create_sagging_cable(cable1_start, cable1_end, accent_color, 0.08)

	# Decorative cable 2: Bottom-right corner to bottom-left (dark, tight)
	var cable2_start = Vector3(half_w - 0.05, -half_h + 0.05, z_front)
	var cable2_end = Vector3(-half_w + 0.1, -half_h + 0.03, z_front)
	_create_sagging_cable(cable2_start, cable2_end, cable_color, 0.03)

	# Decorative cable 3: Looping cable on top (visual interest)
	var cable3_start = Vector3(-half_w + 0.15, half_h - 0.02, z_front)
	var cable3_end = Vector3(half_w - 0.15, half_h - 0.02, z_front)
	_create_looping_cable(cable3_start, cable3_end, Color(0.8, 0.2, 0.2), 0.06)

func _create_cable_segment(start: Vector3, end: Vector3, color: Color):
	"""Create a straight cable segment (frame rail)"""
	var cable = MeshInstance3D.new()
	cable.name = "FrameCable"

	var direction = end - start
	var length = direction.length()
	var midpoint = (start + end) / 2.0

	var cyl = CylinderMesh.new()
	cyl.top_radius = cable_thickness
	cyl.bottom_radius = cable_thickness
	cyl.height = length
	cyl.radial_segments = tube_sides
	cable.mesh = cyl

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.3
	mat.roughness = 0.6
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = glow_intensity
	cable.material_override = mat

	cable.position = midpoint

	# Orient cylinder along direction (use Basis.looking_at() - works before node is in tree)
	var dir_norm = direction.normalized()
	if dir_norm != Vector3.UP and dir_norm != Vector3.DOWN:
		cable.basis = Basis.looking_at((end - midpoint).normalized(), Vector3.UP)
		cable.rotate_object_local(Vector3.RIGHT, PI / 2)
	else:
		if direction.y < 0:
			cable.rotation_degrees.x = 180

	add_child(cable)
	frame_cables.append(cable)

func _create_sagging_cable(start: Vector3, end: Vector3, color: Color, sag_amount: float):
	"""Create a cable that sags naturally between two points"""
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var mat = _create_cable_material(color)
	st.set_material(mat)

	# Generate catenary curve points
	var segments = spline_resolution
	var positions: Array[Vector3] = []

	for i in range(segments + 1):
		var t = float(i) / float(segments)
		var pos = start.lerp(end, t)

		# Catenary sag (parabolic approximation)
		var sag = sin(t * PI) * sag_amount
		pos.y -= sag

		# Add slight random variation for organic feel
		pos.z += sin(t * PI * 2.0) * 0.005

		positions.append(pos)

	# Build tube mesh
	_build_tube_mesh(st, positions)

	var mesh = st.commit()
	var cable_mesh = MeshInstance3D.new()
	cable_mesh.name = "SaggingCable"
	cable_mesh.mesh = mesh
	cable_mesh.material_override = mat
	add_child(cable_mesh)

func _create_looping_cable(start: Vector3, end: Vector3, color: Color, loop_height: float):
	"""Create a cable with a decorative loop"""
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var mat = _create_cable_material(color)
	st.set_material(mat)

	var segments = spline_resolution * 2
	var positions: Array[Vector3] = []

	for i in range(segments + 1):
		var t = float(i) / float(segments)
		var pos = start.lerp(end, t)

		# Create loop shape using sine
		var loop = sin(t * PI * 2.0) * loop_height * 0.5
		pos.y += abs(loop)

		# Forward bulge in middle
		pos.z += sin(t * PI) * 0.02

		positions.append(pos)

	_build_tube_mesh(st, positions)

	var mesh = st.commit()
	var cable_mesh = MeshInstance3D.new()
	cable_mesh.name = "LoopingCable"
	cable_mesh.mesh = mesh
	cable_mesh.material_override = mat
	add_child(cable_mesh)

func _build_tube_mesh(st: SurfaceTool, positions: Array[Vector3]):
	"""Build a tube mesh along a series of positions"""
	for i in range(positions.size() - 1):
		var p1 = positions[i]
		var p2 = positions[i + 1]
		var segment_dir = (p2 - p1).normalized()

		# Find perpendicular vectors
		var up = Vector3.UP
		if abs(segment_dir.dot(up)) > 0.9:
			up = Vector3.RIGHT
		var right = segment_dir.cross(up).normalized()
		var forward = right.cross(segment_dir).normalized()

		var uv_x1 = float(i) / float(positions.size() - 1)
		var uv_x2 = float(i + 1) / float(positions.size() - 1)

		# Create tube segment
		for side in range(tube_sides):
			var angle1 = (float(side) / tube_sides) * TAU
			var angle2 = (float(side + 1) / tube_sides) * TAU

			var offset1 = (right * cos(angle1) + forward * sin(angle1)) * cable_thickness
			var offset2 = (right * cos(angle2) + forward * sin(angle2)) * cable_thickness

			# Triangle 1
			st.set_uv(Vector2(uv_x1, float(side) / tube_sides))
			st.add_vertex(p1 + offset1)
			st.set_uv(Vector2(uv_x2, float(side) / tube_sides))
			st.add_vertex(p2 + offset1)
			st.set_uv(Vector2(uv_x2, float(side + 1) / tube_sides))
			st.add_vertex(p2 + offset2)

			# Triangle 2
			st.set_uv(Vector2(uv_x1, float(side) / tube_sides))
			st.add_vertex(p1 + offset1)
			st.set_uv(Vector2(uv_x2, float(side + 1) / tube_sides))
			st.add_vertex(p2 + offset2)
			st.set_uv(Vector2(uv_x1, float(side + 1) / tube_sides))
			st.add_vertex(p1 + offset2)

	st.generate_normals()

func _create_cable_material(color: Color) -> StandardMaterial3D:
	"""Create a material for cables"""
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.2
	mat.roughness = 0.7
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = glow_intensity * 0.5
	return mat

## Public method to update cable colors dynamically
func set_accent_color(color: Color):
	accent_color = color
	# Could rebuild cables with new color if needed
