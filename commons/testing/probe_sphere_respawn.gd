extends SceneTree
## THE RESET, proven: hit -> hidden + collider off -> cooldown -> standing
## again (mesh visible, collider back, ready to explode again — proven by
## exploding it AGAIN). Negative half: respawn_cooldown 0 = the old
## consumable, freed for good.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_sphere_respawn.gd

const OUT := "res://ada_run/sphere_respawn_probe.txt"

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var fails: Array = []
	var ps: PackedScene = load("res://commons/primitives/spheres/laser_exploding_sphere.tscn")

	# ── the reset ────────────────────────────────────────────────────────────
	var a: StaticBody3D = ps.instantiate() as StaticBody3D
	a.set("explosion_lifetime", 0.2)
	a.set("respawn_cooldown", 1.2)
	get_root().add_child(a)
	await process_frame
	var layer0: int = a.collision_layer
	a.call("hit_by_laser")
	await create_timer(0.3).timeout
	var mesh: MeshInstance3D = a.get_node("MeshInstance3D")
	if mesh.visible:
		fails.append("mesh still visible mid-explosion")
	if a.collision_layer != 0:
		fails.append("collider live mid-explosion")
	await create_timer(1.6).timeout
	if not is_instance_valid(a):
		fails.append("sphere was freed despite a cooldown")
	else:
		if not mesh.visible:
			fails.append("mesh did not return after the cooldown")
		if a.collision_layer != layer0:
			fails.append("collider did not return (layer %d, want %d)" % [a.collision_layer, layer0])
		if bool(a.get("_is_exploding")):
			fails.append("_is_exploding still set after the reset")
		# the whole point: it can go off AGAIN
		a.call("hit_by_laser")
		await create_timer(0.3).timeout
		if mesh.visible:
			fails.append("second explosion did not fire — the reset is not a reset")
		a.queue_free()

	# ── the consumable (negative half) ───────────────────────────────────────
	var b: StaticBody3D = ps.instantiate() as StaticBody3D
	b.set("explosion_lifetime", 0.2)
	b.set("respawn_cooldown", 0.0)
	get_root().add_child(b)
	await process_frame
	b.call("hit_by_laser")
	await create_timer(1.4).timeout
	if is_instance_valid(b) and b.is_inside_tree():
		fails.append("cooldown 0 did not free the sphere — the consumable is gone")

	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string("PASS" if fails.is_empty() else "FAIL: " + "; ".join(fails))
	f.close()
	if fails.is_empty():
		print("SPHERE RESPAWN: PASS — explodes, resets in cooldown, explodes AGAIN; cooldown 0 stays consumable")
	else:
		print("SPHERE RESPAWN: FAIL %d" % fails.size())
		for x in fails:
			print("  - " + str(x))
	quit(0 if fails.is_empty() else 1)
