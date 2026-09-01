extends SceneTree
## THREE HITS, THEN SHREDS, AND THE WAY IS OPEN.
##
## Palle: "when I hit the do not cross line with the hammer it must break into
## shreds after some hits, also remove collider so I can get past."
##
## The load-bearing check is 5: the fragments must OUTLIVE the barrier. They are
## parented to its parent and carry their own tweens precisely because children
## of a queue_free()d node vanish in the same frame — which would look like the
## barrier blinking out with one invisible frame of debris.

func _init() -> void:
	var fails := 0
	var B := load("res://commons/artifacts/do_not_cross_barrier/do_not_cross_barrier.tscn")
	var host := Node3D.new()
	host.name = "Hall"
	get_root().add_child(host)
	var b = B.instantiate()
	host.add_child(b)
	await process_frame
	await process_frame

	var body0 := _find_static(b)
	var meshes0: int = _count_meshes(b)
	print("1  standing: collider=%s  meshes=%d" % [body0 != null, meshes0])
	if body0 == null or meshes0 == 0:
		print("   FAIL nothing to break"); fails += 1

	b.strike(b.global_position + Vector3(0, 1, 0), null)
	b.strike(b.global_position + Vector3(0, 1, 0), null)
	print("2  after two blows: broken=%s (must be false)" % b.is_broken())
	if b.is_broken():
		print("   FAIL broke in two"); fails += 1
	await process_frame

	var kids_before: int = host.get_child_count()
	b.strike(b.global_position + Vector3(0, 1, 0), null)
	await process_frame
	await process_frame
	var kids_after: int = host.get_child_count()
	var shreds: int = kids_after - kids_before
	print("3  third blow -> %d fragment(s) in the hall" % shreds)
	if shreds < 10:
		print("   FAIL it did not come apart"); fails += 1

	# 4. THE WAY IS OPEN — no collider anywhere under the hall
	var waited := 0
	while is_instance_valid(b) and waited < 200:
		await process_frame
		waited += 1
	var still := _find_static(host)
	print("4  collider left in the hall: %s (must be <null>)" % [still])
	if still != null:
		print("   FAIL you still cannot get past"); fails += 1

	# 5. THE SHREDS OUTLIVED THE BARRIER
	print("5  barrier gone=%s  fragments still present=%d"
		% [not is_instance_valid(b), host.get_child_count()])
	if is_instance_valid(b):
		print("   FAIL the barrier is still there"); fails += 1
	if host.get_child_count() == 0:
		print("   FAIL the shreds died with it — nothing to see"); fails += 1

	# 6. and they clean themselves up
	var w2 := 0
	while host.get_child_count() > 0 and w2 < 900:
		await process_frame
		w2 += 1
	print("6  fragments gone after ~%d frames: %s" % [w2, host.get_child_count() == 0])
	if host.get_child_count() > 0:
		print("   FAIL debris is permanent"); fails += 1

	print("")
	print("PROBE OK" if fails == 0 else "PROBE FAILED (%d)" % fails)
	quit(fails)


func _find_static(n: Node) -> StaticBody3D:
	if n is StaticBody3D:
		return n
	for c in n.get_children():
		var r := _find_static(c)
		if r != null:
			return r
	return null

func _count_meshes(n: Node) -> int:
	var k := 0
	for c in n.get_children():
		if c is MeshInstance3D:
			k += 1
		k += _count_meshes(c)
	return k
