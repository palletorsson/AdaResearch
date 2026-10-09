extends Node3D
## Supplied apparatus. The learner changes the score in artifacts/*.gd.
const IDS := ["suspension", "passage", "landscape", "pattern_garden", "plural_body"]
const TITLES := ["A place still held", "Who fits through?", "A world from a cone", "The pattern crosses over", "A body in the plural"]
const CHAPTERS := ["Arrays / Tutorial 3D · after Mona Hatoum", "Transformation / Body · prompted by Mirosław Bałka", "Colour / composition · prompted by Alex McLeod", "Shader Patterns · prompted by Claudia Hart", "Queer Rubber / Pink Extravaganza · prompted by Peaches & Pussykrew"]
const RULES := ["Same 75 addresses. Change the fragments.", "The viewer's body stays 0.56 m wide. Change the opening.", "Same 48 sites, three cones at each. Change their height.", "Same room and flowers. Move the shared pattern through them.", "Same six arms, three heads. Change how far they unfold."]
const KNOBS := ["Fragment variation", "Opening width", "Tree height", "Pattern phase", "Unfold"]
const DEFAULTS := [1.0, 0.72, 0.88, 0.17, 0.9]
const VIEWS := [Vector3(4.6,2.65,6.4),Vector3(3.6,2.0,6.3),Vector3(4.8,3.65,6.7),Vector3(3.8,2.55,6.3),Vector3(3.4,2.5,6.0)]
var mode := 0
var artifact: Node3D
var shell: Node3D
var camera: Camera3D
var player: CharacterBody3D
var eye: Camera3D
var panel: CanvasLayer
var caption: Label
var title: Label
var chapter: Label
var slider: HSlider
var knob_label: Label
var animation_button: Button
var environment: Environment
var walking := false
var orbiting := false
var playing := false
var clock := 0.0
var yaw := 0.0
var pitch := -0.1
var orbit_target := Vector3(0,1.7,-0.6)

func _ready() -> void:
	make_environment()
	camera = Camera3D.new()
	camera.fov = 63
	add_child(camera)
	camera.current = true
	make_player()
	make_ui()
	select_room(0)

func make_environment() -> void:
	var world := WorldEnvironment.new()
	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.background_color = Color(0.78,0.78,0.76)
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.24,0.31,0.42)
	sky_material.sky_horizon_color = Color(0.96,0.91,0.87)
	sky_material.ground_bottom_color = Color(0.035,0.028,0.045)
	sky_material.ground_horizon_color = Color(0.83,0.73,0.80)
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.92,0.90,0.94)
	environment.ambient_light_energy = 0.50
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52,-25,0)
	sun.light_color = Color(1,0.94,0.86)
	sun.light_energy = 1.05
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 30
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25,135,0)
	fill.light_color = Color(0.70,0.77,1)
	fill.light_energy = 0.32
	add_child(fill)

func make_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Visitor"
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.75
	shape.shape = capsule
	shape.position.y = 0.875
	player.add_child(shape)
	add_child(player)
	eye = Camera3D.new()
	eye.position.y = 1.62
	eye.fov = 73
	player.add_child(eye)

func make_ui() -> void:
	panel = CanvasLayer.new()
	add_child(panel)
	var base := PanelContainer.new()
	base.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	base.offset_left = 22
	base.offset_right = -22
	base.offset_top = -220
	base.offset_bottom = -18
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025,0.021,0.032,0.94)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 14
	style.content_margin_bottom = 12
	base.add_theme_stylebox_override("panel",style)
	panel.add_child(base)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",5)
	base.add_child(column)
	var navigation := HBoxContainer.new()
	navigation.add_theme_constant_override("separation",12)
	column.add_child(navigation)
	for i in IDS.size():
		var button := Button.new()
		button.text = "%d  %s" % [i+1,["Suspension","Passage","Landscape","Pattern garden","Plural body"][i]]
		button.pressed.connect(select_room.bind(i))
		navigation.add_child(button)
	title = Label.new()
	title.add_theme_font_size_override("font_size",25)
	column.add_child(title)
	chapter = Label.new()
	chapter.add_theme_font_size_override("font_size",15)
	chapter.modulate = Color(0.95,0.68,0.8)
	column.add_child(chapter)
	caption = Label.new()
	caption.add_theme_font_size_override("font_size",17)
	column.add_child(caption)
	var row := HBoxContainer.new()
	column.add_child(row)
	knob_label = Label.new()
	knob_label.custom_minimum_size.x = 245
	row.add_child(knob_label)
	slider = HSlider.new()
	slider.min_value = 0
	slider.max_value = 1
	slider.step = 0.025
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(change_amount)
	row.add_child(slider)
	var reset := Button.new()
	reset.text = "Reset"
	reset.pressed.connect(select_room.bind(-1))
	row.add_child(reset)
	var walk := Button.new()
	walk.text = "Walk inside"
	walk.pressed.connect(start_walk)
	row.add_child(walk)
	animation_button = Button.new()
	animation_button.text = "Let pattern drift"
	animation_button.pressed.connect(toggle_animation)
	row.add_child(animation_button)
	var hint := Label.new()
	hint.text = "Right-drag to look around · Wheel to move closer · Walk: WASD + mouse, Esc to return · H hides controls"
	hint.add_theme_font_size_override("font_size",14)
	column.add_child(hint)

func select_room(which: int) -> void:
	stop_walk()
	if which >= 0:
		mode = which
	if is_instance_valid(artifact):
		remove_child(artifact)
		artifact.queue_free()
	if is_instance_valid(shell):
		remove_child(shell)
		shell.queue_free()
	shell = load("res://artifacts/build.gd").new()
	add_child(shell)
	var floor_colour := Color(0.40,0.39,0.365)
	var wall_colour := Color(0.81,0.79,0.735)
	if mode == 4:
		floor_colour = Color(0.05,0.018,0.045)
		wall_colour = Color(0.12,0.048,0.11)
	shell.box(Vector3(0,-0.13,0.9),Vector3(12,0.25,12),shell.material(floor_colour,0.73),true)
	shell.box(Vector3(0,2.75,-5),Vector3(12,5.5,0.24),shell.material(wall_colour),true)
	shell.box(Vector3(-6,2.75,0.9),Vector3(0.24,5.5,12),shell.material(wall_colour),true)
	shell.box(Vector3(6,2.75,0.9),Vector3(0.24,5.5,12),shell.material(wall_colour),true)
	# A high roof with open strip lights; cameras remain inside the room envelope.
	shell.box(Vector3(0,5.65,0.9),Vector3(12,0.12,12),shell.material(wall_colour),true)
	for x in [-3.8,0.0,3.8]:
		shell.box(Vector3(x,5.57,0),Vector3(0.18,0.04,8),shell.emissive(Color(1,0.93,0.86),1.2))
	# Supplied studio illumination: the shell receives light but does not block
	# the directional sources. Artwork shadows remain enabled.
	for child in shell.get_children():
		if child is MeshInstance3D:
			child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if mode == 4:
		for x in [-2.6,2.6]:
			shell.box(Vector3(x,2.75,-4.82),Vector3(0.075,4.7,0.08),shell.emissive(Color(1,0.16,0.57),2))
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(0,3.5,2.5)
		lamp.light_color = Color(1,0.36,0.66)
		lamp.light_energy = 2
		lamp.omni_range = 8
		shell.add_child(lamp)
	artifact = load("res://artifacts/"+IDS[mode]+".tscn").instantiate()
	artifact.amount = DEFAULTS[mode]
	add_child(artifact)
	camera.look_at_from_position(VIEWS[mode], orbit_target)
	slider.set_value_no_signal(DEFAULTS[mode])
	title.text = TITLES[mode]
	chapter.text = CHAPTERS[mode]
	caption.text = RULES[mode]
	clock = 0
	playing = false
	animation_button.visible = mode == 3
	animation_button.text = "Let pattern drift"
	update_knob()

func update_knob() -> void:
	if mode == 1:
		knob_label.text = "Opening: %.2f m / body: 0.56 m" % artifact.evidence.opening_width
	else:
		knob_label.text = "%s: %.2f" % [KNOBS[mode],artifact.amount]

func change_amount(value: float) -> void:
	artifact.set_amount(value)
	artifact.set_clock(clock)
	update_knob()

func toggle_animation() -> void:
	playing = not playing
	animation_button.text = "Pause pattern" if playing else "Let pattern drift"

func start_walk() -> void:
	walking = true
	player.position = Vector3(0,0.05,4.8)
	player.velocity = Vector3.ZERO
	yaw = 0
	pitch = 0
	player.rotation = Vector3.ZERO
	eye.rotation = Vector3.ZERO
	eye.current = true
	panel.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func stop_walk() -> void:
	walking = false
	if is_instance_valid(camera):
		camera.current = true
	if is_instance_valid(panel):
		panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	if not walking:
		return
	var movement := Vector3(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),0,float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
	movement = movement.rotated(Vector3.UP,yaw).normalized()*2.6
	player.velocity.x = movement.x
	player.velocity.z = movement.z
	player.velocity.y -= 9.8*delta
	player.move_and_slide()
	if player.position.y < -3:
		player.position = Vector3(0,0.05,4.8)
		player.velocity = Vector3.ZERO

func _process(delta: float) -> void:
	if playing and mode == 3:
		clock += delta
		artifact.set_clock(clock)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			stop_walk()
		if event.keycode == KEY_H:
			panel.visible = not panel.visible
	if event is InputEventMouseMotion:
		if walking:
			yaw -= event.relative.x*0.0025
			pitch = clampf(pitch-event.relative.y*0.0025,-1.25,1.25)
			player.rotation.y = yaw
			eye.rotation.x = pitch
		elif orbiting:
			var offset := camera.position-orbit_target
			offset = offset.rotated(Vector3.UP,-event.relative.x*0.005)
			offset.y = clampf(offset.y+event.relative.y*0.014,-0.5,3.5)
			camera.look_at_from_position(orbit_target+offset,orbit_target)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			orbiting = event.pressed
		if not walking and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			var offset := camera.position-orbit_target
			offset *= 0.94 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.06
			if offset.length() > 1.3 and offset.length() < 12:
				camera.look_at_from_position(orbit_target+offset,orbit_target)
