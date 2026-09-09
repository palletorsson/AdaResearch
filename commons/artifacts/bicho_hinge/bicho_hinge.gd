# @identity
# essence: six identical aluminium plates hinged into a tree on a museum plinth, opened by the seed to one arbitrary configuration and left there — an object whose transformation group is its own joints rather than something a matrix does to it from outside
# desire: that a visitor take hold of a plate, turn it, let go, and find that there is nowhere for it to go back to
# critical_parameter: swing — "tight" · "open" · "free" names the reachable set. It is not a comfort setting: at tight the joints cannot reach the plinth at all (0 of 4000 draws), at open 17.73% of draws put a plate through it, at free 68.75%. A bigger group buys more shapes AND more shapes that are not shapes, and that ratio is the lesson
# triggers: _ready() searches a deterministic Kronecker sequence for a pose that is legibly bent, clears the floor and misses the plinth, and stands the object in it; grabbing a plate turns exactly one hinge; releasing leaves it turned
# emerges: a body with no canonical view. Every still of it — including the four this project will shoot — is a photograph of one accident, which is what Clark said about photographs of Bichos
# needs: floor at y=0 under the origin [the grid provides it]; ~2 m of clear approach so a body can get its hands to plate height, 0.80-1.30 m [spatial_needs.clearance.front]; commons/ui/text_screen.gd for the caption [present]; res://commons/render/pbr_kit.gd [present]; godot-xr-tools for the VR grab [present on this machine but GITIGNORED — loaded by path with a guard, never by class name, so its absence costs the grab and nothing else]
# relationships: stands against Trans_Rotation and Trans_Scale, which do rotation and scale TO a rigid body from outside and leave the body with no say; borrows its defensive addon load from commons/audio/cables/synth_cable_plug.gd and its hinge+handle wiring from commons/audio/interfaces/VRAudioControlDial.tscn, which is the only other thing in this corpus that uses an XR Tools hinge
# truth: a rigid body has one transformation group and it is the same group for every rigid body — the maps next door teach it as something done to a cube. This object carries its own, made of its own joints, and it is SMALLER than the set of poses you can picture for it. So the question stops being what can I do to this thing and becomes what can this thing do, and the answer is a fact about the thing rather than about the algebra.

extends Node3D
class_name BichoHinge

## BICHO — Lygia Clark, Rio de Janeiro, 1960. Hinged aluminium plates with no
## fixed shape and no right way up. Clark held that the work does not exist as an
## image: every photograph of a Bicho is a photograph of one accident, and the
## piece is only itself while somebody is moving it. She called them Critters and
## meant it — they have a "spine", they resist, they will not do everything.
##
## THE ARGUMENT, in a sequence whose maps teach rotation and scale on rigid
## bodies. A cube in Trans_Rotation has one transformation group; so does every
## other cube; the group lives in the matrix and the object is only the thing it
## is applied to. Here the group is the object's OWN articulation. Three things
## follow that a rigid body cannot show you:
##
##   1. THE GROUP IS THE OBJECT'S. Five hinges, each with its own limits, is a
##      five-dimensional box — and it is this Bicho's box, not a Bicho's box.
##   2. COMPOSITION IS ORDER-DEPENDENT AND YOU CAN FEEL IT. Every hinge angle is
##      relative to its parent, so turning the root and then the leaf does not
##      land where turning the leaf and then the root does. Nothing here is
##      commutative and nothing here is written down as a matrix.
##   3. THE REACHABLE SET IS A PROPER SUBSET OF THE IMAGINABLE ONE. The limits
##      cut it, and so does the plinth. See `swing`.
##
## WHAT I COULD NOT TEST, AND WHAT I DID INSTEAD. This was written with the
## editor open on another instance, so Godot could not be run. Every number in
## this file that could be solved was solved first, in a Python replica of the
## forward kinematics using the same arithmetic — the same Kronecker draw, the
## same Transform3D composition order, the same eighteen sample points per plate.
## The pose, the extents, the pass rates and the three clash percentages above are
## outputs of that replica over 4000 draws per mode, not estimates. Where it
## could not help (materials, the addon handoff, the desktop pointer) the code is
## written to fail into something that still stands up and still photographs.

const PBR := preload("res://commons/render/pbr_kit.gd")
const TextScreenScript := preload("res://commons/ui/text_screen.gd")

## The two XR Tools scripts, BY PATH. Never by class name: /addons/* is
## gitignored in this repo (.gitignore:13, with three editor addons whitelisted
## and xr-tools not among them), so `class_name XRToolsInteractableHinge` is a
## global that exists on this machine and would be a PARSE ERROR on a clean
## checkout. synth_cable_plug.gd load()s the handle the same way for the same
## reason. Absent, the pose still builds and the desktop drag still works; only
## the VR grab is gone.
const HINGE_SCRIPT := "res://addons/godot-xr-tools/interactables/interactable_hinge.gd"
const HANDLE_SCRIPT := "res://addons/godot-xr-tools/interactables/interactable_handle.gd"

# ── constants that are decisions, not settings ────────────────────────────────

## Clark's gauge. 3 mm aluminium sheet, cut and hinged; thinner reads as paper
## and thicker reads as armour plate.
const PLATE_T := 0.003
## Plate depth as a fraction of its width. 0.6923 is 0.18/0.26 — a plate a bit
## wider than it is deep, which is what makes the same plate on a `far` edge and
## on a `left` edge two visibly different limbs. A square plate would make the
## tree a polyomino and the object would read as a folding net, which is a
## different and much tidier idea than a Bicho.
const DEPTH_RATIO := 0.6923076923076923
## Plinth half-width as a fraction of plate width. THIS NUMBER IS LOAD-BEARING.
## The root plate stands on edge, so its `left` and `right` hinge lines are
## vertical at x = ±plate_w/2; a plate hinged there swings in a horizontal plane
## and hangs at |x| >= plate_w/2. A plinth wider than that is a plinth the wings
## swing INTO. Measured: at half-width 0.46·w every draw survives, at 0.577·w
## (a 0.30 m plinth under a 0.26 m plate) 4000 of 4000 draws clash and the search
## never returns.
const PLINTH_RATIO := 0.46
## Metres of air between the plinth top and the root plate's bottom edge, so the
## bracket has something to hold and the plate does not appear to grow out of the
## paint.
const ROOT_LIFT := 0.02
## No plate may come closer than this to the floor. A guard, not a look: the
## deepest chain is 3 links and one link reaches sqrt(d² + (w/2)²) = 0.222 m, so
## the geometry cannot reach the floor from a 0.82 m plinth anyway. It is here
## because plinth_height is a knob and someone will set it low.
const FLOOR_CLEAR := 0.10
## How far below the plinth top a plate has to be, inside the plinth footprint,
## before it counts as INSIDE the plinth rather than touching it. 4 mm, which is
## more than the plate half-thickness plus the float error on a plate lying
## exactly in the plinth's top plane — without it the root's own neighbours read
## as buried and the search rejects everything.
const SINK := 0.004
## How far above the plinth top something must reach before the pose counts as
## STANDING rather than folded, IN UNITS OF ONE LINK'S REACH. Proportional, and
## that is the whole point of the constant.
##
## It was a flat 0.20 m, which is a constant about ONE plate width. Swept over
## the 300 combinations of swing × plate_w × plate_count × plinth_height that the
## clamps allow, 30 of them could not satisfy it AT ALL: at plate_w 0.08 with 4
## or 5 plates the best max_y over all 240 draws is 1.0057 against a bar of
## 1.0200 — short by 14 mm, for every seed and every swing — so the search
## exhausted its guard and shipped the flat fallback. A folded stack, a
## push_warning, and nothing else visibly wrong.
##
## 0.90 is not a taste: at the shipped 0.26 m plate one link reaches 0.22204 m
## and 0.90 links is 0.19983 m, so this restates the old bar to within 0.16 mm.
## Measured after the change — the shipped pose is identical (attempt 0, angles
## unchanged), all 50 seeds at the defaults are identical, the only poses that
## move at all are at plate_w 0.08 and 0.16, and failures go 30/300 to 0/300.
const STAND_LINKS := 0.90

## The draw is a Kronecker sequence on irrational strides, NOT a
## RandomNumberGenerator. Two reasons, and the second is the real one:
##   - the same pose on every load, so the capture is repeatable;
##   - the same pose in PYTHON, so the shipped configuration could be solved and
##     its extents measured before this file was ever parsed. A PCG32 stream
##     cannot be replicated in a scratch script without reimplementing PCG32,
##     and a reimplementation you cannot test is not a measurement.
const ALPHA := [1.4142135623730951, 1.7320508075688772, 2.23606797749979,
	2.6457513110645907, 3.3166247903554, 3.605551275463989]
## Attempts per seed, and the stride between seeds. GUARD < STRIDE so no two
## seeds can ever walk into each other's draws. Measured over seeds 0-49 ×
## counts 4-7 × all three swings: 600 of 600 found a pose, worst case at
## attempt 26 of 240.
const STRIDE := 4001.0
const GUARD := 240

## The tree, child by child: [parent plate, which of the parent's free edges].
## Depths are 1, 2, 2, 1, 3, 3 — capped at 3 on purpose, because 3 links of
## 0.222 m reach is 0.666 m and a 0.82 m plinth still leaves 0.154 m of air. A
## fourth level would reach -0.068 and put a plate through the floor.
const LINKS := [
	[0, "far"], [1, "far"], [1, "right"], [0, "left"], [2, "left"], [3, "far"],
]

const SWINGS := ["tight", "open", "free"]

## The XR Tools handle's layer, repeated from interactable_handle.tscn rather
## than read from it (the .tscn is not in the repo). Layer 19. It is also half of
## DesktopInteractionPointer's collision_mask_value (1310720 = layers 19 + 21),
## which is why the plates carry it too: with it, the crosshair can drive them
## with the addon missing entirely.
const HANDLE_LAYER := 262144
const WORLD_LAYER := 1

# ── the argument ──────────────────────────────────────────────────────────────

@export_category("The argument")
## Plates, root included. Four is a limb, seven is a creature. The tree table is
## fixed, so raising this adds a named child to a named parent rather than
## regenerating a different object — the same Bicho with another plate on it.
@export_range(4, 7) var plate_count: int = 6

## "tight" · "open" · "free" — THE REACHABLE SET, and the artifact's argument.
##
## Not a comfort setting. Measured over 4000 draws each, 6 plates, on how often a
## draw puts a plate through the plinth it is standing on:
##
##   tight   0.00%   the joints cannot reach the plinth. Every pose is a pose.
##   open   17.73%   about one imagined shape in six is not available.
##   free   68.75%   two in three of the shapes this thing can be asked for are
##                   shapes it cannot be in, and the object has not changed.
##
## That is the whole lesson in one number: widening a transformation group does
## not widen the set of things you can DO, because the group does not know about
## the plinth. Reachability is a fact about the object AND its situation.
@export var swing: String = "open"

## Which accident. The seed picks a starting point in the Kronecker sequence; the
## search walks forward from there until a pose passes. Every seed is as
## canonical as every other seed, which is to say not at all — the knob exists so
## that nobody can mistake the shipped still for the object.
@export var pose_seed: int = 0

## Plate width in metres, along the hinge line. Everything else scales off it:
## depth (DEPTH_RATIO), plinth width (PLINTH_RATIO), knuckle radius, grab volume.
## 0.26 puts the assembled body at roughly 0.54 × 0.50 × 0.38 sitting between
## 0.80 and 1.30 m — hand height for a standing adult, which is the only height
## at which any of this is true.
@export var plate_w: float = 0.26

@export_category("Presentation")
## Plinth height. The plates sit from here to about here + 0.48.
@export var plinth_height: float = 0.82
## The caption plate beside it. Off, the object is unlabelled, which is a legible
## way to show it and a bad default in a teaching map.
@export var show_caption: bool = true

# ── state ─────────────────────────────────────────────────────────────────────

var _angles: Array[float] = []      ## degrees, one per hinge, live
var _limits: Array[Vector2] = []    ## degrees, [lo, hi] per hinge
var _hinges: Array[Node] = []       ## the rotating node per hinge
var _mounts: Array[Node3D] = []     ## its UNROTATED parent — the drag frame
var _handles: Array[Node] = []      ## the XR grab body per hinge, or null
var _caption: Node3D = null         ## a TextScreen; touched only through set()
var _drag: int = -1                 ## desktop: hinge being dragged, or -1
var _drag_bias: float = 0.0         ## degrees between the grab point and the hinge


func _ready() -> void:
	_build()


# ══ BUILD ════════════════════════════════════════════════════════════════════

func _build() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_angles.clear()
	_limits.clear()
	_hinges.clear()
	_mounts.clear()
	_handles.clear()
	_caption = null
	_drag = -1

	var n: int = clampi(plate_count, 4, 7)
	var w: float = clampf(plate_w, 0.08, 0.60)
	var d: float = w * DEPTH_RATIO
	var ph: float = clampf(plinth_height, 0.20, 1.40)
	var mode: String = _swing_name()

	for i in range(n - 1):
		_limits.append(_band(mode, str(LINKS[i][1])))

	# THE THREE PARALLEL ARRAYS ARE SIZED FIRST AND WRITTEN BY INDEX, never
	# appended. _build_plate walks the tree depth-first, so plate 2's outgoing
	# link (index 4) is built before plate 0's second link (index 3) — appending
	# would have stored hinge 4 at slot 2 and every limit, every caption angle
	# and every drag would have been about the wrong joint, with nothing visibly
	# wrong in the still.
	_hinges.resize(n - 1)
	_mounts.resize(n - 1)
	_handles.resize(n - 1)

	var root_x: Transform3D = _root_frame(ph)
	var found: Array = _search(root_x, n, w, d, ph)
	_angles.assign(found)

	var steel := PBR.machined_metal(PBR.STEEL, 0.24)
	var sheet := PBR.brushed_metal(PBR.ALUMINIUM, 0.30)

	_build_plinth(ph, w, steel)

	# THE WHOLE ARTICULATED TREE IS BUILT DETACHED AND ADDED IN ONE CALL, and
	# that is not tidiness. XRToolsInteractableHandleDriven._ready() hooks its
	# handles by walking its children ONCE, at _ready. Adding a hinge to the tree
	# and then adding its handle underneath means the hinge readies with no
	# children, hooks nothing, and the grab is silently dead — every node
	# present, every layer right, the signal simply never connected.
	var body := Node3D.new()
	body.name = "Bicho"
	body.transform = root_x
	_build_plate(body, 0, n, w, d, sheet, steel)
	add_child(body)

	if show_caption:
		_build_caption(root_x, n, w, d)

	# And THEN unhook what that same walk over-collected. _hook_child_handles
	# recurses into every descendant, so a hinge two levels up also subscribes to
	# this hinge's handle: one grab would drive four joints at once, each
	# applying its own offset to a frame the others are moving. XR Tools was
	# written for a door and a lever, never for a chain.
	call_deferred("_prune_hooks")


## The root plate stands ON EDGE, face toward +Z, and that is three decisions at
## once.
##
## FACING: this corpus presents +Z and photographs from there. A plate lying flat
## on the plinth shows the camera its 3 mm edge and a foreshortened sliver;
## standing it up gives the still a face to read.
##
## REACH: with the root vertical, its side hinges are VERTICAL lines, so the
## wings swing in a horizontal plane and cannot descend into the plinth at all.
## Only grandchildren can go down. Measured, 6 plates, 4000 draws: a vertical
## root passes 51% of draws at `open` against 20% for a flat root with the plinth
## pushed back, and 61% against 0.2% at `tight` — the flat mount could not find a
## tight pose in 400 attempts for any seed.
##
## SIGN: the basis maps the plate's own +Y (its face normal) to world +Z and its
## +Z (out from the mating edge) to world +Y. That is a 180° turn about
## (0,1,1)/√2, right-handed, determinant +1 — NOT the mirror it looks like. It
## also puts positive hinge angles folding toward the visitor, which matters
## because the spine band is asymmetric and most of it is positive.
func _root_frame(ph: float) -> Transform3D:
	var b := Basis(Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 0))
	return Transform3D(b, Vector3(0.0, ph + ROOT_LIFT, 0.0))


## A museum plinth: one chamfered box, plus a bracket at the root plate's foot.
## PBR.box chamfers every edge, which is the whole reason it is here — a plain
## BoxMesh plinth loses its edges to the background in a grey hall.
func _build_plinth(ph: float, w: float, steel: StandardMaterial3D) -> void:
	var pw: float = w * PLINTH_RATIO * 2.0
	var node := Node3D.new()
	node.name = "Plinth"
	add_child(node)

	var paint := PBR.rams_body(Color(0.855, 0.850, 0.835), 0.10)
	var column: MeshInstance3D = PBR.box(
		Vector3(0.0, ph * 0.5, 0.0), Vector3(pw, ph, pw), paint, 0.006)
	column.name = "Column"
	node.add_child(column)

	# The plinth is a thing you cannot walk through. Default layer, like
	# composition_platform's — no mask games, it is furniture.
	var solid := StaticBody3D.new()
	solid.name = "Solid"
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(pw, ph, pw)
	cs.shape = shape
	cs.position = Vector3(0.0, ph * 0.5, 0.0)
	solid.add_child(cs)
	node.add_child(solid)

	# The bracket. A 3 mm sheet standing unaided on a plinth reads as a bug; this
	# is the two-piece clamp that would actually be holding it.
	var jaw: float = w * 0.30
	var bracket: MeshInstance3D = PBR.box(
		Vector3(0.0, ph + ROOT_LIFT * 0.5, 0.0),
		Vector3(jaw, ROOT_LIFT + 0.012, 0.030), steel, 0.003)
	bracket.name = "Bracket"
	node.add_child(bracket)


## One plate, its collider, and a hinge mount per outgoing link. Recursive.
func _build_plate(parent: Node3D, idx: int, n: int, w: float, d: float,
		sheet: StandardMaterial3D, steel: StandardMaterial3D) -> void:
	var plate := Node3D.new()
	plate.name = "Plate_%d" % idx
	parent.add_child(plate)

	var mi: MeshInstance3D = PBR.box(
		Vector3(0.0, 0.0, d * 0.5), Vector3(w, PLATE_T, d), sheet, 0.0012)
	mi.name = "Sheet"
	plate.add_child(mi)

	# RULE: THE COLLIDER IS WHERE THE THING IS. Same box, same centre, same
	# extents as the sheet above it — the chamfer takes 1.2 mm off the corners
	# and nothing else, and the node carries no scale, so the shape IS the
	# silhouette. WORLD_LAYER makes it a real object a hand can rest on;
	# HANDLE_LAYER puts it in DesktopInteractionPointer's raycast mask so the
	# crosshair finds it even when the XR Tools addon is absent.
	var solid := StaticBody3D.new()
	solid.name = "Solid"
	solid.collision_layer = WORLD_LAYER | HANDLE_LAYER
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(w, PLATE_T, d)
	cs.shape = box
	cs.position = Vector3(0.0, 0.0, d * 0.5)
	solid.add_child(cs)
	plate.add_child(solid)

	for i in range(n - 1):
		if int(LINKS[i][0]) != idx:
			continue
		_build_hinge(plate, i, str(LINKS[i][1]), n, w, d, sheet, steel)


## A hinge: an unrotated MOUNT carrying the edge frame, a rotating HINGE inside
## it at the origin, a piano barrel, a grab handle, and the child plate.
##
## The split is forced, not stylistic. XRToolsInteractableHinge._ready() assigns
## `transform = Transform3D(basis_from_angle, Vector3.ZERO)` — it ZEROES its own
## origin. A hinge node that also carried the edge position would silently jump
## to its parent's origin on the first frame. VRAudioControlDial.tscn does the
## same split (DialOrigin > InteractableHinge) and this is why.
func _build_hinge(parent: Node3D, i: int, kind: String, n: int, w: float,
		d: float, sheet: StandardMaterial3D, steel: StandardMaterial3D) -> void:
	var mount := Node3D.new()
	mount.name = "Mount_%d" % (i + 1)
	mount.transform = _edge_frame(kind, w, d)
	parent.add_child(mount)

	var hinge := Node3D.new()
	hinge.name = "Hinge_%d" % (i + 1)
	var lim: Vector2 = _limits[i]
	var script: Script = _addon(HINGE_SCRIPT)
	if script:
		hinge.set_script(script)
		# LIMITS BEFORE POSITION, and both as FLOATS. _set_hinge_position clamps
		# against _hinge_limit_*_rad, which are @onready and therefore 0/0 until
		# the node enters the tree — setting the angle first would clamp it to
		# zero and the object would build flat with every value looking right in
		# the inspector. And Object.set() on a typed float property with an int
		# is refused in SILENCE, which is how another artifact in this repo
		# published sixteen identical frames.
		hinge.set("hinge_limit_min", float(lim.x))
		hinge.set("hinge_limit_max", float(lim.y))
		hinge.set("hinge_steps", 0.0)
		# NO RETURN. default_on_release false is the artifact: a released plate
		# stays where it was let go. Clark's objection to sculpture was exactly
		# that it has a pose to be restored to.
		hinge.set("default_on_release", false)
		hinge.set("hinge_position", float(_angles[i]))
		if hinge.has_signal("hinge_moved"):
			hinge.connect("hinge_moved", Callable(self, "_on_hinge_moved").bind(i))
		if hinge.has_signal("released"):
			hinge.connect("released", Callable(self, "_on_hinge_released"))
	else:
		hinge.rotation.x = deg_to_rad(_angles[i])
	mount.add_child(hinge)
	_hinges[i] = hinge
	_mounts[i] = mount

	# The barrel. One piano hinge along the mating edge rather than two end
	# knuckles: it is one mesh instead of two, it reads unmistakably as a JOINT
	# from any of the four capture angles, and at 7 mm radius on a 3 mm plate it
	# is proud of the sheet on both faces the way a real one is. It hangs off the
	# MOUNT, not the hinge, because a knuckle belongs to both plates.
	var r: float = maxf(PLATE_T * 2.2, w * 0.027)
	var barrel: MeshInstance3D = PBR.pipe(
		Vector3(-w * 0.5 + r, 0.0, 0.0), Vector3(w * 0.5 - r, 0.0, 0.0), r, steel, 12)
	barrel.name = "Barrel"
	mount.add_child(barrel)

	_build_handle(hinge, i, w, d)
	_build_plate(hinge, i + 1, n, w, d, sheet, steel)


## The VR grab volume: the child plate's own outline, thickened.
##
## A 3 mm sheet is not catchable — a hand moving at speed passes through it
## between physics ticks, which is the pink_gun failure with the numbers
## reversed. So the grab box is the plate's width and depth exactly, and 5 cm
## thick. That is a deliberate departure from "the collider is where the thing
## is" in one axis only, and the departure is why: the visible plate keeps its
## own exact collider (above) for everything that touches it; this second, thicker
## volume exists only on the handle layer, only to be grabbed.
func _build_handle(hinge: Node3D, i: int, w: float, d: float) -> void:
	var script: Script = _addon(HANDLE_SCRIPT)
	if script == null:
		_handles[i] = null
		return

	var holder := Node3D.new()
	holder.name = "Handles"
	hinge.add_child(holder)

	# XRToolsInteractableHandle snaps back to its PARENT's transform and warns if
	# it carries any transform of its own, so the placement lives on the origin
	# node and the body sits at identity inside it.
	var origin := Node3D.new()
	origin.name = "Origin"
	origin.position = Vector3(0.0, 0.0, d * 0.5)
	holder.add_child(origin)

	var body := RigidBody3D.new()
	body.name = "Handle"
	body.collision_layer = HANDLE_LAYER
	body.collision_mask = 0
	body.gravity_scale = 0.0
	body.freeze = true
	body.set_script(script)
	body.set("picked_up_layer", 0)
	# Farther than this from its rest point and the handle lets go by itself.
	# One plate-depth: past that the hand has stopped turning the joint and
	# started trying to take the plate off.
	body.set("snap_distance", float(maxf(d, 0.12)))
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(w, 0.05, d)
	cs.shape = box
	body.add_child(cs)
	origin.add_child(body)
	_handles[i] = body


## The caption stands BESIDE the object on its own post, clear of the swing.
##
## The obvious place was the plinth's front face, and it was measured and
## rejected: the plinth is 0.24 m wide, which forces a 0.22 m screen, which puts
## the body glyphs at 0.026 m — under text_screen's own MIN_GLYPH_M of 0.035.
## The component would have been shipping text it declares illegible. On a post
## the screen is 0.40 m wide with 0.048 m glyphs, at 1.05 m, where a museum label
## goes.
##
## ITS X IS DERIVED FROM THE SOLVED POSE, not typed. The object's reach changes
## with the seed, the count and the swing; a fixed offset would put the label
## behind a plate for some of them.
##
## AND IT IS NOT ROTATED. text_screen presents +Z and so does this corpus; an
## artifact that turns its text with rotation.y = PI aims that text into its own
## panel and photographs bare, which cost this project seven captures.
func _build_caption(root_x: Transform3D, n: int, w: float, d: float) -> void:
	var far_x: float = 0.0
	var frames: Array[Transform3D] = _solve(root_x, _angles, n, w, d)
	for f in frames:
		for p in _samples(w, d):
			far_x = maxf(far_x, (f * p).x)

	# EVERY TextScreen PROPERTY GOES THROUGH set(). `_caption` is declared
	# Node3D, and Node3D has no `mode`, `width_m` or `title` — a direct
	# assignment on a statically typed base is a parse error, not a warning, and
	# a parse error in an artifact is an artifact that never loads. `mode` is an
	# enum, so it takes the INT 1 (STAND) and not the string "STAND": set() on a
	# typed property of the wrong type is refused in silence.
	_caption = TextScreenScript.new()
	_caption.name = "Caption"
	_caption.set("mode", 1)                    # STAND — screen on a post, foot at y=0
	_caption.set("width_m", 0.40)
	_caption.set("stand_height", 1.05)
	_caption.set("title", "CONFIGURATION")
	_caption.set("body", _caption_body())
	_caption.position = Vector3(far_x + 0.10 + 0.22, 0.0, 0.0)
	add_child(_caption)


## What the plate says. Angles first because they are the configuration; the stop
## count second because it is the claim about limits; "no home pose" third
## because it is the claim about Clark.
##
## THE ANGLES ARE READ BACK FROM THE JOINTS, never from the search. If the addon
## clamped one differently, or a visitor moved it, the plate says what the object
## is, not what it was asked to be.
func _caption_body() -> String:
	var parts := PackedStringArray()
	for a in _angles:
		parts.append("%d" % roundi(a))
	var lines := PackedStringArray()
	var cur: String = ""
	for p in parts:
		var nxt: String = p if cur == "" else cur + " " + p
		if nxt.length() > 20 and cur != "":
			lines.append(cur)
			cur = p
		else:
			cur = nxt
	if cur != "":
		lines.append(cur)
	lines.append("%d of %d at a stop" % [_stops(), _angles.size()])
	lines.append("no home pose")
	return "\n".join(lines)


## Hinges sitting on one of their limits. Half a degree of tolerance because the
## search snaps one hinge exactly onto a stop and everything else lands wherever
## the sequence put it.
func _stops() -> int:
	var n: int = 0
	for i in range(_angles.size()):
		var lim: Vector2 = _limits[i]
		if absf(_angles[i] - lim.x) <= 0.5 or absf(_angles[i] - lim.y) <= 0.5:
			n += 1
	return n


# ══ THE POSE ═════════════════════════════════════════════════════════════════

## Search for an opening configuration. Not a random pose — a pose that passes.
##
## Five tests, and three of them are geometry rather than taste:
##   spread/bend  the angles must use a real fraction of what the joints allow,
##                and must go both ways. Stated as FRACTIONS of the band so the
##                same test means the same thing at tight and at free.
##   floor        no plate below FLOOR_CLEAR.
##   plinth       no plate inside the plinth. This is the one that does the work
##                — it rejects 0% of draws at tight, 17.73% at open and 68.75% at
##                free, which is the artifact's headline measurement.
##   standing     something must reach STAND_LINKS of a link above the plinth
##                top, or the still is of a folded stack. Proportional, because
##                the flat 0.20 m it replaced was unreachable at small plate
##                widths and quietly shipped the flat fallback there.
##
## FAILURE IS FLAT, not an error. All-zero is coplanar and always legal, and it
## is the one pose this object has that means nothing — the right thing to show
## if the search ever comes up empty. Measured over 600 seed × count × swing
## combinations: it never has, worst case attempt 26 of 240.
##
## THAT SWEEP HELD plate_w AT ITS DEFAULT, and that is how the standing bar shipped
## unreachable. A second sweep that varied it — swing × plate_w × plate_count ×
## plinth_height, 300 combinations across the whole clamp range — found 30 that
## failed every attempt and shipped the flat pose, all of them at plate_w 0.08.
## See STAND_LINKS. A parameter a sweep holds constant is a parameter the sweep
## does not test.
func _search(root_x: Transform3D, n: int, w: float, d: float, ph: float) -> Array:
	var hinges: int = n - 1
	var lo_all: float = INF
	var hi_all: float = -INF
	for lim in _limits:
		lo_all = minf(lo_all, lim.x)
		hi_all = maxf(hi_all, lim.y)
	var rng: float = maxf(hi_all - lo_all, 1.0)
	var half: float = w * PLINTH_RATIO
	var samp: Array[Vector3] = _samples(w, d)
	# One link's reach — the object's own unit, so the standing bar means the
	# same thing at 0.08 m and at 0.60 m. See STAND_LINKS.
	var stand: float = ph + STAND_LINKS * sqrt(d * d + (w * 0.5) * (w * 0.5))

	for k in range(GUARD):
		var a: Array = _draw(k, hinges)
		var amin: float = float(a[0])
		var amax: float = float(a[0])
		for v in a:
			amin = minf(amin, float(v))
			amax = maxf(amax, float(v))
		if amax - amin < 0.40 * rng:
			continue
		if amin > lo_all + 0.25 * rng or amax < hi_all - 0.35 * rng:
			continue

		var frames: Array[Transform3D] = _solve(root_x, a, n, w, d)
		var min_y: float = INF
		var max_y: float = -INF
		var clash: bool = false
		for f in frames:
			for s in samp:
				var p: Vector3 = f * s
				min_y = minf(min_y, p.y)
				max_y = maxf(max_y, p.y)
				if absf(p.x) < half and absf(p.z) < half and p.y < ph - SINK:
					clash = true
		if clash or min_y < FLOOR_CLEAR or max_y < stand:
			continue
		return a

	push_warning("bicho_hinge: no configuration passed in %d attempts at seed %d; opening flat" % [GUARD, pose_seed])
	var flat: Array = []
	for i in range(hinges):
		flat.append(clampf(0.0, _limits[i].x, _limits[i].y))
	return flat


## Attempt k of the seed's sequence. Each hinge reads a different irrational
## stride, so the five angles are spread and uncorrelated without any of them
## being random; seeds are STRIDE apart, which is more than GUARD, so no two
## seeds can walk into each other's draws.
##
## Then ONE hinge is snapped exactly onto a stop. Not decoration: the caption
## claims a count of hinges at their limits, and a claim that reads zero in the
## shipped still is a claim nobody can check.
func _draw(k: int, hinges: int) -> Array:
	var t: float = float(pose_seed) * STRIDE + float(k) + 1.0
	var out: Array = []
	for i in range(hinges):
		var u: float = fmod(t * float(ALPHA[i % ALPHA.size()]), 1.0)
		var lim: Vector2 = _limits[i]
		out.append(lim.x + u * (lim.y - lim.x))
	var j: int = posmod(pose_seed * 7 + k, hinges)
	var lj: Vector2 = _limits[j]
	out[j] = lj.y if float(out[j]) > (lj.x + lj.y) * 0.5 else lj.x
	return out


## Forward kinematics. Frame 0 is the root; every other frame is its parent's,
## times the edge it hangs from, times its own hinge rotation. Composition order
## is the artifact's second claim and it is written here in one line.
func _solve(root_x: Transform3D, a: Array, n: int, w: float, d: float) -> Array[Transform3D]:
	var out: Array[Transform3D] = [root_x]
	for i in range(1, n):
		var parent: int = int(LINKS[i - 1][0])
		var kind: String = str(LINKS[i - 1][1])
		var m: Transform3D = out[parent] * _edge_frame(kind, w, d)
		out.append(m * Transform3D(Basis(Vector3.RIGHT, deg_to_rad(float(a[i - 1]))), Vector3.ZERO))
	return out


## Where a child hangs off its parent, and which way is up for it.
##
## A plate spans x ∈ [-w/2, w/2], z ∈ [0, d] with its thickness on y, so its
## mating edge is z = 0 and its three free edges are far (z = d), right (x = w/2)
## and left (x = -w/2). Every frame here puts the hinge axis on local X and the
## child's out-direction on local +Z, because XRToolsInteractableHinge rotates
## about its local X and nothing else. All three keep +Y as up, so a positive
## angle means the same fold on every joint in the tree.
##
## The hinge is CENTRED on its parent's edge. Where the child's mating edge is
## longer than the edge it hangs from — a w-wide plate on a d-deep side edge —
## it overhangs equally at both ends, which is what the aluminium does and what
## makes six identical plates read as an irregular body.
func _edge_frame(kind: String, w: float, d: float) -> Transform3D:
	match kind:
		"right":
			return Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(w * 0.5, 0.0, d * 0.5))
		"left":
			return Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(-w * 0.5, 0.0, d * 0.5))
		_:
			return Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, d))


## Eighteen points per plate: three across, three along, both faces. Corners
## alone let a plate slice a plinth corner with every corner outside it, and the
## plinth test is the one carrying the whole reachability claim.
func _samples(w: float, d: float) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var across: PackedFloat32Array = [-0.5, 0.0, 0.5]
	var along: PackedFloat32Array = [0.0, 0.5, 1.0]
	var face: PackedFloat32Array = [-0.5, 0.5]
	for sx in across:
		for sz in along:
			for sy in face:
				out.append(Vector3(sx * w, sy * PLATE_T, sz * d))
	return out


# ══ ARTICULATION ═════════════════════════════════════════════════════════════

## Turn one hinge. The only way anything in this file moves.
func set_hinge(i: int, degrees: float) -> void:
	if i < 0 or i >= _hinges.size():
		return
	var lim: Vector2 = _limits[i]
	var v: float = clampf(degrees, lim.x, lim.y)
	_angles[i] = v
	var h: Node = _hinges[i]
	if h == null or not is_instance_valid(h):
		return
	if h.has_method("move_hinge"):
		# The addon path. move_hinge takes RADIANS, clamps again against the same
		# limits, and emits hinge_moved in DEGREES — which lands back in
		# _angles[i] through _on_hinge_moved. Writing it twice is deliberate: if
		# the addon ever clamps differently from this file, the caption reports
		# the joint and not the request.
		h.call("move_hinge", deg_to_rad(v))
		return
	var n3: Node3D = h as Node3D
	if n3:
		n3.rotation.x = deg_to_rad(v)


## Read back. Degrees, parent-relative, in LINK order — which is not the order
## the nodes were built in. See the resize in _build().
func hinge_angles() -> Array:
	return _angles.duplicate()


func _on_hinge_moved(degrees: float, i: int) -> void:
	if i >= 0 and i < _angles.size():
		_angles[i] = degrees


## THE PLATE UPDATES ON RELEASE, NOT PER FRAME. text_screen rebuilds by baking
## text into a new albedo texture; doing that while a joint is turning is a fresh
## ImageTexture every frame for as long as the hand is on it, which is the leak
## data_labor_counter documents and works around. Updating on release also says
## the truer thing: the plate records where you left it.
func _on_hinge_released(_who = null) -> void:
	_refresh_caption()


func _refresh_caption() -> void:
	if _caption and is_instance_valid(_caption):
		_caption.set("body", _caption_body())


## Unhook the handles a hinge collected from below it. See _build().
func _prune_hooks() -> void:
	for i in range(_hinges.size()):
		var h: Node = _hinges[i]
		if h == null or not is_instance_valid(h) or not h.has_method("_on_handle_picked_up"):
			continue
		var mine: Node = _handles[i] if i < _handles.size() else null
		var up := Callable(h, "_on_handle_picked_up")
		var down := Callable(h, "_on_handle_dropped")
		for j in range(_handles.size()):
			var hd: Node = _handles[j]
			if hd == null or not is_instance_valid(hd) or hd == mine:
				continue
			if hd.is_connected("picked_up", up):
				hd.disconnect("picked_up", up)
			if hd.is_connected("dropped", down):
				hd.disconnect("dropped", down)


# ══ THE DESKTOP LANE ═════════════════════════════════════════════════════════

## DesktopInteractionPointer raycasts the crosshair on layers 19 + 21 and walks
## UP from whatever it hits looking for the first ancestor with a `pointer_event`
## method — which, above a plate collider or an XR handle, is this root. So one
## handler serves the whole tree, and the press has to work out which joint the
## visitor meant.
##
## Untested: Godot could not be run this session. It is written so that a wrong
## guess costs a drag that does not track, never an error — every lookup is
## guarded and the model is only ever changed through set_hinge, which clamps.
func pointer_event(event) -> void:
	if event == null:
		return
	var kind: int = int(event.get("event_type"))
	var at: Vector3 = event.get("position")
	match kind:
		2:      # PRESSED
			_drag = _nearest_hinge(at)
			if _drag >= 0:
				_drag_bias = _angles[_drag] - _point_angle(_drag, at)
		4:      # MOVED
			if _drag >= 0:
				set_hinge(_drag, _point_angle(_drag, at) + _drag_bias)
		3, 1:   # RELEASED, EXITED
			if _drag >= 0:
				_drag = -1
				_refresh_caption()


## Which joint is the visitor holding? The one whose CHILD PLATE CENTRE is
## nearest the hit — not the nearest hinge axis, which would hand a grab at the
## far tip of a plate to the joint at its root.
func _nearest_hinge(at: Vector3) -> int:
	var best: int = -1
	var best_d: float = INF
	var d: float = clampf(plate_w, 0.08, 0.60) * DEPTH_RATIO
	for i in range(_hinges.size()):
		var h: Node = _hinges[i]
		if h == null or not is_instance_valid(h) or not (h is Node3D):
			continue
		var c: Vector3 = (h as Node3D).global_transform * Vector3(0.0, 0.0, d * 0.5)
		var dist: float = c.distance_squared_to(at)
		if dist < best_d:
			best_d = dist
			best = i
	return best


## The angle of a world point around hinge i, measured in the MOUNT's frame —
## the unrotated one. Measuring in the hinge's own frame would fold the joint's
## current angle into the reading and the drag would accelerate away from the
## cursor.
func _point_angle(i: int, at: Vector3) -> float:
	if i < 0 or i >= _mounts.size():
		return 0.0
	var m: Node3D = _mounts[i]
	if m == null or not is_instance_valid(m):
		return 0.0
	var p: Vector3 = m.global_transform.affine_inverse() * at
	return rad_to_deg(atan2(p.y, p.z))


# ══ CONFIG ═══════════════════════════════════════════════════════════════════

## Per-cell configuration from a map token. Keys honoured:
##
##   #count:6              plates, 4-7
##   #mode:open            reachable set — tight | open | free
##   #generation_seed:0    which accident
##   #size:0.26            plate width, metres
##   #height:0.82          plinth height, metres
##   #screen:false         hide the caption plate
##
## EVERY NUMERIC KEY ABOVE IS IN CONFIG_PARAM_NAMES (GridInteractablesComponent
## .gd:16). That list is not decoration: line 1705 reads `#key:<number>` on an
## unlisted key as the tutorial's positional shorthand, so a friendlier
## `#seed:7` would become a 7-degree rotation and this artifact would keep its
## default while looking configured. `generation_seed` is on the list and `seed`
## is not, so `generation_seed` is the name.
##
## `swing` is reached as `#mode:` for the same reason in reverse — the value is a
## WORD, which is always safe, and `mode` is on the list anyway. And `#screen:`
## must take true/false rather than 1/0: a bare numeric on an unlisted key is
## eaten as a rotation, and the word arrives as the STRING "false", for which
## bool() returns TRUE. Hence _flag().
##
## THE PROPERTY-NAME ALIASES BELOW ARE THE OTHER HALF OF THAT TRAP, and they were
## the one thing here that could ship a wrong number. `plate_w`, `plinth_height`
## and `pose_seed` are NOT on the list, so `#plate_w:0.3` never arrives as a pair:
## the shorthand branch stores `config_data["plate_w"] = true` and puts 0.3 in the
## artifact's yaw. `float(true)` is 1.0, which clamps to 0.60 — the plate more
## than DOUBLES while the map file reads 0.3. A bare `#count` lands as `true` the
## same way and read back as 0, i.e. four plates. They are kept, because
## apply_grid_config is also called by benches that pass the real property names
## with real typed values, and _num() makes the mangled form inert instead of
## wrong. Only #size / #height / #generation_seed / #count are safe from a TOKEN.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("count"):
		plate_count = clampi(int(_num(config_data["count"], float(plate_count))), 4, 7)
	for k in ["mode", "swing"]:
		# A bool here is the shorthand branch's `true`, not a swing name; taking
		# it would write "true" into the export and warn on every rebuild.
		if config_data.has(k) and typeof(config_data[k]) != TYPE_BOOL:
			swing = str(config_data[k]).strip_edges().to_lower()
	for k in ["generation_seed", "pose_seed"]:
		if config_data.has(k):
			pose_seed = int(_num(config_data[k], float(pose_seed)))
	for k in ["size", "plate_w"]:
		if config_data.has(k):
			plate_w = clampf(_num(config_data[k], plate_w), 0.08, 0.60)
	for k in ["height", "plinth_height"]:
		if config_data.has(k):
			plinth_height = clampf(_num(config_data[k], plinth_height), 0.20, 1.40)
	for k in ["screen", "caption", "show_caption"]:
		if config_data.has(k):
			show_caption = _flag(config_data[k])
	if is_inside_tree():
		_build()


func _swing_name() -> String:
	var s: String = swing.strip_edges().to_lower()
	if SWINGS.has(s):
		return s
	push_warning("bicho_hinge: swing '%s' is not tight/open/free; using open" % swing)
	return "open"


## Hinge limits in degrees for one joint. A function rather than a const
## Dictionary of Vector2s: the limits are two lines either way, and a nested
## const container is the sort of thing that parses on one Godot build and not
## the next.
##
## The spine band is ASYMMETRIC and the wing band is not, because that is what
## the object is. A Bicho's spine folds nearly shut one way — the plates come
## face to face — and barely opens past flat the other. A side hinge has no such
## preference; it is the same joint in both directions.
func _band(mode: String, kind: String) -> Vector2:
	match mode:
		"tight":
			return Vector2(-10.0, 100.0) if kind == "far" else Vector2(-40.0, 40.0)
		"free":
			return Vector2(-170.0, 170.0)
		_:
			return Vector2(-15.0, 165.0) if kind == "far" else Vector2(-95.0, 95.0)


## A config value that is actually a NUMBER, or the knob keeps what it had.
##
## The bool case is the one that matters and it is not defensive dressing: the
## grid's shorthand branch turns `#plate_w:0.3` into `plate_w = true`, and
## `float(true)` is 1.0 — a number, wrong, and silent. `str(true).to_float()` is
## 0.0, wrong the other way. Refusing both leaves the default standing, which is
## a fact a reader can see in the still. This is `#levels:4` with the lesson
## applied.
func _num(v, fallback: float) -> float:
	var t: int = typeof(v)
	if t == TYPE_FLOAT or t == TYPE_INT:
		return float(v)
	if t == TYPE_BOOL:
		return fallback
	var s: String = str(v).strip_edges()
	return s.to_float() if s.is_valid_float() else fallback


## Config values arrive as strings, and bool("0") and bool("false") are both
## true. eleven_dots and fetish_portal carry the same helper for the same reason.
func _flag(v) -> bool:
	if typeof(v) == TYPE_BOOL:
		return bool(v)
	return str(v).strip_edges().to_lower() in ["true", "1", "yes", "on"]


## Load one of the two XR Tools scripts, or nothing. ResourceLoader.exists first,
## because /addons is gitignored here and a preload of a missing path is a hard
## parse failure rather than a null.
func _addon(path: String) -> Script:
	if not ResourceLoader.exists(path):
		return null
	var res: Resource = load(path)
	return res as Script
