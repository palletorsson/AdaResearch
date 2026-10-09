extends Node3D

const BakedText = preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: D = lim(log N(e) / log(1/e)). Cover the shape with boxes. Count. Shrink. Count again. The slope IS the dimension.
# desire: To measure. To show that fractals live between integer dimensions. Sierpinski is not 1D or 2D — it's 1.585D.
# critical_parameter: Grid resolution — coarse grids give rough estimates, fine grids converge to true dimension.
# triggers: Grid cycles → progressively finer overlay, log-log plot updates → regression line converges to D, highlight → current scale shown
# emerges: Fractal dimension from the scaling relationship. The number 1.585 from pure geometry. Measurement from counting.
# needs: VR shape selector [missing — only Sierpinski]. Manual grid control [missing — auto-cycles]. Different fractal inputs.
# relationships: Lives in Fractal_KochSierpinski. Complements the geometric fractals with quantitative measurement. Feeds into the concept that dimension is not always integer.
# truth: Fractal dimension is not a property of the shape. It's a property of how the shape fills space at every scale.

## Box-counting dimension measurement tool.
## Generates a fractal shape (Sierpinski triangle), then overlays progressively
## finer grids and counts occupied boxes at each scale. Plots log(count) vs
## log(1/box_size) — the slope IS the fractal dimension.

const GRID_SCALES := [2, 4, 8, 16, 32, 64]
const SHAPE_SIZE := 6.0
const POINT_COUNT := 8000

# ═══════════════════════════════════════════════════════════════════════════
# STAGE-2 DNA — `evidence`
# ═══════════════════════════════════════════════════════════════════════════
#
# WHAT A MEASUREMENT SHOWS OF ITS OWN PROCEDURE. This artifact is not a fractal;
# it is an act of measuring one, and the number it prints (D = 1.585) is the
# slope of a ladder of six coverings that the shipped build shows ONE RUNG AT A
# TIME, on a two-second timer. So the still frame a room ever actually holds is a
# single grid over a cloud plus an answer — the procedure asserted rather than
# performed.
#
# That is the same question koch_curve and fibonacci_sequences already ask of
# their own iteration, so this TAKES THEIR WORD AND THEIR FOUR VALUES verbatim
# rather than inventing a synonym for it. Three fractal artifacts, one vocabulary:
# a room can now ask "how much working is on show here" of all of them and get
# answers on the same scale.
#
#   result    the shipped instrument: cloud, one grid at the scale the timer
#             happens to be on, the log-log plot, D printed. Byte for byte the
#             legacy build, timer and all.  (DEFAULT)
#   trace     all SIX coverings at once, stacked 0.35 m apart up the Y axis over
#             the same cloud — 2 boxes a side at the bottom, 64 at the top, cold
#             blue to hot magenta. The ladder the slope is read off, standing up
#             in the room instead of arriving one rung every two seconds.
#   longhand  the counting written out. At 16 divisions every OCCUPIED cell is
#             filled in as a warm tile, so N(e) stops being a printed integer and
#             becomes a countable area — the cover itself, next to the number it
#             produced. The empty cells stay as bare line.
#   axiom     the gasket alone. Grid, plot, regression line, axis labels and the
#             D readout all muted; what is left is the shape before anyone
#             measured it, which is the thing the whole apparatus exists against.
#
# The three non-default values STOP THE TWO-SECOND CYCLE. An axis whose picture
# is repainted by _process every two seconds is an axis no still can photograph;
# `result` keeps the cycle exactly as shipped.
#
# STRICTLY ADDITIVE and RNG-FREE. _apply_evidence() is appended to the END of
# _ready(), after every randi() in _generate_sierpinski_points() and after both
# update passes, reads the finished scene graph, and returns immediately at
# `result`. It draws no random number, so the cloud is identical at all four.
const EVIDENCES: PackedStringArray = ["result", "trace", "longhand", "axiom"]
@export_enum("result", "trace", "longhand", "axiom") var evidence: String = "result"

## SEED for the chaos game. The gasket is drawn by 8000 accumulated random
## halvings, so an unseeded run scatters 8000 points DIFFERENTLY every boot —
## and the box counts, and therefore the printed D, move with them. Four variants
## of an unseeded run are four different clouds, and the bite critic would read
## that scatter as a confident result about `evidence`.
## -1 keeps the legacy behaviour EXACTLY: the global randi() stream is used, with
## no seed() call anywhere, precisely as it always was. Any value >= 0 pins the
## cloud so the four tiles differ only in what is drawn OVER it.
@export var shape_seed: int = -1

## Stand an INVISIBLE box (layers = 0) around the union of every value's extent,
## so the framing walk sizes all four shots identically. It has to exist: `axiom`
## mutes the plot at x = 5..8 and `trace` adds 2.1 m of grids overhead, so a
## camera placed from each variant's own AABB would frame four different crops
## and the bite report would be a picture of the framing. Default false — not one
## placement changes; a capture harness sets it true via dna.fixture.
@export var capture_anchor: bool = false

## The scale `longhand` fills in. Index 3 of GRID_SCALES = 16 divisions: fine
## enough that the cover reads as a fractal and not as four big squares, coarse
## enough that the tiles are individually countable, which is the entire point.
const LONGHAND_SCALE_IDX := 3
## Vertical pitch of the `trace` stack. Six rungs at 0.35 m clears the 0.03 m
## point spheres and still fits under the title board at y = 5.5.
const TRACE_STEP := 0.35
const TRACE_BASE_Y := 0.06
const TRACE_COLD := Color(0.24, 0.55, 1.0, 0.55)
const TRACE_HOT := Color(1.0, 0.25, 0.72, 0.55)
const LONGHAND_FILL := Color(1.0, 0.62, 0.18, 0.5)

## Set by trace / longhand / axiom: the exhibit stands still.
var _static_evidence := false
## Grids built by `trace`, and the filled cover built by `longhand`.
var _evidence_parts: Array[MeshInstance3D] = []

## null unless shape_seed >= 0. Null means "use the global randi()", which is
## what every existing placement does.
var _rng: RandomNumberGenerator = null
var _fractal_points: Array[Vector3] = []
var _grid_lines: Array[MeshInstance3D] = []
var _current_scale_idx := 0
var _display_timer := 0.0
var _counts: Array[int] = []
var _plot_mesh: ImmediateMesh
var _plot_instance: MeshInstance3D
var _point_cloud: MultiMeshInstance3D
var _grid_instance: MeshInstance3D
var _grid_mesh: ImmediateMesh
var _scale_tag: Node3D
var _dimension_tag: Node3D
const _SCALE_TAG_POS := Vector3(0.0, 4.8, 3.0)
const _SCALE_TAG_COLOR := Color(1.0, 0.9, 0.3)
const _DIMENSION_TAG_POS := Vector3(5.0, 5.5, 0.0)
const _DIMENSION_TAG_COLOR := Color(0.4, 1.0, 0.6)


func _ready() -> void:
	_read_dna()
	# Built ONLY when shape_seed >= 0. At the -1 default nothing is constructed and
	# _pick_vertex() falls through to the bare global randi(), so the legacy stream
	# is untouched — no seed() call is made anywhere on this path.
	if shape_seed >= 0:
		_rng = RandomNumberGenerator.new()
		_rng.seed = shape_seed
	_generate_sierpinski_points()
	_setup_point_cloud()
	_setup_grid_display()
	_setup_plot()
	_setup_labels()

	# Pre-compute all counts
	for scale in GRID_SCALES:
		_counts.append(_count_boxes(scale))

	_update_grid_display()
	_update_plot()

	# APPENDED LAST. Reads the finished scene graph; draws no random number and
	# returns immediately at `result`.
	_apply_evidence()


func _generate_sierpinski_points() -> void:
	# Chaos game: Sierpinski triangle in XZ plane
	var vertices := [
		Vector3(-SHAPE_SIZE * 0.5, 0.0, -SHAPE_SIZE * 0.3),
		Vector3(SHAPE_SIZE * 0.5, 0.0, -SHAPE_SIZE * 0.3),
		Vector3(0.0, 0.0, SHAPE_SIZE * 0.5),
	]
	var current := Vector3(0.0, 0.0, 0.0)
	# Burn in
	for _i in 100:
		current = (current + vertices[_pick_vertex()]) * 0.5

	for _i in POINT_COUNT:
		current = (current + vertices[_pick_vertex()]) * 0.5
		_fractal_points.append(current)


## The chaos game's only draw. With no seed declared this IS `randi() % 3` — the
## same global call, in the same place, the same number of times — so the legacy
## point cloud is reproduced exactly. With a seed it comes off a private
## generator instead, and the gasket is the same gasket at every capture.
func _pick_vertex() -> int:
	if _rng != null:
		return _rng.randi() % 3
	return randi() % 3


func _setup_point_cloud() -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = _fractal_points.size()
	mm.visible_instance_count = _fractal_points.size()

	var sphere := SphereMesh.new()
	sphere.radius = 0.03
	sphere.height = 0.06
	sphere.radial_segments = 4
	sphere.rings = 2
	mm.mesh = sphere

	for i in _fractal_points.size():
		var xform := Transform3D.IDENTITY
		xform.origin = _fractal_points[i]
		mm.set_instance_transform(i, xform)
		mm.set_instance_color(i, Color(0.3, 0.8, 1.0, 0.6))

	_point_cloud = MultiMeshInstance3D.new()
	_point_cloud.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_point_cloud.material_override = mat
	add_child(_point_cloud)


func _setup_grid_display() -> void:
	_grid_mesh = ImmediateMesh.new()
	_grid_instance = MeshInstance3D.new()
	_grid_instance.mesh = _grid_mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 1.0, 0.15)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_grid_instance.material_override = mat
	add_child(_grid_instance)


func _setup_plot() -> void:
	_plot_mesh = ImmediateMesh.new()
	_plot_instance = MeshInstance3D.new()
	_plot_instance.mesh = _plot_mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_plot_instance.material_override = mat
	_plot_instance.position = Vector3(5.0, 3.0, 0.0)
	add_child(_plot_instance)

	# Plot axes labels
	var x_label := BakedText.make_tag("log(1/box_size)", Color(0.9, 0.92, 0.95), 0.22)
	if x_label:
		x_label.position = Vector3(5.0, 2.2, 0.0)
		add_child(x_label)

	var y_label := BakedText.make_tag("log(count)", Color(0.9, 0.92, 0.95), 0.22)
	if y_label:
		y_label.position = Vector3(3.5, 4.5, 0.0)
		add_child(y_label)


func _setup_labels() -> void:
	var title := BakedText.make_tag("Box-Counting Dimension", Color(0.95, 0.97, 1.0), 0.32)
	if title:
		title.position = Vector3(0.0, 5.5, 3.0)
		add_child(title)

	# Scale + dimension boards are rebuilt each time their text changes.
	_rebuild_scale_tag("")
	_rebuild_dimension_tag("")


func _rebuild_scale_tag(text: String) -> void:
	if _scale_tag and is_instance_valid(_scale_tag):
		_scale_tag.queue_free()
		_scale_tag = null
	if text.is_empty():
		return
	_scale_tag = BakedText.make_tag(text, _SCALE_TAG_COLOR, 0.24)
	if _scale_tag:
		_scale_tag.position = _SCALE_TAG_POS
		add_child(_scale_tag)


func _rebuild_dimension_tag(text: String) -> void:
	if _dimension_tag and is_instance_valid(_dimension_tag):
		_dimension_tag.queue_free()
		_dimension_tag = null
	if text.is_empty():
		return
	_dimension_tag = BakedText.make_tag(text, _DIMENSION_TAG_COLOR, 0.28)
	if _dimension_tag:
		_dimension_tag.position = _DIMENSION_TAG_POS
		add_child(_dimension_tag)


func _process(delta: float) -> void:
	# trace / longhand / axiom are exhibits, not a loop. Only `result` cycles.
	if _static_evidence:
		return
	_display_timer += delta
	if _display_timer >= 2.0:
		_display_timer = 0.0
		_current_scale_idx = (_current_scale_idx + 1) % GRID_SCALES.size()
		_update_grid_display()
		_update_plot()


func _count_boxes(divisions: int) -> int:
	var box_size := SHAPE_SIZE / float(divisions)
	var occupied := {}
	var offset := Vector3(SHAPE_SIZE * 0.5, 0.0, SHAPE_SIZE * 0.5)

	for pt in _fractal_points:
		var shifted := pt + offset
		var ix := int(shifted.x / box_size)
		var iz := int(shifted.z / box_size)
		var key := ix * 10000 + iz
		occupied[key] = true

	return occupied.size()


func _update_grid_display() -> void:
	var divisions: int = GRID_SCALES[_current_scale_idx]
	var box_size := SHAPE_SIZE / float(divisions)
	var count: int = _counts[_current_scale_idx]

	_rebuild_scale_tag("%d boxes, %d occupied" % [divisions * divisions, count])

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 1.0, 0.12)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	_grid_mesh.clear_surfaces()
	_grid_mesh.surface_begin(Mesh.PRIMITIVE_LINES, mat)

	var half := SHAPE_SIZE * 0.5
	# Vertical lines
	for i in divisions + 1:
		var x := -half + i * box_size
		_grid_mesh.surface_add_vertex(Vector3(x, 0.01, -half))
		_grid_mesh.surface_add_vertex(Vector3(x, 0.01, half))

	# Horizontal lines
	for i in divisions + 1:
		var z := -half + i * box_size
		_grid_mesh.surface_add_vertex(Vector3(-half, 0.01, z))
		_grid_mesh.surface_add_vertex(Vector3(half, 0.01, z))

	_grid_mesh.surface_end()


func _update_plot() -> void:
	_plot_mesh.clear_surfaces()

	if _counts.size() < 2:
		return

	# Compute log-log points
	var log_points: Array[Vector2] = []
	for i in _counts.size():
		var box_size := SHAPE_SIZE / float(GRID_SCALES[i])
		var log_inv_size := log(1.0 / box_size) / log(2.0)
		var log_count := log(float(_counts[i])) / log(2.0)
		log_points.append(Vector2(log_inv_size, log_count))

	# Scale to display
	var x_min := log_points[0].x
	var x_max := log_points[log_points.size() - 1].x
	var y_min := log_points[0].y
	var y_max := log_points[log_points.size() - 1].y
	var x_range := maxf(x_max - x_min, 0.1)
	var y_range := maxf(y_max - y_min, 0.1)
	var plot_size := 3.0

	# Linear regression for dimension
	var sum_x := 0.0
	var sum_y := 0.0
	var sum_xy := 0.0
	var sum_xx := 0.0
	var n := float(log_points.size())
	for pt in log_points:
		sum_x += pt.x
		sum_y += pt.y
		sum_xy += pt.x * pt.y
		sum_xx += pt.x * pt.x
	var slope := (n * sum_xy - sum_x * sum_y) / maxf(n * sum_xx - sum_x * sum_x, 0.001)
	_rebuild_dimension_tag("D = %.3f" % slope)

	# Draw axes
	var axis_mat := StandardMaterial3D.new()
	axis_mat.albedo_color = Color(0.5, 0.5, 0.5, 0.4)
	axis_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	axis_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	_plot_mesh.surface_begin(Mesh.PRIMITIVE_LINES, axis_mat)
	_plot_mesh.surface_add_vertex(Vector3(0, 0, 0))
	_plot_mesh.surface_add_vertex(Vector3(plot_size, 0, 0))
	_plot_mesh.surface_add_vertex(Vector3(0, 0, 0))
	_plot_mesh.surface_add_vertex(Vector3(0, plot_size, 0))
	_plot_mesh.surface_end()

	# Draw data points and connecting line
	var point_mat := StandardMaterial3D.new()
	point_mat.albedo_color = Color(0.3, 0.8, 1.0)
	point_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	_plot_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, point_mat)
	for i in log_points.size():
		var px := (log_points[i].x - x_min) / x_range * plot_size
		var py := (log_points[i].y - y_min) / y_range * plot_size
		_plot_mesh.surface_add_vertex(Vector3(px, py, 0))
	_plot_mesh.surface_end()

	# Highlight current scale point
	var highlight_mat := StandardMaterial3D.new()
	highlight_mat.albedo_color = Color(1.0, 0.3, 0.4)
	highlight_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	if _current_scale_idx < log_points.size():
		var pt := log_points[_current_scale_idx]
		var px := (pt.x - x_min) / x_range * plot_size
		var py := (pt.y - y_min) / y_range * plot_size
		# Draw a small cross
		_plot_mesh.surface_begin(Mesh.PRIMITIVE_LINES, highlight_mat)
		_plot_mesh.surface_add_vertex(Vector3(px - 0.1, py, 0))
		_plot_mesh.surface_add_vertex(Vector3(px + 0.1, py, 0))
		_plot_mesh.surface_add_vertex(Vector3(px, py - 0.1, 0))
		_plot_mesh.surface_add_vertex(Vector3(px, py + 0.1, 0))
		_plot_mesh.surface_end()

	# Draw regression line
	var fit_mat := StandardMaterial3D.new()
	fit_mat.albedo_color = Color(0.3, 1.0, 0.5, 0.6)
	fit_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fit_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var intercept := (sum_y - slope * sum_x) / n

	_plot_mesh.surface_begin(Mesh.PRIMITIVE_LINES, fit_mat)
	var x0 := x_min
	var y0 := slope * x0 + intercept
	var x1 := x_max
	var y1 := slope * x1 + intercept
	_plot_mesh.surface_add_vertex(Vector3(0, (y0 - y_min) / y_range * plot_size, 0))
	_plot_mesh.surface_add_vertex(Vector3(plot_size, (y1 - y_min) / y_range * plot_size, 0))
	_plot_mesh.surface_end()


func apply_grid_config(config: Dictionary) -> void:
	for k in config.keys():
		set_meta("config_%s" % str(k), config[k])
	var was: String = evidence
	_read_dna()
	if evidence != was:
		_apply_evidence()


# ═══════════════════════════════════════════════════════════════════════════
# evidence — everything below is new and nothing above it moved.
# ═══════════════════════════════════════════════════════════════════════════

## Map tokens arrive as config_<key> metadata. An unreadable word keeps the
## shipped instrument rather than blanking a board four rooms expect to see.
func _read_dna() -> void:
	if has_meta("config_evidence"):
		var v: String = str(get_meta("config_evidence")).strip_edges().to_lower()
		if EVIDENCES.has(v):
			evidence = v
	if has_meta("config_shape_seed"):
		shape_seed = int(str(get_meta("config_shape_seed")))
	if has_meta("config_capture_anchor"):
		var a: String = str(get_meta("config_capture_anchor")).strip_edges().to_lower()
		capture_anchor = a == "true" or a == "1" or a == "yes"


func _apply_evidence() -> void:
	for part in _evidence_parts:
		if is_instance_valid(part):
			part.queue_free()
	_evidence_parts.clear()

	var key: String = str(evidence).strip_edges().to_lower()
	if not EVIDENCES.has(key):
		key = "result"

	# Restore the shipped state first, so a value change at runtime is reversible.
	_static_evidence = false
	_set_muted(_grid_instance, false)
	_set_muted(_plot_instance, false)
	_mute_tags(false)

	match key:
		"trace":
			_static_evidence = true
			_build_trace_stack()
		"longhand":
			_static_evidence = true
			_current_scale_idx = LONGHAND_SCALE_IDX
			_update_grid_display()
			_update_plot()
			_build_longhand_cover()
		"axiom":
			_static_evidence = true
			_set_muted(_grid_instance, true)
			_set_muted(_plot_instance, true)
			_mute_tags(true)

	if capture_anchor:
		_add_capture_anchor()


## All six coverings at once, one above the other. Each rung is the same line
## grid _update_grid_display() draws, at its own division count, lifted clear of
## the cloud so the ladder reads as a ladder.
func _build_trace_stack() -> void:
	for i in GRID_SCALES.size():
		var divisions: int = GRID_SCALES[i]
		var box_size := SHAPE_SIZE / float(divisions)
		var y := TRACE_BASE_Y + float(i) * TRACE_STEP
		var tint: Color = TRACE_COLD.lerp(TRACE_HOT, float(i) / float(maxi(GRID_SCALES.size() - 1, 1)))

		var mat := StandardMaterial3D.new()
		mat.albedo_color = tint
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

		var im := ImmediateMesh.new()
		im.surface_begin(Mesh.PRIMITIVE_LINES, mat)
		var half := SHAPE_SIZE * 0.5
		for j in divisions + 1:
			var x := -half + j * box_size
			im.surface_add_vertex(Vector3(x, y, -half))
			im.surface_add_vertex(Vector3(x, y, half))
		for j in divisions + 1:
			var z := -half + j * box_size
			im.surface_add_vertex(Vector3(-half, y, z))
			im.surface_add_vertex(Vector3(half, y, z))
		im.surface_end()

		var mi := MeshInstance3D.new()
		mi.name = "TraceRung_%d" % divisions
		mi.mesh = im
		mi.material_override = mat
		add_child(mi)
		_evidence_parts.append(mi)


## N(e) as an area instead of an integer: every cell the gasket actually touches
## at 16 divisions, filled in. Two triangles per occupied cell, laid at y = 0.02
## so they sit over the 0.01 grid lines without fighting them for the depth test.
func _build_longhand_cover() -> void:
	var divisions: int = GRID_SCALES[LONGHAND_SCALE_IDX]
	var box_size := SHAPE_SIZE / float(divisions)
	var half := SHAPE_SIZE * 0.5

	var occupied := {}
	var offset := Vector3(half, 0.0, half)
	for pt in _fractal_points:
		var shifted := pt + offset
		var ix := int(shifted.x / box_size)
		var iz := int(shifted.z / box_size)
		occupied[ix * 10000 + iz] = Vector2i(ix, iz)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = LONGHAND_FILL
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES, mat)
	var inset := box_size * 0.06
	for key in occupied:
		var cell: Vector2i = occupied[key]
		var x0 := -half + float(cell.x) * box_size + inset
		var z0 := -half + float(cell.y) * box_size + inset
		var x1 := x0 + box_size - inset * 2.0
		var z1 := z0 + box_size - inset * 2.0
		var y := 0.02
		im.surface_add_vertex(Vector3(x0, y, z0))
		im.surface_add_vertex(Vector3(x1, y, z0))
		im.surface_add_vertex(Vector3(x1, y, z1))
		im.surface_add_vertex(Vector3(x0, y, z0))
		im.surface_add_vertex(Vector3(x1, y, z1))
		im.surface_add_vertex(Vector3(x0, y, z1))
	im.surface_end()

	var mi := MeshInstance3D.new()
	mi.name = "LonghandCover"
	mi.mesh = im
	mi.material_override = mat
	add_child(mi)
	_evidence_parts.append(mi)


## layers = 0, never visible = false: the render layer mask is per-instance, so a
## muted node stops drawing while everything parented under it is left alone.
## Hiding a tag with `visible` would take its text mesh down with it and there
## would be no way to bring one back without the other.
func _set_muted(node: Node, muted: bool) -> void:
	if node == null or not is_instance_valid(node):
		return
	if node is VisualInstance3D:
		var vi: VisualInstance3D = node
		vi.layers = 0 if muted else 1
	for child in node.get_children():
		_set_muted(child, muted)


## Title, axis captions, scale board and D readout. The two rebuilt tags are
## re-muted after every rebuild by _apply_evidence, which longhand calls into.
func _mute_tags(muted: bool) -> void:
	for child in get_children():
		if child == _point_cloud or child == _grid_instance or child == _plot_instance:
			continue
		if _evidence_parts.has(child):
			continue
		if child.name == "CaptureAnchor":
			continue
		_set_muted(child, muted)


## An invisible box over the union of every value's extent. The cloud spans
## +/- 3 m; the plot instance sits at x = 5 and draws 3 m of axes up from y = 3;
## the title board is at y = 5.5; `trace` reaches TRACE_BASE_Y + 5 * TRACE_STEP.
## Fixed numbers, not measured ones — a box measured from the built scene would
## be a different box for each value, which is the failure it exists to prevent.
func _add_capture_anchor() -> void:
	if has_node("CaptureAnchor"):
		return
	var x_min := -SHAPE_SIZE * 0.5 - 0.5
	var x_max := 8.6
	var y_min := -0.2
	var y_max := 6.2
	var z_half := SHAPE_SIZE * 0.5 + 0.5
	var anchor := MeshInstance3D.new()
	anchor.name = "CaptureAnchor"
	var bm := BoxMesh.new()
	bm.size = Vector3(x_max - x_min, y_max - y_min, z_half * 2.0)
	anchor.mesh = bm
	anchor.position = Vector3((x_min + x_max) * 0.5, (y_min + y_max) * 0.5, 0.0)
	anchor.layers = 0
	add_child(anchor)
