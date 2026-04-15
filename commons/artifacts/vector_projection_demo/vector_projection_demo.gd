# vector_projection_demo.gd
# Interactive projection and reflection visualizer
# Shows: proj_B(A) = (A·B/|B|²)B and reflect = A - 2·proj_n(A)
#
# Algorithm: Computes orthogonal projection of vector A onto a plane defined by
# normal n, and the specular reflection of A about that plane. The projection
# strips the normal component: proj_plane(A) = A - (A·n̂)n̂. The reflection
# mirrors A through the plane: reflect(A) = A - 2(A·n̂)n̂. Users drag vector
# endpoints in VR to explore how projection preserves the tangential component
# and how angle of incidence equals angle of reflection.
#
# VR-enabled with grabbable vector endpoints
# QFEP: Projection as "shadow" - reducing dimensions while preserving alignment
#
# @identity
# essence: reflect(A) = A - 2(A.n)n. Projection strips a component; reflection mirrors through a plane. Both are dot-product machines.
# desire: To let the learner tilt a plane and watch a vector bounce — making the law of reflection a spatial experience, not a memorized rule.
# critical_parameter: The normal vector direction. It defines the plane. Tilting it changes what "perpendicular" means and rewrites both projection and reflection.
# triggers: Handle drag (A or n) → five arrows update simultaneously (A, n, projection, reflection, normal component), preset buttons → floor/wall/45deg/glance
# emerges: Angle of incidence equaling angle of reflection — visible in the symmetry of A and its reflection about the translucent plane. Glancing angles produce near-tangent reflections.
# needs: VR grabbable handles [has], preset buttons [has], translucent plane mesh [has]. Missing: bouncing ball animation following the reflection path.
# relationships: Extends dot_product_projector (projection uses dot product). Feeds into normal_force_demo (force decomposition onto surface normal). Used by every billiard/bounce in the engine.
# truth: A mirror does not reverse left and right. It reverses the component perpendicular to its surface. Reflection is subtraction, twice.

extends Node3D

class_name VectorProjectionDemo

# Geometric constants
const PANEL_BACKING_DEPTH := 0.008
const FRAME_THICKNESS := 0.004
const FRAME_DEPTH := 0.01
const LABEL_PIXEL_SIZE := 0.001
const LABEL_Z_OFFSET := 0.002
const AXIS_LINE_RADIUS := 0.005
const ORIGIN_RADIUS := 0.03
const HANDLE_RADIUS := 0.04
const HANDLE_COLLISION_RADIUS := 0.06
const DROP_LINE_RADIUS := 0.004

## Maximum length vectors can extend from origin
@export_range(0.1, 5.0, 0.1) var max_vector_length: float = 1.2
## Thickness of arrow shafts for vector display
@export_range(0.005, 0.1, 0.005) var arrow_thickness: float = 0.025

## Vector A (incident/source) — drag handle in VR to change
@export var vector_a: Vector3 = Vector3(0.6, 0.7, 0.2):
	set(value):
		vector_a = value.limit_length(max_vector_length)
		if is_inside_tree():
			_update_visualization()

## Normal vector defining the reflection plane — drag handle in VR to change
@export var normal: Vector3 = Vector3(0.0, 1.0, 0.0):
	set(value):
		normal = value.normalized() * 0.6 if value.length() > 0.01 else Vector3(0, 1, 0) * 0.6
		if is_inside_tree():
			_update_visualization()

## Color for vector A (incident ray)
@export var color_a: Color = Color(1.0, 0.3, 0.3)
## Color for the surface normal
@export var color_normal: Color = Color(0.3, 0.8, 1.0)
## Color for the plane projection component
@export var color_projection: Color = Color(0.3, 1.0, 0.4)
## Color for the reflected vector
@export var color_reflection: Color = Color(1.0, 0.6, 0.8)
## Color for the normal projection component (ghost arrow)
@export var color_proj_normal: Color = Color(1.0, 0.8, 0.3, 0.6)
## Background color for info panels
@export var panel_color: Color = Color(0.06, 0.06, 0.08, 0.9)

var _arrow_a: Node3D
var _arrow_normal: Node3D
var _arrow_projection: Node3D
var _arrow_reflection: Node3D
var _arrow_proj_normal: Node3D
var _plane_mesh: MeshInstance3D
var _drop_line: MeshInstance3D
var _handle_a: Node3D
var _handle_n: Node3D
var _title_panel: Node3D
var _formula_panel: Node3D
var _control_panel: Node3D

var _label_a: Label3D
var _label_n: Label3D
var _label_proj: Label3D
var _label_refl: Label3D

var _axes_container: Node3D

# Shared materials (allocated once, reused across panels/frames)
var _frame_mat: StandardMaterial3D
var _panel_backing_mat: StandardMaterial3D

var _rack_panel: Node3D

## Builds a labeled panel with backing mesh and frame border
func _create_text_panel(panel_name: String, text: String, pos: Vector3,
		size: Vector2 = Vector2(0.3, 0.08), font_size: int = 16,
		alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Node3D:
	var panel = Node3D.new()
	panel.name = panel_name
	panel.position = pos

	var backing = MeshInstance3D.new()
	backing.name = "Backing"
	var box = BoxMesh.new()
	box.size = Vector3(size.x, size.y, PANEL_BACKING_DEPTH)
	backing.mesh = box
	backing.material_override = _panel_backing_mat
	backing.position.z = -0.005
	panel.add_child(backing)

	_add_panel_frame(panel, size)

	var label = Label3D.new()
	label.name = "Label"
	label.text = text
	label.pixel_size = LABEL_PIXEL_SIZE
	label.font_size = font_size
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position.z = LABEL_Z_OFFSET
	panel.add_child(label)

	return panel

## Adds a thin metallic frame border around a panel using MultiMesh
func _add_panel_frame(panel: Node3D, size: Vector2):
	var half_w = size.x / 2.0
	var half_h = size.y / 2.0

	var unit_box := BoxMesh.new()
	unit_box.size = Vector3(1, 1, 1)

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = unit_box
	mm.instance_count = 4

	# Horizontal edges (top and bottom)
	var h_size = Vector3(size.x + FRAME_THICKNESS * 2, FRAME_THICKNESS, FRAME_DEPTH)
	var frame_z = -FRAME_DEPTH / 2.0 + LABEL_Z_OFFSET
	for i in 2:
		var y_mult = -1.0 + i * 2.0
		var xf = Transform3D(Basis().scaled(h_size), Vector3(0, half_h * y_mult, frame_z))
		mm.set_instance_transform(i, xf)

	# Vertical edges (left and right)
	var v_size = Vector3(FRAME_THICKNESS, size.y, FRAME_DEPTH)
	for i in 2:
		var x_mult = -1.0 + i * 2.0
		var xf = Transform3D(Basis().scaled(v_size), Vector3(half_w * x_mult, 0, frame_z))
		mm.set_instance_transform(2 + i, xf)

	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = _frame_mat
	panel.add_child(mmi)

## Returns the Label3D child from a panel created by _create_text_panel
func _get_panel_label(panel: Node3D) -> Label3D:
	return panel.get_node_or_null("Label") as Label3D

func _ready():
	_init_shared_materials()
	_create_base()
	_create_coordinate_axes()
	_create_plane()
	_create_arrows()
	_create_vector_labels()
	_create_drop_line()
	_create_handles()
	_create_labels()
	_create_vr_controls()
	_update_visualization()

## Initializes reusable material templates
func _init_shared_materials():
	_frame_mat = StandardMaterial3D.new()
	_frame_mat.albedo_color = Color(0.3, 0.32, 0.35)
	_frame_mat.metallic = 0.5
	_frame_mat.roughness = 0.4

	_panel_backing_mat = StandardMaterial3D.new()
	_panel_backing_mat.albedo_color = panel_color
	_panel_backing_mat.metallic = 0.2
	_panel_backing_mat.roughness = 0.8

## Creates the white origin sphere at Vector3.ZERO
func _create_base():
	var origin = MeshInstance3D.new()
	origin.name = "Origin"
	var sphere = SphereMesh.new()
	sphere.radius = ORIGIN_RADIUS
	sphere.height = ORIGIN_RADIUS * 2
	origin.mesh = sphere
	var origin_mat = StandardMaterial3D.new()
	origin_mat.albedo_color = Color(1, 1, 1)
	origin_mat.emission_enabled = true
	origin_mat.emission = Color(1, 1, 1)
	origin_mat.emission_energy_multiplier = 0.3
	origin.material_override = origin_mat
	add_child(origin)

## Builds X/Y/Z axis indicators extending beyond max_vector_length
func _create_coordinate_axes():
	_axes_container = Node3D.new()
	_axes_container.name = "Axes"
	add_child(_axes_container)

	var axis_length = max_vector_length * 1.3
	_create_axis_line(Vector3(axis_length, 0, 0), Color(1.0, 0.3, 0.3, 0.5), "X")
	_create_axis_line(Vector3(0, axis_length, 0), Color(0.3, 1.0, 0.3, 0.5), "Y")
	_create_axis_line(Vector3(0, 0, axis_length), Color(0.3, 0.5, 1.0, 0.5), "Z")

## Creates a single axis cylinder with endpoint label
func _create_axis_line(direction: Vector3, color: Color, label_text: String):
	var length = direction.length()
	var norm = direction.normalized()

	var shaft = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = AXIS_LINE_RADIUS
	cylinder.bottom_radius = AXIS_LINE_RADIUS
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

## Creates billboarded labels that float near each vector's midpoint
func _create_vector_labels():
	_label_a = _create_vector_label("A", color_a)
	_label_n = _create_vector_label("n", color_normal)
	_label_proj = _create_vector_label("proj", color_projection)
	_label_refl = _create_vector_label("refl", color_reflection)
	add_child(_label_a)
	add_child(_label_n)
	add_child(_label_proj)
	add_child(_label_refl)

## Builds a single billboarded label with outline for readability
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

## Creates the semi-transparent reflection plane mesh
func _create_plane():
	_plane_mesh = MeshInstance3D.new()
	_plane_mesh.name = "ReflectionPlane"
	var plane = PlaneMesh.new()
	plane.size = Vector2(1.2, 1.2)
	_plane_mesh.mesh = plane

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.4, 0.6, 0.25)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 0.3
	_plane_mesh.material_override = mat
	add_child(_plane_mesh)

## Creates all five vector arrows (A, normal, projection, reflection, normal component)
func _create_arrows():
	_arrow_a = _create_arrow("ArrowA", color_a)
	_arrow_normal = _create_arrow("ArrowNormal", color_normal)
	_arrow_projection = _create_arrow("ArrowProjection", color_projection)
	_arrow_reflection = _create_arrow("ArrowReflection", color_reflection)
	_arrow_proj_normal = _create_arrow("ArrowProjNormal", color_proj_normal, true)

	add_child(_arrow_a)
	add_child(_arrow_normal)
	add_child(_arrow_projection)
	add_child(_arrow_reflection)
	add_child(_arrow_proj_normal)

## Builds a single arrow (shaft cylinder + cone head) with optional ghost styling
func _create_arrow(arrow_name: String, color: Color, ghost: bool = false) -> Node3D:
	var arrow = Node3D.new()
	arrow.name = arrow_name

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

## Creates the perpendicular drop line from A to its plane projection
func _create_drop_line():
	_drop_line = MeshInstance3D.new()
	_drop_line.name = "DropLine"
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = DROP_LINE_RADIUS
	cylinder.bottom_radius = DROP_LINE_RADIUS
	cylinder.height = 1.0
	_drop_line.mesh = cylinder

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 1, 1, 0.4)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_drop_line.material_override = mat
	add_child(_drop_line)

## Creates grabbable handle spheres at vector A and normal endpoints
func _create_handles():
	_handle_a = _create_handle("HandleA", color_a)
	_handle_a.position = vector_a
	add_child(_handle_a)

	_handle_n = _create_handle("HandleN", color_normal)
	_handle_n.position = normal
	add_child(_handle_n)

## Builds a single grabbable handle with collision area for VR interaction
func _create_handle(handle_name: String, color: Color) -> Node3D:
	var handle = Node3D.new()
	handle.name = handle_name

	var sphere = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = HANDLE_RADIUS
	mesh.height = HANDLE_RADIUS * 2
	sphere.mesh = mesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.4
	sphere.material_override = mat
	handle.add_child(sphere)

	var area = Area3D.new()
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = HANDLE_COLLISION_RADIUS
	collision.shape = shape
	area.add_child(collision)
	handle.add_child(area)

	return handle

## Creates the title and formula info panels
func _create_labels():
	_title_panel = _create_text_panel(
		"TitlePanel",
		"PROJECTION & REFLECTION",
		Vector3(0, max_vector_length + 0.3, -0.3),
		Vector2(0.46, 0.07),
		20
	)
	_title_panel.rotation_degrees = Vector3(0, 180, 0)
	add_child(_title_panel)

	_formula_panel = _create_text_panel(
		"FormulaPanel",
		"",
		Vector3(-max_vector_length - 0.2, max_vector_length * 0.5, 0),
		Vector2(0.52, 0.18),
		11
	)
	_formula_panel.rotation_degrees = Vector3(0, 90, 0)
	add_child(_formula_panel)

## Builds the VR preset button panel with FLOOR/WALL/45deg/GLANCE/RESET buttons
func _create_vr_controls():
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_rack_panel = RackTpl.create_panel("PROJECTION", [
		[
			{"type": "button", "label": "FLOOR"},
			{"type": "button", "label": "WALL"},
			{"type": "button", "label": "45deg"},
			{"type": "button", "label": "GLANCE"},
			{"type": "button", "label": "RESET"},
		],
	])
	_rack_panel.position = Vector3(0, 0.04, max_vector_length + 0.38)
	_rack_panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(_rack_panel)
	_control_panel = _rack_panel

	var presets = [
		[Vector3(0.5, 0.5, 0.2), Vector3(0, 1, 0)],
		[Vector3(0.5, 0.3, 0.4), Vector3(1, 0, 0)],
		[Vector3(0.6, 0.4, 0), Vector3(0.707, 0.707, 0)],
		[Vector3(0.7, 0.1, 0), Vector3(0, 1, 0)],
		[Vector3(0.5, 0.6, 0.2), Vector3(0, 1, 0)],
	]

	for i in range(presets.size()):
		var btn = _rack_panel.find_child("Btn_%d" % i, true, false)
		if btn:
			var va = presets[i][0]
			var vn = presets[i][1]
			var area = btn.get_node_or_null("InteractableAreaButton")
			if area:
				area.button_pressed.connect(func(_b): _apply_preset(va, vn))

## Sets vectors to a named preset configuration
func _apply_preset(va: Vector3, vn: Vector3):
	vector_a = va
	normal = vn.normalized() * 0.5
	_handle_a.position = vector_a
	_handle_n.position = normal

## Recalculates projection, reflection, and updates all visual elements
func _update_visualization():
	var n_unit = normal.normalized()

	# Projection of A onto normal (component along normal)
	var proj_onto_normal = n_unit * vector_a.dot(n_unit)

	# Projection onto plane (perpendicular to normal) = A - proj_onto_normal
	var proj_onto_plane = vector_a - proj_onto_normal

	# Reflection: A - 2 * proj_onto_normal
	var reflection = vector_a - 2.0 * proj_onto_normal

	# Update arrows
	_position_arrow(_arrow_a, Vector3.ZERO, vector_a)
	_position_arrow(_arrow_normal, Vector3.ZERO, normal)
	_position_arrow(_arrow_projection, Vector3.ZERO, proj_onto_plane)
	_position_arrow(_arrow_reflection, Vector3.ZERO, reflection)
	_position_arrow(_arrow_proj_normal, proj_onto_plane, vector_a)

	# Update vector labels
	_label_a.position = vector_a * 0.5 + Vector3(0.04, 0.04, 0)
	_label_n.position = normal * 0.5 + Vector3(0.04, 0.04, 0)
	_label_proj.position = proj_onto_plane * 0.5 + Vector3(0, -0.04, 0.04)
	_label_refl.position = reflection * 0.5 + Vector3(0.04, 0, 0.04)

	# Update plane orientation
	_update_plane_orientation(n_unit)

	# Update drop line
	_update_drop_line(vector_a, proj_onto_plane)

	# Update labels
	_update_labels(n_unit, proj_onto_plane, reflection, proj_onto_normal)

## Positions an arrow's shaft and head to point from start to end
func _position_arrow(arrow: Node3D, start: Vector3, end: Vector3):
	var direction = end - start
	var length = direction.length()

	if length < 0.01:
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

## Orients the reflection plane mesh perpendicular to the normal vector
func _update_plane_orientation(n: Vector3):
	var tangent = n.cross(Vector3.RIGHT)
	if tangent.length() < 0.001:
		tangent = n.cross(Vector3.FORWARD)
	tangent = tangent.normalized()
	var bitangent = n.cross(tangent).normalized()
	_plane_mesh.transform.basis = Basis(tangent, bitangent, n)

## Updates the perpendicular drop line between A's tip and its plane projection
func _update_drop_line(a_tip: Vector3, proj: Vector3):
	var perp = a_tip - proj
	if perp.length() < 0.01:
		_drop_line.visible = false
		return
	_drop_line.visible = true

	var mid = (a_tip + proj) / 2.0
	_drop_line.position = mid
	_drop_line.scale = Vector3(1, perp.length(), 1)

	var up = Vector3.UP
	if abs(perp.normalized().dot(up)) > 0.99:
		up = Vector3.FORWARD
	_drop_line.look_at(_drop_line.global_position + perp, up)
	_drop_line.rotate_object_local(Vector3.RIGHT, PI/2)

## Updates the formula panel with current vector values and angle
func _update_labels(n_unit: Vector3, proj_plane: Vector3, reflection: Vector3, proj_n: Vector3):
	var angle = 0.0
	if vector_a.length() > 0.001:
		angle = acos(clampf(vector_a.normalized().dot(n_unit), -1.0, 1.0))

	var label = _get_panel_label(_formula_panel)
	if label:
		label.text = "A = (%.2f, %.2f, %.2f)\n" % [vector_a.x, vector_a.y, vector_a.z]
		label.text += "n = (%.2f, %.2f, %.2f)\n" % [n_unit.x, n_unit.y, n_unit.z]
		label.text += "proj_plane = (%.2f, %.2f, %.2f)\n" % [proj_plane.x, proj_plane.y, proj_plane.z]
		label.text += "reflection = (%.2f, %.2f, %.2f)\n" % [reflection.x, reflection.y, reflection.z]
		label.text += "angle to normal = %.1f°" % rad_to_deg(angle)

func _process(_delta):
	if _handle_a and _handle_a.position != vector_a:
		vector_a = _handle_a.position
	if _handle_n:
		var new_n = _handle_n.position
		if new_n.length() > 0.01 and new_n != normal:
			normal = new_n.normalized() * 0.5
			_handle_n.position = normal

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: _apply_preset(Vector3(0.5, 0.5, 0.2), Vector3(0, 1, 0))
			KEY_2: _apply_preset(Vector3(0.5, 0.3, 0.4), Vector3(1, 0, 0))
			KEY_3: _apply_preset(Vector3(0.6, 0.4, 0), Vector3(0.707, 0.707, 0))
			KEY_4: _apply_preset(Vector3(0.7, 0.1, 0), Vector3(0, 1, 0))
			KEY_R: _apply_preset(Vector3(0.5, 0.6, 0.2), Vector3(0, 1, 0))

func _exit_tree():
	for child in get_children():
		if is_instance_valid(child) and not child.is_queued_for_deletion():
			child.queue_free()

## Sets both vectors programmatically and updates handle positions
func set_vectors(a: Vector3, n: Vector3):
	vector_a = a
	normal = n.normalized() * 0.5
	_handle_a.position = vector_a
	_handle_n.position = normal

## Returns the projection of A onto the plane (perpendicular to normal)
func get_projection() -> Vector3:
	var n_unit = normal.normalized()
	return vector_a - n_unit * vector_a.dot(n_unit)

## Returns the reflection of A about the plane defined by the normal
func get_reflection() -> Vector3:
	var n_unit = normal.normalized()
	return vector_a - 2.0 * n_unit * vector_a.dot(n_unit)

## Grid system integration point for positioning and configuration
func apply_grid_config(config_data: Dictionary) -> void:
	pass
