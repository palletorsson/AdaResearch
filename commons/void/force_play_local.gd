extends "res://commons/artifacts/force_play/encounter.gd"
## Source physics and controls, on the tower's floor instead of over its shafts.
func floor_patch(size: Vector2, colour: Material = null) -> void:
	var pieces: Array[Rect2] = [Rect2(-size*0.5,size)]
	var building: Node = self
	while building != null and not "spec" in building:building=building.get_parent()
	if building != null:
		for shaft in building.spec.shafts:
			var corners: Array[Vector2] = []
			for x in [-1,1]:
				for z in [-1,1]:
					var p := to_local(Vector3(shaft.x+x*(building.spec.shaft_width*0.5+0.04),global_position.y,float(shaft.get("z",0))+z*(building.spec.shaft_depth*0.5+0.04)))
					corners.append(Vector2(p.x,p.z))
			var hole := Rect2(corners[0],Vector2.ZERO)
			for p in corners: hole=hole.expand(p)
			var next: Array[Rect2] = []
			for piece in pieces:
				var cut := piece.intersection(hole)
				if not cut.has_area(): next.append(piece);continue
				for r in [Rect2(piece.position,Vector2(cut.position.x-piece.position.x,piece.size.y)),Rect2(Vector2(cut.end.x,piece.position.y),Vector2(piece.end.x-cut.end.x,piece.size.y)),Rect2(Vector2(cut.position.x,piece.position.y),Vector2(cut.size.x,cut.position.y-piece.position.y)),Rect2(Vector2(cut.position.x,cut.end.y),Vector2(cut.size.x,piece.end.y-cut.end.y))]:
					if r.has_area():next.append(r)
			pieces=next
	for piece in pieces:
		var center := piece.get_center()
		box(Vector3(center.x,0.025,center.y),Vector3(piece.size.x,0.05,piece.size.y),colour if colour!=null else pale,true)

func _ready() -> void:
	super._ready()
	add_to_group("void_exterior_walk")
	add_to_group("void_floor_extension")
	if kind == "flight": add_to_group("void_controlled_carry")

func contains_visitor(world_position: Vector3) -> bool:
	if kind == "flight": return _point_inside(world_position)
	var p := to_local(world_position)
	return absf(p.x)<=extent.x*0.5 and absf(p.z)<=extent.y*0.5 and p.y>=-0.3 and p.y<5.5
