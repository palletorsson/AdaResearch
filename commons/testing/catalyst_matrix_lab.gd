extends SceneTree

## Catalyst Matrix Lab — auto-research
##
## Drops every catalyst projectile mode onto a fresh CatalystFoe.
## For each combo: captures before+after screenshots, logs the
## state change and foe_mode result, writes a markdown matrix
## to user://catalyst_matrix/results.md.
##
## Output:
##   user://catalyst_matrix/<mode>_before.png
##   user://catalyst_matrix/<mode>_after.png
##   user://catalyst_matrix/results.md  (markdown matrix doc)
##   user://catalyst_matrix/results.json (raw data)
##
## Run:
##   godot --xr-mode off --no-window --script res://commons/testing/catalyst_matrix_lab.gd

const FoeScene := preload("res://commons/hazards/catalyst_foe/catalyst_foe.tscn")
const ProjectileScript := preload("res://commons/hazards/becoming_catalyst/catalyst_projectile.gd")

# Each entry: mode_id → metadata (color from mode_X.gd's create_projectile)
# wait_frames overrides the default settle time for slow / bouncy projectiles
# that need extra physics ticks to actually reach the foe. Default is 250.
const MODES: Array = [
	{"id": "primitives",     "color": Color(0.85, 0.85, 0.95), "speed": 6.0,  "expected_foe_mode": 0, "label": "GOO (convert)",                   "wait_frames": 500, "lifetime": 10.0},
	{"id": "transformation", "color": Color(0.7, 0.3, 0.85),   "speed": 12.0, "expected_foe_mode": 1, "label": "TRANSPORT (push peers)"},
	{"id": "chromatic",      "color": Color(1.0, 0.5, 0.2),    "speed": 10.0, "expected_foe_mode": 4, "label": "CHROMA (hue+badge)"},
	{"id": "forces",         "color": Color(0.3, 0.7, 1.0),    "speed": 14.0, "expected_foe_mode": 2, "label": "SWARM (faster + bigger)"},
	{"id": "waveform",       "color": Color(0.9, 0.4, 0.6),    "speed": 9.0,  "expected_foe_mode": 5, "label": "WAVE (slow pulse)"},
	{"id": "chaos",          "color": Color(0.95, 0.2, 0.2),   "speed": 13.0, "expected_foe_mode": 2, "label": "SWARM (chaos)"},
	{"id": "cellular",       "color": Color(0.4, 0.9, 0.3),    "speed": 8.0,  "expected_foe_mode": 3, "label": "DRAINFRIEND (entropy)"},
	{"id": "fractal",        "color": Color(0.6, 0.4, 0.95),   "speed": 11.0, "expected_foe_mode": 6, "label": "FRACTAL (split conversion)"},
	{"id": "branching",      "color": Color(0.5, 0.95, 0.5),   "speed": 9.0,  "expected_foe_mode": 7, "label": "BRANCH (hue+badge)"},
	{"id": "swarm",          "color": Color(0.95, 0.7, 0.2),   "speed": 12.0, "expected_foe_mode": 2, "label": "SWARM"},
]

var _results: Array = []  # list of per-mode result dicts
var _root: Node3D


func _initialize() -> void:
	call_deferred("_run_all")


func _run_all() -> void:
	print("=== catalyst matrix lab ===")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://catalyst_matrix"))

	for mode in MODES:
		print("\n--- mode: %s — %s ---" % [mode["id"], mode["label"]])
		var result: Dictionary = await _test_one(mode)
		_results.append(result)

	# Write results
	_write_json()
	_write_markdown()
	print("\n=== %d / %d modes transformed the foe ===" % [
		_count_passes(), MODES.size()])
	quit(0)


func _test_one(mode: Dictionary) -> Dictionary:
	var root := Node3D.new()
	root.name = "Mode_" + mode["id"]
	get_root().add_child(root)
	_root = root
	# Many catalyst mode projectiles call get_tree().current_scene.add_child()
	# to spawn decorative effects (calming fields, fractal splits, branching
	# trees). In a SceneTree script there's no current_scene by default — set
	# it so those modes can spawn without null-deref errors.
	get_root().get_tree().current_scene = root

	# Light + camera + floor (same setup as vent_foe_lab)
	_build_environment(root)

	# Stand-in player
	var player := Node3D.new()
	player.add_to_group("player")
	root.add_child(player)
	player.global_position = Vector3(0, 0, 100)

	# Foe at origin
	var foe: Node = FoeScene.instantiate()
	root.add_child(foe)
	(foe as Node3D).global_position = Vector3(0, 0, 0)
	(foe as Node).set("step_period_s", 999.0)
	(foe as Node).set("require_catalyst_armed", false)
	await get_root().get_tree().process_frame

	# Capture BEFORE
	await _capture("%s_before" % mode["id"])

	# Spawn projectile of this mode, dropped above foe
	var ball: Node = ProjectileScript.new()
	var script_path := "res://commons/hazards/becoming_catalyst/modes/%s_projectile.gd" % mode["id"]
	if ResourceLoader.exists(script_path):
		ball.set_script(load(script_path))
	ball.set("speed", mode["speed"])
	# Per-mode lifetime override (primitives shrinks over its lifetime, so
	# bouncy slow modes need a longer fuse than the 6s default).
	var mode_lifetime: float = float(mode.get("lifetime", 6.0))
	ball.set("lifetime", mode_lifetime)
	ball.set("color_primary", mode["color"])
	ball.set("direction", Vector3.DOWN)
	root.add_child(ball)
	(ball as Node3D).global_position = Vector3(0, 1.5, 0)
	(ball as RigidBody3D).linear_velocity = Vector3(0, -6.0, 0)

	# Wait long enough for impact + animation to settle. Slow / bouncy modes
	# can override the default 250 frames via the mode dict's wait_frames key.
	var wait_frames: int = int(mode.get("wait_frames", 250))
	for _i in wait_frames:
		await get_root().get_tree().process_frame

	# Capture AFTER
	await _capture("%s_after" % mode["id"])

	# Read state
	var state: int = int((foe as Node).get("state"))
	var foe_mode: int = int((foe as Node).get("foe_mode"))
	var albedo: Color = Color()
	if (foe as Node).has_method("get") and "_mat" in foe:
		var mat = foe.get("_mat")
		if mat:
			albedo = mat.albedo_color
	var ok: bool = state == 1 and foe_mode == int(mode["expected_foe_mode"])

	print("  state=%d (1=FRIEND), foe_mode=%d (expected %d), albedo=%s, %s" % [
		state, foe_mode, int(mode["expected_foe_mode"]), albedo,
		"PASS" if ok else "FAIL"])

	root.queue_free()
	await get_root().get_tree().process_frame
	await get_root().get_tree().process_frame

	return {
		"mode": mode["id"],
		"label": mode["label"],
		"projectile_color": [mode["color"].r, mode["color"].g, mode["color"].b],
		"speed": mode["speed"],
		"hit": state == 1,
		"state_after": state,
		"foe_mode_after": foe_mode,
		"expected_foe_mode": int(mode["expected_foe_mode"]),
		"albedo_after": [albedo.r, albedo.g, albedo.b],
		"pass": ok,
	}


func _build_environment(root: Node3D) -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.light_energy = 1.5
	root.add_child(sun)
	var ambient := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.13, 0.15, 0.22)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_BG
	env.ambient_light_color = Color(0.45, 0.45, 0.55)
	env.ambient_light_energy = 0.7
	ambient.environment = env
	root.add_child(ambient)
	var cam := Camera3D.new()
	root.add_child(cam)
	cam.global_position = Vector3(1.5, 1.2, 1.5)
	cam.look_at(Vector3(0, 0.2, 0), Vector3.UP)
	cam.current = true
	# Floor
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	var floor_col := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(4, 0.2, 4)
	floor_col.shape = floor_shape
	floor_body.add_child(floor_col)
	root.add_child(floor_body)
	floor_body.position = Vector3(0, -0.1, 0)
	var floor_mesh := MeshInstance3D.new()
	var fpm := BoxMesh.new()
	fpm.size = Vector3(4, 0.2, 4)
	floor_mesh.mesh = fpm
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.3, 0.3, 0.4)
	floor_mesh.material_override = fmat
	floor_body.add_child(floor_mesh)


func _capture(label: String) -> void:
	await get_root().get_tree().process_frame
	var vp := get_root() as Viewport
	if vp == null: return
	var img := vp.get_texture().get_image()
	if img == null: return
	var path := "user://catalyst_matrix/%s.png" % label
	img.save_png(path)


func _count_passes() -> int:
	var n: int = 0
	for r in _results:
		if r.get("pass", false): n += 1
	return n


func _write_json() -> void:
	var out := {
		"generated_at": Time.get_datetime_string_from_system(true),
		"total": _results.size(),
		"passed": _count_passes(),
		"modes": _results,
	}
	var f := FileAccess.open("user://catalyst_matrix/results.json", FileAccess.WRITE)
	if f == null: return
	f.store_string(JSON.stringify(out, "  "))
	f.close()


func _write_markdown() -> void:
	var f := FileAccess.open("user://catalyst_matrix/results.md", FileAccess.WRITE)
	if f == null: return
	f.store_string("# Catalyst Mode × Foe Matrix\n\n")
	f.store_string("Auto-generated by `commons/testing/catalyst_matrix_lab.gd`. Each row drops one catalyst mode's projectile onto a fresh foe and records the result.\n\n")
	f.store_string("| Mode | Behavior | Hit? | State after | foe_mode | Result |\n")
	f.store_string("|------|----------|------|-------------|----------|--------|\n")
	for r in _results:
		var hit: String = "✓" if r.get("hit", false) else "✗"
		var ok: String = "PASS" if r.get("pass", false) else "FAIL"
		var fm_lbl: String = ["GOO", "TRANSPORT", "SWARM", "DRAINFRIEND", "CHROMA", "WAVE", "FRACTAL", "BRANCH"][int(r.get("foe_mode_after", 0))]
		f.store_string("| `%s` | %s | %s | %d | %d (%s) | %s |\n" % [
			r["mode"], r["label"], hit, int(r.get("state_after", 0)),
			int(r.get("foe_mode_after", 0)), fm_lbl, ok])
	f.store_string("\n## Visual matrix\n\n")
	for r in _results:
		f.store_string("### `%s` — %s\n\n" % [r["mode"], r["label"]])
		var pc: Array = r.get("projectile_color", [0, 0, 0])
		f.store_string("Projectile color: rgb(%.2f, %.2f, %.2f)  ·  Speed: %.1f m/s\n\n" % [
			pc[0], pc[1], pc[2], float(r.get("speed", 0))])
		f.store_string("| Before | After |\n|--------|-------|\n")
		f.store_string("| ![%s before](%s_before.png) | ![%s after](%s_after.png) |\n\n" % [
			r["mode"], r["mode"], r["mode"], r["mode"]])
	f.close()
