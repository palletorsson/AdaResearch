extends "res://commons/artifacts/matter_reference/matter_reference.gd"
## New studies: gravity, contact friction and an explicitly elastic ideal cable.
## Outcomes are measured from Jolt bodies. No success animation moves a body.
var study := "ramp"
var angle_degrees := 18.0
var pull_mass := .55
var surface_index := 1
var friction_values := [.15,.35,.65]
var released := false
var history: Array = []
var starts: Dictionary = {}
var reading: Dictionary = {}
var travelled: Dictionary = {}
var settled := 0.0
var cable_length := 0.0
var cable_tension := 0.0
var cable_stiffness := 400.0
var cable_damping := 8.0
var cable_lines: Array[MeshInstance3D] = []
var wheel_mesh: MeshInstance3D
var ledger: Label3D
var rebuilding := false

func apply_grid_config(config: Dictionary) -> void:
	study = str(config.get("study",study));angle_degrees = clampf(float(config.get("angle",18)),6,42);pull_mass = clampf(float(config.get("pull_mass",.55)),.1,1.5);surface_index = clampi(int(config.get("surface",1)),0,2);super.apply_grid_config(config)

func mat(look: String) -> Material:
	if look=="grit":
		if materials.has(look):return materials[look]
		var material := StandardMaterial3D.new();material.albedo_texture = load("res://commons/artifacts/matter_reference/textures/sand.png") as Texture2D;material.albedo_color = Color("575149");material.roughness = .98;materials[look] = material;return material
	if look not in ["steel","ivory","handle","cable"]:return super.mat(look)
	if materials.has(look):return materials[look]
	var material := StandardMaterial3D.new();material.albedo_color = Color({"steel":"17171e","ivory":"eee9dd","handle":"ee478f","cable":"d5c4a5"}[look]);material.roughness = .34 if look=="steel" else .7;material.metallic = .75 if look=="steel" else 0.0;materials[look] = material;return material

func label(host: Node3D,text: String,at: Vector3,size := 22) -> Label3D:
	var node := Label3D.new();node.text = text;node.position = at;node.font_size = size;node.pixel_size = .0014;node.modulate = Color("fff3e1");node.outline_modulate = Color("211c28");node.outline_size = 4;host.add_child(node);return node

func fixed(id: String,at: Vector3,size: Vector3,look := "plywood",mu := .35) -> StaticBody3D:
	var node := StaticBody3D.new();node.name = id;node.position = at;node.collision_layer = 1;node.collision_mask = 1;add_child(node)
	var shape := CollisionShape3D.new();shape.shape = BoxShape3D.new();shape.shape.size = size;shape.shape.margin = .001;node.add_child(shape);box_mesh(node,Vector3.ZERO,size,look)
	var pm := PhysicsMaterial.new();pm.friction = mu;pm.bounce = 0;node.physics_material_override = pm;remember(node,id);return node

func cube(id: String,at: Vector3,mass: float,mu: float,size := .34) -> XRToolsPickable:
	var body := Pickable.instantiate() as XRToolsPickable
	for child in body.get_children():child.free()
	body.name = id;body.position = at;body.mass = mass;body.freeze = true;body.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC;body.can_sleep = false;body.continuous_cd = true;body.collision_layer = 1|4;body.collision_mask = 1|4;body.enabled = true;body.release_mode = XRToolsPickable.ReleaseMode.UNFROZEN;body.set_meta("desktop_passive_carry",true)
	body.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE;body.angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE;body.linear_damp = 0;body.angular_damp = 0
	var pm := PhysicsMaterial.new();pm.friction = mu;pm.bounce = 0;body.physics_material_override = pm;add_child(body)
	var shape := CollisionShape3D.new();shape.shape = BoxShape3D.new();shape.shape.size = Vector3.ONE*size;shape.shape.margin = .001;body.add_child(shape);box_mesh(body,Vector3.ZERO,Vector3.ONE*size,"ivory")
	# Thin steel edges keep the familiar cube legible on the wooden surface.
	for axis in 3:
		for s in [-1,1]:
			for t in [-1,1]:
				var p := Vector3.ZERO;var edge := Vector3.ONE*.006;p[(axis+1)%3] = s*size*.501;p[(axis+2)%3] = t*size*.501;edge[axis] = size+.005;box_mesh(body,p,edge,"steel")
	body.picked_up.connect(picked.bind(id));body.dropped.connect(dropped.bind(id));bodies[id] = body;remember(body,id+" / hand-placeable "+str(mass)+" kg cube");return body

func prop(id: String,at: Vector3,size: Vector3,look := "crate") -> void:
	fixed(id,at,size,look)

func _ready() -> void:
	graph = {"inputs":{},"hinges":[],"planar":[]}
	match study:
		"ramp":build_ramp()
		"coast":build_coast()
		"pull":build_pull()
	build_controls();apply_poses(pending)
	for id in bodies:homes[id] = bodies[id].transform
	reset_take()
	set_meta("void_preview_kind","New native friction study. Jolt gravity/contact determines movement; no output poses are animated. Pull uses an explicitly elastic unilateral cable with an ideal massless roller, not a native pulley joint. Members remain independently editable; arbitrary rearrangements can break the calibrated demonstration.")

func build_ramp() -> void:
	var track := fixed("Ramp",Vector3(0,1,0),Vector3(2.8,.08,.72),"grit" if surface_index==2 else "plywood",float(friction_values[surface_index]));track.rotation.z = -deg_to_rad(angle_degrees)
	for x in [-1.36,1.36]:
		var stop := CollisionShape3D.new();stop.shape = BoxShape3D.new();stop.shape.size = Vector3(.08,.19,.72);stop.position = Vector3(x,.10,0);track.add_child(stop);box_mesh(track,stop.position,stop.shape.size,"steel")
	remember(track,"Tilted wooden plank / real contact surface")
	var catcher := fixed("RampCatch",track.transform*Vector3(1.36,.25,0),Vector3(.10,.50,.8),"steel",float(friction_values[surface_index]));catcher.basis = track.basis;remember(catcher,"Downhill catch stop / independently editable")
	var body := cube("Crate",track.transform*Vector3(-.85,.213,0),2,float(friction_values[surface_index]));body.basis = track.basis
	for x in [-.9,.9]:
		var top: float = 1-x*tan(deg_to_rad(angle_degrees))-.04/cos(deg_to_rad(angle_degrees))
		prop("RampSupport"+str(int(x*10)),Vector3(x,top*.5,0),Vector3(.38,top,.62))
	var ruler := Node3D.new();ruler.name = "TravelMarks";add_child(ruler)
	for i in range(13):
		var at: Vector3 = track.transform*Vector3(-1.2+i*.2,.047,.38);box_mesh(ruler,at,Vector3(.018,.012,.12),"steel")
	remember(ruler,"Twenty-centimetre witness marks")
	remember(body,"Two-kilogram cube / gravity supplies the pull")

func build_coast() -> void:
	for i in 2:
		var z := -.5 if i==0 else .5;var mu := .06 if i==0 else .65;var id := "Smooth" if i==0 else "Rough"
		var track := fixed(id+"Plank",Vector3(0,.61,z),Vector3(3.6,.08,.76),"plywood" if i==0 else "grit",mu)
		for x in [-1.75,1.75]:
			var stop := CollisionShape3D.new();stop.shape = BoxShape3D.new();stop.shape.size = Vector3(.08,.15,.76);stop.position = Vector3(x,.09,0);track.add_child(stop);box_mesh(track,stop.position,stop.shape.size,"steel")
		label(track,id.to_upper(),Vector3(-1.25,.14,.4),18);remember(track,id+" plank / contact friction "+str(mu));cube(id,Vector3(-1.1,.823,z),2,mu)
	for x in [-1.25,1.25]:prop("CoastPlinth"+str(int(x*100)),Vector3(x,.285,0),Vector3(.45,.57,1.6))
	var ruler := Node3D.new();ruler.name = "TravelMarks";add_child(ruler)
	for i in range(16):box_mesh(ruler,Vector3(-1.5+i*.2,.66,0),Vector3(.012,.012,1.9),"steel")
	remember(ruler,"Same impulse, two actual stopping distances")

func build_pull() -> void:
	var track := fixed("PullPlank",Vector3(-.1,.61,0),Vector3(3.1,.08,.8),"plywood",float(friction_values[surface_index]))
	for x in [-1.6,1.4]:
		var stop := CollisionShape3D.new();stop.shape = BoxShape3D.new();stop.shape.size = Vector3(.08,.19,.8);stop.position = Vector3(x,.10,0);track.add_child(stop);box_mesh(track,stop.position,stop.shape.size,"steel")
	remember(track,"Level plank / contact resists the suspended mass")
	for x in [-1.1,.9]:prop("PullPlinth"+str(int(x*10)),Vector3(x,.285,0),Vector3(.45,.57,.75))
	cube("Crate",Vector3(-.85,.823,0),2,float(friction_values[surface_index]));cube("Weight",Vector3(2,.43,0),pull_mass,0,.26)
	var pulley := Node3D.new();pulley.name = "Pulley";pulley.position = Vector3(1.85,.843,0);add_child(pulley)
	box_mesh(pulley,Vector3(-.17,-.19,-.29),Vector3(.72,.06,.10),"steel");box_mesh(pulley,Vector3(0,0,-.16),Vector3(.055,.38,.055),"steel")
	wheel_mesh = MeshInstance3D.new();wheel_mesh.mesh = CylinderMesh.new();wheel_mesh.mesh.top_radius = .15;wheel_mesh.mesh.bottom_radius = .15;wheel_mesh.mesh.height = .07;wheel_mesh.rotation.x = PI/2;wheel_mesh.material_override = mat("steel");pulley.add_child(wheel_mesh)
	var hub := MeshInstance3D.new();hub.mesh = CylinderMesh.new();hub.mesh.top_radius = .04;hub.mesh.bottom_radius = .04;hub.mesh.height = .11;hub.rotation.x = PI/2;hub.material_override = mat("handle");pulley.add_child(hub);remember(pulley,"Ideal roller / elastic cable guide")
	for i in 12:
		var a := Vector3(cos(i*PI/24),sin(i*PI/24),0)*.15;var b := Vector3(cos((i+1)*PI/24),sin((i+1)*PI/24),0)*.15
		var line := MeshInstance3D.new();line.mesh = CylinderMesh.new();line.mesh.top_radius = .008;line.mesh.bottom_radius = .008;line.mesh.height = a.distance_to(b);line.position = (a+b)*.5;line.quaternion = Quaternion(Vector3.UP,(b-a).normalized());line.material_override = mat("cable");pulley.add_child(line)
	remember(pulley,"Ideal roller / elastic cable guide")
	var cable := Node3D.new();cable.name = "Cable";add_child(cable)
	for i in 2:
		var line := MeshInstance3D.new();line.mesh = CylinderMesh.new();line.mesh.top_radius = .008;line.mesh.bottom_radius = .008;line.mesh.height = 1;line.material_override = mat("cable");cable.add_child(line);cable_lines.append(line)
	update_cable_visuals();remember(cable,"Visible elastic cable / spring tension, no pose constraint")

func build_controls() -> void:
	var host := Node3D.new();host.name = "Controls";host.position = Vector3(0,.8,1.65);add_child(host);box_mesh(host,Vector3(0,-.4,0),Vector3(1.5,.8,.18),"steel")
	var names := ["LESS","MORE","SURFACE","RELEASE","RESET"]
	for i in names.size():
		var button := ButtonScene.instantiate();button.name = names[i];button.label = names[i];button.position = Vector3((i-2)*.28,.08,.14);button.cube_size = .055;button.cap_color = Color("ee478f");host.add_child(button);buttons[names[i]] = button;button.pressed.connect(command.bind(names[i]))
	status = label(host,"",Vector3(0,.32,.14));finish_control_labels(host);remember(host,"Adjust, release, witness, repeat")
	var witness := Node3D.new();witness.name = "Witness";witness.position = Vector3(-2.3 if study=="pull" else 2.3,1.0,1.65);add_child(witness);box_mesh(witness,Vector3.ZERO,Vector3(1.3,.65,.08),"steel");box_mesh(witness,Vector3(0,-.5,0),Vector3(.12,1.0,.12),"crate");ledger = label(witness,"",Vector3(0,.04,.06),18);remember(witness,"Three measured takes / encounter-local comparison")
	button_visibility("LESS",study!="coast");button_visibility("MORE",study!="coast");button_visibility("SURFACE",study!="coast");button_text("RELEASE","SAME PUSH" if study=="coast" else "RELEASE")

func parameter_text() -> String:
	if study=="ramp":return "%.0f° / FRICTION %.2f"%[angle_degrees,friction_values[surface_index]]
	if study=="pull":return "%.2f kg / FRICTION %.2f"%[pull_mass,friction_values[surface_index]]
	return "2 kg EACH / SAME 2.4 Ns PUSH"

func command(id: String) -> void:
	if id=="RESET":reset_take();return
	if id=="RELEASE":
		if result>=0:reset_take()
		release_take();return
	if released:status.text = "RESET BEFORE ADJUSTING";return
	if rebuilding:return
	if id=="SURFACE":surface_index = (surface_index+1)%friction_values.size()
	elif study=="ramp":angle_degrees = clampf(angle_degrees+(-2 if id=="LESS" else 2),6,42)
	elif study=="pull":pull_mass = clampf(snappedf(pull_mass+(-.1 if id=="LESS" else .1),.05),.1,1.5)
	pending.angle = angle_degrees;pending.pull_mass = pull_mass;pending.surface = surface_index
	# Rebuild parameter-dependent geometry, retaining explicitly edited member poses.
	rebuilding = true;rebuild_parameters.call_deferred()

func rebuild_parameters() -> void:
	resetting_take = true
	for body in bodies.values():
		if hand_holds(body):release_hand_hold(body)
	for child in get_children():child.free()
	bodies.clear();homes.clear();buttons.clear();part_defaults.clear();joints.clear();plane_joints.clear();cable_lines.clear();_ready();rebuilding = false

func picked(_body: Node3D,id: String) -> void:
	release_plane(id);hand_placed[id] = true;quiet = 0

func dropped(_body: Node3D,_id: String) -> void:
	if not resetting_take and not released:release_take()

func reset_take() -> void:
	resetting_take = true
	for body in bodies.values():
		if hand_holds(body):release_hand_hold(body)
	for joint in joints:
		if is_instance_valid(joint):joint.queue_free()
	for guide in plane_joints.values():
		if is_instance_valid(guide.anchor):guide.anchor.queue_free()
	joints.clear();plane_joints.clear();released = false;running = false;elapsed = 0;settled = 0;result = -1;reading.clear();travelled.clear();starts.clear();hand_placed.clear();cable_tension = 0
	for id in bodies:
		var body: RigidBody3D = bodies[id];body.freeze = true;body.linear_velocity = Vector3.ZERO;body.angular_velocity = Vector3.ZERO;body.transform = homes[id];PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,body.global_transform)
	if study=="pull":cable_length = cable_span();update_cable_visuals()
	resetting_take = false;update_readout()

func weight_guide() -> void:
	var anchor := StaticBody3D.new();anchor.position = bodies.Weight.position;add_child(anchor);var joint := Generic6DOFJoint3D.new();joint.position = anchor.position;add_child(joint);joint.node_a = joint.get_path_to(anchor);joint.node_b = joint.get_path_to(bodies.Weight)
	for axis in ["x","y","z"]:
		joint.call("set_flag_"+axis,Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT,axis!="y");joint.call("set_flag_"+axis,Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT,true)
		joint.call("set_param_"+axis,Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT,0.0);joint.call("set_param_"+axis,Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT,0.0);joint.call("set_param_"+axis,Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT,0.0);joint.call("set_param_"+axis,Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT,0.0)
	joints.append(joint);plane_joints.Weight = {"joint":joint,"anchor":anchor}

func release_take() -> void:
	if released:return
	released = true;running = true;elapsed = 0
	for id in bodies:
		starts[id] = bodies[id].global_position;travelled[id] = 0.0
		if hand_holds(bodies[id]):continue
		bodies[id].freeze = false
		if study=="pull" and id=="Weight":weight_guide()
		else:install_plane(id)
		if study=="coast":bodies[id].apply_central_impulse(global_basis.x*2.4)
	update_readout()

func cable_points() -> Array[Vector3]:
	var pulley: Node3D = get_node("Pulley")
	return [bodies.Crate.to_global(Vector3(0,.17,0)),pulley.to_global(Vector3(0,.15,0)),pulley.to_global(Vector3(.15,0,0)),bodies.Weight.to_global(Vector3(0,.13,0))]

func cable_span() -> float:
	var points := cable_points();return points[0].distance_to(points[1])+points[2].distance_to(points[3])

func update_cable_visuals() -> void:
	if cable_lines.size()!=2:return
	var points := cable_points()
	for i in 2:
		var a := to_local(points[i*2]);var b := to_local(points[i*2+1]);var delta := b-a;var line := cable_lines[i];line.position = (a+b)*.5;line.scale.y = maxf(.001,delta.length());line.quaternion = Quaternion(Vector3.UP,delta.normalized())
	wheel_mesh.rotation.z = -(bodies.Crate.global_position-starts.Crate).dot(global_basis.x)/.15 if starts.has("Crate") else 0.0

func cable_forces() -> void:
	var points := cable_points();var left := (points[0]-points[1]).normalized();var right := (points[3]-points[2]).normalized();var speed: float = bodies.Crate.linear_velocity.dot(left)+bodies.Weight.linear_velocity.dot(right)
	var extension := cable_span()-cable_length
	cable_tension = maxf(0,cable_stiffness*extension+cable_damping*speed) if extension>0 else 0.0
	bodies.Crate.apply_central_force(-left*cable_tension);bodies.Weight.apply_central_force(-right*cable_tension);update_cable_visuals()

func update_readout() -> void:
	if not is_instance_valid(status):return
	var names := {"ramp":"LET GO","coast":"KEEP GOING","pull":"ALMOST ENOUGH"}
	status.text = str(names[study])+" / "+parameter_text()+"\n"+(str(reading.get("summary","OBSERVING")) if released else "ADJUST, THEN RELEASE")
	if is_instance_valid(ledger):
		var lines: Array[String] = ["LAST TAKES"]
		for take in history:lines.append(str(take))
		if history.is_empty():lines.append("RELEASE TO MEASURE")
		ledger.text = "\n".join(lines)

func _physics_process(dt: float) -> void:
	if not released:return
	if study=="pull":cable_forces()
	if not running:return
	for body in bodies.values():
		if hand_holds(body):return
	elapsed += dt;var moving := false;var left_plank := false
	for id in bodies:
		var distance: float = (bodies[id].global_position-starts[id]).dot(global_basis.x if study!="ramp" else get_node("Ramp").global_basis.x)
		if study=="pull" and id=="Weight":distance = (bodies[id].global_position-starts[id]).dot(-global_basis.y)
		if study=="ramp":
			var at: Vector3 = get_node("Ramp").to_local(bodies[id].global_position);left_plank = absf(at.x)>1.75 or absf(at.z)>.65 or absf(at.y-.213)>.6
		if not left_plank:travelled[id] = maxf(float(travelled[id]),distance)
		if bodies[id].linear_velocity.length()>.025:moving = true
	settled = 0 if moving else settled+dt
	var summary := ""
	if study=="coast":summary = "SMOOTH %.1f / ROUGH %.1f cm"%[travelled.Smooth*100,travelled.Rough*100]
	else:summary = ("SLID " if travelled.Crate>.08 else "STUCK ")+"%.1f cm"%(travelled.Crate*100)
	if left_plank:summary += " / LEFT PLANK"
	reading = {"summary":summary,"travel":travelled.duplicate(),"seconds":elapsed,"angle":angle_degrees,"pull_mass":pull_mass,"friction":friction_values[surface_index],"cable_tension":cable_tension,"hand_placed":not hand_placed.is_empty()}
	if elapsed>1 and settled>.75 or elapsed>8 or left_plank:
		running = false;result = int(travelled.get("Crate",travelled.get("Smooth",0))>.08);reading.finished = settled>.75;history.append(parameter_text()+" / "+summary)
		if history.size()>3:history.pop_front()
	update_readout()
