# hole_with_cones.gd - Construction site scene with hole and traffic cones
# A ground plane with a circular hole and 3 traffic cones around it
extends Node3D

# @identity
# essence: ground_plane - circular_hole + 3_cones_at_120° — absence as geometry: topology through subtraction
# desire: learner understands that holes are defined by what surrounds them, not what fills them
# critical_parameter: hole_segments — how many triangles fan-triangulate the circular boundary of the hole
# triggers: nothing — static environment piece; experienced by walking around and looking into the hole
# emerges: the concept of Boolean subtraction — the hole is real space defined by its edge, not its missing content
# needs: [missing VR controls — static environment object]
# relationships: demonstrates Boolean difference concept; precursor to boolean_tunnel in transformation sequence
# truth: a hole is not the absence of matter — it is a boundary condition imposed on surrounding matter

@export var ground_size: float = 4.0  # Size of ground plane
@export var hole_radius: float = 0.6  # Radius of the hole
@export var ground_color: Color = Color(0.3, 0.3, 0.35)  # Asphalt gray
@export var cone_distance: float = 0.9  # Distance of cones from hole center

var _ground_mesh: MeshInstance3D
var _cones: Array[Node3D] = []

func _ready():
	_build_scene()

func _build_scene():
	# Clean up existing
	for child in get_children():
		child.queue_free()
	_cones.clear()

	# Build ground with hole
	_build_ground_with_hole()

	# Add three traffic cones around the hole
	_add_traffic_cones()

	# Add collision for ground (not the hole)
	_create_ground_collision()

func _build_ground_with_hole():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half = ground_size / 2.0
	var segments = 24  # Segments for the circular hole

	# Create ground as triangles radiating from hole edge to corners/edges
	# We'll divide the ground into sectors and create triangles

	# First, create vertices for hole edge
	var hole_vertices: Array[Vector3] = []
	for i in range(segments):
		var angle = i * TAU / segments
		hole_vertices.append(Vector3(cos(angle) * hole_radius, 0, sin(angle) * hole_radius))

	# Corner vertices
	var corners = [
		Vector3(-half, 0, -half),  # 0: back-left
		Vector3(half, 0, -half),   # 1: back-right
		Vector3(half, 0, half),    # 2: front-right
		Vector3(-half, 0, half)    # 3: front-left
	]

	# Edge midpoints
	var edges = [
		Vector3(0, 0, -half),  # back
		Vector3(half, 0, 0),   # right
		Vector3(0, 0, half),   # front
		Vector3(-half, 0, 0)   # left
	]

	# For each hole segment, create triangle(s) to appropriate boundary
	for i in range(segments):
		var h0 = hole_vertices[i]
		var h1 = hole_vertices[(i + 1) % segments]

		# Determine which section of ground this segment faces
		var angle = (i + 0.5) * TAU / segments
		var sector = int((angle + PI/4) / (PI/2)) % 4  # 0=right, 1=front, 2=left, 3=back

		# Get the outer point(s) for this sector
		var outer_point: Vector3
		match sector:
			0:  # Right side (angle 315-45 deg)
				outer_point = edges[1]  # right edge
			1:  # Front side (angle 45-135 deg)
				outer_point = edges[2]  # front edge
			2:  # Left side (angle 135-225 deg)
				outer_point = edges[3]  # left edge
			3:  # Back side (angle 225-315 deg)
				outer_point = edges[0]  # back edge

		# Create triangle from hole edge to outer
		st.set_color(ground_color)
		st.set_normal(Vector3.UP)
		st.add_vertex(h0)
		st.add_vertex(h1)
		st.add_vertex(outer_point)

	# Fill in the corners - triangles from edge midpoints to corners
	# Back-right corner
	st.set_normal(Vector3.UP)
	st.add_vertex(edges[0])  # back mid
	st.add_vertex(corners[1])  # back-right
	st.add_vertex(edges[1])  # right mid

	# Front-right corner
	st.add_vertex(edges[1])
	st.add_vertex(corners[2])
	st.add_vertex(edges[2])

	# Front-left corner
	st.add_vertex(edges[2])
	st.add_vertex(corners[3])
	st.add_vertex(edges[3])

	# Back-left corner
	st.add_vertex(edges[3])
	st.add_vertex(corners[0])
	st.add_vertex(edges[0])

	_ground_mesh = MeshInstance3D.new()
	_ground_mesh.mesh = st.commit()
	_ground_mesh.name = "GroundMesh"

	var material = StandardMaterial3D.new()
	material.albedo_color = ground_color
	material.roughness = 0.9
	_ground_mesh.material_override = material

	add_child(_ground_mesh)

	# Add hole edge ring for visual effect
	_add_hole_edge(hole_vertices)

func _add_hole_edge(hole_vertices: Array[Vector3]):
	# Create a dark ring around the hole edge
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var edge_width = 0.05
	var edge_depth = 0.1

	for i in range(hole_vertices.size()):
		var h0 = hole_vertices[i]
		var h1 = hole_vertices[(i + 1) % hole_vertices.size()]

		# Inner edge (down into hole)
		var h0_inner = h0 + Vector3(0, -edge_depth, 0)
		var h1_inner = h1 + Vector3(0, -edge_depth, 0)

		# Create vertical face going down
		st.set_color(Color(0.1, 0.1, 0.1))  # Dark edge
		var normal = (h0 - Vector3.ZERO).normalized()  # Point inward
		st.set_normal(-normal)
		st.add_vertex(h0)
		st.add_vertex(h1)
		st.add_vertex(h1_inner)
		st.add_vertex(h0)
		st.add_vertex(h1_inner)
		st.add_vertex(h0_inner)

	var edge_mesh = MeshInstance3D.new()
	edge_mesh.mesh = st.commit()
	edge_mesh.name = "HoleEdge"

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.1, 0.1, 0.1)
	edge_mesh.material_override = material

	add_child(edge_mesh)

func _add_traffic_cones():
	# Load traffic cone scene
	var cone_scene = load("res://commons/primitives/trafficcone/trafficcone.tscn")
	if not cone_scene:
		push_warning("Traffic cone scene not found")
		return

	# Place 3 cones around the hole at 120 degree intervals
	for i in range(3):
		var angle = i * TAU / 3.0 + PI/6  # Offset by 30 degrees
		var pos = Vector3(cos(angle) * cone_distance, 0, sin(angle) * cone_distance)

		var cone = cone_scene.instantiate()
		cone.position = pos
		# Rotate cone to face slightly toward hole center
		cone.rotation.y = angle + PI
		add_child(cone)
		_cones.append(cone)

func _create_ground_collision():
	var static_body = StaticBody3D.new()
	static_body.name = "GroundCollision"
	add_child(static_body)

	var half = ground_size / 2.0

	# Create 4 box collisions around the hole (not covering the hole)
	# This creates a ground you can walk on but fall through the hole

	var box_width = (ground_size - hole_radius * 2) / 2.0

	# Right side
	var right_col = CollisionShape3D.new()
	var right_box = BoxShape3D.new()
	right_box.size = Vector3(box_width, 0.1, ground_size)
	right_col.shape = right_box
	right_col.position = Vector3(half - box_width/2, -0.05, 0)
	static_body.add_child(right_col)

	# Left side
	var left_col = CollisionShape3D.new()
	var left_box = BoxShape3D.new()
	left_box.size = Vector3(box_width, 0.1, ground_size)
	left_col.shape = left_box
	left_col.position = Vector3(-half + box_width/2, -0.05, 0)
	static_body.add_child(left_col)

	# Front (between hole and edge)
	var front_col = CollisionShape3D.new()
	var front_box = BoxShape3D.new()
	front_box.size = Vector3(hole_radius * 2, 0.1, box_width)
	front_col.shape = front_box
	front_col.position = Vector3(0, -0.05, half - box_width/2)
	static_body.add_child(front_col)

	# Back
	var back_col = CollisionShape3D.new()
	var back_box = BoxShape3D.new()
	back_box.size = Vector3(hole_radius * 2, 0.1, box_width)
	back_col.shape = back_box
	back_col.position = Vector3(0, -0.05, -half + box_width/2)
	static_body.add_child(back_col)
