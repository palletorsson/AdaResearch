extends "res://commons/artifacts/spine_films/more_structure/structure_stage.gd"
const SOURCE=preload("res://algorithms/graphtheory/minimumspanningtree/mst_visualization.gd")
var records:Array=[]
var decisions:Array=[]
var arches:Array[Node3D]=[]
var node_meshes:Array[MeshInstance3D]=[]
var readout:Label3D
var source_positions:PackedVector3Array=[]
var accepted_keys:Array=[]
func _build()->void:
	title_text="Keep a connection; refuse a cycle"
	phases.assign(["A graph offers more than one route", "Order its edges by their cost", "The cheapest edge must join separate sets", "Nine edges keep ten vertices connected"])
	notes.assign(["The hall's actual seeded graph supplies positions, edges and distance weights.","Arch height displays edge cost; it is explanatory geometry, not a new weight calculation.","The original union-find answers whether two ends already belong to the same set. Pink closes a cycle; teal joins sets.","This is a minimum spanning tree, not a shortest route between two selected vertices. Grey edges were unnecessary for this objective."])
	source_paths.assign(["res://algorithms/graphtheory/minimumspanningtree/mst_visualization.gd"])
	var source=SOURCE.new();source.initialize_graph()
	for v in source.vertices:source_positions.append(v.position)
	var ordered:Array=source.edges.duplicate(true);ordered.sort_custom(func(a,b):return a.weight<b.weight)
	var accepted:=0;var total:=0.0;var rejected:=0
	for edge in ordered:
		var keep:bool=source.find_union_find(edge.from)!=source.find_union_find(edge.to)
		if keep:source.union_union_find(edge.from,edge.to);accepted+=1;total+=edge.weight;accepted_keys.append(key(edge))
		else:rejected+=1
		decisions.append({"edge":edge.duplicate(true),"accepted":keep,"total":total,"count":accepted})
		if accepted==source.graph_size-1:break
	source._solve_mst_now()
	var source_keys:Array=[]
	for edge in source.mst_edges:source_keys.append(key(edge))
	var min_p:=source_positions[0];var max_p:=min_p
	for v in source_positions:min_p=min_p.min(v);max_p=max_p.max(v)
	var centre:Vector3=(min_p+max_p)*.5
	for i in source_positions.size():
		var p:Vector3=pose(source_positions[i]-centre)
		node_meshes.append(add_ball(p,.11,CHALK));add_label(str(i),p+Vector3(0,-.21,0),CHALK)
	for edge in ordered:
		records.append(edge.duplicate(true))
		var a:=pose(source_positions[edge.from]-centre);var b:=pose(source_positions[edge.to]-centre)
		var group:=film_group();arches.append(group)
		var path:=PackedVector3Array()
		for k in 13:
			var u:=float(k)/12;path.append(a.lerp(b,u)+Vector3(0,sin(u*PI)*edge.weight*.14,0))
		film_path(path,SLATE,group,.022)
		var label:=add_label("%.1f"%edge.weight,path[6]+Vector3(0,.16,0),GOLD,group);label.font_size=23
	evidence={"vertices":source.graph_size,"edges":source.edges.size(),"accepted":accepted,"rejected_before_complete":rejected,"source_cost":source.mst_cost,"observer_cost":total,"accepted_keys":accepted_keys.duplicate(),"source_keys":source_keys,"seed":source.BUILD_SEED,"source_calls":["initialize_graph","find_union_find","union_union_find","_solve_mst_now"],"source_never_entered_tree":true}
	source.free();readout=add_label("",Vector3(0,3.65,0),CHALK)
	film_deck();frame_scene(Vector3(0,1.35,0),12.0,.32,.36)
func key(edge:Dictionary)->String:return "%d:%d"%[mini(edge.from,edge.to),maxi(edge.from,edge.to)]
func pose(p:Vector3)->Vector3:return Vector3(p.x*.34,.36+p.z*.30,p.y*.27)
func _draw(time:float)->void:
	var phase:=phase_index(time);var u:=phase_progress(time)
	var current:=mini(int(u*decisions.size()),decisions.size()-1)
	for i in arches.size():
		var colour:=SLATE;var visible:=true
		if phase==0:visible=i<=int(u*arches.size())
		elif phase==1:colour=GOLD if i==mini(int(u*records.size()),records.size()-1) else SLATE
		elif phase==2:
			for j in current+1:
				if key(records[i])==key(decisions[j].edge):colour=TEAL if decisions[j].accepted else PINK
		else:visible=accepted_keys.has(key(records[i]));colour=TEAL
		arches[i].visible=visible
		for child in arches[i].get_children():
			if child is MeshInstance3D:child.material_override.albedo_color=colour
	readout.text="10 VERTICES / %d AVAILABLE EDGES"%records.size() if phase<2 else ("EDGE %d–%d / %s"%[decisions[current].edge.from,decisions[current].edge.to,"JOIN" if decisions[current].accepted else "CYCLE: REFUSE"] if phase==2 else "9 KEPT / TOTAL COST %.2f"%evidence.source_cost)
