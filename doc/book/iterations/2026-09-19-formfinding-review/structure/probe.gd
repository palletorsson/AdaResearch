extends SceneTree
const BASE := "res://doc/book/iterations/2026-09-19-formfinding-review/structure/"
const SCRIPTS := [
	"commons/artifacts/laundry_line_cathedral/laundry_line_cathedral.gd",
	"commons/artifacts/calder_mobile/calder_mobile.gd",
	"commons/primitives/tensegrity_triangle/tensegrity_triangle.gd",
	"commons/artifacts/fractal_truss_tower/fractal_truss_tower.gd",
	"commons/primitives/parametric/catenoid.gd",
	"algorithms/wavefunctions/line_builder_3d/cable_builder.gd"]
var out := BASE + "runtime/"
var before := false
var museum_mode := false
var captures := false
var hall := "FormFinding_Catenary"
var originals: Array[Resource] = []
var checks: Array[Dictionary] = []
var observation: Dictionary = {}
var artifacts: Dictionary = {}
var cam: Camera3D
var segment: Node3D
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
		if arg.begins_with("--hall="): hall = arg.trim_prefix("--hall=")
	before = "--before" in OS.get_cmdline_user_args()
	museum_mode = "--museum" in OS.get_cmdline_user_args()
	captures = "--capture" in OS.get_cmdline_user_args()
	if museum_mode:
		var frozen := GDScript.new()
		frozen.source_code = FileAccess.get_file_as_string(BASE + "frozen-museum.gd")
		check(frozen.reload() == OK, "saved shared museum script compiles")
		frozen.take_over_path("res://commons/scenes/endless_museum.gd")
		originals.append(frozen)
	if before:
		for path in SCRIPTS:
			var saved := GDScript.new()
			var regex := RegEx.new(); regex.compile("(?m)^class_name .*$")
			saved.source_code = regex.sub(FileAccess.get_file_as_string(BASE + "before/" + path), "", true)
			check(saved.reload() == OK, "saved source compiles " + path)
			saved.take_over_path("res://" + path); originals.append(saved)
		for key in ["catenoid", "helicoid"]:
			var path: String = "commons/primitives/parametric/" + key + ".tscn"
			var saved: PackedScene = load(BASE + "before/" + path)
			saved.take_over_path("res://" + path); originals.append(saved)
	run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks.append({"ok":ok,"message":message})
	print("STRUCTURE ", "PASS " if ok else "FAIL ", message)
func run() -> void:
	if museum_mode: await museum()
	else:
		var world := Node3D.new(); root.add_child(world); current_scene = world
		var scenes := {
			"laundry_line_cathedral":"commons/artifacts/laundry_line_cathedral/laundry_line_cathedral.tscn",
			"calder_mobile":"commons/artifacts/calder_mobile/calder_mobile.tscn",
			"fractal_truss_tower":"commons/artifacts/fractal_truss_tower/fractal_truss_tower.tscn",
			"tensegrity_triangle":"commons/primitives/tensegrity_triangle/tensegrity_triangle.tscn",
			"catenoid":"commons/primitives/parametric/catenoid.tscn",
			"helicoid":"commons/primitives/parametric/helicoid.tscn",
			"cable_builder":"algorithms/wavefunctions/line_builder_3d/cable_builder.tscn"}
		for key in scenes:
			var n: Node3D = load("res://" + scenes[key]).instantiate(); world.add_child(n)
			n.position.x = artifacts.size() * 12.0; artifacts[key] = n
		await process_frame
	await artifact_checks()
	if captures:
		if hall == "FormFinding_Catenary":
			if artifacts.has("laundry_line_cathedral"):
				await capture("laundry-standing",artifacts.laundry_line_cathedral,Vector3(3.7,1.65,1.0),Vector3(0,1.7,0))
				await capture("laundry-plaque",artifacts.laundry_line_cathedral,Vector3(1.2,1.5,-2.25),Vector3(1.2,1.15,-1.25))
		else:
			if artifacts.has("calder_mobile"):
				await capture("calder-standing",artifacts.calder_mobile,Vector3(0,1.65,-4.0),Vector3(0,1.8,0))
				await capture("calder-plaque",artifacts.calder_mobile,Vector3(0,.8,-2.6),Vector3(0,.2,0))
			if artifacts.has("fractal_truss_tower"):
				await capture("truss-standing",artifacts.fractal_truss_tower,Vector3(0,1.65,-3.1),Vector3(0,2.05,0))
	finish()
func artifact_checks() -> void:
	for key in ["catenoid","helicoid"]:
		if not artifacts.has(key): continue
		var n: RigidBody3D = artifacts[key]
		n.freeze = true
		await physics_frame
		var query := PhysicsShapeQueryParameters3D.new()
		var sphere := SphereShape3D.new(); sphere.radius = .04
		query.shape = sphere; query.transform.origin = n.global_position; query.collision_mask = 4
		var hits := n.get_world_3d().direct_space_state.intersect_shape(query)
		var found := hits.any(func(item): return item.collider == n)
		check(n.get_script().get_base_script().resource_path.ends_with("/objects/pickable.gd"), key + " inherits pickup contract")
		check(n.can_pick_up(null), key + " permits pickup when not held")
		check(found == (not before), key + " hand collision-mask query matches expected source version")
		observation[key] = {"collision_layer":n.collision_layer,"hand_query_found":found,"original_layer":n.original_collision_layer,"can_pick_up":n.can_pick_up(null)}
	if artifacts.has("laundry_line_cathedral"):
		var n: Node3D = artifacts.laundry_line_cathedral
		var bars := n.find_children("AnchorCrossbar*","MeshInstance3D",false,false)
		check(bars.size() == (0 if before else 2), "laundry two crossbars bridge all three anchor pairs")
		for x in [-n.span/2,n.span/2]:
			for a in n.sags: check(is_equal_approx(n._cat_y(x,a),n.pole_h), "analytic laundry curve meets support endpoint")
		var plate: Node = n.get_node("LaundryPlate")
		check(plate.body.contains("gravity solved") if before else plate.body.contains("not a gravity solver"), "laundry plaque distinguishes analytic geometry from settling")
		observation["laundry"] = {"crossbars":bars.size(),"plaque":plate.body}
	if artifacts.has("calder_mobile"):
		var n: Node3D = artifacts.calder_mobile
		var states := []
		for lever in ["solved","halved","inverted"]:
			n.apply_grid_config({"lever":lever,"evidence":"longhand"})
			await process_frame
			var tree: Node3D = n.get_child(1)
			var lp: Vector3 = tree.get_child(3).position
			var rp: Vector3 = tree.get_child(4).position
			check(is_equal_approx(lp.y,rp.y) == (lever=="solved"), "Calder root rod pose shows selected lever " + lever)
			check(n._plaque.text.contains("STATIC MOMENT MODEL") if not before else n._plaque.text.contains("ALEXANDER CALDER"), "Calder label identifies implemented model " + lever)
			states.append({"lever":lever,"left":str(lp),"right":str(rp),"mass":n._total_mass,"plaque":n._plaque.text})
		check(is_equal_approx(states[0].mass,states[1].mass) and is_equal_approx(states[1].mass,states[2].mass), "Calder same seed retains leaf mass across lever alternatives")
		n.apply_grid_config({"lever":"solved","evidence":"longhand"})
		observation["calder"] = states
	if artifacts.has("fractal_truss_tower"):
		var n: Node3D = artifacts.fractal_truss_tower
		n.set_process(false); n._t=0; n._process(0)
		var labels := n.find_children("*","Label3D",true,false)
		check(labels.size()==1, "truss retains its single board")
		if labels.size():
			check(labels[0].text.contains("MAX STRENGTH") if before else labels[0].text.contains("NO LOAD TEST"), "truss board distinguishes bracing geometry from proof of strength")
			observation["truss_plaque"] = labels[0].text
	if artifacts.has("tensegrity_triangle"):
		var n: Node3D = artifacts.tensegrity_triangle
		n.set_process(false); n._phase=0; n._process(PI/(2*n.load_speed))
		check(is_equal_approx(n.scale.y,1-n.load_amplitude), "triangle pulse directly prescribes squash, not solved load")
		n._phase=0; n._process(0)
	if artifacts.has("cable_builder"):
		var n: Node3D = artifacts.cable_builder; n.set_process(false)
		var p: Node3D = n.control_points[1]; var old: Vector3 = p.position
		p.position.y += .25; n._update_cable()
		check(n.curve.get_point_position(1).is_equal_approx(n.to_local(p.global_position)), "moving cable bead rebuilds spline through actual control position")
		p.position=old; n._update_cable()
func museum() -> void:
	var em: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	check(em.get_script().source_code==FileAccess.get_file_as_string(BASE+"frozen-museum.gd"),"actual museum scene uses saved shared loader bytes")
	observation["museum_source_sha256"]=em.get_script().source_code.sha256_text()
	var ctl := out+"museum-control.json"
	var f := FileAccess.open(ctl,FileAccess.WRITE); f.store_string(JSON.stringify({"first_chapter":"formfinding","dollhouse":0,"grid_pack":1}));f.close()
	em.set("EM_CONTROL",ctl);em.set("_overrides_path",ctl+".unused");em.set("_hand_path",ctl+".unused-hand")
	em.set("start_chapter","formfinding");em.set("start_map",hall)
	root.add_child(em);current_scene=em
	await create_timer(1.0).timeout
	em.set_process(false);em.set_physics_process(false);em.call("flush_stamps")
	for rec: Dictionary in em.get("_segments"):
		if rec.node.get_meta("em_map","")==hall: segment=rec.node
	check(segment!=null,"actual authored museum segment loads: " + hall)
	if not segment:return
	for i in 30:await process_frame
	var player: CharacterBody3D=em.get("_player");player.set_physics_process(false)
	# The scene's one-second guard reclaims its walker camera even when _process
	# is disabled. Suspend that guard only in this capture harness.
	for child in em.get("_cam").get_children():
		if child is Timer: child.stop()
	em.get("_feel").set_process(false)
	em.get("_wardrobe").appearance_save_path="";em.get("_wardrobe").costume.visible=false
	var placements := []
	for node in segment.find_children("*","Node3D",true,false):
		var key: String=node.get_meta("artifact_lookup_name","")
		if key!="" and not artifacts.has(key):
			artifacts[key]=node;placements.append({"key":key,"position":str(node.global_position),"script":node.get_script().resource_path if node.get_script() else ""})
	observation["placements"]=placements
	for key in artifacts:
		if key=="science_screen":
			var screen: Node=artifacts[key]
			observation["science_screen"]={"source":screen._source_artifact_name,"mode":screen._generic_mode_name,"generic":screen._generic_mode,"line":screen._line_mode,"triangle":screen._triangle_mode}
	for rec in em.get("_vis_records"):
		var n=rec.get("node")
		if n is Node3D and is_instance_valid(n) and segment.is_ancestor_of(n):n.visible=true
	cam=Camera3D.new();em.add_child(cam);cam.fov=56
func capture(id: String, object: Node3D, position: Vector3,target: Vector3) -> void:
	var pos:=object.to_global(position);var aim:=object.to_global(target)
	cam.global_position=pos;cam.look_at(aim);cam.make_current()
	for i in 20:await process_frame
	check(root.get_camera_3d()==cam, id + " intended camera remains active before render")
	await RenderingServer.frame_post_draw
	check(root.get_camera_3d()==cam, id + " intended camera remains active in saved frame")
	root.get_texture().get_image().save_png(out+id+".png")
	var f:=FileAccess.open(out+id+"-camera.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"position":str(pos),"target":str(aim),"fov":cam.fov,"viewport":str(root.size)},"  "));f.close()
func finish() -> void:
	var failures:=checks.filter(func(item):return not item.ok)
	var f:=FileAccess.open(out+"verification.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observation,"replay_before":before,"headset_tested":false,"interaction":"source methods and physics mask queries; no real tracked hand"},"  "));f.close()
	print("FORM FINDING STRUCTURE CHECKS ",checks.size()," FAILURES ",failures.size())
	quit(0 if failures.is_empty() else 1)
