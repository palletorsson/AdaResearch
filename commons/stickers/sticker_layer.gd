extends Node3D
## THE STICKERS OF ONE HOST, drawn under that host's node. The layer's own transform IS the host frame (stickers.ts:
## a board's face centre, x right, y up, z out; a bench primitive's centre; a Void work's exported GLB frame; a Void
## floor's Floor<i> frame), so every sticker is placed exactly as its record says: at, n, up and size in that frame.
##
## A sticker is a PROJECTOR, as three.js's decal is (sticker-decal.ts): a box extent(design, size) = [w, h] along right
## and up (right = up x n) and DEPTH_RATIO times the long side along n, centred on `at`. It prints the picture, by an
## orthographic projection along -n, on the host's surface inside that box that faces n by at least MIN_FACING. Where
## the layer knows the host's BODY it prints exactly that (body(): the host's `surface` - the bench's sphere {shape:
## sphere, r} and cylinder {shape: cylinder, r, h} - or, for a board or a bench primitive, the box of the body's own
## collider: the board's Face, the bench's box and slab):
##   CURVED, the sphere and the cylinder's side ("Curved_<design>", one ArrayMesh per design): a GRID over the layout,
##   each of its points carried along -n onto the body. Cells past the projector's depth, or facing n by less than
##   MIN_FACING, are cut away at that boundary (found on each cell's edges); the cylinder's side ends at its rims. Every
##   vertex is lifted out along the body's normal there, which also lights it. Seen along n, each point of the picture
##   is where three.js prints it, and neither prints what lies past the depth (the corners of a 0.4 m sticker on the
##   0.3 m sphere). Laid along the body's normals instead (until 2026-11-13), the same picture point landed up to 1.1 cm
##   from three.js's at 0.18 m and 5.4 cm at 0.4 m, and the corners were drawn where three.js prints none.
##   PLANAR, a box's six faces and a cylinder's two caps (a 96-gon, as three.js's bench cuts it): the face clipped by the
##   projector's box (DecalGeometry's six planes), so a sticker ends at the edge of its face, where three.js's decal ends
##   (a flat quad by the edge of the bench box's top or the cylinder's cap stood out in the air past the body, 11.8 and
##   10.5 cm in the re-check of 2026-11-13). A sticker that lies whole inside one face is the quad below; one cut at an
##   edge is a mesh ("Clipped_<design>").
## Anywhere else (a Void work or floor, whose bodies the layer does not know), and for a sticker its body takes no ink
## from (drawn where its record says, as three.js draws an unseated one), a sticker is FLAT: one MultiMeshInstance3D per
## design ("Stickers_<design>"), the shared 1 x 1 quad scaled per instance to extent(design, size) - the DRAWN box, the
## die-cut border included - its basis columns right * w, up * h, n, its origin at + n * its lift.
##
## THE STACK: a sticker stuck later (higher z) lies over every earlier one it overlaps. Its lift is LIFT, or a step over
## the highest of the earlier live stickers whose drawn footprint overlaps its own (footprint(): the box its print fills
## in its own right / up / n, tested against the others' by separating axes), at most STACK_HEIGHT over LIFT; a step is
## STACK (0.1 mm) between flat prints and CURVED_STACK (0.5 mm, more than any grid's sag) where either is a grid. So
## stickers that do not overlap all lie at LIFT, and the cap is met only by a pile of 60 overlapping flat stickers or 12
## curved ones. (Counted by its index on the host, as until 2026-11-13, the 61st sticker of a board and the 13th of the
## sphere met the cap whatever overlapped what, and two overlapping stickers there were drawn at one lift: on the sphere
## they pierced each other, on the board the earlier one could cover the later. three.js orders them by rank.)
##
## Peeled stickers are drawn as RESIDUE ("Residue_<design>", "CurvedResidue_<design>", "ClippedResidue_<design>"): the
## silhouette in one flat colour (StickerData.RESIDUE_COLOR) at RESIDUE_ALPHA, 1.2 mm off the surface, under the
## stickers that are on - a peel is an event that leaves residue, never a deletion. Materials and pictures come from
## StickerData (one per design).
##
## A board sticker is drawn on the board's FACE whatever an older record says (drawn_as: stickers.ts settle) - or, on a
## board with DEPTH, where settle() puts it: anywhere from the paper to `depth` in front of it, facing out. One in front
## of the paper HANGS: it is drawn flat, its quad at its own at.z (never printed onto the paper behind it, which its
## projector would reach when it hangs within half its depth of it), at least LIFT from the paper, and it has a BACK
## ("Backs_<design>": its silhouette in a card's colour, facing -n), so a visitor walking round the layers sees a card
## from behind, not nothing. Its cord and its threads are the board's (sticker_board/sticker_threads.gd).
##
## A TWO-SIDED board (stock cardboard: a wall of a construction, sticker_construction) has a back as well as a front:
## a record whose normal points back is drawn on the back face (drawn_as: settle with the board's sidedness, n = -Z,
## at.z = -CARDBOARD), its lift along -Z, out of the cardboard; the body is the wall's box collider, so a back sticker
## is printed on the back face exactly as a front one is on the front (cut at its edge when it reaches past it). Front
## and back stickers never stack on each other: their footprints lie CARDBOARD apart along z.
##
## SCRIBBLES (stickers.ts Stroke, PENS, drawnStrokes, strokeZ): the pen strokes on a board's faces, drawn here too, so
## every board host shows its scribbles - a paper board its front's, a cardboard wall both faces' (a back stroke on a
## board that has no back is not drawn, as the web's updateStrokes skips it). Each face's strokes are ONE mesh
## ("Strokes_front", "Strokes_back"), in the record's order, a later line over an earlier one: each stroke a flat RIBBON
## at stroke_z(face) in the board frame, its width, and the rest from its pen as the contract gives it (StickerData.PENS):
## its cap (round: a half disc at each end; square: half the width on past each end), its join (miter: a corner mitred up
## to StickerData.MITER_LIMIT times the half width and bevelled past it; round: a round corner, a gentle one mitred up to
## ROUND_MITER so the line stays one strip), its opacity, and its soft edge (`soft` > 0: the line blurred by a Gaussian
## whose deviation is soft times its width - the spray's 0.2 - as the alpha across a ribbon soft_reach(soft) widths each
## side). It is the web's ribbon (cardboard3d.ts strokeRibbon), so one strip covers each part of a line once and a
## translucent pen keeps one opacity along it. Wound to face out of its face only: a front stroke is not seen from behind
## the cardboard. A stroke's ribbon is made once and kept while its pen, width, colour, face and points stay; a face's
## mesh is made again exactly when the list of its ribbons changed.
## INK LIES ON THE CARDBOARD (stickers.ts drawnStrokes): a sticker on a face is drawn over every scribble on that face,
## whichever came first, as the web paints a face (paper, scribbles, residue, stickers). A sticker's material (alpha
## scissor with alpha to coverage) is drawn in the see-through pass, its solid part written to depth first in the depth
## prepass; the ink is kept under it twice over. By ORDER: the scribbles' material sorts before every other see-through
## surface (STROKE_PRIORITY), so the stickers and the residue of their face are drawn after it. By DEPTH: the ribbon lies
## STROKE_LIFT (0.6 mm) off its face and its shader pulls it STROKE_PULL (0.4 mm) toward the eye, so from any side it
## stays behind a sticker (LIFT, 2 mm) and the residue (RESIDUE_LIFT, 1.2 mm) and in front of its face. Either alone kept
## the ink under in the probe's views (CI, square on and 55 degrees off); round 1 had neither - a 3 mm pull and the
## stickers' own order, which sorts by distance - and its lines lay over the stickers seen 55 degrees off.
##
## The host sets `host` (and `surface`) before adding the layer; the layer redraws itself whenever the placements or
## designs change. It has no _process of its own: a floor's residency pauses and hides it with its floor at no cost.
## STAGED (a cardboard construction's walls, sticker_construction.gd sets `staged` before the layer enters the tree): the
## layer then draws nothing at once. What a redraw has to do - each design's picture, the stickers, each scribble's
## ribbon not yet made, the faces' meshes - is done one piece at a time in _process, within a budget of each frame
## SHARED by every staged layer and thread drawer (stage_may, stage_spent: FRAME_BUDGET_MS), and _process is off again
## when it is drawn; a change meanwhile plans the pass again (what was made is kept). busy() says whether it is still
## drawing. So a wall of 100 scribbles costs no frame more than a few milliseconds (the research construction's first
## build held the main thread 210 to 293 ms in one frame, 2026-11-15).

const StickerData := preload("res://commons/stickers/sticker_data.gd")
const LIFT := 0.002          # off the surface (stickers.ts / the contract)
const STACK := 0.0001        # a step in the stack between flat prints (0.1 mm)
const STACK_MOST := 60       # flat steps in STACK_HEIGHT
## On a curve two stickers are two different grids, each sagging between its points by up to 0.37 mm, so 0.1 mm of
## stack (the flat step) let an earlier sticker show through a later one where they overlap (seen on the sphere in the
## probe's curved.png): a curved step is 0.5 mm, more than any sag, at most 12 of them (6 mm).
const CURVED_STACK := 0.0005
const CURVED_STACK_MOST := 12
const STACK_HEIGHT := 0.006  # the most a pile climbs over LIFT: STACK * STACK_MOST = CURVED_STACK * CURVED_STACK_MOST
const RESIDUE_LIFT := 0.0012 # under the stickers on it
const STEP := 0.07           # a curved grid's cell spans at most about this angle (rad): its chords sag under 0.4 mm
const CELLS_LEAST := 8
const CELLS_MOST := 32
# --- sticker-decal.ts ---
const MIN_FACING := 0.2      # MIN_FACING: cos 78.5 degrees; past that a projection smears more than it prints
const DEPTH_RATIO := 0.5     # DEPTH_RATIO: the projector's depth along n, as a share of the sticker's long side
const MIN_DEPTH := 0.002     # MIN_DEPTH
const CAP_SIDES := 96        # a cylinder's cap, cut as three.js cuts the bench's (CylinderGeometry, 96 segments)
# --- the stack ---
const FOOT_SLACK := 0.001    # a footprint's box reaches this far each way along its n (more than a grid's sag)
const TOUCH := 0.00001       # footprints that only touch (overlapping by less than 0.01 mm) are not a pile
# --- the scribbles: the pens are the contract's (StickerData.PENS: cap, join, opacity, soft; StickerData.MITER_LIMIT) ---
## a round join's gentle corner (up to a 32 degree turn) is mitred too, so its line stays one strip (a choice of the
## views, cardboard3d.ts ROUND_MITER: the mitre's tip stands at most 4 % of the half width past the round join's arc)
const ROUND_MITER := 1.04
const ROUND_STEP := PI / 12.0  # a round cap or join in steps of at most 15 degrees
## How far a scribble is pulled toward the eye (metres, along the eye's ray). Ink lies on the cardboard: the ribbon lies
## STROKE_LIFT (0.6 mm) off its face, under the residue (RESIDUE_LIFT, 1.2 mm) and every sticker (LIFT, 2 mm and up).
## Pulled 0.4 mm along the eye's ray it stands at most 1.0 mm off its face from any side (a pull along the ray rises off
## the face by at most its own length), so by depth it never comes up to the residue or a sticker, and it stays 0.6 mm
## or more clear of the face it lies on.
const STROKE_PULL := 0.0004
## The scribbles sort before every other see-through surface (Material.render_priority: lower is drawn first) - the
## stickers (alpha to coverage puts them in the see-through pass) and the residue (priority 0) - so on one face those are
## drawn after the ink, over it. The line being drawn and the eraser's mark sort over the face's lines (sorting_offset,
## sticker_pen.gd), still before the stickers.
const STROKE_PRIORITY := -1
## The scribbles' one material: the ribbon's colour (linear) and its pen's opacity per vertex; UV.x runs across the
## ribbon (-1 one edge, 0 the centre line, +1 the other; a round cap's rim is 1) and UV.y is the pen's `soft` (0: a hard
## edge), whose alpha across a ribbon soft_reach(soft) widths each side is the line one width wide blurred by a Gaussian
## of soft widths (erf: Abramowitz and Stegun 7.1.26, within 1.5e-7; cardboard3d.ts softAlpha). Depth is not written (one
## face's strokes lie in one plane: the record's order decides), back faces are culled (a front stroke is not seen
## through the cardboard), and the ribbon is lit as the face under it is.
const STROKE_SHADER := """shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, skip_vertex_transform;
uniform float pull = 0.0004;
float erf_as(float x) {
	float s = sign(x);
	float a = abs(x);
	float t = 1.0 / (1.0 + 0.3275911 * a);
	float y = 1.0 - (((((1.061405429 * t - 1.453152027) * t + 1.421413741) * t - 0.284496736) * t + 0.254829592) * t) * exp(-a * a);
	return s * y;
}
void vertex() {
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	NORMAL = normalize(MODELVIEW_NORMAL_MATRIX * NORMAL);
	VERTEX -= normalize(VERTEX) * pull;
}
void fragment() {
	float ink = 1.0;
	float soft = UV.y;
	if (soft > 0.0) {
		float x = abs(UV.x) * (0.5 + 3.0 * soft);
		float k = soft * 1.41421356237;
		ink = 0.5 * (erf_as((x + 0.5) / k) - erf_as((x - 0.5) / k));
	}
	ALBEDO = COLOR.rgb;
	ALPHA = COLOR.a * ink;
	ROUGHNESS = 0.75;
}
"""
# --- staged drawing (STAGED) ---
## The share of each frame staged drawing may take (ms), SHARED by every staged layer and thread drawer: a piece of work
## starts while its frame has spent nothing yet, or still has room for the most a piece of its kind has cost; so a frame
## carries about this much, or one piece alone where a single piece costs more (a 2000-point line's ribbon, 9 ms).
const FRAME_BUDGET_MS := 3.0

static var _stroke_material: ShaderMaterial = null
static var _budget_frame := -1
static var _budget_spent := 0        # usec of staged work in this frame
static var _stage_costs: Dictionary = {}   # piece kind -> the most one such piece has cost (usec)
static var stage_frame_most := 0     # usec: the most staged work one frame has carried (probes; stage_reset())
static var stage_frames := 0         # frames that carried staged work (probes)
static var _stage_kinds: Dictionary = {}   # piece kind -> [pieces, usec in all, the most one cost] since stage_reset()
static var _pictured: Dictionary = {}      # designs whose picture a staged piece has had made (forgotten when the designs change)
static var stage_slow: Array = []          # staged pieces of a layer that took over 5 ms: [kind, host, design, ms] (probes)
static var _stage_frame_log: Array = []    # each frame's staged work (usec) since stage_reset(), the frame being drawn not yet in it
static var _budget_other := 0              # usec of this frame's staged work but the designs' pictures (StickerData.texture)
static var stage_frame_most_other := 0     # the most of that one frame carried (probes)
static var stage_marks: Array = []         # [process frame, usec, kind] of each staged piece since stage_reset() (probes; the first 4000)

var host: Dictionary = {}
var surface: Dictionary = {} # {shape: "sphere", r} or {shape: "cylinder", r, h}: the host's analytic body; {} = body()
var data: Node = null
var drawn := 0               # stickers drawn (state on)
var residue := 0             # peeled stickers drawn as residue
var backs := 0               # hanging stickers' backs drawn
var lifts: Dictionary = {}   # id -> the lift each live sticker is drawn at (its place in the stack), for probes
var sided := false           # the host is a two-sided board (a cardboard wall): it has a back to draw on
var strokes_drawn := {"front": 0, "back": 0}   # scribbles drawn on each face
var stroke_builds := 0       # ribbons made (a probe reads how many a change made again)
var staged := false          # set before the layer enters the tree: it draws a piece at a time (STAGED)
var stage_usec := 0          # what this layer's staged pieces have cost in all (probes)
var stage_pieces := 0        # how many pieces they were
var _sig := ""
var _stroke_sigs := {"front": "", "back": ""}
var _kept: Dictionary = {}   # stroke id -> {rec, head, sig, ribbon, version}: each ribbon made once
var _next_version := 1
var _stage: Array = []       # the pieces of the pass still to do: [kind, arg]
var _restage := false        # something changed: the pass is planned again

func _ready() -> void:
	data = StickerData.get_or_create(get_tree())
	data.placements_changed.connect(redraw)
	data.designs_changed.connect(_designs_changed)
	set_process(false)
	redraw()

func host_key() -> String:
	return StickerData.host_key(host)

## How far in front of its paper this host's stickers may hang: a board's depth (boards.json, read as the server reads
## it); 0 for a flat board and for every other host.
func depth() -> float:
	if data == null or str(host.get("kind", "")) != "board" or not data.has_method("board_depth"):
		return 0.0
	return float(data.board_depth(str(host.get("id", ""))))

## Whether a record (as drawn: drawn_as) HANGS in front of a board's paper rather than lying on it.
static func hangs(s: Dictionary, h: Dictionary, board_depth: float) -> bool:
	return str(h.get("kind", "")) == "board" and board_depth > 0.0 and float(StickerData.a3(s.get("at"))[2]) > 0.0

func _designs_changed() -> void:
	_sig = ""
	_pictured.clear()
	redraw()

## The body this host's stickers print on (host frame): `surface` when the host set one; else, for a board or a bench
## primitive, the box of its body's own collider (the board's Face, the bench's box and slab); {} for a Void host.
func body() -> Dictionary:
	if not surface.is_empty():
		return surface
	if str(host.get("kind", "")) in ["board", "primitive"]:
		return box_of(get_parent())
	return {}

## Draw this host's stickers again, when they (or the designs, or the body) changed since the last time; and its
## scribbles, face by face, when they changed. A staged layer plans the pass and draws it piece by piece (STAGED).
func redraw() -> void:
	if data == null:
		return
	if staged:
		_restage = true
		set_process(true)
		return
	_sided_now()
	_draw_stickers()
	_draw_strokes()

func _sided_now() -> void:
	sided = str(host.get("kind", "")) == "board" and data.has_method("board_sided") and bool(data.board_sided(str(host.get("id", ""))))

## Whether a staged layer is still drawing what changed (always false for a layer that draws at once).
func busy() -> bool:
	return staged and (_restage or not _stage.is_empty())

## A staged layer's pass, a piece at a time within the frame's shared budget; off again when it is drawn.
func _process(_delta: float) -> void:
	if not staged or data == null:
		set_process(false)
		return
	while true:
		if _restage:
			_restage = false
			_stage = [["plan", null]]
		if _stage.is_empty():
			set_process(false)
			return
		var piece: Array = _stage[0]
		if not stage_may(str(piece[0])):
			return
		_stage.pop_front()
		var t0 := Time.get_ticks_usec()
		match str(piece[0]):
			"plan":
				_plan()
			"picture":
				data.material(str(piece[1]))
				_pictured[str(piece[1])] = true
			"stickers":
				_draw_stickers()
			"ribbon":
				_kept_of(piece[1])
			"material":
				stroke_material()
			"strokes":
				_draw_strokes()
		var spent := Time.get_ticks_usec() - t0
		stage_usec += spent
		stage_pieces += 1
		stage_spent(str(piece[0]), spent)
		if spent > 5000 and stage_slow.size() < 40:
			stage_slow.append([str(piece[0]), host_key(), str(piece[1]) if piece[1] is String else "", snappedf(float(spent) / 1000.0, 0.001)])

## What a staged pass does, in order: each design's picture this session has not made (a first rasterising is the
## dearest piece, 3 to 9 ms), the stickers when what they are drawn from changed, the ribbon of each scribble not yet
## made (one that reads the same as the one made is kept, at a hash's cost), the session's stroke material, and the faces'
## meshes when the list of their ribbons changed. A layer nothing of whose host changed is done with its plan (an op on
## one wall costs the seven others a fraction of a millisecond each, not a frame's turn for every piece).
func _plan() -> void:
	_sided_now()
	var seen := {}
	for s in data.stickers_on(host_key()):
		var d := str(s.get("design", ""))
		if d != "" and not seen.has(d) and not _pictured.has(d):
			seen[d] = true
			_stage.append(["picture", d])
	if _stickers_sig() != _sig:
		_stage.append(["stickers", null])
	var faces_changed := false
	var versions := {"front": [], "back": []}   # Arrays: a packed array held in a Dictionary is a value (an append lands on a copy)
	if str(host.get("kind", "")) == "board" and data.has_method("strokes_on"):
		for s in data.strokes_on(str(host.get("id", ""))):
			var face := str(s.get("face", "front"))
			if face != "front" and not (face == "back" and sided):
				continue
			var had: Dictionary = _kept.get(str(s.get("id", "")), {})
			if not had.is_empty() and not is_same(had.rec, s) and str(had.sig) == _stroke_sig(s):
				had.rec = s     # a truth read again: the same line
			if had.is_empty() or not is_same(had.rec, s):
				_stage.append(["ribbon", s])
				faces_changed = true
			else:
				(versions[face] as Array).append(str(had.version))
	for face in versions:
		var list: Array = versions[face]
		if ",".join(PackedStringArray(list)) != str(_stroke_sigs.get(face, "")) or (list.is_empty() != (get_node_or_null("Strokes_" + str(face)) == null)):
			faces_changed = true
	if faces_changed:
		if _stroke_material == null:
			_stage.append(["material", null])   # the session's first: its shader made in a piece of its own
		_stage.append(["strokes", null])

## Whether a staged piece of `kind` may start in this frame: the frame has spent nothing on staged work yet, or the
## most such a piece has cost still fits in FRAME_BUDGET_MS.
static func stage_may(kind: String) -> bool:
	_stage_roll()
	return _budget_spent == 0 or _budget_spent + int(_stage_costs.get(kind, 0)) <= int(FRAME_BUDGET_MS * 1000.0)

## A staged piece of `kind` that took `usec`: charged to this frame's budget, and kept as what such a piece costs.
static func stage_spent(kind: String, usec: int) -> void:
	_stage_roll()
	if _budget_spent == 0:
		stage_frames += 1
	_budget_spent += usec
	stage_frame_most = maxi(stage_frame_most, _budget_spent)
	if kind != "picture":
		_budget_other += usec
		stage_frame_most_other = maxi(stage_frame_most_other, _budget_other)
	_stage_costs[kind] = maxi(int(_stage_costs.get(kind, 0)), usec)
	var k: Array = _stage_kinds.get(kind, [0, 0, 0])
	_stage_kinds[kind] = [int(k[0]) + 1, int(k[1]) + usec, maxi(int(k[2]), usec)]
	if stage_marks.size() < 4000:
		stage_marks.append([_budget_frame, usec, kind])

## Since stage_reset() (probes): the most staged work one frame carried (ms), in how many frames, and each kind of
## piece: how many, their mean and the most one cost (ms).
static func stage_report() -> Dictionary:
	var kinds := {}
	for kind in _stage_kinds:
		var k: Array = _stage_kinds[kind]
		kinds[kind] = {"n": k[0], "mean_ms": snappedf(float(k[1]) / maxf(1.0, float(k[0])) / 1000.0, 0.001), "most_ms": snappedf(float(k[2]) / 1000.0, 0.001)}
	var log := _stage_frame_log.duplicate()
	if _budget_spent > 0:
		log.append(_budget_spent)
	log.sort()
	var at := func(share: float) -> float: return float(log[mini(log.size() - 1, int(log.size() * share))]) / 1000.0 if not log.is_empty() else 0.0
	return {"frame_most_ms": float(stage_frame_most) / 1000.0, "frames": stage_frames, "kinds": kinds, "slow": stage_slow.duplicate(),
		"frame_p50_ms": at.call(0.5), "frame_p95_ms": at.call(0.95), "frame_second_most_ms": float(log[-2]) / 1000.0 if log.size() >= 2 else 0.0,
		"frames_over_8ms": log.filter(func(v): return int(v) > 8000).size(), "frame_most_but_pictures_ms": float(stage_frame_most_other) / 1000.0}

static func stage_reset() -> void:
	stage_frame_most = 0
	stage_frame_most_other = 0
	stage_frames = 0
	_stage_kinds = {}
	stage_slow = []
	_stage_frame_log = []
	stage_marks = []
	_budget_spent = 0
	_budget_other = 0

static func _stage_roll() -> void:
	var f := Engine.get_process_frames()
	if f != _budget_frame:
		if _budget_spent > 0 and _stage_frame_log.size() < 20000:
			_stage_frame_log.append(_budget_spent)
		_budget_frame = f
		_budget_spent = 0
		_budget_other = 0

## What this host's stickers are drawn from, as one string: when it is the one drawn, nothing is drawn again.
func _stickers_sig() -> String:
	return "%d|%s|%s|%s|%s" % [int(data.revisions.get("designs", -1)), JSON.stringify(body()), depth(), sided, JSON.stringify(data.stickers_on(host_key()))]

func _draw_stickers() -> void:
	var surf := body()
	var list: Array = data.stickers_on(host_key())
	var deep := depth()
	var sig := _stickers_sig()
	if sig == _sig:
		return
	_sig = sig
	var on_board := str(host.get("kind", "")) == "board"
	var on: Array = []
	var off: Array = []
	for s0 in list:
		var s := drawn_as(s0, host, deep, sided)
		if str(s.get("state", "on")) == "on":
			on.append(s)
		else:
			off.append(s)
	on.sort_custom(_earlier)
	var groups: Dictionary = {}     # node name -> [design, peeled, [[sticker, lift, shape]]]
	var feet: Array = []            # [footprint, lift, a grid, height] of each live sticker so far, in the stack's order
	lifts = {}
	for s in on:
		var d: Dictionary = data.design(str(s.get("design", "")))
		if d.is_empty():
			continue   # a design this game does not have (yet): its stickers wait for it
		var hang := hangs(s, host, deep)
		# a hanging sticker is its quad at its own depth (no paper under it to print on); one on a body, the print
		var g := {"laid": false, "curved": false} if hang else shape_of(s, d, surf)
		var foot := footprint(s, d, g)
		var curved := bool(g.get("curved", false))
		# on a board every sticker faces +Z, so the stack compares HEIGHTS (at.z + lift): a later sticker lies a step
		# over every earlier one it overlaps, at whatever depth either hangs; elsewhere lifts over one surface. On a
		# wall's back every sticker faces -Z at one at.z: they stack among themselves (a back footprint lies CARDBOARD
		# from every front one, more than twice FOOT_SLACK, so a back and a front sticker never overlap)
		var height := float(StickerData.a3(s.get("at"))[2]) if on_board else 0.0
		var base := maxf(0.0, LIFT - height) if hang else LIFT
		var lift := base
		for f in feet:
			if boxes_overlap(foot, f[0]):
				lift = maxf(lift, float(f[1]) + float(f[3]) - height + (CURVED_STACK if curved or bool(f[2]) else STACK))
		lift = minf(lift, base + STACK_HEIGHT)
		feet.append([foot, lift, curved, height])
		lifts[str(s.get("id", ""))] = lift
		_group(groups, s, g, lift, false)
		if hang:
			_group(groups, s, g, lift, false, "Backs_")
	for s in off:
		var d: Dictionary = data.design(str(s.get("design", "")))
		if not d.is_empty():
			_group(groups, s, {"laid": false, "curved": false} if hangs(s, host, deep) else shape_of(s, d, surf), RESIDUE_LIFT, true)
	var keep: Dictionary = {}
	drawn = 0
	residue = 0
	backs = 0
	for node_name in groups:
		var grp: Array = groups[node_name]
		var key: String = grp[0]
		var peeled: bool = grp[1]
		var back := str(node_name).begins_with("Backs_")
		var mat: Material = data.back_material(key) if back else (data.residue_material(key) if peeled else data.material(key))
		var flat := back or str(node_name).begins_with("Stickers_") or str(node_name).begins_with("Residue_")
		var ok := _fill(node_name, mat, grp[2], key, back) if flat else _fill_laid(node_name, mat, grp[2])
		if ok:
			keep[node_name] = true
			if back:
				backs += (grp[2] as Array).size()
			elif peeled:
				residue += (grp[2] as Array).size()
			else:
				drawn += (grp[2] as Array).size()
	for c in get_children():
		if (c is MultiMeshInstance3D or c is MeshInstance3D) and not keep.has(str(c.name)):
			remove_child(c)
			c.queue_free()

## The order of the stack: by z, and by id where two share a z (so every redraw stacks them alike).
static func _earlier(a: Dictionary, b: Dictionary) -> bool:
	var za := int(a.get("z", 0))
	var zb := int(b.get("z", 0))
	return za < zb or (za == zb and str(a.get("id", "")) < str(b.get("id", "")))

func _group(groups: Dictionary, s: Dictionary, g: Dictionary, lift: float, peeled: bool, prefix := "") -> void:
	var key := str(s.get("design", ""))
	var node_name: String
	if prefix != "":
		node_name = prefix + key
	elif not bool(g.get("laid", false)):
		node_name = ("Residue_" if peeled else "Stickers_") + key
	elif bool(g.get("curved", false)):
		node_name = ("CurvedResidue_" if peeled else "Curved_") + key
	else:
		node_name = ("ClippedResidue_" if peeled else "Clipped_") + key
	if not groups.has(node_name):
		groups[node_name] = [key, peeled, []]
	(groups[node_name][2] as Array).append([s, lift, g])

func _fill(node_name: String, mat: Material, entries: Array, design_id: String, back := false) -> bool:
	var d: Dictionary = data.design(design_id)
	if d.is_empty() or mat == null:
		return false   # a design this game does not have (yet), or its picture not drawn: its stickers wait for it
	var mmi := get_node_or_null(node_name) as MultiMeshInstance3D
	if mmi == null:
		mmi = MultiMeshInstance3D.new()
		mmi.name = node_name
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = data.quad_mesh()
		mmi.multimesh = mm
		add_child(mmi)
	mmi.material_override = mat
	var batch := mmi.multimesh
	batch.instance_count = entries.size()
	for i in entries.size():
		var xf := pose(entries[i][0], d, float(entries[i][1]))
		if back:
			# the same quad turned to face -n (columns -right, up, -n: a turn, not a mirror), in the same plane
			xf = Transform3D(Basis(-xf.basis.x, xf.basis.y, -xf.basis.z), xf.origin)
		batch.set_instance_transform(i, xf)
	return true

## The laid stickers of one design (or their residue) as one ArrayMesh in the host frame. The node carries metas for
## probes: ids (in order), ranges ([first vertex, count] per sticker), centres (each sticker's drawn centre) and lifts.
func _fill_laid(node_name: String, mat: Material, entries: Array) -> bool:
	if mat == null:
		return false
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	var ids: Array = []
	var ranges: Array = []
	var centres := PackedVector3Array()
	var lift_list: Array = []
	for e in entries:
		var g: Dictionary = e[2]
		var lift := float(e[1])
		var gv: Array = g.verts
		var gn: Array = g.norms
		var base := verts.size()
		for i in gv.size():
			var m: Vector3 = gn[i]
			verts.append(Vector3(gv[i]) + m * lift)
			norms.append(m)
		for uv in g.uvs:
			uvs.append(uv)
		for k in g.idx:
			idx.append(base + int(k))
		ids.append(str((e[0] as Dictionary).get("id", "")))
		ranges.append([base, gv.size()])
		centres.append(Vector3(g.centre) + Vector3(g.centre_n) * lift)
		lift_list.append(lift)
	var mi := get_node_or_null(node_name) as MeshInstance3D
	if mi == null:
		mi = MeshInstance3D.new()
		mi.name = node_name
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
	var mesh := ArrayMesh.new()
	if not idx.is_empty():
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_NORMAL] = norms
		arrays[Mesh.ARRAY_TEX_UV] = uvs
		arrays[Mesh.ARRAY_INDEX] = idx
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mi.mesh = mesh
	mi.material_override = mat
	mi.set_meta("ids", ids)
	mi.set_meta("ranges", ranges)
	mi.set_meta("centres", centres)
	mi.set_meta("lifts", lift_list)
	return true

## The record as it is drawn: on a BOARD it faces out of the face whatever an older record says (stickers.ts settle:
## n = +Z, up laid on the face), ON the paper (at.z = 0) - or, on a board with depth `board_depth`, anywhere from the
## paper to that depth in front of it (at.z clamped to [0, depth]); the server settles every op since, so the truth
## holds no other. three.js does not do the first: its board host is the face plane only, so an older record on the
## back gets no decal there and its 3D view lists it as unseated, a translucent quad at its own pose. On a TWO-SIDED
## board (`sided`: a cardboard wall) a record whose normal points back is on the back face (n = -Z, at.z = -CARDBOARD).
## Elsewhere the record itself.
static func drawn_as(s: Dictionary, h: Dictionary, board_depth := 0.0, two_sided := false) -> Dictionary:
	if str(h.get("kind", "")) != "board":
		return s
	var c := s.duplicate()
	StickerData.settle(c, null, board_depth, two_sided)
	return c

## A flat sticker's quad in its host frame: basis columns right * w, up * h, n; origin at + n * lift.
static func pose(s: Dictionary, d: Dictionary, lift: float) -> Transform3D:
	var b := StickerData.basis(StickerData.v3(s.get("n")), StickerData.v3(s.get("up")))
	var e := StickerData.extent(d, float(s.get("size", 0.2)))
	return Transform3D(Basis(b.right * e.x, b.up * e.y, b.n), StickerData.v3(s.get("at")) + b.n * lift)

# ==== the body ====

## The analytic body a node's stickers print on (host frame), for the pad: its meta sticker_surface (the bench's sphere
## and cylinder), else for a board or a bench primitive the box of its own collider; {} when it is not known.
static func surface_of(node: Variant, h: Dictionary) -> Dictionary:
	if not node is Node:
		return {}
	var meta: Variant = (node as Node).get_meta("sticker_surface", {})
	if meta is Dictionary and not (meta as Dictionary).is_empty():
		return meta
	if str(h.get("kind", "")) in ["board", "primitive"]:
		return box_of(node)
	return {}

## The box of a body's one collider: {shape: "box", size: [x, y, z], at: [x, y, z]} in the body's frame, or {} when the
## body has not exactly one enabled CollisionShape3D, an unturned BoxShape3D.
static func box_of(node: Node) -> Dictionary:
	if node == null:
		return {}
	var found: Dictionary = {}
	for c in node.get_children():
		var cs := c as CollisionShape3D
		if cs == null or cs.disabled or cs.shape == null:
			continue
		if not cs.shape is BoxShape3D or not cs.transform.basis.is_equal_approx(Basis.IDENTITY) or not found.is_empty():
			return {}
		var sz: Vector3 = (cs.shape as BoxShape3D).size
		found = {"shape": "box", "size": [sz.x, sz.y, sz.z], "at": [cs.position.x, cs.position.y, cs.position.z]}
	return found

## Whether a sticker on a host with this surface is laid on the curve (a grid) rather than drawn flat: every sticker
## on a sphere; on a cylinder, one on its side (|n.y| <= POLE), not one on a cap.
static func is_curved(s: Dictionary, surf: Dictionary) -> bool:
	if float(surf.get("r", 0.0)) <= 0.0:
		return false
	match str(surf.get("shape", "")):
		"sphere":
			return true
		"cylinder":
			return absf(float(StickerData.norm3(StickerData.a3(s.get("n")))[1])) <= StickerData.POLE
	return false

## Whether a sticker is drawn as a mesh laid on its body (a grid, or a face cut at its edge) rather than as its quad.
static func laid(s: Dictionary, d: Dictionary, surf: Dictionary) -> bool:
	match str(surf.get("shape", "")):
		"":
			return false
		"sphere":
			return float(surf.get("r", 0.0)) > 0.0
		"cylinder":
			if is_curved(s, surf):
				return true
	return bool(shape_of(s, d, surf).get("laid", false))

## The sticker's projector (sticker-decal.ts projector()): its at, right / up / n, extent [w, h] and depth along n.
static func projector(s: Dictionary, d: Dictionary) -> Dictionary:
	var b := StickerData.basis(StickerData.v3(s.get("n")), StickerData.v3(s.get("up")))
	var e := StickerData.extent(d, float(s.get("size", 0.2)))
	return {"at": StickerData.v3(s.get("at")), "right": b.right, "up": b.up, "n": b.n, "w": e.x, "h": e.y,
		"depth": maxf(MIN_DEPTH, DEPTH_RATIO * maxf(e.x, e.y))}

## Whether the point p of the body (host frame; `normal` the surface's normal there, when known) is under the
## sticker's print: inside its projector's box, on a surface facing n by at least MIN_FACING. The pad picks with this.
static func holds(s: Dictionary, d: Dictionary, p: Vector3, surf: Dictionary, normal := Vector3.ZERO) -> bool:
	var pr := projector(s, d)
	var rel: Vector3 = p - Vector3(pr.at)
	if absf(rel.dot(pr.right)) > float(pr.w) / 2.0 or absf(rel.dot(pr.up)) > float(pr.h) / 2.0 or absf(rel.dot(pr.n)) > float(pr.depth) / 2.0:
		return false
	var m := normal if normal.length_squared() > 1e-12 else _normal_at(p, surf)
	return m == Vector3.ZERO or m.normalized().dot(pr.n) >= MIN_FACING

## The point of a sticker's layout that a point p of the surface (host frame) is printed from: (u, v) along its right
## and up from `at` - the projection is orthographic, so this is p's own offset; Vector2(INF, INF) where the surface
## there faces n by less than MIN_FACING (its far side). The inverse of the print, for picking a sticker under the aim.
static func layout_of(s: Dictionary, p: Vector3, surf: Dictionary) -> Vector2:
	var b := StickerData.basis(StickerData.v3(s.get("n")), StickerData.v3(s.get("up")))
	var m := _normal_at(p, surf)
	if m != Vector3.ZERO and m.dot(b.n) < MIN_FACING:
		return Vector2(INF, INF)
	var rel := p - StickerData.v3(s.get("at"))
	return Vector2(rel.dot(b.right), rel.dot(b.up))

## The outward normal of an analytic body at its surface point p (host frame), Vector3.ZERO when it has none.
static func _normal_at(p: Vector3, surf: Dictionary) -> Vector3:
	match str(surf.get("shape", "")):
		"sphere":
			return p.normalized() if p.length() > 1e-9 else Vector3.ZERO
		"cylinder":
			var r := float(surf.get("r", 0.0))
			var hh := float(surf.get("h", 0.0)) / 2.0
			if hh > 0.0 and absf(p.y) >= hh - 0.001 and Vector2(p.x, p.z).length() < r - 0.001:
				return Vector3(0, signf(p.y), 0)
			var side := Vector3(p.x, 0.0, p.z)
			return side.normalized() if side.length() > 1e-9 else Vector3.ZERO
		"box":
			var e := StickerData.v3(surf.get("size")) / 2.0
			var q := p - StickerData.v3(surf.get("at", [0.0, 0.0, 0.0]))
			var best := -1
			var most := -INF
			for axis in 3:
				if e[axis] > 0.0 and absf(q[axis]) / e[axis] > most:
					most = absf(q[axis]) / e[axis]
					best = axis
			var m := Vector3.ZERO
			if best >= 0:
				m[best] = signf(q[best])
			return m
	return Vector3.ZERO

## One sticker as it is drawn, at `lift`: {verts, norms, uvs, idx, centre} in the host frame - laid on the body as
## shape_of() prints it, or its quad as a mesh where it is drawn flat. `fixed_cells` > 0 sets a grid's cells a side.
static func curved_mesh(s: Dictionary, d: Dictionary, lift: float, surf: Dictionary, fixed_cells := 0) -> Dictionary:
	var g := shape_of(s, d, surf, fixed_cells)
	if not bool(g.get("laid", false)):
		var xf := pose(s, d, lift)
		var nn: Vector3 = xf.basis.z.normalized()
		return {"verts": PackedVector3Array([xf * Vector3(-0.5, 0.5, 0), xf * Vector3(0.5, 0.5, 0), xf * Vector3(0.5, -0.5, 0), xf * Vector3(-0.5, -0.5, 0)]),
			"norms": PackedVector3Array([nn, nn, nn, nn]), "uvs": PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]),
			"idx": PackedInt32Array([0, 1, 2, 0, 2, 3]), "centre": xf.origin}
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var gv: Array = g.verts
	var gn: Array = g.norms
	for i in gv.size():
		var m: Vector3 = gn[i]
		verts.append(Vector3(gv[i]) + m * lift)
		norms.append(m)
	return {"verts": verts, "norms": norms, "uvs": PackedVector2Array(g.uvs), "idx": PackedInt32Array(g.idx), "centre": Vector3(g.centre) + Vector3(g.centre_n) * lift}

# ==== the print ====

## How one sticker is printed on a body (sticker-decal.ts: the projector's box, MIN_FACING, the orthographic
## projection along -n): {laid: false} for its plain quad - no body known, a sticker whole inside one face, or one the
## body takes no ink from - else {laid: true, curved (a grid among its pieces), verts, norms, uvs, idx (Arrays), centre,
## centre_n} in the host frame at lift 0: verts[i] + norms[i] * lift is the print at a lift.
static func shape_of(s: Dictionary, d: Dictionary, surf: Dictionary, fixed_cells := 0) -> Dictionary:
	var kind := str(surf.get("shape", ""))
	if kind == "" or d.is_empty():
		return {"laid": false, "curved": false}
	var pr := projector(s, d)
	var out := {"verts": [], "norms": [], "uvs": [], "idx": [], "curved": false, "pieces": 0, "whole": false}
	match kind:
		"sphere":
			if float(surf.get("r", 0.0)) > 0.0:
				_grid(out, pr, surf, fixed_cells)
		"cylinder":
			var r := float(surf.get("r", 0.0))
			var hh := float(surf.get("h", 0.0)) / 2.0
			if r > 0.0:
				_grid(out, pr, surf, fixed_cells)
				if hh > 0.0:
					for sgn in [1.0, -1.0]:
						var cap: Array = []
						for k in CAP_SIDES:
							var a := TAU * k / CAP_SIDES
							cap.append(Vector3(r * sin(a), sgn * hh, r * cos(a)))
						_planar(out, pr, cap, Vector3(0.0, sgn, 0.0))
		"box":
			var size := StickerData.v3(surf.get("size"))
			if size.x > 0.0 and size.y > 0.0 and size.z > 0.0:
				for f in _box_faces(StickerData.v3(surf.get("at", [0.0, 0.0, 0.0])), size / 2.0):
					_planar(out, pr, f[0], f[1])
	if (out.idx as Array).is_empty():
		return {"laid": false, "curved": false}
	if not bool(out.curved) and int(out.pieces) == 1 and bool(out.whole):
		return {"laid": false, "curved": false}
	var c0: Dictionary = _cast(pr, surf, Vector2.ZERO) if bool(out.curved) else {}
	var hit := bool(c0.get("hit", false))
	out["laid"] = true
	out["centre"] = c0.p if hit else pr.at
	out["centre_n"] = c0.m if hit else pr.n
	return out

## The six faces of a box (centre c, half extents e): [[polygon, outward normal]].
static func _box_faces(c: Vector3, e: Vector3) -> Array:
	var faces: Array = []
	for axis in 3:
		for sgn in [1.0, -1.0]:
			var m := Vector3.ZERO
			m[axis] = sgn
			var a1 := (axis + 1) % 3
			var a2 := (axis + 2) % 3
			var poly: Array = []
			for corner in [[-1.0, -1.0], [1.0, -1.0], [1.0, 1.0], [-1.0, 1.0]]:
				var p := c
				p[axis] += sgn * e[axis]
				p[a1] += float(corner[0]) * e[a1]
				p[a2] += float(corner[1]) * e[a2]
				poly.append(p)
			faces.append([poly, m])
	return faces

## A planar face of the body under the projector (sticker-decal.ts: a triangle whose face normal . n >= MIN_FACING is
## clipped by the six planes of the projector's box): the face polygon (convex, host frame), clipped in projector space
## (x along right, y along up, z along n, from `at`), appended as a fan. The UV of a point is its (x, y) in the box.
static func _planar(out: Dictionary, pr: Dictionary, poly: Array, m: Vector3) -> void:
	var n: Vector3 = pr.n
	var facing := m.dot(n)
	if facing < MIN_FACING:
		return
	var at: Vector3 = pr.at
	var right: Vector3 = pr.right
	var up: Vector3 = pr.up
	var w: float = pr.w
	var h: float = pr.h
	var hd: float = float(pr.depth) / 2.0
	var pts: Array = []
	for p in poly:
		var rel: Vector3 = Vector3(p) - at
		pts.append(Vector3(rel.dot(right), rel.dot(up), rel.dot(n)))
	for plane in [[0, 1.0, w / 2.0], [0, -1.0, w / 2.0], [1, 1.0, h / 2.0], [1, -1.0, h / 2.0], [2, 1.0, hd], [2, -1.0, hd]]:
		pts = _clip_axis(pts, int(plane[0]), float(plane[1]), float(plane[2]))
		if pts.size() < 3:
			return
	var area := 0.0
	for k in pts.size():
		var a: Vector3 = pts[k]
		var b: Vector3 = pts[(k + 1) % pts.size()]
		area += a.x * b.y - b.x * a.y
	area = absf(area) / 2.0
	if area < 1e-10:
		return
	var verts: Array = out.verts
	var base := verts.size()
	for q in pts:
		verts.append(at + right * q.x + up * q.y + n * q.z)
		(out.norms as Array).append(m)
		(out.uvs as Array).append(Vector2(q.x / w + 0.5, 0.5 - q.y / h))
	for k in range(1, pts.size() - 1):
		_tri(out, base, base + k, base + k + 1)
	out.pieces = int(out.pieces) + 1
	# the sticker's own plane is this face's, and the face holds all of it: the plain quad draws exactly this
	out.whole = facing >= 1.0 - 1e-5 and absf((Vector3(poly[0]) - at).dot(m)) <= 0.0005 and area >= w * h * (1.0 - 1e-4)

## Sutherland-Hodgman in projector space: the polygon kept where sign * p[axis] <= bound.
static func _clip_axis(poly: Array, axis: int, sign: float, bound: float) -> Array:
	var kept: Array = []
	for k in poly.size():
		var a: Vector3 = poly[k]
		var c: Vector3 = poly[(k + 1) % poly.size()]
		var fa := sign * a[axis] - bound
		var fc := sign * c[axis] - bound
		if fa <= 0.0:
			kept.append(a)
		if (fa < 0.0 and fc > 0.0) or (fa > 0.0 and fc < 0.0):
			kept.append(a.lerp(c, fa / (fa - fc)))
	return kept

## The sphere's surface or the cylinder's side, printed through the projector: the layout's cells x cells grid (enough
## that no cell spans more than STEP radians where the print is steepest, or `fixed_cells`), each point carried along
## -n onto the body (_cast). A cell inside every bound is two triangles on shared points; one cut by a bound (the
## projector's depth, MIN_FACING, a rim) is clipped in the layout at that bound and fanned.
static func _grid(out: Dictionary, pr: Dictionary, surf: Dictionary, fixed_cells: int) -> void:
	var r := float(surf.get("r", 0.0))
	var n: Vector3 = pr.n
	if str(surf.get("shape", "")) == "cylinder" and Vector2(n.x, n.z).length() < MIN_FACING:
		return   # the side faces n nowhere by MIN_FACING (a sticker on a cap): it takes no ink
	var w: float = pr.w
	var h: float = pr.h
	var steep := clampf(1.0 - float(pr.depth) / (2.0 * r), MIN_FACING, 1.0)   # the least facing inside the depth
	var cells := fixed_cells if fixed_cells > 0 else clampi(ceili(maxf(w, h) / (r * steep * STEP)), CELLS_LEAST, CELLS_MOST)
	var row := cells + 1
	var lattice: Array = []          # per point: [vertex index or -1, layout (u, v), uv, bounds, cast]
	for j in row:
		for i in row:
			var uv := Vector2(float(i) / cells, float(j) / cells)
			var lv := Vector2((uv.x - 0.5) * w, (0.5 - uv.y) * h)
			var e := _bounds(pr, surf, lv)
			lattice.append([-1, lv, uv, e[0], e[1]])
	var nb := (lattice[0][3] as Array).size()
	var before := (out.idx as Array).size()
	for j in cells:
		for i in cells:
			var corners := [lattice[j * row + i], lattice[j * row + i + 1], lattice[(j + 1) * row + i + 1], lattice[(j + 1) * row + i]]
			var whole := true
			var outside := false
			for k in nb:
				var fails := 0
				for c in corners:
					if float(c[3][k]) < 0.0:
						fails += 1
				whole = whole and fails == 0
				outside = outside or fails == 4
			if outside:
				continue
			if whole:
				var ids: Array = []
				for c in corners:
					if int(c[0]) < 0:
						c[0] = _add(out, c[4], c[2])
					ids.append(int(c[0]))
				_tri(out, ids[0], ids[1], ids[2])
				_tri(out, ids[0], ids[2], ids[3])
				continue
			var poly: Array = []
			for c in corners:
				poly.append(c[1])
			for k in nb:
				poly = _clip_layout(poly, pr, surf, k)
				if poly.size() < 3:
					break
			if poly.size() < 3:
				continue
			var casts: Array = []
			for lv in poly:
				var cast := _cast(pr, surf, lv)
				if not bool(cast.hit):
					casts.clear()
					break
				casts.append(cast)
			if casts.size() < 3:
				continue
			var ids: Array = []
			for k in poly.size():
				var lv: Vector2 = poly[k]
				ids.append(_add(out, casts[k], Vector2(lv.x / w + 0.5, 0.5 - lv.y / h)))
			for k in range(1, ids.size() - 1):
				_tri(out, ids[0], ids[k], ids[k + 1])
	if (out.idx as Array).size() > before:
		out.curved = true

## The layout point (u, v) carried along -n onto the sphere or the cylinder's side: the front-most crossing of the
## line at + right u + up v + t n with the body. {hit, t, p, m (the outward normal there), facing (= m . n)}; a miss
## has hit false and a facing below 0 that grows to 0 at the body's silhouette (so a bound can be found across it).
static func _cast(pr: Dictionary, surf: Dictionary, lv: Vector2) -> Dictionary:
	var n: Vector3 = pr.n
	var q: Vector3 = Vector3(pr.at) + Vector3(pr.get("right", Vector3.RIGHT)) * lv.x + Vector3(pr.get("up", Vector3.UP)) * lv.y
	var r := float(surf.get("r", 0.0))
	if r <= 0.0:
		return {"hit": false, "facing": -1.0}
	if str(surf.get("shape", "")) == "cylinder":
		var a := n.x * n.x + n.z * n.z
		var b := q.x * n.x + q.z * n.z
		var c := q.x * q.x + q.z * q.z - r * r
		var disc := b * b - a * c
		if a < 1e-9:
			return {"hit": false, "facing": -1.0}
		if disc < 0.0:
			return {"hit": false, "facing": -sqrt(-disc) / r}
		var root := sqrt(disc)
		var t := (-b + root) / a
		var p := q + n * t
		return {"hit": true, "t": t, "p": p, "m": Vector3(p.x, 0.0, p.z).normalized(), "facing": root / r}
	var b2 := q.dot(n)
	var disc2 := b2 * b2 - (q.dot(q) - r * r)
	if disc2 < 0.0:
		return {"hit": false, "facing": -sqrt(-disc2) / r}
	var root2 := sqrt(disc2)
	var t2 := -b2 + root2
	var p2 := q + n * t2
	return {"hit": true, "t": t2, "p": p2, "m": p2.normalized(), "facing": root2 / r}

## The bounds a layout point must keep to be printed, each >= 0 inside: [facing - MIN_FACING, the projector's back
## (t + depth / 2), its front (depth / 2 - t), and on the cylinder its top and bottom rims], with the point's cast.
static func _bounds(pr: Dictionary, surf: Dictionary, lv: Vector2) -> Array:
	var c := _cast(pr, surf, lv)
	var hd := float(pr.depth) / 2.0
	var cyl := str(surf.get("shape", "")) == "cylinder"
	var hh := float(surf.get("h", 0.0)) / 2.0
	var g: Array = [float(c.facing) - MIN_FACING]
	if bool(c.hit):
		var t := float(c.t)
		g.append(t + hd)
		g.append(hd - t)
		if cyl:
			var y: float = (c.p as Vector3).y
			g.append(hh - y if hh > 0.0 else 1.0)
			g.append(y + hh if hh > 0.0 else 1.0)
	else:
		g.append_array([-1.0, -1.0] + ([-1.0, -1.0] if cyl else []))
	return [g, c]

## Sutherland-Hodgman in the layout against bound k (>= 0 inside): each crossing found on its edge (_crossing).
static func _clip_layout(poly: Array, pr: Dictionary, surf: Dictionary, k: int) -> Array:
	var values: Array = []
	for p in poly:
		values.append(float(_bounds(pr, surf, p)[0][k]))
	var kept: Array = []
	for i in poly.size():
		var a: Vector2 = poly[i]
		var c: Vector2 = poly[(i + 1) % poly.size()]
		var ga: float = values[i]
		var gc: float = values[(i + 1) % poly.size()]
		if ga >= 0.0:
			kept.append(a)
		if (ga >= 0.0) != (gc >= 0.0):
			kept.append(_crossing(pr, surf, k, a, c, ga, gc))
	return kept

## Where bound k crosses 0 between layout points a and c (one inside, one out), on its inside: false position and
## halving in turn, to a hundred-thousandth of the edge.
static func _crossing(pr: Dictionary, surf: Dictionary, k: int, a: Vector2, c: Vector2, ga: float, gc: float) -> Vector2:
	var s_in := 0.0 if ga >= 0.0 else 1.0
	var s_out := 1.0 - s_in
	var g_in := ga if ga >= 0.0 else gc
	var g_out := gc if ga >= 0.0 else ga
	for it in 24:
		if absf(s_out - s_in) < 1e-5:
			break
		var s := (s_in + s_out) / 2.0 if it % 2 == 1 else s_in + (s_out - s_in) * g_in / (g_in - g_out)
		var gs := float(_bounds(pr, surf, a.lerp(c, s))[0][k])
		if gs >= 0.0:
			s_in = s
			g_in = gs
		else:
			s_out = s
			g_out = gs
	return a.lerp(c, s_in)

static func _add(out: Dictionary, cast: Dictionary, uv: Vector2) -> int:
	(out.verts as Array).append(cast.p)
	(out.norms as Array).append(cast.m)
	(out.uvs as Array).append(uv)
	return (out.verts as Array).size() - 1

## One triangle, wound as Godot's front face (clockwise seen from outside: (b - a) x (c - a) points into the body).
static func _tri(out: Dictionary, a: int, b: int, c: int) -> void:
	var v: Array = out.verts
	var nm: Array = out.norms
	var va: Vector3 = v[a]
	var f := (Vector3(v[b]) - va).cross(Vector3(v[c]) - va)
	if f.length_squared() < 1e-24:
		return
	var o: Vector3 = Vector3(nm[a]) + Vector3(nm[b]) + Vector3(nm[c])
	if f.dot(o) > 0.0:
		(out.idx as Array).append_array([a, c, b])
	else:
		(out.idx as Array).append_array([a, b, c])

# ==== the stack ====

## The box a sticker's print fills (host frame), in its own right / up / n: its quad, or its laid mesh's extent, and
## FOOT_SLACK each way along n. {c, ax: [right, up, n], h (half extents), r (its bounding radius)}.
static func footprint(s: Dictionary, d: Dictionary, g: Dictionary) -> Dictionary:
	var b := StickerData.basis(StickerData.v3(s.get("n")), StickerData.v3(s.get("up")))
	var right: Vector3 = b.right
	var up: Vector3 = b.up
	var n: Vector3 = b.n
	var at := StickerData.v3(s.get("at"))
	var c := at
	var h: Vector3
	if not bool(g.get("laid", false)):
		var e := StickerData.extent(d, float(s.get("size", 0.2)))
		h = Vector3(e.x / 2.0, e.y / 2.0, FOOT_SLACK)
	else:
		var lo := Vector3(INF, INF, INF)
		var hi := Vector3(-INF, -INF, -INF)
		for p in g.verts:
			var rel: Vector3 = Vector3(p) - at
			var q := Vector3(rel.dot(right), rel.dot(up), rel.dot(n))
			lo = Vector3(minf(lo.x, q.x), minf(lo.y, q.y), minf(lo.z, q.z))
			hi = Vector3(maxf(hi.x, q.x), maxf(hi.y, q.y), maxf(hi.z, q.z))
		var mid := (lo + hi) / 2.0
		h = (hi - lo) / 2.0 + Vector3(0.0, 0.0, FOOT_SLACK)
		c = at + right * mid.x + up * mid.y + n * mid.z
	return {"c": c, "ax": [right, up, n], "h": h, "r": h.length()}

## Whether two footprints overlap (separating axes of two boxes: their six faces' normals, then the nine products of
## their edges). Boxes that only touch, by less than TOUCH, do not.
static func boxes_overlap(a: Dictionary, b: Dictionary) -> bool:
	var t: Vector3 = Vector3(b.c) - Vector3(a.c)
	if t.length() > float(a.r) + float(b.r):
		return false
	var ax: Array = a.ax
	var bx: Array = b.ax
	var ea: Vector3 = a.h
	var eb: Vector3 = b.h
	var rot: Array = []
	var arot: Array = []
	for i in 3:
		var row: Array = []
		var arow: Array = []
		for j in 3:
			var v := Vector3(ax[i]).dot(Vector3(bx[j]))
			row.append(v)
			arow.append(absf(v) + 1e-6)
		rot.append(row)
		arot.append(arow)
	var ta: Array = [t.dot(ax[0]), t.dot(ax[1]), t.dot(ax[2])]
	for i in 3:
		if absf(ta[i]) > ea[i] + eb[0] * arot[i][0] + eb[1] * arot[i][1] + eb[2] * arot[i][2] - TOUCH:
			return false
	for j in 3:
		var tb: float = ta[0] * rot[0][j] + ta[1] * rot[1][j] + ta[2] * rot[2][j]
		if absf(tb) > ea[0] * arot[0][j] + ea[1] * arot[1][j] + ea[2] * arot[2][j] + eb[j] - TOUCH:
			return false
	for i in 3:
		var i1 := (i + 1) % 3
		var i2 := (i + 2) % 3
		for j in 3:
			var j1 := (j + 1) % 3
			var j2 := (j + 2) % 3
			var ra: float = ea[i1] * arot[i2][j] + ea[i2] * arot[i1][j]
			var rb: float = eb[j1] * arot[i][j2] + eb[j2] * arot[i][j1]
			if absf(ta[i2] * rot[i1][j] - ta[i1] * rot[i2][j]) > ra + rb:
				return false
	return true

# ==== where ====

## Where a sticker's middle is drawn (host frame) at `lift`: its `at` carried onto a curved body along -n, else at.
static func centre_of(s: Dictionary, surf: Dictionary, lift: float) -> Vector3:
	var b := StickerData.basis(StickerData.v3(s.get("n")), StickerData.v3(s.get("up")))
	var at := StickerData.v3(s.get("at"))
	if str(surf.get("shape", "")) in ["sphere", "cylinder"]:
		var c := _cast({"at": at, "right": b.right, "up": b.up, "n": b.n}, surf, Vector2.ZERO)
		if bool(c.hit):
			return Vector3(c.p) + Vector3(c.m) * lift
	return at + Vector3(b.n) * lift

## Where each drawn sticker stands in the world, by id (for probes and tools): {id: Vector3}.
func world_positions() -> Dictionary:
	var out: Dictionary = {}
	var surf := body()
	var deep := depth()
	for s0 in data.stickers_on(host_key()):
		var s := drawn_as(s0, host, deep, sided)
		var id := str(s.get("id", ""))
		if hangs(s, host, deep):
			out[id] = global_transform * centre_of(s, {}, float(lifts.get(id, maxf(0.0, LIFT - float(StickerData.a3(s.get("at"))[2])))))
		else:
			out[id] = global_transform * centre_of(s, surf, LIFT)
	return out

# ==== the scribbles ====

## Draw this board's scribbles again where they changed: one mesh per face ("Strokes_front", "Strokes_back"), made
## again exactly when the list of that face's ribbons changed (one drawn, erased, brought back, changed). A back stroke
## on a board without a back is not drawn. The mesh carries metas for probes: ids (in order), ranges ([first vertex,
## count] per stroke) and z (stroke_z of its face).
func _draw_strokes() -> void:
	var faces := {"front": [], "back": []}
	if str(host.get("kind", "")) == "board" and data.has_method("strokes_on"):
		for s in data.strokes_on(str(host.get("id", ""))):
			var face := str(s.get("face", "front"))
			if faces.has(face) and (face == "front" or sided):
				(faces[face] as Array).append(s)
	var live: Dictionary = {}
	for face in faces:
		var kept: Array = []
		var versions := PackedStringArray()
		for s in faces[face]:
			var k := _kept_of(s)
			kept.append(k)
			versions.append(str(k.version))
			live[str(s.get("id", ""))] = true
		var sig := ",".join(versions)
		var node_name := "Strokes_" + str(face)
		if sig == str(_stroke_sigs.get(face, "")) and (kept.is_empty() == (get_node_or_null(node_name) == null)):
			continue
		_stroke_sigs[face] = sig
		strokes_drawn[face] = kept.size()
		var old := get_node_or_null(node_name)
		if kept.is_empty():
			if old != null:
				remove_child(old)
				old.queue_free()
			continue
		_fill_strokes(node_name, kept, StickerData.stroke_z(str(face)))
	for id in _kept.keys():
		if not live.has(id):
			_kept.erase(id)

## A stroke's ribbon, made once: kept while the record is the same one (an op leaves an untouched stroke's record as it
## was), or one that reads the same (a truth read again: its points compared by their hash and count, which costs a
## fourteenth of writing them out - 0.9 ms against 13 ms for the research walls' 700 strokes).
func _kept_of(s: Dictionary) -> Dictionary:
	var id := str(s.get("id", ""))
	var had: Dictionary = _kept.get(id, {})
	if not had.is_empty() and is_same(had.rec, s):
		return had
	var sig := _stroke_sig(s)
	if not had.is_empty() and str(had.sig) == sig:
		had.rec = s
		return had
	var k := {"rec": s, "sig": sig, "ribbon": stroke_ribbon(s), "version": _next_version}
	_next_version += 1
	stroke_builds += 1
	_kept[id] = k
	return k

## What a stroke's ribbon is made from, as one string: its face, pen, width, colour, and its points by their hash and
## count.
static func _stroke_sig(s: Dictionary) -> String:
	var pts: Variant = s.get("points", [])
	return "%s|%s|%s|%s|%s" % [s.get("face", ""), s.get("pen", ""), s.get("width", 0.0), s.get("colour", ""),
		str((pts as Array).hash()) + ":" + str((pts as Array).size()) if pts is Array else str(pts)]

## One face's ribbons as one ArrayMesh in the board frame, in the order given (no depth written: a later ribbon is drawn
## over an earlier one).
func _fill_strokes(node_name: String, kept: Array, z: float) -> void:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	var ids: Array = []
	var ranges: Array = []
	for k in kept:
		var r: Dictionary = k.ribbon
		var base := verts.size()
		verts.append_array(r.verts)
		norms.append_array(r.norms)
		uvs.append_array(r.uvs)
		cols.append_array(r.cols)
		for i in (r.idx as PackedInt32Array):
			idx.append(base + i)
		ids.append(str((k.rec as Dictionary).get("id", "")))
		ranges.append([base, (r.verts as PackedVector3Array).size()])
	var mi := get_node_or_null(node_name) as MeshInstance3D
	if mi == null:
		mi = MeshInstance3D.new()
		mi.name = node_name
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
	var mesh := ArrayMesh.new()
	if not idx.is_empty():
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_NORMAL] = norms
		arrays[Mesh.ARRAY_TEX_UV] = uvs
		arrays[Mesh.ARRAY_COLOR] = cols
		arrays[Mesh.ARRAY_INDEX] = idx
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mi.mesh = mesh
	mi.material_override = stroke_material()
	mi.set_meta("ids", ids)
	mi.set_meta("ranges", ranges)
	mi.set_meta("z", z)

## The one material every scribble is drawn with (STROKE_SHADER), shared by every layer: sorted before every other
## see-through surface (STROKE_PRIORITY), pulled STROKE_PULL toward the eye.
static func stroke_material() -> ShaderMaterial:
	if _stroke_material == null:
		var sh := Shader.new()
		sh.code = STROKE_SHADER
		_stroke_material = ShaderMaterial.new()
		_stroke_material.shader = sh
		_stroke_material.render_priority = STROKE_PRIORITY
		_stroke_material.set_shader_parameter("pull", STROKE_PULL)
	return _stroke_material

## How far a soft pen's ribbon reaches each side of its centre line, in widths: half the line and three deviations
## (`soft` widths each; cardboard3d.ts softReach). The spray's: 1.1.
static func soft_reach(soft: float) -> float:
	return 0.5 + 3.0 * soft

## One stroke as a ribbon (cardboard3d.ts strokeRibbon, ported): {verts, norms, uvs, cols, idx} in the board frame at
## z = stroke_z(face). Its pen is the contract's (StickerData.PENS): its CAP ends the line (round: a half disc at each
## end; square: half its width on past each end) and draws a dot (a stroke whose points are all one point: a round
## pen's disc, a square pen's square); its JOIN turns a corner. ONE strip: the segments meet at a corner in shared
## vertices, mitred (along the bisector, hw / cos(turn / 2) out), so no part of a line is covered twice; only a corner
## too sharp for that - past StickerData.MITER_LIMIT for a miter join (the chisel), past ROUND_MITER for a round one - is
## broken, each segment ending square to itself there and the outer side filled: a round join's arc, a miter join's
## bevel. A soft pen's ribbon (soft > 0) reaches soft_reach(soft) widths each side of its centre line, its uv.y its
## `soft` (the shader's blur). Every triangle is wound as Godot's front face seen from OUTSIDE its face (clockwise from +Z
## on the front; from -Z, where x reads mirrored, on the back), so a front stroke is culled from behind the cardboard;
## normals out of the face; colour the stroke's (linear) with its pen's opacity as alpha; uv (across, soft).
static func stroke_ribbon(s: Dictionary) -> Dictionary:
	var pen: Dictionary = StickerData.PENS.get(str(s.get("pen", "")), StickerData.PENS.fine)
	var soft := maxf(0.0, float(pen.get("soft", 0.0)))
	var face := str(s.get("face", "front"))
	var back := face == "back"
	var z := StickerData.stroke_z(face)
	var width := float(s.get("width", pen.width))
	var hw := width * soft_reach(soft) if soft > 0.0 else width / 2.0
	# an object, not a Dictionary: a packed array held in a Dictionary is a value, and an append to it lands on a copy
	var out := _Ribbon.new()
	out.back = back
	var pts: Array = []
	for p in s.get("points", []):
		if not (p is Array and (p as Array).size() == 2):
			continue
		var v := Vector2(float(p[0]), float(p[1]))
		if pts.is_empty() or (pts[-1] as Vector2).distance_to(v) > 1e-7:
			pts.append(v)
	var square := str(pen.get("cap", "round")) == "square"
	var miter := str(pen.get("join", "round")) == "miter"
	if pts.size() == 1:
		var c: Vector2 = pts[0]
		if not square:
			_fan(out, c, 0.0, TAU, hw)
		else:
			var a := _vert(out, c + Vector2(-hw, -hw), -1.0)
			var b := _vert(out, c + Vector2(hw, -hw), -1.0)
			var cc := _vert(out, c + Vector2(hw, hw), 1.0)
			var d := _vert(out, c + Vector2(-hw, hw), 1.0)
			_rtri(out, a, b, cc)
			_rtri(out, a, cc, d)
	elif pts.size() > 1:
		var dir: Array = []
		for i in pts.size() - 1:
			dir.append(((pts[i + 1] as Vector2) - (pts[i] as Vector2)).normalized())
		var last := dir.size() - 1
		var starts: Array = []
		var ends: Array = []
		var d0: Vector2 = dir[0]
		var dl: Vector2 = dir[last]
		starts.append(_pair(out, (pts[0] as Vector2) - (d0 * hw if square else Vector2.ZERO), Vector2(-d0.y, d0.x), hw))
		for i in range(1, last + 1):
			var a: Vector2 = dir[i - 1]
			var b: Vector2 = dir[i]
			var turn := atan2(a.x * b.y - a.y * b.x, a.x * b.x + a.y * b.y)
			var ratio := 1.0 / cos(turn / 2.0)
			var p: Vector2 = pts[i]
			if absf(turn) < 1e-9 or ratio <= (StickerData.MITER_LIMIT if miter else ROUND_MITER):
				var m := Vector2(-a.y - b.y, a.x + b.x).normalized()
				var shared := _pair(out, p, m, hw * ratio)
				ends.append(shared)
				starts.append(shared)
				continue
			ends.append(_pair(out, p, Vector2(-a.y, a.x), hw))
			starts.append(_pair(out, p, Vector2(-b.y, b.x), hw))
			# the outer side of the corner: the right of a left turn, the left of a right turn
			var side := -1.0 if turn > 0.0 else 1.0
			var oa := Vector2(-a.y * side, a.x * side)
			var ob := Vector2(-b.y * side, b.x * side)
			if not miter:
				_fan(out, p, atan2(oa.y, oa.x), turn, hw)
			else:
				_rtri(out, _vert(out, p, 0.0), _vert(out, p + oa * hw, 1.0), _vert(out, p + ob * hw, 1.0))
		ends.append(_pair(out, (pts[last + 1] as Vector2) + (dl * hw if square else Vector2.ZERO), Vector2(-dl.y, dl.x), hw))
		for i in last + 1:
			var la: int = starts[i][0]
			var ra: int = starts[i][1]
			var lb: int = ends[i][0]
			var rb: int = ends[i][1]
			_rtri(out, ra, rb, lb)
			_rtri(out, ra, lb, la)
		if not square:
			_fan(out, pts[0], atan2(d0.x, -d0.y), PI, hw)            # from the left of the start, round behind it
			_fan(out, pts[last + 1], atan2(-dl.x, dl.y), PI, hw)     # from the right of the end, round ahead of it
	var n := out.pos.size()
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var cols := PackedColorArray()
	verts.resize(n)
	norms.resize(n)
	uvs.resize(n)
	cols.resize(n)
	var hex := str(s.get("colour", "#16191e"))
	var colour := (Color(hex) if Color.html_is_valid(hex) else Color("16191e")).srgb_to_linear()
	colour.a = float(pen.opacity)
	var normal := Vector3(0.0, 0.0, -1.0 if back else 1.0)
	for i in n:
		var q: Vector2 = out.pos[i]
		verts[i] = Vector3(q.x, q.y, z)
		norms[i] = normal
		uvs[i] = Vector2(out.across[i], soft)
		cols[i] = colour
	return {"verts": verts, "norms": norms, "uvs": uvs, "cols": cols, "idx": out.idx}

## A ribbon's vertex `across` of the way over it (-1 right edge, 0 the centre line, +1 left edge; a round rim is 1).
static func _vert(out: _Ribbon, p: Vector2, across: float) -> int:
	out.pos.append(p)
	out.across.append(across)
	return out.pos.size() - 1

## A ribbon's left and right vertices at p, `k` out along the normal `nrm`.
static func _pair(out: _Ribbon, p: Vector2, nrm: Vector2, k: float) -> Array:
	return [_vert(out, p + nrm * k, 1.0), _vert(out, p - nrm * k, -1.0)]

## One ribbon triangle wound as Godot's front face seen from outside its face (none for a sliver).
static func _rtri(out: _Ribbon, a: int, b: int, c: int) -> void:
	var pos := out.pos
	var pa := pos[a]
	var area := (pos[b].x - pa.x) * (pos[c].y - pa.y) - (pos[b].y - pa.y) * (pos[c].x - pa.x)
	if not (absf(area) > 1e-14):
		return
	# counter-clockwise seen from +Z is area > 0; Godot's front face is clockwise seen from outside
	if (area > 0.0) == out.back:
		out.idx.append_array([a, b, c])
	else:
		out.idx.append_array([a, c, b])

## A round cap or corner: a fan about c from the angle `from` through `sweep`, in steps of at most ROUND_STEP.
static func _fan(out: _Ribbon, c: Vector2, from: float, sweep: float, hw: float) -> void:
	var steps := maxi(1, ceili(absf(sweep) / ROUND_STEP))
	var centre := _vert(out, c, 0.0)
	var prev := _vert(out, c + Vector2(cos(from), sin(from)) * hw, 1.0)
	for k in range(1, steps + 1):
		var a := from + sweep * float(k) / float(steps)
		var v := _vert(out, c + Vector2(cos(a), sin(a)) * hw, 1.0)
		_rtri(out, centre, prev, v)
		prev = v

## A ribbon as it is made: its vertices in the board plane, how far across the ribbon each lies, its triangles, and
## whether it is wound for the back.
class _Ribbon:
	var pos := PackedVector2Array()
	var across := PackedFloat32Array()
	var idx := PackedInt32Array()
	var back := false
