extends Node3D
class_name ApproachScale

# @identity
# essence: a field of blocks packed too close to walk between, which shrink around whoever comes near until there is a way through
# desire: the visitor stops reading the room's size as a fact and starts reading it as a relation to their own body
# critical_parameter: min_scale — how much room your arrival is worth
# triggers: any player body or museum walker inside the field's Area3D; continuous, by distance, not by a switch
# emerges: a wall of obstacles becomes a corridor that follows you and closes behind you
# needs: nothing outside itself — no manager, no map data, no provider
# relationships: the third of the three body-operated transformations; carve_grid removes what you touch, approach_wall opens what you face, this one shrinks what you stand among
# truth: a room is only as big as the nearest body makes it
#
## 2026-09-08, Palle: "The same with scaling scale down around us so we can walk."
##
## THE VISITOR'S BODY IS THE TRANSFORMATION. In the rest of this chapter a cube is
## translated, turned or scaled while you watch it happen: the operator is the
## artifact and you are the audience. Here the operator is you. The blocks hold a
## scale that is a function of your distance and nothing else, so walking forward
## is the scale operation and standing still is the identity. The room's size is
## measured in how close you are standing.
##
## It is also the chapter's standing ruling — "transformation creates empty space.
## The holes are the pathway" — taken one step past where the map can follow. The
## hole is not authored into the structure layer. You make it by arriving.
##
## THE ARITHMETIC IS THE ARGUMENT, so it must not be fudged. At rest the gap
## between neighbours is spacing_m - block_m = 1.50 - 1.15 = 0.35 m, and a shoulder
## is 0.52 m, so the field is genuinely shut: not "tight", shut. At min_scale a
## block is 0.34 * 1.15 = 0.39 m and the gap is 1.11 m, which is a doorway. The
## factor that first clears a shoulder is (spacing_m - SHOULDER_M) / block_m =
## 0.852. If you retune the exports and that number lands above 1.0 or below
## min_scale, the artifact can never open and says so on `rigid`.
##
## IT MASKS LAYER 1 AS WELL AS LAYER 20, AND THAT IS WHAT MAKES IT WORK IN THE
## MUSEUM. The endless museum's walker is a bare CharacterBody3D named "Walker" on
## collision layer 1, in group `em_walker` and nothing else: not in any grid player
## group, no XROrigin3D above it, not on layer 20. An Area3D masking the player
## layer alone overlaps it never, with no error and no log line, and the artifact
## simply stands there being furniture. This masks 1 | 524288 and reads positions
## out of one Area3D, so the VR player, the desktop player and the walker all move
## the same blocks.
##
## THE COST OF THAT: our own blocks are solid bodies on collision_layer 1 — the
## walker's layer, which is also every body's default. An area masking layer 1
## therefore picks up its own furniture, and every block would measure a visitor
## standing exactly at its own centre: the whole field collapses to min_scale on
## the first frame and looks, from the outside, like the artifact working
## perfectly. Moving the blocks off layer 1 would make them non-solid world
## geometry, so instead they stay and are refused by ANCESTRY in `_is_visitor` —
## they are our own descendants and nothing else in the hall is. carve_grid and
## approach_wall each met this independently; any artifact that builds bodies and
## masks layer 1 has it.
##
## SCALE THE SHAPE, NOT THE NODE. Each block sets BoxMesh.size and BoxShape3D.size
## and keeps scale at 1. Godot warns about non-uniformly scaled collision shapes
## and a scaled node's shape does not reliably follow into the physics server, so a
## block scaled the lazy way would look shrunk and still block you — which is the
## exact failure this artifact would be least able to notice. Each block also gets
## its OWN BoxShape3D and BoxMesh: shapes are Resources, and one shared instance
## would resize all nine blocks at once, which is the bug this design invites.

const PLAYER_LAYER := 524288          # physics layer 20 — the grid's player body
const WALKER_LAYER := 1               # physics layer 1  — the museum's Walker
## A body's width at the shoulder. What "wide enough to pass" means, in metres.
const SHOULDER_M := 0.52
## Visitors are re-read at 12 Hz rather than every frame. get_overlapping_bodies()
## allocates an Array per call and this ships to a Quest; ease_s smooths over the
## gap so nothing visible is lost.
const POLL_S := 0.08
## How long a visitor stands inside reach before an unmoving field is a complaint.
const RIGID_AFTER_S := 3.5

## How many blocks actually get built, laid out row-major across the grid below.
## Fewer than cols * rows leaves the tail cells empty, which is a hole authored
## into the field rather than made by walking; more than that is clamped.
@export var blocks: int = 9
## How wide the field stands, in blocks, running left to right across the room.
@export var cols: int = 3
## How deep it stands, in blocks, running away from you.
@export var rows: int = 3
## Distance between neighbouring block centres, metres. With block_m this fixes
## the gap at rest, and the gap at rest is the whole premise.
@export var spacing_m: float = 1.5
## The side of one block at full size, metres. It stands on the floor, so this is
## also how tall it is.
@export var block_m: float = 1.15
## The smallest a block gets when you are standing on top of it. 0.34 turns a
## 0.35 m gap into a 1.11 m one.
@export var min_scale: float = 0.34
## How far away you start to matter, metres. Beyond this a block is at full size
## and does not care that you exist.
@export var reach_m: float = 2.2
## Seconds for a block to reach the size your distance asks for. It is a breath,
## not a snap; too long and you walk into a block that has not finished moving.
@export var ease_s: float = 0.28
## The colour of a block at rest. It brightens as it gives way and returns to this
## when it is full size again, so the field's state is readable at a glance.
@export var block_color: Color = Color(0.42, 0.46, 0.55)

## The narrowest gap near a visitor first became wider than a shoulder.
signal passage_opened()
## It closed again — you walked out of reach, or through.
signal passage_closed()
## A visitor stood inside reach_m for RIGID_AFTER_S and never got a way through.
## Said out loud because a field that looks alive and cannot actually be walked is
## the bug this artifact is most likely to have, and it has four different causes
## that all look identical from a screenshot.
signal rigid(why: String)

var _field: Node3D
var _area: Area3D
var _count := 0

# Parallel per-block state. Built once, written in place, never reallocated.
var _bodies: Array[AnimatableBody3D] = []
var _meshes: Array[BoxMesh] = []
var _shapes: Array[BoxShape3D] = []
var _mats: Array[StandardMaterial3D] = []
var _centres := PackedVector3Array()   # y is zeroed: distance is measured on the floor
var _factor := PackedFloat32Array()    # what the block is now
var _shown := PackedFloat32Array()     # what was last written to mesh and shape
var _dist2 := PackedFloat32Array()     # squared floor distance to the nearest visitor

var _visitors := PackedVector3Array()  # floor positions, refreshed at POLL_S
var _own := {}                         # instance ids of our own blocks — see the header
var _poll := 0.0
var _near_s := 0.0
var _open := false
var _ever_open := false
var _rigid_said := false
var _local_gap := 0.0


func _ready() -> void:
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("blocks"):
		blocks = int(config_data["blocks"])
	if config_data.has("cols"):
		cols = int(config_data["cols"])
	if config_data.has("rows"):
		rows = int(config_data["rows"])
	if config_data.has("spacing"):
		spacing_m = float(config_data["spacing"])
	if config_data.has("block"):
		block_m = float(config_data["block"])
	if config_data.has("min_scale"):
		min_scale = float(config_data["min_scale"])
	if config_data.has("reach"):
		reach_m = float(config_data["reach"])
	if config_data.has("ease"):
		ease_s = float(config_data["ease"])
	if config_data.has("color"):
		var c: Variant = config_data["color"]
		if c is Color:
			block_color = c
		elif typeof(c) == TYPE_STRING and Color.html_is_valid(str(c)):
			block_color = Color.html(str(c))
	if is_inside_tree():
		_build()


func _build() -> void:
	for c in get_children():
		c.queue_free()
	_bodies.clear()
	_meshes.clear()
	_shapes.clear()
	_mats.clear()
	_own.clear()
	_open = false
	_ever_open = false
	_rigid_said = false
	_near_s = 0.0

	cols = maxi(1, cols)
	rows = maxi(1, rows)
	_count = clampi(blocks, 0, cols * rows)
	# THE ARITHMETIC IN THE HEADER IS THE ARGUMENT, so a map is not allowed to break
	# it silently. block_m above spacing_m is a field with no gaps at all — solid at
	# rest and still solid when shrunk, which reads as a wall somebody forgot to
	# finish. reach_m at 0 is a field that can never be asked for anything.
	spacing_m = maxf(spacing_m, 0.1)
	block_m = clampf(block_m, 0.05, spacing_m)
	min_scale = clampf(min_scale, 0.02, 1.0)
	reach_m = maxf(reach_m, 0.0)
	ease_s = maxf(ease_s, 0.0)
	_centres.resize(_count)
	_factor.resize(_count)
	_shown.resize(_count)
	_dist2.resize(_count)

	_field = Node3D.new()
	_field.name = "Field"
	add_child(_field)

	var base := StandardMaterial3D.new()
	base.albedo_color = block_color
	base.roughness = 0.62
	base.emission_enabled = true
	base.emission = block_color.lightened(0.45)
	base.emission_energy_multiplier = 0.0

	for i in _count:
		var c: int = i % cols
		@warning_ignore("integer_division")
		var r: int = i / cols
		var centre := Vector3(
			(float(c) - float(cols - 1) * 0.5) * spacing_m,
			0.0,
			(float(r) - float(rows - 1) * 0.5) * spacing_m)
		_centres[i] = centre
		_factor[i] = 1.0
		_dist2[i] = INF         # nobody has arrived yet, so nothing is asked of it

		# ANIMATABLE, NOT STATIC, and the difference is the visitor's ankles.
		# _apply_size re-seats this body every physics frame so its base stays on
		# the floor as it shrinks, and a StaticBody3D moved by script carries no
		# platform velocity: the solver sees geometry teleport rather than move,
		# and a visitor standing against a block is pushed through it or trapped
		# inside it. approach_wall's slats are AnimatableBody3D for exactly this
		# reason and said so in writing before this file was fixed to match.
		var body := AnimatableBody3D.new()
		body.name = "Block%d" % i
		body.position = centre
		body.sync_to_physics = true
		# On layer 1 on purpose: it has to be solid to the same bodies the area is
		# watching. It is refused as a visitor by ancestry — see _is_visitor.
		body.collision_layer = WALKER_LAYER
		body.collision_mask = 0

		var mesh := MeshInstance3D.new()
		var bm := BoxMesh.new()
		mesh.mesh = bm
		# One material per block, made once at build. The tint has to be per-block
		# because the whole point is that they are at different sizes, and nine
		# StandardMaterial3D at build time is cheaper than one shader at runtime.
		var mat := base.duplicate() as StandardMaterial3D
		mesh.material_override = mat
		body.add_child(mesh)

		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()   # one per block; a shared shape resizes all nine
		col.shape = shape
		body.add_child(col)

		_field.add_child(body)
		_bodies.append(body)
		_meshes.append(bm)
		_shapes.append(shape)
		_mats.append(mat)
		_own[body.get_instance_id()] = true
		_apply_size(i, 1.0)

	# ONE area over the whole field plus a reach of margin, so a visitor is already
	# being read before the outermost block needs to move. Tall enough that a
	# walking body crosses it rather than stepping over.
	_area = Area3D.new()
	_area.name = "Influence"
	_area.collision_layer = 0
	_area.monitorable = false
	_area.collision_mask = PLAYER_LAYER | WALKER_LAYER
	var acol := CollisionShape3D.new()
	var abox := BoxShape3D.new()
	abox.size = Vector3(
		float(cols - 1) * spacing_m + block_m + reach_m * 2.0,
		2.4,
		float(rows - 1) * spacing_m + block_m + reach_m * 2.0)
	acol.shape = abox
	acol.position.y = 1.2
	_area.add_child(acol)
	add_child(_area)

	_visitors.resize(0)
	_local_gap = narrowest_gap_m()


## PHYSICS, NOT IDLE. Everything below moves a collider — _apply_size re-seats
## each block and resizes its shape — and a collider moved outside the physics
## step is a collider the solver never saw move.
func _physics_process(delta: float) -> void:
	if _count == 0:
		return

	_poll -= delta
	if _poll <= 0.0:
		_poll = POLL_S
		_poll_visitors()
		_measure()

	# Frame-rate independent approach: after ease_s the block has covered ~63% of
	# the distance to what your position asks for, at any refresh rate.
	var k: float = 1.0 if ease_s <= 0.0 else 1.0 - exp(-delta / ease_s)
	var moving := false
	for i in _count:
		var target: float = _target_for(i)
		var f: float = _factor[i] + (target - _factor[i]) * k
		if absf(f - target) < 0.002:
			f = target
		_factor[i] = f
		# Writing BoxMesh.size and BoxShape3D.size costs a resource update and a
		# physics server call, so a settled field must cost nothing at all.
		if absf(f - _shown[i]) > 0.004:
			_apply_size(i, f)
			moving = true

	if moving or _visitors.size() > 0:
		_check_passage(delta)


## Refresh the visitor list. This is the one allocation in the artifact and it
## happens twelve times a second, not ninety.
func _poll_visitors() -> void:
	if _area == null or not is_instance_valid(_area):
		return
	var found := 0
	var bodies := _area.get_overlapping_bodies()
	for b in bodies:
		if b == null or _own.has(b.get_instance_id()):
			continue        # our own blocks are on layer 1 too — see the header
		if not _is_visitor(b):
			continue
		if _visitors.size() <= found:
			_visitors.resize(found + 1)
		var p: Vector3 = to_local(b.global_position)
		p.y = 0.0
		_visitors[found] = p
		found += 1
	if _visitors.size() != found:
		_visitors.resize(found)


## WHO COUNTS, and why it is not "any CharacterBody3D".
##
## `hazard_creature_base` extends CharacterBody3D, so the obvious fallback hands
## the field to the museum's own traffic: a silhouette wandering among the blocks
## holds them small, and the visitor arrives at a field that is already passable —
## which is the one thing this artifact must never be until you are close. The
## desktop player is in `player_body` (desktop_player.tscn:11), the museum's
## Walker in `em_walker` and nothing else, and the VR XRToolsPlayerBody in no group
## at all, so that one is recognised by the XROrigin3D above it.
## Shared verbatim with carve_grid and approach_wall.
func _is_visitor(b: Node) -> bool:
	if b == null or is_ancestor_of(b):
		return false
	if b.is_in_group("em_walker") or b.is_in_group("player_body") \
		or b.is_in_group("player") or b.is_in_group("vr_player"):
		return true
	var n: Node = b.get_parent()
	while n != null:
		if n is XROrigin3D:
			return true
		n = n.get_parent()
	return false


## Distance is measured on the floor, not through the air: a block's centre sits
## half a block up and a walker's origin sits at its feet, so a 3D distance would
## carry a constant 0.57 m of height into a 2.2 m reach and quietly shorten it.
## What the visitor is asking is "can I get past this", which is a question about
## the plan, not the elevation.
##
## Done once per poll for the whole field, because everything below wants it: the
## law, the near test and the passage test each needed the same number and were
## each recomputing it per block per frame.
func _measure() -> void:
	if _visitors.is_empty():
		for i in _count:
			_dist2[i] = INF
		return
	for i in _count:
		var c: Vector3 = _centres[i]
		var best: float = INF
		for v in _visitors:
			var d: float = c.distance_squared_to(v)
			if d < best:
				best = d
		_dist2[i] = best


## THE LAW: factor = lerp(min_scale, 1.0, eased(dist / reach_m)). Your distance is
## the only input. Standing still is the identity operation.
func _target_for(i: int) -> float:
	if reach_m <= 0.0 or is_inf(_dist2[i]):
		return 1.0
	var t: float = clampf(sqrt(_dist2[i]) / reach_m, 0.0, 1.0)
	t = t * t * (3.0 - 2.0 * t)     # eased, so the field breathes instead of ramping
	return lerpf(min_scale, 1.0, t)


## Re-seat as well as resize: the block shrinks about its own centre, but a cube
## that shrinks about its centre floats, so the body drops to keep its bottom face
## on the floor. Half of the shrinking you see is this.
func _apply_size(i: int, f: float) -> void:
	var s: float = maxf(0.01, block_m * f)
	_meshes[i].size = Vector3(s, s, s)
	_shapes[i].size = Vector3(s, s, s)
	var b: AnimatableBody3D = _bodies[i]
	b.position.y = s * 0.5
	# Quiet: the emission only comes up as the block gives way, so the shrinking is
	# legible from the far end of a hall without the field becoming a light source.
	_mats[i].emission_energy_multiplier = (1.0 - f) * 0.9
	_shown[i] = f


## The narrowest gap among the pairs a visitor is actually standing between. Far
## corners of the field are still shut and are supposed to be — asking the whole
## field to open would mean the passage never opens for anyone standing at an edge.
func _check_passage(delta: float) -> void:
	var gap: float = INF
	var any_near := false
	var r2: float = reach_m * reach_m
	for i in _count:
		var near_i: bool = _dist2[i] <= r2
		any_near = any_near or near_i
		var right: int = i + 1
		var down: int = i + cols
		# A pair counts only if the visitor is beside THAT pair. Testing "is anyone
		# anywhere in the field" instead would drag the far corners into the
		# narrowest-gap answer and the passage would never read as open.
		#
		# The row is never computed: `down < _count` already implies the block has a
		# row below it, because _count is capped at cols * rows. Only the column has
		# to be asked, or block 2 in a 3-wide grid would pair with block 3 across the
		# wrap and report a gap between two blocks that are 3 m apart.
		if i % cols + 1 < cols and right < _count and (near_i or _dist2[right] <= r2):
			gap = minf(gap, spacing_m - block_m * (_factor[i] + _factor[right]) * 0.5)
		if down < _count and (near_i or _dist2[down] <= r2):
			gap = minf(gap, spacing_m - block_m * (_factor[i] + _factor[down]) * 0.5)

	_local_gap = narrowest_gap_m() if is_inf(gap) else gap

	if any_near:
		_near_s += delta
	else:
		_near_s = 0.0
		_rigid_said = false     # a fresh visitor gets a fresh verdict

	var open: bool = any_near and not is_inf(gap) and gap > SHOULDER_M
	if open and not _open:
		_open = true
		_ever_open = true
		passage_opened.emit()
	elif not open and _open:
		_open = false
		passage_closed.emit()

	if not _rigid_said and not _ever_open and _near_s > RIGID_AFTER_S:
		_rigid_said = true
		var why: String = _rigid_reason()
		push_warning("approach_scale: " + why)
		rigid.emit(why)


## Which of the four ways this can fail actually happened. Written as a sentence
## because it is read in a log by somebody who is not holding the arithmetic.
func _rigid_reason() -> String:
	if _count < 2:
		return "only %d block built — nothing to walk between" % _count
	if reach_m <= 0.0:
		return "reach_m is %.2f, so no visitor is ever close enough to matter" % reach_m
	var smallest: float = 1.0
	for i in _count:
		smallest = minf(smallest, _factor[i])
	if smallest > 0.97:
		return "nothing shrank: min_scale is %.2f and ease_s is %.2f s" % [min_scale, ease_s]
	var opened: float = (spacing_m - SHOULDER_M) / maxf(0.01, block_m)
	return "shrank to %.2f but the gap is still %.2f m; it needs factor %.2f to clear a %.2f m shoulder" \
		% [smallest, _local_gap, opened, SHOULDER_M]


## The narrowest gap anywhere in the field, metres, at the current sizes. With
## nobody in the room this is the resting gap and should be under a shoulder — a
## probe that reads more than SHOULDER_M here has a field that was never shut.
func narrowest_gap_m() -> float:
	if _count < 2:
		return spacing_m
	var gap: float = INF
	for i in _count:
		if i % cols + 1 < cols and i + 1 < _count:
			gap = minf(gap, spacing_m - block_m * (_factor[i] + _factor[i + 1]) * 0.5)
		if i + cols < _count:
			gap = minf(gap, spacing_m - block_m * (_factor[i] + _factor[i + cols]) * 0.5)
	return spacing_m if is_inf(gap) else gap


## What block i is scaled to right now. 1.0 is untouched, min_scale is stood on.
func factor_at(i: int) -> float:
	if i < 0 or i >= _count:
		return 1.0
	return _factor[i]


## For a probe: how many bodies the area is actually reading. Zero while somebody
## is plainly standing in the field means the mask is wrong, and that is the one
## failure `rigid` cannot report, because an unseen visitor starts no timer.
func visitor_count() -> int:
	return _visitors.size()


## For a probe: is there a way through near a visitor at this instant.
func is_open() -> bool:
	return _open
