extends RefCounted
## Shared route costs from the existing FlowGrid. No neighbour reads.
const Grid = preload("res://algorithms/pathfinding/flow_field/FlowGrid.gd")
const COUNT := 24
const SPEED := 1.6
const ACCEL := 6.0
const ISLAND := Rect2(-1.0,-2.5,2.0,5.0)
var grid = Grid.new(31,23,.5)
var positions:Array[Vector3]=[]
var velocities:Array[Vector3]=[]
var waypoints:Array[Vector3]=[]
var arrived:Array[bool]=[]
var route := 0
var rebuilds := 0
var ticks := 0
var target := Vector3(-5.5,0,0)

func _init()->void:
	for z in range(grid.height):
		for x in range(grid.width):
			var p:Vector3=grid.grid_to_world(x,z)
			if x==0 or z==0 or x==grid.width-1 or z==grid.height-1 or ISLAND.grow(.18).has_point(Vector2(p.x,p.z)):
				grid.set_cost(x,z,255)
	for i in range(COUNT):
		positions.append(slot(i));velocities.append(Vector3.ZERO);waypoints.append(slot(i));arrived.append(true)
	_rebuild()

func slot(i:int)->Vector3:
	return target+Vector3((i%4-1.5)*.43,0,(i/4-2.5)*.43)

func _rebuild()->void:
	var cell:Vector2i=grid.world_to_grid(target)
	grid.calculate_flow_field(cell.x,cell.y)
	# Cardinal steps avoid the table's diagonal corner cutting. Keep its costs.
	for z in range(grid.height):
		for x in range(grid.width):
			var index:int=z*grid.width+x
			var best:int=grid.integration_field[index];var direction:=Vector2.ZERO
			for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
				var n:Vector2i=Vector2i(x,z)+offset
				if n.x<0 or n.y<0 or n.x>=grid.width or n.y>=grid.height:continue
				var cost:int=grid.integration_field[n.y*grid.width+n.x]
				if cost<best:best=cost;direction=Vector2(offset)
			grid.vector_field[index]=direction
	rebuilds+=1

func set_route(next:int)->void:
	next=clampi(next,-1,1)
	if next==route:return
	route=next;target=Vector3(-5.5,0,0) if route==0 else Vector3(5.5,0,route*3.75)
	_rebuild()
	for i in range(COUNT):
		arrived[i]=false
		var c:Vector2i=grid.world_to_grid(positions[i]);waypoints[i]=grid.grid_to_world(c.x,c.y)

func valid(p:Vector3)->bool:
	# Agent display radius is .17 m; keep it clear of the island and perimeter.
	if absf(p.x)>7.08 or absf(p.z)>5.08:return false
	return not ISLAND.grow(.18).has_point(Vector2(p.x,p.z))

func step(dt:float)->void:
	for i in range(COUNT):
		if arrived[i]:continue
		var p:=positions[i]
		var landing:bool=p.x*target.x>0 and absf(p.x)>4.0 and absf(p.z-target.z)<2.0
		if landing:waypoints[i]=slot(i)
		elif p.distance_to(waypoints[i])<.06:
			var c:Vector2i=grid.world_to_grid(p)
			var v:Vector3=grid.get_vector(p)
			waypoints[i]=grid.grid_to_world(c.x+roundi(v.x),c.y+roundi(v.z))
		var delta:=waypoints[i]-p
		var desired:Vector3=delta.normalized()*minf(SPEED,delta.length()*5.0)
		velocities[i]=velocities[i].move_toward(desired,ACCEL*dt)
		var candidate:=p+velocities[i]*dt
		if valid(candidate):positions[i]=candidate
		else:velocities[i]=Vector3.ZERO
		if landing and positions[i].distance_to(slot(i))<.025:
			positions[i]=slot(i);velocities[i]=Vector3.ZERO;arrived[i]=true
	ticks+=1
