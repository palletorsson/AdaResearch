extends SceneTree
## MANY VERSIONS, SIDE BY SIDE (2026-08-26, Palle: "iterate and improve with
## multi agent many different versions"). Reads a variant list written by the
## design agents, builds every one on the same floor under the same light, and
## photographs each from the same two standpoints — a portrait and a walk —
## so the comparison is about the ANIMAL and not about the camera.
##
## ONE Godot run for all of them: two instances collide on the user:// lock.
const IN := "res://ada_run/_crab_variants.json"
const OUT := "res://ada_run/variant_shots"
const CRAB := "res://commons/hazards/head_crab/head_crab.tscn"

var _cam: Camera3D = null
var _stage: Node3D = null
var _n := 0

func _initialize() -> void: call_deferred("_run")

func _world() -> void:
	_stage = Node3D.new(); get_root().add_child(_stage)
	var fb := StaticBody3D.new()
	var cs := CollisionShape3D.new(); var bx := BoxShape3D.new()
	bx.size = Vector3(200, 0.4, 60); cs.shape = bx; cs.position = Vector3(0, -0.2, 0)
	fb.add_child(cs); _stage.add_child(fb)
	var fm := MeshInstance3D.new(); var fbm := BoxMesh.new()
	fbm.size = Vector3(200, 0.4, 60); fm.mesh = fbm; fm.position = Vector3(0, -0.2, 0)
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.15, 0.15, 0.18); fmat.roughness = 0.9
	fm.material_override = fmat; _stage.add_child(fm)
	# A MIRROR NEEDS SOMETHING TO MIRROR. At metallic 0.95 against a flat colour
	# background the legs came back matte black: a metal is almost entirely its
	# reflection, and there was nothing in the world to reflect. A procedural
	# sky gives the finish a gradient to pick up, which is what makes a polished
	# dark object read as polished rather than as a silhouette.
	var env := WorldEnvironment.new(); var e := Environment.new()
	var sky := Sky.new()
	var pm := ProceduralSkyMaterial.new()
	pm.sky_top_color = Color(0.16, 0.19, 0.26)
	pm.sky_horizon_color = Color(0.42, 0.45, 0.52)
	pm.ground_bottom_color = Color(0.05, 0.05, 0.07)
	pm.ground_horizon_color = Color(0.20, 0.21, 0.25)
	pm.sun_angle_max = 12.0
	sky.sky_material = pm
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 1.0
	e.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_exposure = 1.05
	env.environment = e; _stage.add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-38, -32, 0); key.light_energy = 2.0
	key.shadow_enabled = true; _stage.add_child(key)
	# a cool rim from behind, so a dark object keeps an edge against a dark floor
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-14, 152, 0)
	rim.light_energy = 1.5
	rim.light_color = Color(0.72, 0.82, 1.0)
	_stage.add_child(rim)
	_cam = Camera3D.new(); _cam.fov = 40.0; _stage.add_child(_cam); _cam.current = true

func _look(at: Vector3, from: Vector3) -> void:
	_cam.global_position = from; _cam.look_at(at, Vector3.UP)

func _shoot(n: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_root().get_texture().get_image()
	if img == null: return
	var d := ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(d)
	if img.save_png(d.path_join(n + ".png")) == OK:
		_n += 1

func _run() -> void:
	_world()
	var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(IN))
	if not (doc is Dictionary):
		print("no variant file"); quit(1); return
	var vs: Array = (doc as Dictionary).get("variants", [])
	print("VARIANTS: %d" % vs.size())
	var crabs: Array = []
	# every crab gets its own lane, 8 m apart, and its own visitor to hunt
	for i in range(vs.size()):
		var v: Dictionary = vs[i]
		var pr: Dictionary = v.get("params", {})
		var c: Node3D = (load(CRAB) as PackedScene).instantiate() as Node3D
		var csg := {}
		for k in pr:
			var key := String(k)
			if key.begins_with("creature_") or key.begins_with("leg_"):
				var cv: Variant = pr[k]
				if cv is String and String(cv).begins_with("#"):
					csg[key] = Color(String(cv))
				else:
					csg[key] = cv
			elif key == "ride_local":
				c.set("ride_local", float(pr[k]))
			elif key == "stance":
				c.set("stance", float(pr[k]))
			else:
				c.set(key, pr[k])
		c.set("csg_params", csg)
		# the finish block, if the variant carries one
		var fin: Dictionary = v.get("finish", {})
		for fk in fin:
			var fkey := String(fk)
			var fv: Variant = fin[fk]
			if fv is Array and (fv as Array).size() >= 3:
				c.set(fkey, Color(float(fv[0]), float(fv[1]), float(fv[2])))
			else:
				c.set(fkey, fv)
		_stage.add_child(c)
		c.global_position = Vector3(float(i) * 8.0, 0, 0)
		crabs.append(c)
		var w := CharacterBody3D.new()
		w.name = "Walker"; w.add_to_group("em_walker")   # only the first is found by group
		_stage.add_child(w); w.global_position = Vector3(float(i) * 8.0, 0, -7)
	await create_timer(1.4).timeout

	# PORTRAIT: same standpoint relative to every crab, so they are comparable
	for i in range(crabs.size()):
		var c: Node3D = crabs[i]
		var p: Vector3 = c.global_position
		_look(p + Vector3(0, 0.20, 0), p + Vector3(0.62, 0.42, 0.80))
		await create_timer(0.15).timeout
		await _shoot("v%d_portrait" % (i + 1))
	# let them walk, then shoot the same two views again
	await create_timer(2.6).timeout
	for i in range(crabs.size()):
		var c2: Node3D = crabs[i]
		var p2: Vector3 = c2.global_position
		_look(p2 + Vector3(0, 0.16, 0), p2 + Vector3(1.05, 0.55, 1.25))
		await create_timer(0.12).timeout
		await _shoot("v%d_walk" % (i + 1))
		_look(p2 + Vector3(0, 0.16, 0), p2 + Vector3(0.95, 0.16, 0.08))
		await create_timer(0.12).timeout
		await _shoot("v%d_side" % (i + 1))

	var f := FileAccess.open(OUT + "/_index.txt", FileAccess.WRITE)
	f.store_string("shots %d\n" % _n); f.close()
	print("VARIANT SHOTS: %d" % _n)
	quit(0)
