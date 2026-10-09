extends Node3D

# @identity
# essence: θ(t+1) = θ(t) - η∇f(θ) — follow the negative gradient downhill; four variants racing on the same surface
# desire: watch SGD, Momentum, Nesterov, and Adam race down a loss landscape, each with its own strategy
# critical_parameter: learning_rate (η) — too small creeps, too large oscillates, just right converges
# triggers: mode button switches between optimizer race, convergence analysis, and Hessian eigenvalue display; function button cycles loss surfaces
# emerges: Adam's adaptive superiority on most surfaces; saddle points that trap SGD; Nesterov's look-ahead advantage
# needs: VR push button for mode [has], sliders for learning rate, momentum, speed [has]
# relationships: unlocks neural_network_visualization (gradient descent IS the training loop); contrasts 9_3_smart_rockets_vr (gradient-free vs gradient-based optimization)
# truth: learning is descending a landscape you cannot fully see — the gradient is the only local truth available

# Gradient Descent — Optimizer Variants & Convergence Analysis
# Compares SGD, Momentum, Nesterov, Adam on 3D loss surfaces
# Shows convergence behavior, learning rate sensitivity, Hessian structure

const BakedText = preload("res://commons/utils/baked_text_albedo.gd")
# preload, not class_name: headless-safe, and the grammar's G8 is a source-level check.
const HangarKit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")

enum Mode { OPTIMIZERS, CONVERGENCE, HESSIAN }

# ── constants ──────────────────────────────────────────────────────────

const COL_SGD       := Color(0.9, 0.3, 0.3, 1.0)   # red
const COL_MOMENTUM  := Color(0.3, 0.9, 0.3, 1.0)   # green
const COL_NESTEROV  := Color(0.3, 0.5, 0.9, 1.0)   # blue
const COL_ADAM      := Color(0.9, 0.7, 0.1, 1.0)   # gold
const COL_SURFACE   := Color(0.15, 0.12, 0.25, 0.6)
const COL_SURFACE_HI := Color(0.5, 0.3, 0.7, 0.6)
const COL_MINIMUM   := Color(0.2, 0.9, 0.4, 1.0)
const COL_HESSIAN_P := Color(0.1, 0.6, 0.9, 0.9)   # positive eigenvalue
const COL_HESSIAN_N := Color(0.9, 0.2, 0.2, 0.9)   # negative eigenvalue
const COL_GRID      := Color(0.3, 0.3, 0.4, 0.3)
## `axiom` only. The gradient field belongs to no runner, so it may not wear a
## runner's colour — an instrument white-blue, the law having no team.
const COL_FIELD     := Color(0.75, 0.78, 0.92, 1.0)
const COL_LR_COLORS : Array = [
	Color(0.9, 0.2, 0.2), Color(0.2, 0.8, 0.3), Color(0.2, 0.5, 0.9),
	Color(0.9, 0.6, 0.1), Color(0.7, 0.2, 0.8),
]

const SURFACE_RES := 40
const TRAIL_MAX   := 200
const ADAM_EPS     := 1e-8

# ── the basin axis ─────────────────────────────────────────────────────
# The artifact's argument IS the surface, and until now the surface was the one
# thing no map could change: function_preset is an int only apply_grid_config
# could set, so every placement of the sequence's optimisation centrepiece stood
# under a header about landscapes you cannot fully see while showing the single
# flattering case — one minimum, convex, gradient-honest.
#
# The five values are ordered by how badly the local gradient lies:
#   bowl     the gradient is the truth
#   valley   the gradient is true but useless (steepest ≠ toward the minimum)
#   plural   the gradient is true about SOME minimum, and there are four
#   plateau  there is no gradient to have
#   scarp    the gradient is false — a jump the derivative cannot see
const FN_BOWL: int    = 0
const FN_VALLEY: int  = 1
const FN_PLURAL: int  = 2
const FN_PLATEAU: int = 3
const FN_SCARP: int   = 4

const BASINS: PackedStringArray = ["bowl", "valley", "plural", "plateau", "scarp"]

# ── the evidence axis ──────────────────────────────────────────────────
# `basin` settled WHAT is being descended. This settles what the artifact puts
# in the frame as proof that a descent happened at all — and the shipped answer
# was the maximal one, hard-coded: four trails, four markers and four live
# gradient arrows, always, with no way for a map to ask for less or for more.
#
#   result    the four markers where the runners currently stand. No trails, no
#             arrows: an optimizer is a POSITION, the answer with no working.
#   trace     + the paths. Descent becomes a HISTORY — which is where SGD's
#             zig-zag, Momentum's overshoot and Adam's straight run live; none
#             of that is legible from a marker.
#   longhand  + the local gradient at each runner, the quantity every step is
#             actually computed from. THE SHIPPED PICTURE, unchanged.
#   axiom     the instance gives way to the rule: the runners go, and -grad f is
#             sampled over the whole field. Nobody is descending; the law is
#             just standing there, and on `plateau` it visibly has nothing to
#             say while on `scarp` the arrows either side of the face point at
#             each other. This value is where the two axes finally argue.
#
# The word and the four values are the `evidence` family's, taken character for
# character from example_1_7/1_9 and example_2_8/2_9 (which took them in turn
# from koch_curve and box_counting_dimension). The family asks one question of a
# thing in motion: what do you offer as PROOF that a law is moving it?
#
# THE DEFAULT DIFFERS FROM THE FAMILY'S and that is a fact about this artifact
# rather than a drift in the word. The motion demos ship as `result` — a bare
# ball, all their exhibits withheld. This one ships with its working already on
# the table, so its shipped value is `longhand`, and a map that asks the Motion
# 101 demos and this one for `longhand` still gets four answers to one question.
const EVIDENCE: PackedStringArray = ["result", "trace", "longhand", "axiom"]

## `axiom` grid resolution — 8 spans, so 9 x 9 = 81 samples, the same lattice
## _init_hessian() reads the curvature on. One field, sampled two ways.
const FIELD_RES: int = 8

## basin name -> function_preset index. One table so the word and the int cannot
## drift; every route (sweep @export, map token, VR FUNCTION button) goes through it.
const BASIN_PRESET: Dictionary = {
	"bowl": FN_BOWL,
	"valley": FN_VALLEY,
	"plural": FN_PLURAL,
	"plateau": FN_PLATEAU,
	"scarp": FN_SCARP,
}

## PLATEAU. r² of the flat disc — 6.25 is a 5.0 m diameter table over the 8 x 8 m
## field. Inside it the tanh rim term is identically zero and the only relief is
## PLATEAU_TILT * r², which at the disc edge is 0.125 * 0.1275 = 0.016 m: flat to
## within 0.02 m, but NOT exactly flat. That distinction is the whole value. Zero
## gradient would trip the |∇f| < 0.0005 convergence test on step one and the four
## runners would be declared converged before they moved, which photographs as a
## bug. A gradient of 0.04·r instead lets each optimizer show what it does when the
## surface has almost nothing to say: SGD and Momentum creep in proportion to a
## vanishing slope, while Adam — which divides the gradient by its own magnitude —
## walks across the flat at full learning rate as if it knew something.
const PLATEAU_R2: float = 6.25
const PLATEAU_TILT: float = 0.02

## SCARP. f jumps by 3.0 across x = 0; at y_scale 0.15 that is a 0.45 m face.
const SCARP_RISE: float = 3.0
## Half-width of the shear column, 0.02 mm. The surface is sampled on 40 columns
## 0.2 m apart, so a plain step would be emitted as a 0.2 m RAMP — a smear where
## the artifact's whole claim is a discontinuity. Two columns straddling x = 0 by
## this much make the jump a genuinely vertical quad.
const SCARP_SEAM: float = 0.00002

# ── exported params ────────────────────────────────────────────────────
## Stage-2 DNA axis — the shape of the surface being descended: how many minima it
## has, and whether the local gradient tells the truth about where they are.
## Read at the top of _ready(), so the sweep reaches it by setting the @export
## alone; apply_grid_config accepts it too (`#basin:scarp`) but is not the only route.
@export_enum("bowl", "valley", "plural", "plateau", "scarp") var basin: String = "bowl"
## The int the surface code actually switches on. Kept in sync with `basin` by
## _sync_basin_from_exports(); a scene or inspector that sets this and leaves
## `basin` at its default still wins, so nothing shipped changes shape.
@export var function_preset: int = 0  # 0=bowl 1=valley 2=plural 3=plateau 4=scarp
## Stage-2 DNA axis — how much of the descent is drawn. Costs no rebuild: every
## value is a branch inside the per-frame ImmediateMesh pass, so a map or the
## sweep can move it and the standing body is never touched.
@export_enum("result", "trace", "longhand", "axiom") var evidence: String = "longhand"
@export var learning_rate: float = 0.05
@export var momentum_beta: float = 0.9
@export var adam_beta1: float = 0.9
@export var adam_beta2: float = 0.999
@export var step_speed: float = 2.0

# ── plotting-table console (cabinet grammar, HORIZONTAL dialect) ───────
## Housing finish — "rams" (light Braun default) or "terminal" (dark console).
## Every colour derives from HangarKit.finish_palette(), so one word re-skins
## the whole body instead of a dozen hand-typed constants.
@export var show_console: bool = true
@export var finish: String = "terminal"
@export var wear: float = 0.10
@export var unit_code: String = "GD-01"
## The deck plane, in the artifact's own coordinates. It is 0.0 and that is
## the truth, not a convenience: _eval() bottoms out at exactly 0 for all
## three presets (quadratic at the origin, Rosenbrock at (1,1), Himmelblau at
## four points), so the surface's floor sits precisely on y = 0. The console is
## built DOWNWARD from there — the deck IS the zero-loss datum, and the
## optimizers are racing to touch the tabletop.
@export var deck_height: float = 0.0
## Floor-to-deck drop — the table's own legs, which is the horizontal
## dialect's footing (an 8.8 m plinth shaft would be a monolith, not
## furniture). Lands the flush keypad in the VR reach band.
@export var stand_height: float = 0.92
## Curb width: the broad working rail you stand at, ringing the field.
@export var curb_w: float = 0.42
## The instrument bay bulging forward from the near curb — keypad, readout
## and key strip live in ONE bay instead of smearing round the ring.
@export var bay_w: float = 3.0
@export var bay_d: float = 0.52

# ── internal state ─────────────────────────────────────────────────────
## True once _ready() has finished a full synchronous build. apply_grid_config
## arrives deferred, AFTER _ready(), and must never rebuild before there is
## something to rebuild.
var _built: bool = false
## Every node THIS SCRIPT parented into the tree, in creation order. The rebuild
## frees exactly these — never get_children(), which would take the grid's own
## added plates and the framer's panels with it.
var _created: Array[Node] = []

var _mode: int = Mode.OPTIMIZERS
var _time: float = 0.0
var _stepping: bool = false
var _step_count: int = 0

# surface range
var _x_range := Vector2(-4.0, 4.0)
var _z_range := Vector2(-4.0, 4.0)
var _y_scale := 0.4  # height scaling for function values

# optimizer states (arrays of dicts)
var _optimizers: Array = []  # each: {name, color, pos, vel, m, v, path, converged, value}

# convergence mode
var _conv_runs: Array = []  # array of {lr, paths (array of arrays per optimizer)}

# hessian mode
var _hessian_grid: Array = []  # array of {pos, eigenvalues, eigenvectors}

# ── mesh instances ─────────────────────────────────────────────────────
var _surface_im: ImmediateMesh
var _surface_mi: MeshInstance3D
var _trails_im: ImmediateMesh
var _trails_mi: MeshInstance3D
var _arrows_im: ImmediateMesh
var _arrows_mi: MeshInstance3D
var _hessian_im: ImmediateMesh
var _hessian_mi: MeshInstance3D
var _markers_im: ImmediateMesh
var _markers_mi: MeshInstance3D

var _mat_unshaded: StandardMaterial3D
var _mat_alpha: StandardMaterial3D

# ── labels (integrated 2D-in-3D baked boards) ────────────────────────────
var _title_root: Node3D     # anchor for the billboarded title tag
var _info_root: Node3D      # anchor for the multi-line info board
var _legend_root: Node3D    # anchor for the multi-line legend board
var _title_node: Node3D     # current baked title tag (regenerated on change)
var _info_node: Node3D      # current baked info block
var _legend_node: Node3D    # current baked legend block
var _title_cache: String = ""
var _info_cache: String = ""
var _legend_cache: String = ""

const TITLE_COLOR  := Color(0.95, 0.97, 1.0)
const INFO_COLOR   := Color(0.8, 0.8, 0.9)
const LEGEND_COLOR := Color(0.7, 0.7, 0.8)

# ── controls ───────────────────────────────────────────────────────────
var _mode_button: Node3D
var _lr_slider: Node3D
var _beta_slider: Node3D
var _speed_slider: Node3D
var _fn_button: Node3D

# ════════════════════════════════════════════════════════════════════════
#  LIFECYCLE
# ════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_sync_basin_from_exports()
	_build_all()
	_built = true

## The whole body, from @export values alone, SYNCHRONOUSLY. No call_deferred:
## a deferred build that has already removed its children hands the grid's
## auto-grounding a zero AABB, and the artifact silently sinks into the floor.
func _build_all() -> void:
	_create_materials()
	_create_mesh_instances()
	_create_labels()
	_create_controls()
	_init_mode()
	_create_console()

## Reconcile the word and the int before anything samples _eval().
##
## `basin` wins when it is set, which is the sweep's route and the map's route.
## When it is left at its default the legacy `function_preset` wins and `basin` is
## renamed to match — so a scene or an inspector that already asked for
## Rosenbrock keeps Rosenbrock instead of being quietly reset to the bowl.
func _sync_basin_from_exports() -> void:
	evidence = _pick_axis(evidence, EVIDENCE, "longhand")
	basin = _pick_axis(basin, BASINS, "bowl")
	if basin != "bowl":
		function_preset = int(BASIN_PRESET.get(basin, FN_BOWL))
	else:
		function_preset = clampi(function_preset, 0, BASINS.size() - 1)
		basin = BASINS[function_preset]

## Free only what this script made, then build again INLINE. Ordered so the three
## label anchors are detached from the console before the console itself goes.
func _rebuild_now() -> void:
	for c in _created:
		if not is_instance_valid(c):
			continue
		var p: Node = c.get_parent()
		if p != null:
			p.remove_child(c)
		c.queue_free()
	_created.clear()

	_surface_im = null
	_surface_mi = null
	_trails_im = null
	_trails_mi = null
	_arrows_im = null
	_arrows_mi = null
	_hessian_im = null
	_hessian_mi = null
	_markers_im = null
	_markers_mi = null
	_title_root = null
	_info_root = null
	_legend_root = null
	# The *_node refs point at children of the anchors just freed, and the caches
	# would otherwise make _update_labels() early-return on a matching string and
	# never re-bake the readout.
	_title_node = null
	_info_node = null
	_legend_node = null
	_title_cache = ""
	_info_cache = ""
	_legend_cache = ""
	_mode_button = null
	_lr_slider = null
	_beta_slider = null
	_speed_slider = null
	_fn_button = null

	_build_all()

## Parent a node and remember it belongs to us.
func _own(n: Node) -> Node:
	add_child(n)
	_created.append(n)
	return n

func _process(delta: float) -> void:
	_time += delta
	if _stepping:
		var steps_per_frame := int(ceil(step_speed * delta * 30.0))
		for i in steps_per_frame:
			if _step_count >= TRAIL_MAX:
				_stepping = false
				break
			match _mode:
				Mode.OPTIMIZERS:
					_step_optimizers()
				Mode.CONVERGENCE:
					_step_convergence()
			_step_count += 1
	_draw_all()
	_update_labels()

# ════════════════════════════════════════════════════════════════════════
#  MATERIALS & MESH SETUP
# ════════════════════════════════════════════════════════════════════════

func _create_materials() -> void:
	_mat_unshaded = StandardMaterial3D.new()
	_mat_unshaded.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_unshaded.vertex_color_use_as_albedo = true
	_mat_unshaded.cull_mode = BaseMaterial3D.CULL_DISABLED

	_mat_alpha = _mat_unshaded.duplicate()
	_mat_alpha.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

func _create_mesh_instances() -> void:
	_surface_im = ImmediateMesh.new()
	_surface_mi = MeshInstance3D.new()
	_surface_mi.mesh = _surface_im
	_surface_mi.material_override = _mat_alpha
	_own(_surface_mi)

	_trails_im = ImmediateMesh.new()
	_trails_mi = MeshInstance3D.new()
	_trails_mi.mesh = _trails_im
	_trails_mi.material_override = _mat_unshaded
	_own(_trails_mi)

	_arrows_im = ImmediateMesh.new()
	_arrows_mi = MeshInstance3D.new()
	_arrows_mi.mesh = _arrows_im
	_arrows_mi.material_override = _mat_unshaded
	_own(_arrows_mi)

	_hessian_im = ImmediateMesh.new()
	_hessian_mi = MeshInstance3D.new()
	_hessian_mi.mesh = _hessian_im
	_hessian_mi.material_override = _mat_alpha
	_own(_hessian_mi)

	_markers_im = ImmediateMesh.new()
	_markers_mi = MeshInstance3D.new()
	_markers_mi.mesh = _markers_im
	_markers_mi.material_override = _mat_unshaded
	_own(_markers_mi)

# ════════════════════════════════════════════════════════════════════════
#  LABELS
# ════════════════════════════════════════════════════════════════════════

func _create_labels() -> void:
	# Anchors hold the baked boards; the boards themselves are (re)generated
	# in _update_labels() whenever their text content changes.
	#
	# These three positions are the BARE-mode fallback — a title 3.2 m overhead,
	# a telemetry board at 2.5 m, and a legend at -1.6 m, floating a metre and a
	# half UNDER the terrain where nothing could ever see it. With show_console
	# on, _create_console() re-parents all three onto the plotting table: the
	# title into the curb's name inlay, the telemetry into the sunk readout, the
	# legend into the milled key strip. The interface is part of the body.
	#
	# NOTHING HERE MOVES FOR THE BASIN AXIS, and that is a finding rather than an
	# omission: all three homes sit at z >= 4.16, beyond the field's near edge at
	# z = 4.0. The terrain occupies x,z in [-4, 4] exactly. So no surface this axis
	# can name — not the 0.55 m plateau rim, not the 0.45 m scarp face, not the
	# corner slopes that cap out at 4.0 m — can reach a caption, whatever its
	# height. The captions are protected by the plan of the table, not by a
	# clearance number that a new preset could overrun.
	_title_root = Node3D.new()
	_title_root.position = Vector3(0, 3.2, 0)
	_own(_title_root)

	_info_root = Node3D.new()
	_info_root.position = Vector3(0, 2.5, 0)
	_own(_info_root)

	_legend_root = Node3D.new()
	_legend_root.position = Vector3(0, -1.6, 0)
	_own(_legend_root)

# ════════════════════════════════════════════════════════════════════════
#  CONTROLS
# ════════════════════════════════════════════════════════════════════════

## Where the flush keypad sits in the near instrument bay. Shared by
## _create_controls (which runs first and mounts the pad) and _create_console
## (which mills the dark pocket the pad is recessed into) so the two cannot
## drift apart.
func _pad_center() -> Vector3:
	var cxm: float = (_x_range.x + _x_range.y) * 0.5
	var bay_cz: float = _z_range.y + bay_d * 0.5
	return Vector3(cxm - 1.08, deck_height + 0.020, bay_cz + 0.04)


func _create_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var rows: Array = [
		[
			{"type": "button", "label": "MODE"},
			{"type": "button", "label": "FUNCTION"},
		],
		[
			{"type": "slider_h", "label": "LEARN RATE", "default": learning_rate / 0.2},
			{"type": "slider_h", "label": "MOMENTUM", "default": momentum_beta},
		],
		[
			{"type": "slider_h", "label": "SPEED", "default": step_speed / 5.0},
		],
	]
	# Frameless: the milled pocket in the curb IS the faceplate. The pad is
	# recessed FLUSH and pressed downward — the horizontal dialect's answer to
	# the vertical wedge shoulder. Kept on the ARTIFACT ROOT, not on the
	# console, so the rack's cream and copper element materials stay out of the
	# housing material set the grammar measures (dice_throw does the same).
	var panel: Node3D = RackTpl.create_panel("GRADIENT", rows, show_console)
	if show_console:
		var pad: Vector3 = _pad_center()
		panel.position = Vector3(pad.x, pad.y + 0.006, pad.z + 0.005)
		panel.rotation_degrees = Vector3(-80, 0, 0)
		panel.scale = Vector3.ONE * 0.85
	else:
		panel.position = Vector3(0, -1.0, 0)
		panel.rotation_degrees = Vector3(-25, 0, 0)
	_own(panel)
	if show_console:
		# The curb inlay owns the name; the pad's baked title would say it twice.
		var pad_title: Node = panel.get_node_or_null("Title")
		if pad_title != null:
			pad_title.queue_free()

	_mode_button = panel.find_child("Btn_0", true, false)
	if _mode_button:
		var area: Node = _mode_button.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _cycle_mode())

	_fn_button = panel.find_child("Btn_1", true, false)
	if _fn_button:
		var area: Node = _fn_button.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _cycle_function())

	_lr_slider = panel.find_child("Param_0", true, false)
	if _lr_slider and _lr_slider.has_signal("slider_moved"):
		_lr_slider.slider_moved.connect(_on_lr_changed)

	_beta_slider = panel.find_child("Param_1", true, false)
	if _beta_slider and _beta_slider.has_signal("slider_moved"):
		_beta_slider.slider_moved.connect(_on_beta_changed)

	_speed_slider = panel.find_child("Param_2", true, false)
	if _speed_slider and _speed_slider.has_signal("slider_moved"):
		_speed_slider.slider_moved.connect(_on_speed_changed)

func _cycle_mode() -> void:
	_mode = (_mode + 1) % 3
	_init_mode()

## The FUNCTION button now walks all five surfaces, not the first three. The two
## new ones are standing geometry the surface code already handles, so there is
## nothing to rebuild — _init_mode() re-seeds the runners and the ImmediateMesh
## re-samples _eval() on the next frame.
func _cycle_function() -> void:
	function_preset = (function_preset + 1) % BASINS.size()
	basin = BASINS[function_preset]
	_init_mode()

func _on_lr_changed(_v: float) -> void:
	learning_rate = clampf(_lr_slider.get_normalized_value() * 0.2, 0.001, 0.2)
	_init_mode()

func _on_beta_changed(_v: float) -> void:
	momentum_beta = clampf(_beta_slider.get_normalized_value(), 0.0, 0.99)
	adam_beta1 = momentum_beta
	_init_mode()

func _on_speed_changed(_v: float) -> void:
	step_speed = clampf(_speed_slider.get_normalized_value() * 5.0, 0.1, 5.0)

# ════════════════════════════════════════════════════════════════════════
#  PLOTTING TABLE — the cabinet grammar, HORIZONTAL dialect
# ════════════════════════════════════════════════════════════════════════
## THE PLANE decides the dialect before anything else. Every directional
## quantity this artifact computes lies in XZ: the optimizer paths are Vector2
## in x/z, the gradient arrows are Vector3(dir.x, y, dir.y), and the Hessian
## mode draws a 9x9 field of eigenvector crosses dead flat. Height is the
## dependent variable, f(x,z). This is a topographic map with tokens moving
## across it, and you read a map by looking DOWN. HORIZONTAL.
##
## Not dice_throw's table console — that is 0.6 m of felt you lean over, its
## interface distributed round a small rim. This field is 8 x 8 m: you do not
## lean over it, you WALK AROUND it and stand at its edge. That is a PLOTTING
## TABLE (the Fighter Command board, the visitor-centre relief model). Three
## things follow that the table console does not have, which is why it earns
## its own body name: the rail is a CURB you stand at, not a rim you reach
## across; the interface concentrates in ONE instrument bay bulging from the
## near curb; and the curb is GRADUATED, because nothing in this artifact
## currently tells you what x and z mean and a plotting table's rim always
## carries its scale.
##
##   vertical part          →  what it becomes here
##   ─────────────────────     ────────────────────────────────────────────
##   back slab              →  the curb ring, the slab laid flat round the field
##   inset window / screen  →  readout SUNK 14 deg off the deck
##   sign band overhead     →  name INLAID FLAT in the near curb, read looking down
##   keypad on a wedge      →  keypad recessed FLUSH in a milled pocket, face-up
##   maroon flank           →  maroon edge INLAY LINE under the curb's top edge
##   vent slats on the back →  vents in the APRON, seen from below
##   plinth + feet          →  apron + the furniture's own legs
##
## ONE TRANSLATION MADE DELIBERATELY: the canon puts the readout in the FAR
## rail because at 0.6 m the far rail is readable across the table. At 8 m it
## is eight metres away. So the far-rail readout role MIGRATES to the near bay
## keeping its treatment exactly — sunk, 14 degrees off the deck, tilted up
## toward the reader standing at +Z. A translation forced by scale, not a part
## transferred from the other dialect. Nothing stands up.
func _create_console() -> void:
	if not show_console:
		return

	# ── derived from the artifact's OWN field, not from magic numbers ──
	var x0: float = _x_range.x
	var x1: float = _x_range.y
	var z0: float = _z_range.x
	var z1: float = _z_range.y
	var fw: float = x1 - x0
	var fd: float = z1 - z0
	var cxm: float = (x0 + x1) * 0.5
	var czm: float = (z0 + z1) * 0.5

	var curb_th: float = 0.055
	var curb_top: float = deck_height + 0.048
	var curb_y: float = curb_top - curb_th * 0.5
	var outer_w: float = fw + 2.0 * curb_w
	var x_left_out: float = x0 - curb_w
	var x_right_out: float = x1 + curb_w
	var z_far_out: float = z0 - curb_w
	var z_near_out: float = z1 + bay_d
	var bay_cz: float = z1 + bay_d * 0.5
	var bay_h: float = 0.188
	var bay_x_lo: float = cxm - bay_w * 0.5
	var bay_x_hi: float = cxm + bay_w * 0.5
	# the outer side edge runs the full ring, far curb through near curb
	var side_z_lo: float = z_far_out
	var side_z_hi: float = z1 + curb_w
	var side_len: float = side_z_hi - side_z_lo
	var side_cz: float = (side_z_lo + side_z_hi) * 0.5

	var con := Node3D.new()
	con.name = "TableConsole"
	con.set_meta("housing", true)      # so the grammar probe scopes its rules here
	_own(con)

	# ── one word drives every colour ──
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var pal_panel: Color = pal["panel"]
	var pal_accent: Color = pal["accent"]
	var pal_text: Color = pal["text"]
	var pal_body: Color = pal["body"]
	var ew: float = float(pal["wear"]) if finish.to_lower() == "terminal" else wear
	var shell: StandardMaterial3D = HangarKit.finish_body(finish, pal_body, ew)
	# The near-black is a FIXED value, never panel.darkened() — 0.55 lands at
	# ~0.31 grey and washes out every pocket and apron in the family.
	var dark: StandardMaterial3D = HangarKit.painted_metal(Color(0.09, 0.09, 0.105), ew, 0.4, 0.5)
	var maroon: StandardMaterial3D = HangarKit.painted_metal(Color(0.30, 0.11, 0.09), ew)
	var steel: StandardMaterial3D = HangarKit.worn_metal(pal_panel)
	var accent: StandardMaterial3D = HangarKit.emissive(pal_accent, 2.2)

	# ── 0. THE BASIN — a milled well the surface sits IN ────────────────
	# Without this the loss surface (floor at y=0) hangs over open air framed
	# by the curb, reading as a membrane on a frame. A dark floor plate just
	# below the deck + low inner walls make it a well — the horizontal
	# translation of the vertical dialect's dark window backdrop.
	var basin_depth: float = 0.10
	con.add_child(HangarKit.box(Vector3(cxm, deck_height - basin_depth - 0.008, czm),
		Vector3(fw + 0.02, 0.016, fd + 0.02), dark))
	for wall in [
		[Vector3(cxm, deck_height - basin_depth * 0.5, z0), Vector3(fw + 0.02, basin_depth, 0.012)],
		[Vector3(cxm, deck_height - basin_depth * 0.5, z1), Vector3(fw + 0.02, basin_depth, 0.012)],
		[Vector3(x0, deck_height - basin_depth * 0.5, czm), Vector3(0.012, basin_depth, fd + 0.02)],
		[Vector3(x1, deck_height - basin_depth * 0.5, czm), Vector3(0.012, basin_depth, fd + 0.02)],
	]:
		con.add_child(HangarKit.box(wall[0], wall[1], dark))

	# ── 1. CURB RING — the back slab, laid flat ─────────────────────────
	# The near side is interrupted by the instrument bay, so it comes in two
	# slabs either side of it.
	con.add_child(HangarKit.box(Vector3(cxm, curb_y, z0 - curb_w * 0.5),
		Vector3(outer_w, curb_th, curb_w), shell))
	con.add_child(HangarKit.box(Vector3(x0 - curb_w * 0.5, curb_y, czm),
		Vector3(curb_w, curb_th, fd), shell))
	con.add_child(HangarKit.box(Vector3(x1 + curb_w * 0.5, curb_y, czm),
		Vector3(curb_w, curb_th, fd), shell))
	con.add_child(HangarKit.box(Vector3((x_left_out + bay_x_lo) * 0.5, curb_y, z1 + curb_w * 0.5),
		Vector3(bay_x_lo - x_left_out, curb_th, curb_w), shell))
	con.add_child(HangarKit.box(Vector3((bay_x_hi + x_right_out) * 0.5, curb_y, z1 + curb_w * 0.5),
		Vector3(x_right_out - bay_x_hi, curb_th, curb_w), shell))

	# ── 2. INSTRUMENT BAY — bulging forward from the near curb ──────────
	# Thicker than the plain curb because it has to SWALLOW the lower half of
	# a sunk readout. The bulge is why the interface reads as one bay instead
	# of smeared round the ring.
	con.add_child(HangarKit.box(Vector3(cxm, curb_top - bay_h * 0.5, bay_cz),
		Vector3(bay_w, bay_h, bay_d), shell))

	# ── 3. MAROON EDGE INLAY — a LINE, not a band ───────────────────────
	# The vertical flank is a mass; a mass laid flat becomes a stripe of paint
	# claiming the surface. On furniture the colour is stated by a line: 0.009
	# on a 0.055 edge face, about a sixth of it.
	var band_y: float = curb_top - 0.015
	var band_h: float = 0.009
	var band_t: float = 0.008
	con.add_child(HangarKit.box(Vector3(cxm, band_y, z_far_out + 0.004),
		Vector3(outer_w, band_h, band_t), maroon))
	con.add_child(HangarKit.box(Vector3(x_left_out + 0.004, band_y, side_cz),
		Vector3(band_t, band_h, side_len), maroon))
	con.add_child(HangarKit.box(Vector3(x_right_out - 0.004, band_y, side_cz),
		Vector3(band_t, band_h, side_len), maroon))
	con.add_child(HangarKit.box(Vector3((x_left_out + bay_x_lo) * 0.5, band_y, z1 + curb_w - 0.004),
		Vector3(bay_x_lo - x_left_out, band_h, band_t), maroon))
	con.add_child(HangarKit.box(Vector3((bay_x_hi + x_right_out) * 0.5, band_y, z1 + curb_w - 0.004),
		Vector3(x_right_out - bay_x_hi, band_h, band_t), maroon))
	con.add_child(HangarKit.box(Vector3(cxm, band_y, z_near_out - 0.004),
		Vector3(bay_w, band_h, band_t), maroon))
	for bs in [-1.0, 1.0]:
		con.add_child(HangarKit.box(
			Vector3(cxm + bs * (bay_w * 0.5 - 0.004), band_y, (z1 + curb_w + z_near_out) * 0.5),
			Vector3(band_t, band_h, bay_d - curb_w), maroon))

	# ── 4. THE EMBER DATUM LINE ─────────────────────────────────────────
	# Routed along the curb's INNER lip, framing the field exactly where the
	# surface bottoms out. This is the family's one warm line AND the zero-loss
	# datum stated in light: the optimizers are racing to touch it.
	var em_y: float = curb_top + 0.001
	for sz in [-1.0, 1.0]:
		con.add_child(HangarKit.box(Vector3(cxm, em_y, czm + sz * (fd * 0.5 + 0.014)),
			Vector3(fw + 0.028, 0.003, 0.006), accent))
		con.add_child(HangarKit.box(Vector3(cxm + sz * (fw * 0.5 + 0.014), em_y, czm),
			Vector3(0.006, 0.003, fd + 0.028), accent))

	# ── 5. GRADUATED CURB — the teaching gain ───────────────────────────
	# Nothing in this artifact told a viewer what x and z were. A plotting
	# table's rim always carries its scale.
	var n_steps: int = int(round(fw))
	for i in range(n_steps + 1):
		var ux: float = x0 + float(i)
		var major: bool = (i == 0 or i == n_steps or i * 2 == n_steps)
		var tl: float = 0.090 if major else 0.055
		con.add_child(HangarKit.box(Vector3(ux, curb_top - 0.001, z0 - 0.006 - tl * 0.5),
			Vector3(0.006, 0.004, tl), dark))
		con.add_child(HangarKit.box(Vector3(ux, curb_top - 0.001, z1 + 0.006 + tl * 0.5),
			Vector3(0.006, 0.004, tl), dark))
	var n_steps_z: int = int(round(fd))
	for j in range(n_steps_z + 1):
		var uz: float = z0 + float(j)
		var major_z: bool = (j == 0 or j == n_steps_z or j * 2 == n_steps_z)
		var tlz: float = 0.090 if major_z else 0.055
		con.add_child(HangarKit.box(Vector3(x0 - 0.006 - tlz * 0.5, curb_top - 0.001, uz),
			Vector3(tlz, 0.004, 0.006), dark))
		con.add_child(HangarKit.box(Vector3(x1 + 0.006 + tlz * 0.5, curb_top - 0.001, uz),
			Vector3(tlz, 0.004, 0.006), dark))
	# Numerals every two units, read by looking down. On the FAR curb for x and
	# the LEFT curb for z — the near curb is the instrument bay.
	for i2 in range(n_steps + 1):
		if i2 % 2 != 0:
			continue
		var nx: float = x0 + float(i2)
		var xlab: MeshInstance3D = HangarKit.stencil("%d" % int(round(nx)),
			Vector2(0.075, 0.030), pal_accent.lightened(0.25))
		if xlab != null:
			xlab.position = Vector3(nx, curb_top + 0.002, z0 - 0.13)
			xlab.rotation_degrees = Vector3(-90, 0, 0)
			con.add_child(xlab)
	for j2 in range(n_steps_z + 1):
		if j2 % 2 != 0:
			continue
		var nz: float = z0 + float(j2)
		var zlab: MeshInstance3D = HangarKit.stencil("%d" % int(round(nz)),
			Vector2(0.075, 0.030), pal_accent.lightened(0.25))
		if zlab != null:
			zlab.position = Vector3(x0 - 0.13, curb_top + 0.002, nz)
			zlab.rotation_degrees = Vector3(-90, 0, 0)
			con.add_child(zlab)
	var div_patch: MeshInstance3D = HangarKit.brand_patch("1 DIVISION = 1.0 UNIT",
		Vector2(0.42, 0.055), Color(0.09, 0.09, 0.105), pal_text)
	if div_patch != null:
		div_patch.position = Vector3(cxm - 3.0, curb_top + 0.002, z0 - 0.30)
		div_patch.rotation_degrees = Vector3(-90, 0, 0)
		con.add_child(div_patch)

	# ── 6. READOUT — the telemetry comes home ───────────────────────────
	# 14 degrees off the deck: an inlaid plotter's screen, read by looking
	# down. Steeper and it stands up like a monitor, which is the vertical
	# dialect wearing a table. SIZE IS LOAD-BEARING: HangarKit.readout throws
	# its top bezel bar upward, so at h = 0.30 with the centre sunk to +0.004
	# the bar tops out at 0.083 — inside the 0.10 allowance. At the tempting
	# h = 0.34 centred on the curb top it reaches 0.143 and the table has
	# become a machine wearing a table.
	var tilt: float = -76.0
	var norm := Vector3(0.0, 0.970, 0.242)        # screen face normal
	var loc_up := Vector3(0.0, 0.242, -0.970)     # screen local up, in world
	var scr_w: float = 1.30
	var scr_h: float = 0.30
	var scr_c := Vector3(cxm + 0.05, deck_height + 0.004, bay_cz - 0.02)

	var pocket: MeshInstance3D = HangarKit.box(scr_c - norm * 0.012,
		Vector3(scr_w + 0.06, scr_h + 0.05, 0.014), dark)
	pocket.rotation_degrees = Vector3(tilt, 0, 0)
	con.add_child(pocket)

	var scr_lip: MeshInstance3D = HangarKit.box(
		scr_c + loc_up * (scr_h * 0.5 + 0.005) + norm * 0.003,
		Vector3(scr_w + 0.06, 0.004, 0.005), accent)
	scr_lip.rotation_degrees = Vector3(tilt, 0, 0)
	con.add_child(scr_lip)

	_rehome(_info_root, con, "InfoScreen", scr_c, Vector3(tilt, 0, 0))

	# ── 7. KEY STRIP — the legend, milled into the curb ─────────────────
	# The saturated phenomenon colours live HERE, in a dark pocket, naming the
	# thing they belong to. They never touch the off-white shell.
	var key_c := Vector3(cxm + 1.15, deck_height + 0.020, bay_cz + 0.04)
	var key_pocket: MeshInstance3D = HangarKit.box(key_c, Vector3(0.62, 0.20, 0.012), dark)
	key_pocket.rotation_degrees = Vector3(-80, 0, 0)
	con.add_child(key_pocket)
	var norm80 := Vector3(0.0, 0.9848, 0.1736)
	_rehome(_legend_root, con, "LegendStrip", key_c + norm80 * 0.009, Vector3(-80, 0, 0))

	# ── 8. KEYPAD POCKET — the pad is mounted in _create_controls ───────
	var pad_c: Vector3 = _pad_center()
	var pad_pocket: MeshInstance3D = HangarKit.box(pad_c, Vector3(0.34, 0.30, 0.012), dark)
	pad_pocket.rotation_degrees = Vector3(-80, 0, 0)
	con.add_child(pad_pocket)

	# ── 9. NAME INLAID FLAT in the near curb ────────────────────────────
	# The readout header owns the live mode; the curb owns the permanent name,
	# and under it the update rule — the thing actually worth printing on the
	# machine.
	_rehome(_title_root, con, "NamePlate",
		Vector3(cxm - 2.30, curb_top + 0.002, z1 + 0.16), Vector3(-90, 0, 0))
	var name_tag: Node3D = BakedText.make_tag("GRADIENT DESCENT",
		Color(0.93, 0.94, 0.97), 0.030, Color(0.07, 0.075, 0.09), false, Color(0, 0, 0, 0))
	if name_tag != null:
		_title_node = name_tag
		_title_root.add_child(name_tag)
	var name_sub: Node3D = BakedText.make_tag("THETA <- THETA - ETA * GRAD f(THETA)",
		Color(0.58, 0.50, 0.44), 0.013, Color(0.07, 0.075, 0.09), false, Color(0, 0, 0, 0))
	if name_sub != null:
		name_sub.position = Vector3(0.0, -0.040, 0.0)   # local -Y reads as +Z once flat
		_title_root.add_child(name_sub)

	# ── 10. CHART TRAY — the convergence plot, laid down ────────────────
	# _draw_convergence_chart used to stand a 2.5 m plot in the air off the
	# right edge. It is routed into the right curb instead: a chart-recorder
	# trough you read by walking the edge. The trace itself is re-based in
	# _draw_convergence_chart.
	con.add_child(HangarKit.box(Vector3(x1 + 0.21, curb_top - 0.006, czm),
		Vector3(0.28, 0.010, 2.50), dark))
	con.add_child(HangarKit.box(Vector3(x1 + 0.09, curb_top - 0.001, czm),
		Vector3(0.006, 0.003, 2.50), accent))

	# ── 11. APRON + VENTS ───────────────────────────────────────────────
	# Sized off the CURB RING, not off the bay bulge — the apron has to be
	# inset from the curb all the way round so the curb reads as a lip. The
	# vents go in the near face, where a table hides them.
	var apron_h: float = 0.12
	var apron_top: float = curb_top - curb_th
	var apron_y: float = apron_top - apron_h * 0.5
	var apron_d: float = side_len - 0.16
	con.add_child(HangarKit.box(Vector3(cxm, apron_y, side_cz),
		Vector3(outer_w - 0.16, apron_h, apron_d), dark))
	var vent_z: float = side_cz + apron_d * 0.5 + 0.002
	for vx in [-2.2, 2.2]:
		for gi in range(5):
			con.add_child(HangarKit.box(
				Vector3(cxm + vx, apron_top - 0.024 - float(gi) * 0.013, vent_z),
				Vector3(0.34, 0.007, 0.008), shell))

	# ── 12. LEGS — the horizontal dialect's footing ─────────────────────
	# Not HangarKit.plinth: a plinth builds a solid shaft, and an 8.8 x 8.8 m
	# shaft is a monolith, not furniture. The dialect's footing is explicitly
	# the furniture's own legs.
	var leg_top: float = apron_top - apron_h
	var leg_bot: float = deck_height - stand_height
	var leg_h: float = leg_top - leg_bot
	var leg_cy: float = (leg_top + leg_bot) * 0.5
	var lx: float = outer_w * 0.5 - 0.30
	var lz: float = side_len * 0.5 - 0.30
	var leg_spots: Array = [
		Vector2(cxm - lx, side_cz - lz), Vector2(cxm, side_cz - lz), Vector2(cxm + lx, side_cz - lz),
		Vector2(cxm - lx, side_cz), Vector2(cxm + lx, side_cz),
		Vector2(cxm - lx, side_cz + lz), Vector2(cxm, side_cz + lz), Vector2(cxm + lx, side_cz + lz),
	]
	for sp in leg_spots:
		var s2: Vector2 = sp
		con.add_child(HangarKit.box(Vector3(s2.x, leg_cy, s2.y),
			Vector3(0.13, leg_h, 0.13), dark))
		con.add_child(HangarKit.box(Vector3(s2.x, leg_bot + 0.015, s2.y),
			Vector3(0.18, 0.03, 0.18), dark))

	# ── 13. KIT DETAILS, HORIZONTAL — nothing climbs off the deck ───────
	# No grime_band: the apron is already near-black and an opaque dirt shadow
	# on it reads as a slab hanging under the table. No dust_streaks: they
	# would read as smears on a translucent phenomenon.
	con.add_child(HangarKit.bolts(
		Vector3(bay_x_lo + 0.10, curb_y, z_near_out - 0.022),
		Vector3(bay_x_hi - 0.10, curb_y, z_near_out - 0.022),
		11, 0.008, steel))
	con.add_child(HangarKit.bolts(
		Vector3(x_left_out + 0.12, curb_y, z_far_out + 0.022),
		Vector3(x_right_out - 0.12, curb_y, z_far_out + 0.022),
		15, 0.008, steel))
	var code: MeshInstance3D = HangarKit.stencil(unit_code, Vector2(0.11, 0.028),
		pal_accent.lightened(0.25))
	if code != null:
		code.position = Vector3(bay_x_lo + 0.09, curb_top + 0.002, bay_cz + 0.20)
		code.rotation_degrees = Vector3(-90, 0, 0)   # read by looking down
		con.add_child(code)


## Move an existing label anchor onto the housing. The founding ruling is that
## the interface is PART OF THE BODY, so the boards are not rebuilt somewhere
## else — the same nodes are re-parented onto the console and re-aimed.
func _rehome(node: Node3D, parent: Node3D, nm: String, pos: Vector3, rot: Vector3) -> void:
	if node == null:
		return
	var old: Node = node.get_parent()
	if old != null:
		old.remove_child(node)
	node.name = nm
	parent.add_child(node)
	node.position = pos
	node.rotation_degrees = rot

# ════════════════════════════════════════════════════════════════════════
#  FUNCTION EVALUATION
# ════════════════════════════════════════════════════════════════════════

func _fn_name() -> String:
	match function_preset:
		FN_BOWL: return "Quadratic Bowl"
		FN_VALLEY: return "Rosenbrock Valley"
		FN_PLURAL: return "Himmelblau"
		FN_PLATEAU: return "Plateau"
		FN_SCARP: return "Scarp"
		_: return "Quadratic Bowl"

func _eval(p: Vector2) -> float:
	var x := p.x
	var y := p.y
	match function_preset:
		FN_BOWL:  # Quadratic bowl: x² + y²
			return x * x + y * y
		FN_VALLEY:  # Rosenbrock: (1-x)² + 100(y-x²)²
			return (1.0 - x) * (1.0 - x) + 100.0 * (y - x * x) * (y - x * x)
		FN_PLURAL:  # Himmelblau: (x²+y-11)² + (x+y²-7)²
			return (x*x + y - 11.0) * (x*x + y - 11.0) + (x + y*y - 7.0) * (x + y*y - 7.0)
		FN_PLATEAU:
			# 4·tanh(0.35·max(0, r²-6.25)) + 0.02·r²
			#
			# A surface with no information to give. The tanh term is IDENTICALLY
			# ZERO inside the 5 m disc — max() clamps its argument, so this is not a
			# small number, it is nothing — and saturates to 4.0 in the outer ring,
			# which at y_scale 0.1275 is the 0.55 m rim at the field edge. What is
			# left over the disc is the 0.02·r² residue: 0.016 m of relief at the
			# disc edge, flat to within 0.02 m and yet not so flat that the runners
			# are declared converged before they have moved.
			var r2p := x * x + y * y
			return 4.0 * tanh(0.35 * maxf(0.0, r2p - PLATEAU_R2)) + PLATEAU_TILT * r2p
		FN_SCARP:
			# r² + 3·step(x)
			#
			# The shipped bowl, cut. Everywhere except x = 0 the derivative is the
			# bowl's own and is perfectly honest about the bowl; it has no term for
			# the 0.45 m drop standing one step away, because a step function has no
			# derivative to give. The local truth is false. Gradient arrows on
			# either side of the face point at each other and one of them is wrong.
			var r2s := x * x + y * y
			return r2s + SCARP_RISE * (1.0 if x > 0.0 else 0.0)
		_:
			return x * x + y * y

func _gradient(p: Vector2) -> Vector2:
	var eps := 0.0001
	var dx := (_eval(Vector2(p.x + eps, p.y)) - _eval(Vector2(p.x - eps, p.y))) / (2.0 * eps)
	var dy := (_eval(Vector2(p.x, p.y + eps)) - _eval(Vector2(p.x, p.y - eps))) / (2.0 * eps)
	return Vector2(dx, dy)

func _hessian(p: Vector2) -> Array:
	# Returns [fxx, fxy, fyx, fyy] via finite differences
	var eps := 0.001
	var f00 := _eval(p)
	var fxx := (_eval(Vector2(p.x + eps, p.y)) - 2.0 * f00 + _eval(Vector2(p.x - eps, p.y))) / (eps * eps)
	var fyy := (_eval(Vector2(p.x, p.y + eps)) - 2.0 * f00 + _eval(Vector2(p.x, p.y - eps))) / (eps * eps)
	var fxy := (_eval(Vector2(p.x + eps, p.y + eps)) - _eval(Vector2(p.x + eps, p.y - eps))
		- _eval(Vector2(p.x - eps, p.y + eps)) + _eval(Vector2(p.x - eps, p.y - eps))) / (4.0 * eps * eps)
	return [fxx, fxy, fxy, fyy]

func _hessian_eigen(p: Vector2) -> Dictionary:
	# 2x2 eigenvalue decomposition
	var h := _hessian(p)
	var a: float = h[0]
	var b: float = h[1]
	var d: float = h[3]
	var trace := a + d
	var det := a * d - b * b
	var disc := trace * trace - 4.0 * det
	if disc < 0.0:
		disc = 0.0
	var sqrt_disc := sqrt(disc)
	var l1 := (trace + sqrt_disc) / 2.0
	var l2 := (trace - sqrt_disc) / 2.0
	# eigenvectors
	var v1 := Vector2(1, 0)
	var v2 := Vector2(0, 1)
	if abs(b) > 1e-8:
		v1 = Vector2(l1 - d, b).normalized()
		v2 = Vector2(l2 - d, b).normalized()
	elif abs(a - d) > 1e-8:
		v1 = Vector2(1, 0)
		v2 = Vector2(0, 1)
	return {"l1": l1, "l2": l2, "v1": v1, "v2": v2}

func _start_pos() -> Vector2:
	match function_preset:
		FN_BOWL: return Vector2(3.5, 2.5)
		FN_VALLEY: return Vector2(-1.5, 1.5)
		FN_PLURAL: return Vector2(0.5, 0.5)
		# Inside the flat disc (r² = 5.96 < 6.25), so the runners start on the part
		# of the surface that is telling them nothing.
		FN_PLATEAU: return Vector2(2.0, 1.4)
		# The bowl's own start, deliberately: scarp is the bowl plus a cliff and the
		# still should differ from `bowl` by the cliff and nothing else. x = 3.5 puts
		# every runner on the HIGH side, walking down into the face.
		FN_SCARP: return Vector2(3.5, 2.5)
		_: return Vector2(3.0, 2.0)

func _y_scale_for_fn() -> float:
	match function_preset:
		FN_BOWL: return 0.15
		FN_VALLEY: return 0.0005  # Rosenbrock has huge values
		FN_PLURAL: return 0.003
		FN_PLATEAU: return 0.1275  # 4.0 saturation -> a 0.55 m rim at the field edge
		FN_SCARP: return 0.15      # the bowl's own scale; 3.0 jump -> a 0.45 m face
		_: return 0.15

# ════════════════════════════════════════════════════════════════════════
#  MODE INIT
# ════════════════════════════════════════════════════════════════════════

func _init_mode() -> void:
	_stepping = false
	_step_count = 0
	_y_scale = _y_scale_for_fn()

	_surface_mi.visible = true
	_trails_mi.visible = (_mode != Mode.HESSIAN)
	_arrows_mi.visible = (_mode == Mode.OPTIMIZERS)
	_hessian_mi.visible = (_mode == Mode.HESSIAN)
	_markers_mi.visible = true

	match _mode:
		Mode.OPTIMIZERS:
			_init_optimizers()
		Mode.CONVERGENCE:
			_init_convergence()
		Mode.HESSIAN:
			_init_hessian()

	_stepping = true

func _init_optimizers() -> void:
	_optimizers.clear()
	var start := _start_pos()
	var lr := learning_rate

	# SGD (vanilla)
	_optimizers.append({
		"name": "SGD",
		"color": COL_SGD,
		"pos": start,
		"vel": Vector2.ZERO,
		"m": Vector2.ZERO,
		"v_adam": Vector2.ZERO,
		"t": 0,
		"path": [start],
		"converged": false,
		"value": _eval(start),
		"type": "sgd",
	})

	# Momentum
	_optimizers.append({
		"name": "Momentum",
		"color": COL_MOMENTUM,
		"pos": start,
		"vel": Vector2.ZERO,
		"m": Vector2.ZERO,
		"v_adam": Vector2.ZERO,
		"t": 0,
		"path": [start],
		"converged": false,
		"value": _eval(start),
		"type": "momentum",
	})

	# Nesterov
	_optimizers.append({
		"name": "Nesterov",
		"color": COL_NESTEROV,
		"pos": start,
		"vel": Vector2.ZERO,
		"m": Vector2.ZERO,
		"v_adam": Vector2.ZERO,
		"t": 0,
		"path": [start],
		"converged": false,
		"value": _eval(start),
		"type": "nesterov",
	})

	# Adam
	_optimizers.append({
		"name": "Adam",
		"color": COL_ADAM,
		"pos": start,
		"vel": Vector2.ZERO,
		"m": Vector2.ZERO,
		"v_adam": Vector2.ZERO,
		"t": 0,
		"path": [start],
		"converged": false,
		"value": _eval(start),
		"type": "adam",
	})

func _init_convergence() -> void:
	_conv_runs.clear()
	var lrs := [0.001, 0.01, 0.05, 0.1, 0.15]
	var start := _start_pos()
	for i in lrs.size():
		var run := {
			"lr": lrs[i],
			"color": COL_LR_COLORS[i],
			"pos": start,
			"vel": Vector2.ZERO,
			"m": Vector2.ZERO,
			"v_adam": Vector2.ZERO,
			"t": 0,
			"path": [start],
			"values": [_eval(start)],
			"converged": false,
		}
		_conv_runs.append(run)

func _init_hessian() -> void:
	_hessian_grid.clear()
	var res := 8
	var dx := (_x_range.y - _x_range.x) / float(res)
	var dz := (_z_range.y - _z_range.x) / float(res)
	for i in range(res + 1):
		for j in range(res + 1):
			var px := _x_range.x + i * dx
			var pz := _z_range.x + j * dz
			var p := Vector2(px, pz)
			var eigen := _hessian_eigen(p)
			_hessian_grid.append({
				"pos": p,
				"l1": eigen.l1,
				"l2": eigen.l2,
				"v1": eigen.v1,
				"v2": eigen.v2,
			})

# ════════════════════════════════════════════════════════════════════════
#  STEPPING
# ════════════════════════════════════════════════════════════════════════

func _step_optimizers() -> void:
	for opt in _optimizers:
		if opt.converged:
			continue
		var pos: Vector2 = opt.pos
		var grad := _gradient(pos)

		if grad.length() < 0.0005:
			opt.converged = true
			continue

		var new_pos := pos
		match opt.type:
			"sgd":
				new_pos = pos - learning_rate * grad

			"momentum":
				opt.vel = momentum_beta * (opt.vel as Vector2) - learning_rate * grad
				new_pos = pos + (opt.vel as Vector2)

			"nesterov":
				var look_ahead := pos + momentum_beta * (opt.vel as Vector2)
				var look_grad := _gradient(look_ahead)
				opt.vel = momentum_beta * (opt.vel as Vector2) - learning_rate * look_grad
				new_pos = pos + (opt.vel as Vector2)

			"adam":
				opt.t = (opt.t as int) + 1
				var t_f := float(opt.t as int)
				opt.m = adam_beta1 * (opt.m as Vector2) + (1.0 - adam_beta1) * grad
				opt.v_adam = adam_beta2 * (opt.v_adam as Vector2) + (1.0 - adam_beta2) * Vector2(grad.x * grad.x, grad.y * grad.y)
				var m_hat: Vector2 = (opt.m as Vector2) / (1.0 - pow(adam_beta1, t_f))
				var v_hat: Vector2 = (opt.v_adam as Vector2) / (1.0 - pow(adam_beta2, t_f))
				new_pos = pos - learning_rate * Vector2(
					m_hat.x / (sqrt(v_hat.x) + ADAM_EPS),
					m_hat.y / (sqrt(v_hat.y) + ADAM_EPS)
				)

		# Clamp to range
		new_pos.x = clampf(new_pos.x, _x_range.x, _x_range.y)
		new_pos.y = clampf(new_pos.y, _z_range.x, _z_range.y)
		opt.pos = new_pos
		opt.value = _eval(new_pos)
		(opt.path as Array).append(new_pos)

func _step_convergence() -> void:
	for run in _conv_runs:
		if run.converged:
			continue
		var pos: Vector2 = run.pos
		var grad := _gradient(pos)
		if grad.length() < 0.0005:
			run.converged = true
			continue

		# Adam with this run's lr
		run.t = (run.t as int) + 1
		var t_f := float(run.t as int)
		var lr_r: float = run.lr
		run.m = adam_beta1 * (run.m as Vector2) + (1.0 - adam_beta1) * grad
		run.v_adam = adam_beta2 * (run.v_adam as Vector2) + (1.0 - adam_beta2) * Vector2(grad.x * grad.x, grad.y * grad.y)
		var m_hat: Vector2 = (run.m as Vector2) / (1.0 - pow(adam_beta1, t_f))
		var v_hat: Vector2 = (run.v_adam as Vector2) / (1.0 - pow(adam_beta2, t_f))
		var new_pos := pos - lr_r * Vector2(
			m_hat.x / (sqrt(v_hat.x) + ADAM_EPS),
			m_hat.y / (sqrt(v_hat.y) + ADAM_EPS)
		)
		new_pos.x = clampf(new_pos.x, _x_range.x, _x_range.y)
		new_pos.y = clampf(new_pos.y, _z_range.x, _z_range.y)
		run.pos = new_pos
		(run.path as Array).append(new_pos)
		(run.values as Array).append(_eval(new_pos))

# ════════════════════════════════════════════════════════════════════════
#  DRAWING
# ════════════════════════════════════════════════════════════════════════

func _draw_all() -> void:
	_draw_surface()
	match _mode:
		Mode.OPTIMIZERS:
			_draw_optimizer_trails()
			_draw_optimizer_markers()
			_hessian_im.clear_surfaces()
		Mode.CONVERGENCE:
			_draw_convergence_trails()
			_draw_convergence_chart()
			_hessian_im.clear_surfaces()
		Mode.HESSIAN:
			_trails_im.clear_surfaces()
			_arrows_im.clear_surfaces()
			_draw_hessian()
			_draw_hessian_markers()

func _draw_surface() -> void:
	_surface_im.clear_surfaces()
	_surface_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var dx := (_x_range.y - _x_range.x) / float(SURFACE_RES)
	var dz := (_z_range.y - _z_range.x) / float(SURFACE_RES)

	if function_preset == FN_SCARP:
		# One extra column pair straddling x = 0, so the discontinuity is emitted as
		# a vertical quad rather than smeared into a 0.2 m ramp by the sampling.
		var cols: PackedFloat64Array = _scarp_columns(dx)
		for ci in range(cols.size() - 1):
			for cj in range(SURFACE_RES):
				var zs: float = _z_range.x + cj * dz
				_emit_surface_quad(cols[ci], cols[ci + 1], zs, zs + dz)
	else:
		# Untouched arithmetic — same loop bounds, same `x0 + dx` recurrence, so the
		# three shipped presets emit the same vertex stream they always did.
		for i in range(SURFACE_RES):
			for j in range(SURFACE_RES):
				var x0 := _x_range.x + i * dx
				var z0 := _z_range.x + j * dz
				_emit_surface_quad(x0, x0 + dx, z0, z0 + dz)

	_surface_im.surface_end()

## The column edges for `scarp`: every normal sample except the one that lands on
## x = 0, which is replaced by a pair 0.02 mm either side of it. The quad between
## that pair spans 0.04 mm horizontally and 0.45 m vertically — a clean shear line
## running the full 8.0 m of the field.
func _scarp_columns(dx: float) -> PackedFloat64Array:
	var cols := PackedFloat64Array()
	for i in range(SURFACE_RES + 1):
		var xa: float = _x_range.x + i * dx
		if xa < -SCARP_SEAM:
			cols.append(xa)
	cols.append(-SCARP_SEAM)
	cols.append(SCARP_SEAM)
	for k in range(SURFACE_RES + 1):
		var xb: float = _x_range.x + k * dx
		if xb > SCARP_SEAM:
			cols.append(xb)
	return cols

## One surface quad, verbatim from the loop it used to live inside: two triangles,
## the 4.0 m height cap, and the low-to-high colour ramp.
func _emit_surface_quad(x0: float, x1: float, z0: float, z1: float) -> void:
	var y00 := _eval(Vector2(x0, z0)) * _y_scale
	var y10 := _eval(Vector2(x1, z0)) * _y_scale
	var y01 := _eval(Vector2(x0, z1)) * _y_scale
	var y11 := _eval(Vector2(x1, z1)) * _y_scale

	# Cap height for visualization
	y00 = minf(y00, 4.0)
	y10 = minf(y10, 4.0)
	y01 = minf(y01, 4.0)
	y11 = minf(y11, 4.0)

	var c00 := COL_SURFACE.lerp(COL_SURFACE_HI, clampf(y00 / 3.0, 0.0, 1.0))
	var c10 := COL_SURFACE.lerp(COL_SURFACE_HI, clampf(y10 / 3.0, 0.0, 1.0))
	var c01 := COL_SURFACE.lerp(COL_SURFACE_HI, clampf(y01 / 3.0, 0.0, 1.0))
	var c11 := COL_SURFACE.lerp(COL_SURFACE_HI, clampf(y11 / 3.0, 0.0, 1.0))

	var n := Vector3.UP

	# Tri 1
	_surface_im.surface_set_color(c00)
	_surface_im.surface_set_normal(n)
	_surface_im.surface_add_vertex(Vector3(x0, y00, z0))
	_surface_im.surface_set_color(c10)
	_surface_im.surface_set_normal(n)
	_surface_im.surface_add_vertex(Vector3(x1, y10, z0))
	_surface_im.surface_set_color(c01)
	_surface_im.surface_set_normal(n)
	_surface_im.surface_add_vertex(Vector3(x0, y01, z1))

	# Tri 2
	_surface_im.surface_set_color(c10)
	_surface_im.surface_set_normal(n)
	_surface_im.surface_add_vertex(Vector3(x1, y10, z0))
	_surface_im.surface_set_color(c11)
	_surface_im.surface_set_normal(n)
	_surface_im.surface_add_vertex(Vector3(x1, y11, z1))
	_surface_im.surface_set_color(c01)
	_surface_im.surface_set_normal(n)
	_surface_im.surface_add_vertex(Vector3(x0, y01, z1))

## The paths. `result` is the answer without the working and `axiom` has no
## runner to have a history, so both leave the trail mesh empty — cleared and
## never begun, rather than begun and left with no vertices.
func _draw_optimizer_trails() -> void:
	_trails_im.clear_surfaces()
	if evidence == "result" or evidence == "axiom":
		return
	_trails_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	for opt in _optimizers:
		var path: Array = opt.path
		var col: Color = opt.color
		for k in range(1, path.size()):
			var p0: Vector2 = path[k - 1]
			var p1: Vector2 = path[k]
			var y0 := minf(_eval(p0) * _y_scale + 0.05, 4.05)
			var y1 := minf(_eval(p1) * _y_scale + 0.05, 4.05)
			_im_line_3d(_trails_im, Vector3(p0.x, y0, p0.y), Vector3(p1.x, y1, p1.y), col, 0.03)

	_trails_im.surface_end()

func _draw_optimizer_markers() -> void:
	_arrows_im.clear_surfaces()
	_markers_im.clear_surfaces()

	# The four runners themselves. Present at every value except `axiom`, where
	# the whole claim is that no particular descent is being shown.
	if evidence != "axiom":
		_markers_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		for opt in _optimizers:
			var pos: Vector2 = opt.pos
			var y := minf(_eval(pos) * _y_scale + 0.1, 4.1)
			var col: Color = opt.color
			_im_diamond(_markers_im, Vector3(pos.x, y, pos.y), 0.15, col)
		_markers_im.surface_end()

	if evidence == "longhand":
		# Draw gradient arrows at current positions — the quantity each step is
		# computed from, in each runner's own colour. The shipped behaviour.
		_arrows_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		for opt in _optimizers:
			if opt.converged:
				continue
			var pos: Vector2 = opt.pos
			var grad := _gradient(pos)
			var dir := -grad.normalized()
			var y := minf(_eval(pos) * _y_scale + 0.15, 4.15)
			var tip := Vector3(pos.x + dir.x * 0.4, y, pos.y + dir.y * 0.4)
			var base := Vector3(pos.x, y, pos.y)
			_im_line_3d(_arrows_im, base, tip, opt.color as Color, 0.02)
		_arrows_im.surface_end()
	elif evidence == "axiom":
		_draw_gradient_field()


## `axiom`: -grad f sampled on the 9 x 9 lattice, with no runner anywhere.
##
## Direction is normalised, because the direction is the local truth the update
## rule consumes. LENGTH carries log|grad f| instead, and that is what makes the
## value argue rather than decorate: on `plateau` every arrow collapses toward
## the 0.12 floor because the surface has nothing to say, while on `scarp` the
## two columns either side of the face point AT EACH OTHER — the honest local
## derivative of a bowl on both sides, one of which is a lie about the cliff
## standing between them.
func _draw_gradient_field() -> void:
	_arrows_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var dx: float = (_x_range.y - _x_range.x) / float(FIELD_RES)
	var dz: float = (_z_range.y - _z_range.x) / float(FIELD_RES)

	# One pass for the scale, so the ladder is relative to THIS surface. Without
	# it Rosenbrock's 10^4 gradients and the plateau's 0.08 share a ruler and one
	# of the two is a flat field of minimum-length stubs for the wrong reason.
	var g_max: float = 0.0
	var mags: Array[float] = []
	for i in range(FIELD_RES + 1):
		for j in range(FIELD_RES + 1):
			var px: float = _x_range.x + float(i) * dx
			var pz: float = _z_range.x + float(j) * dz
			var m: float = _gradient(Vector2(px, pz)).length()
			mags.append(m)
			if m > g_max:
				g_max = m
	var denom: float = log(1.0 + maxf(g_max, 0.001))

	var k: int = 0
	for i2 in range(FIELD_RES + 1):
		for j2 in range(FIELD_RES + 1):
			var px2: float = _x_range.x + float(i2) * dx
			var pz2: float = _z_range.x + float(j2) * dz
			var p := Vector2(px2, pz2)
			var grad := _gradient(p)
			var mag: float = mags[k]
			k += 1
			if grad.length_squared() < 1e-12:
				continue
			var dir := -grad.normalized()
			var t: float = clampf(log(1.0 + mag) / denom, 0.0, 1.0)
			var arrow_len: float = 0.12 + 0.28 * t
			var y: float = minf(_eval(p) * _y_scale + 0.15, 4.15)
			var base := Vector3(p.x, y, p.y)
			var tip := Vector3(p.x + dir.x * arrow_len, y, p.y + dir.y * arrow_len)
			_im_line_3d(_arrows_im, base, tip, COL_FIELD, 0.02)

	_arrows_im.surface_end()

func _draw_convergence_trails() -> void:
	_trails_im.clear_surfaces()
	_trails_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	for run in _conv_runs:
		var path: Array = run.path
		var col: Color = run.color
		for k in range(1, path.size()):
			var p0: Vector2 = path[k - 1]
			var p1: Vector2 = path[k]
			var y0 := minf(_eval(p0) * _y_scale + 0.05, 4.05)
			var y1 := minf(_eval(p1) * _y_scale + 0.05, 4.05)
			_im_line_3d(_trails_im, Vector3(p0.x, y0, p0.y), Vector3(p1.x, y1, p1.y), col, 0.025)

	_trails_im.surface_end()

	# Markers
	_markers_im.clear_surfaces()
	_markers_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for run in _conv_runs:
		var pos: Vector2 = run.pos
		var y := minf(_eval(pos) * _y_scale + 0.1, 4.1)
		_im_diamond(_markers_im, Vector3(pos.x, y, pos.y), 0.12, run.color as Color)
	_markers_im.surface_end()

func _draw_convergence_chart() -> void:
	# Draw f(x) over iterations as small chart using arrows mesh.
	#
	# With the console on, this is not a plot standing in the air off the right
	# edge of a horizontal artifact — it is a routed TRACE CHANNEL in the right
	# curb, a chart-recorder trough read by looking down as you walk the edge.
	# Same log-normalisation, same per-run colours, same axes; only the basis
	# changes: iteration runs along +Z down the tray, value across it in +X.
	_arrows_im.clear_surfaces()
	_arrows_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var chart_origin: Vector3
	var u_axis: Vector3
	var v_axis: Vector3
	var span_u: float
	var span_v: float
	if show_console:
		chart_origin = Vector3(_x_range.y + 0.07, deck_height + 0.052, -1.25)
		u_axis = Vector3(0, 0, 1)
		v_axis = Vector3(1, 0, 0)
		span_u = 2.50
		span_v = 0.26
	else:
		chart_origin = Vector3(_x_range.y + 1.0, 0.0, _z_range.x)
		u_axis = Vector3(1, 0, 0)
		v_axis = Vector3(0, 1, 0)
		span_u = 2.5
		span_v = 2.5

	# Axes
	_im_line_3d(_arrows_im, chart_origin, chart_origin + u_axis * span_u, COL_GRID, 0.02)
	_im_line_3d(_arrows_im, chart_origin, chart_origin + v_axis * span_v, COL_GRID, 0.02)

	for run in _conv_runs:
		var vals: Array = run.values
		if vals.size() < 2:
			continue
		var max_v := 0.001
		for v_item in vals:
			var vf: float = v_item
			if vf > max_v:
				max_v = vf
		for k in range(1, vals.size()):
			var u0: float = (float(k - 1) / float(TRAIL_MAX)) * span_u
			var u1: float = (float(k) / float(TRAIL_MAX)) * span_u
			var y0_val: float = vals[k - 1]
			var y1_val: float = vals[k]
			var t0: float = clampf(log(y0_val + 1.0) / log(max_v + 1.0), 0.0, 1.0)
			var t1: float = clampf(log(y1_val + 1.0) / log(max_v + 1.0), 0.0, 1.0)
			var pa: Vector3 = chart_origin + u_axis * u0 + v_axis * (t0 * span_v)
			var pb: Vector3 = chart_origin + u_axis * u1 + v_axis * (t1 * span_v)
			_im_line_3d(_arrows_im, pa, pb, run.color as Color, 0.015)

	_arrows_im.surface_end()

func _draw_hessian() -> void:
	_hessian_im.clear_surfaces()
	_hessian_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	for h in _hessian_grid:
		var pos: Vector2 = h.pos
		var y := minf(_eval(pos) * _y_scale + 0.1, 4.1)
		var center := Vector3(pos.x, y, pos.y)
		var l1: float = h.l1
		var l2: float = h.l2
		var v1: Vector2 = h.v1
		var v2: Vector2 = h.v2

		# Scale eigenvalue visualization
		var scale := 0.3
		var len1 := clampf(abs(l1) * _y_scale * 2.0, 0.05, 0.8) * scale
		var len2 := clampf(abs(l2) * _y_scale * 2.0, 0.05, 0.8) * scale

		var c1 := COL_HESSIAN_P if l1 >= 0 else COL_HESSIAN_N
		var c2 := COL_HESSIAN_P if l2 >= 0 else COL_HESSIAN_N

		# Draw eigenvector 1
		var e1a := center + Vector3(v1.x, 0, v1.y) * len1
		var e1b := center - Vector3(v1.x, 0, v1.y) * len1
		_im_line_3d(_hessian_im, e1a, e1b, c1, 0.025)

		# Draw eigenvector 2
		var e2a := center + Vector3(v2.x, 0, v2.y) * len2
		var e2b := center - Vector3(v2.x, 0, v2.y) * len2
		_im_line_3d(_hessian_im, e2a, e2b, c2, 0.025)

	_hessian_im.surface_end()

func _draw_hessian_markers() -> void:
	_markers_im.clear_surfaces()
	_markers_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	for h in _hessian_grid:
		var pos: Vector2 = h.pos
		var y := minf(_eval(pos) * _y_scale + 0.1, 4.1)
		var l1: float = h.l1
		var l2: float = h.l2
		# Color by definiteness: both positive = blue, mixed = yellow, both negative = red
		var col: Color
		if l1 >= 0 and l2 >= 0:
			col = COL_HESSIAN_P
		elif l1 < 0 and l2 < 0:
			col = COL_HESSIAN_N
		else:
			col = Color(0.9, 0.8, 0.2, 0.9)  # saddle = yellow
		_im_diamond(_markers_im, Vector3(pos.x, y, pos.y), 0.06, col)

	_markers_im.surface_end()

# ════════════════════════════════════════════════════════════════════════
#  IMMEDIATE MESH HELPERS
# ════════════════════════════════════════════════════════════════════════

func _im_line_3d(im: ImmediateMesh, a: Vector3, b: Vector3, col: Color, w: float) -> void:
	var dir := (b - a)
	if dir.length_squared() < 1e-8:
		return
	dir = dir.normalized()
	var up := Vector3.UP
	if abs(dir.dot(up)) > 0.99:
		up = Vector3.FORWARD
	var side := dir.cross(up).normalized() * w * 0.5
	var u := up.cross(dir).normalized() * w * 0.5

	# Quad 1 (horizontal)
	im.surface_set_color(col)
	im.surface_set_normal(up)
	im.surface_add_vertex(a - side)
	im.surface_set_color(col)
	im.surface_set_normal(up)
	im.surface_add_vertex(a + side)
	im.surface_set_color(col)
	im.surface_set_normal(up)
	im.surface_add_vertex(b + side)

	im.surface_set_color(col)
	im.surface_set_normal(up)
	im.surface_add_vertex(a - side)
	im.surface_set_color(col)
	im.surface_set_normal(up)
	im.surface_add_vertex(b + side)
	im.surface_set_color(col)
	im.surface_set_normal(up)
	im.surface_add_vertex(b - side)

	# Quad 2 (vertical)
	im.surface_set_color(col)
	im.surface_set_normal(side.normalized())
	im.surface_add_vertex(a - u)
	im.surface_set_color(col)
	im.surface_set_normal(side.normalized())
	im.surface_add_vertex(a + u)
	im.surface_set_color(col)
	im.surface_set_normal(side.normalized())
	im.surface_add_vertex(b + u)

	im.surface_set_color(col)
	im.surface_set_normal(side.normalized())
	im.surface_add_vertex(a - u)
	im.surface_set_color(col)
	im.surface_set_normal(side.normalized())
	im.surface_add_vertex(b + u)
	im.surface_set_color(col)
	im.surface_set_normal(side.normalized())
	im.surface_add_vertex(b - u)

func _im_diamond(im: ImmediateMesh, center: Vector3, size: float, col: Color) -> void:
	var s := size
	var top := center + Vector3(0, s, 0)
	var bot := center - Vector3(0, s * 0.5, 0)
	var pts := [
		center + Vector3(s, 0, 0),
		center + Vector3(0, 0, s),
		center + Vector3(-s, 0, 0),
		center + Vector3(0, 0, -s),
	]
	for i in 4:
		var next := (i + 1) % 4
		# Upper face
		im.surface_set_color(col)
		im.surface_set_normal(Vector3.UP)
		im.surface_add_vertex(top)
		im.surface_set_color(col)
		im.surface_set_normal(Vector3.UP)
		im.surface_add_vertex(pts[i])
		im.surface_set_color(col)
		im.surface_set_normal(Vector3.UP)
		im.surface_add_vertex(pts[next])
		# Lower face
		im.surface_set_color(col * 0.7)
		im.surface_set_normal(-Vector3.UP)
		im.surface_add_vertex(bot)
		im.surface_set_color(col * 0.7)
		im.surface_set_normal(-Vector3.UP)
		im.surface_add_vertex(pts[next])
		im.surface_set_color(col * 0.7)
		im.surface_set_normal(-Vector3.UP)
		im.surface_add_vertex(pts[i])

# ════════════════════════════════════════════════════════════════════════
#  LABELS
# ════════════════════════════════════════════════════════════════════════

func _update_labels() -> void:
	var mode_names := ["Optimizer Variants", "Convergence Analysis", "Hessian Eigenvalues"]
	var mode_name: String = str(mode_names[_mode])
	var title_text: String = "Gradient Descent — " + mode_name
	var info_text: String = ""
	var legend_text: String = ""
	# The key strip is the legend the sentence was always standing in for:
	# one chip per runner, in the phenomenon's own colour, with its name.
	var legend_entries: Array = []

	match _mode:
		Mode.OPTIMIZERS:
			if evidence == "axiom":
				# The runners are still stepping under the hood, but none of them
				# is in the frame. A readout rolling off four positions nobody can
				# see, under a key strip naming four colours nobody can see, would
				# be the label contradicting the picture.
				# ASCII only: this string is baked by HangarKit.readout, and the
				# em-dash the title uses never reaches the baker (the console
				# title path returns early), so it is untested in this font.
				info_text = "f(x,y) = %s  |  -grad f on a %d x %d lattice\nno optimizer placed - direction is the local truth,\nlength is log|grad f| relative to this surface" % [
					_fn_name(), FIELD_RES + 1, FIELD_RES + 1]
				legend_text = "the rule, not the run"
				legend_entries.append({"label": "-GRAD f", "color": COL_FIELD})
			else:
				info_text = "f(x,y) = %s  |  lr=%.4f  b=%.2f  step=%d" % [_fn_name(), learning_rate, momentum_beta, _step_count]
				for opt in _optimizers:
					var status := "converged" if opt.converged else "f=%.4f" % [opt.value as float]
					info_text += "\n%s: (%.2f, %.2f) %s" % [opt.name, (opt.pos as Vector2).x, (opt.pos as Vector2).y, status]
				legend_text = "Red=SGD  Green=Momentum  Blue=Nesterov  Gold=Adam"
				for opt2 in _optimizers:
					legend_entries.append({"label": str(opt2.name).to_upper(), "color": opt2.color as Color})

		Mode.CONVERGENCE:
			info_text = "Adam on %s  |  b1=%.2f  b2=%.3f  step=%d" % [_fn_name(), adam_beta1, adam_beta2, _step_count]
			for run in _conv_runs:
				var val := _eval(run.pos as Vector2)
				info_text += "\nlr=%.3f: f=%.4f%s" % [run.lr as float, val, " *" if run.converged else ""]
			legend_text = "5 learning rates compared — log(f) chart on right"
			for run2 in _conv_runs:
				legend_entries.append({"label": "LR %.3f" % [run2.lr as float], "color": run2.color as Color})

		Mode.HESSIAN:
			info_text = "f(x,y) = %s  |  Hessian at %d x %d grid points\nBlue=positive definite  Red=negative  Yellow=saddle" % [_fn_name(), 9, 9]
			legend_text = "Line length ~ |eigenvalue|  Direction = eigenvector"
			legend_entries.append({"label": "POSITIVE DEFINITE", "color": COL_HESSIAN_P})
			legend_entries.append({"label": "SADDLE", "color": Color(0.9, 0.8, 0.2, 0.9)})
			legend_entries.append({"label": "NEGATIVE DEFINITE", "color": COL_HESSIAN_N})

	var legend_key: String = legend_text
	if show_console:
		var parts: PackedStringArray = PackedStringArray()
		for e in legend_entries:
			parts.append(str((e as Dictionary).get("label", "")))
		legend_key = "|".join(parts)

	_rebuild_title(title_text)
	_rebuild_info(mode_name.to_upper(), info_text)
	_rebuild_legend(legend_key, legend_text, legend_entries)

## The permanent name is INLAID FLAT in the near curb, built once by
## _create_console; the readout header owns the live mode. So with the console
## on, this live rebuild path is retired — a second title is a second object.
func _rebuild_title(text: String) -> void:
	if show_console:
		return
	if text == _title_cache and _title_node != null:
		return
	_title_cache = text
	if _title_node != null:
		_title_node.queue_free()
		_title_node = null
	var tag: Node3D = BakedText.make_tag(text, TITLE_COLOR, 0.32, Color(0.08, 0.09, 0.11), true, Color(0.86, 0.40, 0.16))
	if tag:
		_title_node = tag
		_title_root.add_child(tag)

## Regenerate the telemetry when it changes. With the console on it is the
## framed instrument screen sunk in the near bay — the header carries the live
## mode name, the lines carry the figures. The billboard flag is gone: a sunk
## screen that turns to face you is what made the old board float.
func _rebuild_info(header: String, text: String) -> void:
	var key: String = header + "\n" + text
	if key == _info_cache and _info_node != null:
		return
	_info_cache = key
	if _info_node != null:
		_info_node.queue_free()
		_info_node = null
	var block: Node3D = null
	if show_console:
		var pal: Dictionary = HangarKit.finish_palette(finish)
		var pal_text: Color = pal["text"]
		var pal_accent: Color = pal["accent"]
		block = HangarKit.readout(header, Array(text.split("\n")),
			Vector2(1.30, 0.30), Color(0.04, 0.05, 0.08), pal_text, pal_accent, finish)
	else:
		block = _make_billboard_block(text, INFO_COLOR, 0.18, 4.4)
	if block:
		_info_node = block
		_info_root.add_child(block)

## Regenerate the legend when it changes. With the console on it is the key
## strip milled into the near curb: emissive chips in the phenomenon's own
## constants, each named. These are the only saturated colours on the body and
## they sit in a dark pocket — they never touch the off-white shell.
func _rebuild_legend(key: String, text: String, entries: Array) -> void:
	if key == _legend_cache and _legend_node != null:
		return
	_legend_cache = key
	if _legend_node != null:
		_legend_node.queue_free()
		_legend_node = null
	var block: Node3D = null
	if show_console:
		block = _make_key_strip(entries)
	else:
		block = _make_billboard_block(text, LEGEND_COLOR, 0.15, 4.4)
	if block:
		_legend_node = block
		_legend_root.add_child(block)

## The key strip's contents: one emissive chip per runner in its own colour,
## with the name stencilled beside it. Built in the strip's local plane; the
## anchor supplies the -80 degree tilt into the milled pocket.
func _make_key_strip(entries: Array) -> Node3D:
	var root := Node3D.new()
	root.name = "KeyStrip"
	var n: int = entries.size()
	if n == 0:
		return root
	var strip_w: float = 0.62
	var strip_h: float = 0.20
	var pitch: float = minf(0.040, (strip_h - 0.030) / float(n))
	var top_y: float = float(n - 1) * pitch * 0.5
	for i in range(n):
		var e: Dictionary = entries[i]
		var c: Color = e.get("color", Color(0.86, 0.34, 0.11))
		var ry: float = top_y - float(i) * pitch
		root.add_child(HangarKit.box(
			Vector3(-strip_w * 0.5 + 0.032, ry, 0.005),
			Vector3(0.026, 0.026, 0.005), HangarKit.emissive(c, 1.4)))
		var lbl: MeshInstance3D = HangarKit.stencil(str(e.get("label", "")),
			Vector2(0.44, 0.024), Color(0.90, 0.89, 0.85))
		if lbl != null:
			lbl.position = Vector3(-strip_w * 0.5 + 0.282, ry, 0.005)
			root.add_child(lbl)
	return root

## Build a multi-line baked text block and billboard every line quad so the
## readout always faces the viewer (the make_text_block quads face +Z).
func _make_billboard_block(text: String, color: Color, line_h: float, max_w: float) -> Node3D:
	var lines: Array = Array(text.split("\n"))
	var block: Node3D = BakedText.make_text_block(lines, color, line_h, max_w, line_h * 0.35, true)
	if block == null:
		return null
	for child in block.get_children():
		if child is MeshInstance3D:
			var m = child.material_override
			if m is StandardMaterial3D:
				m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	return block

# ════════════════════════════════════════════════════════════════════════
#  GRID CONFIG
# ════════════════════════════════════════════════════════════════════════

func apply_grid_config(config: Dictionary) -> void:
	# Snapshot everything before touching it. This arrives via call_deferred AFTER
	# _ready(), and curation_station hands EVERY artifact it curates
	# {"emissive": false} one line after framing its labels — a dict with no key
	# this artifact accepts, which must therefore change nothing at all. It is not
	# accepted here precisely so that it cannot half-work: an accepted key that
	# applies nowhere is the failure this guard was written after.
	var before_basin: String = basin
	var before_preset: int = function_preset
	var before_mode: int = _mode
	var before_lr: float = learning_rate
	var before_mb: float = momentum_beta
	var before_b1: float = adam_beta1
	var before_b2: float = adam_beta2
	var before_ss: float = step_speed

	# ── Stage-2 DNA axis — `#evidence:axiom` ───────────────────────────────
	# Deliberately NOT part of the rebuild test below. Every value of `evidence`
	# is a branch in the per-frame draw, so the standing body is correct for all
	# four already; rebuilding for it would free and rebuild an 8 m console to
	# change which ImmediateMesh gets vertices next frame.
	if config.has("evidence"):
		evidence = _pick_axis(str(config["evidence"]), EVIDENCE, evidence)

	# ── Stage-2 DNA axis — `#basin:plateau` ────────────────────────────────
	if config.has("basin"):
		basin = _pick_axis(str(config["basin"]), BASINS, basin)
		function_preset = int(BASIN_PRESET.get(basin, FN_BOWL))

	# The legacy int/string route, still working, extended to the five. `basin` is
	# renamed to follow it so the word and the int cannot disagree afterwards.
	if config.has("function_preset"):
		var fp = config["function_preset"]
		if fp is int:
			function_preset = clampi(fp, 0, BASINS.size() - 1)
		elif fp is String:
			match (fp as String).to_lower():
				"quadratic", "bowl": function_preset = FN_BOWL
				"rosenbrock", "valley": function_preset = FN_VALLEY
				"himmelblau", "plural": function_preset = FN_PLURAL
				"plateau": function_preset = FN_PLATEAU
				"scarp": function_preset = FN_SCARP
		basin = BASINS[clampi(function_preset, 0, BASINS.size() - 1)]

	# ── the temporal params, applied IN PLACE ──────────────────────────────
	if config.has("learning_rate"):
		learning_rate = clampf(float(config["learning_rate"]), 0.0001, 0.5)
	if config.has("momentum_beta"):
		momentum_beta = clampf(float(config["momentum_beta"]), 0.0, 0.999)
	if config.has("adam_beta1"):
		adam_beta1 = clampf(float(config["adam_beta1"]), 0.0, 0.999)
	if config.has("adam_beta2"):
		adam_beta2 = clampf(float(config["adam_beta2"]), 0.0, 0.9999)
	if config.has("step_speed"):
		step_speed = clampf(float(config["step_speed"]), 0.1, 10.0)

	if config.has("mode"):
		var m := str(config["mode"]).to_upper()
		match m:
			"OPTIMIZERS": _mode = Mode.OPTIMIZERS
			"CONVERGENCE": _mode = Mode.CONVERGENCE
			"HESSIAN": _mode = Mode.HESSIAN

	if not _built:
		return

	if basin == before_basin and function_preset == before_preset:
		# No standing geometry changed, so the body stays exactly as built. The
		# runners still need re-seeding if a temporal param moved.
		var temporal_moved: bool = (_mode != before_mode)
		temporal_moved = temporal_moved or (learning_rate != before_lr)
		temporal_moved = temporal_moved or (momentum_beta != before_mb)
		temporal_moved = temporal_moved or (adam_beta1 != before_b1)
		temporal_moved = temporal_moved or (adam_beta2 != before_b2)
		temporal_moved = temporal_moved or (step_speed != before_ss)
		if temporal_moved:
			_init_mode()
		return

	_rebuild_now()
	print("[GradientDescent] Config applied — basin=%s (preset %d, %s)" % [
		basin, function_preset, _fn_name()])


## Accept an axis value only if it names something this artifact actually builds.
## A typo has to fall back to the shipped look; a half-recognised value would
## strand a placement showing a surface nobody asked for.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback
