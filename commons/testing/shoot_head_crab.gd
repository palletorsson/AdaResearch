extends SceneTree
## THE HEAD CRAB, WALKING (2026-08-26, Palle: "use that to make the small head
## crab and show me"). Builds the crab on the four-leg critter's plant-and-step
## rig, gives it a visitor to hunt, and photographs the WALK — a gait only
## proves itself in motion, so the frames are timed to the stride and the step
## count is measured, not asserted.
const OUT := "res://ada_run/crab_shots"
const CRAB := "res://commons/hazards/head_crab/head_crab.tscn"

var _cam: Camera3D = null
var _stage: Node3D = null
var _shots: Array = []
var _steps: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _world() -> void:
	_stage = Node3D.new(); get_root().add_child(_stage)
	var fb := StaticBody3D.new()
	var cs := CollisionShape3D.new(); var bx := BoxShape3D.new()
	bx.size = Vector3(40, 0.4, 40); cs.shape = bx; cs.position = Vector3(0, -0.2, 0)
	fb.add_child(cs); _stage.add_child(fb)
	var fm := MeshInstance3D.new(); var fbm := BoxMesh.new()
	fbm.size = Vector3(40, 0.4, 40); fm.mesh = fbm; fm.position = Vector3(0, -0.2, 0)
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.16, 0.16, 0.19); fmat.roughness = 0.9
	fm.material_override = fmat; _stage.add_child(fm)
	var env := WorldEnvironment.new(); var e := Environment.new()
	e.background_mode = Environment.BG_COLOR; e.background_color = Color(0.06, 0.06, 0.08)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.45, 0.47, 0.55); e.ambient_light_energy = 0.55
	env.environment = e; _stage.add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-40, -35, 0); key.light_energy = 1.6
	key.shadow_enabled = true; _stage.add_child(key)
	_cam = Camera3D.new(); _cam.fov = 44.0; _stage.add_child(_cam); _cam.current = true

func _look(at: Vector3, from: Vector3) -> void:
	_cam.global_position = from
	_cam.look_at(at, Vector3.UP)

func _shoot(n: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_root().get_texture().get_image()
	if img == null: return
	var d := ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(d)
	if img.save_png(d.path_join(n + ".png")) == OK:
		_shots.append(n); print("  shot " + n)

func _run() -> void:
	_world()
	await create_timer(0.5).timeout
	var crab: Node3D = (load(CRAB) as PackedScene).instantiate() as Node3D
	_stage.add_child(crab)
	crab.global_position = Vector3(0, 0, 0)
	# the visitor it walks toward
	var walker := CharacterBody3D.new()
	walker.name = "Walker"; walker.add_to_group("em_walker")
	_stage.add_child(walker)
	walker.global_position = Vector3(0, 0, -6)
	await create_timer(1.0).timeout

	# a portrait first, close, so the body and the four legs read
	_look(Vector3(0, 0.20, 0), Vector3(0.85, 0.55, 1.05))
	await create_timer(0.3).timeout
	await _shoot("a_portrait")

	# then the WALK: track it, shooting through one stride
	var prev_planted: Array = (crab.get("_planted") as Array).duplicate()
	for i in range(6):
		await create_timer(0.42).timeout
		var p: Vector3 = crab.global_position
		_look(p + Vector3(0, 0.18, 0), p + Vector3(1.0, 0.62, 1.25))
		await _shoot("b_walk_%d" % i)
		var now: Array = crab.get("_planted") as Array
		for k in range(mini(now.size(), prev_planted.size())):
			if (now[k] as Vector3).distance_to(prev_planted[k]) > 0.02:
				_steps += 1
		prev_planted = now.duplicate()

	# from the side, low — the stride and the planted feet
	var p2: Vector3 = crab.global_position
	_look(p2 + Vector3(0, 0.14, 0), p2 + Vector3(1.35, 0.30, 0.15))
	await create_timer(0.2).timeout
	await _shoot("c_side_low")
	# and from above: the diagonal pairing of a four-legged gait
	_look(p2, p2 + Vector3(0.05, 1.5, 0.05))
	await create_timer(0.35).timeout
	await _shoot("d_from_above")

	var travelled: float = crab.global_position.distance_to(Vector3.ZERO)
	var f := FileAccess.open(OUT + "/_index.txt", FileAccess.WRITE)
	if f != null:
		f.store_string("shots %d\nsteps %d\ntravelled %.2f m\n" % [_shots.size(), _steps, travelled])
		f.close()
	print("CRAB: %d shots, %d foot-plants, walked %.2f m" % [_shots.size(), _steps, travelled])
	quit(0)
