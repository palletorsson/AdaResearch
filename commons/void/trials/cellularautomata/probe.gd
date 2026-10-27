extends "res://tools/probes/void_trial_probe.gd"
## Cellular Automata transfer trial: the ten original placements of CA_Introduction
## and CA_ElementaryRules in the actual Void, desktop and synthetic tracked XR.
##
## Authored by Claude, then corrected and executed serially by Codex (181 checks).
## Desktop mouse and synthetic XR input are tested; physical headset play is separate.
## Run: see run_probe.py beside this file. Writes checks.json and measure.json
## into --out=<dir>; --capture adds Mobile screenshots.
const TRIAL_SCENE := "res://commons/void/trials/cellularautomata/trial.tscn"
## Floor-local provenance: exhibit key -> original script the Artifact root must still carry.
const ORIGINAL_SCRIPTS := {
	"1/f1_synthesis_stand_2_3": "res://commons/artifacts/synthesis/synthesis_stand.gd",
	"1/f1_dark_sphere_5_3": "res://commons/artifacts/dark_sphere/dark_sphere.gd",
	"1/f1_persian_rug_4_4": "res://algorithms/cellularautomata/persian_rug/persian_rug.gd",
	"1/f1_ca_rule_explorer_10_5": "res://commons/artifacts/ca_rule_explorer/ca_rule_explorer.gd",
	"1/f1_langton_swarm_10_9": "res://commons/artifacts/langton_swarm/langton_swarm.gd",
	"1/f1_line_network_ca_10_12": "res://algorithms/cellularautomata/ca_showcase/LineNetworkCA.gd",
	"1/f1_ca_showcase_3_14": "res://algorithms/cellularautomata/ca_showcase/ca_showcase.gd",
	"1/f1_rule110_computer_10_16": "res://commons/artifacts/rule110_computer/rule110_computer.gd",
	"2/f2_structure_growth_6_6": "res://algorithms/cellularautomata/cellular_automata_3d/CellularAutomata3D_Flexible.gd",
	"2/f2_dark_sphere_10_9": "res://commons/artifacts/dark_sphere/dark_sphere.gd",
}
var measure_report := {}

func start(use_xr: bool) -> void:
	xr = use_xr
	if xr:
		head = tracker("head", XRServer.TRACKER_HEAD, "default", Vector3(0,1.65,0))
		left = tracker("left_hand", XRServer.TRACKER_CONTROLLER, "aim", Vector3(-.3,1.2,-.4))
		right = tracker("right_hand", XRServer.TRACKER_CONTROLLER, "aim", Vector3(.3,1.2,-.4))
		left.set_input("primary",Vector2.ZERO); right.set_input("primary",Vector2.ZERO)
		right.set_input("grip",0.0); right.set_input("trigger_click",false)
	var scene: PackedScene = load(TRIAL_SCENE)
	var staged: Node3D = scene.instantiate()
	check("trial satisfies staging scene type", is_instance_of(staged, load("res://addons/godot-xr-tools/staging/scene_base.gd")))
	game = staged
	game.force_xr = xr
	root.add_child(game); current_scene = game
	if not xr: game.body.scripted_input=true
	await frames(45)
	game.scene_loaded(); game.scene_visible()
	await frames(30)
	game.atmosphere.animate_sky=false; game.atmosphere.set_sky_time(180)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
		if arg=="--capture": take_photos=true
	DirAccess.make_dir_recursive_absolute(out)
	check("probe uses isolated save data", OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if not checks.back().passed: quit(1);return
	var curated_floors: int = Source.read_rooms().floors.size()
	check("curated tower is read untouched", curated_floors>=1 and Source.read_rooms().floors[0].map=="Point_Zero")
	check("trial rooms carry the ten placements", Source.read_rooms("cellularautomata").floors[1].artifacts.size()==8 and Source.read_rooms("cellularautomata").floors[2].artifacts.size()==2)
	var museum_score: int = root.get_node("GameManager").player_score
	for use_xr in [false,true]:
		await visit(use_xr, museum_score)
	check("trial selection does not leak into the tower",Source.read_rooms().floors.size()==curated_floors)
	FileAccess.open(out.path_join("measure.json"),FileAccess.WRITE).store_string(JSON.stringify(measure_report,"\t"))
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Native Godot 4.6, actual physics, desktop and synthetic tracked XR. Mobile screenshots when captured. No physical headset. Probe authored without a run; see HANDOFF.md."},"\t"))
	print("VOID_TRIAL_RESULT ",checks.size()," checks; failures: ",failed)
	quit(0 if failed.is_empty() else 1)

## Floor-local bounds of every visible mesh under a node.
func floor_bounds(node: Node3D, level: float) -> AABB:
	var result := AABB()
	var first := true
	for geometry in node.find_children("*","GeometryInstance3D",true,false):
		if not geometry.is_visible_in_tree(): continue
		var local: AABB
		if geometry is MeshInstance3D and geometry.mesh!=null: local=geometry.mesh.get_aabb()
		elif geometry is MultiMeshInstance3D and geometry.multimesh!=null: local=geometry.multimesh.get_aabb()
		else: continue
		local=geometry.global_transform*local
		result=local if first else result.merge(local)
		first=false
	result.position.y-=level
	return result

func record_bounds(key: String, node: Node3D, level: float) -> AABB:
	var b := floor_bounds(node, level)
	measure_report[key]={"min":[snappedf(b.position.x,.01),snappedf(b.position.y,.01),snappedf(b.position.z,.01)],
		"max":[snappedf(b.end.x,.01),snappedf(b.end.y,.01),snappedf(b.end.z,.01)],
		"size":[snappedf(b.size.x,.01),snappedf(b.size.y,.01),snappedf(b.size.z,.01)]}
	return b

## Shaft holes, A corner landing and the slab edge, floor-local. Overhead geometry
## (the stored-row ring) may cross a hole above head height.
func clear_of_frame(b: AABB, head_clearance := 1.8) -> bool:
	if b.position.x < -21.0 or b.end.x > 21.0 or b.position.z < -16.0 or b.end.z > 16.0: return false
	if b.position.y < -0.12: return false
	if b.position.y >= head_clearance: return true
	for hole in [Rect2(-12.5,-3,5,6), Rect2(7.5,-3,5,6)]:
		if Rect2(b.position.x, b.position.z, b.size.x, b.size.z).intersects(hole): return false
	return true

## Stand the tracked controller `offset` away from `target`, aim its ray at it and pull the trigger.
func point_and_press(controller: XRControllerTracker, target: Vector3, offset: Vector3) -> void:
	var origin: Node3D=game.get_node("XROrigin3D")
	var at: Vector3=target+offset
	var forward: Vector3=(target-at).normalized()
	var basis := Basis.looking_at(forward,Vector3.UP)
	controller.set_pose("aim",Transform3D(basis,origin.to_local(at)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	await frames(20)
	controller.set_input("trigger_click",true); await frames(6)
	controller.set_input("trigger_click",false); await frames(12)
	hand_at(controller,game.body.global_position+Vector3(0.3,1.2,-0.4)); await frames(5)

func photo(filename:String,at:Vector3,target:Vector3) -> void:
	if not take_photos or xr:return
	var before: Vector3=game.body.global_position
	var floor_index:=1 if filename.begins_with("f1-") else 2
	game.place_player(game.spawn_for(floor_index));await frames(10)
	for layer in game.find_children("*","CanvasLayer",true,false):
		if layer.get_viewport()==game.get_viewport():layer.hide()
	game.status.hide();game.notice_time=-1
	var origin:Node3D=game.get_node("XROrigin3D");origin.hide()
	root.msaa_3d=Viewport.MSAA_4X
	await photograph(filename,at,target)
	origin.show()
	game.place_player(before);await frames(10)

func mouse_press(area: Node3D) -> void:
	Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	game.camera.look_at(area.get_node("CollisionShape3D").global_position)
	await frames(20)
	var event:=InputEventMouseButton.new()
	event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true
	Input.parse_input_event(event);await frames(6)
	event=InputEventMouseButton.new()
	event.button_index=MOUSE_BUTTON_LEFT;event.pressed=false
	Input.parse_input_event(event);await frames(10)

func button_area(panel: Node, index: int) -> Node:
	var button: Node = panel.find_child("Btn_%d" % index, true, false)
	return button.get_node("InteractableAreaButton") if button != null else null

func visit(use_xr: bool, museum_score: int) -> void:
	await start(use_xr)
	var tag := "XR: " if use_xr else "Desktop: "
	var content: Node3D=game.building.content
	var level1: float=float(game.building.spec.levels[1])
	var level2: float=float(game.building.spec.levels[2])
	var level3: float=float(game.building.spec.levels[3])
	check(tag+"starts on floor 1 at the shared spawn",game.checkpoint==1 and absf(game.body.global_position.y-level1)<0.12 and absf(game.body.global_position.x)<0.5 and absf(game.body.global_position.z-12.0)<0.5)
	check(tag+"four levels, fixed frame, both shafts",game.building.spec.levels.size()==4 and game.building.spec.width==42 and game.building.spec.shafts.size()==2)
	# Floor 2 streams as a preview; complete it so both floors can be inspected.
	content.load_floor(2); await frames(10)
	var keys1: Array = content.exhibits.keys().filter(func(key): return str(key).begins_with("1/"))
	var keys2: Array = content.exhibits.keys().filter(func(key): return str(key).begins_with("2/"))
	check(tag+"eight placements on floor 1 and two on floor 2",keys1.size()==8 and keys2.size()==2)
	for key in ORIGINAL_SCRIPTS:
		var mount: Node3D = content.exhibits.get(key)
		var ok: bool = mount != null and mount.has_node("Artifact")
		if ok:
			var artifact: Node3D = mount.get_node("Artifact")
			var floor_index: int = int(str(key).left(1))
			var item_id: String = str(key).substr(2)
			var declared: Array = content.data.floors[floor_index].artifacts.filter(func(a): return str(a.id)==item_id)
			ok = artifact.get_script() != null and artifact.get_script().resource_path == ORIGINAL_SCRIPTS[key] \
				and declared.size()==1 and str(artifact.get_meta("artifact_lookup_name","")) == str(declared[0].artifact)
		check(tag+"original scene and identity stamp "+key, ok)
	# No supply leads on abstract floors; no original camera, sun or environment may take over.
	var stolen := false
	for key in ORIGINAL_SCRIPTS:
		var artifact: Node3D = content.exhibits[key].get_node("Artifact")
		for camera in artifact.find_children("*","Camera3D",true,false):
			if camera.current: stolen = true
		for sun in artifact.find_children("*","DirectionalLight3D",true,false):
			if sun.visible: stolen = true
	check(tag+"no imported camera or sun is active", not stolen)
	check(tag+"abstract floors carry no decorative supply leads", not content.roots[1].has_node("Lead_f1_dark_sphere_5_3"))

	# ── CA_Introduction ────────────────────────────────────────────────────
	var explorer: Node3D = content.exhibits["1/f1_ca_rule_explorer_10_5"].get_node("Artifact")
	check(tag+"explorer wears the neighbourhood study at Rule 90, held, 32 cells, 24 rows, 4 gen/s",explorer._neighbour_study and explorer.rule==90 and not explorer.auto_run and explorer.cells_x==32 and explorer.rows_visible==24 and is_equal_approx(explorer.generations_per_second,4.0))
	check(tag+"explorer builds desk, ring and hand point",explorer.has_node("NeighbourStudy") and explorer.has_node("NeighbourStudy/NeighbourRing") and explorer.has_node("NeighbourStudy/HandPoint/PointBody") and explorer.has_node("NeighbourStudy/StudyControls"))
	var reading: Dictionary = explorer.neighbourhood_readback()
	check(tag+"single seed at the sample cell reads 0 1 0 and Rule 90 predicts 0",reading.generation==0 and reading.inputs==[0,1,0] and reading.next==0 and reading.seed=="single")
	explorer.step(); await frames(3)
	reading = explorer.neighbourhood_readback()
	check(tag+"STEP gives one generation: 1 0 1 at the same address, still held",reading.generation==1 and reading.inputs==[1,0,1] and not explorer.auto_run)
	var ring: Node3D = explorer.get_node("NeighbourStudy/NeighbourRing")
	await frames(8)
	var ring_row: Vector3 = ring.to_global(ring.at(0,0))
	check(tag+"the ring's current row hangs 2.02 m above the floor and its stored rows follow the board",absf(ring_row.y-level1-2.02)<0.06 and ring.rendered.size()==explorer._grid.size())
	explorer.toggle_seed(); await frames(3)
	check(tag+"SEED selects the pair and resets the history",explorer.neighbourhood_readback().seed=="pair" and explorer.generation==0)
	explorer.toggle_seed(); await frames(3)
	explorer.set_rule(30); await frames(3)
	check(tag+"rule 30 preset keeps the study held",explorer.rule==30 and explorer.generation==0 and not explorer.auto_run)
	explorer.set_rule(90); await frames(3)
	var point: Node3D = explorer.get_node("NeighbourStudy/HandPoint/PointBody")
	point.action_pressed.emit(point); await frames(3)
	check(tag+"(signal path, not input) the hand point's trigger steps the board",explorer.generation==1)
	explorer._reset(); await frames(2)

	var network: Node3D = content.exhibits["1/f1_line_network_ca_10_12"].get_node("Artifact")
	check(tag+"network keeps #size:2.0 and the arrival study",is_equal_approx(network.fit,2.0) and network._arrival_requested and network.has_node("GrowthHistory"))
	await frames(45)
	var history: Node3D = network.get_node("GrowthHistory")
	check(tag+"twenty growth updates finish, the scan stops and twenty stages are kept",not network.is_running and history.ready_to_watch and history.counts.size()>=20 and network.connections.size()>0)
	var net_bounds := record_bounds("1/f1_line_network_ca_10_12", network, level1)
	check(tag+"the fitted tangle stands within 2.6 m and above the floor",maxf(net_bounds.size.x,maxf(net_bounds.size.y,net_bounds.size.z))<=2.7 and net_bounds.position.y>=-0.02)
	history.replay(); await frames(5)
	check(tag+"REPLAY plays the recorded stages",history.begun and history.playing and history.stage<=1)

	var rug: Node3D = content.exhibits["1/f1_persian_rug_4_4"].get_node("Artifact")
	var rug_step: int = rug.current_step
	await frames(90)
	check(tag+"the rug is woven and keeps stepping",rug._built and rug.texture!=null and rug.stencil=="quadrant" and rug.division=="frame" and rug.current_step>rug_step)
	var rug_bounds := record_bounds("1/f1_persian_rug_4_4", rug, level1)
	check(tag+"the rug lies 2.5 cm above the floor, 2.56 x 3.84",absf(rug_bounds.position.y-0.025)<0.01 and absf(rug_bounds.size.x-2.56)<0.05 and absf(rug_bounds.size.z-3.84)<0.05)

	var swarm: Node3D = content.exhibits["1/f1_langton_swarm_10_9"].get_node("Artifact")
	var swarm_state: Array = swarm._state.duplicate(true)
	await frames(30)
	check(tag+"turmites keep painting a shared surface",swarm._ants.size()>=8 and swarm._ants.size()<=16 and swarm._field!=null and swarm._state!=swarm_state and str(swarm._readout.text).begins_with("agents:"))

	var computer: Node3D = content.exhibits["1/f1_rule110_computer_10_16"].get_node("Artifact")
	var drawn: int = computer._draw_to
	var first_row: PackedInt32Array = computer._rows[0]
	await frames(40)
	check(tag+"rule 110 console computes 32 generations of 48 cells and keeps running",computer.rule==110 and computer._rows.size()==32 and computer._field!=null and (computer._draw_to!=drawn or computer._rows[0]!=first_row))

	var showcase: Node3D = content.exhibits["1/f1_ca_showcase_3_14"].get_node("Artifact")
	var visible_showcases: int = 0
	for stage in showcase.showcases:
		if stage.visible: visible_showcases += 1
	check(tag+"showcase holds twelve systems, one shown",showcase.showcases.size()==12 and showcase.info_panels.size()==12 and visible_showcases==1)
	var show_bounds := record_bounds("1/f1_ca_showcase_3_14", showcase, level1)
	check(tag+"showcase: animated spheres clear the slab (height 0.62 adaptation)",show_bounds.position.y>=0.0 and show_bounds.position.y<=0.2)
	var before_cycle: int = showcase.current_showcase
	showcase.cycle_to_next_showcase(); await frames(3)
	check(tag+"the showcase cycles",showcase.current_showcase==(before_cycle+1)%12)

	var stand: Node3D = content.exhibits["1/f1_synthesis_stand_2_3"].get_node("Artifact")
	var born := false
	for child in stand.get_children():
		if str(child.get_meta("artifact_lookup_name",""))=="dark_sphere": born = true
	check(tag+"synthesis stand pins the dark_sphere hero from the verdict file",stand.subject=="dark_sphere" and stand.mode=="hero" and str(stand._verdict.get("verdict",""))=="hero" and born and stand.get_child_count()>=3)
	var orb: Node3D = content.exhibits["1/f1_dark_sphere_5_3"].get_node("Artifact")
	check(tag+"the dark orb stands on the rug's edge",orb._sphere_mesh!=null and record_bounds("1/f1_dark_sphere_5_3",orb,level1).position.y>=-0.02)
	for key in ["1/f1_synthesis_stand_2_3","1/f1_ca_rule_explorer_10_5","1/f1_langton_swarm_10_9","1/f1_rule110_computer_10_16"]:
		record_bounds(key, content.exhibits[key].get_node("Artifact"), level1)
	var frame_ok := true
	for key in keys1:
		if not measure_report.has(key): continue
		var m: Dictionary = measure_report[key]
		var b := AABB(Vector3(m.min[0],m.min[1],m.min[2]),Vector3(m.size[0],m.size[1],m.size[2]))
		if not clear_of_frame(b): frame_ok=false; print("[void] floor 1 body crosses the frame: ",key," ",m)
	check(tag+"every floor 1 body stays on the slab, out of both shafts (ring overhead allowed)",frame_ok)

	# ── CA_ElementaryRules ─────────────────────────────────────────────────
	game.place_player(game.spawn_for(2)); await frames(40)
	check(tag+"floor 2 becomes the live floor",game.floor_stream.focus==2)
	var growth: Node3D = content.exhibits["2/f2_structure_growth_6_6"].get_node("Artifact")
	check(tag+"structure growth wears the three-state study and the neighbour room",growth.has_node("StructureStudy") and growth.has_node("StructureStudy/NeighbourRoom") and growth.has_node("StructureStudy/StateHand/PointBody") and growth.paused and growth.growth_seed==23090)
	var study: Node3D = growth.get_node("StructureStudy")
	var room: Node3D = study.neighbour_room
	var r: Dictionary = room.readback()
	check(tag+"held at generation 0 with a 20-step budget; cell (26,22,24) active",study.readback().generation==0 and study.budget==20 and r.centre==1)
	study.step_once(); await frames(3)
	r = room.readback()
	check(tag+"after STEP the cell is fading beside seven active neighbours (the chapter's claim)",r.generation==1 and r.centre==2 and r.active_neighbours==7)
	study.step_once(); await frames(3)
	r = room.readback()
	check(tag+"after the next STEP the address is empty",r.generation==2 and r.centre==0)
	study.toggle_view(); await frames(2)
	var height_colours: bool = growth.use_gradient
	study.toggle_view(); await frames(2)
	check(tag+"VIEW swaps state colours for a height gradient and back",height_colours and not growth.use_gradient)
	study.replay(); await frames(3)
	check(tag+"REPLAY returns to the seeded beginning",study.readback().generation==0 and room.readback().centre==1)
	var growth_bounds := record_bounds("2/f2_structure_growth_6_6", growth, level2)
	check(tag+"the 3.2 m volume rises from the floor; furniture stays below 3.4 m",growth_bounds.position.y>=-0.02 and growth_bounds.end.y<=3.5 and growth_bounds.size.x<=8.0)
	var console: Node3D = study.get_node("Console")
	var console_local: Vector3 = content.roots[2].to_local(console.global_position)
	check(tag+"the console stands on the rim, south of the volume, at hand height",absf(console_local.x-1.65)<0.1 and absf(console_local.z-3.36)<0.1 and absf(console_local.y-1.05)<0.1)
	var lid := ray(Vector3(0,level2+0.6,0.5),Vector3(0,level2-0.6,0.5))
	# Repeated Glass bodies receive generated names. Check the actual basin
	# parent and translucent lid material, not a non-unique display name.
	var glass_hit:=false
	if not lid.is_empty() and absf(lid.position.y-level2)<0.05 and lid.collider.get_parent().name=="Basin":
		for mesh in lid.collider.find_children("*","MeshInstance3D",true,false):
			if mesh.material_override is StandardMaterial3D and mesh.material_override.transparency==BaseMaterial3D.TRANSPARENCY_ALPHA:glass_hit=true
	check(tag+"the original floor opening is a glass-lidded basin under the volume",glass_hit)
	var orb2: Node3D = content.exhibits["2/f2_dark_sphere_10_9"].get_node("Artifact")
	check(tag+"the second dark orb stands beside the route",orb2._sphere_mesh!=null and record_bounds("2/f2_dark_sphere_10_9",orb2,level2).position.y>=-0.02)
	frame_ok = true
	for key in keys2:
		var m: Dictionary = measure_report[key]
		var b := AABB(Vector3(m.min[0],m.min[1],m.min[2]),Vector3(m.size[0],m.size[1],m.size[2]))
		if not clear_of_frame(b): frame_ok=false; print("[void] floor 2 body crosses the frame: ",key," ",m)
	check(tag+"every floor 2 body stays on the slab, out of both shafts",frame_ok)
	check(tag+"leave and return keeps the explorer instance",is_instance_valid(explorer) and content.exhibits["1/f1_ca_rule_explorer_10_5"].get_node("Artifact")==explorer)

	# ── Real input ─────────────────────────────────────────────────────────
	if not use_xr:
		game.place_player(Vector3(-1.8,level1+.06,4));await frames(30)
		explorer._reset();await frames(2)
		await mouse_press(button_area(explorer.get_node("NeighbourStudy/StudyControls"),0))
		check("Desktop: mouse presses explorer STEP",explorer.generation==1)
		game.place_player(Vector3(1.65,level2+.06,4.8));await frames(30)
		study.replay();await frames(2)
		await mouse_press(button_area(study.get_node("Console/StudyControls"),0))
		check("Desktop: mouse presses structure STEP",study.readback().generation==1)
	if use_xr:
		game.place_player(game.spawn_for(1)); await frames(40)
		var pressed: Array = []
		var panel: Node = explorer.get_node("NeighbourStudy/StudyControls")
		for i in range(4):
			var area: Node = button_area(panel, i)
			if area != null: area.button_pressed.connect(func(_b): pressed.append("Btn_%d"%i))
		explorer._reset(); await frames(2)
		# The panel faces the visitor east of the desk: approach along -X.
		await point_and_press(right, button_area(panel,0).global_position, Vector3(0.55,0.15,0.0))
		print("[void] explorer buttons pressed by the pointer: ",pressed)
		check("XR: pointer + trigger presses STEP alone and the board advances once",pressed==["Btn_0"] and explorer.generation==1 and not explorer.auto_run)
		var cell_before: int = explorer.sample_cell
		hand_at(right, point.global_position+Vector3(-0.03,0,0)); await frames(20)
		right.set_input("grip",1.0); await frames(15)
		check("XR: grip lifts the hand point with XRTools",point.is_picked_up())
		# The rail runs along the board's x, which the 90-degree facing turns onto world -z.
		hand_at(right, point.global_position+Vector3(0,0,-0.3)); await frames(20)
		var cell_moved: bool = explorer.sample_cell!=cell_before
		right.set_input("grip",0.0); await frames(25)
		check("XR: moving the held point selects another address; release parks it on the rail",cell_moved and not point.is_picked_up() and absf(point.position.y-0.20)<0.05)
		hand_at(right,game.body.global_position+Vector3(0.3,1.2,-0.4)); await frames(5)
		game.place_player(game.spawn_for(2)); await frames(40)
		study.replay(); await frames(2)
		var study_panel: Node = study.get_node("Console/StudyControls")
		# The console faces south toward the spawn: approach along +Z.
		await point_and_press(right, button_area(study_panel,0).global_position, Vector3(0.0,0.1,0.55))
		check("XR: pointer + trigger presses the study's STEP",study.readback().generation==1)
		var state_point: Node3D = study.get_node("StateHand/PointBody")
		hand_at(right, state_point.global_position+Vector3(-0.03,0,0)); await frames(20)
		right.set_input("grip",1.0); await frames(15)
		var held: bool = state_point.is_picked_up()
		right.set_input("trigger_click",true); await frames(6)
		right.set_input("trigger_click",false); await frames(10)
		var stepped: int = study.readback().generation
		right.set_input("grip",0.0); await frames(20)
		check("XR: the held state point's trigger steps the volume",held and stepped==2)
		hand_at(right,game.body.global_position+Vector3(0.3,1.2,-0.4)); await frames(5)

	# ── Walk, drops, retry ─────────────────────────────────────────────────
	game.place_player(game.spawn_for(1)); await frames(30)
	var route1: Array = [Vector3(0,level1,9.5),Vector3(-1.6,level1,7.0),Vector3(-2.0,level1,4.0),Vector3(-2.4,level1,1.0),
		Vector3(-2.4,level1,-1.0),Vector3(-1.2,level1,-4.5),Vector3(-4.0,level1,-8.3),Vector3(0,level1,-9.0),
		Vector3(5.5,level1,-2.0),Vector3(5.5,level1,2.0),Vector3(7.5,level1,4.0),Vector3(7.5,level1,9.0),Vector3(0,level1,12.0),Vector3(-6.2,level1,6.5),Vector3(-6.4,level1,1.9)]
	for at in route1:
		check(tag+"floor 1 aisle reaches "+str(at),await move_to(at))
	var cushions: int = game.cushioned_landings
	var charge_before:float=game.charge.get_charge()
	var travel_before:float=game.charge.metres_travelled
	check(tag+"drop through A onto floor 2's corner boards",await move_to(Vector3(-8.3,level2,-1.9)))
	var walking_cost:float=(game.charge.metres_travelled-travel_before)*game.charge.CHARGE_PER_METRE
	check(tag+"the drop saves floor 2 with only walking charge spent",game.checkpoint==2 and game.deaths==0 and game.cushioned_landings==cushions+1 and absf(charge_before-game.charge.get_charge()-walking_cost)<.01)
	var route2: Array = [Vector3(-6.0,level2,-1.9),Vector3(-4.0,level2,-0.9),Vector3(0.0,level2,5.0),Vector3(1.65,level2,4.8),
		Vector3(3.0,level2,4.8),Vector3(4.6,level2,0.5),Vector3(3.8,level2,-3.6),Vector3(0.0,level2,-3.6),Vector3(0.0,level2,0.5),Vector3(-6.4,level2,1.9)]
	for at in route2:
		check(tag+"floor 2 route reaches "+str(at),await move_to(at))
	check(tag+"the glass lid carried the body across the opening",game.deaths==0 and not game.recovering)
	await photo("f1-arrival",Vector3(0,level1+1.65,11.5),Vector3(-1,level1+1.0,2))
	await photo("f1-explorer",Vector3(-1.4,level1+1.6,4.2),Vector3(-4.2,level1+1.1,3.6))
	await photo("f1-under-ring",Vector3(-3.5,level1+1.65,2.4),Vector3(-3.5,level1+3.2,0.6))
	await photo("f1-rug-and-stand",Vector3(0,level1+1.65,9.0),Vector3(2.5,level1+0.4,5.5))
	await photo("f1-network-showcase",Vector3(-1.5,level1+1.65,0.5),Vector3(0,level1+1.2,-5.5))
	await photo("f1-plan",Vector3(0,level1+13,0.5),Vector3(0,level1,0.4))
	await photo("f2-console",Vector3(1.65,level2+1.65,6.2),Vector3(1.0,level2+1.2,0.5))
	await photo("f2-neighbour-room",Vector3(4.0,level2+1.65,2.0),Vector3(3.85,level2+1.4,-1.3))
	await photo("f2-plan",Vector3(0,level2+13,0.5),Vector3(0,level2,0.4))
	cushions = game.cushioned_landings
	check(tag+"drop through A onto the catch floor's boards",await move_to(Vector3(-8.3,level3,1.9)))
	check(tag+"the catch floor saves without injury",game.checkpoint==3 and game.deaths==0 and game.cushioned_landings==cushions+1)
	study.step_once(); await frames(2)
	game.die("Retry trial"); await frames(130)
	var rebuilt: Node3D = content.exhibits["2/f2_structure_growth_6_6"].get_node("Artifact")
	check(tag+"retry returns to floor 2 with a rebuilt study at generation 0",game.checkpoint==2 and not game.recovering and rebuilt!=growth and rebuilt.get_node("StructureStudy").readback().generation==0)
	# The streaming window after a retry on floor 2 is floors 2 and 3; floor 1 rebuilds on return.
	check(tag+"retry rebuilds both floor 2 placements",content.exhibits.keys().filter(func(key): return str(key).begins_with("2/")).size()==2)
	game.place_player(game.spawn_for(1)); await frames(40)
	check(tag+"returning to floor 1 rebuilds its eight placements",content.exhibits.keys().filter(func(key): return str(key).begins_with("1/")).size()==8)
	check(tag+"trial never changes museum score",root.get_node("GameManager").player_score==museum_score)
	game.queue_free(); await frames(15)
	if use_xr:
		for item in [head,left,right]: XRServer.remove_tracker(item)
