extends Node3D
class_name ProfilerFlameGraph

# @identity
# essence: one frame of a profiler frozen into relief — 950 samples of a nested call tree cut into stacked bars, width proportional to total samples under a frame, height its depth in the stack, and the colour rising toward red with the samples a frame burns in its OWN body rather than in what it called
# desire: to stop performance being a scalar. A frame time is one number; a flame graph is the shape that number has, and the shape is where the cost actually lives
# critical_parameter: max_depth — how far down the stack the relief is cut. At 2 the profile is a management summary (two fat bars, no culprit); at 5 the whole stack stands and chunk_hash, four rows up and 15% of every frame, is visible as the widest hot bar
# triggers: _ready() totals the hardcoded tree bottom-up, lays each frame left-to-right inside its parent's span, extrudes a BoxMesh per frame, tints it by self-share against the hottest frame, and names the widest and hottest frames on the caption band
# emerges: the eye finds the hot leaf before the labels are read — a wide bar near the top is a function nobody calls that everybody waits for, and that reading needs no legend
# needs: BoxMesh bars and Label3D captions [Godot built-ins]; Grid.gdshader for the board [present]; a floor to stand the two legs on [any map cell]
# relationships: the resourcemanagement sequence's diagnostic instrument — it reads what the allocators and pools upstream produced, and it is the only artifact in that room that measures rather than allocates
# truth: a profile is not a ranking, it is a topology. Total time tells you which subtree is expensive; only self time tells you which function is. Every optimisation that targeted the widest bar instead of the hottest one was aimed at a container.

## Static stacked-bar relief of a single profiled frame. Observe-only: no input,
## no animation — the whole argument is in the geometry, which is the point of a
## flame graph. Built procedurally in _ready(), same idiom as dome_kit.

const SHADER_PATH := "res://commons/resourses/shaders/Grid.gdshader"

## The profiled frame. Each entry is [name, self_samples, children].
## Self samples are the ticks the profiler caught INSIDE that function's own body;
## a frame's total is its self plus everything beneath it. Hardcoded on purpose —
## a live profiler would redraw every frame and the relief would stop being readable.
const CALL_TREE: Array = [
	"root", 0, [
		["_process", 30, [
			["animation_blend", 95, []],
			["render_prepare", 25, [
				["cull_frustum", 88, []],
				["sort_draw_calls", 40, [
					["radix_sort", 76, []],
				]],
				["build_uniforms", 22, []],
			]],
			["script_tick", 64, []],
		]],
		["_physics_process", 18, [
			["grid_rebuild", 26, [
				["chunk_hash", 148, []],
				["mesh_upload", 44, []],
			]],
			["collide_broadphase", 71, [
				["narrowphase", 58, []],
			]],
			["audio_mix", 39, []],
		]],
		["idle", 106, []],
	]
]

# --- board geometry (metres) ---------------------------------------------
const BOARD_W := 1.86
const BOARD_H := 1.05
const BOARD_D := 0.07
const BOARD_BOTTOM := 0.62          # legs raise the board to reading height
const LEG_W := 0.07

const GRAPH_W := 1.70               # the span the root bar occupies
const GRAPH_BOTTOM := 0.24          # from board bottom, in board-local metres
const GRAPH_H := 0.60
const BAR_GAP := 0.006
const BAR_Z := BOARD_D * 0.5 + 0.012

const COOL := Color(0.28, 0.52, 0.72)
const HOT := Color(0.96, 0.30, 0.20)

## How many rows of the stack are cut. 1 = the root bar alone; 5 = the full tree.
@export_range(1, 6) var max_depth: int = 5
## Board caption. Empty keeps the profile's own header.
@export var caption: String = ""

var _built: bool = false
var _created: Array[Node] = []
var _total_cache: Dictionary = {}


func _ready() -> void:
	_build_all()
	_built = true


func _own(n: Node) -> void:
	_created.append(n)
	add_child(n)


func _build_all() -> void:
	_total_cache.clear()
	_build_board()
	_build_bars()
	_build_captions()


# --- tree arithmetic ------------------------------------------------------

## Samples spent in this frame and everything it called. Memoised by name, which
## is safe here because the tree has no repeated frame names.
func _total(node: Array) -> int:
	var key: String = str(node[0])
	if _total_cache.has(key):
		return int(_total_cache[key])
	var t: int = int(node[1])
	for child in node[2]:
		t += _total(child)
	_total_cache[key] = t
	return t


## Flatten the tree into drawable rows. Each row is a Dictionary:
## {name, depth, x0, width, self, total}. x0 is measured from the left edge of
## the graph span. Children are packed left-to-right inside their parent; the
## parent's own self-time is the remainder on the right, which is exactly how a
## real flame graph shows a function that does work of its own.
func _rows() -> Array:
	var out: Array = []
	var root_total: int = _total(CALL_TREE)
	if root_total <= 0:
		return out
	_walk(CALL_TREE, 0, 0.0, float(root_total), out)
	return out


func _walk(node: Array, depth: int, x0: float, root_total: float, out: Array) -> void:
	if depth >= max_depth:
		return
	var total: int = _total(node)
	var width: float = float(total) / root_total * GRAPH_W
	out.append({
		"name": str(node[0]),
		"depth": depth,
		"x0": x0,
		"width": width,
		"self": int(node[1]),
		"total": total,
	})
	var cursor: float = x0
	for child in node[2]:
		var cw: float = float(_total(child)) / root_total * GRAPH_W
		_walk(child, depth + 1, cursor, root_total, out)
		cursor += cw


## The largest self-sample count in the tree. The tint is normalised against this
## so at least one bar reaches full red — an absolute scale would leave a profile
## with no single hotspot looking uniformly cold, which is a different claim.
func _peak_self(rows: Array) -> int:
	var peak: int = 1
	for r in rows:
		peak = maxi(peak, int(r["self"]))
	return peak


# --- geometry -------------------------------------------------------------

func _build_board() -> void:
	var board := MeshInstance3D.new()
	board.name = "Board"
	var box := BoxMesh.new()
	box.size = Vector3(BOARD_W, BOARD_H, BOARD_D)
	board.mesh = box
	board.position = Vector3(0.0, BOARD_BOTTOM + BOARD_H * 0.5, 0.0)
	board.material_override = _grid_material(
		Color(0.13, 0.14, 0.18), Color(0.35, 0.42, 0.52), 0.4)
	_own(board)

	for side in [-1.0, 1.0]:
		var leg := MeshInstance3D.new()
		var lb := BoxMesh.new()
		lb.size = Vector3(LEG_W, BOARD_BOTTOM, LEG_W)
		leg.mesh = lb
		leg.position = Vector3(float(side) * (BOARD_W * 0.5 - 0.14),
			BOARD_BOTTOM * 0.5, 0.0)
		leg.material_override = _grid_material(
			Color(0.22, 0.23, 0.27), Color(0.40, 0.44, 0.52), 0.3)
		_own(leg)


func _build_bars() -> void:
	var rows: Array = _rows()
	if rows.is_empty():
		return
	var peak: float = float(_peak_self(rows))
	var row_h: float = GRAPH_H / float(max_depth)
	var left: float = -GRAPH_W * 0.5
	for r in rows:
		var w: float = float(r["width"]) - BAR_GAP
		if w <= 0.004:
			continue
		var depth: int = int(r["depth"])
		var cx: float = left + float(r["x0"]) + float(r["width"]) * 0.5
		var cy: float = BOARD_BOTTOM + GRAPH_BOTTOM + float(depth) * row_h + row_h * 0.5

		var bar := MeshInstance3D.new()
		bar.name = "Bar_%s" % str(r["name"])
		var box := BoxMesh.new()
		box.size = Vector3(w, row_h - BAR_GAP, 0.03)
		bar.mesh = box
		bar.position = Vector3(cx, cy, BAR_Z)
		var share: float = clampf(float(r["self"]) / peak, 0.0, 1.0)
		var tint: Color = COOL.lerp(HOT, share)
		bar.material_override = _bar_material(tint, share)
		_own(bar)

		_add_bar_label(str(r["name"]), cx, cy, w)


## A frame is named on its own bar only if the name fits at a size a standing
## player can read. A squeezed 8 pt label on a 3 cm bar is noise; the caption band
## carries the two frames that actually matter.
func _add_bar_label(text: String, cx: float, cy: float, bar_w: float) -> void:
	var chars: int = maxi(1, text.length())
	var fit_h: float = (bar_w - 0.024) / (float(chars) * 0.52)
	var h: float = minf(0.042, fit_h)
	if h < 0.017:
		return
	var label := Label3D.new()
	label.text = text
	label.font_size = 48
	label.pixel_size = h / 48.0
	label.modulate = Color(0.06, 0.07, 0.09)
	label.outline_size = 0
	label.position = Vector3(cx, cy, BAR_Z + 0.018)
	label.no_depth_test = false
	_own(label)


func _build_captions() -> void:
	var rows: Array = _rows()
	if rows.is_empty():
		return
	var root_total: int = _total(CALL_TREE)

	# Widest frame below the root: the biggest SUBTREE. It is the one the eye
	# lands on and, nine times out of ten, the one that is innocent.
	var widest: Dictionary = {}
	var hottest: Dictionary = {}
	for r in rows:
		if int(r["depth"]) >= 1:
			if widest.is_empty() or int(r["total"]) > int(widest["total"]):
				widest = r
		if hottest.is_empty() or int(r["self"]) > int(hottest["self"]):
			hottest = r

	var header: String = caption
	if header == "":
		header = "ONE FRAME — %d SAMPLES, %d ROWS DEEP" % [root_total, max_depth]
	_add_band(header, BOARD_BOTTOM + BOARD_H - 0.075, 0.040,
		Color(0.72, 0.78, 0.88))

	if not widest.is_empty():
		var pct: float = float(widest["total"]) / float(root_total) * 100.0
		_add_band("widest  %s — %d of %d samples (%d%%)" % [
			str(widest["name"]), int(widest["total"]), root_total, int(round(pct))],
			BOARD_BOTTOM + 0.145, 0.034, Color(0.55, 0.72, 0.90))
	if not hottest.is_empty():
		_add_band("hottest  %s — %d samples in its own body" % [
			str(hottest["name"]), int(hottest["self"])],
			BOARD_BOTTOM + 0.088, 0.034, HOT)


func _add_band(text: String, y: float, height_m: float, tint: Color) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 48
	label.pixel_size = height_m / 48.0
	label.modulate = tint
	label.outline_size = 3
	label.outline_modulate = Color(0.04, 0.04, 0.06)
	label.position = Vector3(0.0, y, BAR_Z + 0.006)
	_own(label)


# --- material -------------------------------------------------------------

## Bars carry a plain emissive material rather than the grid shader: a wireframe
## grid drawn over a 3 cm bar reads as a texture, and the tint is the only signal
## the bar is carrying.
func _bar_material(tint: Color, share: float) -> Material:
	var m := StandardMaterial3D.new()
	m.albedo_color = tint
	m.roughness = 0.5
	m.emission_enabled = true
	m.emission = tint
	m.emission_energy_multiplier = 0.35 + share * 1.5
	return m


func _grid_material(fill: Color, wire: Color, emit: float) -> Material:
	var shader: Shader = load(SHADER_PATH)
	if shader:
		var m := ShaderMaterial.new()
		m.shader = shader
		m.set_shader_parameter("modelColor", fill)
		m.set_shader_parameter("wireframeColor", wire)
		m.set_shader_parameter("emissionColor", wire)
		m.set_shader_parameter("width", 1.0)
		m.set_shader_parameter("blur", 1.0)
		m.set_shader_parameter("emission_strength", emit)
		m.set_shader_parameter("modelOpacity", 1.0)
		m.set_shader_parameter("wireframeOpacity", 1.0)
		m.set_shader_parameter("globalOpacity", 1.0)
		m.set_shader_parameter("show_interior", true)
		return m
	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = fill
	fallback.roughness = 0.4
	return fallback


## Tear down only what this script made, then rebuild in place. Synchronous —
## a deferred rebuild lands after the grid has grounded and framed us and would
## undo both.
func _rebuild_now() -> void:
	for c in _created:
		if is_instance_valid(c) and c.get_parent() == self:
			remove_child(c)
			c.queue_free()
	_created.clear()
	_build_all()


## Grid config. Keys: "max_depth" (1-6), "caption".
func apply_grid_config(config_data: Dictionary) -> void:
	var before_depth: int = max_depth
	var before_caption: String = caption

	if config_data.has("max_depth"):
		max_depth = clampi(int(config_data["max_depth"]), 1, 6)
	if config_data.has("caption"):
		caption = str(config_data["caption"])

	if not _built:
		return
	if max_depth == before_depth and caption == before_caption:
		# Nothing geometric changed. curation_station hands every artifact it
		# frames a config one line after setting its labels; rebuilding on a
		# no-op would throw that framing away.
		return

	_rebuild_now()
	print("[ProfilerFlameGraph] Config applied — max_depth=%d" % max_depth)
