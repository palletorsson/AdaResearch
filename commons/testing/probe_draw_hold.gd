extends Node3D

## Does HOLD-TO-DRAW actually lay points? (2026-08-29)
##
## draw_triangle_faces used to place one point per RELEASE. It now lays one on a
## timer while held, gated on the hand having travelled off the last point. Both
## halves of that are easy to get wrong in a way that looks like nothing: a timer
## with no distance gate lays points on top of each other and the snap logic
## refuses each of them in silence, and a distance gate that is too eager lays
## none at all. So this drives the artifact directly and counts.
##
## A SCENE, not a --script probe: draw_triangle_faces names the SoundBank autoload,
## and an `extends SceneTree` script cannot compile anything that does.
##
##   godot --path . res://commons/testing/probe_draw_hold.tscn --xr-mode off

const ART := "res://commons/primitives/point/draw_triangle_faces.tscn"


func _ready() -> void:
	var ps: PackedScene = load(ART)
	if ps == null:
		print("[probe] no scene at %s" % ART)
		get_tree().quit(1)
		return
	var art: Node3D = ps.instantiate() as Node3D
	add_child(art)
	await get_tree().process_frame
	await get_tree().process_frame

	var sphere: Node3D = art.get("_draw_sphere") as Node3D
	if sphere == null:
		print("[probe] FAIL — the artifact has no _draw_sphere; it never resolved its own path")
		get_tree().quit(1)
		return

	print("[probe] hold_place_seconds=%.2f  hold_place_min_travel=%.3f  snap=%.3f" % [
		float(art.get("hold_place_seconds")), float(art.get("hold_place_min_travel")),
		float(art.get("point_snap_distance"))])

	# ── 1. a STILL hand must lay nothing after the first point ───────────────
	art.set("_is_grabbed", true)
	sphere.global_position = Vector3(0, 1.2, 0)
	for i in range(12):                      # 6 simulated seconds
		art._process(0.5)
	var still: int = (art.get("placed_points") as Array).size()
	print("[probe] still hand, 6 s held      -> %d point(s)  %s" % [
		still, "OK (one, then it stops)" if still == 1 else "*** expected exactly 1 ***"])

	# ── 2. a MOVING hand must lay one per interval ───────────────────────────
	var before: int = still
	for i in range(12):                      # 6 more seconds, 0.30 m per half second
		sphere.global_position += Vector3(0.30, 0, 0)
		art._process(0.5)
	var moved: int = (art.get("placed_points") as Array).size() - before
	print("[probe] moving hand, 6 s held     -> %d new point(s) %s" % [
		moved, "OK (about one a second)" if moved >= 5 and moved <= 7 else "*** expected 5-7 ***"])

	# ── 3. turning it off must restore the old behaviour ─────────────────────
	art.set("hold_place_seconds", 0.0)
	var before2: int = (art.get("placed_points") as Array).size()
	for i in range(12):
		sphere.global_position += Vector3(0.30, 0, 0)
		art._process(0.5)
	var off: int = (art.get("placed_points") as Array).size() - before2
	print("[probe] disabled, 6 s held        -> %d new point(s) %s" % [
		off, "OK (silent)" if off == 0 else "*** expected 0 ***"])

	var ok: bool = still == 1 and moved >= 5 and moved <= 7 and off == 0
	print("[probe] %s" % ("PASS" if ok else "FAIL"))
	get_tree().quit(0 if ok else 1)
