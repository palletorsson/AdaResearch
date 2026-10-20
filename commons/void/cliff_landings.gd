extends RefCounted
## Permanent, irregular concrete extensions of the floor. Ordinary fall damage applies.

static func enabled(spec: Dictionary) -> bool:
	return spec.get("cliff_landings", {}).get("enabled", false)

static func landing(spec: Dictionary, index: int) -> Dictionary:
	var settings: Dictionary = spec.cliff_landings
	var profile: Dictionary = settings.profiles[(index - 1) % settings.profiles.size()]
	var outline := PackedVector2Array()
	for point in profile.outline:
		outline.append(Vector2(float(point[0]), float(point[1])))
	var offsets: Array = settings.get("lateral_offsets", [0.0, 8.0])
	return {"side": -1.0 if settings.get("side", "south") == "north" else 1.0,
		"x": float(profile.offset_x) + float(offsets[(index - 1) % offsets.size()]), "outline": outline}

static func extent(spec: Dictionary) -> float:
	var depth := 0.0
	if enabled(spec):
		for profile in spec.cliff_landings.profiles:
			for point in profile.outline: depth = maxf(depth, float(point[1]))
	return depth

static func build(building: Node3D, index: int) -> void:
	var spec: Dictionary = building.spec
	var plan := landing(spec, index)
	var outline: PackedVector2Array = plan.outline
	var side: float = plan.side
	var thickness: float = spec.slab_thickness
	var slab := StaticBody3D.new()
	slab.name = "SlabCliffLanding"
	slab.position = Vector3(plan.x, 0, side * float(spec.depth) / 2.0)
	slab.set_meta("void_floor_index", index)
	building.floors[index].add_child(slab)
	var top := PackedVector3Array()
	var bottom := PackedVector3Array()
	for point in outline:
		top.append(Vector3(point.x, 0, side * point.y))
		bottom.append(Vector3(point.x, -thickness, side * point.y))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var triangles := Geometry2D.triangulate_polygon(outline)
	for i in range(0, triangles.size(), 3):
		_triangle(surface, top[triangles[i]], top[triangles[i+1]], top[triangles[i+2]], Vector3.UP)
		_triangle(surface, bottom[triangles[i]], bottom[triangles[i+1]], bottom[triangles[i+2]], Vector3.DOWN)
	for i in outline.size():
		var j := (i + 1) % outline.size()
		var edge := outline[j] - outline[i]
		var normal := Vector3(edge.y, 0, -edge.x * side).normalized()
		_triangle(surface, top[i], bottom[i], bottom[j], normal)
		_triangle(surface, top[i], bottom[j], top[j], normal)
	var mesh := MeshInstance3D.new()
	mesh.name = "Concrete"
	mesh.mesh = surface.commit()
	mesh.material_override = building.concrete
	slab.add_child(mesh)
	var collision := CollisionShape3D.new()
	var shape := ConvexPolygonShape3D.new()
	var points := top.duplicate()
	points.append_array(bottom)
	shape.points = points
	collision.shape = shape
	slab.add_child(collision)
	# A thin inset edge catches the evening light; it is neither a rail nor a pad.
	var paint: StandardMaterial3D = building.pink.duplicate()
	paint.emission_enabled = true
	paint.emission = Color("b987a8")
	paint.emission_energy_multiplier = 0.25
	for i in range(1, outline.size()):
		var j := (i + 1) % outline.size()
		var a := top[i].lerp(Vector3(0, 0, side * 1.1), 0.04) + Vector3.UP * 0.012
		var b := top[j].lerp(Vector3(0, 0, side * 1.1), 0.04) + Vector3.UP * 0.012
		building.pipe(slab, "EdgePaint", a, b, 0.022, paint)
	var number := Label3D.new()
	number.text = "%02d" % index
	number.font_size = 128
	number.pixel_size = 0.008
	number.outline_size = 0
	number.modulate = Color("38373d")
	number.position = Vector3(0, 0.014, side * 1.1)
	number.rotation_degrees = Vector3(-90, 0 if side > 0 else 180, 0)
	slab.add_child(number)
	# Mark the departure above the next landing. Staggered positions on one facade
	# leave it exposed instead of hiding it underneath the current balcony.
	var upper: Node3D = building.floors[index - 1]
	building.box(upper, "CliffLaunchMark", Vector3(plan.x, 0.015, side * (float(spec.depth)/2.0 - 0.12)), Vector3(2.8, 0.025, 0.12), paint, false)

static func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, normal: Vector3) -> void:
	# Godot's front faces wind clockwise when viewed from outside.
	var vertices := [a, c, b] if (b-a).cross(c-a).dot(normal) > 0 else [a, b, c]
	for vertex in vertices:
		surface.set_normal(normal)
		surface.add_vertex(vertex)
