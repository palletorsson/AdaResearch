extends SceneTree
## Exercise the shipped triangle tool's timed placement and mesh-building path.
## Same planar L boundary, two cyclic starting vertices. No triangulation is
## reimplemented here: measurements read the tool's actual generated mesh.
## godot --headless --path . --script res://tools/probes/museum_triangle_fan.gd

const SCENE := "res://commons/primitives/point/draw_triangle_faces.tscn"
const BOUNDARY := [Vector2(0, 0), Vector2(1.2, 0), Vector2(1.2, 0.4),
	Vector2(0.4, 0.4), Vector2(0.4, 1.2), Vector2(0, 1.2)]
var output := "res://ada_run/museum_iteration/evidence/triangle_fan.json"

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			output = arg.substr(6)
	call_deferred("_run")

func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var tool: Node3D = load(SCENE).instantiate()
	world.add_child(tool)
	tool.set_process(false)
	var handle: RigidBody3D = tool.get_node("GrabPoint")
	handle.freeze = true
	var pointer := Node3D.new()
	world.add_child(pointer)
	await process_frame
	await process_frame
	var cases: Array[Dictionary] = []
	for start in [0, 1]:
		var count_before: int = tool.get("completed_triangles").size()
		var button_area: Node3D = tool.get_node("NewOutlineButton/InteractableAreaButton")
		XRToolsPointerEvent.pressed(pointer, button_area, button_area.global_position)
		XRToolsPointerEvent.released(pointer, button_area, button_area.global_position)
		var restart_ok: bool = tool.get("current_path").is_empty() and tool.get("completed_triangles").size() == count_before
		tool.call("_on_grab_point_picked_up", null)
		var tip: Node3D = tool.get("_draw_sphere")
		for step in range(BOUNDARY.size() + 1):
			var p: Vector2 = BOUNDARY[(start + step) % BOUNDARY.size()]
			tip.global_position = Vector3(p.x, 1.2, p.y)
			tool.call("_process", float(tool.get("hold_place_seconds")) + 0.01)
		var groups: Array = tool.get("completed_triangles")
		var record := {"start_vertex": start, "point_count": tool.get("placed_points").size(), "restart_preserves_faces": restart_ok,
			"completed_faces": groups.size(), "boundary_area_m2": 0.8,
			"hold_interval_seconds": tool.get("hold_place_seconds"),
			"grid_size_m": tool.get("grid_size"), "triangles": []}
		var total_area := 0.0
		var outside := 0
		if groups.size() == start + 1:
			var instance: MeshInstance3D = groups[-1]["mesh"]
			var vertices: PackedVector3Array = instance.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			# The shipped tool emits front and back for every triangle (six vertices).
			for offset in range(0, vertices.size(), 6):
				var a := Vector2(vertices[offset].x, vertices[offset].z)
				var b := Vector2(vertices[offset + 1].x, vertices[offset + 1].z)
				var c := Vector2(vertices[offset + 2].x, vertices[offset + 2].z)
				var centroid := (a + b + c) / 3.0
				var area := absf((b - a).cross(c - a)) * 0.5
				var in_notch := centroid.x > 0.40001 and centroid.y > 0.40001
				outside += int(in_notch)
				total_area += area
				record["triangles"].append({"a": [a.x, a.y], "b": [b.x, b.y], "c": [c.x, c.y],
					"area_m2": area, "centroid": [centroid.x, centroid.y], "centroid_outside_boundary": in_notch})
		var before_pause: int = tool.get("placed_points").size()
		tool.call("_process", 5.0)
		record["pause_adds_no_point"] = tool.get("placed_points").size() == before_pause
		record["sum_triangle_area_m2"] = total_area
		record["outside_centroids"] = outside
		cases.append(record)
	var passed: bool = (cases[0]["point_count"] == 6 and cases[1]["point_count"] == 6
		and cases[0]["completed_faces"] == 1 and cases[1]["completed_faces"] == 2
		and is_equal_approx(cases[0]["sum_triangle_area_m2"], 0.8)
		and cases[0]["outside_centroids"] == 0 and cases[1]["outside_centroids"] > 0
		and cases[1]["sum_triangle_area_m2"] > 0.8 and cases[0]["pause_adds_no_point"] and cases[1]["pause_adds_no_point"]
		and cases[0]["restart_preserves_faces"] and cases[1]["restart_preserves_faces"])
	var report := {"passed": passed, "scene": SCENE, "engine": Engine.get_version_info()["string"],
		"scope": "One real scene, pointer-button restart, timed placement and emitted meshes with supplied hand positions; no human/headset trial. Area sums include overlaps, not union area.",
		"cases": cases}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
	var file := FileAccess.open(output, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("MUSEUM_TRIANGLE_FAN ", JSON.stringify(report))
	world.free()
	quit(0 if passed else 1)
