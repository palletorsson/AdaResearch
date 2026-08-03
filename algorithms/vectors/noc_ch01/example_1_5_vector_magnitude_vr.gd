# ===========================================================================
# NOC Example 1.5: Vector Magnitude
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_VEC := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_GAUGE := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")

# ═══════════════════════════════════════════════════════════════════════════
# STAGE-2 DNA — `decomposition` and `metric`
# ═══════════════════════════════════════════════════════════════════════════
#
# WHAT THE GAUGE IS A GAUGE OF, and WHERE ITS NUMBER COMES FROM.
#
# Both words and both value lists are taken character for character from the
# sibling bench vector_magnitude_demo (commons/artifacts/vector_magnitude_demo),
# promoted 2026-07-29, which teaches the same quantity with the same vocabulary.
# A shared vocabulary is only honest if the siblings measure alike, so nothing
# here is a synonym: "star" is the components all leaving the origin on both
# benches, "chain" is the components walked end to end on both, "none" is the
# claim left to the numbers with no supporting geometry on both.
#
#   decomposition
#     none    one arrow, a gauge bar and a number. Nothing says WHERE the number
#             comes from. THE SHIPPED BUILD, byte for byte — outside `none` not
#             one component node is ever created.
#     star    the components drawn from the origin, x red, y green, z blue. The
#             Pythagorean reading: three legs from a shared corner, and the
#             magnitude is the closure over them.
#     chain   the same three components walked tip to tail, arriving exactly on
#             the vector's tip. Magnitude stops being a formula and becomes the
#             shortcut across a staircase you can see the steps of.
#
#   metric — which norm the instrument reads. sqrt(x²+y²+z²) was welded into
#            _process as `vector.length()`, so the bench could only ever argue
#            that "length" means one thing.
#     euclidean   vector.length(). The shipped reading.
#     taxicab     |x| + |y| + |z|. Under decomposition=chain this is literally the
#                 length of the walked path, so the two axes read each other.
#     chebyshev   max(|x|, |y|, |z|). The longest single component; the staircase
#                 collapses to its tallest step.
#
# The arrow, the gauge bar and the readout are the same three nodes at the same
# three positions in every reading. What changes is what is standing next to them
# and what the bar is measuring.
@export_enum("none", "star", "chain") var decomposition: String = "none"
@export_enum("euclidean", "taxicab", "chebyshev") var metric: String = "euclidean"

## Allow-lists. An unknown word in a map token falls back to the shipped reading
## rather than stranding a placement with a blank bench.
const DECOMPOSITIONS: PackedStringArray = ["none", "star", "chain"]
const METRICS: PackedStringArray = ["euclidean", "taxicab", "chebyshev"]

@export var vector: Vector3 = Vector3(0.2, 0.15, 0)

var _sim_root: Node3D
var _arrow: MeshInstance3D
var _gauge_bar: MeshInstance3D
var _magnitude_label: Label3D
var _center: Vector3 = Vector3(0, 0.5, 0)
var _controller_root: Node3D

# ── DNA state ────────────────────────────────────────────────────────────────
## The gauge's own caption. Held so `metric` can say which norm the bar reads;
## under euclidean its text is the shipped literal "Magnitude" and never changes.
var _title_label: Label3D = null
## Built only for decomposition != "none"; null on every shipped placement.
var _components_root: Node3D = null
var _leg_x: MeshInstance3D = null
var _leg_y: MeshInstance3D = null
var _leg_z: MeshInstance3D = null
var _tip_dot: MeshInstance3D = null

const DNA_ROD: float = 0.007
const DNA_RED := Color(0.95, 0.35, 0.35)
const DNA_GREEN := Color(0.45, 0.95, 0.45)
const DNA_BLUE := Color(0.40, 0.62, 1.0)

func _ready() -> void:
	_read_grid_config_meta()
	_setup_environment()
	_spawn_arrow()
	_spawn_gauge()
	_apply_metric()
	_apply_decomposition()
	set_process(true)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	add_child(_sim_root)


	_controller_root = Node3D.new()
	_controller_root.position = Vector3(0.75, 0.5, 0)
	add_child(_controller_root)

	var x_controller := CONTROLLER_SCENE.instantiate()
	x_controller.parameter_name = "Vec.x"
	x_controller.min_value = -0.3
	x_controller.max_value = 0.3
	x_controller.default_value = vector.x
	x_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(x_controller)
	x_controller.value_changed.connect(func(v: float) -> void:
		vector.x = v
	)
	x_controller.set_value(vector.x)

	var y_controller := CONTROLLER_SCENE.instantiate()
	y_controller.parameter_name = "Vec.y"
	y_controller.min_value = -0.3
	y_controller.max_value = 0.3
	y_controller.default_value = vector.y
	y_controller.position = Vector3(0, -0.18, 0)
	y_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(y_controller)
	y_controller.value_changed.connect(func(v: float) -> void:
		vector.y = v
	)
	y_controller.set_value(vector.y)

func _spawn_arrow() -> void:
	_arrow = MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.01
	cylinder.bottom_radius = 0.01
	cylinder.height = 0.1
	_arrow.mesh = cylinder
	_arrow.material_override = MAT_VEC
	_sim_root.add_child(_arrow)

func _spawn_gauge() -> void:
	var gauge_root := Node3D.new()
	gauge_root.position = Vector3(-0.45, 0.5, 0)
	_sim_root.add_child(gauge_root)

	_gauge_bar = MeshInstance3D.new()
	var bar := BoxMesh.new()
	bar.size = Vector3(0.02, 0.1, 0.02)
	_gauge_bar.mesh = bar
	_gauge_bar.material_override = MAT_GAUGE
	gauge_root.add_child(_gauge_bar)

	_magnitude_label = Label3D.new()
	_magnitude_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_magnitude_label.font_size = 20
	_magnitude_label.modulate = Color(1.0, 0.85, 1.0)
	_magnitude_label.position = Vector3(0, -0.25, 0)
	gauge_root.add_child(_magnitude_label)

	var title := Label3D.new()
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.font_size = 18
	title.modulate = Color(1.0, 0.85, 1.0)
	title.position = Vector3(0, 0.28, 0)
	title.text = "Magnitude"
	gauge_root.add_child(title)
	_title_label = title

func _process(_delta: float) -> void:
	var magnitude: float = _norm(vector)

	_update_arrow(_arrow, _center, vector)

	var bar_height: float = clamp(magnitude * 2.0, 0.0, 0.8)
	_gauge_bar.scale.y = bar_height / 0.1
	_gauge_bar.position.y = -0.2 + bar_height * 0.5

	_magnitude_label.text = "%.3f" % magnitude

	if _components_root != null:
		_dna_update()

func _update_arrow(arrow: MeshInstance3D, origin: Vector3, vec: Vector3) -> void:
	var length := vec.length()
	if length < 0.01:
		arrow.visible = false
		return

	arrow.visible = true
	arrow.position = origin + vec * 0.5
	arrow.look_at_from_position(arrow.position, origin + vec, Vector3.UP)
	arrow.rotate_object_local(Vector3.RIGHT, PI / 2)
	arrow.scale = Vector3(1, length, 1)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


# ═══════════════════════════════════════════════════════════════════════════
# CONFIG
# ═══════════════════════════════════════════════════════════════════════════

## Grid config arrives twice and by two different routes: GridInteractablesComponent
## sets config_<key> metadata on the instantiated root and then calls
## apply_grid_config(), and the capture harness calls apply_grid_config() before the
## scene enters the tree. Reading the metadata on the way in means the decomposition
## is built once, correctly, instead of built as `none` and then raised.
##
## Costs nothing when no token is present: the exports keep their defaults and not a
## single existing placement changes.
func _read_grid_config_meta() -> void:
	var node: Node = self
	while node != null:
		if node.has_meta("config_decomposition"):
			decomposition = str(node.get_meta("config_decomposition"))
		if node.has_meta("config_metric"):
			metric = str(node.get_meta("config_metric"))
		node = node.get_parent()


## Config from map_data.json tokens: #decomposition:chain  ·  #decomposition:star#metric:taxicab
##
## GUARDED ON CHANGE, deliberately. A placement carrying any other token arrives here
## with neither key, and the grid reaches this twice for one placement; an unguarded
## rebuild would tear down and re-raise the components on both of those, for nothing.
func apply_grid_config(config: Dictionary) -> void:
	if config.is_empty():
		return

	if config.has("metric"):
		var m: String = str(config["metric"]).strip_edges().to_lower()
		if METRICS.has(m) and m != metric:
			metric = m
			# Before _ready() the gauge does not exist yet and _ready() does this itself.
			if _title_label != null:
				_apply_metric()

	if config.has("decomposition"):
		var d: String = str(config["decomposition"]).strip_edges().to_lower()
		if DECOMPOSITIONS.has(d) and d != decomposition:
			decomposition = d
			if _sim_root != null:
				_apply_decomposition()


# ═══════════════════════════════════════════════════════════════════════════
# METRIC
# ═══════════════════════════════════════════════════════════════════════════

## The length of `vector` under the declared norm. `euclidean` returns
## vector.length() — the identical call the gauge and the readout always made.
func _norm(v: Vector3) -> float:
	if metric == "taxicab":
		return absf(v.x) + absf(v.y) + absf(v.z)
	if metric == "chebyshev":
		return maxf(absf(v.x), maxf(absf(v.y), absf(v.z)))
	return v.length()


## The caption names the norm, because a bar that reads 0.35 where it used to read
## 0.25 is otherwise an unexplained instrument. Under euclidean the text is the
## shipped literal and the label is untouched.
func _apply_metric() -> void:
	var want: String = String(metric).strip_edges().to_lower()
	if not METRICS.has(want):
		want = "euclidean"
	metric = want
	if _title_label == null:
		return
	if want == "taxicab":
		_title_label.text = "Magnitude  |x|+|y|+|z|"
	elif want == "chebyshev":
		_title_label.text = "Magnitude  max|x_i|"
	else:
		_title_label.text = "Magnitude"


# ═══════════════════════════════════════════════════════════════════════════
# DECOMPOSITION
# ═══════════════════════════════════════════════════════════════════════════

## `none` frees the components and returns the bench to arrow-bar-number; the other
## two readings build the same three legs once and only move them.
func _apply_decomposition() -> void:
	var want: String = String(decomposition).strip_edges().to_lower()
	if not DECOMPOSITIONS.has(want):
		want = "none"
	decomposition = want

	if want == "none":
		if _components_root != null:
			_components_root.queue_free()
			_components_root = null
			_leg_x = null
			_leg_y = null
			_leg_z = null
			_tip_dot = null
		return

	if _components_root == null:
		_build_components()

	# The tip marker only means something when the walk is supposed to arrive on it.
	if _tip_dot != null:
		_tip_dot.visible = (want == "chain")


func _build_components() -> void:
	_components_root = Node3D.new()
	_components_root.name = "Decomposition"
	add_child(_components_root)

	_leg_x = _dna_rod(DNA_RED)
	_leg_y = _dna_rod(DNA_GREEN)
	_leg_z = _dna_rod(DNA_BLUE)

	_tip_dot = MeshInstance3D.new()
	var dot := SphereMesh.new()
	dot.radius = 0.012
	dot.height = 0.024
	_tip_dot.mesh = dot
	_tip_dot.material_override = _dna_mat(Color(1.0, 0.85, 0.35), 1.0)
	_tip_dot.visible = false
	_components_root.add_child(_tip_dot)


func _dna_rod(c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(DNA_ROD, 1.0, DNA_ROD)   # scaled to the component's length per frame
	mi.mesh = bm
	mi.material_override = _dna_mat(c, 0.8)
	mi.visible = false
	_components_root.add_child(mi)
	return mi


func _dna_mat(c: Color, emit: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.6
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	return m


## star  — all three legs leave the origin.
## chain — each leg starts where the previous one ended, so the last one lands on
##         the tip the arrow points at. Nothing else differs between them: same
##         three vectors, same three colours, a different place to stand.
func _dna_update() -> void:
	var cx: Vector3 = Vector3(vector.x, 0.0, 0.0)
	var cy: Vector3 = Vector3(0.0, vector.y, 0.0)
	var cz: Vector3 = Vector3(0.0, 0.0, vector.z)

	if decomposition == "chain":
		_dna_place(_leg_x, _center, cx)
		_dna_place(_leg_y, _center + cx, cy)
		_dna_place(_leg_z, _center + cx + cy, cz)
	else:
		_dna_place(_leg_x, _center, cx)
		_dna_place(_leg_y, _center, cy)
		_dna_place(_leg_z, _center, cz)

	if _tip_dot != null and _tip_dot.visible:
		_tip_dot.position = _center + vector


## Seats a unit-height rod along `vec` from `origin`. The length test is only about
## degenerate components, so a leg that collapses and grows back comes back with it.
func _dna_place(mi: MeshInstance3D, origin: Vector3, vec: Vector3) -> void:
	if mi == null:
		return
	var l: float = vec.length()
	if l < 0.005:
		mi.visible = false
		return
	mi.visible = true
	mi.position = origin + vec * 0.5
	var up: Vector3 = Vector3.UP
	if absf((vec / l).dot(Vector3.UP)) > 0.999:
		up = Vector3.FORWARD          # look_at cannot use an up parallel to the aim
	mi.look_at_from_position(mi.position, origin + vec, up)
	mi.rotate_object_local(Vector3.RIGHT, PI / 2)
	mi.scale = Vector3(1.0, l, 1.0)
