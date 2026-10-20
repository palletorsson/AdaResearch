extends Node3D
## Gaudi-inspired geometric column forest. No structural load solver is claimed.
const B=preload("spatial_builder.gd")
const PALE:=Color("e9e2d5")
const DARK:=Color("191e29")
const GOLD:=Color("f2be64")
const BLUE:=Color("70cddd")
var portals:Node3D
var room:Node3D
var source:Node3D
var target:Node3D
var columns:Array[Node3D]=[]
var branches:Array[MeshInstance3D]=[]
var guides:Array[MeshInstance3D]=[]
var readout:Label3D
var angle:=35.0
var show_rule:=false
var centre:=Vector3(-3.5,0,5.8)

func setup(owner_portals:Node3D)->void:
	portals=owner_portals;room=Node3D.new();add_child(room)
	room.name="ColumnForest";room.position=Vector3(32,195,0)
	B.box(room,Vector3(0,-0.2,0),Vector3(14,0.4,20),PALE,true)
	for x in [-7,7]:B.box(room,Vector3(x,5.8,0),Vector3(0.2,11.6,20),PALE,true)
	B.box(room,Vector3(0,5.8,-10),Vector3(14,11.6,0.2),DARK,true)
	for x in [-4,4]:B.box(room,Vector3(x,5.8,10),Vector3(6,11.6,0.2),DARK,true)
	B.box(room,Vector3(0,7.4,10),Vector3(2,8.4,0.2),DARK,true)
	for z in range(-9,10):B.box(room,Vector3(0,0.006,z),Vector3(13.7,0.012,0.018),Color("aaa7a0"))
	for x in range(-6,7):B.box(room,Vector3(x,0.007,0),Vector3(0.018,0.014,19.7),Color("aaa7a0"))
	for z in [-6.0,-2.0,2.0,6.0]:
		for x in [-4.6,4.6]:
			var column:=Node3D.new();room.add_child(column);column.position=Vector3(x,0,z)
			columns.append(column)
			B.cylinder(column,Vector3(0,0.2,0),0.8,0.4,DARK,true)
			B.mesh(column,shaft(6,5.5,0.47,PI/2),Vector3(0,0.4,0),PALE,true)
			B.ball(column,Vector3(0,5.9,0),0.5,PALE)
			for j in range(4):
				var direction:=Vector3(cos(TAU*j/4),0,sin(TAU*j/4))
				var middle:=Vector3(0,5.9,0)+direction*1.15+Vector3.UP*1.8
				B.tube(column,Vector3(0,5.9,0),middle,PALE,0.21)
				for side in [-1,1]:
					var end:=middle+direction.rotated(Vector3.UP,side*0.45)*0.8+Vector3.UP*1.3
					B.tube(column,middle,end,PALE,0.12)
					# Join each fork to the sampled vault rib above this column row.
					B.tube(column,end,Vector3(end.x,vault_height(x+end.x),0),PALE,0.1)
		# Vault ribs are sampled geometry, joined by a light canopy. These are
		# geometric constructions, not evidence of engineered load capacity.
		for j in range(28):
			var ax:=lerpf(-6.6,6.6,float(j)/28);var bx:=lerpf(-6.6,6.6,float(j+1)/28)
			var a:=Vector3(ax,vault_height(ax),z)
			var b:=Vector3(bx,vault_height(bx),z)
			B.tube(room,a,b,GOLD,0.075)
	for x in [-5.8,-3,0,3,5.8]:
		var height:float=vault_height(x)
		B.box(room,Vector3(x,height,0),Vector3(0.065,0.065,16),PALE)
	# A low front study brings the same branching rule within reach and sight.
	B.cylinder(room,centre+Vector3(0,0.15,0),0.7,0.3,DARK,true)
	B.mesh(room,shaft(6,1.25,0.22,PI/2),centre+Vector3(0,0.3,0),PALE,true)
	for j in range(4):
		var branch:=B.tube(room,centre+Vector3.UP*1.55,centre+Vector3.UP*2.5,PALE,0.1)
		branch.set_meta("portal_dynamic",true);branches.append(branch)
		var guide:=B.tube(room,centre+Vector3.UP*1.55,centre+Vector3.UP*2.5,BLUE,0.107)
		guide.material_override=B.material(BLUE,true);guides.append(guide);guide.set_meta("portal_dynamic",true)
	readout=B.text(room,"",Vector3(-3.5,3.45,5.85),16,GOLD);readout.pixel_size=0.003
	B.text(room,"ENDLESS MUSEUM",Vector3(0,8,-9.84),40,PALE)
	B.text(room,"always another room",Vector3(0,7.45,-9.83),20,PALE)
	B.text(room,"PROFILE / TWIST / BRANCH / CANOPY",Vector3(0,6.6,-9.82),25,GOLD)
	B.text(room,"A geometric forest, inspired by Gaudi.\nCarry the point to open the front study.\nTrigger: show the construction lines.",Vector3(0,5.8,-9.81),18,PALE)
	for x in [-5.5,5.5]:
		for z in [-6,2,7]:
			var light:=OmniLight3D.new();room.add_child(light)
			light.position=Vector3(x,7,z);light.omni_range=20;light.light_energy=2.5
	# Coloured clerestory strips make the different bays legible.
	for side in [-1,1]:
		for z in [-6,-2,2,6]:
			B.box(room,Vector3(side*6.85,7.8,z),Vector3(0.03,4.5,1.6),Color("ed78ad") if side==-1 else BLUE)
	source=Node3D.new();portals.interiors[1].add_child(source)
	source.position=Vector3(-3.4,0,-4.2);portals.frame(source,GOLD,"COLUMN FOREST / GAUDI")
	B.box(source,Vector3(0,1.5,-0.7),Vector3(2.5,3,0.2),DARK,true)
	target=Node3D.new();room.add_child(target);target.position=Vector3(0,0,9.84);target.rotation.y=PI
	portals.frame(target,GOLD,"BACK TO BLUE / MUSEUM")
	redraw();room.visible=false

static func shaft(sides:int,height:float,radius:float,twist:float)->ArrayMesh:
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for layer in range(24):
		for j in range(sides):
			var vertices:Array[Vector3]=[]
			for corner in [Vector2i(j,layer),Vector2i(j+1,layer),Vector2i(j+1,layer+1),Vector2i(j,layer+1)]:
				var t:=float(corner.y)/24;var theta:float=TAU*corner.x/sides+twist*t
				vertices.append(Vector3(cos(theta)*radius*(1-0.18*t),height*t,sin(theta)*radius*(1-0.18*t)))
			for index in [0,2,1,0,3,2]:surface.add_vertex(vertices[index])
	surface.generate_normals();return surface.commit()

static func vault_height(x:float)->float:
	return 9+sin(PI*clampf((x+6.6)/13.2,0,1))*2.2

func redraw()->void:
	for j in range(4):
		var direction:=Vector3(cos(TAU*j/4),0,sin(TAU*j/4))
		var start:=centre+Vector3.UP*1.55
		var end:=start+direction*sin(deg_to_rad(angle))*1.2+Vector3.UP*cos(deg_to_rad(angle))*1.2
		for line:MeshInstance3D in [branches[j],guides[j]]:
			var difference:=end-start;var y:=difference.normalized();var x:=Vector3.UP.cross(y).normalized()
			line.position=(start+end)/2;line.basis=Basis(x,y,x.cross(y)).orthonormalized()
			line.mesh.height=difference.length()
		guides[j].visible=show_rule
	readout.text="BRANCH OPENING  %.0f degrees\nHold the point; move it sideways.\nTrigger shows the rule. Geometry, not a load test."%angle

func update_hand()->void:
	if portals.sector!=-4 or not portals.wing.point.held():return
	var displacement:Vector3=portals.wing.point.global_position-portals.wing.eye_position()
	var next:=lerpf(18,55,clampf((displacement.dot(room.global_basis.x)+0.6)/1.2,0,1))
	if absf(next-angle)>0.5:angle=next;redraw()

func trigger(pressed:bool)->void:
	if pressed and portals.sector==-4:show_rule=not show_rule;redraw()
