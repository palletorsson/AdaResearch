# @identity
# essence: a rack of identical units a visitor can slide along one line, and a plate above them that reads the row and says out loud what the arrangement is claiming
# desire: that someone moves one block for no reason, looks up, and finds the room has already named what they did — and then discovers that putting equality back is harder than taking it away
# critical_parameter: order — serial / centred / hero / graded. It is the only thing about this object that is a claim rather than a fact, and it is deliberately NOT what the plate reads
# triggers: _ready builds the rack and names it synchronously, because a still must never photograph a blank plate; _process polls each unit's LOCAL transform (desktop carrying emits no grab signal at all) and re-reads the row whenever one moves
# emerges: a hierarchy the visitor did not intend and cannot deny, because the plate is not reading their intention, it is reading the distance between two blocks — and equality turns out to be the one arrangement that has to be maintained
# needs: the PBR kit for the deck and plinth [present]; the project face via baked_text_albedo.project_font, so the plate reads like a wall label and not like a debug overlay [present]; the xr-tools pickable for the hand [present, and the build degrades to static bodies if it is missing rather than to an empty rack]
# relationships: the near sibling is composition_twins, which also polls frozen pickables on a bench and also learned that no_gravity_gun and release_mode 1 are what stop a rack becoming a floor; the far sibling is walk_this_line_marking, which is the other artifact in this corpus whose whole payload is a sentence addressed to the person standing in front of it
# truth: equality between units is not a state the objects are in, it is a claim the arrangement makes — and it is the only claim here that has to be maintained, because every other one can be made by accident. This museum sorts every artifact in every room into primary, secondary and decoration; that is the hierarchy Lohse spent forty years refusing, and this is it put on a table at hand height where it can be picked up and, with some difficulty, put back down.

extends Node3D
class_name SerialPrinciple

const PBR := preload("res://commons/render/pbr_kit.gd")
## THE PROJECT'S FACE, not ThemeDB.fallback_font. baked_text_albedo's own comment
## records why: every baked label in the corpus used the engine fallback, "which is
## why museum captions read like a debug overlay". project_font() returns Roboto if
## the file is there and the fallback if it is not, so this cannot fail to text.
const TEXT := preload("res://commons/utils/baked_text_albedo.gd")
## The addon scene rather than a hand-rolled RigidBody3D: collision_layer 4
## (= layer 3), collision_mask 196615 and freeze_mode 1 all arrive already set, and
## layer 3 is the one layer BOTH hands reach — desktop carry masks 3/18/19, the VR
## pickup area masks 3/17/19. composition_twins established this and paid for it.
##
## LOADED, NOT PRELOADED, and the difference is the whole point of the fallback in
## _make_unit: `/addons/*` is gitignored in this repo, and a preload of a missing
## file fails at PARSE time, which would take the rack, the plate and the sentence
## down with the grab. facture_bench documents the same hazard from the other side.
const PICKABLE_PATH := "res://addons/godot-xr-tools/objects/pickable.tscn"
const GRAB_POINT_FMT := "res://addons/godot-xr-tools/objects/grab_points/grab_point_hand_%s.tscn"

## The shipped claims. A word key, so `#order:hero` can never be eaten by the
## grid's `#key:<number>` tutorial shorthand.
const ORDERS: Array[String] = ["serial", "centred", "hero", "graded"]

## THE THREE CONSTANTS BELOW ARE COUPLED TO PLATE_CLEAR. The plate hangs at
## deck + unit_height * PLATE_CLEAR, and PLATE_CLEAR is above both of the factors
## any preset can produce, so no shipped arrangement ever reaches the sign. Raise
## HERO_FACTOR or GRADE_TOP past 1.60 and the tallest unit starts eating the text.
const HERO_FACTOR: float = 1.55
## The ladder's floor is 0.78 and not lower for a reason that is rule 2, not taste:
## at unit_size_m 0.16 the smallest graded unit is 0.125 m across, and a hand stops
## reliably catching things somewhere just under that (composition_twins measured
## 0.16 as the smallest it trusted). Its collider matches its mesh exactly, so the
## only way to keep it catchable is to keep it big.
const GRADE_BOTTOM: float = 0.78
const GRADE_TOP: float = 1.50
const PLATE_CLEAR: float = 1.60
## The smallest gap between two neighbours that still reads as a gap in a still,
## and the number the deck's capacity is computed from.
const MIN_EDGE_GAP: float = 0.04
## The attribution under every reading. A constant rather than an inline literal
## because it is the only sentence on this object that never changes.
const CREDIT_LINE: String = "

after Richard Paul Lohse, 1902-1988
\"the serial principle is a radical democratic principle\""

@export_group("The units")
## Identical, and the count is the only thing about them a map may change.
## Capped at 7 rather than 9 because the graded ladder divides a fixed span
## (GRADE_BOTTOM..GRADE_TOP) by count-1: at nine units a step is small enough that
## the plate can no longer honestly call the result a rank.
@export_range(1, 7) var unit_count: int = 5
## The unit across, in metres. Its height is this times unit_aspect.
@export var unit_size_m: float = 0.16
## Taller than wide, so the row reads as a row of standing things rather than as a
## tray of tiles — and so turning one on its side is a visible act.
@export var unit_aspect: float = 1.75
## ONE COLOUR FOR ALL OF THEM, and there is deliberately no per-unit colour on this
## object at any level. A colour difference is the cheapest hierarchy there is: it
## needs no space, no height and no size, and it would let a map assert a primary
## unit without moving anything. The only differences available here are the ones a
## visitor can also make with their hands.
@export var unit_color: Color = Color(0.845, 0.825, 0.775)

@export_group("The rack")
## The shipped arrangement. Sets transforms and sizes and NOTHING ELSE — see
## _read_and_name for why that separation is the whole design.
@export_enum("serial", "centred", "hero", "graded") var order: String = "serial"
@export var deck_width_m: float = 1.80
@export var deck_depth_m: float = 0.56
## Table height. A visitor has to be able to reach in and move a unit without
## crouching, or the argument is behind glass.
@export var deck_height_m: float = 0.92
## The plinth and the sign as collision. On by default: this is furniture, and a
## visitor who walks through the middle of a table has not met it.
@export var solid: bool = true

@export_group("The reading")
## HOW UNEQUAL IS UNEQUAL. Everything the plate says turns on this one number, so
## it is worth stating what it costs in both directions: at the shipped defaults a
## gap is 0.36 m, so 8% is 29 mm — about two fingers. Tighter and a careful visitor
## can never restore the serial case by hand, which would make equality a thing only
## the code can assert. Looser and the plate calls a hierarchy you can plainly see
## "no unit above another", which is the failure that matters, because that is the
## plate lying in the direction the room already leans.
@export_range(0.01, 0.40) var tolerance: float = 0.08
## How far above the row a single unit has to stand before it is a hero rather than
## a wobble. Read against the median unit, so it is a ratio and not a length.
@export_range(0.05, 1.00) var prominence_gate: float = 0.15
## The units are frozen on release (see _make_unit), which is what turns "held up
## in the air" from a moment into an arrangement. This bounds it, and it bounds the
## row to one line: z is clamped HARD, to the line itself, not to a band around it.
##
## That forecloses something real — a visitor cannot pull one unit forward out of
## the rank, or build a second row behind the first — and a soft band would feel
## better in the hand. The hard line is kept for the reason that outranks feel: the
## plate reads x, height and size and nothing else, so any difference a visitor can
## make in z is a difference the plate would be SILENT about. A unit standing 8 cm
## proud of the row under a sign reading NO UNIT ABOVE ANOTHER is this object's
## worst failure, and it is worse than a stiff constraint. The claim space is the
## clamp: what the rack lets you do is exactly what the plate can name.
@export var clamp_reach: bool = true

var _units: Array[Node3D] = []
var _meshes: Array[MeshInstance3D] = []
var _owned: Array[Node] = []
var _last: Array[Transform3D] = []
## HOLDERS, NOT Label3D — see _label. The plate bakes its text into an albedo
## texture, because a Label3D on this plate renders NOTHING: read back live it is
## visible, fonted, 9 cm tall and 6 mm proud of a dark panel, and the capture
## still shows bare metal. Every artifact in the corpus whose caption actually
## reaches a picture bakes it (orange_and_apples via commons/ui/text_screen.gd,
## the wall labels via BakedTextAlbedo.make_label_mesh). Measured 2026-09-09.
const TextScreen := preload("res://commons/ui/text_screen.gd")
var _screen: Node3D = null
var _verdict: Node3D = null
var _evidence: Node3D = null

## Resolved once per build, not once per unit.
var _pickable_scene: PackedScene = null

var _unit_h: float = 0.28
var _deck_top: float = 0.92
var _row_z: float = -0.08
## The sign plane. A MEMBER rather than a local in _build_plate, because _row_z has
## to stay clear of it and the corpus's standing lesson about a rule implemented
## twice is long_museum.py: the second copy drifts and both surfaces look right.
var _plate_z: float = 0.22
var _plate_base: float = 1.43
var _lift_ceiling: float = 0.55


func _ready() -> void:
	_build()
	# NAMED SYNCHRONOUSLY, HERE, and not left to the first _process. The evidence
	# for this artifact is a PNG, the capture harness photographs it a couple of
	# frames after instantiation, and a plate that is still blank at that moment
	# publishes an artifact whose entire payload is missing. Nothing in the read
	# needs a physics step: the units are frozen and standing exactly where _build
	# put them, so the measurement is already valid.
	_read_and_name()


# ── BUILDING ─────────────────────────────────────────────────────────────────

func _build() -> void:
	# Only what this script made. Freeing every child instead would take the
	# config_* metadata carriers and anything a map dressed the token with.
	for o in _owned:
		if is_instance_valid(o):
			o.queue_free()
	_owned.clear()
	_units.clear()
	_meshes.clear()
	_last.clear()

	if _pickable_scene == null and ResourceLoader.exists(PICKABLE_PATH):
		_pickable_scene = load(PICKABLE_PATH) as PackedScene

	var u_w: float = maxf(unit_size_m, 0.05)
	# HOW MANY UNITS THIS DECK CAN ACTUALLY HOLD, which is not the same question as
	# how many were asked for. The row has to stay legible at the WIDEST size any
	# order can produce (hero, 1.55x), with a real gap between neighbours, or the
	# hero preset photographs as one lump. Capacity = (usable + gap) / (widest +
	# gap); at the shipped 1.80 m deck with 0.16 m units that is 5, which is why
	# five is the default. A map that wants seven has to say `#width:2.4` too, and
	# it is told so rather than silently given an overhanging rack.
	var n_ask: int = clampi(unit_count, 1, 7)
	var usable: float = maxf(deck_width_m - 0.20, u_w * 2.0)
	var widest: float = u_w * HERO_FACTOR
	var n_fit: int = int(floor((usable + MIN_EDGE_GAP) / (widest + MIN_EDGE_GAP)))
	var n_units: int = clampi(mini(n_ask, n_fit), 1, 7)
	if n_units < n_ask:
		push_warning("serial_principle: %d units of %.2f m need a deck %.2f m wide; showing %d. Add #width:%.1f" % [
			n_ask, u_w, float(n_ask) * (widest + MIN_EDGE_GAP) - MIN_EDGE_GAP + 0.20,
			n_units, ceilf((float(n_ask) * (widest + MIN_EDGE_GAP) - MIN_EDGE_GAP + 0.20) * 10.0) / 10.0])
	_unit_h = u_w * maxf(unit_aspect, 0.4)
	_deck_top = maxf(deck_height_m, 0.30)
	_plate_z = deck_depth_m * 0.5 - 0.06
	# The row sits 20 cm back from the front lip, AND never within 12 cm of the sign
	# plane. The second term is not tidiness: apply_grid_config clamps `depth` down
	# to 0.30, and at 0.30 the naive first term alone puts the row at z +0.05, where
	# the outer units (x +-0.676, half-depth 0.08) run through the posts standing at
	# x +-0.68, z 0.065..0.115. At the shipped 0.56 m depth the second term is 0.10
	# against the first's -0.08, so minf picks the first and no placed rack moves.
	_row_z = minf(-deck_depth_m * 0.5 + 0.20, _plate_z - 0.12)
	_plate_base = _deck_top + _unit_h * PLATE_CLEAR + 0.06
	_lift_ceiling = 0.55

	var body: StaticBody3D = null
	if solid:
		body = StaticBody3D.new()
		body.name = "Furniture"
		# Layer 1 is the world. Mask 0 because a table detects nothing — it is only
		# ever the thing detected.
		body.collision_layer = 1
		body.collision_mask = 0
		add_child(body)
		_owned.append(body)

	_build_plinth(body)
	_build_plate(body)

	var plan: Dictionary = _order_plan(n_units, u_w)
	var xs: Array = plan["xs"]
	var fs: Array = plan["factors"]
	for i in range(n_units):
		var unit: Node3D = _make_unit(i, float(xs[i]), float(fs[i]), u_w)
		add_child(unit)
		_owned.append(unit)
		_units.append(unit)
		_last.append(unit.transform)

	set_process(_units.size() > 0)


## The plinth, and the ONE deck the units share.
##
## The deck is a single continuous plate with no slots, no numbers and no marks on
## it. That is not an omission — a numbered slot is already a hierarchy, because
## position 1 exists before anything stands in it. Whatever ranking this object
## ends up displaying has to have been put there by somebody's hands.
func _build_plinth(body: StaticBody3D) -> void:
	var deck_t: float = 0.035
	var base_h: float = _deck_top - deck_t

	var stone: StandardMaterial3D = PBR.concrete(PBR.CONCRETE_GREY.darkened(0.34), 0.34)
	var base: MeshInstance3D = PBR.box(
		Vector3(0.0, base_h * 0.5, 0.0),
		Vector3(deck_width_m * 0.94, base_h, deck_depth_m * 0.90),
		stone, -1.0, 0.22)
	base.name = "Plinth"
	add_child(base)
	_owned.append(base)

	# Brushed along X — the deck was rolled and drawn in the direction the row
	# runs, so the highlight smears the same way the units are laid out.
	var deck_mat: StandardMaterial3D = PBR.brushed_metal(PBR.STEEL.darkened(0.20), 0.34, 0.18, "x")
	var deck: MeshInstance3D = PBR.box(
		Vector3(0.0, _deck_top - deck_t * 0.5, 0.0),
		Vector3(deck_width_m, deck_t, deck_depth_m),
		deck_mat, -1.0, 0.10)
	deck.name = "Deck"
	add_child(deck)
	_owned.append(deck)

	# TWO SHAPES, NOT ONE BOX FROM THE FLOOR TO THE DECK. The deck slab overhangs
	# the plinth on every side, and a single full-width column would put an
	# invisible wall in the 5 cm of air under the lip — the place a visitor's toes
	# and a dropped unit both go. The collider is where the thing is.
	if body != null:
		_add_shape(body, Vector3(0.0, base_h * 0.5, 0.0),
			Vector3(deck_width_m * 0.94, base_h, deck_depth_m * 0.90))
		_add_shape(body, Vector3(0.0, _deck_top - deck_t * 0.5, 0.0),
			Vector3(deck_width_m, deck_t, deck_depth_m))


func _build_plate(body: StaticBody3D) -> void:
	var plate_w: float = minf(deck_width_m * 0.80, 1.44)
	var plate_h: float = 0.46
	var plate_z: float = _plate_z
	var post_h: float = _plate_base - _deck_top

	var dark: StandardMaterial3D = PBR.terminal_body(PBR.TERMINAL_BODY, 0.26)
	for s in [-1.0, 1.0]:
		var post: MeshInstance3D = PBR.box(
			Vector3(s * (plate_w * 0.5 - 0.04), _deck_top + post_h * 0.5, plate_z),
			Vector3(0.05, post_h, 0.05), dark, -1.0, 0.15)
		post.name = "Post%s" % ("L" if s < 0.0 else "R")
		add_child(post)
		_owned.append(post)

	var panel: MeshInstance3D = PBR.box(
		Vector3(0.0, _plate_base + plate_h * 0.5, plate_z),
		Vector3(plate_w, plate_h, 0.045),
		PBR.terminal_body(PBR.TERMINAL_PANEL, 0.14), -1.0, 0.08)
	panel.name = "Plate"
	add_child(panel)
	_owned.append(panel)

	if body != null:
		# THE POSTS TOO, not just the panel. They are two 5 cm sticks and nobody is
		# meant to press them, but rule 2 is about what the hand MEETS, not about what
		# the hand was aiming at, and a sign you can put your forearm through is not a
		# sign. Sizes are the meshes' own, above. They stand at z +0.22 against a row
		# clamped to z -0.08, so nothing on the deck can ever reach them.
		for s2 in [-1.0, 1.0]:
			_add_shape(body, Vector3(float(s2) * (plate_w * 0.5 - 0.04), _deck_top + post_h * 0.5, plate_z),
				Vector3(0.05, post_h, 0.05))
		_add_shape(body, Vector3(0.0, _plate_base + plate_h * 0.5, plate_z),
			Vector3(plate_w, plate_h, 0.045))

	# 6 mm proud of the panel face, and turned to face -Z. Label3D builds its quad
	# in the local XY plane facing +Z and is double_sided by default, so an
	# unrotated label read from the front of the rack is legible but MIRRORED.
	var face_z: float = plate_z - 0.0225 - 0.006
	var wrap_px: float = (plate_w - 0.10) / 0.0017

	# THE PLATE IS A TextScreen, AND BOTH HALVES OF THAT WERE PAID FOR.
	#
	# It began as three Label3D lines. Read back from a live instance they were
	# perfect — text set ("NO UNIT ABOVE ANOTHER"), font set, visible in tree,
	# alpha 1.0, 92 mm tall, 6 mm proud of a near-black panel — and the panel
	# photographed BARE, from 1.5 m, with the camera aimed at it. Two faults were
	# hiding behind one symptom, and each on its own still gives a blank plate:
	#
	#   1. FACING. Every line was built with rotation.y = PI, on the reasoning
	#      that the quad faces +Z and the visitor stands at -Z. The visitor does
	#      not: this rack presents +Z. The text was aimed into the panel.
	#   2. LANE. With the facing corrected, a BakedTextAlbedo.make_label_mesh
	#      quad still photographs blank here — verified after the flip, same
	#      framing, twice — while commons/ui/text_screen.gd renders in the same
	#      capture, in the same session, on the same bench.
	#
	# So the label lane is out and the component that demonstrably reaches a
	# picture is in. Chasing (2) alone cost a double-sided quad and a
	# priority-lifted quad; chasing (1) alone would have "fixed" it invisibly.
	# A thing that measures as present and photographs as absent is either
	# pointing away or drawn by a lane nobody has seen work. Check both.
	#
	# The tint exports carry the rack's own palette so the plate does not arrive
	# wearing the blue lab default, and the width comes from the same wrap
	# measure the old labels used, so the composition is unchanged.
	_screen = TextScreen.new()
	_screen.name = "Plate"
	_screen.mode = 0                                  # SCREEN — a face, no stand
	_screen.width_m = wrap_px * LABEL_M_PER_UNIT
	_screen.bg_color = Color(0.10, 0.10, 0.10)
	_screen.frame_color = Color(0.17, 0.17, 0.17)
	_screen.title_color = Color(0.94, 0.93, 0.90)
	_screen.body_color = Color(0.72, 0.74, 0.71)
	_screen.position = Vector3(0.0, _plate_base + 0.235, face_z)
	add_child(_screen)
	_owned.append(_screen)


## A line on the plate, as a HOLDER whose text is baked and re-baked into it.
##
## This was three Label3D nodes and they drew nothing. Read back from a live
## instance they were perfect — text set ("NO UNIT ABOVE ANOTHER"), font set,
## visible in tree, modulate alpha 1.0, at y 1.75 on a near-black panel, 6 mm
## proud of its face and 9 cm tall — and the panel photographed bare from 1.5 m
## with the camera aimed at it. So the node was right and the LANE was wrong, and
## a plate that names nothing is not a lesser version of this artifact: naming
## the arrangement IS the artifact, and the rack without it is furniture.
##
## Baking is what the rest of the corpus does. The physical text height is
## preserved exactly rather than re-tuned by eye: the old pixel_size was
## 0.0017 m per font unit, so a `size` of 54 stood 92 mm tall, and
## force_font_size = size * 0.0017 * px_per_m reproduces that in the baked image
## instead of letting _fit_font_size solve a new one from the string's length —
## which would make the short verdict tower over the long evidence line.
##
## unshaded, because the panel is deliberately near-black: a lit quad on it
## would read as grey text in a dark room, which is the one thing a label may
## not do.
const LABEL_PX_PER_M: int = 1400
const LABEL_M_PER_UNIT: float = 0.0017

func _label(nm: String, size: int, weight: String, tint: Color, at: Vector3, wrap_px: float) -> Node3D:
	var holder := Node3D.new()
	holder.name = nm
	holder.position = at
	# NOT turned. The plate faced -Z for five captures and photographed bare
	# every time; the rack presents +Z, as the corpus convention says.
	# wrap_px was (plate_w - 0.10) / 0.0017; the metres come straight back out.
	holder.set_meta("wrap_m", wrap_px * LABEL_M_PER_UNIT)
	holder.set_meta("size", size)
	holder.set_meta("weight", weight)
	holder.set_meta("tint", tint)
	return holder


## Bake `text` into `holder`, replacing whatever it said before. Free-then-build
## rather than mutating a texture: the bake is cached by content in
## BakedTextAlbedo, so re-stating the same sentence costs a dictionary hit.
func _say_on(holder: Node3D, text: String) -> void:
	if holder == null or not is_instance_valid(holder):
		return
	for c in holder.get_children():
		holder.remove_child(c)
		c.queue_free()
	if text.strip_edges() == "":
		return
	var size: int = int(holder.get_meta("size", 30))
	var wrap_m: float = float(holder.get_meta("wrap_m", 0.9))
	var tint: Color = holder.get_meta("tint", Color.WHITE)
	var weight: String = String(holder.get_meta("weight", "regular"))
	# two lines of headroom: the longest verdict wraps and the shortest does not
	var h: float = float(size) * LABEL_M_PER_UNIT * 2.4
	var fs: int = int(round(float(size) * LABEL_M_PER_UNIT * float(LABEL_PX_PER_M)))
	var q: MeshInstance3D = TEXT.make_label_mesh(
		text, tint, Vector2(wrap_m, h), LABEL_PX_PER_M, true, weight, fs)
	if q == null:
		return
	# READABLE FROM EITHER SIDE, AND IN FRONT OF ITS OWN PANEL.
	#
	# The quad is built facing +Z and this holder turns it to -Z, which is right
	# for a visitor at the row. Culling it there costs nothing when the guess is
	# right and costs the whole artifact when it is wrong, and the guess had
	# already been wrong once on this plate. A baked label is two triangles.
	#
	# render_priority lifts it clear of the near-black panel 6 mm behind it:
	# the quad is transparent, the panel opaque, and 6 mm is a thin margin to
	# hand to depth precision when the alternative is a plate that says nothing.
	var m := q.get_active_material(0) as StandardMaterial3D
	if m != null:
		m = m.duplicate() as StandardMaterial3D
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.render_priority = 4
		q.material_override = m
	holder.add_child(q)


func _add_shape(body: StaticBody3D, centre: Vector3, size: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	cs.position = centre
	body.add_child(cs)


## One unit. Every one of them is built by this function from the same two numbers,
## which is the only guarantee the corpus has that they are actually identical.
func _make_unit(i: int, x: float, factor: float, u_w: float) -> Node3D:
	var w: float = u_w * factor
	var h: float = _unit_h * factor

	var mesh := BoxMesh.new()
	mesh.size = Vector3(w, h, w)
	var mat: StandardMaterial3D = PBR.rams_body(unit_color, 0.05)
	# rams_body tiles its grain at 4 for a surface about a metre across; a 28 cm
	# block wants it roughly 3.6x finer or the speckle never repeats across the
	# face and the unit reads as flat colour — which on a rack of IDENTICAL units
	# is the difference between five objects and one texture. Rule of thumb from
	# the kit itself: factor ~= 1 / longest dimension.
	PBR.scale_detail(mat, 1.0 / maxf(h, 0.05))

	var mi := MeshInstance3D.new()
	mi.name = "Body"
	mi.mesh = mesh
	mi.material_override = mat
	# ORIGIN AT THE BASE. Every measurement in this file is a height above the
	# deck, so a unit of any size has to rest at the same value; with the base at
	# the body origin, lift is exactly the body's y minus the deck top, whatever
	# the size factor did.
	mi.position = Vector3(0.0, h * 0.5, 0.0)

	var unit: Node3D = null
	var pick: Node = null
	if _pickable_scene != null:
		pick = _pickable_scene.instantiate()
	if pick is RigidBody3D:
		var rb: RigidBody3D = pick
		rb.freeze = true                      # a rack, not a physics toy
		rb.set("release_mode", 1)             # FROZEN: it stays exactly where it is let go
		# The gravity gun rides the VR rig's right hand and its _is_valid_target
		# UNFREEZES any frozen body with pick_up() unless the body is in this
		# group. Without it one stray ray sweeps the whole rack onto the floor —
		# which would be a hierarchy nobody made.
		rb.add_to_group("no_gravity_gun")
		var cs: CollisionShape3D = rb.get_node_or_null("CollisionShape3D")
		if cs != null:
			# THE COLLIDER IS THE MESH, to the millimetre. It is tempting to
			# inflate it so small units are easier to catch; the corpus's warning
			# against that is pink_gun, where a 2 cm shape under a 30 cm body
			# landed one click in 121. The size is kept catchable instead, which
			# is what GRADE_BOTTOM is for.
			var shape := BoxShape3D.new()
			shape.size = Vector3(w, h, w)
			cs.shape = shape
			cs.position = Vector3(0.0, h * 0.5, 0.0)
		for side in ["left", "right"]:
			var gp: String = GRAB_POINT_FMT % side
			if ResourceLoader.exists(gp):
				rb.add_child((load(gp) as PackedScene).instantiate())
		unit = rb
	else:
		# THE RACK STANDS EVEN IF THE HAND DOES NOT. /addons/* is gitignored in
		# this repo, so the pickable can genuinely be absent from a checkout; a
		# still of an empty plinth would be a picture of nothing at all, and the
		# argument here is carried by the geometry and the plate, not by the grab.
		var sb := StaticBody3D.new()
		sb.collision_layer = 1
		sb.collision_mask = 0
		var cs2 := CollisionShape3D.new()
		var b2 := BoxShape3D.new()
		b2.size = Vector3(w, h, w)
		cs2.shape = b2
		cs2.position = Vector3(0.0, h * 0.5, 0.0)
		sb.add_child(cs2)
		unit = sb

	unit.name = "Unit%d" % i
	unit.add_child(mi)
	unit.position = Vector3(x, _deck_top, _row_z)
	_meshes.append(mi)
	return unit


# ── THE FOUR SHIPPED CLAIMS ──────────────────────────────────────────────────

## Positions and size factors for one named order. This function may set transforms
## and sizes. It may NOT touch the plate, and it does not know what the plate is
## going to say — see _read_and_name.
func _order_plan(n: int, u_w: float) -> Dictionary:
	var margin: float = 0.10
	var usable: float = maxf(deck_width_m - margin * 2.0, u_w * 2.0)
	var widest: float = u_w * HERO_FACTOR
	var pitch: float = (usable - widest) / maxf(float(n - 1), 1.0)
	var half: float = pitch * float(n - 1) * 0.5

	var xs: Array[float] = []
	var fs: Array[float] = []
	for i in range(n):
		xs.append(-half + pitch * float(i))
		fs.append(1.0)

	var key: String = order.strip_edges().to_lower()
	if key == "centered":
		key = "centred"

	if key == "hero":
		# One unit enlarged, positions untouched. Enlarged and NOT raised, so that
		# nothing in a shipped still is floating in mid-air — a levitating block
		# reads as a bug from four angles and the plate cannot outrun that. Lifting
		# is left to the visitor, who has a hand in the shot to explain it.
		fs[n / 2] = HERO_FACTOR
	elif key == "graded":
		# A ladder across a FIXED span rather than a fixed step: the span is what
		# keeps the smallest unit catchable and the tallest one clear of the plate
		# at any count, and the step falls out of it.
		for i in range(n):
			var t: float = 0.0 if n <= 1 else float(i) / float(n - 1)
			fs[i] = lerpf(GRADE_BOTTOM, GRADE_TOP, t)
	elif key == "centred" and n >= 3:
		# One unit alone in the middle with the rest packed out to the flanks. The
		# moat is not set directly — it is whatever is left over once both flanks
		# are pushed to the edges, which is why the pack has to be TIGHTER than the
		# natural pitch and not merely different from it: at seven units the serial
		# pitch has already fallen to 0.23 m, and a pack of 0.216 would leave a moat
		# nobody could see. 1.25x the unit is a 4 cm edge gap — a visible huddle at
		# any count this deck can hold.
		#
		# Note what this cannot do. At THREE units, mirror symmetry forces the two
		# flankers onto the outer edges, which is the evenly spaced arrangement — so
		# `#order:centred#count:3` builds the serial case and the plate says
		# NO UNIT ABOVE ANOTHER. At an EVEN count there is no middle unit to isolate
		# and it makes two camps instead. Both are left to be read rather than
		# corrected: a preset that quietly fixed itself would be a preset the plate
		# had to agree with, and the plate agrees with nothing.
		var tight: float = u_w * 1.25
		var edge: float = half
		var flank: int = n / 2
		var k: int = 0
		# Ascending in x, both flanks. Writing the left flank inward-out here was
		# the first version and it laid the units down in the wrong index order —
		# invisible, because the units are identical and the classifier sorts by x,
		# which is exactly the kind of wrong that survives a look at the picture.
		for i in range(flank):
			xs[k] = -edge + tight * float(i)
			k += 1
		if n % 2 == 1:
			xs[k] = 0.0
			k += 1
		for i in range(flank):
			xs[k] = edge - tight * float(flank - 1 - i)
			k += 1

	return {"xs": xs, "factors": fs}


# ── READING THE ROW ──────────────────────────────────────────────────────────

func _process(_delta: float) -> void:
	var changed: bool = false
	for i in range(_units.size()):
		var u: Node3D = _units[i]
		if not is_instance_valid(u):
			continue
		if clamp_reach:
			_constrain(i, u)
		# POLLING, AND NOTHING ELSE COVERS BOTH HANDS. DesktopInteractionPointer
		# never calls pick_up(), never emits and never marks the object — it writes
		# global_position each frame and restores freeze/layer/mask on release,
		# silently. So on desktop, which is the walk Palle does daily, there is no
		# grab signal to connect to at all. XRToolsPickable does emit picked_up and
		# dropped, but only at the two ends of a grab, never during the motion.
		# The transform is the one thing both hands actually touch.
		var t: Transform3D = u.transform
		if t.is_equal_approx(_last[i]):
			continue
		_last[i] = t
		changed = true
	if changed:
		_read_and_name()


func _constrain(i: int, u: Node3D) -> void:
	var w: float = 0.16
	# WHERE THE UNIT RESTS — which is only the same question as "origin on the deck"
	# while the unit is upright. The mesh hangs h/2 ABOVE the unit origin, because
	# rule 1 puts the origin at the base; tip a unit onto its side, which the registry
	# advertises as an interaction, and that offset rotates out of Y. The box then
	# straddles the origin, and clamping the origin to the deck buries half of it —
	# w/2, 80 mm at the defaults — inside the steel. A block sunk into the table under
	# a sign reading NO UNIT ABOVE ANOTHER is the same failure as the z clamp exists to
	# prevent, in the other axis.
	#
	# The AABB's lowest point IS where a box touches, at any rotation, so the offset is
	# measured rather than assumed, and it does not depend on q.y — both terms move
	# together, so there is no feedback. Upright it is exactly zero and this is a no-op.
	var rest: float = _deck_top
	if i < _meshes.size() and is_instance_valid(_meshes[i]) and _meshes[i].mesh != null:
		var mi: MeshInstance3D = _meshes[i]
		w = mi.mesh.get_aabb().size.x
		var ab: AABB = (u.transform * mi.transform) * mi.mesh.get_aabb()
		rest = _deck_top + (u.position.y - ab.position.y)
	var lim: float = maxf(deck_width_m * 0.5 - w * 0.5 - 0.02, 0.0)
	var q: Vector3 = u.position
	var c := Vector3(
		clampf(q.x, -lim, lim),
		clampf(q.y, rest, rest + _lift_ceiling),
		_row_z)
	if not c.is_equal_approx(q):
		u.position = c


## Where each unit actually is, in the rack's own frame.
##
## MEASURED, NOT REMEMBERED, and that is the load-bearing decision in this file.
## The plate never sees `order`. It reads the built geometry, so if _order_plan and
## the plate ever disagree the plate wins and the preset is what is wrong — which
## makes the four shipped stills a real test of the classifier rather than four
## captions the code wrote for itself.
##
## LOCAL coordinates, because neither hand reparents a pickable; the rack can be
## rotated or scaled by any map token and every number below is unaffected.
##
## The height is the AABB's, so a unit turned on its side measures SHORT. That is
## deliberate: from the front of a rack of standing units, a unit lying down is a
## shorter unit, and this plate reports what the room shows rather than what the
## object privately still is.
func _measure() -> Array:
	var rows: Array = []
	for i in range(_units.size()):
		var u: Node3D = _units[i]
		if not is_instance_valid(u) or i >= _meshes.size():
			continue
		var mi: MeshInstance3D = _meshes[i]
		if not is_instance_valid(mi) or mi.mesh == null:
			continue
		var ab: AABB = (u.transform * mi.transform) * mi.mesh.get_aabb()
		rows.append({
			"x": ab.get_center().x,
			"h": ab.size.y,
			"lift": ab.position.y - _deck_top,
		})
	rows.sort_custom(func(a, b): return float(a["x"]) < float(b["x"]))
	return rows


func _read_and_name() -> void:
	var said: Dictionary = _classify(_measure())
	# str(), not String(). The corpus has already been bitten once by the String()
	# constructor throwing on a value that came out of a Dictionary.
	if _screen == null or not is_instance_valid(_screen):
		return
	_screen.title = str(said["verdict"])
	_screen.body = str(said["evidence"]) + CREDIT_LINE


## THE ARTIFACT. Everything above this is a table.
##
## Three channels, measured and normalised so they can be compared with one
## another: how much the units differ in SIZE, how much they differ in LIFT, and
## how much the gaps between them differ. Size and lift are one family — both are
## "this one stands above the others" — so the louder of the two is the one that
## gets classified, and spacing competes with the pair.
##
## The gaps are centre-to-centre. Edge-to-edge would let enlarging a unit fake a
## spacing claim, and then the hero preset would come back reading as a crowd.
func _classify(rows: Array) -> Dictionary:
	var n: int = rows.size()
	if n == 0:
		return {"verdict": "NOTHING IS ARRANGED", "evidence": "the rack is empty"}
	if n == 1:
		return {"verdict": "ONE UNIT IS NOT A COMPOSITION",
			"evidence": "a series needs a second term"}

	var hs: Array[float] = []
	var ls: Array[float] = []
	var xs: Array[float] = []
	for r in rows:
		hs.append(float(r["h"]))
		ls.append(float(r["lift"]))
		xs.append(float(r["x"]))

	var gaps: Array[float] = []
	for i in range(n - 1):
		gaps.append(xs[i + 1] - xs[i])

	var med_h: float = maxf(_median(hs), 0.0001)
	var mean_g: float = maxf(_mean(gaps), 0.0001)
	var size_spread: float = (_amax(hs) - _amin(hs)) / med_h
	var lift_spread: float = (_amax(ls) - _amin(ls)) / med_h
	var gap_spread: float = (_amax(gaps) - _amin(gaps)) / mean_g

	var tol: float = clampf(tolerance, 0.01, 0.40)
	var ev: String = "%d units · spacing %d%% · size %d%% · lift %d%% · tol %d%%" % [
		n, _pct(gap_spread), _pct(size_spread), _pct(lift_spread), _pct(tol)]

	if size_spread <= tol and lift_spread <= tol and gap_spread <= tol:
		return {"verdict": "NO UNIT ABOVE ANOTHER", "evidence": ev}

	var prom_spread: float = maxf(size_spread, lift_spread)
	# Written out rather than as a ternary: a conditional expression over two typed
	# arrays infers as bare Array, and assigning that back into an Array[float]
	# is the sort of thing that either warns or fails depending on the build.
	var prom: Array[float] = ls
	if size_spread >= lift_spread:
		prom = hs

	var verdict: String = ""
	if prom_spread >= gap_spread:
		verdict = _name_series(prom, med_h, n, tol)
	else:
		verdict = _name_gaps(gaps, mean_g, n, tol)
	return {"verdict": verdict, "evidence": ev}


## Classify a per-unit series (sizes or lifts) that is ALREADY known to vary by
## more than the tolerance. That precondition is what lets the monotone test use a
## step threshold of half a percent: with the total spread established, n-1 steps
## all leaning the same way is the evidence, and demanding each individual step
## clear the tolerance would make a long gentle ladder read as an accident.
func _name_series(v: Array[float], unit: float, n: int, tol: float) -> String:
	if n >= 3 and _monotone(v, unit * 0.005):
		return "YOU MADE A RANK"
	if n == 2:
		return "ONE OVER THE OTHER"
	var med: float = _median(v)
	var devs: Array[float] = []
	for x in v:
		devs.append(x - med)
	var hi: int = 0
	for i in range(devs.size()):
		if absf(devs[i]) > absf(devs[hi]):
			hi = i
	var second: float = 0.0
	for i in range(devs.size()):
		if i != hi:
			second = maxf(second, absf(devs[i]))
	# ONE unit out of line and the rest together: that is a hero. Two out of line
	# and it is not a hierarchy, it is a mess, and the plate should not flatter it.
	if absf(devs[hi]) >= prominence_gate * unit and second <= tol * unit:
		return "YOU MADE A HERO" if devs[hi] > 0.0 else "YOU DEMOTED ONE"
	return "YOU MADE AN UNEVEN SET"


func _name_gaps(g: Array[float], mean_g: float, n: int, tol: float) -> String:
	var m: int = g.size()
	var sym: bool = true
	for i in range(m):
		if absf(g[i] - g[m - 1 - i]) > tol * mean_g:
			sym = false
			break
	if sym and m >= 2:
		if n % 2 == 1:
			# The middle unit's two gaps, against every other gap in the row.
			var c: int = n / 2
			var inner: float = minf(g[c - 1], g[c])
			var outer: float = 0.0
			for i in range(m):
				if i != c - 1 and i != c:
					outer = maxf(outer, g[i])
			if inner > outer:
				return "YOU MADE A FOCAL POINT"
		elif m % 2 == 1:
			var mid: float = g[(m - 1) / 2]
			if mid >= _amax(g):
				return "YOU MADE TWO CAMPS"
	if m >= 2 and _monotone(g, mean_g * 0.005):
		return "YOU MADE A GRADIENT"
	# One gap standing well clear of the others, and the others together: a group
	# and somebody outside it.
	var big: int = 0
	for i in range(m):
		if g[i] > g[big]:
			big = i
	var rest: Array[float] = []
	for i in range(m):
		if i != big:
			rest.append(g[i])
	if rest.size() >= 1:
		var spread_rest: float = 0.0 if rest.size() < 2 else (_amax(rest) - _amin(rest)) / mean_g
		if g[big] >= _amax(rest) * (1.0 + prominence_gate) and spread_rest <= tol:
			return "YOU MADE A GROUP AND AN OUTSIDER"
	return "YOU MADE UNEVEN SPACING"


# ── ARITHMETIC ───────────────────────────────────────────────────────────────

func _monotone(v: Array[float], step_eps: float) -> bool:
	if v.size() < 2:
		return false
	var sign_first: float = signf(v[1] - v[0])
	if sign_first == 0.0:
		return false
	for i in range(v.size() - 1):
		var d: float = v[i + 1] - v[i]
		if signf(d) != sign_first or absf(d) < step_eps:
			return false
	return true


func _median(v: Array[float]) -> float:
	if v.is_empty():
		return 0.0
	var s: Array[float] = v.duplicate()
	s.sort()
	var k: int = s.size() / 2
	if s.size() % 2 == 1:
		return s[k]
	return (s[k - 1] + s[k]) * 0.5


func _mean(v: Array[float]) -> float:
	if v.is_empty():
		return 0.0
	var t: float = 0.0
	for x in v:
		t += x
	return t / float(v.size())


func _amax(v: Array[float]) -> float:
	var m: float = v[0]
	for x in v:
		m = maxf(m, x)
	return m


func _amin(v: Array[float]) -> float:
	var m: float = v[0]
	for x in v:
		m = minf(m, x)
	return m


func _pct(x: float) -> int:
	return int(round(clampf(x, 0.0, 9.99) * 100.0))


# ── THE MAP TOKEN ────────────────────────────────────────────────────────────

## Keys honoured:
##   "order"  — serial | centred | centered | hero | graded   (a WORD)
##   "count"  — how many units, 1..7
##   "width"  — deck width in metres
##   "depth"  — deck depth in metres
##   "size"   — unit width in metres
##   "height" — deck height in metres
##   "solid"  — plinth, posts and sign as collision. WRITE `#solid:false`, never
##              `#solid:0` — see _flag, where the reason is a fault in the grid
##              and not in this artifact
##   "color1" — the one colour every unit wears
##
## EVERY NUMERIC KEY HERE IS ALREADY IN GridInteractablesComponent.CONFIG_PARAM_NAMES
## (:16), and that is load-bearing rather than tidy: `#key:12` on a name outside
## that list is read as the tutorial's positional shorthand, the artifact receives
## the boolean `true`, and the map silently gains a 12 degree rotation. That is why
## there is no `#pitch:` and no `#spacing:` on this object — neither name is
## registered, so both would be traps. The spacing is derived from width and count,
## which are.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("order"):
		var o: String = str(config_data["order"]).strip_edges().to_lower()
		if o == "centered":
			o = "centred"
		if ORDERS.has(o):
			order = o
		else:
			push_warning("serial_principle: unknown order '%s' — keeping '%s'" % [o, order])
	if config_data.has("count"):
		unit_count = clampi(int(config_data["count"]), 1, 7)
	if config_data.has("width"):
		deck_width_m = clampf(float(config_data["width"]), 0.6, 6.0)
	if config_data.has("depth"):
		deck_depth_m = clampf(float(config_data["depth"]), 0.3, 2.0)
	if config_data.has("size"):
		unit_size_m = clampf(float(config_data["size"]), 0.06, 0.40)
	if config_data.has("height"):
		deck_height_m = clampf(float(config_data["height"]), 0.30, 1.40)
	if config_data.has("solid"):
		solid = _flag(config_data["solid"])
	for k in ["color1", "color"]:
		if config_data.has(k):
			unit_color = _as_color(config_data[k], unit_color)
	if is_inside_tree():
		_build()
		_read_and_name()


## THIS COMMENT WAS WRONG WHEN IT SHIPPED, and it was wrong the same way in
## fetish_portal:187 and do_not_cross_barrier:205, which is where it was copied
## from. It said `#solid:0` arrives as the STRING "0". It does not arrive at all:
## `solid` is absent from CONFIG_PARAM_NAMES and "0" passes is_valid_float(), so
## the shorthand branch (GridInteractablesComponent.gd:1705) eats the whole pair,
## hands this function the BOOLEAN true and stamps a 0 degree rotation on the map.
## The spelling that reads as "off" is the one that turns the collider ON.
##
## What the helper is actually for is every lane that does NOT run the grid's
## _coerce_to_export_type (:1770) — a config Dictionary built in code, a museum
## stamp on a root still outside the tree, a direct caller. There "false" arrives
## as a raw String, and bool() on ANY non-empty String is true in GDScript.
func _flag(v) -> bool:
	if typeof(v) == TYPE_BOOL:
		return bool(v)
	return str(v).strip_edges().to_lower() in ["true", "1", "yes", "on"]


func _as_color(v, fallback: Color) -> Color:
	if v is Color:
		return v
	if v is Array and (v as Array).size() >= 3:
		var a: Array = v
		return Color(float(a[0]), float(a[1]), float(a[2]))
	if v is String and str(v) != "":
		return Color(str(v))
	return fallback
