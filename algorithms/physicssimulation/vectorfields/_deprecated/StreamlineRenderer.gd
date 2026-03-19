extends Node3D

# Draws 3D streamlines of a vector field using ImmediateMesh.
# Vortex centers orbit gently, producing flowing field lines in 3D space.

@export var line_color: Color = Color(0.8, 0.0, 0.0, 0.7)
@export var seed_grid_cols: int = 20
@export var seed_grid_rows: int = 12
@export var step_size: float = 0.004
@export var max_steps: int = 200
@export var field_strength: float = 0.02
@export var centers_count: int = 10
@export var random_seed: int = 42
@export var animate: bool = true
@export var animation_speed: float = 0.4
@export var center_orbit_radius: float = 0.03
@export var rebuild_interval: float = 0.1

var _polylines: Array[PackedVector3Array] = []
var _centers: Array[Vector3] = []
var _time: float = 0.0
var _accum: float = 0.0

var _mesh_instance: MeshInstance3D
var _label: Label3D

# Field bounds in 3D (XZ plane)
var _field_size: Vector2 = Vector2(0.7, 0.5)

func _ready() -> void:
	if random_seed != 0:
		seed(random_seed)

	_mesh_instance = MeshInstance3D.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 1.5
	_mesh_instance.material_override = mat
	add_child(_mesh_instance)

	_label = Label3D.new()
	_label.text = "Vector Field Streamlines"
	_label.font_size = 32
	_label.position = Vector3(0, -0.02, 0.3)
	_label.modulate = Color(1, 1, 1, 0.8)
	add_child(_label)

	_generate_centers()
	_build_streamlines()
	_rebuild_mesh()

func _process(delta: float) -> void:
	if not animate:
		return
	_time += delta
	_accum += delta
	if _accum >= rebuild_interval:
		_accum = 0.0
		_build_streamlines()
		_rebuild_mesh()

func _rebuild_mesh() -> void:
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	for points in _polylines:
		if points.size() < 2:
			continue
		for i in range(1, points.size()):
			var t := float(i) / points.size()
			var c := line_color
			c.a = t * 0.8
			im.surface_set_color(c)
			im.surface_add_vertex(points[i - 1])
			im.surface_set_color(c)
			im.surface_add_vertex(points[i])
	im.surface_end()
	_mesh_instance.mesh = im

func _build_streamlines() -> void:
	_polylines.clear()
	if _centers.is_empty():
		_generate_centers()

	var cols: int = max(seed_grid_cols, 1)
	var rows: int = max(seed_grid_rows, 1)

	for r in range(rows):
		for c in range(cols):
			var p := Vector3(
				-_field_size.x * 0.5 + (c + 0.5) * _field_size.x / cols,
				0.0,
				-_field_size.y * 0.5 + (r + 0.5) * _field_size.y / rows
			)
			var forward := _integrate_streamline(p, 1.0)
			var backward := _integrate_streamline(p, -1.0)
			backward.reverse()
			var joined := PackedVector3Array()
			joined.append_array(backward)
			joined.push_back(p)
			joined.append_array(forward)
			_polylines.append(joined)

func _integrate_streamline(start: Vector3, direction_sign: float) -> PackedVector3Array:
	var pts := PackedVector3Array()
	var p := start
	var half_w := _field_size.x * 0.5
	var half_h := _field_size.y * 0.5
	for i in range(max_steps):
		var v := _vector_field(p)
		var v_len := v.length()
		if v_len < 0.00001:
			break
		var dp := v.normalized() * step_size * direction_sign
		# RK2 midpoint
		var mid := p + dp * 0.5
		var vmid := _vector_field(mid).normalized()
		dp = vmid * step_size * direction_sign
		p += dp
		if p.x < -half_w or p.x > half_w or p.z < -half_h or p.z > half_h:
			break
		pts.append(p)
	return pts

func _generate_centers() -> void:
	_centers.clear()
	for i in range(centers_count):
		var pos := Vector3(
			randf_range(-_field_size.x * 0.45, _field_size.x * 0.45),
			0.0,
			randf_range(-_field_size.y * 0.45, _field_size.y * 0.45)
		)
		_centers.append(pos)

func _vector_field(p: Vector3) -> Vector3:
	# Superposition of swirling vortex centers in XZ plane
	var v := Vector3.ZERO
	for i in range(_centers.size()):
		var base_c := _centers[i]
		var phase := _time * animation_speed + float(i) * 0.7
		var c := base_c + Vector3(sin(phase), 0.0, cos(phase)) * center_orbit_radius
		var r := p - c
		var d2: float = max(r.x * r.x + r.z * r.z, 0.0004)
		# Swirl: perpendicular in XZ
		var swirl: Vector3 = Vector3(-r.z, 0.0, r.x) / d2
		v += swirl * field_strength
	# Gentle pull toward center
	v += -p * 0.05
	return v

func apply_grid_config(config: Dictionary) -> void:
	pass

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
