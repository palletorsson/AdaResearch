extends "res://commons/artifacts/spine_films/more_structure/structure_stage.gd"
const SOURCE = preload("res://algorithms/fractals/example_8_4_cantor_set_vr.gd")
var bars: Array[MeshInstance3D] = []
var cuts: Array[MeshInstance3D] = []
var records: Array = []
var cut_records: Array = []
var readout: Label3D
func _build() -> void:
	title_text="Keep two thirds; repeat the cut"
	phases.assign(["A whole interval", "The middle third leaves", "Apply the same cut to both survivors", "Five finite rounds of removal"])
	notes.assign(["The hall's original Cantor recursion supplies every retained interval.", "The removed volume moves away to expose the operation. This separation is explanatory staging.", "Every surviving interval supplies the next two calls: each one-third as long.", "There are 32 retained intervals after five removals. A finite model does not demonstrate the infinite set's cardinality."])
	source_paths.assign(["res://algorithms/fractals/example_8_4_cantor_set_vr.gd"])
	var source = SOURCE.new(); source.initial_width=5.4; source.max_depth=5; source.tick="limit"; source.vertical_spacing=.42; source.removal="gone"
	source._build()
	var counts: Array[int]=[0,0,0,0,0,0]
	var lengths: Array[float]=[0,0,0,0,0,0]
	for child in source._sim_root.get_children():
		if child is MeshInstance3D and child.mesh is BoxMesh:
			var depth:=roundi((.3-child.position.y)/.42)
			var length:float=child.mesh.size.x
			records.append({"depth":depth,"x":child.position.x,"length":length})
			counts[depth]+=1; lengths[depth]+=length
			bars.append(add_box(Vector3(child.position.x,2.7-depth*.39,-depth*.24),Vector3(length,.17,.34),TEAL.lerp(CHALK,depth/5.0)))
			if depth<5:
				cut_records.append({"depth":depth,"x":child.position.x,"length":length/3.0})
				cuts.append(add_box(Vector3(child.position.x,2.7-(depth+1)*.39,-(depth+1)*.24),Vector3(length/3.0,.17,.34),PINK))
	evidence={"counts":counts,"lengths":lengths,"initial_width":5.4,"calls":"original _build → _draw_cantor","records":records.duplicate(true),"source_never_entered_tree":true}
	source.free()
	readout=add_label("",Vector3(0,3.25,0),CHALK)
	film_deck();frame_scene(Vector3(0,1.5,-.4),10.3,.24,.2)
func _draw(time:float)->void:
	var phase:=phase_index(time);var u:=phase_progress(time)
	var depth:=0 if phase==0 else (1 if phase==1 else (2 if phase==2 else 2+mini(int(u*4),3)))
	for i in bars.size(): bars[i].visible=records[i].depth<=depth
	for i in cuts.size():
		var d:int=cut_records[i].depth
		cuts[i].visible=(phase==1 and d==0) or (phase==2 and d==1)
		cuts[i].position=Vector3(cut_records[i].x,2.7-(d+1)*.39-u*.55,-(d+1)*.24+u*1.25)
	readout.text="ROUND %d  /  %d INTERVALS  /  RETAINED %.3f m"%[depth,1<<depth,5.4*pow(2.0/3.0,depth)]
