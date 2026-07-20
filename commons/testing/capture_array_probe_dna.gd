## Array-probe DNA sweep — ONE artifact given the props-dna-gallery
## treatment: studio bead-shots of twelve DNA configurations, proving the
## parameter dimensions (mode × count × spacing × color) actually vary the
## form. Same rig as capture_props_dna_gallery.gd (near-black catalog
## backdrop, filmic tonemap, AABB-orbit 3/4 camera, 1024²).
##
## Run:
##   godot --xr-mode off --no-window \
##     --script res://commons/testing/capture_array_probe_dna.gd -- \
##     --out=user://array_probe_dna
extends SceneTree

const CAPTURE_SIZE: Vector2i = Vector2i(1024, 1024)
const BG_COLOR: Color = Color(0.055, 0.055, 0.070)
const CAMERA_FOV: float = 32.0
const CAMERA_YAW: float = 0.55
const CAMERA_PITCH: float = -0.30
const FRAME_PADDING: float = 1.95
const SCENE := "res://commons/artifacts/array_probe/array_probe.tscn"

const EMBER := Color(0.86, 0.30, 0.10)
const SIGNAL := Color(0.20, 0.85, 1.00)

var _viewport: SubViewport
var _camera: Camera3D
var _scene_holder: Node3D
var _output_dir: String = "user://array_probe_dna"
var _entries: Array = []

# The variant table — the artifact's DNA exhausted one dial at a time.
const VARIANTS := [
	{"variant": "linear_5_sparse", "meta": "linear_array_demo",
	 "dna": {"mode": "linear", "count": 5, "spacing": 0.34},
	 "label": "Linear, five, sparse", "notes": "The queue with room to breathe — five elements under the law of nexts, spacing wide enough that each cube reads alone before it reads as a row."},
	{"variant": "linear_7_standard", "meta": "linear_array_demo",
	 "dna": {"mode": "linear", "count": 7},
	 "label": "Linear, seven — the baseline", "notes": "The probe as placed in the map: seven parts, the plain queue. Every other cell in this gallery is this one with a dial turned."},
	{"variant": "linear_12_dense", "meta": "linear_array_demo",
	 "dna": {"mode": "linear", "count": 12, "spacing": 0.20},
	 "label": "Linear, twelve, dense", "notes": "The queue at rush hour — count up, spacing down, and the row starts reading as a BAR: exhaustion approaching continuity."},
	{"variant": "radial_6_council", "meta": "radial_array_demo",
	 "dna": {"mode": "radial", "count": 6},
	 "label": "Radial, six — the council", "notes": "Six under the law of angles: the hexagon, chemistry's favorite committee. No first, no last, every member facing the empty chair in the middle."},
	{"variant": "radial_9", "meta": "radial_array_demo",
	 "dna": {"mode": "radial", "count": 9},
	 "label": "Radial, nine", "notes": "Nine around the circle — the council grown past the hexagon into something looser: membership without symmetry's neatness."},
	{"variant": "radial_12_clock", "meta": "radial_array_demo",
	 "dna": {"mode": "radial", "count": 12, "spacing": 0.30},
	 "label": "Radial, twelve — the clock", "notes": "Twelve under the law of angles is a clock face before it is anything else — the radial array arriving at the arrangement a culture already memorized."},
	{"variant": "grid_9_field", "meta": "grid_array_demo",
	 "dna": {"mode": "grid", "count": 9},
	 "label": "Grid, nine — the field", "notes": "Three by three, each element addressed twice — the smallest square field, and the arrangement every map in this project stands on."},
	{"variant": "grid_16", "meta": "grid_array_demo",
	 "dna": {"mode": "grid", "count": 16, "spacing": 0.24},
	 "label": "Grid, sixteen", "notes": "Four by four: the field squared — enough cells that the eye stops counting members and starts reading ROWS. The moment an array becomes a territory."},
	{"variant": "stack_5", "meta": "stack_array_demo",
	 "dna": {"mode": "stack", "count": 5},
	 "label": "Stack, five", "notes": "Five under the law of aboves — a pile young enough to look stable. Order is load-bearing: every element rests its case on the one below."},
	{"variant": "stack_8_tower", "meta": "stack_array_demo",
	 "dna": {"mode": "stack", "count": 8},
	 "label": "Stack, eight — the tower", "notes": "Eight high and the stack becomes a tower testing patience — the only arrangement in the family where MORE visibly means RISKIER."},
	{"variant": "linear_7_ember", "meta": "linear_array_demo",
	 "dna": {"mode": "linear", "count": 7, "primitive_color": EMBER},
	 "label": "Linear, seven — ember finish", "notes": "The baseline queue in the station's signal-ember palette: the same law wearing the corridor accent, kin to the door with the lit threshold."},
	{"variant": "radial_9_signal", "meta": "radial_array_demo",
	 "dna": {"mode": "radial", "count": 9, "primitive_color": SIGNAL},
	 "label": "Radial, nine — signal finish", "notes": "The council lit in signal cyan — the color dial proving DNA is not only geometry: the same nine members, rebadged from stock to beacon."},
]


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_output_dir = a.substr(6)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))

	_viewport = SubViewport.new()
	_viewport.size = CAPTURE_SIZE
	_viewport.transparent_bg = false
	_viewport.own_world_3d = true
	var iso_world := World3D.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.65, 0.72)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	iso_world.environment = env
	_viewport.world_3d = iso_world
	_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.msaa_3d = Viewport.MSAA_8X
	_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	_viewport.use_taa = false
	_viewport.use_debanding = true
	get_root().add_child(_viewport)

	var key := DirectionalLight3D.new()
	key.light_energy = 1.25
	key.rotation = Vector3(deg_to_rad(-42.0), deg_to_rad(28.0), 0.0)
	_viewport.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.45
	fill.rotation = Vector3(deg_to_rad(-18.0), deg_to_rad(-140.0), 0.0)
	_viewport.add_child(fill)

	_camera = Camera3D.new()
	_camera.fov = CAMERA_FOV
	_viewport.add_child(_camera)
	_camera.current = true

	_scene_holder = Node3D.new()
	_viewport.add_child(_scene_holder)

	await process_frame
	await _run()


func _run() -> void:
	var packed: PackedScene = load(SCENE)
	var index := 0
	for spec in VARIANTS:
		index += 1
		var node: Node3D = packed.instantiate()
		var dna: Dictionary = spec.get("dna", {})
		for prop in dna.keys():
			node.set(prop, dna[prop])
		node.set_meta("artifact_lookup_name", str(spec.get("meta", "")))
		_scene_holder.add_child(node)
		await create_timer(0.4).timeout

		var aabb: AABB = _combined_aabb(node)
		if aabb.size.length() < 0.001:
			aabb = AABB(Vector3(-0.5, 0, -0.5), Vector3(1, 1, 1))
		var center: Vector3 = aabb.position + aabb.size * 0.5
		var max_dim: float = max(aabb.size.x, max(aabb.size.y, aabb.size.z))
		var dist: float = max_dim * FRAME_PADDING + 0.5
		var offset := Vector3(
			sin(CAMERA_YAW) * cos(CAMERA_PITCH),
			-sin(CAMERA_PITCH),
			cos(CAMERA_YAW) * cos(CAMERA_PITCH)
		) * dist
		_camera.global_position = center + offset
		_camera.look_at(center, Vector3.UP)

		await process_frame
		await process_frame
		var img: Image = _viewport.get_texture().get_image()
		var vid := "array_probe_%02d_%s" % [index, str(spec["variant"])]
		img.save_png("%s/%s.png" % [_output_dir, vid])
		var dna_clean := {}
		for k in dna.keys():
			var v = dna[k]
			dna_clean[k] = ("%.3f,%.3f,%.3f,%.3f" % [v.r, v.g, v.b, v.a]) if v is Color else v
		var sidecar := {"id": vid, "label": spec.get("label", ""),
			"notes": spec.get("notes", ""), "dna": dna_clean,
			"meta": spec.get("meta", ""), "scene": SCENE}
		var jf := FileAccess.open("%s/%s.json" % [_output_dir, vid], FileAccess.WRITE)
		jf.store_string(JSON.stringify(sidecar, "\t"))
		jf.close()
		_entries.append({"id": vid, "index": index,
			"label": spec.get("label", ""), "notes": spec.get("notes", ""),
			"dna": dna_clean,
			"image": "/array-probe-dna/%s.png" % vid,
			"config": "/array-probe-dna/%s.json" % vid})
		for c in _scene_holder.get_children():
			c.queue_free()
		await create_timer(0.05).timeout

	var manifest := {
		"version": 1,
		"description": "ONE artifact (array_probe) auto-researched in the props-dna-gallery register: twelve DNA configurations across mode (linear/radial/grid/stack) x count x spacing x color. Same .gd, same .tscn — twelve expressions. The single-artifact improvement loop's stage-2 exemplar.",
		"capture_size": [CAPTURE_SIZE.x, CAPTURE_SIZE.y],
		"entries": _entries,
	}
	var f := FileAccess.open("%s/manifest.json" % _output_dir, FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest, "\t"))
	f.close()
	print("DONE — %d entries saved to %s" % [_entries.size(), _output_dir])
	quit(0)


func _combined_aabb(node: Node3D) -> AABB:
	var result := AABB()
	var first := true
	var stack: Array = [node]
	while not stack.is_empty():
		var n = stack.pop_back()
		if n is MeshInstance3D and (n as MeshInstance3D).mesh:
			var mi := n as MeshInstance3D
			var ab: AABB = mi.global_transform * mi.mesh.get_aabb()
			if ab.size.length() > 0.0:
				if first:
					result = ab
					first = false
				else:
					result = result.merge(ab)
		for c in n.get_children():
			stack.push_back(c)
	return result
