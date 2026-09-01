extends SceneTree
## Three blows must break the barrier — the bug this replaces let exactly ONE
## land, ever, because the hammer blacklisted every target it touched and the
## guard sat ABOVE the strike() call. hp froze at 2 and the barrier kept its
## 7-degree lean forever. That is the "it only tilts a bit" report.
##
## Note what this probe does NOT do: it does not simulate swing speed. The tilt
## is only reachable from inside strike(), so the observed symptom already
## proved the sweep, the mask and the speed gate were working. The defect was
## downstream of all of them.

func _init() -> void:
	var fails := 0
	var hammer_scene := load("res://commons/artifacts/line_sledgehammer/line_sledgehammer.tscn")
	var barrier_scene := load("res://commons/artifacts/do_not_cross_barrier/do_not_cross_barrier.tscn")

	var h = hammer_scene.instantiate()
	get_root().add_child(h)
	var b = barrier_scene.instantiate()
	get_root().add_child(b)
	# APART. Spawned on the same spot, the hammer's own sweep lands a real blow
	# during the settle frames and the count is off by one before the test
	# starts -- which is how the first run of this probe read "start hp = 2".
	b.global_position = Vector3(0, 0, 40)
	await process_frame
	await process_frame

	var at: Vector3 = b.global_position
	var hp0: int = b.hit_points_left()
	print("start hp = %d (must be 3)" % hp0)
	if hp0 != 3:
		print("  FAIL something already hit it"); fails += 1

	# THREE BLOWS
	for i in range(3):
		var landed: bool = h._try_break(b, at)
		var hp: int = b.hit_points_left() if is_instance_valid(b) else -1
		var gone: bool = (not is_instance_valid(b)) or b.is_broken()
		print("blow %d: landed=%s hp=%d broken=%s" % [i + 1, landed, hp, gone])
		if not landed:
			print("  FAIL blow %d never reached strike() — the blacklist bit again" % (i + 1))
			fails += 1
		if i < 2 and gone:
			print("  FAIL it broke after only %d blow(s)" % (i + 1)); fails += 1

	if is_instance_valid(b) and not b.is_broken():
		print("  FAIL three blows did not break it"); fails += 1
	else:
		print("broken after three blows: ok")

	# NEGATIVE: a fourth swing at a dead target must not land
	if is_instance_valid(b):
		if h._try_break(b, at):
			print("  FAIL a broken barrier took a fourth blow"); fails += 1

	# THE LASER CONTRACT — one beam clears it outright, because
	# trigger_explosion() returns void and cannot report a survivor.
	var b2 = barrier_scene.instantiate()
	get_root().add_child(b2)
	await process_frame
	await process_frame
	b2.trigger_explosion()
	print("beam on a fresh barrier -> broken=%s (must be true)" % b2.is_broken())
	if not b2.is_broken():
		print("  FAIL the beam can no longer clear the way"); fails += 1

	print("")
	print("PROBE %s" % ("OK" if fails == 0 else "FAILED %d" % fails))
	quit(fails)
