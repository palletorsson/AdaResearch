extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name CantorBench

## @identity
## name: "Cantor set"
## tier: medium
## lineage: the Cantor middle-thirds set — Cantor's dust, the first fractal, built by the
##   simplest rule of erasure laid out generation by generation on a bench.
## essence: A solid bar at the top. Below it, the same bar with its middle third removed.
##   Below that, each remaining piece loses ITS middle third. Generation after generation
##   stacked downward, the line dissolving into dust — yet uncountably many points survive
##   every cut. What is left has length zero but is as numerous as the whole line.
## truth: "remove the middle third, forever" — length → 0, points → uncountable. D = log 2 / log 3 ≈ 0.63.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var generations: int = 6
@export var bar_span: float = 0.82          # width of generation 0 (m)
@export var row_gap: float = 0.085          # vertical spacing between generations
@export var bar_color_top: Color = Color(0.55, 0.90, 1.0)
@export var bar_color_dust: Color = Color(1.0, 0.78, 0.45)
@export var label_color: Color = Color(0.85, 0.92, 1.0)

var _t: float = 0.0
var _stack_root: Node3D = null


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("generations"):
		generations = clampi(int(config["generations"]), 1, 8)
	if config.has("bar_span"):
		bar_span = float(config["bar_span"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_stack_root = null
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


func _build() -> void:
	# --- bench base + pillar ------------------------------------------------
	var base_mat: StandardMaterial3D = _matte_mat(Color(0.20, 0.22, 0.26), 0.85)
	add_child(_box(Vector3(0.0, 0.10, 0.0), Vector3(1.1, 0.20, 0.7), base_mat))
	var top_mat: StandardMaterial3D = _steel_mat(Color(0.40, 0.44, 0.50))
	add_child(_box(Vector3(0.0, 0.85, 0.0), Vector3(1.1, 0.04, 0.7), top_mat))
	add_child(_cylinder(Vector3(0.0, 0.50, -0.18), 0.05, 0.70, base_mat))

	# --- backboard the dust is drawn on (facing +Z) -------------------------
	var board_h: float = float(generations) * row_gap + 0.12
	var board_y: float = 1.16
	var board_mat: StandardMaterial3D = _matte_mat(Color(0.05, 0.06, 0.09), 0.95)
	add_child(_box(Vector3(0.0, board_y, 0.13), Vector3(bar_span + 0.12, board_h, 0.02), board_mat))

	var root := Node3D.new()
	root.name = "DustStack"
	add_child(root)
	_stack_root = root

	# --- build the Cantor generations as intervals --------------------------
	# Each generation is a list of [start, end] spans in [0,1].
	var intervals: Array = [[0.0, 1.0]]
	var rows: Array = []          # rows[g] = array of [start,end]
	rows.append(intervals.duplicate(true))
	for _g in range(generations - 1):
		var next: Array = []
		for span_pair: Array in intervals:
			var a: float = span_pair[0]
			var b: float = span_pair[1]
			var third: float = (b - a) / 3.0
			next.append([a, a + third])
			next.append([b - third, b])
		intervals = next
		rows.append(intervals.duplicate(true))

	# Count total segments for the MultiMesh.
	var total_segments: int = 0
	for r: Array in rows:
		total_segments += r.size()

	var field: MultiMeshInstance3D = _field(total_segments, true)
	field.name = "Cantor"
	var mm: MultiMesh = field.multimesh
	var ox: float = -bar_span * 0.5
	var top_row_y: float = board_y + board_h * 0.5 - 0.10
	var seg_h: float = 0.045
	var idx: int = 0
	for g in range(rows.size()):
		var rs: Array = rows[g]
		var ry: float = top_row_y - float(g) * row_gap
		var tcol: Color = bar_color_top.lerp(bar_color_dust, float(g) / float(max(generations - 1, 1)))
		for span_pair: Array in rs:
			var a: float = span_pair[0]
			var b: float = span_pair[1]
			var seg_w: float = (b - a) * bar_span
			var cx: float = ox + (a + b) * 0.5 * bar_span
			# keep tiny segments visible with a minimum width
			var draw_w: float = maxf(seg_w, 0.004)
			var basis := Basis().scaled(Vector3(draw_w, seg_h, 0.02))
			mm.set_instance_transform(idx, Transform3D(basis, Vector3(cx, ry, 0.145)))
			mm.set_instance_color(idx, tcol)
			idx += 1
	root.add_child(field)

	# --- labels -------------------------------------------------------------
	add_child(_billboard_label("D = log 2 / log 3 ≈ 0.63", Vector3(0.0, board_y - board_h * 0.5 - 0.02, 0.16), 16, bar_color_dust))
	add_child(_billboard_label("REMOVE THE MIDDLE THIRD, FOREVER", Vector3(0.0, 1.6, 0.0), 22, label_color))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _stack_root != null:
		_stack_root.rotation.y = sin(_t * 0.35) * 0.04
