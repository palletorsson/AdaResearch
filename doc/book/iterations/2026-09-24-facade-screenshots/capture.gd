extends Node3D

const Builder = preload("res://commons/artifacts/facade_builder/facade_builder.gd")
const PRESETS = ["classical", "baroque", "venetian_gothic", "naples_diamond_rustication", "florence_marble", "nyc_tenement", "superstudio_grid", "memphis_totem"]
var camera: Camera3D
var records: Array = []

func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.19, 0.21, 0.24)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.87, 0.91)
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, -28, 0)
	sun.light_energy = 0.65
	sun.light_color = Color(1.0, 0.97, 0.92)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 100.0
	add_child(sun)
	var floor_node := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(180, 180)
	floor_node.mesh = plane
	floor_node.position.y = -0.03
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.24, 0.25, 0.27)
	mat.roughness = 0.92
	floor_node.material_override = mat
	add_child(floor_node)
	camera = Camera3D.new()
	camera.fov = 46.0
	camera.far = 300.0
	camera.current = true
	add_child(camera)
	_run.call_deferred()

func _run() -> void:
	var out := OS.get_environment("ADA_FACADE_CAPTURE_OUT")
	for preset in PRESETS:
		var path := "res://commons/facade_parts/presets/%s.json" % preset
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		var w: float = float(data.facade.total_width)
		var h: float = float(data.facade.total_height)
		var work = Builder.new()
		work.plan_path = path
		work.position.x = -w * 0.5
		add_child(work)
		for i in range(16):
			await get_tree().process_frame
		var half_fov: float = tan(deg_to_rad(camera.fov * 0.5))
		var distance: float = maxf(h * 1.26 / (2.0 * half_fov), w * 1.26 / (2.0 * half_fov * 1.6)) + 1.5
		var target := Vector3(0, h * 0.48, 0)
		camera.position = target + Vector3(-distance * 0.12, distance * 0.055, distance)
		camera.look_at(target)
		await get_tree().create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		var error: int = img.save_png(out.path_join(preset + ".png"))
		var composed: Node = work.get_node_or_null("FacadeComposed")
		records.append({"preset":preset, "plan_path":path, "width":w, "height":h, "composed":composed != null, "saved":error == OK, "camera":str(camera.position)})
		print("CAPTURED ", preset)
		work.queue_free()
		await get_tree().process_frame
	var f := FileAccess.open(out.path_join("captures.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(records, "  "))
	f.close()
	get_tree().quit()
