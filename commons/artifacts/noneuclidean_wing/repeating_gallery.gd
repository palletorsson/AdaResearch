extends Node3D
## Flat periodic gallery: one physical tile, eight batched visual neighbours.
## Inspired by Manifold Garden's repetition; gravity remains upright here.
const B=preload("spatial_builder.gd")
const PERIOD:=7.68
const EDGE:=PERIOD/2
const PALE:=Color("e9e2d5")
const DARK:=Color("191e29")
const BLUE:=Color("70cddd")
const GOLD:=Color("f2be64")
var portals:Node3D
var room:Node3D
var source:Node3D
var target:Node3D
var echoes:Array[MeshInstance3D]=[]
var laps:=Vector2i.ZERO
var readout:Label3D

func setup(owner_portals:Node3D)->void:
	portals=owner_portals;room=Node3D.new();add_child(room)
	room.name="RepeatingGallery";room.position=Vector3(-32,155,0)
	B.box(room,Vector3(0,-0.2,0),Vector3(PERIOD,0.4,PERIOD),PALE,true)
	# Four matching thresholds; corner blocks leave a two-metre straight path.
	for x in [-2.6,2.6]:
		for z in [-2.6,2.6]:
			B.box(room,Vector3(x,0.18,z),Vector3(1,0.36,1),DARK,true)
			B.cylinder(room,Vector3(x,2.4,z),0.28,4.5,PALE,true)
			B.box(room,Vector3(x,4.6,z),Vector3(1,0.18,1),GOLD)
	for edge in range(4):
		var gate:=Node3D.new();room.add_child(gate);gate.rotation.y=PI/2*edge
		for x in [-1.1,1.1]:B.box(gate,Vector3(x,2.1,EDGE),Vector3(0.16,4.2,0.16),BLUE,true)
		B.box(gate,Vector3(0,4.18,EDGE),Vector3(2.36,0.16,0.16),BLUE)
		# Guard the solid sides rather than allowing an unsupported diagonal exit.
		for x in [-2.48,2.48]:B.box(gate,Vector3(x,1.6,EDGE),Vector3(2.68,3.2,0.1),DARK,true)
		B.box(gate,Vector3(0,0.015,EDGE-0.04),Vector3(2,0.025,0.12),GOLD)
	for i in range(-3,4):
		B.box(room,Vector3(i,0.007,0),Vector3(0.016,0.014,PERIOD),Color("9c9c98"))
		B.box(room,Vector3(0,0.006,i),Vector3(PERIOD,0.012,0.016),Color("9c9c98"))
	B.cylinder(room,Vector3(-1.55,0.65,-1.35),0.55,1.3,DARK,true)
	var torus:=TorusMesh.new();torus.inner_radius=0.65;torus.outer_radius=0.76
	var ring:=B.mesh(room,torus,Vector3(-1.55,2.1,-1.35),GOLD);ring.rotation.x=PI/2
	# Geometry repeats in a finite visible 3x3 patch. Its neighbouring instances
	# have no collision, scripts or independent student objects.
	for original in room.find_children("*","MeshInstance3D",true,false):
		var batched:=MultiMeshInstance3D.new();room.add_child(batched)
		var multi:=MultiMesh.new();multi.transform_format=MultiMesh.TRANSFORM_3D
		multi.mesh=original.mesh;multi.instance_count=8;batched.multimesh=multi
		batched.material_override=original.material_override;var instance:=0
		for x in [-1,0,1]:
			for z in [-1,0,1]:
				if x==0 and z==0:continue
				var pose:Transform3D=room.global_transform.affine_inverse()*original.global_transform
				pose.origin+=Vector3(x*PERIOD,0,z*PERIOD)
				multi.set_instance_transform(instance,pose);instance+=1
	for x in [-1,0,1]:
		for z in [-1,0,1]:
			if x==0 and z==0:continue
			var echo:=MeshInstance3D.new();room.add_child(echo)
			echo.set_meta("portal_view",true)
			echo.mesh=portals.wing.point.get_child(0).mesh
			echo.material_override=portals.point_finish;echo.set_meta("offset",Vector3(x*PERIOD,0,z*PERIOD))
			echoes.append(echo)
	B.text(room,"ENDLESS MUSEUM",Vector3(0,5.2,-EDGE+0.06),30,PALE)
	B.text(room,"always another room",Vector3(0,4.83,-EDGE+0.06),17,PALE)
	B.text(room,"CROSS A GOLD EDGE / KEEP WALKING",Vector3(0,4.48,-EDGE+0.07),17,BLUE).pixel_size=0.004
	readout=B.text(room,"",Vector3(2.4,2.8,-2.55),16,GOLD);readout.pixel_size=0.003
	for x in [-3,3]:
		var light:=OmniLight3D.new();room.add_child(light);light.position=Vector3(x,4.5,0)
		light.omni_range=30;light.light_energy=3
	source=Node3D.new();portals.interiors[0].add_child(source)
	source.position=Vector3(-3.4,0,-4.2);portals.frame(source,BLUE,"REPEATING GALLERY / MANIFOLD")
	B.box(source,Vector3(0,1.5,-0.7),Vector3(2.5,3,0.2),DARK,true)
	target=Node3D.new();room.add_child(target)
	# Return door sits off the two wrap axes, so it never interrupts a lap.
	target.position=Vector3(2,0,1.5);target.rotation.y=PI
	portals.frame(target,BLUE,"BACK TO ROSE / MUSEUM")
	room.visible=false

func tick_wrap()->bool:
	var changed:=false
	if portals.sector==-3:
		var p:Vector3=room.to_local(portals.wing.eye_position())
		var shift:=Vector3.ZERO
		if absf(p.z)<0.9 and absf(p.x)>EDGE:
			var steps:=floori((p.x+EDGE)/PERIOD);shift.x=-steps*PERIOD;laps.x+=steps
		elif absf(p.x)<0.9 and absf(p.z)>EDGE:
			var steps:=floori((p.z+EDGE)/PERIOD);shift.z=-steps*PERIOD;laps.y+=steps
		if shift!=Vector3.ZERO:
			portals.wing.move_together(room.global_basis*shift)
			portals.last_eye=portals.wing.eye_position();changed=true
	# A released hand point beyond an edge folds into the same physical tile.
	if portals.point_sector==-3 and not portals.wing.point.held():
		var p:Vector3=room.to_local(portals.wing.point.global_position)
		if absf(p.z)<0.9:p.x=fposmod(p.x+EDGE,PERIOD)-EDGE
		if absf(p.x)<0.9:p.z=fposmod(p.z+EDGE,PERIOD)-EDGE
		portals.wing.point.global_position=room.to_global(p)
	for echo in echoes:
		echo.visible=portals.point_sector==-3
		echo.position=room.to_local(portals.wing.point.global_position)+echo.get_meta("offset")
	readout.text="EDGE CROSSINGS  X %d / Z %d\nOne live point; repeated views.\nUpright gravity. Flat local distances."%[laps.x,laps.y]
	return changed
