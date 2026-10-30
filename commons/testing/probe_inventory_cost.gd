extends Node3D
## WHAT A PREFAB COSTS (Palle, 2026-10-30: "an object budget in VR - we have to know the polycount"). Every item of
## items.json is made once by its own scene with the item's defaults, given half a second to build, and counted:
## triangles (every visible MeshInstance3D's faces; a MultiMesh times its instances), draws (mesh surfaces +
## labels), lights, SubViewports, particle systems, physics bodies, and scripts that run every frame. Also the
## renderer's own count of the whole scene with that one thing in it. Not a test: a table,
## ada_run/inventory/costs.json and costs.md, and the game's copy commons/data/inventory/costs.json.
## Run: godot --path . --xr-mode off --resolution 1280x800 res://commons/testing/probe_inventory_cost.tscn

const Items = preload("res://commons/player/inventory_items.gd")

func _ready() -> void:
	var out_dir := ProjectSettings.globalize_path("res://ada_run/inventory");DirAccess.make_dir_recursive_absolute(out_dir)
	var env := WorldEnvironment.new();var e := Environment.new();e.background_mode = Environment.BG_COLOR;e.background_color = Color("2a2c33");env.environment = e;add_child(env)
	var floor_b := StaticBody3D.new();floor_b.collision_layer = 1;add_child(floor_b)
	var fs := CollisionShape3D.new();var fb := BoxShape3D.new();fb.size = Vector3(12, .1, 12);fs.shape = fb;fs.position.y = -.05;floor_b.add_child(fs)
	var cam := Camera3D.new();cam.transform = Transform3D(Basis(), Vector3(0, 1.4, 3.5)).looking_at(Vector3(0, .5, 0));add_child(cam);cam.current = true
	await RenderingServer.frame_post_draw
	var base_prims: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	var base_draws: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var rows: Array = []
	for it in Items.items():
		var id := str(it.id);var token := str(it.get("token", ""))
		if str(it.get("coming", "")) != "" or token == "":continue
		var path := Items.scene_for(token)
		if path == "" or not ResourceLoader.exists(path):rows.append({"id": id, "token": token, "error": "no scene"});continue
		var n: Node = (load(path) as PackedScene).instantiate()
		var cfg: Dictionary = Items.config_for(it, {})
		for k in cfg:n.set_meta("config_%s" % str(k), cfg[k])
		if n.has_method("apply_grid_config"):n.apply_grid_config(cfg)
		add_child(n)
		if n is Node3D:(n as Node3D).global_position = Vector3(0, .5, 0)
		for i in 30:
			await get_tree().process_frame
		var c := _count(n)
		await RenderingServer.frame_post_draw;await RenderingServer.frame_post_draw
		c["frame_triangles"] = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME) - base_prims
		c["frame_draws"] = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME) - base_draws
		c["id"] = id;c["token"] = token;c["name"] = str(it.get("name", id))
		rows.append(c)
		print("[probe_inventory_cost] %-10s tris %7d  draws %4d  lights %d  viewports %d  particles %d  bodies %d  ticking %d  (frame: %d tris, %d draws)" % [id, c.triangles, c.draws, c.lights, c.viewports, c.particles, c.bodies, c.ticking, c.frame_triangles, c.frame_draws])
		remove_child(n);n.queue_free()
		await get_tree().process_frame
	var report := {"measured": Time.get_datetime_string_from_system(), "doc": "What one of each prefab costs, counted by probe_inventory_cost.gd: triangles and draws from its meshes (a MultiMesh times its instances), the renderer's own frame counts with that one thing in the scene (frame_*), lights, SubViewports, particle systems, physics bodies and scripts ticking every frame. The budget in items.json is spent against these.", "items": rows}
	var text := JSON.stringify(report, "  ")
	var o := FileAccess.open(out_dir.path_join("costs.json"), FileAccess.WRITE);o.store_string(text);o.close()
	var g := FileAccess.open(ProjectSettings.globalize_path("res://commons/data/inventory/costs.json"), FileAccess.WRITE);g.store_string(text + "\n");g.close()
	var md := "| item | triangles | draws | frame tris | frame draws | lights | viewports | particles | bodies | ticking |\n|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|\n"
	for r in rows:
		if r.has("error"):md += "| %s | %s |\n" % [r.id, r.error];continue
		md += "| %s | %d | %d | %d | %d | %d | %d | %d | %d | %d |\n" % [r.id, r.triangles, r.draws, r.frame_triangles, r.frame_draws, r.lights, r.viewports, r.particles, r.bodies, r.ticking]
	var m := FileAccess.open(out_dir.path_join("costs.md"), FileAccess.WRITE);m.store_string(md);m.close()
	print("[probe_inventory_cost] %d items measured" % rows.size())
	get_tree().quit(0)

func _count(root: Node) -> Dictionary:
	var c := {"triangles": 0, "draws": 0, "lights": 0, "viewports": 0, "particles": 0, "bodies": 0, "ticking": 0, "labels": 0}
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for ch in n.get_children():stack.append(ch)
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null and (n as Node3D).is_visible_in_tree() and (n as MeshInstance3D).layers != 0:
			var mesh: Mesh = (n as MeshInstance3D).mesh
			c.triangles += _tris(mesh);c.draws += mesh.get_surface_count()
		elif n is MultiMeshInstance3D and (n as MultiMeshInstance3D).multimesh != null and (n as Node3D).is_visible_in_tree():
			var mm: MultiMesh = (n as MultiMeshInstance3D).multimesh
			if mm.mesh != null:c.triangles += _tris(mm.mesh) * mm.instance_count;c.draws += mm.mesh.get_surface_count()
		elif n is Label3D:c.labels += 1;c.draws += 1
		elif n is CSGShape3D and (n as CSGShape3D).is_root_shape():
			var arr: Array = (n as CSGShape3D).get_meshes()
			if arr.size() >= 2 and arr[1] is Mesh:c.triangles += _tris(arr[1]);c.draws += (arr[1] as Mesh).get_surface_count()
		if n is Light3D:c.lights += 1
		if n is SubViewport:c.viewports += 1
		if n is GPUParticles3D or n is CPUParticles3D:c.particles += 1
		if n is PhysicsBody3D:c.bodies += 1
		if n.get_script() != null and (n.has_method("_process") or n.has_method("_physics_process")) and (n.is_processing() or n.is_physics_processing()):c.ticking += 1
	return c

static func _tris(mesh: Mesh) -> int:
	var total := 0
	for s in mesh.get_surface_count():
		var arrays: Array = mesh.surface_get_arrays(s)
		if arrays.size() <= Mesh.ARRAY_INDEX:continue
		var idx = arrays[Mesh.ARRAY_INDEX];var verts = arrays[Mesh.ARRAY_VERTEX]
		if idx != null and idx.size() > 0:total += idx.size() / 3
		elif verts != null:total += verts.size() / 3
	return total
