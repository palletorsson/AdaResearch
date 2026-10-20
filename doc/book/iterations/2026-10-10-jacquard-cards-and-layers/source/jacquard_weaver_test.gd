extends SceneTree
const P = preload("res://commons/artifacts/jacquard_weaver/weave_program.gd")
const G = preload("res://commons/artifacts/jacquard_weaver/weave_geometry.gd")
const Fabric = preload("res://commons/artifacts/jacquard_weaver/weave_fabric.gd")
const Colours = preload("res://commons/artifacts/jacquard_weaver/yarn_colours.gd")
const OUT := "res://doc/book/iterations/2026-10-10-jacquard-cards-and-layers/"
var checks: Array=[]
var studio: Node3D
var loom: Node3D
var layers: Node3D

func _initialize() -> void: call_deferred("run")
func check(ok: bool, title: String) -> void:
	checks.append({"passed":ok,"test":title}); print("PASS " if ok else "FAIL ",title)
	assert(ok,title)

func pick() -> void:
	check(loom.start_pick(),"Begin a valid card cycle")
	loom.advance_cycle(1.4)
	loom.advance_cycle(1.4)

func run() -> void:
	create_timer(100).timeout.connect(func():quit(98))
	studio=load("res://commons/artifacts/jacquard_weaver/jacquard_studio.tscn").instantiate(); root.add_child(studio)
	await process_frame
	loom=studio.loom; layers=studio.layers; loom.set_process(false)
	check(loom.cards.size()==12 and loom.program.deck.size()==8,"Twelve physical cards, eight programmable chain slots")
	check(loom.program.history.is_empty() and layers.records.is_empty(),"Both artifacts arrive empty; no invented woven history")
	check(not loom.program.put(8,90,P.preset("plain",0)),"Reject a slot outside the chain")
	check(not loom.program.put(0,90,[1,0]),"Reject a malformed card")
	check(not loom.program.put(0,90,P.preset("plain",0)),"Do not overwrite an occupied slot")
	var card=loom.cards[0]
	card.on_desktop_grab(null)
	check(loom.program.deck[0]==null and card.held(),"Desktop pickup removes card from chain")
	check(not loom.place_card(card,0),"A held card cannot be teleported into a slot")
	card.position=loom.slots[0]; card.on_desktop_drop()
	await process_frame; await process_frame
	check(card.slot==0 and loom.program.deck[0].id==0,"Dropping near an empty slot installs and aligns the actual card")
	loom.start_pick()
	var fixed: Dictionary=loom.program.active.duplicate(true)
	loom.select_card(0); loom.toggle_hole(0)
	check(loom.program.active==fixed,"Editing a card during a pass preserves the already read mask")
	loom.advance_cycle(2.8)
	check(loom.program.history.size()==1 and loom.program.history[0]==fixed,"A completed shuttle cycle commits one immutable pick")
	check(layers.records==loom.program.history,"Layer sculpture receives exactly the loom record")
	var earlier: Array=loom.program.snapshot()
	loom.set_preset("plain")
	check(loom.program.history==earlier,"Loading another card set preserves woven history")
	loom.select_card(0); loom.toggle_hole(1)
	check(loom.program.history==earlier,"Editing a future mask does not rewrite cloth")
	pick()
	check(layers.records.size()==2,"The second pass adds one layer")
	var saved: Array=layers.records.duplicate(true)
	layers.set_gap(.075)
	check(layers.records==saved,"Unfolding layers leaves data unchanged")
	var separation:=true
	for row in range(layers.records.size()):
		for col in range(Fabric.THREADS):
			var bit: int=layers.records[row].bits[col%12]
			var a:=Fabric.point(layers.records,col,row,true);var b:=Fabric.point(layers.records,col,row,false)
			separation=separation and absf(a.y-b.y)>Fabric.HALF_HEIGHT*2 and ((a.y>b.y)==(bit==1))
	check(separation,"Every layer crossing preserves warp-over / warp-under and separates yarn surfaces")
	check(layers.weft_path.size()==196 and layers.warp_paths.size()==96,"Two actual picks cross all 96 warp threads")
	var snapshot: Array=loom.program.snapshot(); snapshot[0].bits[0]=9
	check(loom.program.history[0].bits[0]!=9,"External record is a deep copy")
	# Exercise actual XR Tools pickup and release, not just the model's put().
	var origin:=XROrigin3D.new(); root.add_child(origin)
	var controller:=XRController3D.new(); origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate(); controller.add_child(pickup)
	card=loom.cards[7]; controller.global_position=card.global_position; card.pick_up(pickup)
	for i in range(3): await physics_frame
	check(card.is_picked_up() and loom.program.deck[7]==null,"XR Tools pickup removes a card from the running chain")
	card.action(); check(loom.selected==7,"Held trigger selects that card's punch editor")
	controller.global_position=loom.to_global(loom.slots[7])
	for i in range(3): await physics_frame
	card.let_go(pickup,Vector3.ZERO,Vector3.ZERO)
	for i in range(4): await physics_frame
	check(not card.is_picked_up() and card.slot==7,"XR release installs the card back into its slot")
	# A real handle moves the XR slider; release must retain its setting.
	layers.slider.move_slider(0.0)
	controller.global_position=layers.handle.global_position; layers.handle.pick_up(pickup)
	for i in range(3): await physics_frame
	controller.global_position.x+=.18
	for i in range(6): await physics_frame
	check(layers.gap>.002,"Pulling the actual XR handle unfolds the layer sculpture")
	layers.handle.let_go(pickup,Vector3.ZERO,Vector3.ZERO)
	var released_gap: float=layers.gap
	for i in range(3): await physics_frame
	check(is_equal_approx(layers.gap,released_gap),"Layer slider keeps its setting after release")
	origin.queue_free(); await process_frame
	# Missing slots are skipped, all-empty chains do nothing.
	loom.reset_cloth()
	for c in loom.cards: loom.remove_card(c)
	check(not loom.start_pick(),"An empty chain cannot produce a pick")
	loom.place_card(loom.cards[3],6)
	check(loom.program.next_slot()==6,"Chain advances across empty sockets")
	loom.start_pick(); loom.advance_cycle(2.8)
	check(loom.program.history[0].id==3 and loom.program.history[0].slot==6,"A reinserted card carries its identity and new slot into history")
	loom.reset_cloth(); loom.set_preset("diamond")
	loom.weave_sample(P.LIMIT)
	check(loom.program.history.size()==128 and not loom.start_pick(),"One hundred twenty-eight picks bound geometry and stop the loom")
	loom.reset_cloth()
	check(loom.program.history.is_empty() and layers.records.is_empty() and loom.program.deck[0]!=null,"Clear cloth resets both displays while retaining the card program")
	# Capture a deliberate transition, eight plain then sixteen diamond picks.
	loom.set_preset("plain")
	for i in range(8): loom.start_pick(); loom.advance_cycle(2.8)
	var first: Array=loom.program.snapshot()
	loom.set_preset("diamond")
	for i in range(16): loom.start_pick(); loom.advance_cycle(2.8)
	check(loom.program.history.slice(0,8)==first,"Visible plain-to-diamond transition keeps its first eight picks")
	layers.set_gap(.065)
	if "--capture" in OS.get_cmdline_user_args(): await capture()
	tartan_checks()
	dense_checks()
	if "--capture" in OS.get_cmdline_user_args(): await capture_tartan()
	var file:=FileAccess.open(OUT+"tests.json",FileAccess.WRITE)
	var passed:=true
	for c in checks:passed=passed and c.passed
	file.store_string(JSON.stringify({"passed":passed,"checks":checks,"kind":"Actual Godot runtime, recorded yarn colours, geometric crossings, simulated XR controller; no headset trial"},"\t")); file.close()
	quit(0 if passed else 1)

func press(button: Node3D) -> void:
	var area=button.get_node("InteractableAreaButton")
	area.button_pressed.emit(area)

func tartan_checks() -> void:
	loom.set_tartan()
	check(loom.warp_colors==Colours.SETT and loom.weft_colors==Colours.SETT,"Tartan uses the same twelve-thread colour repeat in warp and weft")
	check(loom.program.history.is_empty() and layers.records.is_empty(),"Tartan + Clear explicitly starts a fresh sample")
	loom.start_pick()
	var yarn: String=loom.program.active.weft_color
	press(loom.weft_buttons[0])
	check(loom.weft_colors[0]!=yarn and loom.program.active.weft_color==yarn,"Physical weft button changes the repeat without recolouring a running shuttle pass")
	loom.advance_cycle(2.8)
	var first: Dictionary=loom.program.history[0].duplicate(true)
	press(loom.weft_buttons[1]); loom.start_pick(); loom.advance_cycle(2.8)
	check(loom.program.history[1].weft_color==loom.weft_colors[1],"The next pass records the edited weft colour")
	check(is_equal_approx(loom.weft_marker.position.x,-.63) and loom.shuttle.material_override.albedo_color.is_equal_approx(Color(str(loom.weft_colors[1]))),"Weft marker and actual shuttle identify the colour used by the second pass")
	check(loom.program.history[0]==first,"Later weft edits leave the first coloured pick intact")
	var warp_before: Array=loom.warp_colors.duplicate()
	press(loom.warp_buttons[0])
	check(loom.warp_draft!=warp_before and loom.warp_colors==warp_before,"Physical warp button edits a draft without silently rethreading existing cloth")
	check(loom.program.history[0].warp_colors==warp_before and layers.records[0].warp_colors==warp_before,"Both displays retain the warp colours used to weave the sample")
	loom.match_weft()
	check(loom.weft_colors==loom.warp_draft,"Match Weft copies the proposed warp repeat")
	var copied: Array=loom.weft_colors.duplicate(); loom.cycle_colour(true,2)
	check(loom.weft_colors==copied,"Matching copies values; later warp edits cannot mutate the weft repeat")
	var deck_before: Array=loom.program.deck.duplicate(true)
	loom.apply_warp()
	check(loom.program.history.is_empty() and layers.records.is_empty() and loom.warp_colors==loom.warp_draft,"Thread + Clear applies the new warp and clears both histories")
	check(loom.program.deck==deck_before,"Rethreading keeps the selected card chain")
	loom.set_tartan()
	for i in range(24): loom.start_pick(); loom.advance_cycle(2.8)
	var exact:=true
	for row in range(24):
		var record: Dictionary=loom.program.history[row]
		exact=exact and record.weft_color==Colours.SETT[row%12] and record.warp_colors==Colours.SETT
		for col in range(12):exact=exact and int(record.bits[col])==(1 if posmod(col-row,4)<2 else 0)
	check(exact,"Twenty-four passes combine an independent 12-step colour repeat with the 4-step 2/2 twill")
	check(layers.records==loom.program.history,"Layer sculpture keeps the exact lift masks AND thread colours")
	var array: Array=layers.drawdown_mesh.mesh.surface_get_arrays(0)
	var colours: PackedColorArray=array[Mesh.ARRAY_COLOR]
	var faithful:=colours.size()==24*96*4
	for row in range(24):
		for col in range(96):
			var record: Dictionary=loom.program.history[row]
			var expected:=Color(str(record.warp_colors[col%12]) if int(record.bits[col%12])==1 else str(record.weft_color))
			faithful=faithful and colours[(row*96+col)*4].is_equal_approx(expected)
	check(faithful,"Every drawdown cell displays the actual upper thread, never an invented mixed colour")
	var record_before: Array=layers.records.duplicate(true)
	layers.set_gap(.075)
	check(layers.records==record_before,"Spreading the tartan into layers retains recorded colours and crossings")
	var actual: Color=loom.cloth.get_child(0).mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR][0]
	var expected_colour:=Color(str(Colours.SETT[0])).srgb_to_linear()
	# Mesh colours are quantized to RGBA8 by ArrayMesh.
	check(absf(actual.r-expected_colour.r)<=1.0/255 and absf(actual.g-expected_colour.g)<=1.0/255 and absf(actual.b-expected_colour.b)<=1.0/255,"Actual yarn colour survives GPU storage within one RGBA8 step")
	var rows_before: Array=loom.program.snapshot(); var weft_before: Array=loom.weft_colors.duplicate()
	loom.set_preset("plain")
	check(loom.program.history==rows_before and loom.weft_colors==weft_before,"Changing the weave cards leaves both colour program and finished cloth intact")
	loom.set_preset("twill")

func dense_checks() -> void:
	loom.set_tartan()
	press(layers.sample_button)
	check(loom.program.history.size()==96 and layers.records==loom.program.history,"Weave 96 Picks button commits 96 actual card cycles in both views")
	var colours_and_bits:=true
	for row in range(96):
		var r:Dictionary=layers.records[row]
		colours_and_bits=colours_and_bits and r.weft_color==Colours.SETT[row%12] and int(r.slot)==row%8
		for col in range(96):
			var a:=Fabric.point(layers.records,col,row,true)
			var b:=Fabric.point(layers.records,col,row,false)
			colours_and_bits=colours_and_bits and ((a.y>b.y)==(int(r.bits[col%12])==1))
	check(colours_and_bits,"Every dense crossing repeats the recorded twelve-hook choice across 96 ends")
	check(Fabric.RADIUS*2/Fabric.PITCH>.9 and layers.warp_paths.size()==96,"Flattened yarns occupy more than 90 percent of the thread pitch")
	var saved:Array=layers.records.duplicate(true)
	var mesh_id:int=layers.fabric_mesh.mesh.get_instance_id()
	layers.set_gap(0.0)
	check(not layers.drawdown_mesh.visible,"Closed cloth shows real yarn geometry with no coloured diagram filling the gaps")
	layers.set_gap(.075)
	check(layers.records==saved and layers.fabric_mesh.mesh.get_instance_id()==mesh_id,"Slider opens the same mesh on the GPU without rebuilding or rewriting cloth")
	check(is_equal_approx(float(layers.fabric_material.get_shader_parameter("opening")),1.0) and layers.drawdown_mesh.visible,"Fully open handle updates the shader and reveals the crossing diagram")
	var a:=Fabric.opened(Fabric.point(saved,42,95,true),1.0,96)
	var b:=Fabric.opened(Fabric.point(saved,42,95,false),1.0,96)
	check(absf(a.y-b.y)>.025 and a.y<3.0 and b.y<3.0,"Opening enlarges the crossing clearance while bounding total sample height")
	var mesh: ArrayMesh=layers.fabric_mesh.mesh
	check(mesh.get_surface_count()==1 and mesh.surface_get_array_len(0)<160000,"Ninety-six picks use one yarn surface with bounded vertex count")
	loom.start_pick();var active:Dictionary=loom.program.active.duplicate(true)
	press(loom.weft_buttons[0]);press(layers.sample_button)
	check(loom.program.history[96]==active and loom.program.history.slice(0,96)==saved,"Batch weaving preserves an in-flight colour snapshot and every previous pick")
	check(loom.program.history.size()==P.LIMIT and layers.records.size()==P.LIMIT and not loom.start_pick(),"Repeated batch presses stop at capacity without fabricating or dropping rows")
	loom.set_tartan();press(layers.sample_button)

func capture_tartan() -> void:
	var cam:=root.get_viewport().get_camera_3d()
	layers.set_gap(.0)
	await shot(cam,layers.position+Vector3(.5,4.5,3.2),layers.position+Vector3(0,.96,-.1),"tartan-flat",43)
	await shot(cam,layers.position+Vector3(.22,1.7,.25),layers.position+Vector3(0,.98,-.18),"tartan-detail",49)
	layers.set_gap(.068)
	await shot(cam,layers.position+Vector3(3.0,3.6,3.8),layers.position+Vector3(0,1.7,-.1),"tartan-layers",46)
	loom.start_pick(); loom.advance_cycle(1.5)
	await shot(cam,loom.position+Vector3(2.7,2.7,4.6),loom.position+Vector3(.02,1.4,.3),"tartan-loom",48)
	await shot(cam,loom.position+Vector3(.2,1.8,2.65),loom.position+Vector3(0,1.27,1.1),"tartan-controls",58)

func shot(camera: Camera3D, pos: Vector3, target: Vector3, output: String, fov:=45.0) -> void:
	camera.position=pos; camera.look_at(target); camera.fov=fov; camera.make_current()
	for i in range(6): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+output+".png")

func capture() -> void:
	root.size=Vector2i(1800,1200)
	root.msaa_3d=Viewport.MSAA_4X
	var env:=Environment.new(); env.background_mode=Environment.BG_COLOR; env.background_color=Color("141b22")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color=Color("dce6ed"); env.ambient_light_energy=.65
	var world:=WorldEnvironment.new(); world.environment=env; root.add_child(world)
	var sun:=DirectionalLight3D.new(); sun.rotation_degrees=Vector3(-48,-27,0); sun.light_energy=1.5; sun.shadow_enabled=true; root.add_child(sun)
	var ground=Node3D.new(); root.add_child(ground); G.box(ground,Vector3(0,-.08,0),Vector3(16,.1,12),G.material("5e696d"))
	var cam:=Camera3D.new(); root.add_child(cam)
	loom.start_pick(); loom.advance_cycle(1.6)
	await shot(cam,Vector3(5.6,3.6,8.0),Vector3(0,1.45,.15),"studio",40)
	await shot(cam,loom.position+Vector3(2.9,2.7,4.7),loom.position+Vector3(0,1.40,.3),"loom",46)
	await shot(cam,layers.position+Vector3(3.0,2.7,3.3),layers.position+Vector3(0,1.65,.3),"layers",44)
	await shot(cam,loom.position+Vector3(0,1.05,2.4),loom.position+Vector3(0,.71,1.05),"cards",41)
	layers.set_gap(0.0)
	await shot(cam,layers.position+Vector3(.6,3.7,2.8),layers.position+Vector3(0,1.0,.3),"flat",43)
