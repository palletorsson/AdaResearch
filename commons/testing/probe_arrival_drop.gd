extends SceneTree

## Does a new map begin four metres up, and does the visitor LAND? (2026-09-06)
##
## Palle: "when I start a new map drop me from y = 4 m."
##
## Two claims, and only one of them is about the number. Placing a body at y 4 is
## an assignment and cannot really go wrong. What can go wrong is everything
## after it:
##
##   the floor is not built yet   the museum streams, and the walker is created
##                                in _setup_world before any segment exists. A
##                                visitor who falls through an unbuilt deck is
##                                caught by _catch_if_fallen and set down at a
##                                save point — which LOOKS like a normal arrival
##                                and is a rescue.
##   the fall never ends          a clamp, a zeroed velocity, a body resting on
##                                nothing: y stays at 4 and the visitor is
##                                standing in the air, which no print would say.
##   the catch fires              _catches going up is the museum saying it
##                                rescued you. An arrival that needs rescuing is
##                                not an arrival.
##
## So the probe watches the fall to its end and reads _catches on the way out.
##
##   godot --path . --xr-mode off --script res://commons/testing/probe_arrival_drop.gd -- --em-segments=2

const MUSEUM := "res://commons/scenes/endless_museum.tscn"
const LAYOUT := "res://commons/data/em_layout.json"
const REPORT := "res://ada_run/arrival_drop_probe.txt"

var _lines: Array[String] = []
var _fails: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var want: float = _drop_m()
	_lines.append("[probe] em_layout arrival.drop_m = %.2f" % want)

	var mus: Node3D = (load(MUSEUM) as PackedScene).instantiate() as Node3D
	root.add_child(mus)
	await process_frame
	await process_frame

	# ── 1. the arrival point itself ──────────────────────────────────────
	# ABOVE THE FLOOR, not above zero. _drop_point measures the deck under the
	# arrival cell and adds the drop, so on a converted hall whose floor is 2 m up
	# the right answer is 6, and a probe asserting 4 would fail the fix.
	var target: Vector3 = mus.call("_drop_point")
	var deck: float = _deck_at(mus, target)
	var over: float = target.y - maxf(deck, 0.0)
	_check(absf(over - want) < 0.15,
		"the walk begins at %s — %.2f m over a deck at %.2f" % [
			str(target.snapped(Vector3(0.1, 0.01, 0.1))), over, deck],
		"the walk begins at y %.2f, %.2f m over the deck at %.2f — arrival.drop_m asks for %.2f" % [
			target.y, over, deck, want])

	# ── 2. and the walker was actually PUT there ─────────────────────────
	# _drop_point is a function; _setup_world assigning its result to the walker
	# is a separate fact, and the one the visitor experiences.
	var player: Node3D = mus.get("_player")
	if player == null:
		_check(false, "", "no walker on a desktop boot — this probe cannot watch a fall")
		_finish()
		return
	# THE HIGHEST y SEEN, not the instantaneous one. Gravity is running from the
	# frame the walker exists, so by the time a probe can read the field the
	# visitor has already fallen a little — the first version read 3.63 and
	# reported the museum had moved the walker off its own arrival point. It had
	# not; the probe was late.
	var floor_here: float = _floor_under(player.position)
	var start_y: float = player.position.y
	_check(start_y >= floor_here + want - 0.5,
		"the walker came in at y %.2f, over a floor at %.2f — %.2f m of fall%s" % [
			start_y, floor_here, start_y - floor_here,
			"" if absf(start_y - floor_here - want) < 0.5 else " (gravity had already run)"],
		"the walker is at y %.2f over a floor at %.2f — %.2f m, and arrival.drop_m asks for %.2f" % [
			start_y, floor_here, start_y - floor_here, want])

	# ── 3. the fall ends, on a floor, without a rescue ───────────────────
	var catches_before: int = int(mus.get("_catches"))
	var lowest: float = start_y
	# A SEPARATE FLAG, not a sentinel value. The first version used -1.0 for "not
	# settled" and then tested settled_at >= 0.0, so a visitor who came to rest at
	# y -0.147 — a perfectly good deck slightly below zero — was reported as never
	# having landed. The sentinel and the measurement shared a number line.
	var settled: bool = false
	var settled_at: float = 0.0
	var t0: int = Time.get_ticks_msec()
	var last_y: float = start_y
	var still: int = 0
	while Time.get_ticks_msec() - t0 < 6000:
		await physics_frame
		var y: float = player.position.y
		lowest = minf(lowest, y)
		# 5 mm, not 1 mm. A CharacterBody3D resting on a deck creeps by fractions
		# of a millimetre for as long as you watch it; the first version demanded
		# 1 mm of stillness twelve frames running and reported a landed visitor as
		# "never came to rest" at y -0.147 on a floor at -0.218.
		if absf(y - last_y) < 0.005:
			still += 1
			if still >= 10 and not settled:
				settled = true
				settled_at = y
				break
		else:
			still = 0
		last_y = y
	var fell_s: float = float(Time.get_ticks_msec() - t0) / 1000.0

	_check(settled,
		"the fall ended after %.2f s at y %.3f" % [fell_s, settled_at],
		"y was still moving after %.1f s (now %.2f, lowest %.2f) — the visitor never came to rest" % [
			fell_s, last_y, lowest])
	_check(settled and settled_at < start_y - 0.5,
		"  ...and it is %.2f m below where the visitor came in — they fell" % (start_y - settled_at),
		"  ...but only %.2f m below the start: nothing fell, the visitor is standing in the air at y %.2f" % [
			start_y - maxf(settled_at, 0.0), maxf(settled_at, start_y)])

	# THE CATCH IS THE TELL. It sets the visitor down at a save point when they
	# drop past the floor, and it does it silently enough that the arrival still
	# looks like an arrival. If it fired, the deck was not there to land on.
	var catches_after: int = int(mus.get("_catches"))
	_check(catches_after == catches_before,
		"  ...onto a floor that existed: _catch_if_fallen never fired",
		"  ...through the floor: the museum caught the visitor %d time(s) during the drop and set them down at a save point" % [
			catches_after - catches_before])

	# ── 4. AND NOT INSIDE IT, which is the actual complaint ──────────────
	# Palle: "I end up inside the floor and was stuck in transformation
	# sequence." The transformation maps were converted to RAISED floors on
	# 2026-09-06 (7a43d2a4b, d78de3be2) and every arrival in the museum was
	# written as a y of zero, so the visitor was placed under the deck. That does
	# not read as an error: settled, not caught, not moving — all three checks
	# above pass on a body sealed inside a floor. The tell is that the deck is
	# ABOVE them.
	var rest: Vector3 = player.position
	var under: float = _floor_under(rest)
	_check(under <= rest.y + 0.12,
		"the visitor stands ON the deck: feet y %.3f, floor %.3f" % [rest.y, under],
		"the visitor is INSIDE the floor — feet at y %.2f with %.2f m of deck above them" % [
			rest.y, under - rest.y])

	# and the body fits where it came to rest. margin 0.0: the default 0.04
	# reports a body RESTING on a floor as intersecting it.
	var space: PhysicsDirectSpaceState3D = root.world_3d.direct_space_state
	var cap := CapsuleShape3D.new()
	cap.radius = 0.32
	cap.height = 1.5
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = cap
	q.transform = Transform3D(Basis(), rest + Vector3(0.0, 0.75, 0.0))
	q.margin = 0.0
	# EXCLUDING THE WALKER. The first run reported the visitor stuck inside
	# "Walker:<CharacterBody3D>" — itself. A body always intersects its own shape.
	q.exclude = [player.get_rid()]
	var hits: Array = space.intersect_shape(q, 4)
	var names := PackedStringArray()
	for h in hits:
		names.append(str(h.get("collider", "?")))
	_check(hits.is_empty(),
		"  ...and the walker's capsule stands clear — not stuck",
		"  ...but the capsule is inside %d thing(s): %s" % [hits.size(), String(", ").join(names)])

	# ── 5. A RAISED CELL, which is where the report came from ────────────
	# Palle: "I end up inside the floor and was stuck in transformation sequence."
	# The transformation halls were converted to the heights layer this morning,
	# and every arrival in this file was written as a y of ZERO — so on a cell
	# whose deck stands a metre up, the visitor is placed inside it.
	#
	# The hall the museum happens to open at may not have a raised arrival cell
	# (Trans_Pre, Trans_Rotation and Trans_RotationSpectacle are all level 0 at
	# (7, 1), measured). So the fix is tested where it BITES: on a cell the walk
	# map says is raised, asked of the same function the arrival uses.
	var wh: Variant = mus.get("_walk_h")
	var raised := Vector2i(0, 0)
	var raised_h: float = 0.0
	var n_raised: int = 0
	if wh is Dictionary:
		for k in (wh as Dictionary):
			var h: float = float((wh as Dictionary)[k])
			if h > 0.05:
				n_raised += 1
				if raised_h <= 0.0:
					raised = k
					raised_h = h
	if n_raised == 0:
		var n_cells: int = (wh as Dictionary).size() if wh is Dictionary else -1
		_lines.append("[probe] _walk_h holds %d cell(s) and NONE is raised — so the floor-aware arrival is inert in the halls this run built, and untested by it" % n_cells)
	else:
		var a: Vector3 = mus.call("_arrival_at", float(raised.x) + 0.5, float(raised.y) + 0.5)
		_check(absf(a.y - (raised_h + want)) < 0.01,
			"a raised cell (%d, %d) stands %.2f m up, and an arrival there is at y %.2f — %.2f m over its OWN deck, not over zero (%d raised cell(s) in these halls)" % [
				raised.x, raised.y, raised_h, a.y, a.y - raised_h, n_raised],
			"a raised cell (%d, %d) stands %.2f m up but an arrival there is at y %.2f — %.2f m over the deck, and the visitor lands %s it" % [
				raised.x, raised.y, raised_h, a.y, a.y - raised_h,
				"inside" if a.y < raised_h else "over"])
		_check(a.y > raised_h,
			"  ...so the visitor is above the deck rather than sealed under it",
			"  ...which is INSIDE the deck: y %.2f under a floor at %.2f" % [a.y, raised_h])

	_finish()


## The first surface above the feet, or the one under them when there is none —
## a body standing ON a deck and a body sealed UNDER it are told apart by which.
func _floor_under(at: Vector3) -> float:
	# FROM JUST OVER THE FEET, not from the sky. Casting from at.y + 30 takes the
	# first thing it meets, which over a roofed hall is the CEILING — it reported
	# the deck at 10.63 m in a room whose floor is zero, and the museum was
	# briefly starting the walk fourteen metres up because of it.
	var space: PhysicsDirectSpaceState3D = root.world_3d.direct_space_state
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(at.x, at.y + 0.30, at.z), Vector3(at.x, at.y - 8.0, at.z))
	var hit: Dictionary = space.intersect_ray(q)
	return float(hit.get("position", Vector3(0, -999, 0)).y) if not hit.is_empty() else -999.0


## The museum's own record of how high this cell's deck stands.
func _deck_at(mus: Node3D, at: Vector3) -> float:
	var wh: Variant = mus.get("_walk_h")
	if wh is Dictionary:
		return float((wh as Dictionary).get(Vector2i(int(floor(at.x)), int(floor(at.z))), 0.0))
	return 0.0


func _drop_m() -> float:
	if not FileAccess.file_exists(LAYOUT):
		return 4.0
	var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT))
	if v is Dictionary and (v as Dictionary).get("arrival") is Dictionary:
		return clampf(float(((v as Dictionary)["arrival"] as Dictionary).get("drop_m", 4.0)), 0.0, 12.0)
	return 4.0


func _check(ok: bool, line: String, why: String) -> void:
	_lines.append("[probe] %s  %s" % [line, "OK" if ok else "*** %s ***" % why])
	if not ok:
		_fails.append(why)


func _finish() -> void:
	var ok: bool = _fails.is_empty()
	_lines.append("[probe] %s%s" % ["PASS" if ok else "FAIL",
		"" if ok else " — " + String(";  ").join(PackedStringArray(_fails))])
	var f := FileAccess.open(REPORT, FileAccess.WRITE)
	if f != null:
		f.store_string(String.chr(10).join(PackedStringArray(_lines)) + String.chr(10))
		f.close()
	for l in _lines:
		print(l)
	quit(0 if ok else 1)
