# distribution_sampler.gd
# Interactive probability distribution visualizer
# Shows Gaussian, Uniform, Poisson, Exponential distributions
#
# QFEP: Distributions as "shape of randomness" — entropy has structure
#
# @identity
# essence: f(x|θ) — probability density function parameterized by distribution type
# desire: switch between Uniform, Gaussian, Poisson, Exponential and watch falling particles build different shapes
# critical_parameter: law — which PDF governs the draw, each with fundamentally different tail behavior (uniform | gaussian | poisson | exponential); evidence — how many draws the histogram is standing on when you find it (none | anecdote | sample | census)
# triggers: _sample_distribution() dispatches to Box-Muller (Gaussian), inverse CDF (Exponential), Knuth (Poisson)
# emerges: the theoretical PDF curve overlays the histogram and they converge — shape is not noise, noise has shape
# needs: VR push buttons for distribution switching [has]; falling-particle animation [has]; slider for params [missing]
# relationships: depends on galton_board (Gaussian intuition); contrasts with slot_machine (discrete uniform vs continuous families)
# truth: Every distribution is a constraint on randomness — the shape of what remains possible.
#
## Implements an interactive probability distribution sampler.
## Draws samples from Uniform, Gaussian (Box-Muller transform), Poisson
## (inverse transform), or Exponential (inverse CDF) distributions and
## displays them as a falling-particle histogram with theoretical PDF overlay.
## Key parameters: distribution selects the active type, samples_per_second
## controls animation speed, num_bins sets histogram resolution.

extends Node3D

class_name DistributionSampler

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# --- Constants ---
const AXIS_RADIUS := 0.002
const BAR_DEPTH := 0.02
const BAR_HEIGHT_MIN := 0.01
const BAR_FILL_RATIO := 0.9
const CURVE_SEGMENTS := 100
const FALL_SPEED := 0.5
const MARKER_RADIUS := 0.008
const SAMPLE_SPAWN_OFFSET := 0.05
const TIMER_WRAP := 1000.0


## Width of the histogram display area in meters
@export_range(0.1, 2.0, 0.05) var display_width: float = 0.6
## Height of the histogram display area in meters
@export_range(0.1, 2.0, 0.05) var display_height: float = 0.4
## Number of histogram bins
@export_range(2, 200) var num_bins: int = 30
## Maximum number of samples before auto-sampling stops
@export_range(10, 10000) var max_samples: int = 1000

## Distribution type
enum DistType { UNIFORM, GAUSSIAN, POISSON, EXPONENTIAL }
## Which probability distribution to sample from
@export var distribution: DistType = DistType.GAUSSIAN:
	set(value):
		distribution = value
		_clear_samples()

## Mean of the Gaussian distribution (normalized 0–1 range)
@export_range(0.0, 1.0, 0.01) var gaussian_mean: float = 0.5
## Standard deviation of the Gaussian distribution
@export_range(0.01, 0.5, 0.01) var gaussian_std: float = 0.15

## Lambda parameter for the Poisson distribution
@export_range(0.1, 20.0, 0.1) var poisson_lambda: float = 5.0

## Rate parameter for the Exponential distribution
@export_range(0.1, 20.0, 0.1) var exponential_rate: float = 3.0

## Number of random samples generated per second
@export_range(1.0, 200.0, 1.0) var samples_per_second: float = 50.0:
	set(value):
		samples_per_second = clampf(value, 1.0, 200.0)

## Whether to continuously generate samples automatically
@export var auto_sample: bool = true

## Seed for the sampler. -1 (the default) draws from the global stream exactly as
## before — same calls, same order, byte-identical histogram behaviour.
##
## NOT AN AXIS, AND DELIBERATELY SO. This instrument builds its whole picture out of
## unseeded draws while it runs, which means two captures of it are two different
## histograms even with every knob identical: any axis declared here would be measured
## against sampling noise and would report whatever the dice said. Set this
## non-negative and CLEAR (or a config change) replays the same sample sequence, so a
## future axis on this artifact can be measured rather than guessed at.
##
## THAT FUTURE ARRIVED 2026-08-03 and took the other road: `evidence` below lays its
## draws down from its OWN seeded generator (`evidence_seed`), which leaves this knob
## and the live stream exactly as they were. sample_seed is still not an axis.
@export var sample_seed: int = -1
var _rng: RandomNumberGenerator = null

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA — promoted by hand 2026-08-03
#
# The note above is why this artifact was passed over twice. It is right that an
# unseeded stream cannot be measured, and it is right that the histogram builds
# over TIME — at 50 samples/second, a still taken 0.35 s after _ready catches a
# machine with an empty chart and a handful of markers still in the air. So the
# first knob this needed was not an axis at all.
#
#   law         WHICH RULE GOVERNS THE DRAW
#               uniform · gaussian · poisson · exponential
#   evidence    HOW MANY DRAWS THE HISTOGRAM STANDS ON WHEN YOU FIND IT
#               none · anecdote · sample · census
#
# `law` is the @identity critical_parameter — "f(x|θ), each with fundamentally
# different tail behaviour" — made reachable from a map token. The word is
# shared with force_field_visualizer, which asks the same question of a field
# (which law shapes what you are looking at); in probability the LAW of a random
# variable is literally its distribution, so the word is not a metaphor here.
# The four values are the four the code has always dispatched on.
#
# `evidence` is what makes `law` photographable, and it is the same ladder, word
# for word, as galton_board and shannon_workbench: how much looking the picture
# is standing on. As with those two, the rungs are qualitative and the counts
# are this machine's own.
#   none       0. The legacy lineage: bins empty, only the theory curve drawn.
#              Every one of the 10 placements is here.
#   anecdote   1. One bin at full height. A distribution "shown" by one draw.
#   sample     25. Scattered single-count bars across 30 bins — the shape is
#              not yet legible and the bars claim it is.
#   census     1000. max_samples. The histogram closes on the curve drawn over
#              it, which is the whole argument of the artifact.
#
# The pre-seeded draws run through the SAME _sample_distribution() the live
# machine uses, in the same order — they are earlier draws, not different ones.
# They come from a private generator seeded by `evidence_seed`, so at
# evidence=none no RNG is constructed and the global stream is never touched:
# frame one of an unconfigured placement is byte-identical to yesterday's.
#
# Deliberately NOT promoted: samples_per_second (a rate is invisible to a still
# — the exact fault this artifact was already declining), auto_sample (same),
# and gaussian_mean / gaussian_std / poisson_lambda / exponential_rate, which
# are the operating knobs of ONE law rather than a choice between laws.
# ─────────────────────────────────────────────────────────────────────────────

## AXIS 1 — which law governs the draw. "gaussian" is the shipped default, and
## at that value nothing is assigned: the export default below already IS
## DistType.GAUSSIAN, so a scene or map that set `distribution` directly keeps
## whatever it set.
@export_enum("uniform", "gaussian", "poisson", "exponential") var law: String = "gaussian"
## AXIS 2 — how many draws the histogram stands on when you find it. Shared
## vocabulary with galton_board and shannon_workbench. none = the legacy state:
## an empty chart waiting for the sampler to fill it.
@export_enum("none", "anecdote", "sample", "census") var evidence: String = "none"
## Seed for the pre-seeded draws only, so a variant photographs the same
## histogram twice. Off the default path entirely: at evidence=none nothing
## reads it and no generator is built.
@export var evidence_seed: int = 20260803

## The axis words, mapped onto the enum the rest of the file already uses.
const LAW_TYPES := {
	"uniform": DistType.UNIFORM,
	"gaussian": DistType.GAUSSIAN,     # the legacy lineage
	"poisson": DistType.POISSON,
	"exponential": DistType.EXPONENTIAL,
}
## The evidence ladder, as draws already made.
const EVIDENCE_DRAWS := {
	"none": 0,          # the legacy lineage — 10 placements, all of them
	"anecdote": 1,
	"sample": 25,
	"census": 1000,     # = max_samples
}
## Set for the duration of _seed_evidence() and null everywhere else, so the
## pre-seeded draws are deterministic without the live machine's stream — or the
## global stream — changing at all.
var _evidence_rng: RandomNumberGenerator = null

## Color of the histogram bars
@export var color_bar: Color = Color(0.3, 0.7, 1.0)
## Color of the theoretical PDF curve overlay
@export var color_theory: Color = Color(1.0, 0.5, 0.3, 0.6)
## Color of the falling sample markers
@export var color_sample: Color = Color(1.0, 0.9, 0.3)

# State
var _bins: Array[int] = []
var _total_samples: int = 0
var _sample_timer: float = 0.0
var _falling_samples: Array[Dictionary] = []

# Bars — rendered as MultiMesh
var _bar_mm: MultiMesh
var _bar_mmi: MultiMeshInstance3D
var _bar_x_positions: PackedFloat32Array

# Theory curve — reused ImmediateMesh
var _theory_curve: MeshInstance3D
var _im: ImmediateMesh
var _theory_mat: StandardMaterial3D

# Sample markers — shared mesh and material
var _sample_markers: Node3D
var _sample_sphere: SphereMesh
var _sample_mat: StandardMaterial3D

# Labels and controls
var _info_label: Label3D
var _stats_label: Label3D
var _control_panel: Node3D

# Shared materials
var _panel_mat: StandardMaterial3D
var _axis_mat: StandardMaterial3D

# Signal tracking for cleanup
var _signal_connections: Array = []

func _ready() -> void:
	_read_meta_overrides()
	# "gaussian" is the export default of `distribution`, so this is a genuine
	# no-op at the default value — nothing is assigned and anything the .tscn or
	# a map already set survives untouched.
	if law != "gaussian":
		distribution = int(LAW_TYPES.get(law, DistType.GAUSSIAN)) as DistType
	_init_shared_resources()
	_create_display()
	_create_bars()
	_create_theory_curve()
	_create_sample_markers()
	_create_labels()
	_create_vr_controls()
	_clear_samples()
	_seed_evidence()

## Initialize reusable mesh and material resources.
func _init_shared_resources() -> void:
	_panel_mat = StandardMaterial3D.new()
	_panel_mat.albedo_color = Color(0.05, 0.05, 0.08)

	_axis_mat = StandardMaterial3D.new()
	_axis_mat.albedo_color = Color(0.4, 0.4, 0.5)

	_sample_sphere = SphereMesh.new()
	_sample_sphere.radius = MARKER_RADIUS
	_sample_sphere.height = MARKER_RADIUS * 2.0

	_sample_mat = StandardMaterial3D.new()
	_sample_mat.albedo_color = color_sample
	_sample_mat.emission_enabled = true
	_sample_mat.emission = color_sample
	_sample_mat.emission_energy_multiplier = 0.5

	_theory_mat = StandardMaterial3D.new()
	_theory_mat.albedo_color = color_theory
	_theory_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	_im = ImmediateMesh.new()

## Build the back panel and axis lines.
func _create_display() -> void:
	var back := MeshInstance3D.new()
	back.name = "BackPanel"
	var box := BoxMesh.new()
	box.size = Vector3(display_width + 0.04, display_height + 0.04, 0.01)
	back.mesh = box
	back.material_override = _panel_mat
	back.position = Vector3(0, display_height / 2, -0.01)
	add_child(back)

	_create_axis_line(Vector3(-display_width / 2, 0, 0), Vector3(display_width / 2, 0, 0))
	_create_axis_line(Vector3(-display_width / 2, 0, 0), Vector3(-display_width / 2, display_height, 0))

## Create a cylinder-based axis line between two 3D points.
func _create_axis_line(start: Vector3, end: Vector3) -> void:
	var line := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = AXIS_RADIUS
	cylinder.bottom_radius = AXIS_RADIUS
	cylinder.height = (end - start).length()
	line.mesh = cylinder
	line.material_override = _axis_mat

	line.position = (start + end) / 2
	var direction := end - start

	add_child(line)

	if direction.length() > 0.001:
		var up := Vector3.UP
		if abs(direction.normalized().dot(up)) > 0.99:
			up = Vector3.FORWARD
		line.look_at(line.global_position + direction, up)
		line.rotate_object_local(Vector3.RIGHT, PI / 2)

## Create histogram bars as a MultiMesh for efficient GPU instancing.
func _create_bars() -> void:
	var bar_width := display_width / float(num_bins)

	var box := BoxMesh.new()
	box.size = Vector3(bar_width * BAR_FILL_RATIO, BAR_HEIGHT_MIN, BAR_DEPTH)

	_bar_mm = MultiMesh.new()
	_bar_mm.transform_format = MultiMesh.TRANSFORM_3D
	_bar_mm.mesh = box
	_bar_mm.instance_count = num_bins

	_bar_x_positions = PackedFloat32Array()
	_bar_x_positions.resize(num_bins)

	for i in range(num_bins):
		var x := -display_width / 2 + (i + 0.5) * bar_width
		_bar_x_positions[i] = x
		var xf := Transform3D()
		xf.origin = Vector3(x, 0, 0)
		_bar_mm.set_instance_transform(i, xf)

	_bar_mmi = MultiMeshInstance3D.new()
	_bar_mmi.name = "Bars"
	_bar_mmi.multimesh = _bar_mm

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color_bar
	mat.emission_enabled = true
	mat.emission = color_bar
	mat.emission_energy_multiplier = 0.2
	_bar_mmi.material_override = mat

	add_child(_bar_mmi)

## Create the theory curve mesh node with a reusable ImmediateMesh.
func _create_theory_curve() -> void:
	_theory_curve = MeshInstance3D.new()
	_theory_curve.name = "TheoryCurve"
	_theory_curve.mesh = _im
	_theory_curve.material_override = _theory_mat
	add_child(_theory_curve)

## Create the container node for falling sample markers.
func _create_sample_markers() -> void:
	_sample_markers = Node3D.new()
	_sample_markers.name = "SampleMarkers"
	add_child(_sample_markers)

## Create title and statistics labels.
func _create_labels() -> void:
	# Title — a framed 2D-in-3D sign on a STALK above the screen (mounted to the body, not floating).
	var title := HangarKit.signage("DISTRIBUTION SAMPLER", [], Vector2(display_width * 0.64, 0.11), 0.13, Vector3(0, 1, 0))
	title.position = Vector3(0, display_height, 0)
	add_child(title)

	# Stats — an empty framed plate on a side BRACKET; the live value text sits on its face
	# (2D-on-surface, fixed orientation), updated every frame by _update_stats().
	var arm := 0.12
	var sx := display_width / 2 + 0.05
	var sy := display_height / 2
	var stats_plate := HangarKit.signage("", [], Vector2(0.34, 0.3), arm, Vector3(1, 0, 0))
	stats_plate.position = Vector3(sx, sy, 0)
	add_child(stats_plate)
	_stats_label = Label3D.new()
	_stats_label.name = "StatsLabel"
	_stats_label.pixel_size = 0.0011
	_stats_label.font_size = 12
	_stats_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_stats_label.modulate = Color(0.09, 0.09, 0.11)
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.position = Vector3(sx + arm, sy + 0.02, 0.05)
	add_child(_stats_label)

## Create VR-interactive buttons for switching distributions and clearing data.
func _create_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_panel("DISTRIBUTIONS", [
		[{"type": "button", "label": "UNIFORM"}, {"type": "button", "label": "GAUSS"}, {"type": "button", "label": "POISSON"}, {"type": "button", "label": "EXPON"}],
		[{"type": "button", "label": "CLEAR"}],
	])
	_control_panel.position = Vector3(0, -0.08, 0.15)
	_control_panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(_control_panel)

	for i in range(4):
		var btn: Node = _control_panel.find_child("Btn_%d" % i, true, false)
		if btn:
			var area = btn.get_node_or_null("InteractableAreaButton")
			if area:
				var type_idx := i
				var cb := func(_b): distribution = type_idx as DistType
				area.button_pressed.connect(cb)
				_signal_connections.append([area, &"button_pressed", cb])

	var clear_btn: Node = _control_panel.find_child("Btn_4", true, false)
	if clear_btn:
		var area = clear_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _clear_samples())
			_signal_connections.append([area, &"button_pressed", _clear_samples])

## Reset all bins, samples, and visuals to initial state.
func _clear_samples(_button = null) -> void:
	# Re-seeded here so CLEAR replays the same sample sequence. At sample_seed = -1
	# this is skipped entirely and the global stream is untouched — the legacy path.
	if sample_seed >= 0:
		if _rng == null:
			_rng = RandomNumberGenerator.new()
		_rng.seed = sample_seed
	_bins.clear()
	_bins.resize(num_bins)
	for i in range(num_bins):
		_bins[i] = 0
	_total_samples = 0
	_sample_timer = 0.0
	_falling_samples.clear()
	if _bar_mm:
		_update_bars()
	if _im:
		_update_theory_curve()

func _process(delta: float) -> void:
	if auto_sample and _total_samples < max_samples:
		_sample_timer = wrapf(_sample_timer + delta, 0.0, TIMER_WRAP)
		var interval := 1.0 / samples_per_second
		while _sample_timer >= interval and _total_samples < max_samples:
			_sample_timer -= interval
			_add_sample()

	_update_falling_samples(delta)
	_update_stats()

## Draw a single sample from the current distribution and spawn a falling marker.
func _add_sample() -> void:
	var value := _sample_distribution()

	var x := -display_width / 2 + value * display_width
	_falling_samples.append({
		"x": x,
		"y": display_height + SAMPLE_SPAWN_OFFSET,
		"value": value,
		"landed": false
	})

	var marker := MeshInstance3D.new()
	marker.mesh = _sample_sphere
	marker.material_override = _sample_mat
	marker.position = Vector3(x, display_height + SAMPLE_SPAWN_OFFSET, 0.02)
	_sample_markers.add_child(marker)

## Sample a value in [0, 1] from the currently selected distribution.
func _sample_distribution() -> float:
	match distribution:
		DistType.UNIFORM:
			return _rand()

		DistType.GAUSSIAN:
			var u1 := _rand()
			var u2 := _rand()
			var z := sqrt(-2.0 * log(u1 + 0.0001)) * cos(TAU * u2)
			return clampf(gaussian_mean + z * gaussian_std, 0.0, 1.0)

		DistType.POISSON:
			var L := exp(-poisson_lambda)
			var k := 0
			var p := 1.0
			while p > L:
				k += 1
				p *= _rand()
			return clampf(float(k - 1) / maxf(poisson_lambda * 3, 0.0001), 0.0, 1.0)

		DistType.EXPONENTIAL:
			var u := _rand()
			var val := -log(u + 0.0001) / maxf(exponential_rate, 0.0001)
			return clampf(val / 2.0, 0.0, 1.0)

	return _rand()


## The only draw in this artifact. sample_seed = -1 falls straight through to randf(),
## same call, same order, same stream, so the legacy histogram is unchanged.
func _rand() -> float:
	# The pre-seeded history, when one is being laid down. Null at every other
	# moment, including the whole of the default path.
	if _evidence_rng != null:
		return _evidence_rng.randf()
	if sample_seed < 0:
		return randf()
	if _rng == null:
		_rng = RandomNumberGenerator.new()
		_rng.seed = sample_seed
	return _rng.randf()

## Animate falling markers downward and register them into histogram bins on landing.
func _update_falling_samples(delta: float) -> void:
	var to_remove: Array[int] = []

	for i in range(_falling_samples.size()):
		var sample = _falling_samples[i]
		if sample.landed:
			to_remove.append(i)
			continue

		sample.y -= delta * FALL_SPEED

		var bin_idx := int(sample.value * num_bins)
		bin_idx = clampi(bin_idx, 0, num_bins - 1)
		var bin_height := float(_bins[bin_idx]) / maxf(float(max_samples), 1.0) * display_height * 5

		if sample.y <= bin_height:
			sample.landed = true
			_bins[bin_idx] += 1
			_total_samples += 1
			_update_bars()

	var markers := _sample_markers.get_children()
	for i in range(mini(_falling_samples.size(), markers.size())):
		markers[i].position.y = _falling_samples[i].y

	for i in range(to_remove.size() - 1, -1, -1):
		var idx := to_remove[i]
		_falling_samples.remove_at(idx)
		if idx < _sample_markers.get_child_count():
			_sample_markers.get_child(idx).queue_free()

## Update histogram bar transforms via MultiMesh based on current bin counts.
func _update_bars() -> void:
	var max_count := 1
	for count in _bins:
		max_count = maxi(max_count, count)

	for i in range(num_bins):
		var height := float(_bins[i]) / float(max_count) * display_height * BAR_FILL_RATIO + BAR_HEIGHT_MIN
		var xf := Transform3D()
		xf.basis = Basis.IDENTITY.scaled(Vector3(1.0, height / BAR_HEIGHT_MIN, 1.0))
		xf.origin = Vector3(_bar_x_positions[i], height / 2.0, 0.0)
		_bar_mm.set_instance_transform(i, xf)

## Rebuild the theoretical PDF curve on the reusable ImmediateMesh.
func _update_theory_curve() -> void:
	_im.clear_surfaces()
	_im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	for i in range(CURVE_SEGMENTS + 1):
		var x_norm := float(i) / float(CURVE_SEGMENTS)
		var y := _theoretical_pdf(x_norm)
		var x := -display_width / 2 + x_norm * display_width
		_im.surface_add_vertex(Vector3(x, y * display_height * 0.8, 0.01))

	_im.surface_end()

## Return the theoretical PDF value for the current distribution at normalized x.
func _theoretical_pdf(x: float) -> float:
	match distribution:
		DistType.UNIFORM:
			return 1.0

		DistType.GAUSSIAN:
			var z := (x - gaussian_mean) / maxf(gaussian_std, 0.0001)
			return exp(-0.5 * z * z) / (maxf(gaussian_std, 0.0001) * sqrt(TAU))

		DistType.POISSON:
			var k := int(x * poisson_lambda * 3)
			var factorial := 1.0
			for i in range(1, k + 1):
				factorial *= i
			return pow(poisson_lambda, k) * exp(-poisson_lambda) / maxf(factorial, 0.0001) * 3

		DistType.EXPONENTIAL:
			var t := x * 2
			return exponential_rate * exp(-exponential_rate * t) * 2

	return 0.0

## Update statistics label with sample mean, standard deviation, and count.
func _update_stats() -> void:
	if _total_samples == 0:
		_stats_label.text = "n = 0"
		return

	var sum := 0.0
	var sum_sq := 0.0
	var bar_width := 1.0 / float(num_bins)

	for i in range(num_bins):
		var x := (i + 0.5) * bar_width
		sum += x * _bins[i]
		sum_sq += x * x * _bins[i]

	var mean := sum / _total_samples
	var variance := sum_sq / _total_samples - mean * mean
	var std := sqrt(maxf(variance, 0))

	var dist_names = ["Uniform", "Gaussian", "Poisson", "Exponential"]
	_stats_label.text = "%s\nn = %d\nμ = %.3f\nσ = %.3f" % [dist_names[distribution], _total_samples, mean, std]

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: distribution = DistType.UNIFORM
			KEY_2: distribution = DistType.GAUSSIAN
			KEY_3: distribution = DistType.POISSON
			KEY_4: distribution = DistType.EXPONENTIAL
			KEY_SPACE: auto_sample = not auto_sample
			KEY_C: _clear_samples()
			KEY_S: _add_sample()

func _exit_tree() -> void:
	for conn in _signal_connections:
		if is_instance_valid(conn[0]) and conn[0].is_connected(conn[1], conn[2]):
			conn[0].disconnect(conn[1], conn[2])
	_signal_connections.clear()

## Set the active probability distribution.
func set_distribution(d: DistType) -> void:
	distribution = d

## Clear all samples and reset the histogram.
func clear() -> void:
	_clear_samples()

## Draw a single sample from the current distribution.
func sample() -> void:
	_add_sample()

# ═════════════════════════════════════════════════════════════════════
# DNA — law and evidence
# ═════════════════════════════════════════════════════════════════════

## Lay down the draws this machine is found standing on. Returns before building
## anything at evidence=none, which is the state every existing placement is in.
func _seed_evidence() -> void:
	var draws: int = mini(int(EVIDENCE_DRAWS.get(evidence, 0)), max_samples)
	if draws <= 0:
		return
	_evidence_rng = RandomNumberGenerator.new()
	_evidence_rng.seed = evidence_seed
	for _i in draws:
		var value: float = _sample_distribution()
		var bin_idx: int = clampi(int(value * num_bins), 0, num_bins - 1)
		_bins[bin_idx] += 1
		_total_samples += 1
	_evidence_rng = null
	_update_bars()


## Validate an axis value against the code's own list. An unknown word keeps the
## current value rather than silently building something nobody asked for.
func _axis_value(raw: String, allowed: Array, fallback: String) -> String:
	var v: String = raw.strip_edges().to_lower()
	return v if allowed.has(v) else fallback


## Map tokens arrive as `config_*` metadata BEFORE the node enters the tree
## (GridInteractablesComponent sets the metas, then add_child), so reading them
## here means _ready builds the asked-for variant in one pass.
func _read_meta_overrides() -> void:
	if has_meta("config_law"):
		law = _axis_value(str(get_meta("config_law")), LAW_TYPES.keys(), law)
	if has_meta("config_evidence"):
		evidence = _axis_value(str(get_meta("config_evidence")),
			EVIDENCE_DRAWS.keys(), evidence)
	if has_meta("config_evidence_seed"):
		evidence_seed = int(str(get_meta("config_evidence_seed")))


## GUARDED. The grid calls this deferred, AFTER _ready has built the body, so a
## rebuild here must be earned: nothing is cleared unless a value this artifact
## owns actually differs from what it already built with.
func apply_grid_config(config_data: Dictionary) -> void:
	# Parsed through str() first: a fixture that passes "7" rather than 7 would be
	# rejected outright by set() on a typed int and the seed would silently not apply.
	if config_data.has("sample_seed"):
		sample_seed = int(str(config_data["sample_seed"]))
		_clear_samples()

	var want_law: String = law
	var want_evidence: String = evidence
	var want_seed: int = evidence_seed
	if config_data.has("law"):
		want_law = _axis_value(str(config_data["law"]), LAW_TYPES.keys(), law)
	if config_data.has("evidence"):
		want_evidence = _axis_value(str(config_data["evidence"]),
			EVIDENCE_DRAWS.keys(), evidence)
	if config_data.has("evidence_seed"):
		want_seed = int(str(config_data["evidence_seed"]))

	if want_law == law and want_evidence == evidence and want_seed == evidence_seed:
		return

	var law_changed: bool = want_law != law
	law = want_law
	evidence = want_evidence
	evidence_seed = want_seed
	# Only when the law itself moved — otherwise a map that changes `evidence`
	# alone would silently overwrite a `distribution` the scene had set.
	# The setter clears the histogram and redraws the theory curve, which is
	# exactly what a change of law should do.
	if law_changed:
		distribution = int(LAW_TYPES.get(law, distribution)) as DistType
	# Before _ready has run there is nothing built to re-seed; _ready will.
	if _bar_mm == null:
		return
	_clear_samples()
	_seed_evidence()
