extends Node3D
## A retained circle becomes a repeated coordinate lookup across a place.
## The chair's projection is supplied; no copied meshes are made by fract().
const G = preload("res://commons/artifacts/jacquard_weaver/weave_geometry.gd")
const SLIDER = preload("res://commons/interactables/physical_stepped_slider.gd")
const BUTTON = preload("res://commons/interactables/push_button.tscn")
const CHAIR = preload("res://commons/primitives/chair/chair_modern.tscn")
const SHADER = preload("./repeated_mask.gdshader")
var room_material: ShaderMaterial
var chair_material: ShaderMaterial
var square_material: ShaderMaterial
var chair: Node3D
var square: MeshInstance3D
var sliders: Dictionary = {}
var buttons: Dictionary = {}
var readout: Label3D
var chair_label: Label3D
var density := 1.0
var phase := 0.0
var chair_amount := 0.0
var attached := false

func _ready() -> void:
	var cream := G.material("e4d9c8")
	var dark := G.material("332930")
	room_material = ShaderMaterial.new(); room_material.shader = SHADER
	chair_material = room_material.duplicate()
	square_material = room_material.duplicate(); square_material.set_shader_parameter("use_uv", true)
	# Two patterned banks leave a calm, continuous walking strip in the middle.
	for side in [-1.0, 1.0]:
		G.box(self, Vector3(side * 3.65, .018, 0), Vector3(4.7, .025, 10.8), room_material)
		G.box(self, Vector3(side * 6.04, 2.2, 0), Vector3(.12, 4.4, 10.8), room_material, true)
		G.box(self, Vector3(side * 3.7, 2.2, -5.46), Vector3(4.6, 4.4, .12), room_material, true)
	G.box(self, Vector3(0, .018, 0), Vector3(2.55, .025, 10.8), cream)
	for z in [-4.8, 0.0, 4.8]:
		for x in [-6.2, 6.2]:
			G.box(self, Vector3(x, 2.35, z), Vector3(.22, 4.7, .28), cream, true)
		G.box(self, Vector3(0, 4.65, z), Vector3(12.6, .22, .28), cream)
	# Familiar cube and a real project prefab, keeping their ordinary silhouettes.
	G.box(self, Vector3(-3.1, .60, .2), Vector3(1.2, 1.2, 1.2), room_material, true).name = "CarriedCube"
	var column := MeshInstance3D.new(); column.name = "PatternColumn"
	var cylinder := CylinderMesh.new(); cylinder.top_radius = .50; cylinder.bottom_radius = .50; cylinder.height = 3.8
	column.mesh = cylinder; column.material_override = room_material; column.position = Vector3(-3.8, 1.9, -3.0); add_child(column)
	var body := StaticBody3D.new(); var shape := CollisionShape3D.new(); var c := CylinderShape3D.new(); c.radius = .5; c.height = 3.8
	shape.shape = c; body.add_child(shape); column.add_child(body)
	chair = CHAIR.instantiate(); chair.name = "PatternChair"; chair.scale = Vector3.ONE * 1.8; chair.rotation.y = PI; add_child(chair)
	for mesh in chair.find_children("*", "MeshInstance3D", true, false): mesh.material_override = chair_material
	# Rail makes the changed placement visible while leaving the surrounding pattern fixed.
	for z in [-1.35, -1.95]: G.box(self, Vector3(3.6, .025, z), Vector3(2.7, .03, .035), dark)
	chair_label = label("", Vector3(3.6, 1.85, -2.0), 24)
	# A flat UV receiver makes the core lookup inspectable before the supplied projections.
	G.box(self, Vector3(-3.55, 1.85, 4.4), Vector3(2.6, 2.6, .10), dark, true)
	square = MeshInstance3D.new(); square.name = "UVSquare"; var quad := QuadMesh.new(); quad.size = Vector2(2.45, 2.45)
	square.mesh = quad; square.material_override = square_material; square.position = Vector3(-3.55, 1.85, 4.46); add_child(square)
	label("THE SAME CIRCLE", Vector3(-3.55, 3.45, 4.46), 29)
	label("tile = fract(UV * 3 * density + shift)", Vector3(-3.55, .37, 4.46), 18)
	# All global controls are on one shallow, reachable console.
	G.box(self, Vector3(3.4, 1.0, 3.65), Vector3(3.35, .12, .65), cream, true)
	for x in [2.0, 4.8]: G.box(self, Vector3(x, .48, 3.65), Vector3(.12, .96, .45), dark, true)
	for i in range(3):
		var key: String = ["DENSITY", "SHIFT", "CHAIR"][i]
		var control = SLIDER.new(); control.name = key; control.continuous = true; control.param_name = key
		control.position = Vector3(2.25 + i * .45, 1.29, 3.85); add_child(control); sliders[key] = control
		control.value_changed.connect(func(v: float): set_control(key, v))
	for i in range(2):
		var key: String = ["ATTACH", "RESET"][i]
		var button = BUTTON.instantiate(); button.name = key; button.position = Vector3(3.8 + i * .55, 1.07, 3.73); add_child(button)
		button.get_node("InteractableAreaButton").button_pressed.connect(func(_b): act(key)); buttons[key] = button
		var text := label(key, button.position + Vector3(0, .012, .20), 12); text.rotation_degrees.x = -60
	readout = label("", Vector3(3.4, 1.85, 3.7), 20)
	label("Slide the pattern. Then move the chair.", Vector3(3.4, 2.37, 3.7), 23)
	label("02 / THE IMAGE LEAVES ITS FRAME", Vector3(0, 4.23, 4.94), 34)
	var back_title := label("A PATTERNED PLACE", Vector3(0, 4.23, -4.94), 34); back_title.rotation.y = PI
	for pos in [Vector3(-3, 4, 2), Vector3(3, 4, 2), Vector3(0, 4, -3)]:
		var light := OmniLight3D.new(); light.position = pos; light.omni_range = 9; light.light_energy = 1.5; light.light_color = Color("ffe7d2"); add_child(light)
	var console_light := OmniLight3D.new(); console_light.position = Vector3(3.3, 2.5, 5.1); console_light.omni_range = 3.5; console_light.light_energy = 2.0; add_child(console_light)
	set_meta("em_visibility_bounds", AABB(Vector3(-6.5, 0, -5.6), Vector3(13, 4.9, 11.2)))
	update_rule()

func label(text: String, at: Vector3, points: int) -> Label3D:
	var l := Label3D.new(); l.text = text; l.position = at; l.font_size = points * 2; l.pixel_size = .002
	l.modulate = Color("f5ebda"); l.outline_modulate = Color("332930"); l.outline_size = 7; l.double_sided = false; add_child(l); return l

func set_control(key: String, value: float) -> void:
	match key:
		"DENSITY": density = lerpf(.5, 2.0, clampf(value, 0, 1))
		"SHIFT": phase = clampf(value, 0, 1)
		"CHAIR": chair_amount = clampf(value, 0, 1)
	update_rule()

func act(key: String) -> void:
	if key == "ATTACH": attached = not attached
	elif key == "RESET": density = 1.0; phase = 0.0; chair_amount = 0.0; attached = false
	update_rule()

func update_rule() -> void:
	if chair == null: return
	chair.position = Vector3(2.6 + chair_amount * 2.0, 0, -1.65)
	for mat in [room_material, chair_material, square_material]:
		mat.set_shader_parameter("density", density); mat.set_shader_parameter("phase", phase)
		mat.set_shader_parameter("field_origin", global_position)
	chair_material.set_shader_parameter("attached", attached)
	# Retain metre units when attaching the projection to the enlarged prefab.
	var chair_frame := Transform3D(chair.global_basis.orthonormalized(), chair.global_position)
	chair_material.set_shader_parameter("receiver_inverse", chair_frame.affine_inverse())
	sliders.DENSITY.set_normalized_value(inverse_lerp(.5, 2.0, density)); sliders.SHIFT.set_normalized_value(phase); sliders.CHAIR.set_normalized_value(chair_amount)
	readout.text = "%.2f repeats / metre    shift %.2f\nChair pattern: %s" % [density, phase, "ON THE CHAIR" if attached else "IN THE ROOM"]
	chair_label.text = "The chair carries its pattern" if attached else "The chair crosses the pattern"

func apply_grid_config(_config: Dictionary) -> void:
	# Map instancing can set the final parent transform after _ready().
	call_deferred("update_rule")
