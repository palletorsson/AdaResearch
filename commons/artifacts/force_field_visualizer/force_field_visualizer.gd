# force_field_visualizer.gd
# Vector field visualization for forces
# Shows gravity, electric field, or custom fields as arrow grids
#
# QFEP: Fields as invisible structure — order you can't see until you probe it

extends Node3D

class_name ForceFieldVisualizer

## Field dimensions
@export var field_size: float = 0.8
@export var grid_resolution: int = 8

## Field type
enum FieldType { GRAVITY, POINT_CHARGE, DIPOLE, VORTEX, CUSTOM }
@export var field_type: FieldType = FieldType.POINT_CHARGE:
	set(value):
		field_type = value
		_update_field()

## Field parameters
@export var field_strength: float = 1.0:
	set(value):
		field_strength = clampf(value, 0.1, 5.0)
		_update_field()

## Source position (for point fields)
@export var source_position: Vector3 = Vector3.ZERO:
	set(value):
		source_position = value
		if _source_marker:
			_source_marker.position = source_position
		_update_field()

## Colors
@export var color_positive: Color = Color(1.0, 0.3, 0.3)  # Red - outward/positive
@export var color_negative: Color = Color(0.3, 0.5, 1.0)  # Blue - inward/negative
@export var color_source: Color = Color(1.0, 0.8, 0.3)    # Yellow - source

# Visuals
var _arrows: Array[Node3D] = []
var _source_marker: MeshInstance3D
var _source_2_marker: MeshInstance3D  # For dipole
var _info_label: Label3D
var _control_panel: Node3D

const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")
const SLIDER_HORIZONTAL = preload("res://commons/interactables/slider_horizontal.tscn")

func _ready():
	_create_base()
	_create_arrows()
	_create_source_markers()
	_create_labels()
	_create_vr_controls()
	_update_field()

func _create_base():
	# Transparent base plane
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

func _create_arrows():
	var cell_size = field_size / float(grid_resolution)
	var half_size = field_size / 2.0
	
	for j in range(grid_resolution):
		for i in range(grid_resolution):
			var arrow = _create_arrow()
			var x = -half_size + (i + 0.5) * cell_size
			var z = -half_size + (j + 0.5) * cell_size
			arrow.position = Vector3(x, 0, z)
			_arrows.append(arrow)
			add_child(arrow)

func _create_arrow() -> Node3D:
	var arrow = Node3D.new()
	arrow.name = "FieldArrow"
	
	var shaft = MeshInstance3D.new()
	shaft.name = "Shaft"
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.004
	cylinder.bottom_radius = 0.004
	cylinder.height = 0.05
	shaft.mesh = cylinder
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.WHITE
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.3
	shaft.material_override = mat
	shaft.position = Vector3(0, 0.025, 0)
	arrow.add_child(shaft)
	
	var head = MeshInstance3D.new()
	head.name = "Head"
	var cone = CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.012
	cone.height = 0.02
	head.mesh = cone
	head.material_override = mat
	head.position = Vector3(0, 0.06, 0)
	arrow.add_child(head)
	
	return arrow

func _create_source_markers():
	_source_marker = MeshInstance3D.new()
	_source_marker.name = "SourceMarker"
	var sphere = SphereMesh.new()
	sphere.radius = 0.03
	sphere.height = 0.06
	_source_marker.mesh = sphere
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color_source
	mat.emission_enabled = true
	mat.emission = color_source
	mat.emission_energy_multiplier = 0.5
	_source_marker.material_override = mat
	_source_marker.position = source_position
	add_child(_source_marker)
	
	# Second source for dipole
	_source_2_marker = MeshInstance3D.new()
	_source_2_marker.name = "Source2Marker"
	_source_2_marker.mesh = sphere.duplicate()
	var mat2 = StandardMaterial3D.new()
	mat2.albedo_color = color_negative
	mat2.emission_enabled = true
	mat2.emission = color_negative
	mat2.emission_energy_multiplier = 0.5
	_source_2_marker.material_override = mat2
	_source_2_marker.visible = false
	add_child(_source_2_marker)

func _create_labels():
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.002
	_info_label.font_size = 16
	_info_label.position = Vector3(0, 0.2, 0)
	_info_label.text = "FORCE FIELD"
	add_child(_info_label)

func _create_vr_controls():
	_control_panel = Node3D.new()
	_control_panel.name = "ControlPanel"
	_control_panel.position = Vector3(0, 0.02, field_size/2 + 0.15)
	_control_panel.rotation_degrees = Vector3(-30, 180, 0)
	add_child(_control_panel)
	
	# Panel backing
	var panel_back = MeshInstance3D.new()
	var panel_mesh = BoxMesh.new()
	panel_mesh.size = Vector3(0.45, 0.12, 0.01)
	panel_back.mesh = panel_mesh
	var panel_mat = StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.08, 0.08, 0.1)
	panel_mat.metallic = 0.3
	panel_back.material_override = panel_mat
	_control_panel.add_child(panel_back)
	
	# Field type buttons
	var types = ["GRAVITY", "CHARGE", "DIPOLE", "VORTEX"]
	for i in range(types.size()):
		var btn = PUSH_BUTTON.instantiate()
		btn.name = "Type%d" % i
		btn.position = Vector3(-0.15 + i * 0.1, 0.025, -0.005)
		btn.scale = Vector3(0.65, 0.65, 0.65)
		_control_panel.add_child(btn)
		_add_button_label(btn, types[i])
		
		var type_idx = i
		var area = btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(): field_type = type_idx as FieldType)
	
	# Strength slider
	var strength_slider = SLIDER_HORIZONTAL.instantiate()
	strength_slider.name = "StrengthSlider"
	strength_slider.position = Vector3(0, -0.025, -0.005)
	strength_slider.scale = Vector3(0.8, 0.8, 0.8)
	var strength_label = strength_slider.get_node_or_null("Frame/LabelName")
	if strength_label:
		strength_label.text = "STRENGTH"
	_control_panel.add_child(strength_slider)
	strength_slider.slider_moved.connect(func(_pos): 
		if strength_slider.has_method("get_normalized_value"):
			field_strength = 0.1 + strength_slider.get_normalized_value() * 4.9
	)

func _add_button_label(btn: Node, text: String):
	var lbl = Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.0008
	lbl.font_size = 6
	lbl.position = Vector3(0, -0.02, 0.01)
	btn.add_child(lbl)

func _update_field():
	for arrow in _arrows:
		var pos = arrow.position
		var field = _calculate_field(pos)
		_orient_arrow(arrow, field)
	
	# Update source visibility
	_source_marker.visible = field_type in [FieldType.POINT_CHARGE, FieldType.DIPOLE, FieldType.VORTEX]
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
			# Tangent field: perpendicular to r
			var tangent = Vector3(-r.z, 0, r.x).normalized()
			return tangent * field_strength / (dist + 0.1)
		
		_:
			return Vector3.ZERO

func _orient_arrow(arrow: Node3D, field: Vector3):
	var magnitude = field.length()
	
	if magnitude < 0.001:
		arrow.visible = false
		return
	arrow.visible = true
	
	# Scale arrow by field magnitude (clamped)
	var scale_factor = clampf(magnitude * 0.5, 0.3, 2.0)
	arrow.scale = Vector3(scale_factor, scale_factor, scale_factor)
	
	# Color by direction (outward=red, inward=blue)
	var direction = field.normalized()
	var from_source = (arrow.position - source_position).normalized()
	var alignment = direction.dot(from_source)  # 1=outward, -1=inward
	
	var color: Color
	if field_type == FieldType.GRAVITY:
		color = color_negative  # Always down
	else:
		color = color_negative.lerp(color_positive, (alignment + 1) / 2.0)
	
	var shaft = arrow.get_node("Shaft")
	var head = arrow.get_node("Head")
	
	var mat = shaft.material_override as StandardMaterial3D
	mat.albedo_color = color
	mat.emission = color
	
	head.material_override = mat
	
	# Orient arrow
	arrow.transform.basis = Basis.IDENTITY
	
	if field.length() > 0.001:
		var up = Vector3.UP
		if abs(direction.dot(up)) > 0.99:
			up = Vector3.FORWARD
		arrow.look_at(arrow.global_position + field, up)
		arrow.rotate_object_local(Vector3.RIGHT, -PI/2)

func _update_info():
	var type_names = ["GRAVITY", "POINT CHARGE", "DIPOLE", "VORTEX", "CUSTOM"]
	_info_label.text = "%s FIELD\nStrength: %.1f" % [type_names[field_type], field_strength]

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: field_type = FieldType.GRAVITY
			KEY_2: field_type = FieldType.POINT_CHARGE
			KEY_3: field_type = FieldType.DIPOLE
			KEY_4: field_type = FieldType.VORTEX
			KEY_UP: field_strength = minf(field_strength + 0.2, 5.0)
			KEY_DOWN: field_strength = maxf(field_strength - 0.2, 0.1)

func set_field_type(type: FieldType):
	field_type = type

func set_strength(s: float):
	field_strength = s

func move_source(pos: Vector3):
	source_position = pos
