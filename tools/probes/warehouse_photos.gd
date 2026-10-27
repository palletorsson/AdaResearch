extends "res://tools/probes/movable_pivot_probe.gd"
## Photography only: existing accepted warehouse layout, real floor geometry.
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--pictures="):pictures=arg.trim_prefix("--pictures=")
	DirAccess.make_dir_recursive_absolute(pictures)
	host=Node3D.new();root.add_child(host);current_scene=host
	var environment:=WorldEnvironment.new();var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR;env.background_color=Color("a9a5b0")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("ded3df");env.ambient_light_energy=.65
	environment.environment=env;host.add_child(environment)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-55,-25,0);sun.light_energy=1.1;sun.shadow_enabled=true;host.add_child(sun)
	var building: Node3D=load("res://commons/void/architecture.gd").new();host.add_child(building);await ticks(8)
	artifact=building.content.exhibits["1/variation"].get_node("Artifact")
	for layer in root.find_children("*","CanvasLayer",true,false):layer.hide()
	camera=Camera3D.new();camera.fov=65;host.add_child(camera)
	await shot("01-warehouse-overview",Vector3(2.4,4.8,10.5),Vector3(0,.45,0))
	camera.fov=60;await shot("02-warehouse-entry",Vector3(0,2.4,7.9),Vector3(0,.65,-.3))
	camera.fov=58;await shot("03-warehouse-open-cells",Vector3(-3.8,3.4,3.8),Vector3(-1.6,.2,1.2))
	FileAccess.open(pictures.path_join("photos.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"scope":"Native photography of accepted saved crate field; not another gameplay test."},"  "))
	print("WAREHOUSE_PHOTOS_DONE");building.free();host.free();quit()
