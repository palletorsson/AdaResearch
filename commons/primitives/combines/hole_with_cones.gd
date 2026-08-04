# hole_with_cones.gd - Construction site scene with hole and traffic cones
# A ground plane with a circular hole and 3 traffic cones around it
extends Node3D

# @identity
# essence: ground_plane - circular_hole + 3_cones_at_120° — absence as geometry: topology through subtraction
# desire: learner understands that holes are defined by what surrounds them, not what fills them
# critical_parameter: cordon — how the absence is declared to the next person (cones / tape / barrier / none / covered). Under it, hole_segments: how many triangles fan-triangulate the circular boundary of the hole
# triggers: nothing — static environment piece; experienced by walking around and looking into the hole
# emerges: the concept of Boolean subtraction — the hole is real space defined by its edge, not its missing content
# needs: [missing VR controls — static environment object]
# relationships: demonstrates Boolean difference concept; precursor to boolean_tunnel in transformation sequence
# truth: a hole is not the absence of matter — it is a boundary condition imposed on surrounding matter

@export var ground_size: float = 4.0  # Size of ground plane
@export var hole_radius: float = 0.6  # Radius of the hole
@export var ground_color: Color = Color(0.3, 0.3, 0.35)  # Asphalt gray
@export var cone_distance: float = 0.9  # Distance of cones from hole center

# ── STAGE-2 DNA — promoted 2026-08-03 ─────────────────────────────────
#
# `cordon` — how the absence is declared.
#
# The hole is the artifact; the cones are the SPEECH ACT about the hole, and
# they were welded to it. Three plastic pylons at 120 degrees are one answer to
# "a danger exists here, tell the next person" and the object could give no
# other. Every value below leaves the hole exactly where it is and changes only
# what the site says about it — which is the whole of the artifact's argument,
# because a hazard is not what is missing but what the surrounding matter has
# been made to announce.
#
#   cones     the shipped site. Three traffic cones, 120 degrees apart, 30
#             degrees offset, each turned to face the pit. Portable, provisional,
#             stackable: a warning that expects to be taken away again.
#   tape      three posts and a taut ribbon between them. A LINE, not an
#             obstacle — it stops nobody and it is not trying to. The perimeter
#             is drawn and the rest is left to you.
#   barrier   a continuous hoarding right round the pit. The warning has become
#             a wall: no longer addressed to your judgement, it simply removes
#             the choice. What is safe and what is permitted stop being separate.
#   none      the hole, unmarked. The danger is entirely real and says nothing.
#             The floor looks like floor until you are in it — the control case
#             that shows the other four were all speech, not geometry.
#   covered   a steel plate over the pit. The most common answer on a real site
#             and the most double-edged: the hazard is not declared but SEALED,
#             the ground reads whole, and the absence has been made invisible
#             rather than safe. Marking and concealing are the same gesture done
#             one step further.
@export_enum("cones", "tape", "barrier", "none", "covered") var cordon: String = "cones"

## The same list as the @export_enum above. The enum is what the editor and the
## declaration gate read; this is what an incoming map token is checked against.
const CORDON_VALUES: Array[String] = ["cones", "tape", "barrier", "none", "covered"]

var _ground_mesh: MeshInstance3D
var _cones: Array[Node3D] = []
var _built: bool = false

func _ready():
	_build_scene()

func _build_scene():
	# Clean up existing. remove_child as well as queue_free: on a REBUILD the
	# freed nodes would otherwise still be in the tree for the rest of the frame
	# and the new ground would be laid on top of the old one. At _ready the
	# scene has no children, so this is a no-op there.
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_cones.clear()

	# Build ground with hole
	_build_ground_with_hole()

	# Declare the hazard — or don't. Default "cones" is the shipped site.
	_build_cordon()

	# Add collision for ground (not the hole)
	_create_ground_collision()
	_built = true

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

## Dispatch on the declaration. "none" builds nothing on purpose.
func _build_cordon() -> void:
	match cordon:
		"cones":
			_add_traffic_cones()
		"tape":
			_add_tape_line()
		"barrier":
			_add_barrier_ring()
		"covered":
			_add_cover_plate()
		"none":
			pass


## Three posts and a ribbon: the perimeter drawn, nothing blocked. Posts stand
## where the cones stood, so the two values are the same claim at different
## strengths.
func _add_tape_line() -> void:
	var post_mat := StandardMaterial3D.new()
	post_mat.albedo_color = Color(0.82, 0.82, 0.86)
	post_mat.metallic = 0.4
	post_mat.roughness = 0.5

	var tape_mat := StandardMaterial3D.new()
	tape_mat.albedo_color = Color(0.95, 0.75, 0.05)
	tape_mat.emission_enabled = true
	tape_mat.emission = Color(0.95, 0.75, 0.05)
	tape_mat.emission_energy_multiplier = 0.35
	tape_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	tape_mat.roughness = 0.8

	var post_h: float = 0.72
	var pts: Array[Vector3] = []
	for i in range(3):
		var angle: float = float(i) * TAU / 3.0 + PI / 6.0
		pts.append(Vector3(cos(angle) * cone_distance, 0.0, sin(angle) * cone_distance))

	for i in range(pts.size()):
		var post := MeshInstance3D.new()
		post.name = "TapePost%d" % i
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.022
		cyl.bottom_radius = 0.03
		cyl.height = post_h
		cyl.radial_segments = 8
		post.mesh = cyl
		post.material_override = post_mat
		post.position = pts[i] + Vector3(0, post_h * 0.5, 0)
		add_child(post)

	for i in range(pts.size()):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[(i + 1) % pts.size()]
		var ribbon := MeshInstance3D.new()
		ribbon.name = "Tape%d" % i
		var bm := BoxMesh.new()
		bm.size = Vector3(a.distance_to(b), 0.09, 0.006)
		ribbon.mesh = bm
		ribbon.material_override = tape_mat
		ribbon.position = (a + b) * 0.5 + Vector3(0, post_h * 0.82, 0)
		# Box's long axis is +X; a spin about Y sends +X to (cos, -sin) in XZ.
		ribbon.rotation = Vector3(0.0, atan2(a.z - b.z, b.x - a.x), 0.0)
		add_child(ribbon)


## A continuous hoarding: the warning become a wall. Twelve tangential panels,
## which reads as a ring at any distance a player meets it from.
func _add_barrier_ring() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.88, 0.34, 0.07)
	mat.roughness = 0.75

	var panels: int = 12
	var wall_h: float = 0.58
	var radius: float = cone_distance
	var span: float = TAU * radius / float(panels) * 1.04

	for i in range(panels):
		var angle: float = float(i) * TAU / float(panels)
		var panel := MeshInstance3D.new()
		panel.name = "BarrierPanel%d" % i
		var bm := BoxMesh.new()
		bm.size = Vector3(span, wall_h, 0.05)
		panel.mesh = bm
		panel.material_override = mat
		panel.position = Vector3(cos(angle) * radius, wall_h * 0.5, sin(angle) * radius)
		# +X must lie along the tangent (-sin, cos): a spin of -(angle + 90) about Y.
		panel.rotation = Vector3(0.0, -(angle + PI * 0.5), 0.0)
		add_child(panel)


## The plate. The hazard is not announced but sealed, and the ground reads
## whole — so the collision has to agree with the picture, or the artifact would
## be lying in one sense and telling the truth in the other.
func _add_cover_plate() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.34, 0.34, 0.37)
	mat.metallic = 0.6
	mat.roughness = 0.45

	var plate := MeshInstance3D.new()
	plate.name = "HoleCover"
	var cm := CylinderMesh.new()
	cm.top_radius = hole_radius * 1.1
	cm.bottom_radius = hole_radius * 1.1
	cm.height = 0.04
	cm.radial_segments = 32
	plate.mesh = cm
	plate.material_override = mat
	plate.position = Vector3(0, 0.02, 0)
	add_child(plate)

	var body := StaticBody3D.new()
	body.name = "CoverCollision"
	add_child(body)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(hole_radius * 2.2, 0.04, hole_radius * 2.2)
	col.shape = box
	col.position = Vector3(0, 0.02, 0)
	body.add_child(col)


## Accept an axis value only if it names a declaration we actually build.
func _pick_axis(raw: String, allowed: Array[String], fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## Contract: this runs AFTER _ready(), deferred from GridInteractablesComponent,
## and curation_station calls it on artifacts it has just framed with keys this
## object has never heard of. There was no apply_grid_config here before, so
## EVERY key was ignored; the only one that is not ignored now is `cordon`, and
## only when it names a different declaration than the one already built. All
## ten placements pass no config at all, so none of them moves.
func apply_grid_config(config_data: Dictionary) -> void:
	if not config_data.has("cordon"):
		return
	var c: String = _pick_axis(str(config_data["cordon"]), CORDON_VALUES, cordon)
	if c == cordon:
		return
	cordon = c
	if not _built:
		return   # _ready has not run yet; it will build with this value.
	_build_scene()

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
