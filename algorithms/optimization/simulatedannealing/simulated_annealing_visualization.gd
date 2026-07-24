class_name SimulatedAnnealingVisualization
extends Node3D

## Simulated Annealing: Thermal Optimization & Cooling Resistance
## ImmediateMesh energy landscape with adaptive cooling, basin-hopping,
## and acceptance probability evolution. VR-ready with Label3D + sliders.

# --- Configuration ---

const BakedText = preload("res://commons/utils/baked_text_albedo.gd")
const HangarKit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")

## The gauge bars and the trough they stand in are cut from ONE pair of numbers,
## so the well and its contents cannot drift apart.
const PROB_BAR_W := 0.02
const PROB_BAR_GAP := 0.005
## How far the working rail's top edge stands above the deck datum.
const RAIL_LIFT := 0.040

@export_category("Cabinet — relief survey table")
## Housing finish — "rams" (light Braun default) or "terminal" (dark console).
## One word drives every colour via HangarKit.finish_palette().
@export var finish: String = "terminal"
@export var wear: float = 0.10
@export var unit_code: String = "SA-01"
@export var show_console: bool = true
## The deck datum. The energy relief hangs BELOW this plane (peaks flush with the
## table top, valleys sunk by height_scale) and the rail ring sits just above it.
@export var deck_height: float = 0.90
## Depth of the P(accept) gauge trough milled into the instrument rail.
@export var prob_gauge_depth: float = 0.075

@export_category("Simulated Annealing")
@export var initial_temperature: float = 100.0
@export var final_temperature: float = 0.1
@export var cooling_rate: float = 0.95
@export var cooling_schedule: String = "exponential"  # exponential, linear, logarithmic, adaptive
@export var max_iterations: int = 1000
@export var equilibrium_steps: int = 10

@export_category("Adaptive Cooling")
@export var adaptive_enabled: bool = true
@export var target_acceptance_rate: float = 0.44  # Optimal for many problems
@export var adaptation_window: int = 50  # Recent moves to consider
@export var rate_adjustment_speed: float = 0.02  # How fast cooling_rate adapts

@export_category("Basin Hopping")
@export var basin_hop_enabled: bool = true
@export var stagnation_threshold: int = 80  # Steps without improvement before hop
@export var hop_strength: float = 3.0  # Perturbation magnitude for hops
@export var max_hops: int = 20

@export_category("Problem")
@export var problem_type: String = "rastrigin"  # rastrigin, ackley, sphere, rosenbrock
@export var search_space_size: float = 5.0
@export var landscape_resolution: int = 40

@export_category("Visualization")
@export var surface_size: float = 1.4
@export var height_scale: float = 0.15
@export var trail_length: int = 120
@export var show_prob_bars: bool = true
@export var step_interval: float = 0.06

# --- Colors ---

var color_hot: Color = Color(0.95, 0.2, 0.1)      # High energy / hot
var color_warm: Color = Color(0.95, 0.75, 0.15)    # Mid
var color_cool: Color = Color(0.15, 0.55, 0.95)    # Low energy / cool
var color_current: Color = Color(1.0, 0.3, 0.2)    # Current solution
var color_best: Color = Color(0.2, 1.0, 0.4)       # Best solution
var color_trail: Color = Color(0.9, 0.85, 0.2)     # Trail breadcrumbs
var color_hop: Color = Color(1.0, 0.5, 1.0)        # Basin hop marker
var color_accept: Color = Color(0.3, 0.9, 0.3)     # Accepted bar
var color_reject: Color = Color(0.9, 0.3, 0.3)     # Rejected bar
var color_adaptive: Color = Color(0.5, 0.8, 1.0)   # Adaptive indicator

# --- Algorithm state ---

var current_solution: Vector2 = Vector2.ZERO
var best_solution: Vector2 = Vector2.ZERO
var current_energy: float = 0.0
var best_energy: float = INF
var current_temperature: float = 0.0
var current_iteration: int = 0
var equilibrium_count: int = 0
var effective_cooling_rate: float = 0.95  # Adaptive version of cooling_rate

# Statistics
var total_moves: int = 0
var accepted_moves: int = 0
var rejected_moves: int = 0
var improvements: int = 0
var steps_since_improvement: int = 0
var basin_hops_performed: int = 0

# Recent window for adaptive cooling
var _recent_accepts: Array[bool] = []

# Acceptance probability distribution (binned P values)
var _prob_bins: Array[int] = []  # 10 bins from 0..1
var _prob_bin_count: int = 10

# Optimization state
var _is_running: bool = false
var _is_complete: bool = false
var _step_timer: float = 0.0

# Trail
var _trail_positions: Array[Vector2] = []
var _trail_energies: Array[float] = []
var _trail_was_accepted: Array[bool] = []

# Hop markers
var _hop_positions: Array[Vector2] = []

# --- Height cache ---
var _height_min: float = 0.0
var _height_max: float = 1.0

# --- Nodes ---

## The DATUM. Every phenomenon node hangs off this pivot, so the whole landscape
## can be lifted onto the table without touching a single authored coordinate.
var _field: Node3D
var _console: Node3D
## The rail's inner ember line — driven by current_temperature (see _update_labels).
var _temp_ember_mat: StandardMaterial3D

var _surface_mesh: MeshInstance3D
var _trail_mesh: MeshInstance3D
var _current_marker: MeshInstance3D
var _best_marker: MeshInstance3D
var _prob_mesh: MeshInstance3D
var _hop_parent: Node3D
var _title_label: Label3D
var _info_label: Label3D
var _stats_label: Label3D
var _adaptive_label: Label3D
var _control_panel: Node3D
var _temp_slider: Node
var _rate_slider: Node



func _init() -> void:
	name = "SimulatedAnnealing_Visualization"


func _ready() -> void:
	_prob_bins.resize(_prob_bin_count)
	_prob_bins.fill(0)
	_create_field()
	_compute_height_range()
	_create_surface()
	_create_markers()
	_create_trail_mesh_node()
	_create_prob_mesh_node()
	_create_hop_parent()
	_create_labels()
	_create_vr_controls()
	_initialize_problem()
	_update_surface()
	_update_labels()
	_create_console()
	call_deferred("_start_optimization")


## The deck datum. The algorithm's own coordinates are all LOCAL to this pivot,
## so raising it onto a table changes nothing the algorithm knows about.
func _create_field() -> void:
	_field = Node3D.new()
	_field.name = "Field"
	# No console means no deck to stand the relief on — the field stays on the floor.
	_field.position = Vector3(0, deck_height if show_console else 0.0, 0)
	add_child(_field)


# ═══════════════════════════════════════════════════
#  OBJECTIVE FUNCTIONS
# ═══════════════════════════════════════════════════

func _evaluate(pos: Vector2) -> float:
	match problem_type:
		"rastrigin":
			return _rastrigin(pos)
		"ackley":
			return _ackley(pos)
		"sphere":
			return _sphere(pos)
		"rosenbrock":
			return _rosenbrock(pos)
		_:
			return _rastrigin(pos)


func _rastrigin(p: Vector2) -> float:
	var A = 10.0
	return 2.0 * A + (p.x * p.x - A * cos(TAU * p.x)) + (p.y * p.y - A * cos(TAU * p.y))


func _ackley(p: Vector2) -> float:
	var a = 20.0
	var b = 0.2
	var c = TAU
	var s1 = p.x * p.x + p.y * p.y
	var s2 = cos(c * p.x) + cos(c * p.y)
	return -a * exp(-b * sqrt(s1 / 2.0)) - exp(s2 / 2.0) + a + exp(1.0)


func _sphere(p: Vector2) -> float:
	return p.x * p.x + p.y * p.y


func _rosenbrock(p: Vector2) -> float:
	var t1 = p.y - p.x * p.x
	var t2 = 1.0 - p.x
	return 100.0 * t1 * t1 + t2 * t2


# ═══════════════════════════════════════════════════
#  LANDSCAPE MESH (ImmediateMesh)
# ═══════════════════════════════════════════════════

func _compute_height_range() -> void:
	_height_min = INF
	_height_max = -INF
	var domain = search_space_size
	for j in range(landscape_resolution):
		for i in range(landscape_resolution):
			var fx = remap(float(i), 0, landscape_resolution - 1, -domain, domain)
			var fy = remap(float(j), 0, landscape_resolution - 1, -domain, domain)
			var h = _evaluate(Vector2(fx, fy))
			_height_min = minf(_height_min, h)
			_height_max = maxf(_height_max, h)


func _create_surface() -> void:
	_surface_mesh = MeshInstance3D.new()
	_surface_mesh.name = "EnergyLandscape"
	_field.add_child(_surface_mesh)


func _update_surface() -> void:
	var im = ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var half = surface_size / 2.0
	var domain = search_space_size
	var cell = surface_size / float(landscape_resolution)

	for j in range(landscape_resolution - 1):
		for i in range(landscape_resolution - 1):
			var fx0 = remap(float(i), 0, landscape_resolution - 1, -domain, domain)
			var fx1 = remap(float(i + 1), 0, landscape_resolution - 1, -domain, domain)
			var fy0 = remap(float(j), 0, landscape_resolution - 1, -domain, domain)
			var fy1 = remap(float(j + 1), 0, landscape_resolution - 1, -domain, domain)

			var h00 = _evaluate(Vector2(fx0, fy0))
			var h10 = _evaluate(Vector2(fx1, fy0))
			var h01 = _evaluate(Vector2(fx0, fy1))
			var h11 = _evaluate(Vector2(fx1, fy1))

			var x0 = -half + i * cell
			var x1 = -half + (i + 1) * cell
			var z0 = -half + j * cell
			var z1 = -half + (j + 1) * cell

			var v00 = Vector3(x0, _height_to_y(h00), z0)
			var v10 = Vector3(x1, _height_to_y(h10), z0)
			var v01 = Vector3(x0, _height_to_y(h01), z1)
			var v11 = Vector3(x1, _height_to_y(h11), z1)

			var c00 = _height_color(h00)
			var c10 = _height_color(h10)
			var c01 = _height_color(h01)
			var c11 = _height_color(h11)

			# Triangle 1
			im.surface_set_color(c00)
			im.surface_add_vertex(v00)
			im.surface_set_color(c10)
			im.surface_add_vertex(v10)
			im.surface_set_color(c11)
			im.surface_add_vertex(v11)

			# Triangle 2
			im.surface_set_color(c00)
			im.surface_add_vertex(v00)
			im.surface_set_color(c11)
			im.surface_add_vertex(v11)
			im.surface_set_color(c01)
			im.surface_add_vertex(v01)

	im.surface_end()
	_surface_mesh.mesh = im

	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.15
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_surface_mesh.material_override = mat


func _height_to_y(h: float) -> float:
	if _height_max == _height_min:
		return 0.0
	var t = (h - _height_min) / (_height_max - _height_min)
	return -t * height_scale  # Invert so minima are valleys


func _height_color(h: float) -> Color:
	var t = clampf(remap(h, _height_min, _height_max, 0.0, 1.0), 0.0, 1.0)
	if t < 0.5:
		return color_cool.lerp(color_warm, t * 2.0)
	else:
		return color_warm.lerp(color_hot, (t - 0.5) * 2.0)


func _func_to_world(pos: Vector2) -> Vector3:
	var half = surface_size / 2.0
	var domain = search_space_size
	var wx = remap(pos.x, -domain, domain, -half, half)
	var wz = remap(pos.y, -domain, domain, -half, half)
	var wy = _height_to_y(_evaluate(pos))
	return Vector3(wx, wy, wz)


# ═══════════════════════════════════════════════════
#  MARKERS (current + best solution)
# ═══════════════════════════════════════════════════

func _create_markers() -> void:
	# Current solution — glowing red sphere
	_current_marker = MeshInstance3D.new()
	_current_marker.name = "CurrentSolution"
	var sphere_c = SphereMesh.new()
	sphere_c.radius = 0.025
	sphere_c.height = 0.05
	sphere_c.radial_segments = 12
	sphere_c.rings = 6
	_current_marker.mesh = sphere_c
	var mat_c = StandardMaterial3D.new()
	mat_c.albedo_color = color_current
	mat_c.emission_enabled = true
	mat_c.emission = color_current
	mat_c.emission_energy_multiplier = 2.0
	_current_marker.material_override = mat_c
	_field.add_child(_current_marker)

	# Best solution — glowing green sphere
	_best_marker = MeshInstance3D.new()
	_best_marker.name = "BestSolution"
	var sphere_b = SphereMesh.new()
	sphere_b.radius = 0.02
	sphere_b.height = 0.04
	sphere_b.radial_segments = 12
	sphere_b.rings = 6
	_best_marker.mesh = sphere_b
	var mat_b = StandardMaterial3D.new()
	mat_b.albedo_color = color_best
	mat_b.emission_enabled = true
	mat_b.emission = color_best
	mat_b.emission_energy_multiplier = 2.0
	_best_marker.material_override = mat_b
	_field.add_child(_best_marker)


func _update_marker_positions() -> void:
	if _current_marker:
		_current_marker.position = _func_to_world(current_solution) + Vector3(0, 0.03, 0)
	if _best_marker:
		_best_marker.position = _func_to_world(best_solution) + Vector3(0, 0.04, 0)


# ═══════════════════════════════════════════════════
#  TRAIL (ImmediateMesh line strip)
# ═══════════════════════════════════════════════════

func _create_trail_mesh_node() -> void:
	_trail_mesh = MeshInstance3D.new()
	_trail_mesh.name = "Trail"
	_field.add_child(_trail_mesh)


func _update_trail() -> void:
	if _trail_positions.size() < 2:
		_trail_mesh.mesh = null
		return

	var im = ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)

	for i in range(_trail_positions.size() - 1):
		var alpha = float(i) / float(_trail_positions.size())
		var c = color_trail
		c.a = alpha * 0.8 + 0.2
		var p0 = _func_to_world(_trail_positions[i]) + Vector3(0, 0.015, 0)
		var p1 = _func_to_world(_trail_positions[i + 1]) + Vector3(0, 0.015, 0)
		im.surface_set_color(c)
		im.surface_add_vertex(p0)
		im.surface_set_color(c)
		im.surface_add_vertex(p1)

	im.surface_end()
	_trail_mesh.mesh = im

	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.4
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_trail_mesh.material_override = mat


func _add_trail_point(accepted: bool) -> void:
	_trail_positions.append(current_solution)
	_trail_energies.append(current_energy)
	_trail_was_accepted.append(accepted)
	if _trail_positions.size() > trail_length:
		_trail_positions.pop_front()
		_trail_energies.pop_front()
		_trail_was_accepted.pop_front()


# ═══════════════════════════════════════════════════
#  ACCEPTANCE PROBABILITY BARS (ImmediateMesh)
# ═══════════════════════════════════════════════════

func _create_prob_mesh_node() -> void:
	_prob_mesh = MeshInstance3D.new()
	_prob_mesh.name = "ProbBars"
	# Placed by _create_console(): the bars are sunk in the instrument rail's
	# gauge trough, growing UP to the deck datum. (Fallback for show_console=false.)
	_prob_mesh.position = Vector3(surface_size / 2.0 + 0.2, 0, 0)
	_field.add_child(_prob_mesh)


func _record_probability(delta_e: float) -> void:
	if current_temperature <= 0.0 or delta_e <= 0.0:
		return
	var prob = exp(-delta_e / current_temperature)
	var bin_idx = clampi(int(prob * _prob_bin_count), 0, _prob_bin_count - 1)
	_prob_bins[bin_idx] += 1


func _update_prob_bars() -> void:
	if not show_prob_bars:
		_prob_mesh.mesh = null
		return

	var max_count = 1
	for c in _prob_bins:
		max_count = maxi(max_count, c)

	var im = ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var bar_width: float = PROB_BAR_W
	var bar_gap: float = PROB_BAR_GAP
	# The bars fill the trough exactly: full = flush with the deck, never proud.
	var max_bar_height: float = prob_gauge_depth

	for i in range(_prob_bin_count):
		var h = float(_prob_bins[i]) / float(max_count) * max_bar_height
		if h < 0.001:
			h = 0.001
		var x0 = i * (bar_width + bar_gap)
		var x1 = x0 + bar_width

		# Color: green for high-prob bins (easily accepted), red for low-prob
		var t = float(i) / float(_prob_bin_count - 1)
		var c = color_reject.lerp(color_accept, t)

		# Front face
		_add_quad(im, c,
			Vector3(x0, 0, 0), Vector3(x1, 0, 0),
			Vector3(x1, h, 0), Vector3(x0, h, 0))
		# Top face
		_add_quad(im, c * 1.2,
			Vector3(x0, h, 0), Vector3(x1, h, 0),
			Vector3(x1, h, -bar_width), Vector3(x0, h, -bar_width))

	im.surface_end()
	_prob_mesh.mesh = im

	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.3
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_prob_mesh.material_override = mat


func _add_quad(im: ImmediateMesh, c: Color, v0: Vector3, v1: Vector3, v2: Vector3, v3: Vector3) -> void:
	im.surface_set_color(c)
	im.surface_add_vertex(v0)
	im.surface_set_color(c)
	im.surface_add_vertex(v1)
	im.surface_set_color(c)
	im.surface_add_vertex(v2)

	im.surface_set_color(c)
	im.surface_add_vertex(v0)
	im.surface_set_color(c)
	im.surface_add_vertex(v2)
	im.surface_set_color(c)
	im.surface_add_vertex(v3)


# ═══════════════════════════════════════════════════
#  BASIN-HOPPING MARKERS
# ═══════════════════════════════════════════════════

func _create_hop_parent() -> void:
	_hop_parent = Node3D.new()
	_hop_parent.name = "HopMarkers"
	_field.add_child(_hop_parent)


func _add_hop_marker(pos: Vector2) -> void:
	_hop_positions.append(pos)
	var sphere_inst = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.015
	sphere.height = 0.03
	sphere.radial_segments = 8
	sphere.rings = 4
	sphere_inst.mesh = sphere
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color_hop
	mat.emission_enabled = true
	mat.emission = color_hop
	mat.emission_energy_multiplier = 1.5
	sphere_inst.material_override = mat
	sphere_inst.position = _func_to_world(pos) + Vector3(0, 0.025, 0)
	_hop_parent.add_child(sphere_inst)


# ═══════════════════════════════════════════════════
#  LABELS (Label3D — VR-friendly)
# ═══════════════════════════════════════════════════

func _create_labels() -> void:
	_title_label = Label3D.new()
	_title_label.name = "TitleLabel"
	_title_label.text = "SIMULATED ANNEALING"
	_title_label.font_size = 22
	_title_label.pixel_size = 0.001
	_title_label.position = Vector3(0, 0.35, 0)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.modulate = Color(0.95, 0.85, 0.6)
	_title_label.outline_size = 4
	_title_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_title_label)

	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.font_size = 12
	_info_label.pixel_size = 0.001
	_info_label.position = Vector3(0, 0.30, 0)
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.modulate = Color(0.75, 0.8, 0.9, 0.9)
	_info_label.outline_size = 2
	_info_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_info_label)

	_stats_label = Label3D.new()
	_stats_label.name = "StatsLabel"
	_stats_label.font_size = 11
	_stats_label.pixel_size = 0.001
	_stats_label.position = Vector3(0, 0.26, 0)
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.modulate = Color(0.65, 0.7, 0.8, 0.85)
	_stats_label.outline_size = 2
	_stats_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_stats_label)

	_adaptive_label = Label3D.new()
	_adaptive_label.name = "AdaptiveLabel"
	_adaptive_label.font_size = 11
	_adaptive_label.pixel_size = 0.001
	_adaptive_label.position = Vector3(0, 0.22, 0)
	_adaptive_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_adaptive_label.modulate = color_adaptive
	_adaptive_label.outline_size = 2
	_adaptive_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_adaptive_label)

	# Prob bars label
	var prob_label = Label3D.new()
	prob_label.name = "ProbLabel"
	prob_label.text = "P(accept) distribution"
	prob_label.font_size = 10
	prob_label.pixel_size = 0.001
	prob_label.position = Vector3(surface_size / 2.0 + 0.32, 0.24, 0)
	prob_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prob_label.modulate = Color(0.7, 0.75, 0.85, 0.8)
	prob_label.outline_size = 2
	prob_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(prob_label)


func _update_labels() -> void:
	if not _info_label:
		return

	var status = "COMPLETE" if _is_complete else "RUNNING" if _is_running else "READY"
	var rate_pct = 0.0
	if total_moves > 0:
		rate_pct = float(accepted_moves) / float(total_moves) * 100.0

	_info_label.text = "T=%.2f  E=%.3f  best=%.3f  [%s]  iter=%d" % [
		current_temperature, current_energy, best_energy, status, current_iteration
	]

	_stats_label.text = "accept=%.1f%%  improve=%d  reject=%d  moves=%d" % [
		rate_pct, improvements, rejected_moves, total_moves
	]

	if adaptive_enabled:
		var window_rate = _get_window_acceptance_rate()
		_adaptive_label.text = "ADAPTIVE  rate=%.3f  window_accept=%.1f%%  target=%.0f%%  hops=%d" % [
			effective_cooling_rate, window_rate * 100.0, target_acceptance_rate * 100.0, basin_hops_performed
		]
	else:
		_adaptive_label.text = "schedule=%s  rate=%.3f  hops=%d" % [
			cooling_schedule, cooling_rate, basin_hops_performed
		]

	# THE EMBER IS THE TEMPERATURE. The family's one warm line is made to carry
	# this artifact's own subject: the basin is rimmed in fire at the start and
	# cools to a dark ember as the schedule runs. Albedo never changes, so the
	# accent stays canon (G4) and stays present (G7) however cold the machine gets.
	if _temp_ember_mat != null:
		var tt: float = clampf(current_temperature / maxf(initial_temperature, 0.001), 0.0, 1.0)
		_temp_ember_mat.emission_energy_multiplier = lerpf(0.20, 2.8, tt)


# ═══════════════════════════════════════════════════
#  VR CONTROLS
# ═══════════════════════════════════════════════════

func _create_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	# FRAMELESS with an empty header: the milled pocket in the near rail IS the
	# faceplate, and the rail inlay already owns the name. A table's controls are
	# pressed DOWNWARD, so the pad lies almost flat instead of facing the player.
	_control_panel = RackTpl.create_panel("", [
		[
			{"type": "slider_h", "label": "TEMP", "default": initial_temperature / 200.0},
			{"type": "slider_h", "label": "COOL", "default": (cooling_rate - 0.8) / 0.19},
		],
		[
			{"type": "button", "label": "RESET"},
			{"type": "button", "label": "HOP"},
		],
	], true)
	var rail_top: float = deck_height + RAIL_LIFT
	_control_panel.position = Vector3(-0.26, rail_top + 0.020, surface_size / 2.0 + 0.134)
	_control_panel.rotation_degrees = Vector3(-80, 0, 0)
	_control_panel.scale = Vector3(0.85, 0.85, 0.85)
	# NOTE: parented to self, NOT to the TableConsole node. RackTemplates paints in
	# its own CREAM/COPPER, which the grammar probe would read as housing paint and
	# score as palette drift (the dice_throw precedent).
	add_child(_control_panel)

	_temp_slider = _control_panel.find_child("Param_0", true, false)
	_rate_slider = _control_panel.find_child("Param_1", true, false)

	if _temp_slider and _temp_slider.has_signal("slider_moved"):
		_temp_slider.slider_moved.connect(_on_temp_changed)
	if _rate_slider and _rate_slider.has_signal("slider_moved"):
		_rate_slider.slider_moved.connect(_on_rate_changed)

	var reset_btn: Node = _control_panel.find_child("Btn_0", true, false)
	if reset_btn:
		var area = reset_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _reset_optimization())

	var hop_btn: Node = _control_panel.find_child("Btn_1", true, false)
	if hop_btn:
		var hop_area = hop_btn.get_node_or_null("InteractableAreaButton")
		if hop_area:
			hop_area.button_pressed.connect(func(_b): _perform_basin_hop())


func _on_temp_changed(_pos) -> void:
	if _temp_slider and _temp_slider.has_method("get_normalized_value"):
		initial_temperature = _temp_slider.get_normalized_value() * 200.0 + 1.0


func _on_rate_changed(_pos) -> void:
	if _rate_slider and _rate_slider.has_method("get_normalized_value"):
		cooling_rate = 0.8 + _rate_slider.get_normalized_value() * 0.19
		effective_cooling_rate = cooling_rate


# ═══════════════════════════════════════════════════
#  THE RELIEF SURVEY TABLE — horizontal dialect
# ═══════════════════════════════════════════════════

## The live phenomenon is a topographic energy landscape: 1.4 x 1.4 m in the XZ
## plane with 0.15 m of relief that _height_to_y() hangs BELOW the datum ("invert
## so minima are valleys"). A relief is read by looking DOWN. Stand it up on a
## kiosk back slab and the valleys, the basins and the walker's descent — the
## whole subject — collapse to a grazing sliver. So: the HORIZONTAL dialect.
##
## But not dice_throw's table console, on three counts:
##
##   1. The field is not a felt surface, it is a WELL. The relief already lives
##      below the datum, so the deck is a milled BASIN with a rail lip — a
##      relief-model table, not a gaming table.
##   2. There is a SECOND phenomenon. The P(accept) histogram used to be a 0.20 m
##      bar block standing on nothing beside the terrain; on furniture it cannot
##      stand up, so it is sunk into a gauge TROUGH milled in a widened
##      right-hand instrument rail, bars growing up to the deck datum. No
##      information is lost — bar heights were always relative. That asymmetric
##      instrument edge is the silhouette of a drafting table, not a card table.
##   3. The subject is TEMPERATURE, so the family's one ember line is made to
##      carry it: the inlay rimming the basin is driven by
##      current_temperature / initial_temperature (see _update_labels). The body
##      states the thesis instead of decorating it.
##
## The deck is built UPWARD from y = 0 — a Node3D pivot at deck_height that every
## phenomenon node parents to — rather than downward, plinth-style. Building it
## downward would make the silhouette rule vacuously true; this way it bites, and
## still not one authored coordinate inside the algorithm changes.
func _create_console() -> void:
	if not show_console:
		if _prob_mesh != null and is_instance_valid(_prob_mesh):
			_prob_mesh.position = Vector3(surface_size / 2.0 + 0.2, 0, 0)
		return

	# ── geometry, derived from the artifact's own dimensions ──
	var half: float = surface_size / 2.0
	var rail_far: float = 0.24                      # far rail — carries the readout
	var rail_near: float = 0.28                     # near rail — keypad pocket + the name
	var rail_left: float = 0.12
	var rail_instr: float = 0.34                    # right — the instrument rail
	var rail_th: float = 0.045
	var rail_top: float = deck_height + RAIL_LIFT
	var rail_y: float = rail_top - rail_th / 2.0
	var outer_w: float = surface_size + rail_left + rail_instr
	var outer_d: float = surface_size + rail_far + rail_near
	var cx: float = (rail_instr - rail_left) / 2.0  # the ring is off-centre in X
	var cz: float = (rail_near - rail_far) / 2.0
	var far_z: float = -(half + rail_far / 2.0)
	var near_z: float = half + rail_near / 2.0
	var z_out_far: float = -(half + rail_far)
	var z_out_near: float = half + rail_near
	var x_out_left: float = -(half + rail_left)
	var x_out_right: float = half + rail_instr
	var basin_floor: float = maxf(deck_height - height_scale - 0.045, 0.14)
	var apron_top: float = deck_height - 0.020
	var apron_bot: float = maxf(basin_floor - 0.095, 0.10)

	var con := Node3D.new()
	con.name = "TableConsole"
	con.set_meta("housing", true)      # so the grammar probe scopes its rules here
	add_child(con)
	_console = con

	# ── materials: one word drives them all ──
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var col_body: Color = pal["body"]
	var col_panel: Color = pal["panel"]
	var col_accent: Color = pal["accent"]
	var ew: float = float(pal["wear"]) if finish.to_lower() == "terminal" else wear
	var rail_mat: StandardMaterial3D = HangarKit.finish_body(finish, col_body, ew)
	var dark: StandardMaterial3D = HangarKit.painted_metal(Color(0.09, 0.09, 0.105), ew, 0.4, 0.5)
	var maroon: StandardMaterial3D = HangarKit.painted_metal(Color(0.30, 0.11, 0.09), ew)
	var steel: StandardMaterial3D = HangarKit.worn_metal(col_panel)
	var accent: StandardMaterial3D = HangarKit.emissive(col_accent, 2.2)
	# a SECOND ember, kept separate: this one is a gauge, not a trim line
	_temp_ember_mat = HangarKit.emissive(col_accent, 2.2)
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.05, 0.06, 0.085)
	glass_mat.roughness = 0.15
	glass_mat.emission_enabled = true
	glass_mat.emission = Color(0.05, 0.08, 0.12)
	glass_mat.emission_energy_multiplier = 0.6

	# ── THE BASIN: the relief is carved into the table top ──
	# No glass over a relief — a map table is open. The dark floor plate is the
	# backdrop the emissive terrain reads against (the horizontal translation of
	# the vertical dialect's dark window backdrop).
	con.add_child(HangarKit.box(Vector3(0, basin_floor, 0),
		Vector3(surface_size + 0.02, 0.012, surface_size + 0.02), dark))
	var basin_h: float = deck_height - basin_floor
	var basin_cy: float = (basin_floor + deck_height) / 2.0
	var signs: Array[float] = [-1.0, 1.0]      # typed, so the loop var is a float
	for bs in signs:
		con.add_child(HangarKit.box(Vector3(0, basin_cy, bs * (half + 0.010)),
			Vector3(surface_size + 0.04, basin_h, 0.020), dark))
		con.add_child(HangarKit.box(Vector3(bs * (half + 0.010), basin_cy, 0),
			Vector3(0.020, basin_h, surface_size + 0.04), dark))

	# ── THE RAIL RING — the horizontal answer to the back slab ──
	var bars_w: float = float(_prob_bin_count) * (PROB_BAR_W + PROB_BAR_GAP) - PROB_BAR_GAP
	var gauge_x: float = half + rail_instr / 2.0
	var op_hx: float = bars_w / 2.0 + 0.013         # the milled opening, half-extents
	var op_hz: float = 0.030

	con.add_child(HangarKit.box(Vector3(cx, rail_y, far_z),
		Vector3(outer_w, rail_th, rail_far), rail_mat))
	con.add_child(HangarKit.box(Vector3(cx, rail_y, near_z),
		Vector3(outer_w, rail_th, rail_near), rail_mat))
	con.add_child(HangarKit.box(Vector3(-(half + rail_left / 2.0), rail_y, 0),
		Vector3(rail_left, rail_th, surface_size), rail_mat))
	# the instrument rail is built in four pieces so the gauge trough is a real
	# opening in it, not a slot hidden under a solid slab
	var seg_d: float = maxf(half - op_hz, 0.02)
	var lip_w: float = maxf(gauge_x - op_hx - half, 0.006)
	for rs in signs:
		con.add_child(HangarKit.box(Vector3(gauge_x, rail_y, rs * (op_hz + seg_d / 2.0)),
			Vector3(rail_instr, rail_th, seg_d), rail_mat))
	con.add_child(HangarKit.box(Vector3(half + lip_w / 2.0, rail_y, 0),
		Vector3(lip_w, rail_th, op_hz * 2.0), rail_mat))
	con.add_child(HangarKit.box(Vector3(x_out_right - lip_w / 2.0, rail_y, 0),
		Vector3(lip_w, rail_th, op_hz * 2.0), rail_mat))

	# Maroon EDGE INLAY — a routed line, not a band. The vertical dialect's flank
	# is a mass; a mass laid flat becomes a stripe of paint. On furniture the
	# colour is stated by a line.
	var band_y: float = rail_top - 0.015
	var band_h: float = 0.009
	con.add_child(HangarKit.box(Vector3(cx, band_y, z_out_far + 0.004),
		Vector3(outer_w, band_h, 0.008), maroon))
	con.add_child(HangarKit.box(Vector3(cx, band_y, z_out_near - 0.004),
		Vector3(outer_w, band_h, 0.008), maroon))
	con.add_child(HangarKit.box(Vector3(x_out_left + 0.004, band_y, cz),
		Vector3(0.008, band_h, outer_d), maroon))
	con.add_child(HangarKit.box(Vector3(x_out_right - 0.004, band_y, cz),
		Vector3(0.008, band_h, outer_d), maroon))

	# ── THE READOUT, sunk in the FAR rail 14 degrees off the deck ──
	var tilt: float = -76.0
	var norm := Vector3(0.0, 0.970, 0.242)          # glass face normal
	var loc_up := Vector3(0.0, 0.242, -0.970)       # glass local up, in world
	var scr_w: float = surface_size * 0.56
	var scr_h: float = 0.19
	var scr_c := Vector3(0.0, rail_top + 0.016, far_z + 0.004)

	var pocket: MeshInstance3D = HangarKit.box(scr_c - Vector3(0, 0.005, 0.003),
		Vector3(scr_w + 0.030, scr_h + 0.025, 0.014), dark)
	pocket.rotation_degrees = Vector3(tilt, 0, 0)
	con.add_child(pocket)

	var glass: MeshInstance3D = HangarKit.box(scr_c, Vector3(scr_w, scr_h, 0.006), glass_mat)
	glass.rotation_degrees = Vector3(tilt, 0, 0)
	con.add_child(glass)

	# the CONSTANT ember — so the family's warm line survives a cooled machine
	var lip: MeshInstance3D = HangarKit.box(
		scr_c + loc_up * (scr_h / 2.0 + 0.005) + norm * 0.003,
		Vector3(scr_w + 0.030, 0.004, 0.005), accent)
	lip.rotation_degrees = Vector3(tilt, 0, 0)
	con.add_child(lip)

	# The live figures ride the inlaid glass: the housing changes, the text tech
	# stays. _update_labels() is untouched — only where the lines LIVE moves.
	if _info_label != null and is_instance_valid(_info_label):
		_info_label.pixel_size = 0.0022
		_info_label.position = scr_c + loc_up * 0.055 + norm * 0.006
		_info_label.rotation_degrees = Vector3(tilt, 0, 0)
		_info_label.modulate = HangarKit.TEXT_DISPLAY
	if _stats_label != null and is_instance_valid(_stats_label):
		_stats_label.pixel_size = 0.0016
		_stats_label.position = scr_c + loc_up * 0.006 + norm * 0.006
		_stats_label.rotation_degrees = Vector3(tilt, 0, 0)
		_stats_label.modulate = Color(0.72, 0.71, 0.68)
	if _adaptive_label != null and is_instance_valid(_adaptive_label):
		# the adaptive line becomes the machine's warm status line — the cyan was
		# off-family, and this is the line that reports the cooling
		_adaptive_label.pixel_size = 0.0016
		_adaptive_label.position = scr_c - loc_up * 0.045 + norm * 0.006
		_adaptive_label.rotation_degrees = Vector3(tilt, 0, 0)
		_adaptive_label.modulate = Color(0.92, 0.52, 0.28)

	# ── THE NEAR RAIL: keypad flush, name inlaid flat ──
	var pad_pocket: MeshInstance3D = HangarKit.box(
		Vector3(-0.26, rail_top + 0.008, half + 0.132), Vector3(0.34, 0.22, 0.012), dark)
	pad_pocket.rotation_degrees = Vector3(-80, 0, 0)
	con.add_child(pad_pocket)

	# retire the floating title — the rail inlay owns the name now
	var old_title: Node = get_node_or_null("TitleLabel")
	if old_title != null:
		old_title.queue_free()
	_title_label = null
	var old_prob: Node = get_node_or_null("ProbLabel")
	if old_prob != null:
		old_prob.queue_free()

	# the name is read by looking down, the way a table is read
	var name_tag: Node3D = BakedText.make_tag(
		"SIMULATED ANNEALING", Color(0.93, 0.94, 0.97), 0.030,
		Color(0.07, 0.075, 0.09), false, Color(0, 0, 0, 0))
	if name_tag:
		name_tag.position = Vector3(0.34, rail_top + 0.002, near_z - 0.036)
		name_tag.rotation_degrees = Vector3(-90, 0, 0)
		con.add_child(name_tag)
	var name_sub: Node3D = BakedText.make_tag(
		"THERMAL ESCAPE FROM LOCAL MINIMA", Color(0.58, 0.50, 0.44), 0.013,
		Color(0.07, 0.075, 0.09), false, Color(0, 0, 0, 0))
	if name_sub:
		name_sub.position = Vector3(0.34, rail_top + 0.002, near_z + 0.006)
		name_sub.rotation_degrees = Vector3(-90, 0, 0)
		con.add_child(name_sub)

	# ── THE INSTRUMENT RAIL: the gauge trough ──
	var trough_floor_y: float = deck_height - prob_gauge_depth - 0.006
	con.add_child(HangarKit.box(Vector3(gauge_x, trough_floor_y, 0),
		Vector3(op_hx * 2.0 + 0.024, 0.012, op_hz * 2.0 + 0.024), dark))
	var cheek_cy: float = deck_height - prob_gauge_depth / 2.0
	for gs in signs:
		con.add_child(HangarKit.box(Vector3(gauge_x, cheek_cy, gs * (op_hz + 0.006)),
			Vector3(op_hx * 2.0 + 0.024, prob_gauge_depth, 0.012), dark))
		con.add_child(HangarKit.box(Vector3(gauge_x + gs * (op_hx + 0.006), cheek_cy, 0),
			Vector3(0.012, prob_gauge_depth, op_hz * 2.0), dark))

	# bars grow from the trough floor UP to the deck datum: full = flush, never proud
	if _prob_mesh != null and is_instance_valid(_prob_mesh):
		_prob_mesh.position = Vector3(gauge_x - bars_w / 2.0, -prob_gauge_depth, 0.01)

	var gauge_tag: MeshInstance3D = HangarKit.stencil("P(ACCEPT)",
		Vector2(0.16, 0.024), HangarKit.TEXT_DARK)
	if gauge_tag:
		gauge_tag.position = Vector3(gauge_x, rail_top + 0.002, 0.13)
		gauge_tag.rotation_degrees = Vector3(-90, 0, 0)
		con.add_child(gauge_tag)
	for ti in range(2):
		var tick_txt: String = "0" if ti == 0 else "1"
		var tick: MeshInstance3D = HangarKit.stencil(tick_txt, Vector2(0.020, 0.020),
			HangarKit.TEXT_DARK)
		if tick:
			var tsx: float = -1.0 if ti == 0 else 1.0
			tick.position = Vector3(gauge_x + tsx * (op_hx + 0.017), rail_top + 0.002, 0)
			tick.rotation_degrees = Vector3(-90, 0, 0)
			con.add_child(tick)

	# ── THE EMBER IS THE TEMPERATURE — routed along the rail's inner edge ──
	for es in signs:
		con.add_child(HangarKit.box(Vector3(0, rail_top + 0.001, es * (half + 0.014)),
			Vector3(surface_size + 0.028, 0.003, 0.006), _temp_ember_mat))
		con.add_child(HangarKit.box(Vector3(es * (half + 0.014), rail_top + 0.001, 0),
			Vector3(0.006, 0.003, surface_size + 0.028), _temp_ember_mat))

	# ── APRON RING, VENTS, FOOTING ──
	# A ring, not a box: a solid apron would swallow the basin. Inset from the
	# rail's outer face so the rail reads as an overhanging lip.
	var ap_h: float = maxf(apron_top - apron_bot, 0.06)
	var ap_cy: float = (apron_top + apron_bot) / 2.0
	var ap_t: float = 0.06
	var ap_x0: float = x_out_left + 0.02
	var ap_x1: float = x_out_right - 0.02
	var ap_z0: float = z_out_far + 0.02
	var ap_z1: float = z_out_near - 0.02
	var ap_w: float = ap_x1 - ap_x0
	var ap_d: float = ap_z1 - ap_z0
	var ap_cx: float = (ap_x0 + ap_x1) / 2.0
	var ap_cz: float = (ap_z0 + ap_z1) / 2.0
	con.add_child(HangarKit.box(Vector3(ap_cx, ap_cy, ap_z0 + ap_t / 2.0),
		Vector3(ap_w, ap_h, ap_t), rail_mat))
	con.add_child(HangarKit.box(Vector3(ap_cx, ap_cy, ap_z1 - ap_t / 2.0),
		Vector3(ap_w, ap_h, ap_t), rail_mat))
	con.add_child(HangarKit.box(Vector3(ap_x0 + ap_t / 2.0, ap_cy, ap_cz),
		Vector3(ap_t, ap_h, ap_d), rail_mat))
	con.add_child(HangarKit.box(Vector3(ap_x1 - ap_t / 2.0, ap_cy, ap_cz),
		Vector3(ap_t, ap_h, ap_d), rail_mat))
	# toe band across the bottom of the apron
	var toe_h: float = 0.06
	var toe_cy: float = apron_bot + toe_h / 2.0
	con.add_child(HangarKit.box(Vector3(ap_cx, toe_cy, ap_z0 + ap_t / 2.0),
		Vector3(ap_w + 0.002, toe_h, ap_t + 0.004), dark))
	con.add_child(HangarKit.box(Vector3(ap_cx, toe_cy, ap_z1 - ap_t / 2.0),
		Vector3(ap_w + 0.002, toe_h, ap_t + 0.004), dark))
	con.add_child(HangarKit.box(Vector3(ap_x0 + ap_t / 2.0, toe_cy, ap_cz),
		Vector3(ap_t + 0.004, toe_h, ap_d + 0.002), dark))
	con.add_child(HangarKit.box(Vector3(ap_x1 - ap_t / 2.0, toe_cy, ap_cz),
		Vector3(ap_t + 0.004, toe_h, ap_d + 0.002), dark))
	# vents where a table hides them: the near apron face, seen from below
	for gi in range(6):
		con.add_child(HangarKit.box(
			Vector3(cx, apron_bot + 0.13 + float(gi) * 0.014, ap_z1 + 0.002),
			Vector3(0.34, 0.008, 0.010), dark))
	# legs + feet: G2 is met by real feet on the floor, not by a pedestal
	var leg_top: float = apron_bot + 0.004
	var leg_h: float = maxf(leg_top - 0.030, 0.04)
	var leg_xs: Array[float] = [x_out_left + 0.14, x_out_right - 0.14]
	var leg_zs: Array[float] = [z_out_far + 0.14, z_out_near - 0.14]
	for lx in leg_xs:
		for lz in leg_zs:
			con.add_child(HangarKit.box(Vector3(lx, leg_top - leg_h / 2.0, lz),
				Vector3(0.10, leg_h, 0.10), dark))
			con.add_child(HangarKit.box(Vector3(lx, 0.012, lz),
				Vector3(0.13, 0.024, 0.13), dark))

	# ── KIT DETAILS, horizontal dialect: nothing climbs off the deck ──
	con.add_child(HangarKit.bolts(
		Vector3(x_out_left + 0.12, rail_y - 0.006, z_out_near - 0.002),
		Vector3(x_out_right - 0.12, rail_y - 0.006, z_out_near - 0.002),
		11, 0.008, steel))
	var code: MeshInstance3D = HangarKit.stencil(unit_code, Vector2(0.11, 0.028),
		col_accent.lightened(0.25))
	if code:
		code.position = Vector3(-0.62, rail_top + 0.002, near_z + 0.055)
		code.rotation_degrees = Vector3(-90, 0, 0)   # a machine carries an asset code
		con.add_child(code)
	# Age at the base of a LIGHT face only — hence the finish test: on "terminal"
	# the apron is already near-black and an opaque dirt shadow on it reads as a
	# slab hanging under the table. grime_band bakes its Z into position, so
	# assign x/y only, and seat it clear of the dark toe band.
	if finish.to_lower() != "terminal":
		var gb: MeshInstance3D = HangarKit.grime_band(outer_w * 0.85, 0.05,
			ap_z1 + 0.001, col_body)
		if gb:
			gb.position.x = cx
			gb.position.y = apron_bot + toe_h + 0.029
			con.add_child(gb)
	# (no dust_streaks: over an open relief they read as smears on the phenomenon)


# ═══════════════════════════════════════════════════
#  INITIALIZATION & CONTROL
# ═══════════════════════════════════════════════════

func _initialize_problem() -> void:
	# Random start in search space
	current_solution = Vector2(
		randf_range(-search_space_size * 0.8, search_space_size * 0.8),
		randf_range(-search_space_size * 0.8, search_space_size * 0.8)
	)
	current_energy = _evaluate(current_solution)
	best_solution = current_solution
	best_energy = current_energy

	current_temperature = initial_temperature
	effective_cooling_rate = cooling_rate
	current_iteration = 0
	equilibrium_count = 0

	total_moves = 0
	accepted_moves = 0
	rejected_moves = 0
	improvements = 0
	steps_since_improvement = 0
	basin_hops_performed = 0

	_recent_accepts.clear()
	_prob_bins.fill(0)

	_trail_positions.clear()
	_trail_energies.clear()
	_trail_was_accepted.clear()
	_hop_positions.clear()

	_add_trail_point(true)
	_update_marker_positions()


func _start_optimization() -> void:
	if _is_running:
		return
	_is_running = true
	_is_complete = false


func _reset_optimization() -> void:
	_is_running = false
	_is_complete = false

	# Clear hop markers
	for child in _hop_parent.get_children():
		child.queue_free()

	_initialize_problem()
	_compute_height_range()
	_update_surface()
	_update_trail()
	_update_prob_bars()
	_update_labels()

	call_deferred("_start_optimization")


# ═══════════════════════════════════════════════════
#  SIMULATION LOOP
# ═══════════════════════════════════════════════════

func _process(delta: float) -> void:
	if not _is_running or _is_complete:
		return

	_step_timer += delta
	if _step_timer < step_interval:
		return
	_step_timer -= step_interval

	_perform_annealing_step()

	# Check termination
	if current_temperature <= final_temperature or current_iteration >= max_iterations:
		_is_running = false
		_is_complete = true

	_update_trail()
	_update_labels()

	# Update prob bars less frequently for performance
	if current_iteration % 10 == 0:
		_update_prob_bars()


func _perform_annealing_step() -> void:
	# Generate neighbor
	var neighbor = _generate_neighbor()
	var neighbor_energy = _evaluate(neighbor)
	var delta_energy = neighbor_energy - current_energy

	var accept = false

	if delta_energy < 0:
		accept = true
		improvements += 1
		steps_since_improvement = 0
	else:
		var probability = exp(-delta_energy / maxf(current_temperature, 0.0001))
		_record_probability(delta_energy)
		accept = randf() < probability
		steps_since_improvement += 1

	total_moves += 1

	# Track for adaptive cooling
	_recent_accepts.append(accept)
	if _recent_accepts.size() > adaptation_window:
		_recent_accepts.pop_front()

	if accept:
		current_solution = neighbor
		current_energy = neighbor_energy
		accepted_moves += 1

		if current_energy < best_energy:
			best_solution = current_solution
			best_energy = current_energy

		_add_trail_point(true)
		_update_marker_positions()
	else:
		rejected_moves += 1
		_add_trail_point(false)

	# Update equilibrium / temperature
	equilibrium_count += 1
	if equilibrium_count >= equilibrium_steps:
		_update_temperature()
		equilibrium_count = 0

	# Basin-hopping check
	if basin_hop_enabled and steps_since_improvement >= stagnation_threshold:
		if basin_hops_performed < max_hops:
			_perform_basin_hop()

	current_iteration += 1


func _generate_neighbor() -> Vector2:
	# Perturbation scales with temperature
	var strength = current_temperature / initial_temperature * search_space_size * 0.3
	var neighbor = Vector2(
		current_solution.x + randf_range(-strength, strength),
		current_solution.y + randf_range(-strength, strength)
	)
	neighbor.x = clampf(neighbor.x, -search_space_size, search_space_size)
	neighbor.y = clampf(neighbor.y, -search_space_size, search_space_size)
	return neighbor


func _update_temperature() -> void:
	if adaptive_enabled:
		_adaptive_temperature_update()
	else:
		match cooling_schedule:
			"exponential":
				current_temperature *= cooling_rate
			"linear":
				var progress = float(current_iteration) / float(max_iterations)
				current_temperature = initial_temperature * (1.0 - progress)
			"logarithmic":
				current_temperature = initial_temperature / log(2.0 + current_iteration)
			_:
				current_temperature *= cooling_rate


# ═══════════════════════════════════════════════════
#  ADAPTIVE COOLING
# ═══════════════════════════════════════════════════

func _adaptive_temperature_update() -> void:
	var window_rate = _get_window_acceptance_rate()

	# If accepting too many moves -> cool faster (reduce rate)
	# If accepting too few moves -> cool slower (increase rate)
	if window_rate > target_acceptance_rate + 0.05:
		effective_cooling_rate = maxf(effective_cooling_rate - rate_adjustment_speed, 0.8)
	elif window_rate < target_acceptance_rate - 0.05:
		effective_cooling_rate = minf(effective_cooling_rate + rate_adjustment_speed, 0.999)
	# Otherwise hold steady

	current_temperature *= effective_cooling_rate


func _get_window_acceptance_rate() -> float:
	if _recent_accepts.is_empty():
		return 1.0
	var count = 0
	for a in _recent_accepts:
		if a:
			count += 1
	return float(count) / float(_recent_accepts.size())


# ═══════════════════════════════════════════════════
#  BASIN-HOPPING
# ═══════════════════════════════════════════════════

func _perform_basin_hop() -> void:
	# Large random perturbation to escape current basin
	var hop_target = Vector2(
		current_solution.x + randf_range(-hop_strength, hop_strength),
		current_solution.y + randf_range(-hop_strength, hop_strength)
	)
	hop_target.x = clampf(hop_target.x, -search_space_size, search_space_size)
	hop_target.y = clampf(hop_target.y, -search_space_size, search_space_size)

	# Mark the hop origin
	_add_hop_marker(current_solution)

	# Jump to new position
	current_solution = hop_target
	current_energy = _evaluate(current_solution)

	# Briefly reheat to explore the new basin
	current_temperature = maxf(current_temperature, initial_temperature * 0.3)

	steps_since_improvement = 0
	basin_hops_performed += 1

	_add_trail_point(true)
	_update_marker_positions()


# ═══════════════════════════════════════════════════
#  GRID CONFIG
# ═══════════════════════════════════════════════════

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("initial_temperature"):
		initial_temperature = float(config_data["initial_temperature"])
	if config_data.has("cooling_rate"):
		cooling_rate = float(config_data["cooling_rate"])
		effective_cooling_rate = cooling_rate
	if config_data.has("cooling_schedule"):
		cooling_schedule = str(config_data["cooling_schedule"])
	if config_data.has("max_iterations"):
		max_iterations = int(config_data["max_iterations"])
	if config_data.has("equilibrium_steps"):
		equilibrium_steps = int(config_data["equilibrium_steps"])
	if config_data.has("problem_type"):
		problem_type = str(config_data["problem_type"])
	if config_data.has("search_space_size"):
		search_space_size = float(config_data["search_space_size"])
	if config_data.has("adaptive_enabled"):
		adaptive_enabled = bool(config_data["adaptive_enabled"])
	if config_data.has("target_acceptance_rate"):
		target_acceptance_rate = float(config_data["target_acceptance_rate"])
	if config_data.has("basin_hop_enabled"):
		basin_hop_enabled = bool(config_data["basin_hop_enabled"])
	if config_data.has("hop_strength"):
		hop_strength = float(config_data["hop_strength"])
	if config_data.has("step_interval"):
		step_interval = float(config_data["step_interval"])
	if config_data.has("surface_size"):
		surface_size = float(config_data["surface_size"])
	if config_data.has("height_scale"):
		height_scale = float(config_data["height_scale"])

	# ── housing ──
	if config_data.has("finish"):
		finish = str(config_data["finish"])
	if config_data.has("wear"):
		wear = float(config_data["wear"])
	if config_data.has("unit_code"):
		unit_code = str(config_data["unit_code"])
	if config_data.has("deck_height"):
		deck_height = float(config_data["deck_height"])
	if config_data.has("show_console"):
		show_console = bool(config_data["show_console"])
	if config_data.has("prob_gauge_depth"):
		prob_gauge_depth = float(config_data["prob_gauge_depth"])

	# Re-initialize with new settings
	_is_running = false
	_is_complete = false
	for child in _hop_parent.get_children():
		child.queue_free()
	if _field != null and is_instance_valid(_field):
		_field.position = Vector3(0, deck_height if show_console else 0.0, 0)

	# The rail ring is cut from surface_size and height_scale, so a config-driven
	# resize has to re-cut it — otherwise the body no longer matches its field.
	if _console != null and is_instance_valid(_console):
		remove_child(_console)
		_console.queue_free()
		_console = null
	_temp_ember_mat = null
	if _control_panel != null and is_instance_valid(_control_panel):
		remove_child(_control_panel)
		_control_panel.queue_free()
		_control_panel = null
	_temp_slider = null
	_rate_slider = null
	_create_vr_controls()
	_create_console()

	_initialize_problem()
	_compute_height_range()
	_update_surface()
	_update_prob_bars()
	_update_labels()
	call_deferred("_start_optimization")


func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
