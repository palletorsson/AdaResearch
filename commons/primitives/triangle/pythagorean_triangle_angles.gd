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

# Mesh instances
var triangle_mesh: MeshInstance3D
var square_a_mesh: MeshInstance3D
var square_b_mesh: MeshInstance3D
var square_c_mesh: MeshInstance3D

var angle_mesh_0: MeshInstance3D # Angle at Vertex 0 (Right angle usually)
var angle_mesh_1: MeshInstance3D
var angle_mesh_2: MeshInstance3D

var drag_points: DragPointSet

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
