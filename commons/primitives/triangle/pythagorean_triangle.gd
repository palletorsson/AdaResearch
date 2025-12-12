# PythagoreanTriangle.gd - Creates a right triangle demonstrating Pythagorean theorem
extends Node3D

var vertex_color: Color = Color(0.2, 0.8, 0.3, 0.7)  # Transparent green marble
@export var sphere_size_multiplier: float = 0.25
@export var sphere_y_offset: float = 0.5  # Base height for interaction

## Freeze behavior options
@export var alter_freeze : bool = false

# Mesh instances
var triangle_mesh: MeshInstance3D
var square_a_mesh: MeshInstance3D
var square_b_mesh: MeshInstance3D
var square_c_mesh: MeshInstance3D
var angle_meshes: Array[MeshInstance3D] = []
var right_angle_mesh: MeshInstance3D

# Snapping
const SNAP_THRESHOLD_DISTANCE = 0.4


var drag_points: DragPointSet

# Standing Right Triangle (XY plane)
# Originating somewhat centered
var vertex_positions: Array[Vector3] = [
	Vector3(-0.5, sphere_y_offset, 0.0),       # Corner (C) - Right Angle
	Vector3(0.5, sphere_y_offset, 0.0),        # Base End (B)
	Vector3(-0.5, sphere_y_offset + 1.0, 0.0)  # Top (A)
]

# Indices for triangle: C, B, A (0, 1, 2)
var triangle_indices: Array[int] = [0, 1, 2]

# Labels for sides
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
	
	# Square A (Side BC - Base)
	square_a_mesh = MeshInstance3D.new()
	square_a_mesh.name = "SquareA"
	apply_material(square_a_mesh, Color(0.2, 0.6, 1.0, 0.5)) # Blueish
	add_child(square_a_mesh)

	# Square B (Side CA - Height)
	square_b_mesh = MeshInstance3D.new()
	square_b_mesh.name = "SquareB"
	apply_material(square_b_mesh, Color(1.0, 0.6, 0.2, 0.5)) # Orangeish
	add_child(square_b_mesh)

	# Square C (Side AB - Hypotenuse)
	square_c_mesh = MeshInstance3D.new()
	square_c_mesh.name = "SquareC"
	apply_material(square_c_mesh, Color(0.8, 0.2, 1.0, 0.5)) # Purpleish
	add_child(square_c_mesh)

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
	# Create labels for the three sides
	var label_configs = [
		{"name": "BaseLabel", "text": "a"},
		{"name": "HeightLabel", "text": "b"},
		{"name": "HypotenuseLabel", "text": "c"}
	]

	for config in label_configs:
		var label = Label3D.new()
		label.name = config["name"]
		label.text = config["text"]
		label.font_size = 32 # Larger for visibility
		label.outline_size = 4
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(label)
		label_nodes[config["name"]] = label

	# Create Pythagorean formula label
	var formula_label = Label3D.new()
	formula_label.name = "FormulaLabel"
	formula_label.text = "a² + b² = c²"
	formula_label.font_size = 48
	formula_label.outline_size = 6
	formula_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	formula_label.modulate = Color(1.0, 1.0, 0.5, 1.0)  # Yellow color
	add_child(formula_label)
	label_nodes["FormulaLabel"] = formula_label
	
	# Create Angle Indicators
	right_angle_mesh = MeshInstance3D.new()
	right_angle_mesh.name = "RightAngleIndicator"
	apply_material(right_angle_mesh, Color.YELLOW)
	add_child(right_angle_mesh)
	
	for i in range(2): # For the two acute angles
		var mesh = MeshInstance3D.new()
		mesh.name = "AngleIndicator_%d" % i
		apply_material(mesh, Color.WHITE)
		add_child(mesh)
		angle_meshes.append(mesh)

func update_visuals():
	update_triangle_mesh()
	update_squares()
	update_triangle_mesh()
	update_squares()
	update_labels()
	update_angles()

func update_labels():
	# Vertices: 0=C (Corner), 1=B (Right), 2=A (Top)
	# Side a: 0 -> 1 (Base)
	# Side b: 0 -> 2 (Height)
	# Side c: 1 -> 2 (Hypotenuse)
	
	var a_vec = vertex_positions[1] - vertex_positions[0]
	var b_vec = vertex_positions[2] - vertex_positions[0]
	var c_vec = vertex_positions[2] - vertex_positions[1]
	
	var a_len = a_vec.length()
	var b_len = b_vec.length()
	var c_len = c_vec.length()

	# Update label texts
	if label_nodes.has("BaseLabel"):
		label_nodes["BaseLabel"].text = "a = %.2f" % a_len
		label_nodes["BaseLabel"].position = (vertex_positions[0] + vertex_positions[1]) / 2.0 + Vector3(0, -0.2, 0) # Below

	if label_nodes.has("HeightLabel"):
		label_nodes["HeightLabel"].text = "b = %.2f" % b_len
		label_nodes["HeightLabel"].position = (vertex_positions[0] + vertex_positions[2]) / 2.0 + Vector3(-0.2, 0, 0) # Left

	if label_nodes.has("HypotenuseLabel"):
		label_nodes["HypotenuseLabel"].text = "c = %.2f" % c_len
		label_nodes["HypotenuseLabel"].position = (vertex_positions[1] + vertex_positions[2]) / 2.0 + Vector3(0.2, 0.2, 0) # Out a bit
		label_nodes["HypotenuseLabel"].modulate = Color(1.0, 0.5, 0.8, 1.0)

	# Update Pythagorean formula label with actual values
	if label_nodes.has("FormulaLabel"):
		var a_sq = a_len * a_len
		var b_sq = b_len * b_len
		var c_sq = c_len * c_len
		
		# Show inequality if not right-angled?
		# For now, show the sum comparison
		var sum_sq = a_sq + b_sq
		var diff = abs(sum_sq - c_sq)
		
		var op = "="
		if diff > 0.05: op = "≈" # Approximate
		if diff > 0.5: op = "≠"  # Not equal
		
		label_nodes["FormulaLabel"].text = "a² + b² %s c²\n%.1f + %.1f %s %.1f" % [op, a_sq, b_sq, op, c_sq]
		
		# Position above triangle
		var center = (vertex_positions[0] + vertex_positions[1] + vertex_positions[2]) / 3.0
		label_nodes["FormulaLabel"].position = center + Vector3(0, 1.2, 0) # High above
		
		# Color coding the formula
		# We can't easily color parts of a Label3D text without BBCode, but Label3D supports outline.
		# Let's try to interpret equation nicely.
		# For now, keep the Yellow color but maybe separate labels? 
		# Or just stick to one label as requested but ensure the text is clear.
		label_nodes["FormulaLabel"].modulate = Color(1.0, 1.0, 0.4, 1.0) # Bright Yellow

func update_triangle_mesh():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Standard Normals for standing triangle (Z+)
	var normal = Vector3.BACK 

	var v0 = vertex_positions[0]
	var v1 = vertex_positions[1]
	var v2 = vertex_positions[2]

	add_triangle_face(st, v0, v1, v2, normal)
	add_triangle_face(st, v0, v2, v1, -normal) # Double-sided
	
	triangle_mesh.mesh = st.commit()

func update_squares():
	# Generate squares extending OUTWARDS from the sides
	# Since it's 2D in XY plane, "outward" means perpendicular to the edge vector in the XY plane
	
	# Side A (0->1)
	update_square_mesh(square_a_mesh, vertex_positions[0], vertex_positions[1])

	# Side B (0->2)
	# Note: We want squares to go OUT. 
	# For side 0->2 (up), out is Left (-X). 
	update_square_mesh(square_b_mesh, vertex_positions[2], vertex_positions[0]) # Flip order to flip normal direction

	# Side C (1->2)
	# Hypotenuse. 
	update_square_mesh(square_c_mesh, vertex_positions[1], vertex_positions[2])

func update_square_mesh(mesh_inst: MeshInstance3D, p1: Vector3, p2: Vector3):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var edge = p2 - p1
	var normal = Vector3.BACK
	
	# Calculate vector perpendicular to edge in XY plane
	# Rotate -90 degrees around Z
	var perp = Vector3(edge.y, -edge.x, 0.0)
	
	# Check winding/direction? 
	# Let's assume counter-clockwise winding for the triangle 0->1->2
	# If we walk 0->1, perpendicular to right is (y, -x)
	
	var p3 = p2 + perp
	var p4 = p1 + perp
	
	# Two triangles for square
	add_triangle_face(st, p1, p2, p4, normal)
	add_triangle_face(st, p2, p3, p4, normal)
	
	# Back faces
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
	
	if drag_points:
		drag_points.set_points_positions(vertex_positions)
	update_visuals()
	print("Reset to standard right triangle")

func _on_point_moved(index: int, position: Vector3, _meta: Dictionary) -> void:
	if index < 0 or index >= vertex_positions.size():
		return
		
	# FORCE Z=0 CONSTRAINT
	var constrained_pos = Vector3(position.x, position.y, 0.0)
	
	# Apply Snapping
	constrained_pos = _get_snapped_position(index, constrained_pos)
	
	if vertex_positions[index] == constrained_pos:
		return
		
	vertex_positions[index] = constrained_pos
	
	# Update visual position of the drag point immediately?
	# The DragPointSet might update itself based on physics/input, 
	# but we need to enforce the constraint.
	# Ideally DragPointSet allows constraint, but we can just snap it back next frame if needed.
	# Since this signal comes FROM interaction, we update our data.
	
	update_visuals()

func _get_snapped_position(index: int, pos: Vector3) -> Vector3:
	# Indices: 0=Corner(C), 1=Base(B), 2=Top(A)
	# Right angle is intended at 0.
	
	var v0 = vertex_positions[0]
	var v1 = vertex_positions[1]
	var v2 = vertex_positions[2]
	
	var snapped_pos = pos
	var did_snap = false
	
	if index == 0:
		# Moving the right-angle corner.
		# Snap to Thales Circle defined by diameter v1-v2
		var center = (v1 + v2) * 0.5
		var radius = v1.distance_to(v2) * 0.5
		var dist_to_center = pos.distance_to(center)
		
		# If close to the circle (radius distance)
		if abs(dist_to_center - radius) < SNAP_THRESHOLD_DISTANCE:
			var dir = (pos - center).normalized()
			snapped_pos = center + dir * radius
			did_snap = true
			
	elif index == 1:
		# Moving Base (B). Snap to make 0->1 perpendicular to 0->2
		# Line passing through v0 with direction perpendicular to (v2-v0)
		var leg_vec = v2 - v0
		var perp_dir = Vector3(leg_vec.y, -leg_vec.x, 0).normalized() # Rotation in Z? No, XY plane.
		# Actually we want the projection of pos onto the line defined by v0 and perp_dir
		# That ensures 90 deg at v0.
		
		# But wait, 0->1 could also align with 0->2 (0 deg) or opposite (180). We want 90.
		# The line through v0 with direction perp to (v2-v0) contains all points that form a 90 deg angle.
		
		var v0_to_pos = pos - v0
		var projected = v0_to_pos.project(perp_dir)
		var target = v0 + projected
		
		if pos.distance_to(target) < SNAP_THRESHOLD_DISTANCE:
			snapped_pos = target
			did_snap = true
			
	elif index == 2:
		# Moving Top (A). Snap to make 0->2 perpendicular to 0->1
		var leg_vec = v1 - v0
		var perp_dir = Vector3(-leg_vec.y, leg_vec.x, 0).normalized()
		
		var v0_to_pos = pos - v0
		var projected = v0_to_pos.project(perp_dir)
		var target = v0 + projected
		
		if pos.distance_to(target) < SNAP_THRESHOLD_DISTANCE:
			snapped_pos = target
			did_snap = true
	
	if did_snap:
		# Optional: Visual feedback for snap?
		pass
		
	return snapped_pos

func update_angles():
	# 0 is C (Right Angle), 1 is B, 2 is A
	var v0 = vertex_positions[0]
	var v1 = vertex_positions[1]
	var v2 = vertex_positions[2]
	
	# Check if Right Angle
	var dir_a = (v2 - v0).normalized()
	var dir_b = (v1 - v0).normalized()
	var dot = dir_a.dot(dir_b) # 0 if 90 deg
	var angle_rad = acos(clamp(dot, -1.0, 1.0))
	var angle_deg = rad_to_deg(angle_rad)
	
	var is_right_angle = abs(angle_deg - 90.0) < 1.0
	
	right_angle_mesh.visible = is_right_angle
	if is_right_angle:
		update_square_indicator(right_angle_mesh, v0, dir_b, dir_a, 0.3)
	
	# Update other arcs (just generic arcs for now)
	update_arc_indicator(angle_meshes[0], v1, v0, v2, 0.4) # Angle at B
	update_arc_indicator(angle_meshes[1], v2, v0, v1, 0.4) # Angle at A

func update_square_indicator(mesh_inst: MeshInstance3D, corner: Vector3, dir1: Vector3, dir2: Vector3, size: float):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)
	
	var p1 = corner + dir1 * size
	var p2 = corner + dir2 * size
	var p3 = p1 + dir2 * size # The projected corner
	
	st.add_vertex(p1)
	st.add_vertex(p3)
	
	st.add_vertex(p3)
	st.add_vertex(p2)
	
	# Fill?
	# Let's just do lines for the symbol
	mesh_inst.mesh = st.commit()

func update_arc_indicator(mesh_inst: MeshInstance3D, corner: Vector3, leg1_end: Vector3, leg2_end: Vector3, size: float):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	var d1 = (leg1_end - corner).normalized()
	var d2 = (leg2_end - corner).normalized()
	
	var steps = 10
	for i in range(steps + 1):
		var t = float(i) / steps
		var dir = d1.slerp(d2, t).normalized()
		st.add_vertex(corner + dir * size)
		
	mesh_inst.mesh = st.commit()

	pass

func _on_point_picked_up(index: int, _pickable, _meta: Dictionary) -> void:
	pass

func _on_point_dropped(index: int, _pickable, _meta: Dictionary) -> void:
	# Enforce final snap to Z=0
	var pos = vertex_positions[index]
	pos.z = 0.0
	vertex_positions[index] = pos
	if drag_points:
		drag_points.set_point_position(index, pos)
	update_visuals()

func print_help():
	print("=== Pythagorean Triangle (Standing) ===")
	print("Demonstrates: a² + b² = c²")
	print("Mouse: Drag corners (constrained to XY plane)")
	print("R: Reset to standard right triangle")
