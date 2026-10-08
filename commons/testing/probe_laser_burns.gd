extends SceneTree
## THE BEAM MUST BREAK THE BARRIER, and only after the dwell.
##
## 2026-09-05, Palle: "let the laser destroy the do_not_cross_barrier". The
## barrier has advertised `trigger_explosion()` as "the laser's own contract"
## since it learned to break; the only caller in the corpus was the SLEDGEHAMMER
## honouring it on the laser's behalf. This proves the beam now does it itself.
##
## What is actually under test is the whole chain, not the last call in it: the
## raycast finding a collider, the walk UP from that collider to the node that
## carries the script, the dwell accumulating, and the contract firing once.
## Calling _burn() with the barrier handed to it would prove none of that.
##
## And the negative half matters more than the positive one. `burns` is off by
## default because laser_measure stands in 47 maps, so a probe that only shows
## the beam breaking things would pass just as happily on a build where the
## default had flipped.

func _init() -> void:
	var fails := 0
	var barrier_scene := load("res://commons/artifacts/do_not_cross_barrier/do_not_cross_barrier.tscn")
	var laser_script := load("res://commons/primitives/laser_measure/laser_measure.gd")

	# ── 1. THE DEFAULT DOES NOT BURN ─────────────────────────────────────────
	var b0 = barrier_scene.instantiate()
	get_root().add_child(b0)
	b0.global_position = Vector3(0, 0, -3)
	var quiet := Node3D.new()
	quiet.set_script(laser_script)
	get_root().add_child(quiet)
	quiet.global_position = Vector3.ZERO
	await process_frame
	await physics_frame
	await physics_frame
	for i in range(120):                      # four seconds of dwell at 30 Hz
		quiet.perform_measurement()
	var untouched: bool = is_instance_valid(b0) and not b0.is_broken()
	print("1  default (burns off): barrier standing = %s  (must be true)" % untouched)
	if not untouched:
		print("   FAIL a laser that was only measuring took down the scenery")
		fails += 1
	if is_instance_valid(b0):
		b0.queue_free()
	quiet.queue_free()
	await process_frame

	# ── 2. WITH burns ON, THE DWELL IS REQUIRED ──────────────────────────────
	var b1 = barrier_scene.instantiate()
	get_root().add_child(b1)
	b1.global_position = Vector3(0, 0, -3)
	var hot := Node3D.new()
	hot.set_script(laser_script)
	hot.set("burns", true)
	hot.set("burn_seconds", 1.2)
	get_root().add_child(hot)
	hot.global_position = Vector3.ZERO
	await process_frame
	await physics_frame
	await physics_frame

	# HALF the dwell: 18 ticks at 30 Hz is 0.6 s against a 1.2 s burn.
	for i in range(18):
		hot.perform_measurement()
	var early: bool = is_instance_valid(b1) and not b1.is_broken()
	print("2  half the dwell: barrier standing = %s  (must be true)" % early)
	if not early:
		print("   FAIL the dwell is not being counted — a sweep would clear a room")
		fails += 1

	# ── 3. AND THE FULL DWELL TAKES IT ───────────────────────────────────────
	for i in range(40):
		if not is_instance_valid(b1):
			break
		hot.perform_measurement()
	await process_frame
	var gone: bool = (not is_instance_valid(b1)) or b1.is_broken()
	print("3  full dwell: barrier broken = %s  (must be true)" % gone)
	if not gone:
		var hp: int = b1.hit_points_left() if is_instance_valid(b1) else -1
		print("   FAIL the beam never reached it — hp still %d" % hp)
		print("   (a miss here is usually the raycast: check the beam points -Z at the target)")
		fails += 1

	print("\nprobe_laser_burns: %s" % ("PASS" if fails == 0 else "%d FAILED" % fails))
	quit(0 if fails == 0 else 1)
