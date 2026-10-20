extends Node3D
const Model=preload("model.gd")
const PointBody=preload("res://commons/artifacts/particle_swarm_walk/point_body.gd")
const HOME:=Vector3(-8.3,1.18,0)
const CYAN:=Color("74dbe8")
const PINK:=Color("f18ebf")
var model=Model.new()
var point:XRToolsPickable
var figures:Array[Node3D]=[]
var legs:Array[Array]=[]
var arrows:Array[Node3D]=[]
var status:Label3D
var guides:=true
var playing:=true
var elapsed:=0.0
var released:=0.0
var arrow_layer:Node3D
var shown_rebuild:=-1
var destinations:Array[MeshInstance3D]=[]

func material(c:Color)->StandardMaterial3D:
	var m:=StandardMaterial3D.new();m.albedo_color=c;m.roughness=.4;return m
func part(mesh:Mesh,at:Vector3,c:Color,parent:Node3D=self)->MeshInstance3D:
	var n:=MeshInstance3D.new();n.mesh=mesh;n.position=at;n.material_override=material(c);parent.add_child(n);return n
func box(size:Vector3,at:Vector3,c:Color,solid:=false)->MeshInstance3D:
	var mesh:=BoxMesh.new();mesh.size=size;var n:=part(mesh,at,c)
	if solid:
		var body:=StaticBody3D.new();body.collision_layer=1;body.collision_mask=0
		var shape:=BoxShape3D.new();shape.size=size;var collider:=CollisionShape3D.new();collider.shape=shape
		body.add_child(collider);add_child(body);body.position=at
	return n
func words(text:String,at:Vector3,size:=28)->Label3D:
	var n:=Label3D.new();n.text=text;n.position=at;n.font_size=size;n.pixel_size=.003;n.outline_size=6
	n.billboard=BaseMaterial3D.BILLBOARD_ENABLED;add_child(n);return n
func sphere(radius:float,at:Vector3,c:Color,parent:Node3D)->MeshInstance3D:
	var mesh:=SphereMesh.new();mesh.radius=radius;mesh.height=radius*2;mesh.radial_segments=12;mesh.rings=6
	return part(mesh,at,c,parent)

func _ready()->void:
	box(Vector3(15,.025,11),Vector3(0,.013,0),Color("202c3a"))
	box(Vector3(2,1.05,5),Vector3(0,.525,0),Color("e9e6de"),true)
	words("ONE FIELD / MANY BODIES",Vector3(0,3.25,0),54)
	words("The floor gives directions. No body reads its neighbours.",Vector3(0,2.85,0),28)
	for sign in [-1,1]:
		box(Vector3(3,.035,2.6),Vector3(5.5,.04,sign*3.75),CYAN if sign<0 else PINK)
		var sign_label:=words("A" if sign<0 else "B",Vector3(5.5,2.4,sign*3.75),128)
		sign_label.pixel_size=.006
		var ring:=TorusMesh.new();ring.inner_radius=.27;ring.outer_radius=.31;ring.rings=24;ring.ring_segments=6
		destinations.append(part(ring,Vector3(5.5,.07,sign*3.75),Color.WHITE))
	box(Vector3(2.5,.035,3),Vector3(-5.5,.04,0),Color("5c6571"))
	words("RETURN",Vector3(-5.5,2.3,0),32)
	for i in range(model.COUNT):
		var figure:=Node3D.new();figure.name="Walker%02d"%i;add_child(figure);figures.append(figure)
		var colour:=Color("ffdc91") if i==0 else CYAN.lerp(PINK,float(i)/23)
		sphere(.14,Vector3(0,1.34,0),colour,figure)
		var torso:=CapsuleMesh.new();torso.radius=.12;torso.height=.49;torso.radial_segments=8;torso.rings=4
		part(torso,Vector3(0,.98,0),Color("d6dce1"),figure)
		var pair:Array=[]
		for side in [-1,1]:
			var leg_root:=Node3D.new();figure.add_child(leg_root);leg_root.position=Vector3(side*.065,.76,0)
			var limb:=CylinderMesh.new();limb.top_radius=.04;limb.bottom_radius=.04;limb.height=.62;limb.radial_segments=6
			part(limb,Vector3(0,-.31,0),colour,leg_root);pair.append(leg_root)
		legs.append(pair)
	arrow_layer=Node3D.new();arrow_layer.name="Directions";add_child(arrow_layer)
	for z in range(1,model.grid.height-1,2):
		for x in range(1,model.grid.width-1,2):
			var at:Vector3=model.grid.grid_to_world(x,z)
			if not model.valid(at):continue
			var arrow:=Node3D.new();arrow_layer.add_child(arrow);arrow.position=at+Vector3.UP*.085
			arrow.set_meta("cell",Vector2i(x,z));arrows.append(arrow)
			var stem:=CylinderMesh.new();stem.top_radius=.018;stem.bottom_radius=.018;stem.height=.29;stem.radial_segments=6
			var shaft:=part(stem,Vector3(0,0,-.035),Color("96c6d6"),arrow);shaft.rotation.x=PI/2
			var cone:=CylinderMesh.new();cone.top_radius=0;cone.bottom_radius=.075;cone.height=.12;cone.radial_segments=6
			var tip:=part(cone,Vector3(0,0,-.235),Color("96c6d6"),arrow);tip.rotation.x=-PI/2
	box(Vector3(.36,1.02,.36),Vector3(HOME.x,.51,0),Color("e9e6de"),true)
	point=PointBody.new();point.name="DestinationPoint";add_child(point);point.position=HOME
	point.action_pressed.connect(func(_p):
		if point.held():guides=not guides)
	words("CARRY A DIRECTION",HOME+Vector3(0,1.05,0),30)
	words("Move the point toward A or B\nTrigger / left click: show the field\nDrop: the same bodies return",HOME+Vector3(0,.7,0),17)
	status=words("",HOME+Vector3(0,.3,0),17)
	for z in [-4,4]:
		var light:=OmniLight3D.new();light.position=Vector3(0,4,z);light.omni_range=12;light.light_energy=2;add_child(light)
	_refresh()

func _physics_process(dt:float)->void:
	if point.held():
		released=0
		var dz:float=to_local(point.global_position).z-HOME.z
		if dz<-.2:model.set_route(-1)
		elif dz>.2:model.set_route(1)
	else:
		model.set_route(0);released+=dt
		if released>1.5 and point.position.distance_to(HOME)>.001:point.position=HOME
	if playing:model.step(minf(dt,1.0/30))

func _process(dt:float)->void:
	elapsed+=dt;_refresh()

func _refresh()->void:
	for i in range(figures.size()):
		figures[i].position=model.positions[i]+Vector3.UP*.05
		var v:Vector3=model.velocities[i]
		if v.length()>.02:figures[i].rotation.y=atan2(-v.x,-v.z)
		for j in range(2):legs[i][j].rotation.x=sin(elapsed*7+i+j*PI)*.35*minf(v.length(),1.0)
	if arrow_layer!=null:arrow_layer.visible=guides
	if shown_rebuild!=model.rebuilds:
		for arrow in arrows:
			var c:Vector2i=arrow.get_meta("cell");var v:Vector3=model.grid.get_vector(model.grid.grid_to_world(c.x,c.y))
			arrow.visible=v.length()>.01;arrow.rotation.y=atan2(-v.x,-v.z)
		shown_rebuild=model.rebuilds
	if status!=null:status.text="Destination: "+({-1:"A",0:"RETURN",1:"B"}[model.route])+"  |  Arrived: %d / 24"%model.arrived.count(true)
	for i in range(destinations.size()):destinations[i].visible=model.route==(-1 if i==0 else 1)

func get_museum_occupied_cells()->Array[Vector2i]:
	var result:Array[Vector2i]=[]
	for p in [to_global(HOME)]:
		for x in range(floori(p.x-.18),floori(p.x+.18)+1):
			for z in range(floori(p.z-.18),floori(p.z+.18)+1):result.append(Vector2i(x,z))
	for x in range(-2,3):
		for z in range(-5,6):
			var p:=to_global(Vector3(x*.49,0,z*.49));var c:=Vector2i(floori(p.x),floori(p.z))
			if not result.has(c):result.append(c)
	return result
