## Sweep capture for the ceiling DNA gallery.
##
## Renders each of the ten variants in commons/maps/ceiling_dna_library.json
## as a 3D Godot capture. A minimal chamber is built per variant (floor +
## four walls), then GridCeilingComponent runs with the variant's config
## and the camera shoots from inside the chamber looking slightly up at
## the ceiling. Output goes to <out>/{name}.png + a manifest.json that
## the /ceiling-dna-gallery page can load.
##
## Run:
##   "/c/Users/palle/Desktop/Godot_v4.6-stable_win64.exe" --path . \
##     --xr-mode off --no-window \
##     --script res://commons/testing/capture_ceiling_dna_gallery.gd -- \
##     --out=user://ceiling_dna_gallery
##
## Output: <out>/{name}.png + manifest.json
extends SceneTree

const LIBRARY_PATH := "res://commons/maps/ceiling_dna_library.json"
const CEILING_COMPONENT_PATH := "res://commons/grid/GridCeilingComponent.gd"
const CAPTURE_SIZE: Vector2i = Vector2i(1024, 768)
const BG_COLOR: Color = Color(0.03, 0.03, 0.04)
const ROOM_W: float = 9.0
const ROOM_D: float = 8.0
const EYE_HEIGHT: float = 1.7
const CAMERA_FOV: float = 70.0

var _output_dir: String = "user://ceiling_dna_gallery"
var _viewport: SubViewport
var _camera: Camera3D
var _chamber: Node3D
var _entries: Array = []


func _initialize() -> void:
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--out="):
			_output_dir = arg.split("=")[1]
	_run.call_deferred()


func _run() -> void:
	# Isolated viewport so other autoloads don't bleed in.
	_viewport = SubViewport.new()
	_viewport.size = CAPTURE_SIZE
	_viewport.own_world_3d = true
	var iso_world := World3D.new()

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.5, 0.6)
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	# Low exposure + minimal glow so the ceiling's recessed light
	# panels (which use emissive materials AND OmniLight3D) don't
	# wash out the rest of the image. We want fixture detail readable.
	env.tonemap_exposure = 0.45
	env.tonemap_white = 1.4
	env.ssao_enabled = true
	env.ssao_intensity = 0.5
	env.ssao_radius = 0.6
	env.glow_enabled = true
	env.glow_intensity = 0.10
	env.glow_bloom = 0.04
	env.glow_strength = 0.6
	iso_world.environment = env

	_viewport.world_3d = iso_world
	_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.msaa_3d = Viewport.MSAA_4X
	get_root().add_child(_viewport)

	_camera = Camera3D.new()
	_camera.fov = CAMERA_FOV
	_camera.near = 0.05
	_camera.far = 80.0
	_camera.current = true
	_viewport.add_child(_camera)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))

	# Load DNA library.
	if not FileAccess.file_exists(LIBRARY_PATH):
		push_error("ceiling_dna_library.json not found at %s" % LIBRARY_PATH)
		quit(1)
		return
	var raw: String = FileAccess.get_file_as_string(LIBRARY_PATH)
	var library = JSON.parse_string(raw)
	if not (library is Dictionary):
		push_error("Library parse failed")
		quit(1)
		return

	# Load GridCeilingComponent script.
	var ceiling_script: GDScript = load(CEILING_COMPONENT_PATH)
	if ceiling_script == null:
		push_error("Failed to load GridCeilingComponent")
		quit(1)
		return

	# Iterate variants.
	for name in library.keys():
		if name.begins_with("_"):
			continue
		var entry = library[name]
		if not (entry is Dictionary):
			continue
		var ceiling_cfg: Dictionary = entry.get("ceiling", {})
		var blurb: String = String(entry.get("blurb", ""))

		print("[ceiling-dna] Capturing %s …" % name)
		await _capture_variant(String(name), blurb, ceiling_cfg, ceiling_script)

	# Manifest.
	var manifest := {
		"version": 1,
		"description": "Ten ceiling DNA variants rendered in Godot via GridCeilingComponent. Each capture is a minimal 9×8m chamber (bare floor + walls) so the ceiling is the only feature evaluated. Camera at player POV (1.7m eye-height), looking slightly upward toward the back wall so the ceiling fills the upper two-thirds of the frame.",
		"capture_size": [CAPTURE_SIZE.x, CAPTURE_SIZE.y],
		"camera": {
			"projection": "perspective",
			"fov_deg": CAMERA_FOV,
			"eye_height_m": EYE_HEIGHT,
			"position_formula": "stand at (0, eye, room_depth*0.35), look at (0, ceiling_height*0.75, -room_depth*0.35)",
		},
		"room_width_m": ROOM_W,
		"room_depth_m": ROOM_D,
		"entries": _entries,
	}
	var f := FileAccess.open("%s/manifest.json" % _output_dir, FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest, "\t"))
	f.close()
	print("DONE — %d entries → %s" % [_entries.size(), _output_dir])
	quit(0)


# Build a minimal chamber, attach a GridCeilingComponent, generate the
# ceiling from the variant's config, capture, then tear down for the
# next variant.
func _capture_variant(name: String, blurb: String, ceiling_cfg: Dictionary, ceiling_script: GDScript) -> void:
	# Determine ceiling height for camera framing (defaults to 4.0).
	var ceiling_h: float = float(ceiling_cfg.get("height", 4.0))

	# Build the chamber.
	_chamber = Node3D.new()
	_chamber.name = "Chamber"
	_viewport.add_child(_chamber)

	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.88, 0.88, 0.90)
	wall_mat.roughness = 0.6

	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.55, 0.55, 0.58)
	floor_mat.roughness = 0.7

	# Floor.
	var fl := MeshInstance3D.new()
	fl.name = "Floor"
	var fm := BoxMesh.new()
	fm.size = Vector3(ROOM_W, 0.05, ROOM_D)
	fl.mesh = fm
	fl.material_override = floor_mat
	fl.position = Vector3(ROOM_W * 0.5, -0.025, ROOM_D * 0.5)
	_chamber.add_child(fl)

	# Four walls (full height up to ceiling).
	for spec in [
		{"size": Vector3(ROOM_W, ceiling_h, 0.05), "pos": Vector3(ROOM_W * 0.5, ceiling_h * 0.5, -0.025)},
		{"size": Vector3(ROOM_W, ceiling_h, 0.05), "pos": Vector3(ROOM_W * 0.5, ceiling_h * 0.5, ROOM_D + 0.025)},
		{"size": Vector3(0.05, ceiling_h, ROOM_D), "pos": Vector3(-0.025, ceiling_h * 0.5, ROOM_D * 0.5)},
		{"size": Vector3(0.05, ceiling_h, ROOM_D), "pos": Vector3(ROOM_W + 0.025, ceiling_h * 0.5, ROOM_D * 0.5)},
	]:
		var w := MeshInstance3D.new()
		var wm := BoxMesh.new()
		wm.size = spec["size"]
		w.mesh = wm
		w.material_override = wall_mat
		w.position = spec["pos"]
		_chamber.add_child(w)

	# Minimal grid_data stub. GridCeilingComponent types its
	# data_component field as GridDataComponent, so we use a real one
	# and just set its `grid_dimensions` so get_grid_dimensions returns
	# the chamber size.
	var stub_data := GridDataComponent.new()
	stub_data.grid_dimensions = Vector3i(int(ROOM_W), 1, int(ROOM_D))
	_chamber.add_child(stub_data)

	# Instantiate the GridCeilingComponent (it's a Node, not Node3D, so
	# add it as child of the chamber). It mounts its meshes as siblings
	# on grid_system, so we pass _chamber as the grid_system reference.
	var ceiling = ceiling_script.new()
	ceiling.grid_system = _chamber
	ceiling.data_component = stub_data
	ceiling.cube_size = 1.0
	ceiling.gutter = 0.0
	# Provide width/depth so the component spans the full chamber.
	ceiling.ceiling_width = ROOM_W
	ceiling.ceiling_depth = ROOM_D
	_chamber.add_child(ceiling)

	# Generate ceiling.
	ceiling.generate_ceiling(ceiling_cfg)

	# Camera: stand near the back of the chamber at eye-height, look
	# diagonally toward the opposite corner at ~60% ceiling height.
	# This frames the ceiling along the upper third of the image while
	# keeping enough wall + floor visible to read the space.
	_camera.position = Vector3(ROOM_W * 0.5 - 1.5, EYE_HEIGHT, ROOM_D * 0.92)
	_camera.look_at(Vector3(ROOM_W * 0.5 + 0.8, ceiling_h * 0.6, ROOM_D * 0.05), Vector3.UP)

	# Wait a couple frames for lights + flicker timers to settle.
	await create_timer(0.20).timeout

	# Capture.
	var img: Image = _viewport.get_texture().get_image()
	if img == null:
		push_warning("Capture returned null for %s" % name)
		_chamber.queue_free()
		return
	var out_path: String = "%s/%s.png" % [_output_dir, name]
	img.save_png(out_path)
	print("  -> %s" % out_path)

	_entries.append({
		"name": name,
		"blurb": blurb,
		"image": "%s.png" % name,
		"ceiling": ceiling_cfg,
	})

	# Tear down chamber for next variant.
	_chamber.queue_free()
	_chamber = null
	await create_timer(0.05).timeout


# (Earlier draft used an inner _DataStub class; replaced with a real
# GridDataComponent instance whose grid_dimensions field is set
# directly, since GridCeilingComponent types data_component strictly.)
