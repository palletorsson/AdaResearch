extends Node3D
const VesselSurface = preload("vessel_surface.gd")
const PointBody = preload("point_body.gd")
const SAMPLE_STEP := 200
const STEP := 0.0166667
var surface = VesselSurface.new()
var live := MeshInstance3D.new()
var kept := MeshInstance3D.new()
var point = PointBody.new()
var caption := Label3D.new()
var step_count := 0
var saved_step := -1
var saved_positions := PackedVector3Array()
var saved_indices := PackedInt32Array()

func _ready() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("c98288")
	material.roughness = 0.3
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	for body in [live, kept]:
		body.material_override = material
		add_child(body)
	live.position = Vector3(-0.85, 2.0, 0)
	kept.position = Vector3(0.85, 2.0, 0)
	point.position = Vector3(0, 1.1, 1.0)
	add_child(point)
	point.action_pressed.connect(func(_source): capture())
	caption.position = Vector3(0, 3.0, 0)
	caption.font_size = 32
	caption.pixel_size = 0.0025
	caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(caption)
	restart()

func _physics_process(_delta: float) -> void:
	surface.sim.step(STEP)
	step_count += 1
	live.mesh = surface.mesh_for(surface.sim.positions, surface.indices)
	if step_count == SAMPLE_STEP:
		capture()
	update_caption()

func capture() -> void:
	saved_positions = surface.sim.positions.duplicate()
	saved_indices = surface.indices.duplicate()
	saved_step = step_count
	kept.mesh = surface.mesh_for(saved_positions, saved_indices)
	update_caption()

func restart() -> void:
	surface = VesselSurface.new()
	step_count = 0
	saved_step = -1
	saved_positions.clear()
	saved_indices.clear()
	kept.mesh = null
	live.mesh = surface.mesh_for(surface.sim.positions, surface.indices)
	update_caption()

func update_caption() -> void:
	var reading := "waiting" if saved_step < 0 else "step %d" % saved_step
	caption.text = "LIVE: step %d    |    KEPT: %s\nPoint trigger / 1: capture    2: restart" % [step_count, reading]

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			capture()
		elif event.keycode == KEY_2:
			restart()
