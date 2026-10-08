extends "res://commons/artifacts/spine_films/film_stage.gd"
const E=preload("res://commons/artifacts/spine_films/early/geometry.gd")
var histories:Array=[]
var fields:Array[Node3D]=[]
var balls:Array=[]
var bonds:Array[MeshInstance3D]=[]
var neighbours:Array[int]=[]
var centre:=78
var time_label:Label3D
var all_pairs:Array[Vector2i]=[]
var lattice_bonds:Array=[]

func _build()->void:
	title_text="A movement reaches its neighbours"
	phases.assign(["One pulse", "The connections carry a difference", "A wave crosses the lattice", "Remove only the coupling"])
	notes.assign(["Both private lattices receive the source instrument's same single pulse.","Eight surrounding neighbours enter each source force calculation.","Each frame uses the existing oscillator solver; the view slows down three seconds.","Left: coupling 1.5. Right: zero. Both still have the same restoring force and damping."])
	source_paths.assign(["res://algorithms/wavefunctions/coupled_oscillator_lattice/coupled_oscillator_lattice.gd"])
	var peaks:Array[float]=[]
	for strength in [1.5,0.0]:
		var source:Node=load(source_paths[0]).new()
		source.set("coupling_strength",strength);source.set("excitation_mode","Pulse")
		var data:Array[Dictionary]=[]
		for x in range(12):
			for z in range(12):data.append({"index":x*12+z,"grid_pos":Vector2(x,z),"position":Vector3((x-6)*0.4,1,(z-6)*0.4),"displacement":0.0,"velocity":0.0,"acceleration":0.0,"phase":0.0})
		source.set("oscillators",data)
		neighbours.assign(source.call("_get_neighbors",Vector2(6,6)))
		if strength>0:
			for i in range(144):
				var adjacent:Array=source.call("_get_neighbors",data[i].grid_pos)
				for j in adjacent:
					if j>i:all_pairs.append(Vector2i(i,j))
		var states:Array[PackedFloat32Array]=[]
		for frame in range(121):
			var state:=PackedFloat32Array()
			for osc in source.get("oscillators"):state.append(float(osc.displacement))
			states.append(state)
			if frame<120:
				for step in range(3):source.call("comparison_step",1.0/120.0)
		histories.append(states);peaks.append(float(source.get("_neighbor_peak")))
		source.free()
		var field:=Node3D.new();display.add_child(field);fields.append(field)
		var field_balls:Array[MeshInstance3D]=[]
		for x in range(12):
			for z in range(12):field_balls.append(E.sphere(field,Vector3((x-5.5)*0.34,1,(z-5.5)*0.34),0.055,E.PINK if strength>0 else E.BLUE))
		balls.append(field_balls)
		var field_bonds:Array[MeshInstance3D]=[]
		for pair in all_pairs:field_bonds.append(E.line(field,field_balls[pair.x].position,field_balls[pair.y].position,Color("73546a") if strength>0 else Color("47687b"),0.006))
		lattice_bonds.append(field_bonds)
	for neighbor in neighbours:bonds.append(E.line(fields[0],balls[0][centre].position,balls[0][neighbor].position,E.GOLD,0.013))
	E.box(display,Vector3(0,0.15,0),Vector3(6.5,0.1,4.5),E.INK)
	time_label=E.label(display,"SOURCE TIME 0.00 s",Vector3(0,3.0,0),E.WHITE,0.15)
	evidence={"oscillators":144,"states_per_field":121,"source_steps":360,"step_seconds":1.0/120.0,"centre_index":centre,"neighbours":neighbours,"coupled_neighbor_peak":peaks[0],"independent_neighbor_peak":peaks[1],"solver":"comparison_step","unused_random_phase_replaced_with_zero":true}
	frame_scene(Vector3(0,1.2,0),9.6,0.45,0.53)

func _draw(time:float)->void:
	var p:=phase_index(time);var u:=phase_progress(time)
	var widen:=smoothstep(0,0.4,u) if p==2 else (1.0 if p==3 else 0.0)
	frame_scene(Vector3(0,1.55,0).lerp(Vector3(0,1.2,0),widen),lerpf(5.2,9.6,widen),_azimuth,0.53)
	time_label.position.y=lerpf(2.65,3.0,widen)
	var sample:=clampi(int(20+u*25),0,120) if p<2 else clampi(int(u*120),0,120)
	for field_index in range(2):
		fields[field_index].visible=field_index==0 or p==3
		fields[field_index].scale=Vector3.ONE*(0.67 if p==3 else 1.0)
		fields[field_index].position=Vector3(-1.6 if field_index==0 else 1.6,0,0) if p==3 else Vector3.ZERO
		var state:PackedFloat32Array=histories[field_index][sample]
		for i in range(144):
			balls[field_index][i].position.y=1+state[i]
			balls[field_index][i].visible=p>1 or i==centre or (p==1 and neighbours.has(i))
		for i in range(all_pairs.size()):
			var pair:Vector2i=all_pairs[i]
			E.line_pose(lattice_bonds[field_index][i],balls[field_index][pair.x].position,balls[field_index][pair.y].position)
			lattice_bonds[field_index][i].visible=p>=2 and field_index==0
	for i in range(bonds.size()):
		E.line_pose(bonds[i],balls[0][centre].position,balls[0][neighbours[i]].position)
		bonds[i].visible=p==1 or p==2
	time_label.text="SOURCE TIME %.2f s"%(sample*0.025)
