extends "res://algorithms/vectors/shared/vector_scene_base.gd"

class_name StretchBench

# The Stretch Bench (scalar_stretch_bench)  —  concept: scalar multiplication  k * v
#
# @identity
# essence: (k*v) = (k*vx, k*vy, k*vz). One scalar dial drives one vector. Scalar
#   multiplication only ever touches LENGTH and SIGN — never the line the vector
#   lies on. |k*v| = |k| * |v|, always.
# desire: To turn one brass crank and watch the twin arrow stretch past v's tick,
#   shrink back through the origin, collapse to a glowing dot at k=0, and flip 180
#   degrees through its own tail when k goes negative.
# critical_parameter: k in [-3, +3]. The three landmarks — k=+1 (identity, the twins
#   coincide), k=0 (collapse to the origin dot), k=-1 (perfect mirror) — are the
#   whole lesson, felt as detents under the hand.
# triggers: drag the brass crank along the graduated rail (the scalar's POSITION on
#   the number line IS the input); or drive the desktop slider labelled "k". The
#   amber base v is grabbable to re-aim the reference line; the twin k*v snaps to it
#   and is never grabbable.
# emerges: the realisation that the amber twin always lies on v's line — scaling is
#   not rotation. Negative k is reversal, |k|>1 is stretch, |k|<1 is shrink, k=0 is
#   collapse. The etched ghost-lattice (-2v..3v) is the field the dial sweeps.
# truth: To multiply a vector by a number is to choose a length and a direction-sign
#   on a line you have already drawn. The line is given; the dial chooses where on it.

# ── Color language (fixed across the Vector Bench) ───────────────────────────
var base_color: Color = Color(1.0, 0.72, 0.22)         # warm amber  — the INPUT vector v (grabbable)
var twin_color: Color = Color(0.55, 0.7, 1.0)          # cyan-violet — the DERIVED twin k*v (k >= 0)
var twin_flip_color: Color = Color(1.0, 0.35, 0.3)     # red         — the twin when k < 0 (reversed through the tail)
var slate_color: Color = Color(0.10, 0.11, 0.14)       # dark slate pedestal
var brass_color: Color = Color(0.78, 0.62, 0.28)       # brass rim / crank / dial
var lattice_color: Color = Color(0.45, 0.5, 0.58)      # etched integer ground-lattice hairlines

# ── DNA axes (stage 2, promoted 2026-08-05) ──────────────────────────────────
# regime: WHICH NAMED CASE of k the bench is standing at. The whole content of
#   scalar multiplication is what k does to a vector, and this file already names
#   the cases in prose four times over — the @identity ("k=+1 identity, k=0
#   collapse, k=-1 perfect mirror … the three landmarks are the whole lesson"),
#   the info panel's "k<0 reverses / k=0 collapses", the twin's red flip colour,
#   and _refresh_text's REVERSED / COLLAPSED / same way. Every one of them was a
#   case the bench could only reach if a player turned the crank; a map could
#   place the bench and never argue anything but k=1. The rail genuinely reaches
#   them: it is etched -3v..3v at every integer, _k_to_rail_x maps the full
#   [min_k, max_k] onto it, and the crank, bead and needle all ride that map, so
#   the negative half is a real position on a real number line and not a promise.
#     identity — k = +1: the twin lies exactly on v (what this always opened at).
#     stretch  — k = +2: |k|>1, the twin overshoots v's tick to the 2v lattice line.
#     shrink   — k = +0.5: 0<|k|<1, the twin falls short, inside v.
#     collapse — k = 0: the twin vanishes and the glowing origin dot appears.
#     reversal — k = -1: the twin flips through its own tail and turns red.
# workings: how much of the construction the bench draws. `workings` with these
#   four values in this order is the Vector Bench's word — length_lantern, its
#   HOUSING sibling (same slate plinth, same brass rim, same etched integer
#   lattice, standing beside it in Force_Preview), plus adder_board, vector_add,
#   vector_sub, dot_aligner and projection_shadow. The scaffolding here was never
#   optional: the ghost lattice, the amber operand, the dial and the panel were
#   hard-wired to go up together, so a room could not show a scaled vector as a
#   bare result and had to teach the whole apparatus or nothing.
#     outcome    — the twin k*v alone on its plinth. The result asserted.
#     trace      — + the etched -3v..3v lattice and the bead: the field k sweeps.
#     operands   — + the amber v and the crank: what the scalar is acting on.
#     expression — + the dial, the readout and the panel (what this always drew).
const REGIME_VALUES: Array = ["identity", "stretch", "shrink", "collapse", "reversal"]
const REGIME_K: Dictionary = {
	"identity": 1.0,
	"stretch": 2.0,
	"shrink": 0.5,
	"collapse": 0.0,
	"reversal": -1.0,
}
const WORKINGS_VALUES: Array = ["outcome", "trace", "operands", "expression"]

@export_enum("identity", "stretch", "shrink", "collapse", "reversal") var regime: String = "identity"
@export_enum("outcome", "trace", "operands", "expression") var workings: String = "expression"

# ── Tunable DNA (overridable via apply_grid_config) ──────────────────────────
var default_k: float = 1.0
var min_k: float = -3.0
var max_k: float = 3.0
var base_vector: Vector3 = Vector3(0.6, 0.4, 0.0)      # fixed reference v in the rail plane (logical units)
var housed: bool = false                               # seat the control plate INSIDE a ControlConsole cabinet

# ── Runtime state ────────────────────────────────────────────────────────────
var _k: float = 1.0
var _snap_integers: bool = false

# Geometry constants (LOGICAL space, pre-SCENE_SCALE). Mirrors catapult arrow build.
const ARROW_THICKNESS: float = 0.018
const RAIL_HALF_LEN: float = 1.2                       # the number line spans k in [-3, +3] over +/- this
const PLINTH_TOP_Y: float = 0.9                        # bench surface height (logical)

# ── Node references ──────────────────────────────────────────────────────────
var _base_arrow: Node3D = null                         # amber v  (grabbable endpoint)
var _twin_arrow: Node3D = null                         # k*v      (built catapult-style, never grabbable)
var _collapse_dot: MeshInstance3D = null               # glowing dot shown at k == 0
var _crank: Node3D = null                              # brass crank that slides along the rail (the k input)
var _crank_grab: Area3D = null                         # grab area on the crank
var _bead: MeshInstance3D = null                       # bead on the number line at k
var _dial_needle: Node3D = null                        # rotating needle on the brass "k" dial
var _slider: Node3D = null                             # desktop / accessibility fallback control
var _snap_button: Node3D = null                        # SNAP integer-lock toggle
var _lattice: Node3D = null                            # etched integer ticks + their ghost labels
var _dial: Node3D = null                               # the brass "k" dial assembly
var _info_panel: Node3D = null                         # the two-column info panel behind the bench
var _info_label: Label = null   # 2D live-data column on the info panel (2D-in-3D)
var _readout_label: Label = null   # 2D Label on the plate's 2D-in-3D display
var _k_dial_label: Label3D = null

# Caches for the grabbable base vector (so we read v cheaply each frame).
var _base_start: Node3D = null
var _base_end: Node3D = null

# Crank drag state (VR grab along the rail).
var _crank_dragging: bool = false

# Throttle text updates (~0.1s, per the shared spine convention).
var _time_since_text: float = 0.0
const TEXT_INTERVAL: float = 0.1

const SLIDER_SCENE_LOCAL := preload("res://commons/interactables/slider_horizontal.tscn")
const BUTTON_SCENE_LOCAL := preload("res://commons/interactables/push_button.tscn")
const ControlPanelScript = preload("res://commons/ui/control_panel.gd")
const ControlConsoleScript = preload("res://commons/ui/control_console.gd")


# ═══════════════════════════════════════════════════════════════════════════
# LIFECYCLE  —  base _ready() calls build_scene()
# ═══════════════════════════════════════════════════════════════════════════

func build_scene() -> void:
	# Scaled exhibition presentation; base_scale() == 0.5 * scale_multiplier.
	scale = base_scale()

	_k = clampf(_regime_k(), min_k, max_k)

	_build_pedestal()
	_build_rail_and_lattice()
	_build_dial()
	_build_vectors()
	_build_crank()
	_build_number_line()
	_build_controls()
	_build_panels()

	_refresh_all()
	_apply_workings()


func _process(delta: float) -> void:
	# The base vector v is grabbable; re-read it each frame so the twin tracks the
	# line the player re-aims. (Reading the grab sphere is cheap.)
	_refresh_geometry()

	_time_since_text += delta
	if _time_since_text >= TEXT_INTERVAL:
		_time_since_text = 0.0
		_refresh_text()


# ═══════════════════════════════════════════════════════════════════════════
# BENCH GEOMETRY  —  dark slate pedestal + brass rim
# ═══════════════════════════════════════════════════════════════════════════

func _build_pedestal() -> void:
	var bench := Node3D.new()
	bench.name = "Bench"
	environment_root.add_child(bench)

	var sc := SCENE_SCALE
	var slate_mat := _make_material(slate_color, 0.0, 0.7, 0.25)
	var brass_mat := _make_material(brass_color, 0.25, 0.35, 0.85)

	# Plinth body — a low slate block the rail sits on.
	var plinth := MeshInstance3D.new()
	plinth.name = "Plinth"
	var plinth_box := BoxMesh.new()
	plinth_box.size = Vector3(2.8, PLINTH_TOP_Y, 0.7) * sc
	plinth.mesh = plinth_box
	plinth.material_override = slate_mat
	plinth.position = Vector3(0.0, PLINTH_TOP_Y * 0.5, 0.0) * sc
	bench.add_child(plinth)

	# Brass rim — a thin frame around the top edge of the plinth.
	var rim_y := PLINTH_TOP_Y
	var rim_thick := 0.04
	var rim_depth := 0.06
	# Two long rims (front/back along X), two short rims (left/right along Z).
	for z_mult in [-1.0, 1.0]:
		var rim := MeshInstance3D.new()
		var rim_box := BoxMesh.new()
		rim_box.size = Vector3(2.8, rim_depth, rim_thick) * sc
		rim.mesh = rim_box
		rim.material_override = brass_mat
		rim.position = Vector3(0.0, rim_y, z_mult * 0.35) * sc
		bench.add_child(rim)
	for x_mult in [-1.0, 1.0]:
		var rim2 := MeshInstance3D.new()
		var rim2_box := BoxMesh.new()
		rim2_box.size = Vector3(rim_thick, rim_depth, 0.7) * sc
		rim2.mesh = rim2_box
		rim2.material_override = brass_mat
		rim2.position = Vector3(x_mult * 1.4, rim_y, 0.0) * sc
		bench.add_child(rim2)


func _build_rail_and_lattice() -> void:
	var rail := Node3D.new()
	rail.name = "Rail"
	environment_root.add_child(rail)

	var sc := SCENE_SCALE
	var brass_mat := _make_material(brass_color, 0.2, 0.35, 0.85)
	var rail_y := PLINTH_TOP_Y + 0.05

	# The graduated rail — a brass bar running along X (the number line for k).
	var bar := MeshInstance3D.new()
	bar.name = "GraduatedRail"
	var bar_box := BoxMesh.new()
	bar_box.size = Vector3(RAIL_HALF_LEN * 2.0 + 0.1, 0.02, 0.04) * sc
	bar.mesh = bar_box
	bar.material_override = brass_mat
	bar.position = Vector3(0.0, rail_y, 0.0) * sc
	rail.add_child(bar)

	# Etched integer ground-lattice: a hairline tick + ghost label at every integer
	# multiple of k from -3..3. This is the field the crank sweeps through; the
	# player sees -2v, -1v, 0, 1v, 2v, 3v marked on the rail before they ever move.
	# Grouped under one node so `workings` can take the whole field off in a single
	# flag; the node carries no transform of its own, so every tick and label sits
	# where it always sat.
	_lattice = Node3D.new()
	_lattice.name = "Lattice"
	rail.add_child(_lattice)

	var lattice_mat := _make_material(lattice_color, 0.4, 0.4, 0.2)
	for ki in range(int(round(min_k)), int(round(max_k)) + 1):
		var x := _k_to_rail_x(float(ki))
		# Hairline tick standing up from the rail.
		var tick := MeshInstance3D.new()
		var tick_box := BoxMesh.new()
		var tick_h := 0.14 if ki == 0 else (0.10 if (ki == 1 or ki == -1) else 0.07)
		tick_box.size = Vector3(0.008, tick_h, 0.05) * sc
		tick.mesh = tick_box
		tick.material_override = lattice_mat
		tick.position = Vector3(x * sc, rail_y * sc + tick_h * 0.5 * sc, 0.0)
		_lattice.add_child(tick)

		# Etched integer label under each tick.
		var lbl := _make_label(_format_int_label(ki), lattice_color, 16)
		lbl.position = Vector3(x * sc, (rail_y - 0.06) * sc, 0.06 * sc)
		_lattice.add_child(lbl)


# ═══════════════════════════════════════════════════════════════════════════
# THE BRASS "k" DIAL  (a readout dial with a rotating needle)
# ═══════════════════════════════════════════════════════════════════════════

func _build_dial() -> void:
	var dial := Node3D.new()
	dial.name = "KDial"
	# Stands at the right end of the rail, tilted toward the player.
	dial.position = Vector3(1.55, PLINTH_TOP_Y + 0.28, 0.0) * SCENE_SCALE
	dial.rotation_degrees = Vector3(-18.0, 0.0, 0.0)
	environment_root.add_child(dial)
	_dial = dial

	var sc := SCENE_SCALE
	var brass_mat := _make_material(brass_color, 0.25, 0.3, 0.9)

	# Dial face.
	var face := MeshInstance3D.new()
	var face_cyl := CylinderMesh.new()
	face_cyl.top_radius = 0.16
	face_cyl.bottom_radius = 0.16
	face_cyl.height = 0.02
	face.mesh = face_cyl
	face.material_override = _make_material(slate_color, 0.0, 0.6, 0.3)
	face.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)  # face the player (lay flat -> upright)
	face.scale = Vector3.ONE * sc
	dial.add_child(face)

	# Brass rim of the dial.
	var ring := MeshInstance3D.new()
	var ring_torus := TorusMesh.new()
	ring_torus.inner_radius = 0.15
	ring_torus.outer_radius = 0.18
	ring.mesh = ring_torus
	ring.material_override = brass_mat
	ring.scale = Vector3.ONE * sc
	dial.add_child(ring)

	# Rotating needle pivot — points to the current k on the dial.
	_dial_needle = Node3D.new()
	_dial_needle.name = "Needle"
	dial.add_child(_dial_needle)
	var needle := MeshInstance3D.new()
	var needle_box := BoxMesh.new()
	needle_box.size = Vector3(0.012, 0.15, 0.012) * sc
	needle.mesh = needle_box
	needle.material_override = _make_material(twin_color, 0.6, 0.3, 0.2)
	needle.position = Vector3(0.0, 0.075, 0.0) * sc  # offset so it sweeps from the centre
	_dial_needle.add_child(needle)

	# "k" caption + live numeric value on the dial.
	_k_dial_label = _make_label("k", brass_color, 22)
	_k_dial_label.position = Vector3(0.0, -0.22 * sc, 0.02 * sc)
	dial.add_child(_k_dial_label)


# ═══════════════════════════════════════════════════════════════════════════
# THE VECTORS  —  amber v (grabbable) + cyan/red twin k*v (catapult-style)
# ═══════════════════════════════════════════════════════════════════════════

func _build_vectors() -> void:
	# Lift both vectors to sit on the bench surface; the shared origin marker is at
	# the world origin, so we place an arrow origin at the bench's left datum.
	var origin := _v_origin()

	# Base vector v — grabbable endpoint so the player can re-aim the reference line.
	_base_arrow = spawn_vector(origin, origin + base_vector, base_color, "v (base)", true)
	_base_start = _base_arrow.get_node_or_null("lineContainer/GrabSphere")
	_base_end = _base_arrow.get_node_or_null("lineContainer/GrabSphere2")

	# Twin k*v — built catapult-style (shaft + cone) so we can recolour and reverse
	# it freely. NEVER grabbable: it snaps to k*v every frame.
	_twin_arrow = _create_arrow("TwinArrow", twin_color)
	add_child(_twin_arrow)

	# Collapse dot — a glowing dot shown at the origin when k == 0.
	_collapse_dot = MeshInstance3D.new()
	_collapse_dot.name = "CollapseDot"
	var dot_sphere := SphereMesh.new()
	dot_sphere.radius = 0.04
	dot_sphere.height = 0.08
	_collapse_dot.mesh = dot_sphere
	_collapse_dot.material_override = _make_material(twin_color, 1.2, 0.2, 0.0)
	_collapse_dot.position = origin * SCENE_SCALE
	_collapse_dot.visible = false
	add_child(_collapse_dot)


# ═══════════════════════════════════════════════════════════════════════════
# THE CRANK  —  judge's improvement: a grabbable crank that slides along the
# rail, so the scalar's POSITION on the number line IS the input gesture.
# (slider_horizontal stays wired as the desktop / accessibility fallback.)
# ═══════════════════════════════════════════════════════════════════════════

func _build_crank() -> void:
	_crank = Node3D.new()
	_crank.name = "Crank"
	add_child(_crank)

	var sc := SCENE_SCALE
	var brass_mat := _make_material(brass_color, 0.35, 0.25, 0.95)

	# Crank body — a brass knob with a stem, riding the rail.
	var stem := MeshInstance3D.new()
	var stem_cyl := CylinderMesh.new()
	stem_cyl.top_radius = 0.03
	stem_cyl.bottom_radius = 0.03
	stem_cyl.height = 0.14
	stem.mesh = stem_cyl
	stem.material_override = brass_mat
	stem.position = Vector3(0.0, 0.07, 0.0) * sc
	_crank.add_child(stem)

	var knob := MeshInstance3D.new()
	var knob_sphere := SphereMesh.new()
	knob_sphere.radius = 0.06
	knob_sphere.height = 0.12
	knob.mesh = knob_sphere
	knob.material_override = brass_mat
	knob.position = Vector3(0.0, 0.15, 0.0) * sc
	_crank.add_child(knob)

	# Grab area on the crank (player_hand layer). We drive _k from the crank's X.
	_crank_grab = Area3D.new()
	_crank_grab.name = "CrankGrab"
	# Layer 2 / mask 2 mirror the project's "interactable hand" convention loosely;
	# we keep it permissive so a hand or pointer can register a press.
	_crank_grab.collision_layer = 2
	_crank_grab.collision_mask = 2
	var grab_shape := CollisionShape3D.new()
	var grab_sphere := SphereShape3D.new()
	grab_sphere.radius = 0.09 * sc
	grab_shape.shape = grab_sphere
	grab_shape.position = Vector3(0.0, 0.15, 0.0) * sc
	_crank_grab.add_child(grab_shape)
	_crank.add_child(_crank_grab)

	# Try to wire any grab-style signals this Area exposes (kept defensive: the
	# Area3D itself only has body/area signals, so the real drive is the desktop
	# slider; the crank still slides visually to the current k via _position_crank).
	if _crank_grab.has_signal("grabbed"):
		_crank_grab.connect("grabbed", Callable(self, "_on_crank_grabbed"))
	if _crank_grab.has_signal("released"):
		_crank_grab.connect("released", Callable(self, "_on_crank_released"))


func _build_number_line() -> void:
	# A bead that rides the rail at the current k — a second, redundant read of the
	# scalar so the number line "shows" k even when the crank is elsewhere.
	_bead = MeshInstance3D.new()
	_bead.name = "KBead"
	var bead_sphere := SphereMesh.new()
	bead_sphere.radius = 0.035
	bead_sphere.height = 0.07
	_bead.mesh = bead_sphere
	_bead.material_override = _make_material(twin_color, 1.0, 0.2, 0.1)
	add_child(_bead)


# ═══════════════════════════════════════════════════════════════════════════
# CONTROLS  —  desktop "k" slider fallback + SNAP integer-lock button
# ═══════════════════════════════════════════════════════════════════════════

func _build_controls() -> void:
	var sc := SCENE_SCALE

	# Seat the k slider + SNAP on the canonical Braun ControlPanel — standard
	# spacing, orientation, and baked labels (no hand-placed offsets). When
	# `housed`, the same plate is recessed inside a ControlConsole cabinet (the
	# console forwards the identical add_slider / add_button / add_readout API).
	var panel
	if housed:
		var console = ControlConsoleScript.new()
		console.name = "ControlConsole"
		console.auto_demo = false   # the bench supplies its own controls
		panel = console
	else:
		panel = ControlPanelScript.new()
		panel.name = "ControlPlate"
	panel.position = Vector3(0.0, PLINTH_TOP_Y + 0.02, 0.45) * sc
	add_child(panel)
	if housed:
		panel.set_title("Stretch Bench")

	# Desktop / accessibility "k" slider (range min_k..max_k). The crank is the VR
	# gesture; this is the fallback the design explicitly keeps wired.
	_slider = panel.add_slider("k", "k")
	if _slider.has_method("set_range"):
		_slider.call("set_range", min_k, max_k)
	if _slider.has_method("set_normalized_value"):
		_slider.call("set_normalized_value", _k_to_norm(_k))
	if _slider.has_signal("slider_moved"):
		_slider.connect("slider_moved", Callable(self, "_on_slider_moved"))

	# SNAP push_button — toggles continuous vs integer-snapped k so the player can
	# land exactly on k=-1 (mirror) and k=2 (double).
	_snap_button = panel.add_button("SNAP")
	_snap_button.set("pressed_color", twin_color)
	_snap_button.set("released_color", brass_color)
	# Prefer the root `pressed` signal; fall back to the inner area button.
	if _snap_button.has_signal("pressed"):
		_snap_button.connect("pressed", Callable(self, "_on_snap_pressed"))
	else:
		var inner := _snap_button.get_node_or_null("InteractableAreaButton")
		if inner and inner.has_signal("button_pressed"):
			inner.connect("button_pressed", Callable(self, "_on_snap_inner"))

	# Readout display, integrated into the TOP of the plate (not floating).
	_readout_label = panel.add_readout("")


func _build_panels() -> void:
	# Two-column info panel (live data | static formula) behind the bench, raised.
	_info_label = create_info_panel(
		"Stretch Bench",
		Vector3(0.0, PLINTH_TOP_Y + 1.6, -0.9),
		Vector2(2.6, 1.1),
		"k * v = (k*vx, k*vy, k*vz)",
		"|k*v| = |k| * |v|\nk<0 reverses\nk=0 collapses")
	# create_info_panel parents the panel under the base's info_root; grab the node
	# itself (not just the live-data Label) so `workings` can take it off.
	if info_root != null:
		_info_panel = info_root.get_node_or_null("InfoPanel") as Node3D


# ═══════════════════════════════════════════════════════════════════════════
# DNA  —  regime (which case of k) and workings (how much is drawn)
# ═══════════════════════════════════════════════════════════════════════════

## The k the bench opens at. At "identity" — the default — this SHORT-CIRCUITS to
## the shipped default_k instead of the table's 1.0, so a map that sets `k` on the
## token keeps its own number rather than being silently reset to the regime's.
func _regime_k() -> float:
	if regime == "identity":
		return default_k
	return float(REGIME_K.get(regime, default_k))


## workings gates. At "expression" (the default) all three return true, which is
## the only state this bench could previously be in — so every existing placement
## draws the identical lattice, operands, dial and panel it always drew.
func _shows_lattice() -> bool:
	return workings != "outcome"


func _shows_operands() -> bool:
	return workings == "operands" or workings == "expression"


func _shows_expression() -> bool:
	return workings == "expression"


## Visibility only — nothing is torn down and nothing is rebuilt, so this is safe
## to re-run on a live bench. The twin and the collapse dot are never gated: they
## are the outcome, and _refresh_geometry owns their visibility.
func _apply_workings() -> void:
	if _lattice != null:
		_lattice.visible = _shows_lattice()
	if _bead != null:
		_bead.visible = _shows_lattice()
	if _base_arrow != null:
		_base_arrow.visible = _shows_operands()
	if _crank != null:
		_crank.visible = _shows_operands()
	if _dial != null:
		_dial.visible = _shows_expression()
	if _info_panel != null:
		_info_panel.visible = _shows_expression()


# ═══════════════════════════════════════════════════════════════════════════
# CONTROL CALLBACKS
# ═══════════════════════════════════════════════════════════════════════════

func _on_slider_moved(_value) -> void:
	if _slider == null:
		return
	var norm: float = 0.5
	if _slider.has_method("get_normalized_value"):
		norm = float(_slider.call("get_normalized_value"))
	_set_k(lerpf(min_k, max_k, clampf(norm, 0.0, 1.0)))


func _on_snap_pressed() -> void:
	_snap_integers = not _snap_integers
	_set_k(_k)  # re-apply with snap state


func _on_snap_inner(_button) -> void:
	_on_snap_pressed()


func _on_crank_grabbed(_by = null) -> void:
	_crank_dragging = true


func _on_crank_released(_by = null) -> void:
	_crank_dragging = false


# ═══════════════════════════════════════════════════════════════════════════
# K STATE
# ═══════════════════════════════════════════════════════════════════════════

func _set_k(value: float) -> void:
	var new_k: float = clampf(value, min_k, max_k)
	if _snap_integers:
		new_k = clampf(round(new_k), min_k, max_k)
	_k = new_k
	_refresh_all()


# ═══════════════════════════════════════════════════════════════════════════
# REFRESH  —  geometry every frame, text throttled
# ═══════════════════════════════════════════════════════════════════════════

func _refresh_all() -> void:
	_refresh_geometry()
	_refresh_text()


## Recompute the twin, dot, crank, bead, dial needle from current v and k.
func _refresh_geometry() -> void:
	var origin := _v_origin()
	var v := _current_v()
	var result := v * _k

	# Twin arrow k*v — same origin, length |k|*|v|, reversed when k<0.
	if _twin_arrow:
		if abs(_k) < 0.02 or result.length() < 0.01:
			# Collapse: hide the arrow, show the glowing dot on the origin.
			_twin_arrow.visible = false
			if _collapse_dot:
				_collapse_dot.position = origin * SCENE_SCALE
				_collapse_dot.visible = true
		else:
			if _collapse_dot:
				_collapse_dot.visible = false
			var twin_end := origin + result
			_position_arrow(_twin_arrow, origin, twin_end)
			# Recolour: red when reversed (k<0), cyan-violet otherwise.
			var col: Color = twin_flip_color if _k < 0.0 else twin_color
			_apply_arrow_color(_twin_arrow, col)

	# Crank rides the rail at x(k).
	if _crank:
		_position_crank()

	# Bead on the number line at x(k).
	if _bead:
		var bx := _k_to_rail_x(_k)
		_bead.position = Vector3(bx * SCENE_SCALE,
			(PLINTH_TOP_Y + 0.05) * SCENE_SCALE,
			0.0)

	# Dial needle sweeps from straight-up at k=0 to +/- across the range.
	if _dial_needle:
		var t: float = _k_to_norm(_k)            # 0..1 across [min_k, max_k]
		var ang: float = lerpf(-120.0, 120.0, t) # -120deg (min) .. +120deg (max)
		_dial_needle.rotation_degrees = Vector3(0.0, 0.0, -ang)


func _refresh_text() -> void:
	var v := _current_v()
	var result := v * _k
	var dir_word := "REVERSED" if _k < 0.0 else ("COLLAPSED" if abs(_k) < 0.02 else "same way")

	if _info_label:
		var lines := []
		lines.append("k = %.2f" % _k)
		lines.append("v = (%.2f, %.2f, %.2f)" % [v.x, v.y, v.z])
		lines.append("k*v = (%.2f, %.2f, %.2f)" % [result.x, result.y, result.z])
		lines.append("|v| = %.2f" % v.length())
		lines.append("|k| = %.2f" % abs(_k))
		lines.append("|k*v| = |k|*|v| = %.2f" % (abs(_k) * v.length()))
		lines.append("dir: %s" % dir_word)
		_info_label.text = "\n".join(lines)

	if _readout_label:
		_readout_label.text = "k = %.2f\n|k*v| = %.2f" % [_k, abs(_k) * v.length()]

	if _k_dial_label:
		_k_dial_label.text = "k = %.2f" % _k


# ═══════════════════════════════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════════════════════════════

## Logical origin of both vectors: left datum on the bench surface, centred in Z.
func _v_origin() -> Vector3:
	return Vector3(0.0, PLINTH_TOP_Y + 0.05, 0.0)


## Read the live base vector v from the grab sphere positions (player may re-aim
## it). Falls back to the configured base_vector if the grab spheres are missing.
func _current_v() -> Vector3:
	if _base_start != null and _base_end != null:
		var s: float = SCENE_SCALE * scale.x
		if s > 0.0001:
			var delta: Vector3 = (_base_end.global_position - _base_start.global_position) / s
			if delta.length() > 0.001:
				return delta
	return base_vector


## Map a scalar k to its X position along the rail (logical units, pre-SCENE_SCALE).
func _k_to_rail_x(k: float) -> float:
	var t: float = _k_to_norm(k)
	return lerpf(-RAIL_HALF_LEN, RAIL_HALF_LEN, t)


func _k_to_norm(k: float) -> float:
	if max_k == min_k:
		return 0.5
	return clampf((k - min_k) / (max_k - min_k), 0.0, 1.0)


## Slide the crank visually to the current k on the rail.
func _position_crank() -> void:
	var x := _k_to_rail_x(_k)
	_crank.position = Vector3(x * SCENE_SCALE,
		(PLINTH_TOP_Y + 0.05) * SCENE_SCALE,
		0.0)


# ── Arrow build / position (copied from catapult.gd) ─────────────────────────

## Build an arrow (shaft cylinder + cone head). Mirrors catapult._create_arrow.
func _create_arrow(arrow_name: String, color: Color) -> Node3D:
	var arrow := Node3D.new()
	arrow.name = arrow_name

	var shaft := MeshInstance3D.new()
	shaft.name = "Shaft"
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = ARROW_THICKNESS
	cylinder.bottom_radius = ARROW_THICKNESS
	cylinder.height = 1.0
	shaft.mesh = cylinder
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.5
	shaft.material_override = mat
	arrow.add_child(shaft)

	var head := MeshInstance3D.new()
	head.name = "Head"
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = ARROW_THICKNESS * 2.5
	cone.height = ARROW_THICKNESS * 5.0
	head.mesh = cone
	head.material_override = mat
	arrow.add_child(head)

	return arrow


## Position an arrow from start to end (both in this node's local space, LOGICAL),
## scaling shaft and placing the head. Mirrors catapult._position_arrow but applies
## SCENE_SCALE so it lives in the same scaled space as spawn_vector arrows.
func _position_arrow(arrow: Node3D, start_logical: Vector3, end_logical: Vector3) -> void:
	var start := start_logical * SCENE_SCALE
	var end := end_logical * SCENE_SCALE
	var dir := end - start
	var length := dir.length()
	if length < 0.01:
		arrow.visible = false
		return
	arrow.visible = true

	arrow.transform = Transform3D.IDENTITY
	arrow.position = start

	var shaft: Node3D = arrow.get_node("Shaft")
	var head: Node3D = arrow.get_node("Head")

	var head_len: float = ARROW_THICKNESS * 5.0 * SCENE_SCALE
	var shaft_length: float = length - head_len
	shaft.scale = Vector3(1.0, maxf(shaft_length, 0.01), 1.0)
	shaft.position = dir.normalized() * (shaft_length / 2.0)
	head.position = dir.normalized() * (length - ARROW_THICKNESS * 2.5 * SCENE_SCALE)

	# look_at() works in GLOBAL space. `dir` is in the arrow's parent local frame,
	# so rotate it by the parent's global basis to get a world direction first.
	var parent := arrow.get_parent() as Node3D
	var world_dir := dir
	if parent:
		world_dir = parent.global_transform.basis * dir
	var up := Vector3.UP
	if world_dir.length() > 0.0001 and abs(world_dir.normalized().dot(up)) > 0.99:
		up = Vector3.FORWARD
	arrow.look_at(arrow.global_position + world_dir, up)
	arrow.rotate_object_local(Vector3.RIGHT, PI / 2.0)


## Recolour an arrow built by _create_arrow (shaft + head share the material).
func _apply_arrow_color(arrow: Node3D, color: Color) -> void:
	if arrow == null:
		return
	var shaft := arrow.get_node_or_null("Shaft") as MeshInstance3D
	if shaft and shaft.material_override is StandardMaterial3D:
		var mat: StandardMaterial3D = shaft.material_override
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color
	var head := arrow.get_node_or_null("Head") as MeshInstance3D
	if head:
		# Head shares the shaft material in _create_arrow; reassign defensively.
		if shaft:
			head.material_override = shaft.material_override


# ── Material / label builders (copied from catapult.gd) ──────────────────────

func _make_material(color: Color, emission_energy: float = 0.0,
		roughness: float = 0.6, metallic: float = 0.2) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	if emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission_energy
	return mat


func _make_label(text: String, color: Color, font_size: int = 22) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = font_size
	label.outline_size = maxi(2, font_size / 6)
	label.outline_modulate = Color.BLACK
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.0012
	label.no_depth_test = false
	return label


func _format_int_label(ki: int) -> String:
	if ki == 0:
		return "0"
	if ki == 1:
		return "v"
	if ki == -1:
		return "-v"
	return "%dv" % ki


# ═══════════════════════════════════════════════════════════════════════════
# GRID CONFIG  —  scale_multiplier handled by super; k default + DNA here
# ═══════════════════════════════════════════════════════════════════════════

func apply_grid_config(config: Dictionary) -> void:
	if config == null:
		return

	# DNA knobs (read before super may rebuild the scene). `k` is read first, so a
	# token naming both k and regime=identity keeps its own explicit number.
	if config.has("k") or config.has("default_k"):
		var kv = config.get("k", config.get("default_k", default_k))
		default_k = float(kv)
		_k = clampf(default_k, min_k, max_k)
	if config.has("min_k"):
		min_k = float(config["min_k"])
	if config.has("max_k"):
		max_k = float(config["max_k"])
	if config.has("base_vector") and config["base_vector"] is Vector3:
		base_vector = config["base_vector"]
	# The two declared axes. Both are validated against their own value list, so a
	# misspelled token leaves the bench exactly as it shipped rather than falling
	# into a half-set state.
	if config.has("regime"):
		var want_regime: String = str(config["regime"]).strip_edges().to_lower()
		if REGIME_VALUES.has(want_regime) and want_regime != regime:
			regime = want_regime
			_k = clampf(_regime_k(), min_k, max_k)
	if config.has("workings"):
		var want_workings: String = str(config["workings"]).strip_edges().to_lower()
		if WORKINGS_VALUES.has(want_workings):
			workings = want_workings

	if config.has("housed"):
		housed = bool(config["housed"])
	if config.has("console"):
		housed = bool(config["console"])
	if config.has("base_color") and config["base_color"] is Color:
		base_color = config["base_color"]
	if config.has("twin_color") and config["twin_color"] is Color:
		twin_color = config["twin_color"]
	if config.has("twin_flip_color") and config["twin_flip_color"] is Color:
		twin_flip_color = config["twin_flip_color"]

	# Let the base handle scale_multiplier (and rebuild if already built).
	super.apply_grid_config(config)

	# If we did not rebuild but the scene is live, push the new values in. Both
	# axes are re-applied here rather than triggering a rebuild: regime moves a
	# number the refresh already reads, and workings is visibility on nodes that
	# are already standing. Nothing is torn down on any path through this function.
	if _scene_built and is_inside_tree() and _twin_arrow != null:
		if _slider and _slider.has_method("set_range"):
			_slider.call("set_range", min_k, max_k)
		if _slider and _slider.has_method("set_normalized_value"):
			_slider.call("set_normalized_value", _k_to_norm(_k))
		_apply_workings()
		_refresh_all()
