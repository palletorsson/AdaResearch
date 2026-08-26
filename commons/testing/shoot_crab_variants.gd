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
	var env := WorldEnvironment.new(); var e := Environment.new()
	e.background_mode = Environment.BG_COLOR; e.background_color = Color(0.06, 0.06, 0.08)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.46, 0.48, 0.56); e.ambient_light_energy = 0.6
	env.environment = e; _stage.add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-38, -32, 0); key.light_energy = 1.7
	key.shadow_enabled = true; _stage.add_child(key)
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
				csg[key] = pr[k]
			elif key == "ride_local":
				c.set("ride_local", float(pr[k]))
			elif key == "stance":
				c.set("stance", float(pr[k]))
			else:
				c.set(key, pr[k])
		c.set("csg_params", csg)
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
		_look(p + Vector3(0, 0.16, 0), p + Vector3(0.95, 0.60, 1.15))
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
		_look(p2 + Vector3(0, 0.12, 0), p2 + Vector3(1.5, 0.22, 0.1))
		await create_timer(0.12).timeout
		await _shoot("v%d_side" % (i + 1))

	var f := FileAccess.open(OUT + "/_index.txt", FileAccess.WRITE)
	f.store_string("shots %d\n" % _n); f.close()
	print("VARIANT SHOTS: %d" % _n)
	quit(0)
