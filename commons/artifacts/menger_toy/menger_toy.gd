extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name MengerToy

## @identity
## A held Menger sponge — a cube that has hollowed itself out, kept only the edges.
## Truth: "infinite surface, zero volume". Each subdivision throws away 7 of 27, keeps 20,
## and does it again. In the limit there is nothing left to fill, yet the skin never stops.

@export var depth: int = 3
@export var span: float = 0.4
@export var sway: bool = true
@export var sponge_color: Color = Color(0.85, 0.55, 0.25)

var _cells: Array[Vector3] = []
var _leaf_size: float = 0.1
var _spin: float = 0.0


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
	_compute_cells()
	add_child(_sponge_field())
	add_child(_billboard_label("MENGER", Vector3(0.0, span * 0.85, 0.0), 22, sponge_color))


func _compute_cells() -> void:
	_cells.clear()
	# Start with one unit cube centred at origin, recurse keeping the 20 non-centre sub-cubes.
	var d: int = clampi(depth, 1, 3)
	var divisions: int = int(pow(3.0, float(d)))
	_leaf_size = span / float(divisions)
	_recurse(Vector3.ZERO, span, d)


func _recurse(center: Vector3, size: float, level: int) -> void:
	if level == 0:
		_cells.append(center)
		return
	var child: float = size / 3.0
	for ix in range(3):
		for iy in range(3):
			for iz in range(3):
				# Drop a sub-cube if it sits at the centre of any axis-pair (Menger rule):
				# keep only cells where at most one coordinate is the middle (1).
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
	var s: float = _leaf_size * 0.96
	for i in range(n):
		var p: Vector3 = _cells[i]
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(s, s, s)), p))
		# Tint warmer near the shell edges, cooler in the recessed channels.
		var edge: float = clampf((absf(p.x) + absf(p.y) + absf(p.z)) / (span * 1.5), 0.0, 1.0)
		var col: Color = sponge_color.lerp(Color(1.0, 0.85, 0.4), edge)
		mm.set_instance_color(i, col)
	return mi


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
	_spin += delta * 0.4
	rotation = Vector3(0.2 * sin(_spin * 0.7), _spin, 0.0)
