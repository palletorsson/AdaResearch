extends SceneTree
## WHAT THE ROW WOULD LOOK LIKE (2026-08-27).
##
## The probe measured footprints from 0.34 m to 3.50 m across the seven, which
## means a row of them as-is compares SIZES and not LEGS. Before writing a map
## that places them, look at them: individually, framed to each one's own
## extent, and then all seven together at the spacing a room would give them.
const DIR := "res://commons/hazards/octapod_crawler/"
const NAMES := ["one_leg", "two_leg_critter", "three_leg_critter", "four_leg_critter",
	"five_leg_critter", "six_leg_critter", "octapod_ik"]
const OUT := "res://ada_run/leg_ladder_shots"

var _cam: Camera3D
var _stage: Node3D
var _n := 0

func _initialize() -> void: call_deferred("_run")

func _world() -> void:
	_stage = Node3D.new(); get_root().add_child(_stage)
	var fb := StaticBody3D.new(); var cs := CollisionShape3D.new(); var bx := BoxShape3D.new()
	bx.size = Vector3(400, 1.0, 60); cs.shape = bx; cs.position = Vector3(60, 0.0, 0)
	fb.add_child(cs); _stage.add_child(fb)
	var fm := MeshInstance3D.new(); var fbm := BoxMesh.new()
	fbm.size = Vector3(400, 1.0, 60); fm.mesh = fbm; fm.position = Vector3(60, 0.0, 0)
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.16, 0.16, 0.19); fmat.roughness = 0.9
	fm.material_override = fmat; _stage.add_child(fm)
	var env := WorldEnvironment.new(); var e := Environment.new()
	var sky := Sky.new(); var pm := ProceduralSkyMaterial.new()
	pm.sky_top_color = Color(0.17, 0.20, 0.27); pm.sky_horizon_color = Color(0.44, 0.47, 0.54)
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
		_n += 1; print("  shot %s" % n)

func _box(n: Node3D) -> Dictionary:
	var boxes: Array = []
	var stack: Array = [n]
	while not stack.is_empty():
		var q: Node = stack.pop_back()
		if q is VisualInstance3D:
			var vi: VisualInstance3D = q
			var wb: AABB = vi.global_transform * vi.get_aabb()
			if wb.size.length() > 0.0001: boxes.append(wb)
		for ch in q.get_children(): stack.append(ch)
	var anchor: Vector3 = n.global_position
	var box := AABB(); var has := false
	for b in boxes:
		var wb2: AABB = b
		if wb2.size.length() > 12.0: continue
		if wb2.get_center().distance_to(anchor) > 8.0: continue
		box = wb2 if not has else box.merge(wb2)
		has = true
	return {"has": has, "box": box}

func _run() -> void:
	_world()
	var x := 0.0
	var live: Array = []
	for nm in NAMES:
		var path: String = DIR + nm + ".tscn"
		if not ResourceLoader.exists(path): continue
		var inst: Node = (load(path) as PackedScene).instantiate()
		if inst == null: continue
		_stage.add_child(inst)
		if inst is Node3D: (inst as Node3D).global_position = Vector3(x, 0.5, 0)
		live.append({"nm": nm, "n": inst, "x": x})
		x += 12.0
	await create_timer(2.4).timeout

	var i := 0
	for e in live:
		var ed: Dictionary = e
		var n: Node3D = ed["n"]
		var bd: Dictionary = _box(n)
		var box: AABB = bd["box"]
		var at: Vector3 = box.get_center() if bd["has"] else n.global_position
		var diag: float = box.size.length() if bd["has"] else 1.0
		var d2: float = clampf(diag * 1.15, 0.7, 7.0)
		print("  %-20s diag %.2f m -> camera %.2f m" % [String(ed["nm"]), diag, d2])
		_cam.global_position = at + Vector3(d2 * 0.50, d2 * 0.36, d2 * 0.78)
		_cam.look_at(at, Vector3.UP)
		await create_timer(0.2).timeout
		i += 1
		await _shoot("%d_%s" % [i, String(ed["nm"])])

	# and the row as a room would show it, from one standpoint
	_cam.global_position = Vector3(36.0, 14.0, 30.0)
	_cam.look_at(Vector3(36.0, 1.0, 0.0), Vector3.UP)
	await create_timer(0.25).timeout
	await _shoot("0_the_row_as_is")
	print("LEG LADDER SHOTS: %d" % _n)
	var f := FileAccess.open(OUT + "/_index.txt", FileAccess.WRITE)
	if f != null: f.store_string("%d\n" % _n); f.close()
	quit(0 if _n >= 5 else 1)
