extends RefCounted
## The museum's recessed, glass-covered basin adapted to the tower's slab.
## All rectangles are floor-local X/Z; the walkable lid stays at Y=0.

static func slab(building: Node3D, host: Node3D, title: String, at: Vector3, size: Vector3) -> void:
	var pieces: Array[Rect2] = [Rect2(at.x-size.x/2, at.z-size.z/2, size.x, size.z)]
	for values in host.get_meta("basin", {}).get("rects", []):
		var cut := Rect2(values[0], values[1], values[2], values[3])
		var next: Array[Rect2] = []
		for piece in pieces:
			if not piece.intersects(cut):
				next.append(piece)
				continue
			var inside := piece.intersection(cut)
			for remainder in [
				Rect2(piece.position, Vector2(inside.position.x-piece.position.x, piece.size.y)),
				Rect2(inside.end.x,piece.position.y,piece.end.x-inside.end.x,piece.size.y),
				Rect2(inside.position.x,piece.position.y,inside.size.x,inside.position.y-piece.position.y),
				Rect2(inside.position.x,inside.end.y,inside.size.x,piece.end.y-inside.end.y)]:
				if remainder.has_area(): next.append(remainder)
		pieces = next
	for piece in pieces:
		var centre := piece.get_center()
		var body: Node3D=building.box(host,title,Vector3(centre.x,at.y,centre.y),Vector3(piece.size.x,size.y,piece.size.y),building.concrete)
		# Split slabs can receive generated node names; checkpoint identity must
		# belong to the physical surface rather than its display name.
		body.set_meta("void_floor_index",host.get_meta("void_floor_index",-1))

static func build(building: Node3D, floor_root: Node3D) -> void:
	var spec: Dictionary = floor_root.get_meta("basin", {})
	if spec.is_empty(): return
	var host := Node3D.new()
	host.name = "Basin"
	floor_root.add_child(host)
	var depth := float(spec.depth)
	var xs: Array[float] = []
	var zs: Array[float] = []
	var rects: Array[Rect2] = []
	for values in spec.rects:
		var rect := Rect2(values[0],values[1],values[2],values[3])
		rects.append(rect)
		for x in [rect.position.x,rect.end.x]:
			if not xs.has(x): xs.append(x)
		for z in [rect.position.y,rect.end.y]:
			if not zs.has(z): zs.append(z)
	xs.sort(); zs.sort()
	var tiles: Dictionary = {}
	for x in range(xs.size()-1):
		for z in range(zs.size()-1):
			var rect := Rect2(xs[x],zs[z],xs[x+1]-xs[x],zs[z+1]-zs[z])
			for source in rects:
				if source.has_point(rect.get_center()):
					tiles[Vector2i(x,z)] = rect
					break
	var dark: Material = building.material(Color("252a33"),0.8)
	var glass: StandardMaterial3D = building.material(Color(0.55,0.77,0.80,0.22),0.12)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	for key in tiles:
		var rect: Rect2 = tiles[key]
		var centre := rect.get_center()
		building.box(host,"Bottom",Vector3(centre.x,-depth-0.10,centre.y),Vector3(rect.size.x,0.20,rect.size.y),dark)
		if spec.get("glass",true):
			var lid: Node3D=building.box(host,"Glass",Vector3(centre.x,-0.03,centre.y),Vector3(rect.size.x,0.06,rect.size.y),glass)
			lid.set_meta("void_floor_index",floor_root.get_meta("void_floor_index",-1))
		for direction in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			if tiles.has(key+direction): continue
			var along_x: bool = direction.x != 0
			var at := Vector3(centre.x+direction.x*(rect.size.x/2-0.05),-depth/2,centre.y+direction.y*(rect.size.y/2-0.05))
			var size := Vector3(0.1 if along_x else rect.size.x,depth,rect.size.y if along_x else 0.1)
			building.box(host,"Wall",at,size,dark)
