extends "res://commons/primitives/cubes/grab_cube_grid_snap.gd"
## A hand-scale height control sampling the existing room-scale HSV field.
## Physical height .65..1.85 m corresponds to the column's .46..4.60 m span.
signal sample_changed(hsv: Vector3, rgb: Color)
const LOW_HAND := 0.65
const HIGH_HAND := 1.85
var field: Node3D
var sampled_hsv := Vector3.ZERO
var sampled_rgb := Color.BLACK
var field_point := Vector3.ZERO
var _last_position := Vector3(INF, INF, INF)
var _readout: Label3D
var _chip: MeshInstance3D

func _ready() -> void:
	super._ready()
	field = get_parent()
	# Keep the inherited pickup and its highlight; enlarge the card, not its root.
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.35, 0.28, 0.035)
	$CollisionShape3D.transform = Transform3D.IDENTITY
	$CollisionShape3D.shape = shape
	_chip = $MeshInstance3D
	_chip.transform = Transform3D.IDENTITY
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.305, 0.095, 0.02)
	_chip.mesh = mesh
	_chip.position = Vector3(0, 0.068, 0.024)
	_chip.material_override = field.make_field_material(0, 0.0, 0.0)
	var back := MeshInstance3D.new()
	back.name = "SamplerCase"
	var case_mesh := BoxMesh.new()
	case_mesh.size = Vector3(0.35, 0.28, 0.025)
	back.mesh = case_mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("eeeade")
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	back.material_override = mat
	add_child(back)
	_readout = $Label
	_readout.transform = Transform3D.IDENTITY
	_readout.position = Vector3(0, -0.062, 0.02)
	_readout.font_size = 26
	_readout.pixel_size = 0.00065
	_readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_readout.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_readout.modulate = Color("161b24")
	_readout.outline_size = 0
	_readout.autowrap_mode = TextServer.AUTOWRAP_OFF
	_readout.no_depth_test = false
	_update_sample()

func _process(_delta: float) -> void:
	if is_instance_valid(field) and field.has_method("sample_volume"):
		_update_sample()

func _update_sample() -> void:
	var p: Vector3 = field.to_local(global_position)
	if p.is_equal_approx(_last_position):
		return
	_last_position = p
	var value: float = clampf((p.y - LOW_HAND) / (HIGH_HAND - LOW_HAND), 0.0, 1.0)
	field_point = Vector3(clampf(p.x, 0, 12.8), lerpf(field.VALUE_BOTTOM, field.VALUE_TOP, value), clampf(p.z, 0, 19.2))
	sampled_hsv = field.hsv_at(field_point)
	sampled_rgb = field.sample_volume(field_point)
	_chip.material_override.set_shader_parameter("sample_hsv", sampled_hsv)
	var boundary := " / EDGE" if p.x<0 or p.x>12.8 or p.z<0 or p.z>19.2 else ""
	_readout.text = "HSV %.2f  %.2f  %.2f\nRGB %.2f  %.2f  %.2f\nFIELD Y %.2f m%s" % [sampled_hsv.x,sampled_hsv.y,sampled_hsv.z,sampled_rgb.r,sampled_rgb.g,sampled_rgb.b,field_point.y,boundary]
	field.move_sample_marker(field_point, sampled_hsv)
	sample_changed.emit(sampled_hsv, sampled_rgb)
