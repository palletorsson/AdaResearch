extends SceneTree

## Smoke test — render ONE tree-DNA variant, save to user://, exit.
## Use this to debug the gallery lab before running 60 variants.

const CritterDNAClass = preload("res://algorithms/nature_system/dna/critter_dna.gd")
const CritterTraitMapperClass = preload(
	"res://algorithms/nature_system/dna/critter_trait_mapper.gd"
)
const TreeMorphologyClass = preload(
	"res://algorithms/nature_system/morphology/tree_morphology.gd"
)

const CONFIG_PATH := "C:/Users/palle/Documents/GitHub/ada_encyclopedia/public/tree-dna-gallery/td_broad_oak_01.json"
const OUT_PATH := "user://td_smoke.png"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("[td_smoke] start, config=%s" % CONFIG_PATH)

	var root_3d := Node3D.new()
	get_root().add_child(root_3d)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.92, 0.92, 0.95)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_BG
	env.ambient_light_energy = 0.6
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	root_3d.add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.light_energy = 1.5
	root_3d.add_child(sun)

	var camera := Camera3D.new()
	camera.fov = 35.0
	root_3d.add_child(camera)
	camera.current = true

	# Read config.
	var f := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if f == null:
		push_error("[td_smoke] cannot open config: %s" % CONFIG_PATH)
		quit(1); return
	var raw := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		push_error("[td_smoke] bad JSON")
		quit(1); return
	var cfg: Dictionary = parsed
	cfg.erase("_cluster")
	cfg.erase("_id")
	for k in ["primary_color", "secondary_color", "tertiary_color"]:
		if cfg.has(k):
			var v = cfg[k]
			if v is Array and v.size() >= 3:
				cfg[k] = Color(float(v[0]), float(v[1]), float(v[2]))

	var dna: CritterDNA = CritterDNAClass.new()
	dna.from_dict(cfg)
	dna.body_type = 0.0
	print("[td_smoke] DNA: segments=%.1f scale=%.2f branch_angle=%.1f leaf=%.2f"
		% [dna.segments, dna.scale, dna.branch_angle, dna.leaf_density])

	var trait_mapper := CritterTraitMapperClass.new()
	var tree_root := Node3D.new()
	root_3d.add_child(tree_root)
	TreeMorphologyClass.build(dna, tree_root, trait_mapper, 3)
	print("[td_smoke] tree built, child count=%d" % tree_root.get_child_count())

	# Wait for build, then frame.
	await create_timer(0.4).timeout
	await process_frame

	var aabb: AABB = _aabb_of(tree_root)
	var h: float = maxf(aabb.size.y, 0.5)
	var r: float = maxf(aabb.size.x, aabb.size.z) * 0.5
	var dist: float = maxf(maxf(h * 1.4, r * 2.4), 1.5)
	camera.global_position = Vector3(
		dist * 0.75, aabb.position.y + h * 0.55, dist * 0.75
	)
	camera.look_at(Vector3(0.0, aabb.position.y + h * 0.45, 0.0), Vector3.UP)
	print("[td_smoke] aabb size=%s, camera at %s"
		% [aabb.size, camera.global_position])

	await process_frame
	await process_frame

	var img: Image = root.get_viewport().get_texture().get_image()
	if img == null:
		push_error("[td_smoke] viewport image null"); quit(1); return
	var save_err := img.save_png(OUT_PATH)
	if save_err != OK:
		push_error("[td_smoke] save_png failed: %s" % save_err); quit(1); return

	var globalized := ProjectSettings.globalize_path(OUT_PATH)
	print("[td_smoke] DONE: %s" % globalized)
	quit(0)


func _aabb_of(node: Node) -> AABB:
	var combined := AABB()
	var first := true
	var stack: Array = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D and n.mesh != null:
			var local: AABB = (n as MeshInstance3D).get_aabb()
			var xform: Transform3D = (n as Node3D).global_transform
			var world: AABB = xform * local
			if first:
				combined = world
				first = false
			else:
				combined = combined.merge(world)
		for child in n.get_children():
			stack.push_back(child)
	if first:
		return AABB(Vector3(-0.5, 0.0, -0.5), Vector3(1.0, 1.0, 1.0))
	return combined
