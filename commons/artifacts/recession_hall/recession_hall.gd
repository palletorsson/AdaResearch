extends Node3D
class_name RecessionHall

## recession_hall — an axis named after one of its four values, and the value it is named
## after is the one the camera can barely see.
##
## ═══════════════════════════════════════════════════════════════════════════════════════
## THE FAMILY. Two tokens declare `recession` with the identical four values
## nested | collapsed | abreast | strata, and nothing else in the corpus declares the word:
##
##   folding_past          res://commons/primitives/temporal/animated_folding_past.tscn
##                         → commons/primitives/temporal/animated_folding_past.gd
##   fractal_recursion_2   res://algorithms/fractals/example_8_2_recursion_vr.tscn
##                         → algorithms/fractals/example_8_2_recursion_vr.gd
##
## The brief asked whether these two are about the same thing. They are — but not about
## the thing the word says, and they are NOT about it in the same way. Four readings, each
## traceable to a line.
##
## ───────────────────────────────────────────────────────────────────────────────────────
## (1) NOTHING RECEDES, IN SEVEN OF THE EIGHT CELLS.
##
## `recession` names depth. Count the depths:
##
##   animated_folding_past.gd:185   nested     z = z_base_offset + (-frame_progress * 4.5)
##                                             → ten frames spread over 4.05 m of z
##   animated_folding_past.gd:194   collapsed  origin = (0, 0, z_base_offset - 4.5)   ONE z
##   animated_folding_past.gd:197   abreast    origin = (rank * frame_width * 0.2, 0,
##                                             z_base_offset)                          ONE z
##   animated_folding_past.gd:204   strata     origin = (0, …, z_base_offset)          ONE z
##
##   example_8_2_recursion_vr.gd:160-175  _seat() returns z = 0.0 in EVERY branch.
##   example_8_2_recursion_vr.gd:245      position = center + Vector3(0, 0, (depth-d)*0.003)
##
## That 0.003 sits OUTSIDE the recession switch — every value gets the same ladder, and the
## line above it (`:244`) says what it is for: "Offset each layer slightly in Z to prevent
## z-fighting". At the shipped depth 6 the whole recession of fractal_recursion_2 is 15 mm
## across a 1.06 m frame: 1.4%, an anti-z-fighting device. Its @identity (`:21`) calls them
## "concentric squares receding in Z". They recede fifteen millimetres.
##
## So across two members × four values, exactly ONE cell has a depth ordering:
## folding_past at `nested` — which is the export default (`:55`). The axis is named after
## its default, and the other three values are definable only by NOT having the property the
## word names. That is a third species alongside wave 20's and wave 21's all-rungs values:
## not a value that is the union of the axis, but an axis that is the name of one value.
##
## The brief's suspicion was that `abreast` is not a recession. It is not — and neither are
## `strata` or `collapsed`. The hole is three rungs wide, not one.
##
## ───────────────────────────────────────────────────────────────────────────────────────
## (2) THE SIGN IS OPPOSITE. In folding_past the inner, older, smaller frame is FURTHER
## (`:185`, z grows negative with frame_progress, and the scene camera looks from +z). In
## fractal_recursion_2 the innermost square is NEARER: `:245` gives z = (depth-d)*0.003,
## which increases with iteration index, and the scene's Camera3D sits at (0,1,2) looking
## toward −z (example_8_2_recursion_vr.tscn:10). One file's recession goes away from you and
## the other's comes toward you, under one word, with one value list.
##
## ───────────────────────────────────────────────────────────────────────────────────────
## (3) `abreast` AND `strata` MEAN OPPOSITE THINGS, AND THAT IS THE SECOND AXIS.
##
##   animated_folding_past.gd:196   "abreast":  scale = 1.0
##   animated_folding_past.gd:203   "strata":   scale = 1.0
##
## At half its values folding_past THROWS AWAY `scale_ratio` — the parameter its own
## @identity (`:6`) names one clause after `recession` as setting "how tightly … the nesting
## folds inward". fractal_recursion_2 refuses exactly that: `_drawn_size` (`:181-187`)
## overrides the size only for `collapsed`, so at `abreast` and `strata` the halving
## survives. Its registry states the difference and calls it "a fact about the artifact";
## what follows from it is that the vocabulary is not shared where it counts. Photograph
## both at `abreast` and you get ten equal rectangles beside six halving squares — the same
## word answering opposite questions about whether self-similarity survives rearrangement.
##
## This bench makes that choice a rung instead of an assumption. `inheritance` is the second
## axis: WHAT A LEVEL TAKES FROM THE ONE BEFORE IT.
##
## ───────────────────────────────────────────────────────────────────────────────────────
## (4) NEITHER MEMBER IS RECURSIVE. fractal_recursion_2's `_draw_recursive_pattern`
## (`:226-237`) makes exactly ONE recursive call (`:236`) — branching factor 1, a tail call,
## a loop in recursion's clothes; its own registry found this and it is confirmed here by
## counting. folding_past has no recursion at all: `for i in range(frame_count)`
## (`animated_folding_past.gd:171`). What the two share is a GEOMETRIC SEQUENCE of similar
## rectangles laid out by a rule, and that is what this bench builds.
##
## ═══════════════════════════════════════════════════════════════════════════════════════
## WHAT THIS BENCH IS.
##
## A hall: a back wall, a floor and soffit, two side returns and a proscenium — the frame
## example_8_2 draws with four bars (`_create_frame`, `:190-213`) given a fixed size the
## family never gave it. Inside it stand four LEVELS, each a rectangular ring: folding_past's
## wireframe outline (`:113-138`, four edges) and example_8_2's four-bar frame are the same
## figure, so the ring is the honest merge of the two bodies.
##
## THE HALL NEVER MOVES. Both sources' registries warn that their extent changes with the
## value and that the sweep frames the union, so the small values shrink in frame and the
## measured pairs carry a framing difference they did not earn. Here the world box is a
## constant in all twelve cells: the levels always fit inside the opening, and the camera is
## placed once on a box that does not depend on either axis.
##
##   `recession`   WHERE EACH LEVEL SITS — which direction the run of the rule is laid along.
##       nested      concentric, each level standing back along −Z by exactly what it lost:
##                   z = −(s0 − sk). Containment, and the only value with any depth.
##       collapsed   every level drawn at the innermost size, at the origin. Both sources
##                   collapse to the innermost term (animated_folding_past.gd:193;
##                   example_8_2_recursion_vr.gd:181-187). The nest at its own limit.
##       abreast     the run laid along +X, terms tiled edge to edge, centres aligned.
##                   Succession without containment.
##       strata      the same run laid along +Y. Deposition.
##
##   `inheritance` WHAT A LEVEL TAKES FROM THE ONE BEFORE IT — the size ratio.
##       halved      0.5, example_8_2_recursion_vr.gd:78 (`size_reduction`)
##       eased       0.85, animated_folding_past.gd:22 (`scale_ratio`)
##       equal       1.0 — the ratio folding_past silently imposes at `abreast` and `strata`
##                   by setting scale = 1.0, here named and made visible at all four
##                   arrangements instead of at two.
##
## THE TWO SOURCES SHIP DIFFERENT DEFAULTS ON THE SECOND AXIS, so this family has no shared
## default cell. The default here is `nested` + `halved`, which is example_8_2's picture;
## folding_past's is `nested` + `eased`. Both are in the sheet, one cell apart, and the
## disagreement is the argument.
##
## ═══════════════════════════════════════════════════════════════════════════════════════
## THE INSTRUMENT, AND WHAT IT COSTS.
##
## THE HALL IS YAWED BY 0.62 rad. capture_config_sweep.gd:69-70 puts the camera at
## YAW 0.62 / PITCH −0.26 and :443 builds its direction as
## Vector3(sin(yaw)cos(pitch), −sin(pitch), cos(yaw)cos(pitch)), whose horizontal bearing is
## atan2(sin 0.62, cos 0.62) = 0.62 exactly. Turning the hall to meet it makes the three run
## directions project to exactly:
##
##       local +X  (abreast)   screen (+1.000000, +0.000000)   length 1.000000
##       local +Y  (strata)    screen (+0.000000, +0.966390)   length 0.966390
##       local −Z  (nested)    screen (+0.000000, +0.257081)   length 0.257081
##
## THIS IS THE FINDING, IN THE HARNESS'S OWN CONSTANTS: at the standpoint every DNA tile in
## this programme has ever been shot from, the direction the axis is NAMED after is
## compressed to 25.7% — 3.89x less visible than `abreast` and 3.76x less than `strata`. An
## axis called `recession`, photographed by an instrument that can barely see recession. At
## the shipped default the whole depth run contributes an 8.5 px upward drift of the
## innermost ring and a 7.6% perspective shrink in a 760 px frame; the ARRANGEMENT carries
## the value and the recession contributes about one percent of the picture. That is how
## three of four values could sit on this axis unimplemented and nothing complained.
##
## The counterfactual was built and rejected: leaving the hall unyawed raises the depth
## projection to 0.617564, but then `nested` photographs as a sheared row rather than a nest
## and `abreast` loses 17% to foreshortening. Facing the camera photographs the family's
## argument; the cost is written down above rather than hidden.
##
## BAR THICKNESS IS 0.07 OF THE LEVEL'S OWN SIZE, AND 0.07 IS DERIVED. 1 − 2(0.07) = 0.86,
## which is the first hundredth above folding_past's own 0.85 — so `eased` is the tightest
## nest in which every level's bar still clears its parent's aperture. A thicker bar would
## have hidden a level and made a value a fact about a line width. Below BAR_MIN the bar
## stops scaling and the levels stop being similar; that floor is 0.006 m = 2.6 px in the
## sweep's frame, and a bar under about 2.5 px antialiases away. A level that does not render
## is not evidence, so the floor is stated rather than discovered in the tiles.
##
## FOUR LEVELS, NOT SIX. Six is example_8_2's shipped depth, but 0.5^5 puts the innermost
## term at 0.6 px here and its bar under a fifth of a pixel — the same fault its own registry
## warns about at depth 7 ("a handful of pixels at dead centre"). 4 is a declared rung of
## that artifact's own `depth` axis and it is the largest count at which every term of every
## ratio still photographs.
##
## THE LEVELS ARE UNSHADED AND SO IS THE BACK WALL, so every pixel that moves between two
## cells goes from one exactly-computable byte to another and the predicted degeneracy could
## be computed rather than estimated. The hall's frame, returns and floor stay lit, so the
## object keeps a body. example_8_2's palette carries per-colour alpha (`:85-90`, 0.9 down to
## 0.65) under TRANSPARENCY_ALPHA (`:262`); the RGB is taken verbatim and the alpha is forced
## to 1.0, because the designed null puts four rings in the same place and an alpha composite
## there is a fact about transparency sort order rather than about the axis.
##
## RING DEPTH 0.002 IS UNDER THE 0.003 Z STEP, on purpose. example_8_2 draws 5 mm boxes on a
## 3 mm step (`:242`, `:245`) so its squares interpenetrate; filled squares hide the fault.
## Rings do not, so the step has to clear the thickness or the collapsed cell z-fights.
##
## Deterministic: no randf, no randi, no noise, no _process, no Timer, no tween. Every vertex
## and colour is arithmetic on constants, so a variant is a fact and not a sample. No
## dna.fixture is needed — _ready builds the whole object standalone.


## WHERE EACH LEVEL SITS. The family's word and the family's four values, in the family's
## order, declared identically by both members.
@export_enum("nested", "collapsed", "abreast", "strata") var recession: String = "nested":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not RECESSIONS.has(picked):
			return                            ## an unreachable value keeps the standing hall
		recession = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## WHAT A LEVEL TAKES FROM THE ONE BEFORE IT. Declared by no other artifact in the corpus —
## checked across all 108 registry files, 489 distinct axis names.
@export_enum("halved", "eased", "equal") var inheritance: String = "halved":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not INHERITANCES.has(picked):
			return
		inheritance = picked
		if is_inside_tree() and not _bulk:
			_rebuild()


const RECESSIONS: PackedStringArray = ["nested", "collapsed", "abreast", "strata"]
const INHERITANCES: PackedStringArray = ["halved", "eased", "equal"]

## The ratios are the sources' own numbers, not a ladder someone liked:
## example_8_2_recursion_vr.gd:78 ships size_reduction 0.5; animated_folding_past.gd:22
## ships scale_ratio 0.85; 1.0 is what animated_folding_past.gd:196 and :203 assign when
## they set scale = 1.0 and stop being about a ratio at all.
const RATIO: Dictionary = {
	"halved": 0.5,
	"eased": 0.85,
	"equal": 1.0,
}

## example_8_2_recursion_vr.gd:85-90, RGB verbatim, alpha dropped to 1.0. The palette has
## six entries and this hall shows four; at six terms the two smallest are sub-pixel here,
## and at seven that file's own index wraps and the innermost square comes back red.
const LEVEL_COLOR: Array[Color] = [
	Color(0.90, 0.20, 0.30, 1.0),
	Color(0.95, 0.50, 0.10, 1.0),
	Color(0.95, 0.85, 0.20, 1.0),
	Color(0.30, 0.85, 0.40, 1.0),
]

const N_LEVEL: int = 4
## The run of a sequence that never diminishes: N_LEVEL * LEVEL_SIZE. The hall is exactly
## the size of the thing that does not recede, which is why `equal` fills it edge to edge.
## Written out rather than divided, so the constant folder never has to evaluate a type
## conversion; _check_hints asserts the relation at load instead.
const SPAN: float = 1.20
const LEVEL_SIZE: float = 0.30                           ## SPAN / N_LEVEL

const BAR_FRAC: float = 0.07                             ## 1 - 2*0.07 = 0.86 > 0.85
const BAR_MIN: float = 0.006                             ## 2.6 px in the sweep's frame
const RING_T: float = 0.002                              ## < Z_STEP, so nothing z-fights
const Z_STEP: float = 0.003                              ## example_8_2_recursion_vr.gd:245

const MARGIN: float = 0.08                               ## clear air, widest run to reveal
const OPENING: float = SPAN + 2.0 * MARGIN               ## 1.36
const FRAME_BAR: float = 0.05
const OUTER: float = OPENING + 2.0 * FRAME_BAR           ## 1.46
const CENTRE_Y: float = OUTER * 0.5                      ## 0.73, and the hall stands on y=0
const WALL_T: float = 0.05
const WALL_FRONT: float = -0.36
const PROS_Z: float = 0.05
const RETURN_T: float = 0.04

## capture_config_sweep.gd:69. The hall turns to meet it; see the header for what that buys
## and what it costs.
const CAMERA_YAW: float = 0.62

const WALL_COLOR: Color = Color(0.20, 0.21, 0.24, 1.0)
const HALL_COLOR: Color = Color(0.28, 0.27, 0.30, 1.0)

var _bulk: bool = false
var _hall: Node3D = null


func _ready() -> void:
	_check_hints()
	_rebuild()


## The sizes the rule lays down, outermost first. Asked ahead of the walk so a layout can
## know its run before it starts placing terms — example_8_2_recursion_vr.gd:121-129 does
## the same and for the same reason.
func _sizes() -> Array[float]:
	var out: Array[float] = []
	var r: float = float(RATIO.get(inheritance, 0.5))
	var s: float = LEVEL_SIZE
	for k in range(N_LEVEL):
		out.append(s)
		s = s * r
	return out


## The bar of a level is a fixed fraction of that level's own side, so the levels are similar
## objects rather than a shape with a border. BAR_MIN is where the camera stops being able to
## see the similarity; see the header.
func _bar(side: float) -> float:
	return maxf(BAR_MIN, BAR_FRAC * side)


## WHERE LEVEL k SITS, relative to the middle of the opening, and WHAT SIZE IT IS DRAWN AT.
##
## `nested` and `collapsed` are centred in x and y, which is the centre every term of both
## sources has ever been drawn at. `nested` steps back along −Z by exactly what the level
## lost — z = −(s0 − sk) — because in a nest the visible gap between two frames IS the margin
## the parent leaves around the child, and this makes that gap distance. It has the property
## the word needs: when the ratio is 1 nothing is lost, so nothing recedes.
##
## `abreast` walks the terms along +X and `strata` along +Y, tiled edge to edge: the run is
## the sum of the sizes the rule itself produced, so no spacing constant is invented
## (example_8_2_recursion_vr.gd:160-175). Centres are aligned in the cross direction rather
## than bottom edges (which is what `:174` does), so that the two values are one run laid
## along two axes and nothing else — which is what makes their pair a measurement of
## direction instead of a measurement of alignment.
func _seat(k: int, sizes: Array[float]) -> Vector4:
	var eps: float = float(k) * Z_STEP
	if recession == "collapsed":
		return Vector4(0.0, 0.0, eps, sizes[N_LEVEL - 1])
	if recession == "nested":
		return Vector4(0.0, 0.0, -(sizes[0] - sizes[k]) + eps, sizes[k])
	var run: float = 0.0
	for s in sizes:
		run += s
	var walked: float = 0.0
	for i in range(k):
		walked += sizes[i]
	var along: float = walked + sizes[k] * 0.5 - run * 0.5
	if recession == "abreast":
		return Vector4(along, 0.0, eps, sizes[k])
	return Vector4(0.0, along, eps, sizes[k])


func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_hall = Node3D.new()
	_hall.name = "Hall"
	_hall.rotation.y = CAMERA_YAW
	add_child(_hall)
	_build_hall()
	_build_levels()


## Constant in all twelve cells. Nothing below reads either axis.
func _build_hall() -> void:
	var half_open: float = OPENING * 0.5
	var depth: float = PROS_Z - WALL_FRONT
	var mid_z: float = (PROS_Z + WALL_FRONT) * 0.5

	## The one unshaded surface of the hall: every pixel a level does not cover is this
	## exact byte, which is what makes the predicted degeneracy arithmetic.
	_box("BackWall", Vector3(OUTER, OUTER, WALL_T),
		Vector3(0.0, CENTRE_Y, WALL_FRONT - WALL_T * 0.5), WALL_COLOR, true)

	_box("ReturnL", Vector3(RETURN_T, OPENING, depth),
		Vector3(-(half_open - RETURN_T * 0.5), CENTRE_Y, mid_z), HALL_COLOR, false)
	_box("ReturnR", Vector3(RETURN_T, OPENING, depth),
		Vector3(half_open - RETURN_T * 0.5, CENTRE_Y, mid_z), HALL_COLOR, false)
	_box("Floor", Vector3(OPENING, RETURN_T, depth),
		Vector3(0.0, CENTRE_Y - half_open + RETURN_T * 0.5, mid_z), HALL_COLOR, false)
	_box("Soffit", Vector3(OPENING, RETURN_T, depth),
		Vector3(0.0, CENTRE_Y + half_open - RETURN_T * 0.5, mid_z), HALL_COLOR, false)

	var off: float = half_open + FRAME_BAR * 0.5
	_box("ProsTop", Vector3(OUTER, FRAME_BAR, FRAME_BAR),
		Vector3(0.0, CENTRE_Y + off, PROS_Z), HALL_COLOR, false)
	_box("ProsBottom", Vector3(OUTER, FRAME_BAR, FRAME_BAR),
		Vector3(0.0, CENTRE_Y - off, PROS_Z), HALL_COLOR, false)
	_box("ProsLeft", Vector3(FRAME_BAR, OPENING, FRAME_BAR),
		Vector3(-off, CENTRE_Y, PROS_Z), HALL_COLOR, false)
	_box("ProsRight", Vector3(FRAME_BAR, OPENING, FRAME_BAR),
		Vector3(off, CENTRE_Y, PROS_Z), HALL_COLOR, false)


func _build_levels() -> void:
	var sizes: Array[float] = _sizes()
	for k in range(N_LEVEL):
		var seat: Vector4 = _seat(k, sizes)
		_ring(k, Vector3(seat.x, CENTRE_Y + seat.y, seat.z), seat.w, LEVEL_COLOR[k])


## One level: four bars, which is example_8_2's frame (`_create_frame`, :190-213) and
## folding_past's wireframe rectangle (:113-138) drawn as the same object.
func _ring(k: int, centre: Vector3, side: float, col: Color) -> void:
	var t: float = _bar(side)
	var arm: float = (side - t) * 0.5
	var inner: float = maxf(0.0, side - 2.0 * t)
	var tag: String = "Level%d" % k
	_box(tag + "T", Vector3(side, t, RING_T), centre + Vector3(0.0, arm, 0.0), col, true)
	_box(tag + "B", Vector3(side, t, RING_T), centre + Vector3(0.0, -arm, 0.0), col, true)
	_box(tag + "L", Vector3(t, inner, RING_T), centre + Vector3(-arm, 0.0, 0.0), col, true)
	_box(tag + "R", Vector3(t, inner, RING_T), centre + Vector3(arm, 0.0, 0.0), col, true)


func _box(nm: String, size: Vector3, pos: Vector3, col: Color, flat: bool) -> void:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = nm
	var m: BoxMesh = BoxMesh.new()
	m.size = size
	mi.mesh = m
	mi.position = pos
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = col
	if flat:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	else:
		mat.metallic = 0.0
		mat.roughness = 0.8
	mi.material_override = mat
	_hall.add_child(mi)


## Config from a map token:  recession_hall#recession:abreast#inheritance:equal
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return
	_bulk = true
	if config_data.has("recession"):
		recession = str(config_data["recession"])
	if config_data.has("inheritance"):
		inheritance = str(config_data["inheritance"])
	_bulk = false
	if is_inside_tree():
		_rebuild()


## The declaration gate reads the @export_enum hint; the builder reads the const. If the two
## ever drift, every tile in a sweep becomes a fact about which of them a given tool trusted
## — which is science_screen's whole failure, and it cost that pass sixteen identical frames
## and a confident INERT verdict about a typo.
func _check_hints() -> void:
	var pairs: Array = [["recession", RECESSIONS], ["inheritance", INHERITANCES]]
	for entry in pairs:
		var key: String = str(entry[0])
		var want: PackedStringArray = entry[1]
		for prop in get_property_list():
			if String(prop.get("name", "")) != key:
				continue
			var got: PackedStringArray = String(prop.get("hint_string", "")).split(",")
			if got != want:
				push_warning("recession_hall: %s hint %s != const %s" % [key, got, want])
	for value in INHERITANCES:
		if not RATIO.has(value):
			push_warning("recession_hall: inheritance %s has no ratio" % value)
	## The hall is sized to the run of the ratio that does not diminish. If this ever drifts,
	## `abreast` at `equal` stops filling the opening and every framing number in the registry
	## is a fact about a stale constant.
	if not is_equal_approx(LEVEL_SIZE * float(N_LEVEL), SPAN):
		push_warning("recession_hall: LEVEL_SIZE * N_LEVEL != SPAN")
