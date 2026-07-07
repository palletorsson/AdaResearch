extends SceneTree

## fungus_dna_gallery_lab.gd
##
## Render every fd_*.json in the fungus-dna-gallery folder by feeding
## it to FungusMorphology.build (the cap+stem+gill mushroom builder
## from algorithms/nature_system/morphology/) and capturing one PNG
## per variant.
##
## Mirrors tree_dna_gallery_lab.gd: same CritterDNA path, same trait
## mapper, just FungusMorphology instead of TreeMorphology. v2 of
## this lab — v1 used CellularAutomata3D voxel mold which didn't read
## as mushrooms.
##
## Run:
##   godot --xr-mode off --no-window \
##     --script res://commons/testing/fungus_dna_gallery_lab.gd

const CritterDNAClass = preload("res://algorithms/nature_system/dna/critter_dna.gd")
const CritterTraitMapperClass = preload(
	"res://algorithms/nature_system/dna/critter_trait_mapper.gd"
)
const FungusMorphologyClass = preload(
	"res://algorithms/nature_system/morphology/fungus_morphology.gd"
)
const GroundPatchClass = preload("res://commons/testing/ground_patch.gd")

const GALLERY_DIR := "C:/Users/palle/Documents/GitHub/ada_encyclopedia/public/fungus-dna-gallery"

const SETTLE_SECONDS := 0.4

var _trait_mapper: CritterTraitMapper = null
var _fungus: Node3D = null
var _camera: Camera3D = null
var _root_3d: Node3D = null


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not DirAccess.dir_exists_absolute(GALLERY_DIR):
		push_error("[fungus_gallery] gallery dir missing: %s" % GALLERY_DIR)
		quit(1); return

	_setup_scene()
	_trait_mapper = CritterTraitMapperClass.new()
	await process_frame
	await process_frame

	# Walk every fd_*.json
	var dir := DirAccess.open(GALLERY_DIR)
	dir.list_dir_begin()
	var configs: Array[String] = []
	var fname := dir.get_next()
	while fname != "":
		if fname.begins_with("fd_") and fname.ends_with(".json"):
			configs.append(fname)
		fname = dir.get_next()
	dir.list_dir_end()
	configs.sort()
	print("[fungus_gallery] %d configs queued" % configs.size())

	var rendered: int = 0
	for cfg_name in configs:
		var ok := await _render_one(cfg_name)
		if ok:
			rendered += 1
		if rendered % 5 == 0 and rendered > 0:
			print("  ... %d / %d" % [rendered, configs.size()])

	print("[fungus_gallery] DONE: %d / %d mushrooms captured"
		% [rendered, configs.size()])
	quit(0)


func _setup_scene() -> void:
	_root_3d = Node3D.new()
	get_root().add_child(_root_3d)

	# Off-white background — same as flower / tree galleries. Mushrooms
	# now have proper geometry and colours so they stand out fine on a
	# light BG.
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.92, 0.92, 0.95)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_BG
	env.ambient_light_energy = 0.7
	env.ambient_light_color = Color(0.95, 0.95, 1.0)
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	_root_3d.add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.light_energy = 1.4
	sun.shadow_enabled = false
	_root_3d.add_child(sun)

	# Camera — added to tree first, positioned per-fungus in _render_one.
	_camera = Camera3D.new()
	_camera.fov = 35.0
	_camera.near = 0.05
	_camera.far = 50.0
	_root_3d.add_child(_camera)
	_camera.current = true


func _render_one(cfg_name: String) -> bool:
	var cfg_id := cfg_name.replace(".json", "")
	var cfg_path := GALLERY_DIR + "/" + cfg_name

	var f := FileAccess.open(cfg_path, FileAccess.READ)
	if f == null:
		push_warning("[fungus_gallery] cannot open %s" % cfg_path)
		return false
	var raw := f.get_as_text()
	f.close()

	var parsed: Variant = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		push_warning("[fungus_gallery] bad JSON: %s" % cfg_path)
		return false
	var cfg: Dictionary = parsed

	# Strip generator-only keys before from_dict.
	cfg.erase("_cluster")
	cfg.erase("_id")

	# Convert RGB lists to Color objects for the colour genes.
	for k in ["primary_color", "secondary_color", "tertiary_color"]:
		if cfg.has(k):
			var v = cfg[k]
			if v is Array and v.size() >= 3:
				cfg[k] = Color(float(v[0]), float(v[1]), float(v[2]))

	var dna: CritterDNA = CritterDNAClass.new()
	dna.from_dict(cfg)
	dna.body_type = 3.0  # Force fungus

	# Free the previous fungus.
	if _fungus and is_instance_valid(_fungus):
		_fungus.queue_free()
		await process_frame

	# Spawn a fresh wrapper at origin and ask FungusMorphology to
	# fill it with cap+stem+gill geometry.
	_fungus = Node3D.new()
	_fungus.name = cfg_id
	_root_3d.add_child(_fungus)
	FungusMorphologyClass.build(dna, _fungus, _trait_mapper, 3)

	# Fungus-kingdom ground patch — dark organic / rotting-wood. The
	# living_ground shader's fungus channel adds mycelium-vein detail
	# and bioluminescent emission for high-iridescence variants.
	# Alien_lumen variants get the alien preset (purple+iridescent).
	var ground_kingdom: String = "alien" if dna.iridescence > 0.5 else "fungus"
	var ground_size: float = maxf(dna.scale * 1.6, 1.0)
	GroundPatchClass.attach(_fungus, ground_kingdom, Vector2(ground_size, ground_size))

	# Keep the trait-mapper shader (membrane iridescence on the cap,
	# bark on the stem, scales on gills) — but override the
	# `transparency` uniform to 0 on every shader material. The trait
	# mapper sets transparency = dna.transparency, and the shader's
	# `if (transparency > 0.05) ALPHA_SCISSOR_THRESHOLD = 0.1`
	# (critter_dna.gdshader:463) discards fragments — even small
	# DNA transparency values made the stem and cap invisible.
	# This fix preserves all the shader's visual richness.
	# (Production NOTE: the biome dispatcher's _spawn_fungus has the
	# same problem in VR — see doc/CRITTER_VR_PLAN.md.)
	_zero_transparency(_fungus)

	# Wait for build, then frame from AABB.
	await process_frame

	var aabb: AABB = _compute_aabb(_fungus)
	var visible_h: float = clampf(aabb.size.y, 0.2, 1.5)
	var visible_r: float = clampf(maxf(aabb.size.x, aabb.size.z) * 0.5, 0.1, 1.0)

	# Distance must accommodate vertical extent. With FOV 35, vertical
	# view at distance d ≈ 0.63*d. Fit h with margin via d ≈ h*2.0.
	# Also make sure the radius fits horizontally (16:9 aspect).
	var dist: float = clampf(maxf(visible_h * 2.0, visible_r * 3.2), 0.6, 2.5)
	# Look at 0.55 of height — slight bias toward the cap which is the
	# visual focus, but keep the stem in frame.
	var look_y: float = aabb.position.y + visible_h * 0.55
	_camera.global_position = Vector3(
		dist * 0.7, look_y + visible_h * 0.20, dist * 0.7
	)
	_camera.look_at(Vector3(0.0, look_y, 0.0), Vector3.UP)

	await create_timer(SETTLE_SECONDS).timeout
	await process_frame
	await process_frame

	var img: Image = root.get_viewport().get_texture().get_image()
	if img == null:
		push_warning("[fungus_gallery] viewport image null for %s" % cfg_id)
		return false

	var out_path := GALLERY_DIR + "/" + cfg_id + ".png"
	var save_err := img.save_png(out_path)
	if save_err != OK:
		push_warning("[fungus_gallery] save_png failed for %s: %s"
			% [cfg_id, save_err])
		return false
	return true


## Force `transparency` uniform to 0 on every ShaderMaterial in the
## subtree. Fixes the alpha-scissor bug where the trait mapper passes
## a small dna.transparency value (e.g., 0.07) which trips the
## shader's discard branch and hides the whole fragment.
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


## Replace shader materials with simple StandardMaterial3D using the
## DNA's primary/secondary/tertiary colours. Kept as a fallback /
## VR-cheap baseline option but no longer the default — the shader
## carries all the per-DNA surface variation.
func _force_opaque(node: Node, dna: CritterDNA) -> void:
	for child in node.get_children():
		var mat := StandardMaterial3D.new()
		var name_str: String = child.name
		if name_str == "Stem":
			mat.albedo_color = dna.secondary_color
			mat.roughness = 0.85
		elif name_str == "Cap":
			mat.albedo_color = dna.primary_color
			mat.roughness = 0.55
			# Bioluminescent caps glow.
			if dna.iridescence > 0.4:
				mat.emission_enabled = true
				mat.emission = dna.primary_color
				mat.emission_energy_multiplier = dna.iridescence * 0.6
			# Translucent caps.
			if dna.transparency > 0.2:
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				var c := dna.primary_color
				c.a = 1.0 - dna.transparency * 0.7
				mat.albedo_color = c
		elif name_str == "Gills" or name_str.begins_with("HeadFlower"):
			mat.albedo_color = dna.tertiary_color
			mat.roughness = 0.45
		elif name_str == "Spores":
			mat.albedo_color = dna.tertiary_color.lightened(0.2)
			mat.roughness = 0.4
			if dna.iridescence > 0.3:
				mat.emission_enabled = true
				mat.emission = dna.tertiary_color
				mat.emission_energy_multiplier = dna.iridescence * 0.4
		elif name_str == "StemRing":
			mat.albedo_color = dna.secondary_color.lightened(0.2)
			mat.roughness = 0.6
		else:
			mat.albedo_color = dna.primary_color
			mat.roughness = 0.6

		if child is MeshInstance3D:
			(child as MeshInstance3D).material_override = mat
		elif child is MultiMeshInstance3D:
			(child as MultiMeshInstance3D).material_override = mat

		# Recurse — colony layouts wrap each mushroom in a sub-Node3D
		# (Colony_<i> / Bracket_<i>) whose children are the actual meshes.
		_force_opaque(child, dna)


## Walk the node and accumulate every MeshInstance3D / MultiMeshInstance3D
## AABB into one combined AABB. Returns a small default if nothing has
## a mesh yet.
func _compute_aabb(node: Node) -> AABB:
	var combined := AABB()
	var first := true
	var stack: Array = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		var local_aabb: AABB
		var has_mesh := false
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			local_aabb = (n as MeshInstance3D).get_aabb()
			has_mesh = true
		elif n is MultiMeshInstance3D and (n as MultiMeshInstance3D).multimesh != null:
			local_aabb = (n as MultiMeshInstance3D).get_aabb()
			has_mesh = true
		if has_mesh and n is Node3D:
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
