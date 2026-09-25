extends SceneTree
## Focused checks in the real isolated museum. Supplied controls, no headset claim.
var checks: Array = []
var failures: Array = []
var observations: Dictionary = {}
var museum: Node3D
var hall: Node3D
var camera: Camera3D
var folder: String
var map_id: String

func _initialize() -> void: run.call_deferred()
func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"passed":passed})
	if not passed: failures.append(label)
	print("[transformation] ", "PASS " if passed else "FAIL ", label)
func xyz(p: Vector3) -> Array: return [p.x,p.y,p.z]
func find_scene(suffix: String) -> Node3D:
	for n in hall.find_children("*", "Node3D", true, false):
		if n.get_script() != null and str(n.get_script().resource_path).ends_with(suffix): return n
	return null
func tick() -> void:
	await physics_frame
	await process_frame
func select_pair(bench: Node3D, index: int) -> void:
	bench._slider.set_normalized_value(float(index) / 3.0)
	bench._slider.slider_moved.emit(Vector3.ZERO)
	await create_timer(0.25).timeout
func floor_at(p: Vector3) -> Dictionary:
	var ray := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 0.3, p + Vector3.DOWN * 0.6, 1)
	return hall.get_world_3d().direct_space_state.intersect_ray(ray)
func snapshot(name: String, eye: Vector3, target: Vector3, fov: float = 55.0) -> void:
	if DisplayServer.get_name() == "headless": return
	camera.global_position = eye
	camera.look_at(target)
	camera.fov = fov
	camera.current = true
	await create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	check("capture camera retained: " + name, root.get_camera_3d() == camera)
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder + name + ".png"))

func run() -> void:
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	folder = spec.run
	map_id = spec.room
	museum = load(folder + "museum_snapshot.tscn").instantiate()
	museum.set("EM_CONTROL",folder+"control.json")
	museum.set("_hand_path",folder+"necklace_hand.json")
	museum.set("_overrides_path",folder+"em_overrides.json")
	museum.set("start_chapter",spec.sequence)
	museum.set("start_map",map_id)
	museum.set("plan_file",folder+"plan.json")
	root.add_child(museum)
	current_scene = museum
	var start := Time.get_ticks_msec()
	while not bool(museum.get("_museum_core_ready")) and Time.get_ticks_msec()-start < 60000: await process_frame
	museum.set("_lazy_pending",0)
	museum.set_process(false)
	museum.set_physics_process(false)
	await create_timer(1.0).timeout
	for child in museum.get_children():
		if child is Node3D and str(child.get_meta("em_map","")) == map_id: hall = child; break
	check("requested museum hall loaded",hall != null)
	if hall == null: finish(); return
	camera = Camera3D.new();root.add_child(camera)
	var previous: Camera3D = museum.get("_cam")
	if previous != null:
		for timer in previous.find_children("*","Timer",true,false):timer.stop()
	if map_id == "Trans_Rotation": await rotation_checks()
	else: await landing_checks()
	finish()

func rotation_checks() -> void:
	var bench := find_scene("/transform_composition_workbench.gd")
	var arrays := find_scene("/array_compare.gd")
	var axial := find_scene("/axial_sweep.gd")
	check("existing workbench placed with both rotation studies", bench != null and arrays != null and axial != null)
	if bench == null or arrays == null or axial == null: return
	observations["workbench_world"] = xyz(bench.global_position)
	observations["initial_pair"] = bench._pair_index
	observations["slider_value"] = bench._slider.get_normalized_value()
	observations["configured_pair"] = bench.get_meta("config_initial_pair", "missing")
	check("numeric pair retains map orientation", is_equal_approx(fposmod(bench.rotation_degrees.y,360),180))
	check("map selects the X/Y pair",bench._pair_index == 3)
	check("map reveals intermediate forms",bench.workings == "trace" and bench._workings_root.get_child_count() >= 2)
	var pair: Dictionary = bench._pairs[3]
	var x: Transform3D = pair.t1_xform
	var y: Transform3D = pair.t2_xform
	check("X/Y order changes actual basis",not (y*x).basis.is_equal_approx((x*y).basis))
	var first_left: Node3D = bench._left_root.get_child(0)
	var first_right: Node3D = bench._right_root.get_child(0)
	check("rendered blue form receives X then Y", first_left.basis.is_equal_approx(bench._stage_transform(y*x,Vector3.ZERO).basis))
	check("rendered red form receives Y then X", first_right.basis.is_equal_approx(bench._stage_transform(x*y,Vector3.ZERO).basis))
	await snapshot("order-comparison",bench.to_global(Vector3(0,1.7,2.5)),bench.to_global(Vector3(0,1.6,-0.1)),48)
	await select_pair(bench,1)
	check("real slider signal selects commuting pair",bench._pair_index == 1)
	pair = bench._pairs[1]; x=pair.t1_xform;y=pair.t2_xform
	check("rotation and uniform scale commute",(y*x).is_equal_approx(x*y))
	check("commuting pair has different intermediate poses",not x.is_equal_approx(y))
	await snapshot("commuting-comparison",bench.to_global(Vector3(0,1.7,2.5)),bench.to_global(Vector3(0,1.6,-0.1)),48)
	await select_pair(bench,3)
	check("visitor can return to the X/Y pair",bench._pair_index == 3)
	var count := 0
	for band in arrays.bands:
		var marker: MeshInstance3D = band.witnesses
		check(str(band.id)+" marks are two batched surfaces",marker.mesh.get_surface_count()==2)
		check(str(band.id)+" mark has no collision",marker.get_child_count()==0)
		for cube: Node3D in band.cubes:
			count += 1
			var collision: CollisionShape3D = cube.get_node("Body/CollisionShape3D") if cube.has_node("Body/CollisionShape3D") else cube.find_child("*Collision*",true,false)
			# The production helper leaves collision nodes unnamed; inspect the body.
			if collision == null:
				for c in cube.get_node("Body").get_children():
					if c is CollisionShape3D:collision=c;break
			check("cube geometry unchanged "+str(band.id)+" "+str(cube.name),collision != null and collision.shape.size.is_equal_approx(Vector3.ONE*arrays.EDGE))
	check("all 48 cubes retain their collision",count == 48)
	var yband: Dictionary = arrays.bands[1]
	await snapshot("array-mark-zero",yband.node.to_global(Vector3(-4,2,-3)),yband.node.to_global(Vector3(-0.6,-0.5,1)),55)
	await snapshot("array-mark-ninety",yband.node.to_global(Vector3(-4,2,11)),yband.node.to_global(Vector3(-0.6,-0.5,10)),55)
	var at_zero: Transform3D = yband.cubes[0].transform
	var at_ninety: Transform3D = yband.cubes[-1].transform
	check("Y top mark changes direction at 90 degrees",not (at_zero.basis*Vector3.RIGHT).is_equal_approx(at_ninety.basis*Vector3.RIGHT))
	axial.playing=false;axial.seek(0)
	var witness: MeshInstance3D = axial.meshspin.get_node_or_null("FaceWitness")
	check("sweep cube has an attached face witness",witness != null)
	if witness != null:
		var direction: Vector3 = witness.global_basis*Vector3.FORWARD
		axial.seek(5.0)
		check("witness follows the sweep quarter-turn",absf(direction.dot(witness.global_basis*Vector3.FORWARD)) < 0.0001)
		axial.seek(0.9)
		await snapshot("marked-sweep",axial.to_global(Vector3(-1.2,2.5,-2)),axial.to_global(Vector3(0,2,0)),48)
	axial.set_shape("triangle");await tick()
	check("cube witness removed for triangular profile",axial.meshspin.get_node_or_null("FaceWitness")==null)
	axial.set_shape("cube");await tick()
	check("cube witness restored after shape toggle",axial.meshspin.get_node_or_null("FaceWitness")!=null)
	var approach := bench.to_global(Vector3(0,0,1.25))
	var hit := floor_at(approach)
	check("comparison has floor at visitor approach",not hit.is_empty() and absf(hit.position.y-bench.global_position.y)<0.02)
	observations["approach"] = xyz(approach)
	await snapshot("array-and-comparison",bench.to_global(Vector3(-3,3,5)),bench.global_position+Vector3.UP,65)

func landing_checks() -> void:
	var bank := find_scene("/adjustable_landing.gd")
	var bridge := find_scene("/rotation_cube.gd")
	check("landing and rotating bridge exist",bank != null and bridge != null)
	if bank == null or bridge == null: return
	# Freeze the production aligned pose for both bank photographs.
	bridge.pause_timer=0;bridge.is_rotating=true;bridge.current_angle=0
	bridge.target_angle=bridge.rotation_angle
	bridge._process(bridge.rotation_angle/bridge.rotation_speed)
	bridge.set_process(false);bridge.set_physics_process(false)
	check("comparison uses the aligned quarter-turn",is_equal_approx(bridge.current_angle,90))
	var bridge_before: Transform3D = bridge.mesh_instance.global_transform
	var landing_before: Vector3 = bank.landing.global_position
	check("control relocated to near bank",bank.control_rig.position.is_equal_approx(Vector3(1,0,-3)))
	check("landing home kept independently",bank.landing.position.is_equal_approx(bank.HOME))
	var approach := bank.to_global(Vector3(1,0,-3.8))
	var hit := floor_at(approach)
	check("control approach has support",not hit.is_empty() and absf(hit.position.y-bank.global_position.y)<0.02)
	var height: float = bank.slider.global_position.y-bank.global_position.y
	check("bank slider remains at reachable height",height > 0.9 and height < 1.3)
	observations["slider_height_m"] = height
	observations["controls_world"] = xyz(bank.control_rig.global_position)
	bank.slider.set_normalized_value(1.0);bank.slider.slider_moved.emit(Vector3.ZERO)
	check("real slider signal changes destination",is_equal_approx(bank.target_displacement,1))
	await create_timer(4.2).timeout
	check("bank moves one metre",is_equal_approx(bank.displacement,1))
	check("landing stays level",absf(bank.landing.global_position.y-landing_before.y)<0.0001)
	check("control move never changes bridge transform",bridge.mesh_instance.global_transform.is_equal_approx(bridge_before))
	await snapshot("bank-gap",bank.to_global(Vector3(3,2.4,-4.8)),bank.to_global(Vector3(1.6,0.8,-0.6)),65)
	var button: Node = bank.find_child("Btn_0",true,false).get_node("InteractableAreaButton")
	button.button_pressed.emit(button)
	await create_timer(4.2).timeout
	check("RESET restores bank home",is_zero_approx(bank.displacement) and bank.landing.global_position.is_equal_approx(landing_before))
	check("RESET returns slider",is_zero_approx(float(bank.slider.get_normalized_value())))
	await snapshot("bank-at-crossing",bank.to_global(Vector3(3,2.4,-4.8)),bank.to_global(Vector3(1.6,0.8,-0.6)),65)
	await snapshot("bank-control-close",bank.to_global(Vector3(1,1.7,-4.3)),bank.to_global(Vector3(1,1.2,-3.1)),55)

func finish() -> void:
	var result := {"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Real museum, supplied slider/reset events and geometry checks; headset and learner understanding untested."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("TRANSFORMATION ENCOUNTERS ",map_id," ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
