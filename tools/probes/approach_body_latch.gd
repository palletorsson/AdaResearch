extends SceneTree

## Trans_Body, 2026-11-09 (Palle): "approach_scale more boxes and start contract earlier by distance, stay in
## contracted position. Approach_wall have three segments of door and keep the one the player walks through open.
## Make all artifact in this map white."
##
## A bench, no museum: each artifact is instantiated, configured through apply_grid_config (as floor_content does),
## and a bare em_walker CharacterBody3D is walked along a path one step per physics frame. The physics world is asked
## about clearance with a shoulder sphere (r 0.26), not the artifacts' own flags.
##
## SCALE  A default config still breathes (shrinks near, regrows after).            [default unchanged]
##        Trans_Body config: blocks move at 4 m out (old reach 2.7 m does not).     [earlier]
##        Shut before the walk; a shoulder passes along the walked line after.       [walkable]
##        After leaving, the walked corridor stays at min_scale.                     [latch]
##        NEGATIVE: same config, latch off -> the corridor regrows.                  [the test bites]
##        white_edges: every block has its edge overlay, cube scale == shape size.   [look]
## WALL   segments=3 latch: approach door 0 and back off -> it opens, then closes.
##        Push a solid body through door 1 0.9 m off centre (fins stopped the Void walker); walk on -> door 1 stays
##        open (>= 2.5 m of free shoulder centres), doors 0/2 shut; a shoulder fits in door 1 only.
##        NEGATIVE: latch off -> door 1 closes after the crossing.
##        Default config: opens on approach, shuts after (unchanged).
##
##   timeout 150 godot --headless --path . --xr-mode off --script res://tools/probes/approach_body_latch.gd

const SCALE := "res://commons/artifacts/approach_scale/approach_scale.tscn"
const WALL := "res://commons/artifacts/approach_wall/approach_wall.tscn"
const SHOULDER_R := 0.26
const STEP := 0.05

const SCALE_BODY := {"cols": 8, "rows": 4, "blocks": 32, "spacing": 1.5, "block": 1.2, "block_height": 2.1,
	"min_scale": 0.34, "reach": 6.0, "latch": true, "commit": 0.5, "look": "white_edges"}
const SCALE_OLD := {"cols": 5, "rows": 3, "blocks": 15, "spacing": 2.3, "block": 2.1, "min_scale": 0.34, "reach": 2.7}
const WALL_BODY := {"width": 12, "height": 4.4, "slats": 15, "aperture": 1.6, "reach": 2.8, "segments": 3,
	"latch": true, "look": "white_edges"}

var _root: Node3D
var _walker: CharacterBody3D
var _fails: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_root = Node3D.new()
	get_root().add_child(_root)
	_walker = CharacterBody3D.new()
	_walker.name = "Walker"
	_walker.collision_layer = 1
	_walker.collision_mask = 0
	_walker.add_to_group("em_walker")
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.25
	cap.height = 1.5
	cs.shape = cap
	cs.position = Vector3(0, 0.75, 0)
	_walker.add_child(cs)
	_root.add_child(_walker)
	_park()

	await _scale_default()
	await _scale_body(true)
	await _scale_body(false)
	await _scale_earlier_than_old()
	await _wall_doors(true)
	await _wall_doors(false)
	await _wall_default()

	print("[probe] %s%s" % ["PASS" if _fails.is_empty() else "FAIL", "" if _fails.is_empty() else " — " + "; ".join(_fails)])
	quit(0 if _fails.is_empty() else 1)


# ---------------------------------------------------------------- approach_scale

func _scale_default() -> void:
	var a := await _make(SCALE, {})
	_walker.global_position = Vector3(0, 0, 0)        # on the centre block (index 4 of 3x3)
	await _settle(60)
	var near: float = a.factor_at(4)
	_park()
	await _settle(90)
	var after: float = a.factor_at(4)
	_say("scale default: centre block %.2f with a visitor on it, %.2f after they leave" % [near, after])
	_check(near < 0.5 and after > 0.98, "default config still breathes (shrink near, regrow after)")
	a.queue_free()
	await _settle(2)


func _scale_body(latched: bool) -> void:
	var cfg := SCALE_BODY.duplicate()
	cfg["latch"] = latched
	var a := await _make(SCALE, cfg)
	var tag := "scale Trans_Body latch=%s" % str(latched)
	# Before anybody comes: shut along the line x = 0 (the seam between the two middle columns).
	var shut_free: bool = _line_free(Vector3(0, 0.4, -2.6), Vector3(0, 0.4, 2.6))
	_check(not shut_free, tag + ": shut before the walk (a shoulder cannot pass)")
	# Walk in from 12 m out along x = 0, through, and out the far side.
	await _walk(Vector3(0, 0, -12), Vector3(0, 0, 0.0))
	await _settle(45)
	var free_mid: bool = _line_free(Vector3(0, 0.4, -2.6), Vector3(0, 0.4, 2.6))
	_check(free_mid, tag + ": a shoulder passes along the walked line once you are among the blocks")
	await _walk(Vector3(0, 0, 0), Vector3(0, 0, 12))
	_park()
	await _settle(150)
	# Blocks 3 and 4 of each row stand either side of x = 0.
	var corridor := 0.0
	var far_edge: float = a.factor_at(0)
	for r in 4:
		corridor = maxf(corridor, maxf(a.factor_at(r * 8 + 3), a.factor_at(r * 8 + 4)))
	var free_after: bool = _line_free(Vector3(0, 0.4, -2.6), Vector3(0, 0.4, 2.6))
	_say("%s: after leaving, corridor blocks max factor %.2f, far corner %.2f, shoulder passes %s"
		% [tag, corridor, far_edge, str(free_after)])
	if latched:
		_check(corridor <= 0.35 and free_after, tag + ": the walked corridor STAYS at min_scale and passable")
		_check(far_edge > 0.95, tag + ": the far corner (6 m off the line) was never asked and is still full")
		# The look: every block has an edge overlay and the cube's node scale equals its collider.
		var ok := true
		var bodies: Array = a.get("_bodies")
		var shapes: Array = a.get("_shapes")
		for i in bodies.size():
			var cube: MeshInstance3D = (bodies[i] as Node).get_node_or_null("Cube")
			if cube == null or cube.get_node_or_null("EdgeOutline") == null:
				ok = false
				break
			if not cube.scale.is_equal_approx((shapes[i] as BoxShape3D).size):
				ok = false
				break
		_check(ok, tag + ": white_edges - every block has its overlay and the drawn cube matches its collider")
	else:
		_check(corridor > 0.98 and not free_after, "NEGATIVE " + tag + ": the corridor regrows and the field shuts")
	a.queue_free()
	await _settle(2)


## The earlier start: with the visitor 4 m short of the first row, the Trans_Body reach moves blocks; the old one
## (2.7 m) does not.
func _scale_earlier_than_old() -> void:
	var results := []
	for cfg in [SCALE_BODY, SCALE_OLD]:
		var a := await _make(SCALE, cfg)
		var rows: int = int(cfg["rows"])
		var cols: int = int(cfg["cols"])
		var first_row_z: float = -float(rows - 1) * 0.5 * float(cfg["spacing"])
		_walker.global_position = Vector3(0, 0, first_row_z - 4.0)
		await _settle(60)
		var least := 1.0
		for i in cols:
			least = minf(least, a.factor_at(i))
		results.append(least)
		_park()
		a.queue_free()
		await _settle(2)
	_say("scale at 4 m from the first row: Trans_Body reach 6.0 -> %.2f, old reach 2.7 -> %.2f" % [results[0], results[1]])
	_check(results[0] < 0.9 and results[1] > 0.99, "contraction starts earlier (4 m out) with the new reach, not the old")


# ---------------------------------------------------------------- approach_wall

func _wall_doors(latched: bool) -> void:
	var cfg := WALL_BODY.duplicate()
	cfg["latch"] = latched
	var w := await _make(WALL, cfg)
	var tag := "wall 3 doors latch=%s" % str(latched)
	var built: Array = w.get("_slats")
	_say("%s: built %d boards of %.3f m, %d per door" % [tag, built.size(), float(w.get("_slat_w")), int(w.get("_per"))])
	# Door 0 (x -6..-2): walk up to 0.8 m in front, then back off without crossing.
	await _walk(Vector3(-4, 0, -5), Vector3(-4, 0, -0.8))
	await _settle(40)
	var d0_open: float = w.door_openness(0)
	var d1_then: float = w.door_openness(1)
	await _walk(Vector3(-4, 0, -0.8), Vector3(-4, 0, -5))
	_park()
	await _settle(90)
	var d0_after: float = w.door_openness(0)
	_say("%s: door 0 approached %.2f (door 1 meanwhile %.2f), backed off %.2f" % [tag, d0_open, d1_then, d0_after])
	_check(d0_open > 0.9 and d1_then < 0.05 and d0_after < 0.02, tag + ": an approached door opens alone and closes again")
	# Door 1 (x -2..2): walk through it OFF-CENTRE (x 0.9, the Void walker's failure was 0.2 m off a slot centre),
	# as a SOLID body pushed with move_and_collide, then on 5 m past. A door full of fins stops it.
	var through: bool = await _push_through(Vector3(0.9, 0, -5), Vector3(0.9, 0, 5))
	_park()
	await _settle(120)
	var o := [w.door_openness(0), w.door_openness(1), w.door_openness(2)]
	var fit := [_line_free(Vector3(-5.9, 1.05, 0), Vector3(-2.1, 1.05, 0)),
		_line_free(Vector3(-1.9, 1.05, 0), Vector3(1.9, 1.05, 0)),
		_line_free(Vector3(2.1, 1.05, 0), Vector3(5.9, 1.05, 0))]
	var run1: float = _free_run(Vector3(-2.0, 1.05, 0), Vector3(2.0, 1.05, 0))
	_say("%s: solid body pushed through door 1 at x 0.9: %s" % [tag, str(through)])
	_say("%s: after walking through door 1 and away: openness %.2f / %.2f / %.2f, a shoulder fits %s / %s / %s, held %d, door 1 free run %.2f m of shoulder centres"
		% [tag, o[0], o[1], o[2], str(fit[0]), str(fit[1]), str(fit[2]), int(w.held_count()), run1])
	_check(through, tag + ": a solid 0.25 m body walks through door 1 0.9 m off its centre")
	if latched:
		_check(o[1] > 0.98 and fit[1], tag + ": the door walked through STAYS open and a shoulder fits")
		_check(run1 >= 2.5, tag + ": the open door clears most of its 4 m (a shoulder can cross anywhere in %.2f m), not slots" % run1)
		_check(o[0] < 0.02 and o[2] < 0.02 and not fit[0] and not fit[2], tag + ": the other two doors are shut")
	else:
		_check(o[1] < 0.02 and not fit[1], "NEGATIVE " + tag + ": without latch the door closes behind you")
	# The look: every board has its edge overlay.
	var dressed := 0
	for s in built:
		var board: Node = (s as Node).get_node_or_null("Board")
		if board != null and board.get_node_or_null("EdgeOutline") != null:
			dressed += 1
	_check(dressed == built.size(), tag + ": white_edges - %d of %d boards carry their edges" % [dressed, built.size()])
	w.queue_free()
	await _settle(2)


func _wall_default() -> void:
	var w := await _make(WALL, {})
	var n: int = (w.get("_slats") as Array).size()
	await _walk(Vector3(0, 0, -4), Vector3(0, 0, -0.8))
	await _settle(60)
	var near: float = w.openness()
	var passable: bool = w.is_passable()
	_park()
	await _settle(90)
	var after: float = w.openness()
	_say("wall default: %d slats, openness %.2f near (passable %s), %.2f after leaving" % [n, near, str(passable), after])
	_check(n == 5 and near > 0.9 and passable and after < 0.01, "default wall unchanged: 7 asked, 5 built (the old clamp), opens near, shuts after")
	w.queue_free()
	await _settle(2)


# ---------------------------------------------------------------- bench

func _make(path: String, cfg: Dictionary) -> Node3D:
	var a := (load(path) as PackedScene).instantiate() as Node3D
	for k in cfg:
		a.set_meta("config_" + str(k), cfg[k])
	_root.add_child(a)
	if not cfg.is_empty():
		a.call("apply_grid_config", cfg)
	await _settle(10)
	return a


func _walk(from: Vector3, to: Vector3) -> void:
	var steps: int = maxi(1, int(ceil(from.distance_to(to) / STEP)))
	for i in steps + 1:
		_walker.global_position = from.lerp(to, float(i) / float(steps))
		await physics_frame


## Is there a run of shoulder-sphere positions along the segment that touches nothing? (the walker excluded)
func _line_free(from: Vector3, to: Vector3) -> bool:
	var space: PhysicsDirectSpaceState3D = get_root().world_3d.direct_space_state
	var shape := SphereShape3D.new()
	shape.radius = SHOULDER_R
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.collide_with_bodies = true
	q.collide_with_areas = false
	q.exclude = [_walker.get_rid()]
	var steps: int = maxi(1, int(ceil(from.distance_to(to) / 0.02)))
	if from.z == to.z:
		# Across a wall's plane: is ANY position along it free (a hole somewhere in this door)?
		for i in steps + 1:
			q.transform = Transform3D(Basis.IDENTITY, from.lerp(to, float(i) / float(steps)))
			if space.intersect_shape(q, 1).is_empty():
				return true
		return false
	# Along a walk: is EVERY position free (a path)?
	for i in steps + 1:
		q.transform = Transform3D(Basis.IDENTITY, from.lerp(to, float(i) / float(steps)))
		if not space.intersect_shape(q, 1).is_empty():
			return false
	return true


## Push a solid capsule (the bench walker, radius 0.25) from -> to with move_and_collide, one step per physics frame,
## as the Void walker moves. True when it gets within 0.25 m of the target.
func _push_through(from: Vector3, to: Vector3) -> bool:
	_walker.collision_mask = 1
	_walker.global_position = from
	await physics_frame
	var stuck := 0
	var ok := false
	for i in 600:
		var left: Vector3 = to - _walker.global_position
		left.y = 0.0
		if left.length() < 0.25:
			ok = true
			break
		var before: Vector3 = _walker.global_position
		_walker.move_and_collide(left.normalized() * minf(STEP, left.length()))
		_walker.global_position.y = 0.0
		stuck = stuck + 1 if before.distance_to(_walker.global_position) < STEP * 0.2 else 0
		if stuck > 120:
			break
		await physics_frame
	_walker.collision_mask = 0
	return ok


## The longest run of free shoulder-sphere centres along a line, metres.
func _free_run(from: Vector3, to: Vector3) -> float:
	var space: PhysicsDirectSpaceState3D = get_root().world_3d.direct_space_state
	var shape := SphereShape3D.new()
	shape.radius = SHOULDER_R
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.exclude = [_walker.get_rid()]
	var steps: int = maxi(1, int(ceil(from.distance_to(to) / 0.02)))
	var best := 0.0
	var run := 0.0
	for i in steps + 1:
		q.transform = Transform3D(Basis.IDENTITY, from.lerp(to, float(i) / float(steps)))
		if space.intersect_shape(q, 1).is_empty():
			run += 0.02
			best = maxf(best, run)
		else:
			run = 0.0
	return best


func _park() -> void:
	_walker.global_position = Vector3(0, 0, -400)


func _settle(n: int) -> void:
	for i in n:
		await process_frame
		await physics_frame


func _say(line: String) -> void:
	print("[probe] " + line)


func _check(ok: bool, what: String) -> void:
	print("[probe] %s  %s" % ["OK  " if ok else "FAIL", what])
	if not ok:
		_fails.append(what)
