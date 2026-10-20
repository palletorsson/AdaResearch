extends Node3D
## The old arrow's place becomes a hollow volume. Only the first carried point
## can grant the ability. The point stays available to the coordinate lesson.
const ABILITY := preload("res://commons/hazards/becoming_catalyst/first_catalyst_ability.gd")
const CENTRE := Vector3(0, 1.24, 0)
const RADIUS := 0.24
const DWELL_SECONDS := 0.18
var activated := false
var field: MeshInstance3D
var instruction: Label3D
var _candidate: Node3D
var _dwell := 0.0
var _manager: Node
## Optional session owner for an isolated playtest; normal halls use the autoload.
var capability_source: Node

func _ready() -> void:
	name = "FirstCatalystField"
	add_to_group("first_catalyst_field")
	_make_plinth()
	field = ABILITY.make_glow(RADIUS)
	field.name = "HollowField"
	field.position = CENTRE
	field.material_override = field.material_override.duplicate()
	field.material_override.set_shader_parameter("strength", 0.65)
	add_child(field)
	for axis in [Vector3.ZERO, Vector3(PI / 2, 0, 0)]:
		var ring := MeshInstance3D.new()
		var mesh := TorusMesh.new()
		mesh.inner_radius = RADIUS - 0.002
		mesh.outer_radius = RADIUS + 0.002
		mesh.rings = 48
		mesh.ring_segments = 6
		ring.mesh = mesh
		ring.position = CENTRE
		ring.rotation = axis
		var finish := StandardMaterial3D.new()
		finish.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		finish.albedo_color = Color(0.60, 0.75, 0.86, 0.5)
		finish.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ring.material_override = finish
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(ring)
	instruction = Label3D.new()
	instruction.name = "Instruction"
	instruction.text = "Place the point in the field."
	instruction.font_size = 40
	instruction.pixel_size = 0.00135
	instruction.modulate = Color(0.1, 0.1, 0.12)
	instruction.outline_size = 0
	instruction.position = Vector3(0, 0.62, 0.361)
	add_child(instruction)
	_manager = capability_source if is_instance_valid(capability_source) else get_node_or_null("/root/CatalystCapabilityManager")
	if _manager != null and _manager.has_first_catalyst():
		_mark_activated()

func _physics_process(delta: float) -> void:
	if activated:
		return
	var found: Node3D = null
	for point in get_tree().get_nodes_in_group("ada_coordinate_point"):
		if accepts(point):
			found = point
			break
	if found == null:
		_candidate = null
		_dwell = 0.0
		return
	if found != _candidate:
		_candidate = found
		_dwell = 0.0
	_dwell += delta
	if _dwell >= DWELL_SECONDS and _manager != null:
		_manager.unlock_first_catalyst()
		_mark_activated()

func accepts(point: Node) -> bool:
	return is_instance_valid(point) and point is Node3D and point.is_inside_tree() \
		and point.is_in_group("first_catalyst_seed") \
		and str(point.get_meta("coordinate_id", "")) == "point_one_main" \
		and point.global_position.distance_to(to_global(CENTRE)) <= RADIUS - 0.07

func _mark_activated() -> void:
	activated = true
	instruction.text = "The form is yours.\nFree your hands. Bring them close.\nAim a hand. Press its trigger.\nSeparate to release the form."
	instruction.font_size = 30
	field.material_override.set_shader_parameter("strength", 1.25)

func _make_plinth() -> void:
	var support := MeshInstance3D.new()
	support.name = "FieldPlinth"
	var box := BoxMesh.new()
	box.size = Vector3(0.72, 0.94, 0.72)
	support.mesh = box
	support.position.y = box.size.y * 0.5
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.9, 0.895, 0.875)
	material.roughness = 0.82
	support.material_override = material
	add_child(support)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var boundary := BoxShape3D.new()
	boundary.size = box.size
	shape.shape = boundary
	body.add_child(shape)
	support.add_child(body)
