extends Node3D
## Independent study gallery. Fixed views compare arrangements; walking reads gaps.
var work: Node3D
var camera: Camera3D
var walker: CharacterBody3D
var eye: Camera3D
var overlay: CanvasLayer
var status: Label
var buttons: Dictionary = {}
var walking := false
var pitch := 0.0

func _ready() -> void:
	_build_gallery()
	work = load("res://commons/artifacts/colour_assembly/colour_assembly.tscn").instantiate()
	add_child(work)
	camera = Camera3D.new()
	add_child(camera)
	camera.fov = 76
	set_view(0)
	_build_walker()
	_build_controls()
	_update_status()

func _build_gallery() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("e5e2dc")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("e2e7f3")
	env.ambient_light_energy = 0.38
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-58,-35,0)
	sun.light_color = Color("ffecd3")
	sun.light_energy = 0.70
	sun.shadow_enabled = true
	sun.shadow_bias = 0.04
	sun.shadow_normal_bias = 0.3
	sun.directional_shadow_max_distance = 35
	add_child(sun)
	var white := _material(Color("f1efe9"),0.92)
	var floor_mat := _material(Color("b6b1aa"),0.72)
	_box("Floor",Vector3(14.6,0.20,18.2),Vector3(0,-0.10,0),floor_mat,true)
	_box("BackWall",Vector3(14.6,6.4,0.20),Vector3(0,3.2,-9.0),white,true)
	for side in [-1,1]:
		_box("SideWall",Vector3(0.20,6.4,18.2),Vector3(side*7.2,3.2,0),white,true)
		_box("EntrySide",Vector3(5.9,6.4,0.2),Vector3(side*4.25,3.2,9),white,true)
	_box("EntryLintel",Vector3(2.6,3.4,0.2),Vector3(0,4.7,9),white,true)
	# The roof has a long clerestory gap; neutral room light is fixed in all states.
	for side in [-1,1]:
		_box("Ceiling",Vector3(4.6,0.16,18.2),Vector3(side*4.95,6.32,0),white,true)
	var clerestory := StandardMaterial3D.new()
	clerestory.albedo_color = Color("eef4ff")
	clerestory.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var daylight := _box("HighDaylight",Vector3(5.3,0.05,18.2),Vector3(0,6.45,0),clerestory,false)
	daylight.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Narrow fixed rails give the suspended panels a support across the opening.
	var rail := _material(Color("c8cbd0"),0.45)
	for z in [-2.65,-1.325,0.0,1.325,2.65]:
		_box("CeilingRail",Vector3(10.3,0.08,0.08),Vector3(0,6.25,z),rail,false)
	var fill := OmniLight3D.new()
	fill.position = Vector3(0,5.6,1)
	fill.omni_range = 18
	fill.light_energy = 0.75
	add_child(fill)
	var seat := _material(Color("30383e"),0.70)
	for side in [-1,1]:
		_box("BenchSeat",Vector3(0.62,0.12,2.9),Vector3(side*5.95,0.44,0.2),seat,true)
		for end in [-1,1]:
			_box("BenchLeg",Vector3(0.48,0.38,0.10),Vector3(side*5.95,0.19,0.2+end*1.15),white,true)

func _build_walker() -> void:
	walker = CharacterBody3D.new()
	walker.name = "Visitor"
	walker.collision_layer = 2
	walker.collision_mask = 1
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.24
	shape.height = 1.75
	collider.shape = shape
	collider.position.y = 0.9
	walker.add_child(collider)
	eye = Camera3D.new()
	eye.position.y = 1.65
	eye.fov = 76
	walker.add_child(eye)
	add_child(walker)
	walker.position = Vector3(0,0.04,7.3)
	walker.set_physics_process(false)

func _build_controls() -> void:
	overlay = CanvasLayer.new()
	add_child(overlay)
	var backing := PanelContainer.new()
	backing.position = Vector2(18,18)
	overlay.add_child(backing)
	var margin := MarginContainer.new()
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,12)
	backing.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",8)
	margin.add_child(column)
	for row in [["Canopy","Screens","Gathering"],["Alternating","Groups of three","One colour"],["Overview","At the edge","Walk","Reset"]]:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation",8)
		column.add_child(line)
		for title in row:
			var button := Button.new()
			button.text = title
			button.custom_minimum_size = Vector2(152,38)
			button.pressed.connect(choose.bind(title))
			line.add_child(button)
			buttons[title] = button
	status = Label.new()
	status.add_theme_color_override("font_color",Color("f3d5e1"))
	status.add_theme_font_size_override("font_size",15)
	column.add_child(status)

func choose(title: String) -> void:
	if title in work.ARRANGEMENTS:
		# A new screen must not materialise through a visitor standing in its bay.
		if walking and absf(walker.position.x) < 5.3 and absf(walker.position.z) < 5.3:
			status.text = "Walk back to the edge before rearranging."
			return
		work.set_arrangement(work.ARRANGEMENTS.find(title))
	elif title in work.COLOUR_RULES:
		work.set_colour_rule(work.COLOUR_RULES.find(title))
	else:
		match title:
			"Overview": set_view(0)
			"At the edge": set_view(1)
			"Walk": start_walk()
			"Reset":
				set_view(0)
				work.set_arrangement(0)
				work.set_colour_rule(0)
	_update_status()

func _update_status() -> void:
	status.text = "12 panels  ·  %s  ·  %s\n%s" % [work.ARRANGEMENTS[work.arrangement],work.COLOUR_RULES[work.colour_rule],
		"WASD + mouse · Esc releases the pointer" if walking else "Change one condition. Keep the other."]

func set_view(index: int) -> void:
	walking = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var views := [[Vector3(6.55,4.65,7.45),Vector3(-0.3,1.65,-0.6)],
		[Vector3(0,1.65,7.3),Vector3(0,2,-1)]]
	camera.position = views[index][0]
	camera.look_at(views[index][1])
	camera.make_current()

func start_walk() -> void:
	walking = true
	walker.position = Vector3(0,0.04,7.3)
	walker.rotation = Vector3.ZERO
	walker.velocity = Vector3.ZERO
	pitch = 0
	eye.rotation.x = 0
	eye.make_current()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if walking and event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		walker.rotation.y -= event.relative.x*0.0025
		pitch = clampf(pitch-event.relative.y*0.0025,-1.35,1.35)
		eye.rotation.x = pitch
	if walking and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if not walking: return
	var wish := Vector3.ZERO
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		wish.x = float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A))
		wish.z = float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W))
	var direction := walker.basis*wish.normalized()
	walker.velocity.x = direction.x*2.8
	walker.velocity.z = direction.z*2.8
	walker.velocity.y = -0.5 if walker.is_on_floor() else walker.velocity.y-9.8*delta
	walker.move_and_slide()
	if walker.position.y < -3: start_walk()

func _material(colour: Color,roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = roughness
	return mat

func _box(label: String,size: Vector3,at: Vector3,material: Material,solid: bool) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = at
	node.material_override = material
	add_child(node)
	if solid: node.create_trimesh_collision()
	return node
