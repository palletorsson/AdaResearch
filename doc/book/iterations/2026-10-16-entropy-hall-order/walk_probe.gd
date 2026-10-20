extends "res://doc/book/iterations/2026-10-16-entropy-hall-order/audit.gd"
var capsule:=CapsuleShape3D.new()
var exclusions: Array[RID]=[]
var grid:=AStarGrid2D.new()
var approach_points={
	"arrival":Vector2(8.5,2.5), "ledger":Vector2(8.5,2.9),
	"jar A":Vector2(7.63,7.2),"jar B":Vector2(6.21,7.2),"jar C":Vector2(4.79,7.2),"jar D":Vector2(3.37,7.2),
	"jar readings":Vector2(7.8,7.15),"shakeable jar":Vector2(12.5,7.6),
	"sorting table":Vector2(5.5,12.8),"compartments":Vector2(11.5,12.7),
	"point entry":Vector2(17.5,15.7),"point interior":Vector2(17.5,21.5),"point exit":Vector2(17.5,27.3),
	"ruin":Vector2(8.5,26.25),"weathering wall":Vector2(4.25,29),
	"hybrids":Vector2(19.5,8),"hardware wear":Vector2(3.5,18.3),
	"doorway":Vector2(12.5,33.5),"signal controls":Vector2(12.5,34.4),
	"signal interior":Vector2(12.5,48.5),"signal side":Vector2(21.5,48.5),"exit":Vector2(12.5,62.5)}
func inspect(p: Vector2) -> Dictionary:
	var at:=map_world(Vector3(p.x,0,p.y));var space:=hall.get_world_3d().direct_space_state
	var support:=0
	for off in [Vector3.ZERO,Vector3(0.04,0,0.04),Vector3(-0.04,0,0.04),Vector3(0.04,0,-0.04),Vector3(-0.04,0,-0.04)]:
		var ray:=PhysicsRayQueryParameters3D.create(at+off+Vector3.UP*0.35,at+off-Vector3.UP*0.35,1);ray.exclude=exclusions
		var hit:=space.intersect_ray(ray)
		if not hit.is_empty() and hit.normal.y>0.9 and absf(hit.position.y-at.y)<0.14:support+=1
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.collision_mask=5;query.exclude=exclusions
	query.transform=Transform3D(Basis(),at+Vector3.UP*0.98);query.margin=0.02
	var hits:=space.intersect_shape(query,8);var names: Array=[]
	for hit in hits:names.append(str(hit.collider.get_path()))
	return {"clear":support>=3 and hits.is_empty(),"support":support,"obstacles":names}
func cell(p: Vector2) -> Vector2i:return Vector2i((p/0.5).round())
func path_between(a: Vector2,b: Vector2) -> PackedVector2Array:
	if grid.is_point_solid(cell(a)) or grid.is_point_solid(cell(b)):return PackedVector2Array()
	var path:=grid.get_point_path(cell(a),cell(b))
	if not path.is_empty():
		path.insert(0,a);path.append(b)
	return path
func continuous_clear(path: PackedVector2Array) -> bool:
	if path.is_empty():return false
	for i in range(1,path.size()):
		var steps:=int(ceil(path[i-1].distance_to(path[i])/0.1))
		for j in range(steps+1):
			if not inspect(path[i-1].lerp(path[i],float(j)/maxi(steps,1))).clear:return false
	return true
func landing_checks() -> void:
	var hybrid:=find_scene("/prefab_disorder/prefab_disorder.gd")
	if hybrid!=null:hybrid.ghost.auto_enabled=false
	await super.landing_checks()
	capsule.radius=0.3;capsule.height=1.8
	var player= museum.get("_player")
	if player is CollisionObject3D:exclusions.append(player.get_rid())
	for body in get_nodes_in_group("player_body"):
		if body is CollisionObject3D:exclusions.append(body.get_rid())
	observations.approaches={}
	for name in approach_points:
		var state:=inspect(approach_points[name]);observations.approaches[name]=state
		check("clear supported approach: "+name,state.clear)
	observations.original_threshold=inspect(Vector2(8.5,0.5))
	var portals= museum.get("_portal_stream")
	check("authored arrival is used without fallback",portals!=null and not portals._entry.is_empty() and not portals._entry.get("invalid",false) and portals._entry.get("source","")=="sp")
	check("negative control: wall blocks capsule",not inspect(Vector2(24.5,20.5)).clear)
	check("negative control: jar plinth blocks capsule",not inspect(Vector2(5.5,8.5)).clear)
	if portals!=null:
		observations.portal_entry=portals._entry;observations.portal_exit=portals._exit
		check("arrival supported by production portal check",portals._arrival_supported())
		check("authored exit remains valid",not portals._exit.is_empty() and not portals._exit.get("invalid",false))
	var all: Dictionary=observations.artifacts
	observations.overlaps=[]
	for a in all:
		if a=="weathering_wall":continue
		var box: Dictionary=all[a]
		check("inside room footprint: "+a,box.min[0]>=0.9 and box.max[0]<=24.1 and box.min[2]>=1 and box.max[2]<=64)
		var rect:=Rect2(Vector2(box.min[0],box.min[2]),Vector2(box.max[0]-box.min[0],box.max[2]-box.min[2]))
		for b in all:
			if b<=a:continue
			var other: Dictionary=all[b]
			var r:=Rect2(Vector2(other.min[0],other.min[2]),Vector2(other.max[0]-other.min[0],other.max[2]-other.min[2]))
			if rect.intersects(r):observations.overlaps.append([a,b])
	check("all artifact envelopes are separate",observations.overlaps.is_empty())
	grid.region=Rect2i(0,0,50,131);grid.cell_size=Vector2.ONE*0.5
	grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;grid.update()
	for x in 50:
		for z in 131:grid.set_point_solid(Vector2i(x,z),not inspect(Vector2(x,z)*0.5).clear)
	observations.routes={}
	for name in approach_points:
		var path:=path_between(approach_points.arrival,approach_points[name]);var record: Array=[]
		for at in path:record.append([at.x,at.y])
		observations.routes[name]=record
		check("walk from entry to "+name,continuous_clear(path))
	# A continuous entry-to-exit route visits every main encounter in text order.
	var route: Array=[];var previous: Vector2=approach_points.arrival
	for name in ["ledger","jar A","jar D","jar readings","shakeable jar","sorting table","compartments","point entry","point interior","point exit","ruin","doorway","signal controls","signal interior","signal side","exit"]:
		var path:=path_between(previous,approach_points[name])
		check("ordered walking leg to "+name,continuous_clear(path))
		for at in path:route.append([at.x,at.y])
		previous=approach_points[name]
	observations.ordered_route=route
	var jars:=find_scene(SOURCES.entropy_jar_states)
	await snapshot("jar-approach",jars.to_global(Vector3(0,1.65,3.6)),jars.to_global(Vector3(0,1.45,0)),76)
	var points:=find_scene(SOURCES.entropy_axiom)
	await snapshot("large-studies",points.to_global(Vector3(-6.5,2.3,-6.8)),points.to_global(Vector3(-0.5,1.8,1.8)),72)
	var ruin:=find_scene(SOURCES.entropy_ruin)
	await snapshot("ruin-and-wall",ruin.to_global(Vector3(4.5,2.5,-5)),ruin.to_global(Vector3(-2,1.6,0)),70)
	await snapshot("through-doorway",map_world(Vector3(12.5,1.65,31.5)),map_world(Vector3(12.5,2,43)),65)
	# Regression for the relocated optional rehearsal's existing next-stop route.
	if hybrid!=null:
		hybrid.ghost.actor.position=Vector3(0,0,2.15)
		hybrid.ghost.walk.actor=hybrid.ghost.actor;hybrid.ghost.walk.destination=find_scene(SOURCES.shannon_entropy_meter)
		check("hybrid rehearsal can still reach ledger",hybrid.ghost.walk.plan())
		hybrid.ghost.walk.cancel("layout probe complete")
	observations.scope="Native museum: 0.6 m wide / 1.8 m tall capsule, support rays, full-room route graph, installed bounds and original ghost path planner. Headset and human reading remain open."
