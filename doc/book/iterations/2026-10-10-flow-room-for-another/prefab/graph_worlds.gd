extends Node3D
## Concrete comparisons, not measured social/biological datasets.
const Flow = preload("flow_model.gd")
const TreeModel = preload("tree_model.gd")
const DATA = "res://commons/artifacts/graph_worlds/cases.json"
var cases: Array = []
var selected := 6
var phase := 0
var visual: Node3D
var controls: Array[StaticBody3D] = []
var positions: Array[Vector3] = []
var edges: Array = []
var marked: Array[int] = []
var active: Array[int] = []
var note := ""
var evidence: Dictionary = {}
var infected: Array[int] = [0]
var rng := RandomNumberGenerator.new()

class WorldButton extends StaticBody3D:
	var action: Callable
	func pointer_event(event) -> void:
		if event.event_type == 2:action.call()

func _ready() -> void:
	cases = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	for i in range(4):
		var button := WorldButton.new()
		button.position = Vector3(-1.35 + i * 0.9, 0.92, 1.65)
		button.collision_layer=(1<<20)|(1<<22);button.collision_mask=0
		var shape:=BoxShape3D.new();shape.size=Vector3(.8,.2,.08)
		var collision:=CollisionShape3D.new();collision.shape=shape;button.add_child(collision)
		var mesh:=BoxMesh.new();mesh.size=shape.size
		mesh_at(mesh,Vector3.ZERO,Color("a76688"),button)
		words(["PREVIOUS","TRY IT","NEXT","RESET"][i],Vector3(0,0,.06),21,button)
		button.action=[func():select_case(selected-1),act,func():select_case(selected+1),func():select_case(selected)][i]
		add_child(button);controls.append(button)
	select_case(selected)

func select_case(index:int) -> void:
	selected=posmod(index,cases.size());phase=0;infected.assign([0]);rng.seed=140
	rebuild()

func act() -> void:
	if cases[selected].mode=="disease":
		var before:=infected.duplicate()
		for e in edges:
			for pair in [e,[e[1],e[0]]]:
				if pair[0] in before and pair[1] not in infected and rng.randf()<.35:infected.append(pair[1])
	phase+=1;rebuild()

func reach(start:int,links:Array,directed:=false) -> Array[int]:
	var seen:Array[int]=[];var queue:Array[int]=[start]
	while not queue.is_empty():
		var a:int=queue.pop_front()
		if a in seen:continue
		seen.append(a)
		for e in links:
			if e[0]==a and e[1] not in seen:queue.append(e[1])
			if not directed and e[1]==a and e[0] not in seen:queue.append(e[0])
	return seen

func path_to(goal:int,links:Array) -> Array[int]:
	var queue:=[0];var parent:Dictionary={0:-1}
	while not queue.is_empty():
		var a:int=queue.pop_front()
		for e in links:
			var b:int=e[1] if e[0]==a else (e[0] if e[1]==a else -1)
			if b>=0 and not parent.has(b):parent[b]=a;queue.append(b)
	var path:Array[int]=[]
	if not parent.has(goal):return path
	var v:=goal
	while v!=-1:path.push_front(v);v=parent[v]
	return path

func rebuild() -> void:
	if visual!=null:remove_child(visual);visual.queue_free()
	visual=Node3D.new();add_child(visual)
	var spec:Dictionary=cases[selected];var mode:String=spec.mode
	positions.assign([Vector3(-1.5,1,-.6),Vector3(-.7,1,-.7),Vector3(-.7,1,.65),Vector3(.2,1,-.7),Vector3(.2,1,.65),Vector3(1.1,1,-.6),Vector3(1.5,1,.6)])
	edges=[[0,1],[0,2],[1,3],[1,4],[2,5],[2,6]]
	marked.clear();active.clear();evidence.clear();note=""
	var directed:=mode in ["counts","return","flow"]
	var labels:Array=[];var flow_model=null
	match mode:
		"visit":
			var order:=reach(0,edges);marked.assign(order.slice(0,mini(phase+1,order.size())))
			note="Queue visit order: "+str(marked);evidence.visited=marked.duplicate()
		"layout":
			if phase%2==1:
				for i in range(7):positions[i]=Vector3(cos(i*TAU/7)*1.35,1,sin(i*TAU/7)*.85)
			note="Same six trails / seven junctions. Position is not connection.";evidence.edges=edges.duplicate(true)
		"path","future":
			edges=[[0,1],[0,2],[1,3],[2,4],[3,5],[4,5],[5,6]]
			if mode=="path" and phase%2==1:edges.erase([1,3])
			if mode=="future":
				edges.erase([4,5])
				if phase%3>=1:edges.erase([3,5])
				if phase%3==2:edges.append([4,5])
			marked=path_to(6,edges);note="Route: "+str(marked)+(" / unavailable" if marked.is_empty() else "")
			evidence.route=marked.duplicate()
		"counts":
			edges=[[0,1],[0,1],[1,2],[2,3],[2,4],[4,5],[5,6]]
			if phase%2==1:edges.remove_at(0)
			var counts:=[0,0,0,0,0,0,0]
			for e in edges:counts[e[1]]+=1
			for i in range(7):labels.append("%d / %d shares"%[i,counts[i]])
			note="Recorded shares: "+str(edges.size())+". Counts do not establish belief.";evidence.counts=counts
		"return":
			positions.resize(6);edges=[[0,1],[1,2],[2,0],[2,3],[3,4],[4,5],[5,3]]
			if phase%2==1:edges.append([3,2])
			var reversed:Array=[]
			for e in edges:reversed.append([e[1],e[0]])
			var back:=reach(0,reversed,true)
			for v in reach(0,edges,true):
				if v in back:marked.append(v)
			note="Can go AND return from island0: "+str(marked);evidence.mutual=marked.duplicate()
		"tree":
			var tree=TreeModel.new();tree.reset();edges.clear()
			for link in tree.links:edges.append([link.a,link.b])
			for i in range(mini(phase,8)):tree.step()
			active.assign(tree.chosen)
			if phase>=9:active.erase(0)
			if phase>=10:active.append(6)
			var kept:Array=[]
			for i in active:kept.append(edges[i])
			marked=reach(0,kept);note="Tree cost %.1f / reachable %d of7"%[tree.cost(tree.chosen),marked.size()]
			evidence.reached=marked.duplicate();evidence.cost=tree.cost(tree.chosen)
		"flow":
			flow_model=Flow.new();flow_model.reset();edges.clear()
			for link in flow_model.links:edges.append([link.a,link.b])
			for i in range(mini(phase,3)):flow_model.step()
			for i in range(edges.size()):
				if flow_model.flow[edges[i][0]][edges[i][1]]>0:active.append(i)
			note="Allocated: %d crate slots. Pink cancels a previous plan."%flow_model.total
			evidence.total=flow_model.total;evidence.changes=flow_model.changes.duplicate(true)
		"matching":
			positions.assign([Vector3(-1,1,-.65),Vector3(-1,1,.65),Vector3(1,1,-.65),Vector3(1,1,.65)])
			edges=[[0,2],[0,3],[1,2]];active.assign([0] if phase%2==0 else [1,2])
			labels=["maker A","maker B","drill","saw"]
			note="%d compatible pairs / one tool per maker"%active.size();evidence.pairs=active.duplicate()
		"disease":
			edges=[[0,1],[1,2],[1,3],[2,4],[3,5],[4,6],[5,6]];marked.assign(infected)
			note="Round %d / %d infected. New cases transmit next round."%[phase,infected.size()];evidence.infected=infected.duplicate()
		"euler":
			positions.assign([Vector3(-1.5,1,0),Vector3(0,1,-.75),Vector3(0,1,.75),Vector3(1.5,1,0)])
			edges=[[0,1],[0,1],[0,2],[0,2],[0,3],[1,3],[2,3]]
			var degree:=[0,0,0,0]
			for e in edges:degree[e[0]]+=1;degree[e[1]]+=1
			for i in range(4):labels.append("shore%d / degree%d"%[i,degree[i]] if phase>0 else "shore%d"%i)
			note="Four odd degrees: no walk uses every bridge exactly once." if phase>0 else "Try the bridges. Then count the odd degrees."
			evidence.degree=degree
	var ground:=Color("436879") if mode in ["euler","path","return","flow"] else Color("566052")
	box(Vector3(4,.14,2.7),Vector3(0,.77,0),ground)
	for i in range(positions.size()):
		var p:Vector3=positions[i];var kind:String=spec.kind
		if mode=="matching" and i>=2:kind="tool"
		var colour:=Color("e2ac70") if i in marked else Color("dbdaca")
		if mode=="disease":colour=Color("d27695") if i in infected else Color("9ccabf")
		make_object(kind,p,colour,i)
		words(str(i) if labels.is_empty() else labels[i],p+Vector3(0,.64,0),19)
	for i in range(edges.size()):
		var e:Array=edges[i];var a:Vector3=positions[e[0]];var b:Vector3=positions[e[1]]
		var color:=Color("deb77b") if i in active else Color("7faeb1")
		if mode in ["visit","path","future","return"] and e[0] in marked and e[1] in marked:color=Color("e6b579")
		var offset:=Vector3(0,-.06,0)
		if mode in ["euler","counts"]:offset.z=(i%2-.5)*.20
		rod(a+offset,b+offset,color,.025 if mode not in ["euler","path"] else .065)
		if directed:arrow(a+offset,b+offset,color)
		if mode=="flow":
			var amount:int=flow_model.flow[e[0]][e[1]]
			words("%d/%d"%[amount,flow_model.links[i].cap],(a+b)*.5+Vector3.UP*.24,21)
			if amount>0:box(Vector3(.13,.13,.13),a.lerp(b,.4)+Vector3.UP*.07,Color("e4ba72"))
	if mode=="flow":
		for change in flow_model.changes:
			if change.undo:rod(positions[change.a]+Vector3.UP*.34,positions[change.b]+Vector3.UP*.34,Color("ed89bd"),.025)
	words(spec.title,Vector3(0,2.7,-.35),31)
	words(spec.era,Vector3(0,2.51,-.35),19)
	words(spec.action,Vector3(0,2.29,-.35),20)
	words(wrap_text(spec.limit,74),Vector3(0,1.99,-.95),17)
	words(note,Vector3(0,.39,1.15),20)
	evidence.case_id=spec.id;evidence.phase=phase;evidence.edge_count=edges.size()

func wrap_text(s:String,width:int) -> String:
	var lines:PackedStringArray=[];var line:=""
	for word in s.split(" "):
		if line.length()+word.length()+1>width:lines.append(line);line=""
		line+=(" " if not line.is_empty() else "")+word
	lines.append(line);return "\n".join(lines)

func mesh_at(mesh:Mesh,at:Vector3,color:Color,parent:Node=null) -> MeshInstance3D:
	var n:=MeshInstance3D.new();n.mesh=mesh;n.position=at
	var m:=StandardMaterial3D.new();m.albedo_color=color;m.roughness=.6;n.material_override=m
	(parent if parent!=null else visual).add_child(n);return n
func box(size:Vector3,at:Vector3,color:Color) -> MeshInstance3D:
	var m:=BoxMesh.new();m.size=size;return mesh_at(m,at,color)
func ball(radius:float,at:Vector3,color:Color) -> void:
	var m:=SphereMesh.new();m.radius=radius;m.height=radius*2;mesh_at(m,at,color)
func rod(a:Vector3,b:Vector3,color:Color,radius:=.025) -> void:
	if a.distance_to(b)<.001:return
	var m:=CylinderMesh.new();m.top_radius=radius;m.bottom_radius=radius;m.height=a.distance_to(b)
	var n:=mesh_at(m,(a+b)*.5,color);n.quaternion=Quaternion(Vector3.UP,(b-a).normalized())
func arrow(a:Vector3,b:Vector3,color:Color) -> void:
	var m:=CylinderMesh.new();m.top_radius=0;m.bottom_radius=.085;m.height=.17
	var n:=mesh_at(m,a.lerp(b,.7),color);n.quaternion=Quaternion(Vector3.UP,(b-a).normalized())
func words(s:String,at:Vector3,size:int,parent:Node=null) -> void:
	var n:=Label3D.new();n.text=s;n.position=at;n.font_size=size;n.pixel_size=.002
	(parent if parent!=null else visual).add_child(n)
func make_object(kind:String,p:Vector3,color:Color,i:int) -> void:
	match kind:
		"person":
			ball(.095,p+Vector3.UP*.42,color);box(Vector3(.14,.23,.12),p+Vector3.UP*.22,color)
			for x in [-.045,.045]:rod(p+Vector3(x,0,0),p+Vector3(x,.13,0),color,.028)
			rod(p+Vector3(-.14,.13,0),p+Vector3(.14,.3,0),color,.023)
		"ant":
			for z in [-.12,0,.12]:ball(.075,p+Vector3(0,.06,z),Color("342832"))
			for z in [-.1,0,.1]:rod(p+Vector3(-.2,0,z+.05),p+Vector3(0,.06,z),color,.016);rod(p+Vector3(.2,0,z+.05),p+Vector3(0,.06,z),color,.016)
		"phone":
			box(Vector3(.22,.4,.07),p+Vector3.UP*.2,Color("302e42"));box(Vector3(.17,.29,.02),p+Vector3(0,.21,.05),color)
		"boat":
			box(Vector3(.38,.1,.19),p,color);box(Vector3(.14,.13,.13),p+Vector3.UP*.1,Color("b89aa4"))
		"tool":
			box(Vector3(.35,.12,.13),p+Vector3.UP*.17,color);rod(p,p+Vector3.UP*.16,Color("333442"),.045)
			if i==2:rod(p+Vector3(.16,.17,0),p+Vector3(.34,.17,0),color,.018)
		"relay":
			box(Vector3(.38,.1,.3),p,color);rod(p,p+Vector3.UP*.42,color,.02);ball(.09,p+Vector3.UP*.45,Color("e4aa76"))
		_:
			box(Vector3(.38,.09,.33),p-Vector3.UP*.1,Color("bfc6ba"));box(Vector3(.28,.27,.25),p+Vector3.UP*.08,color)
			var roof:=CylinderMesh.new();roof.top_radius=0;roof.bottom_radius=.23;roof.height=.17;roof.radial_segments=4
			mesh_at(roof,p+Vector3.UP*.29,Color("bc8d91"));box(Vector3(.08,.12,.02),p+Vector3(0,.02,.14),Color("4d5662"))
