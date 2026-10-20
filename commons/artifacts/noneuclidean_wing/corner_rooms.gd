extends Node3D
## An unbounded numbered walk, held in at most five resident rooms.
## Four right turns restore heading, but never identify two different rooms.
const B = preload("spatial_builder.gd")
const PALE := Color("e9e2d5")
const DARK := Color("191e29")
const COLOURS = [Color("f2be64"),Color("ed78ad"),Color("70cddd"),Color("b8a1ec")]
var owner_portals: Node3D
var entrance: Node3D
var resident: Dictionary = {}
var generated := 0
var high_water := 0
var opened_depth := 0

func setup(portals: Node3D) -> void:
	owner_portals=portals
	entrance=Node3D.new(); portals.lobby.add_child(entrance)
	entrance.name="CornerWalkEntrance"; entrance.position=Vector3(4.65,0,-3.4)
	portals.frame(entrance,COLOURS[0],"AROUND THE CORNER")
	B.box(entrance,Vector3(0,1.5,-0.7),Vector3(2.5,3,0.2),DARK,true)
	B.text(entrance,"Keep turning. Carry the same point.",Vector3(0,3.36,0.04),14,PALE).pixel_size=0.003
	B.box(portals.lobby,Vector3(4.65,0.015,0.1),Vector3(0.055,0.015,6.8),COLOURS[0])

func ensure_neighbours(depth: int) -> void:
	var needed: Array[int]=[0,depth,depth+1]
	if depth>0: needed.append(depth-1)
	# A dropped point keeps its physical room; no state disappears behind you.
	if owner_portals.point_sector>=2: needed.append(owner_portals.point_sector-2)
	var remove: Array=[]
	for old in resident:
		if old not in needed: remove.append(old)
	for old in remove:
		remove_links(old+2)
		resident[old].room.free(); resident.erase(old)
	for number in needed:
		if not resident.has(number): build_room(number)
	connect_pair(-1,2,entrance,resident[0].entry)
	for number in resident:
		if resident.has(number+1):
			connect_pair(number+2,number+3,resident[number].exit,resident[number+1].entry)
	high_water=maxi(high_water,resident.size())
	opened_depth=maxi(opened_depth,depth)

func remove_links(sector: int) -> void:
	for i in range(owner_portals.links.size()-1,3,-1):
		var link: Dictionary=owner_portals.links[i]
		if link.from==sector or link.to==sector:
			link.view.free(); link.writer.free(); owner_portals.links.remove_at(i)

func connect_pair(a: int, b: int, source: Node3D, target: Node3D) -> void:
	for link in owner_portals.links:
		if link.from==a and link.to==b: return
	for direction in range(2):
		var link := {"from":a if direction==0 else b,"to":b if direction==0 else a,
			"source":source if direction==0 else target,"target":target if direction==0 else source}
		# Reuse references of removed links, never collide with a resident writer.
		var reference := 20
		var used: Array=[]
		for present in owner_portals.links: used.append(present.get("reference",0))
		while reference in used: reference+=1
		link.reference=reference
		owner_portals.links.append(link); owner_portals.build_view(link,reference)

func show_sector(sector: int) -> void:
	for number in resident:
		resident[number].room.visible=owner_portals.wing.current==0 and sector==number+2

func build_room(number: int) -> void:
	var slots: Array=[]
	for data in resident.values(): slots.append(data.slot)
	var slot := 0
	while slot in slots: slot+=1
	var room := Node3D.new(); add_child(room)
	room.name="CornerRoom%04d"%(number+1)
	room.position=Vector3(slot*24,125,0)
	room.rotation.y=-PI/2*(number%4)
	var colour: Color=COLOURS[number%4]
	B.box(room,Vector3(0,-0.2,0),Vector3(12,0.4,12),PALE,true)
	# Entry on the south wall, exit on the east wall: a physical right turn.
	for pos in [Vector3(-6,2,0),Vector3(0,2,-6)]:
		B.box(room,pos,Vector3(0.2,4,12) if pos.x==-6 else Vector3(12,4,0.2),DARK,true)
	for x in [-3.5,3.5]: B.box(room,Vector3(x,2,6),Vector3(5,4,0.2),PALE,true)
	for z in [-3.5,3.5]: B.box(room,Vector3(6,2,z),Vector3(0.2,4,5),PALE,true)
	B.box(room,Vector3(0,3.5,6),Vector3(2,1,0.2),PALE,true)
	B.box(room,Vector3(6,3.5,0),Vector3(0.2,1,2),PALE,true)
	# The solid inner room occludes the next threshold from the entrance.
	var core := B.box(room,Vector3(2.5,1.8,2.5),Vector3(3.4,3.6,3.4),DARK,true)
	core.name="BlindCorner"
	B.box(room,Vector3(2.5,3.65,2.5),Vector3(3.5,0.1,3.5),colour)
	for z in range(-5,6): B.box(room,Vector3(0,0.005,z),Vector3(11.7,0.01,0.018),Color("aba9a3"))
	for x in range(-5,6): B.box(room,Vector3(x,0.006,0),Vector3(0.018,0.01,11.7),Color("aba9a3"))
	B.box(room,Vector3(0,0.018,3),Vector3(0.07,0.02,6),colour)
	B.box(room,Vector3(3,0.018,0),Vector3(6,0.02,0.07),colour)
	B.text(room,"ENDLESS MUSEUM",Vector3(-1.5,3.35,-5.84),31,PALE)
	B.text(room,"always another room",Vector3(-1.5,2.96,-5.83),18,PALE)
	B.text(room,"ROOM %04d"%(number+1),Vector3(-1.5,2.28,-5.82),37,colour)
	B.text(room,"Four right turns. You are somewhere else.",Vector3(-1.5,1.8,-5.81),16,PALE)
	B.text(room,"TURN RIGHT  >",Vector3(0,1.35,-1.5),17,colour).pixel_size=0.004
	# A predictable, regenerable landmark; the point itself is never regenerated.
	B.cylinder(room,Vector3(-3.2,0.55,-2),0.8,1.1,DARK,true)
	B.cylinder(room,Vector3(-3.2,1.11,-2),0.83,0.045,colour)
	for j in range(1+number%4):
		var torus := TorusMesh.new(); torus.inner_radius=0.63; torus.outer_radius=0.7
		var ring := B.mesh(room,torus,Vector3(-3.2,1.8+j*0.42,-2),colour)
		ring.rotation.x=PI/2
	B.cylinder(room,Vector3(-1.4,0.45,1.8),0.32,0.9,DARK,true)
	B.text(room,"YOUR POINT",Vector3(-1.4,0.7,2.14),10,PALE).pixel_size=0.003
	for x in [-4.3,3.8]:
		var light := OmniLight3D.new(); room.add_child(light)
		light.position=Vector3(x,3.7,-2.8); light.omni_range=16; light.light_energy=2.5
	# Open roof keeps the museum sky; beams give the room a clear human scale.
	for z in [-4,0,4]: B.box(room,Vector3(0,4,z),Vector3(12,0.12,0.16),colour)
	var entry := Node3D.new(); room.add_child(entry)
	entry.position=Vector3(0,0,5.84); entry.rotation.y=PI
	var exit := Node3D.new(); room.add_child(exit)
	exit.position=Vector3(5.84,0,0); exit.rotation.y=-PI/2
	owner_portals.frame(entry,COLOURS[(number+3)%4],"BACK / MUSEUM" if number==0 else "BACK / %04d"%number)
	owner_portals.frame(exit,colour,"NEXT / %04d"%(number+2))
	resident[number]={"room":room,"entry":entry,"exit":exit,"slot":slot}
	room.visible=false; generated+=1
