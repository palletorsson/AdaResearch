extends Node3D
## Standalone desktop workshop. Mouse click points at the same VR button areas.
## WASD moves the camera; hold right mouse to look; Q/E move down/up.
var cam:Camera3D
func _ready() -> void:
	var environment=WorldEnvironment.new();var env=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("101d2a");env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("e1ecff");env.ambient_light_energy=0.65;environment.environment=env;add_child(environment)
	var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-55,-25,0);sun.light_energy=0.9;sun.shadow_enabled=true;add_child(sun)
	var stage=load("res://commons/artifacts/timing_machines/machine_stage.gd").new();add_child(stage)
	stage.box(Vector3(0,-0.1,0),Vector3(18,0.2,19),stage.material("31414a"),true)
	stage.box(Vector3(-7,1.6,0),Vector3(0.12,3.2,17),stage.material("455463"),true)
	stage.box(Vector3(7,1.6,0),Vector3(0.12,3.2,17),stage.material("455463"),true)
	stage.label("LANDSCAPES / POSSIBLE BODIES\nDesktop workshop: WASD + Q/E, hold right mouse to look, click a button",Vector3(0,4.2,-5.5),0.0019)
	var bench=load("res://commons/artifacts/landscape_flow_bench/landscape_flow_bench.tscn").instantiate();add_child(bench)
	cam=Camera3D.new();add_child(cam);cam.environment=env.duplicate();cam.fov=53;cam.position=Vector3(8,7,11);cam.look_at(Vector3(0,1.0,0));cam.current=true
func _process(delta:float) -> void:
	var direction=Vector3(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),0,float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
	cam.position+=(cam.global_basis*direction+Vector3.UP*(float(Input.is_physical_key_pressed(KEY_E))-float(Input.is_physical_key_pressed(KEY_Q))))*delta*4
func _unhandled_input(event:InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_RIGHT:Input.mouse_mode=Input.MOUSE_MODE_CAPTURED if event.pressed else Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseMotion and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
		cam.rotation.y-=event.relative.x*0.003;cam.rotation.x=clampf(cam.rotation.x-event.relative.y*0.003,-1.45,1.45)
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		var from=cam.project_ray_origin(event.position);var query=PhysicsRayQueryParameters3D.create(from,from+cam.project_ray_normal(event.position)*30,1|1048576);query.collide_with_areas=true
		var hit=get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty() and hit.collider.has_method("pointer_event"):
			XRToolsPointerEvent.pressed(cam,hit.collider,hit.position);XRToolsPointerEvent.released(cam,hit.collider,hit.position)
