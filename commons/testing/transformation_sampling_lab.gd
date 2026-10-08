extends Node3D
## Desktop research fixture. The artifact also supplies physical VR buttons.
const Study = preload("res://commons/artifacts/transformation_sampling/transformation_sampling.tscn")
var study: Node3D
var camera: Camera3D
var walker: CharacterBody3D
var walking: bool = false
var axial: Node3D

func _ready() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("111e2a")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("b7c7d6")
	environment.ambient_light_energy = 0.7
	world.environment = environment
	add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45,25,0)
	light.light_energy = 1.3
	light.shadow_enabled = true
	add_child(light)
	var floor_mesh := MeshInstance3D.new()
	var floor_box := BoxMesh.new()
	floor_box.size = Vector3(20,0.1,20)
	floor_mesh.mesh = floor_box
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("33424c")
	floor_mesh.material_override = material
	floor_mesh.position = Vector3(0,-0.05,2)
	add_child(floor_mesh)
	var ground := StaticBody3D.new()
	var ground_shape := CollisionShape3D.new()
	var ground_box := BoxShape3D.new()
	ground_box.size = floor_box.size
	ground_shape.shape = ground_box
	ground.position = floor_mesh.position
	ground.add_child(ground_shape)
	add_child(ground)
	study = Study.instantiate()
	add_child(study)
	camera = Camera3D.new()
	camera.position = Vector3(0,6.5,-9)
	camera.fov = 48
	add_child(camera)
	camera.look_at(Vector3(0,1.2,1.8))
	camera.make_current()
	walker = CharacterBody3D.new()
	walker.name = "DesktopWalker"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.22
	capsule.height = 1.75
	var walker_shape := CollisionShape3D.new()
	walker_shape.shape = capsule
	walker_shape.position.y = 0.875
	walker.add_child(walker_shape)
	add_child(walker)
	# The companion can be used independently and added to the research fixture.
	var axial_scene := "res://commons/artifacts/axial_sweep/axial_sweep.tscn"
	if ResourceLoader.exists(axial_scene):
		axial = load(axial_scene).instantiate()
		axial.position = Vector3(-6,0,0)
		add_child(axial)
	var layer := CanvasLayer.new()
	add_child(layer)
	var row := HFlowContainer.new()
	layer.add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	row.offset_left = 20
	row.offset_right = -20
	row.offset_top = 20
	for i in 5:
		var button := Button.new()
		button.text = ["Change body","Add / remove mark","Change sample interval","Pause / play","Reset"][i]
		button.pressed.connect(study._press.bind(i))
		row.add_child(button)
	var overview := Button.new()
	overview.text = "Overview"
	overview.pressed.connect(show_overview)
	row.add_child(overview)
	for i in 4:
		var button := Button.new()
		button.text = ["Translate","Rotate","Scale","Combine"][i]
		button.pressed.connect(focus.bind(i))
		row.add_child(button)
	var walk := Button.new()
	walk.text = "Walk up: WASD / hold right mouse to look"
	walk.pressed.connect(enter_walk)
	row.add_child(walk)
	var compare := Button.new()
	compare.text = "Show / hide sampled comparisons"
	compare.pressed.connect(func(): study.set_comparisons(not study.show_comparisons))
	row.add_child(compare)
	if axial:
		var inspect := Button.new()
		inspect.text = "Axial body"
		inspect.pressed.connect(focus_axial)
		row.add_child(inspect)
		for item in [["Axial: change shape","cycle_shape"],["Axial: boundary","toggle_envelope"],["Axial: pause","toggle_playing"]]:
			var button := Button.new()
			button.text = item[0]
			button.pressed.connect(func():
				if axial.has_method(item[1]): axial.call(item[1]))
			row.add_child(button)

func _release_camera() -> void:
	walking = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if camera.get_parent()!=self: camera.reparent(self)

func enter_walk() -> void:
	for station in study.stations: station.root.show()
	walker.position = Vector3(2.2,0.02,-2.2)
	walker.rotation.y = PI
	walker.velocity = Vector3.ZERO
	camera.reparent(walker)
	camera.position = Vector3(0,1.7,0)
	camera.rotation = Vector3.ZERO
	camera.fov = 70
	walking = true

func _physics_process(delta: float) -> void:
	if not walking: return
	var direction := Vector3(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),0,float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
	direction = walker.basis * direction.normalized()
	walker.velocity.x = direction.x*1.8
	walker.velocity.z = direction.z*1.8
	walker.velocity.y -= 9.8*delta
	walker.move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if not walking: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if event.pressed else Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		walker.rotate_y(-event.relative.x*0.003)
		camera.rotation.x = clampf(camera.rotation.x-event.relative.y*0.003,-1.35,1.35)
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func focus(index: int) -> void:
	_release_camera()
	for i in 4: study.stations[i].root.visible = (i==index)
	var station: Node3D = study.stations[index].root
	camera.fov = 65
	camera.global_position = station.to_global(Vector3(0,1.72,-2.4))
	camera.look_at(station.to_global(Vector3(0,1.85,0.0)))

func focus_axial() -> void:
	_release_camera()
	for station in study.stations: station.root.show()
	camera.fov = 55
	camera.global_position = axial.to_global(Vector3(0.8,1.72,-2.6))
	camera.look_at(axial.to_global(Vector3(0,1.9,0)))

func show_overview() -> void:
	_release_camera()
	for station in study.stations: station.root.show()
	camera.position=Vector3(0,6.5,-9)
	camera.fov=48
	camera.look_at(Vector3(0,1.2,1.8))
