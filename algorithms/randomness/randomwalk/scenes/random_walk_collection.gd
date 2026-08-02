# @identity
# essence: a rack of six sheets, each showing a DIFFERENT walk law — simple, diagonal, brownian, fractal, self-avoiding, lévy — drawn as ink on a 128x128 page you can pick up
# desire: hold two laws side by side in two hands and see that "random" was never one thing
# critical_parameter: residue — how much of each walk's history the rack leaves standing (head | tail | path | envelope | ensemble); walk_seed pins which six walks you get
# triggers: each sheet waits 1 s, picks its law, then burns 20-80 steps into its page; grabbing a sheet in VR resumes its walk one step every 0.1 s
# emerges: six pages of scribble that are obviously not the same kind of scribble — the lévy sheet is islands joined by long straight lines, the self-avoiding one is a maze that never touches itself
# needs: six RandomWalkGrabPaper instances [has]; a seed so two runs are comparable [added]
# relationships: the third walk of the group — shares the `residue` ladder word for word with [[random_walk_128]] (a walk you stand on) and [[random_walk_leash]] (a walk you hold); the sheets themselves are [[random_walk_grab_paper]], which is its own token and is NOT modified by this script's file
# truth: One walk is an anecdote. Six walks under six laws on one rack is the first honest thing anyone can say about chance.
#
# ─────────────────────────────────────────────────────────────────────────────
# DNA PROMOTION (2026-08-02) — residue
#
# This scene had ZERO exports and no script on its root. That is not the same as
# having nothing to vary: it is a rack that was assembled by hand in the editor
# and then never asked a question. This script is the root's first script; it
# adds one axis, one seed, and one bench flag, and at its default value it does
# nothing at all.
#
# THE GROUP. random_walk_128 and random_walk_leash already share one word for
# one idea, and this is the third walk, so it takes the same word with the same
# five values in the same order and the same meaning:
#
#   residue   how much of the walk's own history the rack leaves standing
#
#     head  <  tail  <  path  <  envelope  <  ensemble
#
#   head      only where each walk IS. The page is wiped back to the few pixels
#             within HEAD_RADIUS of the walker, so six sheets each carry one
#             small mark on an empty field and nothing tells you how it got
#             there. The claim, the same one 128 makes: a random process seen
#             from outside is a LOCATION, and this is what every rand() call in
#             every program actually looks like.
#     tail      + a window. Everything within TAIL_RADIUS of the walker
#             survives, so each page carries a short stub of its own scribble
#             and the six laws become distinguishable again — but only just, and
#             not where any of them started.
#     path      + the archive. Every stroke the walk ever made, and nothing ever
#             fades. THIS IS THE LEGACY LINEAGE, pixel for pixel: at `path` this
#             script sets process off in _ready() and never touches a page, so
#             all six placements render exactly what they render today.
#     envelope  + the bound. A rail drawn around the smallest rectangle each
#             walk stayed inside. The scribble alone says "it spread"; the rail
#             says HOW FAR, and putting six rails on one rack is the only way to
#             see that the lévy sheet's bound is enormous and the self-avoiding
#             sheet's is tight — which is the whole comparison the rack exists
#             to make and which the raw scribble hides.
#     ensemble  + the counterfactual. Three more walks under THE SAME LAW as the
#             sheet they are laid under, in pale ink, beneath the real one. Each
#             page stops being THE brownian walk and becomes ONE brownian walk.
#             Nothing in the pale ink happened; that is the point.
#
# THE WINDOW AT `head` AND `tail` IS CUT IN SPACE, NOT IN TIME, and that is
# worth saying plainly. A page keeps pixels, not steps — RandomWalk draws a
# Bresenham line and forgets it — so there is no step order to slice. A disc
# around the walker is the honest available approximation of "recently", and it
# buys something a temporal window would not: the five rungs are STRICTLY NESTED
# SETS OF PIXELS. head ⊂ tail ⊂ path, and envelope and ensemble only add. No
# rung invents ink the record did not already contain, so nothing here can be
# mistaken for a different walk.
#
# WHAT IS DELIBERATELY NOT THE AXIS. `selected_walk_type` on each sheet is the
# obvious knob and it is CURRICULUM: those six laws in that order are what this
# rack teaches, and shuffling them would be changing the lesson, not the
# staging. `interval` is a RATE and invisible to a still. background_color and
# pixel_color are "which colour", which is never an argument.
#
# NOT TOUCHED: the mathematics, and the sheets' own file. RandomWalk's seven
# walk functions, the 20-80 step burst, the Bresenham line and the grab-to-walk
# behaviour are identical at every rung. random_walk_grab_paper is a separate
# registered token with its own placements and this promotion does not edit its
# script or its scene — everything below reads the sheets' public state and
# composites on top of the page they already drew.
# ─────────────────────────────────────────────────────────────────────────────

extends Node3D
class_name RandomWalkCollection

## THE AXIS — how much of each walk's history this rack leaves standing. One
## ordered ladder, monotone: each rung shows everything the rung below shows,
## plus one more kind of leaving. `path` is the legacy default, and at `path`
## this script does nothing whatsoever.
@export_enum("head", "tail", "path", "envelope", "ensemble") var residue: String = "path"

## The allow-list, in ladder order — the same five words the @export_enum above
## declares, same spelling, same sequence.
const RESIDUES: PackedStringArray = ["head", "tail", "path", "envelope", "ensemble"]

## The ladder, as rank. ADOPTED WORD FOR WORD from random_walk_leash, which is
## the group's canonical table, and duplicated for the same mechanical reason
## random_walk_128 duplicates it: that file preloads two godot-xr-tools scenes,
## and a parse-time dependency from here would drag the whole XR addon into a
## rack that already instances the pickable it needs. All three copies say so;
## if one changes, change all three.
const RESIDUE_RUNGS := {
	"head": 0,      # the walker
	"tail": 1,      # + a window
	"path": 2,      # + the whole record   ← legacy default
	"envelope": 3,  # + the bound it obeyed
	"ensemble": 4,  # + the walks it did not take
}

# ── Determinism ──────────────────────────────────────────────────────────────
# NO SEEDED WALK, NO MEASUREMENT. Six sheets is six independent random objects,
# so an evidence sweep of an unseeded rack renders five different racks and
# reports the difference between the racks as the axis — a confident, entirely
# false bite that nothing downstream can catch.
#
# WHY A SEED ON THE ROOT REACHES THE SHEETS: every sheet's _ready() begins with
# `await get_tree().create_timer(1.0).timeout` and draws NOTHING before that.
# _ready() runs children-first, so this root's _ready() has already returned by
# the time the first sheet resumes at t = 1 s. seed() here therefore lands ahead
# of every draw on the rack, and no sheet's file has to change for it to work.

## Pins the global stream the six sheets draw from. -1 = do not touch it, i.e.
## today: a fresh unpredictable rack every launch, which is right in a room and
## useless on a bench. Any value >= 0 calls seed() once, first thing in _ready().
@export var walk_seed: int = -1

## Bench-only, and an INT rather than a bool on purpose — a fixture value that
## arrives as the string "true" is silently rejected by a typed bool property
## and the flag then reads false with nothing logged. 0 = today; 1 = strip.
##
## WHAT IT STRIPS AND WHY. The rack carries two MeshInstance3Ds that render
## nothing and wreck the framing: placeMe/MeshInstance3D has no mesh at all, and
## placeMe/Sprite3D/MeshInstance3D2 is a 5.4-unit box under a Sprite3D whose
## `visible` is false. The sweep's AABB walk counts every MeshInstance3D
## regardless of mesh or visibility, so that invisible box measures the rack at
## 3.24 m (the registry has it recorded) when the six sheets it is supposed to
## photograph span about 0.6 m. The camera fits the DIAGONAL, so it parks ~16 m
## out and the subject lands at roughly 6% of frame width — small enough that
## any axis, however violent, measures as noise. At 1 both are freed before the
## first frame; neither draws a pixel in any room, so nothing visible changes.
@export var bench_bare_rack: int = 0

## `head` — the disc kept around the walker, in page pixels (page is 128x128).
## Small enough to read as a marker and not as a stub.
const HEAD_RADIUS: float = 3.0
## `tail` — the window kept around the walker. A 20-80 step burst at area_size 2
## spans roughly 40 px, so 12 keeps a legible stretch and drops the rest.
const TAIL_RADIUS: float = 12.0
## `envelope` — the rail's ink and thickness. The sheets ship a BLACK page and a
## magenta stroke (random_walk_grab_paper.tscn overrides the script's green
## default), so white is the one ink that cannot be mistaken for either; 1 px
## would vanish at the size a sheet occupies in frame.
const RAIL_INK: Color = Color(1.0, 1.0, 1.0, 1.0)
const RAIL_THICKNESS: int = 3
## `ensemble` — how many counterfactual walks are laid under each real one, and
## how long each is. Kept at the low end of the sheets' own 20-80 range so the
## pale ink reads as a halo and never as a second subject.
const GHOST_WALKS: int = 3
const GHOST_STEPS: int = 44

## The six sheets, found by duck-typing rather than by node path so a renamed or
## reordered instance cannot silently drop out of the rack.
var _papers: Array[Node] = []
## The residue is applied exactly once, on the first frame after every sheet has
## finished its burst.
var _applied: bool = false


func _ready() -> void:
	# FIRST, and before any sheet has drawn. -1 in every room, so this is a
	# no-op there and the global stream is exactly where it always was.
	if walk_seed >= 0:
		seed(walk_seed)

	_papers = _find_papers(self)

	if bench_bare_rack != 0:
		_bare_the_rack()

	# THE LEGACY RUNG. At `path` this script has no further business: no poll,
	# no page is read, no page is written, and all six placements render what
	# they have always rendered.
	if _rung() == 2:
		set_process(false)
		return
	set_process(true)


## Polls for the moment every sheet has finished its 20-80 step burst — about
## t = 1 s — and composites once. A fixed timer was rejected: the sweep
## photographs at ~1.2 s, so a guess 0.2 s wide would decide the whole result.
func _process(_delta: float) -> void:
	if _applied or _papers.is_empty():
		set_process(false)
		return
	for p in _papers:
		if int(p.get("turn_count")) <= 0:
			return
	_applied = true
	set_process(false)
	_apply_residue()


func apply_grid_config(config: Dictionary) -> void:
	if config.has("residue"):
		var want: String = str(config["residue"]).strip_edges().to_lower()
		if RESIDUES.has(want):
			residue = want
		else:
			push_warning("random_walk_collection: unknown residue '%s' — keeping '%s'" % [want, residue])
	if config.has("walk_seed"):
		walk_seed = int(str(config["walk_seed"]))
	if config.has("bench_bare_rack"):
		bench_bare_rack = int(str(config["bench_bare_rack"]))
	# A rung that arrives after _ready() still gets applied: the poll is
	# restarted unless we are back at the legacy rung, which owns no pixels.
	if _rung() != 2 and not _applied:
		set_process(true)


# ═════════════════════════════════════════════════════════════════════════════
# THE RESIDUE LADDER
# ═════════════════════════════════════════════════════════════════════════════

## The reader. Lower, strip, and fall back to the legacy value on anything
## unrecognised: a typo must not wipe six pages that six rooms expect to be
## covered in ink.
func residue_name() -> String:
	var v: String = residue.strip_edges().to_lower()
	if RESIDUE_RUNGS.has(v):
		return v
	if v != "":
		push_warning("random_walk_collection: unknown residue '%s' — keeping 'path'" % v)
	return "path"


## Rank of the current rung, 0..4. Every gate below is a comparison against it.
func _rung() -> int:
	return int(RESIDUE_RUNGS.get(residue_name(), 2))


## One pass over the rack. Every rung derives from the page the sheet itself
## drew — nothing here runs the curriculum's walk a second time except the pale
## ensemble ink, which is explicitly counterfactual.
func _apply_residue() -> void:
	var rung: int = _rung()
	for p in _papers:
		var img: Image = p.get("img")
		if img == null:
			continue
		var w: int = img.get_width()
		var h: int = img.get_height()
		if w <= 0 or h <= 0:
			continue
		var bg: Color = p.get("background_color")
		var ink: Color = p.get("pixel_color")
		var head: Vector2 = p.get("current_position")

		if rung <= 1:
			var keep: float = HEAD_RADIUS
			if rung == 1:
				keep = TAIL_RADIUS
			_keep_window(img, w, h, bg, head, keep)
		if rung >= 3:
			_draw_bound(img, w, h, bg)
		if rung >= 4:
			_lay_ensemble(p, img, w, h, bg, ink)

		var tex: ImageTexture = p.get("texture")
		if tex == null:
			continue
		tex.set_image(img)
		var mi = p.get("mesh_instance")
		if mi is MeshInstance3D:
			MaterialHelper.update_texture_material(mi, tex)


## `head` and `tail` — everything further than `radius` from the walker returns
## to background. Subtractive only: this never writes ink, so what survives is a
## strict subset of the record the sheet drew.
func _keep_window(img: Image, w: int, h: int, bg: Color, head: Vector2, radius: float) -> void:
	var r2: float = radius * radius
	for y in range(h):
		for x in range(w):
			var dx: float = float(x) - head.x
			var dy: float = float(y) - head.y
			if dx * dx + dy * dy > r2:
				img.set_pixel(x, y, bg)


## `envelope` — the smallest rectangle the walk stayed inside, read straight off
## the page (any pixel that is not background is a place the walk went) and
## drawn as a rail just outside it.
func _draw_bound(img: Image, w: int, h: int, bg: Color) -> void:
	var min_x: int = w
	var min_y: int = h
	var max_x: int = -1
	var max_y: int = -1
	for y in range(h):
		for x in range(w):
			if img.get_pixel(x, y).is_equal_approx(bg):
				continue
			if x < min_x:
				min_x = x
			if x > max_x:
				max_x = x
			if y < min_y:
				min_y = y
			if y > max_y:
				max_y = y
	if max_x < 0:
		return
	min_x = maxi(min_x - RAIL_THICKNESS, 0)
	min_y = maxi(min_y - RAIL_THICKNESS, 0)
	max_x = mini(max_x + RAIL_THICKNESS, w - 1)
	max_y = mini(max_y + RAIL_THICKNESS, h - 1)
	for t in range(RAIL_THICKNESS):
		var top: int = mini(min_y + t, h - 1)
		var bottom: int = maxi(max_y - t, 0)
		for x in range(min_x, max_x + 1):
			img.set_pixel(x, top, RAIL_INK)
			img.set_pixel(x, bottom, RAIL_INK)
		var left: int = mini(min_x + t, w - 1)
		var right: int = maxi(max_x - t, 0)
		for y in range(min_y, max_y + 1):
			img.set_pixel(left, y, RAIL_INK)
			img.set_pixel(right, y, RAIL_INK)


## `ensemble` — three more walks from the same origin under the SAME LAW as this
## sheet, in pale ink, composited UNDERNEATH the real one so the record stays on
## top and nothing the walk actually did is covered up.
##
## The ghosts are drawn into their own buffer and then merged only where the
## record left background, which is why "under" is true here and not merely
## claimed. They draw from the global stream because RandomWalk's seven
## functions are static and take no generator; that stream is re-pinned first
## from walk_seed, disjointly, and every real draw on the rack has already
## happened by the time this runs, so nothing observable moves.
func _lay_ensemble(p: Node, img: Image, w: int, h: int, bg: Color, ink: Color) -> void:
	var kind = p.get("chosen_walk_type")
	if kind == null:
		return
	var area: int = int(p.get("area_size"))
	if area <= 0:
		area = 1
	var ghost_ink: Color = bg.lerp(ink, 0.45)
	var ghosts := Image.create(w, h, false, Image.FORMAT_RGBA8)
	ghosts.fill(bg)
	if walk_seed >= 0:
		seed(walk_seed * 7919 + 104729)
	for g in range(GHOST_WALKS):
		var pos := Vector2(w / 2.0, h / 2.0)
		var visited := {}
		for i in range(GHOST_STEPS):
			pos = RandomWalk.perform_random_walk(ghosts, pos, area, w, h, kind, visited, ghost_ink)
	for y in range(h):
		for x in range(w):
			if not img.get_pixel(x, y).is_equal_approx(bg):
				continue
			if ghosts.get_pixel(x, y).is_equal_approx(bg):
				continue
			img.set_pixel(x, y, ghost_ink)


# ═════════════════════════════════════════════════════════════════════════════
# THE RACK
# ═════════════════════════════════════════════════════════════════════════════

## Every descendant that carries a sheet's public state. Duck-typed rather than
## pathed: the instances are named RandomWalkGrabPaper_<law>_<id> by hand in the
## scene and a rename must not quietly empty the rack.
func _find_papers(from: Node) -> Array[Node]:
	var found: Array[Node] = []
	var stack: Array[Node] = [from]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n != from:
			if "turn_count" in n and "current_position" in n and "img" in n:
				found.append(n)
		for c in n.get_children():
			stack.append(c)
	return found


## Bench only. Frees the two MeshInstance3Ds that render nothing and blow up the
## sweep's AABB. Anything under a sheet is left alone — the sheets ARE the
## subject — and so is the SubViewport, which is not a MeshInstance3D and never
## reached the AABB in the first place.
func _bare_the_rack() -> void:
	var stack: Array[Node] = [self]
	var stripped: int = 0
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if not (n is MeshInstance3D):
			continue
		if _inside_a_paper(n):
			continue
		var mi := n as MeshInstance3D
		# A meshless MeshInstance3D still contributes a POINT to the AABB; a
		# mesh under a hidden parent contributes its whole box. Both are
		# invisible to a player and both distort the framing.
		if mi.mesh == null or not mi.is_visible_in_tree():
			mi.queue_free()
			stripped += 1
	print("[RandomWalkCollection] bench_bare_rack: freed %d non-rendering mesh nodes" % stripped)


func _inside_a_paper(n: Node) -> bool:
	var cur: Node = n
	while cur != null and cur != self:
		if _papers.has(cur):
			return true
		cur = cur.get_parent()
	return false
