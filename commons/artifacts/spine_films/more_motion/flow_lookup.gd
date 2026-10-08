extends "res://commons/artifacts/spine_films/film_stage.gd"
const Kit = preload("res://commons/artifacts/spine_films/middle/film_kit.gd")
const Draw = preload("res://commons/artifacts/spine_films/more_motion/drawing.gd")
var paths: Array[PackedVector3Array] = []
var arrows: Array[Node3D] = []
var heads: Array[Node3D] = []
var trails: Array[MeshInstance3D] = []
var direction_rod: MeshInstance3D
var record: Label3D
var directions: Array[Vector2] = []

func _build() -> void:
	title_text="THE NEXT POSITION IS ANOTHER LOOKUP"
	duration=28.0
	phases.assign(["READ ONE ADDRESS","TAKE SMALL STEPS","READ AGAIN","MANY STARTING PLACES"])
	notes.assign(["The field stays fixed. A position selects one unit direction.","The source moves by direction × speed × elapsed time; no acceleration is stored.","Each new position becomes the address for the next direction.","Three starting positions follow the same held field and leave different records."])
	source_paths.assign(["res://commons/artifacts/flow_field_painter/flow_field_painter.gd"])
	var source=load(source_paths[0]).new()
	source.canvas_size=Vector2(6,4)
	source.particle_speed=.16
	source.field_evolving=false
	source._noise=FastNoiseLite.new()
	source._noise.noise_type=FastNoiseLite.TYPE_PERLIN
	source._noise.frequency=.01
	source._noise.seed=113
	source._im=ImmediateMesh.new()
	for p in [Vector2(-.8,-.5),Vector2(-.3,.2),Vector2(.6,-.6)]:
		source._particles.append({"x":p.x,"y":p.y,"trail":PackedVector2Array(),"color":Color.WHITE})
		paths.append(PackedVector3Array([Vector3(p.x,.55,p.y)]))
	for step in 160:
		directions.append(source.field_direction(Vector2(source._particles[0].x,source._particles[0].y)))
		source._process(.05)
		for i in 3: paths[i].append(Vector3(source._particles[i].x,.55,source._particles[i].y))
	var max_error:=0.0
	var wraps:=0
	for path in paths:
		for i in range(1,path.size()):
			var d:=path[i].distance_to(path[i-1])
			if d>.1: wraps+=1
			else: max_error=maxf(max_error,absf(d-.008))
	add_box(Vector3(0,.02,0),Vector3(6.6,.10,4.6),Color("242d39"))
	for z in range(9):
		for x in range(13):
			var p:=Vector2(-3+x*.5,-2+z*.5)
			var d:Vector2=source.field_direction(p)
			var start:=Vector3(p.x,.2,p.y)
			var tip:=start+Vector3(d.x,0,d.y)*.22
			arrows.append(add_rod(start,tip,.012,Kit.BLUE))
			arrows.append(add_ball(tip,.025,Kit.BLUE))
	source.free()
	for i in 3:
		heads.append(add_ball(paths[i][0],.11,[Kit.GOLD,Kit.PINK,Kit.TEAL][i]))
		trails.append(add_lines(PackedVector3Array(),[Kit.GOLD,Kit.PINK,Kit.TEAL][i]))
	direction_rod=Kit.rod(display,Vector3.ZERO,Vector3.RIGHT,.038,Kit.material(Kit.GOLD,true))
	record=Draw.caption(display,"",Vector3(0,3.2,0))
	evidence={"source_updates":160,"step_seconds":.05,"speed":.16,"maximum_step_error":max_error,"wrapped_steps":wraps,"field_clock":0.0,"private_seed":113,"paths":3}

func _draw(time: float) -> void:
	if paths.is_empty():return
	var p:=phase_index(time)
	var u:=phase_progress(time)
	var index:=0
	if p==1:index=int(u*20)
	if p==2:index=20+int(u*60)
	if p==3:index=80+int(u*80)
	for i in 3:
		heads[i].visible=p==3 or i==0
		heads[i].position=paths[i][index]
		var mesh:=ImmediateMesh.new()
		var pairs:=Draw.path_pairs(paths[i],index+1)
		if not pairs.is_empty():
			mesh.surface_begin(Mesh.PRIMITIVE_LINES)
			for a in pairs:mesh.surface_add_vertex(a)
			mesh.surface_end()
		trails[i].mesh=mesh
		trails[i].visible=p==3 or i==0
	var d:=directions[mini(index,directions.size()-1)]
	Kit.set_rod(direction_rod,paths[0][index],paths[0][index]+Vector3(d.x,0,d.y)*.75)
	record.text="HELD FIELD · SAMPLE %d\n0.008 m PER SOURCE STEP" % index
	record.position=paths[0][index]+Vector3(0,.95,0) if p==1 else Vector3(0,3.2,0)
	if p==1:
		frame_from_position(paths[0][index],paths[0][index]+Vector3(2,3.2,4))
	else:
		frame_from_position(Vector3(0,.6,0),Vector3(6,7.4,9))

func validation() -> Dictionary:
	return {"passed":evidence.maximum_step_error<.00001 and evidence.wrapped_steps==0 and paths[0]!=paths[1],"evidence":evidence}
