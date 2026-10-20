extends Node3D
## Borromini-inspired forced perspective, built from ordinary measured geometry.
const B=preload("spatial_builder.gd")
const PALE:=Color("e9e2d5")
const DARK:=Color("191e29")
const GOLD:=Color("f2be64")
var room:Node3D
var source:Node3D
var target:Node3D
var columns:Array[MeshInstance3D]=[]
var portals:Node3D
const FRONT:=2.8
const BACK:=-5.2

func setup(owner_portals:Node3D)->void:
	portals=owner_portals
	room=Node3D.new();add_child(room);room.name="PerspectiveGallery";room.position=Vector3(-32,90,0)
	B.box(room,Vector3(0,-0.2,0),Vector3(14,0.4,12),PALE,true)
	for x in [-7,7]:B.box(room,Vector3(x,2.5,0),Vector3(0.2,5,12),PALE,true)
	B.box(room,Vector3(0,2.5,-6),Vector3(14,5,0.2),DARK,true)
	for x in [-4,4]:B.box(room,Vector3(x,2.5,6),Vector3(6,5,0.2),DARK,true)
	B.box(room,Vector3(0,4,6),Vector3(2,2,0.2),DARK,true)
	for z in range(-5,6):B.box(room,Vector3(0,0.006,z),Vector3(13.7,0.012,0.02),Color("aaa7a0"))
	# Actual taper: 3 m wide / 3.4 m high becomes 0.84 m / 1.3 m.
	quad([Vector3(-1.5,0,FRONT),Vector3(1.5,0,FRONT),Vector3(0.42,0.6,BACK),Vector3(-0.42,0.6,BACK)],PALE)
	quad([Vector3(-1.5,3.4,FRONT),Vector3(-0.42,1.9,BACK),Vector3(0.42,1.9,BACK),Vector3(1.5,3.4,FRONT)],PALE)
	for side in [-1,1]:
		# Both full-height converging walls sustain the axial depth illusion.
		quad([Vector3(side*1.5,0,FRONT),Vector3(side*0.42,0.6,BACK),Vector3(side*0.42,1.9,BACK),Vector3(side*1.5,3.4,FRONT)],DARK)
	for j in range(9):
		var t:=float(j)/8;var scale:=lerpf(1,0.28,t);var z:=lerpf(FRONT,BACK,t)
		var floor_height:=0.6*t;var h:=lerpf(3.4,1.3,t)
		for side in [-1,1]:
			var x:float=side*1.24*scale
			B.box(room,Vector3(x,floor_height+0.08*scale,z),Vector3(0.46,0.16,0.46)*scale,GOLD,true)
			columns.append(B.cylinder(room,Vector3(x,floor_height+h/2,z),0.14*scale,h-0.25*scale,PALE,true))
			B.box(room,Vector3(x,floor_height+h-0.08*scale,z),Vector3(0.46,0.16,0.46)*scale,GOLD)
		B.box(room,Vector3(0,floor_height+h,z),Vector3(2.8*scale,0.12*scale,0.22*scale),GOLD)
		# Transverse bands remain real geometry; no camera or vertex warping.
		B.box(room,Vector3(0,floor_height+0.014,z),Vector3(2.4*scale,0.025,0.07*scale),DARK)
	B.cylinder(room,Vector3(0,0.8,BACK+0.25),0.18,0.4,GOLD,true)
	B.ball(room,Vector3(0,1.13,BACK+0.25),0.13,DARK)
	# An ordinary side walkway reveals the eight-metre construction.
	for j in range(9):
		B.box(room,Vector3(-3.1,0.016,FRONT-j),Vector3(0.5,0.025,0.055),GOLD)
		var mark:=B.text(room,str(j)+" m",Vector3(-3.6,0.04,FRONT-j),12,DARK)
		mark.rotation.x=-PI/2;mark.pixel_size=0.004
	B.cylinder(room,Vector3(0,0.018,4.25),0.45,0.035,GOLD)
	B.text(room,"STAND HERE / THEN WALK BESIDE IT",Vector3(0,3.95,FRONT+0.12),18,GOLD).pixel_size=0.004
	B.text(room,"ENDLESS MUSEUM",Vector3(-4.3,4.25,-5.84),28,PALE).pixel_size=0.004
	B.text(room,"always another room",Vector3(-4.3,3.9,-5.83),16,PALE).pixel_size=0.004
	B.text(room,"EIGHT METRES / A LONGER APPEARANCE",Vector3(-4.3,3.25,-5.82),18,GOLD).pixel_size=0.003
	B.text(room,"The sphere keeps its size.\nThe columns get smaller.\nWalk along the marked side path.",Vector3(-4.3,2.65,-5.81),16,PALE).pixel_size=0.003
	for x in [-4,4]:
		var light:=OmniLight3D.new();room.add_child(light);light.position=Vector3(x,4,1)
		light.omni_range=18;light.light_energy=3
	source=Node3D.new();portals.lobby.add_child(source);source.position=Vector3(-4.65,0,-3.4)
	portals.frame(source,GOLD,"PERSPECTIVE / BORROMINI")
	B.box(source,Vector3(0,1.5,-0.7),Vector3(2.5,3,0.2),DARK,true)
	target=Node3D.new();room.add_child(target);target.position=Vector3(0,0,5.84);target.rotation.y=PI
	portals.frame(target,GOLD,"BACK TO THE LINKED ROOMS")
	room.visible=false

func quad(points:Array,colour:Color)->void:
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in [0,1,2,0,2,3]:surface.add_vertex(points[i])
	surface.generate_normals()
	var mesh:=B.mesh(room,surface.commit(),Vector3.ZERO,colour,true)
	mesh.material_override.cull_mode=BaseMaterial3D.CULL_DISABLED
