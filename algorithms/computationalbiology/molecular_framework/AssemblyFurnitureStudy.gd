extends "res://algorithms/computationalbiology/molecular_framework/AssemblyRagdoll.gd"
## The same force-driven grab experiment, applied to the existing furniture graphs.
## Explicit supports hold an authored pose until first grab. The seat/top/legs then
## move as separate rigid parts joined by free pins, not welded furniture.
var assembly_kind := "Chair"
var catalog: Dictionary = {}
var furniture_scale := 1.2
var supports: Array[PinJoint3D] = []
var support_wires: Array[MeshInstance3D] = []
var sizes: Dictionary = {}
var tint := Color(.65,.32,.51)

func build(assembly: Dictionary) -> void:
	if built: return
	built=true
	furniture_scale=1.15 if assembly_kind=="Table" else 1.2
	tint=Color(.38,.59,.42) if assembly_kind=="Table" else (Color(.85,.65,.32) if assembly_kind=="Lamp" else Color(.65,.32,.51))
	for row in assembly.nodes:
		points[str(row.id)]=Vector3(row.pos[0],row.pos[1],row.pos[2])*furniture_scale+Vector3(0,.04,0)
	_stage()
	for row in assembly.nodes:
		_furniture_part(str(row.id),catalog.get(row.part,{}))
	for pair in assembly.bonds:
		var a: String=pair[0]
		var b: String=pair[1]
		var at: Vector3=points[a].lerp(points[b],.5)
		if b.begins_with("leg"):
			at=Vector3(points[b].x,points[a].y-.025,points[b].z)
		elif b=="back": at=Vector3(0,points.seat.y,points.back.z)
		elif assembly_kind=="Lamp":
			if b=="shaft": at=points.base+Vector3(0,.035,0)
			elif b=="bulb": at=points.bulb
		_join(a,b,at)
	for id in parts:
		var at: Vector3=points[id]
		if id in ["seat","top","base"]: at+=Vector3(0,.04,float(sizes[id].z)*.5+.07)
		elif id=="back": at+=Vector3(0,.1,.065)
		elif id=="shade": at+=Vector3(0,0,.31)
		elif id=="bulb": at+=Vector3(0,0,.17)
		elif id=="shaft": at+=Vector3(0,0,.075)
		anchors[id]={"part":parts[id],"local":parts[id].to_local(to_global(at))}
		_make_grip(id)
	_hang()
	_sync_grips()

func _furniture_part(id: String, definition: Dictionary) -> void:
	var body := RigidBody3D.new()
	body.name="Part_"+id
	body.mass=float(definition.get("mass",.8))
	body.collision_layer=8; body.collision_mask=1|8
	body.linear_damp=.45; body.angular_damp=.8; body.continuous_cd=true
	var friction := PhysicsMaterial.new(); friction.friction=.8; friction.bounce=0
	body.physics_material_override=friction
	add_child(body); body.position=points[id]
	var mesh := MeshInstance3D.new()
	mesh.name="FurnitureMesh"
	var collision := CollisionShape3D.new()
	if id in ["seat","top","back","base"]:
		var size := Vector3(.6,.055,.6)
		if id=="top":size=Vector3(.92,.065,.92)
		elif id=="back":size=Vector3(.6,.84,.065)
		elif id=="base":size=Vector3(.55,.055,.55)
		var box := BoxMesh.new();box.size=size;mesh.mesh=box
		var shape := BoxShape3D.new();shape.size=size;collision.shape=shape
		sizes[id]=size
	elif id=="bulb":
		var sphere := SphereMesh.new();sphere.radius=.14;sphere.height=.28;mesh.mesh=sphere
		var shape := SphereShape3D.new();shape.radius=.14;collision.shape=shape
	elif id=="shade":
		var shade := CylinderMesh.new();shade.top_radius=.1;shade.bottom_radius=.3;shade.height=.32;shade.radial_segments=24
		mesh.mesh=shade;collision.shape=shade.create_convex_shape()
	else:
		var cylinder := CylinderMesh.new()
		cylinder.top_radius=.034 if id=="shaft" else (.066 if assembly_kind=="Table" else .05)
		cylinder.bottom_radius=cylinder.top_radius
		cylinder.height=1.16 if id=="shaft" else ((.75 if assembly_kind=="Table" else .5)*furniture_scale-.055)
		mesh.mesh=cylinder
		var shape := CylinderShape3D.new();shape.height=cylinder.height;shape.radius=cylinder.top_radius;collision.shape=shape
	mesh.material_override=material(tint,.0)
	if id=="bulb":
		mesh.material_override=material(Color(1,.83,.46),1.4)
		var light := OmniLight3D.new();light.light_color=Color(1,.78,.42);light.light_energy=.4;light.omni_range=2.0
		body.add_child(light)
	body.add_child(mesh);body.add_child(collision)
	parts[id]=body;initial[id]=body.transform
	body.force_update_transform()

func _stage() -> void:
	_box(Vector3(0,.012,0),Vector3(2.6,.024,2.6),Color(.13,.16,.19),true)
	for x in [-1.1,1.1]: _box(Vector3(x,1.04,-.5),Vector3(.05,2.08,.05),Color(.42,.46,.48),true)
	_box(Vector3(0,2.08,-.5),Vector3(2.25,.05,.05),Color(.42,.46,.48),true)
	hanger_body=StaticBody3D.new();hanger_body.name="PoseSupports"
	hanger_body.collision_layer=0;hanger_body.collision_mask=0;add_child(hanger_body)
	caption=Label3D.new();caption.position=Vector3(0,2.33,-.5)
	caption.font_size=26;caption.pixel_size=.0025;caption.modulate=Color(.2,.3,.34)
	caption.outline_size=4;caption.double_sided=true;add_child(caption)
	var rack: Node3D=load("res://commons/audio/rack_templates/RackTemplates.gd").create_panel("",[[{"type":"button","label":"REASSEMBLE"}]])
	rack.position=Vector3(1.08,1.05,-.15);rack.rotation_degrees.x=-15;rack.scale=Vector3.ONE*1.8
	add_child(rack)
	reset_button=rack.find_child("Btn_0",true,false).get_node("InteractableAreaButton")
	reset_button.button_pressed.connect(func(_b):request_reset())

func _hang() -> void:
	# These pins hold part centres in place. They stage the initial assembly;
	# they are all removed together on first grab, unlike the structural pins.
	hanger_body.force_update_transform()
	for id in parts:
		parts[id].force_update_transform()
		var support := PinJoint3D.new();support.name="Support_"+id
		add_child(support);support.position=points[id]
		support.node_a=support.get_path_to(hanger_body);support.node_b=support.get_path_to(parts[id])
		supports.append(support)
		var wire := MeshInstance3D.new();var cord := CylinderMesh.new()
		cord.top_radius=.003;cord.bottom_radius=.003;cord.radial_segments=6
		var a: Vector3=points[id];var b:=Vector3(a.x,2.08,-.5)
		cord.height=a.distance_to(b);wire.mesh=cord
		wire.material_override=material(Color(.65,.7,.72))
		add_child(wire);wire.position=(a+b)*.5
		var direction: Vector3=(b-a).normalized()
		var up:=Vector3.RIGHT if absf(direction.dot(Vector3.UP))>.99 else Vector3.UP
		wire.basis=Basis.looking_at(direction,up)*Basis(Vector3.RIGHT,PI/2)
		support_wires.append(wire)
	caption.text="HELD AS A "+assembly_kind.to_upper()+"\nTake a coral ring. Let go."

func _unhang() -> void:
	for support in supports:
		support.node_a=NodePath();support.node_b=NodePath();support.queue_free()
	supports.clear()
	for wire in support_wires:wire.queue_free()
	support_wires.clear()

func begin_pull(id: String) -> void:
	super.begin_pull(id)
	if active.has(id):caption.text="WHAT HOLDS A "+assembly_kind.to_upper()+"?\nPull one part."

func end_pull(id: String) -> void:
	super.end_pull(id)
	caption.text="STILL A "+assembly_kind.to_upper()+"?\nReassemble to try another part."
