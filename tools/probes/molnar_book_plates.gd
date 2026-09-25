extends SceneTree
## Native book views of the same registered artifact; controls/floor hidden in close studies only.
const OUT := "res://doc/book/iterations/2026-09-23-array-molnar-volume/"
var camera:Camera3D
var study:Node3D
var shots:Array=[]
func _initialize() -> void:run.call_deferred()
func run() -> void:
	root.msaa_3d=Viewport.MSAA_4X
	var stage:=Node3D.new();root.add_child(stage);current_scene=stage
	var world:=WorldEnvironment.new();var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR;env.background_color=Color(0.035,0.038,0.042)
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color.WHITE;env.ambient_light_energy=0.7
	world.environment=env;stage.add_child(world)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-45,-35,0);sun.light_energy=1.0;stage.add_child(sun)
	study=load("res://commons/artifacts/molnar_cube_study/molnar_cube_study.tscn").instantiate();stage.add_child(study)
	camera=Camera3D.new();stage.add_child(camera);camera.current=true
	camera.environment=env.duplicate(true)
	camera.environment.fog_enabled=false
	var mushroom:Node=root.get_node_or_null("MushroomHand")
	if mushroom!=null and mushroom.get("_hud")!=null:mushroom.get("_hud").hide()
	await create_timer(0.4).timeout
	study.get_node("ControlRig").hide();study.get_node("GalleryFloor").hide()
	study.get_node("LowPlinth").hide();study.get_node("FloatingLip").hide()
	for child in study.get_children():
		if child is Label3D:child.hide()
	study.amount=Vector3.ZERO;study.target_amount=Vector3.ZERO;study.set_layers(1)
	await shot("plate-one-layer-order",Vector3(0,1.85,5),Vector3(0,1.85,0),34)
	study.amount=Vector3(0.7,0.7,0.6);study.target_amount=study.amount;study._refresh()
	await shot("plate-one-layer-departures",Vector3(0,1.85,5),Vector3(0,1.85,0),34)
	study.set_layers(4)
	await shot("plate-volume",Vector3(3.7,3.4,4.8),Vector3(0,1.85,0),35)
	FileAccess.open(OUT+"plate-report.json",FileAccess.WRITE).store_string(JSON.stringify({"scope":"Same production artifact in neutral photographic stage, selected poses, ControlRig and floor/plinth hidden for unobstructed book studies. Not museum placement or a historical reconstruction.","shots":shots,"artifact_sha256":FileAccess.get_sha256("res://commons/artifacts/molnar_cube_study/molnar_cube_study.gd")},"  "))
	quit(0)
func shot(title:String,eye:Vector3,aim:Vector3,fov:float) -> void:
	camera.position=eye;camera.look_at(aim);camera.fov=fov
	camera.environment.fog_enabled=false
	var mushroom:Node=root.get_node_or_null("MushroomHand")
	if mushroom!=null and mushroom.get("_hud")!=null:mushroom.get("_hud").hide()
	await create_timer(0.3).timeout;await RenderingServer.frame_post_draw
	var code:=root.get_texture().get_image().save_png(OUT+title+".png")
	shots.append({"name":title,"saved":code==OK,"layers":study.depth_layers,"frames":study.frames.multimesh.visible_instance_count,"amount":[study.amount.x,study.amount.y,study.amount.z]})
	print("MOLNAR BOOK ",title," ",code)
