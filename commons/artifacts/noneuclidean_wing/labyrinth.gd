extends Node3D
## A finite four-room loop plus a hand-unlocked shortcut. One carried marker.
const B=preload("spatial_builder.gd")
const PALE:=Color("e9e2d5")
const DARK:=Color("191e29")
const GOLD:=Color("f2be64")
const BLUE:=Color("70cddd")
var portals:Node3D
var rooms:Array[Node3D]=[]
var doors:Array[Dictionary]=[]
var pairs:Array[Dictionary]=[]
var source:Node3D
var seal:MeshInstance3D
var gate:MeshInstance3D
var reverse_gate:MeshInstance3D
var shortcut_open:=false
var sign:Label3D

func setup(owner_portals:Node3D)->void:
	portals=owner_portals
	# A east→B north→C west→D south→A. A north→C is a shortcut.
	var used:Array=[["south","east","north","west"],["west","north"],["south","west","east"],["east","south"]]
	for i in range(4):
		var room:=Node3D.new();add_child(room);rooms.append(room)
		room.name="Labyrinth"+str(i);room.position=Vector3(i*16,240,0)
		B.box(room,Vector3(0,-0.2,0),Vector3(8,0.4,8),PALE,true)
		var frames:Dictionary={}
		for edge in ["south","east","north","west"]:
			var wall:=Node3D.new();room.add_child(wall)
			wall.rotation.y={"south":0.0,"east":PI/2,"north":PI,"west":-PI/2}[edge]
			if edge in used[i]:
				for x in [-2.5,2.5]:B.box(wall,Vector3(x,2,4),Vector3(3,4,0.18),DARK,true)
				B.box(wall,Vector3(0,3.5,4),Vector3(2,1,0.18),DARK,true)
				var door:=Node3D.new();wall.add_child(door);door.position=Vector3(0,0,3.84);door.rotation.y=PI
				portals.frame(door,GOLD,"PASSAGE");frames[edge]=door
			else:B.box(wall,Vector3(0,2,4),Vector3(8,4,0.18),DARK,true)
		for z in range(-3,4):B.box(room,Vector3(0,0.008,z),Vector3(7.7,0.016,0.025),Color("aaa7a0"))
		for x in range(-3,4):B.box(room,Vector3(x,0.007,0),Vector3(0.025,0.014,7.7),Color("aaa7a0"))
		B.cylinder(room,Vector3(-1.7,0.55,1.2),0.65,1.1,DARK,true)
		var colour:Color=[GOLD,BLUE,Color("ed78ad"),PALE][i]
		if i==1:B.box(room,Vector3(-1.7,1.7,1.2),Vector3(0.65,0.65,0.65),colour)
		else:
			var torus:=TorusMesh.new();torus.inner_radius=0.45;torus.outer_radius=0.55
			var ring:=B.mesh(room,torus,Vector3(-1.7,1.8,1.2),colour);ring.rotation.x=PI/2
		B.text(room,"ENDLESS MUSEUM",Vector3(0,4.65,-3.82),23,PALE)
		B.text(room,"always another room",Vector3(0,4.28,-3.81),13,PALE)
		B.text(room,"ROOM "+["A","B","C","D"][i],Vector3(-2.4,2.7,-3.8),30,colour).pixel_size=0.007
		B.text(room,["THE MARKER","THE CUBE","ROSE RING","PALE RING"][i],Vector3(-2.4,2.3,-3.79),18,colour).pixel_size=0.005
		var light:=OmniLight3D.new();room.add_child(light);light.position=Vector3(0,3.8,0)
		light.omni_range=12;light.light_energy=3
		room.visible=false;doors.append(frames)
	source=Node3D.new();portals.interiors[1].add_child(source)
	source.position=Vector3(3.4,0,-4.2);portals.frame(source,GOLD,"LABYRINTH / LEAVE A MARK")
	B.box(source,Vector3(0,1.5,-0.7),Vector3(2.5,3,0.2),DARK,true)
	pairs.append({"a":1,"b":-5,"source":source,"target":doors[0].south})
	pairs.append({"a":-5,"b":-6,"source":doors[0].east,"target":doors[1].west})
	pairs.append({"a":-6,"b":-7,"source":doors[1].north,"target":doors[2].south})
	pairs.append({"a":-7,"b":-8,"source":doors[2].west,"target":doors[3].east})
	pairs.append({"a":-8,"b":-5,"source":doors[3].south,"target":doors[0].north})
	pairs.append({"a":-5,"b":-7,"source":doors[0].west,"target":doors[2].east})
	gate=B.box(rooms[0],Vector3(-3.65,1.45,0),Vector3(0.15,2.9,2),DARK,true)
	gate.set_meta("portal_dynamic",true)
	reverse_gate=B.box(rooms[2],Vector3(3.65,1.45,0),Vector3(0.15,2.9,2),DARK,true)
	reverse_gate.set_meta("portal_dynamic",true)
	seal=B.ball(rooms[0],Vector3(-3.5,1.3,0),0.14,GOLD)
	sign=B.text(rooms[0],"SHORTCUT\nBring your held point to the gold seal.",Vector3(-3.45,2.5,0),14,GOLD)
	sign.pixel_size=0.003;sign.rotation.y=PI/2

func show_sector(sector:int)->void:
	for i in range(4):rooms[i].visible=portals.wing.current==0 and sector==-5-i

func update_hand()->void:
	if shortcut_open or portals.sector!=-5 or not portals.wing.point.held():return
	if portals.wing.point.global_position.distance_to(seal.global_position)>0.35:return
	shortcut_open=true
	for barrier in [gate,reverse_gate]:barrier.visible=false;barrier.get_child(0).collision_layer=0
	seal.material_override=B.material(BLUE,true)
	sign.text="SHORTCUT OPEN / A TO C\nThe connection stays open."
