extends SceneTree

## softbody_fungus_gallery_lab.gd
##
## Sister lab to fungus_dna_gallery_lab.gd. Same FungusMorphology
## base, but each variant's `_deform` block is applied as per-node
## scale + tilt transforms on Cap / Stem after the rigid mushroom is
## built. The result is a soft-body-looking pose captured statically
## — no physics simulation needed.
##
## Run:
##   godot --xr-mode off --no-window \
##     --script res://commons/testing/softbody_fungus_gallery_lab.gd

const CritterDNAClass = preload("res://algorithms/nature_system/dna/critter_dna.gd")
const CritterTraitMapperClass = preload(
	"res://algorithms/nature_system/dna/critter_trait_mapper.gd"
)
const FungusMorphologyClass = preload(
	"res://algorithms/nature_system/morphology/fungus_morphology.gd"
)
const GroundPatchClass = preload("res://commons/testing/ground_patch.gd")

const GALLERY_DIR := "C:/Users/palle/Documents/GitHub/ada_encyclopedia/public/softbody-fungus-gallery"

const SETTLE_SECONDS := 0.4

var _trait_mapper: CritterTraitMapper = null
var _fungus: Node3D = null
var _camera: Camera3D = null
var _root_3d: Node3D = null


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not DirAccess.dir_exists_absolute(GALLERY_DIR):
		push_error("[sf_gallery] gallery dir missing: %s" % GALLERY_DIR)
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
		if fname.begins_with("sf_") and fname.ends_with(".json"):
			configs.append(fname)
		fname = dir.get_next()
	dir.list_dir_end()
	configs.sort()
	print("[sf_gallery] %d configs queued" % configs.size())

	var rendered: int = 0
	for cfg_name in configs:
		var ok := await _render_one(cfg_name)
		if ok:
			rendered += 1
		if rendered % 5 == 0 and rendered > 0:
			print("  ... %d / %d" % [rendered, configs.size()])

	print("[sf_gallery] DONE: %d / %d soft mushrooms captured"
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
		push_warning("[sf_gallery] cannot open %s" % cfg_path)
		return false
	var raw := f.get_as_text()
	f.close()

	var parsed: Variant = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		push_warning("[sf_gallery] bad JSON: %s" % cfg_path)
		return false
	var cfg: Dictionary = parsed

	# Pull deform block out before from_dict, then strip generator keys.
	var deform: Dictionary = cfg.get("_deform", {})
	cfg.erase("_deform")
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

	# Free previous fungus.
	if _fungus and is_instance_valid(_fungus):
		_fungus.queue_free()
		await process_frame

	_fungus = Node3D.new()
	_fungus.name = cfg_id
	_root_3d.add_child(_fungus)
	FungusMorphologyClass.build(dna, _fungus, _trait_mapper, 3)

	# Same ground policy as the rigid fungus gallery: dark organic
	# rotting-wood ground, alien preset for highly-iridescent variants.
	var ground_kingdom: String = "alien" if dna.iridescence > 0.5 else "fungus"
	var ground_size: float = maxf(dna.scale * 1.6, 1.0)
	GroundPatchClass.attach(_fungus, ground_kingdom, Vector2(ground_size, ground_size))

	# Force opaque colours and apply soft-body deformation pose.
	_force_opaque_and_deform(_fungus, dna, deform)

	await process_frame

	# Frame the camera. Because deformation can blow up the AABB (esp.
	# tilted variants), we use a slightly more generous distance.
	var aabb: AABB = _compute_aabb(_fungus)
	var visible_h: float = clampf(aabb.size.y, 0.2, 1.5)
	var visible_r: float = clampf(maxf(aabb.size.x, aabb.size.z) * 0.5, 0.1, 1.2)
	var dist: float = clampf(maxf(visible_h * 2.2, visible_r * 3.6), 0.7, 3.0)
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
		push_warning("[sf_gallery] viewport image null for %s" % cfg_id)
		return false

	var out_path := GALLERY_DIR + "/" + cfg_id + ".png"
	var save_err := img.save_png(out_path)
	if save_err != OK:
		push_warning("[sf_gallery] save_png failed for %s: %s"
			% [cfg_id, save_err])
		return false
	return true


## Apply opaque material + soft-body deformation pose. Walks Cap and
## Stem nodes (also any colony Bracket_<i> / Colony_<i> wrappers) and
## applies scale + rotation per the deform dict.
func _force_opaque_and_deform(node: Node, dna: CritterDNA, deform: Dictionary) -> void:
	for child in node.get_children():
		var name_str: String = child.name

		# Skip ground patches — they have their own ShaderMaterial
		# (living_ground.gdshader) that we want to preserve.
		if name_str.begins_with("GroundPatch_"):
			continue

		# Material override — same as fungus_dna_gallery_lab.
		var mat := StandardMaterial3D.new()
		if name_str == "Stem":
			mat.albedo_color = dna.secondary_color
			mat.roughness = 0.85
		elif name_str == "Cap":
			mat.albedo_color = dna.primary_color
			mat.roughness = 0.55
			if dna.iridescence > 0.4:
				mat.emission_enabled = true
				mat.emission = dna.primary_color
				mat.emission_energy_multiplier = dna.iridescence * 0.6
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

		# Deformation pose — per-node transform.
		if child is Node3D:
			var node3d := child as Node3D
			match name_str:
				"Stem":
					node3d.scale = Vector3(
						float(deform.get("stem_scale_x", 1.0)),
						float(deform.get("stem_scale_y", 1.0)),
						float(deform.get("stem_scale_z", 1.0))
					)
					var tx: float = deg_to_rad(float(deform.get("stem_tilt_x", 0.0)))
					var tz: float = deg_to_rad(float(deform.get("stem_tilt_z", 0.0)))
					# Tilt around the BASE of the stem, not its centre.
					# Stem mesh.position.y = stem_height/2 already, so
					# rotating the node tilts about its origin which is
					# the stem base. Good.
					node3d.rotation = Vector3(tx, node3d.rotation.y, tz)

				"Cap":
					node3d.scale = Vector3(
						float(deform.get("cap_scale_x", 1.0)),
						float(deform.get("cap_scale_y", 1.0)),
						float(deform.get("cap_scale_z", 1.0))
					)
					var tx2: float = deg_to_rad(float(deform.get("cap_tilt_x", 0.0)))
					var tz2: float = deg_to_rad(float(deform.get("cap_tilt_z", 0.0)))
					node3d.rotation = Vector3(tx2, node3d.rotation.y, tz2)
					var oy: float = float(deform.get("cap_offset_y", 0.0))
					node3d.position.y += oy

				"Gills", "Spores", "StemRing":
					# Gills / spores follow the cap — use cap scale for x/z
					# only (don't squash gills along y or they vanish).
					node3d.scale = Vector3(
						float(deform.get("cap_scale_x", 1.0)),
						1.0,
						float(deform.get("cap_scale_z", 1.0))
					)

		# Recurse — colonies wrap each mushroom in Colony_<i> / Bracket_<i>
		# nodes whose children are Cap / Stem / Gills.
		_force_opaque_and_deform(child, dna, deform)


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
