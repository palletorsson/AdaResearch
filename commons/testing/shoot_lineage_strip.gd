extends SceneTree
## THE ANCESTORS, PHOTOGRAPHED (2026-08-26).
##
## The census put the spider next to the corpus's own point and line as numbers.
## This puts them next to each other as pictures, in the order the spine walks
## them: a point, a point with a vector, a line, a trace, a triangle, the egg,
## and the animal. Same light, same lens, each framed to its own size — the
## subjects differ by two orders of magnitude and a single standpoint would
## show a spider and six specks.
const IN := "res://ada_run/_lineage_subjects.json"
const OUT := "res://ada_run/lineage_strip"

## token, caption, camera distance in metres, height
const ORDER := [
	["interactive_point_origin_force", 2.6, 1.4],
	["line", 2.4, 1.2],
	["draw_dot", 1.5, 0.9],
	["triangle", 2.6, 1.4],
	["dark_sphere", 2.2, 1.1],
	["head_crab", 1.5, 0.72],
]

var _cam: Camera3D
var _stage: Node3D
var _n := 0

func _initialize() -> void: call_deferred("_run")

func _world() -> void:
	_stage = Node3D.new(); get_root().add_child(_stage)
	var fb := StaticBody3D.new(); var cs := CollisionShape3D.new(); var bx := BoxShape3D.new()
	bx.size = Vector3(400, 0.4, 200); cs.shape = bx; cs.position = Vector3(0, -0.2, 0)
	fb.add_child(cs); _stage.add_child(fb)
	var fm := MeshInstance3D.new(); var fbm := BoxMesh.new()
	fbm.size = Vector3(400, 0.4, 200); fm.mesh = fbm; fm.position = Vector3(0, -0.2, 0)
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.14, 0.14, 0.17); fmat.roughness = 0.92
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
	_cam = Camera3D.new(); _cam.fov = 40.0; _stage.add_child(_cam); _cam.current = true

func _shoot(n: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_root().get_texture().get_image()
	if img == null: return
	var d := ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(d)
	if img.save_png(d.path_join(n + ".png")) == OK:
		_n += 1; print("  shot %s" % n)

func _run() -> void:
	_world()
	var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(IN))
	var subs: Array = (doc as Dictionary).get("subjects", []) if doc is Dictionary else []
	var by := {}
	for s in subs: by[String((s as Dictionary).get("token", ""))] = String((s as Dictionary).get("scene", ""))

	# the spider wants something to walk toward, and it is the only one that walks
	var w := CharacterBody3D.new(); w.name = "Walker"; w.add_to_group("em_walker")
	_stage.add_child(w); w.global_position = Vector3(60, 0, -8)

	var x := 0.0
	var placed: Array = []
	for row in ORDER:
		var tok := String(row[0])
		var path := String(by.get(tok, ""))
		if path == "" or not ResourceLoader.exists(path):
			print("  skip %s" % tok); continue
		var inst: Node = (load(path) as PackedScene).instantiate()
		if inst == null: continue
		_stage.add_child(inst)
		if inst is Node3D: (inst as Node3D).global_position = Vector3(x, 0, 0)
		placed.append({"tok": tok, "x": x, "d": float(row[1]), "h": float(row[2]), "node": inst})
		x += 14.0
	await create_timer(2.0).timeout

	# FRAME FROM THE AABB, NOT FROM A GUESS. The first strip used hand-typed
	# distances and photographed the corpus line — 0.24 m end to end — from
	# 2.4 m, so the ancestor of the whole animal came out forty pixels wide in
	# the corner of the frame. These subjects differ by two orders of magnitude;
	# the only honest standpoint is one derived from each ones own extent.
	var i := 0
	for p in placed:
		var pd: Dictionary = p
		var n: Node3D = pd["node"]
		# AND THROW OUT THE HOGS. Merging every box measured draw_dot at 28.4 m
		# and the point at 17.3 m: one backdrop quad or one far-flung marker
		# inflates the merged AABB and the framing collapses again, this time
		# in the other direction. Boxes larger than three times the median are
		# dropped, which is the documented fix for exactly this.
		var boxes: Array = []
		var diags: Array = []
		var stack: Array = [n]
		while not stack.is_empty():
			var q: Node = stack.pop_back()
			if q is VisualInstance3D:
				var vi: VisualInstance3D = q
				var wb: AABB = vi.global_transform * vi.get_aabb()
				var dl: float = wb.size.length()
				if dl > 0.0001:
					boxes.append(wb); diags.append(dl)
			for ch in q.get_children(): stack.append(ch)
		# FIXED thresholds, and a fallback. A median-derived cap over-corrected in
		# the other direction and threw away every part of the triangle, leaving
		# a frame with nothing in it. These subjects stand 14 m apart and none is
		# over a metre, so 2 m of extent and 1.5 m of distance separate the
		# artifact from its backdrop without a statistic that can collapse.
		var box := AABB()
		var has := false
		var kept := 0
		var anchor: Vector3 = (n as Node3D).global_position
		for pass_i in range(2):
			for bi in range(boxes.size()):
				var wb2: AABB = boxes[bi]
				if pass_i == 0:
					if wb2.size.length() > 2.0: continue
					if wb2.get_center().distance_to(anchor) > 1.5: continue
				box = wb2 if not has else box.merge(wb2)
				has = true
				kept += 1
			if has: break     # second pass only runs when the filter kept nothing
		var at: Vector3 = box.get_center() if has else (n as Node3D).global_position
		var diag: float = box.size.length() if has else 1.0
		var d2: float = clampf(diag * 1.20, 0.26, 1.70)
		print("  %-32s kept %d of %d parts, diag %.3f m -> camera %.3f m" % [String(pd["tok"]), kept, boxes.size(), diag, d2])
		_cam.global_position = at + Vector3(d2 * 0.50, d2 * 0.40, d2 * 0.76)
		_cam.look_at(at, Vector3.UP)
		await create_timer(0.2).timeout
		i += 1
		await _shoot("%d_%s" % [i, String(pd["tok"])])
	print("LINEAGE STRIP: %d shot(s)" % _n)
	var f := FileAccess.open(OUT + "/_index.txt", FileAccess.WRITE)
	if f != null: f.store_string("%d\n" % _n); f.close()
	quit(0 if _n >= 4 else 1)
