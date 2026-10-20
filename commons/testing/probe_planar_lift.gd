extends SceneTree
## DOES THE PLANE FORCE THE CROSSINGS, AND DOES SPACE DISSOLVE THEM?
##
## Three claims, each with its negative half:
##  1. k5 flat has EXACTLY 5 crossings and they genuinely collide; k33 flat has
##     exactly 9. Computed from the drawn chords, not quoted from a book.
##  2. Lifted, the crossings in the plane DO NOT CHANGE (an arc's shadow runs
##     where its chord runs) while collisions in space go to zero with real
##     clearance. The gap between the two numbers is the artifact.
##  3. wheel is the control: planar, zero crossings even flat, so the red marks
##     on k5 are facts about k5 and not about flatness itself.

const SCENE := "res://commons/artifacts/planar_lift/planar_lift.tscn"


func _mk(graph: String, lift: String) -> Node:
	var n = load(SCENE).instantiate()
	n.set("graph", graph)
	n.set("lift", lift)
	get_root().add_child(n)
	return n


func _count(n: Node, cls: String) -> int:
	var k := 0
	if n.get_class() == cls:
		k += 1
	for c in n.get_children():
		k += _count(c, cls)
	return k


func _init() -> void:
	var fails := 0

	var a = _mk("k5", "flat")
	await process_frame
	print("1  k5/flat     crossings=%d collisions=%d   (must be 5, 5)"
		% [a.crossings_in_plane(), a.collisions_in_space()])
	if a.crossings_in_plane() != 5 or a.collisions_in_space() != 5:
		fails += 1
		print("   FAIL the pentagon-and-pentagram drawing of K5 has exactly 5 chord crossings")

	var b = _mk("k5", "lifted")
	await process_frame
	var clear_mm: float = b.min_clearance_m() * 1000.0
	print("2  k5/lifted   crossings=%d collisions=%d clearance=%.1f mm   (5, 0, >2)"
		% [b.crossings_in_plane(), b.collisions_in_space(), clear_mm])
	if b.crossings_in_plane() != 5:
		fails += 1
		print("   FAIL lifting changed the SHADOW -- the projection must be untouched")
	if b.collisions_in_space() != 0 or clear_mm <= 2.0:
		fails += 1
		print("   FAIL the resolve pass left touching arcs; the lift did not dissolve the plane's verdict")

	var c = _mk("k33", "flat")
	await process_frame
	print("3  k33/flat    crossings=%d collisions=%d   (must be 9, >0)"
		% [c.crossings_in_plane(), c.collisions_in_space()])
	if c.crossings_in_plane() != 9 or c.collisions_in_space() == 0:
		fails += 1
		print("   FAIL two sorted rows of three give one crossing per pair of pairs: 9")

	var d = _mk("k33", "lifted")
	await process_frame
	print("4  k33/lifted  collisions=%d   (must be 0)" % d.collisions_in_space())
	if d.collisions_in_space() != 0:
		fails += 1

	var e = _mk("wheel", "flat")
	await process_frame
	print("5  wheel/flat  crossings=%d collisions=%d   (must be 0, 0 -- the control)"
		% [e.crossings_in_plane(), e.collisions_in_space()])
	if e.crossings_in_plane() != 0 or e.collisions_in_space() != 0:
		fails += 1
		print("   FAIL the planar control crossed; the red marks would mean nothing")

	var f = _mk("k5", "slight")
	await process_frame
	print("6  k5/slight   collisions=%d clearance=%.1f mm   (0 -- separated by a hair)"
		% [f.collisions_in_space(), f.min_clearance_m() * 1000.0])
	if f.collisions_in_space() != 0:
		fails += 1
		print("   FAIL two centimetres of height should already separate every arc")

	var steals := 0
	for cls in ["Camera3D", "WorldEnvironment", "CanvasLayer", "DirectionalLight3D"]:
		steals += _count(a, cls)
	print("7  steals (cam/env/canvas/light) = %d   (must be 0)" % steals)
	if steals > 0:
		fails += 1

	print("probe_planar_lift: %s" % ("PASS" if fails == 0 else "%d FAILED" % fails))
	quit(0 if fails == 0 else 1)
