extends SceneTree
## Does the box the vending machine, the belt and the plinths seat a prefab by (Vending._bounds: MeshInstance3D only)
## miss part of it? A modular composite draws its repeated parts as MultiMesh (commons/modular/builder.gd
## batch_repeats). For every item in commons/data/inventory/items.json the prefab is made as _make_mini makes it,
## left 20 frames to build, and two boxes are taken: plain meshes only, and plain meshes + MultiMeshes. Reported per
## item where they differ: how far the seated base would be off (the part below the seated base sinks into the tray
## or the plinth cap) and how far the centre would be off.
##
##   python tools/run_floor_probe.py Primitives_Prefab_Test prefab_seat_boxes.gd seat_boxes.json <folder> --no-opening --opera-quiet

const Items = preload("res://commons/player/inventory_items.gd")
const HandLib = preload("res://commons/player/inventory_hand.gd")
const Vending = preload("res://commons/artifacts/vending_machine/vending_machine.gd")

var folder := "res://ada_run/prefab_seat_boxes"


func _initialize() -> void:
	run.call_deferred()


func _full(root_node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for part in root_node.find_children("*", "GeometryInstance3D", true, false):
		if not (part is MeshInstance3D or part is MultiMeshInstance3D) or not (part as Node3D).is_visible_in_tree(): continue
		if part is MeshInstance3D and (part as MeshInstance3D).mesh == null: continue
		if part is MultiMeshInstance3D and ((part as MultiMeshInstance3D).multimesh == null or (part as MultiMeshInstance3D).multimesh.instance_count == 0): continue
		var b: AABB = (part as Node3D).global_transform * (part as VisualInstance3D).get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	var stage := Node3D.new()
	stage.name = "SeatBoxes"
	root.add_child(stage)
	stage.global_position = Vector3(0, 500, 0)
	var made := {}
	var x := 0.0
	for it: Dictionary in Items.items():
		var path := Items.scene_for(str(it.get("token", "")))
		if path == "" or not ResourceLoader.exists(path): continue
		var n: Node = (load(path) as PackedScene).instantiate()
		if not n is Node3D:
			n.free()
			continue
		var cfg := Items.config_for(it, {})
		for k in cfg: n.set_meta("config_%s" % str(k), cfg[k])
		if n.has_method("apply_grid_config"): n.apply_grid_config(cfg)
		HandLib._make_inert(n)
		stage.add_child(n)
		(n as Node3D).position = Vector3(x, 0, 0)
		x += 6.0
		made[str(it.id)] = n
	for i in 20: await process_frame
	var rows := []
	var multimesh_items := 0
	for id in made:
		var n := made[id] as Node3D
		if not is_instance_valid(n): continue
		var plain: AABB = Vending._bounds(n)
		var full := _full(n)
		var mm := n.find_children("*", "MultiMeshInstance3D", true, false).size()
		if mm > 0: multimesh_items += 1
		if full.size.length() < 0.001: continue
		var sink := plain.position.y - full.position.y if plain.size.length() > 0.001 else full.size.y
		var drift := Vector2(plain.get_center().x - full.get_center().x, plain.get_center().z - full.get_center().z).length() if plain.size.length() > 0.001 else 0.0
		var lost := 1.0 - (plain.size.length() / full.size.length()) if plain.size.length() > 0.001 else 1.0
		if mm > 0 or absf(sink) > 0.005 or drift > 0.005:
			rows.append({"id": id, "multimeshes": mm, "sinks_m": snappedf(sink, 0.001), "centre_off_m": snappedf(drift, 0.001), "box_missed": snappedf(lost, 0.01),
				"plain": [plain.size.snappedf(0.01)], "full": [full.size.snappedf(0.01)]})
	rows.sort_custom(func(a, b): return float(a.sinks_m) + float(a.centre_off_m) > float(b.sinks_m) + float(b.centre_off_m))
	var result := {"passed": true, "items": made.size(), "with_multimesh": multimesh_items, "differ": rows.size(), "checks": [], "rows": rows}
	for r in rows.slice(0, 40):
		(result.checks as Array).append({"check": r.id, "ok": absf(float(r.sinks_m)) < 0.01 and float(r.centre_off_m) < 0.01, "sinks_m": r.sinks_m, "centre_off_m": r.centre_off_m, "missed": r.box_missed, "mm": r.multimeshes})
	var file := FileAccess.open(folder.path_join("seat_boxes.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()
	quit()
