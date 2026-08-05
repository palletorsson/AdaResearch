# Riemann Pump — left, right, midpoint sums as accumulation strategies
#
# Three side-by-side strip displays of the same curve f(x) = (1 - cos(x))/2 over [0, π].
# All three accumulate vertical rectangles toward the total area, but each picks the
# rectangle's height differently:
#   - Left panel:   height = f(left edge of strip)
#   - Right panel:  height = f(right edge of strip)
#   - Mid panel:    height = f(midpoint of strip)
#
# Pumping the bar count up and down shows how all three converge to the same area as
# the partition becomes finer — but the *biases* differ at coarse resolution. This is
# the difference between a sum and an integral made visible.
#
# @qfep_term: F at the cusp of Δ — accumulation as the inverse operation of slope.
#
# @identity
# essence: three side-by-side strip panels summing the same curve's area by left, right, and midpoint rectangles, pumping the strip count up and down to show them converge
# desire: to show that accumulation is a choice of strategy at coarse resolution but one shared area in the limit
# critical_parameter: n_strips — the partition fineness; at low counts the three panels' biases diverge visibly, at high counts they collapse onto the true integral
# triggers: _ready() builds three panels (axes + curve + strips); _process pumps n_strips on a slow sinusoid and rebuilds each strategy's rectangle heights
# emerges: the difference between a sum and an integral, made spatial — three biases converging to one number
# needs: three strip panels [present]; curve mesh per panel [present]; pump animation [present]; class_name RiemannPump [present]; @identity [present, 2026-07-12]
# relationships: the accumulation counterpart to partial_derivative_terrain's slope; resolved by ftc_bridge (which names sum and slope as inverses); sibling in the change sequence
# truth: area under a curve has no single recipe — left, right, and midpoint all reach it, and their disagreement at coarse scale is the integral announcing itself.

extends Node3D
class_name RiemannPump

# --- STAGE-2 DNA (promoted 2026-08-05) ---------------------------------------
#
# TWO THINGS WERE WELDED SHUT HERE, and they are the two halves of the artifact's
# own truth statement.
#
# `comparison` is WHAT STANDS BESIDE WHAT. Before this pass the bench asserted
# exactly one thing and could assert nothing else: three rules, three panels, in
# a row, always. It could not show the left/right pair as the BRACKET they are
# (f is increasing on [0, PI], so the left sum is always under the true area and
# the right sum always over it, and the answer is trapped between two pictures);
# it could not show the three sums OVERLAID, where the disagreement stops being a
# comparison across the room and becomes a difference of heights at one x; and it
# could not show the midpoint rule ALONE, the reading you would actually use,
# with nothing to argue with.
#
# `resolution` is HOW FINE THE PARTITION IS — and, unavoidably, whether it holds
# still. _process drives n_strips on a sinusoid between 4 and 32 every frame, so
# the export was unreachable in practice: a sweep of n_strips measured 0.011% and
# 0.016% between values because the pump overwrote each one before the shutter.
# The partition IS this artifact's declared critical_parameter, so the only way
# to photograph it is to let a value stop the pump. `pump` does not.
#
# WHY THE SHOWN SET IS RE-CENTRED AND THE DEFAULT IS STILL EXACT: for three
# panels the centring formula (idx - (k-1)/2) * pitch IS the shipped
# (i - 1) * pitch, term for term, so `rules` rebuilds the original row. For a
# subset it keeps the panels in the middle of the frame, which is what makes the
# axis measurable: if a lone panel kept its old x the difference between `single`
# and `bracket` would be dominated by a whole-panel translation and the sums'
# disagreement — the thing being argued — would be the smaller signal.

const COMPARISONS: Array[String] = ["rules", "overlay", "bracket", "single"]
const RESOLUTIONS: Array[String] = ["pump", "coarse", "mid", "fine"]
## The pinned rungs. `mid` is 12, which is the shipped n_strips export default —
## the count the artifact is BUILT at before _process's first frame moves it.
const RESOLUTION_STRIPS := {"coarse": 4, "mid": 12, "fine": 32}

# Rule indices in the shipped panel order: panel 0 sampled the strip's LEFT edge,
# panel 1 its RIGHT edge, panel 2 its MIDPOINT. _emit_strips still branches on the
# same literal 0/1/2 it always did; these names exist for _panel_groups to read.
const RULE_LEFT: int = 0
const RULE_RIGHT: int = 1
const RULE_MID: int = 2

@export_category("Riemann Settings")
@export var left_color: Color = Color(0.95, 0.55, 0.55, 0.7)
@export var right_color: Color = Color(0.55, 0.95, 0.55, 0.7)
@export var mid_color: Color = Color(0.55, 0.65, 0.95, 0.7)
@export var curve_color: Color = Color(0.85, 0.85, 0.95, 1.0)
@export var n_strips: int = 12
@export var panel_width: float = 1.4
@export var panel_height: float = 0.7
@export var panel_gap: float = 0.25
@export var pump_period: float = 6.0  # seconds for one slow cycle

@export_category("DNA")
## Which accumulation rules stand beside each other. rules = the shipped row.
@export_enum("rules", "overlay", "bracket", "single") var comparison: String = "rules"
## How fine the partition is. pump = the shipped sinusoid, still moving.
@export_enum("pump", "coarse", "mid", "fine") var resolution: String = "pump"

var _t: float = 0.0
var _strip_parents := []  # one Node3D per panel, in left-to-right order
var _curve_parents := []  # the curve strips for each panel
var _panel_rules := []    # the rule indices each panel carries
var _built: bool = false


func _ready() -> void:
	# Only a pinned resolution touches n_strips; `pump` leaves the shipped 12 in
	# place and lets _process take it over on the first frame, as before.
	if resolution != "pump":
		n_strips = int(RESOLUTION_STRIPS.get(resolution, n_strips))
	_build_panels()
	_built = true


## Which rules share a panel, one entry per panel, left to right. The fall-through
## is `rules` and returns the shipped three-panel row in the shipped order.
func _panel_groups() -> Array:
	match comparison:
		"overlay":
			return [[RULE_LEFT, RULE_RIGHT, RULE_MID]]
		"bracket":
			return [[RULE_LEFT], [RULE_RIGHT]]
		"single":
			return [[RULE_MID]]
	return [[RULE_LEFT], [RULE_RIGHT], [RULE_MID]]


func _build_panels() -> void:
	for i in _strip_parents.size():
		var old: Node3D = _strip_parents[i]
		if is_instance_valid(old):
			# remove_child before queue_free: a queued node is still a child for
			# the rest of the frame, and two overlapping rows would be captured.
			remove_child(old)
			old.queue_free()
	_strip_parents.clear()
	_curve_parents.clear()
	_panel_rules.clear()
	var groups: Array = _panel_groups()
	var k: int = groups.size()
	for idx in k:
		var parent := Node3D.new()
		# For k == 3 this is exactly the shipped (float(i) - 1.0) * pitch.
		var x_off: float = (float(idx) - (float(k) - 1.0) * 0.5) * (panel_width + panel_gap)
		parent.position = Vector3(x_off, 0.0, 0.0)
		add_child(parent)
		_strip_parents.append(parent)
		_panel_rules.append(groups[idx])
		_build_axes_for(parent)
		var curve := _build_curve_for(parent)
		_curve_parents.append(curve)
	_rebuild_strips(n_strips)


func apply_grid_config(config_data: Dictionary) -> void:
	var rebuild: bool = false
	if config_data.has("comparison"):
		var c: String = _pick_axis(str(config_data["comparison"]), COMPARISONS, comparison)
		if c != comparison:
			comparison = c
			rebuild = true
	if config_data.has("resolution"):
		var r: String = _pick_axis(str(config_data["resolution"]), RESOLUTIONS, resolution)
		if r != resolution:
			resolution = r
			if r != "pump":
				n_strips = int(RESOLUTION_STRIPS.get(r, n_strips))
			rebuild = true
	# Only on a real change, and only once _ready has built the row once.
	if rebuild and _built:
		_build_panels()
	# The shipped key, behaving as it always did: redraw at that count, and under
	# `pump` be overwritten again by _process on the very next frame.
	if config_data.has("n_strips"):
		n_strips = int(config_data["n_strips"])
		_rebuild_strips(n_strips)


func _pick_axis(raw: String, allowed: Array[String], fallback: String) -> String:
	var v: String = raw.strip_edges().to_lower()
	return v if allowed.has(v) else fallback


func _process(delta: float) -> void:
	# `pump` is the shipped behaviour. Every other value of `resolution` freezes
	# the partition where _ready built it, which is the whole point: a count that
	# changes every frame cannot be photographed.
	if resolution != "pump":
		return
	_t += delta
	# Animate n_strips between 4 and 32 with a slow sine.
	var phase: float = (sin(_t * TAU / pump_period) + 1.0) * 0.5
	var target: int = int(round(lerp(4.0, 32.0, phase)))
	if target != n_strips:
		n_strips = target
		_rebuild_strips(n_strips)


func _f(x: float) -> float:
	# x in [0, PI]; output in [0, panel_height].
	return (1.0 - cos(x)) * 0.5 * panel_height


func _build_axes_for(parent: Node3D) -> void:
	var bar := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(panel_width, 0.015, 0.015)
	bar.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.35, 0.4, 1.0)
	bar.material_override = mat
	parent.add_child(bar)


func _build_curve_for(parent: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var imm := ImmediateMesh.new()
	imm.clear_surfaces()
	imm.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	var n := 64
	for i in n + 1:
		var t_norm := float(i) / float(n)
		var x_panel: float = lerp(-panel_width * 0.5, panel_width * 0.5, t_norm)
		var x_fn: float = lerp(0.0, PI, t_norm)
		imm.surface_add_vertex(Vector3(x_panel, _f(x_fn), 0.0))
	imm.surface_end()
	mi.mesh = imm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = curve_color
	mat.emission_enabled = true
	mat.emission = curve_color
	mat.emission_energy_multiplier = 1.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mat
	parent.add_child(mi)
	return mi


func _rebuild_strips(n: int) -> void:
	# Remove old strips (anything named "_strip_..." in each parent).
	# Was `for i in 3`, which indexed _strip_parents out of bounds if anything
	# called this before _ready. Panel count is now read from the array.
	for i in _strip_parents.size():
		var parent: Node3D = _strip_parents[i]
		for child in parent.get_children():
			if child.name.begins_with("_strip_"):
				child.queue_free()
		_emit_strips(parent, _panel_rules[i], n)


func _emit_strips(parent: Node3D, rules: Array, n: int) -> void:
	var strip_width: float = panel_width / float(n)
	var seq: int = 0
	for r in rules.size():
		var panel_idx: int = rules[r]
		# One rule per panel is the shipped case and keeps the shipped z exactly.
		# An OVERLAID panel spreads its three rules in depth instead, shortest sum
		# nearest the viewer, so the taller ones still read behind it rather than
		# being hidden by the sum that under-estimates them.
		var z: float = -0.01 if rules.size() == 1 else -0.004 - 0.006 * float(r)
		for k in n:
			var t0: float = float(k) / float(n)
			var t1: float = float(k + 1) / float(n)
			var sample_t: float = t0
			match panel_idx:
				0: sample_t = t0  # left
				1: sample_t = t1  # right
				2: sample_t = (t0 + t1) * 0.5  # midpoint
			var x_fn: float = sample_t * PI
			var height: float = _f(x_fn)
			var strip := MeshInstance3D.new()
			# seq == k whenever the panel holds one rule, so single-rule panels
			# carry the same node names they always did.
			strip.name = "_strip_" + str(seq)
			seq += 1
			var box := BoxMesh.new()
			box.size = Vector3(strip_width * 0.95, max(height, 0.001), 0.02)
			strip.mesh = box
			var mat := StandardMaterial3D.new()
			var col: Color = [left_color, right_color, mid_color][panel_idx]
			mat.albedo_color = col
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.emission_enabled = true
			mat.emission = col
			mat.emission_energy_multiplier = 0.5
			strip.material_override = mat
			var x_panel: float = lerp(-panel_width * 0.5, panel_width * 0.5, (t0 + t1) * 0.5)
			strip.position = Vector3(x_panel, height * 0.5, z)
			parent.add_child(strip)
