# vector_subtraction_demo.gd
## Visualizes vector subtraction using the identity A - B = A + (-B).
## Shows vectors A and B from origin, the negation -B, and the tip-to-tail
## construction where -B is placed at A's tip to produce the result A - B.
## VR-enabled: grabbable arrow endpoints let learners drag vectors interactively.
##
## @identity
## essence: A - B = A + (-B). Subtraction is addition of the opposite. The difference vector points from B's tip to A's tip.
## desire: To show that subtraction is not removal — it is the directed gap between two positions.
## critical_parameter: The relationship between vector_a and vector_b. When equal, the result is zero — the gap closes.
## triggers: Handle drag → all five arrows update (A, B, -B, -B from tip, result), preset buttons → orthogonal/same/opposing configurations
## emerges: The ghost arrow -B appearing at A's tip makes the tip-to-tail construction visible. Subtracting identical vectors yields zero — visually collapsing to a point.
## needs: VR grabbable handles [has], preset buttons [has]. Missing: animation showing the construction step by step.
## relationships: Inverse of vector_addition_demo. Prerequisite for hl_turret_vectors (direction = target - turret is subtraction).
## truth: The difference between two positions is a direction. Subtraction creates the arrow that connects them.

extends Node3D

class_name VectorSubtractionDemo

## Maximum length any vector can reach before clamping
@export_range(0.1, 5.0, 0.1) var max_vector_length: float = 1.2
## Thickness of arrow shafts
@export_range(0.001, 0.05, 0.001) var arrow_thickness: float = 0.006

## Vector A — draggable in VR
@export var vector_a: Vector3 = Vector3(0.8, 0.4, -0.1):
	set(value):
		vector_a = value.limit_length(max_vector_length)
		if is_inside_tree():
			_update_vectors()

## Vector B — draggable in VR
@export var vector_b: Vector3 = Vector3(0.2, 0.7, 0.3):
	set(value):
		vector_b = value.limit_length(max_vector_length)
		if is_inside_tree():
			_update_vectors()

## Color for vector A
@export var color_a: Color = Color(1.0, 0.3, 0.3)
## Color for vector B
@export var color_b: Color = Color(0.3, 0.5, 1.0)
## Color for the negated vector -B (ghost)
@export var color_neg_b: Color = Color(0.5, 0.7, 1.0, 0.6)
## Color for the result vector A - B
@export var color_result: Color = Color(0.3, 1.0, 0.4)
## Color for info panel backgrounds
@export var panel_color: Color = Color(0.06, 0.06, 0.08, 0.9)

## AXIS — HOW MUCH OF THE ARITHMETIC THE BENCH DRAWS. Adopted word for word (and value
## for value, in order) from [[transform_composition_workbench]] and shared across the
## whole vector subject, so a room cannot show its sum as a walked route and its
## difference as a bare answer.
##
##   outcome     the difference alone. A, B, −B and the tip-to-tail leg all leave the
##               render layers with their labels; one green arrow reaches from the origin
##               and nothing in the frame says which two positions made it.
##   trace       the legacy lineage, byte for byte — the TRIANGLE rule this artifact was
##               written to argue: A from the origin, −B standing on A's TIP, the result
##               closing them. A − B is a walk you took.
##   operands    the gap instead of the walk. The tip-to-tail leg retires and a bright
##               arrow is drawn straight from B's TIP to A's TIP — the difference read as
##               the directed distance between two positions — inside the dashed
##               parallelogram that A and −B span.
##   expression  the algebra promoted over the geometry. The side formula panel is joined
##               by a board standing over the arrows, facing the player, writing
##               A − B = A + (−B) with the components substituted, between two emissive
##               rules in the result's green.
##
## The five arrows are the pivot: they are the only saturated things in the frame, and
## outcome takes four of them out.
@export_enum("outcome", "trace", "operands", "expression") var workings: String = "trace"
const WORKINGS: PackedStringArray = ["outcome", "trace", "operands", "expression"]

## AXIS — WHICH DIFFERENCE THE BENCH DRAWS. Taken character for character from
## [[VectorSubtraction]] and [[example_1_3_vector_subtraction_vr]], the two other benches
## in this corpus arguing a − b; one operation should not carry three vocabularies for the
## question of which operand gets negated. `workings` says how much of the arithmetic is
## shown, `order` says whose arithmetic it is — independent questions, and this artifact's
## own @identity already names the second one ("when equal, the result is zero") without
## ever making it reachable from a map.
##
##   a_minus_b   head = A, tail = B. −B is the ghost, the tip-to-tail leg stands on A's
##               tip, the green arrow is A − B. Literally the `vector_a - vector_b` this
##               file was written with. The shipped reading.
##   b_minus_a   the operands swap. −A is the ghost, the leg stands on B's tip, and the
##               green arrow points the other way — the same two positions, the opposite
##               direction between them.
##   reciprocal  both differences at once, nose to nose through the origin.
##               Anti-commutativity as one picture instead of a claim.
##
## The ghost colour is deliberately NOT swapped under b_minus_a: color_neg_b names the ROLE
## (the negated operand) and not the operand, so the frame stays readable and no material
## built in _ready has to be rewritten per value.
@export_enum("a_minus_b", "b_minus_a", "reciprocal") var order: String = "a_minus_b"
const ORDERS: PackedStringArray = ["a_minus_b", "b_minus_a", "reciprocal"]

var _arrow_a: Node3D
var _arrow_b: Node3D
var _arrow_neg_b: Node3D  # -B from origin
var _arrow_neg_b_tip: Node3D  # -B from tip of A (tip-to-tail)
var _arrow_result: Node3D
var _handle_a: Node3D
var _handle_b: Node3D
var _title_panel: Node3D
var _formula_panel: Node3D

# Vector labels
var _label_a: Label3D
var _label_b: Label3D
var _label_neg_b: Label3D
var _label_result: Label3D

# Coordinate axes
var _axes_container: Node3D

# WORKINGS dressing lives here and nowhere else — created last in _ready() so the
# legacy tree above it is untouched, cleared and refilled on every _update_vectors().
var _workings_root: Node3D

# ORDER dressing (the reciprocal counter-arrow) lives here and nowhere else, created after
# the workings holder so neither it nor anything above it changes index. Empty on the
# default and on b_minus_a; only `reciprocal` ever puts a node in it.
var _order_root: Node3D

# The operands as `order` reads them, so _apply_workings can draw the gap between the right
# two tips. On a_minus_b these are exactly vector_a and vector_b.
var _ord_head: Vector3 = Vector3.ZERO
var _ord_tail: Vector3 = Vector3.ZERO

# VR Controls
var _control_panel: Node3D

# Shared materials (created once, reused across nodes)
var _frame_mat: StandardMaterial3D
var _panel_backing_mat: StandardMaterial3D

# Node tracking for cleanup
var _created_nodes: Array[Node] = []


func _add_tracked_child(node: Node) -> void:
	add_child(node)
	_created_nodes.append(node)

## Creates a text label with a backing panel frame
func _create_text_panel(panel_name: String, text: String, pos: Vector3, 
		size: Vector2 = Vector2(0.3, 0.08), font_size: int = 16, 
		alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Node3D:
	var panel = Node3D.new()
	panel.name = panel_name
	panel.position = pos
	
	# Backing panel
	var backing = MeshInstance3D.new()
	backing.name = "Backing"
	var box = BoxMesh.new()
	box.size = Vector3(size.x, size.y, 0.008)
	backing.mesh = box
	
	backing.material_override = _panel_backing_mat
	backing.position.z = -0.005
	panel.add_child(backing)
	
	# Frame edges
	_add_panel_frame(panel, size)
	
	# Label
	var label = Label3D.new()
	label.name = "Label"
	label.text = text
	label.pixel_size = 0.001
	label.font_size = font_size
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position.z = 0.002
	panel.add_child(label)
	
	return panel

func _add_panel_frame(panel: Node3D, size: Vector2):
	var thickness = 0.004
	var depth = 0.01
	var half_w = size.x / 2.0
	var half_h = size.y / 2.0
	var z_pos = -depth / 2.0 + 0.002

	var unit_box := BoxMesh.new()
	unit_box.size = Vector3(1, 1, 1)

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = unit_box
	mm.instance_count = 4

	# Top edge
	var xf := Transform3D(Basis.IDENTITY.scaled(Vector3(size.x + thickness * 2, thickness, depth)), Vector3(0, half_h, z_pos))
	mm.set_instance_transform(0, xf)
	# Bottom edge
	xf = Transform3D(Basis.IDENTITY.scaled(Vector3(size.x + thickness * 2, thickness, depth)), Vector3(0, -half_h, z_pos))
	mm.set_instance_transform(1, xf)
	# Left edge
	xf = Transform3D(Basis.IDENTITY.scaled(Vector3(thickness, size.y, depth)), Vector3(-half_w, 0, z_pos))
	mm.set_instance_transform(2, xf)
	# Right edge
	xf = Transform3D(Basis.IDENTITY.scaled(Vector3(thickness, size.y, depth)), Vector3(half_w, 0, z_pos))
	mm.set_instance_transform(3, xf)

	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = _frame_mat
	panel.add_child(mmi)

func _get_panel_label(panel: Node3D) -> Label3D:
	return panel.get_node_or_null("Label") as Label3D

func _ready():
	_init_shared_materials()
	_create_base()
	_create_coordinate_axes()
	_create_arrows()
	_create_vector_labels()
	_create_handles()
	_create_labels()
	_create_vr_controls()
	# WORKINGS holder — created LAST, so every node above keeps the index and the
	# position it has today. Empty on the default; nothing above this line moves.
	_workings_root = Node3D.new()
	_workings_root.name = "Workings"
	_add_tracked_child(_workings_root)
	# ORDER holder — after the workings holder, so the workings holder's own index is
	# unchanged too. Stays empty at a_minus_b and b_minus_a.
	_order_root = Node3D.new()
	_order_root.name = "Order"
	_add_tracked_child(_order_root)
	_update_vectors()

func _init_shared_materials():
	_frame_mat = StandardMaterial3D.new()
	_frame_mat.albedo_color = Color(0.3, 0.32, 0.35)
	_frame_mat.metallic = 0.5
	_frame_mat.roughness = 0.4

	_panel_backing_mat = StandardMaterial3D.new()
	_panel_backing_mat.albedo_color = panel_color
	_panel_backing_mat.metallic = 0.2
	_panel_backing_mat.roughness = 0.8

func _create_base():
	# Ground plane
	var base = MeshInstance3D.new()
	base.name = "Base"
	
	var plane = PlaneMesh.new()
	plane.size = Vector2(max_vector_length * 2.5, max_vector_length * 2.5)
	base.mesh = plane
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.1, 0.12, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	base.material_override = mat
	base.position = Vector3(0, -0.01, 0)
	_add_tracked_child(base)

	# Origin marker
	var origin = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.03
	sphere.height = 0.06
	origin.mesh = sphere
	var origin_mat = StandardMaterial3D.new()
	origin_mat.albedo_color = Color(1, 1, 1)
	origin_mat.emission_enabled = true
	origin_mat.emission = Color(1, 1, 1)
	origin_mat.emission_energy_multiplier = 0.3
	origin.material_override = origin_mat
	_add_tracked_child(origin)

func _create_coordinate_axes():
	_axes_container = Node3D.new()
	_axes_container.name = "Axes"
	_add_tracked_child(_axes_container)
	
	var axis_length = max_vector_length * 1.3
	_create_axis_line(Vector3(axis_length, 0, 0), Color(1.0, 0.3, 0.3, 0.5), "X")
	_create_axis_line(Vector3(0, axis_length, 0), Color(0.3, 1.0, 0.3, 0.5), "Y")
	_create_axis_line(Vector3(0, 0, axis_length), Color(0.3, 0.5, 1.0, 0.5), "Z")

func _create_axis_line(direction: Vector3, color: Color, label_text: String):
	var length = direction.length()
	var norm = direction.normalized()
	
	var shaft = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.005
	cylinder.bottom_radius = 0.005
	cylinder.height = length
	shaft.mesh = cylinder
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shaft.material_override = mat
	shaft.position = direction / 2.0
	
	if abs(norm.dot(Vector3.UP)) < 0.99:
		shaft.look_at(shaft.position + direction, Vector3.UP)
		shaft.rotate_object_local(Vector3.RIGHT, PI/2)
	
	_axes_container.add_child(shaft)
	
	var lbl = Label3D.new()
	lbl.text = label_text
	lbl.pixel_size = 0.002
	lbl.font_size = 16
	lbl.modulate = color
	lbl.position = direction + norm * 0.05
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_axes_container.add_child(lbl)

func _create_vector_labels():
	_label_a = _create_vector_label("A", color_a)
	_label_b = _create_vector_label("B", color_b)
	_label_neg_b = _create_vector_label("-B", color_neg_b)
	_label_result = _create_vector_label("A-B", color_result)
	_add_tracked_child(_label_a)
	_add_tracked_child(_label_b)
	_add_tracked_child(_label_neg_b)
	_add_tracked_child(_label_result)

func _create_vector_label(text: String, color: Color) -> Label3D:
	var label = Label3D.new()
	label.text = text
	label.pixel_size = 0.0018
	label.font_size = 16
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.outline_size = 6
	label.outline_modulate = Color(0, 0, 0, 0.7)
	return label

func _create_arrows():
	_arrow_a = _create_arrow("ArrowA", color_a)
	_arrow_b = _create_arrow("ArrowB", color_b)
	_arrow_neg_b = _create_arrow("ArrowNegB", color_neg_b, true)
	_arrow_neg_b_tip = _create_arrow("ArrowNegBTip", color_neg_b, true)
	_arrow_result = _create_arrow("ArrowResult", color_result)
	
	_add_tracked_child(_arrow_a)
	_add_tracked_child(_arrow_b)
	_add_tracked_child(_arrow_neg_b)
	_add_tracked_child(_arrow_neg_b_tip)
	_add_tracked_child(_arrow_result)

func _create_arrow(arrow_name: String, color: Color, ghost: bool = false) -> Node3D:
	var arrow = Node3D.new()
	arrow.name = arrow_name
	
	# Shaft
	var shaft = MeshInstance3D.new()
	shaft.name = "Shaft"
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = arrow_thickness * (0.5 if ghost else 1.0)
	cylinder.bottom_radius = arrow_thickness * (0.5 if ghost else 1.0)
	cylinder.height = 1.0
	shaft.mesh = cylinder
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	if ghost:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	else:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.2
	shaft.material_override = mat
	arrow.add_child(shaft)
	
	# Head (cone)
	var head = MeshInstance3D.new()
	head.name = "Head"
	var cone = CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = arrow_thickness * 2.5 * (0.5 if ghost else 1.0)
	cone.height = arrow_thickness * 5
	head.mesh = cone
	head.material_override = mat
	arrow.add_child(head)
	
	return arrow

func _create_handles():
	# Grabbable handle for vector A tip
	_handle_a = _create_handle("HandleA", color_a)
	_handle_a.position = vector_a
	_add_tracked_child(_handle_a)

	# Grabbable handle for vector B tip
	_handle_b = _create_handle("HandleB", color_b)
	_handle_b.position = vector_b
	_add_tracked_child(_handle_b)

func _create_handle(handle_name: String, color: Color) -> Node3D:
	var handle = Node3D.new()
	handle.name = handle_name
	
	var sphere = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = 0.04
	mesh.height = 0.08
	sphere.mesh = mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.4
	sphere.material_override = mat
	handle.add_child(sphere)
	
	# Collision for grabbing
	var area = Area3D.new()
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.06
	collision.shape = shape
	area.add_child(collision)
	handle.add_child(area)
	
	return handle

func _create_labels():
	# Title panel - facing player
	_title_panel = _create_text_panel(
		"TitlePanel",
		"VECTOR SUBTRACTION",
		Vector3(0, max_vector_length + 0.25, -0.3),
		Vector2(0.40, 0.07),
		22
	)
	_title_panel.rotation_degrees = Vector3(0, 180, 0)
	_add_tracked_child(_title_panel)
	
	# Formula panel - to the side
	_formula_panel = _create_text_panel(
		"FormulaPanel",
		"",
		Vector3(-max_vector_length - 0.15, max_vector_length * 0.5, 0),
		Vector2(0.46, 0.18),
		13
	)
	_formula_panel.rotation_degrees = Vector3(0, 90, 0)
	_add_tracked_child(_formula_panel)

func _create_vr_controls():
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_panel("VECTOR SUB", [
		[{"type": "button", "label": "ORTHO"}, {"type": "button", "label": "SAME"}, {"type": "button", "label": "OPPOSE"}, {"type": "button", "label": "RESET"}],
	])
	_control_panel.position = Vector3(0, 0.04, max_vector_length + 0.32)
	_control_panel.rotation_degrees = Vector3(-25, 0, 0)
	_add_tracked_child(_control_panel)

	var presets = [
		[Vector3(0.5, 0, 0), Vector3(0, 0.5, 0)],
		[Vector3(0.5, 0.3, 0), Vector3(0.5, 0.3, 0)],
		[Vector3(0.5, 0.3, 0), Vector3(-0.3, -0.2, 0)],
		[Vector3(0.6, 0.4, 0), Vector3(0.2, 0.6, 0.2)],
	]
	for i in range(presets.size()):
		var btn: Node = _control_panel.find_child("Btn_%d" % i, true, false)
		if btn:
			var area = btn.get_node_or_null("InteractableAreaButton")
			if area:
				var va = presets[i][0]
				var vb = presets[i][1]
				area.button_pressed.connect(func(_b): _apply_preset(va, vb))

func _apply_preset(va: Vector3, vb: Vector3):
	vector_a = va
	vector_b = vb
	_handle_a.position = vector_a
	_handle_b.position = vector_b

func _update_vectors():
	# ORDER decides which operand is negated. a_minus_b is head = A, tail = B — the
	# literal `-vector_b` and `vector_a - vector_b` these two lines used to be.
	_ord_head = vector_a
	_ord_tail = vector_b
	if _order_value() == "b_minus_a":
		_ord_head = vector_b
		_ord_tail = vector_a
	var neg_b = -_ord_tail
	var result = _ord_head - _ord_tail  # = _ord_head + neg_b

	# Arrow A (from origin)
	_position_arrow(_arrow_a, Vector3.ZERO, vector_a)

	# Arrow B (from origin)
	_position_arrow(_arrow_b, Vector3.ZERO, vector_b)

	# Negative B from origin (shows the opposite)
	_position_arrow(_arrow_neg_b, Vector3.ZERO, neg_b)

	# Negative B from tip of A (tip-to-tail for A + (-B))
	_position_arrow(_arrow_neg_b_tip, _ord_head, _ord_head + neg_b)

	# Update vector labels
	_label_a.position = vector_a * 0.5 + Vector3(0.04, 0.04, 0)
	_label_b.position = vector_b * 0.5 + Vector3(0.04, 0.04, 0)
	_label_neg_b.position = neg_b * 0.5 + Vector3(0.04, 0.04, 0)
	_label_result.position = result * 0.5 + Vector3(0.04, 0.04, 0)
	# The two label TEXTS follow the order. At a_minus_b these assign the exact strings
	# _create_vector_labels() already put there, so the default writes itself back.
	_label_neg_b.text = "-" + _tail_symbol()
	_label_result.text = _head_symbol() + "-" + _tail_symbol()

	# Result arrow (from origin to A - B)
	_position_arrow(_arrow_result, Vector3.ZERO, result)

	# Update formula
	_update_formula(neg_b, result)

	# WORKINGS, applied LAST so nothing above it moves. "trace" restores every layer
	# and builds nothing at all — the legacy lineage, byte for byte.
	_apply_workings(neg_b, result)

	# ORDER dressing, after it. Returns on the first line unless the value is reciprocal.
	_apply_order(result)

func _position_arrow(arrow: Node3D, start: Vector3, end: Vector3):
	var direction = end - start
	var length = direction.length()
	
	if length < 0.001:
		arrow.visible = false
		return
	arrow.visible = true
	
	var shaft = arrow.get_node("Shaft")
	var head = arrow.get_node("Head")
	
	var mid = (start + end) / 2.0
	shaft.position = mid
	shaft.scale = Vector3(1, length - arrow_thickness * 5, 1)
	head.position = end - direction.normalized() * arrow_thickness * 2.5
	
	if direction.length() > 0.001:
		var up = Vector3.UP
		if abs(direction.normalized().dot(up)) > 0.99:
			up = Vector3.FORWARD
		arrow.look_at(arrow.global_position + direction, up)
		arrow.rotate_object_local(Vector3.RIGHT, PI/2)

func _update_formula(neg_b: Vector3, result: Vector3):
	var label = _get_panel_label(_formula_panel)
	if label:
		# h/t are "A"/"B" at a_minus_b, so every line below is the shipped line character
		# for character; only b_minus_a swaps them and only reciprocal appends.
		var h: String = _head_symbol()
		var t: String = _tail_symbol()
		label.text = "A = (%.2f, %.2f, %.2f)\n" % [vector_a.x, vector_a.y, vector_a.z]
		label.text += "B = (%.2f, %.2f, %.2f)\n" % [vector_b.x, vector_b.y, vector_b.z]
		label.text += "-%s = (%.2f, %.2f, %.2f)\n" % [t, neg_b.x, neg_b.y, neg_b.z]
		label.text += "%s - %s = %s + (-%s) = (%.2f, %.2f, %.2f)" % [
			h, t, h, t, result.x, result.y, result.z]
		if _order_value() == "reciprocal":
			label.text += "\n%s - %s = (%.2f, %.2f, %.2f)" % [
				t, h, -result.x, -result.y, -result.z]

func _process(_delta):
	if _handle_a and _handle_a.position != vector_a:
		vector_a = _handle_a.position
	if _handle_b and _handle_b.position != vector_b:
		vector_b = _handle_b.position

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				_apply_preset(Vector3(0.5, 0, 0), Vector3(0, 0.5, 0))
			KEY_2:
				_apply_preset(Vector3(0.5, 0.3, 0), Vector3(0.5, 0.3, 0))
			KEY_3:
				_apply_preset(Vector3(0.5, 0.3, 0), Vector3(-0.3, -0.2, 0))
			KEY_R:
				_apply_preset(Vector3(0.6, 0.4, 0), Vector3(0.2, 0.6, 0.2))

func set_vectors(a: Vector3, b: Vector3):
	vector_a = a
	vector_b = b
	_handle_a.position = vector_a
	_handle_b.position = vector_b

func get_result() -> Vector3:
	return vector_a - vector_b

func _exit_tree():
	for node in _created_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_created_nodes.clear()

## Guarded on all three counts the corpus has been burned by: the key must be NAMED, the
## word must VALIDATE, and the value must actually DIFFER. Nothing is redrawn otherwise, and
## nothing is redrawn at all until _ready has built once — _order_root is null before that,
## and the pending value is picked up by _ready's own _update_vectors().
func apply_grid_config(config_data: Dictionary) -> void:
	var touched: bool = false
	if config_data.has("workings"):
		var w: String = String(config_data["workings"]).strip_edges().to_lower()
		if WORKINGS.has(w) and w != workings:
			workings = w
			touched = true
	if config_data.has("order"):
		var o: String = String(config_data["order"]).strip_edges().to_lower()
		if ORDERS.has(o) and o != order:
			order = o
			touched = true
	if touched and is_inside_tree() and _order_root != null:
		_update_vectors()


# --- WORKINGS ---------------------------------------------------------------
# One axis, four values, shared word for word with the rest of the vector subject.
# Every builder writes only into _workings_root; removal is always `layers = 0` on the
# MeshInstance3D / Label3D leaves — never `visible = false`, which in Godot takes a
# holder's whole subtree with it (and this artifact's arrows ARE holders).

func _workings_value() -> String:
	var w: String = String(workings).strip_edges().to_lower()
	return w if WORKINGS.has(w) else "trace"


# --- ORDER -------------------------------------------------------------------
# An unknown word in a map token falls back to the shipped reading rather than stranding a
# placement with a blank bench — the same allow-list discipline WORKINGS uses above.

func _order_value() -> String:
	var o: String = String(order).strip_edges().to_lower()
	return o if ORDERS.has(o) else "a_minus_b"


## "A" unless the operands have been swapped.
func _head_symbol() -> String:
	return "B" if _order_value() == "b_minus_a" else "A"


## "B" unless the operands have been swapped.
func _tail_symbol() -> String:
	return "A" if _order_value() == "b_minus_a" else "B"


## RECIPROCAL — the counter-difference, drawn from the origin in the direction the result
## does not go, with its own midpoint label. Both differences stand nose to nose through
## the origin, which is anti-commutativity as a picture rather than a sentence. Every other
## value of `order` leaves this holder empty, so the shipped bench gains no node at all.
func _apply_order(result: Vector3) -> void:
	if _order_root == null:
		return
	for c in _order_root.get_children():
		_order_root.remove_child(c)
		c.queue_free()
	if _order_value() != "reciprocal":
		return
	_order_root.add_child(_w_arrow(Vector3.ZERO, -result, color_result, arrow_thickness, 0.6))
	var lbl: Label3D = _create_vector_label(_tail_symbol() + "-" + _head_symbol(), color_result)
	lbl.position = -result * 0.5 + Vector3(0.04, 0.04, 0)
	_order_root.add_child(lbl)


func _set_layers(n: Node, bits: int) -> void:
	if n is VisualInstance3D:
		(n as VisualInstance3D).layers = bits
	for child in n.get_children():
		_set_layers(child, bits)


func _apply_workings(neg_b: Vector3, result: Vector3) -> void:
	if _workings_root == null:
		return
	for c in _workings_root.get_children():
		_workings_root.remove_child(c)
		c.queue_free()

	var mode: String = _workings_value()

	# Restore first, so a value change at runtime is reversible and the default is
	# always exactly today's build.
	for n in [_arrow_a, _arrow_b, _arrow_neg_b, _arrow_neg_b_tip,
			_label_a, _label_b, _label_neg_b]:
		if n != null:
			_set_layers(n, 1)

	match mode:
		"outcome":
			# The difference alone. Both operands, the negation and the tip-to-tail leg
			# leave the render layers with their labels; A − B stands from the origin
			# with nothing to say where it came from.
			for n in [_arrow_a, _arrow_b, _arrow_neg_b, _arrow_neg_b_tip,
					_label_a, _label_b, _label_neg_b]:
				if n != null:
					_set_layers(n, 0)
		"operands":
			# The gap, not the walk. The leg standing on A's tip retires and the
			# difference is drawn where it actually lives: straight from B's TIP to A's
			# TIP. The dashed sides close the parallelogram A and −B span.
			if _arrow_neg_b_tip != null:
				_set_layers(_arrow_neg_b_tip, 0)
			# tail's tip to head's tip. At a_minus_b that is vector_b -> vector_a, the
			# pair this line was written with.
			_workings_root.add_child(_w_arrow(_ord_tail, _ord_head, color_result, 0.010, 2.0))
			var side: Color = Color(color_result.r, color_result.g, color_result.b, 0.5)
			_workings_root.add_child(_w_dashed(_ord_head, _ord_head + neg_b, side))
			_workings_root.add_child(_w_dashed(neg_b, _ord_head + neg_b, side))
			_workings_root.add_child(_w_dot(vector_b, color_b))
			_workings_root.add_child(_w_dot(vector_a, color_a))
		"expression":
			_workings_root.add_child(_w_board(neg_b, result))
		_:
			pass                                   # "trace" — the legacy lineage


## A solid emissive arrow between two points, in the artifact's own arrow idiom.
func _w_arrow(from: Vector3, to: Vector3, color: Color, radius: float, energy: float) -> Node3D:
	var root := Node3D.new()
	var dir: Vector3 = to - from
	var length: float = dir.length()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	if length < 0.001:
		return root
	var head_len: float = radius * 5.0
	var shaft := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = maxf(length - head_len, 0.001)
	shaft.mesh = cyl
	shaft.material_override = mat
	root.add_child(shaft)
	var head := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = radius * 2.5
	cone.height = head_len
	head.mesh = cone
	head.material_override = mat
	root.add_child(head)
	shaft.position = Vector3(0.0, maxf(length - head_len, 0.001) * 0.5, 0.0)
	head.position = Vector3(0.0, length - head_len * 0.5, 0.0)
	# Basis built by hand rather than look_at(): look_at() needs the node to already be
	# inside the tree, and this arrow is assembled before it is parented.
	root.transform = Transform3D(_w_basis_y_to(dir), from)
	return root


## A basis whose +Y runs along `dir` — the axis the local arrow meshes are built on.
func _w_basis_y_to(dir: Vector3) -> Basis:
	var y: Vector3 = dir.normalized()
	if y.length() < 0.0001:
		return Basis()
	var ref: Vector3 = Vector3.UP if absf(y.dot(Vector3.UP)) < 0.985 else Vector3.RIGHT
	var x: Vector3 = ref.cross(y).normalized()
	var z: Vector3 = x.cross(y).normalized()
	return Basis(x, y, z)


## A dashed guide between two points — the parallelogram sides.
func _w_dashed(from: Vector3, to: Vector3, color: Color) -> Node3D:
	var root := Node3D.new()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(color.r, color.g, color.b, 1.0)
	mat.emission_energy_multiplier = 0.9
	var mesh := SphereMesh.new()
	mesh.radius = 0.011
	mesh.height = 0.022
	mesh.radial_segments = 8
	mesh.rings = 4
	var n: int = 13
	for i in range(n):
		if i % 2 == 1:
			continue
		var dot := MeshInstance3D.new()
		dot.mesh = mesh
		dot.material_override = mat
		dot.position = from.lerp(to, float(i) / float(n - 1))
		root.add_child(dot)
	return root


func _w_dot(at: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.022
	mesh.height = 0.044
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.4
	mi.material_override = mat
	mi.position = at
	return mi


## EXPRESSION — a board standing over the arrows facing the player, writing the identity
## out with the components substituted, between two emissive rules in the result's green.
func _w_board(neg_b: Vector3, result: Vector3) -> Node3D:
	var board := Node3D.new()
	board.name = "WorkingsBoard"
	board.position = Vector3(0.0, max_vector_length + 0.52, 0.0)
	var w: float = max_vector_length * 1.7
	var h: float = w * 0.30
	var plate := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(w, h, 0.02)
	plate.mesh = box
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color(0.81, 0.79, 0.75)
	pm.roughness = 0.92
	plate.material_override = pm
	board.add_child(plate)
	var rule_mat := StandardMaterial3D.new()
	rule_mat.albedo_color = color_result
	rule_mat.emission_enabled = true
	rule_mat.emission = color_result
	rule_mat.emission_energy_multiplier = 2.0
	for sy in [1.0, -1.0]:
		var rule := MeshInstance3D.new()
		var rb := BoxMesh.new()
		rb.size = Vector3(w, h * 0.06, 0.024)
		rule.mesh = rb
		rule.material_override = rule_mat
		rule.position = Vector3(0.0, sy * h * 0.5, 0.006)
		board.add_child(rule)
	var l := Label3D.new()
	l.name = "Algebra"
	# `head`, not `h`: this function already has a float h (the board height, used
	# by pixel_size four lines down), and a second `var h` in the same scope is a
	# parse error that stops the whole script loading.
	var head: String = _head_symbol()
	var t: String = _tail_symbol()
	l.text = "%s − %s  =  %s + (−%s)\n(%+.2f, %+.2f, %+.2f) + (%+.2f, %+.2f, %+.2f)\n=  (%+.2f, %+.2f, %+.2f)" % [
		head, t, head, t,
		_ord_head.x, _ord_head.y, _ord_head.z, neg_b.x, neg_b.y, neg_b.z,
		result.x, result.y, result.z]
	l.font_size = 30
	l.pixel_size = h / 300.0
	l.modulate = Color(0.17, 0.17, 0.19)
	l.outline_size = 5
	l.outline_modulate = Color(0.90, 0.88, 0.84, 0.9)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = Vector3(0.0, 0.0, 0.02)
	board.add_child(l)
	return board
