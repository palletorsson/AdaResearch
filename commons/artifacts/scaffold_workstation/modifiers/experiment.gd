extends RefCounted
## Opt-in study document for the existing workstation graph. No global save writes.
## Stable member IDs, immutable base records, three bounded modifiers and a fixed clock.
## The cells rule and rigid motion come from the existing modular apparatus.
const Model=preload("../model.gd")
const Cells=preload("res://commons/modular/mod_cells.gd")
const Motion=preload("res://commons/modular/grid_motion.gd")
var members:Array=[]
var settings:Dictionary={"random":false,"seed":42,"cells":false,"motion":false,"rate":8.0,"period":4.0}
var generation:=0
var elapsed:=0.0
var remainder:=0.0
var cells:=PackedFloat32Array()
var history:Array=[]
var kernel:Node3D

func _init()->void:
	kernel=Cells.new();kernel.n=4
	kernel.p={"birth":[3],"survive":[2,3],"states":2}
	reset()

func _notification(what:int)->void:
	if what==NOTIFICATION_PREDELETE and is_instance_valid(kernel):kernel.free()

static func record_key(r:Dictionary)->String:return JSON.stringify(Model.canonical(r))

static func wall_records()->Array:
	var model:=Model.new()
	# Twenty-five six-port joints, forty one-metre rods, sixteen one-metre quads.
	for y in 5:
		for x in [0,-1,1,-2,2]:
			var p:Array=[x*.5,y*.5,0]
			if p==[0.0,0.0,0]:continue
			assert(model.add(Model.canonical({"kind":"point","at":p}),3))
	for rod in model.candidates("rod_short",3):model.add(rod,3)
	for face in model.candidates("quad",3):
		if face.get("span",1)==.5:model.add(face,3)
	return model.records.duplicate(true)

func import_records(records:Array)->bool:
	var model:=Model.new()
	if not model.restore(records):return false
	members=[{"id":"origin","record":{"kind":"point","at":[0,0,0]}}]
	for i in model.records.size():members.append({"id":"member-%03d"%i,"record":model.records[i].duplicate(true)})
	reset();history.clear();return true

func records()->Array:
	# Snapshots may reorder the member list; rebuild dependency order without changing IDs.
	var pending:Array=[];var model:=Model.new()
	for member in members:
		if member.id!="origin":pending.append(member.record.duplicate(true))
	if model.restore(pending):return model.records.duplicate(true)
	while not pending.is_empty():
		var progress:=false
		for i in range(pending.size()-1,-1,-1):
			if model.add(pending[i],3):pending.remove_at(i);progress=true
		if not progress:return []
	return model.records.duplicate(true)

func id_for(record:Dictionary)->String:
	var key:=record_key(record)
	for member in members:
		if record_key(member.record)==key:return str(member.id)
	return ""

func cell_index(record:Dictionary)->int:
	if record.kind!="quad" or record.plane!=[0,1] or record.get("span",1)!=.5:return -1
	var x:=roundi((float(record.at[0])+1)*2)
	var y:=roundi(float(record.at[1])*2)
	return y*4+x if x>=0 and x<4 and y>=0 and y<4 else -1

func reset()->void:
	generation=0;elapsed=0;remainder=0
	cells.resize(16);cells.fill(0)
	for y in [0,1,2]:cells[y*4+1]=1

func step()->void:
	cells=kernel._generation(cells);generation+=1

func advance(delta:float)->void:
	if not is_finite(delta) or delta<0:return
	elapsed+=delta
	if not settings.cells:return
	remainder+=delta
	var interval:float=1.0/float(settings.rate)
	# Keep the fractional time; rules read the previous state once per generation.
	while remainder+1e-9>=interval:
		remainder=maxf(0,remainder-interval);step()

func change(key:String,value:Variant)->bool:
	if not settings.has(key):return false
	var proposal:Dictionary=snapshot();proposal.settings[key]=value
	var before:=snapshot()
	if not restore(proposal):return false
	history.append(before)
	if history.size()>32:history.pop_front()
	return true

func undo()->bool:
	if history.is_empty():return false
	return restore(history.pop_back())

func assembly_pose()->Transform3D:
	var offset:=Vector3.ZERO
	if settings.random:
		var rng:=RandomNumberGenerator.new();rng.seed=int(settings.seed)^0x531
		offset.x=(int(rng.randi()%3)-1)*2.0 # Canonical metres, a legal whole-module location.
	var motion:Dictionary={"enabled":settings.motion,"period":settings.period,"phase":0.0,"curve":"sine","wait":0.0,
		"pivot":[0,2,0],"travel":[0,0,1],"turn":[0,25,0],"scale":[1,1,1],"frame":"local","order":"TRS"}
	var part:Dictionary={"cell":[0,0,0],"rotation":[0,0,0],"mirror":[1,1,1],"motion":motion}
	return Transform3D(Basis.IDENTITY,offset)*Motion.pose(part,{"columns":1,"rows":1,"cell":1},elapsed,{})

func snapshot()->Dictionary:
	return {"version":3,"coordinate_unit_metres":2,"members":members.duplicate(true),"settings":settings.duplicate(true),
		"state":{"generation":generation,"elapsed":elapsed,"remainder":remainder,"cells":Array(cells)}}

func save(path:String)->bool:
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null:return false
	# Preserve the fractional clock exactly, rather than rounding it at each save.
	file.store_string(JSON.stringify(snapshot(),"",true,true));file.close();return true

func restore(document:Dictionary)->bool:
	# Strict and atomic: unknown operations, bad IDs or an invalid graph do not erase state.
	if document.get("version")!=3 or document.get("coordinate_unit_metres")!=2:return false
	var next=document.get("members");var config=document.get("settings");var state=document.get("state")
	if not next is Array or next.is_empty() or next.size()>2049 or not config is Dictionary or not state is Dictionary:return false
	if config.size()!=settings.size() or not settings.keys().all(func(k):return config.has(k)):return false
	for key in ["random","cells","motion"]:
		if not config[key] is bool:return false
	for key in ["seed","rate","period"]:
		if not (config[key] is int or config[key] is float) or not is_finite(float(config[key])):return false
	if float(config.seed)!=roundf(float(config.seed)) or absf(float(config.seed))>2147483647:return false
	if config.rate<.5 or config.rate>16 or config.period<1 or config.period>60:return false
	for key in ["generation","elapsed","remainder"]:
		if not state.has(key) or not (state[key] is int or state[key] is float) or not is_finite(float(state[key])) or float(state[key])<0:return false
	if float(state.generation)!=roundf(float(state.generation)) or float(state.remainder)>=2.0:return false
	if not state.get("cells") is Array or state.cells.size()!=16:return false
	if not state.cells.all(func(v):return v is float or v is int):return false
	if not state.cells.all(func(v):return v==0 or v==1):return false
	var seen:Dictionary={};var shapes:Dictionary={};var normalized:Array=[]
	for member in next:
		if not member is Dictionary or not member.get("id") is String or member.id.is_empty() or seen.has(member.id):return false
		if not member.get("record") is Dictionary:return false
		var record:Dictionary=Model.canonical(member.record)
		if record.is_empty() or shapes.has(record_key(record)):return false
		seen[member.id]=true;shapes[record_key(record)]=true
		normalized.append({"id":member.id,"record":record})
	if not seen.has("origin"):return false
	var origin:Array=normalized.filter(func(m):return m.id=="origin")
	if origin[0].record!={"kind":"point","at":[0,0,0]}:return false
	var old_members:Array=members;members=normalized
	var legal:Array=records()
	if legal.size()!=members.size()-1:members=old_members;return false
	settings=config.duplicate(true);settings.seed=int(settings.seed)
	generation=int(state.generation);elapsed=float(state.elapsed);remainder=float(state.remainder);cells=PackedFloat32Array(state.cells)
	return true
