extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## A trial court in the existing museum. Forces accumulate; ordinary misses stay.
const POINT = preload("res://commons/artifacts/force_capability_lab/force_point.gd")
const BODY = preload("res://commons/artifacts/force_capability_lab/loose_point.gd")
const CUBE = preload("res://commons/interactables/grab_cube.gd")
const PAD = preload("res://commons/artifacts/force_capability_lab/capability_pad.gd")
const MORTAR = preload("res://commons/artifacts/force_capability_lab/ring_mortar.gd")
const PLATFORM = preload("res://commons/scenes/mapobjects/transport_cube.tscn")
const ADAPTER = preload("res://commons/artifacts/force_field_zone/field_carry_provider.gd")
const VISOR = preload("res://commons/artifacts/force_capability_lab/body_visor.gd")
var visor: Node3D
var visor_status: Label3D
var _last_launch: Dictionary = {}
var points: Array = []
var loose: Array[RigidBody3D] = []
var homes: Dictionary = {}
var springs: Array[RigidBody3D] = []
var spring_homes: Array[Vector3] = []
var spring_lines: MeshInstance3D
var pole: RigidBody3D
var pole_home: Transform3D
var hinge: HingeJoint3D
var mortar: Node3D
var pad: Node3D
var platform: Node3D
var goal: Area3D
var cargo: RigidBody3D
var drag_coefficient := 3.0 # N per (m/s): linear drag on loose bodies in the marked lane
var status: Label3D
var _carry: Dictionary = {}
var _launch: Dictionary = {}
var _reset_pending := false
var recovered := 0
var desktop_pointers: Array[Node] = []

func _ready() -> void:
	add_to_group("ada_museum_carry")
	add_to_group("force_capability_court")
	set_meta("em_keep_scale",true)
	var pale := material("e5e2d9"); var ink := material("25272a")
	# Narrow marks connect stations without making an obstacle course of the floor.
	for z in range(-10,11,2): box(Vector3(0,0.012,z),Vector3(0.04,0.012,0.55),ink)
	plaque("THE POINT GAINS POWER",Vector3(-3.6,2.5,-9.4),3.9)
	plaque("Aim down / back. Hold the trigger.\nRelease: thrust stops; motion remains.",Vector3(-3.6,1.7,-9.4),3.9,0.0012)
	for i in range(2):
		var at := Vector3(-4.2+i*0.8,1.1,-9)
		box(at-Vector3(0,0.55,0),Vector3(0.48,1.1,0.48),pale,true)
		var point = POINT.new(); point.name = "ThrustPoint%d" % i
		point.position = at+Vector3.UP*0.15; add_child(point); points.append(point); remember(point)
	button("RESET",Vector3(-2.1,0,-9),"RESET TRIAL")
	status = plaque("Misses stay. Reset when you choose.",Vector3(-3.6,0.45,-10),3.9,0.00105)
	build_visor_station(pale,ink)
	mortar = MORTAR.new(); mortar.name = "DonutCakeMortar"
	mortar.position = Vector3(4,0,-9); add_child(mortar)
	for z in [-3.7,-2.2]:
		box(Vector3(4,0.06,z),Vector3(1.7,0.12,1.1),pale,true)
		box(Vector3(4,0.57,z),Vector3(0.10,1.02,0.10),ink,true)
	plaque("Land a ring. Keep a miss.",Vector3(4,1.9,-3.2),3.0,0.00125)
	pad = PAD.new(); pad.name = "LaunchPad"; pad.court = self
	pad.position = Vector3(0,0,-4); pad.up_force = 6.0; pad.forward_force = 4.0
	pad.foresight = "parabola"; pad.vectors = "sum"; add_child(pad)
	plaque("LAUNCH / LAND\nSame launch; a moving destination.",Vector3(0,2.0,-4.8),3.1,0.00125)
	platform = PLATFORM.instantiate(); platform.name = "MovingPlatform"
	platform.position = Vector3(-1.5,0.5,0.3)
	platform.auto_start = true; platform.move_distance = 3.0; platform.move_speed = 0.65
	platform.return_delay = 0.4; platform.rotation_speed = 0.0; platform.bob_height = 0.0
	add_child(platform)
	platform.cube_mesh.material_override = pale
	build_hinge(pale,ink)
	build_springs(ink)
	# The familiar slope and cubes: no prescribed solution connects them to the goal.
	var slope := Node3D.new(); slope.name = "Slope"; slope.position = Vector3(-3.8,0.5,5.0)
	slope.rotation.x = deg_to_rad(18); add_child(slope)
	box(Vector3.ZERO,Vector3(1.8,0.12,3.0),pale,true,slope)
	for i in range(5):
		var cube = CUBE.new(); cube.name = "LooseCube%d" % i
		cube.cube_size = 0.48; cube.cube_color = Color("dedbd4") if i%2==0 else Color("28292b")
		cube.mass = 1.5; cube.collision_layer = 4; cube.collision_mask = 524293
		cube.position = Vector3(-5.0+(i%3)*0.65,0.4,8.0+(i/3)*0.65)
		add_child(cube); remember(cube)
	box(Vector3(-3.7,0.012,8.5),Vector3(3.5,0.015,4.0),material("8f7085"))
	button("DRAG",Vector3(-5.2,0,6.2),"DRAG  0 / 3")
	button("PUSH",Vector3(-3.9,0,6.2),"PUSH CUBES")
	plaque("DRAG\nWhat do you bring with you?",Vector3(-3.7,2.2,8.9),3.7,0.0014)
	box(Vector3(2.7,0.45,10.1),Vector3(1.1,0.9,1.1),pale,true)
	cargo = BODY.new(); cargo.name = "CarriedPoint"; cargo.release_mode = XRToolsPickable.ReleaseMode.UNFROZEN
	cargo.position = Vector3(-2.7,0.95,-7.5); cargo.mass = 0.8
	var black := material("111216"); black.roughness = 0.1; black.metallic = 0.3
	cargo.get_child(0).material_override = black
	box(Vector3(-2.7,0.4,-7.5),Vector3(0.7,0.8,0.7),pale,true)
	plaque("BRING THIS POINT THROUGH THE ROOM",Vector3(-2.7,0.45,-7.9),2.3,0.0008)
	add_child(cargo); remember(cargo)
	goal = Area3D.new(); goal.name = "Destination"; goal.position = Vector3(2.7,1.15,10.1)
	goal.collision_layer = 0; goal.collision_mask = 4
	var cs := CollisionShape3D.new(); var bs := BoxShape3D.new(); bs.size = Vector3(1.05,0.5,1.05)
	cs.shape = bs; goal.add_child(cs); add_child(goal)
	goal.body_entered.connect(func(body):
		if body == cargo: status.text = "The point reached the plinth.\nWhat else moved on the way?")
	plaque("THE POINT ARRIVES\nWhat else moved on the way?",Vector3(2.7,2.0,10.7),3.5,0.0015)
	get_tree().node_added.connect(_node_added)
	install_adapter.call_deferred()

func build_visor_station(pale: Material, ink: Material) -> void:
	visor=VISOR.new();visor.name="BodyVisor";visor.court=self;add_child(visor)
	box(Vector3(1.8,0.55,-10.8),Vector3(1.05,1.1,0.55),pale,true)
	# An open visor on its dock identifies the wearable without blocking the view.
	for x in [-0.28,0.28]:box(Vector3(1.8+x,1.42,-10.8),Vector3(0.025,0.045,0.32),ink)
	box(Vector3(1.8,1.42,-10.96),Vector3(0.58,0.045,0.025),ink)
	box(Vector3(1.8,1.38,-10.96),Vector3(0.44,0.05,0.015),material("be7b99"))
	button("VISOR",Vector3(1.8,0,-11.55),"WEAR / REMOVE")
	buttons.VISOR.rotation.x=-PI/2.0
	buttons.VISOR.position.z-=0.23
	visor_status=plaque("YOUR BODY IS THE POINT\nWear the vector visor. Desktop: F8",Vector3(1.8,2,-10.8),3.0,0.00105)
	plaque("Velocity: m/s. Thrust / mass: m/s².\nLooking, moving and pushing can differ.",Vector3(1.8,2.65,-10.8),3.2,0.0009)

func visitor() -> CharacterBody3D:
	var navigator=get_tree().get_first_node_in_group("museum_portal_navigation")
	if navigator!=null:
		var museum=navigator.museum
		if bool(museum.get("_vr")):
			var rig= museum.call("_vr_rig")
			if rig!=null:return rig.find_child("PlayerBody",true,false) as CharacterBody3D
		return museum.get("_player") as CharacterBody3D
	return null

func wear_visor(receiver: CharacterBody3D) -> bool:
	if receiver==null or not _point_inside(receiver.global_position):return false
	var eye: Camera3D
	if receiver is XRToolsPlayerBody:eye=receiver.camera_node
	else:
		var cameras=receiver.find_children("*","Camera3D",true,false)
		if not cameras.is_empty():eye=cameras[0] as Camera3D
	if eye==null:
		var navigator=get_tree().get_first_node_in_group("museum_portal_navigation")
		if navigator!=null and navigator.museum.get("_player")==receiver:eye=navigator.museum.get("_cam")
	if eye==null:return false
	visor.attach(receiver,eye);visor.set_worn(not visor.worn)
	buttons.VISOR.set_selected(visor.worn)
	visor_status.text="VISOR ON / YOUR BODY IS THE POINT" if visor.worn else "VISOR OFF / LOOK AT THE ROOM"
	return true

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F8:
		if wear_visor(visitor()):get_viewport().set_input_as_handled()

func thrust_acceleration(receiver: CharacterBody3D) -> Vector3:
	var thrust:=Vector3.ZERO
	for point in points:
		if point.receiver()==receiver:thrust+=point.acceleration()
	return thrust

func body_reading(receiver: CharacterBody3D) -> Dictionary:
	return {"velocity":receiver.velocity,"thrust":thrust_acceleration(receiver),"gravity":Vector3.DOWN*9.8,
		"launch_recent":Time.get_ticks_msec()-int(_last_launch.get(receiver.get_instance_id(),-10000))<1000}

func plaque(words: String, at: Vector3, width: float, pixels: float = 0.00165) -> Label3D:
	box(at+Vector3(0,0,0.025),Vector3(width,0.48,0.035),material("dedbd4"))
	var text := label(words,at,pixels); text.font_size = 108; text.rotation.y = PI; text.modulate = Color("24262a")
	return text

func button(id: String, at: Vector3, words: String) -> void:
	box(at+Vector3.UP*0.45,Vector3(0.40,0.9,0.40),material("dfddd6"),true)
	var b = PUSH.instantiate(); b.position = at+Vector3.UP*0.92; b.scale = Vector3.ONE*1.6
	add_child(b); buttons[id] = b; b.pressed.connect(act.bind(id))
	var text := label(words,at+Vector3(0,1.16,0),0.00085); text.font_size = 90; text.rotation.y = PI; text.modulate = Color("24252a")

func remember(body: RigidBody3D) -> void:
	loose.append(body); homes[body] = body.transform

func build_hinge(pale: Material, ink: Material) -> void:
	var anchor := StaticBody3D.new(); anchor.name = "HingeAnchor"; anchor.position = Vector3(-4,0.38,-0.4); add_child(anchor)
	box(Vector3.ZERO,Vector3(1.25,0.25,0.55),pale,false,anchor)
	var foot := CollisionShape3D.new(); var foot_shape := BoxShape3D.new(); foot_shape.size = Vector3(1.25,0.25,0.55)
	foot.shape = foot_shape; anchor.add_child(foot)
	pole = RigidBody3D.new(); pole.name = "FallingPole"; pole.mass = 6.0
	pole.position = Vector3(-4,2.36,-0.25); pole.rotation.x = deg_to_rad(4)
	pole.freeze = true; pole.collision_layer = 4; pole.collision_mask = 524293
	var mesh := MeshInstance3D.new(); var shape := BoxMesh.new(); shape.size = Vector3(0.85,4.0,0.18)
	mesh.mesh = shape; mesh.material_override = ink; pole.add_child(mesh)
	var col := CollisionShape3D.new(); var bound := BoxShape3D.new(); bound.size = shape.size; col.shape = bound; pole.add_child(col)
	add_child(pole); pole_home = pole.transform
	hinge = HingeJoint3D.new(); hinge.name = "RealHinge"; hinge.position = anchor.position
	hinge.rotation.y = PI/2.0; add_child(hinge)
	hinge.node_a = hinge.get_path_to(anchor); hinge.node_b = hinge.get_path_to(pole)
	hinge.exclude_nodes_from_collision = true
	box(Vector3(-4,0.12,3.35),Vector3(1.25,0.24,0.5),pale,true)
	button("HINGE",Vector3(-5.3,0,-1.7),"RELEASE POLE")
	plaque("ONE FREE AXIS\nA falling pole can become a bridge.",Vector3(-4,4.65,0),3.6,0.00135)

func build_springs(ink: Material) -> void:
	for i in range(2):
		var b = BODY.new(); b.name = "SpringPoint%d" % i; b.freeze = false; b.mass = 0.7
		b.release_mode = XRToolsPickable.ReleaseMode.UNFROZEN
		b.position = Vector3(3.6+i*0.38,1.0,3.3)
		b.axis_lock_linear_y = true; b.axis_lock_linear_z = true
		b.collision_mask = 524293; b.linear_damp = 0.0
		b.get_child(0).material_override = ink; add_child(b)
		springs.append(b); spring_homes.append(b.position); remember(b)
	box(Vector3(3.8,0.73,3.3),Vector3(3.6,0.08,0.65),material("dedbd4"),true)
	for x in [2.1,5.5]: box(Vector3(x,0.6,3.3),Vector3(0.12,1.2,0.65),ink,true)
	spring_lines = MeshInstance3D.new(); spring_lines.material_override = material("cb83a4"); add_child(spring_lines)
	button("SPRING",Vector3(4,0,1.8),"GIVE ONE A PUSH")
	plaque("SPRINGS / CONTACT\nA push travels into another body.",Vector3(4,2.2,3.65),3.6,0.0013)

func act(id: String) -> void:
	match id:
		"VISOR": wear_visor(visitor())
		"RESET": _reset_pending = true
		"HINGE": pole.freeze = false; pole.sleeping = false
		"SPRING": springs[0].apply_central_impulse(global_basis.x * 0.7)
		"DRAG":
			drag_coefficient = 0.0 if drag_coefficient > 0.0 else 3.0
			status.text = "Drag = %.0f N per (m/s).\nSame push; a different distance." % drag_coefficient
		"PUSH":
			for b in loose:
				if str(b.name).begins_with("LooseCube") and not is_held(b): b.apply_central_impulse(global_basis.z * 3.0)

func is_held(body: RigidBody3D) -> bool:
	if body is XRToolsPickable and body.is_picked_up(): return true
	if body.has_method("held") and body.held(): return true
	# The desktop pointer freezes a body without using the XR grab driver.
	for p in desktop_pointers:
		if is_instance_valid(p) and p.get("_held") == body: return true
	return body.has_meta("capability_desktop_held")

func _physics_process(delta: float) -> void:
	if _reset_pending:
		_reset_pending = false
		reset_trial()
	for i in range(springs.size()):
		var b := springs[i]
		if not is_held(b):
			var offset: float = to_local(b.global_position).x - spring_homes[i].x
			var speed: float = b.linear_velocity.dot(global_basis.x)
			b.apply_central_force(global_basis.x * (-9.0*offset-0.16*speed))
	for b in loose:
		if is_held(b): continue
		var p := to_local(b.global_position)
		if p.x > -5.6 and p.x < -1.8 and p.z > 6.5 and p.z < 10.6:
			b.apply_central_force(-b.linear_velocity * drag_coefficient)
		if p.y < -12.0 or p.length() > 65.0:
			restore_body(b); recovered += 1
			status.text = "Recovered %d out-of-bounds bodies.\nOrdinary misses remain." % recovered
	# Lost rings are recovered to the cake, never culled to make a new shot possible.
	for ring in mortar.rings:
		if is_instance_valid(ring) and not is_held(ring) and to_local(ring.global_position).y < -12.0:
			ring.global_position = to_global(Vector3(4,1.6,-10.2)); ring.linear_velocity = Vector3.ZERO; ring.angular_velocity = Vector3.ZERO
	update_spring_lines()

func update_spring_lines() -> void:
	var line := ImmediateMesh.new(); line.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in range(2):
		var start := Vector3(2.1 if i==0 else 5.5,1,3.3)
		var finish := to_local(springs[i].global_position)
		for j in range(40):
			for t in [float(j)/40.0,float(j+1)/40.0]:
				var p: Vector3 = start.lerp(finish,t)
				p += Vector3(0,sin(t*TAU*7),cos(t*TAU*7))*0.06*sin(t*PI)
				line.surface_add_vertex(p)
	line.surface_end(); spring_lines.mesh = line

func restore_body(body: RigidBody3D) -> void:
	body.transform = homes[body]; body.linear_velocity = Vector3.ZERO; body.angular_velocity = Vector3.ZERO; body.sleeping = false
	if body in points: body.freeze = true; body.firing = false

func reset_trial() -> bool:
	for body in loose + mortar.rings:
		if is_instance_valid(body) and is_held(body):
			status.text = "Put down the held object before resetting."; return false
	for b in loose: restore_body(b)
	pole.freeze = true; pole.transform = pole_home; pole.linear_velocity = Vector3.ZERO; pole.angular_velocity = Vector3.ZERO
	mortar.reset_rings()
	status.text = "A new trial. Misses stay until you reset."
	return true

func _point_inside(world: Vector3) -> bool:
	var p := to_local(world)
	return absf(p.x) < 7.4 and p.z > -12.8 and p.z < 12.5 and p.y > -5.0 and p.y < 16.0

func queue_launch(body: CharacterBody3D, velocity: Vector3) -> void:
	_launch[body.get_instance_id()] = velocity
	_last_launch[body.get_instance_id()] = Time.get_ticks_msec()

func carry_velocity(body: CharacterBody3D, delta: float, incoming: Vector3) -> Vector3:
	var id := body.get_instance_id()
	var v: Vector3 = _carry.get(id,incoming)
	var launched := _launch.has(id)
	if launched: v = _launch[id]; _launch.erase(id)
	var thrust := thrust_acceleration(body)
	if body.is_on_floor() and not launched and v.y <= 0.1 and thrust.length_squared() < 0.01:
		var desired := walking_velocity(body)
		v.x = move_toward(v.x,desired.x,14.0*delta)
		v.z = move_toward(v.z,desired.z,14.0*delta)
		v.y = 0.0
		if not body is XRToolsPlayerBody and Input.is_key_pressed(KEY_SPACE): v.y = 4.5
	# Exclusive provider owns gravity here; it must be applied exactly once.
	v += (Vector3.DOWN*9.8+thrust)*delta
	return v.limit_length(14.0)

func walking_velocity(body: CharacterBody3D) -> Vector3:
	if body is XRToolsPlayerBody:
		var frame: Basis = body.camera_node.global_basis
		return (frame.x.slide(Vector3.UP).normalized()*body.ground_control_velocity.x-frame.z.slide(Vector3.UP).normalized()*body.ground_control_velocity.y)*XRServer.world_scale
	var x := float(Input.is_key_pressed(KEY_D))-float(Input.is_key_pressed(KEY_A))
	var z := float(Input.is_key_pressed(KEY_S))-float(Input.is_key_pressed(KEY_W))
	return body.global_basis * Vector3(x,0,z).normalized()*3.0

func record_carry(body: CharacterBody3D) -> void: _carry[body.get_instance_id()] = body.velocity
func release_carry(body: CharacterBody3D) -> void:
	_carry.erase(body.get_instance_id()); _launch.erase(body.get_instance_id())
	_last_launch.erase(body.get_instance_id())

func _node_added(node: Node) -> void:
	if node is XRToolsPlayerBody: install_adapter.call_deferred()
	if node.has_method("_grab_held") and node not in desktop_pointers: desktop_pointers.append(node)

func install_adapter() -> void:
	for node in get_tree().root.find_children("*","Node",true,false):
		if node.has_method("_grab_held") and node not in desktop_pointers: desktop_pointers.append(node)
	for body in get_tree().get_nodes_in_group("player_body"):
		if not body is XRToolsPlayerBody or body.get_node_or_null("FieldCarryAdapter") != null: continue
		var adapter = ADAPTER.new(); adapter.name = "FieldCarryAdapter"; adapter.receiver = body
		body.add_child(adapter)
		if adapter not in body._movement_providers: body._movement_providers.append(adapter)
		body._movement_providers.sort_custom(body.sort_by_order)

