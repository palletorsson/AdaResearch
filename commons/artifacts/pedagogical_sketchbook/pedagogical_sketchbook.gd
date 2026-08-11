extends Node3D
class_name PedagogicalSketchbook

# @identity
# essence: three sheets pinned side by side on one standing easel, each carrying THE SAME WALK read a different way. Left: the walk as an open line, the point still on its journey. Centre: the same walk closed on itself, so the deviation it earned is spent on the radius of an enclosure. Right: the same walk untouched, with a surface raised to the floor beneath it, so the identical points now read as the top edge of a plane. Klee's Pedagogical Sketchbook opens by dividing line into active, medial and passive; this is that page made an object you can stand in front of.
# desire: it wants the taxonomy to stop being a caption and become a comparison. klee_walking_point can be any one of the three, and in twenty maps it has only ever been the first — so the claim that these are ONE walk seen three ways has never been available to look at, only to read. The sketchbook wants the player to see the wobble of the meander survive into the ring's radius and into the plane's silhouette, and to conclude, without being told, that "line" is not a kind of thing but a way of being looked at.
# critical_parameter: walk_style. It turns all three panels at once, which is the whole design: the axis does not choose between the readings, it changes the walk they are all readings OF. Turn it to straight and you get the collapsed line, the perfect circle and the plain rectangle — the taxonomy's degenerate case, where the three readings still differ but the biography is gone. grain is the second knob: how many points the walk is quantised into, and it is here to show that the three readings are not equally robust to coarse sampling.
# triggers: _ready instantiates three klee_walking_point scenes, sets line to each of the source's own three kinds before add_child so each builds itself, and pins the walk animation to completion so the still photographs the finished mark; apply_grid_config rebuilds only on a value that validated, differs, and arrives after the first build.
# emerges: at grain=points the left panel has stopped being a line — it is nine beads — and the centre panel has stopped being a ring; but the right panel is still unambiguously a plane. Klee's third kind survives coarse sampling that destroys the other two, because a plane only needs its edge sampled while a line has to BE its points. Nobody could see that from the source, which can only be one kind at a time.
# needs: klee_walking_point on disk [its scene and its two value tables, both preloaded]; three frames to make the comparison a triptych rather than three objects; a floor to stand on
# relationships: made entirely out of `klee_walking_point` — three of it, unmodified, driven by its own LINE_KINDS table; sibling to `grabbable_line`, which asks what a line is made OF and answers by breaking a solid rod, where this asks what a line IS and answers by not touching it at all; cousin to `draw_dot_time_domain`, whose `retention` axis is the same discovery in the time domain (what a trace KEEPS, against what a trace IS).
# truth: the three kinds of line are not three objects. They are one walk and three decisions about where to stop looking. Klee's page one is usually taught as a classification; put the three side by side from one walk and it reads instead as a demonstration that classification was the wrong verb.

## The Pedagogical Sketchbook triptych — one walk, three ontologies of line.
##
## Built procedurally out of three live klee_walking_point instances. Nothing
## about the walk is re-implemented here: the path generator, the closing of the
## medial ring and the raising of the passive plane are all the source's own
## code, reached by instancing its scene. This file only decides where the three
## panels stand, what they are all set to, and that the walk has finished by the
## time anyone photographs it.
##
## Origin is the FLOOR at the centre of the middle panel. The sheets face +Z.

# ── DNA (stage synthesis, born promoted 2026-08-06) ──────────────────────────
#
# WHY THIS EXISTS. The grant calls the whole project "Klee's Sketchbook in drag
# in VR" and klee_walking_point is its founding image. That artifact was promoted
# with two axes — walk_style (what the point DID) and line (what the mark IS) —
# and the second one is the Sketchbook's own opening taxonomy: active, medial,
# passive. But an axis shows one value per still. The claim those three values
# make TOGETHER — that they are one walk and not three objects — is the one
# thing the source can never photograph.
#
# HOW THE THREE PANELS ARE KEPT HONEST. They are the same walk by CONSTRUCTION,
# not by agreement:
#   · all three are instances of klee_walking_point.tscn, not ports;
#   · they get identical walk_style, walk_length, walk_height and trail_points,
#     set before add_child so each builds with them in its own _ready;
#   · the panel list is not written here — it is read out of the source's own
#     `LINE_KINDS` const, in the source's own order, so the triptych cannot
#     drift out of step with the taxonomy it exhibits (the slot_machine pattern);
#   · and there is NOTHING TO SEED. klee_walking_point is deterministic summed
#     sines with no randf and no noise anywhere in the file — a requirement of
#     the Primitives sequence, which this synthesis inherits for free. The three
#     panels agree because the same inputs produce the same points, which is a
#     stronger guarantee than a shared seed and was checked by reading the file,
#     not assumed.
#
# walk_style — REUSED CHARACTER FOR CHARACTER from klee_walking_point, same four
#   values, same order, same default. It turns all three panels at once, because
#   the triptych IS the line axis unrolled into space: the knob that remains is
#   the one that changes the walk being read.
#     meander   SHIPPED, and the default here. Three summed sines, no goal.
#     straight  the collapsed route. The taxonomy's degenerate case: line, circle
#               and rectangle, all three still distinct, all three now generic.
#     arc       one decision, made once.
#     spiral    the walk that keeps turning inside its own territory — and the
#               value that exposes an assumption in Klee's third kind. A spiral
#               is not single-valued in x, so the passive plane's columns pile up
#               on each other instead of forming a field. The source has always
#               done this; it is not repaired here, because repairing it would
#               make this a port and not an exhibit.
#
# grain — how finely the walk is quantised into its constituent points. THE WORD
#   IS TAKEN FROM `grabbable_line` AND ITS VALUE LIST IS REFUSED, on the record
#   and for the same reason folding_past refused `fold`: grabbable_line's grain
#   is solid|split|quartered|lattice|shell, which are PARTITIONS OF A SOLID ROD,
#   and every one of them presumes a whole that gets broken. This trail was never
#   solid. It is points pretending to be a line, and the question runs the other
#   way — how many points before the pretence works. Taking that word with those
#   answers would name a mechanism this object lacks. `resolution` (coarse|mid|
#   fine|ultra) was refused too: it is a quality ladder, and here the coarse end
#   is not worse, it is the truth uncovered.
#     points  9   too few to read as a line at all. THE FINDING LIVES HERE: the
#                 left panel is beads and the centre panel is a nonagon, but the
#                 right panel is still plainly a plane.
#     beads   20  the chain — you read the points and the line at once.
#     stroke  48  DEFAULT, and klee_walking_point's own shipped trail_points, so
#                 each panel is exactly the picture the source ships, three times.
#     flood   112 continuous. The points are gone; only the marks remain.
#
# DECLINED. Everything about the walk's animation — speed, hold, loop, how far
# the head has got — is declined for the reason the source declined it: the
# evidence is one still and a still cannot tell 0.32 from 0.9. Here it is worse
# than declined, it is PINNED: the panels are driven to completion inside the
# first process frame and held forever, so the still is the finished mark by
# construction rather than by settle timing. Panel arrangement is declined as an
# axis because it is mounting, not argument. Hinging the outer sheets into a
# proper altarpiece was designed and dropped: the sweep camera sits at yaw 0.62
# rad off-axis, so angled wings would turn one panel toward it and the other
# away, and unequal treatment of the three readings is the one thing this object
# must not do.

const KLEE_SCENE: PackedScene = preload("res://commons/primitives/klee_walking_point/klee_walking_point.tscn")
# Untyped on purpose: an untyped const preload exposes the script's own consts by
# name, which is how LINE_KINDS and WALK_STYLES are read rather than copied.
const KLEE_SCRIPT = preload("res://commons/primitives/klee_walking_point/klee_walking_point.gd")

## Mirrors klee_walking_point.WALK_STYLES. GDScript cannot build an @export_enum
## from a const, and the declaration gate reads the enum, so the list has to be
## written out — but _check_vocabulary() compares the two at runtime and warns if
## they ever diverge, which is the closest this language gets to the promise.
const WALK_STYLE_VALUES: PackedStringArray = ["meander", "straight", "spiral", "arc"]
const GRAIN_POINTS: Dictionary = {"points": 9, "beads": 20, "stroke": 48, "flood": 112}

@export_group("Reading")
## The walk all three panels are readings of. klee_walking_point's own four.
@export_enum("meander", "straight", "spiral", "arc") var walk_style: String = "meander"
## How finely the walk is quantised into points. See the DNA block for the refusal.
@export_enum("points", "beads", "stroke", "flood") var grain: String = "stroke"

@export_group("Sheet")
## Length of the walk drawn on each sheet. Sized so the widest reading (an open
## meander at 0.75) clears the frame's inner width with 0.05 either side.
@export var walk_length: float = 0.75
@export var walk_height: float = 0.45
@export var frame_color: Color = Color(0.62, 0.58, 0.50)
@export var caption_color: Color = Color(0.80, 0.76, 0.68)
## Word under each sheet. Off leaves the taxonomy for the eye alone.
@export var captions: bool = true

# ── Geometry, all derived once and stated so the numbers can be argued with ──
#
# The content's worst case across every walk_style x line combination is the
# spiral: it reaches +-0.45*walk_length in Y, and its passive plane then drops a
# further 0.6*walk_height below that. So the sheet has to hold y in
# [-0.6475, +0.3775] (head radius included) — span 1.025, centred at -0.135,
# which is where CONTENT_OFFSET_Y comes from. Every panel takes the SAME offset;
# centring them individually would be the flattering lie this object exists to
# avoid.
const FRAME_W: float = 0.92
const FRAME_H: float = 1.18
const RAIL: float = 0.035
const RAIL_D: float = 0.03
const PANEL_PITCH: float = 1.02
const PANEL_CENTRE_Y: float = 1.30
const CONTENT_OFFSET_Y: float = 0.135
const FRAME_Z: float = -0.055
const CAPTION_DROP: float = 0.09
const FOOT_DEPTH: float = 0.16
## Fast enough that one process frame carries the walk past its end, where it
## clamps and holds. klee_walking_point's own capture fixture is walk_speed 40 /
## loop false; this takes it further so no settle time has to be assumed.
const PANEL_WALK_SPEED: float = 1000.0

var _built: bool = false
var _frame_mat: StandardMaterial3D = null


func _ready() -> void:
	_read_metadata_overrides()
	_check_vocabulary()
	_build()


## Rebuild only when a named value VALIDATED, actually MOVED, and _ready has
## already built once. force_pad tore itself down on any call including ones
## naming nothing it owns; this returns early on all three counts.
func apply_grid_config(config_data: Dictionary) -> void:
	var before: String = _config_signature()
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if not _built:
		return
	if _config_signature() == before:
		return
	_rebuild()


func _config_signature() -> String:
	return "%s|%s|%.4f|%.4f|%s" % [walk_style, grain, walk_length, walk_height, str(captions)]


func _read_metadata_overrides() -> void:
	if has_meta("config_walk_style"):
		var ws: String = str(get_meta("config_walk_style")).strip_edges().to_lower()
		if WALK_STYLE_VALUES.has(ws):
			walk_style = ws
	if has_meta("config_grain"):
		var gr: String = str(get_meta("config_grain")).strip_edges().to_lower()
		if GRAIN_POINTS.has(gr):
			grain = gr
	if has_meta("config_walk_length"):
		walk_length = float(str(get_meta("config_walk_length")))
	if has_meta("config_walk_height"):
		walk_height = float(str(get_meta("config_walk_height")))
	if has_meta("config_captions"):
		# Parsed from a STRING. A typed bool export handed a token parser's "true"
		# rejects it before _ready ever runs; the conversion belongs here, where
		# the value is still text.
		var cp: String = str(get_meta("config_captions")).strip_edges().to_lower()
		captions = cp == "true" or cp == "1" or cp == "yes"


## The one guarantee this file cannot get from the compiler: that the four words
## in WALK_STYLE_VALUES are still the four words klee_walking_point implements.
## A silent divergence here would set an invalid value, the panels would fall
## back to their own default, and the sweep would publish identical frames and
## call the axis inert — the science_screen failure exactly.
func _check_vocabulary() -> void:
	var theirs: String = ",".join(KLEE_SCRIPT.WALK_STYLES)
	var mine: String = ",".join(WALK_STYLE_VALUES)
	if theirs != mine:
		var msg: String = "pedagogical_sketchbook: walk_style has drifted from its source."
		msg += " klee_walking_point implements [" + theirs + "];"
		msg += " this artifact declares [" + mine + "]."
		msg += " Fix the @export_enum and the registry together, or the sweep will"
		msg += " photograph the default four times."
		push_warning(msg)
	if KLEE_SCRIPT.LINE_KINDS.size() < 2:
		push_warning("pedagogical_sketchbook: klee_walking_point.LINE_KINDS has "
			+ "fewer than two kinds; there is no triptych to build.")


# ── Build ─────────────────────────────────────────────────────────────

func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	_built = false
	_frame_mat = null
	_build()


func _build() -> void:
	_built = true
	_frame_mat = StandardMaterial3D.new()
	_frame_mat.albedo_color = frame_color
	_frame_mat.emission_enabled = true
	_frame_mat.emission = frame_color
	_frame_mat.emission_energy_multiplier = 0.25
	_frame_mat.roughness = 0.85

	# The panel list is the SOURCE's taxonomy, in the source's own order, read at
	# runtime. Left to right: active, medial, passive — not a curatorial choice.
	var kinds: PackedStringArray = KLEE_SCRIPT.LINE_KINDS
	var count: int = kinds.size()
	if count < 1:
		return
	var span: float = float(count - 1) * PANEL_PITCH
	var n_points: int = int(GRAIN_POINTS.get(grain, 48))

	for i in range(count):
		var kind: String = kinds[i]
		var x: float = -span * 0.5 + float(i) * PANEL_PITCH
		_build_frame(x)
		_build_panel(x, kind, n_points)
		if captions:
			_build_caption(x, kind)

	# One foot bar under the whole triptych. It is also the thing that keeps the
	# capture AABB IDENTICAL across every value of both axes: the frames and the
	# foot never change, so the fixed camera frames the same box for all sixteen
	# variants and the tiles are comparable pixel for pixel.
	var foot: MeshInstance3D = _box(
		Vector3(span + FRAME_W, RAIL, FOOT_DEPTH),
		Vector3(0.0, RAIL * 0.5, -0.02))
	foot.name = "Foot"
	add_child(foot)


## One sheet's frame: two stiles carried down to the floor, so the three
## readings meet the eye at one height, and two rails closing the sheet.
func _build_frame(x: float) -> void:
	var half_w: float = FRAME_W * 0.5
	var half_h: float = FRAME_H * 0.5
	var top: float = PANEL_CENTRE_Y + half_h
	var bottom: float = PANEL_CENTRE_Y - half_h
	var stile_x: float = half_w - RAIL * 0.5

	var left: MeshInstance3D = _box(Vector3(RAIL, top, RAIL_D),
		Vector3(x - stile_x, top * 0.5, FRAME_Z))
	left.name = "StileL"
	add_child(left)

	var right: MeshInstance3D = _box(Vector3(RAIL, top, RAIL_D),
		Vector3(x + stile_x, top * 0.5, FRAME_Z))
	right.name = "StileR"
	add_child(right)

	var rail_top: MeshInstance3D = _box(Vector3(FRAME_W, RAIL, RAIL_D),
		Vector3(x, top - RAIL * 0.5, FRAME_Z))
	rail_top.name = "RailTop"
	add_child(rail_top)

	var rail_bottom: MeshInstance3D = _box(Vector3(FRAME_W, RAIL, RAIL_D),
		Vector3(x, bottom + RAIL * 0.5, FRAME_Z))
	rail_bottom.name = "RailBottom"
	add_child(rail_bottom)


## One reading. Every property is written BEFORE add_child, so the instance's own
## _ready builds with them; written after, _build would already have run on the
## defaults and the panel would be a lie about which walk it shows.
func _build_panel(x: float, kind: String, n_points: int) -> void:
	var panel: Node3D = KLEE_SCENE.instantiate()
	panel.name = "Sheet_%s" % kind
	_apply_to_panel(panel, "line", kind)
	_apply_to_panel(panel, "walk_style", walk_style)
	_apply_to_panel(panel, "trail_points", n_points)
	_apply_to_panel(panel, "walk_length", walk_length)
	_apply_to_panel(panel, "walk_height", walk_height)
	# The walk is generated centred on its own origin; the sheet, not the floor,
	# is what it hangs in.
	_apply_to_panel(panel, "lift_to_floor", false)
	# The mark, not the making. See DECLINED in the DNA block.
	_apply_to_panel(panel, "walk_speed", PANEL_WALK_SPEED)
	_apply_to_panel(panel, "loop", false)
	panel.position = Vector3(x, PANEL_CENTRE_Y + CONTENT_OFFSET_Y, 0.0)
	add_child(panel)


## Object.set() on a property that does not exist is a SILENT no-op, which is the
## exact shape of every wasted batch in this corpus: the value never lands, the
## panel builds its own default, and sixteen identical frames get published as a
## verdict. So every write is checked against the real property list first, and a
## miss is loud.
func _apply_to_panel(panel: Object, prop: String, value: Variant) -> void:
	if not _has_property(panel, prop):
		var msg: String = "pedagogical_sketchbook: klee_walking_point has no property '"
		msg += prop + "'. The sheet will build with its own default and this"
		msg += " triptych will quietly show the wrong picture."
		push_warning(msg)
		return
	panel.set(prop, value)


func _has_property(obj: Object, prop: String) -> bool:
	for p in obj.get_property_list():
		if str(p.get("name", "")) == prop:
			return true
	return false


## One word, Klee's own. Label3D carries no mesh, so it does not touch the
## capture AABB and cannot pull the framing off the sheets.
func _build_caption(x: float, kind: String) -> void:
	var lab: Label3D = Label3D.new()
	lab.name = "Caption_%s" % kind
	lab.text = kind
	lab.font_size = 32
	lab.pixel_size = 0.0022
	lab.modulate = caption_color
	lab.outline_size = 0
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.position = Vector3(x,
		PANEL_CENTRE_Y - FRAME_H * 0.5 - CAPTION_DROP,
		FRAME_Z + 0.02)
	add_child(lab)


func _box(size: Vector3, pos: Vector3) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var bm: BoxMesh = BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _frame_mat
	mi.position = pos
	return mi
