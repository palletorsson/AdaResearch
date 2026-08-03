# PythagoreanTriangleAngles.gd - Extends Pythagorean demo with Angle emphasis
extends Node3D

# @identity
# essence: a² + b² = c² — the Pythagorean theorem made spatial: three squares grown from triangle sides
# desire: learner sees the theorem not as a formula but as an area relationship — squares fitting together
# critical_parameter: the right angle vertex — fixing it keeps the right angle while the learner explores leg ratios
# triggers: dragging any vertex — hypotenuse square resizes to match the sum of the two leg squares
# emerges: the theorem as a visual conservation law — the big square always equals the two small squares combined
# needs: [has grabbable vertex spheres [has], has formula Label3D (a²+b²≈c²) [has], missing VR angle slider]
# relationships: sibling to triangle; depends on understanding line length; connects to rotation via angles
# truth: the Pythagorean theorem is a statement about areas, not lengths — c² is literally a square

# PythagoreanTriangleAngles.gd - Extends Pythagorean demo with Angle emphasis

var vertex_color: Color = Color(0.2, 0.8, 0.3, 0.7)  # Transparent green marble
@export var sphere_size_multiplier: float = 0.25
@export var sphere_y_offset: float = 0.5  # Base height for interaction
@export var arc_radius: float = 0.3

## Freeze behavior options
@export var alter_freeze : bool = false

## DNA — how much of the proof is on show.
## The shipped exhibit grows three squares from the sides and prints the arithmetic:
## it ASSERTS the theorem. "result" is that exhibit, byte for byte.
##   axiom    the triangle, the right-angle marker and a + b = c in symbols. No squares.
##   result   the three squares and the numbers. The claim made spatial.
##   trace    the two leg squares sheared into equal-area parallelograms leaning along
##            the altitude — the move that carries them toward the hypotenuse square.
##   longhand Euclid I.47: the altitude drawn through, and the hypotenuse square cut
##            into the two rectangles that ARE the leg squares.
@export_enum("result", "trace", "longhand", "axiom") var evidence: String = "result"

const EVIDENCE_VALUES := ["result", "trace", "longhand", "axiom"]

# Mesh instances
var triangle_mesh: MeshInstance3D
var square_a_mesh: MeshInstance3D
var square_b_mesh: MeshInstance3D
var square_c_mesh: MeshInstance3D

var angle_mesh_0: MeshInstance3D # Angle at Vertex 0 (Right angle usually)
var angle_mesh_1: MeshInstance3D
var angle_mesh_2: MeshInstance3D

var drag_points: DragPointSet

# Proof geometry. Built lazily, the first time a value other than result/axiom asks
# for it, so the shipped exhibit has not one extra node in it.
var _proof_root: Node3D
var _shear_a: MeshInstance3D
var _shear_b: MeshInstance3D
var _split_near: MeshInstance3D
var _split_far: MeshInstance3D
var _altitude: MeshInstance3D

# Standing Right Triangle (XY plane)
var vertex_positions: Array[Vector3] = [
	Vector3(-0.5, sphere_y_offset, 0.0),       # Corner (C)
	Vector3(0.5, sphere_y_offset, 0.0),        # Base End (B)
	Vector3(-0.5, sphere_y_offset + 1.0, 0.0)  # Top (A)
]

# Indices for triangle: C, B, A (0, 1, 2)
var triangle_indices: Array[int] = [0, 1, 2]

# Labels
var label_nodes: Dictionary = {}

func _ready():
	drag_points = DragPointSet.new()
	drag_points.name = "DragPoints"
	add_child(drag_points)

	drag_points.point_picked_up.connect(_on_point_picked_up)
	drag_points.point_dropped.connect(_on_point_dropped)
	drag_points.point_moved.connect(_on_point_moved)

	create_meshes()
	_setup_drag_points()
	create_labels()
	
	update_visuals()
	print_help()

func create_meshes():
	# Main Triangle
	triangle_mesh = MeshInstance3D.new()
	triangle_mesh.name = "TriangleMesh"
	apply_material(triangle_mesh, Color.DEEP_PINK)
	add_child(triangle_mesh)
	
	# Squares (A, B, C)
	square_a_mesh = create_vis_mesh("SquareA", Color(0.2, 0.6, 1.0, 0.3))
	square_b_mesh = create_vis_mesh("SquareB", Color(1.0, 0.6, 0.2, 0.3))
	square_c_mesh = create_vis_mesh("SquareC", Color(0.8, 0.2, 1.0, 0.3))
	
	# Angle Arcs
	angle_mesh_0 = create_vis_mesh("AngleArc0", Color.YELLOW)
	angle_mesh_1 = create_vis_mesh("AngleArc1", Color.YELLOW)
	angle_mesh_2 = create_vis_mesh("AngleArc2", Color.YELLOW)

func create_vis_mesh(n: String, c: Color) -> MeshInstance3D:
	var m = MeshInstance3D.new()
	m.name = n
	add_child(m)
	apply_material(m, c)
	return m

func _setup_drag_points():
	var point_configs: Array = []
	for i in range(vertex_positions.size()):
		point_configs.append({
			"id": i,
			"name": "GrabSphere_%d" % i,
			"position": vertex_positions[i],
			"meta": {"vertex_index": i}
		})

	drag_points.setup(point_configs, {
		"default_scale": sphere_size_multiplier,
		"default_color": vertex_color,
		"freeze_on_drop": true,
		"unfreeze_on_pickup": true,
		"alter_freeze": alter_freeze
	})

func create_labels():
	# Side Labels
	create_label("BaseLabel", "a", 24)
	create_label("HeightLabel", "b", 24)
	create_label("HypotenuseLabel", "c", 24)

	# Formula
	var fl = create_label("FormulaLabel", "Equation", 32)
	fl.modulate = Color(1.0, 1.0, 0.5, 1.0)
	
	# Angle Labels
	var al0 = create_label("Angle0", "90Â°", 32)
	al0.modulate = Color.YELLOW
	var al1 = create_label("Angle1", "Angle", 24)
	var al2 = create_label("Angle2", "Angle", 24)

func create_label(n: String, t: String, s: int) -> Label3D:
	var label = Label3D.new()
	label.name = n
	label.text = t
	label.font_size = s
	label.outline_size = 4
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
	label_nodes[n] = label
	return label

func update_visuals():
	update_triangle_mesh()
	update_squares()
	update_angles()
	update_labels()
	_apply_evidence()

func update_labels():
	var lengths = get_side_lengths()
	var a_len = lengths[0]
	var b_len = lengths[1]
	var c_len = lengths[2]

	# Side Labels
	update_label_pos("BaseLabel", "a = %.2f" % a_len, (vertex_positions[0] + vertex_positions[1]) / 2.0 + Vector3(0, -0.2, 0))
	update_label_pos("HeightLabel", "b = %.2f" % b_len, (vertex_positions[0] + vertex_positions[2]) / 2.0 + Vector3(-0.2, 0, 0))
	update_label_pos("HypotenuseLabel", "c = %.2f" % c_len, (vertex_positions[1] + vertex_positions[2]) / 2.0 + Vector3(0.2, 0.2, 0))

	# Formula
	var a_sq = a_len * a_len
	var b_sq = b_len * b_len
	var c_sq = c_len * c_len
	var sum_sq = a_sq + b_sq
	var diff = abs(sum_sq - c_sq)
	var op = "="
	if diff > 0.05: op = "â‰ˆ"
	if diff > 0.5: op = "â‰ "
	
	update_label_pos("FormulaLabel", "aÂ² + bÂ² %s cÂ²\n%.1f + %.1f %s %.1f" % [op, a_sq, b_sq, op, c_sq], 
		(vertex_positions[0] + vertex_positions[1] + vertex_positions[2]) / 3.0 + Vector3(0, 1.5, 0))

	# The shipped formula label is the claim on one line and its arithmetic on the next,
	# and every value but `axiom` leaves both exactly as written above. axiom keeps the
	# first line only: the statement in symbols, with no squares and no sums to check it
	# against. Written as a trim of the shipped text rather than a second literal, so the
	# default cannot drift away from it.
	if evidence == "axiom" and label_nodes.has("FormulaLabel"):
		var claim: String = String(label_nodes["FormulaLabel"].text).split("\n")[0]
		label_nodes["FormulaLabel"].text = claim


func update_label_pos(n: String, t: String, p: Vector3):
	if label_nodes.has(n):
		label_nodes[n].text = t
		label_nodes[n].position = p

func update_angles():
	# Update Arcs and Angle Labels
	update_angle_visual(0, angle_mesh_0, "Angle0", vertex_positions[0], vertex_positions[1], vertex_positions[2])
	update_angle_visual(1, angle_mesh_1, "Angle1", vertex_positions[1], vertex_positions[2], vertex_positions[0])
	update_angle_visual(2, angle_mesh_2, "Angle2", vertex_positions[2], vertex_positions[0], vertex_positions[1])

func update_angle_visual(_idx: int, mesh: MeshInstance3D, label_name: String, center: Vector3, pA: Vector3, pB: Vector3):
	var dirA = (pA - center).normalized()
	var dirB = (pB - center).normalized()
	
	# Calculate Angle (XY Plane)
	# Use atan2 difference for robust angle
	var angle_rad = dirA.angle_to(dirB)
	var deg = rad_to_deg(angle_rad)
	
	# Label
	if label_nodes.has(label_name):
		label_nodes[label_name].text = "%.0fÂ°" % deg
		# Position: Along the bisector
		var bisector = (dirA + dirB).normalized() * (arc_radius + 0.15)
		label_nodes[label_name].position = center + bisector
	
	# Mesh Gen
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var normal = Vector3.BACK
	
	# Is it a right angle? Draw Square
	if abs(deg - 90.0) < 1.0:
		# Draw box
		var s = arc_radius * 0.7
		var p1 = center + dirA * s
		var p2 = center + dirB * s
		var p3 = center + (dirA + dirB).normalized() * (s * 1.414) # Corner
		
		# Box is 2 triangles: Center->P1->P3, Center->P3->P2 ?? No. 
		# Box is C, P1, P3, P2.
		# Triangle 1: C, P1, P3
		# Triangle 2: C, P3, P2
		add_triangle_face(st, center, p1, p3, normal)
		add_triangle_face(st, center, p3, p2, normal)
		add_triangle_face(st, center, p3, p1, -normal)
		add_triangle_face(st, center, p2, p3, -normal)
		
	else:
		# Draw Arc
		var segments = 10
		var current_vec = dirA * arc_radius
		# We need to rotate from dirA to dirB in steps
		# Axis is Z
		# Cross check to Determine rotation direction?
		# A cross B. If Z positive/negative...
		var cross = dirA.cross(dirB)
		var axis = Vector3.BACK if cross.z > 0 else Vector3.FORWARD # Or similar check
		
		# Alternatively, simply interpolate spherical linear?
		# Or generic rotation.
		
		for i in range(segments):
			var t1 = float(i) / segments
			var t2 = float(i+1) / segments
			
			var v1 = dirA.slerp(dirB, t1) * arc_radius
			var v2 = dirA.slerp(dirB, t2) * arc_radius
			
			add_triangle_face(st, center, center + v1, center + v2, normal)
			add_triangle_face(st, center, center + v2, center + v1, -normal)
			
	mesh.mesh = st.commit()

func get_side_lengths() -> Array:
	return [
		vertex_positions[0].distance_to(vertex_positions[1]),
		vertex_positions[0].distance_to(vertex_positions[2]),
		vertex_positions[1].distance_to(vertex_positions[2])
	]

func update_triangle_mesh():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var normal = Vector3.BACK 
	add_triangle_face(st, vertex_positions[0], vertex_positions[1], vertex_positions[2], normal)
	add_triangle_face(st, vertex_positions[0], vertex_positions[2], vertex_positions[1], -normal)
	triangle_mesh.mesh = st.commit()

func update_squares():
	update_square_mesh(square_a_mesh, vertex_positions[0], vertex_positions[1])
	update_square_mesh(square_b_mesh, vertex_positions[2], vertex_positions[0])
	update_square_mesh(square_c_mesh, vertex_positions[1], vertex_positions[2])

func update_square_mesh(mesh_inst: MeshInstance3D, p1: Vector3, p2: Vector3):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var edge = p2 - p1
	var normal = Vector3.BACK
	var perp = Vector3(edge.y, -edge.x, 0.0)
	var p3 = p2 + perp
	var p4 = p1 + perp
	add_triangle_face(st, p1, p2, p4, normal)
	add_triangle_face(st, p2, p3, p4, normal)
	add_triangle_face(st, p1, p4, p2, -normal)
	add_triangle_face(st, p2, p4, p3, -normal)
	mesh_inst.mesh = st.commit()

# ---------------------------------------------------------------------------
# Proof geometry — everything below is reached only by a non-default `evidence`.
# ---------------------------------------------------------------------------

## Which figures are on show for the current value.
##
## The first line is the whole of the default guarantee: at evidence == "result"
## nothing below runs, no proof node is ever constructed, and the three squares keep
## the visibility they were born with.
func _apply_evidence() -> void:
	if evidence == "result" and _proof_root == null:
		return

	var needs_proof: bool = evidence == "trace" or evidence == "longhand"
	if needs_proof and _proof_root == null:
		_create_proof_nodes()

	# result: all three squares, the claim asserted.
	# axiom:  no squares at all — the triangle and the right angle only.
	# trace:  the leg squares have been sheared, so the parallelograms stand in for them.
	# longhand: the hypotenuse square has been cut, so the two rectangles stand in for it.
	square_a_mesh.visible = evidence == "result" or evidence == "longhand"
	square_b_mesh.visible = evidence == "result" or evidence == "longhand"
	square_c_mesh.visible = evidence == "result" or evidence == "trace"

	if _proof_root != null:
		_update_proof_meshes()
		_shear_a.visible = evidence == "trace"
		_shear_b.visible = evidence == "trace"
		_split_near.visible = evidence == "longhand"
		_split_far.visible = evidence == "longhand"
		_altitude.visible = evidence == "longhand"


## Built lazily the first time trace or longhand asks, so a shipped placement has not
## one extra node in its tree. Colours are the leg squares' own, because the argument
## is that these figures ARE those squares.
func _create_proof_nodes() -> void:
	_proof_root = Node3D.new()
	_proof_root.name = "ProofGeometry"
	add_child(_proof_root)

	_shear_a = _create_proof_mesh("ShearA", Color(0.2, 0.6, 1.0, 0.3))
	_shear_b = _create_proof_mesh("ShearB", Color(1.0, 0.6, 0.2, 0.3))
	_split_near = _create_proof_mesh("SplitNear", Color(0.2, 0.6, 1.0, 0.3))
	_split_far = _create_proof_mesh("SplitFar", Color(1.0, 0.6, 0.2, 0.3))
	_altitude = _create_proof_mesh("Altitude", Color(1.0, 1.0, 0.5, 0.5))


func _create_proof_mesh(n: String, c: Color) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = n
	_proof_root.add_child(m)
	apply_material(m, c)
	m.visible = false
	return m


## Where the altitude from the right angle meets the hypotenuse. Euclid's whole
## construction hangs off this point.
func _altitude_foot() -> Vector3:
	var b: Vector3 = vertex_positions[1]
	var edge: Vector3 = vertex_positions[2] - b
	var len_sq: float = edge.length_squared()
	if len_sq < 0.000001:
		return b
	var t: float = clampf((vertex_positions[0] - b).dot(edge) / len_sq, 0.0, 1.0)
	return b + edge * t


## A vector whose projection onto p_hat is exactly `height`, leaning along `dir`.
## Equal projection means equal area: that is the shear, and the reason the sheared
## parallelogram is still the square it came from.
func _shear_offset(p_hat: Vector3, height: float, dir: Vector3) -> Vector3:
	var k: float = dir.dot(p_hat)
	var lean: Vector3 = dir
	if k < 0.0:
		lean = -dir
		k = -k
	if k < 0.15:
		# Too oblique to shear without the figure shooting off the exhibit — fall back
		# to the square itself rather than draw a sliver.
		return p_hat * height
	return lean * (height / k)


func _quad_mesh(mesh_inst: MeshInstance3D, p1: Vector3, p2: Vector3, p3: Vector3, p4: Vector3) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var normal: Vector3 = Vector3.BACK
	add_triangle_face(st, p1, p2, p3, normal)
	add_triangle_face(st, p1, p3, p4, normal)
	add_triangle_face(st, p1, p3, p2, -normal)
	add_triangle_face(st, p1, p4, p3, -normal)
	mesh_inst.mesh = st.commit()


func _update_proof_meshes() -> void:
	var v0: Vector3 = vertex_positions[0]
	var v1: Vector3 = vertex_positions[1]
	var v2: Vector3 = vertex_positions[2]

	var foot: Vector3 = _altitude_foot()
	var drop: Vector3 = foot - v0
	if drop.length_squared() < 0.000001:
		drop = Vector3.UP
	var alt_dir: Vector3 = drop.normalized()

	# The two leg squares, sheared along the altitude. Same base, same perpendicular
	# height, same area — the classic sliding proof, held still.
	var edge_a: Vector3 = v1 - v0
	var perp_a: Vector3 = Vector3(edge_a.y, -edge_a.x, 0.0)
	var off_a: Vector3 = _shear_offset(perp_a.normalized(), perp_a.length(), alt_dir)
	_quad_mesh(_shear_a, v0, v1, v1 + off_a, v0 + off_a)

	var edge_b: Vector3 = v0 - v2
	var perp_b: Vector3 = Vector3(edge_b.y, -edge_b.x, 0.0)
	var off_b: Vector3 = _shear_offset(perp_b.normalized(), perp_b.length(), alt_dir)
	_quad_mesh(_shear_b, v2, v0, v0 + off_b, v2 + off_b)

	# Euclid I.47: the altitude, produced through the hypotenuse square, cuts it into
	# two rectangles. The one next to B has area a^2, the one next to A has area b^2 —
	# so the near rectangle is drawn in square A's blue and the far one in square B's
	# orange. That colouring IS the theorem.
	var edge_c: Vector3 = v2 - v1
	var perp_c: Vector3 = Vector3(edge_c.y, -edge_c.x, 0.0)
	_quad_mesh(_split_near, v1, foot, foot + perp_c, v1 + perp_c)
	_quad_mesh(_split_far, foot, v2, v2 + perp_c, foot + perp_c)

	var tip: Vector3 = foot + perp_c
	var side: Vector3 = Vector3(-alt_dir.y, alt_dir.x, 0.0) * 0.02
	_quad_mesh(_altitude, v0 + side, tip + side, tip - side, v0 - side)


## Grid system integration.
##
## Guarded twice over: the key has to be present AND the value has to differ, so a map
## token carrying unrelated layout keys does not rebuild the exhibit. triangle_mesh is
## null until _ready has built once, which keeps a config applied early from drawing
## against meshes that do not exist yet — the exports alone are enough then.
func apply_grid_config(config_data: Dictionary) -> void:
	var changed: bool = false

	if config_data.has("evidence"):
		# Map config values arrive as strings; an unknown one is ignored rather than
		# silently rendering the default under a name that was never reached.
		var wanted_evidence: String = str(config_data["evidence"]).strip_edges().to_lower()
		if wanted_evidence != evidence and EVIDENCE_VALUES.has(wanted_evidence):
			evidence = wanted_evidence
			changed = true

	if config_data.has("arc_radius"):
		var wanted_arc: float = float(config_data["arc_radius"])
		if not is_equal_approx(wanted_arc, arc_radius):
			arc_radius = wanted_arc
			changed = true

	if changed and triangle_mesh != null:
		update_visuals()


func add_triangle_face(st: SurfaceTool, v1, v2, v3, n):
	st.set_normal(n)
	st.set_uv(Vector2(0,0))
	st.add_vertex(v1)
	st.set_uv(Vector2(1,0))
	st.add_vertex(v2)
	st.set_uv(Vector2(0,1))
	st.add_vertex(v3)

func apply_material(mesh_instance: MeshInstance3D, color: Color):
	var material = ShaderMaterial.new()
	var shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")
	if shader:
		material.shader = shader
		material.set_shader_parameter("wireframe_color", Color.WHITE)
		material.set_shader_parameter("fill_color", color)
		mesh_instance.material_override = material

func reset_to_right_triangle():
	vertex_positions = [
		Vector3(-0.5, sphere_y_offset, 0.0),
		Vector3(0.5, sphere_y_offset, 0.0),
		Vector3(-0.5, sphere_y_offset + 1.0, 0.0)
	]
	if drag_points: drag_points.set_points_positions(vertex_positions)
	update_visuals()

func _on_point_moved(index: int, position: Vector3, _meta: Dictionary) -> void:
	if index < 0 or index >= vertex_positions.size(): return
	var constrained_pos = Vector3(position.x, position.y, 0.0)
	vertex_positions[index] = constrained_pos
	update_visuals()

func _on_point_picked_up(_index: int, _pickable, _meta: Dictionary) -> void: pass

func _on_point_dropped(index: int, _pickable, _meta: Dictionary) -> void:
	var pos = vertex_positions[index]
	pos.z = 0.0
	vertex_positions[index] = pos
	if drag_points: drag_points.set_point_position(index, pos)
	update_visuals()

func print_help():
	print("=== Pythagorean Triangle Angles ===")
	print("Demonstrates angles and squares.")
	print("Mouse: Drag corners (XY Plane).")
