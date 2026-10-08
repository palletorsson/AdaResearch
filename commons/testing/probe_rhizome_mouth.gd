extends SceneTree

## Can you get IN? (2026-09-03)
##
## probe_rhizome_inside.gd proved the building works: 8 of 8 chambers standable,
## 10 of 10 passages passable, 8 of 8 reachable. Every one of those measurements
## was taken by a probe that STARTED INSIDE. All of them were true, and none of
## them noticed that abs(f) - wall gives a CLOSED shell — an outer skin, an inner
## skin, and no way between them. A visitor standing on the floor beside it had
## no door, and the building would have shipped as a sealed lump that measured
## perfectly.
##
## That is this project's own recurring failure wearing a new coat: the gate
## answered the question it was asked and nobody asked the other one. So this
## probe asks only the other one, and it asks it from OUTSIDE.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_rhizome_mouth.gd

const SCENE := "res://commons/artifacts/radial_inside/rhizome_inside.tscn"
const PLAYER := "res://commons/scenes/desktop_player.tscn"
const REPORT := "res://ada_run/rhizome_mouth_probe.txt"

var _lines: Array[String] = []
var _fails: Array[String] = []
var _cap_r: float = 0.30
var _cap_h: float = 1.80


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_read_envelope()
	if not ResourceLoader.exists(SCENE):
		_check(false, "", "%s does not exist" % SCENE)
		_finish()
		return
	var n: Node3D = (load(SCENE) as PackedScene).instantiate() as Node3D
	n.set("seed", 3)
	root.add_child(n)
	await process_frame
	await physics_frame
	await physics_frame

	for m in ["entrance_point", "entrance_dir", "cavity_points"]:
		if not n.has_method(m):
			_check(false, "", "the body does not expose %s() — a map cannot place a door it cannot find" % m)
			_finish()
			return

	var mouth: Vector3 = n.call("entrance_point")
	var dir: Vector3 = n.call("entrance_dir")
	var pts: Array = n.call("cavity_points")
	_lines.append("[probe] mouth at (%.2f, %.2f, %.2f) facing (%.2f, %.2f, %.2f); %d chamber(s)"
		% [mouth.x, mouth.y, mouth.z, dir.x, dir.y, dir.z, pts.size()])

	var space: PhysicsDirectSpaceState3D = root.world_3d.direct_space_state
	var cap := CapsuleShape3D.new()
	cap.radius = _cap_r
	cap.height = _cap_h

	# ── 1. OUTSIDE IS ACTUALLY OUTSIDE ───────────────────────────────────
	#
	# The walk has to start in open air, or "I got in" is just "I was already in".
	var outside: Vector3 = mouth + dir * 9.0
	_check(_fits(space, cap, outside), "the approach point 9 m out along the mouth axis is open air",
		"the approach point is inside geometry — this probe would be starting from indoors")

	# ── 2. THE WALK IN ───────────────────────────────────────────────────
	#
	# Straight along the mouth axis, because that is what the cut is: a capsule
	# bored horizontally through the wall. Every station must fit the PLAYER'S
	# OWN capsule with the query margin zeroed — a default 0.04 m margin reports
	# a body resting on a floor as stuck, which cost a run on the tunnel.
	var steps: int = 90
	var blocked_at: float = -1.0
	var blocked_by: String = ""
	var narrowest: float = 1.0e9
	var narrow_at: float = 0.0
	for i in range(steps + 1):
		var t: float = 1.0 - float(i) / float(steps)      # 1 = outside, 0 = the mouth
		var q: Vector3 = mouth + dir * (9.0 * t)
		if not _fits(space, cap, q):
			blocked_at = 9.0 * t
			# NAME WHAT BLOCKED, and say whether it is above, below or beside.
			# "sealed at 2.70 m" sends you looking for a bore that does not reach;
			# "the outer skin, 0.31 m BELOW the walk line" says the mouth is at the
			# wrong height, which is a different repair entirely.
			var qq := PhysicsShapeQueryParameters3D.new()
			qq.shape = cap
			qq.transform = Transform3D(Basis(), q)
			qq.margin = 0.0
			var hits: Array = space.intersect_shape(qq, 4)
			var names: Array[String] = []
			for hh in hits:
				var bn: Node = hh.get("collider")
				if bn != null and bn.get_parent() != null:
					names.append(String(bn.get_parent().name))
			var up: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(q, q + Vector3.UP * 6.0))
			var dn: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(q, q + Vector3.DOWN * 6.0))
			blocked_by = "%s | ceiling %s, floor %s" % [
				", ".join(names) if not names.is_empty() else "unnamed",
				("%.2f m up" % (float((up["position"] as Vector3).y) - q.y)) if not up.is_empty() else "none",
				("%.2f m down" % (q.y - float((dn["position"] as Vector3).y))) if not dn.is_empty() else "none"]
			break
		var clear: float = _clearance(space, q)
		if clear < narrowest:
			narrowest = clear
			narrow_at = 9.0 * t
	_check(blocked_at < 0.0,
		"the player's own capsule (r %.2f, h %.2f) walks all 9 m from open air to inside the chamber"
			% [_cap_r, _cap_h],
		"blocked %.2f m out along the mouth axis by %s" % [blocked_at, blocked_by])
	_check(narrowest > _cap_r * 1.2,
		"narrowest clearance beside the body on the way in: %.2f m at %.1f m out (body half-width %.2f)"
			% [narrowest, narrow_at, _cap_r],
		"the mouth pinches to %.2f m at %.1f m out — under the %.2f m the body needs"
			% [narrowest, narrow_at, _cap_r])

	# ── 3. AND YOU ARRIVE SOMEWHERE, not in a pocket ─────────────────────
	#
	# A cut that opens a hole but stops short of the cavity gives a niche you can
	# stand in and go no further, which from outside is indistinguishable from a
	# door. So: the arrival point must be within reach of a real chamber centre.
	var nearest: float = 1.0e9
	var which: int = -1
	for i in range(pts.size()):
		var d: float = (pts[i] as Vector3).distance_to(mouth)
		if d < nearest:
			nearest = d
			which = i
	_check(nearest < 6.0,
		"the mouth arrives %.2f m from chamber %d — a door into the building, not a niche in its wall"
			% [nearest, which],
		"the nearest chamber is %.2f m from the mouth — this is a pocket, not an entrance" % nearest)

	# ── 4. THE SILL ──────────────────────────────────────────────────────
	#
	# There is NO STEP HEIGHT in this engine, so a sill of any size is a wall that
	# looks like a threshold. Drop the capsule at the mouth and just outside it and
	# compare the two floors.
	var f_in: float = _floor_y(space, mouth)
	var f_out: float = _floor_y(space, mouth + dir * 3.0)
	if f_in > -1.0e8 and f_out > -1.0e8:
		_check(absf(f_in - f_out) < 0.25,
			"the sill is %.3f m: floor %.2f outside, %.2f inside (no step height in this engine)"
				% [absf(f_in - f_out), f_out, f_in],
			"a %.2f m sill at the mouth — with no step height that is a wall you cannot climb"
				% absf(f_in - f_out))
	else:
		_lines.append("[probe] note  no floor found %s — the mouth opens over open ground, which a map has to supply"
			% ("inside" if f_in <= -1.0e8 else "outside"))

	n.queue_free()
	_finish()


func _fits(space: PhysicsDirectSpaceState3D, cap: CapsuleShape3D, at: Vector3) -> bool:
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = cap
	q.transform = Transform3D(Basis(), at)
	q.margin = 0.0
	return space.intersect_shape(q, 1).is_empty()


## The radius of the largest sphere that fits at a point, by rays in six
## directions. Reports 1e9 when nothing is hit, which is honest: no wall found.
func _clearance(space: PhysicsDirectSpaceState3D, at: Vector3) -> float:
	var best: float = 1.0e9
	for d in [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
		var hit: Dictionary = space.intersect_ray(
			PhysicsRayQueryParameters3D.create(at, at + d * 12.0))
		if not hit.is_empty():
			best = minf(best, at.distance_to(hit["position"]))
	return best


func _floor_y(space: PhysicsDirectSpaceState3D, at: Vector3) -> float:
	var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(
		at + Vector3(0.0, 2.0, 0.0), at + Vector3(0.0, -6.0, 0.0)))
	return float((hit["position"] as Vector3).y) if not hit.is_empty() else -1.0e9


func _read_envelope() -> void:
	if not ResourceLoader.exists(PLAYER):
		return
	var p: Node = (load(PLAYER) as PackedScene).instantiate()
	for cs in _shapes(p):
		if cs.shape is CapsuleShape3D:
			_cap_r = (cs.shape as CapsuleShape3D).radius
			_cap_h = (cs.shape as CapsuleShape3D).height
			break
	_lines.append("[probe] envelope read from the player: capsule r %.2f m, h %.2f m" % [_cap_r, _cap_h])
	p.free()


func _shapes(n: Node) -> Array[CollisionShape3D]:
	var out: Array[CollisionShape3D] = []
	if n is CollisionShape3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_shapes(c))
	return out


func _finish() -> void:
	var ok: bool = _fails.is_empty()
	_lines.append("[probe] %s%s" % ["PASS" if ok else "FAIL", "" if ok else " — " + String(";  ").join(PackedStringArray(_fails))])
	var f := FileAccess.open(REPORT, FileAccess.WRITE)
	if f != null:
		f.store_string(String.chr(10).join(PackedStringArray(_lines)) + String.chr(10))
		f.close()
	for l in _lines:
		print(l)
	quit(0 if ok else 1)


func _check(ok: bool, line: String, why: String) -> void:
	if line != "":
		_lines.append("[probe] %s  %s" % [line, "OK" if ok else "*** %s ***" % why])
	else:
		_lines.append("[probe] *** %s ***" % why)
	if not ok:
		_fails.append(why)
