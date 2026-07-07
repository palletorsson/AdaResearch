extends SceneTree

## Smoke test — render ONE FungusMorphology mushroom variant.

const CritterDNAClass = preload("res://algorithms/nature_system/dna/critter_dna.gd")
const CritterTraitMapperClass = preload(
	"res://algorithms/nature_system/dna/critter_trait_mapper.gd"
)
const FungusMorphologyClass = preload(
	"res://algorithms/nature_system/morphology/fungus_morphology.gd"
)

const CONFIG_PATH := "C:/Users/palle/Documents/GitHub/ada_encyclopedia/public/fungus-dna-gallery/fd_button_dome_01.json"
const OUT_PATH := "user://fd_smoke.png"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("[fd_smoke] start, config=%s" % CONFIG_PATH)

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

	# Read config.
	var f := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if f == null:
		push_error("[fd_smoke] cannot open: %s" % CONFIG_PATH)
		quit(1); return
	var raw := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		push_error("[fd_smoke] bad JSON"); quit(1); return
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
	dna.body_type = 3.0
	print("[fd_smoke] DNA: scale=%.2f curve=%.2f width=%.2f length=%.2f socio=%.2f infl=%.2f"
		% [dna.scale, dna.part_curve, dna.part_width, dna.part_length,
		   dna.sociality, dna.inflorescence])

	var trait_mapper := CritterTraitMapperClass.new()
	var fungus_root := Node3D.new()
	root_3d.add_child(fungus_root)
	FungusMorphologyClass.build(dna, fungus_root, trait_mapper, 3)
	print("[fd_smoke] fungus built, child count=%d" % fungus_root.get_child_count())

	# Trait-mapper shader is enabled. The shader applies
	# transparency = dna.transparency at line 221 of trait mapper, which
	# triggers ALPHA_SCISSOR_THRESHOLD = 0.1 in the shader (line 463) when
	# transparency > 0.05. Even a small dna.transparency makes the cap
	# alpha-scissored, which can fully discard fragments. Force it to 0
	# on every shader material so opaque caps stay opaque.
	_zero_transparency(fungus_root)

	await create_timer(0.4).timeout
	await process_frame

	var aabb: AABB = _aabb_of(fungus_root)
	# Cap aabb to sane range — MultiMesh sometimes reports huge boxes.
	var h: float = clampf(aabb.size.y, 0.2, 1.5)
	var r: float = clampf(maxf(aabb.size.x, aabb.size.z) * 0.5, 0.1, 1.0)
	# Distance must accommodate vertical extent. With FOV 35, vertical
	# view at distance d is 2*d*tan(17.5°) ≈ 0.63*d. To fit a height of
	# h with 25% margin, d = h * 1.25 / 0.63 ≈ h * 2.0. Same logic for
	# radius (horizontal).
	var dist: float = clampf(maxf(h * 2.0, r * 3.2), 0.6, 2.5)
	# Look at 0.6 * height — biased toward the cap, which is the visual
	# focus. Centre look-at offsets stem and cap together in frame.
	var look_y: float = aabb.position.y + h * 0.55
	camera.global_position = Vector3(dist * 0.7, look_y + h * 0.25, dist * 0.7)
	camera.look_at(Vector3(0.0, look_y, 0.0), Vector3.UP)
	print("[fd_smoke] aabb pos=%s size=%s, h=%.2f r=%.2f dist=%.2f"
		% [aabb.position, aabb.size, h, r, dist])
	print("[fd_smoke] camera at %s, look_y=%.2f"
		% [camera.global_position, look_y])
	# Inspect each mesh node so we can see what's actually being built.
	_dump_meshes(fungus_root, 0)

	await process_frame
	await process_frame

	var img: Image = root.get_viewport().get_texture().get_image()
	if img == null:
		push_error("[fd_smoke] viewport image null"); quit(1); return
	var save_err := img.save_png(OUT_PATH)
	if save_err != OK:
		push_error("[fd_smoke] save_png failed: %s" % save_err); quit(1); return

	var globalized := ProjectSettings.globalize_path(OUT_PATH)
	print("[fd_smoke] DONE: %s" % globalized)
	quit(0)


## Walk every MeshInstance3D / MultiMeshInstance3D and set the shader's
## `transparency` uniform to 0 on its material_override. The trait
## mapper sets transparency = dna.transparency, but the shader treats
## any transparency > 0.05 as alpha-scissor cutout (line 463 of
## critter_dna.gdshader), which can hide the whole mesh.
func _zero_transparency(node: Node) -> void:
	for child in node.get_children():
		var mat = null
		if child is MeshInstance3D:
			mat = (child as MeshInstance3D).material_override
		elif child is MultiMeshInstance3D:
			mat = (child as MultiMeshInstance3D).material_override
		if mat is ShaderMaterial:
			(mat as ShaderMaterial).set_shader_parameter("transparency", 0.0)
		_zero_transparency(child)


func _force_opaque(node: Node, dna: CritterDNA) -> void:
	for child in node.get_children():
		var mat := StandardMaterial3D.new()
		match (child.name as String):
			"Stem":
				mat.albedo_color = dna.secondary_color
			"Cap":
				mat.albedo_color = dna.primary_color
			"Gills", "Spores":
				mat.albedo_color = dna.tertiary_color
				mat.vertex_color_use_as_albedo = true
			_:
				mat.albedo_color = dna.primary_color
		mat.roughness = 0.7
		if child is MeshInstance3D:
			(child as MeshInstance3D).material_override = mat
		elif child is MultiMeshInstance3D:
			(child as MultiMeshInstance3D).material_override = mat
		_force_opaque(child, dna)


func _dump_meshes(node: Node, depth: int) -> void:
	var pad := "  ".repeat(depth)
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		var mi := node as MeshInstance3D
		var local := mi.get_aabb()
		var world := mi.global_transform * local
		print("%s· %s [Mesh] world_size=%s pos=%s"
			% [pad, mi.name, world.size, mi.global_position])
	elif node is MultiMeshInstance3D and (node as MultiMeshInstance3D).multimesh != null:
		var mmi := node as MultiMeshInstance3D
		var local := mmi.get_aabb()
		var world := mmi.global_transform * local
		print("%s· %s [MultiMesh count=%d] world_size=%s pos=%s"
			% [pad, mmi.name, mmi.multimesh.instance_count,
			   world.size, mmi.global_position])
	for child in node.get_children():
		_dump_meshes(child, depth + 1)


func _aabb_of(node: Node) -> AABB:
	var combined := AABB()
	var first := true
	var stack: Array = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		var local_aabb: AABB
		var has := false
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			local_aabb = (n as MeshInstance3D).get_aabb()
			has = true
		elif n is MultiMeshInstance3D and (n as MultiMeshInstance3D).multimesh != null:
			local_aabb = (n as MultiMeshInstance3D).get_aabb()
			has = true
		if has and n is Node3D:
			var xform: Transform3D = (n as Node3D).global_transform
			var world: AABB = xform * local_aabb
			if first:
				combined = world
				first = false
			else:
				combined = combined.merge(world)
		for child in n.get_children():
			stack.push_back(child)
	if first:
		return AABB(Vector3(-0.3, 0.0, -0.3), Vector3(0.6, 0.4, 0.6))
	return combined
