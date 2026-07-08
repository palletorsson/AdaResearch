extends SceneTree
# Orbit-capture proof for the endless ring: instantiate jspace_ring, place a
# camera at several topic angles around the loop, let _process re-light the
# field at each, and save a first-person shot per topic. This is the ONLY way
# to prove the scroll — a static 4-angle capture can't, because the field only
# lights under a walking camera.

const OUT_DIR := "user://jspace_ring_shots"
const RING_R := 6.0
# sample topics around the ring: point(0), line(1), fractal(10), cell(15), proof(23)
const SAMPLES := [
	{"i": 0,  "name": "point"},
	{"i": 1,  "name": "line"},
	{"i": 10, "name": "fractal"},
	{"i": 15, "name": "cell"},
	{"i": 23, "name": "proof"},
]
const N_TOPICS := 24

var _cam: Camera3D
var _ring: Node3D
var _idx := 0
var _env: WorldEnvironment

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var scene = load("res://commons/artifacts/jspace/jspace_ring.tscn")
	_ring = scene.instantiate()
	root.add_child(_ring)

	# a little light so the dark pillars read
	var dl := DirectionalLight3D.new()
	dl.rotation_degrees = Vector3(-55, -35, 0)
	dl.light_energy = 0.7
	root.add_child(dl)
	_env = WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.05, 0.05, 0.08)
	e.ambient_light_color = Color(0.2, 0.22, 0.32)
	e.ambient_light_energy = 0.5
	_env.environment = e
	root.add_child(_env)

	_cam = Camera3D.new()
	_cam.fov = 78
	root.add_child(_cam)
	_cam.make_current()
	_place(SAMPLES[0]["i"])
	_run()

func _place(topic_i: int) -> void:
	var ang := TAU * float(topic_i) / float(N_TOPICS)
	# walker's eye: just outside the ring path, looking tangentially along it
	var eye := Vector3(cos(ang), 0, sin(ang)) * (RING_R + 2.4) + Vector3(0, 1.7, 0)
	var ahead_ang := ang + 0.5
	var look := Vector3(cos(ahead_ang), 0, sin(ahead_ang)) * RING_R + Vector3(0, 1.0, 0)
	_cam.global_position = eye
	_cam.look_at(look, Vector3.UP)

func _run() -> void:
	await process_frame
	await process_frame     # let _process light the field for this angle
	for s in SAMPLES:
		_place(int(s["i"]))
		# a few frames so _process (reads camera angle) + relabel settle
		for _f in range(4):
			await process_frame
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		var path := "%s/%s.png" % [OUT_DIR, s["name"]]
		img.save_png(path)
		print("captured ", path)
	print("DONE jspace_ring orbit capture")
	quit(0)
