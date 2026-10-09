extends Node3D
## Supplied desktop room and ordinary walking capsule. No XR or suspension physics.
const Build = preload("res://commons/artifacts/reference_studies/build.gd")
const Sculpture = preload("res://commons/artifacts/suspension_passage/suspension_passage.gd")
var artifact: Node3D
var shell: Node3D
var camera: Camera3D
var player: CharacterBody3D
var eye: Camera3D
var panel: CanvasLayer
var caption: Label
var cell_buttons: Array[Button] = []
var rule_buttons: Array[Button] = []
var body_button: Button
var body_width := 0.56
var selected := -1
var walking := false
var orbiting := false
var yaw := 0.0
var pitch := 0.0
var orbit_target := Vector3(0,2.15,0)

func _ready() -> void:
	make_room()
	artifact = Sculpture.new()
	add_child(artifact)
	camera = Camera3D.new()
	camera.fov = 59
	add_child(camera)
	camera.current = true
	set_view(0)
	make_player()
	make_ui()
	update_ui()

func make_room() -> void:
	shell = Build.new()
	add_child(shell)
	var walls: StandardMaterial3D = shell.material(Color(0.85,0.83,0.79))
	var floor_mat: StandardMaterial3D = shell.material(Color(0.43,0.425,0.41),0.88)
	shell.box(Vector3(0,-0.125,0),Vector3(12,0.25,14),floor_mat,true)
	shell.box(Vector3(0,3,-7),Vector3(12,6,0.2),walls,true)
	shell.box(Vector3(-6,3,0),Vector3(0.2,6,14),walls,true)
	shell.box(Vector3(6,3,0),Vector3(0.2,6,14),walls,true)
	shell.box(Vector3(0,3,7),Vector3(12,6,0.2),walls,true)
	shell.box(Vector3(0,6.1,0),Vector3(12,0.15,14),walls)
	for x in [-3.9,0.0,3.9]:
		shell.box(Vector3(x,6.0,0),Vector3(0.12,0.025,11),shell.emissive(Color(1,0.93,0.84),1.2))
	# The studio shell receives the supplied light; it does not occlude it.
	for child in shell.get_children():
		if child is MeshInstance3D:
			child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var ink: StandardMaterial3D = shell.material(Color(0.22,0.20,0.20))
	for side in [-1,1]:
		# Four small corner marks show the sampled field, not a confinement wall.
		for end in [-1,1]:
			shell.box(Vector3(side*2.95,0.004,end*2.80),Vector3(0.016,0.005,0.30),ink)
			shell.box(Vector3(side*2.80,0.004,end*2.95),Vector3(0.30,0.005,0.016),ink)
	shell.plaque("SEVEN PLACES FOR A PASSAGE",Vector3(0,3.85,-6.85))
	shell.plaque("49 fragments   /   7 raised",Vector3(0,3.52,-6.85))
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.30,0.35,0.42)
	sky_material.sky_horizon_color = Color(0.95,0.91,0.86)
	sky_material.ground_bottom_color = Color(0.14,0.13,0.12)
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.90,0.91,0.95)
	environment.ambient_light_energy = 0.55
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-58,-28,0)
	sun.light_energy = 1.0
	sun.light_color = Color(1,0.94,0.85)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 30
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-32,125,0)
	fill.light_color = Color(0.79,0.84,1.0)
	fill.light_energy = 0.3
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
	player.position = Vector3(0,0.04,4.0)
	eye = Camera3D.new()
	eye.position.y = 1.62
	eye.fov = 70
	player.add_child(eye)

func make_ui() -> void:
	panel = CanvasLayer.new()
	add_child(panel)
	var base := PanelContainer.new()
	base.position = Vector2(20,780)
	base.size = Vector2(1180,190)
	panel.add_child(base)
	var margin := MarginContainer.new()
	for key in ["margin_left","margin_right","margin_top","margin_bottom"]:
		margin.add_theme_constant_override(key,16)
	base.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",10)
	margin.add_child(column)
	var title := Label.new()
	title.text = "SEVEN PLACES FOR A PASSAGE  /  after Mona Hatoum"
	title.add_theme_font_size_override("font_size",23)
	column.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",10)
	column.add_child(row)
	for i in 2:
		var button := Button.new()
		button.text = ["One passage","Separate pockets"][i]
		button.custom_minimum_size = Vector2(155,38)
		button.pressed.connect(select_arrangement.bind(i))
		row.add_child(button)
		rule_buttons.append(button)
	for item in [["Walk inside",start_walk],["View from entry",set_view.bind(1)],["Reset",select_arrangement.bind(0)]]:
		var button := Button.new()
		button.text = item[0]
		button.pressed.connect(item[1])
		row.add_child(button)
	body_button = Button.new()
	body_button.pressed.connect(toggle_body)
	row.add_child(body_button)
	caption = Label.new()
	column.add_child(caption)
	var hint := Label.new()
	hint.text = "Right-drag: orbit · Wheel: closer · V: view · H: controls · Walk: WASD + mouse · Esc: return"
	column.add_child(hint)
	var grid_panel := PanelContainer.new()
	grid_panel.position = Vector2(1250,630)
	panel.add_child(grid_panel)
	var grid_column := VBoxContainer.new()
	grid_panel.add_child(grid_column)
	var label := Label.new()
	label.text = "Rose = raised / click two to swap\nTop: far side · Bottom: entry"
	grid_column.add_child(label)
	var grid := GridContainer.new()
	grid.columns = 7
	grid_column.add_child(grid)
	for z in 7:
		for x in 7:
			var button := Button.new()
			button.text = "%d,%d" % [x,z]
			button.custom_minimum_size = Vector2(39,37)
			button.pressed.connect(choose_cell.bind(z*7+x))
			grid.add_child(button)
			cell_buttons.append(button)

func update_ui() -> void:
	var titles := ["One passage","Separate pockets","Your arrangement"]
	caption.text = "%s · %d fragments / %d raised · body: %.2f m wide, 1.75 m tall" % [titles[artifact.arrangement],artifact.evidence.fragments,artifact.evidence.raised,body_width]
	body_button.text = "Body: %.2f m" % body_width
	if selected >= 0:
		caption.text += " · choose a cell at the other height"
	for i in cell_buttons.size():
		cell_buttons[i].modulate = Color(1,0.38,0.58) if artifact.lifted_cells[i] else Color(0.73,0.73,0.73)
		if i == selected:
			cell_buttons[i].modulate = Color(1,0.84,0.45)

func select_arrangement(which: int) -> void:
	stop_walk()
	selected = -1
	artifact.apply_rule(which)
	update_ui()

func toggle_body() -> void:
	stop_walk()
	body_width = 1.32 if body_width < 1.0 else 0.56
	(player.get_child(0).shape as CapsuleShape3D).radius = body_width * 0.5
	# Move to the clear arrival area before changing the walking volume.
	player.position = Vector3(0,0.04,4.0)
	player.velocity = Vector3.ZERO
	update_ui()

func choose_cell(index: int) -> void:
	stop_walk()
	if selected < 0:
		selected = index
	elif selected == index:
		selected = -1
	elif artifact.swap_cells(selected,index):
		selected = -1
	else:
		selected = index
	update_ui()

func set_view(which: int) -> void:
	stop_walk()
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	if which == 0:
		camera.look_at_from_position(Vector3(5.25,3.35,6.65),orbit_target)
	else:
		camera.look_at_from_position(Vector3(0,1.64,4.3),Vector3(0,1.65,0))

func start_walk() -> void:
	walking = true
	player.position = Vector3(0,0.04,4.0)
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
	var motion := Vector3(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),0,float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
	motion = motion.rotated(Vector3.UP,yaw).normalized()*2.2
	player.velocity.x = motion.x
	player.velocity.z = motion.z
	player.velocity.y -= 9.8*delta
	player.move_and_slide()
	if player.position.y < -3:
		player.position = Vector3(0,0.04,4.0)
		player.velocity = Vector3.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			stop_walk()
		if event.keycode == KEY_H:
			panel.visible = not panel.visible
		if event.keycode == KEY_V:
			set_view(1 if camera.position.x > 0.1 else 0)
	if event is InputEventMouseMotion:
		if walking:
			yaw -= event.relative.x*0.0025
			pitch = clampf(pitch-event.relative.y*0.0025,-1.25,1.25)
			player.rotation.y = yaw
			eye.rotation.x = pitch
		elif orbiting:
			var offset := camera.position-orbit_target
			offset = offset.rotated(Vector3.UP,-event.relative.x*0.005)
			offset.y = clampf(offset.y+event.relative.y*0.014,-1.0,3.7)
			camera.look_at_from_position(orbit_target+offset,orbit_target)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			orbiting = event.pressed
		if not walking and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			var offset := camera.position-orbit_target
			offset *= 0.94 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.06
			if offset.length() > 1.3 and offset.length() < 9:
				camera.look_at_from_position(orbit_target+offset,orbit_target)
