extends SceneTree
## Targeted staging: native source cycle, shared viewing and physical circulation.
const Source := preload("res://commons/void/room_source.gd")
var out := ""
var building: Node3D
var lens: Camera3D
var checks: Array = []
var failed: Array = []
var observations: Dictionary = {}
var level_y := -354.0

func _initialize() -> void:
	run.call_deferred()

func check(label: String, ok: bool) -> void:
	checks.append({"name":label,"passed":ok})
	if not ok:failed.append(label)
	print("BAY_CHECK ", label, " ", ok)

func frames(count: int) -> void:
	for i in count:await physics_frame

func geometry(node: Node, boxes: Array) -> void:
	if node is SubViewport:return
	if node is MeshInstance3D and node.mesh != null and node.is_visible_in_tree():
		boxes.append(node.global_transform * node.get_aabb())
	elif node is MultiMeshInstance3D and node.multimesh != null and node.is_visible_in_tree():
		boxes.append(node.global_transform * node.get_aabb())
	for child in node.get_children():geometry(child, boxes)

func bounds(node: Node) -> AABB:
	var boxes: Array = [];geometry(node, boxes)
	if boxes.is_empty():return AABB()
	var result: AABB = boxes[0]
	for box in boxes:result = result.merge(box)
	return result

func at(x: float, y: float, z: float) -> Vector3:
	return Vector3(x, level_y + y, z)

func photo(name: String, eye: Vector3, target: Vector3) -> void:
	lens.make_current()
	lens.global_position = eye;lens.look_at(target)
	await frames(3);await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))

func walk(visitor: CharacterBody3D, points: Array, label: String) -> void:
	var completed := true
	for target in points:
		var reached := false
		# Allow the actual low walking speed enough time for the longest side.
		var distance:float=Vector2(target.x-visitor.position.x,target.z-visitor.position.z).length()
		var budget:int=int(ceil(distance/(3.0*.45)*Engine.physics_ticks_per_second))+90
		for frame in budget:
			var diff: Vector3 = target-visitor.global_position;diff.y = 0
			if diff.length() < .10:reached=true;break
			visitor.drive = Vector2(diff.x,diff.z).normalized()*.45
			await frames(1)
		visitor.drive = Vector2.ZERO
		if not reached:
			completed=false
			for i in visitor.get_slide_collision_count():
				print("BAY_BLOCKER ",label," ",visitor.get_slide_collision(i).get_collider().get_path())
			break
	check(label, completed)
	observations[label] = {"reached":completed,"last_position":[visitor.position.x,visitor.position.y-level_y,visitor.position.z]}

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	Source.use_main_tower = true
	var scene := Node3D.new();root.add_child(scene);current_scene=scene
	building=load("res://commons/void/architecture.gd").new();building.stream_content=true;scene.add_child(building)
	var draft: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(out.path_join("draft-rooms.json")))
	building.content.data.floors[59]=draft.floors[59]
	building.content.load_floor(59)
	var shown: Array[int]=[59];building.show_floor_window(shown)
	level_y=building.spec.levels[59]
	root.size=Vector2i(1440,900)
	var env:=WorldEnvironment.new();env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("293137")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("e0e5e8");env.environment.ambient_light_energy=.48
	env.environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC;scene.add_child(env)
	var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-45,-25,0);light.light_energy=.9;light.shadow_enabled=true;scene.add_child(light)
	lens=Camera3D.new();lens.current=true;lens.fov=65;lens.far=70;scene.add_child(lens)
	await frames(45)
	check("standard42m floor and two shafts retained", building.spec.width==42 and building.spec.shafts.size()==2)
	check("all21 original artifacts retained", draft.floors[59].artifacts.size()==21)
	var clock:Node3D=building.content.exhibits["59/clock"].get_node("Artifact")
	var turn:Node3D=building.content.exhibits["59/turn"].get_node("Artifact")
	var bench:Node3D=building.content.props["59/clock-bench"]
	var top_y:float=bounds(bench.get_node("Prefab")).end.y
	var low:=INF;var high:=-INF
	var initial_angle:float=turn._current_angle
	var previous_angle:float=initial_angle
	var angle_travel:=0.0
	for i in 240:
		var box:AABB=clock._cube_mesh.global_transform*clock._cube_mesh.get_aabb()
		low=minf(low,box.position.y);high=maxf(high,box.end.y)
		await frames(1)
		angle_travel+=absf(angle_difference(previous_angle,turn._current_angle))
		previous_angle=turn._current_angle
	check("cube clears actual tabletop throughout four-second sample", low-top_y>.05)
	check("original sine still moves cube through .8m cycle",high-low>.95 and high-low<1.15)
	check("original frequency and amplitude remain",is_equal_approx(clock.frequency,1) and is_equal_approx(clock.amplitude,.2))
	check("comparison cube still turns",angle_travel>5)
	observations["cycle"]={"bench_top":top_y-level_y,"cube_min":low-level_y,"cube_max":high-level_y,"clearance":low-top_y,"sample_physics_frames":240}
	for id in ["backdrop","side","low-edge","store","stock","lamp"]:
		var prop:Node3D=building.content.props["59/return-bay-"+id]
		var box:AABB=bounds(prop)
		check(id+" has actual native geometry",box.size.length()>.1)
		check(id+" stays within central floor and storey",box.position.x> -7.4 and box.end.x<7.4 and box.position.z> -8.5 and box.end.z<8.5 and box.end.y<level_y+5.64)
		observations[id]={"min":[box.position.x,box.position.y-level_y,box.position.z],"max":[box.end.x,box.end.y-level_y,box.end.z]}
	var visitor:CharacterBody3D=load("res://commons/void/walker.gd").new();scene.add_child(visitor)
	# This fixture checks physical circulation, not mouse-hand interactions.
	# Real background mouse events must not rotate deterministic drive axes.
	visitor.set_process_unhandled_input(false)
	visitor.desktop_pointer.enabled=false
	visitor.desktop_pointer.set_process_input(false)
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	lens.make_current()
	visitor.scripted_input=true
	visitor.position=at(-6,.06,4.5);await frames(12)
	await walk(visitor,[at(-4.6,0,5.0),at(-1.5,0,5.4)],"default arrival reaches shared front")
	await walk(visitor,[at(1.35,0,4.8),at(1.35,0,1.8),at(-4.6,0,1.8),at(-4.6,0,4.8),at(-1.5,0,5.4)],"continuous walk around both benches")
	await walk(visitor,[at(1.35,0,4.8),at(1.35,0,1.8),at(0,0,0)],"departure reaches existing pendulum approach")
	visitor.queue_free();await frames(3)
	for id in ["clock","turn"]:
		var target:Vector3=at(-3 if id=="clock" else 0,1.65 if id=="clock" else 1.3,3)
		var query:=PhysicsRayQueryParameters3D.create(at(-1.5,1.65,5.4),target,1)
		var hit:Dictionary=scene.get_world_3d().direct_space_state.intersect_ray(query)
		var source:Node3D=clock if id=="clock" else turn
		check(id+" visible from shared working position",hit.is_empty() or source.is_ancestor_of(hit.collider))
	await photo("01-shared-work-area",at(-1.5,1.65,6.6),at(-1.5,1.5,2.5))
	await photo("02-arriving-at-the-benches",at(-6.4,2.1,7.4),at(-1.7,1.5,2.7))
	await photo("03-room-to-walk-around",at(1.25,2.0,1.8),at(-2.0,1.2,3.1))
	var result:Dictionary={"passed":failed.is_empty(),"checks":checks,"failed":failed,"observations":observations,"scope":"One staged comparison bay on actual main-floor59 geometry. Four-second native cycle, actual tabletop, physical desktop capsule routes and collision sightlines. Other artifact interactions and physical VR headset playthrough not tested. Neutral inspection lighting in captures."}
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("SHARED_BAY_RESULT ",checks.size()," failures:",failed)
	quit(0 if failed.is_empty() else 1)
