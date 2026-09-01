extends SceneTree
## THREE BLOWS, AND WHAT COMES OUT.
##
## Palle: "like in Half-Life the object has some health so we need to hit like
## two or three times for it to be destroyed" + "super nice queer confetti that
## disappears soon."
##
## Seven checks. Two are about the confetti GOING — a burst that stays is debris,
## and a room whose destruction leaves permanent litter is a room keeping score.

func _init() -> void:
	var fails := 0
	var Barrier := load("res://commons/artifacts/do_not_cross_barrier/do_not_cross_barrier.tscn")
	var Conf := load("res://commons/artifacts/queer_confetti/queer_confetti.gd")

	var b = Barrier.instantiate()
	get_root().add_child(b)
	await process_frame
	await process_frame

	print("1  starts with %d hit point(s), broken=%s" % [b.hit_points_left(), b.is_broken()])
	if b.hit_points_left() != 3:
		print("   FAIL expected 3"); fails += 1

	# blow one and two must NOT break it
	for n in 2:
		var landed: bool = b.strike(b.global_position + Vector3(0, 1, 0), null)
		print("2.%d blow landed=%s  hp left=%d  broken=%s"
			% [n + 1, landed, b.hit_points_left(), b.is_broken()])
		if not landed:
			print("   FAIL a blow did not register"); fails += 1
		if b.is_broken():
			print("   FAIL destroyed in %d hit(s) — one swing means it never held" % (n + 1))
			fails += 1
		await process_frame

	# the third finishes it
	var last: bool = b.strike(b.global_position + Vector3(0, 1, 0), null)
	print("3  third blow: landed=%s broken=%s" % [last, b.is_broken()])
	if not b.is_broken():
		print("   FAIL still standing after three"); fails += 1

	# and a fourth is refused
	var extra: bool = b.strike()
	print("4  fourth blow returns %s (must be false)" % extra)
	if extra:
		print("   FAIL hitting a broken thing still counts"); fails += 1

	# ---- the confetti ----
	var c = Conf.burst(get_root(), Vector3(0, 1, 0), 40, 1.0)
	await process_frame
	await process_frame
	var pieces := 0
	for ch in c.get_children():
		if ch is MultiMeshInstance3D:
			pieces += ch.multimesh.instance_count
	print("5  burst made %d piece(s) across %d shape(s)" % [pieces, c.get_child_count()])
	if pieces < 40 or c.get_child_count() < 4:
		print("   FAIL a burst of one shape reads as machine output"); fails += 1

	# 6. it MOVES — read from the artifact's OWN transform array, not from the
	#    MultiMesh.
	#
	#    Measured, not assumed: headless, set_instance_transform() writes are not
	#    readable back at all. A one-node isolation test wrote (0.5, 0.25, 0) and
	#    read (0, 0, 0) — the dummy RenderingServer keeps no instance data. So a
	#    probe that verifies motion through get_instance_transform is testing the
	#    render server, finds it dead, and reports the artifact broken.
	var p0: Vector3 = (c._base[0][0] as Transform3D).origin
	for i in 20:
		await process_frame
	var p1: Vector3 = (c._base[0][0] as Transform3D).origin
	print("6  a piece travelled %.3f m in %.2f s of game time (must be > 0.01)"
		% [p0.distance_to(p1), c._age])
	if p0.distance_to(p1) <= 0.01:
		print("   FAIL the confetti is static"); fails += 1

	# 7. IT GOES. Counted in the burst's OWN age, because a headless frame is not
	#    16 ms — it is about 7, so a loop counting wall-clock never reaches the
	#    lifetime and reports permanent debris that is nothing of the kind.
	var life: float = c.lifetime
	var guard := 0
	while is_instance_valid(c) and guard < 2000:
		await process_frame
		guard += 1
	print("7  freed itself after its %.1f s lifetime: %s (must be true)"
		% [life, not is_instance_valid(c)])
	if is_instance_valid(c):
		print("   FAIL it stayed — that is debris, and debris keeps score"); fails += 1

	print("")
	print("PROBE OK" if fails == 0 else "PROBE FAILED (%d)" % fails)
	quit(fails)
