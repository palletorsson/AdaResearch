extends Node3D
## One live camera in a private filming world, displayed on a museum monitor.
## Layers isolate each line set; the source world cannot appear in visitor cameras.
const FILTER = preload("res://commons/artifacts/line_space_workshop/study_filter.gdshader")
const NAMES = ["MONO / FRONT", "INK / OBLIQUE", "CONTOUR / ORBIT", "SCAN / OBLIQUE"]
const SIZE := Vector2i(384, 288)
const FRAME_SECONDS := 1.0 / 12.0
var workshop: Node3D
var bay := 0
var viewport: SubViewport
var camera: Camera3D
var screen: MeshInstance3D
var visibility: VisibleOnScreenNotifier3D
var _elapsed := 0.0
var _frame_clock := 0.0

func _ready() -> void:
	viewport = SubViewport.new()
	viewport.name = "LiveFilm"
	viewport.size = SIZE
	viewport.world_3d = workshop.film_world.find_world_3d()
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	viewport.msaa_3d = Viewport.MSAA_DISABLED
	add_child(viewport)
	camera = Camera3D.new()
	camera.name = "StudyCamera"
	camera.cull_mask = 1 << (16 + bay)
	camera.near = 0.05
	camera.far = 2.7
	camera.fov = 42.0
	# The frontal study uses parallel projection: separated rods can seem to cross.
	if bay == 0:
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = 1.25
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("030609")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color.WHITE
	environment.ambient_light_energy = 0.8
	camera.environment = environment
	viewport.add_child(camera)
	camera.make_current()
	build_monitor()
	update_camera()

func build_monitor() -> void:
	var casing := Node3D.new()
	casing.name = "MonitorCasing"
	casing.position = Vector3(workshop.bay_x(bay), 1.25, 0.68)
	casing.rotation_degrees.x = -18.0
	add_child(casing)
	var body := MeshInstance3D.new()
	var shell := BoxMesh.new()
	shell.size = Vector3(0.86, 0.70, 0.075)
	body.mesh = shell
	var shell_material := StandardMaterial3D.new()
	shell_material.albedo_color = Color("17232a")
	shell_material.metallic = 0.6
	shell_material.roughness = 0.3
	body.material_override = shell_material
	casing.add_child(body)
	screen = MeshInstance3D.new()
	screen.name = "FilmSurface"
	var surface := QuadMesh.new()
	surface.size = Vector2(0.80, 0.60)
	screen.mesh = surface
	screen.position = Vector3(0, 0.025, 0.039)
	var filter := ShaderMaterial.new()
	filter.shader = FILTER
	filter.set_shader_parameter("film", viewport.get_texture())
	filter.set_shader_parameter("treatment", bay)
	filter.set_shader_parameter("texel", Vector2.ONE / Vector2(SIZE))
	filter.set_shader_parameter("ink", workshop.INKS[bay])
	screen.material_override = filter
	casing.add_child(screen)
	visibility = VisibleOnScreenNotifier3D.new()
	visibility.layers = 1
	visibility.aabb = AABB(Vector3(-0.43,-0.35,-0.04),Vector3(0.86,0.70,0.08))
	casing.add_child(visibility)
	var caption := Label3D.new()
	caption.name = "FilmCaption"
	caption.text = "LIVE  ·  " + NAMES[bay]
	caption.font_size = 48
	caption.pixel_size = 0.00057
	caption.outline_size = 0
	caption.modulate = workshop.INKS[bay]
	caption.position = Vector3(0, -0.31, 0.04)
	casing.add_child(caption)
	var count: Label3D = workshop.captions[bay]
	count.reparent(casing)
	count.position = Vector3(0,0.39,0.04)
	count.rotation = Vector3.ZERO
	# A slim support; visual only, so a visitor's hand cannot be trapped by it.
	workshop.box(Vector3(workshop.bay_x(bay),0.47,0.66),Vector3(0.045,0.94,0.045),shell_material)
	workshop.box(Vector3(workshop.bay_x(bay),0.024,0.66),Vector3(0.40,0.04,0.32),shell_material)

func _process(delta: float) -> void:
	_elapsed += delta
	_frame_clock += delta
	if not visibility.is_on_screen():
		_frame_clock = 0.0
		return
	if _frame_clock >= FRAME_SECONDS:
		_frame_clock = fmod(_frame_clock, FRAME_SECONDS)
		update_camera()
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func update_camera() -> void:
	var center := Vector3(workshop.bay_x(bay), 1.4, -0.23)
	var direction := Vector3(0, 0, 1.7)
	if bay == 1: direction = Vector3(0.7, 0.3, 1.55)
	if bay == 2:
		# A slow ±35° orbit shows that a flat image can hide a folded corner.
		var angle := sin(_elapsed * TAU / 36.0) * deg_to_rad(35.0)
		direction = Vector3(sin(angle)*1.7, 0.22, cos(angle)*1.7)
	if bay == 3: direction = Vector3(-0.65, 0.6, 1.45)
	camera.global_position = center + direction
	camera.look_at(center, Vector3.UP)
