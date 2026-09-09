# @identity
# essence: a bench carrying one number twice — on the left as repeated identical signs with the last one cut down to the remainder, on the right as a single figure grown by the count, with half that same count nested inside it at a quarter of the ink
# desire: that a visitor turn the crank onto a number that does not divide, watch a figure get cut through the middle, and recognise that cut as the same operation the index uses when it asks which column it is in
# critical_parameter: unit — how many one sign is worth, the chart's SCALE. It is the divisor, so it decides whether there is a cut at all: at unit 1 every quantity divides, the left field is silent and honest, and nothing is argued. The artifact only says something when the number resists the sign
# triggers: the crank (dial_smooth's hinge, grabbed by a VR hand or the desktop crosshair). Turning it sets an integer quantity; the left field re-lays out at slots = ceil(q/unit) with the last sign clipped to q % unit, the right field rescales linearly, and both captions are re-derived from what was actually built rather than from what was asked for
# emerges: two pictures of one number that cannot be reconciled — one you can count and one you can only believe — and a stub of a person standing at the far end of the row where the remainder is
# needs: floor at y=0 under the origin [the grid provides it]; ~2 m of approach so a body can reach the crank [spatial_needs.clearance.front]; a lit hall — this is a printed chart built in relief, it has no emission of its own and in the dark it is a slab [the hall provides it]
# relationships: takes its text lane from orange_and_apples (commons/ui/text_screen.gd, mode 0, never turned) and its crank from agreement_gauge (dial_smooth, read through get_normalized_value rather than through the signal's argument). Its quarrel is with the building it stands in: nearly every artifact in this corpus encodes a number as a length, a height or a brightness, and Neurath is the person who said which of those a reader can actually count. The right-hand field is this building's habit, drawn on purpose
# truth: a number drawn as a size can be believed but not counted. Neurath's rule — more signs, never a bigger sign — is not a house style, it is the decision to hand the arithmetic back to the reader, and the price of that decision is a figure cut through the middle. The cut is not the chart failing to come out even. It is the chart saying what the division left over, which is the one thing an area never says.

extends Node3D
class_name IsotypeBench

## ISOTYPE BENCH — Otto Neurath and Gerd Arntz, the Vienna Method of Pictorial
## Statistics, Gesellschafts- und Wirtschaftsmuseum, from 1925. Two rules, and
## both of them are refusals:
##
##   1. A GREATER QUANTITY IS MORE SIGNS OF THE SAME SIZE, never a bigger sign.
##   2. COLOUR CARRIES CATEGORY, never quantity.
##
## The first is the one built here, twice over. LEFT obeys it: rows of identical
## signs at a fixed pitch, and where the quantity does not divide by the unit the
## last sign is CUT — so the remainder stands in the row as a half figure. RIGHT
## breaks it: the same number as one figure whose linear size follows the count,
## which means its AREA follows the square of the count, so doubling the number
## quadruples the ink. Both fields are driven by one crank.
##
## WHY THIS IS IN array_tutorial AND NOT IN A CRITIQUE ROOM. The sequence teaches
## index, count, modulo, repeat. The left field is not an illustration of modulo,
## it IS one: _redraw computes `full = q / unit` and `rem = q % unit` and the
## remainder is the width of the last sign, at hand height, in wood-thick relief.
## And the row wrap is a second modulo in the same picture — slot i sits at
## `row = i / per_row`, `col = i % per_row`, which is the sequence's own stated
## objective (`index // width` is the row, `index % width` is the column) drawn
## rather than said. Two divisions, one number, one glance.
##
## THE SIGN IS FOUR BOXES, AND THAT IS A CONSTRAINT, NOT LAZINESS. Arntz cut his
## figures for a printing block: flat, hard-edged, no modelling. Built from
## axis-aligned boxes, the vertical cut is EXACT — clipping a box at x = c gives
## another box. A cylinder head or a lathed torso would clip wrong and the half
## figure would be a lie about its own arithmetic. The blocky figure is faithful
## to the source and it is the only shape that can be honestly halved.
##
## THE RIGHT FIELD'S SCALE IS ARBITRARY AND THAT IS THE POINT. The lying figure
## is normalised so the crank's maximum exactly fills the field — a number chosen
## by me, readable nowhere on the object. An area chart's scale cannot be
## recovered from the chart, which is the second half of Neurath's objection and
## the reason the right field carries a rail with no ticks on it. The left rail
## has a tick at every slot boundary, because there is something there to count.
##
## THE RIGHT FIELD ALSO BREAKS RULE 2, ON PURPOSE. Its two nested figures are one
## category (people) in two hues, because the only thing separating them is
## quantity. The left field's signs are all one colour for the same reason in
## reverse. Nobody is told this; it is just there to be noticed.
##
## THE ORIGIN IS THE FLOOR at the centre of the bench. Nothing is below y = 0 —
## an artifact centred on its own origin stands half-sunk everywhere
## auto-grounding is skipped, which is every map token carrying an explicit y.

const PbrKit = preload("res://commons/render/pbr_kit.gd")
## The only text component in this project that renders in a capture. Label3D and
## BakedTextAlbedo.make_label_mesh were both verified blank; text_screen's
## make_panel_mesh / make_text_block path is what orange_and_apples uses and its
## plate is legible in its own still. Mode 0 (SCREEN) and NEVER rotated — this
## corpus presents +Z, and text turned by PI aims itself into its own panel.
const TextScreenScript = preload("res://commons/ui/text_screen.gd")
## The crank. dial_smooth rather than a hand-rolled handle, because it already
## carries BOTH interaction paths: XRToolsInteractableHandle bodies on collision
## layer 262144 (bit 19) for the VR hand, and a pointer_event() on its root for
## the desktop crosshair, whose raycast masks 1310720 = layers 19 + 21
## (DesktopInteractionPointer.gd:10). A bare RigidBody3D would have been
## grabbable on desktop and invisible in the headset.
const DIAL_SCENE := preload("res://commons/interactables/dial_smooth.tscn")

# ── THE BENCH. Every figure in metres, in the artifact's own frame, y = 0 floor ─
## A recessed foot, so the plinth reads as standing rather than as poured. It is
## also what puts the artifact's minimum Y at exactly 0.
const FOOT := Vector3(1.30, 0.08, 0.32)
const PLINTH := Vector3(1.40, 0.80, 0.40)        # y 0.08 .. 0.88
const PLINTH_FRONT := 0.20
const SLAB := Vector3(1.48, 0.05, 0.46)          # y 0.88 .. 0.93, overhangs
const SLAB_TOP := 0.93
const BOARD := Vector3(1.44, 0.86, 0.05)         # y 0.93 .. 1.79
const BOARD_Z := -0.16
const BOARD_FACE := -0.135                       # BOARD_Z + BOARD.z * 0.5

# ── THE TWO FIELDS ────────────────────────────────────────────────────────────
## The chart band. Its bottom is at 1.05 rather than at the bench top, so the
## crank plate standing in front of it cannot climb into the picture: the plate's
## highest point is 1.019, and a nearer object under a camera that looks DOWN
## (the corpus captures at pitch -0.26) projects lower still.
const FIELD_TOP := 1.42
const FIELD_BOT := 1.05
const FIELD_H := 0.37
const LEFT_L := -0.66
const RIGHT_L := 0.08
const FIELD_W := 0.58
## Derived, not typed. Two numbers for one edge drift the day the board moves.
const RIGHT_CX := RIGHT_L + FIELD_W * 0.5

## Fraction of a row's pitch the sign fills — the rest is the air above its head.
const ROW_FILL := 0.78
## Sign width over sign height. Arntz's standing figure is about half as wide as
## it is tall; 0.52 keeps it a person rather than a domino at any row count.
const FIG_ASPECT := 0.52
## Sign width over slot pitch. The 28% remainder is the gap between signs, which
## has to survive at every count or the row reads as one bar — which is exactly
## the thing being argued against.
const SIGN_FILL := 0.72
## Relief, metres. Flat decals photograph as paint; 16 mm gives every sign a lit
## side face, and gives the CUT a face of its own that the canonical camera
## (yaw 0.62, about 35 degrees off the approach) sees square on.
const SIGN_DEPTH := 0.016
const LIE_DEPTH := 0.020        # the big lying figure
## The half-count figure stands ON the big one's front face, with 1 mm of
## standoff. Not floating in front of it: nested is the whole demonstration, and
## a visible air gap would read as two separate charts rather than as one figure
## sitting inside four times its own area.
const LIE_NEST_Z := 0.021

const RAIL_H := 0.005
const RAIL_D := 0.008
const TICK_W := 0.0035
const TICK_H := 0.013

# ── THE CRANK ────────────────────────────────────────────────────────────────
## The plate is let into the bench top at 45 degrees, rising away from the
## visitor the way a drafting board does. Its NEAR edge sits 32 mm below the slab
## surface — inset rather than bolted on — and its far edge tops out at y = 1.019,
## 31 mm under the chart, so it never climbs into the picture it drives.
const CRANK_ORIGIN := Vector3(0.0, 0.955, 0.150)
const CRANK_TILT_DEG := -45.0
const CRANK_PLATE := Vector3(0.26, 0.16, 0.020)
## The dial's grabbable ring: eight 18 mm spheres centred at radius 25 mm, so the
## grab surface is the annulus from 7 mm to 43 mm. Everything I draw on top of it
## stays inside 43 mm — hub 26 mm, pointer tip 42 mm — so the crank a visitor
## SEES is a crank a visitor can reach. pink_gun shipped with a 2 cm collider
## under a 30 cm body and landed 1 click in 121; this is that lesson, arithmetic.
const HUB_R := 0.026
const POINTER_TIP := 0.042
const ARC_R0 := 0.052
const ARC_R1 := 0.062
const ARC_TICKS := 9
## Degrees of pointer sweep, each way. dial_smooth ships hinge limits at +/-135
## and this matches them; if a map ever changes those limits the pointer still
## spans its whole range, because it is driven from the normalised value and not
## from the raw angle.
const SWEEP_DEG := 135.0
## Where the crank tops out if nothing else is said. A map may ask for more (see
## _q_max) and the crank grows to fit rather than clipping the number.
const DIAL_MAX := 48
## Seconds of quiet before the captions are re-baked. The chart itself redraws on
## every step — it is boxes — but each caption costs four font bakes through
## BakedText, and dragging the crank across its whole range is 47 steps. Redraw
## the cheap thing now, the expensive thing when the hand stops.
const CAPTION_SETTLE := 0.18

# ── PALETTE ──────────────────────────────────────────────────────────────────
## Ink blue, not black. A near-black sign would need the whole dark-body recipe
## (F0 restored, a clearcoat, a backlight under the albedo) to stop reading as a
## hole, and none of that is worth spending on a shape whose entire job is to be
## the same as the sign beside it. Arntz printed in flat colour as often as in
## black.
const INK := Color(0.115, 0.185, 0.345)
const BOARD_COL := Color(0.845, 0.825, 0.775)
const RULE_COL := Color(0.42, 0.43, 0.45)
## The right field's two hues. One category, two quantities, two colours — the
## violation of Neurath's second rule, drawn rather than described.
const LIE_A := Color(0.84, 0.33, 0.12)
const LIE_B := Color(0.18, 0.50, 0.46)

## The sign, in normalised sign coordinates: u from the LEFT edge, v from the
## baseline, both 0..1, as (u0, v0, u1, v1). Head, torso, near leg, far leg.
## The head overlaps the torso by 0.01 and the legs overlap it by 0.01 — a 4 mm
## neck gap at this scale photographs as a head floating off its shoulders.
const FIG_PARTS := [
	Vector4(0.33, 0.78, 0.67, 1.00),
	Vector4(0.16, 0.34, 0.84, 0.79),
	Vector4(0.20, 0.00, 0.44, 0.35),
	Vector4(0.56, 0.00, 0.80, 0.35),
]
## Below this fraction of a sign's width a surviving strip is a burr, not a mark.
const MIN_STRIP := 0.02

# ── THE KNOBS ────────────────────────────────────────────────────────────────
## The number the bench is showing. 27 by default and that is not decoration:
## the shipped value MUST NOT divide by the unit, or the left field has no cut in
## it and the artifact photographs as an ordinary pictogram chart. 27 = 5 x 5 + 2.
@export_range(1, 96) var quantity: int = 27

## How many one sign is worth — the chart's SCALE, which is the word Neurath
## printed on his own charts ("1 sign = 1,000,000"). This is the divisor, so it
## is what produces the cut.
@export_range(1, 24) var unit: int = 5

## Signs per row. Deliberately NOT equal to the unit: two moduli that share a
## number look like one rule, and they are two. At 4 with 6 slots the second row
## runs short by two, and the empty slots stay drawn on the rail.
@export_range(1, 12) var per_row: int = 4

## The right-hand field. Off, only Neurath's field stands and the bench is a
## plain pictogram chart — which is the control condition, and the reason it is a
## knob at all: an object that cannot be shown without its own argument is not
## making one.
@export var show_lie: bool = true

# ── STATE ────────────────────────────────────────────────────────────────────
## Built once and never rebuilt: bench, board, screens, crank. The crank in
## particular MUST survive a redraw, because it holds the hinge position and the
## signal connection — free it and the number the visitor set goes with it.
var _frame: Node3D
## Rebuilt on every value change: the two fields and their rails.
var _chart: Node3D
## dial_smooth.gd carries no class_name, so it can only be reached dynamically —
## every call to it below goes through has_method/call, which is also how
## agreement_gauge holds the same control.
var _dial: Node3D
var _needle: Node3D
## The screens ARE statically typed, deliberately. `Object.set()` on a typed
## property of the wrong type is refused in SILENCE — that is how one artifact
## published sixteen identical frames of an axis it never set. TextScreen is a
## global class, so `_left_screen.title = x` is checked at compile time and
## cannot fail quietly.
var _left_screen: TextScreen
var _right_screen: TextScreen

var _q_max: int = DIAL_MAX
var _caption_dirty: bool = false
var _settle: float = 0.0
## BoxMesh resources keyed by size. Every full sign in the left field is the same
## four boxes, so five signs are four meshes and five times four instances. Only
## the cut sign owns geometry nobody else uses.
var _mesh_cache: Dictionary = {}

var _m_body: StandardMaterial3D
var _m_slab: StandardMaterial3D
var _m_board: StandardMaterial3D
var _m_ink: StandardMaterial3D
var _m_rule: StandardMaterial3D
var _m_lie_a: StandardMaterial3D
var _m_lie_b: StandardMaterial3D
var _m_plate: StandardMaterial3D
var _m_needle: StandardMaterial3D
var _m_hub: StandardMaterial3D


func _ready() -> void:
	_materials()
	_build_frame()
	_redraw(true)
	set_process(false)


# ── FRAME ────────────────────────────────────────────────────────────────────

func _materials() -> void:
	_m_body = PbrKit.painted_metal(Color(0.29, 0.29, 0.30), 0.20, 0.30, 0.58)
	_m_slab = PbrKit.brushed_metal(PbrKit.ALUMINIUM, 0.34)
	_m_board = PbrKit.rams_body(BOARD_COL, 0.05)
	_m_ink = PbrKit.rams_body(INK, 0.04)
	_m_rule = PbrKit.rams_body(RULE_COL, 0.10)
	_m_lie_a = PbrKit.rams_body(LIE_A, 0.04)
	_m_lie_b = PbrKit.rams_body(LIE_B, 0.04)
	_m_plate = PbrKit.painted_metal(Color(0.20, 0.21, 0.23), 0.18, 0.35, 0.50)
	_m_needle = PbrKit.painted_metal(Color(0.88, 0.86, 0.80), 0.10, 0.20, 0.45)
	_m_hub = PbrKit.brushed_metal(PbrKit.STEEL, 0.30)


func _build_frame() -> void:
	_frame = Node3D.new()
	_frame.name = "Bench"
	add_child(_frame)

	# Body. PbrKit.box chamfers every edge, which is right for furniture (an edge
	# that catches a highlight line instead of vanishing) and wrong for the signs,
	# which are printing blocks and stay plain BoxMesh.
	_frame.add_child(PbrKit.box(Vector3(0.0, FOOT.y * 0.5, 0.0), FOOT, _m_body, -1.0, 0.10))
	_frame.add_child(PbrKit.box(Vector3(0.0, FOOT.y + PLINTH.y * 0.5, 0.0), PLINTH, _m_body, -1.0, 0.08))
	_frame.add_child(PbrKit.box(Vector3(0.0, SLAB_TOP - SLAB.y * 0.5, 0.0), SLAB, _m_slab, -1.0, 0.06))
	_frame.add_child(PbrKit.box(Vector3(0.0, SLAB_TOP + BOARD.y * 0.5, BOARD_Z), BOARD, _m_board, 0.004, 0.02))

	# The divider. Two fields on one board are two fields only if something says
	# so; without it the eye reads a single row of eight things.
	_frame.add_child(PbrKit.box(
		Vector3(0.0, (FIELD_BOT + FIELD_TOP) * 0.5, BOARD_FACE + 0.004),
		Vector3(0.010, FIELD_H + 0.08, 0.008), _m_rule, 0.0015, 0.0))

	_build_colliders()
	_build_screens()
	_build_crank()


## Three boxes, each matching a thing a body can walk into. The crank plate gets
## none: it stands 82 mm above a slab that is already solid, and a hard box there
## would sit exactly where a hand is meant to reach in.
func _build_colliders() -> void:
	var body := StaticBody3D.new()
	body.name = "Solid"
	_frame.add_child(body)
	# The foot's 50 mm shadow gap is covered rather than modelled — nothing can
	# get into it, and a collider that stops at 0.08 lets a toe through the floor.
	_add_box_shape(body, Vector3(0.0, (FOOT.y + PLINTH.y) * 0.5, 0.0),
		Vector3(PLINTH.x, FOOT.y + PLINTH.y, PLINTH.z))
	_add_box_shape(body, Vector3(0.0, SLAB_TOP - SLAB.y * 0.5, 0.0), SLAB)
	_add_box_shape(body, Vector3(0.0, SLAB_TOP + BOARD.y * 0.5, BOARD_Z), BOARD)


func _add_box_shape(body: StaticBody3D, centre: Vector3, size: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	cs.position = centre
	body.add_child(cs)


## Three screens, none of them turned. The two on the board are re-derived from
## what the chart actually built; the one on the plinth is the museum label and
## never changes.
##
## EVERY STRING IS SET BEFORE add_child, AND THAT IS A MEASURED RULE. TextScreen's
## setters are guarded with `if is_inside_tree(): _rebuild()`, so a property driven
## after the node has entered the tree queue_free()s the whole plate and bakes
## another — which left the renderer holding freed materials, "Parameter material
## is null" x40 per map, measured 2026-07-21 and written up in specimen_plinth.gd
## :107. Three screens x (title + body) is six of those at map load. Setting first
## costs nothing: the guard is false until add_child, and _ready() then builds each
## plate exactly once.
func _build_screens() -> void:
	var lc: PackedStringArray = _left_caption()
	var rc: PackedStringArray = _right_caption()
	_left_screen = _screen("LeftCaption", 0.50,
		Vector3(-0.35, 1.585, BOARD_FACE + 0.016), lc[0], lc[1])
	_right_screen = _screen("RightCaption", 0.50,
		Vector3(0.35, 1.585, BOARD_FACE + 0.016), rc[0], rc[1])
	var _label: TextScreen = _screen("BenchLabel", 0.62,
		Vector3(0.0, 0.50, PLINTH_FRONT + 0.014),
		"VIENNA METHOD 1925",
		"turn the crank. the left field obeys Neurath. the right one does not.")


## Mode.SCREEN — a framed plate on the surface, no post and no recline, and NO
## rotation of any kind. Text turned to face somewhere other than +Z aims itself
## into its own panel and photographs as clean metal, which reads back live as
## perfect: set, sized, visible, alpha 1.0, and blank in every capture.
##
## Named, because three unnamed TextScreens come out of Godot as Node3D,
## @Node3D@2, @Node3D@3, and probe_aabb_hogs.gd reports the tree by node name.
func _screen(p_name: String, w: float, pos: Vector3, p_title: String,
		p_body: String) -> TextScreen:
	var s: TextScreen = TextScreenScript.new()
	s.name = p_name
	s.mode = TextScreen.Mode.SCREEN
	s.width_m = w
	s.bg_color = Color(0.09, 0.11, 0.15)
	s.frame_color = Color(0.17, 0.19, 0.24)
	s.title_color = Color(0.62, 0.79, 1.0)
	s.body_color = Color(0.91, 0.93, 0.97)
	s.title = p_title
	s.body = p_body
	s.position = pos
	# LAST, and that is the whole point of the ordering above.
	_frame.add_child(s)
	return s


func _build_crank() -> void:
	var crank := Node3D.new()
	crank.name = "Crank"
	crank.position = CRANK_ORIGIN
	crank.rotation_degrees.x = CRANK_TILT_DEG
	_frame.add_child(crank)

	crank.add_child(PbrKit.box(Vector3.ZERO, CRANK_PLATE, _m_plate, 0.004, 0.12))

	# The engraved sweep. Fixed ticks, moving pointer — an instrument, not a
	# readout: what it says is where the needle stands against them. One mesh,
	# nine instances; the ticks differ only by their transform.
	var tick_mesh := BoxMesh.new()
	tick_mesh.size = Vector3(0.0028, ARC_R1 - ARC_R0, 0.004)
	var tick_r: float = (ARC_R0 + ARC_R1) * 0.5
	for i in range(ARC_TICKS):
		var f: float = float(i) / float(maxi(ARC_TICKS - 1, 1))
		# Same sign as the pointer below, so a tick and the needle that reaches it
		# are describing the same number.
		var ang: float = -deg_to_rad(lerpf(-SWEEP_DEG, SWEEP_DEG, f))
		var tick := MeshInstance3D.new()
		tick.mesh = tick_mesh
		tick.material_override = _m_rule
		var b := Basis(Vector3(0.0, 0.0, 1.0), ang)
		tick.transform = Transform3D(b, b * Vector3(0.0, tick_r, 0.0) + Vector3(0.0, 0.0, 0.012))
		crank.add_child(tick)

	# The dial itself, flush with the plate face at local z 0.010.
	# `as Node3D`: PackedScene.instantiate() is statically typed Node, and GDScript
	# refuses the narrowing without it.
	_dial = DIAL_SCENE.instantiate() as Node3D
	_dial.name = "Dial"
	_dial.position = Vector3(0.0, 0.0, 0.014)
	crank.add_child(_dial)
	if _dial.has_method("set_param_name"):
		_dial.call("set_param_name", "QUANTITY")
	_sync_dial_range()
	if _dial.has_signal("hinge_moved"):
		_dial.connect("hinge_moved", Callable(self, "_on_crank"))

	# My own hub and pointer, in FRONT of the dial and carrying no collider at
	# all. A raycast only hits CollisionObject3D, so this cannot shadow the
	# handles underneath it — the thing you see and the thing you grab are the
	# same annulus.
	_needle = Node3D.new()
	_needle.name = "Pointer"
	_needle.position = Vector3(0.0, 0.0, 0.024)
	crank.add_child(_needle)

	var hub := MeshInstance3D.new()
	var hub_mesh := CylinderMesh.new()
	hub_mesh.top_radius = HUB_R
	hub_mesh.bottom_radius = HUB_R * 1.06
	hub_mesh.height = 0.018
	hub_mesh.radial_segments = 24
	hub.mesh = hub_mesh
	hub.material_override = _m_hub
	hub.rotation_degrees.x = 90.0      # CylinderMesh is Y-axis; face the plate
	hub.position = Vector3(0.0, 0.0, 0.009)
	_needle.add_child(hub)

	var arm := MeshInstance3D.new()
	var arm_mesh := BoxMesh.new()
	arm_mesh.size = Vector3(0.009, POINTER_TIP - 0.008, 0.010)
	arm.mesh = arm_mesh
	arm.material_override = _m_needle
	arm.position = Vector3(0.0, (POINTER_TIP + 0.008) * 0.5, 0.015)
	_needle.add_child(arm)

	# A counterweight on the far side, so the thing reads as a crank arm on a
	# spindle rather than as an arrow pasted on a knob.
	var tail := MeshInstance3D.new()
	var tail_mesh := BoxMesh.new()
	tail_mesh.size = Vector3(0.014, 0.014, 0.010)
	tail.mesh = tail_mesh
	tail.material_override = _m_needle
	tail.position = Vector3(0.0, -0.017, 0.015)
	_needle.add_child(tail)

	_point_needle(_norm_for(quantity))


# ── THE CRANK'S ARITHMETIC ───────────────────────────────────────────────────

## The crank's ceiling follows the number it was given, so a map that asks for 80
## gets a crank that reaches 80 rather than a crank that drags the chart back to
## 48 on the first touch.
func _sync_dial_range() -> void:
	_q_max = maxi(DIAL_MAX, quantity)
	if _dial == null:
		return
	if _dial.has_method("set_range"):
		_dial.call("set_range", 1.0, float(_q_max))
	if _dial.has_method("set_normalized_value"):
		_dial.call("set_normalized_value", _norm_for(quantity))


func _norm_for(q: int) -> float:
	return clampf(inverse_lerp(1.0, float(maxi(_q_max, 2)), float(q)), 0.0, 1.0)


## Driven by get_normalized_value(), NOT by the signal's argument. The hinge emits
## degrees and dial_smooth's own label handler remaps that against limits it also
## reads in degrees, so the argument is fine — but the normalised getter is the
## only reading that stays correct if the limits are ever changed, and it is what
## agreement_gauge uses for the same reason.
func _on_crank(_angle) -> void:
	if _dial == null or not _dial.has_method("get_normalized_value"):
		return
	var norm: float = clampf(float(_dial.call("get_normalized_value")), 0.0, 1.0)
	_point_needle(norm)
	var q: int = clampi(int(round(lerpf(1.0, float(_q_max), norm))), 1, _q_max)
	if q == quantity:
		return
	quantity = q
	_redraw(false)


## The pointer turns about +Z by MINUS the hinge angle, which is what the dial's
## own knob does: the hinge spins about DialOrigin's local X, and that axis maps
## to world -Z. Same sign, same plane, so the two can never disagree about which
## way the crank was turned.
func _point_needle(norm: float) -> void:
	if _needle == null:
		return
	_needle.rotation.z = -deg_to_rad(lerpf(-SWEEP_DEG, SWEEP_DEG, clampf(norm, 0.0, 1.0)))


func _process(delta: float) -> void:
	if not _caption_dirty:
		set_process(false)
		return
	_settle -= delta
	if _settle <= 0.0:
		_caption_dirty = false
		set_process(false)
		_write_captions()


# ── THE CHART ────────────────────────────────────────────────────────────────

func _redraw(immediate: bool) -> void:
	if _frame == null:
		return
	if _chart != null and is_instance_valid(_chart):
		# remove_child first: queue_free alone leaves the old node in the tree
		# until the end of the frame and the new one inherits a duplicated name.
		_frame.remove_child(_chart)
		_chart.queue_free()
	_chart = Node3D.new()
	_chart.name = "Chart"
	_frame.add_child(_chart)
	_mesh_cache.clear()

	var u: int = clampi(unit, 1, 24)
	var per: int = clampi(per_row, 1, 12)
	var q: int = clampi(quantity, 1, 96)
	# Integer arithmetic throughout. ceil(q / float(u)) sits on a float cliff and
	# a chart whose sign count depends on which side of an ulp a double lands is
	# a bug waiting for a different build.
	var full: int = q / u
	var rem: int = q % u
	var slots: int = full + (1 if rem > 0 else 0)
	var rows: int = (slots + per - 1) / per

	_build_left(u, per, full, rem, slots, rows)
	if show_lie:
		_build_right(q)

	if immediate:
		_caption_dirty = false
		set_process(false)
		_write_captions()
	else:
		_caption_dirty = true
		_settle = CAPTION_SETTLE
		set_process(true)


## Neurath's field. Signs of one size at one pitch, the last one cut.
func _build_left(u: int, per: int, full: int, rem: int, slots: int, rows: int) -> void:
	var row_pitch: float = FIELD_H / float(maxi(rows, 1))
	var sign_h: float = row_pitch * ROW_FILL
	var sign_w: float = sign_h * FIG_ASPECT
	var pitch: float = sign_w / SIGN_FILL
	var need_w: float = pitch * float(per)
	if need_w > FIELD_W:
		# Too many columns for the board. Shrink the SIGNS, never the pitch
		# ratio — signs that touch are a bar, and a bar is the other field.
		var k: float = FIELD_W / need_w
		sign_h *= k
		sign_w *= k
		pitch *= k
		need_w = FIELD_W
	var x0: float = LEFT_L + (FIELD_W - need_w) * 0.5

	for r in range(rows):
		var base_y: float = FIELD_TOP - row_pitch * float(r + 1)
		_rail(x0, base_y, need_w, per, pitch)

	for i in range(slots):
		# THE SEQUENCE'S OWN ARITHMETIC, run rather than illustrated. Row is the
		# floor division, column is the remainder, and the short last row is what
		# the remainder looks like from outside.
		var r: int = i / per
		var c: int = i % per
		var frac: float = 1.0
		if i == full and rem > 0:
			frac = float(rem) / float(u)
		var left_x: float = x0 + pitch * float(c) + (pitch - sign_w) * 0.5
		var base_y: float = FIELD_TOP - row_pitch * float(r + 1)
		_place_sign(_chart, Vector3(left_x, base_y, BOARD_FACE), sign_w, sign_h,
			SIGN_DEPTH, frac, _m_ink)


## The rail runs the FULL row whatever the row holds, and carries a tick at every
## slot boundary. That is what makes the short last row visible as short and the
## cut sign visible as cut — a rail drawn only under what was built would hide
## both, and both are the point.
func _rail(x0: float, base_y: float, w: float, per: int, pitch: float) -> void:
	var rail := MeshInstance3D.new()
	rail.mesh = _box_mesh(Vector3(w, RAIL_H, RAIL_D))
	rail.material_override = _m_rule
	rail.position = Vector3(x0 + w * 0.5, base_y - RAIL_H * 0.5, BOARD_FACE + RAIL_D * 0.5)
	_chart.add_child(rail)

	for c in range(per + 1):
		var tick := MeshInstance3D.new()
		tick.mesh = _box_mesh(Vector3(TICK_W, TICK_H, RAIL_D))
		tick.material_override = _m_rule
		tick.position = Vector3(x0 + pitch * float(c),
			base_y - RAIL_H - TICK_H * 0.5, BOARD_FACE + RAIL_D * 0.5)
		_chart.add_child(tick)


## The lie. One figure whose HEIGHT follows the count, so its area follows the
## square of it; and inside it, on the same baseline, the same figure at half the
## count. Half as tall, half as wide, a quarter of the ink — which is the whole
## demonstration, standing still, needing no crank turned to be seen.
func _build_right(q: int) -> void:
	var rail := MeshInstance3D.new()
	rail.mesh = _box_mesh(Vector3(FIELD_W, RAIL_H, RAIL_D))
	rail.material_override = _m_rule
	rail.position = Vector3(RIGHT_CX, FIELD_BOT - RAIL_H * 0.5, BOARD_FACE + RAIL_D * 0.5)
	_chart.add_child(rail)

	var ref: float = float(maxi(_q_max, q))
	var big_h: float = FIELD_H * (float(q) / maxf(ref, 1.0))
	var big_w: float = big_h * FIG_ASPECT
	if big_w > FIELD_W:
		var k: float = FIELD_W / big_w
		big_h *= k
		big_w *= k
	_place_sign(_chart, Vector3(RIGHT_CX - big_w * 0.5, FIELD_BOT, BOARD_FACE),
		big_w, big_h, LIE_DEPTH, 1.0, _m_lie_a)

	var half_q: int = q / 2
	if half_q < 1:
		return
	var small_h: float = big_h * (float(half_q) / float(q))
	var small_w: float = small_h * FIG_ASPECT
	_place_sign(_chart, Vector3(RIGHT_CX - small_w * 0.5, FIELD_BOT, BOARD_FACE + LIE_NEST_Z),
		small_w, small_h, LIE_DEPTH, 1.0, _m_lie_b)


# ── THE SIGN ─────────────────────────────────────────────────────────────────

## Four boxes clipped at u = frac. Clipping a box is another box, which is why
## the figure is boxes: the half sign is EXACTLY half a sign and not a drawing of
## one. Returns dictionaries rather than nodes so the caller can share meshes.
func _sign_boxes(w: float, h: float, d: float, frac: float) -> Array:
	var out: Array = []
	var f: float = clampf(frac, 0.0, 1.0)
	for p in FIG_PARTS:
		var u0: float = p.x
		var u1: float = minf(p.z, f)
		if u1 - u0 < MIN_STRIP:
			continue
		var v0: float = p.y
		var v1: float = p.w
		out.append({
			"size": Vector3((u1 - u0) * w, (v1 - v0) * h, d),
			"pos": Vector3((u0 + u1) * 0.5 * w, (v0 + v1) * 0.5 * h, d * 0.5),
		})
	return out


## `origin` is the sign's BOTTOM-LEFT corner on the board face, which is what
## makes a cut sign stay put: clipping shortens the figure to the right and its
## left edge and its baseline never move, so the slot it stands in is unchanged.
func _place_sign(parent: Node3D, origin: Vector3, w: float, h: float, d: float,
		frac: float, mat: Material) -> void:
	for b in _sign_boxes(w, h, d, frac):
		var bs: Vector3 = b["size"]
		var bp: Vector3 = b["pos"]
		var mi := MeshInstance3D.new()
		mi.mesh = _box_mesh(bs)
		mi.material_override = mat
		mi.position = origin + bp
		parent.add_child(mi)


func _box_mesh(size: Vector3) -> BoxMesh:
	var key: String = "%.4f|%.4f|%.4f" % [size.x, size.y, size.z]
	var m: BoxMesh = _mesh_cache.get(key)
	if m == null:
		m = BoxMesh.new()
		m.size = size
		_mesh_cache[key] = m
	return m


# ── THE CAPTIONS ─────────────────────────────────────────────────────────────

## DERIVED, never typed. The numbers on the board are recomputed from the same
## integers the geometry was laid out from, so a caption cannot survive a change
## it does not describe. A room whose subject is counting cannot afford a wall
## that lies about its own count.
##
## Sized against text_screen's own wrap: at width 0.50 it wraps at 26 columns and
## holds 5 body lines, so a body over about 130 characters is truncated with an
## ellipsis rather than shrunk. Every string below is inside that.
##
## [title, body], returned rather than assigned, so the SAME arithmetic can seed a
## screen before it enters the tree and refresh it afterwards. Two code paths
## writing one caption is how a board ends up disagreeing with its own chart.
func _left_caption() -> PackedStringArray:
	var u: int = clampi(unit, 1, 24)
	var q: int = clampi(quantity, 1, 96)
	var full: int = q / u
	var rem: int = q % u
	if rem > 0:
		return PackedStringArray([
			"%d = %d x %d + %d" % [q, full, u, rem],
			"one sign = %d. the last sign is cut to %d/%d." % [u, rem, u]])
	return PackedStringArray([
		"%d = %d x %d" % [q, full, u],
		"one sign = %d. more signs, never a bigger sign." % u])


func _right_caption() -> PackedStringArray:
	if not show_lie:
		return PackedStringArray([
			"NOTHING HERE",
			"the second field is switched off. this is the control."])
	var q: int = clampi(quantity, 1, 96)
	var half_q: int = q / 2
	if half_q < 1:
		return PackedStringArray([
			"THE SAME %d" % q,
			"one figure, scaled by the count. nothing to measure it against."])
	return PackedStringArray([
		"THE SAME %d" % q,
		"one figure, scaled by the count. %d is half as many, and a quarter of the ink." % half_q])


## The UPDATE path, and it writes only what actually CHANGED. Every assignment to
## a TextScreen already in the tree frees the plate and bakes a new one, so an
## unconditional write costs four rebuilds per crank settle — and four for nothing
## at all on the first pass, where _build_screens has just seeded the screens with
## these exact strings. The comparison is two String compares against four font
## bakes; it is not an optimisation, it is the difference between rebuilding and
## not rebuilding.
func _write_captions() -> void:
	if _left_screen != null and is_instance_valid(_left_screen):
		var lc: PackedStringArray = _left_caption()
		if _left_screen.title != lc[0]:
			_left_screen.title = lc[0]
		if _left_screen.body != lc[1]:
			_left_screen.body = lc[1]

	if _right_screen != null and is_instance_valid(_right_screen):
		var rc: PackedStringArray = _right_caption()
		if _right_screen.title != rc[0]:
			_right_screen.title = rc[0]
		if _right_screen.body != rc[1]:
			_right_screen.body = rc[1]


# ── CONFIG ───────────────────────────────────────────────────────────────────

## Per-cell configuration from a map token. Keys honoured:
##
##   #count:27       the quantity
##   #scale:5        how many one sign is worth — the chart's scale, the divisor
##   #cols:4         signs per row
##   #lie:false      hide the right-hand field
##
## EVERY NUMERIC KEY ABOVE IS IN CONFIG_PARAM_NAMES (GridInteractablesComponent
## .gd:16). That is load-bearing, not tidiness: an unlisted `#key:<number>` is
## read as the tutorial's positional shorthand at line 1705, so it never arrives
## here at all — the artifact keeps its default and stores the number as a
## rotation, which is how one artifact ended up building 2 levels while its map
## token said 4 and nothing anywhere complained.
##
## SO `#unit:5` AND `#quantity:27` DO NOT WORK, and they are not offered as
## aliases even though they are the obvious names. `scale` is not a compromise:
## a chart's scale IS its units-per-symbol, which is exactly what Neurath printed
## along the bottom of his own charts, and `count` is the number being charted.
##
## `#lie:false` must take a WORD. `#lie:0` is a lone numeric on an unlisted key
## and is eaten as a rotation; and even if it arrived it would arrive as the
## STRING "0", and bool("0") is true in GDScript. Hence _flag().
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("count"):
		quantity = clampi(_as_int(config_data["count"], quantity), 1, 96)
	if config_data.has("scale"):
		unit = clampi(_as_int(config_data["scale"], unit), 1, 24)
	if config_data.has("cols"):
		per_row = clampi(_as_int(config_data["cols"], per_row), 1, 12)
	if config_data.has("lie"):
		show_lie = _flag(config_data["lie"])
	if not is_inside_tree():
		return
	_sync_dial_range()
	_point_needle(_norm_for(quantity))
	# Immediate: a capture can follow a config apply in the same second, and a
	# board still carrying the previous number is a photograph of a bug.
	_redraw(true)


## Config values arrive as strings, and bool("0") and bool("false") are both
## true. The same helper fetish_portal and eleven_dots carry, for the same reason.
func _flag(v) -> bool:
	if typeof(v) == TYPE_BOOL:
		return bool(v)
	return str(v).strip_edges().to_lower() in ["true", "1", "yes", "on"]


## str(), never String(): String() on a JSON cell throws.
func _as_int(v, fallback: int) -> int:
	match typeof(v):
		TYPE_INT, TYPE_FLOAT:
			return int(v)
		TYPE_STRING, TYPE_STRING_NAME:
			var s: String = str(v).strip_edges()
			if s.is_valid_int():
				return int(s)
			if s.is_valid_float():
				return int(s.to_float())
	return fallback
