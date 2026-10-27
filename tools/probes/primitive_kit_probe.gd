extends SceneTree
var out := ""
var checks: Array=[]
var host: Node3D
var camera: Camera3D
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	run.call_deferred()
func check(label: String, value: bool) -> void:
	checks.append({"name":label,"passed":value});print("KIT_CHECK ",value," ",label)
func frames(count: int) -> void:
	for i in count:await physics_frame
func specimen(id: String, at: Vector3) -> Node3D:
	var body: Node3D=load("res://commons/artifacts/primitive_encounters/"+id+".tscn").instantiate()
	body.position=at;host.add_child(body);return body
func photo(title: String, at: Vector3, target: Vector3) -> void:
	camera.position=at;camera.look_at(target);await frames(8);await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(title+".png"))
func run() -> void:
	host=Node3D.new();root.add_child(host);current_scene=host
	var frame: Node3D=load("res://tools/probes/primitive_kit_frame.gd").new();host.add_child(frame)
	var env := WorldEnvironment.new();env.environment=Environment.new();host.add_child(env)
	env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("303842")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("bfc9d5");env.environment.ambient_light_energy=.6
	env.environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	var sun := DirectionalLight3D.new();sun.rotation_degrees=Vector3(-48,-28,0);sun.light_color=Color("ffe8c8");sun.light_energy=1.8;sun.shadow_enabled=true;host.add_child(sun)
	camera=Camera3D.new();camera.fov=48;host.add_child(camera);camera.make_current()
	root.msaa_3d=Viewport.MSAA_4X
	var pieces: Array[Node3D]=[]
	for length in [1,2,4]:
		var piece := specimen("timber_plank_%dm"%length,Vector3(0,-5.2,-3+length*.9));pieces.append(piece)
		check("plank %d m retains source box collider"%length,piece.get_node("PickupBody").shape.size==Vector3(length,.06,.25))
		check("plank %d m has grain and light-catching edge geometry"%length,piece.get_node("Skin").mesh.get_surface_count()==1 and piece.get_node("Skin").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()>36 and piece.get_node("Skin").material_override.albedo_texture!=null)
	for entry in [["timber_panel_1x1",Vector2(1,1),Vector3(-2,-5.5,-2)],["timber_panel_2x1",Vector2(2,1),Vector3(-2,-5.5,0)],["timber_panel_2x2",Vector2(2,2),Vector3(2,-5.5,0)]]:
		var piece := specimen(entry[0],entry[2]);pieces.append(piece)
		check(str(entry[0])+" exact nominal collider / bottom anchor",piece.get_node("PanelCollision").shape.size==Vector3(entry[1].x,.045,entry[1].y) and is_equal_approx(piece.get_node("PanelCollision").position.y,.0225))
	var ball := specimen("trace_point_ball",Vector3(-3,-5.1,1.5));pieces.append(ball)
	check("Trace canonical ball is 28 cm and has the original gravity release",is_equal_approx(ball.get_node("PointCollision").shape.radius,.14) and is_equal_approx(ball.mass,.3) and ball.release_mode==0)
	var pyramid := specimen("traffic_pyramid_5",Vector3(3.6,-5.5,-2));pieces.append(pyramid)
	var crystal := specimen("pentagonal_bipyramid_7",Vector3(4.9,-5.5,-.5));pieces.append(crystal)
	check("traffic pyramid has exactly 5 hull vertices / 5 faces",pyramid.get_meta("vertex_count")==5 and pyramid.get_meta("face_count")==5 and pyramid.get_node("ExactHull").shape.points.size()==5)
	check("seven-vertex bipyramid has 10 faces and 7 hull corners",crystal.get_meta("vertex_count")==7 and crystal.get_meta("face_count")==10 and crystal.get_node("ExactHull").shape.points.size()==7)
	check("traffic band is a real exportable texture",pyramid.get_node("ExactPolyhedron").material_override.albedo_texture!=null)
	await photo("01-primitives-kit",Vector3(4.6,-2.3,7),Vector3(0,-5.1,0))
	for piece in pieces:piece.queue_free()
	await frames(3)
	var ramp: Node3D=load("res://commons/artifacts/trace_ball_ramp/trace_ball_ramp.tscn").instantiate();ramp.position=Vector3(-15,-6,-4);host.add_child(ramp)
	check("existing Trace ramp instances the canonical ball",ramp.ball.scene_file_path.ends_with("trace_point_ball.tscn"))
	var deck := specimen("melencolia_platform",Vector3(0,-5.5,-2))
	check("court reuses 25 actual one-metre block scenes",deck.get_children().filter(func(n):return str(n.name).begins_with("Cube_") and n.scene_file_path.ends_with("platform_block.tscn")).size()==25)
	check("court reuses 25 exact one-metre timber panels",deck.get_children().filter(func(n):return str(n.name).begins_with("Panel_") and n.scene_file_path.ends_with("timber_panel_1x1.tscn")).size()==25)
	check("fixed court skins use at most eight GPU instance groups",deck.get_meta("fixed_draw_groups",999)<=8)
	for x in [-.5,.5]:
		var access := specimen("wedge_blocker",Vector3(x,-6,1.5));access.rotation.y=PI
	for i in 3:
		var shape := specimen("traffic_pyramid_5" if i==0 else "pentagonal_bipyramid_7" if i==1 else "trace_point_ball",Vector3(-1.4+i*1.4,-4.99,-2))
		shape.enabled=false
	await frames(15)
	var query := PhysicsRayQueryParameters3D.create(Vector3(0,-3,-1),Vector3(0,-7,-1),1)
	var hit := host.get_world_3d().direct_space_state.intersect_ray(query)
	check("court is physically supported at the old one-metre level",not hit.is_empty() and absf(hit.position.y+4.997)<.04)
	await photo("02-melencolia-construction-court",Vector3(4.6,-2.1,6.5),Vector3(0,-5,-1.7))
	await photo("03-timber-joins",Vector3(3,-3,2),Vector3(.2,-5,-1.5))
	# Read the real saved court through the game's own placement loader. Keep
	# its horizontal poses/config and render only this local group in the frame.
	for child in host.get_children():
		if child is Node3D and not child.scene_file_path.is_empty():child.queue_free()
	await frames(3)
	var content: Node3D=load("res://commons/void/floor_content.gd").new();content.lazy=true
	frame.add_child(content);frame.content=content
	var actual := Node3D.new();actual.name="SavedMelencoliaCourt";actual.position.y=-6;host.add_child(actual)
	for record in content.data.floors[12].artifacts:
		if record.artifact in ["void_primitive_melencolia","pyramid","pyramidlong","cube_scene","prism_block"]:
			content._build_artifact(actual,12,record)
	await frames(35)
	var court: Node3D=content.exhibits["12/hall"].get_node("Artifact/CourtDeck")
	check("saved Melencolia hall uses the actual modular court",court.scene_file_path.ends_with("melencolia_platform.tscn"))
	await photo("04-saved-melencolia-court",Vector3(-4.6,-2.1,6.5),Vector3(0,-4.7,-1.7))
	var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/void/catalog.json"))
	var dressing=load("res://commons/void/set_dressing.gd")
	for kind in catalog.props:
		if catalog.props[kind].get("group","")!="Primitives kit":continue
		var placed: Node3D=dressing.build(frame,frame.floors[1],{"id":kind,"kind":kind,"position":[-18,5],"facing":90,"scale":1},catalog.props[kind])
		check("palette "+str(kind)+" builds its real source rather than a fallback box",placed.has_node("Prefab") and placed.get_node("Prefab").scene_file_path==catalog.props[kind].scene)
		placed.queue_free();await process_frame
	var passed := checks.all(func(c):return c.passed)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks,"scope":"Native source / exact collider / canonical reuse checks and captures in a bounded standard-frame fixture. Not a full tower playthrough or headset acceptance."},"  "))
	quit(0 if passed else 1)
