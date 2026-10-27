extends "res://commons/artifacts/matter_experiments/friction_studies.gd"
## Two planks, two chocks, one cube and one ball. All six remain loose in 3D.
## No joints, pose snapping, balancing forces, success state or timed collapse.
const Piece = preload("res://commons/artifacts/matter_experiments/leaning_piece.gd")
const PLANK := Vector3(1.25,.07,.26)
var hand_free_seconds := 0.0
var readout_clock := 0.0
var brittle := true
var balance_offset := -.02

func apply_grid_config(config: Dictionary) -> void:
	brittle = bool(config.get("brittle",true));balance_offset = clampf(float(config.get("balance_offset",-.02)),-.025,.025);super.apply_grid_config(config)

func loose(id: String,at: Vector3,mass: float,mu: float) -> XRToolsPickable:
	var body := Piece.new();body.name = id;body.position = at;body.mass = mass
	var contact := PhysicsMaterial.new();contact.friction = mu;contact.bounce = .015;body.physics_material_override = contact
	add_child(body);bodies[id] = body;return body

func box_shape(body: Node3D,size: Vector3) -> void:
	var shape := CollisionShape3D.new();shape.shape = BoxShape3D.new();shape.shape.size = size;shape.shape.margin = .001;body.add_child(shape)

func timber(body: Node3D,size: Vector3) -> void:
	var skin := MeshInstance3D.new();skin.mesh = Timber.mesh(size);skin.material_override = Timber.material();body.add_child(skin)

func plank(id: String,at: Vector3,angle: float) -> void:
	var body := loose(id,at,.8,.15 if brittle else .65);body.basis = Basis(Vector3.BACK,angle)*Basis(Vector3.RIGHT,PI/2 if brittle else 0.0);box_shape(body,PLANK);timber(body,PLANK)
	# A small pink end-grain mark distinguishes the two movable members.
	box_mesh(body,Vector3(-PLANK.x*.5-.001,0,0),Vector3(.004,PLANK.y*.7,PLANK.z*.7),"handle")
	remember(body,id+" / loose timber plank, 1.25 m")

func wedge(id: String,at: Vector3,mirror: bool) -> void:
	var body := loose(id,at,1.6,.85)
	if mirror:body.rotation.y = PI
	var points := PackedVector3Array([Vector3(-.2,0,-.2),Vector3(.2,0,-.2),Vector3(-.2,.18,-.2),Vector3(-.2,0,.2),Vector3(.2,0,.2),Vector3(-.2,.18,.2)])
	var shape := CollisionShape3D.new();shape.shape = ConvexPolygonShape3D.new();shape.shape.points = points;shape.shape.margin = .001;body.add_child(shape)
	var faces := [[0,2,1],[3,4,5],[0,1,4,3],[0,3,5,2],[1,2,5,4]];var surface := SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face in faces:
		for i in range(1,face.size()-1):
			for k in [face[0],face[i],face[i+1]]:
				var p: Vector3 = points[k];surface.set_uv(Vector2(p.x,p.z)*2);surface.add_vertex(p)
	surface.generate_normals();surface.generate_tangents();var skin := MeshInstance3D.new();skin.mesh = surface.commit();skin.material_override = Timber.material();body.add_child(skin)
	box_mesh(body,Vector3(-.203,.09,0),Vector3(.004,.055,.15),"handle")
	remember(body,id+" / loose wooden chock")

func _ready() -> void:
	graph = {"inputs":{},"hinges":[],"planar":[]}
	var board := fixed("Board",Vector3(0,.57,0),Vector3(2.8,.06,1.5),"plywood",.22)
	if brittle:
		# A physical retaining lip keeps the loose test ball nearby; no pose reset.
		for x in [-1.385,1.385]:
			var rim := CollisionShape3D.new();rim.shape = BoxShape3D.new();rim.shape.size = Vector3(.03,.06,1.5);rim.position = Vector3(x,.06,0);board.add_child(rim);box_mesh(board,rim.position,rim.shape.size,"crate")
		for z in [-.735,.735]:
			var rim := CollisionShape3D.new();rim.shape = BoxShape3D.new();rim.shape.size = Vector3(2.8,.06,.03);rim.position = Vector3(0,.06,z);board.add_child(rim);box_mesh(board,rim.position,rim.shape.size,"crate")
		remember(board,"Board / low physical retaining lip")
	for x in [-.96,.96]:fixed("Plinth"+str(int(x*100)),Vector3(x,.27,0),Vector3(.46,.54,1.08),"crate",.8)
	var angle := deg_to_rad(55);var section := PLANK.z if brittle else PLANK.y;var dx := PLANK.x*.5*cos(angle)+section*.5*sin(angle);var y := .60+section*.5*cos(angle)+PLANK.x*.5*sin(angle)+.002
	plank("LeftPlank",Vector3(-dx,y,-.12),angle);plank("RightPlank",Vector3(dx,y,-.12),PI-angle)
	var foot := PLANK.x*cos(angle)+section*sin(angle)
	var chock_z := -.12-(.2+PLANK.y*.5-.008) if brittle else -.12
	wedge("LeftWedge",Vector3(-foot-.202,.602,chock_z),true);wedge("RightWedge",Vector3(foot+.202,.602,chock_z),false)
	var cube_at := Vector3(0,.742,.48)
	if brittle:
		var peak := y+PLANK.x*.5*sin(angle)
		cube_at = Vector3(0,peak+cos(angle)/sin(angle)*(.14-section*.5*sin(angle))+.141,-.12+balance_offset)
	var load_cube := loose("Cube",cube_at,.5,.15 if brittle else .6);box_shape(load_cube,Vector3.ONE*.28);box_mesh(load_cube,Vector3.ZERO,Vector3.ONE*.28,"ivory")
	for axis in 3:
		for s in [-1,1]:
			for t in [-1,1]:
				var p := Vector3.ZERO;var edge := Vector3.ONE*.005;p[(axis+1)%3] = s*.141;p[(axis+2)%3] = t*.141;edge[axis] = .285;box_mesh(load_cube,p,edge,"steel")
	remember(load_cube,"Cube / loose half-kilogram load")
	var ball_at := Vector3(-.45,.711,.36) if brittle else Vector3(-.7,.713,.48)
	var ball := loose("Ball",ball_at,.18,.45);ball.linear_damp = .8;ball.angular_damp = .8;ball.can_sleep = true;var shape := CollisionShape3D.new();shape.shape = SphereShape3D.new();shape.shape.radius = .11;ball.add_child(shape)
	var skin := MeshInstance3D.new();skin.mesh = SphereMesh.new();skin.mesh.radius = .11;skin.mesh.height = .22;skin.material_override = mat("ivory");ball.add_child(skin);remember(ball,"Ball / loose 180 g load")
	build_lean_controls();apply_poses(pending)
	for id in bodies:homes[id] = bodies[id].transform
	reset_take()
	set_meta("void_preview_kind","Six loose, grabbable Jolt bodies, no joints or pose correction. Held bodies retain contact with these parts through the native held-object layer. Editor preview is the authored starting arrangement. Runtime rearrangements are temporary; save reusable authoring arrangements in the lab editor.")

func build_lean_controls() -> void:
	var host := Node3D.new();host.name = "Controls";host.position = Vector3(0,.64,.77);add_child(host)
	box_mesh(host,Vector3(0,0,0),Vector3(2.0,.18,.07),"steel")
	var button := ButtonScene.instantiate();button.name = "RESET";button.label = "RESET";button.position = Vector3(.84,.04,.06);button.cube_size = .055;button.cap_color = Color("ee478f");host.add_child(button);button.pressed.connect(reset_take);buttons.RESET = button
	label(host,"LEANING TOGETHER / A BRITTLE BALANCE" if brittle else "LEANING TOGETHER / WHAT HOLDS WHAT?",Vector3(-.1,.025,.04),22)
	status = label(host,"",Vector3(-.18,-.035,.04),17)
	label(host,"LMB: light tap · RMB: hold / release · wheel: reach\nQ/E: roll · Z/X: tilt · Shift+Q/E: yaw\nVR: touch, grip and turn with either hand",Vector3(-.08,-.18,.04),14)
	finish_control_labels(host);remember(host,"Reset and hand-placement instructions")

func reset_take() -> void:
	resetting_take = true
	for body in bodies.values():
		if hand_holds(body):release_hand_hold(body)
	for id in bodies:
		var body: RigidBody3D = bodies[id];body.freeze = true;body.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC;body.transform = homes[id];body.linear_velocity = Vector3.ZERO;body.angular_velocity = Vector3.ZERO;PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,body.global_transform);body.freeze = false
	hand_free_seconds = 0;resetting_take = false;update_lean_readout()

func observations() -> Dictionary:
	var held: Array[String] = [];var contacts: Array[String] = [];var angles := {}
	for id in bodies:
		var body: XRToolsPickable = bodies[id]
		if hand_holds(body):held.append(id)
		for other in body.get_colliding_bodies():
			if bodies.values().has(other):
				var pair: Array[String] = [id,str(other.name)];pair.sort();var key := " + ".join(pair)
				if key not in contacts:contacts.append(key)
	for id in ["LeftPlank","RightPlank"]:angles[id] = rad_to_deg(asin(clampf(absf(bodies[id].global_basis.x.normalized().dot(global_basis.y.normalized())),0,1)))
	return {"held":held,"contacts":contacts,"angles":angles,"hand_free_seconds":hand_free_seconds}

func update_lean_readout() -> void:
	if not is_instance_valid(status):return
	var state := observations();status.text = "HOLDING "+", ".join(state.held) if not state.held.is_empty() else "WITHOUT HANDS %.1f s / PLANKS %.0f° · %.0f°"%[hand_free_seconds,state.angles.LeftPlank,state.angles.RightPlank]

func _physics_process(dt: float) -> void:
	var held := false
	for body in bodies.values():held = held or hand_holds(body)
	hand_free_seconds = 0.0 if held else hand_free_seconds+dt
	readout_clock += dt
	if readout_clock>.2:readout_clock = 0;update_lean_readout()

func prepare_editor_preview() -> void:
	reset_take()
	for body in bodies.values():body.freeze = true
	set_physics_process(false)
