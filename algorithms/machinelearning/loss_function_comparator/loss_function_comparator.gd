# loss_function_comparator.gd
# Same dataset, three different loss functions applied simultaneously.
# Left: MSE loss landscape (smooth bowl, single minimum).
# Center: Huber loss (robust to outliers, flat bottom).
# Right: Custom adversarial loss (multiple minima, deceptive valleys).
# A gradient descent ball rolls on each surface.
# The point: the "answer" depends entirely on which loss function you chose.
#
# @identity
#   essence: three landscapes from one dataset — the loss function is the author
#   desire: players see that optimization answers depend on the question you formalize
#   critical_parameter: outlier_fraction — how many data points are outliers
#   triggers: instantiation, dataset perturbation slider
#   emerges: the insight that loss functions are not discovered but designed
#   needs: [implemented] 3 terrain meshes, gradient descent balls, Label3D equations, controls
#   relationships: gradient_descent_landscape (single loss), optimization_algorithms (optimizer comparison)
#   truth: the landscape is not given — it is authored

extends Node3D

const BakedText = preload("res://commons/utils/baked_text_albedo.gd")

# --- Configuration ---
@export var terrain_resolution: int = 32
@export var terrain_size: float = 0.5
@export var terrain_height_scale: float = 0.15
@export var ball_radius: float = 0.012
@export var learning_rate: float = 0.02
@export var spacing: float = 0.6
@export var outlier_fraction: float = 0.15

# ------------------------------------------------------------------
# Stage-2 DNA axis — #tail:<value>
# ------------------------------------------------------------------
# WHAT SITS IN THE TAIL of the 20-sample dataset all three surfaces are fitted
# to — which samples are allowed to shape what counts as error. The title board
# says "Same data. Three loss functions. Three different answers." This axis
# makes the first sentence a variable and thereby tests the third.
#
# Named for the DATA, not for the verdict: the surfaces are computed from the
# samples, so varying the tail makes every terrain re-form honestly and none of
# the three loss rules has to pretend to be another.
#
#   few    the shipped look. outlier_fraction 0.15 coin-flipped over 20 samples
#          on the shipped seed 123, giving a handful of two-signed strays at
#          |noise| 1.5-3.0. MSE is a steep bowl, Huber the same bowl with the
#          walls flattened, adversarial is ridged.
#   none   no strays at all — every sample within +/-0.2 of the true line. MSE
#          and Huber then agree EXACTLY (both land on the least-squares fit);
#          on clean data the argument for choosing a loss function evaporates.
#   heavy  12 of the 20 samples in the tail. Both basins migrate ~0.17 m across
#          their 0.5 m tiles: when the tail is the majority, robustness fails.
#   sole   exactly one sample at |noise| 3.0 and nineteen clean — placed at
#          x = +1.0, where a single point buys the most tilt.
#   split  the tail is not noise but a coherent second population: six samples
#          on a line of slope -0.5. Every basin walks to a compromise made of
#          data the other basin calls error.
#
# The whole axis lives inside _generate_dataset(). Nothing else moves — in
# particular terrain_height_scale stays 0.15, because the legend boards clear the
# surfaces by exactly 0.10 m (_create_labels reads terrain_height_scale + 0.10)
# and raising one without the other would push a sheet into a board.
@export_enum("few", "none", "heavy", "sole", "split") var tail: String = "few"

## Accepted spellings. A typo has to fall back to the shipped dataset rather
## than half-resolve into a composition nobody asked for.
const TAILS: PackedStringArray = ["few", "none", "heavy", "sole", "split"]

## The shipped seed. Set at the top of every build so two builds of one axis
## value are pixel-identical; the slider/reset path deliberately keeps drawing
## from the running stream so a hand perturbation is a new draw.
const DATA_SEED: int = 123
## The +/-0.2 clean baseline the four composed tails SHARE, so the tail is the
## only difference between them (sole is literally none plus one point).
const JITTER_SEED: int = 9317
## Tail magnitudes for `heavy`, and the tight jitter on `split`'s second line.
const TAIL_SEED: int = 4471
const SPLIT_SEED: int = 5209

const HEAVY_COUNT: int = 12       # 60 % of 20
const SPLIT_COUNT: int = 6
const SPLIT_SLOPE: float = -0.5   # the second population's own honest line
const SOLE_MAGNITUDE: float = 3.0

# --- Internal ---
var _terrains: Array[MeshInstance3D] = []
var _terrain_materials: Array[StandardMaterial3D] = []
var _balls: Array[MeshInstance3D] = []
var _ball_positions: Array[Vector2] = []  # param space (x, z)
var _trail_points: Array[Array] = [[], [], []]
var _trail_meshes: Array[MeshInstance3D] = []
# Integrated 2D-in-3D boards (baked-text, no floating Label3D):
#   _legend_boards[t] — one per loss function: name + equation on a spaced tag.
#   _title_board       — title + subtitle consolidated onto one panel.
var _legend_boards: Array[Node3D] = []
var _title_board: Node3D

var _loss_names: Array[String] = ["MSE Loss", "Huber Loss", "Adversarial Loss"]
var _loss_equations: Array[String] = [
	"L = (1/n) sum (y - y_hat)^2",
	"L = Huber(delta=1.0)",
	"L = sum sin(3*e) + 0.5*e^2"
]
var _loss_colors: Array[Color] = [
	Color(0.3, 0.6, 0.9),   # Blue — MSE
	Color(0.4, 0.8, 0.45),  # Green — Huber
	Color(0.9, 0.35, 0.35), # Red — Adversarial
]

# Dataset
var _data_x: Array[float] = []
var _data_y: Array[float] = []
var _rng := RandomNumberGenerator.new()

var _controls: Node
var _running: bool = true
var _step_timer: float = 0.0
var _step_interval: float = 0.08

## Every node THIS script parents to itself. _rebuild_now frees exactly these —
## freeing get_children() would take the grid's own plates with it.
var _created: Array[Node] = []
var _built: bool = false
## Ball glow. Non-geometry, so a config that only carries `emissive` is applied
## in place and never triggers a rebuild.
var _emissive: bool = true


func _ready() -> void:
	_build_all()
	_built = true


## SYNCHRONOUS, from @export values alone — the sweep sets `tail` and adds the
## node to the tree, and gets three finished surfaces with no deferred step.
func _build_all() -> void:
	_rng.seed = DATA_SEED
	_generate_dataset()
	_create_terrains()
	_create_balls()
	_create_labels()
	_create_title()
	_create_controls()


func apply_grid_config(config_data: Dictionary) -> void:
	var before_tail: String = tail
	if config_data.has("tail"):
		tail = _pick_axis(str(config_data["tail"]), TAILS, tail)

	# Non-geometry key — applied IN PLACE, before the early returns, so it bites
	# even when the axis did not change and nothing is rebuilt.
	if config_data.has("emissive"):
		_emissive = _to_bool(config_data["emissive"], _emissive)
		_apply_emissive()

	if not _built:
		return
	if tail == before_tail:
		return
	_rebuild_now()
	print("[LossFunctionComparator] Config applied - tail=%s" % [tail])


## Inline, no call_deferred: a deferred rebuild that removes children first makes
## the grid's auto-grounding measure a zero AABB and bail.
func _rebuild_now() -> void:
	for c: Node in _created:
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_created.clear()
	_terrains.clear()
	_terrain_materials.clear()
	_balls.clear()
	_ball_positions.clear()
	_trail_meshes.clear()
	for tp: Array in _trail_points:
		tp.clear()
	_legend_boards.clear()
	_title_board = null
	_controls = null
	_build_all()


## Accept an axis value only if it names something we actually build.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


func _to_bool(v: Variant, fallback: bool) -> bool:
	if v is bool:
		return bool(v)
	if v is int or v is float:
		return float(v) != 0.0
	if v is String:
		var s: String = str(v).to_lower().strip_edges()
		if s == "true" or s == "1" or s == "yes" or s == "on":
			return true
		if s == "false" or s == "0" or s == "no" or s == "off":
			return false
	return fallback


## The balls are the only lit parts. With glow off they keep their colour as
## albedo so they still read as three descents rather than three grey pips.
func _apply_emissive() -> void:
	for t in range(_balls.size()):
		var m: StandardMaterial3D = _balls[t].material_override as StandardMaterial3D
		if m == null:
			continue
		m.emission_enabled = _emissive
		if _emissive:
			m.albedo_color = Color(1, 1, 1)
		else:
			m.albedo_color = _loss_colors[t].lerp(Color(1, 1, 1), 0.35)


# ------------------------------------------------------------------
# Dataset generation
# ------------------------------------------------------------------

# The ONLY place the #tail: axis acts. Twenty x positions are fixed; what varies
# is which of the twenty y values are allowed to be strays, and what kind.
func _generate_dataset() -> void:
	_data_x.clear()
	_data_y.clear()
	var n: int = 20
	for i in range(n):
		_data_x.append(float(i) / (n - 1) * 2.0 - 1.0)

	match tail:
		"none":
			_clean_baseline()
		"heavy":
			_tail_heavy()
		"sole":
			_tail_sole()
		"split":
			_tail_split()
		_:
			_tail_few()


# `few` — VERBATIM the shipped composition, including the draw ORDER, so the
# default renders the pre-promotion look exactly: a clean +/-0.2 draw per sample,
# an outlier_fraction coin flip, and on a hit a two-signed |noise| 1.5-3.0.
func _tail_few() -> void:
	for i in range(_data_x.size()):
		var noise: float = _rng.randf_range(-0.2, 0.2)
		if _rng.randf() < outlier_fraction:
			noise = _rng.randf_range(1.5, 3.0) * (1.0 if _rng.randf() > 0.5 else -1.0)
		_data_y.append(0.5 * _data_x[i] + noise)


# The tail-free dataset, and the shared substrate of the three composed tails
# below: twenty samples within +/-0.2 of y = 0.5x. On this data MSE and Huber are
# minimised at the SAME (w, b) — the two sheets stop disagreeing.
func _clean_baseline() -> void:
	var jit: RandomNumberGenerator = RandomNumberGenerator.new()
	jit.seed = JITTER_SEED
	for i in range(_data_x.size()):
		_data_y.append(0.5 * _data_x[i] + jit.randf_range(-0.2, 0.2))


# `heavy` — 12 of 20 in the tail, ONE-SIGNED. Two-signed strays leave the mean
# where it was and MSE's sheet is then translation-invariant to them, so a
# symmetric 60 % tail would have been a no-op on the surface that matters; a
# one-sided contaminating population is also the case the robustness argument is
# actually about. Spread evenly across x so the intercept takes the hit.
func _tail_heavy() -> void:
	_clean_baseline()
	var tr: RandomNumberGenerator = RandomNumberGenerator.new()
	tr.seed = TAIL_SEED
	for idx: int in _spread_indices(HEAVY_COUNT):
		_data_y[idx] = 0.5 * _data_x[idx] + tr.randf_range(1.5, 3.0)


# `sole` — nineteen clean samples and one at |noise| 3.0, put at x = +1.0 where
# a single point buys the largest slope change available to it.
func _tail_sole() -> void:
	_clean_baseline()
	var idx: int = _data_x.size() - 1
	_data_y[idx] = 0.5 * _data_x[idx] + SOLE_MAGNITUDE


# `split` — the tail is a coherent second population, six samples on their own
# line of slope -0.5 with only +/-0.05 of scatter. Nothing here is an error;
# there are two lines in the room and each fit calls the other one noise.
func _tail_split() -> void:
	_clean_baseline()
	var sj: RandomNumberGenerator = RandomNumberGenerator.new()
	sj.seed = SPLIT_SEED
	for idx: int in _spread_indices(SPLIT_COUNT):
		_data_y[idx] = SPLIT_SLOPE * _data_x[idx] + sj.randf_range(-0.05, 0.05)


# Evenly spaced sample indices, endpoints included — so a composed tail spans the
# whole x range and moves the slope as well as the intercept. Deterministic:
# rounding collisions are topped up from the low end, never from a draw.
func _spread_indices(count: int) -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	var n: int = _data_x.size()
	if count <= 0 or n <= 0:
		return out
	if count == 1:
		out.append(n - 1)
		return out
	for k in range(count):
		var idx: int = int(round(float(k) * float(n - 1) / float(count - 1)))
		if not out.has(idx):
			out.append(idx)
	var i: int = 0
	while out.size() < count and i < n:
		if not out.has(i):
			out.append(i)
		i += 1
	return out


# ------------------------------------------------------------------
# Loss functions over 2D parameter space (w, b) for y = w*x + b
# ------------------------------------------------------------------

func _mse_loss(w: float, b: float) -> float:
	var total := 0.0
	for i in range(_data_x.size()):
		var e: float = _data_y[i] - (w * _data_x[i] + b)
		total += e * e
	return total / _data_x.size()


func _huber_loss(w: float, b: float) -> float:
	var total := 0.0
	var delta := 1.0
	for i in range(_data_x.size()):
		var e: float = absf(_data_y[i] - (w * _data_x[i] + b))
		if e <= delta:
			total += 0.5 * e * e
		else:
			total += delta * (e - 0.5 * delta)
	return total / _data_x.size()


func _adversarial_loss(w: float, b: float) -> float:
	var total := 0.0
	for i in range(_data_x.size()):
		var e: float = _data_y[i] - (w * _data_x[i] + b)
		total += sin(3.0 * e) + 0.5 * e * e
	return total / _data_x.size()


func _eval_loss(loss_idx: int, w: float, b: float) -> float:
	match loss_idx:
		0: return _mse_loss(w, b)
		1: return _huber_loss(w, b)
		2: return _adversarial_loss(w, b)
	return 0.0


# ------------------------------------------------------------------
# Terrain meshes
# ------------------------------------------------------------------

func _create_terrains() -> void:
	for t in range(3):
		var mesh := _build_terrain_mesh(t)
		var mi := MeshInstance3D.new()
		mi.mesh = mesh

		var mat := StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_terrain_materials.append(mat)
		mi.material_override = mat

		mi.position = Vector3((t - 1) * spacing, 0, 0)
		add_child(mi)
		_created.append(mi)
		_terrains.append(mi)


func _build_terrain_mesh(loss_idx: int) -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var res := terrain_resolution
	var half := terrain_size * 0.5

	# Parameter ranges: w in [-2, 2], b in [-2, 2]
	var param_min := -2.0
	var param_max := 2.0
	var param_range := param_max - param_min

	# Find min/max loss for color normalization
	var min_loss := INF
	var max_loss := -INF
	var loss_grid: Array = []
	loss_grid.resize(res + 1)

	for ix in range(res + 1):
		loss_grid[ix] = []
		loss_grid[ix].resize(res + 1)
		for iz in range(res + 1):
			var w := param_min + (float(ix) / res) * param_range
			var b := param_min + (float(iz) / res) * param_range
			var loss := _eval_loss(loss_idx, w, b)
			loss_grid[ix][iz] = loss
			min_loss = minf(min_loss, loss)
			max_loss = maxf(max_loss, loss)

	var loss_range := max_loss - min_loss
	if loss_range < 0.001:
		loss_range = 1.0

	# Build mesh
	for ix in range(res):
		for iz in range(res):
			# Quad: two triangles
			for tri in range(2):
				var offsets: Array
				if tri == 0:
					offsets = [[0, 0], [1, 0], [1, 1]]
				else:
					offsets = [[0, 0], [1, 1], [0, 1]]

				for off in offsets:
					var gx: int = ix + off[0]
					var gz: int = iz + off[1]
					var norm_loss: float = (loss_grid[gx][gz] - min_loss) / loss_range
					var height := norm_loss * terrain_height_scale

					var px := -half + (float(gx) / res) * terrain_size
					var pz := -half + (float(gz) / res) * terrain_size

					# Color: green at minima, red at peaks
					var base_color: Color = _loss_colors[loss_idx]
					var col := base_color.lerp(Color(0.15, 0.12, 0.1), norm_loss * 0.7)
					col = col.lerp(Color(1, 1, 1), (1.0 - norm_loss) * 0.3)

					st.set_color(col)
					st.set_normal(Vector3.UP)
					st.add_vertex(Vector3(px, height, pz))

	st.generate_normals()
	return st.commit()


# ------------------------------------------------------------------
# Gradient descent balls
# ------------------------------------------------------------------

func _create_balls() -> void:
	var mesh := SphereMesh.new()
	mesh.radius = ball_radius
	mesh.height = ball_radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6

	for t in range(3):
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1, 1, 1)
		mat.emission_enabled = _emissive
		mat.emission = _loss_colors[t]
		mat.emission_energy_multiplier = 1.5
		if not _emissive:
			mat.albedo_color = _loss_colors[t].lerp(Color(1, 1, 1), 0.35)
		mi.material_override = mat
		add_child(mi)
		_created.append(mi)
		_balls.append(mi)

		# Fixed start in param space — same descent every build.
		_ball_positions.append(Vector2(1.5, 1.0))

		# Trail mesh placeholder
		var trail_mi := MeshInstance3D.new()
		add_child(trail_mi)
		_created.append(trail_mi)
		_trail_meshes.append(trail_mi)

	_update_ball_visuals()


func _update_ball_visuals() -> void:
	var half := terrain_size * 0.5
	var param_min := -2.0
	var param_range := 4.0

	for t in range(3):
		var bp: Vector2 = _ball_positions[t]
		var norm_x := (bp.x - param_min) / param_range
		var norm_z := (bp.y - param_min) / param_range
		var px := -half + norm_x * terrain_size
		var pz := -half + norm_z * terrain_size
		var loss := _eval_loss(t, bp.x, bp.y)
		var min_l := _eval_loss(t, 0.5, 0.0)  # rough estimate
		var max_l := _eval_loss(t, 2.0, 2.0)
		var norm_loss := clampf((loss - min_l) / maxf(max_l - min_l, 0.001), 0.0, 1.0)
		var height := norm_loss * terrain_height_scale + ball_radius

		_balls[t].position = Vector3(
			(t - 1) * spacing + px,
			height,
			pz
		)


# ------------------------------------------------------------------
# Gradient descent step (numerical gradient)
# ------------------------------------------------------------------

func _gradient_step(loss_idx: int) -> void:
	var bp: Vector2 = _ball_positions[loss_idx]
	var eps := 0.01
	var loss_center := _eval_loss(loss_idx, bp.x, bp.y)
	var dw := (_eval_loss(loss_idx, bp.x + eps, bp.y) - loss_center) / eps
	var db := (_eval_loss(loss_idx, bp.x, bp.y + eps) - loss_center) / eps

	bp.x -= learning_rate * dw
	bp.y -= learning_rate * db

	# Clamp to param space
	bp.x = clampf(bp.x, -2.0, 2.0)
	bp.y = clampf(bp.y, -2.0, 2.0)

	_ball_positions[loss_idx] = bp
	_trail_points[loss_idx].append(bp)


# ------------------------------------------------------------------
# Labels
# ------------------------------------------------------------------

# Per-loss legend boards: name + equation as one spaced 2-line tag above each
# terrain. Kept SEPARATE per function (they are the colour-coded legend) but the
# name and its equation now share one integrated board so they never overlap.
func _create_labels() -> void:
	for t in range(3):
		var board := Node3D.new()
		board.name = "LegendBoard_%d" % t
		board.position = Vector3((t - 1) * spacing, terrain_height_scale + 0.10, 0)

		# Name — bright colour-coded line.
		var name_mesh: MeshInstance3D = BakedText.make_label_mesh(
			_loss_names[t], _loss_colors[t], Vector2(0.34, 0.05), 1400, true)
		if name_mesh:
			name_mesh.position = Vector3(0, 0.032, 0)
			_billboard_mesh(name_mesh)
			board.add_child(name_mesh)

		# Equation — smaller, desaturated line, clearly gapped below the name.
		var eq_mesh: MeshInstance3D = BakedText.make_label_mesh(
			_loss_equations[t], _loss_colors[t].lerp(Color.WHITE, 0.45),
			Vector2(0.40, 0.032), 1400, true)
		if eq_mesh:
			eq_mesh.position = Vector3(0, -0.020, 0)
			_billboard_mesh(eq_mesh)
			board.add_child(eq_mesh)

		add_child(board)
		_created.append(board)
		_legend_boards.append(board)


# Title + subtitle consolidated onto ONE opaque panel plate above the centre.
func _create_title() -> void:
	_title_board = Node3D.new()
	_title_board.name = "TitleBoard"
	_title_board.position = Vector3(0, 0.40, 0)

	# Opaque backing plate so the two lines read as one board.
	var plate: MeshInstance3D = BakedText.make_panel_mesh(
		"", Color(0.06, 0.07, 0.09, 1.0), Color.WHITE, Vector2(0.62, 0.14))
	if plate:
		plate.position = Vector3(0, 0, -0.004)
		_billboard_mesh(plate)
		_title_board.add_child(plate)

	# Two text lines stacked on the plate face.
	var block: Node3D = BakedText.make_text_block(
		["Loss Function Comparator",
		"Same data. Three loss functions. Three different answers."],
		Color(0.95, 0.93, 0.90), 0.036, 0.58, 0.016, true)
	if block:
		block.position = Vector3(0, 0, 0.004)
		_billboard_node(block)
		_title_board.add_child(block)

	add_child(_title_board)
	_created.append(_title_board)


# Billboard a single baked-text quad toward the viewer.
func _billboard_mesh(mesh: MeshInstance3D) -> void:
	var m = mesh.material_override
	if m is StandardMaterial3D:
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED


# Billboard every baked-text quad inside a board node.
func _billboard_node(node: Node3D) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			_billboard_mesh(child)


# ------------------------------------------------------------------
# Controls
# ------------------------------------------------------------------

func _create_controls() -> void:
	var slider_scene = load("res://commons/interactables/slider_horizontal.tscn")
	if slider_scene == null:
		return

	_controls = Node3D.new()
	_controls.name = "ArtifactControls"
	add_child(_controls)
	_created.append(_controls)

	# Outlier fraction slider
	var slider: Node = slider_scene.instantiate()
	slider.position = Vector3(0, 0.02, terrain_size * 0.5 + 0.15)
	slider.rotation_degrees.y = 180
	_controls.add_child(slider)

	var label_node = slider.get_node_or_null("Frame/LabelName")
	if label_node:
		label_node.text = "Outliers"
	slider.set_param_name("Outliers")
	# The knob must not lie about a composed tail: it reads the tail's effective
	# stray fraction, clamped into the slider's 0-0.5 range.
	slider.set_normalized_value(clampf(_tail_fraction() / 0.5, 0.0, 1.0))
	slider.slider_moved.connect(_on_outlier_changed)

	# Reset button
	var btn_scene = load("res://commons/interactables/push_button.tscn")
	if btn_scene:
		var btn: Node = btn_scene.instantiate()
		btn.position = Vector3(0.2, 0.02, terrain_size * 0.5 + 0.15)
		_controls.add_child(btn)
		var area = btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(_on_reset_pressed)


## The stray fraction each tail actually contains, so the slider reflects it.
func _tail_fraction() -> float:
	match tail:
		"none":
			return 0.0
		"heavy":
			return float(HEAVY_COUNT) / 20.0
		"sole":
			return 1.0 / 20.0
		"split":
			return float(SPLIT_COUNT) / 20.0
	return outlier_fraction


# Taking the knob hands the tail back to the coin flip: the value becomes `few`
# with the fraction the hand chose, rather than a composed tail silently
# disagreeing with the slider under it.
func _on_outlier_changed(value: float) -> void:
	outlier_fraction = value * 0.5
	tail = "few"
	_regenerate()


func _on_reset_pressed() -> void:
	_regenerate()


func _regenerate() -> void:
	_generate_dataset()
	# Rebuild terrain meshes
	for t in range(3):
		_terrains[t].mesh = _build_terrain_mesh(t)
	# Reset balls
	for t in range(3):
		_ball_positions[t] = Vector2(1.5, 1.0)
		_trail_points[t].clear()
	_update_ball_visuals()


# ------------------------------------------------------------------
# Process
# ------------------------------------------------------------------

func _process(delta: float) -> void:
	if not _running:
		return

	_step_timer += delta
	if _step_timer >= _step_interval:
		_step_timer = 0.0
		for t in range(3):
			_gradient_step(t)
		_update_ball_visuals()
