extends SceneTree
## THE MUSHROOM, LOOKED AT (2026-08-27).
##
## Three questions a compile cannot answer: does it read as a mushroom from a
## visitor's distance, does the fired arc land where it is aimed, and does it
## sit on the floor rather than in it.
const M := "res://commons/artifacts/spore_mushroom/spore_mushroom.tscn"
const OUT := "res://ada_run/mushroom_shots"

var _cam: Camera3D
var _stage: Node3D
var _n := 0
var _l: Array = []

func _initialize() -> void: call_deferred("_run")
func _say(s: String) -> void: _l.append(s); print(s)

func _world() -> void:
	_stage = Node3D.new(); get_root().add_child(_stage)
	var fb := StaticBody3D.new(); var cs := CollisionShape3D.new(); var bx := BoxShape3D.new()
	bx.size = Vector3(80, 1.0, 80); cs.shape = bx; cs.position = Vector3(0, -0.5, 0)
	fb.add_child(cs); _stage.add_child(fb)
	var fm := MeshInstance3D.new(); var fbm := BoxMesh.new()
	fbm.size = Vector3(80, 1.0, 80); fm.mesh = fbm; fm.position = Vector3(0, -0.5, 0)
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.20, 0.19, 0.22); fmat.roughness = 0.94
	fm.material_override = fmat; _stage.add_child(fm)
	var env := WorldEnvironment.new(); var e := Environment.new()
	var sky := Sky.new(); var pm := ProceduralSkyMaterial.new()
	pm.sky_top_color = Color(0.17, 0.20, 0.27); pm.sky_horizon_color = Color(0.46, 0.48, 0.55)
	pm.ground_bottom_color = Color(0.06, 0.06, 0.08); pm.ground_horizon_color = Color(0.22, 0.22, 0.26)
	sky.sky_material = pm
	e.background_mode = Environment.BG_SKY; e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY; e.ambient_light_energy = 1.05
	e.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC; e.tonemap_exposure = 1.05
	env.environment = e; _stage.add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-42, -36, 0); key.light_energy = 2.1
	key.shadow_enabled = true; _stage.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-12, 150, 0); rim.light_energy = 1.2
	rim.light_color = Color(0.74, 0.84, 1.0); _stage.add_child(rim)
	_cam = Camera3D.new(); _cam.fov = 40.0; _stage.add_child(_cam); _cam.current = true

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
	var ps: PackedScene = load(M) as PackedScene

	# one standing still, for the portrait
	var a: Node3D = ps.instantiate() as Node3D
	_stage.add_child(a); a.global_position = Vector3.ZERO
	a.call("_plant", Vector3.ZERO)
	await create_timer(0.9).timeout
	_cam.global_position = Vector3(0.30, 0.24, 0.42)
	_cam.look_at(Vector3(0, 0.13, 0), Vector3.UP)
	await create_timer(0.2).timeout
	await _shoot("1_portrait")

	# five of them scattered, at a visitor's distance and eye height
	var placed: Array = []
	for i in range(5):
		var m: Node3D = ps.instantiate() as Node3D
		_stage.add_child(m)
		var ang: float = TAU * float(i) / 5.0
		var at := Vector3(cos(ang) * 0.9 + 2.4, 0.0, sin(ang) * 0.7)
		m.global_position = at
		m.call("_plant", at)
		placed.append(m)
	await create_timer(0.7).timeout
	_cam.global_position = Vector3(2.4, 1.62, 3.1)
	_cam.look_at(Vector3(2.4, 0.10, 0.0), Vector3.UP)
	await create_timer(0.2).timeout
	await _shoot("2_five_on_the_floor")

	# and one FIRED: does the arc land where it is aimed?
	var f: Node3D = ps.instantiate() as Node3D
	_stage.add_child(f)
	var from := Vector3(-4.0, 1.45, 3.0)
	var aim := Vector3(-1.0, 0.45, -1.0).normalized()
	f.call("launch", from, aim, 5.6)
	_cam.global_position = Vector3(-5.6, 2.0, 5.2)
	_cam.look_at(Vector3(-2.6, 0.6, 0.6), Vector3.UP)
	await create_timer(0.30).timeout
	await _shoot("3_in_flight")
	var t := 0.0
	while t < 6.0:
		await create_timer(0.05).timeout
		t += 0.05
		if bool(f.call("is_bait")): break
	_say("  it landed after %.2f s at %s" % [t, str(f.global_position)])
	_say("  in the bait group: %s" % str(f.is_in_group("spider_bait")))
	_say("  resting y %.3f (the floor is 0.000)" % f.global_position.y)
	_cam.global_position = f.global_position + Vector3(0.34, 0.26, 0.46)
	_cam.look_at(f.global_position + Vector3(0, 0.12, 0), Vector3.UP)
	await create_timer(0.25).timeout
	await _shoot("4_where_it_landed")

	var ok: bool = bool(f.call("is_bait")) and absf(f.global_position.y) < 0.05
	_say("VERDICT: %s" % ("it flies, it lands on the floor, it is bait" if ok else "the arc or the landing is wrong"))
	var fh := FileAccess.open(OUT + "/_index.txt", FileAccess.WRITE)
	if fh != null: fh.store_string("\n".join(PackedStringArray(_l)) + "\n"); fh.close()
	quit(0 if ok and _n >= 4 else 1)
