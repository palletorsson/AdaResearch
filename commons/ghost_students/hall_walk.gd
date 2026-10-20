extends Node
## A bounded, floor-checked approach route. No teleport fallback or player body.
signal ended(result: Dictionary)
const CELL=0.35
const PACE=0.75
var actor: Node3D
var destination: Node3D
var walking:=false
var requested:=false
var points: Array[Vector3]=[]
var cursor:=0
var floor_y:=0.0
var receipt: Dictionary={}
var capsule:=CapsuleShape3D.new()

func _init() -> void:
	capsule.radius=0.22;capsule.height=1.65

func begin(student: Node3D, target: Node3D) -> void:
	actor=student;destination=target;requested=true

func cancel(reason: String) -> void:
	if not walking and not requested: return
	requested=false;walking=false;receipt.status=reason;ended.emit(receipt)

func clear_at(point: Vector3) -> bool:
	return inspect_at(point).clear

func inspect_at(point: Vector3) -> Dictionary:
	var space:=actor.get_world_3d().direct_space_state
	# Jolt can return a side normal exactly at a tiled floor seam. Require actual
	# support on three of five nearby probes, rather than treating seams as walls.
	var supported:=0
	for offset in [Vector3.ZERO,Vector3(0.035,0,0.035),Vector3(-0.035,0,0.035),Vector3(0.035,0,-0.035),Vector3(-0.035,0,-0.035)]:
		var ray:=PhysicsRayQueryParameters3D.create(point+offset+Vector3.UP*0.35,point+offset-Vector3.UP*0.35,1)
		var hit:=space.intersect_ray(ray)
		if not hit.is_empty() and absf(hit.position.y-floor_y)<=0.12 and hit.normal.y>=0.9: supported+=1
	if supported<3: return {"clear":false,"reason":"insufficient floor support","at":str(point),"supported":supported}
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.collision_mask=1
	query.transform=Transform3D(Basis(),Vector3(point.x,floor_y+0.88,point.z));query.margin=0.025
	var collisions:=space.intersect_shape(query,1)
	return {"clear":collisions.is_empty(),"at":str(point),"collider":"" if collisions.is_empty() else str(collisions[0].collider.get_path())}

func segment_clear(a: Vector3,b: Vector3) -> bool:
	var count:=maxi(1,ceili(a.distance_to(b)/0.10))
	for i in range(count+1):
		if not clear_at(a.lerp(b,float(i)/count)): return false
	return true

func plan() -> bool:
	points.clear();cursor=0
	if not is_instance_valid(destination):
		receipt={"status":"no next artifact in this scene"};return false
	var start:=actor.global_position;floor_y=start.y
	var finish:=destination.to_global(Vector3(0,0,2.35));finish.y=floor_y
	receipt={"status":"planning","destination":"shannon_entropy_meter","destination_path":str(destination.get_path()),"speed_metres_per_second":PACE,"clearance_radius":capsule.radius,"path_world":[],"travelled_metres":0.0}
	receipt.start_check=inspect_at(start);receipt.finish_check=inspect_at(finish)
	if not receipt.start_check.clear or not receipt.finish_check.clear: receipt.status="approach obstructed";return false
	# The museum's cabinet walls can put the doorway beyond the two instruments.
	var low:=Vector2(minf(start.x,finish.x)-6,minf(start.z,finish.z)-6)
	var high:=Vector2(maxf(start.x,finish.x)+6,maxf(start.z,finish.z)+6)
	var grid:=AStarGrid2D.new();grid.region=Rect2i(Vector2i.ZERO,Vector2i((high-low)/CELL)+Vector2i.ONE)
	grid.cell_size=Vector2.ONE*CELL;grid.offset=low;grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;grid.update()
	for x in grid.region.size.x:
		for y in grid.region.size.y:
			var at:=grid.get_point_position(Vector2i(x,y))
			grid.set_point_solid(Vector2i(x,y),not clear_at(Vector3(at.x,floor_y,at.y)))
	var first:=Vector2i(((Vector2(start.x,start.z)-low)/CELL).round())
	var last:=Vector2i(((Vector2(finish.x,finish.z)-low)/CELL).round())
	if grid.is_point_solid(first) or grid.is_point_solid(last): receipt.status="approach grid obstructed";return false
	var path:=grid.get_point_path(first,last)
	if path.is_empty():
		receipt.status="no clear floor route"
		var rows: Array=[]
		for y in grid.region.size.y:
			var row:=""
			for x in grid.region.size.x:
				var id:=Vector2i(x,y)
				row+="S" if id==first else ("F" if id==last else ("#" if grid.is_point_solid(id) else "."))
			rows.append(row)
		receipt.grid=rows;return false
	points.append(start)
	for at in path: points.append(Vector3(at.x,floor_y,at.y))
	points.append(finish)
	for i in range(1,points.size()):
		if not segment_clear(points[i-1],points[i]): receipt.status="route edge obstructed";points.clear();return false
	for point in points: receipt.path_world.append([point.x,point.y,point.z])
	receipt.status="walking";return true

func _physics_process(delta: float) -> void:
	if requested:
		requested=false;walking=plan()
		if not walking: ended.emit(receipt);return
	if not walking: return
	if not is_instance_valid(destination): cancel("destination removed");return
	var previous:=actor.global_position
	var next:=previous.move_toward(points[cursor],PACE*delta)
	if not segment_clear(previous,next): cancel("route became obstructed");return
	actor.global_position=next
	receipt.travelled_metres+=previous.distance_to(next)
	if next.distance_to(points[cursor])<0.015: cursor+=1
	if cursor>=points.size():
		walking=false;receipt.status="arrived";ended.emit(receipt)
