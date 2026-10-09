extends Node3D
class_name TensegrityTriangle

# @identity
# essence: three rendered struts and joints in a triangular arrangement.
# desire: compare the appearance of rigidity with a tested structural constraint.
# critical_parameter: load_amplitude controls a prescribed scale pulse, not an applied load.
# triggers: _ready constructs meshes; _process writes a sine-driven root scale.
# emerges: a visual squeeze and return without a member-force, hinge or load solver.
# needs: a triangle/square comparison under shared constraints and loads [not implemented].
# relationships: follows three_points_triangle; a possible bridge to truss and spring models.
# truth: the legacy tensegrity name does not make this a tensegrity. The struts touch
# at their joints and there are no tension cables. The pulse cannot prove rigidity.

## Triangular frame diagram — a visual question about structure.
##
## Built procedurally. Origin at the centroid; triangle in the local XY
## plane. The entire arrangement scales periodically; no load response is simulated.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Geometry")
@export var tri_width: float = 1.2
@export var tri_height: float = 1.1
@export var strut_radius: float = 0.045
@export var joint_radius: float = 0.075

@export_group("Material")
@export var strut_color: Color = Color(0.88, 0.89, 0.92)
@export var joint_color: Color = Color(1.0, 0.62, 0.16)   # Fuller orange
@export var load_amplitude: float = 0.035
@export var load_speed: float = 1.6

# ── State ─────────────────────────────────────────────────────────────

var _built: bool = false
var _phase: float = 0.0


func _ready() -> void:
	_read_metadata_overrides()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for c in get_children():
			c.queue_free()
		_built = false
		_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_tri_width"):
		tri_width = float(str(get_meta("config_tri_width")))
	if has_meta("config_tri_height"):
		tri_height = float(str(get_meta("config_tri_height")))
	if has_meta("config_strut_color"):
		strut_color = _parse_color(str(get_meta("config_strut_color")), strut_color)
	if has_meta("config_joint_color"):
		joint_color = _parse_color(str(get_meta("config_joint_color")), joint_color)
	if has_meta("config_load_amplitude"):
		load_amplitude = float(str(get_meta("config_load_amplitude")))


func _parse_color(raw: String, fallback: Color) -> Color:
	var parts := raw.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	return fallback


# ── Build ─────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true

	var v_top := Vector3(0.0, tri_height * 0.6, 0.0)
	var v_bl := Vector3(-tri_width * 0.5, -tri_height * 0.4, 0.0)
	var v_br := Vector3(tri_width * 0.5, -tri_height * 0.4, 0.0)

	var strut_mat := StandardMaterial3D.new()
	strut_mat.albedo_color = strut_color
	strut_mat.roughness = 0.35
	strut_mat.metallic = 0.6

	_add_strut(v_top, v_bl, strut_mat)
	_add_strut(v_bl, v_br, strut_mat)
	_add_strut(v_br, v_top, strut_mat)

	_add_joint(v_top)
	_add_joint(v_bl)
	_add_joint(v_br)

	_phase = 0.0
	set_process(true)


func _add_joint(pos: Vector3) -> void:
	var j := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = joint_radius
	sm.height = joint_radius * 2.0
	j.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = joint_color
	mat.emission_enabled = true
	mat.emission = joint_color
	mat.emission_energy_multiplier = 1.2
	mat.roughness = 0.3
	mat.metallic = 0.3
	j.material_override = mat
	j.position = pos
	add_child(j)


func _add_strut(a: Vector3, b: Vector3, mat: StandardMaterial3D) -> void:
	var dir := (b - a)
	var length := dir.length()
	if length < 0.001:
		return
	dir = dir / length
	var s := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = strut_radius
	cm.bottom_radius = strut_radius
	cm.height = length
	s.mesh = cm
	s.material_override = mat
	var x_axis := dir.cross(Vector3(0, 0, 1))
	if x_axis.length() < 0.001:
		x_axis = dir.cross(Vector3(1, 0, 0))
	x_axis = x_axis.normalized()
	var z_axis := x_axis.cross(dir).normalized()
	s.transform = Transform3D(Basis(x_axis, dir, z_axis), (a + b) * 0.5)
	add_child(s)


func _process(delta: float) -> void:
	if not _built:
		return
	# Prescribed visual pulse: squash in Y and widen slightly in X.
	# This bypasses mechanics; it is not evidence that a frame resists a load.
	_phase += delta * load_speed
	var load: float = maxf(0.0, sin(_phase)) * load_amplitude
	scale = Vector3(1.0 + load * 0.4, 1.0 - load, 1.0)
