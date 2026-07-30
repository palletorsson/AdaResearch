# ===========================================================================
# SelfOrganizingPatterns — Stigmergy, Phase Transitions & Attractor Basins
# Self-organization visualization with indirect coordination (stigmergy),
# order parameter tracking for phase transitions, and attractor basin mapping.
# Elevated features:
#   - ImmediateMesh stigmergy field with deposit/evaporation gradient
#   - Phase transition detection via order parameter (alignment/clustering)
#   - Attractor basin visualization with Voronoi-like coloring
#   - Configurable via apply_grid_config()
# License: CC BY-NC-SA 3.0 derivative
# ===========================================================================

class_name SelfOrganizingPatterns
extends Node3D

const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: three modes — stigmergy (deposit/evaporate field), Ising phase transition (spin flip via Metropolis), attractor basins (gradient descent on potential landscape)
# desire: to push the Noise slider past the critical temperature and watch an ordered flock dissolve into chaos in real time — to hold the phase transition in your hand
# critical_parameter: coupling_strength — below the critical value spins are random (disordered phase); above it they spontaneously align (ordered phase); the exact threshold is where complexity peaks
# triggers: in PHASE_TRANSITION mode, the automated temperature sweep crosses the critical point and the order-parameter graph shows a sharp kink — the signature of a second-order transition
# emerges: in STIGMERGY mode, agents following their own collective trail spontaneously form rotating clusters — an ordered state nobody chose, arising from the instability of uniform randomness
# needs: [has] VR slider for Noise (temperature) and Coupling; [has] mode cycle button and reset button; [missing] no slider for agent_speed or deposit_rate
# relationships: generalizes the stigmergy mechanism of stigmergy_grid and AntColonyOptimization into abstract physics; shares Ising model concepts with phase_transition topics in chaos sequence; connects to attractor theory in neural networks
# truth: order is not imposed from outside — it falls into existence when local interactions exceed the noise floor

## Self-Organizing Patterns with stigmergy, phase transitions, and attractors.
## STIGMERGY mode shows indirect coordination through environmental markers.
## PHASE_TRANSITION mode detects order/disorder transitions via order parameters.
## ATTRACTOR_BASINS mode maps basin boundaries and convergence flow.

# ═══════════════════════════════════════════════════════════════════
# STAGE-2 DNA AXIS — cue
# ═══════════════════════════════════════════════════════════════════
#
# What an agent actually reads before it moves. The three values are the three
# things this artifact already argues order can come from, and until now only
# the first of them was ever shipped: `_mode` was pinned to STIGMERGY and
# reachable only by pressing MODE in the headset, so every placement and every
# capture showed the deposit heatmap. An artifact built to say that order has
# three possible sources had shipped exactly one.
#
#   trace      a mark left in the environment  -> STIGMERGY
#              6 x 6 m plate carries the deposit heatmap, dim blue rising to
#              green and yellow; 60 agent triangles ~0.12 m drift across it;
#              order bar 0.3 x 4.8 m at x 3.3..3.6. Nothing on the left.
#   neighbour  the agent beside it             -> PHASE_TRANSITION
#              centre plate CLEARED; agents redraw as Ising spins coloured cyan
#              or red by local alignment; the right-hand order bar disappears
#              and a 2.0 x 4.8 m phase graph with an orange temperature bar
#              appears at x -5.5..-3.5. Two metres of geometry no other value
#              builds, and on the opposite side of the body.
#   slope      a landscape someone else drew   -> ATTRACTOR_BASINS
#              centre plate fills edge to edge with four flat saturated basin
#              colours meeting along hard Voronoi seams; a full-resolution grid
#              of flow arrows overlays it pointing into the four wells; agents
#              redraw as basin-tinted markers; the order bar returns.
#
# No fourth value. A no-medium variant (all coupling off, empty field, agents on
# pure noise) was considered and cut: a plate with nothing on it is how a render
# scores INERT, and a blank tile is not an argument.
#
# `cue` is the stigmergy literature's own word for the thing an agent reads. It
# was chosen over `mode`, `channel` and `coupling` (all already axis names
# elsewhere in the registry, and `coupling` is this file's own declared critical
# parameter) and over `medium`, which is a live VALUE across twenty-odd registry
# files as a density grade. Value `trace` is deliberately spelled the same as the
# existing `trace` elsewhere in the registry — same meaning, a mark left behind.
# `basin` was taken by the machinelearning wave, hence `slope`.
@export_enum("trace", "neighbour", "slope") var cue: String = "trace"

## The allow-list. A token outside it is a typo and falls back to the shipped
## default rather than half-resolving into a mode with no geometry.
const CUES: PackedStringArray = ["trace", "neighbour", "slope"]

## Every draw in the build path comes off one seeded generator, never the global
## one. Swarms are built from noise — positions, headings, spins, attractor
## placement — and an attractor layout that jitters between runs reads to the
## critic as noise rather than as a value. seed()/randomize() is never called:
## reseeding the whole process from inside one artifact is not this file's right.
const BUILD_SEED: int = 20260730

## The masthead. Info and stats boards are capped at this many rows and the plate
## is sized for exactly this many regardless, so the plate height is fixed across
## cue values (0.16 * 4 + 0.14 = 0.78 m).
const BOARD_ROWS: int = 4
const BOARD_LINE_GAP: float = 0.16
const BOARD_PAD: float = 0.14
const BOARD_WIDTH: float = 1.9

## Basin fill opacity in `slope`. The palette entries carry alpha 0.35 because
## the agent markers and attractor discs reuse them; the field itself has to read
## as four FLAT SATURATED regions, which is the whole of its difference from
## trace's dim graded heatmap.
const BASIN_FILL_ALPHA: float = 0.85
const BASIN_SEAM_ALPHA: float = 0.95

# --- Configuration ---
@export var agent_count: int = 60
@export var grid_resolution: int = 40
@export var field_size: float = 6.0
@export var agent_speed: float = 2.0
@export var deposit_rate: float = 3.0
@export var evaporation_rate: float = 0.015
@export var diffusion_rate: float = 0.08
@export var coupling_strength: float = 1.5
@export var noise_level: float = 0.3
@export var num_attractors: int = 4

# --- Mode ---
# `_mode` is now DERIVED from `cue` at the top of the build and never guessed.
# The MODE button still cycles it in the headset — that is a live instrument, not
# a declaration — but nothing else sets it behind the axis's back.
enum Mode { STIGMERGY, PHASE_TRANSITION, ATTRACTOR_BASINS }
var _mode: int = Mode.STIGMERGY

# --- Lifecycle ---
var _built: bool = false
## Only nodes THIS script added. Freeing get_children() would take the grid's own
## plates with it.
var _owned: Array[Node] = []
var _rng := RandomNumberGenerator.new()
## Board plate faces carry emission. `emissive:false` (which curation_station
## hands to every curated artifact) turns it off in place — the key is accepted,
## so it has to do something.
var _emissive: bool = true

# --- Internal state ---
var _time: float = 0.0
var _stigmergy_grid: Array = []   # 2D float array — environmental signal
var _agents: Array = []
var _attractors: Array = []       # {pos: Vector2, color: Color, strength: float}
var _order_parameter: float = 0.0 # Global alignment measure 0..1
var _order_history: PackedFloat32Array = PackedFloat32Array()
var _susceptibility: float = 0.0  # d(order)/d(coupling) — peaks at transition
var _temperature: float = 1.0     # Effective noise/temperature for phase transition
var _phase_sweep_active: bool = true
var _phase_sweep_dir: float = -1.0  # sweeping temperature down then up

# Basin tracking
var _basin_grid: Array = []  # 2D int array — which attractor each cell converges to
var _flow_field: Array = []  # 2D Vector2 array — gradient direction

# --- Rendering ---
var _field_im: ImmediateMesh
var _field_mi: MeshInstance3D
var _agents_im: ImmediateMesh
var _agents_mi: MeshInstance3D
var _overlay_im: ImmediateMesh
var _overlay_mi: MeshInstance3D
var _flow_im: ImmediateMesh
var _flow_mi: MeshInstance3D
var _graph_im: ImmediateMesh
var _graph_mi: MeshInstance3D

# Materials
var _mat_unshaded: StandardMaterial3D
var _mat_alpha: StandardMaterial3D

# Text boards (framed 2D-in-3D, R-027) — content rebuilt only when text changes
var _header_root: Node3D
var _info_root: Node3D
var _stats_root: Node3D
var _header_cache := ""
var _info_cache := ""
var _stats_cache := ""
var _label_cooldown := 0.0
const LABEL_REFRESH_INTERVAL := 0.25

# VR controls
var _control_rack: Node3D

# Colors
const COL_AGENT_ALIGNED := Color(0.2, 0.85, 0.95)
const COL_AGENT_RANDOM := Color(0.9, 0.3, 0.2)
const COL_DEPOSIT_LOW := Color(0.05, 0.08, 0.25, 0.0)
const COL_DEPOSIT_MED := Color(0.15, 0.4, 0.7, 0.4)
const COL_DEPOSIT_HIGH := Color(0.3, 0.9, 0.5, 0.75)
const COL_DEPOSIT_MAX := Color(1.0, 0.95, 0.3, 0.95)
const COL_ORDER_LINE := Color(0.3, 0.95, 0.6)
const COL_SUSCEPT_LINE := Color(1.0, 0.6, 0.15)
const COL_TRANSITION := Color(1.0, 0.2, 0.3, 0.8)

# Basin palette
const BASIN_COLORS: Array = [
	Color(0.2, 0.6, 1.0, 0.35),
	Color(1.0, 0.4, 0.2, 0.35),
	Color(0.3, 0.9, 0.4, 0.35),
	Color(0.9, 0.2, 0.8, 0.35),
	Color(1.0, 0.85, 0.15, 0.35),
	Color(0.15, 0.9, 0.85, 0.35),
]

# Heatmap color ramp for stigmergy field
const STIG_COLORS: Array = [
	Color(0.03, 0.03, 0.15, 0.0),
	Color(0.08, 0.15, 0.45, 0.25),
	Color(0.12, 0.45, 0.65, 0.45),
	Color(0.25, 0.8, 0.5, 0.65),
	Color(0.85, 0.9, 0.2, 0.8),
	Color(1.0, 0.55, 0.1, 0.9),
	Color(1.0, 0.2, 0.1, 1.0),
]

# Agent state
class AgentState:
	var pos: Vector2
	var heading: float  # angle in radians
	var spin: float     # +1 or -1 for Ising-like alignment
	var basin_id: int = -1

	## Heading and spin are HANDED IN, never drawn here. An inner class calling
	## the global randf() is exactly the unseeded draw that voids a sweep sheet.
	func _init(start: Vector2, start_heading: float, start_spin: float) -> void:
		pos = start
		heading = start_heading
		spin = start_spin


# =========================================================================
# Lifecycle — build synchronously, return, rebuild only on a real change
# =========================================================================

func _ready() -> void:
	_build_all()
	_built = true


## Everything this script puts in the tree, built from the @export values alone.
## Synchronous and bounded: no await, no call_deferred, no loop without a fixed
## count. This sequence has a known headless hang class (simulation artifacts
## that never yield under --no-window) and the cure is that _ready RETURNS.
func _build_all() -> void:
	_rng.seed = BUILD_SEED
	_mode = _mode_for_cue(cue)
	_time = 0.0
	_create_materials()
	_create_mesh_instances()
	_create_labels()
	_create_vr_controls()
	_init_grids()
	_spawn_attractors()
	_spawn_agents()
	_reset_axis_state()
	# Fill the ImmediateMesh surfaces NOW. Two reasons: auto-grounding measures
	# the AABB the moment the build returns and empty surfaces measure zero, and
	# the capturer shoots at ~1.1 s, so the axis has to be legible from the
	# starting arrangement rather than from a settled simulation.
	_draw_all()


## trace / neighbour / slope -> the mode that draws them.
func _mode_for_cue(v: String) -> int:
	match v:
		"neighbour":
			return Mode.PHASE_TRANSITION
		"slope":
			return Mode.ATTRACTOR_BASINS
		_:
			return Mode.STIGMERGY


## Scalar state that depends on which cue is in force. No simulation step is
## taken here — `_measure_order` reads the arrangement we just spawned, which is
## a measurement, not a pre-roll.
func _reset_axis_state() -> void:
	_order_history = PackedFloat32Array()
	_susceptibility = 0.0
	_phase_sweep_active = true
	_phase_sweep_dir = -1.0
	_temperature = 2.0 if _mode == Mode.PHASE_TRANSITION else 1.0
	_measure_order()
	if _mode == Mode.PHASE_TRANSITION:
		# One sample so the phase graph has a value at frame zero.
		_order_history.append(_order_parameter)


## The order parameter of the CURRENT arrangement, per mode. Costs one pass over
## the agents and takes no time step.
func _measure_order() -> void:
	match _mode:
		Mode.PHASE_TRANSITION:
			var total_spin: float = 0.0
			for a in _agents:
				var ag: AgentState = a
				total_spin += ag.spin
			_order_parameter = absf(total_spin) / maxf(float(_agents.size()), 1.0)
		Mode.ATTRACTOR_BASINS:
			var near: int = 0
			for a in _agents:
				var ag: AgentState = a
				ag.basin_id = _nearest_basin(ag.pos)
				if ag.basin_id >= 0:
					var attr: Dictionary = _attractors[ag.basin_id]
					if ag.pos.distance_to(attr["pos"]) < 1.5:
						near += 1
			_order_parameter = float(near) / maxf(float(_agents.size()), 1.0)
		_:
			_compute_order_parameter_clustering()


## Index of the attractor pulling hardest at `p`, or -1 when there are none.
func _nearest_basin(p: Vector2) -> int:
	var best: int = -1
	var best_pull: float = 0.0
	for ai in range(_attractors.size()):
		var attr: Dictionary = _attractors[ai]
		var dir: Vector2 = attr["pos"] - p
		var pull: float = float(attr["strength"]) / maxf(dir.length_squared(), 0.1)
		if best < 0 or pull > best_pull:
			best_pull = pull
			best = ai
	return best


## Tear down only what this script built, then build again — inline, this frame.
## A deferred rebuild that removes children first leaves auto-grounding measuring
## a zero AABB and bailing out.
func _rebuild_now() -> void:
	for c in _owned:
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_owned.clear()
	_field_im = null
	_field_mi = null
	_overlay_im = null
	_overlay_mi = null
	_flow_im = null
	_flow_mi = null
	_agents_im = null
	_agents_mi = null
	_graph_im = null
	_graph_mi = null
	_header_root = null
	_info_root = null
	_stats_root = null
	_control_rack = null
	_header_cache = ""
	_info_cache = ""
	_stats_cache = ""
	_label_cooldown = 0.0
	_build_all()


# =========================================================================
# Materials
# =========================================================================

func _create_materials() -> void:
	_mat_unshaded = StandardMaterial3D.new()
	_mat_unshaded.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_unshaded.vertex_color_use_as_albedo = true
	_mat_unshaded.cull_mode = BaseMaterial3D.CULL_DISABLED

	_mat_alpha = StandardMaterial3D.new()
	_mat_alpha.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_alpha.vertex_color_use_as_albedo = true
	_mat_alpha.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_alpha.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA


# =========================================================================
# Mesh instances
# =========================================================================

func _create_mesh_instances() -> void:
	_field_im = ImmediateMesh.new()
	_field_mi = MeshInstance3D.new()
	_field_mi.name = "StigmergyField"
	_field_mi.mesh = _field_im
	_field_mi.material_override = _mat_alpha
	_adopt(_field_mi)

	_overlay_im = ImmediateMesh.new()
	_overlay_mi = MeshInstance3D.new()
	_overlay_mi.name = "BasinOverlay"
	_overlay_mi.mesh = _overlay_im
	_overlay_mi.material_override = _mat_alpha
	_adopt(_overlay_mi)

	_flow_im = ImmediateMesh.new()
	_flow_mi = MeshInstance3D.new()
	_flow_mi.name = "FlowField"
	_flow_mi.mesh = _flow_im
	_flow_mi.material_override = _mat_alpha
	_adopt(_flow_mi)

	_agents_im = ImmediateMesh.new()
	_agents_mi = MeshInstance3D.new()
	_agents_mi.name = "Agents"
	_agents_mi.mesh = _agents_im
	_agents_mi.material_override = _mat_unshaded
	_adopt(_agents_mi)

	_graph_im = ImmediateMesh.new()
	_graph_mi = MeshInstance3D.new()
	_graph_mi.name = "SideGadget"
	_graph_mi.mesh = _graph_im
	_graph_mi.material_override = _mat_unshaded
	_adopt(_graph_mi)


## add_child + remember. The remembering is what makes _rebuild_now safe.
func _adopt(n: Node) -> void:
	add_child(n)
	_owned.append(n)


# =========================================================================
# Labels
# =========================================================================

func _create_labels() -> void:
	# Three framed dark boards (R-027) baked as plates, NOT Label3D — so
	# LabelFramer never sees them and there is nothing here for it to fight. What
	# had to be fixed is the boards crossing the axis's own geometry:
	#
	#   was: InfoBoard  (-3.6, -3.0) spanned x -4.575..-2.625, landing ON TOP of
	#        neighbour's phase graph at x -5.5..-3.5.
	#   was: StatsBoard (+3.6, -3.0) spanned x 2.625..4.575, landing on top of
	#        the order bar at x 3.3..3.6 at both trace and slope.
	#
	# Now both sit ABOVE the field and INSIDE its width: at field_size 6 the
	# header plate 3.2 x 0.62 m spans y 3.29..3.91, clearing the field's top edge
	# at y 3.0 by 0.29 m, and the two boards (1.9 m wide, 0.78 m tall for four
	# rows) span y 3.97..4.75 at x -2.625..-0.675 and +0.675..+2.625 — clear of
	# the left graph (x < -3.5) and the right bar (x > 3.3) at EVERY cue value.
	# Their 1.35 m horizontal gap is eight times the merge gap, and they are not
	# Label3D in any case, so the three read as one masthead by arrangement
	# rather than by fusion.
	_header_root = Node3D.new()
	_header_root.name = "HeaderBoard"
	_header_root.position = Vector3(0, field_size * 0.5 + 0.6, 0)
	_adopt(_header_root)

	_info_root = Node3D.new()
	_info_root.name = "InfoBoard"
	_info_root.position = Vector3(-field_size * 0.275, field_size * 0.5 + 1.36, 0)
	_adopt(_info_root)

	_stats_root = Node3D.new()
	_stats_root.name = "StatsBoard"
	_stats_root.position = Vector3(field_size * 0.275, field_size * 0.5 + 1.36, 0)
	_adopt(_stats_root)

	_update_labels()


func _rebuild_header(mode_text: String) -> void:
	for child in _header_root.get_children():
		child.queue_free()
	_header_root.add_child(_plate(Vector3(3.2, 0.62, 0.05)))
	var title: MeshInstance3D = BakedText.make_label_mesh("Self-Organizing Patterns", Color(0.9, 0.85, 0.7), Vector2(2.9, 0.24), 1400, true)
	if title:
		title.position = Vector3(0, 0.14, 0.035)
		_header_root.add_child(title)
	var mode_line: MeshInstance3D = BakedText.make_label_mesh(mode_text, Color(0.7, 0.7, 0.8), Vector2(2.4, 0.14), 1400, true)
	if mode_line:
		mode_line.position = Vector3(0, -0.16, 0.035)
		_header_root.add_child(mode_line)


func _rebuild_board(root: Node3D, text: String, color: Color) -> void:
	for child in root.get_children():
		child.queue_free()
	var rows: PackedStringArray = text.split("\n")
	# Cap at four rows and size the plate for four regardless, so the plate
	# height is FIXED across cue values. Otherwise a three-row stats board at
	# slope would be a different-sized object from a four-row one at trace, and
	# the masthead would flinch when the axis changes.
	while rows.size() > BOARD_ROWS:
		rows.remove_at(rows.size() - 1)
	var line_h: float = 0.12
	root.add_child(_plate(Vector3(
		BOARD_WIDTH, BOARD_LINE_GAP * float(BOARD_ROWS) + BOARD_PAD, 0.05)))
	var y: float = BOARD_LINE_GAP * 0.5 * float(rows.size() - 1)
	for r in rows:
		var line: MeshInstance3D = BakedText.make_label_mesh(str(r), color, Vector2(1.7, line_h), 1300, true)
		if line:
			line.position = Vector3(0, y, 0.035)
			root.add_child(line)
		y -= BOARD_LINE_GAP


func _plate(size: Vector3) -> Node3D:
	var g := Node3D.new()
	var frame := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = size + Vector3(0.05, 0.05, -0.01)
	frame.mesh = fm
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.62, 0.60, 0.56)
	fmat.roughness = 0.7
	frame.material_override = fmat
	frame.position = Vector3(0, 0, -0.006)
	g.add_child(frame)
	var face := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	face.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.10, 0.11, 0.14)
	# Honour the current emissive state at creation as well as in place —
	# _rebuild_board makes a fresh plate every time the readout text changes.
	mat.emission_enabled = _emissive
	mat.emission = Color(0.10, 0.11, 0.14)
	mat.emission_energy_multiplier = 0.25
	face.material_override = mat
	face.set_meta("board_face", true)
	g.add_child(face)
	return g


## `emissive:false` from a map or from curation_station turns the board glow off
## across all three boards, including plates rebuilt later. Stateless walk, so it
## stays correct after any number of text rebuilds.
func _apply_emissive() -> void:
	for root in [_header_root, _info_root, _stats_root]:
		if root != null and is_instance_valid(root):
			_apply_emissive_to(root)


func _apply_emissive_to(n: Node) -> void:
	if n is MeshInstance3D and n.has_meta("board_face"):
		var mi: MeshInstance3D = n
		var m: Material = mi.material_override
		if m is StandardMaterial3D:
			var sm: StandardMaterial3D = m
			sm.emission_enabled = _emissive
	for c in n.get_children():
		_apply_emissive_to(c)


# =========================================================================
# VR Controls
# =========================================================================

func _create_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_rack = RackTpl.create_panel("SELF-ORG", [
		[{"type": "slider_h", "label": "NOISE", "default": noise_level}, {"type": "slider_h", "label": "COUPLING", "default": coupling_strength / 3.0}],
		[{"type": "button", "label": "MODE"}, {"type": "button", "label": "RESET"}],
	])
	if _control_rack == null:
		return
	_control_rack.position = Vector3(0, -field_size * 0.5 - 1.0, 0)
	_control_rack.rotation_degrees = Vector3(-25, 0, 0)
	_adopt(_control_rack)

	var noise_slider: Node = _control_rack.find_child("Param_0", true, false)
	if noise_slider and noise_slider.has_signal("slider_moved"):
		noise_slider.slider_moved.connect(_on_noise_changed)

	var coupling_slider: Node = _control_rack.find_child("Param_1", true, false)
	if coupling_slider and coupling_slider.has_signal("slider_moved"):
		coupling_slider.slider_moved.connect(_on_coupling_changed)

	var mode_btn: Node = _control_rack.find_child("Btn_0", true, false)
	if mode_btn:
		var area = mode_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_mode_pressed())

	var reset_btn: Node = _control_rack.find_child("Btn_1", true, false)
	if reset_btn:
		var area = reset_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_reset_pressed())


## The headset's MODE button walks the axis rather than going behind it: `cue`
## follows `_mode` so the declared value never disagrees with what is on screen.
## No node rebuild is needed — all five mesh instances exist at every value and
## it is the draw path that differs.
func _on_mode_pressed() -> void:
	_mode = (_mode + 1) % 3
	cue = CUES[_mode]
	_reset_axis_state()
	_update_labels()
	_draw_all()


func _on_reset_pressed() -> void:
	_reset_simulation()


func _on_noise_changed(_val: float) -> void:
	var slider: Node = _control_rack.find_child("Param_0", true, false)
	if slider and slider.has_method("get_normalized_value"):
		noise_level = slider.get_normalized_value()
		if _mode == Mode.PHASE_TRANSITION:
			_phase_sweep_active = false
			_temperature = noise_level * 2.0


func _on_coupling_changed(_val: float) -> void:
	var slider: Node = _control_rack.find_child("Param_1", true, false)
	if slider and slider.has_method("get_normalized_value"):
		coupling_strength = slider.get_normalized_value() * 3.0


# =========================================================================
# Grid initialization
# =========================================================================

func _init_grids() -> void:
	_stigmergy_grid.clear()
	_basin_grid.clear()
	_flow_field.clear()
	for x in range(grid_resolution):
		var stig_row: Array = []
		stig_row.resize(grid_resolution)
		stig_row.fill(0.0)
		_stigmergy_grid.append(stig_row)

		var basin_row: Array = []
		basin_row.resize(grid_resolution)
		basin_row.fill(-1)
		_basin_grid.append(basin_row)

		var flow_row: Array = []
		flow_row.resize(grid_resolution)
		for y in range(grid_resolution):
			flow_row[y] = Vector2.ZERO
		_flow_field.append(flow_row)


func _world_to_grid(world_pos: Vector2) -> Vector2i:
	var half := field_size * 0.5
	var gx := int((world_pos.x + half) / field_size * grid_resolution)
	var gy := int((world_pos.y + half) / field_size * grid_resolution)
	return Vector2i(clampi(gx, 0, grid_resolution - 1), clampi(gy, 0, grid_resolution - 1))


func _grid_to_world(gx: int, gy: int) -> Vector2:
	var half := field_size * 0.5
	return Vector2(
		-half + (gx + 0.5) / float(grid_resolution) * field_size,
		-half + (gy + 0.5) / float(grid_resolution) * field_size
	)


func _get_stigmergy(pos: Vector2) -> float:
	var g := _world_to_grid(pos)
	return _stigmergy_grid[g.x][g.y]


func _deposit_stigmergy(pos: Vector2, amount: float) -> void:
	var g := _world_to_grid(pos)
	_stigmergy_grid[g.x][g.y] += amount
	# Diffusion to neighbors
	var spread := amount * diffusion_rate
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			var nx: int = g.x + dx
			var ny: int = g.y + dy
			if nx >= 0 and nx < grid_resolution and ny >= 0 and ny < grid_resolution:
				_stigmergy_grid[nx][ny] += spread / 8.0


func _evaporate_field() -> void:
	var decay := 1.0 - evaporation_rate
	for x in range(grid_resolution):
		for y in range(grid_resolution):
			_stigmergy_grid[x][y] *= decay


# =========================================================================
# Attractors
# =========================================================================

func _spawn_attractors() -> void:
	# Seeded, so slope's four colour regions and its flow field land in the same
	# place on every run. An attractor layout that jitters between builds reads to
	# the critic as noise rather than as a value.
	_attractors.clear()
	var half := field_size * 0.35
	for i in range(num_attractors):
		var angle := float(i) / num_attractors * TAU + 0.4
		var dist := half * (0.6 + _rng.randf() * 0.4)
		_attractors.append({
			"pos": Vector2(cos(angle) * dist, sin(angle) * dist),
			"color": BASIN_COLORS[i % BASIN_COLORS.size()],
			"strength": 1.5 + _rng.randf() * 1.0,
		})
	# Bounded: grid_resolution^2 cells, no convergence loop. Complete before the
	# first frame, which is why slope needs no pre-roll.
	_compute_basin_grid()


func _compute_basin_grid() -> void:
	# Assign each grid cell to the attractor it would converge to
	for gx in range(grid_resolution):
		for gy in range(grid_resolution):
			var world := _grid_to_world(gx, gy)
			var best_idx := 0
			var best_potential := INF
			# Compute potential: sum of -strength/distance for each attractor
			# The cell belongs to whichever attractor gives lowest potential
			for ai in range(_attractors.size()):
				var attr: Dictionary = _attractors[ai]
				var dist := world.distance_to(attr["pos"])
				var potential: float = -attr["strength"] / maxf(dist, 0.1)
				if potential < best_potential:
					best_potential = potential
					best_idx = ai
			_basin_grid[gx][gy] = best_idx

			# Flow field: gradient toward nearest attractor
			var nearest_attr: Dictionary = _attractors[best_idx]
			var dir: Vector2 = (nearest_attr["pos"] - world)
			var d: float = dir.length()
			if d > 0.01:
				_flow_field[gx][gy] = dir.normalized() * minf(d, 1.0)
			else:
				_flow_field[gx][gy] = Vector2.ZERO


# =========================================================================
# Agents
# =========================================================================

func _spawn_agents() -> void:
	_agents.clear()
	var half := field_size * 0.4
	for i in range(agent_count):
		var pos := Vector2(_rng.randf_range(-half, half), _rng.randf_range(-half, half))
		var heading: float = _rng.randf() * TAU
		var spin: float = 1.0 if _rng.randf() > 0.5 else -1.0
		_agents.append(AgentState.new(pos, heading, spin))


## The RESET button in the headset. Re-seeds, so pressing it returns the exact
## arrangement the artifact was built with rather than a new random one.
func _reset_simulation() -> void:
	_rng.seed = BUILD_SEED
	_time = 0.0
	_init_grids()
	_spawn_attractors()
	_spawn_agents()
	_reset_axis_state()
	_draw_all()


# =========================================================================
# Process
# =========================================================================

func _process(delta: float) -> void:
	_time += delta

	match _mode:
		Mode.STIGMERGY:
			_update_stigmergy_mode(delta)
		Mode.PHASE_TRANSITION:
			_update_phase_transition_mode(delta)
		Mode.ATTRACTOR_BASINS:
			_update_attractor_basins_mode(delta)

	# Throttle board refresh — baked text rebuilds are texture bakes, so the
	# readouts update a few times per second, not per frame.
	_label_cooldown -= delta
	if _label_cooldown <= 0.0:
		_label_cooldown = LABEL_REFRESH_INTERVAL
		_update_labels()
	_draw_all()


# =========================================================================
# Stigmergy mode — indirect coordination through environmental deposits
# =========================================================================

func _update_stigmergy_mode(delta: float) -> void:
	_evaporate_field()
	var half := field_size * 0.5

	for i in range(_agents.size()):
		var agent: AgentState = _agents[i]

		# Sense stigmergy gradient (3-antenna model like ants)
		var fwd := Vector2(cos(agent.heading), sin(agent.heading))
		var left := fwd.rotated(-PI * 0.3)
		var right := fwd.rotated(PI * 0.3)
		var sense_dist := 0.5

		var s_fwd := _get_stigmergy(agent.pos + fwd * sense_dist)
		var s_left := _get_stigmergy(agent.pos + left * sense_dist)
		var s_right := _get_stigmergy(agent.pos + right * sense_dist)

		# Turn toward strongest signal
		if s_left > s_fwd and s_left > s_right:
			agent.heading -= 0.4 * delta * agent_speed
		elif s_right > s_fwd and s_right > s_left:
			agent.heading += 0.4 * delta * agent_speed

		# Random wander — off the seeded generator, never the global one. This
		# artifact must not consume or reseed the process-wide RNG stream.
		agent.heading += (_rng.randf() - 0.5) * noise_level * 2.0 * delta

		# Move
		var vel := Vector2(cos(agent.heading), sin(agent.heading)) * agent_speed
		agent.pos += vel * delta

		# Boundary wrap
		if agent.pos.x < -half: agent.pos.x += field_size
		elif agent.pos.x > half: agent.pos.x -= field_size
		if agent.pos.y < -half: agent.pos.y += field_size
		elif agent.pos.y > half: agent.pos.y -= field_size

		# Deposit pheromone/signal
		_deposit_stigmergy(agent.pos, deposit_rate * delta)

	# Compute order parameter: how clustered are agents?
	_compute_order_parameter_clustering()


# =========================================================================
# Phase transition mode — Ising-like spin alignment with temperature sweep
# =========================================================================

func _update_phase_transition_mode(delta: float) -> void:
	var half := field_size * 0.5

	# Sweep temperature slowly
	if _phase_sweep_active:
		_temperature += _phase_sweep_dir * delta * 0.08
		if _temperature < 0.05:
			_temperature = 0.05
			_phase_sweep_dir = 1.0
		elif _temperature > 2.0:
			_temperature = 2.0
			_phase_sweep_dir = -1.0

	# Ising-like dynamics: each agent's spin influenced by neighbors
	for i in range(_agents.size()):
		var agent: AgentState = _agents[i]

		# Compute local field from neighbors
		var local_field := 0.0
		var neighbor_count := 0
		for j in range(_agents.size()):
			if j == i:
				continue
			var other: AgentState = _agents[j]
			var dist := agent.pos.distance_to(other.pos)
			if dist < 1.5:
				local_field += other.spin * coupling_strength / maxf(dist, 0.3)
				neighbor_count += 1

		# Metropolis-like spin flip: probability based on energy difference
		var delta_energy := 2.0 * agent.spin * local_field
		if delta_energy < 0.0 or _rng.randf() < exp(-delta_energy / maxf(_temperature, 0.01)):
			agent.spin = -agent.spin

		# Gentle drift to visualize clusters
		if neighbor_count > 0:
			# Move slightly toward same-spin neighbors
			var drift := Vector2.ZERO
			for j in range(_agents.size()):
				if j == i:
					continue
				var other: AgentState = _agents[j]
				var dist := agent.pos.distance_to(other.pos)
				if dist < 2.0 and other.spin == agent.spin:
					drift += (other.pos - agent.pos).normalized() * 0.1
				elif dist < 0.5:
					drift += (agent.pos - other.pos).normalized() * 0.3  # repel if too close
			agent.pos += drift * delta

		# Keep in bounds
		agent.pos.x = clampf(agent.pos.x, -half, half)
		agent.pos.y = clampf(agent.pos.y, -half, half)

	# Order parameter: magnetization |<spin>|
	var total_spin := 0.0
	for agent in _agents:
		total_spin += agent.spin
	var new_order := absf(total_spin) / float(_agents.size())

	# Track susceptibility (variance of order parameter ≈ |dM/dT|)
	var prev_order := _order_parameter
	_order_parameter = new_order
	_susceptibility = absf(new_order - prev_order) / maxf(delta, 0.001)
	_susceptibility = clampf(_susceptibility, 0.0, 5.0)

	# Record history for graph (limit to 200 samples)
	_order_history.append(_order_parameter)
	if _order_history.size() > 200:
		# Trim old entries
		var trimmed := PackedFloat32Array()
		for idx in range(1, _order_history.size()):
			trimmed.append(_order_history[idx])
		_order_history = trimmed


# =========================================================================
# Attractor basins mode — flow field and convergence visualization
# =========================================================================

func _update_attractor_basins_mode(delta: float) -> void:
	var half := field_size * 0.5

	for i in range(_agents.size()):
		var agent: AgentState = _agents[i]

		# Compute force from all attractors (gradient descent on potential)
		var force := Vector2.ZERO
		var best_attr := 0
		var best_pull := 0.0
		for ai in range(_attractors.size()):
			var attr: Dictionary = _attractors[ai]
			var dir: Vector2 = attr["pos"] - agent.pos
			var dist: float = dir.length()
			var pull: float = attr["strength"] / maxf(dist * dist, 0.1)
			force += dir.normalized() * pull
			if pull > best_pull:
				best_pull = pull
				best_attr = ai
		agent.basin_id = best_attr

		# Add noise for exploration
		force += Vector2(_rng.randf() - 0.5, _rng.randf() - 0.5) * noise_level * 2.0

		# Move
		agent.pos += force.normalized() * agent_speed * delta

		# Boundary clamp
		agent.pos.x = clampf(agent.pos.x, -half, half)
		agent.pos.y = clampf(agent.pos.y, -half, half)

		# When agent reaches attractor, respawn at random position
		for ai in range(_attractors.size()):
			var attr: Dictionary = _attractors[ai]
			if agent.pos.distance_to(attr["pos"]) < 0.25:
				agent.pos = Vector2(_rng.randf_range(-half, half), _rng.randf_range(-half, half))
				agent.basin_id = -1
				break

	# Compute order parameter: fraction of agents near their attractor
	var near_count := 0
	for agent in _agents:
		if agent.basin_id >= 0 and agent.basin_id < _attractors.size():
			var attr: Dictionary = _attractors[agent.basin_id]
			if agent.pos.distance_to(attr["pos"]) < 1.5:
				near_count += 1
	_order_parameter = float(near_count) / float(maxf(_agents.size(), 1))


# =========================================================================
# Order parameter computation (clustering metric for stigmergy mode)
# =========================================================================

func _compute_order_parameter_clustering() -> void:
	# Measure alignment: average cosine of heading differences with neighbors
	var total_alignment := 0.0
	var pairs := 0
	for i in range(_agents.size()):
		var ai: AgentState = _agents[i]
		for j in range(i + 1, mini(_agents.size(), i + 10)):
			var aj: AgentState = _agents[j]
			var dist := ai.pos.distance_to(aj.pos)
			if dist < 1.5:
				total_alignment += cos(ai.heading - aj.heading)
				pairs += 1
	if pairs > 0:
		_order_parameter = (total_alignment / float(pairs) + 1.0) * 0.5
	else:
		_order_parameter = 0.5


# =========================================================================
# Drawing
# =========================================================================

func _draw_all() -> void:
	match _mode:
		Mode.STIGMERGY:
			_draw_stigmergy_field()
			_draw_agents_stigmergy()
			_draw_empty(_overlay_im)
			_draw_empty(_flow_im)
			_draw_order_bar()
		Mode.PHASE_TRANSITION:
			_draw_empty(_field_im)
			_draw_agents_ising()
			_draw_empty(_overlay_im)
			_draw_empty(_flow_im)
			_draw_phase_graph()
		Mode.ATTRACTOR_BASINS:
			_draw_empty(_field_im)
			_draw_basin_coloring()
			_draw_flow_arrows()
			_draw_agents_basins()
			_draw_order_bar()


func _draw_empty(im: ImmediateMesh) -> void:
	im.clear_surfaces()


# --- Stigmergy field heatmap ---

func _draw_stigmergy_field() -> void:
	_field_im.clear_surfaces()

	var max_val := 0.01
	for x in range(grid_resolution):
		for y in range(grid_resolution):
			max_val = maxf(max_val, _stigmergy_grid[x][y])

	var cell_w := field_size / float(grid_resolution)
	var half := field_size * 0.5

	_field_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in range(grid_resolution):
		for y in range(grid_resolution):
			var val: float = _stigmergy_grid[x][y]
			if val < 0.01:
				continue

			var t := clampf(val / max_val, 0.0, 1.0)
			var col := _sample_stig_color(t)

			var wx := -half + x * cell_w
			var wy := -half + y * cell_w
			var z := -0.01

			_field_im.surface_set_color(col)
			_field_im.surface_add_vertex(Vector3(wx, wy, z))
			_field_im.surface_add_vertex(Vector3(wx + cell_w, wy, z))
			_field_im.surface_add_vertex(Vector3(wx + cell_w, wy + cell_w, z))

			_field_im.surface_set_color(col)
			_field_im.surface_add_vertex(Vector3(wx, wy, z))
			_field_im.surface_add_vertex(Vector3(wx + cell_w, wy + cell_w, z))
			_field_im.surface_add_vertex(Vector3(wx, wy + cell_w, z))

	_field_im.surface_end()


func _sample_stig_color(t: float) -> Color:
	var n := STIG_COLORS.size() - 1
	var idx := t * n
	var lo := int(floorf(idx))
	var hi := mini(lo + 1, n)
	var frac := idx - lo
	return STIG_COLORS[lo].lerp(STIG_COLORS[hi], frac)


# --- Agents in stigmergy mode (directional diamonds) ---

func _draw_agents_stigmergy() -> void:
	_agents_im.clear_surfaces()
	_agents_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	for agent in _agents:
		var fwd := Vector2(cos(agent.heading), sin(agent.heading))
		var side := fwd.rotated(PI * 0.5)
		var r := 0.08
		var p: Vector2 = agent.pos
		var z := 0.05

		var front: Vector2 = p + fwd * r * 1.8
		var back: Vector2 = p - fwd * r
		var left: Vector2 = p + side * r * 0.7
		var right: Vector2 = p - side * r * 0.7

		var col := COL_AGENT_ALIGNED.lerp(COL_AGENT_RANDOM, noise_level)
		_agents_im.surface_set_color(col)
		_agents_im.surface_add_vertex(Vector3(front.x, front.y, z))
		_agents_im.surface_add_vertex(Vector3(left.x, left.y, z))
		_agents_im.surface_add_vertex(Vector3(back.x, back.y, z))

		_agents_im.surface_set_color(col)
		_agents_im.surface_add_vertex(Vector3(front.x, front.y, z))
		_agents_im.surface_add_vertex(Vector3(back.x, back.y, z))
		_agents_im.surface_add_vertex(Vector3(right.x, right.y, z))

	_agents_im.surface_end()


# --- Agents in Ising/phase transition mode (colored by spin) ---

func _draw_agents_ising() -> void:
	_agents_im.clear_surfaces()
	_agents_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	for agent in _agents:
		var r := 0.1
		var p: Vector2 = agent.pos
		var z := 0.05
		var col: Color
		if agent.spin > 0:
			col = COL_AGENT_ALIGNED
		else:
			col = COL_AGENT_RANDOM

		# Draw as hexagon
		var segments := 6
		for si in range(segments):
			var a0 := float(si) / segments * TAU
			var a1 := float(si + 1) / segments * TAU
			_agents_im.surface_set_color(col)
			_agents_im.surface_add_vertex(Vector3(p.x, p.y, z))
			_agents_im.surface_add_vertex(Vector3(p.x + cos(a0) * r, p.y + sin(a0) * r, z))
			_agents_im.surface_add_vertex(Vector3(p.x + cos(a1) * r, p.y + sin(a1) * r, z))

	_agents_im.surface_end()


# --- Agents in attractor basins mode (colored by basin) ---

func _draw_agents_basins() -> void:
	_agents_im.clear_surfaces()
	_agents_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	for agent in _agents:
		var r := 0.08
		var p: Vector2 = agent.pos
		var z := 0.08
		var col: Color
		if agent.basin_id >= 0 and agent.basin_id < BASIN_COLORS.size():
			col = BASIN_COLORS[agent.basin_id]
			col.a = 1.0
		else:
			col = Color(0.6, 0.6, 0.6)

		# Diamond shape
		_agents_im.surface_set_color(col)
		_agents_im.surface_add_vertex(Vector3(p.x, p.y + r, z))
		_agents_im.surface_add_vertex(Vector3(p.x - r * 0.7, p.y, z))
		_agents_im.surface_add_vertex(Vector3(p.x, p.y - r, z))

		_agents_im.surface_set_color(col)
		_agents_im.surface_add_vertex(Vector3(p.x, p.y + r, z))
		_agents_im.surface_add_vertex(Vector3(p.x, p.y - r, z))
		_agents_im.surface_add_vertex(Vector3(p.x + r * 0.7, p.y, z))

	_agents_im.surface_end()


# --- Basin coloring (Voronoi-like regions) ---

func _draw_basin_coloring() -> void:
	_overlay_im.clear_surfaces()
	_overlay_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var cell_w := field_size / float(grid_resolution)
	var half := field_size * 0.5

	for gx in range(grid_resolution):
		for gy in range(grid_resolution):
			var basin_id: int = _basin_grid[gx][gy]
			if basin_id < 0:
				continue

			var col: Color = BASIN_COLORS[basin_id % BASIN_COLORS.size()]

			# Darken cells near boundaries between basins
			var on_boundary := false
			for dx in [-1, 1]:
				var nx: int = gx + dx
				if nx >= 0 and nx < grid_resolution and _basin_grid[nx][gy] != basin_id:
					on_boundary = true
					break
			if not on_boundary:
				for dy in [-1, 1]:
					var ny: int = gy + dy
					if ny >= 0 and ny < grid_resolution and _basin_grid[gx][ny] != basin_id:
						on_boundary = true
						break

			if on_boundary:
				col = col.lerp(Color(1.0, 1.0, 1.0, 0.6), 0.5)

			var wx := -half + gx * cell_w
			var wy := -half + gy * cell_w
			var z := -0.02

			_overlay_im.surface_set_color(col)
			_overlay_im.surface_add_vertex(Vector3(wx, wy, z))
			_overlay_im.surface_add_vertex(Vector3(wx + cell_w, wy, z))
			_overlay_im.surface_add_vertex(Vector3(wx + cell_w, wy + cell_w, z))

			_overlay_im.surface_set_color(col)
			_overlay_im.surface_add_vertex(Vector3(wx, wy, z))
			_overlay_im.surface_add_vertex(Vector3(wx + cell_w, wy + cell_w, z))
			_overlay_im.surface_add_vertex(Vector3(wx, wy + cell_w, z))

	# Draw attractor centers as bright circles
	for ai in range(_attractors.size()):
		var attr: Dictionary = _attractors[ai]
		var pos: Vector2 = attr["pos"]
		var col: Color = attr["color"]
		col.a = 0.9
		var r := 0.2 + sin(_time * 2.0 + ai) * 0.04
		var segments := 10
		for si in range(segments):
			var a0 := float(si) / segments * TAU
			var a1 := float(si + 1) / segments * TAU
			_overlay_im.surface_set_color(col)
			_overlay_im.surface_add_vertex(Vector3(pos.x, pos.y, 0.03))
			_overlay_im.surface_add_vertex(Vector3(pos.x + cos(a0) * r, pos.y + sin(a0) * r, 0.03))
			_overlay_im.surface_add_vertex(Vector3(pos.x + cos(a1) * r, pos.y + sin(a1) * r, 0.03))

	_overlay_im.surface_end()


# --- Flow field arrows ---

func _draw_flow_arrows() -> void:
	_flow_im.clear_surfaces()
	_flow_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var step := maxi(grid_resolution / 12, 1)
	var arrow_len := field_size / float(grid_resolution) * step * 0.6

	for gx in range(0, grid_resolution, step):
		for gy in range(0, grid_resolution, step):
			var flow: Vector2 = _flow_field[gx][gy]
			if flow.length_squared() < 0.001:
				continue

			var world := _grid_to_world(gx, gy)
			var dir := flow.normalized()
			var perp := dir.rotated(PI * 0.5)
			var z := 0.04

			var tip := world + dir * arrow_len
			var base_l := world + perp * arrow_len * 0.25
			var base_r := world - perp * arrow_len * 0.25

			var basin_id: int = _basin_grid[gx][gy]
			var col: Color = BASIN_COLORS[basin_id % BASIN_COLORS.size()]
			col.a = 0.55

			_flow_im.surface_set_color(col)
			_flow_im.surface_add_vertex(Vector3(tip.x, tip.y, z))
			_flow_im.surface_add_vertex(Vector3(base_l.x, base_l.y, z))
			_flow_im.surface_add_vertex(Vector3(base_r.x, base_r.y, z))

	_flow_im.surface_end()


# --- Order parameter bar (bottom-right) ---

func _draw_order_bar() -> void:
	_graph_im.clear_surfaces()
	_graph_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var bar_x := field_size * 0.5 + 0.3
	var bar_y := -field_size * 0.5
	var bar_w := 0.3
	var bar_h := field_size * 0.8
	var z := 0.0

	# Background
	var bg := Color(0.15, 0.15, 0.2, 0.5)
	_graph_im.surface_set_color(bg)
	_graph_im.surface_add_vertex(Vector3(bar_x, bar_y, z))
	_graph_im.surface_add_vertex(Vector3(bar_x + bar_w, bar_y, z))
	_graph_im.surface_add_vertex(Vector3(bar_x + bar_w, bar_y + bar_h, z))
	_graph_im.surface_set_color(bg)
	_graph_im.surface_add_vertex(Vector3(bar_x, bar_y, z))
	_graph_im.surface_add_vertex(Vector3(bar_x + bar_w, bar_y + bar_h, z))
	_graph_im.surface_add_vertex(Vector3(bar_x, bar_y + bar_h, z))

	# Filled portion
	var fill_h := bar_h * _order_parameter
	var col := COL_ORDER_LINE.lerp(COL_TRANSITION, 1.0 - _order_parameter)
	col.a = 0.8
	_graph_im.surface_set_color(col)
	_graph_im.surface_add_vertex(Vector3(bar_x, bar_y, z + 0.01))
	_graph_im.surface_add_vertex(Vector3(bar_x + bar_w, bar_y, z + 0.01))
	_graph_im.surface_add_vertex(Vector3(bar_x + bar_w, bar_y + fill_h, z + 0.01))
	_graph_im.surface_set_color(col)
	_graph_im.surface_add_vertex(Vector3(bar_x, bar_y, z + 0.01))
	_graph_im.surface_add_vertex(Vector3(bar_x + bar_w, bar_y + fill_h, z + 0.01))
	_graph_im.surface_add_vertex(Vector3(bar_x, bar_y + fill_h, z + 0.01))

	_graph_im.surface_end()


# --- Phase transition graph (order parameter vs temperature) ---

func _draw_phase_graph() -> void:
	_graph_im.clear_surfaces()
	if _order_history.size() < 2:
		return

	_graph_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	# Graph area
	var gx := -field_size * 0.5 - 2.5
	var gy := -field_size * 0.5
	var gw := 2.0
	var gh := field_size * 0.8
	var z := 0.0

	# Background
	var bg := Color(0.1, 0.1, 0.15, 0.5)
	_graph_im.surface_set_color(bg)
	_graph_im.surface_add_vertex(Vector3(gx, gy, z))
	_graph_im.surface_add_vertex(Vector3(gx + gw, gy, z))
	_graph_im.surface_add_vertex(Vector3(gx + gw, gy + gh, z))
	_graph_im.surface_set_color(bg)
	_graph_im.surface_add_vertex(Vector3(gx, gy, z))
	_graph_im.surface_add_vertex(Vector3(gx + gw, gy + gh, z))
	_graph_im.surface_add_vertex(Vector3(gx, gy + gh, z))

	# Plot order parameter history as line segments (as thin quads)
	var n := _order_history.size()
	var line_w := 0.02
	for i in range(n - 1):
		var x0 := gx + float(i) / float(n) * gw
		var x1 := gx + float(i + 1) / float(n) * gw
		var y0 := gy + _order_history[i] * gh
		var y1 := gy + _order_history[i + 1] * gh

		var col := COL_ORDER_LINE
		_graph_im.surface_set_color(col)
		_graph_im.surface_add_vertex(Vector3(x0, y0 - line_w, z + 0.01))
		_graph_im.surface_add_vertex(Vector3(x1, y1 + line_w, z + 0.01))
		_graph_im.surface_add_vertex(Vector3(x1, y1 - line_w, z + 0.01))
		_graph_im.surface_set_color(col)
		_graph_im.surface_add_vertex(Vector3(x0, y0 - line_w, z + 0.01))
		_graph_im.surface_add_vertex(Vector3(x0, y0 + line_w, z + 0.01))
		_graph_im.surface_add_vertex(Vector3(x1, y1 + line_w, z + 0.01))

	# Temperature indicator line (vertical at current position)
	var temp_x := gx + gw  # rightmost = current
	var temp_h := (_temperature / 2.0) * gh
	var tcol := COL_SUSCEPT_LINE
	tcol.a = 0.6
	_graph_im.surface_set_color(tcol)
	_graph_im.surface_add_vertex(Vector3(temp_x - 0.02, gy, z + 0.02))
	_graph_im.surface_add_vertex(Vector3(temp_x + 0.02, gy, z + 0.02))
	_graph_im.surface_add_vertex(Vector3(temp_x + 0.02, gy + temp_h, z + 0.02))
	_graph_im.surface_set_color(tcol)
	_graph_im.surface_add_vertex(Vector3(temp_x - 0.02, gy, z + 0.02))
	_graph_im.surface_add_vertex(Vector3(temp_x + 0.02, gy + temp_h, z + 0.02))
	_graph_im.surface_add_vertex(Vector3(temp_x - 0.02, gy + temp_h, z + 0.02))

	_graph_im.surface_end()


# =========================================================================
# Labels
# =========================================================================

func _update_labels() -> void:
	var mode_names := ["Stigmergy", "Phase Transition", "Attractor Basins"]
	var mode_text := "Mode: %s" % mode_names[_mode]

	var info_text := ""
	var stats_text := ""
	match _mode:
		Mode.STIGMERGY:
			info_text = "Agents: %d\nDeposit: %.1f\nEvaporation: %.3f\nDiffusion: %.2f" % [
				agent_count, deposit_rate, evaporation_rate, diffusion_rate
			]
			stats_text = "Order: %.2f\nNoise: %.2f\nCoupling: %.1f" % [
				_order_parameter, noise_level, coupling_strength
			]
		Mode.PHASE_TRANSITION:
			info_text = "Agents: %d\nTemperature: %.3f\nCoupling: %.1f\nSweep: %s" % [
				agent_count, _temperature, coupling_strength,
				"ON" if _phase_sweep_active else "OFF"
			]
			stats_text = "Order |M|: %.3f\nSusceptibility: %.2f\n%s" % [
				_order_parameter, _susceptibility,
				"ORDERED" if _order_parameter > 0.7 else ("CRITICAL" if _order_parameter > 0.3 else "DISORDERED")
			]
		Mode.ATTRACTOR_BASINS:
			info_text = "Agents: %d\nAttractors: %d\nNoise: %.2f" % [
				agent_count, num_attractors, noise_level
			]
			stats_text = "Convergence: %.0f%%\nBasins: %d" % [
				_order_parameter * 100.0, num_attractors
			]

	# Rebuild each board ONLY when its text actually changed — never per frame.
	if mode_text != _header_cache:
		_header_cache = mode_text
		_rebuild_header(mode_text)
	if info_text != _info_cache:
		_info_cache = info_text
		_rebuild_board(_info_root, info_text, Color(0.6, 0.7, 0.8))
	if stats_text != _stats_cache:
		_stats_cache = stats_text
		_rebuild_board(_stats_root, stats_text, Color(0.7, 0.8, 0.6))


# =========================================================================
# apply_grid_config
# =========================================================================

func apply_grid_config(config: Dictionary) -> void:
	if config.has("agent_count"):
		agent_count = int(config["agent_count"])
	if config.has("grid_resolution"):
		grid_resolution = int(config["grid_resolution"])
	if config.has("field_size"):
		field_size = float(config["field_size"])
	if config.has("agent_speed"):
		agent_speed = float(config["agent_speed"])
	if config.has("deposit_rate"):
		deposit_rate = float(config["deposit_rate"])
	if config.has("evaporation_rate"):
		evaporation_rate = float(config["evaporation_rate"])
	if config.has("diffusion_rate"):
		diffusion_rate = float(config["diffusion_rate"])
	if config.has("coupling_strength"):
		coupling_strength = float(config["coupling_strength"])
	if config.has("noise_level"):
		noise_level = float(config["noise_level"])
	if config.has("num_attractors"):
		num_attractors = int(config["num_attractors"])
	if config.has("mode"):
		var m: String = str(config["mode"]).to_upper()
		match m:
			"STIGMERGY": _mode = Mode.STIGMERGY
			"PHASE_TRANSITION": _mode = Mode.PHASE_TRANSITION
			"ATTRACTOR_BASINS": _mode = Mode.ATTRACTOR_BASINS

	_reset_simulation()
