extends SceneTree
## THE COSTUME, PHOTOGRAPHED (2026-08-27).
##
## The probe proves the limbs are solved and the garment only grows. It says
## nothing about whether the thing is worth wearing, and this repository has
## published enough green verdicts about pictures nobody opened.
##
## Five frames, all from one standpoint so they are comparable: the bare rig,
## then the body after five sequences, then after all twenty-two — and two
## closer looks at what is actually hanging on it.
const COSTUME := "res://commons/player/queer_costume.gd"
const TROPHIES := "res://commons/player/costume_trophies.gd"
const OUT := "res://ada_run/costume_shots"

var _cam: Camera3D
var _stage: Node3D
var _n := 0
var _l: Array = []

func _initialize() -> void: call_deferred("_run")
func _say(s: String) -> void: _l.append(s); print(s)


func _world() -> void:
	_stage = Node3D.new()
	get_root().add_child(_stage)
	current_scene = _stage
	var fm := MeshInstance3D.new()
	var fbm := BoxMesh.new()
	fbm.size = Vector3(40, 1.0, 40)
	fm.mesh = fbm
	fm.position = Vector3(0, -0.5, 0)
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.13, 0.13, 0.16)
	fmat.roughness = 0.95
	fm.material_override = fmat
	_stage.add_child(fm)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	var sky := Sky.new()
	var pm := ProceduralSkyMaterial.new()
	pm.sky_top_color = Color(0.09, 0.10, 0.16)
	pm.sky_horizon_color = Color(0.28, 0.28, 0.36)
	pm.ground_bottom_color = Color(0.04, 0.04, 0.06)
	pm.ground_horizon_color = Color(0.16, 0.16, 0.20)
	sky.sky_material = pm
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.85
	e.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_exposure = 1.0
	# the trophies are emissive and small — glow is what makes them read at all
	e.glow_enabled = true
	e.glow_intensity = 0.55
	e.glow_bloom = 0.12
	env.environment = e
	_stage.add_child(env)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-34, -38, 0)
	key.light_energy = 1.5
	key.shadow_enabled = true
	_stage.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-10, 145, 0)
	rim.light_energy = 1.1
	rim.light_color = Color(0.70, 0.80, 1.0)
	_stage.add_child(rim)

	_cam = Camera3D.new()
	_cam.fov = 40.0
	_stage.add_child(_cam)
	_cam.current = true


func _rig() -> Node3D:
	var origin := XROrigin3D.new()
	origin.name = "XROrigin3D"
	_stage.add_child(origin)
	var cam := XRCamera3D.new()
	cam.name = "XRCamera3D"
	cam.position = Vector3(0, 1.62, 0)
	cam.rotation_degrees = Vector3(0, 20, 0)
	origin.add_child(cam)
	# hands out and a little apart, so the torso has something to face
	var lh := Node3D.new()
	lh.name = "LeftHand"
	lh.position = Vector3(-0.30, 1.16, -0.30)
	origin.add_child(lh)
	var rh := Node3D.new()
	rh.name = "RightHand"
	rh.position = Vector3(0.28, 1.30, -0.34)
	origin.add_child(rh)
	return origin


func _look(at: Vector3, from: Vector3, fov: float) -> void:
	_cam.fov = fov
	_cam.global_position = from
	_cam.look_at(at, Vector3.UP)


func _shoot(n: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_root().get_texture().get_image()
	if img == null:
		return
	var d := ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(d)
	if img.save_png(d.path_join(n + ".png")) == OK:
		_n += 1
		_say("  shot %s" % n)


func _run() -> void:
	_world()
	var origin: Node3D = _rig()
	var c: Node3D = (load(COSTUME) as GDScript).new() as Node3D
	c.name = "QueerCostume"
	origin.add_child(c)
	c.call("attach_to", origin)
	await create_timer(1.2).timeout

	var mid := Vector3(0, 1.15, 0)
	_say("THE COSTUME")

	_look(mid, mid + Vector3(1.55, 0.30, 1.75), 40.0)
	await _shoot("1_bare_rig")

	var T: GDScript = load(TROPHIES) as GDScript
	var spine: Array = ["primitives", "transformation", "color", "change", "forces"]
	for seq in spine:
		c.call("grow")
		var n1: Node3D = T.make(seq)
		if n1 != null:
			c.call("pin", n1, T.slot_for(seq))
	await create_timer(0.6).timeout
	_say("  after five: stage %d, tiers %d, trophies %d"
		% [int(c.get("stage")), int(c.call("garment_tiers")), int(c.call("pinned_count"))])
	await _shoot("2_after_five_sequences")

	var rest: Array = []
	for seq in T.known():
		if not (seq in spine):
			rest.append(seq)
	for seq in rest:
		c.call("grow")
		var n2: Node3D = T.make(seq)
		if n2 != null:
			c.call("pin", n2, T.slot_for(seq))
	await create_timer(0.8).timeout
	_say("  the whole walk: stage %d, tiers %d, trophies %d"
		% [int(c.get("stage")), int(c.call("garment_tiers")), int(c.call("pinned_count"))])
	await _shoot("3_the_whole_walk")

	# and closer, because the trophies are 4-9 cm and the point of them is that
	# each one argues its own sequence
	_look(Vector3(0, 1.48, -0.06), Vector3(0.52, 1.60, 0.56), 26.0)
	await _shoot("4_throat_and_ears")
	_look(Vector3(-0.14, 1.02, 0.0), Vector3(-0.62, 1.14, 0.62), 26.0)
	await _shoot("5_shoulder_and_hip")

	# one frame mid-stride, so the limbs are caught trailing rather than at rest
	var cam3: Node3D = origin.get_node("XRCamera3D")
	var t := 0.0
	while t < 1.1:
		await create_timer(0.033).timeout
		t += 0.033
		cam3.position = Vector3(0, 1.62, -t * 0.9)
	_look(Vector3(0, 1.05, -1.0), Vector3(1.75, 0.55, 1.35), 42.0)
	await _shoot("6_mid_stride")

	_say("")
	_say("VERDICT: %d frame(s) — look at them" % _n)
	var fh := FileAccess.open(OUT + "/_index.txt", FileAccess.WRITE)
	if fh != null:
		fh.store_string("\n".join(PackedStringArray(_l)) + "\n")
		fh.close()
	quit(0 if _n >= 6 else 1)
