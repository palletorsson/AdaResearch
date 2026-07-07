extends SceneTree
## Principal Interface Gallery — renders each interface TYPE built from its
## principal config (InterfacePresets.TYPES), populated to its recipe, so we can
## iterate on the setups centrally and then push to artifacts.
##   godot --path . --xr-mode off --no-window --script res://commons/testing/capture_interface_presets.gd
## Out: user://interface_presets/<type>.png + manifest.json
##
## Iteration loop: tweak interface_presets.gd / control_panel.gd / control_console.gd
## → re-run → review tiles → repeat until perfect → then update target artifacts.

const InterfacePresets = preload("res://commons/ui/interface_presets.gd")
const OUT_DIR := "user://interface_presets"

# Rendering tuned to match /props-dna-gallery (the project's proven catalog look):
# isolated World3D, filmic tonemap + SSAO + glow/bloom, a 3-light studio rig, and
# a perspective orbit camera — so the tiles read as lit product shots, not flat.
const CAPTURE_SIZE := Vector2i(1100, 1100)
const BG_COLOR := Color(0.055, 0.055, 0.070)
const CAMERA_FOV := 32.0          # mild telephoto — clean silhouettes
const CAMERA_YAW := 0.55          # 3/4 from the right
const CAMERA_PITCH := -0.26       # slightly above
const FRAME_PADDING := 1.7

var _viewport: SubViewport
var _scene_holder: Node3D
var _cam: Camera3D
var _entries: Array = []

# id, title, populate-method. Order = gallery order.
const SPECS := [
	["workbench", "WORKBENCH"],
	["machine", "MACHINE"],
	["console", "CONSOLE"],
	["readout", "READOUT"],
	["rack", "RACK"],
	["plaque", "PLAQUE"],
	["dashboard", "DASHBOARD"],
	["pedestal", "PEDESTAL"],
	["tower", "TOWER"],
	["table", "TABLE"],
	["monitor_bank", "MONITOR BANK"],
	["grid_board", "GRID BOARD"],
	["vitrine", "VITRINE"],
	["tank", "TANK"],
	["dish", "DISH"],
	["frame", "FRAME"],
	["launcher", "LAUNCHER"],
]


func _initialize() -> void:
	# Isolated SubViewport with its own World3D (clean backdrop, no scene-env clash).
	_viewport = SubViewport.new()
	_viewport.size = CAPTURE_SIZE
	_viewport.own_world_3d = true
	var iso := World3D.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.65, 0.72)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.tonemap_white = 1.15
	env.ssao_enabled = true
	env.ssao_intensity = 0.5
	env.ssao_radius = 0.6
	env.glow_enabled = true
	env.glow_intensity = 0.40
	env.glow_bloom = 0.12
	iso.environment = env
	_viewport.world_3d = iso
	_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.msaa_3d = Viewport.MSAA_8X
	_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	_viewport.use_debanding = true
	get_root().add_child(_viewport)
	# Three-light studio rig: warm key (camera side, shadows), cool fill, rim.
	var key := DirectionalLight3D.new()
	key.light_energy = 1.25; key.light_color = Color(1.0, 0.97, 0.92)
	key.rotation_degrees = Vector3(-35, 25, 0); key.shadow_enabled = true
	_viewport.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.45; fill.light_color = Color(0.85, 0.90, 1.0)
	fill.rotation_degrees = Vector3(-15, -120, 0)
	_viewport.add_child(fill)
	var rim := DirectionalLight3D.new()
	rim.light_energy = 0.60; rim.rotation_degrees = Vector3(-80, 180, 0)
	_viewport.add_child(rim)
	_cam = Camera3D.new()
	_cam.fov = CAMERA_FOV; _cam.near = 0.02; _cam.far = 80.0; _cam.current = true
	_viewport.add_child(_cam)
	_scene_holder = Node3D.new()
	_viewport.add_child(_scene_holder)
	_run.call_deferred()


func _build_one(type: String, title: String, skin: String = "braun") -> Node3D:
	var node: Node3D = InterfacePresets.build(type, title, 1.0, skin)
	node.position = Vector3(0.0, 1.0, 0.0)
	_scene_holder.add_child(node)
	match type:
		"workbench": _populate_workbench(node)
		"machine": _populate_machine(node)
		"console": _populate_console(node)
		"readout": _populate_readout(node)
		"rack": _populate_rack(node)
		"plaque": node.call("add_readout", "POSTULATE I\na straight line between two points")
		"dashboard": node.call("add_readout", "density 0.42   kingdoms 3\nfoliage 1.0   critters 64\nstage 11 / 19   STABLE")
		"pedestal": _populate_pedestal(node)
		"tower": node.call("add_readout", "NODE 07\n42 req/s")
		"table": _populate_table(node)
		"monitor_bank": _populate_monitor_bank(node)
		"grid_board": _populate_grid_board(node)
		"vitrine": _populate_vitrine(node)
		"tank": _populate_tank(node)
		"dish": _populate_dish(node)
		"frame": _populate_frame(node)
		"launcher": _populate_launcher(node)
	return node


# ── Per-type representative content (recipe placeholders) ──────────────
func _populate_workbench(c: Node3D) -> void:
	c.call("add_readout", "value = 0.50\nresult = 1.23")
	c.call("add_slider", "PARAM", "PARAM")
	_fill_monitor(c.call("add_monitor", Vector2(0.8, 0.5)))


func _populate_machine(c: Node3D) -> void:
	c.call("add_readout", "mode: A\nstep 3 / 8")
	c.call("add_button", "RUN")
	c.call("add_button", "STEP")
	c.call("add_button", "RESET")


func _populate_console(c: Node3D) -> void:
	c.call("add_readout", "target locked\npower 0.72")
	c.call("add_slider", "AIM", "AIM")
	c.call("add_slider", "POWER", "POWER")
	c.call("add_button", "FIRE")
	_fill_cube(c.call("add_cube_space", 0.8))


func _populate_readout(c: Node3D) -> void:
	c.call("add_readout", "x = 1.40   y = -0.30\n|v| = 1.43   θ = 27°")


func _populate_rack(c: Node3D) -> void:
	c.call("add_slider", "FREQ", "FREQ")
	c.call("add_slider", "GAIN", "GAIN")
	c.call("add_readout", "440 Hz")


func _populate_pedestal(c: Node3D) -> void:
	c.call("add_readout", "IDENTITY\nverified")
	c.call("add_button", "SCAN")


func _populate_table(c: Node3D) -> void:
	c.call("add_readout", "layout 6 x 6")
	c.call("add_slider", "ZOOM", "ZOOM")


func _populate_monitor_bank(c: Node3D) -> void:
	c.call("add_readout", "SYS NOMINAL")
	c.call("add_slider", "CH", "CH")
	c.call("add_button", "REC")


func _populate_grid_board(c: Node3D) -> void:
	c.call("add_readout", "12 / 36 cells")
	c.call("add_button", "CLEAR")


# ── container/apparatus forms: readout on the board + content in content() ──
func _populate_vitrine(c: Node3D) -> void:
	c.call("add_readout", "SPECIMEN\nstable")
	var root: Node3D = c.call("content")
	if root:
		var t := MeshInstance3D.new()
		var tm := TorusMesh.new(); tm.inner_radius = 0.07; tm.outer_radius = 0.16
		t.mesh = tm; t.rotation_degrees = Vector3(38, 0, 22)
		t.material_override = _emat(Color(0.6, 1.0, 0.7))
		root.add_child(t)


func _populate_tank(c: Node3D) -> void:
	c.call("add_readout", "depth 0.32 m")
	var root: Node3D = c.call("content")
	if root:
		# a translucent liquid surface + a few suspended motes
		var surf := MeshInstance3D.new()
		var bm := BoxMesh.new(); bm.size = Vector3(0.7, 0.006, 0.48)
		surf.mesh = bm; surf.position = Vector3(0, 0.22, 0)
		surf.material_override = _emat(Color(0.3, 0.7, 1.0))
		(surf.material_override as StandardMaterial3D).emission_energy_multiplier = 0.3
		root.add_child(surf)
		for p in [Vector3(-0.2, 0.1, 0.1), Vector3(0.18, 0.16, -0.12), Vector3(0.0, 0.06, 0.0)]:
			var d := MeshInstance3D.new()
			var sm := SphereMesh.new(); sm.radius = 0.03; sm.height = 0.06
			d.mesh = sm; d.position = p; d.material_override = _emat(Color(0.5, 0.9, 1.0))
			root.add_child(d)


func _populate_dish(c: Node3D) -> void:
	c.call("add_readout", "gen 42")
	var root: Node3D = c.call("content")
	if root:
		for i in 16:
			var a := float(i) * 1.7
			var r := 0.07 + float(i) * 0.031
			var cell := MeshInstance3D.new()
			var bm := BoxMesh.new(); bm.size = Vector3(0.055, 0.01, 0.055)
			cell.mesh = bm
			cell.position = Vector3(cos(a) * r, 0, sin(a) * r)
			cell.material_override = _emat(Color(0.4, 1.0, 0.5))
			root.add_child(cell)


func _populate_frame(c: Node3D) -> void:
	c.call("add_readout", "period 1.4 s")
	var root: Node3D = c.call("content")
	if root:
		# Newton's-cradle row of bobs on lines, hung from the top (y=0 = top beam)
		for i in 5:
			var x := -0.24 + i * 0.12
			var line := MeshInstance3D.new()
			var lm := BoxMesh.new(); lm.size = Vector3(0.004, 0.34, 0.004)
			line.mesh = lm; line.position = Vector3(x, -0.17, 0)
			line.material_override = _emat(Color(0.7, 0.7, 0.75), 0.0)
			root.add_child(line)
			var bob := MeshInstance3D.new()
			var sm := SphereMesh.new(); sm.radius = 0.05; sm.height = 0.10
			bob.mesh = sm; bob.position = Vector3(x, -0.36, 0)
			bob.material_override = _emat(Color(0.85, 0.88, 0.95), 0.0)
			(bob.material_override as StandardMaterial3D).metallic = 0.6
			root.add_child(bob)


func _populate_launcher(c: Node3D) -> void:
	c.call("add_readout", "45 deg  power 0.7")
	var root: Node3D = c.call("content")
	if root:
		# a glowing trajectory arc from the muzzle
		for i in 9:
			var t := float(i) / 8.0
			var p := Vector3(0, t * 0.7 - t * t * 0.5, t * 0.7)
			var dot := MeshInstance3D.new()
			var sm := SphereMesh.new(); sm.radius = 0.018; sm.height = 0.036
			dot.mesh = sm; dot.position = p
			dot.material_override = _emat(Color(1.0, 0.6, 0.2))
			root.add_child(dot)


# ── placeholder viz content (shared with test_console_viz) ─────────────
func _fill_monitor(content: Node3D) -> void:
	if content == null: return
	var heights := [0.18, 0.30, 0.22, 0.36, 0.28, 0.40, 0.24]
	var x := -0.32
	for hgt in heights:
		var bar := MeshInstance3D.new()
		var bm := BoxMesh.new(); bm.size = Vector3(0.06, hgt, 0.006)
		bar.mesh = bm; bar.position = Vector3(x, -0.22 + hgt * 0.5, 0.0)
		bar.material_override = _emat(Color(0.30, 0.85, 1.0))
		content.add_child(bar); x += 0.095


func _fill_cube(content: Node3D) -> void:
	if content == null: return
	var sph := MeshInstance3D.new()
	var sm := SphereMesh.new(); sm.radius = 0.13; sm.height = 0.26
	sph.mesh = sm; sph.material_override = _emat(Color(1.0, 0.55, 0.2))
	content.add_child(sph)
	for p in [Vector3(0.28, 0.22, -0.2), Vector3(-0.25, -0.2, 0.24)]:
		var cube := MeshInstance3D.new()
		var bm := BoxMesh.new(); bm.size = Vector3(0.1, 0.1, 0.1)
		cube.mesh = bm; cube.position = p
		cube.material_override = _emat(Color(0.5, 0.9, 1.0))
		content.add_child(cube)


func _emat(c: Color, energy: float = 0.5) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	if energy > 0.0:
		m.emission_enabled = true; m.emission = c; m.emission_energy_multiplier = energy
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	else:
		m.roughness = 0.5; m.metallic = 0.2
	return m


func _run() -> void:
	# Default: 17 tiles in braun → user://interface_presets. With --skins: the
	# full 17×5 matrix → user://interface_skins (each tile <type>_<skin>.png).
	var skins: Array = ["braun"]
	var outdir: String = OUT_DIR
	for a in OS.get_cmdline_user_args():
		if a == "--skins":
			skins = ["braun", "black_mesa", "sci_fi", "civic", "warm_wood"]
			outdir = "user://interface_skins"
	var multi := skins.size() > 1
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(outdir))
	await process_frame
	for skin in skins:
		for spec in SPECS:
			var type: String = spec[0]
			var title: String = spec[1]
			var node := _build_one(type, title, skin)
			await process_frame
			await create_timer(0.5).timeout
			await process_frame
			await process_frame
			_frame_camera(node)
			await process_frame
			await create_timer(0.15).timeout
			await process_frame
			var slug: String = ("%s_%s" % [type, skin]) if multi else type
			_viewport.get_texture().get_image().save_png("%s/%s.png" % [outdir, slug])
			var cfg: Dictionary = InterfacePresets.config_for(type)
			_entries.append({
				"id": "interface_%s" % slug,
				"type": type,
				"skin": skin,
				"title": title,
				"png": "%s.png" % slug,
				"housing": cfg.get("housing", "console"),
				"config": cfg,
			})
			node.queue_free()
			await process_frame
		print("[presets] skin %s done" % skin)
	var f := FileAccess.open("%s/manifest.json" % outdir, FileAccess.WRITE)
	f.store_string(JSON.stringify({"entries": _entries}, "\t"))
	f.close()
	print("[presets] wrote manifest with %d entries" % _entries.size())
	quit()


func _frame_camera(node: Node3D) -> void:
	# Perspective AABB-orbit (matches the DNA gallery): 3/4 angle, dist scaled to
	# the form's largest dimension so short boards and tall towers both fit.
	var box := _aabb(node)
	var focus := box.get_center()
	var max_dim: float = maxf(box.size.x, maxf(box.size.y, box.size.z))
	var dist: float = max_dim * FRAME_PADDING + 0.5
	var offset := Vector3(
		sin(CAMERA_YAW) * cos(CAMERA_PITCH),
		-sin(CAMERA_PITCH),
		cos(CAMERA_YAW) * cos(CAMERA_PITCH)
	) * dist
	_cam.global_position = focus + offset
	_cam.look_at(focus, Vector3.UP)


func _aabb(node: Node) -> AABB:
	var box := AABB(); var first := true; var stack: Array = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is VisualInstance3D:
			var ab: AABB = (n as VisualInstance3D).get_aabb()
			ab = (n as Node3D).global_transform * ab
			if first: box = ab; first = false
			else: box = box.merge(ab)
		for c in n.get_children(): stack.append(c)
	return box
