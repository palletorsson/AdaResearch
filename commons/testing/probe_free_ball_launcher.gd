extends SceneTree

## DOES IT THROW, DOES IT SHOVE, AND IS IT REALLY FREE?
##
## 2026-09-08, Palle: "in Trans_Pit add shorting free ball from the sides."
##
## The third question is the one that needs a gate. "Free" means nobody aimed it:
## the launcher fires into an empty hall exactly as it fires into a full one, and
## nothing in it may read a visitor's position to decide when or where. That is
## also the easiest property in the corpus to lose by accident, because aiming is
## an improvement — cube_projectile_spawner already leads its target and is
## described as doing so. A future edit that "helps the ball find the player"
## would break nothing, fail no test, and quietly turn this into that.
##
## So the free test is adversarial: the same launcher is watched while a visitor
## is moved to three quite different places, and the direction it throws must not
## budge. If it ever does, the artifact has started having an opinion about who is
## in the room.
##
## THE ROTATION CONVENTION IS MEASURED, NOT DERIVED. The map aims these with the
## token's rotation (270 to throw east, 90 to throw west) and that came out of an
## argument about which way Godot's -Z points after a yaw. An argument is not
## evidence, so the probe stands one at 270 and asks which way the ball actually
## went.
##
##   godot --path . --xr-mode off --no-window --script res://commons/testing/probe_free_ball_launcher.gd

const LAUNCHER := "res://commons/artifacts/free_ball_launcher/free_ball_launcher.tscn"
const REPORT := "res://ada_run/free_ball_launcher_probe.txt"

var _lines: Array[String] = []
var _fails: Array[String] = []
var _gun: Node3D
var _visitor: CharacterBody3D
var _imposter: CharacterBody3D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var root := Node3D.new()
	root.name = "Field"
	get_root().add_child(root)

	# A floor, so a ball that lands can roll instead of falling out of the world
	# and being retired before anything has been measured.
	var ground := StaticBody3D.new()
	ground.collision_layer = 1
	var gcol := CollisionShape3D.new()
	var plane := WorldBoundaryShape3D.new()
	plane.plane = Plane(Vector3.UP, 0.0)
	gcol.shape = plane
	ground.add_child(gcol)
	root.add_child(ground)

	var ps: PackedScene = load(LAUNCHER) as PackedScene
	_gun = ps.instantiate() as Node3D
	root.add_child(_gun)
	_gun.global_position = Vector3.ZERO
	# 270 is what the Trans_Pit tokens on the LEFT wall carry.
	_gun.rotation = Vector3(0.0, deg_to_rad(270.0), 0.0)

	_visitor = _body(root, "Walker", true)
	_imposter = _body(root, "Imposter", false)
	_park(_visitor)
	_park(_imposter)

	# It fires on its own clock; give it several intervals.
	await _settle(400)

	var shots: int = int(_gun.call("shots_fired"))
	var live: int = int(_gun.call("live_count"))
	_say("after ~6.6 s alone: %d shot(s) fired, %d live" % [shots, live])
	_check(shots > 0, "  it fires with nobody in the room",
		"nothing has left the barrel — a launcher that only fires at somebody is not this artifact")
	if shots == 0:
		_finish()
		return

	var travel: Vector3 = _gun.call("last_travel")
	_say("  last travel %s  (|xz| %.2f)" % [str(travel.round()), Vector2(travel.x, travel.z).length()])
	_check(travel.length() > 0.1, "  the ball is going somewhere", "the ball has no travel at all")
	# THE CONVENTION, measured. 270 must send it east, +x.
	var east: float = travel.normalized().dot(Vector3.RIGHT)
	_check(east > 0.85, "  yaw 270 throws EAST: dot(+x) = %.2f" % east,
		"yaw 270 throws %s, not east — every Trans_Pit token is aimed the wrong way" % str(travel.normalized().round()))

	# ── IS IT FREE? ───────────────────────────────────────────────────
	var seen: Array[Vector3] = []
	for at in [Vector3(4, 0, 0), Vector3(-4, 0, 0), Vector3(0, 0, 4)]:
		_visitor.global_position = at
		await _settle(200)
		seen.append(_gun.call("last_travel"))
		_say("  visitor at %-14s -> throws %s" % [str(at.round()), str((seen[-1] as Vector3).normalized().round())])
	var drift := 0.0
	for v in seen:
		drift = maxf(drift, (v.normalized() - travel.normalized()).length())
	_check(drift < 0.35,
		"  the throw ignores where the visitor stands (drift %.2f)" % drift,
		"the throw MOVED by %.2f when the visitor moved — something in the launcher is reading a body, and free is the whole artifact" % drift)

	# ── does it shove? ────────────────────────────────────────────────
	# Stand in the line of fire, close enough that a level throw is still airborne.
	_visitor.global_position = Vector3(2.2, 0, 0)
	_visitor.velocity = Vector3.ZERO
	var pushed := false
	for i in range(400):
		await process_frame
		await physics_frame
		if _visitor.velocity.length() > 0.5:
			pushed = true
			break
	_say("  standing in the line of fire: velocity %s" % str(_visitor.velocity.round()))
	_check(pushed, "  a ball shoves a visitor",
		"a ball reached the visitor and nothing moved — a RigidBody3D does not push a CharacterBody3D, the artifact has to write velocity itself")

	# ── and only a visitor ────────────────────────────────────────────
	_park(_visitor)
	_imposter.global_position = Vector3(2.2, 0, 0)
	_imposter.velocity = Vector3.ZERO
	await _settle(400)
	_say("  a hazard creature in the line of fire: velocity %s" % str(_imposter.velocity.round()))
	_check(_imposter.velocity.length() < 0.5, "  it does not shove the museum's own traffic",
		"the launcher shoved a hazard creature — the visitor test takes any CharacterBody3D")

	# ── A BALL AT REST IS FURNITURE ───────────────────────────────────
	#
	# body_entered fires whichever side moved, and a ball's area keeps monitoring
	# for the whole of life_s — so a ball that landed seconds ago was a mine: walk
	# into it and take the full shove, along the heading it was thrown on and has
	# not been on since. At the defaults three or four are lying about at once, so
	# the floor around the launcher was permanently armed. Nothing else here would
	# have caught it: every check above involves a ball that is still flying.
	_park(_imposter)
	_park(_visitor)
	await _settle(120)
	# THE STATE IS MADE, NOT WAITED FOR. A first version hunted for a ball that had
	# stopped by itself and reported "inconclusive" when none had — a sphere on a
	# frictionless world-boundary rolls for a long time and is retired at life_s
	# before it settles. Stopping one is the exact state under test and takes no luck.
	var still: RigidBody3D = _a_ball()
	_check(still != null, "  there is a ball to stand on",
		"no live ball to test the resting case with — the negative below never ran")
	if still != null:
		still.linear_velocity = Vector3.ZERO
		still.angular_velocity = Vector3.ZERO
		await _settle(4)
		_visitor.global_position = still.global_position + Vector3(0, 0, 0.9)
		_visitor.velocity = Vector3.ZERO
		await _settle(6)
		_visitor.global_position = still.global_position
		await _settle(60)
		_say("  walked into a ball at rest (|v| %.2f): visitor velocity %s"
			% [still.linear_velocity.length(), str(_visitor.velocity.round())])
		_check(_visitor.velocity.length() < 0.5, "  a resting ball is furniture, not a mine",
			"a ball lying on the floor shoved the visitor at %.1f m/s" % _visitor.velocity.length())

	_finish()


## Any live pooled ball. Found by walking the tree, because the pool is a SIBLING of
## the launcher rather than a child — the launcher keeps it outside its own subtree
## so the museum does not measure a ball in flight as the launcher's footprint.
func _a_ball() -> RigidBody3D:
	var stack: Array[Node] = [get_root()]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is RigidBody3D and (n as Node3D).global_position.y > -50.0:
			return n as RigidBody3D
		for c in n.get_children():
			stack.append(c)
	return null


## The museum's Walker recipe, or a creature wearing the same physics. The only
## difference the launcher is allowed to notice is the group.
func _body(root: Node3D, name: String, visitor: bool) -> CharacterBody3D:
	var b := CharacterBody3D.new()
	b.name = name
	b.collision_layer = 1
	b.collision_mask = 0
	if visitor:
		b.add_to_group("em_walker")
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.32
	cap.height = 1.5
	cs.shape = cap
	cs.position = Vector3(0, 0.75, 0)
	b.add_child(cs)
	root.add_child(b)
	return b


func _park(b: CharacterBody3D) -> void:
	b.global_position = Vector3(0, 0, 300)
	b.velocity = Vector3.ZERO


func _settle(n: int) -> void:
	for i in range(n):
		await process_frame
		await physics_frame


func _say(line: String) -> void:
	_lines.append("[probe] %s" % line)


func _finish() -> void:
	var ok: bool = _fails.is_empty()
	_lines.append("[probe] %s%s" % ["PASS" if ok else "FAIL", "" if ok else " — " + ", ".join(_fails)])
	var f := FileAccess.open(REPORT, FileAccess.WRITE)
	if f != null:
		f.store_string(String.chr(10).join(PackedStringArray(_lines)) + String.chr(10))
		f.close()
	for l in _lines:
		print(l)
	quit(0 if ok else 1)


func _check(ok: bool, line: String, why: String) -> void:
	_lines.append("[probe] %s  %s" % [line, "OK" if ok else "*** %s ***" % why])
	if not ok:
		_fails.append(why)
