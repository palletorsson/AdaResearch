extends RefCounted
## A seeded walk grows a connected network; geometry constrains its next choices.
const Model=preload("model.gd")
const DIRECTIONS=[Vector3.RIGHT,Vector3.BACK,Vector3.LEFT,Vector3.FORWARD]
const STEPS=24
const HEADROOM=1.1 # 2.2m envelope: standing XR body plus overhead frame/joint thickness.
var model=Model.new()
var seed_value:=435
var valid:=true
var nodes:Array[Vector3]=[] # Centres of level, 2m-square landings.
var links:Array=[] # Node indices; ramp or flat connection.
var occupied:Array=[] # Per tile: surface bottom and required clear top.
var events:Array=[]
var current:=0

func _init(value:int=435,materialize:bool=true)->void:
	seed_value=value
	var rng:=RandomNumberGenerator.new();rng.seed=value
	var corners=[Vector3(-.5,0,-.5),Vector3(1.5,0,-.5),Vector3(1.5,0,1.5),Vector3(-.5,0,1.5)]
	nodes.append(corners[rng.randi_range(0,3)]);occupy(nodes[0],0)
	for step in STEPS:
		var choices:=extensions(current)
		# The first connection establishes a climb; all subsequent routes are choices.
		if step==0:choices=choices.filter(func(c):return c.rise!=0)
		var neighbours:=adjacent(current)
		var before:=current
		var added:=false
		if not choices.is_empty() and (neighbours.is_empty() or rng.randf()<.72):
			var choice:Dictionary=choices[rng.randi_range(0,choices.size()-1)]
			var destination:Vector3=choice.destination
			var next:int=nodes.find(destination)
			if next<0:
				next=nodes.size();nodes.append(destination);occupy(destination,0)
			if choice.rise!=0:occupy(choice.middle,.5)
			links.append({"a":current,"b":next,"ramp":choice.rise!=0})
			current=next;added=true
		elif not neighbours.is_empty():current=neighbours[rng.randi_range(0,neighbours.size()-1)]
		events.append({"step":step+1,"from":before,"to":current,"added":added,"position":Model.arr(nodes[current]),"rng_after":str(rng.state)})
	if materialize:build()

func adjacent(index:int)->Array:
	var result:Array=[]
	for link in links:
		if link.a==index:result.append(link.b)
		elif link.b==index:result.append(link.a)
	return result

func clear_tile(at:Vector3,rise:float)->bool:
	if at.x<-.5 or at.x>1.5 or at.z<-.5 or at.z>1.5 or at.y<0 or at.y+rise>2:return false
	for tile in occupied:
		if tile.at.x!=at.x or tile.at.z!=at.z:continue
		if at.y<tile.top and at.y+rise+HEADROOM>tile.at.y:return false
	return true

func occupy(at:Vector3,rise:float)->void:
	occupied.append({"at":at,"top":at.y+rise+HEADROOM})

func extensions(index:int)->Array:
	var result:Array=[]
	var at:Vector3=nodes[index]
	for direction in DIRECTIONS:
		for rise in [-.5,0,.5]:
			var destination:Vector3=at+direction*(1 if rise==0 else 2)+Vector3.UP*rise
			var next:int=nodes.find(destination)
			if next in adjacent(index):continue
			if next<0 and not clear_tile(destination,0):continue
			var middle:Vector3=(at+destination)*.5;middle.y=minf(at.y,destination.y)
			if rise!=0 and not clear_tile(middle,.5):continue
			result.append({"destination":destination,"rise":rise,"middle":middle})
	return result

func build()->void:
	for at in nodes:deck(at-Vector3(.5,0,.5))
	for link in links:
		if not link.ramp:continue
		var a:Vector3=nodes[link.a];var b:Vector3=nodes[link.b]
		var low:Vector3=a if a.y<b.y else b
		var high:Vector3=b if a.y<b.y else a
		var base:Vector3=(low+high)*.5;base.y=low.y
		deck(base-Vector3(.5,0,.5))
		var direction:Vector3=high-low;direction.y=0
		var turn:int=1 if direction.x>0 else (3 if direction.x<0 else (0 if direction.z>0 else 2))
		valid=model.add({"kind":"wedge","at":Model.arr(base),"turn":[0,turn,0]},3) and valid

func snapshot()->Dictionary:
	return {"schema":"ada.branching-walk","version":1,"seed":str(seed_value),"rule":"24 connected walk steps; grow or revisit; flat neighbours or supported 1m-rise ramps; 2.2m clearance envelope","nodes":nodes.map(func(p):return Model.arr(p)),"links":links.duplicate(true),"records":model.records.duplicate(true),"events":events.duplicate(true)}

func point(p:Vector3)->void:
	if model.points().has(Model.key(p)):return
	var nearest:Vector3=Vector3.ZERO;var distance:=INF
	for q:Vector3 in model.points().values():
		var d:float=absf(p.x-q.x)+absf(p.y-q.y)+absf(p.z-q.z)
		if d<distance:distance=d;nearest=q
	for axis in 3:
		while absf(nearest[axis]-p[axis])>.01:
			nearest[axis]+=signf(p[axis]-nearest[axis])*.5
			if not model.points().has(Model.key(nearest)):
				valid=model.add({"kind":"point","at":Model.arr(nearest)},3) and valid

func edge(a:Vector3,b:Vector3)->void:
	point(a);point(b)
	if model.edge(a,b):return
	var delta:Vector3=(b-a).normalized()*.5
	while a.distance_to(b)>.01:
		var next:=a+delta;point(next)
		if not model.edge(a,next):
			var found:=false
			for r in model.candidates("rod_short",3):
				if (Model.vec(r.at)==a and Model.vec(r.end)==next) or (Model.vec(r.end)==a and Model.vec(r.at)==next):
					found=model.add(r,3);break
			valid=found and valid
		a=next

func deck(at:Vector3)->void:
	var corners:Array[Vector3]=[at,at+Vector3.RIGHT,at+Vector3(1,0,1),at+Vector3.BACK]
	for i in 4:
		edge(corners[i],corners[(i+1)%4])
		if at.y>0:edge(Vector3(corners[i].x,0,corners[i].z),corners[i])
	for half in 2:
		var r:Dictionary={"kind":"panel","at":Model.arr(at),"plane":[0,2],"half":half}
		if not model.has_record(r):valid=model.add(r,3) and valid

