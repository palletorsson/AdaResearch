extends SceneTree

## Does prism_block stand ON the floor, in both placement lanes?
##
## 2026-09-08, Palle, with a screenshot of the Melencolia court: "prism_block is
## under the floor by default can you fix that".
##
## The prism shipped centred on its node origin (PrismMesh size (1,1,1), base at
## y -0.5), upright only because the grid's _auto_ground_artifact lifted it at
## placement time — and auto-grounding is SKIPPED when a token carries an
## explicit y, which seven maps write. So this checks the artifact itself, where
## the fix belongs: instanced bare, with no grid and nobody to ground it, its
## geometry must already sit at or above its own origin.
##
## Also walks every grain, because each builds different children through
## _adopt and a lift applied in one branch only would pass a single-variant test.
##
##   godot --headless --path . --xr-mode off \
##     --script res://commons/testing/probe_prism_grounded.gd

const PRISM := "res://commons/primitives/prismes/prism_block.tscn"
const GRAINS := ["solid", "split", "quartered", "lattice", "shell"]

var _fail := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)

	for grain in GRAINS:
		var n: Node3D = (load(PRISM) as PackedScene).instantiate() as Node3D
		n.set("grain", grain)
		world.add_child(n)
		await physics_frame
		await create_timer(0.3).timeout

		var vis := AABB()
		var got := false
		for x in _all(n):
			var mi := x as MeshInstance3D
			if mi == null or mi.mesh == null or not mi.is_visible_in_tree():
				continue
			var b: AABB = (mi.global_transform * mi.get_aabb())
			vis = b if not got else vis.merge(b)
			got = true
		var col := AABB()
		var gotc := false
		for x in _all(n):
			var cs := x as CollisionShape3D
			if cs == null or cs.shape == null:
				continue
			var cb: AABB = cs.global_transform * cs.shape.get_debug_mesh().get_aabb()
			col = cb if not gotc else col.merge(cb)
			gotc = true

		if not got:
			_say(false, "%-10s has visible geometry" % grain, "no visible mesh")
			n.queue_free()
			continue
		# the node stands at the origin, so the floor is y = 0.
		#
		# THE UNIT IS WHAT IS GROUNDED, NOT THE OUTERMOST VERTEX. `shell` builds
		# struts ON the unit's edges (STRUT 0.05), so half a strut hangs below
		# y 0 and exactly as much rises above y 1 — a symmetric straddle, which is
		# the variant drawing the cube's frame rather than a grounding error. So
		# the assertion is: nothing dips more than a strut's half-thickness, AND
		# whatever dips is matched at the top. A real sinking (the 0.5 m this
		# probe was written for) fails both.
		var base_y: float = vis.position.y
		var top_y: float = vis.position.y + vis.size.y
		var below: float = maxf(0.0, -base_y)
		var above: float = maxf(0.0, top_y - 1.0)
		# nothing below the floor at all — or, for the frame variants, no more than
		# half a strut and matched by the same overhang on top. `split` is taller
		# than the unit by its own 0.04 gap and dips by nothing, which is why the
		# two clauses are OR and not AND.
		_say(below <= 0.005 or (below <= 0.04 and absf(below - above) < 0.01),
			"%-10s stands on its origin (base %+.3f, top %+.3f)" % [grain, base_y, top_y],
			"under the floor by %.3f m against %.3f m proud of the top — not a straddle"
				% [below, above])
		if gotc:
			_say(col.position.y > -0.02,
				"%-10s collider base y %+.3f" % [grain, col.position.y],
				"the hull is %.3f m under the floor" % (-col.position.y))
		n.queue_free()
		await physics_frame

	print("[probe] %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(1 if _fail > 0 else 0)


func _say(ok: bool, said: String, why: String = "") -> void:
	if ok:
		print("[probe] %s  OK" % said)
	else:
		_fail += 1
		print("[probe] %s  FAIL%s" % [said, ("  — " + why) if why != "" else ""])


func _all(x: Node) -> Array:
	var out: Array = [x]
	for c in x.get_children():
		out.append_array(_all(c))
	return out
