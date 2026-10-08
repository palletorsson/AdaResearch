extends "res://commons/artifacts/spine_films/film_stage.gd"
const E=preload("res://commons/artifacts/spine_films/early/geometry.gd")
var first:=Vector3.ZERO
var second:=Vector3.ZERO
var opposing:=Vector3.ZERO
var arrows:Array[MeshInstance3D]=[]
var tips:Array[MeshInstance3D]=[]
var body:MeshInstance3D
var trail:Array[MeshInstance3D]=[]
var origin:=Vector3(-1.5,0.85,0)
var velocity_arrow:MeshInstance3D

func _build()->void:
	title_text="A force changes a journey"
	phases.assign(["Two existing forces", "Put their arrows head to tail", "A changing velocity", "Zero force is not zero motion"])
	notes.assign(["The actual combined-forces instrument supplies these vectors.","Translation of the arrows preserves their lengths and directions.","An ideal unit-mass interval: acceleration is the sum; contacts and damping are omitted.","Opposing source forces cancel. The velocity already acquired remains."])
	source_paths.assign(["res://algorithms/vectors/02_vector_addition/CombinedForcesDemo.gd","res://algorithms/vectors/shared/force_containment_base.gd"])
	var source:Node=load(source_paths[0]).new()
	source.set("composition","orthogonal")
	first=source.call("_start_force",0);second=source.call("_start_force",1)
	source.set("composition","opposing")
	opposing=source.call("_start_force",1)
	source.free()
	for c in [E.PINK,E.BLUE,E.GOLD]:
		arrows.append(E.line(display,origin,origin+Vector3.UP,c,0.025))
		var cone:=CylinderMesh.new();cone.top_radius=0;cone.bottom_radius=0.095;cone.height=0.22;cone.radial_segments=16
		tips.append(E.mesh(display,cone,c))
	body=E.sphere(display,origin,0.18,E.WHITE)
	velocity_arrow=E.line(display,origin,origin+Vector3.RIGHT,E.WHITE,0.012)
	for i in range(40):trail.append(E.sphere(display,origin,0.023,E.PINK))
	E.box(display,Vector3(-0.5,0.12,0),Vector3(4.2,0.1,2),E.INK)
	E.label(display,"F1",Vector3(-1.7,3.0,0),E.PINK,0.2)
	E.label(display,"F2",Vector3(-1.1,3.0,0),E.BLUE,0.2)
	E.label(display,"sum",Vector3(-0.4,3.0,0),E.GOLD,0.2)
	evidence={"first":first,"second":second,"opposing":opposing,"sum":first+second,"cancelled":first+opposing,"source_forces":true,"motion_model":"ideal unit mass; no damping or contacts"}
	frame_scene(Vector3(-0.2,1.5,0),6.6,0.3,0.25)

func _draw(time:float)->void:
	var p:=phase_index(time);var u:=phase_progress(time)
	var base:=origin
	var scale_factor:=0.85
	var fa:=first*scale_factor
	var fb:Vector3=(opposing if p==3 else second)*scale_factor
	var b_start:=base+fa*smoothstep(0,1,u) if p==1 else base
	if p>=2:b_start=base+fa
	E.line_pose(arrows[0],base,base+fa)
	E.line_pose(arrows[1],b_start,b_start+fb)
	E.line_pose(arrows[2],base,base+fa+fb)
	for i in range(3):arrows[i].visible=(p>0 or i<2) and (i<2 or (fa+fb).length()>0.0001)
	var ends:=[base+fa,b_start+fb,base+fa+fb]
	var directions:=[fa,fb,fa+fb]
	for i in range(3):
		tips[i].visible=(p>0 or i<2) and directions[i].length()>0.0001
		if tips[i].visible:
			tips[i].position=ends[i]-directions[i].normalized()*0.11
			tips[i].basis=Basis(Quaternion(Vector3.UP,directions[i].normalized()))
	var duration_of_interval:=0.9
	var seconds:=u*duration_of_interval
	var acceleration:=first+second
	var acquired_velocity:=acceleration*duration_of_interval
	var endpoint:=origin+0.5*acceleration*duration_of_interval*duration_of_interval
	body.position=origin
	if p==2:body.position=origin+0.5*acceleration*seconds*seconds
	if p==3:body.position=endpoint+acquired_velocity*seconds
	velocity_arrow.visible=p>=2
	E.line_pose(velocity_arrow,body.position,body.position+(acceleration*seconds if p==2 else acquired_velocity)*0.38)
	velocity_arrow.visible=p>=2
	for i in range(trail.size()):
		var t:=float(i)/float(trail.size()-1)
		trail[i].visible=p>=2 and t<=u
		trail[i].position=origin+0.5*acceleration*pow(t*duration_of_interval,2) if p==2 else endpoint+acquired_velocity*t*duration_of_interval
