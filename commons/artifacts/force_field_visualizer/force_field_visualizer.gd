# force_field_visualizer.gd
# Vector field visualization for forces
# Shows gravity, electric field, or custom fields as arrow grids
#
# QFEP: Fields as invisible structure — order you can't see until you probe it
#
# @identity
# essence: F(x) = vector at every point. The field precedes the particle. Space is not empty.
# desire: To show the invisible. To make the learner see that empty space carries instructions.
# critical_parameter: Field type (gravity/coulomb/dipole/vortex). Each is a different spatial grammar.
# triggers: Type button → topology changes (radial vs rotational vs superposed), strength slider → arrows grow/shrink
# emerges: Superposition from dipole (two sources cancel/reinforce). Curl from vortex. Convergence from gravity.
# needs: VR type buttons [has], strength slider [has], equation labels [has]. Could use: particle tracer following field lines.
# relationships: Feeds into ForcesSystems (particles in fields). Contrasts with vector_fields (same concept, different rendering).
# truth: Motion is reading, not deciding. The field tells the particle where to go.

extends Node3D

class_name ForceFieldVisualizer

## Visualizes vector force fields as directional arrow grids.
## Computes field vectors (gravity, Coulomb, dipole, vortex) at each grid point
## and renders scaled, colored arrows via MultiMesh showing magnitude and direction.
## Key parameters: field_type selects the equation, field_strength scales magnitude,
## source_position sets the charge/vortex center.

# Arrow geometry constants
const SHAFT_RADIUS := 0.004
const SHAFT_HEIGHT := 0.05
const SHAFT_OFFSET := 0.025
const HEAD_BOTTOM_RADIUS := 0.012
const HEAD_HEIGHT := 0.02
const HEAD_OFFSET := 0.06
const EMISSION_ENERGY := 0.3
const SOURCE_RADIUS := 0.03
const SOURCE_EMISSION_ENERGY := 0.5
const LABEL_PIXEL_SIZE := 0.002
const BUTTON_LABEL_PIXEL_SIZE := 0.0008

## Size of the field grid in world units
@export_range(0.1, 5.0, 0.1) var field_size: float = 0.8
## Number of arrows per axis (total arrows = grid_resolution²)
@export_range(2, 32) var grid_resolution: int = 8

## Field type
enum FieldType { GRAVITY, POINT_CHARGE, DIPOLE, VORTEX, CUSTOM }
## Which force field equation to visualize
@export var field_type: FieldType = FieldType.POINT_CHARGE:
	set(value):
		field_type = value
		_update_field()

## Multiplier for field magnitude (0.1–5.0)
@export_range(0.1, 5.0, 0.1) var field_strength: float = 1.0:
	set(value):
		field_strength = clampf(value, 0.1, 5.0)
		_update_field()

## Source/charge position for point-based fields
@export var source_position: Vector3 = Vector3.ZERO:
	set(value):
		source_position = value
		if _source_marker:
			_source_marker.position = source_position
		_update_field()

## Color for outward/positive field directions
@export var color_positive: Color = Color(1.0, 0.3, 0.3)
## Color for inward/negative field directions
@export var color_negative: Color = Color(0.3, 0.5, 1.0)
## Color for field source markers
@export var color_source: Color = Color(1.0, 0.8, 0.3)

# MultiMesh arrow rendering
var _arrow_positions: Array[Vector3] = []
var _shaft_mm: MultiMesh
var _head_mm: MultiMesh
var _arrow_count: int = 0

# Scene nodes
var _source_marker: MeshInstance3D
var _source_2_marker: MeshInstance3D
var _info_label: Label3D
var _control_panel: Node3D
var _created_nodes: Array[Node] = []


func _ready() -> void:
	_create_base()
	_create_arrows()
	_create_source_markers()
	_create_labels()
	_create_vr_controls()
	_update_field()

func _exit_tree() -> void:
	for node in _created_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_created_nodes.clear()

func _create_base() -> void:
	var base = MeshInstance3D.new()
	base.name = "Base"
	var plane = PlaneMesh.new()
	plane.size = Vector2(field_size, field_size)
	base.mesh = plane

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.1, 0.12, 0.3)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	base.material_override = mat
	base.position = Vector3(0, -0.01, 0)
	add_child(base)
	_created_nodes.append(base)

func _create_arrows() -> void:
	var cell_size = field_size / maxf(float(grid_resolution), 1.0)
	var half_size = field_size / 2.0
	_arrow_count = grid_resolution * grid_resolution

	# Pre-size position array
	_arrow_positions.resize(_arrow_count)
	var idx := 0
	for j in range(grid_resolution):
		for i in range(grid_resolution):
			var x = -half_size + (i + 0.5) * cell_size
			var z = -half_size + (j + 0.5) * cell_size
			_arrow_positions[idx] = Vector3(x, 0, z)
			idx += 1

	# Shared material for all arrow instances
	var arrow_mat := StandardMaterial3D.new()
	arrow_mat.vertex_color_use_as_albedo = true

	# Shaft MultiMesh (cylinder bodies)
	var shaft_mesh := CylinderMesh.new()
	shaft_mesh.top_radius = SHAFT_RADIUS
	shaft_mesh.bottom_radius = SHAFT_RADIUS
	shaft_mesh.height = SHAFT_HEIGHT

	_shaft_mm = MultiMesh.new()
	_shaft_mm.transform_format = MultiMesh.TRANSFORM_3D
	_shaft_mm.use_colors = true
	_shaft_mm.mesh = shaft_mesh
	_shaft_mm.instance_count = _arrow_count

	var shaft_mmi := MultiMeshInstance3D.new()
	shaft_mmi.name = "ShaftMultiMesh"
	shaft_mmi.multimesh = _shaft_mm
	shaft_mmi.material_override = arrow_mat
	add_child(shaft_mmi)
	_created_nodes.append(shaft_mmi)

	# Head MultiMesh (cone tips)
	var head_mesh := CylinderMesh.new()
	head_mesh.top_radius = 0.0
	head_mesh.bottom_radius = HEAD_BOTTOM_RADIUS
	head_mesh.height = HEAD_HEIGHT

	_head_mm = MultiMesh.new()
	_head_mm.transform_format = MultiMesh.TRANSFORM_3D
	_head_mm.use_colors = true
	_head_mm.mesh = head_mesh
	_head_mm.instance_count = _arrow_count

	var head_mmi := MultiMeshInstance3D.new()
	head_mmi.name = "HeadMultiMesh"
	head_mmi.multimesh = _head_mm
	head_mmi.material_override = arrow_mat
	add_child(head_mmi)
	_created_nodes.append(head_mmi)

func _create_source_markers() -> void:
	_source_marker = MeshInstance3D.new()
	_source_marker.name = "SourceMarker"
	var sphere = SphereMesh.new()
	sphere.radius = SOURCE_RADIUS
	sphere.height = SOURCE_RADIUS * 2.0
	_source_marker.mesh = sphere

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color_source
	mat.emission_enabled = true
	mat.emission = color_source
	mat.emission_energy_multiplier = SOURCE_EMISSION_ENERGY
	_source_marker.material_override = mat
	_source_marker.position = source_position
	add_child(_source_marker)
	_created_nodes.append(_source_marker)

	# Second source for dipole
	_source_2_marker = MeshInstance3D.new()
	_source_2_marker.name = "Source2Marker"
	_source_2_marker.mesh = sphere.duplicate()
	var mat2 = StandardMaterial3D.new()
	mat2.albedo_color = color_negative
	mat2.emission_enabled = true
	mat2.emission = color_negative
	mat2.emission_energy_multiplier = SOURCE_EMISSION_ENERGY
	_source_2_marker.material_override = mat2
	_source_2_marker.visible = false
	add_child(_source_2_marker)
	_created_nodes.append(_source_2_marker)

func _create_labels() -> void:
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = LABEL_PIXEL_SIZE
	_info_label.font_size = 16
	_info_label.position = Vector3(0, 0.2, 0)
	_info_label.text = "FORCE FIELD"
	add_child(_info_label)
	_created_nodes.append(_info_label)

func _create_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_panel("FORCE FIELD", [
		[
			{"type": "slider_h", "label": "STRENGTH", "default": (field_strength - 0.1) / 4.9},
		],
		[
			{"type": "button", "label": "GRAVITY"},
			{"type": "button", "label": "CHARGE"},
			{"type": "button", "label": "DIPOLE"},
			{"type": "button", "label": "VORTEX"},
		],
	])
	_control_panel.position = Vector3(0, 0.02, field_size / 2.0 + 0.15)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)
	_created_nodes.append(_control_panel)

	# Strength slider
	var strength_slider = _control_panel.find_child("Param_0", true, false)
	if strength_slider and strength_slider.has_signal("slider_moved"):
		strength_slider.slider_moved.connect(func(_pos):
			if strength_slider.has_method("get_normalized_value"):
				field_strength = 0.1 + strength_slider.get_normalized_value() * 4.9
		)

	# Field type buttons
	var type_names = ["GRAVITY", "CHARGE", "DIPOLE", "VORTEX"]
	for i in range(type_names.size()):
		var btn: Node = _control_panel.find_child("Btn_%d" % i, true, false)
		if btn:
			var type_idx = i
			var area = btn.get_node_or_null("InteractableAreaButton")
			if area:
				area.button_pressed.connect(func(_b): field_type = type_idx as FieldType)

func _update_field() -> void:
	if not _shaft_mm:
		return
	for i in _arrow_count:
		var pos = _arrow_positions[i]
		var field = _calculate_field(pos)
		_orient_arrow(i, pos, field)

	# Update source visibility
	if _source_marker:
		_source_marker.visible = field_type in [FieldType.POINT_CHARGE, FieldType.DIPOLE, FieldType.VORTEX]
	if _source_2_marker:
		_source_2_marker.visible = field_type == FieldType.DIPOLE
		if field_type == FieldType.DIPOLE:
			_source_2_marker.position = source_position + Vector3(0.2, 0, 0)

	_update_info()

func _calculate_field(pos: Vector3) -> Vector3:
	match field_type:
		FieldType.GRAVITY:
			return Vector3(0, -field_strength, 0)

		FieldType.POINT_CHARGE:
			var r = pos - source_position
			var dist = r.length()
			if dist < 0.01:
				return Vector3.ZERO
			# Inverse square: F = k/r²
			return r.normalized() * field_strength / (dist * dist + 0.01)

		FieldType.DIPOLE:
			var pos1 = source_position
			var pos2 = source_position + Vector3(0.2, 0, 0)

			var r1 = pos - pos1
			var r2 = pos - pos2
			var d1 = r1.length()
			var d2 = r2.length()

			var field1 = r1.normalized() * field_strength / (d1 * d1 + 0.01) if d1 > 0.01 else Vector3.ZERO
			var field2 = -r2.normalized() * field_strength / (d2 * d2 + 0.01) if d2 > 0.01 else Vector3.ZERO

			return field1 + field2

		FieldType.VORTEX:
			var r = pos - source_position
			var dist = r.length()
			if dist < 0.01:
				return Vector3.ZERO
			# Tangent field: cross(up, r) gives perpendicular direction (counterclockwise)
			var tangent = Vector3(-r.z, 0, r.x).normalized()
			# Strength peaks at mid-range, fades at center and edges (vortex profile)
			var profile = dist / (dist * dist + 0.02)
			return tangent * field_strength * profile

		_:
			return Vector3.ZERO

func _orient_arrow(idx: int, pos: Vector3, field: Vector3) -> void:
	var magnitude = field.length()

	if magnitude < 0.001:
		# Hide instance by scaling to near-zero and moving off-screen
		var hidden_xf := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.001), Vector3(0, -100, 0))
		_shaft_mm.set_instance_transform(idx, hidden_xf)
		_head_mm.set_instance_transform(idx, hidden_xf)
		return

	# Scale arrow by field magnitude (clamped)
	var scale_factor = clampf(magnitude * 0.5, 0.3, 2.0)

	# Color by direction (outward=red, inward=blue)
	var direction = field.normalized()
	var from_source = (pos - source_position).normalized()
	var alignment = direction.dot(from_source)  # 1=outward, -1=inward

	var color: Color
	if field_type == FieldType.GRAVITY:
		color = color_negative  # Always down
	elif field_type == FieldType.VORTEX:
		# Vortex uses angular hue: green→cyan→blue around the circle
		var r = pos - source_position
		var angle = atan2(r.x, r.z)
		var hue = fmod((angle + PI) / TAU + 0.3, 1.0)
		color = Color.from_hsv(hue, 0.7, 1.0)
	else:
		color = color_negative.lerp(color_positive, (alignment + 1.0) / 2.0)

	_shaft_mm.set_instance_color(idx, color)
	_head_mm.set_instance_color(idx, color)

	# Compute arrow orientation
	var up := Vector3.UP
	if abs(direction.dot(up)) > 0.99:
		up = Vector3.FORWARD

	var arrow_xf := Transform3D()
	arrow_xf.origin = pos
	arrow_xf = arrow_xf.looking_at(pos + field, up)
	arrow_xf.basis = arrow_xf.basis * Basis(Vector3.RIGHT, -PI / 2.0)
	arrow_xf.basis = arrow_xf.basis.scaled(Vector3(scale_factor, scale_factor, scale_factor))

	# Shaft at local offset
	var shaft_origin = arrow_xf.origin + arrow_xf.basis * Vector3(0, SHAFT_OFFSET, 0)
	_shaft_mm.set_instance_transform(idx, Transform3D(arrow_xf.basis, shaft_origin))

	# Head at local offset
	var head_origin = arrow_xf.origin + arrow_xf.basis * Vector3(0, HEAD_OFFSET, 0)
	_head_mm.set_instance_transform(idx, Transform3D(arrow_xf.basis, head_origin))

func _update_info() -> void:
	var type_names = ["GRAVITY", "POINT CHARGE", "DIPOLE", "VORTEX", "CUSTOM"]
	var desc := ""
	match field_type:
		FieldType.GRAVITY:
			desc = "F = (0, -g, 0)  uniform downward"
		FieldType.POINT_CHARGE:
			desc = "F = k * r / |r|³  inverse-square"
		FieldType.DIPOLE:
			desc = "F = F₊ + F₋  two opposing charges"
		FieldType.VORTEX:
			desc = "F = tangent(r) × profile(|r|)  curl field"
		_:
			desc = ""
	_info_label.text = "%s FIELD\nStrength: %.1f\n%s" % [type_names[field_type], field_strength, desc]

func _input(event) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: field_type = FieldType.GRAVITY
			KEY_2: field_type = FieldType.POINT_CHARGE
			KEY_3: field_type = FieldType.DIPOLE
			KEY_4: field_type = FieldType.VORTEX
			KEY_UP: field_strength = minf(field_strength + 0.2, 5.0)
			KEY_DOWN: field_strength = maxf(field_strength - 0.2, 0.1)

func set_field_type(type: FieldType) -> void:
	field_type = type

func set_strength(s: float) -> void:
	field_strength = s

func move_source(pos: Vector3) -> void:
	source_position = pos

func apply_grid_config(config_data: Dictionary) -> void:
	pass
