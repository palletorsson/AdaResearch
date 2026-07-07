extends SceneTree

## botanical_flower_gallery_lab.gd
##
## Render every BotanicalFlower DNA config in the gallery and capture
## one PNG per variant. Built on the proven smoke_botanical_flower
## pattern: same scene each iteration, just swap the flower.
##
## Output: bf_*.png next to each config — the encyclopedia's
## /botanical-flower-gallery page reads these.
##
## Run:
##   godot --xr-mode off --no-window \
##     --script res://commons/testing/botanical_flower_gallery_lab.gd

const BotanicalFlowerScene := preload("res://commons/flora/botanical_flower.tscn")
const GroundPatchClass = preload("res://commons/testing/ground_patch.gd")

# Gallery dir hard-coded to the encyclopedia public path. If you move
# the encyclopedia, edit here.
const GALLERY_DIR := "C:/Users/palle/Documents/GitHub/ada_encyclopedia/public/botanical-flower-gallery"

const SETTLE_SECONDS := 0.4

var _flower: Node3D = null
var _camera: Camera3D = null
var _root_3d: Node3D = null


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not DirAccess.dir_exists_absolute(GALLERY_DIR):
		push_error("[bf_gallery] gallery dir missing: %s" % GALLERY_DIR)
		quit(1); return

	_setup_scene()
	await process_frame
	await process_frame

	# Walk every bf_*.json in the gallery dir.
	var dir := DirAccess.open(GALLERY_DIR)
	dir.list_dir_begin()
	var configs: Array[String] = []
	var fname := dir.get_next()
	while fname != "":
		if fname.begins_with("bf_") and fname.ends_with(".json"):
			configs.append(fname)
		fname = dir.get_next()
	dir.list_dir_end()
	configs.sort()
	print("[bf_gallery] %d configs queued" % configs.size())

	var rendered: int = 0
	for cfg_name in configs:
		var ok := await _render_one(cfg_name)
		if ok:
			rendered += 1
		if rendered % 5 == 0 and rendered > 0:
			print("  ... %d / %d" % [rendered, configs.size()])

	print("[bf_gallery] DONE: %d / %d flowers captured" % [rendered, configs.size()])
	quit(0)


func _setup_scene() -> void:
	_root_3d = Node3D.new()
	get_root().add_child(_root_3d)

	# Off-white background, matches /dna substrate-gallery aesthetic.
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

	# Camera — added to tree first, positioned per-flower in _render_one.
	_camera = Camera3D.new()
	_camera.fov = 35.0
	_camera.near = 0.05
	_camera.far = 30.0
	_root_3d.add_child(_camera)
	_camera.current = true


func _render_one(cfg_name: String) -> bool:
	var cfg_id := cfg_name.replace(".json", "")
	var cfg_path := GALLERY_DIR + "/" + cfg_name
	var f := FileAccess.open(cfg_path, FileAccess.READ)
	if f == null:
		push_warning("[bf_gallery] cannot open %s" % cfg_path)
		return false
	var raw := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		push_warning("[bf_gallery] bad JSON: %s" % cfg_path)
		return false
	var cfg: Dictionary = parsed

	# Convert RGB-list color fields to Color objects.
	for k in ["stem_color", "leaf_color", "petal_color", "sepal_color",
			  "stamen_color", "pistil_color"]:
		if cfg.has(k):
			var v = cfg[k]
			if v is Array and v.size() >= 3:
				cfg[k] = Color(float(v[0]), float(v[1]), float(v[2]))

	# Free previous flower if any.
	if _flower and is_instance_valid(_flower):
		_flower.queue_free()
		await process_frame

	# Spawn fresh flower at origin, on a meadow ground patch.
	_flower = BotanicalFlowerScene.instantiate()
	_root_3d.add_child(_flower)
	_flower.configure(cfg)
	_flower.rebuild()

	# Frame the camera based on the flower's expected size.
	# Effective flower height ≈ stem_height × overall_scale, plus a bit
	# for the flower head and inflorescence stack. Use a generous factor.
	var stem_h: float = float(cfg.get("stem_height", 0.25))
	var overall: float = float(cfg.get("overall_scale", 1.0))

	# Ground patch — flower kingdom signature: meadow soil + golden
	# pollen sparkle. Sized roughly to the flower's footprint × 1.5 so
	# the patch reads as ground without dominating the frame.
	var ground_size: float = maxf(stem_h * overall * 2.0, 0.6)
	GroundPatchClass.attach(
		_flower,
		"flower",
		Vector2(ground_size, ground_size)
	)
	var flower_count: int = int(cfg.get("flower_count", 1))
	var flower_spacing: float = float(cfg.get("flower_spacing", 0.04))
	# Inflorescences stack flowers above the stem top — add their span.
	var stack_top: float = stem_h + max(flower_count - 1, 0) * flower_spacing
	var visible_height: float = stack_top * overall * 1.2  # 20% margin
	visible_height = max(visible_height, 0.15)
	# Camera at 3/4 angle, distance proportional to flower height.
	var cam_dist: float = max(0.6, visible_height * 2.0)
	_camera.global_position = Vector3(cam_dist * 0.75, visible_height * 0.55, cam_dist * 0.75)
	_camera.look_at(Vector3(0.0, visible_height * 0.45, 0.0), Vector3.UP)

	await create_timer(SETTLE_SECONDS).timeout
	await process_frame
	await process_frame

	var img: Image = root.get_viewport().get_texture().get_image()
	if img == null:
		push_warning("[bf_gallery] viewport image null for %s" % cfg_id)
		return false

	var out_path := GALLERY_DIR + "/" + cfg_id + ".png"
	var save_err := img.save_png(out_path)
	if save_err != OK:
		push_warning("[bf_gallery] save_png failed for %s: %s" % [cfg_id, save_err])
		return false
	return true
