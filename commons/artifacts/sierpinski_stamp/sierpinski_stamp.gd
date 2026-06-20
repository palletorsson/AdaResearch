extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name SierpinskiStamp

## @identity
## name: "Sierpinski"
## tier: applied
## lineage: a stamp — the Sierpinski gasket as a die that prints triangles made of
##   triangles, tiling them across a sheet.
## essence: A stamp head carrying a Sierpinski die rises and falls, leaving an inked gasket
##   on the sheet below; an array of already-printed gaskets fills the bed. Because the die
##   is self-similar, four stamps tile into one larger gasket of the same shape — the print
##   is its own loom. The output never stops being a triangle of triangles.
## truth: "triangle of triangles" — three (or four, tiled) copies reassemble the whole.
##   D = log 3 / log 2 ≈ 1.585.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var depth: int = 4
@export var stamp_size: float = 0.22          # die edge length (m)
@export var cols: int = 3
@export var rows: int = 2
@export var stamp_period: float = 1.8         # seconds per stamp cycle
@export var ink_color: Color = Color(0.70, 0.55, 1.0)
@export var hot_color: Color = Color(1.0, 0.55, 0.30)
@export var label_color: Color = Color(0.88, 0.85, 1.0)

var _t: float = 0.0
var _stamp_head: Node3D = null
var _die_mat: StandardMaterial3D = null
var _leaves: Array = []


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("depth"):
		depth = clampi(int(config["depth"]), 1, 6)
	if config.has("cols"):
		cols = clampi(int(config["cols"]), 1, 5)
	if config.has("rows"):
		rows = clampi(int(config["rows"]), 1, 4)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_stamp_head = null
	_die_mat = null
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


func _make_gasket(size: float, d: int, col: Color, flat: bool) -> MultiMeshInstance3D:
	# Build a Sierpinski gasket as one MultiMesh. flat=true lays it on XZ (printed sheet);
	# flat=false keeps it on XY (the die face, pointing down).
	_leaves.clear()
	var h: float = size * sqrt(3.0) * 0.5
	var apex := Vector2(0.0, h * 0.5)
	var bl := Vector2(-size * 0.5, -h * 0.5)
	var br := Vector2(size * 0.5, -h * 0.5)
	_collect(apex, bl, br, d)
	var count: int = _leaves.size()
	var field: MultiMeshInstance3D = _field(count, true)
	var mm: MultiMesh = field.multimesh
	for i in range(count):
		var leaf: Dictionary = _leaves[i]
		var c2: Vector2 = leaf["c"]
		var s: float = leaf["s"]
		var pos: Vector3
		var basis: Basis
		if flat:
			pos = Vector3(c2.x, 0.0, -c2.y)
			basis = Basis().scaled(Vector3(s * 0.86, 0.01, s * 0.74))
		else:
			pos = Vector3(c2.x, c2.y, 0.0)
			basis = Basis().scaled(Vector3(s * 0.86, s * 0.74, 0.02))
		mm.set_instance_transform(i, Transform3D(basis, pos))
		mm.set_instance_color(i, col)
	return field


func _build() -> void:
	# --- device body (~1 m) -------------------------------------------------
	var body_mat: StandardMaterial3D = _matte_mat(Color(0.22, 0.24, 0.28), 0.7, 0.2)
	add_child(_box(Vector3(0.0, 0.10, 0.0), Vector3(0.9, 0.20, 0.6), body_mat))
	# printed sheet bed
	var sheet_mat: StandardMaterial3D = _matte_mat(Color(0.05, 0.06, 0.09), 0.95)
	add_child(_box(Vector3(0.0, 0.205, 0.06), Vector3(0.8, 0.02, 0.5), sheet_mat))

	# gantry: a single arm holding the stamp head over the bed
	var col_mat: StandardMaterial3D = _steel_mat(Color(0.48, 0.52, 0.58))
	add_child(_box(Vector3(-0.40, 0.55, -0.24), Vector3(0.06, 0.70, 0.06), col_mat))
	add_child(_box(Vector3(-0.15, 0.86, -0.24), Vector3(0.56, 0.06, 0.08), col_mat))

	# --- tiled output of finished gaskets on the sheet ---------------------
	var bed_w: float = 0.72
	var bed_d: float = 0.42
	var cw: float = bed_w / float(cols)
	var cd: float = bed_d / float(rows)
	for r in range(rows):
		for cc in range(cols):
			# skip the (last) cell where the live stamp lands so the fresh one shows there
			if r == rows - 1 and cc == cols - 1:
				continue
			var px: float = -bed_w * 0.5 + (float(cc) + 0.5) * cw
			var pz: float = 0.06 - bed_d * 0.5 + (float(r) + 0.5) * cd
			var g: MultiMeshInstance3D = _make_gasket(stamp_size, depth, ink_color.darkened(0.08), true)
			g.name = "Tile_%d_%d" % [r, cc]
			g.position = Vector3(px, 0.215, pz)
			add_child(g)

	# the live print cell (front-right), where the fresh stamp appears
	var live_x: float = -bed_w * 0.5 + (float(cols - 1) + 0.5) * cw
	var live_z: float = 0.06 - bed_d * 0.5 + (float(rows - 1) + 0.5) * cd
	var fresh: MultiMeshInstance3D = _make_gasket(stamp_size, depth, ink_color, true)
	fresh.name = "FreshPrint"
	fresh.position = Vector3(live_x, 0.215, live_z)
	add_child(fresh)

	# --- the stamp head + Sierpinski die (points down at the live cell) ----
	var head := Node3D.new()
	head.name = "StampHead"
	head.position = Vector3(live_x, 0.0, live_z)
	add_child(head)
	_stamp_head = head
	var handle_mat: StandardMaterial3D = _steel_mat(Color(0.55, 0.58, 0.64))
	head.add_child(_box(Vector3(0.0, 0.58, 0.0), Vector3(0.16, 0.10, 0.16), handle_mat))
	head.add_child(_box(Vector3(0.0, 0.46, 0.0), Vector3(0.05, 0.16, 0.05), handle_mat))
	# the die: a downward-facing gasket on the underside of the head
	var die: MultiMeshInstance3D = _make_gasket(stamp_size, depth, ink_color, false)
	die.name = "Die"
	die.rotation.x = PI / 2.0     # face the gasket downward onto the sheet
	die.position = Vector3(0.0, 0.38, 0.0)
	head.add_child(die)
	_die_mat = die.material_override as StandardMaterial3D

	# --- labels -------------------------------------------------------------
	add_child(_billboard_label("4 tiles → 1 larger gasket", Vector3(0.0, 0.32, 0.30), 16, hot_color))
	add_child(_billboard_label("TRIANGLE OF TRIANGLES", Vector3(0.0, 0.96, 0.0), 24, label_color))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _stamp_head == null:
		return
	var phase: float = fmod(_t, stamp_period) / stamp_period
	var drop: float = 0.0
	if phase < 0.35:
		drop = phase / 0.35
	elif phase < 0.5:
		drop = 1.0
	else:
		drop = maxf(0.0, 1.0 - (phase - 0.5) / 0.5)
	_stamp_head.position.y = -drop * 0.16
	if _die_mat != null:
		var heat: float = 1.0 if (phase >= 0.30 and phase < 0.5) else 0.0
		_die_mat.emission = ink_color.lerp(hot_color, heat)
		_die_mat.emission_energy_multiplier = (0.18 if emissive else 0.0) + heat * 1.0
