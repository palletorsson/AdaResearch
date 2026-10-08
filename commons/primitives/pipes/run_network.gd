extends RefCounted
## Explicit shared port IDs: crossing a line does not connect it. Records contain
## points, style and optional ports [{id, point}], all in the layout's local space.
const Surface = preload("res://commons/primitives/pipes/swept_tube.gd")
const SNAP_DISTANCE := 0.16
const KINDS := ["tube", "pipe", "cable"]

static func nearest(records: Array, point: Vector3, exclude := -1) -> Dictionary:
	var result := {}; var distance := SNAP_DISTANCE
	for index in records.size():
		if index == exclude: continue
		if records[index].has("part"):
			for socket in records[index].sockets:
				if point.distance_to(socket.point) < distance:
					distance=point.distance_to(socket.point)
					result={"run":index,"point":socket.point}
			continue
		var path: PackedVector3Array = records[index].points
		for i in path.size()-1:
			var p := Geometry3D.get_closest_point_to_segment(point,path[i],path[i+1])
			for port in records[index].get("ports",[]):
				if p.distance_to(port.point) < SNAP_DISTANCE: p = port.point; break
			if point.distance_to(p) < distance:
				distance = point.distance_to(p)
				result = {"run":index,"point":p}
	return result

static func connected(record: Dictionary, point: Vector3) -> bool:
	for port in record.get("ports",[]):
		if port.point.distance_to(point) < 0.001: return true
	return false

static func connect_end(records: Array, source: int, at_start: bool) -> bool:
	var path: PackedVector3Array = records[source].points
	var end := 0 if at_start else path.size()-1
	if connected(records[source],path[end]): return false
	var target := nearest(records,path[end],source)
	if target.is_empty(): return false
	var neighbour := path[1] if at_start else path[-2]
	if neighbour.distance_to(target.point) < 0.001: return false
	var id := ""
	for port in records[target.run].get("ports",[]):
		if port.point.distance_to(target.point) < 0.001: id = port.id; break
	if id.is_empty():
		var used := {}
		for record in records:
			for port in record.get("ports",[]): used[port.id] = true
		var serial := 0
		while used.has("joint_%d" % serial): serial += 1
		id = "joint_%d" % serial
		records[target.run].get_or_add("ports",[]).append({"id":id,"point":target.point})
	path[end] = target.point
	records[source].points = path
	records[source].get_or_add("ports",[]).append({"id":id,"point":target.point})
	return true

static func junctions(records: Array) -> Dictionary:
	var result := {}
	for record in records:
		for port in record.get("ports",[]):
			if not result.has(port.id):
				result[port.id] = {"point":port.point,"radius":record.radius,"runs":0}
			result[port.id].radius = maxf(result[port.id].radius,record.radius)
			result[port.id].runs += 1
	return result

static func sag_path(a: Vector3, b: Vector3, sag: float, steps := 32) -> PackedVector3Array:
	# Bounded parabolic drape, not a catenary or a rope simulation.
	var path := PackedVector3Array()
	var drop := minf(maxf(sag,0.0),a.distance_to(b)*0.45)
	drop *= Vector2(b.x-a.x,b.z-a.z).length()/maxf(a.distance_to(b),0.001)
	for i in steps+1:
		var t := float(i)/steps
		path.append(a.lerp(b,t)+Vector3.DOWN*(4.0*drop*t*(1.0-t)))
	return path

static func shape_cable(record: Dictionary, sag := 0.5, floor_y := -INF) -> void:
	var old: PackedVector3Array = record.points
	if old.size() < 2: return
	# Junctions become additional supports; order them by their old arc address.
	var supports: Array = [{"point":old[0],"at":0.0},{"point":old[-1],"at":float(old.size())}]
	for port in record.get("ports",[]):
		if port.point.distance_to(old[0]) < 0.001 or port.point.distance_to(old[-1]) < 0.001: continue
		var best := INF; var at := 0.0
		for i in old.size()-1:
			var p := Geometry3D.get_closest_point_to_segment(port.point,old[i],old[i+1])
			if p.distance_to(port.point) < best:
				best = p.distance_to(port.point)
				at = i+old[i].distance_to(p)/maxf(old[i].distance_to(old[i+1]),0.001)
		supports.append({"point":port.point,"at":at})
	supports.sort_custom(func(a,b): return a.at < b.at)
	var path := PackedVector3Array()
	var steps := maxi(2,mini(32,(Surface.MAX_POINTS-1)/(supports.size()-1)))
	for i in supports.size()-1:
		var depth := minf(sag,maxf(0.0,minf(supports[i].point.y,supports[i+1].point.y)-floor_y))
		var span := sag_path(supports[i].point,supports[i+1].point,depth,steps)
		if not path.is_empty(): span = span.slice(1)
		path.append_array(span)
	record.points = path; record.sag = sag
