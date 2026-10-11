extends Node3D
## Shared in-world seed console. The artwork owns generation; this owns input.
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")
const FIRST_SEED := 1
const LAST_SEED := 100
var artwork: Node3D
var chosen_seed: int = 42
var readout: Label3D
var slider: Node3D
var panel: Node3D
var _pending: int = -1
var _quiet_time: float = 0.0
var _choices := RandomNumberGenerator.new()

static func install(target: Node3D, title: String, offset: Vector3, facing: float) -> void:
	if target.has_node("ArtSeedControls"):
		return
	var controls = load("res://algorithms/randomness/art_seed_controls.gd").new()
	controls.name = "ArtSeedControls"
	controls.artwork = target
	target.add_child(controls)
	controls.build(title, offset, facing)

func build(title: String, offset: Vector3, facing: float) -> void:
	# Wait for museum scale/grounding. Keep the console hand-sized on scaled art.
	await get_tree().process_frame
	await get_tree().process_frame
	global_transform = Transform3D(artwork.global_basis.orthonormalized(), artwork.global_position)
	global_position += global_basis * offset
	rotate_y(facing)
	_choices.randomize()
	panel = Rack.create_panel(title, [
		[{"type":"slider_h", "label":"SEED 1 - 100"}],
		[{"type":"button", "shape":"rect", "label":"PREVIOUS"}, {"type":"button", "shape":"rect", "label":"REPLAY"},
		 {"type":"button", "shape":"rect", "label":"NEXT"}, {"type":"button", "shape":"rect", "label":"NEW SEED"}],
	])
	panel.scale = Vector3.ONE * (0.84 / float(panel.get_meta("panel_w")))
	panel.position.y = 1.13
	_unshade(panel)
	add_child(panel)
	_box(Vector3(0, 0.49, -0.13), Vector3(0.09, 0.98, 0.09))
	_box(Vector3(0, 0.025, 0), Vector3(0.48, 0.05, 0.38))
	_box(Vector3(0, 1.55, 0), Vector3(0.84, 0.20, 0.035))
	readout = Label3D.new()
	readout.position = Vector3(0, 1.55, 0.024)
	readout.font_size = 64
	readout.pixel_size = 0.0012
	readout.no_depth_test = false
	readout.outline_size = 0
	readout.modulate = Color(0.95, 0.94, 0.90)
	add_child(readout)
	slider = panel.get_node("Param_0")
	var names: Array = []
	for value in range(FIRST_SEED, LAST_SEED + 1): names.append(str(value))
	slider.set_choices(names)
	slider.slider_moved.connect(_on_slider)
	for i in range(4):
		var area = panel.get_node("Btn_%d/InteractableAreaButton" % i)
		area.button_pressed.connect(func(_button): _press(i))
	show_seed(artwork.get_generation_seed())

func show_seed(value: int) -> void:
	chosen_seed = value
	if is_instance_valid(readout):
		readout.text = "SEED %03d" % value
		slider.set_normalized_value(float(value - FIRST_SEED) / (LAST_SEED - FIRST_SEED))

func _on_slider(_value) -> void:
	_pending = roundi(slider.get_normalized_value() * (LAST_SEED - FIRST_SEED)) + FIRST_SEED
	_quiet_time = 0.25
	readout.text = "CHOOSE %03d" % _pending

func _process(delta: float) -> void:
	if _pending < FIRST_SEED: return
	_quiet_time -= delta
	if _quiet_time <= 0.0:
		var value := _pending
		_pending = -1
		if value != chosen_seed: artwork.set_generation_seed(value)
		else: show_seed(chosen_seed)

func _press(index: int) -> void:
	_pending = -1
	var value := chosen_seed
	match index:
		0: value = maxi(FIRST_SEED, chosen_seed - 1)
		2: value = mini(LAST_SEED, chosen_seed + 1)
		3:
			# Choose a different seed without advancing the artwork's random stream.
			value = _choices.randi_range(FIRST_SEED, LAST_SEED - 1)
			if value >= chosen_seed: value += 1
	if index == 1 or value != chosen_seed: artwork.set_generation_seed(value)
	else: show_seed(chosen_seed)

func _box(at: Vector3, size: Vector3) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = at
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.055, 0.06, 0.065)
	mesh.material_override = mat
	add_child(mesh)

func _unshade(node: Node) -> void:
	# Local copies preserve button materials and their pressed-state colours.
	if node is Label3D:
		node.outline_size = 0
	if node is MeshInstance3D:
		if node.material_override is StandardMaterial3D:
			node.material_override = node.material_override.duplicate()
			node.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		elif node.mesh:
			for i in range(node.mesh.get_surface_count()):
				var mat = node.get_active_material(i)
				if mat is StandardMaterial3D:
					mat = mat.duplicate()
					mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
					node.set_surface_override_material(i, mat)
	for child in node.get_children(): _unshade(child)
