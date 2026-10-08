extends "res://commons/artifacts/spine_films/more_structure/structure_stage.gd"
const SOURCE=preload("res://algorithms/proceduralgeneration/hybrid_complex/metaballgenerator/metaballgenerator.gd")
var surfaces:Array[ArrayMesh]=[]
var fields:Array[PackedFloat32Array]=[]
var separations:Array[float]=[]
var live:MeshInstance3D
var sources:Array[MeshInstance3D]=[]
var components:Array[MeshInstance3D]=[]
var samples:Array[MeshInstance3D]=[]
var readout:Label3D
var sample_records:Array=[]
var sample_marker:MeshInstance3D
var value_bars:Array[MeshInstance3D]=[]
var value_labels:Array[Label3D]=[]
var sampling_panel:Node3D
func _build()->void:
	title_text="Two contributions become one boundary"
	phases.assign(["Each source contributes a field", "Add their values at the same sample", "Extract one threshold from the sum", "Move the sources; the neck opens"])
	notes.assign(["The actual generator supplies inverse-square fields. The pale spheres are each source's individual threshold surface.","A sample stores a number, not membership in a named ball. The two contributions are added before extraction.","The native project marching-cubes routine extracts field = 1 from the sum. This differs from a Boolean union of spheres.","Only the distance changes. These are 21 finite mesh samples of the original generator, replayed independently of the museum."])
	source_paths.assign(["res://algorithms/proceduralgeneration/hybrid_complex/metaballgenerator/metaballgenerator.gd"])
	var source=SOURCE.new();source.grid_size=Vector3i(32,24,24);source.cell_size=.2;source.iso_level=1;source.kernel="inverse_square";source.array_mesh=ArrayMesh.new()
	source.setup_marching_cubes_tables();source._precompute_grid_positions()
	var rng:=RandomNumberGenerator.new();rng.seed=113
	var first=SOURCE.Metaball.new(Vector3(-1.4,0,0),1.0,.7,rng)
	var second=SOURCE.Metaball.new(Vector3(1.4,0,0),1.0,.7,rng)
	var single_fields:Array[PackedFloat32Array]=[]
	for mb in [first,second]:
		source.metaballs.clear();source.metaballs.append(mb);source._update_influence_radii();source.generate_mesh();single_fields.append(source.field_values.duplicate())
		source.array_mesh=ArrayMesh.new()
	source.metaballs.clear();source.metaballs.append(first);source.metaballs.append(second)
	var counts:Array[int]=[]
	for sample in 21:
		var separation:=lerpf(2.8,.9,float(sample)/20)
		first.position=Vector3(-separation*.5,0,0);second.position=Vector3(separation*.5,0,0)
		source._update_influence_radii();source.generate_mesh()
		surfaces.append(source.array_mesh.duplicate(true));fields.append(source.field_values.duplicate());separations.append(separation)
		counts.append(source.array_mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX].size()/3)
	var sum_error:=0.0
	for i in fields[0].size():sum_error=maxf(sum_error,absf(fields[0][i]-single_fields[0][i]-single_fields[1][i]))
	for x in range(6,27):
		var index:int=15*32*24+12*32+x
		sample_records.append({"position":Vector3(source.grid_positions_x[x],0,source.grid_positions_z[15]),"first":single_fields[0][index],"second":single_fields[1][index],"sum":fields[0][index]})
	evidence={"sample_records":sample_records.duplicate(true),"mesh_samples":surfaces.size(),"grid":[32,24,24],"cell_size":.2,"iso_level":1.0,"source_count":2,"triangle_counts":counts,"sum_error":sum_error,"separations":separations.duplicate(),"source_calls":["_precompute_grid_positions","_update_influence_radii","generate_mesh"],"private_rng_seed":113,"source_never_entered_tree":true}
	source.free()
	live=add_mesh(surfaces[0],TEAL,Vector3(0,1.6,0))
	for side in [-1,1]:
		sources.append(add_ball(Vector3(side*1.4,1.6,0),.10,GOLD))
		components.append(add_ball(Vector3(side*1.4,1.6,0),.7,Color(PINK,.22)))
	for record:Dictionary in sample_records:
		samples.append(add_ball(record.position+Vector3(0,1.6,0),.035,SLATE))
	sample_marker=add_ball(Vector3.ZERO,.095,CHALK)
	sampling_panel=film_group()
	for i in 3:
		value_bars.append(add_box(Vector3((i-1)*1.25,.5,1.85),Vector3(.32,1,.32),[PINK,GOLD,TEAL][i],sampling_panel))
		value_labels.append(add_label("",Vector3((i-1)*1.25,.15,2.0),CHALK,sampling_panel))
	add_rod(Vector3(-1.7,1.10,1.85),Vector3(1.7,1.10,1.85),.015,CHALK,sampling_panel)
	add_label("THRESHOLD 1",Vector3(0,1.28,1.85),CHALK,sampling_panel)
	readout=add_label("",Vector3(0,3.22,0),CHALK)
	film_deck();frame_scene(Vector3(0,1.55,0),10.4,.24,.23)
func _draw(time:float)->void:
	var phase:=phase_index(time);var u:=phase_progress(time)
	var sample:=mini(int(u*20),20) if phase==3 else 0
	live.mesh=surfaces[sample];live.visible=phase>=2
	for i in 2:
		var x:float=(i*2-1)*separations[sample]*.5
		sources[i].position=Vector3(x,1.6,0);components[i].position=sources[i].position;components[i].visible=phase<3
	for dot in samples:dot.visible=phase==1
	sampling_panel.visible=phase==1;sample_marker.visible=phase==1
	var selected:Dictionary=sample_records[mini(int(u*sample_records.size()),sample_records.size()-1)]
	sample_marker.position=selected.position+Vector3(0,1.6,0)
	var values:Array=[selected.first,selected.second,selected.sum]
	for i in 3:
		var height:float=maxf(.012,float(values[i])*.7)
		value_bars[i].scale.y=height;value_bars[i].position.y=.4+height*.5
		value_labels[i].text=["F₁","F₂","SUM"][i]+" %.2f"%values[i]
	var centre_sum:=2*.49/pow(separations[sample]*.5,2)
	readout.text=("p = (%.1f, 0, %.1f) / %.2f + %.2f = %.2f"%[selected.position.x,selected.position.z,selected.first,selected.second,selected.sum] if phase==1 else "F(p) = F₁(p) + F₂(p)") if phase<2 else "DISTANCE %.2f / MIDPOINT FIELD %.2f / THRESHOLD 1"%[separations[sample],centre_sum]
