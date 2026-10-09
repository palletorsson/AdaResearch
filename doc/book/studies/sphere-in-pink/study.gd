extends Node3D
## An Ada lighting study after LeWitt. Our five-switch score has 32 states,
## including all-off. It is not a transcription of the original 28-print work.
const PINK := Color(1.0, 0.50, 0.70)
const LAMP_ENERGY := 0.6
const PALE := Color(0.78, 0.78, 0.78)
const LIGHT_NAMES := ["Top", "Left", "Right", "Front", "Back"]
const LIGHT_POSITIONS := [Vector3(0, 3.8, 0), Vector3(-3, 1, 0),
	Vector3(3, 1, 0), Vector3(0, 1, 3), Vector3(0, 1, -3)]
var lights: Array[SpotLight3D] = []
var camera: Camera3D
var sphere: MeshInstance3D
var sphere_material: StandardMaterial3D
var switches: Array[CheckButton] = []
var material_button: Button
var panel: CanvasLayer
var caption: Label
var mask := 1
var pink_material := false
var sequence_index := 0
var states: Array[int] = []
var playing := false
var clock := 0.0
var orbiting := false
var yaw := 0.0
var pitch := 0.18
var distance := 4.5

func _ready() -> void:
	# Gray-code order changes exactly one switch between neighboring views.
	for i in 32:
		states.append(i ^ (i >> 1))
	build_room()
	make_controls()
	set_lights(1)
	set_process(false)

func build_room() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.035, 0.032, 0.036)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color.WHITE
	environment.ambient_light_energy = 0.018
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = environment
	add_child(world)
	box(Vector3(0, -0.055, 0), Vector3(8, 0.1, 8))
	box(Vector3(0, 2, -4), Vector3(8, 4, 0.1))
	sphere = MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.72
	mesh.height = 1.44
	mesh.radial_segments = 96
	mesh.rings = 48
	sphere.mesh = mesh
	sphere.position = Vector3(0, 0.72, 0)
	sphere_material = StandardMaterial3D.new()
	sphere_material.albedo_color = PALE
	sphere_material.roughness = 0.88
	sphere_material.metallic_specular = 0.18
	# This isolated convex sphere has no external occluder. Its normal supplies
	# the terminator; disable self-shadow-map artifacts while it still casts on the floor.
	sphere_material.disable_receive_shadows = true
	sphere.material_override = sphere_material
	add_child(sphere)
	for i in LIGHT_NAMES.size():
		var lamp := SpotLight3D.new()
		lamp.name = LIGHT_NAMES[i]
		lamp.light_color = PINK
		lamp.light_energy = LAMP_ENERGY
		lamp.spot_range = 7.0
		lamp.spot_angle = 64
		lamp.spot_attenuation = 0.45
		lamp.shadow_enabled = true
		add_child(lamp)
		lamp.position = LIGHT_POSITIONS[i]
		lamp.look_at(sphere.position, Vector3.FORWARD if i == 0 else Vector3.UP)
		lights.append(lamp)
	camera = Camera3D.new()
	camera.fov = 39
	add_child(camera)
	camera.current = true
	update_camera()

func box(at: Vector3, size: Vector3) -> void:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.56, 0.56, 0.56)
	material.roughness = 1
	material.metallic_specular = 0.0
	node.material_override = material
	add_child(node)

func set_lights(value: int) -> void:
	mask = clampi(value, 0, 31)
	for i in lights.size():
		lights[i].visible = (mask & (1 << i)) != 0
		if i < switches.size():
			switches[i].set_pressed_no_signal(lights[i].visible)
	sequence_index = states.find(mask)
	update_caption()

func active_names() -> String:
	var names := PackedStringArray()
	for i in lights.size():
		if lights[i].visible:
			names.append(LIGHT_NAMES[i])
	return "All five lamps off — faint fixed ambient remains" if names.is_empty() else " + ".join(names)

func switch_lamp(_pressed: bool, index: int) -> void:
	set_lights(mask ^ (1 << index))

func next_state() -> void:
	set_lights(states[(sequence_index + 1) % 32])

func toggle_play(button: Button) -> void:
	playing = not playing
	clock = 0.0
	button.text = "Pause" if playing else "One switch at a time"
	set_process(playing)

func set_pink_material(enabled: bool) -> void:
	pink_material = enabled
	sphere_material.albedo_color = PINK if enabled else PALE
	for lamp in lights:
		lamp.light_color = Color.WHITE if enabled else PINK
	if is_instance_valid(material_button):
		material_button.text = "Return to pink light" if enabled else "Compare: pink material / white light"
	update_caption()

func update_caption() -> void:
	if is_instance_valid(caption):
		caption.text = active_names() + "\n" + ("Pink material / white light" if pink_material else "Pale material / pink light")

func make_controls() -> void:
	panel = CanvasLayer.new()
	add_child(panel)
	var base := PanelContainer.new()
	base.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	base.offset_left = 25
	base.offset_right = -25
	base.offset_top = -166
	base.offset_bottom = -18
	panel.add_child(base)
	var stack := VBoxContainer.new()
	base.add_child(stack)
	var row := HBoxContainer.new()
	stack.add_child(row)
	for i in lights.size():
		var toggle := CheckButton.new()
		toggle.text = LIGHT_NAMES[i]
		toggle.toggled.connect(switch_lamp.bind(i))
		row.add_child(toggle)
		switches.append(toggle)
	var actions := HBoxContainer.new()
	stack.add_child(actions)
	var play := Button.new()
	play.text = "One switch at a time"
	play.pressed.connect(toggle_play.bind(play))
	actions.add_child(play)
	var step := Button.new()
	step.text = "Next"
	step.pressed.connect(next_state)
	actions.add_child(step)
	material_button = Button.new()
	material_button.text = "Compare: pink material / white light"
	material_button.pressed.connect(func(): set_pink_material(not pink_material))
	actions.add_child(material_button)
	var reset := Button.new()
	reset.text = "Front view"
	reset.pressed.connect(func(): yaw = 0; pitch = 0.18; distance = 4.5; update_camera())
	actions.add_child(reset)
	caption = Label.new()
	caption.add_theme_font_size_override("font_size", 16)
	stack.add_child(caption)
	var hint := Label.new()
	hint.text = "Right-drag: look around   Wheel: distance   Same sphere, camera and lamp energy in every recorded view."
	hint.add_theme_font_size_override("font_size", 13)
	stack.add_child(hint)

func _process(delta: float) -> void:
	clock += delta
	if clock >= 2.5:
		clock = 0.0
		next_state()

func update_camera() -> void:
	var target := Vector3(0, 0.67, 0)
	var direction := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
	camera.look_at_from_position(target + direction * distance, target)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			orbiting = event.pressed
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			distance = clampf(distance + (-0.25 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 0.25), 2.3, 9)
			update_camera()
	if event is InputEventMouseMotion and orbiting:
		yaw -= event.relative.x * 0.006
		pitch = clampf(pitch + event.relative.y * 0.004, 0.04, 1.2)
		update_camera()
