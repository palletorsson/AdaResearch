extends SceneTree
## THE GESTATION, PHOTOGRAPHED (2026-08-26, Palle: "Can we simulate the break of
## the dark sphere so you can show me how it looks? From point to the head crab?")
##
## Not a mock-up: this builds the REAL artifacts, fires the REAL catalyst call,
## and photographs the result at the moments that matter — the egg intact, the
## break, and what is left standing. Four rows:
##   1 point     the egg in the point place, and the point that falls out of it
##   2 line      one line leaving, several landing
##   3 triangle  it holds, rises, and weaves its own inside
##   4 crab      the octapod wearing guise "sphere" — the same object, hatching
## The crab is the ladder's far end and is NOT yet wired to the gestation; it is
## shot here because its disguise IS a dark sphere, so the row is honest about
## where the ladder is going.
##
## godot --path . --xr-mode off --script res://commons/testing/shoot_gestation_storyboard.gd

const OUT_DIR := "res://ada_run/gestation_shots"
const DS := "res://commons/artifacts/dark_sphere/dark_sphere.tscn"
const CRAB := "res://commons/hazards/octapod_crawler/octapod_crawler.tscn"

var _cam: Camera3D = null
var _stage: Node3D = null
var _shots: Array = []


func _initialize() -> void:
	call_deferred("_run")


func _world() -> void:
	_stage = Node3D.new()
	_stage.name = "Stage"
	get_root().add_child(_stage)

	# a floor to fall onto, and to catch the shadow
	var floor_body := StaticBody3D.new()
	var fcs := CollisionShape3D.new()
	var fbx := BoxShape3D.new()
	fbx.size = Vector3(60, 0.4, 30)
	fcs.shape = fbx
	fcs.position = Vector3(9, -0.2, 0)
	floor_body.add_child(fcs)
	_stage.add_child(floor_body)
	var fm := MeshInstance3D.new()
	var fbm := BoxMesh.new()
	fbm.size = Vector3(60, 0.4, 30)
	fm.mesh = fbm
	fm.position = Vector3(9, -0.2, 0)
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.13, 0.13, 0.16)
	fmat.roughness = 0.9
	fm.material_override = fmat
	_stage.add_child(fm)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.05, 0.05, 0.07)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.4, 0.42, 0.5)
	e.ambient_light_energy = 0.5
	env.environment = e
	_stage.add_child(env)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-42, -38, 0)
	key.light_energy = 1.5
	key.shadow_enabled = true
	_stage.add_child(key)

	_cam = Camera3D.new()
	_cam.fov = 46.0
	_stage.add_child(_cam)
	_cam.current = true


func _look(at: Vector3, from: Vector3) -> void:
	_cam.global_position = from
	_cam.look_at(at, Vector3.UP)


## a dark sphere standing in a named place — the museum stamps em_pearl on the
## hall, so a host carrying that meta is exactly what the artifact reads
func _egg(place: String, at: Vector3) -> Node3D:
	var host := Node3D.new()
	host.set_meta("em_pearl", place)
	host.position = at
	_stage.add_child(host)
	var s: Node3D = (load(DS) as PackedScene).instantiate() as Node3D
	host.add_child(s)
	return s


func _shoot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_root().get_texture().get_image()
	if img == null:
		print("  ! no image for %s" % name)
		return
	var dir_abs: String = ProjectSettings.globalize_path(OUT_DIR)
	DirAccess.make_dir_recursive_absolute(dir_abs)
	var path: String = dir_abs.path_join(name + ".png")
	if img.save_png(path) == OK:
		_shots.append(name)
		print("  shot %s" % name)


func _wait(s: float) -> void:
	await create_timer(s).timeout


func _run() -> void:
	_world()
	await _wait(0.6)

	# ── ROW 1 — THE POINT ───────────────────────────────────────────────────
	var e1: Node3D = _egg("point", Vector3(0, 0.6, 0))
	await _wait(0.9)
	_look(Vector3(0, 0.6, 0), Vector3(1.7, 1.35, 1.9))
	await _wait(0.2)
	await _shoot("1a_point_egg_intact")
	e1.call("hit_by_catalyst_mode", Color(1.0, 0.42, 0.92), "transformation")
	await _wait(0.16)
	await _shoot("1b_point_breaks")
	await _wait(0.55)
	await _shoot("1c_point_falls")
	await _wait(1.4)
	_look(Vector3(0, 0.25, 0), Vector3(1.3, 0.95, 1.5))
	await _shoot("1d_point_landed")

	# ── ROW 2 — THE LINE ────────────────────────────────────────────────────
	var e2: Node3D = _egg("point lines", Vector3(6, 0.6, 0))
	await _wait(0.9)
	_look(Vector3(6, 0.6, 0), Vector3(6.2, 1.5, 2.4))
	await _wait(0.2)
	await _shoot("2a_line_egg_intact")
	e2.call("hit_by_catalyst_mode", Color(0.42, 1.0, 0.88), "transformation")
	await _wait(0.16)
	await _shoot("2b_line_leaves_as_one")
	await _wait(0.45)
	await _shoot("2c_line_breaking")
	await _wait(1.6)
	_look(Vector3(6, 0.2, 0), Vector3(6.2, 1.1, 2.0))
	await _shoot("2d_line_landed_as_several")

	# ── ROW 3 — THE TRIANGLE, AND THE WEAVE ────────────────────────────────
	var e3: Node3D = _egg("point triangle context", Vector3(12, 0.6, 0))
	await _wait(0.9)
	_look(Vector3(12, 0.9, 0), Vector3(12.0, 1.5, 2.9))
	await _wait(0.2)
	await _shoot("3a_triangle_egg_intact")
	e3.call("hit_by_catalyst_mode", Color(0.75, 0.58, 0.98), "transformation")
	await _wait(0.18)
	await _shoot("3b_triangle_egg_breaks")
	await _wait(0.5)
	_look(Vector3(12, 1.15, 0), Vector3(12.0, 1.5, 2.9))
	await _shoot("3c_triangle_rises")
	await _wait(1.6)
	await _shoot("3d_weave_begins")
	await _wait(2.2)
	await _shoot("3e_weave_half")
	await _wait(3.2)
	await _shoot("3f_cloth_complete")
	_look(Vector3(12, 1.15, 0), Vector3(13.6, 1.5, 1.6))
	await _wait(0.2)
	await _shoot("3g_cloth_three_quarter")

	# ── ROW 4 — THE FAR END: the crab wearing the same sphere ──────────────
	if ResourceLoader.exists(CRAB):
		var host := Node3D.new()
		host.position = Vector3(18, 0, 0)
		_stage.add_child(host)
		var crab: Node3D = (load(CRAB) as PackedScene).instantiate() as Node3D
		crab.set("guise", "sphere")
		crab.set("start_dormant", true)
		host.add_child(crab)
		await _wait(1.2)
		# CLOSE. The first sheet shot this row from 2.4 m and the crab read as a
		# speck; worse, it hatches and CHASES, so the late frame caught an empty
		# floor. The camera comes in to 1.5 m and the frames come sooner.
		_look(Vector3(18, 0.42, 0), Vector3(18.15, 0.95, 1.5))
		await _wait(0.2)
		await _shoot("4a_crab_disguised_as_a_sphere")
		# the walker arrives: inside hatch_radius, it opens
		var walker := CharacterBody3D.new()
		walker.name = "Walker"
		walker.add_to_group("em_walker")
		_stage.add_child(walker)
		walker.global_position = Vector3(19.0, 0, 0.6)
		await _wait(0.55)
		await _shoot("4b_crab_hatching")
		await _wait(0.75)
		await _shoot("4c_crab_out")
		await _wait(0.6)
		# it is hunting by now — follow it rather than photograph where it WAS
		var cb: Node3D = crab
		_look(cb.global_position + Vector3(0, 0.15, 0), cb.global_position + Vector3(0.5, 0.75, 1.35))
		await _wait(0.15)
		await _shoot("4d_crab_hunting")

	var f := FileAccess.open("res://ada_run/gestation_shots/_index.txt", FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(PackedStringArray(_shots)) + "\n")
		f.close()
	print("STORYBOARD: %d shot(s) -> %s" % [_shots.size(), OUT_DIR])
	quit(0)
