extends SceneTree
## WHAT RISES THROUGH THE SLAB (the Void, 2026-11-13)
## A tall work on the floor below can stand up through this floor's slab. Before placing anything in the middle of a
## floor, read what is already standing in its air that this floor does not own: every drawn mesh and every solid
## whose box reaches into this storey (10 cm to 2.2 m over the slab, inside the slab's plan) and that belongs to
## another floor's content.
##
##   godot --path <stage> --script res://tools/probes/rises_through.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## through.json: one row a work of another floor, with the box of what reaches in (metres, this floor's frame).
var game: Node3D


func _initialize() -> void:
	run.call_deferred()


func run() -> void:
	var folder := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game); current_scene = game
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	game.scene_loaded(); game.scene_visible()
	var floor: int = game.checkpoint
	var record: Dictionary = game.building.content.data.floors[floor]
	for i in 1200: await physics_frame
	var level: float = float(game.building.spec.levels[floor]) + game.building.global_position.y
	var half_w: float = float(game.building.spec.width) * 0.5
	var half_d: float = float(game.building.spec.depth) * 0.5
	var room := AABB(Vector3(-half_w, level + 0.1, -half_d), Vector3(half_w * 2.0, 2.1, half_d * 2.0))
	var found := {}
	for key in game.building.content.exhibits:
		var parts: PackedStringArray = str(key).split("/")
		if int(parts[0]) == floor: continue
		var mount: Node3D = game.building.content.exhibits[key]
		if not is_instance_valid(mount): continue
		var reach := AABB()
		var first := true
		var solid := false
		for n in mount.find_children("*", "VisualInstance3D", true, false):
			var v := n as VisualInstance3D
			if not v.is_visible_in_tree(): continue
			var box: AABB = v.global_transform * v.get_aabb()
			if not box.intersects(room): continue
			var part: AABB = box.intersection(room)
			reach = part if first else reach.merge(part)
			first = false
		if first: continue
		for n in mount.find_children("*", "CollisionShape3D", true, false):
			var at: Vector3 = (n as CollisionShape3D).global_position
			if room.grow(1.0).has_point(at): solid = true
		found[str(key)] = {"work": str(key), "of_floor": int(parts[0]), "from": [snappedf(reach.position.x, .1), snappedf(reach.position.y - level, .1), snappedf(reach.position.z, .1)],
			"to": [snappedf(reach.end.x, .1), snappedf(reach.end.y - level, .1), snappedf(reach.end.z, .1)], "has_a_solid_near": solid}
	var rows: Array = found.values()
	var file := FileAccess.open(folder.path_join("through.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"floor": floor, "map": str(record.map), "passed": true, "checks": [{"check": "works of other floors that reach into this storey", "ok": true, "count": rows.size(), "works": rows}]}, "\t"))
	file.close()
	print("[rises_through] ", rows.size())
	quit()
