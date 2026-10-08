extends Node3D
## A monitor films a private teaching scene, following commons/monitor/cctv.tscn.
## Only the new illustration changes. Existing museum artifacts remain independent.
## Stage protocol: advance(delta), toggle_pause(), replay(), step_sample(), next_route().
const ButtonScript = preload("res://commons/interactables/interactable_area_button_pointer.gd")
@export var concept_scene: PackedScene = preload("res://commons/artifacts/concept_monitor/line_trace_stage.tscn")
@export var active_distance := 14.0
@export_range(0.0, 1.0) var gaze_dwell := 0.18
@export_flags_3d_physics var sight_collision_mask: int = 1
@export var force_active := false
@export var next_caption := "NEXT ROUTE"
@export var step_caption := "STEP"
var viewport: SubViewport
var stage: Node3D
var screen: MeshInstance3D
var buttons: Dictionary = {}
var pause_label: Label3D
var _frame_elapsed := 0.0
var gaze_active := false
var _gaze_elapsed := 0.0
var _refresh_requested := true

func _ready() -> void:
	viewport = SubViewport.new()
	viewport.name = "PrivateIllustrationWorld"
	viewport.size = Vector2i(1024, 576)
	viewport.own_world_3d = true
	viewport.world_3d = World3D.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	viewport.msaa_3d = Viewport.MSAA_2X
	add_child(viewport)
	stage = concept_scene.instantiate()
	viewport.add_child(stage)
	box("Case", Vector3(2.68, 1.58, 0.12), Vector3(0, 1.72, 0), Color("d9d6d0"), true)
	box("Bezel", Vector3(2.61, 1.49, 0.03), Vector3(0, 1.72, 0.069), Color("15181f"))
	screen = MeshInstance3D.new()
	screen.name = "LiveScreen"
	var quad := QuadMesh.new()
	quad.size = Vector2(2.56, 1.44)
	screen.mesh = quad
	var surface := StandardMaterial3D.new()
	surface.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	surface.albedo_texture = viewport.get_texture()
	surface.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	screen.material_override = surface
	screen.position = Vector3(0, 1.72, 0.087)
	add_child(screen)
	box("Stand", Vector3(0.18, 0.9, 0.20), Vector3(0, 0.48, -0.03), Color("b8b5b0"), true)
	box("Foot", Vector3(0.92, 0.06, 0.52), Vector3(0, 0.03, 0), Color("d9d6d0"), true)
	box("Controls", Vector3(2.15, 0.22, 0.16), Vector3(0, 0.79, 0.10), Color("d9d6d0"))
	for i in range(4):
		var key: String = ["pause", "replay", "step", "route"][i]
		var label := add_button(key, Vector3(-0.78 + i * 0.52, 0.80, 0.21))
		if key == "pause": pause_label = label
func _physics_process(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if force_active or is_looking_at_screen(camera):
		_gaze_elapsed += delta
		gaze_active = force_active or _gaze_elapsed >= gaze_dwell
	else:
		_gaze_elapsed = 0.0
		gaze_active = false

func is_looking_at_screen(camera: Camera3D) -> bool:
	if camera == null or not is_visible_in_tree() or not screen.is_visible_in_tree(): return false
	# The outer viewport supplies the desktop camera or the tracked XRCamera3D.
	# This uses head direction, not eye tracking or the private filmed camera.
	var view := camera.get_camera_transform()
	var inverse := screen.global_transform.affine_inverse()
	var eye := inverse * view.origin
	var direction := inverse.basis * -view.basis.z.normalized()
	if eye.z <= 0.0 or direction.z >= -0.00001: return false
	var hit := eye + direction * (-eye.z / direction.z)
	var half_size := (screen.mesh as QuadMesh).size * 0.5
	if absf(hit.x) > half_size.x or absf(hit.y) > half_size.y: return false
	var target := screen.to_global(hit)
	if view.origin.distance_to(target) > active_distance: return false
	# Stop just before the screen; its own case is behind this plane.
	var end := target.move_toward(view.origin, 0.002)
	var query := PhysicsRayQueryParameters3D.create(view.origin, end, sight_collision_mask)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _process(delta: float) -> void:
	var playing := gaze_active and bool(stage.get("running"))
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE if playing else (SubViewport.UPDATE_ONCE if _refresh_requested else SubViewport.UPDATE_DISABLED)
	_refresh_requested = false
	if not playing:
		_frame_elapsed = 0.0
		return
	_frame_elapsed += delta
	if _frame_elapsed < 1.0 / 30.0: return
	stage.call("advance", _frame_elapsed)
	_frame_elapsed = 0.0
	pause_label.text = "PAUSE" if bool(stage.get("running")) else "PLAY"

func refresh_once() -> void:
	_refresh_requested = true

func activate(key: String) -> void:
	match key:
		"pause": stage.call("toggle_pause")
		"replay": stage.call("replay")
		"step": stage.call("step_sample")
		"route": stage.call("next_route")
	pause_label.text = "PAUSE" if bool(stage.get("running")) else "PLAY"
	# A paused/offscreen feed still renders a changed state once.
	refresh_once()

func add_button(key: String, at: Vector3) -> Label3D:
	var cap := box(key + "Cap", Vector3(0.43, 0.15, 0.04), at, Color("272831"))
	var area := Area3D.new()
	area.name = key + "Button"
	area.set_script(ButtonScript)
	area.set("button", NodePath("../" + str(cap.name)))
	area.set("displacement", Vector3(0, 0, -0.008))
	area.collision_layer = 1 << 20
	area.collision_mask = 393216
	area.position = at
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.46, 0.18, 0.12)
	collision.shape = shape
	area.add_child(collision)
	add_child(area)
	area.connect("button_pressed", func(_button): activate(key))
	buttons[key] = area
	var label := Label3D.new()
	label.text = next_caption if key == "route" else (step_caption if key == "step" else key.to_upper())
	label.position = at + Vector3(0, 0, 0.023)
	label.pixel_size = 0.0009
	label.font_size = 31 if key == "route" else 38
	label.outline_size = 0
	label.modulate = Color("f7d3e4")
	add_child(label)
	return label

func box(title: String, size: Vector3, at: Vector3, colour: Color, solid := false) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = title
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	var finish := StandardMaterial3D.new()
	finish.albedo_color = colour
	finish.roughness = 0.64
	node.material_override = finish
	node.position = at
	add_child(node)
	if solid:
		var body := StaticBody3D.new()
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
		node.add_child(body)
	return node
