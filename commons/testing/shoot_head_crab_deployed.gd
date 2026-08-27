extends SceneTree
## THE DEPLOYED SPIDER (2026-08-26, Palle: "all black spider 3 look good! use
## that as a start and deploy it in to the game").
##
## Photographs what SHIPS — the artifact at its own default values, with no
## overrides from the shooter — plus the small one the arena token asks for, so
## the sheet is evidence about the game and not about a bench rig. One Godot
## run: two instances collide on the user:// lock.
##
## It also round-trips the ARENA'S OWN TOKEN through the real parser first. The
## first placement wrote accent:#7fd8cf, and '#' is the token's config
## separator — the colour was split off and dropped in silence. A sheet showing
## a beautiful animal would have said nothing about that.
const OUT := "res://ada_run/deployed_shots"
const CRAB := "res://commons/hazards/head_crab/head_crab.tscn"
const TOKEN := "head_crab:180:0#scale:0.11#accent:7fd8cf"

var _cam: Camera3D = null
var _stage: Node3D = null
var _n := 0

func _initialize() -> void: call_deferred("_run")

func _world() -> void:
	_stage = Node3D.new(); get_root().add_child(_stage)
	var fb := StaticBody3D.new()
	var cs := CollisionShape3D.new(); var bx := BoxShape3D.new()
	bx.size = Vector3(80, 0.4, 40); cs.shape = bx; cs.position = Vector3(4, -0.2, 0)
	fb.add_child(cs); _stage.add_child(fb)
	var fm := MeshInstance3D.new(); var fbm := BoxMesh.new()
	fbm.size = Vector3(80, 0.4, 40); fm.mesh = fbm; fm.position = Vector3(4, -0.2, 0)
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.15, 0.15, 0.18); fmat.roughness = 0.9
	fm.material_override = fmat; _stage.add_child(fm)
	# a metal is almost entirely its reflection: a flat background renders the
	# polished graphite as matte black, so the sky is what makes it read
	var env := WorldEnvironment.new(); var e := Environment.new()
	var sky := Sky.new(); var pm := ProceduralSkyMaterial.new()
	pm.sky_top_color = Color(0.16, 0.19, 0.26)
	pm.sky_horizon_color = Color(0.42, 0.45, 0.52)
	pm.ground_bottom_color = Color(0.05, 0.05, 0.07)
	pm.ground_horizon_color = Color(0.20, 0.21, 0.25)
	pm.sun_angle_max = 12.0
	sky.sky_material = pm
	e.background_mode = Environment.BG_SKY; e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 1.0
	e.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_exposure = 1.05
	env.environment = e; _stage.add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-38, -32, 0); key.light_energy = 2.0
	key.shadow_enabled = true; _stage.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-14, 152, 0); rim.light_energy = 1.5
	rim.light_color = Color(0.72, 0.82, 1.0); _stage.add_child(rim)
	_cam = Camera3D.new(); _cam.fov = 40.0; _stage.add_child(_cam); _cam.current = true

func _look(at: Vector3, from: Vector3) -> void:
	_cam.global_position = from; _cam.look_at(at, Vector3.UP)

func _shoot(n: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_root().get_texture().get_image()
	if img == null: return
	var d := ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(d)
	if img.save_png(d.path_join(n + ".png")) == OK: _n += 1

func _run() -> void:
	# ── the token, through the REAL parser ─────────────────────────────────
	var gic: Object = load("res://commons/grid/GridInteractablesComponent.gd").new()
	var parsed: Dictionary = gic.call("_parse_config_token", TOKEN)
	var cfg: Dictionary = parsed.get("config_data", {})
	print("TOKEN  %s" % TOKEN)
	print("  name      %s" % str(parsed.get("lookup_name", "")))
	print("  overrides %s" % str(parsed.get("overrides", {})))
	print("  config    %s" % str(cfg))
	var token_ok: bool = cfg.has("accent") and str(cfg["accent"]) == "7fd8cf" and cfg.has("scale")
	print("  ROUND TRIP %s" % ("ok — the accent survives the split" if token_ok else "FAIL"))
	if gic is Node: (gic as Node).free()

	_world()
	# 1. the artifact AS IT SHIPS — nothing set from here
	var a: Node3D = (load(CRAB) as PackedScene).instantiate() as Node3D
	_stage.add_child(a); a.global_position = Vector3(0, 0, 0)
	# 2. the arena's small one, configured by the token the map actually holds
	var b: Node3D = (load(CRAB) as PackedScene).instantiate() as Node3D
	b.call("apply_grid_config", cfg)
	_stage.add_child(b); b.global_position = Vector3(7, 0, 0)
	# each gets a visitor to hunt
	for i in range(2):
		var w := CharacterBody3D.new(); w.name = "Walker"; w.add_to_group("em_walker")
		_stage.add_child(w); w.global_position = Vector3(float(i) * 7.0, 0, -6)
	await create_timer(1.5).timeout

	_look(a.global_position + Vector3(0, 0.20, 0), a.global_position + Vector3(0.62, 0.42, 0.80))
	await create_timer(0.15).timeout
	await _shoot("1_ships_portrait")
	_look(a.global_position + Vector3(0, 0.17, 0), a.global_position + Vector3(0.95, 0.17, 0.06))
	await create_timer(0.12).timeout
	await _shoot("2_ships_side")
	_look(b.global_position + Vector3(0, 0.16, 0), b.global_position + Vector3(0.50, 0.34, 0.64))
	await create_timer(0.12).timeout
	await _shoot("3_arena_small_teal")
	await create_timer(2.4).timeout
	_look(a.global_position + Vector3(0, 0.16, 0), a.global_position + Vector3(1.05, 0.55, 1.25))
	await create_timer(0.12).timeout
	await _shoot("4_ships_walking")
	_look(a.global_position + Vector3(0, 0.10, 0), a.global_position + Vector3(0.42, 0.72, 0.42))
	await create_timer(0.12).timeout
	await _shoot("5_ships_from_above")

	var f := FileAccess.open(OUT + "/_index.txt", FileAccess.WRITE)
	if f != null: f.store_string("%d shots, token %s\n" % [_n, "ok" if token_ok else "FAIL"]); f.close()
	print("DEPLOYED SHEET: %d shot(s)" % _n)
	quit(0 if token_ok and _n >= 5 else 1)
