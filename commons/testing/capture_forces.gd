# One-run capture of the three new forces artifacts (per-AABB framing).
extends SceneTree

const OUT := "user://forces_shots/"
const TARGETS := [
	{"id": "catapult", "scene": "res://commons/artifacts/catapult/catapult.tscn", "params": {}},
	{"id": "weather_station", "scene": "res://algorithms/vectors/weather_vector_field/weather_vector_field.tscn", "params": {}},
	{"id": "vector_addition_xl", "scene": "res://algorithms/vectors/02_vector_addition/VectorAddition.tscn", "params": {"scale_multiplier": 5.0}},
]


func _initialize() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var root := get_root()
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.6, 0.52)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.6, 0.66)
	env.ambient_light_energy = 0.9
	we.environment = env
	root.add_child(we)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-50, -35, 0)
	key.light_energy = 1.2
	root.add_child(key)
	var cam := Camera3D.new()
	cam.fov = 52
	root.add_child(cam)
	cam.make_current()

	for t in TARGETS:
		if not ResourceLoader.exists(t["scene"]):
			print("[forces] MISSING scene: ", t["scene"]); continue
		var inst = load(t["scene"]).instantiate()
		root.add_child(inst)
		if inst.has_method("apply_grid_config") and not (t["params"] as Dictionary).is_empty():
			inst.apply_grid_config(t["params"])
		await create_timer(2.0).timeout
		if inst is Node3D:
			print("[forces] ", t["id"], " root scale=", (inst as Node3D).scale)
		var aabb := _node_aabb(inst)
		var c := aabb.get_center()
		var radius: float = maxf(1.0, aabb.size.length() * 0.45)
		cam.position = c + Vector3(0.5, 0.5, 1.0).normalized() * radius * 1.7
		cam.look_at(c, Vector3.UP)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var img: Image = root.get_texture().get_image()
		img.save_png(OUT + str(t["id"]) + ".png")
		print("[forces] saved ", t["id"], "  aabb=", aabb.size)
		inst.queue_free()
		await create_timer(0.3).timeout
	print("[forces] DONE")
	quit()


func _node_aabb(node: Node) -> AABB:
	var out := AABB()
	var first := true
	for m in node.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if mi.mesh == null:
			continue
		var ga := mi.global_transform * mi.get_aabb()
		if first:
			out = ga; first = false
		else:
			out = out.merge(ga)
	return out
