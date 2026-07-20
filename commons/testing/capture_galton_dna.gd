## Galton-board DNA sweep — the spine hero given the props-dna studio
## treatment: twelve DNA configurations across peg_rows (the critical
## parameter — bins = rows + 1), board proportions, ball flow, and finish.
## Physics piece: each variant gets a settle window so the shot catches the
## board ALIVE — balls mid-fall, bins beginning their census.
##
## Run:
##   godot --xr-mode off --no-window \
##     --script res://commons/testing/capture_galton_dna.gd -- \
##     --out=user://galton_dna
extends SceneTree

const CAPTURE_SIZE: Vector2i = Vector2i(1024, 1024)
const BG_COLOR: Color = Color(0.055, 0.055, 0.070)
const CAMERA_FOV: float = 32.0
const CAMERA_YAW: float = 0.55
const CAMERA_PITCH: float = -0.30
const FRAME_PADDING: float = 1.95
const SCENE := "res://algorithms/randomness/galton_board/galton_board.tscn"
const SETTLE_S: float = 2.6   # physics time before the shot — balls in flight

const EMBER := Color(0.86, 0.30, 0.10)
const SIGNAL := Color(0.20, 0.85, 1.00)

var _viewport: SubViewport
var _camera: Camera3D
var _scene_holder: Node3D
var _output_dir: String = "user://galton_dna"
var _entries: Array = []

const VARIANTS := [
	{"variant": "rows_4_shallow",
	 "dna": {"peg_rows": 4, "num_bins": 5, "balls_per_second": 6.0},
	 "label": "Four rows — chance, shallow", "notes": "Four decisions deep, five bins wide: the bell at its bluntest. With this few coin-flips the middle barely wins — the curve is a hill, not a peak."},
	{"variant": "rows_8_standard",
	 "dna": {"balls_per_second": 6.0},
	 "label": "Eight rows — the baseline", "notes": "The board as placed in Random_Gaussian: eight decisions, nine bins, the classic bell. Every other cell in this gallery is this instrument with a dial turned."},
	{"variant": "rows_12_deep",
	 "dna": {"peg_rows": 12, "num_bins": 13, "board_height": 0.72, "balls_per_second": 6.0},
	 "label": "Twelve rows — the bell tightening", "notes": "Twelve decisions deep and the census sharpens: more independent choices, narrower relative spread — the central limit theorem turning its screw."},
	{"variant": "rows_16_cathedral",
	 "dna": {"peg_rows": 16, "num_bins": 17, "board_height": 0.95, "board_width": 0.62, "balls_per_second": 8.0},
	 "label": "Sixteen rows — the cathedral", "notes": "The board grown to a nave: sixteen ranks of pins, seventeen bins. At this depth individual luck is almost invisible — the aggregate is the whole architecture."},
	{"variant": "ball_rain",
	 "dna": {"balls_per_second": 40.0, "max_active_balls": 220},
	 "label": "The rain — census all at once", "notes": "Flow cranked to a downpour: the population arrives together and the board reads as weather. Statistics at the rate where you stop seeing balls and start seeing DISTRIBUTION."},
	{"variant": "single_file",
	 "dna": {"balls_per_second": 0.6, "max_active_balls": 6},
	 "label": "Single file — one verdict at a time", "notes": "The opposite tempo: one ball in flight, its path legible peg by peg. The bell disappears at this rate — proof it never lived in any single journey."},
	{"variant": "wide_board",
	 "dna": {"board_width": 0.85, "peg_spacing": 0.075, "balls_per_second": 6.0},
	 "label": "Wide set — the bell stretched", "notes": "Same eight decisions, wider steps: the distribution keeps its shape and loses its density — spacing as a zoom on chance."},
	{"variant": "vitrine",
	 "dna": {"color_glass": Color(0.7, 0.85, 1.0, 0.38), "balls_per_second": 6.0},
	 "label": "The vitrine — glass emphasized", "notes": "The case turned visible: the same instrument reading as a museum specimen, chance behind glass. Presentation is a dial too."},
	{"variant": "ember_finish",
	 "dna": {"color_ball": EMBER, "color_bin_bar": Color(0.86, 0.42, 0.10), "color_bell_curve": Color(1.0, 0.55, 0.2, 0.9), "balls_per_second": 6.0},
	 "label": "Ember finish", "notes": "The station's signal-ember palette on the census: falling coals, amber bins. Kin to the corridor door and the linear-ember probe — one family of accents across the catalog."},
	{"variant": "signal_finish",
	 "dna": {"color_ball": SIGNAL, "color_bin_bar": SIGNAL, "color_peg": Color(0.35, 0.45, 0.60), "balls_per_second": 6.0},
	 "label": "Signal finish", "notes": "The cyan rebadge: beads and bins in beacon blue. The color dial proving DNA is not only geometry — same law, different livery."},
	{"variant": "midnight",
	 "dna": {"color_peg": Color(0.16, 0.17, 0.22), "color_ball": Color(0.98, 0.98, 1.0), "color_bin_bar": Color(0.85, 0.88, 1.0), "balls_per_second": 8.0},
	 "label": "Midnight — high contrast", "notes": "Pins nearly swallowed by the dark, balls burning white: the board reduced to its EVENTS. What the eye keeps when the apparatus recedes is exactly the statistics."},
	{"variant": "bounce_wild",
	 "dna": {"ball_bounce": 0.75, "balls_per_second": 6.0},
	 "label": "Wild bounce — restitution 0.75", "notes": "The physics dial: livelier balls ricochet wider, fattening the tails. A reminder that this bell is EMBODIED — its width is material property, not just probability."},
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
		_scene_holder.add_child(node)
		# settle: let the physics run so the shot catches balls in flight
		await create_timer(SETTLE_S).timeout

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
		var vid := "galton_%02d_%s" % [index, str(spec["variant"])]
		img.save_png("%s/%s.png" % [_output_dir, vid])
		var dna_clean := {}
		for k in dna.keys():
			var v = dna[k]
			dna_clean[k] = ("%.3f,%.3f,%.3f,%.3f" % [v.r, v.g, v.b, v.a]) if v is Color else v
		var jf := FileAccess.open("%s/%s.json" % [_output_dir, vid], FileAccess.WRITE)
		jf.store_string(JSON.stringify({"id": vid, "label": spec.get("label", ""),
			"notes": spec.get("notes", ""), "dna": dna_clean, "scene": SCENE}, "\t"))
		jf.close()
		_entries.append({"id": vid, "index": index,
			"label": spec.get("label", ""), "notes": spec.get("notes", ""),
			"dna": dna_clean,
			"image": "/galton-dna/%s.png" % vid,
			"config": "/galton-dna/%s.json" % vid})
		for c in _scene_holder.get_children():
			c.queue_free()
		await create_timer(0.1).timeout

	var manifest := {
		"version": 1,
		"description": "The Galton board (spine hero, Random_Gaussian turn room) auto-researched in the props-dna register: twelve DNA configurations across peg_rows (the critical parameter — bins = rows + 1), board proportions, ball flow tempo, restitution, and finish. Physics captured ALIVE: each shot taken with balls in flight after a settle window.",
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
