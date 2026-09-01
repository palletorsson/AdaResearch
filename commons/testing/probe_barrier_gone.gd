extends SceneTree
## THREE BLOWS AND IT IS GONE — and a fast swing still lands.
##
## Palle: "when I hit the police do not cross this line in VR with the hammer it
## should be destroyed and be gone."
##
## Two things are checked that the earlier probe did not:
##   the barrier LEAVES THE TREE, rather than lying knocked over
##   a swing at VR speed (14 m/s, a 0.19 m step per frame — wider than the
##   0.17 m head) still connects, because the head sweeps instead of sampling

func _init() -> void:
	var fails := 0
	var B := load("res://commons/artifacts/do_not_cross_barrier/do_not_cross_barrier.tscn")
	var H := load("res://commons/artifacts/line_sledgehammer/line_sledgehammer.tscn")

	# ---- gone ----
	var b = B.instantiate()
	get_root().add_child(b)
	await process_frame
	await process_frame
	b.strike(); b.strike()
	print("1  after two blows: broken=%s still in tree=%s" % [b.is_broken(), b.is_inside_tree()])
	if b.is_broken():
		print("   FAIL destroyed in two"); fails += 1
	b.strike()
	print("2  after the third: broken=%s" % b.is_broken())
	if not b.is_broken():
		print("   FAIL still standing"); fails += 1
	var waited := 0
	while is_instance_valid(b) and waited < 400:
		await process_frame
		waited += 1
	print("3  gone from the tree: %s (must be true)" % [not is_instance_valid(b)])
	if is_instance_valid(b):
		print("   FAIL it is still in the room, still saying DO NOT CROSS"); fails += 1

	# ---- a VR-speed swing still connects ----
	var b2 = B.instantiate()
	get_root().add_child(b2)
	await process_frame
	await process_frame
	var h = H.instantiate()
	h.freeze = true
	get_root().add_child(h)
	h.global_position = Vector3(0, -0.4, 1.6)
	await physics_frame
	await physics_frame

	# 14 m/s at 72 Hz = 0.194 m per frame, wider than the 0.17 m head.
	var step := 0.194
	var hits := 0
	for i in 20:
		h.global_position = Vector3(0, -0.4, 1.6 - step * i)
		await physics_frame
		if b2.hit_points_left() < 3:
			hits = 3 - b2.hit_points_left()
			break
	print("4  swing at 14 m/s (%.3f m per frame vs a %.2f m head): landed=%s"
		% [step, h._strike_shape.radius, hits > 0])
	if hits == 0:
		print("   FAIL the fastest swings pass straight through — tunnelling"); fails += 1

	print("")
	print("PROBE OK" if fails == 0 else "PROBE FAILED (%d)" % fails)
	quit(fails)
