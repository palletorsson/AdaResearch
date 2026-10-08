extends SceneTree

## The world-scale body: from the approach line, and from inside it.

const SCENE := "res://commons/artifacts/radial_inside/rhizome_world.tscn"
const OUT := "user://rhizome_world"
const EYE := 1.60

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var pm := ProceduralSkyMaterial.new()
	pm.sky_top_color = Color(0.05, 0.05, 0.09)
	pm.sky_horizon_color = Color(0.22, 0.16, 0.24)
	pm.ground_bottom_color = Color(0.06, 0.05, 0.07)
	pm.ground_horizon_color = Color(0.18, 0.14, 0.18)
	sky.sky_material = pm
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.9
	e.tonemap_mode = Environment.TONE_MAPPER_AGX
	e.tonemap_exposure = 1.15
	e.tonemap_white = 6.0
	e.glow_enabled = true
	e.glow_bloom = 0.0
	e.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	e.glow_hdr_threshold = 1.0
	e.fog_enabled = true
	e.fog_density = 0.004
	e.fog_light_color = Color(0.20, 0.15, 0.22)
	env.environment = e
	root.add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, 132, 0)
	sun.light_energy = 1.5
	sun.light_color = Color(1.0, 0.90, 0.86)
	root.add_child(sun)

	var n: Node3D = (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(n)
	await process_frame
	var k: float = float(n.get("world_scale"))
	var mouth: Vector3 = (n.call("entrance_point") as Vector3) * k
	var dir: Vector3 = n.call("entrance_dir")
	var pts: Array = n.call("cavity_points")

	var cam := Camera3D.new()
	cam.fov = 75.0
	cam.near = 0.05
	cam.far = 900.0
	root.add_child(cam)
	cam.current = true

	var lamp := OmniLight3D.new()
	lamp.omni_range = 40.0
	lamp.light_energy = 3.0
	root.add_child(lamp)

	var shots: Array = [
		["approach", mouth + dir * 46.0 + Vector3(0, EYE, 0), mouth + Vector3(0, EYE, 0)],
		["mouth", mouth + dir * 13.0 + Vector3(0, EYE, 0), mouth + Vector3(0, EYE, 0)],
		["inside", mouth + Vector3(0, EYE, 0), (pts[0] as Vector3) * k + Vector3(0, EYE, 0)],
		["far", mouth + dir * 130.0 + Vector3(0, 22.0, 0), mouth],
	]
	for sh_v in shots:
		var sh: Array = sh_v
		cam.global_position = sh[1]
		cam.look_at(sh[2], Vector3.UP)
		lamp.global_position = (sh[1] as Vector3) + Vector3(0, 2.0, 0)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		get_root().get_texture().get_image().save_png("%s/%s.png" % [OUT, String(sh[0])])
		print("[look] %s" % String(sh[0]))
	quit(0)
