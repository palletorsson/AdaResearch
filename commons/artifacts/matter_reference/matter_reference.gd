extends Node3D
## Source-faithful full-size Matter Gates from the user's Three.js/Cannon factory.
## Input values only release held objects. Outputs are read from real Jolt bodies.
const Timber = preload("res://commons/artifacts/primitive_encounters/timber_finish.gd")
const Pickable = preload("res://addons/godot-xr-tools/objects/pickable.tscn")
const ButtonScene = preload("res://commons/interactables/cube_button.tscn")
var kind := "and"
var graph_path := "res://commons/artifacts/matter_reference/gates.json"
var pending: Dictionary = {}
var graph: Dictionary
var bodies: Dictionary = {}
var homes: Dictionary = {}
var records: Dictionary = {}
var part_defaults: Dictionary = {}
var inputs := {"X":true,"Y":true}
var buttons: Dictionary = {}
var ropes: Dictionary = {}
var chocks: Dictionary = {}
var joints: Array[Joint3D] = []
var plane_joints: Dictionary = {}
var status: Label3D
var running := false
var elapsed := 0.0
var quiet := 0.0
var first_z := -1.0
var result := -1
var hit_log: Array = []
var materials: Dictionary = {}
var hand_placed: Dictionary = {}
var resetting_take := false

func hand_placement_enabled() -> bool:
	# Hinged mechanisms and the other source families keep their own input contract.
	return graph_path in ["res://commons/artifacts/matter_reference/gates.json","res://commons/artifacts/matter_reference/chain.json"]

func hand_part(rec: Dictionary) -> bool:
	return hand_placement_enabled() and float(rec.mass)>0 and rec.role not in ["beam","hinged"]

func hand_holds(body: Node3D) -> bool:
	return body is XRToolsPickable and body.is_picked_up()

func release_hand_hold(body: XRToolsPickable) -> void:
	var holder := body.get_picked_up_by()
	if holder.has_method("drop_object"):body.drop()
	else:body.let_go(holder,Vector3.ZERO,Vector3.ZERO) # Desktop MouseGrip has no drop_object.

func apply_grid_config(config: Dictionary) -> void:
	pending = config.duplicate(true);kind = str(config.get("kind",kind))
	if is_node_ready():apply_poses(config)
static func v(a: Array) -> Vector3:return Vector3(float(a[0]),float(a[1]),float(a[2]))
static func q(a: Array) -> Quaternion:return Quaternion(float(a[0]),float(a[1]),float(a[2]),float(a[3]))
static func arr(a: Vector3) -> Array:return [a.x,a.y,a.z]
func mat(look: String) -> Material:
	if materials.has(look):return materials[look]
	var colors := {"board":"9c8d78","crate":"c9a77a","platform":"c9a77a","crate2":"c69d67","sandbag":"b9a98c","plywood":"dfcda9","breeze":"92938d","sack":"cfc2a6","tyre":"232220","ball":"c4462e","iron":"3b3d40","skittle":"f1ede4","ballZ":"e8892b","medball":"5b3a28","rope":"b49a6a","dark":"4a4540","red":"c4462e"}
	var m := StandardMaterial3D.new();m.albedo_color = Color(colors.get(look,"c9a77a"));m.roughness = .85
	var texture_name: String = {"crate":"pine","platform":"pine","board":"board","post":"pine","stop":"pine","beam":"pine","seesaw":"pine","crate2":"card","sandbag":"sand","plywood":"ply","breeze":"stone","sack":"paper"}.get(look,"")
	if not texture_name.is_empty():
		# ResourceLoader follows the texture import in exported Android packages.
		m.albedo_color = Color.WHITE;m.albedo_texture = load("res://commons/artifacts/matter_reference/textures/"+texture_name+".png") as Texture2D
		if texture_name=="sand":m.uv1_scale = Vector3(2,1,1)
	if look=="iron":m.metallic = .85;m.roughness = .42
	materials[look] = m;return m

func _ready() -> void:
	graph = preload("res://commons/artifacts/matter_reference/source_cache.gd").read_json(graph_path).graphs[kind]
	for rec in graph.bodies:
		records[rec.id] = rec
		if rec.look=="none":continue # The actual Void slab is the source's ground; shafts stay open.
		var body: PhysicsBody3D
		if float(rec.mass)>0:
			var dynamic := Pickable.instantiate() as XRToolsPickable
			for c in dynamic.get_children():c.free()
			dynamic.mass = rec.mass;dynamic.freeze = true;dynamic.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
			dynamic.release_mode = XRToolsPickable.ReleaseMode.UNFROZEN;dynamic.continuous_cd = true;dynamic.can_sleep = false
			dynamic.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM;dynamic.center_of_mass = Vector3.ZERO;dynamic.inertia = v(rec.inertia)
			dynamic.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE;dynamic.angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
			dynamic.linear_damp = -log(1.0-float(rec.linear_damping));dynamic.angular_damp = -log(1.0-float(rec.angular_damping))
			if kind=="nand" and rec.role=="beam":dynamic.angular_damp = float(pending.get("hinge_drag",50.0))
			dynamic.gravity_scale = 9.82/float(ProjectSettings.get_setting("physics/3d/default_gravity",9.8))
			var material := PhysicsMaterial.new();material.friction = .6;material.bounce = .05
			if rec.material=="rubber":material.friction = .9;material.bounce = .15
			if rec.material=="stone":material.friction = 0.0
			if rec.material=="sand":material.friction = .8;material.bounce = 0
			dynamic.physics_material_override = material;dynamic.contact_monitor = true;dynamic.max_contacts_reported = 12
			dynamic.enabled = hand_part(rec)
			dynamic.set_meta("desktop_passive_carry",true)
			dynamic.body_entered.connect(contact.bind(rec.id));dynamic.picked_up.connect(hand_picked.bind(rec.id));dynamic.dropped.connect(hand_dropped.bind(rec.id))
			body = dynamic
		else:body = StaticBody3D.new()
		body.name = rec.id;body.position = v(rec.position);body.quaternion = q(rec.quaternion);body.collision_layer = 1|4 if hand_part(rec) else 1;body.collision_mask = 1|4
		add_child(body);bodies[rec.id] = body
		for sh in rec.shapes:
			var collision := CollisionShape3D.new();collision.position = v(sh.at);collision.quaternion = q(sh.quaternion)
			if sh.type=="box":collision.shape = BoxShape3D.new();collision.shape.size = v(sh.size);collision.shape.margin = .001
			elif sh.type=="convex":
				collision.shape = ConvexPolygonShape3D.new();var points := PackedVector3Array()
				for point in sh.vertices:points.append(v(point))
				collision.shape.points = points;collision.shape.margin = .001
			else:collision.shape = SphereShape3D.new();collision.shape.radius = sh.radius
			body.add_child(collision)
		if rec.look=="tyre":draw_tyre(body)
		elif rec.look=="skittle":draw_skittle(body)
		else:
			for i in rec.shapes.size():
				var sh: Dictionary = rec.shapes[i];var mesh := MeshInstance3D.new();mesh.position = v(sh.at);mesh.quaternion = q(sh.quaternion)
				if sh.type=="box":
					mesh.mesh = BoxMesh.new()
					if mesh.mesh is BoxMesh:mesh.mesh.size = v(sh.size)
				elif sh.type=="convex":
					var st := SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
					for face in sh.faces:
						for n in range(1,face.size()-1):
							for k in [face[0],face[n+1],face[n]]:st.add_vertex(v(sh.vertices[k]))
					st.generate_normals();mesh.mesh = st.commit()
				else:mesh.mesh = SphereMesh.new();mesh.mesh.radius = sh.radius;mesh.mesh.height = sh.radius*2
				mesh.material_override = mat("iron" if rec.look=="seesaw" and i==1 else str(rec.look));body.add_child(mesh)
			if rec.look=="breeze":
				var size := v(rec.shapes[0].size)
				for s in [-1,1]:box_mesh(body,Vector3(0,0,s*size.z*.45),Vector3(size.x*.35,size.y*1.005,size.z*.275),"dark")
		remember(body,str(rec.look)+" / "+str(rec.role)+" / original source part")
	build_dressing();build_controls();apply_poses(pending)
	for id in bodies:homes[id] = bodies[id].transform
	reset_take();set_meta("void_preview_kind","Original Three.js Matter Gates geometry and masses; real Jolt contacts and hinges. Source ground supplied by the standard floor. Pair friction translated to Godot per-body materials; solver calibration is recorded separately.")

func hand_picked(_body: Node3D,id: String) -> void:
	release_plane(id);hand_placed[id] = true
	# A hand has physically removed the suspension/chock. This is not an output bit.
	for input in graph.inputs:
		if graph.inputs[input].body==id:inputs[input] = true
	update_inputs();status.text = "PLACE BY HAND / DROP THE MOVER OR PRESS RELEASE"

func hand_dropped(_body: Node3D,id: String) -> void:
	if resetting_take:return
	quiet = 0
	# Dropping the ball/tyre is a physical start gesture. Supports can be arranged
	# first without starting the whole take. The existing RELEASE control remains.
	if (records[id].role=="mover" or id==str(graph.get("tyre",""))) and not running and result<0:release_take()
	elif running:status.text = kind.to_upper()+" / OBSERVING REAL CONTACTS"
	elif result>=0:status.text = kind.to_upper()+" / Z = "+str(result)+" / RESET FOR A FRESH TAKE"
	else:status.text = "PART PLACED / DROP THE MOVER OR PRESS RELEASE"

func box_mesh(host: Node3D,at: Vector3,size: Vector3,look: String) -> void:
	var mesh := MeshInstance3D.new();mesh.mesh = BoxMesh.new()
	if mesh.mesh is BoxMesh:mesh.mesh.size = size
	mesh.position = at;mesh.material_override = mat(look);host.add_child(mesh)
func draw_tyre(body: Node3D) -> void:
	var mesh := MeshInstance3D.new();mesh.mesh = TorusMesh.new();mesh.mesh.inner_radius = .2;mesh.mesh.outer_radius = .4;mesh.rotation.x = PI/2;mesh.material_override = mat("tyre");body.add_child(mesh)
	for i in range(44):
		var angle := TAU*i/44;var tread := MeshInstance3D.new();tread.mesh = BoxMesh.new();tread.mesh.size = Vector3(.055,.03,.17);tread.position = Vector3(cos(angle)*.392,sin(angle)*.392,0);tread.rotation.z = angle;tread.material_override = mat("tyre");body.add_child(tread)
func draw_skittle(body: Node3D) -> void:
	var profile := [[.045,0],[.058,.05],[.062,.2],[.052,.32],[.033,.42],[.03,.47],[.042,.54],[.04,.6],[.022,.635],[0,.64]]
	var st := SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in range(profile.size()-1):
		for i in range(32):
			var points: Array[Vector3] = []
			for ij in [[i,j],[i+1,j],[i+1,j+1],[i,j+1]]:
				var p: Array = profile[ij[1]];var a: float = TAU*ij[0]/32;points.append(Vector3(cos(a)*p[0],p[1]-.32,sin(a)*p[0]))
			for k in [0,2,1,0,3,2]:st.add_vertex(points[k])
	st.generate_normals();var mesh := MeshInstance3D.new();mesh.mesh = st.commit();mesh.material_override = mat("skittle");body.add_child(mesh)
	for y in [.105,.135]:
		var stripe := MeshInstance3D.new();stripe.mesh = CylinderMesh.new();stripe.mesh.top_radius = .0335;stripe.mesh.bottom_radius = .0335;stripe.mesh.height = .018;stripe.position.y = y;stripe.material_override = mat("red");body.add_child(stripe)

func remember(node: Node3D,label: String) -> void:
	var bound := AABB();var first := true
	for c in node.get_children():
		if c is MeshInstance3D:
			var box: AABB = c.transform*c.mesh.get_aabb();bound = box if first else bound.merge(box);first = false
		elif c is Label3D and not c.text.is_empty():
			var lines: PackedStringArray = c.text.split("\n");var length := 1
			for line in lines:length = maxi(length,line.length())
			var size := Vector3(length*c.font_size*c.pixel_size*.55,lines.size()*c.font_size*c.pixel_size,.01);var box: AABB = c.transform*AABB(-size*.5,size);bound = box if first else bound.merge(box);first = false
	if first:return
	part_defaults[str(node.name)] = {"label":label,"position":arr(node.position),"rotation":arr(node.rotation_degrees),"bounds":[bound.position.x,bound.position.y,bound.position.z,bound.size.x,bound.size.y,bound.size.z]}
func apply_poses(config: Dictionary) -> void:
	for id in config.get("parts",{}):
		var node := get_node_or_null(NodePath(id)) as Node3D
		if node==null:continue
		var pose: Dictionary = config.parts[id]
		node.position = v(pose.get("position",arr(node.position)));node.rotation_degrees = v(pose.get("rotation",arr(node.rotation_degrees)))
		if node is PhysicsBody3D:PhysicsServer3D.body_set_state(node.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,node.global_transform)
		if bodies.has(id):homes[id] = node.transform

func build_dressing() -> void:
	for held in graph.held:
		var rec: Dictionary = records[held.body];var body: Node3D = bodies[held.body]
		var top: float = body.position.y+float(rec.shapes[0].size[1])/2
		var rope_top: float = 1.95 if kind=="xor" else maxf(2.05,top+.42)
		var frame := Node3D.new();frame.name = "Frame_"+held.input;add_child(frame)
		if kind!="xor":
			box_mesh(frame,Vector3(body.position.x,(rope_top+.04)/2,-.62),Vector3(.08,rope_top+.04,.08),"post")
			box_mesh(frame,Vector3(body.position.x,rope_top,(body.position.z-.62)/2),Vector3(.08,.08,absf(body.position.z+.62)+.08),"post")
		var rope := MeshInstance3D.new();rope.name = "Rope";rope.mesh = CylinderMesh.new();rope.mesh.top_radius = .012;rope.mesh.bottom_radius = .012;rope.mesh.height = rope_top-top;rope.position = Vector3(body.position.x,(top+rope_top)/2,body.position.z);rope.material_override = mat("rope");frame.add_child(rope);ropes[held.input] = rope
		remember(frame,"Original suspension frame / "+held.input)
	if kind=="xor":
		var frame := Node3D.new();frame.name = "BalanceFrame";add_child(frame)
		for x in [-1.95,1.95]:box_mesh(frame,Vector3(x,1,.33),Vector3(.08,2,.08),"post")
		box_mesh(frame,Vector3(0,1.99,.33),Vector3(4.02,.08,.08),"post")
		for s in [-1,1]:
			for t in [-1,1]:
				box_mesh(frame,Vector3(s*.22,.47,t*.24),Vector3(.07,1,.07),"post");frame.get_child(-1).rotation.z = -s*.24
		remember(frame,"Original balance suspension frame and trestle")
	if kind=="nand":
		var frame := Node3D.new();frame.name = "SeesawFrame";add_child(frame)
		for z in [-.42,.42]:box_mesh(frame,Vector3(.9,.88,z),Vector3(.08,1.76,.08),"post")
		var axle := MeshInstance3D.new();axle.mesh = CylinderMesh.new();axle.mesh.top_radius = .03;axle.mesh.bottom_radius = .03;axle.mesh.height = .9;axle.position = Vector3(.9,1.7,0);axle.rotation.x = PI/2;axle.material_override = mat("iron");frame.add_child(axle)
		for xy in [[.48,1.36],[1.52,1.22]]:
			box_mesh(frame,Vector3(xy[0],xy[1]/2,-.42),Vector3(.08,xy[1],.08),"post");box_mesh(frame,Vector3(xy[0],xy[1],-.21),Vector3(.06,.06,.42),"post")
		remember(frame,"Original seesaw axle and stop supports")
	if kind=="or":
		for name in graph.inputs:
			var body: Node3D = bodies[graph.inputs[name].body];var r := .4 if name=="X" else .17;var a := atan2(.95,2.8)
			var chock := Node3D.new();chock.name = "Chock_"+name;add_child(chock)
			chock.position = body.position+Vector3(cos(a)*(r+.06)-sin(a)*(r-.05),-sin(a)*(r+.06)-cos(a)*(r-.05),0);chock.rotation.z = -a
			box_mesh(chock,Vector3.ZERO,Vector3(.1,.1,.3),"post");chocks[name] = chock;remember(chock,"Original removable chock / "+name)

func build_controls() -> void:
	var host := Node3D.new();host.name = "Controls";host.position = Vector3(float(graph.frame.x),.8,1.75);add_child(host)
	box_mesh(host,Vector3(0,-.4,0),Vector3(1.1,.8,.18),"dark")
	for i in range(4):
		var id: String = ["X","Y","RELEASE","RESET"][i];var button := ButtonScene.instantiate();button.name = id;button.label = id;button.position = Vector3((i-1.5)*.25,.08,.14);button.cube_size = .055;button.cap_color = Color("e45391");host.add_child(button);buttons[id] = button
		button.pressed.connect(toggle_input.bind(id) if i<2 else release_take if i==2 else reset_take)
	status = Label3D.new();status.position = Vector3(0,.32,.14);status.font_size = 28;status.pixel_size = .0009;host.add_child(status)
	button_visibility("X",graph.inputs.has("X"));button_visibility("Y",graph.inputs.has("Y"))
	finish_control_labels(host);remember(host,"Source release controls / inputs choose what is released")

func button_visibility(id: String,shown: bool) -> void:
	if not buttons.has(id):return
	buttons[id].visible = shown
	for collider in buttons[id].find_children("*","CollisionObject3D",true,false):
		if not collider.has_meta("reference_button_collision"):collider.set_meta("reference_button_collision",[collider.collision_layer,collider.collision_mask])
		var original: Array = collider.get_meta("reference_button_collision");collider.collision_layer = int(original[0]) if shown else 0;collider.collision_mask = int(original[1]) if shown else 0

func finish_control_labels(host: Node3D) -> void:
	# These labels sit above the light button plates, against the dark console.
	# Keep local changes here rather than recolouring every button in the game.
	for label in host.find_children("*","Label3D",true,false):
		label.modulate = Color("fff3e1");label.outline_modulate = Color("211c28");label.outline_size = 6;label.font_size = 24;label.pixel_size = .0015

func button_text(id: String,text: String) -> void:
	if not buttons.has(id):return
	buttons[id].label = text
	for child in buttons[id].get_children():
		if child is Label3D:child.text = text
func toggle_input(id: String) -> void:
	if running or result>=0:status.text = "RESET BEFORE CHANGING THE TAKE";return
	if not graph.inputs.has(id):return
	inputs[id] = not inputs[id];update_inputs()
func update_inputs() -> void:
	for id in ["X","Y"]:
		buttons[id].label = id+" "+("1" if inputs[id] else "0")
		for child in buttons[id].get_children():
			if child is Label3D:child.text = buttons[id].label
		buttons[id].get_node("PushButton").set_selected(inputs[id])
		var placed: bool = graph.inputs.has(id) and hand_placed.has(graph.inputs[id].body)
		if chocks.has(id):chocks[id].visible = (not inputs[id] if running else true) and not placed
		if ropes.has(id):ropes[id].visible = not ((running and inputs[id]) or placed)
	status.text = kind.to_upper()+" / CHOOSE RELEASES, THEN RELEASE"
func reset_take() -> void:
	resetting_take = true
	# Release through XR Tools before restoring homes, otherwise the grab driver
	# would pull a reset part back to the hand on the next frame.
	for body in bodies.values():
		if hand_holds(body):release_hand_hold(body)
	hand_placed.clear()
	running = false;elapsed = 0;quiet = 0;first_z = -1;result = -1;hit_log.clear()
	for joint in joints:
		if is_instance_valid(joint):joint.queue_free()
	for plane in plane_joints.values():
		if is_instance_valid(plane.anchor):plane.anchor.queue_free()
	joints.clear();plane_joints.clear()
	for id in bodies:
		var body: Node3D = bodies[id]
		if body is RigidBody3D:body.freeze = true;body.linear_velocity = Vector3.ZERO;body.angular_velocity = Vector3.ZERO
		body.transform = homes.get(id,body.transform);PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,body.global_transform)
	update_inputs();resetting_take = false
func release_take() -> void:
	if running or result>=0:return
	running = true;update_inputs();status.text = "OBSERVING REAL CONTACTS"
	for id in bodies:
		var body: Node3D = bodies[id]
		if not body is RigidBody3D:continue
		if hand_holds(body):continue
		var held := false
		for input in graph.inputs:
			if graph.inputs[input].body==id and not inputs[input]:held = true
		body.freeze = held;body.sleeping = false
	for h in graph.hinges:
		var joint: Joint3D = PinJoint3D.new() if h.get("type","hinge")=="pin" else HingeJoint3D.new();joint.name = "SourceJoint";joint.position = bodies[h.a].position+bodies[h.a].basis*v(h.pivot_a);joint.quaternion = Quaternion(Vector3(0,0,1),v(h.get("axis_a",[0,0,1])));add_child(joint);joint.node_a = joint.get_path_to(bodies[h.a]);joint.node_b = joint.get_path_to(bodies[h.b]);joint.exclude_nodes_from_collision = true;joints.append(joint)
	for id in graph.planar:
		if bodies[id].freeze or hand_holds(bodies[id]):continue
		install_plane(id)
func install_plane(id: String) -> void:
	# A native joint provides the source's planar guide, without rewriting motion.
	var anchor := StaticBody3D.new();anchor.name = "PlaneAnchor";anchor.position = bodies[id].position;add_child(anchor)
	var joint := Generic6DOFJoint3D.new();joint.position = anchor.position;add_child(joint)
	joint.node_a = joint.get_path_to(anchor);joint.node_b = joint.get_path_to(bodies[id]);joint.exclude_nodes_from_collision = true
	for axis in ["x","y","z"]:
		joint.call("set_flag_"+axis,Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT,axis=="z")
		joint.call("set_flag_"+axis,Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT,axis!="z")
		joint.call("set_param_"+axis,Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT,0.0);joint.call("set_param_"+axis,Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT,0.0)
		joint.call("set_param_"+axis,Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT,0.0);joint.call("set_param_"+axis,Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT,0.0)
	joints.append(joint);plane_joints[id] = {"joint":joint,"anchor":anchor}
func release_plane(id: String) -> void:
	if plane_joints.has(id):plane_joints[id].joint.queue_free();plane_joints[id].anchor.queue_free();plane_joints.erase(id)
func contact(other: Node3D,id: String) -> void:
	if not running:return
	var other_id := str(other.name);hit_log.append({"at":elapsed,"a":id,"b":other_id})
	if records.has(other_id) and not records[other_id].role in ["ramp","floor"]:release_plane(id)
func output_bit() -> int:
	var body: Node3D = bodies[graph.output]
	if kind=="xor":
		var at := to_local(body.global_position);return int(absf(at.x)>1.62 or at.y<.70)
	var upright := clampf(body.global_basis.y.dot(global_basis.y),-1,1)
	return int(acos(upright)>deg_to_rad(30))
func _physics_process(delta: float) -> void:
	if not running:return
	for body in bodies.values():
		if hand_holds(body):
			quiet = 0;status.text = "HAND PLACEMENT / LET GO TO CONTINUE THE TAKE";return
	elapsed += delta
	if output_bit()==1 and first_z<0:first_z = elapsed
	var moving := false
	for body in bodies.values():
		if body is RigidBody3D and not body.freeze and (body.linear_velocity.length()>.05 or body.angular_velocity.length()>.15):moving = true
	quiet = 0 if moving else quiet+delta
	if (first_z>=0 and elapsed>first_z+2.5) or (elapsed>3 and quiet>1) or elapsed>16:
		result = output_bit();running = false;status.text = kind.to_upper()+" / Z = "+str(result)+" / ACTUAL BODY STATE"
