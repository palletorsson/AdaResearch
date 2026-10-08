extends Node3D
## F6: desktop control preview of the exact same monitor artifact.
const Monitor = preload("res://commons/artifacts/concept_monitor/concept_monitor.tscn")
@export var monitor_scene: PackedScene = Monitor
const PointerEvent = preload("res://addons/godot-xr-tools/events/pointer_event.gd")
var camera: Camera3D
var monitor: Node3D
var pressed_target: Node3D
var looking := false

func _ready() -> void:
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("1d2028")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("eee4ec")
	settings.ambient_light_energy = 0.7
	environment.environment = settings
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -20, 0)
	light.light_energy = 0.75
	add_child(light)
	monitor = monitor_scene.instantiate()
	add_child(monitor)
	camera = Camera3D.new()
	camera.position = Vector3(0, 1.62, 4.4)
	camera.fov = 45
	add_child(camera)
	camera.look_at(Vector3(0, 1.5, 0))
	camera.make_current()
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(20, 20)
	var floor_node := MeshInstance3D.new()
	floor_node.mesh = floor_mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("444450")
	mat.roughness = 0.95
	floor_node.material_override = mat
	add_child(floor_node)
	var hud := Label.new()
	hud.text = "Look at the screen to play / Right-drag: look around / Home: return\nClick buttons / Wheel: approach / Arrows: turn the filmed scene"
	hud.position = Vector2(25, 22)
	hud.add_theme_font_size_override("font_size", 18)
	add_child(hud)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and looking:
		camera.rotation.y -= event.relative.x * 0.004
		camera.rotation.x = clampf(camera.rotation.x - event.relative.y * 0.004, -1.3, 1.3)
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		looking = event.pressed
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_HOME:
		camera.look_at(Vector3(0, 1.5, 0))
	if event is InputEventKey and event.pressed and event.keycode in [KEY_LEFT, KEY_RIGHT]:
		var filmed_stage: Node3D = monitor.get("stage")
		if filmed_stage.has_method("orbit"):
			filmed_stage.call("orbit", -0.22 if event.keycode == KEY_LEFT else 0.22)
			monitor.call("refresh_once")
	if not event is InputEventMouseButton: return
	if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		camera.position.z = clampf(camera.position.z + (-0.2 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 0.2), 2.6, 7.0)
	if event.button_index != MOUSE_BUTTON_LEFT: return
	if not event.pressed:
		if is_instance_valid(pressed_target): PointerEvent.released(camera, pressed_target, pressed_target.global_position)
		pressed_target = null
		return
	var from := camera.project_ray_origin(event.position)
	var query := PhysicsRayQueryParameters3D.create(from, from + camera.project_ray_normal(event.position) * 10, 1 | (1 << 20))
	query.collide_with_areas = true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.collider.has_method("pointer_event"):
		pressed_target = hit.collider
		PointerEvent.pressed(camera, pressed_target, hit.position)
