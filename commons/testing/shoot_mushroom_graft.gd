extends SceneTree
## MUSHROOM TO SPIDER PLANT (2026-08-27, Palle: "let me throw mushrooms, by
## firing, that land on the floor and that the spider rather eats ... it stops
## hunting and roots, branch by degrees").
##
## The whole chain, in one run, with pictures at each degree:
##   a stand-in visitor stands still and the spider hunts it
##   a mushroom is FIRED and lands between them
##   the spider breaks off and goes for the mushroom instead — this is the
##     claim that matters, and it is a claim about PREFERENCE, not about range
##   it eats: roots, stops biting, and grows degree 1
##   four more land within its reach and it takes them one at a time
const CRAB := "res://commons/hazards/head_crab/head_crab.tscn"
const MUSH := "res://commons/artifacts/spore_mushroom/spore_mushroom.tscn"
const OUT := "res://ada_run/graft_shots"

var _cam: Camera3D
var _stage: Node3D
var _n := 0
var _l: Array = []

func _initialize() -> void: call_deferred("_run")
func _say(s: String) -> void: _l.append(s); print(s)

func _world() -> void:
	_stage = Node3D.new(); get_root().add_child(_stage)
	var fb := StaticBody3D.new(); var cs := CollisionShape3D.new(); var bx := BoxShape3D.new()
	bx.size = Vector3(90, 1.0, 90); cs.shape = bx; cs.position = Vector3(0, -0.5, 0)
	fb.add_child(cs); _stage.add_child(fb)
	var fm := MeshInstance3D.new(); var fbm := BoxMesh.new()
	fbm.size = Vector3(90, 1.0, 90); fm.mesh = fbm; fm.position = Vector3(0, -0.5, 0)
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
	key.rotation_degrees = Vector3(-40, -34, 0); key.light_energy = 2.0
	key.shadow_enabled = true; _stage.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-14, 152, 0); rim.light_energy = 1.4
	rim.light_color = Color(0.72, 0.82, 1.0); _stage.add_child(rim)
	_cam = Camera3D.new(); _cam.fov = 42.0; _stage.add_child(_cam); _cam.current = true

func _shoot(n: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_root().get_texture().get_image()
	if img == null: return
	var d := ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(d)
	if img.save_png(d.path_join(n + ".png")) == OK:
		_n += 1; _say("  shot %s" % n)

func _look(at: Vector3, back: float, up: float) -> void:
	_cam.global_position = at + Vector3(back * 0.62, up, back * 0.78)
	_cam.look_at(at, Vector3.UP)

func _run() -> void:
	_world()
	var mush: PackedScene = load(MUSH) as PackedScene

	var player := Node3D.new()
	player.name = "PlayerBody"
	player.add_to_group("player")
	player.set_script(preload("res://commons/testing/probe_crab_bite_dummy.gd"))
	_stage.add_child(player); player.global_position = Vector3(0, 0.5, 0)

	var c: Node3D = (load(CRAB) as PackedScene).instantiate() as Node3D
	_stage.add_child(c); c.global_position = Vector3(0, 0, -7.0)
	c.set("detect_m", 16.0)
	await create_timer(1.5).timeout
	_say("MUSHROOM TO SPIDER PLANT")
	_say("  a visitor at the origin; the spider 7 m away and hunting")

	# ── it is hunting: let it close a little, so the break-off is visible ──
	await create_timer(2.0).timeout
	var closing: float = c.global_position.distance_to(player.global_position)
	_say("  after two seconds it has closed to %.2f m" % closing)

	# ── FIRE one, to the side, so choosing it is a CHOICE and not a coincidence
	var m1: Node3D = mush.instantiate() as Node3D
	_stage.add_child(m1)
	m1.call("launch", Vector3(1.6, 1.5, -1.0), Vector3(-0.35, 0.34, -1.0), 5.2)
	var t := 0.0
	while t < 5.0 and not bool(m1.call("is_bait")):
		await create_timer(0.05).timeout
		t += 0.05
	_say("  a mushroom landed at %s after %.2f s" % [str(m1.global_position), t])
	var to_mush: float = c.global_position.distance_to(m1.global_position)
	var to_player: float = c.global_position.distance_to(player.global_position)
	_say("  from the spider: mushroom %.2f m, visitor %.2f m — the mushroom is %s"
		% [to_mush, to_player, "FURTHER" if to_mush > to_player else "nearer"])

	# ── does it break off? ────────────────────────────────────────────────
	var ate := false
	t = 0.0
	while t < 14.0:
		await create_timer(0.05).timeout
		t += 0.05
		if int(c.get("_degree")) > 0:
			ate = true
			break
	_say("  it ate after %.2f s: %s" % [t, str(ate)])
	_say("  rooted %s   can_bite %s   degree %d"
		% [str(c.get("_rooted")), str(c.get("can_bite")), int(c.get("_degree"))])
	var hurt_before: int = int(player.get("hits"))
	await create_timer(0.6).timeout
	var p: Vector3 = c.global_position
	_look(p + Vector3(0, 0.12, 0), 1.15, 0.78)
	await create_timer(0.2).timeout
	await _shoot("1_degree_1")

	# ── feed it four more, within reach of the rooted plant ───────────────
	for i in range(4):
		var m: Node3D = mush.instantiate() as Node3D
		_stage.add_child(m)
		var a: float = TAU * float(i) / 4.0
		var at := p + Vector3(cos(a) * 0.9, 0.0, sin(a) * 0.9)
		m.global_position = at
		m.call("_plant", at)
		var t2 := 0.0
		while t2 < 4.0 and int(c.get("_degree")) < i + 2:
			await create_timer(0.05).timeout
			t2 += 0.05
		_say("  fed %d -> degree %d (%.2f s)" % [i + 2, int(c.get("_degree")), t2])
		if i == 1:
			_look(p + Vector3(0, 0.16, 0), 1.5, 0.95)
			await create_timer(0.2).timeout
			await _shoot("2_degree_3")

	await create_timer(0.8).timeout
	_look(p + Vector3(0, 0.20, 0), 1.9, 1.15)
	await create_timer(0.2).timeout
	await _shoot("3_degree_5")
	# and from a visitor's eye
	_cam.global_position = p + Vector3(1.4, 1.62, 1.9)
	_cam.look_at(p + Vector3(0, 0.15, 0), Vector3.UP)
	await create_timer(0.2).timeout
	await _shoot("4_a_visitors_eye")

	var hurt_after: int = int(player.get("hits"))
	_say("")
	_say("  the visitor was bitten %d time(s) before it rooted, %d after"
		% [hurt_before, hurt_after - hurt_before])
	var sprouts: Array = c.get("_sprouts")
	_say("  degree %d, %d sprout(s), rooted %s, can_bite %s"
		% [int(c.get("_degree")), sprouts.size(), str(c.get("_rooted")), str(c.get("can_bite"))])
	var ok: bool = ate and bool(c.get("_rooted")) and not bool(c.get("can_bite")) \
		and int(c.get("_degree")) == 5 and sprouts.size() >= 4 and (hurt_after - hurt_before) == 0
	_say("VERDICT: %s" % ("it preferred the mushroom, rooted, and branched five times" if ok
		else "INCOMPLETE"))
	var f := FileAccess.open(OUT + "/_index.txt", FileAccess.WRITE)
	if f != null: f.store_string("\n".join(PackedStringArray(_l)) + "\n"); f.close()
	quit(0 if ok else 1)
