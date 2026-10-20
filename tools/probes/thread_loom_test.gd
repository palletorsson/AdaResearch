extends SceneTree
var Loom: Script
var tests: Array = []
var loom: Node3D
const OUT := "res://doc/book/iterations/2026-10-09-thread-loom/"

func _initialize() -> void: call_deferred("run")
func check(ok: bool, title: String) -> void:
	tests.append({"passed":ok,"test":title}); print("PASS " if ok else "FAIL ",title)

func pass_hand() -> void:
	var side: float = loom.start_side()
	for i in range(33):
		loom.sample_shuttle(Vector3(lerpf(side*Loom.EDGE,-side*Loom.EDGE,float(i)/32),Loom.SHED_Y,Loom.SHED_Z))

func run() -> void:
	Loom = load("res://commons/artifacts/thread_loom/thread_loom.gd")
	loom = Loom.new(); root.add_child(loom)
	await process_frame
	check(loom.picks.size()==4,"Four declared starting passes")
	check(loom.yarn_root.get_child_count()==13,"Twelve warp meshes and one continuous weft mesh")
	check(loom.weft_path.size()==4*(Loom.THREADS+2),"Weft follows every crossing and returns at the edges")
	var before: Array = loom.picks.duplicate(true)
	loom.set_draft("twill")
	check(loom.picks==before,"Changing draft preserves already woven picks")
	check(not loom.beat() and loom.picks.size()==4,"Cannot beat without a shuttle pass")
	var start := Vector3(-Loom.EDGE,Loom.SHED_Y,Loom.SHED_Z)
	loom.sample_shuttle(start)
	loom.sample_shuttle(Vector3(Loom.EDGE,Loom.SHED_Y,Loom.SHED_Z))
	check(loom.pending.is_empty(),"Jump from one edge to the other rejected")
	loom.release_shuttle()
	loom.sample_shuttle(start)
	loom.sample_shuttle(start+Vector3(.1,.3,0))
	check(not loom.armed and loom.pending.is_empty(),"A path above the shed cannot weave")
	pass_hand()
	check(loom.pending==loom.draft[0],"Full hand path retains the current lift row")
	var waiting: Array = loom.draft.duplicate(true)
	loom.toggle_cell(0,0)
	check(loom.draft==waiting,"Draft locked while a weft waits to be beaten")
	check(loom.beat() and loom.picks.size()==5,"Beat commits exactly one pass")
	check(loom.start_side()==1.0,"Next pass starts at the opposite selvedge")
	check(loom.picks.slice(0,4)==before,"Future weave leaves four old records unchanged")
	pass_hand(); loom.beat()
	check(loom.picks.size()==6,"Returning hand pass weaves a second row")
	var separation := true
	for row in range(loom.picks.size()):
		for col in range(Loom.THREADS):
			var wp: Vector3 = loom.warp_paths[col][3+loom.picks.size()-1-row]
			var step: int = col if row%2==0 else Loom.THREADS-1-col
			var fp: Vector3 = loom.weft_path[row*(Loom.THREADS+2)+1+step]
			var normal := Vector3.UP if float(loom.picks.size()-1-row)*Loom.PITCH<=.11 else Vector3.BACK
			separation = separation and absf((wp-fp).dot(normal))>2*Loom.RADIUS and is_equal_approx(wp.x,fp.x)
			separation = separation and (((wp-fp).dot(normal)>0)==bool(loom.picks[row][col%4]))
	check(separation,"Every crossing separates real yarn surfaces in its recorded over/under order")
	loom.undo_pick(); check(loom.picks.size()==5,"Undo removes only the last committed pass")
	loom.reset_cloth(); check(loom.picks.is_empty() and loom.weft_path.is_empty(),"Reset leaves bare warp, not a hidden fabric plane")
	var origin := XROrigin3D.new(); root.add_child(origin)
	var controller := XRController3D.new(); origin.add_child(controller)
	var pickup = load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate(); controller.add_child(pickup)
	controller.global_position = loom.shuttle.global_position
	loom.shuttle.pick_up(pickup)
	for i in range(3): await physics_frame
	check(loom.shuttle.is_picked_up(),"XR Tools can pick up the actual shuttle")
	for i in range(41):
		controller.global_position = loom.to_global(Vector3(lerpf(-Loom.EDGE,Loom.EDGE,float(i)/40),Loom.SHED_Y,Loom.SHED_Z))
		for j in range(2): await physics_frame
	check(not loom.pending.is_empty(),"Held XR shuttle movement traverses the shed")
	loom.shuttle.action()
	await physics_frame
	check(loom.picks.size()==1,"Held shuttle trigger beats the pending weft")
	loom.shuttle.let_go(pickup,Vector3.ZERO,Vector3.ZERO)
	await physics_frame
	check(not loom.shuttle.is_picked_up(),"XR release leaves the existing shuttle available")
	origin.queue_free(); await process_frame
	loom.reset_cloth()
	loom.start_pass()
	for i in range(80): loom._process(.02)
	check(not loom.pending.is_empty(),"Guided desktop pass goes through the same path validator")
	loom.beat()
	for i in range(Loom.MAX_PICKS-1): pass_hand(); loom.beat()
	check(loom.picks.size()==Loom.MAX_PICKS,"Finite sample fills to the declared capacity")
	pass_hand(); loom.beat()
	check(loom.picks.size()==Loom.MAX_PICKS,"Capacity bound prevents unbounded geometry growth")
	loom.reset_cloth(); loom.set_draft("plain")
	for i in range(8): pass_hand(); loom.beat()
	loom.set_draft("twill")
	for i in range(8): pass_hand(); loom.beat()
	var result := true
	for t in tests: result = result and t.passed
	var file := FileAccess.open(OUT+"tests.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":result,"checks":tests,"kind":"Godot runtime and prescribed path geometry; no headset trial"},"\t")); file.close()
	if "--capture" in OS.get_cmdline_user_args(): await capture()
	quit(0 if result else 1)

func capture() -> void:
	root.size = Vector2i(1500,1100)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = Color("191f25")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("d1dce8"); env.ambient_light_energy = .7
	environment.environment = env; root.add_child(environment)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-48,-28,0)
	sun.light_energy = 1.7; sun.shadow_enabled = true; root.add_child(sun)
	var camera := Camera3D.new(); root.add_child(camera)
	camera.position = Vector3(2.35,2.55,3.25); camera.look_at(Vector3(-.12,1.05,.14)); camera.fov = 48; camera.make_current()
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"loom.png")
	camera.position = Vector3(.12,1.34,1.7); camera.look_at(Vector3(0,.83,.89)); camera.fov = 45
	for i in range(3): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"crossings.png")
