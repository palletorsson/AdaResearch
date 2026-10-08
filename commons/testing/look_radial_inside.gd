extends SceneTree

## THE GALLERY OF SURFACES — the six architecture surfaces, each shot from inside
## the same building at the same three stations, at the player's own eye height.
##
## A wall shot from outside is a fact about a camera. This one is about being on
## the wrong side of the shell, so every frame is taken standing in it, looking
## the way you would be walking. Same seed, same geometry, same lamp: the ONLY
## thing that changes between rows is the surface, which is what makes the sheet
## evidence rather than decoration.

const SCENE := "res://commons/artifacts/radial_inside/radial_inside.tscn"
const EYE: float = 1.60
const DECK_DROP: float = 1.90
const OUT := "user://radial_inside"
const SURFACES: Array[String] = ["panel", "film", "velvet", "wetstone", "nacre", "flesh"]
const STATIONS: Array[int] = [4, 11, 18]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.015, 0.015, 0.022)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.26, 0.23, 0.31)
	e.ambient_light_energy = 0.75
	e.tonemap_mode = Environment.TONE_MAPPER_AGX
	e.tonemap_exposure = 1.15
	e.tonemap_white = 6.0
	e.glow_enabled = true
	e.glow_bloom = 0.0
	e.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	e.glow_hdr_threshold = 1.0
	e.set_glow_level(2, 0.6); e.set_glow_level(3, 1.0); e.set_glow_level(4, 1.0)
	env.environment = e
	root.add_child(env)

	# A WINDOWLESS INTERIOR HAS NO SUN. One soft lamp at the eye so the panels
	# read at all; the seams supply the rest, which is the reference's own logic.
	var lamp := OmniLight3D.new()
	lamp.omni_range = 16.0
	lamp.light_energy = 1.7
	lamp.light_color = Color(1.0, 0.94, 0.90)
	root.add_child(lamp)

	var cam := Camera3D.new()
	cam.fov = 76.0
	cam.near = 0.05
	root.add_child(cam)
	cam.current = true

	var made: int = 0
	for surf in SURFACES:
		var n: Node3D = (load(SCENE) as PackedScene).instantiate() as Node3D
		n.set("seed", 3)
		n.set("surface", surf)
		root.add_child(n)
		await process_frame
		var spine: Array = n.call("spine_points")
		for si in STATIONS:
			var pi: int = mini(si, spine.size() - 4)
			var here: Vector3 = spine[pi]
			var ahead: Vector3 = spine[mini(pi + 4, spine.size() - 1)]
			var lift := Vector3(0.0, -DECK_DROP + EYE, 0.0)
			cam.global_position = here + lift
			cam.look_at(ahead + lift, Vector3.UP)
			lamp.global_position = here + lift + Vector3(0.0, 0.5, 0.0)
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			var img: Image = get_root().get_texture().get_image()
			img.save_png("%s/%s__station-%d.png" % [OUT, surf, pi])
			made += 1
		n.free()
		await process_frame
	print("[look] %d frame(s): %d surface(s) x %d station(s)" % [made, SURFACES.size(), STATIONS.size()])
	quit(0)
