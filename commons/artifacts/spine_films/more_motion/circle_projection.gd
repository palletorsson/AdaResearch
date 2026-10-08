extends "res://commons/artifacts/spine_films/film_stage.gd"
const Kit = preload("res://commons/artifacts/spine_films/middle/film_kit.gd")
const Draw = preload("res://commons/artifacts/spine_films/more_motion/drawing.gd")
var samples:PackedVector3Array
var helices:PackedVector3Array
var circle_points:PackedVector3Array
var steps:Array[Node3D]=[]
var flat_meshes:Array[Mesh]=[]
var helix_meshes:Array[Mesh]=[]
var head:MeshInstance3D
var rod:MeshInstance3D
var sine_rod:MeshInstance3D
var witness:MeshInstance3D
var records:Label3D
const ORIGIN=Vector3(-3,1.6,0)

func _build() -> void:
	title_text="A TURN LEAVES ITS COORDINATES"
	duration=28
	phases.assign(["TURN A RADIUS","KEEP ITS HEIGHT","A RECORD OF HEIGHTS","KEEP THE OTHER COORDINATE"])
	notes.assign(["The original circle updater places the endpoint at cosine and sine.","The vertical projection reads its height. The arm keeps the same length.","The original bridge generator stores that sine value at each advancing sample.","The source's helix option also keeps cosine in depth. These same samples now occupy space."])
	source_paths.assign(["res://algorithms/wavefunctions/unit_circle/UnitCircle.gd"])
	var source=load(source_paths[0]).new()
	source.samples_per_cycle=81;source.num_cycles=1;source.radius=1.1;source.start_x=-1.5;source.wave_length=5.2;source.enable_collision=false;source.platform_size=Vector3(.06,.06,.28)
	source._create_rotator();source._create_projection_lines()
	for i in 81:
		var theta:=float(i)/80*TAU
		source.angle=theta;source._update_rotator_and_indicators()
		circle_points.append(source.rotating_point.position)
		source.correspondence="both";source._create_bridge_step(theta,i)
		var node:Node3D=source.get_child(source.get_child_count()-1)
		samples.append(node.position+Vector3(0,1.6,0))
		source.remove_child(node);display.add_child(node);steps.append(node)
		flat_meshes.append(node.get_child(0).mesh)
		source.correspondence="helix";source._create_bridge_step(theta,i)
		var helix:Node3D=source.get_child(source.get_child_count()-1)
		helix_meshes.append(helix.get_child(0).mesh)
		helices.append(helix.position+Vector3(0,1.6,0))
	var points:=PackedVector3Array()
	for i in range(1,circle_points.size()):points.append_array(PackedVector3Array([ORIGIN+circle_points[i-1],ORIGIN+circle_points[i]]))
	add_lines(points,Kit.WHITE)
	add_rod(ORIGIN-Vector3.RIGHT*1.3,ORIGIN+Vector3.RIGHT*1.3,.012,Kit.BLUE)
	add_rod(ORIGIN-Vector3.UP*1.3,ORIGIN+Vector3.UP*1.3,.012,Kit.BLUE)
	head=add_ball(ORIGIN+circle_points[0],.10,Kit.GOLD)
	rod=Kit.rod(display,ORIGIN,head.position,.028,Kit.material(Kit.GOLD,true))
	sine_rod=Kit.rod(display,ORIGIN,head.position,.028,Kit.material(Kit.PINK,true))
	witness=Kit.rod(display,head.position,samples[0],.012,Kit.material(Kit.TEAL,true))
	records=Draw.caption(display,"",Vector3(.3,3.35,0))
	add_box(Vector3(0,.15,0),Vector3(9,.10,3.6),Color("242c35"))
	var error:=0.0
	for i in samples.size():error=maxf(error,absf(samples[i].y-1.6-circle_points[i].y))
	evidence={"sample_count":samples.size(),"height_projection_error":error,"radius":source.radius,"source_correspondences":["both","helix"],"helix_depth_span":2.2}
	source.free()

func _draw(time:float) -> void:
	if steps.is_empty():return
	var p:=phase_index(time);var u:=phase_progress(time)
	var index:=int(u*80)
	if p==0:index=int(u*20)
	if p==1:index=20+int(u*20)
	head.position=ORIGIN+circle_points[index]
	Kit.set_rod(rod,ORIGIN,head.position)
	Kit.set_rod(sine_rod,Vector3(head.position.x,ORIGIN.y,0),head.position)
	sine_rod.visible=p>=1 and sine_rod.visible
	Kit.set_rod(witness,head.position,samples[index] if p<3 else helices[index])
	witness.visible=p>=2
	for i in steps.size():
		steps[i].get_child(0).mesh=helix_meshes[i] if p==3 else flat_meshes[i]
		steps[i].visible=p>=2 and (i<=index or p==3)
		steps[i].position=samples[i].lerp(helices[i],smoothstep(0,.6,u) if p==3 else 0.0)
	records.text="ONE RADIUS · ONE HEIGHT" if p<2 else ("y = sine" if p==2 else "y = sine · z = cosine")
	frame_scene(Vector3(0,1.6,0),13.4,.15 if p<3 else .15+u*.45,.20)

func validation() -> Dictionary:
	var error:=0.0
	for i in helices.size():error=maxf(error,absf(helices[i].z-circle_points[i].x))
	return {"passed":evidence.height_projection_error<.00001 and error<.00001 and samples.size()==81,"evidence":evidence}
