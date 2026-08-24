## test_em_seal_clamp.gd — the seal's two clamps, and whether either one speaks.
##
## THE FAULT. `_occupied_cells` clamps a body's footprint twice: meshes to
## MAX_SEAL_RADIUS (2), colliders to MAX_BODY_RADIUS (6). Cells outside a clamp
## stay in `_walk_cells` — the walk map calls them floor while the body stands in
## them — and that is the one obstruction a planner cannot route around, because
## the route it plans goes straight through the object.
##
## The mesh clamp has recorded its overflow since 2026-08-18. The collider clamp,
## which is the only one of the two that can actually stop a walker, recorded
## nothing until 2026-08-22, and its total is what `em_autopilot.json` prints as
## `seal_overflow` beside a failed walk. Gate F has now died three mornings with
## `seal_overflow: 0` in the verdict. That zero could not have risen.
##
## THE NEGATIVE HALF IS THE ARGUMENT. A recorder that fires on everything is as
## useless as one that fires on nothing — it would put an entry beside every
## artifact in the museum and drown the suspect in witnesses. So half these cases
## assert SILENCE: a body inside its clamp must produce no record at all.
##
## And `reaches_origin`, the third case: an extent that starts at (0,0,0) and
## runs out to the cell the body stands in is measuring the trip, not the body.
##
## No museum, no segment, no dressing pass — the claim is arithmetic on two
## boxes, so the test is arithmetic on two boxes.
##
##   godot --headless --path . --xr-mode off \
##     --script res://commons/testing/test_em_seal_clamp.gd
##
## Prints `EM SEAL CLAMP: PASS|FAIL — …` and exits with the failing count.
extends SceneTree

const EM := preload("res://commons/scenes/endless_museum.gd")

# A body dealt at cell (7, 50). MAX_SEAL_RADIUS 2 -> x 5..9, z 48..52.
#                               MAX_BODY_RADIUS 6 -> x 1..13, z 44..56.
const CX := 7
const CZ := 50

## raw = [x0, x1, z0, z1] as the floor of the live AABB; sealed = after the clamp.
## `bites` is what the instrument must say. Each row names the body it stands for.
const CASES: Array = [
	# ── the mesh clamp (radius 2) ────────────────────────────────────────────
	{"name": "mesh_inside", "by": "mesh",
		"raw": [6, 8, 49, 51], "sealed": [6, 8, 49, 51], "bites": false,
		"why": "a plinth 3x3: inside the clamp, nothing lost, nothing to say"},
	{"name": "mesh_exact", "by": "mesh",
		"raw": [5, 9, 48, 52], "sealed": [5, 9, 48, 52], "bites": false,
		"why": "5x5, the clamp's own span — the boundary must not be an overflow"},
	{"name": "mesh_wide", "by": "mesh",
		"raw": [2, 12, 48, 52], "sealed": [5, 9, 48, 52], "bites": true,
		"why": "an 11 m body sealed to 5: three cells left standing on each side"},
	{"name": "mesh_far_overhang", "by": "mesh",
		"raw": [5, 9, 48, 99], "sealed": [5, 9, 48, 52], "bites": true,
		"why": "laser_measure's 51-cell beam — decorative, but it must still count"},
	# ── the collider clamp (radius 6): the half that was silent ──────────────
	{"name": "collider_inside", "by": "collider",
		"raw": [4, 10, 47, 53], "sealed": [4, 10, 47, 53], "bites": false,
		"why": "a 7 m body: wider than the mesh clamp, still honest to the collider"},
	{"name": "collider_exact", "by": "collider",
		"raw": [1, 13, 44, 56], "sealed": [1, 13, 44, 56], "bites": false,
		"why": "13 cells, the widest corridor the templates build — sealed whole"},
	{"name": "collider_wide", "by": "collider",
		"raw": [0, 20, 44, 56], "sealed": [1, 13, 44, 56], "bites": true,
		"why": "two lab_rooms meeting across a 15-cell corridor: THE stall shape"},
	{"name": "collider_deep", "by": "collider",
		"raw": [1, 13, 40, 60], "sealed": [1, 13, 44, 56], "bites": true,
		"why": "over-deep in z alone — a clamp on one axis is still a clamp"},
]

## pos_z, size_z, cell z, and whether the extent is a trip rather than a body.
const ORIGIN_CASES: Array = [
	{"name": "homesick", "pos_z": 0.0, "size_z": 11767.7, "cz": 11767, "reaches": true,
		"why": "9_3_smart_rockets_vr as the ledger actually holds it"},
	{"name": "homesick_small", "pos_z": 1.2, "size_z": 2560.0, "cz": 2562, "reaches": true,
		"why": "dual_display_test: starts near the origin, ends at its own cell"},
	{"name": "big_but_local", "pos_z": 11554.0, "size_z": 50.0, "cz": 11579, "reaches": false,
		"why": "AntColonyV2, genuinely 50 m across and standing where it was dealt"},
	{"name": "near_origin", "pos_z": 0.0, "size_z": 30.0, "cz": 30, "reaches": false,
		"why": "inside the first segment the two pictures are the same; do not guess"},
	{"name": "long_but_offset", "pos_z": 300.0, "size_z": 400.0, "cz": 700, "reaches": false,
		"why": "a long body that does not start at the origin is merely long"},
]


func _initialize() -> void:
	var fails: Array = []

	print("%-20s %-9s %-22s %-8s %-8s  %s" % ["case", "clamp", "raw", "want", "got", "why"])
	print("-".repeat(118))
	for c0 in CASES:
		var c: Dictionary = c0
		var rec: Dictionary = EM.clamp_overflow(c["raw"], c["sealed"], String(c["by"]))
		var got: bool = not rec.is_empty()
		var want: bool = bool(c["bites"])
		if got != want:
			fails.append("%s: wanted %s, got %s" % [c["name"], "a record" if want else "silence",
				"a record" if got else "silence"])
		# a record that does not name its clamp is the fault this test exists for
		if got and String(rec.get("by", "")) != String(c["by"]):
			fails.append("%s: record does not name its clamp (by=%s)" % [c["name"], rec.get("by", "")])
		# and the loss must be countable, not just present
		if got and int(rec.get("lost_x", 0)) + int(rec.get("lost_z", 0)) <= 0:
			fails.append("%s: recorded an overflow that lost no cells" % c["name"])
		print("%-20s %-9s %-22s %-8s %-8s  %s" % [c["name"], c["by"], str(c["raw"]),
			str(want), str(got), c["why"]])

	print("")
	print("%-20s %-10s %-10s %-8s %-8s  %s" % ["origin case", "pos_z", "size_z", "want", "got", "why"])
	print("-".repeat(118))
	for c0 in ORIGIN_CASES:
		var c: Dictionary = c0
		var got: bool = EM.reaches_origin(float(c["pos_z"]), float(c["size_z"]), int(c["cz"]))
		var want: bool = bool(c["reaches"])
		if got != want:
			fails.append("origin/%s: wanted %s, got %s" % [c["name"], want, got])
		print("%-20s %-10.1f %-10.1f %-8s %-8s  %s" % [c["name"], c["pos_z"], c["size_z"],
			str(want), str(got), c["why"]])

	print("")
	if fails.is_empty():
		print("EM SEAL CLAMP: PASS — %d clamp cases (4 bite, 4 silent, both branches named) + %d origin cases" % [
			CASES.size(), ORIGIN_CASES.size()])
		quit(0)
		return
	print("EM SEAL CLAMP: FAIL %d" % fails.size())
	for f in fails:
		print("  - " + String(f))
	quit(fails.size())
