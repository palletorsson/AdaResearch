extends Node3D
## A finite physics comparison to the editable coordinate/graph body.
## Source points: VRBody. Ten rigid parts, nine freely rotating pin joints.
## This deliberately simple puppet has no anatomical angle limits.
## Adjacent parts exclude each other from collision; other parts collide. It does not write the gold workshop's saved pose.
const Grip = preload("res://algorithms/computationalbiology/molecular_framework/AssemblyRagdollGrip.gd")
const BODY_SCALE := 1.12
const SPRING := 180.0
const DAMPING := 12.0
const MAX_FORCE := 90.0
var parts: Dictionary = {}
var points: Dictionary = {}
var anchors: Dictionary = {}
var grips: Dictionary = {}
var tethers: Dictionary = {}
var active: Dictionary = {}
var initial: Dictionary = {}
var links: Array[Dictionary] = []
var hanger: PinJoint3D
var hanger_body: StaticBody3D
var string_mesh: MeshInstance3D
var caption: Label3D
var reset_button: Node
var reset_pending := false
var built := false

func build(assembly: Dictionary) -> void:
	if built: return
	built = true
	for row in assembly.nodes:
		points[str(row.id)] = Vector3(row.pos[0],row.pos[1],row.pos[2]) * BODY_SCALE
	_stage()
	_limb("torso",points.pelvis,points.torso,.135,2.0)
	_limb("head",points.head,points.head,.125,.65)
	for side in ["l","r"]:
		_limb(side+"_upper",points[side+"_sh"],points[side+"_elb"],.065,.35)
		_limb(side+"_fore",points[side+"_elb"],points[side+"_hand"],.06,.25)
		_limb(side+"_thigh",points.pelvis+Vector3(-.12 if side=="l" else .12,0,0),points[side+"_knee"],.075,.6)
		_limb(side+"_shin",points[side+"_knee"],points[side+"_foot"],.065,.4)
	_torso_bar(points.l_sh,points.r_sh,.045)
	_torso_bar(points.torso,points.torso.lerp(points.head,.55),.045)
	_join("torso","head",points.torso.lerp(points.head,.55))
	for side in ["l","r"]:
		_join("torso",side+"_upper",points[side+"_sh"])
		_join(side+"_upper",side+"_fore",points[side+"_elb"])
		_join("torso",side+"_thigh",points.pelvis+Vector3(-.12 if side=="l" else .12,0,0))
		_join(side+"_thigh",side+"_shin",points[side+"_knee"])
	for id in points:
		var part_id: String = "torso"
		if id=="head": part_id="head"
		elif id.ends_with("_sh") or id.ends_with("_elb"): part_id=id.left(1)+"_upper"
		elif id.ends_with("_hand"): part_id=id.left(1)+"_fore"
		elif id.ends_with("_knee"): part_id=id.left(1)+"_thigh"
		elif id.ends_with("_foot"): part_id=id.left(1)+"_shin"
		var part: RigidBody3D = parts[part_id]
		anchors[id] = {"part":part,"local":part.to_local(to_global(points[id]))}
		_make_grip(id)
	_hang()
	_sync_grips()

func material(color: Color, emission: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color=color
	m.metallic=.4
	m.roughness=.35
	m.emission_enabled=emission>0
	m.emission=color
	m.emission_energy_multiplier=emission
	return m

func _limb(id: String, a: Vector3, b: Vector3, radius: float, mass_value: float) -> void:
	var body := RigidBody3D.new()
	body.name="Limb_"+id
	body.mass=mass_value
	body.collision_layer=8
	body.collision_mask=1|8
	body.linear_damp=.45
	body.angular_damp=.8
	body.continuous_cd=true
	var friction := PhysicsMaterial.new()
	friction.friction=.8
	friction.bounce=0
	body.physics_material_override=friction
	add_child(body)
	body.position=(a+b)*.5
	var length := a.distance_to(b)
	if length>.001:
		var direction := (b-a).normalized()
		var up := Vector3.RIGHT if absf(direction.dot(Vector3.UP))>.99 else Vector3.UP
		body.basis=Basis.looking_at(direction,up)*Basis(Vector3.RIGHT,PI/2)
	var mesh := MeshInstance3D.new()
	var shape := CollisionShape3D.new()
	if length<.001:
		var sphere := SphereMesh.new()
		sphere.radius=radius; sphere.height=radius*2
		mesh.mesh=sphere
		var ball := SphereShape3D.new()
		ball.radius=radius; shape.shape=ball
	else:
		var capsule := CapsuleMesh.new()
		capsule.radius=radius; capsule.height=length+radius*2
		mesh.mesh=capsule
		var solid := CapsuleShape3D.new()
		solid.radius=radius; solid.height=capsule.height; shape.shape=solid
	mesh.material_override=material(Color(.25,.66,.73))
	body.add_child(mesh); body.add_child(shape)
	parts[id]=body
	initial[id]=body.transform
	body.force_update_transform()

func _join(a: String, b: String, at: Vector3) -> void:
	var joint := PinJoint3D.new()
	joint.name="Joint_"+a+"_"+b
	add_child(joint)
	joint.position=at
	joint.node_a=joint.get_path_to(parts[a])
	joint.node_b=joint.get_path_to(parts[b])
	joint.exclude_nodes_from_collision=true
	joint.solver_priority=4
	links.append({"a":parts[a],"b":parts[b],"pa":parts[a].to_local(to_global(at)),"pb":parts[b].to_local(to_global(at))})

func _make_grip(id: String) -> void:
	var grip := Grip.new()
	grip.name="Grip_"+id
	grip.study=self; grip.point_id=id
	var radius := .085
	if id=="head": radius=.145
	if id=="torso" or id=="pelvis": radius=.15
	var mesh := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius=radius-.017; ring.outer_radius=radius
	ring.rings=20; ring.ring_segments=10
	mesh.mesh=ring; mesh.rotation.x=PI/2
	mesh.material_override=material(Color(.98,.47,.29),.3)
	grip.add_child(mesh)
	var collision := CollisionShape3D.new()
	var ball := SphereShape3D.new()
	ball.radius=radius
	collision.shape=ball; grip.add_child(collision)
	add_child(grip)
	grips[id]=grip
	var tether := MeshInstance3D.new()
	var cord := CylinderMesh.new()
	cord.top_radius=.005; cord.bottom_radius=.005; cord.radial_segments=8
	tether.mesh=cord; tether.material_override=material(Color(.98,.47,.29),.2)
	tether.visible=false; add_child(tether); tethers[id]=tether

func anchor_position(id: String) -> Vector3:
	var anchor: Dictionary = anchors[id]
	return anchor.part.to_global(anchor.local)

func begin_pull(id: String) -> void:
	if not anchors.has(id) or reset_pending: return
	active[id]=true
	_unhang()
	for body in parts.values(): body.sleeping=false
	caption.text="PULL ONE PART.
What follows?"

func end_pull(id: String) -> void:
	active.erase(id)
	caption.text="LET THE FLOOR ANSWER.
Hang again to try another limb."

func _physics_process(_delta: float) -> void:
	if not built or reset_pending: return
	for id in active:
		var anchor: Dictionary = anchors[id]
		var body: RigidBody3D = anchor.part
		var at := anchor_position(id)
		var offset := at-body.global_position
		var velocity := body.linear_velocity+body.angular_velocity.cross(offset)
		# Limit the target's reach to the bay without moving the hand/controller.
		var local_target := to_local(grips[id].global_position).clamp(Vector3(-1.25,.12,-1.25),Vector3(1.25,2.4,1.25))
		var force := (to_global(local_target)-at)*SPRING-velocity*DAMPING
		body.apply_force(force.limit_length(MAX_FORCE),offset)
	_sync_grips()

func _sync_grips() -> void:
	for id in grips:
		var tether: MeshInstance3D=tethers[id]
		tether.visible=active.has(id)
		if active.has(id):
			var a := anchor_position(id)
			var b: Vector3=grips[id].global_position
			var direction := b-a
			if direction.length()<.015:
				tether.hide()
				continue
			tether.global_position=(a+b)*.5
			var up := Vector3.RIGHT if absf(direction.normalized().dot(Vector3.UP))>.99 else Vector3.UP
			tether.global_basis=Basis.looking_at(direction.normalized(),up)*Basis(Vector3.RIGHT,PI/2)
			(tether.mesh as CylinderMesh).height=direction.length()
			continue
		grips[id].global_position=anchor_position(id)
		grips[id].global_basis=global_basis

func _unhang() -> void:
	if is_instance_valid(hanger):
		hanger.node_a=NodePath(); hanger.node_b=NodePath()
		hanger.queue_free(); hanger=null
	string_mesh.hide()

func _hang() -> void:
	hanger=PinJoint3D.new()
	hanger.name="HangingSupport"
	add_child(hanger)
	hanger.position=points.head
	hanger_body.force_update_transform()
	parts.head.force_update_transform()
	hanger.node_a=hanger.get_path_to(hanger_body)
	hanger.node_b=hanger.get_path_to(parts.head)
	string_mesh.show()
	caption.text="A BODY WITH WEIGHT
Take a coral ring. Let go."

func request_reset() -> void:
	if not active.is_empty() or reset_pending: return
	reset_pending=true
	call_deferred("_reset")

func _reset() -> void:
	_unhang()
	for id in parts:
		var body: RigidBody3D=parts[id]
		body.freeze=true
		body.transform=initial[id]
		body.force_update_transform()
		PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,body.global_transform)
		body.linear_velocity=Vector3.ZERO; body.angular_velocity=Vector3.ZERO
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_inside_tree(): return
	_hang()
	for body in parts.values(): body.freeze=false; body.sleeping=false
	reset_pending=false
	_sync_grips()

func _box(at: Vector3, size: Vector3, color: Color, solid: bool = false) -> void:
	var mesh := MeshInstance3D.new()
	var cube := BoxMesh.new(); cube.size=size
	mesh.mesh=cube; mesh.material_override=material(color)
	if solid:
		var body := StaticBody3D.new()
		body.position=at; body.collision_layer=1; body.collision_mask=0
		add_child(body); body.add_child(mesh)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new(); shape.size=size
		collision.shape=shape; body.add_child(collision)
	else:
		mesh.position=at; add_child(mesh)

func _stage() -> void:
	_box(Vector3(0,.012,0),Vector3(2.8,.024,2.8),Color(.09,.17,.2),true)
	for x in [-1.13,1.13]:
		_box(Vector3(x,1.12,-.38),Vector3(.06,2.24,.06),Color(.38,.47,.5),true)
	_box(Vector3(0,2.24,-.38),Vector3(2.32,.06,.06),Color(.38,.47,.5),true)
	_box(Vector3(0,2.24,-.19),Vector3(.06,.06,.44),Color(.38,.47,.5))
	hanger_body=StaticBody3D.new(); hanger_body.name="SupportAnchor"
	hanger_body.collision_layer=0; hanger_body.collision_mask=0
	add_child(hanger_body)
	string_mesh=MeshInstance3D.new()
	var wire := CylinderMesh.new()
	wire.top_radius=.004; wire.bottom_radius=.004
	wire.height=2.24-points.head.y
	string_mesh.mesh=wire; string_mesh.position=Vector3(0,(2.24+points.head.y)*.5,0)
	string_mesh.material_override=material(Color(.72,.79,.82))
	add_child(string_mesh)
	caption=Label3D.new(); caption.font_size=27; caption.pixel_size=.0026
	caption.position=Vector3(0,2.55,-.25); caption.modulate=Color(.15,.35,.4)
	caption.outline_size=4; caption.double_sided=true; add_child(caption)
	var rack: Node3D=load("res://commons/audio/rack_templates/RackTemplates.gd").create_panel("",[[{"type":"button","label":"HANG AGAIN"}]])
	rack.position=Vector3(1.1,1.1,.05); rack.rotation_degrees.x=-15
	rack.scale=Vector3.ONE*1.8
	add_child(rack)
	reset_button=rack.find_child("Btn_0",true,false).get_node("InteractableAreaButton")
	reset_button.button_pressed.connect(func(_b): request_reset())

func _torso_bar(a: Vector3, b: Vector3, radius: float) -> void:
	var mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius=radius; cylinder.bottom_radius=radius; cylinder.height=a.distance_to(b)
	mesh.mesh=cylinder; mesh.material_override=material(Color(.25,.66,.73))
	parts.torso.add_child(mesh)
	mesh.global_position=to_global((a+b)*.5)
	var direction := global_basis*(b-a).normalized()
	var up := global_basis*Vector3.RIGHT if absf(direction.dot(Vector3.UP))>.99 else Vector3.UP
	mesh.global_basis=Basis.looking_at(direction,up)*Basis(Vector3.RIGHT,PI/2)
