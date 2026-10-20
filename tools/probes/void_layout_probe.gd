extends SceneTree
var viewer: Node3D
var out := ""
var checks: Array[Dictionary] = []

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--out="): out = argument.trim_prefix("--out=")
	run.call_deferred()

func check(label: String, passed: bool) -> void:
	checks.append({"name": label, "passed": passed})
	print("[void-layout] ", "PASS " if passed else "FAIL ", label)

func hit(from: Vector3, to: Vector3) -> Dictionary:
	return viewer.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, 1))

func ticks(count := 3) -> void:
	for i in range(count): await physics_frame

func run() -> void:
	viewer = load("res://commons/void/layout_viewer.tscn").instantiate()
	root.add_child(viewer)
	current_scene = viewer
	await ticks()
	var building: Node3D = viewer.building
	check("roof and two floors are built", building.floors.size() == 3)
	for i in range(3):
		var y := -6.0 * i
		var centre := hit(Vector3(3, y + 1, 1), Vector3(3, y - 1, 1))
		check("floor %d has a solid slab at the declared level" % i, not centre.is_empty() and absf(centre.position.y - y) < 0.001)
		for side in [-1, 1]:
			var wing := hit(Vector3(side * 18, y + 1, 0), Vector3(side * 18, y - 1, 0))
			check("floor %d extended wing %d is solid" % [i, side], not wing.is_empty() and absf(wing.position.y - y) < 0.001)
	for x in [-10.0, 10.0]:
		check("shaft at x=%s remains open through every floor" % x, hit(Vector3(x, 3, 0), Vector3(x, -16, 0)).is_empty())
	var aligned := true
	for x in building.spec.column_x:
		for z in building.spec.column_z:
			var result := hit(Vector3(x, 4, z), Vector3(x, -16, z))
			aligned = aligned and not result.is_empty() and absf(result.position.y - 2.0) < 0.001
	check("twelve aligned structural columns extend above the roof", aligned and building.spec.column_x.size() * building.spec.column_z.size() == 12)
	check("pillar attachment points are available on each floor", building.mounts.size() == 12)
	check("early shafts have no timber or suspended landings", building.temporary.get_child_count() == 0)
	check("one cushion on each lower floor", building.landing_pads.size() == 2)
	for i in range(1, 3):
		var z := 10.2 if i == 1 else -10.2
		var y := -6.0 * i
		var pad := hit(Vector3(0, y + 1, z), Vector3(0, y - 1, z))
		check("balcony %d is flush with its floor" % i, not pad.is_empty() and pad.collider == building.landing_pads[i - 1] and absf(pad.position.y - y) < 0.001)
		check("balcony %d has an unobstructed drop from above" % i, hit(Vector3(0, y + 8, z), Vector3(0, y + 0.1, z)).is_empty())
	check("hidden optional wall has no invisible collision", hit(Vector3(3, -4.5, -6.0), Vector3(3, -4.5, -4.8)).is_empty())
	building.show_partitions(true)
	await ticks()
	check("optional wall can be added with collision", not hit(Vector3(3, -4.5, -6.0), Vector3(3, -4.5, -4.8)).is_empty())
	building.show_partitions(false)
	await ticks()
	var shots := ["roof", "shaft", "floor", "overview", "plan"]
	for i in range(shots.size()):
		viewer.set_view(i)
		viewer.hud.hide()
		await ticks(5)
		await RenderingServer.frame_post_draw
		var err := root.get_texture().get_image().save_png(out.path_join(shots[i] + ".png"))
		check("native render saved: " + shots[i], err == OK)
	building.show_partitions(true)
	viewer.set_view(2)
	await ticks(5)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("partition.png"))
	var passed := checks.all(func(row): return row.passed)
	var file := FileAccess.open(out.path_join("checks.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed": passed, "checks": checks, "scope": "Architectural geometry and rendered views only. No player, jump, death, VR or streaming tests."}, "\t"))
	file.close()
	viewer.queue_free()
	await ticks(3)
	quit(0 if passed else 1)
