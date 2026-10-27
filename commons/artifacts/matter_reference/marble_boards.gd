extends "res://commons/artifacts/matter_reference/matter_reference.gd"
## Original one-marble hole and physical flip-flops; no Boolean-driven routing.
var marbles: Array[RigidBody3D] = []
var queue: Array[String] = []
var next_drop := 0.0
var live := false
var board_graph_path := "res://commons/artifacts/matter_reference/boards.json"
func mat(look: String) -> Material:
	if materials.has(look):return materials[look]
	var m := StandardMaterial3D.new();m.albedo_color = Color({"back":"34313f","glass":"b9c3d6","rocker":"c2384f","hole":"c2384f","tray":"a36600","stop":"77738a","floor":"d8d6e0","marble":"ffffff","dark":"34313f"}.get(look,"fbfafd"));m.roughness = .6
	if look=="glass":m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA;m.albedo_color.a = .1;m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if look=="marble":m.roughness = .2;m.clearcoat_enabled = true;m.clearcoat = 1
	materials[look] = m;return m
func _ready() -> void:
	graph = JSON.parse_string(FileAccess.get_file_as_string(board_graph_path)).graphs[kind]
	for rec in graph.bodies:
		records[rec.id] = rec
		# Computing factories use a large catch plane as their world ground.
		# The standard Void slab supplies it; it must not bridge the shafts.
		if graph.has("templates") and rec.look in ["floor","table"]:continue
		var body: PhysicsBody3D = RigidBody3D.new() if float(rec.mass)>0 else StaticBody3D.new()
		if body is RigidBody3D:
			body.mass = rec.mass;body.inertia = v(rec.inertia);body.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM;body.freeze = true;body.can_sleep = false;body.continuous_cd = true
			body.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE;body.angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE;body.linear_damp = -log(1.0-rec.linear_damping);body.angular_damp = -log(1.0-rec.angular_damping)
			body.angular_damp = float(pending.get("rocker_drag",-log(.7)))
		var pm := PhysicsMaterial.new();pm.friction = .1;pm.bounce = .02;body.physics_material_override = pm
		body.name = rec.id;body.position = v(rec.position);body.quaternion = q(rec.quaternion);body.collision_layer = 1;body.collision_mask = 1;add_child(body);bodies[rec.id] = body
		for sh in rec.shapes:
			var col := CollisionShape3D.new();col.shape = BoxShape3D.new();col.shape.size = v(sh.size);col.shape.margin = .001;col.position = v(sh.at);col.quaternion = q(sh.quaternion);body.add_child(col)
			var mesh := MeshInstance3D.new();mesh.mesh = BoxMesh.new();mesh.mesh.size = v(sh.size);mesh.position = col.position;mesh.quaternion = col.quaternion;mesh.material_override = mat(rec.look);body.add_child(mesh)
		remember(body,"Original "+str(rec.look));homes[rec.id] = body.transform
	for r in graph.rockers:
		var pin := Node3D.new();pin.name = "Axle_"+r.name;pin.position = Vector3(r.px,r.py,0);add_child(pin)
		var mesh := MeshInstance3D.new();mesh.mesh = CylinderMesh.new();mesh.mesh.top_radius = .03;mesh.mesh.bottom_radius = .03;mesh.mesh.height = .3;mesh.rotation.x = PI/2;mesh.material_override = mat("stop");pin.add_child(mesh);remember(pin,"Original physical rocker axle")
	for id in graph.inlets:
		var p: Dictionary = graph.inlets[id];var hopper := Node3D.new();hopper.name = "Hopper_"+id;hopper.position = Vector3(p.x,p.y+.24,0);add_child(hopper)
		var cup := MeshInstance3D.new();cup.mesh = CylinderMesh.new();cup.mesh.top_radius = .2;cup.mesh.bottom_radius = .12;cup.mesh.height = .32;cup.mesh.cap_top = false;cup.mesh.cap_bottom = false;cup.material_override = mat("tray");hopper.add_child(cup)
		for xy in [[-.06,.02],[.07,.04],[0,.13]]:
			var ball := MeshInstance3D.new();ball.mesh = SphereMesh.new();ball.mesh.radius = .075;ball.mesh.height = .15;ball.position = Vector3(xy[0],xy[1]-.04,0);ball.material_override = mat("marble");hopper.add_child(ball)
		remember(hopper,"Original input hopper / "+id)
	build_controls();apply_poses(pending)
	for id in bodies:homes[id] = bodies[id].transform
	set_meta("void_preview_kind","Original marble-board geometry and masses; native Jolt hinge and sphere contacts. Output reads physical rocker angle and occupied trays. Source 240Hz solver translated to Godot 60Hz; validation recorded per mechanism.")
	reset_take()
func build_controls() -> void:
	var host := Node3D.new();host.name = "Controls";host.position = Vector3(0,.8,.75);add_child(host);box_mesh(host,Vector3(0,-.4,0),Vector3(1.1,.8,.18),"dark")
	var names: Array = graph.inlets.keys();names.append("CLEAR")
	for i in names.size():
		var id: String = names[i];var button := ButtonScene.instantiate();button.name = id;button.label = ("DROP " if id!="CLEAR" else "")+id;button.position = Vector3((i-(names.size()-1)*.5)*.3,.06,.14);button.cap_color = Color("e45391");host.add_child(button);buttons[id] = button;button.pressed.connect(reset_take if id=="CLEAR" else enqueue.bind(id))
	status = Label3D.new();status.position = Vector3(0,.32,.14);status.font_size = 28;status.pixel_size = .0009;host.add_child(status);finish_control_labels(host);remember(host,"Reachable source input hoppers and clear control")
func reset_take() -> void:
	live = false;elapsed = 0;next_drop = 0;queue.clear()
	for b in marbles:
		if is_instance_valid(b):b.queue_free()
	marbles.clear()
	for joint in joints:
		if is_instance_valid(joint):joint.queue_free()
	joints.clear()
	for id in bodies:
		var body: Node3D = bodies[id]
		if body is RigidBody3D:body.freeze = true;body.linear_velocity = Vector3.ZERO;body.angular_velocity = Vector3.ZERO
		body.transform = homes[id];PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,body.global_transform)
	status.text = kind.to_upper()+" / DROP MARBLES ONE AT A TIME"
func start_physics() -> void:
	if live:return
	live = true
	for body in bodies.values():
		if body is RigidBody3D:body.freeze = false
	for h in graph.hinges:
		var joint := HingeJoint3D.new();joint.position = bodies[h.a].position+v(h.pivot_a);add_child(joint);joint.node_a = joint.get_path_to(bodies[h.a]);joint.node_b = joint.get_path_to(bodies[h.b]);joint.exclude_nodes_from_collision = true;joints.append(joint)
func enqueue(id: String) -> void:queue.append(id);start_physics()
func drop(id: String) -> RigidBody3D:
	start_physics()
	var ball := RigidBody3D.new();ball.mass = .05;ball.can_sleep = false;ball.continuous_cd = true;ball.linear_damp = -log(.99);ball.angular_damp = -log(.95);ball.gravity_scale = 9.82/9.8
	ball.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE;ball.angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	if kind in ["xor","not","half"]:ball.linear_damp = float(pending.get("marble_drag",1.0))
	ball.collision_layer = 1;ball.collision_mask = 1;var pm := PhysicsMaterial.new();pm.friction = .05;pm.bounce = .05;ball.physics_material_override = pm
	var inlet: Dictionary = graph.inlets[id];ball.position = Vector3(inlet.x,inlet.y,0);add_child(ball)
	var col := CollisionShape3D.new();col.shape = SphereShape3D.new();col.shape.radius = .1;ball.add_child(col)
	var mesh := MeshInstance3D.new();mesh.mesh = SphereMesh.new();mesh.mesh.radius = .1;mesh.mesh.height = .2;mesh.material_override = mat("marble");ball.add_child(mesh);marbles.append(ball)
	# The reference starts at z=0 with perfectly planar contacts. A native
	# guide keeps Jolt's asymmetric contact manifold from drifting sideways.
	var joint := Generic6DOFJoint3D.new();joint.position = ball.position;add_child(joint);joint.node_a = joint.get_path_to(bodies[graph.bodies[0].id]);joint.node_b = joint.get_path_to(ball);joint.exclude_nodes_from_collision = false
	for axis in ["x","y","z"]:
		joint.call("set_flag_"+axis,Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT,axis=="z");joint.call("set_flag_"+axis,Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT,axis!="z")
		joint.call("set_param_"+axis,Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT,0.0);joint.call("set_param_"+axis,Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT,0.0);joint.call("set_param_"+axis,Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT,0.0);joint.call("set_param_"+axis,Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT,0.0)
	joints.append(joint);return ball
func count_zone(id: String) -> int:
	var z: Dictionary = graph.zones[id];var count := 0
	for b in marbles:
		var p := to_local(b.global_position)
		if p.x>z.x0 and p.x<z.x1 and p.y>z.y0 and p.y<z.y1:count+=1
	return count
func read() -> Dictionary:
	match kind:
		"and","or":return {"Z":int(count_zone("Z")>0)}
		"xor","not":return {"Z":int(bodies[graph.rockers[0].body].rotation.z<0)}
		"half":return {"S":int(bodies[graph.rockers[0].body].rotation.z<0),"C":int(count_zone("C")>0)}
		"count":
			var value := 0;var bits: Array = []
			for i in graph.rockers.size():
				var bit := int(bodies[graph.rockers[i].body].rotation.z<0);bits.append(bit);value += bit*(1<<i)
			return {"value":value,"bits":bits,"over":count_zone("over")}
	return {}
func _physics_process(dt: float) -> void:
	if not live:return
	elapsed += dt
	if not queue.is_empty() and elapsed>=next_drop:
		drop(queue.pop_front());next_drop = elapsed+(.8 if kind in ["and","or"] else 1.3)
	status.text = kind.to_upper()+" / "+JSON.stringify(read())+" / "+str(marbles.size())+" MARBLES"
