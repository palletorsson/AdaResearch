extends Node3D
## Standalone desktop walk-through (F6). No UI. Click to look; WASD to walk;
## Escape releases the mouse. Stage is authored, not selected inside the world.
@export_enum("Point_One", "Point_Lines", "Point_Trace", "Point_Line_Grid", "Point_Triangle_Context", "Primitives_Polythedra", "Trans_Rotation", "Trans_Scale") var hall: String = "Trans_Scale"
var walker: CharacterBody3D
var camera: Camera3D
var _inventory: Node
var _previous_count: bool = true
var _hidden_hud: Array[CanvasLayer] = []

func _ready() -> void:
	_inventory = get_node_or_null("/root/MushroomHand")
	if _inventory != null:
		_previous_count = bool(_inventory.get("show_desktop_count"))
		_inventory.set("show_desktop_count", false)
		for child in _inventory.get_children():
			if child is CanvasLayer and child.visible:
				_hidden_hud.append(child)
				child.visible = false
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("29322e")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("e2e5da")
	settings.ambient_light_energy = 0.7
	environment.environment = settings
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-52,-25,0)
	light.light_energy = 1.2
	add_child(light)
	var biome: Node3D = load("res://commons/artifacts/biome_primitives/biome_primitives.tscn").instantiate()
	biome.stage = hall
	add_child(biome)
	walker = CharacterBody3D.new()
	walker.name = "Walker"
	walker.add_to_group("em_walker")
	walker.position = Vector3(0,.03,5)
	var capsule := CapsuleShape3D.new()
	capsule.radius = .25
	capsule.height = 1.7
	var collider := CollisionShape3D.new()
	collider.shape = capsule
	collider.position.y = .85
	walker.add_child(collider)
	camera = Camera3D.new()
	camera.position.y = 1.65
	camera.rotation.x = deg_to_rad(-10)
	camera.current = true
	camera.fov = 75
	walker.add_child(camera)
	add_child(walker)

func _exit_tree() -> void:
	if is_instance_valid(_inventory): _inventory.set("show_desktop_count", _previous_count)
	for layer in _hidden_hud:
		if is_instance_valid(layer): layer.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		walker.rotate_y(-event.relative.x * .002)
		camera.rotation.x = clampf(camera.rotation.x-event.relative.y*.002,-1.35,1.35)

func _physics_process(delta: float) -> void:
	if walker == null: return
	var movement := Vector3(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),0,
		float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
	movement = walker.basis * movement.normalized() * 2.5
	walker.velocity.x = movement.x
	walker.velocity.z = movement.z
	if not walker.is_on_floor(): walker.velocity.y -= 9.8*delta
	else: walker.velocity.y = 0
	walker.move_and_slide()
	# The demo has no surrounding museum floor. Keep its walker on this patch.
	walker.position.x = clampf(walker.position.x,-5.7,5.7)
	walker.position.z = clampf(walker.position.z,-5.7,5.7)
