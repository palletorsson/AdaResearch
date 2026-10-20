extends Node3D
## Native inspection gallery. N opens the installed, functional Noise consoles.
const KINDS := ["floor", "wall", "pillar", "ceiling_l", "ceiling_j"]
var camera: Camera3D

func _ready() -> void:
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("#252335")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("#bec9e0")
	settings.ambient_light_energy = .65
	settings.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = settings
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -30, 0)
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	add_child(sun)
	block(Vector3(0,-.15,0), Vector3(28,.3,10), Color("#55565c"))
	for i in range(KINDS.size()):
		var at := Vector3((i-2)*5.0,0,0)
		var terminal: Node3D = load("res://commons/void/interface_"+KINDS[i]+".tscn").instantiate()
		terminal.position = at
		add_child(terminal)
		match KINDS[i]:
			"wall":
				block(at+Vector3(0,2,-.9),Vector3(3.6,4,.25),Color("#8a8b87"))
			"pillar":
				block(at+Vector3(0,2.5,-.7),Vector3(1,5,1),Color("#777a7c"))
			"ceiling_l", "ceiling_j":
				block(at+Vector3(0,4.95,-.5),Vector3(3.5,.3,2.6),Color("#777a7c"))
		var caption := Label3D.new()
		caption.text = str(i+1)+"   "+KINDS[i].replace("_"," ").to_upper()
		caption.position = at+Vector3(0,.18,1.35)
		caption.font_size = 48
		caption.pixel_size = .006
		add_child(caption)
	camera = Camera3D.new()
	camera.position = Vector3(0,6,18)
	add_child(camera)
	camera.look_at(Vector3(0,2,0))
	camera.current = true
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var instructions := Label.new()
	instructions.position = Vector2(22,18)
	instructions.text = "ARCHITECTURAL INTERFACES\n1–5: inspect mount   0: overview\nHold right mouse: look   WASD: move   Q/E: down/up\nN: open working consoles in Noise trial   Esc: close gallery\n\nMount studies are unassigned; the Noise trial has live controls."
	instructions.add_theme_font_size_override("font_size",20)
	instructions.add_theme_color_override("font_shadow_color",Color.BLACK)
	instructions.add_theme_constant_override("shadow_offset_x",2)
	instructions.add_theme_constant_override("shadow_offset_y",2)
	canvas.add_child(instructions)

func block(at: Vector3, size: Vector3, colour: Color) -> void:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.position = at
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = .85
	mesh.material_override = mat
	add_child(mesh)

func _process(delta: float) -> void:
	var direction := Vector3(
		float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_E))-float(Input.is_physical_key_pressed(KEY_Q)),
		float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
	camera.position += camera.basis*direction.normalized()*delta*5.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		camera.rotation.y -= event.relative.x*.003
		camera.rotation.x = clampf(camera.rotation.x-event.relative.y*.003,-1.5,1.5)
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode >= KEY_1 and event.keycode <= KEY_5:
		var at := Vector3((event.keycode-KEY_1-2)*5.0,0,0)
		camera.position = at+Vector3(2,2.7,4.4)
		camera.look_at(at+Vector3(0,2,0))
	elif event.keycode == KEY_0:
		camera.position = Vector3(0,6,18)
		camera.look_at(Vector3(0,2,0))
	elif event.keycode == KEY_N:
		get_tree().change_scene_to_file("res://commons/void/trials/noise/trial.tscn")
	elif event.keycode == KEY_ESCAPE:
		get_tree().quit()
