extends SceneTree

## critter_dna_gallery_lab.gd
##
## Render every cd_*.json in the critter-dna-gallery folder by
## feeding it to CreatureMorphology.build (the segmented-body / limb
## creature builder) and capturing one PNG per variant.
##
## Same shape as tree / fungus gallery labs. Static T-pose only —
## no animation, no skinning, no transformation. The user explicitly
## doesn't need motion for gallery captures, and skipping animation
## also avoids a class of seam artifacts.
##
## Run:
##   godot --xr-mode off --no-window \
##     --script res://commons/testing/critter_dna_gallery_lab.gd

const CritterDNAClass = preload("res://algorithms/nature_system/dna/critter_dna.gd")
const CritterTraitMapperClass = preload(
	"res://algorithms/nature_system/dna/critter_trait_mapper.gd"
)
const CreatureMorphologyClass = preload(
	"res://algorithms/nature_system/morphology/creature_morphology.gd"
)
const GroundPatchClass = preload("res://commons/testing/ground_patch.gd")

const GALLERY_DIR := "C:/Users/palle/Documents/GitHub/ada_encyclopedia/public/critter-dna-gallery"

const SETTLE_SECONDS := 0.4

var _trait_mapper: CritterTraitMapper = null
var _critter: Node3D = null
var _ground: Node3D = null   # sibling of _critter so the critter's
                              # framing rotation doesn't tilt the ground
var _camera: Camera3D = null
var _root_3d: Node3D = null


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not DirAccess.dir_exists_absolute(GALLERY_DIR):
		push_error("[critter_gallery] gallery dir missing: %s" % GALLERY_DIR)
		quit(1); return

	_setup_scene()
	_trait_mapper = CritterTraitMapperClass.new()
	await process_frame
	await process_frame

	var dir := DirAccess.open(GALLERY_DIR)
	dir.list_dir_begin()
	var configs: Array[String] = []
	var fname := dir.get_next()
	while fname != "":
		if fname.begins_with("cd_") and fname.ends_with(".json"):
			configs.append(fname)
		fname = dir.get_next()
	dir.list_dir_end()
	configs.sort()
	print("[critter_gallery] %d configs queued" % configs.size())

	var rendered: int = 0
	for cfg_name in configs:
		var ok := await _render_one(cfg_name)
		if ok:
			rendered += 1
		if rendered % 5 == 0 and rendered > 0:
			print("  ... %d / %d" % [rendered, configs.size()])

	print("[critter_gallery] DONE: %d / %d critters captured"
		% [rendered, configs.size()])
	quit(0)


func _setup_scene() -> void:
	_root_3d = Node3D.new()
	get_root().add_child(_root_3d)

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
		push_warning("[critter_gallery] cannot open %s" % cfg_path)
		return false
	var raw := f.get_as_text()
	f.close()

	var parsed: Variant = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		push_warning("[critter_gallery] bad JSON: %s" % cfg_path)
		return false
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
	dna.body_type = 1.0  # creature

	if _critter and is_instance_valid(_critter):
		_critter.queue_free()
		await process_frame
	if _ground and is_instance_valid(_ground):
		_ground.queue_free()
		await process_frame

	_critter = Node3D.new()
	_critter.name = cfg_id
	_root_3d.add_child(_critter)
	CreatureMorphologyClass.build(dna, _critter, _trait_mapper, 3)

	# Creature-kingdom ground patch: packed dusty earth with worn-trail
	# texture under the critter. Parented under _root_3d (NOT _critter)
	# because we rotate the critter for framing — we don't want the
	# ground to tilt with it.
	var ground_size: float = maxf(dna.scale * dna.segments * 0.4, 2.5)
	_ground = GroundPatchClass.attach(_root_3d, "creature",
		Vector2(ground_size, ground_size))

	# KEEP the trait-mapper shader — it carries the DNA-driven surface
	# variation (scales, fur, patterns, iridescence, age). Replacing
	# with StandardMaterial3D loses all that. The shader works correctly
	# with MultiMesh batching too, as long as all instances share the
	# same DNA (per-critter case in the Tier 2 plan); for swarm
	# batching of mixed DNA the shader needs a refactor to read
	# INSTANCE_COLOR / INSTANCE_CUSTOM. See doc/CRITTER_VR_PLAN.md.

	# CreatureMorphology builds the body lying along Z axis. Rotate so
	# the spine runs left→right in the gallery frame (more recognizable
	# silhouette than head-on).
	_critter.rotation.y = deg_to_rad(-25.0)

	await process_frame

	var aabb: AABB = _compute_aabb(_critter)
	var visible_h: float = clampf(aabb.size.y, 0.15, 3.0)
	var visible_w: float = clampf(maxf(aabb.size.x, aabb.size.z), 0.2, 6.0)
	# Critters are usually wider than tall — distance dominated by width.
	# Cap raised to 6m because long-bodied larva variants stretch past 2m.
	var dist: float = clampf(maxf(visible_h * 2.0, visible_w * 1.6), 0.6, 8.0)
	var center: Vector3 = aabb.position + aabb.size * 0.5

	_camera.global_position = Vector3(
		dist * 0.7, center.y + visible_h * 0.40, dist * 0.7
	)
	_camera.look_at(center, Vector3.UP)

	await create_timer(SETTLE_SECONDS).timeout
	await process_frame
	await process_frame

	var img: Image = root.get_viewport().get_texture().get_image()
	if img == null:
		push_warning("[critter_gallery] viewport image null for %s" % cfg_id)
		return false

	var out_path := GALLERY_DIR + "/" + cfg_id + ".png"
	var save_err := img.save_png(out_path)
	if save_err != OK:
		push_warning("[critter_gallery] save_png failed for %s: %s"
			% [cfg_id, save_err])
		return false
	return true


## Replace shader materials with simple StandardMaterial3D using the
## DNA's primary/secondary/tertiary colours.
##
## Naming convention from creature_morphology.gd:
##   "Body_<i>"   spine segments      → primary_color
##   "Limb_<seed>_<j>"  limb tubes    → primary_color.darkened
##   "Tip_<i>"    foot / claw tips    → tertiary_color
##   "Head"       head dome           → primary_color.lightened
##   "Eye_<i>"    eye spheres         → tertiary_color
##   "Antenna_<i>" / "Horn_<i>"       → secondary_color
##   "Tail_<i>"   tail segments       → primary_color.darkened
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
			mat.roughness = 0.45
		elif name_str.begins_with("Head"):
			mat.albedo_color = dna.primary_color.lightened(0.05)
			mat.roughness = 0.55
		elif name_str.begins_with("Eye"):
			mat.albedo_color = dna.tertiary_color
			mat.roughness = 0.20
			# Eyes get a subtle glow for liveness even in static frame.
			mat.emission_enabled = true
			mat.emission = dna.tertiary_color
			mat.emission_energy_multiplier = 0.25
		elif name_str.begins_with("Antenna") or name_str.begins_with("Horn"):
			mat.albedo_color = dna.secondary_color
		elif name_str.begins_with("Tail"):
			mat.albedo_color = dna.primary_color.darkened(0.15)
		else:
			mat.albedo_color = dna.primary_color

		# Iridescence on cap-like parts for alien_crab variants.
		if dna.iridescence > 0.4:
			mat.metallic = 0.3
			mat.roughness = clampf(mat.roughness - 0.2, 0.1, 1.0)

		if child is MeshInstance3D:
			(child as MeshInstance3D).material_override = mat
		elif child is MultiMeshInstance3D:
			(child as MultiMeshInstance3D).material_override = mat

		_force_opaque(child, dna)


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
