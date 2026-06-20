extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name MengerFilter

## @identity
## A Menger sponge used as a 3D filter — all surface, almost no body, so light and fluid
## pass through every channel. Truth: "all surface". A solid that became a membrane: the
## carving rule pushed area to infinity and volume to zero, which is exactly what a filter wants.

@export var depth: int = 2
@export var sponge_color: Color = Color(0.5, 0.7, 0.85)
@export var flow_color: Color = Color(0.6, 0.95, 1.0)
@export var sway: bool = true

const SPONGE_SPAN: float = 0.55

var _cells: Array[Vector3] = []
var _leaf_size: float = 0.1
var _flow: MeshInstance3D
var _t: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("depth"):
		depth = int(config["depth"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_build_housing()
	_compute_cells()
	add_child(_sponge_field())
	_build_flow()
	add_child(_billboard_label("ALL SURFACE", Vector3(0.0, 0.95, 0.0), 20, sponge_color))


func _build_housing() -> void:
	# A short cylindrical duct the sponge sits inside; fluid enters -Z, leaves +Z.
	var ring_mat := _steel_mat(Color(0.32, 0.34, 0.4))
	add_child(_torus(Vector3(0.0, 0.4, -0.36), 0.42, 0.04, ring_mat))
	add_child(_torus(Vector3(0.0, 0.4, 0.36), 0.42, 0.04, ring_mat))
	# Four struts connecting the rings.
	var strut_mat := _matte_mat(Color(0.22, 0.24, 0.28), 0.6, 0.3)
	for a in range(4):
		var ang: float = float(a) * PI * 0.5 + PI * 0.25
		var x: float = cos(ang) * 0.42
		var y: float = 0.4 + sin(ang) * 0.42
		add_child(_box(Vector3(x, y, 0.0), Vector3(0.04, 0.04, 0.76), strut_mat))
	# Base.
	add_child(_box(Vector3(0.0, 0.02, 0.0), Vector3(0.7, 0.04, 0.7), _matte_mat(Color(0.15, 0.16, 0.2), 0.8)))


func _compute_cells() -> void:
	_cells.clear()
	var d: int = clampi(depth, 1, 3)
	var divisions: int = int(pow(3.0, float(d)))
	_leaf_size = SPONGE_SPAN / float(divisions)
	_recurse(Vector3.ZERO, SPONGE_SPAN, d)


func _recurse(center: Vector3, size: float, level: int) -> void:
	if level == 0:
		_cells.append(center)
		return
	var child: float = size / 3.0
	for ix in range(3):
		for iy in range(3):
			for iz in range(3):
				var mids: int = 0
				if ix == 1:
					mids += 1
				if iy == 1:
					mids += 1
				if iz == 1:
					mids += 1
				if mids >= 2:
					continue
				var off := Vector3(float(ix) - 1.0, float(iy) - 1.0, float(iz) - 1.0) * child
				_recurse(center + off, child, level - 1)


func _sponge_field() -> MultiMeshInstance3D:
	var n: int = _cells.size()
	var mi := _field(n, true)
	var mm: MultiMesh = mi.multimesh
	var s: float = _leaf_size * 0.94
	for i in range(n):
		var p: Vector3 = _cells[i] + Vector3(0.0, 0.4, 0.0)
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(s, s, s)), p))
		var edge: float = clampf((absf(_cells[i].x) + absf(_cells[i].y) + absf(_cells[i].z)) / (SPONGE_SPAN * 1.5), 0.0, 1.0)
		mm.set_instance_color(i, sponge_color.lerp(flow_color, edge * 0.6))
	return mi


func _build_flow() -> void:
	# A faint translucent shaft of "light/fluid" pouring through the sponge along +Z.
	_flow = _cylinder(Vector3(0.0, 0.4, 0.0), 0.3, 0.9, _glass_mat(flow_color, 0.16))
	_flow.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	add_child(_flow)


func _field(n: int, box: bool = true) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = (BoxMesh.new() if box else SphereMesh.new())
	mm.instance_count = n
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.2 if emissive else 0.0
	mi.material_override = mat
	return mi


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not sway:
		return
	_t += delta
	if _flow != null:
		var pulse: float = 0.16 + 0.06 * sin(_t * 3.0)
		var m := _flow.material_override as StandardMaterial3D
		if m != null:
			m.albedo_color.a = pulse
