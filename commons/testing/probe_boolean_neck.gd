extends SceneTree
## DOES DEEPENING THE SUBTRACTION PART THE BAR, AND ONLY THEN?
##
## The negative half matters more than the positive: at gap=open and gap=narrow
## the bar must STILL BE ONE PIECE, or the artifact is just a thing that falls
## apart and teaches nothing about where the threshold is. The thinnest-neck
## readout must also shrink monotonically as the bites deepen.
##
## (This used to be half of probe_neck_and_cusp. The droplet half moved to
## probe_droplet_fit when that artifact was rebuilt as a physics experiment.)

const NECK := "res://commons/artifacts/boolean_neck/boolean_neck.tscn"


func _neck(gap: String, row: String) -> Node:
	var n = load(NECK).instantiate()
	n.set("row", row)
	n.set("gap", gap)
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

	var seen := []
	for g in ["open", "narrow", "pinched", "severed"]:
		var n = _neck(g, "even")
		await process_frame
		seen.append([g, n.piece_count(), n.thinnest_neck() * 1000.0])
		print("  %-8s pieces=%d  thinnest neck=%.2f mm" % [g, n.piece_count(), n.thinnest_neck() * 1000.0])

	if seen[0][1] != 1 or seen[1][1] != 1:
		print("   FAIL open/narrow already in pieces -- no threshold is being shown")
		fails += 1
	if seen[3][1] <= 1:
		print("   FAIL severed did not part the bar; the subtraction never reaches the midline")
		fails += 1
	for i in range(3):
		if seen[i + 1][2] > seen[i][2] + 1e-6:
			print("   FAIL neck got THICKER as the gap deepened: %s -> %s" % [seen[i][0], seen[i + 1][0]])
			fails += 1

	var single = _neck("severed", "single")
	await process_frame
	print("  single/severed pieces=%d   (must be 2: one cut, two bars)" % single.piece_count())
	if single.piece_count() != 2:
		fails += 1

	var steals := 0
	for cls in ["Camera3D", "WorldEnvironment", "CanvasLayer", "DirectionalLight3D"]:
		steals += _count(single, cls)
	print("  steals (cam/env/canvas/light) = %d   (must be 0)" % steals)
	if steals > 0:
		fails += 1

	print("\nprobe_boolean_neck: %s" % ("PASS" if fails == 0 else "%d FAILED" % fails))
	quit(0 if fails == 0 else 1)
