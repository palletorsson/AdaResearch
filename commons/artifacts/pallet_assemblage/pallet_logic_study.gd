extends Node3D
## Human-built AND: material support, real gravity and a vulnerable output cone.
## Legacy saved sketches retain their removable-blocker grammar.
const Timber = preload("res://commons/artifacts/primitive_encounters/timber_finish.gd")
const ButtonScene = preload("res://commons/interactables/cube_button.tscn")
const Pickable = preload("res://addons/godot-xr-tools/objects/pickable.tscn")
const BALL_LAYER := 1 << 25
var slope := .156/1.8
var board_top := .218
var lift := 0.0
var long_track := false
var supports := false
var start_x := -1.02
var input_x := -.28
var input_y := .34
var target_x := 1.11
var ramp_pieces: Array[XRToolsPickable] = []
var work: Node3D
var ball: XRToolsPickable
var output: XRToolsPickable
var running := false
var outcome := -1
var elapsed := 0.0
var ball_rest := Vector3.ZERO
var cone_rest := Transform3D.IDENTITY
var hit_inputs: Array[String] = []
var passage_times: Dictionary = {}

func line_y(x: float) -> float:
	if supports:return board_top+.167-slope*x
	return board_top+.022+.156+.011*cos(atan(slope))+.0725*slope-slope*x
func ready_text() -> String:
	return "AND / X + Y SUPPORT THE BALL" if supports else "AND / MOVE BOTH BLOCKS TO CLEAR THE BALL"
func build(host: Node3D) -> void:
	work = host
	board_top = work.track_height;lift = board_top-.218
	long_track = work.board_count==2
	if long_track:slope *= .5;start_x = -2.12;input_x = -1.60;input_y = -.12;target_x = 2.36
	supports = work.logic_grammar=="supports"
	if supports:slope = .078/1.15;start_x = -1.22;input_x = -.46;input_y = .46;target_x = 1.44
	for n in work.board_count:
		var board := StaticBody3D.new();board.name = "Board" if n==0 else "Board2";board.position = Vector3((n-.5)*2.4 if long_track else 0,board_top-.009,0);work.add_child(board)
		box(board,"Sheet",Vector3.ZERO,Vector3(2.4,.018,1.2),Timber.material())
		remember(board,Vector3(-1.2,-.009,-.6),Vector3(2.4,.018,1.2),"Loose timber sheet / 2.4 × 1.2 m / 18 mm")
	var concrete := StandardMaterial3D.new();concrete.albedo_color = Color("95968b");concrete.roughness = .97
	for i in range(4*work.board_count):
		var board_x := (-1.2 if i<4 else 1.2) if long_track else 0.0
		var block := StaticBody3D.new();block.name = "CinderBlock"+str(i+1);block.position = Vector3(board_x+(-.82 if i%2==0 else .82),lift+.1,-.45 if i%4<2 else .45);work.add_child(block)
		# One course, on their sides: two real open cells, rather than a dark decal.
		for y in [-.0875,.0875]:box(block,"Bed",Vector3(0,y,0),Vector3(.4,.025,.2),concrete)
		for x in [-.185,0,.185]:box(block,"Web",Vector3(x,0,0),Vector3(.03,.15,.2),concrete)
		remember(block,Vector3(-.2,-.1,-.1),Vector3(.4,.2,.2),"Hollow cinder block / single 20 cm course")
		if lift>.001:
			var crate := StaticBody3D.new();crate.name = "BaseCrate"+str(i+1);crate.position = Vector3(block.position.x,lift/2,block.position.z);work.add_child(crate)
			for y in [-lift/2+.011,lift/2-.011]:box(crate,"CrateDeck",Vector3(0,y,0),Vector3(.5,.022,.3),Timber.material())
			for x in [-.228,.228]:
				for z in [-.128,.128]:box(crate,"CornerPost",Vector3(x,0,z),Vector3(.044,lift-.044,.044),Timber.material())
			for y in [-lift*.28,0,lift*.28]:
				for z in [-.14,.14]:box(crate,"PackingSlat",Vector3(0,y,z),Vector3(.5,.065,.02),Timber.material())
			remember(crate,Vector3(-.25,-lift/2,-.15),Vector3(.5,lift,.3),"Loose timber packing crate / supports the cinder course")
	if work.pieces.size()==20:
		if work.term=="pallet_hand_kit":stage_timber()
		else:output = work.pieces.block_3_3
	if long_track:
		for i in range(4):make_runway(i+1,[-1.70,-.57,.56,1.69][i])
	if supports:
		# Same four standard extra boards: low side edges, not a hidden floor across gaps.
		for i in range(4):
			var rail: XRToolsPickable = ramp_pieces[i]
			var x: float = -.60 if i%2==0 else .60
			rail.position = Vector3(x,line_y(x)+.022,-.1225 if i<2 else .1225);rail.rotation.z = -atan(slope)
			remember(rail,Vector3(-.6,-.011,-.0725),Vector3(1.2,.022,.145),"Loose track edge / 1.2 m / move by hand")
			PhysicsServer3D.body_set_state(rail.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,rail.global_transform)
	ball = make_ball("BallAndRelease",Vector3(start_x,line_y(start_x)+.011+.024+.055,0));ball_rest = ball.position
	var ivory := StandardMaterial3D.new();ivory.albedo_color = Color("fffdf5");ivory.roughness = .4
	output = Pickable.instantiate() as XRToolsPickable;output.name = "TrueCone"
	output.set_script(load("res://commons/artifacts/pallet_assemblage/pallet_piece.gd"))
	for c in output.get_children():
		if c is CollisionShape3D:c.free()
	output.mass = .025;output.freeze = true;output.release_mode = XRToolsPickable.ReleaseMode.UNFROZEN
	output.collision_layer = 1;output.collision_mask = 1|BALL_LAYER;output.continuous_cd = true
	output.physics_material_override = PhysicsMaterial.new();output.physics_material_override.friction = .85;output.physics_material_override.bounce = .02
	var cone := CylinderMesh.new();cone.top_radius = .10;cone.bottom_radius = .008;cone.height = .22;cone.radial_segments = 32
	var cone_skin := MeshInstance3D.new();cone_skin.mesh = cone;cone_skin.material_override = ivory;output.add_child(cone_skin)
	var cone_hit := CollisionShape3D.new();cone_hit.shape = cone.create_convex_shape();cone_hit.shape.margin = .001;output.add_child(cone_hit)
	output.position = Vector3(target_x,board_top+.11+.001,0);work.add_child(output);cone_rest = output.transform
	remember(output,Vector3(-.10,-.11,-.10),Vector3(.20,.22,.20),"TRUE / inverted cone balanced on its tip")
	var controls := Node3D.new();controls.name = "LogicControls";controls.position = Vector3(0,board_top+.014,.47) if lift>.001 else Vector3(0,.245,.49);work.add_child(controls)
	if long_track:controls.position.x = -1.4
	if supports:controls.position.x = -1.4
	var tag := StandardMaterial3D.new();tag.albedo_color = Color("e8dfcb");tag.roughness = .9
	if lift>.001:
		tag.albedo_color = Color("292b35");tag.metallic = .45;tag.roughness = .48
		box(controls,"TrackEdgeControlStrip",Vector3.ZERO,Vector3(.98,.028,.15),tag)
	else:box(controls,"LoosePlywoodTag",Vector3(0,.03,0),Vector3(.98,.12,.035),tag)
	for i in range(4):
		var id: String = ["BALL","RESET","SAVE","RECOVER"][i]
		var button := ButtonScene.instantiate();button.name = id;button.label = id;button.position = Vector3((i-1.5)*.22,.055,.025);button.cube_size = .045;button.cap_color = Color("e45391")
		if lift>.001:
			button.position = Vector3((i-1.5)*.22,.018,0);button.rotation.x = -PI/2;button.cube_size = .065
			button.plate_color = Color("363944");button.frame_color = Color("25262d")
		controls.add_child(button);work.buttons[id] = button
		if lift>.001:
			for label in button.get_children():
				if label is Label3D:label.modulate = Color("fff3e5");label.position.y = .052
		button.pressed.connect(release_ball if i==0 else work.reset_pallet if i==1 else work.save_prefab if i==2 else work.recover_draft)
	work.status = Label3D.new();work.status.name = "Status";work.status.text = ready_text();work.status.font_size = 28;work.status.pixel_size = .001;work.status.position = Vector3(0,.19,0);work.status.modulate = Color("29252b");controls.add_child(work.status)
	if lift>.001:
		work.status.position = Vector3(0,-.011,.105);work.status.rotation.x = -PI/2;work.status.font_size = 22;work.status.pixel_size = .0008
	for row in [["X",input_x],["Y",input_y],["TRUE",target_x]]:
		var label := Label3D.new();label.text = row[0];label.font_size = 36;label.pixel_size = .0008;label.modulate = Color("302b27");label.outline_size = 0
		label.position = Vector3(row[1]-controls.position.x,line_y(row[1])+.13-controls.position.y,-.35);label.rotation.x = -PI/4;controls.add_child(label)
		if long_track:
			label.rotation.x = -PI/2
			label.position.y = (board_top+.003 if row[0]=="TRUE" else line_y(row[1])+.036)-controls.position.y
		if supports:label.position.z = .19-controls.position.z;label.position.y = board_top+.003-controls.position.y
	remember(controls,Vector3(-.55,-.03,-.10),Vector3(1.1,.28,.25),"Track-edge controls / face-up buttons at 0.6 m" if lift>.001 else "Plywood control tag / ball, reset, save")
	if work.pieces.size()!=20:set_physics_process(false)
	work.set_meta("void_preview_kind","Human-operated pallet AND. Two standard timber sheets end to end, four extra loose runway boards, a gentler gravity slope and spaced events." if long_track else "Human-operated pallet AND on one standard timber sheet. White Jolt ball strikes an inverted TRUE cone. Independent timber parts; real gravity and collisions.")
	if supports:work.set_meta("void_preview_kind","Support AND: three original 0.8 m pallet bearers form a compact ramp with two visible gaps. X and Y bridge the gaps. Gravity alone carries the white ball to the inverted cone, or into the catch below. No Boolean-controlled path or snapping.")

func make_ball(release_id: String,at: Vector3) -> XRToolsPickable:
	# The ball's local mesh pose stays the same in every saved profile.
	var legacy_slope := .156/1.8
	var local_ball_y := .218+.022+.156+.011*cos(atan(legacy_slope))+.0725*legacy_slope+legacy_slope*1.02+.011+.024+.055
	var release := Node3D.new();release.name = release_id;release.position = at-Vector3(-1.02,local_ball_y,0);work.add_child(release)
	var carrier := Pickable.instantiate() as XRToolsPickable;carrier.name = "WhiteGravityBall"
	for c in carrier.get_children():
		if c is CollisionShape3D:c.free()
	carrier.mass = .04;carrier.freeze = true;carrier.release_mode = XRToolsPickable.ReleaseMode.UNFROZEN
	carrier.collision_layer = BALL_LAYER|4;carrier.collision_mask = 1;carrier.continuous_cd = true;carrier.can_sleep = false
	carrier.physics_material_override = PhysicsMaterial.new();carrier.physics_material_override.friction = .35;carrier.physics_material_override.bounce = .025
	carrier.linear_damp = .005;carrier.angular_damp = .005
	var mesh := MeshInstance3D.new();var sphere := SphereMesh.new();sphere.radius = .024;sphere.height = .048;mesh.mesh = sphere
	var ivory := StandardMaterial3D.new();ivory.albedo_color = Color("fffdf5");ivory.roughness = .4;mesh.material_override = ivory;carrier.add_child(mesh)
	var hit := CollisionShape3D.new();hit.shape = SphereShape3D.new();hit.shape.radius = .024;carrier.add_child(hit);release.add_child(carrier)
	carrier.position = Vector3(-1.02,local_ball_y,0)
	carrier.contact_monitor = true;carrier.max_contacts_reported = 12;carrier.body_entered.connect(func(body):contact_from(body,carrier))
	carrier.dropped.connect(func(_p):begin_run())
	remember(release,Vector3(-1.08,.25,-.07),Vector3(.15,.4,.14),"White ball / pick up or release from above")
	return carrier

func contact_from(body: Node3D,_carrier: XRToolsPickable) -> void:
	contact(body)

func stage_timber() -> void:
	var angle := -atan(slope)
	if supports:
		stage_supports(angle);return
	if long_track:
		for i in range(4):
			var x: float = [-1.70,-.57,.56,1.69][i]
			pose("deck_"+str(i+1),Vector3(x,line_y(x)+.022,-.1225),Vector3(0,0,angle))
			pose("bottom_"+str(i+1) if i<3 else "deck_5",Vector3(x,line_y(x)+.022,.10 if i<3 else .1225),Vector3(0,0,angle))
	else:
		pose("deck_1",Vector3(-.57,line_y(-.57),0),Vector3(0,0,angle))
		pose("deck_2",Vector3(.44,line_y(.44),0),Vector3(0,0,angle))
		for row in [["deck_3",-.57],["deck_4",.44]]:
			var x: float = row[1];pose(row[0],Vector3(x,line_y(x)+.083,-.09),(Basis(Vector3.BACK,angle)*Basis(Vector3.RIGHT,PI/2)).get_euler())
		pose("deck_5",Vector3(.28,board_top+.033,-.42 if lift>.001 else .42),Vector3(0,.07,0))
		for row in [["bottom_1",-.57],["bottom_2",.44]]:
			var x: float = row[1];pose(row[0],Vector3(x,line_y(x)+.061,.09),(Basis(Vector3.BACK,angle)*Basis(Vector3.RIGHT,PI/2)).get_euler())
		pose("bottom_3",Vector3(.24,board_top+.011,-.42 if lift>.001 else .42))
	for i in range(3):pose("bearer_"+str(i+1),Vector3((i-1)*(.9*work.board_count),board_top+.011,0))
	var ids := ["block_1_2","block_1_3","block_2_1","block_2_2","block_2_3","block_3_2"]
	for i in range(6):
		var x: float = (-.9 if i<3 else 0.0 if i<5 else .9)*work.board_count
		var layer := i if i<3 else i-3 if i<5 else 0
		pose(ids[i],Vector3(x,board_top+.022+.039+layer*.078,0))
	for row in [["block_1_1",input_x],["block_3_1",input_y]]:
		var x: float = row[1];pose(row[0],Vector3(x,line_y(x)+(.011+.039)*cos(angle),0),Vector3(0,0,angle))
	pose("block_3_3",Vector3(1.7 if long_track else .85,board_top+.039,-.42 if lift>.001 else .42))

func stage_supports(angle: float) -> void:
	# Three original transverse bearers become a 2.64 m path; no timber is resized.
	for i in range(3):
		var x: float = (i-1)*.92
		pose("bearer_"+str(i+1),Vector3(x,line_y(x),0),(Basis(Vector3.BACK,angle)*Basis(Vector3.UP,PI/2)).get_euler())
	for row in [["block_1_1",input_x],["block_3_1",input_y]]:
		var x: float = row[1]
		pose(row[0],Vector3(x,line_y(x)+.011-.039,0),Vector3(0,0,angle))
		work.part_defaults[row[0]].label = ("X" if row[0]=="block_1_1" else "Y")+" / removable gap support / present = 1"
	# Real stacked spacers carry the inclined path at three points.
	var ids := ["block_1_2","block_1_3","block_2_1","block_2_2","block_2_3","block_3_2"]
	for i in range(6):
		var x: float = -1.15 if i<3 else 0.0 if i<5 else 1.15
		var level: int = i if i<3 else i-3 if i<5 else 0
		pose(ids[i],Vector3(x,board_top+.039+level*.078,0))
	# A fallen ball meets an actual low timber catch, below the running surface.
	for i in range(2):
		pose("bottom_"+str(i+1),Vector3((input_x if i==0 else input_y)+.16,board_top+.05,0),Vector3(PI/2,PI/2,0))
	pose("bottom_3",Vector3(1.68,board_top+.011,-.42))
	for i in range(5):pose("deck_"+str(i+1),Vector3(-1.65,board_top+.011+i*.022,-.42),Vector3(0,.025*i,0))
	pose("block_3_3",Vector3(1.85,board_top+.039,-.42))

func make_runway(index: int,x: float) -> void:
	var body := Pickable.instantiate() as XRToolsPickable;body.set_script(load("res://commons/artifacts/pallet_assemblage/pallet_piece.gd"));body.name = "Runway"+str(index)
	for c in body.get_children():
		if c is CollisionShape3D:c.free()
	body.freeze = true;body.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC;body.release_mode = XRToolsPickable.ReleaseMode.FROZEN
	body.mass = 2.1;body.collision_layer = 1;body.collision_mask = 1
	var size := Vector3(1.2,.022,.145);var mesh := MeshInstance3D.new();mesh.mesh = Timber.mesh(size);mesh.material_override = Timber.material();body.add_child(mesh)
	var collision := CollisionShape3D.new();collision.shape = BoxShape3D.new();collision.shape.size = size;body.add_child(collision)
	body.position = Vector3(x,line_y(x),0);body.rotation.z = -atan(slope);work.add_child(body);ramp_pieces.append(body)
	remember(body,-size/2,size,"Loose track board / 1.2 m / move by hand")

func pose(id: String,p: Vector3,r := Vector3.ZERO) -> void:
	# Saved sculptures supply their actual poses later through the normal config.
	var body: Node3D = work.pieces[id];body.position = p;body.rotation = r
	work.part_defaults[id].position = work.arr(p);work.part_defaults[id].rotation = work.arr(body.rotation_degrees)
	PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,body.global_transform)

func box(host: Node3D,id: String,p: Vector3,size: Vector3,mat: Material) -> void:
	var mesh := MeshInstance3D.new();mesh.name = id;mesh.mesh = Timber.mesh(size) if mat==Timber.material() else BoxMesh.new()
	if mesh.mesh is BoxMesh:mesh.mesh.size = size
	mesh.position = p;mesh.material_override = mat;host.add_child(mesh)
	var collision_host := host
	if not host is CollisionObject3D:collision_host = StaticBody3D.new();host.add_child(collision_host)
	var col := CollisionShape3D.new();col.shape = BoxShape3D.new();col.shape.size = size;col.position = p;collision_host.add_child(col)

func remember(node: Node3D,p: Vector3,size: Vector3,label: String) -> void:
	work.part_defaults[str(node.name)] = {"position":work.arr(node.position),"rotation":work.arr(node.rotation_degrees),"bounds":[p.x,p.y,p.z,size.x,size.y,size.z],"label":label}

func reset_ball() -> void:
	if not is_instance_valid(ball):return
	if ball.is_picked_up():
		work.status.text = "RELEASE THE BALL BEFORE RESET";return
	for part in ramp_pieces:
		if not is_instance_valid(part):continue
		if part.is_picked_up():work.status.text = "RELEASE THE TRACK BOARD BEFORE RESET";return
		part.freeze = true;part.position = work.vec(work.part_defaults[str(part.name)].position);part.rotation_degrees = work.vec(work.part_defaults[str(part.name)].rotation)
		PhysicsServer3D.body_set_state(part.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,part.global_transform)
	ball.freeze = true;ball.position = ball_rest;ball.linear_velocity = Vector3.ZERO;ball.angular_velocity = Vector3.ZERO
	PhysicsServer3D.body_set_state(ball.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,ball.global_transform)
	running = false;outcome = -1;elapsed = 0;hit_inputs.clear();passage_times.clear()
	if is_instance_valid(output):
		if output.is_picked_up():work.status.text = "RELEASE THE CONE BEFORE RESET";return
		output.freeze = true;output.transform = cone_rest;output.linear_velocity = Vector3.ZERO;output.angular_velocity = Vector3.ZERO
		PhysicsServer3D.body_set_state(output.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,output.global_transform)
	work.status.text = ready_text()

func begin_run() -> void:
	if work.pieces.size()!=20 or not is_instance_valid(output):return
	running = true;elapsed = 0;outcome = -1;hit_inputs.clear();passage_times.clear()
	output.freeze = false;output.sleeping = false
	work.status.text = "OBSERVING THE BALL"
func release_ball() -> void:
	if not is_instance_valid(ball) or ball.is_picked_up() or not ball.freeze:return
	begin_run();ball.freeze = false;ball.sleeping = false
func contact(body: Node3D) -> void:
	if not running:return
	if body==output:outcome = 1;running = false;passage_times["TRUE"] = elapsed;work.status.text = "TRUE / BALL HIT THE INVERTED CONE"
	elif body==work.pieces.block_1_1 or body==work.pieces.block_3_1:
		var id := "X" if body==work.pieces.block_1_1 else "Y"
		if not hit_inputs.has(id):hit_inputs.append(id)
		if supports:work.status.text = id+" / SUPPORTED"
		else:outcome = 0;work.status.text = "0 / "+id+" OBSTRUCTS THE PATH"
	elif supports and (body==work.get_node("Board") or body==work.get_node_or_null("Board2")):
		outcome = 0;running = false;passage_times["LOSS"] = elapsed
		work.status.text = "0 / BALL FELL THROUGH THE GAP"
func _physics_process(delta: float) -> void:
	if not running:return
	elapsed += delta
	var x: float = work.to_local(ball.global_position).x
	if x>=input_x and not passage_times.has("X"):passage_times["X"] = elapsed
	if x>=input_y and not passage_times.has("Y"):passage_times["Y"] = elapsed
	if ball.is_picked_up():running = false;work.status.text = "BALL IN HAND / DROP TO TEST";return
	if ball.global_position.y<work.global_position.y-.1:running = false;outcome = 0;work.status.text = "0 / BALL LEFT THE BOARD"
	elif elapsed>14:running = false;work.status.text = "0 / PATH OBSTRUCTED" if outcome==0 else "NO ARRIVAL / RESET THE BALL"

func carried_parts() -> Array:
	return [ball,output]+ramp_pieces
