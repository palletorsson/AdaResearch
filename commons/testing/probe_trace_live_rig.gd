extends SceneTree
## Does player_trace follow the rig the visitor DRIVES, and can a map token
## switch on the second line?
##
## 2026-09-02, Palle: "in VR I do not see the trace in museum." Under the
## shipped game loop there are TWO XROrigin3D in the tree -- the staging's menu
## rig, first in the tree and never moving, and the loaded scene's, which the
## visitor drives. The old finder took the first it met and cached it forever.
## The museum itself had this bug and fixed it (_vr_eye, 2026-08-18); this
## probe builds that exact tree and asks the recorder which one it shadows.
##
## Seven checks, three of them negatives:
##   1  two rigs, the SECOND is current -> the recorder shadows the second
##   2  moving the dead rig writes nothing                    <- negative
##   3  moving the live rig writes points
##   4  `current` flips to the other rig -> the recorder follows, and the
##      trail RESTARTS (no phantom segment across the room)
##   5  apply_grid_config with STRING values (what the museum sends) reaches
##      seam_grid and show_discarded
##   6  with seam_grid 1.0 every kept point sits on the metre lattice, and the
##      faint line holds points that do NOT
##   7  with seam_grid 0 the kept points leave the lattice     <- negative

func _init() -> void:
	var fails := 0
	var root := get_root()

	# the staging rig: first in the tree, never current, never moves
	var dead := XROrigin3D.new()
	dead.name = "XROrigin3D"
	root.add_child(dead)
	# a hall segment, the way the museum parents artifacts: no ../../XROrigin3D
	var hall := Node3D.new()
	hall.name = "Segment"
	root.add_child(hall)
	# the driven rig: added LAST, and current
	var live := XROrigin3D.new()
	live.name = "XROrigin3D"
	root.add_child(live)
	live.set("current", true)
	live.global_position = Vector3(4, 0, 4)

	var scene := load("res://commons/primitives/point/player_trace.tscn")
	var tr = scene.instantiate()
	hall.add_child(tr)
	await process_frame
	await process_frame

	# ---- 1. which rig? ----
	var got: Node = tr._xr_origin
	print("1  recorder shadows: %s (live=%s dead=%s)" % [got, got == live, got == dead])
	if got != live:
		print("   FAIL it took the wrong rig"); fails += 1

	# ---- 2. NEGATIVE: the dead rig moving writes nothing ----
	var n0: int = tr._trail_points.size()
	for i in 8:
		dead.global_position += Vector3(0.4, 0, 0)
		await process_frame
	print("2  dead rig moved 3.2 m: points %d -> %d (must not grow)" % [n0, tr._trail_points.size()])
	if tr._trail_points.size() != n0:
		print("   FAIL the recorder followed a rig nobody is in"); fails += 1

	# ---- 3. the live rig moving writes ----
	for i in 8:
		live.global_position += Vector3(0.4, 0, 0)
		await process_frame
	var n1: int = tr._trail_points.size()
	print("3  live rig moved 3.2 m: points -> %d (must grow)" % n1)
	if n1 <= n0:
		print("   FAIL the recorder did not follow the live rig"); fails += 1

	# ---- 4. current flips: follow, and RESTART ----
	live.set("current", false)
	dead.set("current", true)
	dead.global_position = Vector3(-6, 0, -6)
	var switched := false
	for i in 400:
		await process_frame
		if tr._xr_origin == dead:
			switched = true
			break
	var after_switch: int = tr._trail_points.size()
	print("4  after the flip: shadows dead=%s, trail restarted at %d points (must be 0)" % [switched, after_switch])
	if not switched:
		print("   FAIL never re-resolved to the rig that became current"); fails += 1
	if after_switch != 0:
		print("   FAIL kept the old walk: one segment would span the room"); fails += 1
	for i in 4:
		dead.global_position += Vector3(0, 0, 0.4)
		await process_frame
	if tr._trail_points.size() == 0:
		print("   FAIL followed the new rig but wrote nothing"); fails += 1
	else:
		var seg: float = 0.0
		if tr._trail_points.size() >= 2:
			seg = tr._trail_points[-1].distance_to(tr._trail_points[-2])
		print("   first segment after the switch: %.2f m (a phantom would be ~14 m)" % seg)
		if seg > 2.0:
			print("   FAIL phantom segment"); fails += 1

	# ---- 5. STRING config, as the museum sends it ----
	tr.apply_grid_config({"seam_grid": "1.0", "show_discarded": "1"})
	print("5  seam_grid=%.2f show_discarded=%s (must be 1.00 / true)" % [tr.seam_grid, tr.show_discarded])
	if tr.seam_grid != 1.0 or not tr.show_discarded:
		print("   FAIL a string in the token did not reach the export"); fails += 1

	# ---- 6. lattice: kept points on it, faint points off it ----
	dead.set("current", false)
	live.set("current", true)
	for i in 400:
		await process_frame
		if tr._xr_origin == live:
			break
	live.global_position = Vector3(0.3, 0, 0.3)
	await process_frame
	for i in 30:
		live.global_position += Vector3(0.13, 0, 0.13)   # a diagonal, off-lattice steps
		await process_frame
	var kept: int = tr._trail_points.size()
	var off_lattice := 0
	for p in tr._trail_points:
		var lp: Vector3 = p - hall.global_position   # trail points are local to the recorder
		if absf(lp.x - roundf(lp.x)) > 0.001 or absf(lp.z - roundf(lp.z)) > 0.001:
			off_lattice += 1
	var truth: int = tr._truth_points.size()
	var truth_off := 0
	for p in tr._truth_points:
		if absf(p.x - roundf(p.x)) > 0.001 or absf(p.z - roundf(p.z)) > 0.001:
			truth_off += 1
	print("6  kept %d points, %d off the metre lattice (must be 0); faint %d points, %d off it (must be >0)"
		% [kept, off_lattice, truth, truth_off])
	if kept == 0 or off_lattice != 0:
		print("   FAIL the kept line is not the staircase"); fails += 1
	if truth == 0 or truth_off == 0:
		print("   FAIL the faint line is not the walk as walked"); fails += 1

	# ---- 7. NEGATIVE: with the grid off, the kept points leave the lattice ----
	tr.apply_grid_config({"seam_grid": "0"})
	tr._trail_points.clear(); tr._trail_times.clear(); tr._trail_speeds.clear()
	for i in 12:
		live.global_position += Vector3(0.13, 0, 0.13)
		await process_frame
	var off2 := 0
	for p in tr._trail_points:
		if absf(p.x - roundf(p.x)) > 0.001 or absf(p.z - roundf(p.z)) > 0.001:
			off2 += 1
	print("7  seam_grid 0: %d points, %d off the lattice (must be >0)" % [tr._trail_points.size(), off2])
	if off2 == 0:
		print("   FAIL the lattice bit with the grid switched off"); fails += 1

	print("")
	print("PROBE %s" % ("OK" if fails == 0 else "FAILED %d" % fails))
	quit(fails)
