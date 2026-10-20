@tool
extends RefCounted
## Pure editing model. Snapshots include every unexposed field.
var data: Dictionary = {}
var catalog: Dictionary = {}
var frame: Dictionary = {}
var parts: Dictionary = {}
var floor_index := 0
var selected := -1
var revision := ""
var saved := ""
var undo_stack: Array[Dictionary] = []
var redo_stack: Array[Dictionary] = []

func load_source() -> void:
	data=read("res://commons/void/rooms.json")
	catalog=read("res://commons/void/catalog.json")
	frame=read("res://commons/void/layout.json")
	parts=read("res://commons/void/line_parts.json")
	revision=FileAccess.get_sha256("res://commons/void/rooms.json")
	saved=JSON.stringify(data)
	undo_stack.clear();redo_stack.clear();selected=-1

func read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var value = JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}

func floor_data() -> Dictionary:
	return data.floors[floor_index]

func dirty() -> bool:
	return saved!=JSON.stringify(data)

func remember() -> void:
	undo_stack.append(data.duplicate(true));redo_stack.clear()
	if undo_stack.size()>100: undo_stack.pop_front()

func undo() -> void:
	if undo_stack.is_empty(): return
	redo_stack.append(data.duplicate(true));data=undo_stack.pop_back();selected=-1

func redo() -> void:
	if redo_stack.is_empty(): return
	undo_stack.append(data.duplicate(true));data=redo_stack.pop_back();selected=-1

func entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var f := floor_data()
	for kind in ["artifacts","copies","walls","props"]:
		for i in range(f.get(kind,[]).size()):
			var item: Dictionary = f[kind][i]
			result.append({"kind":kind,"index":i,"label":str(item.id),"position":centre(kind,item)})
			if kind in ["artifacts","copies"]:
				var area: String = str(item.artifact) if parts.has(str(item.artifact)) else str(item.artifact).trim_prefix("void_lines_")
				for key in parts.get(area,{}):
					if item.get("config",{}).has("only_parts") and key not in item.config.only_parts: continue
					# Captions are available; their names remain stable in the runtime.
					var placement: Dictionary = item.get("config",{}).get("parts",{}).get(key,parts[area][key])
					var pos: Array = placement.get("position",parts[area][key].position)
					var point := Vector3(float(pos[0]),float(pos[1]),float(pos[2]))*float(item.scale)
					point=point.rotated(Vector3.UP,deg_to_rad(float(item.facing)))
					result.append({"kind":"part","collection":kind,"index":i,"key":key,"area":area,"label":"    "+str(key),"position":centre(kind,item)+Vector2(point.x,point.z)})
	for i in range(f.get("route",[]).size()):
		result.append({"kind":"route","index":i,"label":"Route: "+str(f.route[i].label),"position":vec(f.route[i].position)})
	return result

func vec(pair: Array) -> Vector2:
	return Vector2(float(pair[0]),float(pair[1]))

func centre(kind: String, item: Dictionary) -> Vector2:
	if kind=="walls": return (vec(item.from)+vec(item.to))/2
	return vec(item.get("position",catalog.stations.get(item.get("station",""),[0,0])))

func move_entry(entry: Dictionary, to: Vector2) -> void:
	remember()
	var f := floor_data()
	if entry.kind=="part":
		var item: Dictionary = f[entry.get("collection","artifacts")][entry.index]
		if entry.get("collection","")=="copies" and item.get("config",{}).has("only_parts"):
			item.position=[to.x,to.y]
		var offset: Vector2 = to-centre("artifacts",item)
		var local := Vector3(offset.x,0,offset.y).rotated(Vector3.UP,-deg_to_rad(float(item.facing)))/float(item.scale)
		var placement := part_placement(entry)
		placement.position[0]=local.x;placement.position[2]=local.z
	elif entry.kind=="walls":
		var item: Dictionary = f.walls[entry.index]
		var delta := to-centre("walls",item)
		for key in ["from","to"]:
			var pos := vec(item[key])+delta;item[key]=[pos.x,pos.y]
	else:
		f[entry.kind][entry.index].position=[to.x,to.y]

func part_placement(entry: Dictionary) -> Dictionary:
	var item: Dictionary = floor_data()[entry.get("collection","artifacts")][entry.index]
	if not item.has("config"): item.config={}
	if not item.config.has("parts"): item.config.parts={}
	if not item.config.parts.has(entry.key): item.config.parts[entry.key]={"position":parts[entry.area][entry.key].position.duplicate(),"rotation":parts[entry.area][entry.key].rotation.duplicate()}
	var placement: Dictionary = item.config.parts[entry.key]
	for key in ["position","rotation"]:
		if not placement.has(key): placement[key]=parts[entry.area][entry.key].duplicate()
	return placement

func rotate_entry(entry: Dictionary) -> void:
	remember()
	if entry.kind=="part":
		var placement := part_placement(entry)
		placement.rotation[1]=fposmod(float(placement.rotation[1])+90,360)
	elif entry.kind=="walls":
		var wall: Dictionary = floor_data().walls[entry.index]
		var middle := centre("walls",wall)
		for key in ["from","to"]:
			var offset := (vec(wall[key])-middle).rotated(PI/2);wall[key]=[middle.x+offset.x,middle.y+offset.y]
	elif entry.kind!="route":
		var item: Dictionary = floor_data()[entry.kind][entry.index]
		item.facing=(int(item.facing)+90)%360

func add_wall(a: Vector2,b: Vector2,height: float) -> void:
	if a==b: return
	remember()
	floor_data().walls.append({"id":"partition-"+str(Time.get_ticks_usec()),"from":[a.x,a.y],"to":[b.x,b.y],"height":height,"finish":"unfinished"})

func add_prop(kind: String, at: Vector2) -> void:
	remember()
	if not floor_data().has("props"): floor_data().props=[]
	floor_data().props.append({"id":kind+"-"+str(Time.get_ticks_usec()),"kind":kind,"position":[at.x,at.y],"facing":0,"scale":1})

func add_route(at: Vector2) -> void:
	remember()
	if not floor_data().has("route"): floor_data().route=[]
	floor_data().route.append({"label":"Encounter "+str(floor_data().route.size()+1),"position":[at.x,at.y]})

func erase(entry: Dictionary) -> bool:
	if entry.kind not in ["walls","props","route","copies"]: return false
	remember();floor_data()[entry.kind].remove_at(entry.index);selected=-1
	return true
