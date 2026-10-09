extends Node3D
## Supplied camera and walking apparatus. Change the score in artifacts/score.gd.
var room: Node3D
var camera: Camera3D
var player: CharacterBody3D
var eye: Camera3D
var panel: CanvasLayer
var caption: Label
var sample: Label
var seed_control: SpinBox
var row_control: HSlider
var walking := false
var yaw := 0.0
var pitch := 0.0

func _ready() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.009,0.011,0.015)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7,0.75,0.82)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	world.environment = env
	add_child(world)
	room = load("res://artifacts/signal_room.tscn").instantiate()
	add_child(room)
	for z in [-6,3,11]:
		var light := OmniLight3D.new()
		light.position = Vector3(0,5.5,z)
		light.light_color = Color(0.72,0.79,0.9)
		light.light_energy = 0.8
		light.omni_range = 11
		add_child(light)
	camera = Camera3D.new()
	camera.fov = 77
	add_child(camera)
	camera.current = true
	view(0)
	make_player()
	make_ui()
	room.state_changed.connect(update_readout)
	update_readout(room.evidence)

func view(which: int) -> void:
	var positions := [Vector3(0,1.7,10.4),Vector3(4.9,1.7,6.4),Vector3(-3,1.8,-6),Vector3(-4.47,1.3,12.55)]
	var targets := [Vector3(0,2.6,-9),Vector3(-1,1.7,-8),Vector3(1.4,2.9,6),Vector3(-4.47,1.0,11.085)]
	camera.look_at_from_position(positions[which],targets[which])

func make_player() -> void:
	player = CharacterBody3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.75
	var shape := CollisionShape3D.new()
	shape.shape = capsule
	shape.position.y = 0.875
	player.add_child(shape)
	add_child(player)
	eye = Camera3D.new()
	eye.position.y = 1.65
	eye.fov = 77
	player.add_child(eye)

func make_ui() -> void:
	panel = CanvasLayer.new()
	add_child(panel)
	var base := PanelContainer.new()
	base.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	base.offset_left = 28
	base.offset_right = -28
	base.offset_top = -205
	base.offset_bottom = -22
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.026,0.031,0.04,0.96)
	style.content_margin_left = 23
	style.content_margin_right = 23
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	base.add_theme_stylebox_override("panel",style)
	panel.add_child(base)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",8)
	base.add_child(box)
	var title := Label.new()
	title.text = "DIFFERENT NEIGHBOURS     /     4096 addresses, one retained array"
	title.add_theme_font_size_override("font_size",24)
	box.add_child(title)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation",10)
	box.add_child(buttons)
	for i in 3:
		button(buttons,room.Score.NAMES[i],select.bind(i))
	button(buttons,"New seed",new_seed)
	seed_control = SpinBox.new()
	seed_control.min_value = 0
	seed_control.max_value = 999999
	seed_control.value = room.seed_value
	seed_control.value_changed.connect(func(value: float): room.set_pattern(room.mode,int(value)))
	buttons.add_child(seed_control)
	button(buttons,"Step one row",room.step_rows)
	button(buttons,"Reset",reset)
	button(buttons,"Walk inside",start_walk)
	caption = Label.new()
	box.add_child(caption)
	var inspection := HBoxContainer.new()
	box.add_child(inspection)
	sample = Label.new()
	sample.custom_minimum_size.x = 410
	inspection.add_child(sample)
	row_control = HSlider.new()
	row_control.max_value = 252
	row_control.step = 1
	row_control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_control.value_changed.connect(func(row: float): room.inspect_rows(int(row)))
	inspection.add_child(row_control)
	var hint := Label.new()
	hint.text = "1 / 2 / 3 change the rule · V changes view · H hides controls · Walk: WASD + mouse; Esc returns · No automatic animation"
	hint.add_theme_font_size_override("font_size",15)
	box.add_child(hint)

func button(parent: Node, text_value: String, action: Callable) -> void:
	var node := Button.new()
	node.text = text_value
	node.pressed.connect(action)
	parent.add_child(node)

func update_readout(state: Dictionary) -> void:
	caption.text = "%s · seed %d · 2048 black / 2048 white · H = 1 bit per symbol · %d / 7920 neighbour pairs differ · offset %d" % [state.mode,state.seed,state.neighbour_changes,state.offset]
	var lines := PackedStringArray()
	for r in 4:
		var line := ""
		for c in 4:
			line += str(room.display_values[(room.sample_row+r)*16+c+6])
		lines.append(line)
	sample.text = "4 × 4 / rows %03d–%03d / cols 06–09:   %s" % [room.sample_row,room.sample_row+3,"  ".join(lines)]

func select(which: int) -> void:
	room.set_pattern(which,room.seed_value)

func new_seed() -> void:
	seed_control.value = int(seed_control.value)+1

func reset() -> void:
	seed_control.set_value_no_signal(2026)
	row_control.set_value_no_signal(0)
	room.sample_row = 0
	room.set_pattern(0,2026)

func start_walk() -> void:
	walking = true
	player.position = Vector3(0,0.06,10.5)
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
	camera.current = true
	panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	if not walking:
		return
	var direction := Vector3(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),0,float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
	direction = direction.rotated(Vector3.UP,yaw).normalized()*3.2
	player.velocity.x = direction.x
	player.velocity.z = direction.z
	player.velocity.y -= 9.8*delta
	player.move_and_slide()
	if player.position.y < -3:
		player.position = Vector3(0,0.06,10.5)
		player.velocity = Vector3.ZERO

var current_view := 0
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE: stop_walk()
			KEY_H: panel.visible = not panel.visible
			KEY_1: select(0)
			KEY_2: select(1)
			KEY_3: select(2)
			KEY_V:
				current_view = (current_view+1)%4
				view(current_view)
	if event is InputEventMouseMotion and walking:
		yaw -= event.relative.x*0.0025
		pitch = clampf(pitch-event.relative.y*0.0025,-1.25,1.25)
		player.rotation.y = yaw
		eye.rotation.x = pitch
