@tool
extends Node3D

const TWO_PI := PI * 2.0

var _helix_radius: float = 0.65
var _helix_height: float = 6.0
var _helix_turns: int = 5
var _points_per_turn: int = 32
var _strand_point_radius: float = 0.08
var _strand_segments: int = 24
var _rung_every: int = 3
var _phase_offset: float = 0.0
var _vertical_offset: float = 0.0
var _strand_color_a: Color = Color(0.2, 0.85, 1.0, 1.0)
var _strand_color_b: Color = Color(1.0, 0.42, 0.75, 1.0)
var _rung_color: Color = Color(0.7, 1.0, 0.6, 1.0)
var _axis_color: Color = Color(0.35, 0.65, 1.0, 1.0)
var _glow_energy: float = 4.0
var _use_emission: bool = true
var _draw_axis: bool = true

@export_group("Helix Geometry")
@export_range(0.1, 20.0, 0.05) var helix_radius: float = _helix_radius:
	set(value):
		if is_equal_approx(_helix_radius, value):
			return
		_helix_radius = value
		_queue_rebuild()
	get:
		return _helix_radius
@export_range(1.0, 20.0, 0.1) var helix_height: float = _helix_height:
	set(value):
		if is_equal_approx(_helix_height, value):
			return
		_helix_height = value
		_queue_rebuild()
	get:
		return _helix_height
@export_range(1, 20, 1) var helix_turns: int = _helix_turns:
	set(value):
		if _helix_turns == value:
			return
		_helix_turns = value
		_queue_rebuild()
	get:
		return _helix_turns
@export_range(4, 128, 1) var points_per_turn: int = _points_per_turn:
	set(value):
		if _points_per_turn == value:
			return
		_points_per_turn = value
		_queue_rebuild()
	get:
		return _points_per_turn
@export_range(0.02, 0.4, 0.01) var strand_point_radius: float = _strand_point_radius:
	set(value):
		if is_equal_approx(_strand_point_radius, value):
			return
		_strand_point_radius = value
		_queue_rebuild()
	get:
		return _strand_point_radius
@export_range(6, 64, 1) var strand_segments: int = _strand_segments:
	set(value):
		if _strand_segments == value:
			return
		_strand_segments = value
		_queue_rebuild()
	get:
		return _strand_segments
@export_range(1, 16, 1) var rung_every: int = _rung_every:
	set(value):
		if _rung_every == value:
			return
		_rung_every = value
		_queue_rebuild()
	get:
		return _rung_every
@export var phase_offset: float = _phase_offset:
	set(value):
		if is_equal_approx(_phase_offset, value):
			return
		_phase_offset = value
		_queue_rebuild()
	get:
		return _phase_offset
@export var vertical_offset: float = _vertical_offset:
	set(value):
		if is_equal_approx(_vertical_offset, value):
			return
		_vertical_offset = value
		_queue_rebuild()
	get:
		return _vertical_offset

@export_group("Visuals")
@export var strand_color_a: Color = _strand_color_a:
	set(value):
		if _strand_color_a == value:
			return
		_strand_color_a = value
		_queue_rebuild()
	get:
		return _strand_color_a
@export var strand_color_b: Color = _strand_color_b:
	set(value):
		if _strand_color_b == value:
			return
		_strand_color_b = value
		_queue_rebuild()
	get:
		return _strand_color_b
@export var rung_color: Color = _rung_color:
	set(value):
		if _rung_color == value:
			return
		_rung_color = value
		_queue_rebuild()
	get:
		return _rung_color
@export var axis_color: Color = _axis_color:
	set(value):
		if _axis_color == value:
			return
		_axis_color = value
		_queue_rebuild()
	get:
		return _axis_color
@export var glow_energy: float = _glow_energy:
	set(value):
		if is_equal_approx(_glow_energy, value):
			return
		_glow_energy = value
		_queue_rebuild()
	get:
		return _glow_energy
@export var use_emission: bool = _use_emission:
	set(value):
		if _use_emission == value:
			return
		_use_emission = value
		_queue_rebuild()
	get:
		return _use_emission
@export var draw_axis: bool = _draw_axis:
	set(value):
		if _draw_axis == value:
			return
		_draw_axis = value
		_queue_rebuild()
	get:
		return _draw_axis

@export_group("Animation")
@export var auto_rotate: bool = true
@export_range(0.0, 2.0, 0.01) var rotation_speed: float = 0.3
@export var rotate_in_editor: bool = false

var _helix_root: Node3D = null
var _rebuild_queued: bool = false

func _ready() -> void:
	set_process(true)
	_queue_rebuild()

func _process(delta: float) -> void:
	if not auto_rotate:
		return
	if Engine.is_editor_hint() and not rotate_in_editor:
		return
	rotate_y(rotation_speed * delta)

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
	var vertical_step: float = 0.0
	if total_steps > 1:
		vertical_step = helix_height / float(total_steps - 1)
	var start_height: float = -helix_height * 0.5 + vertical_offset
	var angle_step: float = TWO_PI / float(valid_points_per_turn)

	var positions_a: Array[Vector3] = []
	var positions_b: Array[Vector3] = []
	positions_a.resize(total_steps)
	positions_b.resize(total_steps)

	for i in range(total_steps):
		var angle: float = phase_offset + float(i) * angle_step
		var y: float = start_height + float(i) * vertical_step
		var cos_angle: float = cos(angle)
		var sin_angle: float = sin(angle)

		positions_a[i] = Vector3(cos_angle * helix_radius, y, sin_angle * helix_radius)
		var angle_b: float = angle + PI
		positions_b[i] = Vector3(cos(angle_b) * helix_radius, y, sin(angle_b) * helix_radius)

	_create_strand("StrandA", positions_a, strand_color_a)
	_create_strand("StrandB", positions_b, strand_color_b)
	_create_rungs(positions_a, positions_b)
	if draw_axis:
		_create_axis(positions_a, positions_b)

func _create_strand(name: String, positions: Array[Vector3], base_color: Color) -> void:
	if positions.is_empty():
		return
	var sphere_mesh: SphereMesh = SphereMesh.new()
	sphere_mesh.radius = strand_point_radius
	sphere_mesh.height = strand_point_radius * 2.0  # Ensure it's a proper sphere
	sphere_mesh.radial_segments = strand_segments
	var rings: int = max(4, strand_segments / 2)
	sphere_mesh.rings = rings
	var strand_material: StandardMaterial3D = _create_strand_material(base_color)
	sphere_mesh.material = strand_material

	var multimesh: MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	#multimesh.color_format = MultiMesh.COLOR_FLOAT
	multimesh.instance_count = positions.size()
	multimesh.mesh = sphere_mesh

	var count: int = positions.size()
	var denom: float = max(1.0, float(count - 1))
	for i in range(count):
		var pos: Vector3 = positions[i]
		multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, pos))
		var wave: float = 0.5 + 0.5 * sin(float(i) / denom * TWO_PI * 2.0)
		var instance_color: Color = base_color.lerp(Color.WHITE, wave * 0.25)
		multimesh.set_instance_color(i, instance_color)

	var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
	instance.name = name
	instance.multimesh = multimesh
	instance.material_override = strand_material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_helix_root.add_child(instance)
	_assign_owner(instance)

func _create_rungs(positions_a: Array[Vector3], positions_b: Array[Vector3]) -> void:
	var count: int = min(positions_a.size(), positions_b.size())
	if count < 2:
		return
	var step: int = max(1, rung_every)
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)
	var material: StandardMaterial3D = _create_line_material(rung_color)
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
		if normal.length() < 0.001:
			normal = direction.cross(Vector3.RIGHT)
			if normal.length() < 0.001:
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

func _create_axis(positions_a: Array[Vector3], positions_b: Array[Vector3]) -> void:
	var count: int = min(positions_a.size(), positions_b.size())
	if count < 2:
		return
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINE_STRIP)
	var material: StandardMaterial3D = _create_line_material(axis_color)
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

func _create_strand_material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.albedo_color = color
	material.metallic = 0.25
	material.roughness = 0.2
	material.clearcoat = 0.3
	material.clearcoat_roughness = 0.05
	if use_emission:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = glow_energy
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material

func _create_line_material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.albedo_color = color
	material.disable_fog = true
	material.disable_receive_shadows = true
	if use_emission:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = glow_energy * 1.1
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material

func _assign_owner(node: Node) -> void:
	if not Engine.is_editor_hint():
		return
	var owner_node: Node = get_owner()
	if owner_node:
		node.owner = owner_node
