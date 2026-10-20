extends Node3D
## Opt-in experiment placed in the existing Trans_Pre museum hall.
const Skull = preload("res://commons/hazards/catalyst_counterpart/flying_skull.gd")
var skull: CharacterBody3D
var catalyst: RigidBody3D
var readout: Label3D
var buttons: Array[Node3D] = []

func _ready() -> void:
	name = "CounterpartTrial"
	skull = Skull.new()
	skull.position = Vector3(0, 1.65, -3.5)
	add_child(skull)
	# Reuse the held PointBody which already reduces rings/segments and emits a form.
	# Load after autoload startup: XRToolsPickable depends on XRToolsUserSettings.
	catalyst = load("res://commons/artifacts/ignorance_gallery/resolution_catalyst.gd").new()
	catalyst.position = Vector3(-1.65, 1.28, 0)
	add_child(catalyst)
	_plinth(Vector3(-1.65, 0.55, 0), Vector3(0.48, 1.10, 0.48))
	_label("TAKE THE POINT\nTrigger sends a form", Vector3(-1.65, 1.62, 0), 25, 0.0018)
	_label("A FORM THAT ANSWERS", Vector3(0.35, 1.95, 0.05), 35, 0.002)
	_label("Choose an operation. Start when ready.\nSidestep its line, or interrupt it with a form.", Vector3(0.35, 1.70, 0.05), 24, 0.0016)
	readout = _label("", Vector3(0.35, 1.43, 0.05), 25, 0.0017)
	for i in range(4):
		var button: Node3D = load("res://commons/interactables/cube_button.tscn").instantiate()
		button.label = ["MOVE", "TURN", "SCALE", "START / REST"][i]
		button.accent = Color(0.7, 0.7, 0.67)
		button.position = Vector3(-0.35 + i * 0.45, 1.07, 0.1)
		button.scale = Vector3.ONE * 1.3
		add_child(button); buttons.append(button)
		if i < 3: button.pressed.connect(func(): skull.set_power(i + 1))
		else: button.pressed.connect(func(): skull.set_active(not skull.active))
	_plinth(Vector3(0.35, 0.48, 0.1), Vector3(1.8, 0.94, 0.28))

func _process(_delta: float) -> void:
	if not is_instance_valid(skull): return
	var operation: String = ["TRANSLATION", "+ ROTATION", "+ SCALE"][skull.power - 1]
	var state_name: String = ["RESTING", "LINE LOCKED", "MOVING", "RECOVERING", "INTERRUPTED"][skull.state]
	readout.text = "%s / %s\n%d interruptions   %d tags" % [operation, state_name, skull.interruptions, skull.tags]

func _plinth(at: Vector3, dimensions: Vector3) -> void:
	var surface := MeshInstance3D.new(); var mesh := BoxMesh.new()
	mesh.size = dimensions; surface.mesh = mesh; surface.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.81, 0.80, 0.76); material.roughness = 0.8
	surface.material_override = material; add_child(surface)
	var body := StaticBody3D.new(); body.collision_layer = 1; body.collision_mask = 0
	var collision := CollisionShape3D.new(); var shape := BoxShape3D.new()
	shape.size = dimensions; collision.shape = shape
	surface.add_child(body); body.add_child(collision)

func _label(text: String, at: Vector3, font_size: int, pixel_size: float) -> Label3D:
	var label := Label3D.new()
	label.text = text; label.position = at; label.font_size = font_size; label.pixel_size = pixel_size
	label.modulate = Color(0.9, 0.89, 0.86); label.outline_size = 5
	add_child(label)
	return label

static func mount(_museum: Node3D, hall: Node3D) -> Node3D:
	var trial := load("res://commons/hazards/catalyst_counterpart/counterpart_trial.gd").new() as Node3D
	# Locate the opening cube in the actual placed hall, not an assumed world origin.
	var reference: Node3D
	for node in hall.find_children("*", "Node3D", true, false):
		if node.get_script() != null and str(node.get_script().resource_path).ends_with("/pick_up_cube.gd"):
			if reference == null or node.global_position.z < reference.global_position.z: reference = node
	if reference == null:
		push_error("Counterpart trial needs Trans_Pre's existing opening cube")
		trial.free()
		return null
	var at := reference.global_position + Vector3(1.7, 0, 1.5)
	var ray := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 3, at + Vector3.DOWN * 5, 1)
	var floor_hit := hall.get_world_3d().direct_space_state.intersect_ray(ray)
	if floor_hit.is_empty():
		push_error("Counterpart trial needs a supported floor")
		trial.free()
		return null
	at.y = floor_hit.position.y
	trial.position = hall.to_local(at)
	trial.rotation.y = PI # Controls face the entry; the counterpart waits beyond them.
	hall.add_child(trial)
	return trial
