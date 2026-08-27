extends SceneTree
## THE SPIDER TAKEN APART (2026-08-26, Palle: "trace the spider form back to
## point and line via force and composition and weaving").
##
## Six frames of ONE animal in ONE pose from ONE standpoint, with parts removed.
## The pose is frozen before the first shot: six frames of six different poses
## would be six animals, and the argument only holds if it is the same one.
##
## Godot visibility is hierarchical — visible=false takes every descendant with
## it, and the joints hang off the same BoneAttachments as the shafts. layers=0
## is per-instance and does not propagate, which is why every hide here is a
## layer mask and not a visibility flag.
const CRAB := "res://commons/hazards/head_crab/head_crab.tscn"
const OUT := "res://ada_run/decomposition"

var _cam: Camera3D
var _stage: Node3D
var _crab: Node3D
var _spheres: Array = []     # the POINTS
var _cyls: Array = []        # the LINES
var _n := 0

func _initialize() -> void: call_deferred("_run")

func _world() -> void:
	_stage = Node3D.new(); get_root().add_child(_stage)
	var fb := StaticBody3D.new(); var cs := CollisionShape3D.new(); var bx := BoxShape3D.new()
	bx.size = Vector3(200, 0.4, 200); cs.shape = bx; cs.position = Vector3(0, -0.2, 0)
	fb.add_child(cs); _stage.add_child(fb)
	var fm := MeshInstance3D.new(); var fbm := BoxMesh.new()
	fbm.size = Vector3(200, 0.4, 200); fm.mesh = fbm; fm.position = Vector3(0, -0.2, 0)
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.13, 0.13, 0.16); fmat.roughness = 0.92
	fm.material_override = fmat; _stage.add_child(fm)
	var env := WorldEnvironment.new(); var e := Environment.new()
	var sky := Sky.new(); var pm := ProceduralSkyMaterial.new()
	pm.sky_top_color = Color(0.16, 0.19, 0.26); pm.sky_horizon_color = Color(0.42, 0.45, 0.52)
	pm.ground_bottom_color = Color(0.05, 0.05, 0.07); pm.ground_horizon_color = Color(0.20, 0.21, 0.25)
	pm.sun_angle_max = 12.0; sky.sky_material = pm
	e.background_mode = Environment.BG_SKY; e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY; e.ambient_light_energy = 1.0
	e.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC; e.tonemap_exposure = 1.05
	env.environment = e; _stage.add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-40, -34, 0); key.light_energy = 2.0
	key.shadow_enabled = true; _stage.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-14, 152, 0); rim.light_energy = 1.5
	rim.light_color = Color(0.72, 0.82, 1.0); _stage.add_child(rim)
	_cam = Camera3D.new(); _cam.fov = 38.0; _stage.add_child(_cam); _cam.current = true

func _shoot(n: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_root().get_texture().get_image()
	if img == null: return
	var d := ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(d)
	if img.save_png(d.path_join(n + ".png")) == OK:
		_n += 1; print("  shot %s" % n)

func _collect(n: Node) -> void:
	var cls := n.get_class()
	if cls.find("Sphere") != -1 and n is VisualInstance3D: _spheres.append(n)
	elif cls.find("Cylinder") != -1 and n is VisualInstance3D: _cyls.append(n)
	elif n is MeshInstance3D:
		var m: Mesh = (n as MeshInstance3D).mesh
		if m is SphereMesh: _spheres.append(n)
		elif m is CylinderMesh: _cyls.append(n)
	for c in n.get_children(): _collect(c)

func _show(arr: Array, on: bool) -> void:
	for v in arr:
		if is_instance_valid(v): (v as VisualInstance3D).layers = 1 if on else 0

## a fat line between two world points, drawn as a stretched box
func _bar(a: Vector3, b: Vector3, r: float, col: Color, glow: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = Vector3(r, r, a.distance_to(b))
	mi.mesh = bm
	var mt := StandardMaterial3D.new()
	mt.albedo_color = col
	mt.emission_enabled = glow > 0.0; mt.emission = col; mt.emission_energy_multiplier = glow
	mi.material_override = mt
	_stage.add_child(mi)
	mi.global_position = (a + b) * 0.5
	if a.distance_to(b) > 0.0001 and absf((b - a).normalized().dot(Vector3.UP)) < 0.999:
		mi.look_at(b, Vector3.UP)
	return mi

func _dot(p: Vector3, r: float, col: Color, glow: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new(); sm.radius = r; sm.height = r * 2.0
	mi.mesh = sm
	var mt := StandardMaterial3D.new()
	mt.albedo_color = col
	mt.emission_enabled = glow > 0.0; mt.emission = col; mt.emission_energy_multiplier = glow
	mi.material_override = mt
	_stage.add_child(mi); mi.global_position = p
	return mi

func _run() -> void:
	_world()
	var w := CharacterBody3D.new(); w.name = "Walker"; w.add_to_group("em_walker")
	_stage.add_child(w)
	_crab = (load(CRAB) as PackedScene).instantiate() as Node3D
	_stage.add_child(_crab); _crab.global_position = Vector3.ZERO
	await create_timer(1.4).timeout

	# walk it for a while, recording where the feet land, so the trace is real
	var feet: Array = _crab.get("_feet")
	var trace: Array = [[], [], [], []]
	var t := 0.0
	while t < 7.0:
		await create_timer(0.04).timeout
		t += 0.04
		var a := t * 0.5
		w.global_position = Vector3(cos(a) * 8.0, 0, sin(a * 1.6) * 8.0)
		for i in range(min(4, feet.size())):
			var f = feet[i]
			if f != null and is_instance_valid(f):
				trace[i].append((f as Node3D).global_position)

	# ── FREEZE. every later frame is this same pose ────────────────────────
	var target: Vector3 = w.global_position
	_crab.set_process(false); _crab.set_physics_process(false)
	var body: Node = _crab.get("_body")
	if body != null and is_instance_valid(body):
		(body as Node).set_process(false); (body as Node).set_physics_process(false)
	await create_timer(0.4).timeout

	_collect(_crab)
	print("collected %d point-primitives, %d line-primitives" % [_spheres.size(), _cyls.size()])
	var c0: Vector3 = _crab.global_position
	# far enough back that the raised knees stay in frame: the first sheet cut
	# the top row of joints off, and a census frame that loses four of its
	# thirty-six points is not a census
	var eye: Vector3 = c0 + Vector3(0.95, 0.66, 1.24)
	_cam.global_position = eye; _cam.look_at(c0 + Vector3(0, 0.13, 0), Vector3.UP)
	await create_timer(0.2).timeout

	await _shoot("1_the_animal")
	_show(_cyls, false)
	await create_timer(0.1).timeout
	await _shoot("2_the_points_only")          # 32 spheres
	_show(_cyls, true); _show(_spheres, false)
	await create_timer(0.1).timeout
	await _shoot("3_the_lines_only")           # 24 cylinders
	_show(_spheres, true)

	# ── THE CHAIN: the skeleton drawn as points joined by lines ────────────
	# NOT via get_bone_global_pose. The first attempt did that and drew two fat
	# blobs in the sky: the pose is in skeleton space, the skeleton sits inside a
	# rig that carries the 0.15 scale, and the product landed nowhere. Every
	# BoneAttachment3D is a real Node3D whose global_position is already the
	# joint, so the chain is read off the tree instead of reconstructed.
	var skels: Array = []
	var stack: Array = [_crab]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Skeleton3D: skels.append(n)
		for ch in n.get_children(): stack.append(ch)
	_show(_spheres, false); _show(_cyls, false)
	var drawn: Array = []
	for s in skels:
		var sk: Skeleton3D = s
		var pts: Array = []
		for ch2 in sk.get_children():
			if ch2 is BoneAttachment3D:
				pts.append((ch2 as Node3D).global_position)
		# the chain ends at the foot target, which is the point the walk moves
		var owner_leg := -1
		for fi in range(min(4, feet.size())):
			var ft = feet[fi]
			if ft == null or not is_instance_valid(ft): continue
			var fp: Vector3 = (ft as Node3D).global_position
			if pts.size() > 0 and fp.distance_to(pts[pts.size() - 1]) < 0.45:
				owner_leg = fi
		if owner_leg >= 0:
			pts.append((feet[owner_leg] as Node3D).global_position)
		for i2 in range(pts.size()):
			drawn.append(_dot(pts[i2], 0.018, Color(1.0, 0.78, 0.32), 1.6))
			if i2 > 0:
				drawn.append(_bar(pts[i2 - 1], pts[i2], 0.007, Color(0.55, 0.75, 1.0), 1.1))
	await create_timer(0.15).timeout
	await _shoot("4_the_chain")                # 4 x 6 bones, points joined by lines
	for d in drawn: (d as Node).queue_free()
	await create_timer(0.15).timeout
	_show(_spheres, true); _show(_cyls, true)

	# ── THE FORCE: the chase vector, and where each foot is planted ────────
	# THE ARROW IS DRAWN AT THE ANIMAL'S SCALE, not the world's. The first sheet
	# drew the chase vector at its true length — 1.6 m toward a visitor 8 m away
	# — and the whole bar left the frame, so the force frame showed no force.
	var arrow: Array = []
	var sc: float = float(_crab.get("crab_scale"))
	var flat: Vector3 = (target - c0); flat.y = 0.0
	var dir := Vector3.FORWARD
	if flat.length() > 0.01:
		dir = flat.normalized()
		# above the shell, not through it: at body height the bar was simply
		# behind the abdomen from every standpoint that shows the legs
		var base: Vector3 = c0 + Vector3(0, 0.235, 0)
		var tip: Vector3 = base + dir * 0.34
		arrow.append(_bar(base, tip, 0.014, Color(1.0, 0.35, 0.30), 1.8))
		arrow.append(_dot(tip, 0.032, Color(1.0, 0.35, 0.30), 2.0))
	# every planted foot, and — for one of them — the parabola the next step
	# takes: step_height_local and step_threshold_local are in RIG units, so
	# both are multiplied by crab_scale to become metres
	var step_len: float = float(_crab.get("step_threshold_local")) * sc
	var step_h: float = float(_crab.get("step_height_local")) * sc
	for i in range(min(4, feet.size())):
		var f2 = feet[i]
		if f2 == null or not is_instance_valid(f2): continue
		var fp: Vector3 = (f2 as Node3D).global_position
		arrow.append(_dot(fp + Vector3(0, 0.004, 0), 0.026, Color(0.35, 1.0, 0.62), 1.6))
		if i == 0:
			var prev := fp
			for k in range(1, 15):
				var u := float(k) / 14.0
				var pt: Vector3 = fp + dir * (step_len * u)
				pt.y = fp.y + sin(u * PI) * step_h
				arrow.append(_bar(prev, pt, 0.006, Color(1.0, 0.86, 0.32), 1.6))
				prev = pt
			arrow.append(_dot(prev, 0.020, Color(1.0, 0.86, 0.32), 1.6))
	await create_timer(0.15).timeout
	await _shoot("5_the_force")
	for a2 in arrow: (a2 as Node).queue_free()
	await create_timer(0.15).timeout

	# ── THE TRACE: seven seconds of where the feet actually stood ──────────
	var cols := [Color(1.0, 0.45, 0.35), Color(0.42, 0.92, 1.0), Color(1.0, 0.82, 0.35), Color(0.62, 0.72, 1.0)]
	var laid: Array = []
	for i in range(4):
		var last := Vector3(9999, 9999, 9999)
		for p in trace[i]:
			var pv: Vector3 = p
			if pv.distance_to(last) < 0.03: continue
			last = pv
			laid.append(_dot(Vector3(pv.x, 0.012, pv.z), 0.022, cols[i], 1.4))
	# pull back — the trace is bigger than the animal
	_cam.global_position = c0 + Vector3(2.6, 2.5, 3.2)
	_cam.look_at(c0 + Vector3(0.4, 0, 0.4), Vector3.UP)
	await create_timer(0.2).timeout
	await _shoot("6_the_trace")
	print("DECOMPOSITION: %d frames, %d trace marks" % [_n, laid.size()])
	var f3 := FileAccess.open(OUT + "/_index.txt", FileAccess.WRITE)
	if f3 != null:
		f3.store_string("points=%d lines=%d frames=%d\n" % [_spheres.size(), _cyls.size(), _n]); f3.close()
	quit(0 if _n >= 6 else 1)
