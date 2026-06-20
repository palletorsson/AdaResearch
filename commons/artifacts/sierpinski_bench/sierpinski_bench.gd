extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name SierpinskiBench

## @identity
## name: "Sierpinski"
## tier: medium
## lineage: the Sierpinski gasket — Sierpinski's triangle, the canonical self-similar set,
##   recursed until the same hole appears at every scale on a bench.
## essence: A filled triangle has its middle quarter punched out, leaving three corner
##   triangles. Each of those loses ITS middle. Recurse five times and the surface is more
##   hole than triangle, yet at any zoom it looks the same — three copies of itself, half
##   size. The whole IS its parts.
## truth: "the same hole at every scale" — three half-size copies of the whole. D = log 3 / log 2 ≈ 1.585.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var depth: int = 5
@export var tri_size: float = 0.64           # base edge length of the gasket (m)
@export var fill_color: Color = Color(0.70, 0.55, 1.0)
@export var tip_color: Color = Color(1.0, 0.78, 0.50)
@export var label_color: Color = Color(0.88, 0.85, 1.0)

var _t: float = 0.0
var _gasket_root: Node3D = null
var _leaves: Array = []     # each: {center:Vector3, size:float}


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("depth"):
		depth = clampi(int(config["depth"]), 1, 6)
	if config.has("tri_size"):
		tri_size = float(config["tri_size"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_gasket_root = null
	_build()


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
	mat.emission_energy_multiplier = 0.18 if emissive else 0.0
	mi.material_override = mat
	return mi


func _collect(p_a: Vector2, p_b: Vector2, p_c: Vector2, d: int) -> void:
	# Recurse; at the leaf, record the small filled triangle as a center+size.
	if d <= 0:
		var center: Vector2 = (p_a + p_b + p_c) / 3.0
		var size: float = p_a.distance_to(p_b)
		_leaves.append({"c": center, "s": size})
		return
	var ab: Vector2 = (p_a + p_b) * 0.5
	var bc: Vector2 = (p_b + p_c) * 0.5
	var ca: Vector2 = (p_c + p_a) * 0.5
	_collect(p_a, ab, ca, d - 1)
	_collect(ab, p_b, bc, d - 1)
	_collect(ca, bc, p_c, d - 1)


func _build() -> void:
	# --- bench base + pillar ------------------------------------------------
	var base_mat: StandardMaterial3D = _matte_mat(Color(0.20, 0.22, 0.26), 0.85)
	add_child(_box(Vector3(0.0, 0.10, 0.0), Vector3(1.1, 0.20, 0.7), base_mat))
	var top_mat: StandardMaterial3D = _steel_mat(Color(0.40, 0.44, 0.50))
	add_child(_box(Vector3(0.0, 0.85, 0.0), Vector3(1.1, 0.04, 0.7), top_mat))
	add_child(_cylinder(Vector3(0.0, 0.50, -0.18), 0.05, 0.70, base_mat))

	# --- backboard the gasket forms on (facing +Z) --------------------------
	var board_mat: StandardMaterial3D = _matte_mat(Color(0.05, 0.06, 0.09), 0.95)
	add_child(_box(Vector3(0.0, 1.18, 0.13), Vector3(tri_size + 0.12, tri_size + 0.14, 0.02), board_mat))

	var root := Node3D.new()
	root.name = "GasketSway"
	add_child(root)
	_gasket_root = root

	# --- recurse to collect leaf triangles ---------------------------------
	_leaves.clear()
	var h: float = tri_size * sqrt(3.0) * 0.5
	# centred on the board: apex up
	var cx0: float = 0.0
	var cy0: float = 1.18
	var apex := Vector2(cx0, cy0 + h * 0.5)
	var bl := Vector2(cx0 - tri_size * 0.5, cy0 - h * 0.5)
	var br := Vector2(cx0 + tri_size * 0.5, cy0 - h * 0.5)
	_collect(apex, bl, br, depth)

	# --- fill one MultiMesh with the leaf triangles (as small boxes) -------
	var count: int = _leaves.size()
	var field: MultiMeshInstance3D = _field(count, true)
	field.name = "Gasket"
	var mm: MultiMesh = field.multimesh
	for i in range(count):
		var leaf: Dictionary = _leaves[i]
		var c: Vector2 = leaf["c"]
		var s: float = leaf["s"]
		# vertical position drives color (apex warm -> base cool)
		var frac: float = clampf((c.y - bl.y) / maxf(h, 0.001), 0.0, 1.0)
		var col: Color = fill_color.lerp(tip_color, frac)
		# a small box approximating the filled cell
		var basis := Basis().scaled(Vector3(s * 0.86, s * 0.74, 0.02))
		mm.set_instance_transform(i, Transform3D(basis, Vector3(c.x, c.y, 0.145)))
		mm.set_instance_color(i, col)
		# cache for sway-independent (already in root space)
	root.add_child(field)

	# --- labels -------------------------------------------------------------
	add_child(_billboard_label("D = log 3 / log 2 ≈ 1.585", Vector3(0.0, cy0 - h * 0.5 - 0.06, 0.16), 16, tip_color))
	add_child(_billboard_label("THE SAME HOLE AT EVERY SCALE", Vector3(0.0, 1.6, 0.0), 22, label_color))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _gasket_root != null:
		_gasket_root.rotation.y = sin(_t * 0.4) * 0.05
