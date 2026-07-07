extends SceneTree

## Smoke test — render ONE critter variant.

const CritterDNAClass = preload("res://algorithms/nature_system/dna/critter_dna.gd")
const CritterTraitMapperClass = preload(
	"res://algorithms/nature_system/dna/critter_trait_mapper.gd"
)
const CreatureMorphologyClass = preload(
	"res://algorithms/nature_system/morphology/creature_morphology.gd"
)

const CONFIG_PATH := "C:/Users/palle/Documents/GitHub/ada_encyclopedia/public/critter-dna-gallery/cd_walker_quad_01.json"
const OUT_PATH := "user://cd_smoke.png"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("[cd_smoke] start, config=%s" % CONFIG_PATH)

	var root_3d := Node3D.new()
	get_root().add_child(root_3d)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.92, 0.92, 0.95)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_BG
	env.ambient_light_energy = 0.7
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	root_3d.add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.light_energy = 1.4
	root_3d.add_child(sun)

	var camera := Camera3D.new()
	camera.fov = 35.0
	root_3d.add_child(camera)
	camera.current = true

	var f := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if f == null:
		push_error("[cd_smoke] cannot open: %s" % CONFIG_PATH); quit(1); return
	var raw := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		push_error("[cd_smoke] bad JSON"); quit(1); return
	var cfg: Dictionary = parsed
	cfg.erase("_cluster"); cfg.erase("_id")
	for k in ["primary_color", "secondary_color", "tertiary_color"]:
		if cfg.has(k):
			var v = cfg[k]
			if v is Array and v.size() >= 3:
				cfg[k] = Color(float(v[0]), float(v[1]), float(v[2]))

	var dna: CritterDNA = CritterDNAClass.new()
	dna.from_dict(cfg)
	dna.body_type = 1.0
	print("[cd_smoke] DNA: scale=%.2f segments=%.1f symmetry=%.1f mobility=%.2f"
		% [dna.scale, dna.segments, dna.symmetry, dna.mobility])

	var trait_mapper := CritterTraitMapperClass.new()
	var critter_root := Node3D.new()
	root_3d.add_child(critter_root)
	CreatureMorphologyClass.build(dna, critter_root, trait_mapper, 3)
	critter_root.rotation.y = deg_to_rad(-25.0)
	print("[cd_smoke] critter built, child count=%d" % critter_root.get_child_count())

	# Count meshes (draw-call estimate).
	var mesh_count: int = 0
	var mm_count: int = 0
	var stack: Array = [critter_root]
	while not stack.is_empty():
		var n = stack.pop_back()
		if n is MeshInstance3D: mesh_count += 1
		elif n is MultiMeshInstance3D: mm_count += 1
		for c in n.get_children(): stack.push_back(c)
	print("[cd_smoke] draw calls: %d MeshInstance3D, %d MultiMeshInstance3D"
		% [mesh_count, mm_count])

	# Keep the trait-mapper shader (no force_opaque) so we can verify
	# scales / fur / patterns render correctly on critters. (StandardMaterial3D
	# loses all DNA-driven surface variation — see Tier 1 note in
	# doc/CRITTER_VR_PLAN.md.)

	await create_timer(0.4).timeout
	await process_frame

	var aabb: AABB = _aabb_of(critter_root)
	var h: float = clampf(aabb.size.y, 0.15, 1.5)
	var w: float = clampf(maxf(aabb.size.x, aabb.size.z), 0.2, 2.0)
	var dist: float = clampf(maxf(h * 2.0, w * 1.6), 0.6, 3.0)
	var center: Vector3 = aabb.position + aabb.size * 0.5
	camera.global_position = Vector3(dist * 0.7, center.y + h * 0.40, dist * 0.7)
	camera.look_at(center, Vector3.UP)
	print("[cd_smoke] aabb size=%s, dist=%.2f" % [aabb.size, dist])

	await process_frame
	await process_frame

	var img: Image = root.get_viewport().get_texture().get_image()
	if img == null: push_error("[cd_smoke] image null"); quit(1); return
	var save_err := img.save_png(OUT_PATH)
	if save_err != OK: push_error("[cd_smoke] save_png failed: %s" % save_err); quit(1); return

	print("[cd_smoke] DONE: %s" % ProjectSettings.globalize_path(OUT_PATH))
	quit(0)


func _force_opaque(node: Node, dna: CritterDNA) -> void:
	for child in node.get_children():
		var name_str: String = child.name
		var mat := StandardMaterial3D.new()
		mat.roughness = 0.7
		if name_str.begins_with("Body"):
			mat.albedo_color = dna.primary_color
		elif name_str.begins_with("Limb"):
			mat.albedo_color = dna.primary_color.darkened(0.10)
		elif name_str.begins_with("Tip"):
			mat.albedo_color = dna.tertiary_color
		elif name_str.begins_with("Head"):
			mat.albedo_color = dna.primary_color.lightened(0.05)
		elif name_str.begins_with("Eye"):
			mat.albedo_color = dna.tertiary_color
			mat.emission_enabled = true
			mat.emission = dna.tertiary_color
			mat.emission_energy_multiplier = 0.25
		elif name_str.begins_with("Antenna") or name_str.begins_with("Horn"):
			mat.albedo_color = dna.secondary_color
		elif name_str.begins_with("Tail"):
			mat.albedo_color = dna.primary_color.darkened(0.15)
		else:
			mat.albedo_color = dna.primary_color
		if child is MeshInstance3D:
			(child as MeshInstance3D).material_override = mat
		elif child is MultiMeshInstance3D:
			(child as MultiMeshInstance3D).material_override = mat
		_force_opaque(child, dna)


func _aabb_of(node: Node) -> AABB:
	var combined := AABB()
	var first := true
	var stack: Array = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		var local_aabb: AABB
		var has := false
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			local_aabb = (n as MeshInstance3D).get_aabb(); has = true
		elif n is MultiMeshInstance3D and (n as MultiMeshInstance3D).multimesh != null:
			local_aabb = (n as MultiMeshInstance3D).get_aabb(); has = true
		if has and n is Node3D:
			var xform: Transform3D = (n as Node3D).global_transform
			var world: AABB = xform * local_aabb
			if first: combined = world; first = false
			else: combined = combined.merge(world)
		for child in n.get_children(): stack.push_back(child)
	if first:
		return AABB(Vector3(-0.3, 0.0, -0.3), Vector3(0.6, 0.4, 0.6))
	return combined
