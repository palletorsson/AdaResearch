@tool
extends Node3D

const TWO_PI := PI * 2.0
const GOLDEN_RATIO := 1.618033988749

@export_group("Helix Geometry")
@export_range(0.1, 20.0, 0.05) var helix_radius: float = 0.65:
	set(value):
		if not is_equal_approx(helix_radius, value):
			helix_radius = value
			_queue_rebuild()

@export_range(1.0, 20.0, 0.1) var helix_height: float = 6.0:
	set(value):
		if not is_equal_approx(helix_height, value):
			helix_height = value
			_queue_rebuild()

@export_range(1, 20, 1) var helix_turns: int = 5:
	set(value):
		if helix_turns != value:
			helix_turns = value
			_queue_rebuild()

@export_range(4, 128, 1) var points_per_turn: int = 32:
	set(value):
		if points_per_turn != value:
			points_per_turn = value
			_queue_rebuild()

@export_range(0.02, 0.4, 0.01) var strand_point_radius: float = 0.08:
	set(value):
		if not is_equal_approx(strand_point_radius, value):
			strand_point_radius = value
			_queue_rebuild()

@export_range(6, 64, 1) var strand_segments: int = 24:
	set(value):
		if strand_segments != value:
			strand_segments = value
			_queue_rebuild()

@export_range(1, 16, 1) var rung_every: int = 3:
	set(value):
		if rung_every != value:
			rung_every = value
			_queue_rebuild()

@export var phase_offset: float = 0.0:
	set(value):
		if not is_equal_approx(phase_offset, value):
			phase_offset = value
			_queue_rebuild()

@export var vertical_offset: float = 0.0:
	set(value):
		if not is_equal_approx(vertical_offset, value):
			vertical_offset = value
			_queue_rebuild()

@export_group("Visuals")
@export var strand_color_a: Color = Color(0.2, 0.85, 1.0, 1.0):
	set(value):
		if strand_color_a != value:
			strand_color_a = value
			_queue_rebuild()

@export var strand_color_b: Color = Color(1.0, 0.42, 0.75, 1.0):
	set(value):
		if strand_color_b != value:
			strand_color_b = value
			_queue_rebuild()

@export var rung_color: Color = Color(0.7, 1.0, 0.6, 1.0):
	set(value):
		if rung_color != value:
			rung_color = value
			_queue_rebuild()

@export var axis_color: Color = Color(0.35, 0.65, 1.0, 1.0):
	set(value):
		if axis_color != value:
			axis_color = value
			_queue_rebuild()

@export var glow_energy: float = 4.0:
	set(value):
		if not is_equal_approx(glow_energy, value):
			glow_energy = value
			_queue_rebuild()

@export var use_emission: bool = true:
	set(value):
		if use_emission != value:
			use_emission = value
			_queue_rebuild()

@export var draw_axis: bool = true:
	set(value):
		if draw_axis != value:
			draw_axis = value
			_queue_rebuild()

@export_group("Animation")
@export var auto_rotate: bool = true
@export_range(0.0, 2.0, 0.01) var rotation_speed: float = 0.3
@export var rotate_in_editor: bool = false
@export var animate_phase: bool = false
@export_range(0.0, 2.0, 0.01) var phase_animation_speed: float = 0.5
@export var animate_unwinding: bool = false
@export_range(0.0, 1.0, 0.01) var unwinding_amount: float = 0.0
@export var pulse_effect: bool = false
@export_range(0.0, 2.0, 0.01) var pulse_speed: float = 1.0
@export_range(0.0, 1.0, 0.01) var pulse_intensity: float = 0.3

var _helix_root: Node3D = null
var _rebuild_queued: bool = false
var _time_elapsed: float = 0.0
var _cached_materials: Dictionary = {}

func _ready() -> void:
	set_process(true)
	_queue_rebuild()

func _process(delta: float) -> void:
	if Engine.is_editor_hint() and not rotate_in_editor:
		return

	_time_elapsed += delta

	if auto_rotate:
		rotate_y(rotation_speed * delta)

	if animate_phase:
		var new_phase := fmod(phase_offset + phase_animation_speed * delta, TWO_PI)
		if not is_equal_approx(new_phase, phase_offset):
			phase_offset = new_phase

	if pulse_effect and _helix_root:
		_apply_pulse_effect()

func _queue_rebuild() -> void:
	if not is_inside_tree():
		return
	if _rebuild_queued:
		return
	_rebuild_queued = true
	call_deferred("_rebuild")

func _rebuild() -> void:
	_rebuild_queued = false
	build_double_helix()

func build_double_helix() -> void:
	if _helix_root and is_instance_valid(_helix_root):
		_helix_root.queue_free()
	_helix_root = Node3D.new()
	_helix_root.name = "HelixRoot"
	add_child(_helix_root)
	_assign_owner(_helix_root)

	var valid_points_per_turn: int = max(points_per_turn, 3)
	var total_steps: int = max(2, helix_turns * valid_points_per_turn)
	var vertical_step: float = helix_height / float(total_steps - 1) if total_steps > 1 else 0.0
	var start_height: float = -helix_height * 0.5 + vertical_offset
	var angle_step: float = TWO_PI / float(valid_points_per_turn)

	var positions_a: PackedVector3Array = PackedVector3Array()
	var positions_b: PackedVector3Array = PackedVector3Array()
	positions_a.resize(total_steps)
	positions_b.resize(total_steps)

	var unwind_factor: float = unwinding_amount if animate_unwinding else 0.0

	for i in range(total_steps):
		var t: float = float(i) / float(total_steps - 1) if total_steps > 1 else 0.0
		var angle: float = phase_offset + float(i) * angle_step
		var local_unwind: float = unwind_factor * t
		var effective_angle: float = angle + local_unwind * PI
		var y: float = start_height + float(i) * vertical_step
		var radius_modifier: float = 1.0 + local_unwind * 0.5
		var effective_radius: float = helix_radius * radius_modifier

		var cos_angle: float = cos(effective_angle)
		var sin_angle: float = sin(effective_angle)

		positions_a[i] = Vector3(cos_angle * effective_radius, y, sin_angle * effective_radius)
		var angle_b: float = effective_angle + PI
		positions_b[i] = Vector3(cos(angle_b) * effective_radius, y, sin(angle_b) * effective_radius)

	_create_strand("StrandA", positions_a, strand_color_a)
	_create_strand("StrandB", positions_b, strand_color_b)
	_create_rungs(positions_a, positions_b)
	if draw_axis:
		_create_axis(positions_a, positions_b)

func _create_strand(strand_name: String, positions: PackedVector3Array, base_color: Color) -> void:
	if positions.is_empty():
		return

	var sphere_mesh: SphereMesh = SphereMesh.new()
	sphere_mesh.radius = strand_point_radius
	sphere_mesh.height = strand_point_radius * 2.0
	sphere_mesh.radial_segments = strand_segments
	sphere_mesh.rings = max(4, strand_segments / 2)

	var strand_material: StandardMaterial3D = _get_or_create_material(base_color, true)
	sphere_mesh.material = strand_material

	var multimesh: MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.instance_count = positions.size()
	multimesh.mesh = sphere_mesh

	var count: int = positions.size()
	var denom: float = max(1.0, float(count - 1))

	for i in range(count):
		var pos: Vector3 = positions[i]
		multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, pos))
		var t: float = float(i) / denom
		var wave: float = 0.5 + 0.5 * sin(t * TWO_PI * 2.0)
		var instance_color: Color = base_color.lerp(Color.WHITE, wave * 0.25)
		multimesh.set_instance_color(i, instance_color)

	var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
	instance.name = strand_name
	instance.multimesh = multimesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_helix_root.add_child(instance)
	_assign_owner(instance)

func _create_rungs(positions_a: PackedVector3Array, positions_b: PackedVector3Array) -> void:
	var count: int = min(positions_a.size(), positions_b.size())
	if count < 2:
		return

	var step: int = max(1, rung_every)
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)
	var material: StandardMaterial3D = _get_or_create_material(rung_color, false)
	st.set_material(material)

	for i in range(0, count, step):
		var a: Vector3 = positions_a[i]
		var b: Vector3 = positions_b[i]
		st.set_color(rung_color)
		st.add_vertex(a)
		st.set_color(rung_color)
		st.add_vertex(b)

		var mid: Vector3 = (a + b) * 0.5
		var direction: Vector3 = (b - a).normalized()
		var normal: Vector3 = direction.cross(Vector3.UP)
		if normal.length_squared() < 0.000001:
			normal = direction.cross(Vector3.RIGHT)
			if normal.length_squared() < 0.000001:
				normal = Vector3.FORWARD
		normal = normal.normalized()
		var offset: Vector3 = normal * strand_point_radius * 0.8
		st.set_color(rung_color)
		st.add_vertex(mid + offset)
		st.set_color(rung_color)
		st.add_vertex(mid - offset)

	var mesh: ArrayMesh = st.commit()
	if mesh:
		var instance: MeshInstance3D = MeshInstance3D.new()
		instance.name = "Rungs"
		instance.mesh = mesh
		instance.material_override = material
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_helix_root.add_child(instance)
		_assign_owner(instance)

func _create_axis(positions_a: PackedVector3Array, positions_b: PackedVector3Array) -> void:
	var count: int = min(positions_a.size(), positions_b.size())
	if count < 2:
		return

	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINE_STRIP)
	var material: StandardMaterial3D = _get_or_create_material(axis_color, false)
	st.set_material(material)

	var denom: float = max(1.0, float(count - 1))
	for i in range(count):
		var center: Vector3 = (positions_a[i] + positions_b[i]) * 0.5
		var t: float = float(i) / denom
		var pulse: float = 0.5 + 0.5 * sin(t * TWO_PI * 1.5)
		var color_variation: Color = axis_color.lerp(Color.WHITE, pulse * 0.35)
		st.set_color(color_variation)
		st.add_vertex(center)

	var mesh: ArrayMesh = st.commit()
	if mesh:
		var instance: MeshInstance3D = MeshInstance3D.new()
		instance.name = "AxisBeam"
		instance.mesh = mesh
		instance.material_override = material
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_helix_root.add_child(instance)
		_assign_owner(instance)

func _get_or_create_material(color: Color, is_strand: bool) -> StandardMaterial3D:
	var cache_key: String = "%s_%d_%f_%d" % [color.to_html(), int(use_emission), glow_energy, int(is_strand)]

	if _cached_materials.has(cache_key):
		return _cached_materials[cache_key]

	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	if is_strand:
		material.metallic = 0.25
		material.roughness = 0.2
		material.clearcoat = 0.3
		material.clearcoat_roughness = 0.05
		if use_emission:
			material.emission_enabled = true
			material.emission = color
			material.emission_energy_multiplier = glow_energy
	else:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.disable_fog = true
		material.disable_receive_shadows = true
		if use_emission:
			material.emission_enabled = true
			material.emission = color
			material.emission_energy_multiplier = glow_energy * 1.1

	_cached_materials[cache_key] = material
	return material

func _apply_pulse_effect() -> void:
	if not _helix_root:
		return

	var pulse_value: float = 0.5 + 0.5 * sin(_time_elapsed * pulse_speed * TWO_PI)
	var scale_factor: float = 1.0 + pulse_intensity * pulse_value * 0.2

	for child in _helix_root.get_children():
		if child is MultiMeshInstance3D:
			child.scale = Vector3.ONE * scale_factor

func _assign_owner(node: Node) -> void:
	if not Engine.is_editor_hint():
		return
	var owner_node: Node = get_owner()
	if owner_node:
		node.owner = owner_node
