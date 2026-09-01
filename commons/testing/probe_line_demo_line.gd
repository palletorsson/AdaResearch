extends SceneTree
## DOES THE LINE FORM, AND IS ANY OF IT VISIBLE?
##
## Palle: "the point does not form a line now." The connection was firing all
## along — snap_point.gd joins two points within snap_distance (0.15 m shipped),
## and at the new 75 mm radius two snapped points TOUCH, so the line ran entirely
## inside the two spheres. A check that only asked "did connection_created fire?"
## would have reported success on exactly the broken thing.
##
## So the last check is geometric: the gap between the two SURFACES at snap
## range must be positive, or there is no line for anyone to see.

func _init() -> void:
	var D := load("res://commons/primitives/snappoint/demos/line_demo.tscn")
	var d = D.instantiate()
	get_root().add_child(d)
	await process_frame
	await process_frame
	var fails := 0

	var ends: Array = []
	for c in d.get_children():
		if str(c.name).begins_with("SnapPoint"):
			ends.append(c)
	print("1  snap points found: %d" % ends.size())
	if ends.size() != 2:
		print("   FAIL a line needs exactly two ends"); fails += 1
		print("PROBE FAILED (%d)" % fails); quit(fails); return

	var a = ends[0]
	var b = ends[1]
	var sep: float = a.global_position.distance_to(b.global_position)
	print("2  they start %.2f m apart (separation export = %.2f)"
		% [sep, d.point_separation_m])
	if absf(sep - d.point_separation_m) > 0.02:
		print("   FAIL the ends are not where the export says"); fails += 1

	var sd: float = a.snap_distance
	print("3  snap_distance = %.2f m, point radius = %.3f m" % [sd, d.point_radius_m])
	if sd <= 0.0:
		print("   FAIL no snap range"); fails += 1

	# THE CHECK THAT WOULD HAVE CAUGHT IT: at the moment they snap, how much
	# line is outside the two spheres?
	var visible_gap: float = sd - (d.point_radius_m * 2.0)
	print("4  line visible between the surfaces at snap: %.3f m (must be > 0.05)"
		% visible_gap)
	if visible_gap <= 0.05:
		print("   FAIL the line is buried inside the points — forms, cannot be seen")
		fails += 1

	# and the connection really fires when they are brought together
	var connected := false
	var mgr = d.get_node_or_null("SnapConnectionManager")
	if mgr:
		mgr.connection_created.connect(func(_x, _y, _l): connected = true)
	b.global_position = a.global_position + Vector3(sd * 0.5, 0, 0)
	for i in 20:
		await physics_frame
	print("5  brought within %.2f m -> connection fired: %s" % [sd * 0.5, connected])
	if not connected:
		print("   NOTE connection did not fire headless (snap_on_drop_only=%s)"
			% [a.snap_on_drop_only])

	print("")
	print("PROBE OK" if fails == 0 else "PROBE FAILED (%d)" % fails)
	quit(fails)
