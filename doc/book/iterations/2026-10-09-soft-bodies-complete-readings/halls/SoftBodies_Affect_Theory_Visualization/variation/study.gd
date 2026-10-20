extends Node3D
const VesselSurface = preload("vessel_surface.gd")
const PointBody = preload("point_body.gd")
const SAMPLE_STEP := 40
const TURN_SPEED := 0.35
const NEUTRAL := Color("d6cec0")
const ACCENT := Color("c982a9")
var surface = VesselSurface.new()
var left := MeshInstance3D.new()
var right := MeshInstance3D.new()
var point = PointBody.new()
var caption := Label3D.new()
var saved_positions := PackedVector3Array()
var saved_indices := PackedInt32Array()
var condition := 0

func _ready() -> void:
	# Reconstruct the previous lesson's step-40 snapshot from its same recipe.
	surface.sim.simulate(SAMPLE_STEP, 0.0166667)
	saved_positions = surface.sim.positions.duplicate()
	saved_indices = surface.indices.duplicate()
	var saved_mesh: ArrayMesh = surface.mesh_for(saved_positions, saved_indices)
	for body in [left, right]:
		body.mesh = saved_mesh
		var finish := StandardMaterial3D.new()
		finish.albedo_color = NEUTRAL
		finish.roughness = 0.5
		finish.cull_mode = BaseMaterial3D.CULL_DISABLED
		body.material_override = finish
		add_child(body)
	left.position = Vector3(-1.25, 2.2, 0)
	right.position = Vector3(1.25, 2.2, 0)
	point.position = Vector3(0, 1.1, 1.0)
	add_child(point)
	point.action_pressed.connect(func(_source): next_condition())
	caption.position = Vector3(0, 3.4, 0)
	caption.font_size = 32
	caption.pixel_size = 0.0025
	caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(caption)
	set_condition(0)

func _process(delta: float) -> void:
	if condition == 1:
		right.rotate_z(TURN_SPEED * delta)

func set_condition(value: int) -> void:
	condition = value
	right.rotation = Vector3.ZERO
	right.material_override.albedo_color = NEUTRAL
	if condition == 2:
		right.material_override.albedo_color = ACCENT
	caption.text = ["SAME SHAPE / same appearance", "SAME SHAPE / right turns", "SAME SHAPE / right changes colour"][condition]
	caption.text += "\nPoint trigger / 1: next    2: reset"

func next_condition() -> void:
	set_condition((condition + 1) % 3)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			next_condition()
		elif event.keycode == KEY_2:
			set_condition(0)
