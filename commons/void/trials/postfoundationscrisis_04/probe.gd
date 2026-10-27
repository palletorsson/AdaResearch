extends "res://tools/probes/void_transfer_probe.gd"
const PoseStore = preload("res://algorithms/computationalbiology/molecular_framework/AssemblyPoseRecord.gd")

func start(use_xr: bool) -> void:
	# Never read/write the visitor's assembly record during acceptance.
	set_meta(PoseStore.PATH_KEY,out.path_join("test-pose-%s.json"%str(use_xr)))
	set_meta(PoseStore.KEY,{})
	await super.start(use_xr)

func focused_checks(tag: String) -> void:
	if level==1: await laboratory_checks(tag)
	else: await synthesis_checks(tag)

func laboratory_checks(tag: String) -> void:
	var molecule: Node3D=artifact("MolecularDesigner")
	check(tag+"original body and three furniture studies loaded",molecule.has_node("BodyWorkshop") and molecule.has_node("BodyRagdoll") and molecule.has_node("Furniture_Chair") and molecule.has_node("Furniture_Table") and molecule.has_node("Furniture_Lamp"))
	check(tag+"source assembly scale and timing",molecule.scale.is_equal_approx(Vector3.ONE*2) and molecule.float_duration==8 and molecule.assemble_duration==18 and molecule.parts.size()==40)
	check(tag+"source authored catalogue retains eleven or more assemblies",molecule.get_available_assemblies().size()>=11)
	var witness: Node=molecule.parts[0]
	await frames(490)
	check(tag+"original timer assembles using the same instances",molecule.is_assembled() and molecule.parts[0]==witness and molecule.bonds.size()>0)
	var assembled_name: String=molecule.current_assembly
	var key:=InputEventKey.new();key.keycode=KEY_2;key.pressed=true
	Input.parse_input_event(key);await frames(3)
	key=InputEventKey.new();key.keycode=KEY_2;key.pressed=false;Input.parse_input_event(key)
	check(tag+"standalone keyboard shortcuts cannot override shared controls",molecule.current_assembly==assembled_name)
	# Explicit API check of an authored second body; preserves all source instances.
	molecule.assemble_structure("Chair");await frames(90)
	check(tag+"assembly API changes topology without replacing the carriers",molecule.current_assembly=="Chair" and molecule.parts[0]==witness and molecule.bonds.size()==molecule.assemblies.Chair.bonds.size())
	var workshop: Node3D=molecule.get_node("BodyWorkshop")
	check(tag+"workshop retains thirteen joints and twelve connections",workshop.joints.size()==13 and workshop.pairs.size()==12)
	var index: int=workshop.names.find("r_hand")
	var joint: Node3D=workshop.joints[index]
	var before: Vector3=workshop.targets[index]
	await approach(workshop)
	await carry(joint,workshop.to_global(before+Vector3(.2,.16,.14)),tag+"gold joint")
	check(tag+"released joint changes geometry and saves a pose",workshop.edit_count>0 and workshop.targets[index].distance_to(before)>.05 and workshop.last_keep_error==OK and PoseStore.changed(PoseStore.read(self))>0)
	# Connection topology is checked through its original API, separately from pickup.
	var endpoint: int=1
	var destination: int=workshop.names.find("head")
	workshop.begin_connection(endpoint)
	workshop.connection_handle(endpoint).global_position=workshop.to_global(workshop.targets[destination])
	workshop.finish_connection(endpoint);await frames(5)
	check(tag+"connection API reroutes one edge and persists it",workshop.pairs[workshop.bond_index].y==destination and PoseStore.changed_connections(PoseStore.read(self))==1)
	var rag: Node3D=molecule.get_node("BodyRagdoll")
	await approach(rag)
	await carry(rag.grips["r_hand"],rag.to_global(Vector3(.8,1.6,.5)),tag+"ragdoll ring")
	check(tag+"pulling original ragdoll releases its suspension",not is_instance_valid(rag.hanger) and rag.active.is_empty() and rag.parts.size()==10 and rag.links.size()==9)
	await press(rag.reset_button.get_parent());await frames(12)
	check(tag+"HANG AGAIN pointer restores ragdoll suspension",is_instance_valid(rag.hanger) and not rag.reset_pending)
	var chair: Node3D=molecule.get_node("Furniture_Chair")
	await approach(chair)
	var id: String=chair.grips.keys()[0]
	await carry(chair.grips[id],chair.anchor_position(id)+Vector3(.3,.3,.3),tag+"chair ring")
	check(tag+"furniture pull removes pose supports",chair.supports.is_empty() and chair.active.is_empty())
	await press(chair.reset_button.get_parent());await frames(12)
	check(tag+"REASSEMBLE pointer restores furniture supports",not chair.supports.is_empty() and not chair.reset_pending)
	var blanket: Node3D=artifact("markov_blanket_room")
	check(tag+"original sealed lattice separates",blanket.is_separated() and blanket.escape_path_length()==0)
	blanket.apply_grid_config({"shell":"none"});await frames(2)
	check(tag+"configuration API exposes real escape path",not blanket.is_separated() and blanket.escape_path_length()>1)
	blanket.apply_grid_config({"shell":"shell"});await frames(2)
	var bridge: Node3D=artifact("bridge_cut")
	check(tag+"original graph starts connected",bridge.component_count()==1 and bridge.has_bridge())
	bridge.apply_grid_config({"cut":"chord"});await frames(2)
	check(tag+"configuration API chord is a negative control",bridge.component_count()==1)
	bridge.apply_grid_config({"cut":"bridge"});await frames(2)
	check(tag+"configuration API bridge removal splits graph",bridge.component_count()==2)
	bridge.apply_grid_config({"cut":"none"})
	var neck: Node3D=artifact("boolean_neck")
	check(tag+"original CSG neck remains one piece",neck.piece_count()==1 and neck.thinnest_neck()>0)
	neck.apply_grid_config({"gap":"severed"});await frames(3)
	check(tag+"configuration API severs actual CSG profile",neck.piece_count()>1 and neck.thinnest_neck()==0)
	neck.apply_grid_config({"gap":"narrow"})
	var flex: Node3D=artifact("flex_connector")
	flex.apply_grid_config({"slack":"taut"});await frames(2)
	check(tag+"configuration API taut connector fits region",flex.fits_inside() and absf(flex.cord_ratio()-1)<.01)
	flex.apply_grid_config({"slack":"coiled"});await frames(2)
	check(tag+"configuration API slack exceeds region",not flex.fits_inside() and flex.samples_outside()>0)
	flex.apply_grid_config({"slack":"easy"})

func carry(object: Node3D, target: Vector3, label: String) -> void:
	if xr:
		hand_at(right,object.global_position);await frames(15)
		right.set_input("grip",1.0);await frames(15)
		check("XR: "+label+" real grip pickup",game.pickups[1].picked_up_object==object)
		hand_at(right,target);await frames(20)
		right.set_input("grip",0.0);await frames(12)
		check("XR: "+label+" release",game.pickups[1].picked_up_object==null)
	else:
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
		for i in 20:
			game.camera.look_at(object.global_position);await frames(1)
		await mouse_right()
		check("Desktop: "+label+" real mouse pickup",game.body.desktop_pointer._held==object)
		for i in 20:
			game.camera.look_at(target);await frames(1)
		await mouse_right()
		check("Desktop: "+label+" release",game.body.desktop_pointer._held==null)

func mouse_right() -> void:
	var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_RIGHT;event.pressed=true
	Input.parse_input_event(event);await frames(5)
	event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_RIGHT;event.pressed=false
	Input.parse_input_event(event);await frames(8)

func synthesis_checks(tag: String) -> void:
	var returned: Node3D=artifact("assembly_return")
	returned.refresh();await frames(4)
	check(tag+"synthesis receives the actual released laboratory pose",returned.record==PoseStore.read(self) and returned.bodies.has_node("KeptPose") and returned.status.text.contains("connections rerouted: 1"))
	var ledger: Node3D=artifact("accountability_ledger")
	await frames(70)
	check(tag+"ledger reports the visitor record instead of canned examples",ledger.visitor_record and ledger._pose_revision==returned.record.revision and ledger._count==returned.record.completed_edits and ledger._entries[3].contains("1 rerouted"))
	var kept: Dictionary=PoseStore.read(self)
	set_meta(PoseStore.KEY,{})
	returned.refresh();ledger._refresh_record(true);await frames(3)
	check(tag+"empty record never invents a visitor pose",not returned.bodies.has_node("KeptPose") and returned.status.text.contains("NO POSE KEPT") and ledger._count==0)
	set_meta(PoseStore.KEY,kept)
	returned.refresh();ledger._refresh_record(true);await frames(3)
	var sphere: Node3D=artifact("florensky_sphere")
	sphere.set_state(sphere.LogicState.BOTH)
	await approach(sphere,1.6)
	await press(sphere.controls.find_child("Btn_0",true,false))
	check(tag+"OBSERVE pointer reaches original sphere handler",sphere.current_state in [sphere.LogicState.A,sphere.LogicState.NOT_A])
	sphere.set_state(sphere.LogicState.BOTH)
	await press(sphere.controls.find_child("Btn_1",true,false))
	check(tag+"CYCLE pointer reaches original NEITHER state",sphere.current_state==sphere.LogicState.NEITHER)
	sphere.set_state(sphere.LogicState.BOTH)
	var bias: Node3D=artifact("bias_from_inside")
	await approach(bias)
	await press(bias._controls.find_child("Btn_0",true,false))
	check(tag+"READ pointer opens original interpretation",bias._reading.visible)
	await press(bias._controls.find_child("Btn_0",true,false))
	check(tag+"READ pointer closes interpretation",not bias._reading.visible)
	var baseline: Transform3D=bias._marginalized_multimesh.multimesh.get_instance_transform(0)
	bias._slider.set_normalized_value(1.0);bias._on_perspective_changed(1.0);await frames(2)
	check(tag+"COMPRESSION slider API moves the same 24 terms",not baseline.is_equal_approx(bias._marginalized_multimesh.multimesh.get_instance_transform(0)) and bias._marginalized_tags.size()==12 and bias._default_tags.size()==12)
	bias._slider.set_normalized_value(0.0);bias._on_perspective_changed(0.0)
	var edge: Node3D=artifact("edge_ground_synthesis")
	var before: int=edge._active
	await frames(140)
	check(tag+"original synthesis cycle advances four named limits",edge._active!=before and edge._ports.size()==4 and edge._core_charge>0)
	var tt: Node3D=artifact("tt")
	check(tag+"malformed source text token retains executed default pending curation",not tt.has_meta("config_tutorial") and tt.current_tutorial_id.is_empty() and tt.rich_text_label!=null and not tt.rich_text_label.text.is_empty())
	var formula: Node3D=artifact("qfep_formula_3d")
	check(tag+"original formula remains a reading display",not formula.reading_study and formula.term_nodes.size()>5)

func capture_floor() -> void:
	if level==1:
		await photo("01-laboratory-overview",Vector3(9,-2.5,11),Vector3(0,-4.5,-5))
		await photo("02-body-workshop",Vector3(3,-3.7,2),Vector3(-1,-4.7,-4.3))
	else:
		await photo("03-synthesis-overview",Vector3(9,-8.2,-6),Vector3(0,-10.5,6))
		await photo("04-kept-pose",Vector3(0,-10.2,5),Vector3(0,-10.6,0))
