extends SceneTree
## THE MEAL, PHOTOGRAPHED (2026-08-27, Palle: "remove the branches from the
## spider add eating animation").
##
## Replaces shoot_mushroom_graft, whose subject — a spider branching into a
## plant — was removed in the same breath. What is left is worth looking at on
## its own: the animal walks onto the mushroom, settles down over it, noses in,
## and gulps it up through its underside across two seconds.
##
## Four frames from one standpoint so the motion is comparable: standing before
## it, dipped over the food, mid-gulp, and back to its walking pose after.
const CRAB := "res://commons/hazards/head_crab/head_crab.tscn"
const MUSH := "res://commons/artifacts/spore_mushroom/spore_mushroom.tscn"
const OUT := "res://ada_run/eating_shots"

var _cam: Camera3D
var _stage: Node3D
var _n := 0
var _l: Array = []

func _initialize() -> void: call_deferred("_run")
func _say(s: String) -> void: _l.append(s); print(s)

func _world() -> void:
	_stage = Node3D.new(); get_root().add_child(_stage)
	current_scene = _stage
	var fb := StaticBody3D.new(); var cs := CollisionShape3D.new(); var bx := BoxShape3D.new()
	bx.size = Vector3(80, 1.0, 80); cs.shape = bx; cs.position = Vector3(0, -0.5, 0)
	fb.add_child(cs); _stage.add_child(fb)
	var fm := MeshInstance3D.new(); var fbm := BoxMesh.new()
	fbm.size = Vector3(80, 1.0, 80); fm.mesh = fbm; fm.position = Vector3(0, -0.5, 0)
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.17, 0.17, 0.20); fmat.roughness = 0.93
	fm.material_override = fmat; _stage.add_child(fm)
	var env := WorldEnvironment.new(); var e := Environment.new()
	var sky := Sky.new(); var pm := ProceduralSkyMaterial.new()
	pm.sky_top_color = Color(0.16, 0.19, 0.26); pm.sky_horizon_color = Color(0.44, 0.47, 0.54)
	pm.ground_bottom_color = Color(0.05, 0.05, 0.07); pm.ground_horizon_color = Color(0.21, 0.21, 0.25)
	sky.sky_material = pm
	e.background_mode = Environment.BG_SKY; e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY; e.ambient_light_energy = 1.05
	e.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC; e.tonemap_exposure = 1.05
	env.environment = e; _stage.add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-38, -32, 0); key.light_energy = 2.1
	key.shadow_enabled = true; _stage.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-13, 150, 0); rim.light_energy = 1.4
	rim.light_color = Color(0.72, 0.82, 1.0); _stage.add_child(rim)
	_cam = Camera3D.new(); _cam.fov = 36.0; _stage.add_child(_cam); _cam.current = true

func _shoot(n: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_root().get_texture().get_image()
	if img == null: return
	var d := ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(d)
	if img.save_png(d.path_join(n + ".png")) == OK:
		_n += 1; _say("  shot %s" % n)

func _run() -> void:
	_world()
	var m: Node3D = (load(MUSH) as PackedScene).instantiate() as Node3D
	_stage.add_child(m); m.global_position = Vector3.ZERO
	var c: Node3D = (load(CRAB) as PackedScene).instantiate() as Node3D
	_stage.add_child(c); c.global_position = Vector3(2.4, 0, 0.2)
	c.set("detect_m", 20.0)
	await create_timer(1.5).timeout

	# ONE STANDPOINT, low and close, so the dip and the gulp are comparable
	var at := Vector3(0, 0.10, 0)
	_cam.global_position = at + Vector3(0.62, 0.30, 0.86)
	_cam.look_at(at, Vector3.UP)

	_say("THE MEAL")
	await _shoot("1_walking_up")

	# wait for the meal to start, then sample it at three points
	var t := 0.0
	while t < 14.0 and float(c.get("_meal_t")) <= 0.0:
		await create_timer(0.02).timeout
		t += 0.02
	_say("  it began feeding after %.2f s" % t)
	var ft: float = float(c.get("feed_time"))

	await create_timer(ft * 0.22).timeout
	_say("  a fifth in:  body y %.3f, pitch %.1f deg, scale %.3f"
		% [c.global_position.y, rad_to_deg(c.rotation.x), c.scale.x])
	await _shoot("2_settled_over_it")

	await create_timer(ft * 0.30).timeout
	_say("  halfway:     body y %.3f, pitch %.1f deg, scale %.3f"
		% [c.global_position.y, rad_to_deg(c.rotation.x), c.scale.x])
	await _shoot("3_mid_gulp")

	# and after, back to the walking pose
	while float(c.get("_meal_t")) > 0.0:
		await create_timer(0.02).timeout
	await create_timer(0.35).timeout
	_say("  after:       body y %.3f, pitch %.1f deg, scale %.3f"
		% [c.global_position.y, rad_to_deg(c.rotation.x), c.scale.x])
	await _shoot("4_back_to_walking")

	var fails: Array = []
	if absf(c.rotation.x) > 0.02:
		fails.append("it did not come back level — pitch %.2f deg" % rad_to_deg(c.rotation.x))
	if absf(c.scale.x - float(c.get("crab_scale"))) > 0.002:
		fails.append("it did not come back to size — scale %.4f" % c.scale.x)
	if int(c.get("_degree")) < 1:
		fails.append("it never actually ate")
	_say("")
	for f in fails: _say("FAIL %s" % f)
	_say("VERDICT: %s" % ("it settles onto the food, noses in, gulps, and stands back up"
		if fails.is_empty() else "%d fault(s)" % fails.size()))
	var fh := FileAccess.open(OUT + "/_index.txt", FileAccess.WRITE)
	if fh != null: fh.store_string("\n".join(PackedStringArray(_l)) + "\n"); fh.close()
	quit(0 if fails.is_empty() and _n >= 4 else 1)
