extends SceneTree

## tree_dna_gallery_lab.gd
##
## Render every td_*.json in the tree-dna-gallery folder by feeding it
## to TreeMorphology.build (the same path the biome paint dispatcher
## uses) and capturing one PNG per variant.
##
## Mirrors botanical_flower_gallery_lab.gd: one persistent scene with
## camera + sun + env, swap the tree each iteration.
##
## Run:
##   godot --xr-mode off --no-window \
##     --script res://commons/testing/tree_dna_gallery_lab.gd

const CritterDNAClass = preload("res://algorithms/nature_system/dna/critter_dna.gd")
const CritterTraitMapperClass = preload(
	"res://algorithms/nature_system/dna/critter_trait_mapper.gd"
)
const TreeMorphologyClass = preload(
	"res://algorithms/nature_system/morphology/tree_morphology.gd"
)
const GroundPatchClass = preload("res://commons/testing/ground_patch.gd")

const GALLERY_DIR := "C:/Users/palle/Documents/GitHub/ada_encyclopedia/public/tree-dna-gallery"

const SETTLE_SECONDS := 0.4

var _trait_mapper: CritterTraitMapper = null
var _tree: Node3D = null
var _camera: Camera3D = null
var _root_3d: Node3D = null


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not DirAccess.dir_exists_absolute(GALLERY_DIR):
		push_error("[tree_gallery] gallery dir missing: %s" % GALLERY_DIR)
		quit(1); return

	_setup_scene()
	_trait_mapper = CritterTraitMapperClass.new()
	await process_frame
	await process_frame

	# Walk every td_*.json
	var dir := DirAccess.open(GALLERY_DIR)
	dir.list_dir_begin()
	var configs: Array[String] = []
	var fname := dir.get_next()
	while fname != "":
		if fname.begins_with("td_") and fname.ends_with(".json"):
			configs.append(fname)
		fname = dir.get_next()
	dir.list_dir_end()
	configs.sort()
	print("[tree_gallery] %d configs queued" % configs.size())

	var rendered: int = 0
	for cfg_name in configs:
		var ok := await _render_one(cfg_name)
		if ok:
			rendered += 1
		if rendered % 5 == 0 and rendered > 0:
			print("  ... %d / %d" % [rendered, configs.size()])

	print("[tree_gallery] DONE: %d / %d trees captured"
		% [rendered, configs.size()])
	quit(0)


func _setup_scene() -> void:
	_root_3d = Node3D.new()
	get_root().add_child(_root_3d)

	# Off-white background — same as flower gallery.
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.92, 0.92, 0.95)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_BG
	env.ambient_light_energy = 0.6
	env.ambient_light_color = Color(0.95, 0.95, 1.0)
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	_root_3d.add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.light_energy = 1.5
	sun.shadow_enabled = false
	_root_3d.add_child(sun)

	# Camera — added to tree first, positioned per-tree in _render_one.
	_camera = Camera3D.new()
	_camera.fov = 35.0
	_camera.near = 0.05
	_camera.far = 100.0
	_root_3d.add_child(_camera)
	_camera.current = true


func _render_one(cfg_name: String) -> bool:
	var cfg_id := cfg_name.replace(".json", "")
	var cfg_path := GALLERY_DIR + "/" + cfg_name

	var f := FileAccess.open(cfg_path, FileAccess.READ)
	if f == null:
		push_warning("[tree_gallery] cannot open %s" % cfg_path)
		return false
	var raw := f.get_as_text()
	f.close()

	var parsed: Variant = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		push_warning("[tree_gallery] bad JSON: %s" % cfg_path)
		return false
	var cfg: Dictionary = parsed

	# Strip generator-only keys before handing to from_dict (which skips
	# unknown keys but errors on type mismatch for known ones).
	cfg.erase("_cluster")
	cfg.erase("_id")

	# Convert RGB lists to Color objects for the three color genes.
	for k in ["primary_color", "secondary_color", "tertiary_color"]:
		if cfg.has(k):
			var v = cfg[k]
			if v is Array and v.size() >= 3:
				cfg[k] = Color(float(v[0]), float(v[1]), float(v[2]))

	# Build DNA from the dict.
	var dna: CritterDNA = CritterDNAClass.new()
	dna.from_dict(cfg)
	dna.body_type = 0.0  # Force tree even if missing

	# Free the previous tree.
	if _tree and is_instance_valid(_tree):
		_tree.queue_free()
		await process_frame

	# Spawn a fresh tree at origin.
	_tree = Node3D.new()
	_tree.name = cfg_id
	_root_3d.add_child(_tree)

	# Use a higher LOD for gallery quality (3 = max).
	TreeMorphologyClass.build(dna, _tree, _trait_mapper, 3)

	# Tree-kingdom ground patch: mossy green earth with root-hump
	# vertex displacement. Sized to roughly twice the tree's expected
	# footprint so the moss reads even past the canopy.
	var ground_size: float = maxf(dna.scale * 2.4, 1.5)
	GroundPatchClass.attach(_tree, "tree", Vector2(ground_size, ground_size))

	# Estimate visible height for camera framing. Tree height roughly
	# scales with `scale * segments * part_length * 0.6` after L-system
	# growth, but the AABB is more accurate — wait one frame then
	# query the tree's combined AABB.
	await process_frame

	var aabb: AABB = _compute_aabb(_tree)
	var visible_h: float = maxf(aabb.size.y, 0.5)
	var visible_r: float = maxf(aabb.size.x, aabb.size.z) * 0.5
	var center: Vector3 = aabb.position + aabb.size * 0.5

	# Frame the tree from a 3/4 angle.
	var dist: float = maxf(maxf(visible_h * 1.4, visible_r * 2.4), 1.5)
	_camera.global_position = Vector3(
		dist * 0.75, center.y + visible_h * 0.15, dist * 0.75
	)
	_camera.look_at(Vector3(0.0, center.y, 0.0), Vector3.UP)

	await create_timer(SETTLE_SECONDS).timeout
	await process_frame
	await process_frame

	var img: Image = root.get_viewport().get_texture().get_image()
	if img == null:
		push_warning("[tree_gallery] viewport image null for %s" % cfg_id)
		return false

	var out_path := GALLERY_DIR + "/" + cfg_id + ".png"
	var save_err := img.save_png(out_path)
	if save_err != OK:
		push_warning("[tree_gallery] save_png failed for %s: %s"
			% [cfg_id, save_err])
		return false
	return true


## Walk the node and accumulate every MeshInstance3D's AABB into one
## combined AABB. Returns a default 1×1×1 box centred at origin if
## nothing has a mesh yet.
func _compute_aabb(node: Node) -> AABB:
	var combined := AABB()
	var first := true
	var stack: Array = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D and n.mesh != null:
			var local: AABB = (n as MeshInstance3D).get_aabb()
			# Transform to root's local space (we treat _tree as root).
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
