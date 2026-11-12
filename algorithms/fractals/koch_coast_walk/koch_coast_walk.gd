extends Node3D
## THE KOCH COAST WALK (floor Fractal_KochSierpinski; the pass, 2026-11-12)
##
## The floor measures its curves with boxes on a board. This is the same measurement made with a body.
## A Koch island: the snowflake on a triangle of side 4.5 m, half a metre high, its coast a wall. Every generation
## puts a bump on the middle third of every straight piece, so the coast is 3 x side x (4/3)^n long: 13.5, 18, 24,
## 32, 42.7, 56.9 m - without end.
## Walk round it, close. The work counts how far your body went in one lap and writes it beside the coast's length.
## A body is a ruler 0.4 m wide: it cannot enter a notch narrower than itself. Predicted on a bench before the work
## was built (tools/probes/koch_coast_bench.py, a disc of radius 0.2 m): 14.8, 19.1, 24.6 - and then 22.1, 21.4,
## 21.3. The lap grows with the coast for two generations and then gets SHORTER: the third generation's bumps
## close the bays the body could still walk into. The length of a coast is a fact about the ruler.
##
## The top of the island keeps its history: the seed triangle and every generation's bumps in their own colour.
## A lap makes the island grow one generation (`grows_on_lap`); the plates on its south side do the same by foot.
const GENERATIONS := ["seed", "first", "second", "third", "fourth", "fifth"]
const TINTS: Array[Color] = [Color("5bcefa"), Color("8fd4f4"), Color("c7e6f5"), Color("f7d9e1"), Color("f5b8c6"), Color("f08fa8")]
const WALL := Color(0.94, 0.95, 0.98)
const BAND := 1.1                       # a body this close to the coast is walking it

@export_enum("seed", "first", "second", "third", "fourth", "fifth") var generation := "second"
@export var side := 4.5                 ## metres: the seed triangle's side
@export var height := 0.5
@export var grows_on_lap := true        ## a finished lap puts the next generation on the island

var _built: Node3D
var _furniture: Node3D
var _signs: Array[Label3D] = []
var _plates: Array[Vector3] = []
var _guide := PackedVector2Array()      # the coast after two generations at most: enough to know who is walking it
var _walkers := {}                      # body -> {at, went, wound, turns, ways, head}: see _fresh
var _laps := {}                         # generation index -> metres of the last lap walked on it
var _lap_count := 0
var _pressed := -10.0
var _now := 0.0
var _rebuild_usec := 0


func _ready() -> void:
	var given := {}
	for key in ["generation", "side", "height", "grows_on_lap"]:
		if has_meta("config_" + key): given[key] = get_meta("config_" + key)
	_take(given)
	_build_furniture()
	_build()


func _take(config_data: Dictionary) -> bool:
	var changed := false
	if config_data.has("generation") and str(config_data["generation"]) in GENERATIONS and str(config_data["generation"]) != generation:
		generation = str(config_data["generation"])
		changed = true
	for key in ["side", "height"]:
		if config_data.has(key) and not is_equal_approx(float(str(config_data[key])), float(get(key))):
			set(key, maxf(0.1, float(str(config_data[key]))))
			changed = true
	if config_data.has("grows_on_lap"): grows_on_lap = str(config_data["grows_on_lap"]).to_lower() in ["true", "1", "yes"]
	return changed


func apply_grid_config(config_data: Dictionary) -> void:
	var changed := _take(config_data)
	if changed and is_inside_tree() and _furniture != null:
		_build_furniture()
		_build()


## ---- the curve ----

## The island's outline after `depth` generations, in the plane (x east, y north), counter-clockwise, and the
## triangles each generation added: [outline, [[a, b, c, generation], ...]].
static func outline(depth: int, seed_side: float) -> Array:
	var tall: float = seed_side * sqrt(3.0) / 2.0
	var points := PackedVector2Array([Vector2(-seed_side / 2.0, -tall / 3.0), Vector2(seed_side / 2.0, -tall / 3.0), Vector2(0.0, 2.0 * tall / 3.0)])
	var added := [[points[0], points[1], points[2], 0]]
	for g in range(1, depth + 1):
		var next := PackedVector2Array()
		for i in points.size():
			var a: Vector2 = points[i]
			var b: Vector2 = points[(i + 1) % points.size()]
			var d: Vector2 = (b - a) / 3.0
			var p1: Vector2 = a + d
			var p2: Vector2 = a + 2.0 * d
			var peak: Vector2 = p1 + d.rotated(-PI / 3.0)        # outward, for a counter-clockwise outline
			next.append_array([a, p1, peak, p2])
			added.append([p1, peak, p2, g])
		points = next
	return [points, added]


func generation_index() -> int:
	return GENERATIONS.find(generation)


func coast_m(index: int = -1) -> float:
	return 3.0 * side * pow(4.0 / 3.0, float(generation_index() if index < 0 else index))


func _on_floor(p: Vector2, y: float) -> Vector3:
	return Vector3(p.x, y, -p.y)


func _tri(points: PackedVector3Array, normals: PackedVector3Array, colours: PackedColorArray, a: Vector3, b: Vector3, c: Vector3, normal: Vector3, colour: Color) -> void:
	# Godot's front face is clockwise seen from outside
	if (c - a).cross(b - a).dot(normal) < 0.0:
		var keep := b
		b = c
		c = keep
	for p: Vector3 in [a, b, c]:
		points.append(p)
		normals.append(normal)
		colours.append(colour)


func _build() -> void:
	var began := Time.get_ticks_usec()
	if _built != null:
		remove_child(_built)
		_built.queue_free()
	_built = Node3D.new()
	_built.name = "Island"
	add_child(_built)
	var made: Array = outline(generation_index(), side)
	var coast: PackedVector2Array = made[0]
	var points := PackedVector3Array()
	var normals := PackedVector3Array()
	var colours := PackedColorArray()
	for entry in made[1]:
		_tri(points, normals, colours, _on_floor(entry[0], height), _on_floor(entry[1], height), _on_floor(entry[2], height), Vector3.UP, TINTS[int(entry[3])])
	for i in coast.size():
		var a: Vector2 = coast[i]
		var b: Vector2 = coast[(i + 1) % coast.size()]
		var along: Vector2 = (b - a).normalized()
		var out := Vector3(along.y, 0, along.x)                 # the outward normal of a counter-clockwise outline, on the floor
		_tri(points, normals, colours, _on_floor(a, 0), _on_floor(b, 0), _on_floor(b, height), out, WALL)
		_tri(points, normals, colours, _on_floor(a, 0), _on_floor(b, height), _on_floor(a, height), out, WALL)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colours
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var skin := StandardMaterial3D.new()
	skin.vertex_color_use_as_albedo = true
	skin.vertex_color_is_srgb = true
	skin.roughness = 0.8
	var shown := MeshInstance3D.new()
	shown.name = "Coast"
	shown.mesh = mesh
	shown.material_override = skin
	_built.add_child(shown)
	var body := StaticBody3D.new()
	body.name = "Wall"
	var shape := CollisionShape3D.new()
	var ground := ConcavePolygonShape3D.new()
	ground.backface_collision = true
	ground.set_faces(points)
	shape.shape = ground
	body.add_child(shape)
	_built.add_child(body)
	_guide = outline(mini(generation_index(), 2), side)[0]
	for b in _walkers: _walkers[b] = _fresh(_walkers[b].at as Vector2)
	_rebuild_usec = Time.get_ticks_usec() - began
	_write()


## ---- sign, plates, who is near ----

func _build_furniture() -> void:
	if _furniture != null:
		remove_child(_furniture)
		_furniture.queue_free()
	_furniture = Node3D.new()
	_furniture.name = "Furniture"
	add_child(_furniture)
	_signs.clear()
	_plates.clear()
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.11, 0.115, 0.13)
	dark.roughness = 0.85
	# a three-sided sign on the island, one face to each side of the seed triangle: it is read from the lap
	var apothem: float = side * sqrt(3.0) / 6.0 * 0.45
	for k in 3:
		var turn: float = float(k) * TAU / 3.0
		var stand := Node3D.new()
		stand.name = "Sign_%d" % k
		stand.rotation.y = turn
		_furniture.add_child(stand)
		var panel := MeshInstance3D.new()
		var face := BoxMesh.new()
		face.size = Vector3(apothem * 2.0 * sqrt(3.0), 1.4, 0.05)
		panel.mesh = face
		panel.material_override = dark
		panel.position = Vector3(0, height + 1.05, apothem)
		stand.add_child(panel)
		var words := Label3D.new()
		words.pixel_size = 0.003
		words.font_size = 30
		words.line_spacing = 2.0
		words.modulate = Color(0.88, 0.94, 1.0)
		words.outline_size = 4
		words.outline_modulate = Color(0, 0, 0, 1)
		words.width = (apothem * 2.0 * sqrt(3.0) - 0.14) / 0.003
		words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		words.position = Vector3(0, height + 1.05, apothem + 0.03)
		stand.add_child(words)
		_signs.append(words)
	var pad := BoxMesh.new()
	pad.size = Vector3(0.7, 0.03, 0.7)
	var press := BoxShape3D.new()
	press.size = Vector3(0.6, 1.0, 0.6)
	var names := ["NEXT\nGENERATION", "ONE\nBACK"]
	var reach: float = side / sqrt(3.0)                       # the snowflake lies inside this circle
	for which in 2:
		var at := Vector3(-0.65 + float(which) * 1.3, 0.015, reach + BAND + 0.25)
		_plates.append(at)
		var plate := MeshInstance3D.new()
		plate.mesh = pad
		plate.material_override = dark
		plate.position = at
		_furniture.add_child(plate)
		var word := Label3D.new()
		word.text = names[which]
		word.pixel_size = 0.0028
		word.font_size = 32
		word.modulate = Color(1.0, 0.82, 0.16)
		word.rotation_degrees = Vector3(-90, 0, 0)
		word.position = at + Vector3(0, 0.02, 0)
		_furniture.add_child(word)
		var area := Area3D.new()
		area.collision_layer = 0
		area.collision_mask = 0xFFFFFFFF
		var touch := CollisionShape3D.new()
		touch.shape = press
		touch.position.y = 0.5
		area.add_child(touch)
		area.position = at
		area.body_entered.connect(func(b: Node) -> void:
			if b is CharacterBody3D: press_plate(which))
		_furniture.add_child(area)
	var zone := Area3D.new()
	zone.name = "Near"
	zone.collision_layer = 0
	zone.collision_mask = 0xFFFFFFFF
	var room := CylinderShape3D.new()
	room.radius = reach + BAND + 1.2
	room.height = 3.0
	var room_shape := CollisionShape3D.new()
	room_shape.shape = room
	room_shape.position.y = 1.5
	zone.add_child(room_shape)
	zone.body_entered.connect(func(b: Node) -> void:
		if b is CharacterBody3D:
			var here: Vector3 = to_local((b as Node3D).global_position)
			_walkers[b] = _fresh(Vector2(here.x, -here.z)))
	zone.body_exited.connect(func(b: Node) -> void: _walkers.erase(b))
	_furniture.add_child(zone)


func _write() -> void:
	if _signs.is_empty(): return
	var index := generation_index()
	var lines := PackedStringArray(["HOW LONG IS THE COAST, FOR YOU?",
		"Every generation puts a bump on each straight piece: the coast grows by a third, without end.",
		"Walk round it, close. You are a ruler 0.4 m wide.", ""])
	for g in range(0, index + 1):
		var lap: String = "%.1f m" % float(_laps[g]) if _laps.has(g) else "-"
		lines.append("%s   coast %5.1f m   your lap %s%s" % [GENERATIONS[g].to_upper(), coast_m(g), lap, "   <" if g == index else ""])
	for sign in _signs: sign.text = "\n".join(lines)


## Plate 0: the next generation. Plate 1: one back.
func press_plate(which: int) -> void:
	if _now - _pressed < 1.0: return
	_pressed = _now
	set_generation(clampi(generation_index() + (1 if which == 0 else -1), 0, GENERATIONS.size() - 1))


func set_generation(index: int) -> void:
	var next: String = GENERATIONS[clampi(index, 0, GENERATIONS.size() - 1)]
	if next == generation: return
	generation = next
	_build()


## How far a point (x east, y north) is from the guide coast.
func _to_coast(p: Vector2) -> float:
	var best := INF
	for i in _guide.size():
		var a: Vector2 = _guide[i]
		var b: Vector2 = _guide[(i + 1) % _guide.size()]
		best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b)))
	return best


func _physics_process(delta: float) -> void:
	_now += delta
	for b in _walkers:
		if not is_instance_valid(b): continue
		var here3: Vector3 = to_local((b as Node3D).global_position)
		var here := Vector2(here3.x, -here3.z)
		var walker: Dictionary = _walkers[b]
		var before: Vector2 = walker.at
		walker.at = here
		var step: float = here.distance_to(before)
		if step < 0.0005: continue
		if here3.y > height + 0.3 or step > 1.0 or _to_coast(here) > BAND:      # on the island, carried, or walking away
			_walkers[b] = _fresh(here)
			continue
		# the lap is the way gone during the LAST whole round: the approach to the coast is not part of it
		walker.went = float(walker.went) + step
		walker.wound = float(walker.wound) + before.angle_to(here)
		var turns: PackedFloat64Array = walker.turns
		var ways: PackedFloat64Array = walker.ways
		turns.append(float(walker.wound))
		ways.append(float(walker.went))
		var head: int = walker.head
		if absf(float(walker.wound) - turns[head]) >= TAU:
			while head + 1 < turns.size() and absf(float(walker.wound) - turns[head + 1]) >= TAU: head += 1
			_laps[generation_index()] = float(walker.went) - ways[head]
			_lap_count += 1
			_walkers[b] = _fresh(here)
			if grows_on_lap: set_generation((generation_index() + 1) % GENERATIONS.size())
			else: _write()
		elif turns.size() > 20000:           # wandering by the coast without ever going round: begin again
			_walkers[b] = _fresh(here)
		else:
			walker.turns = turns
			walker.ways = ways


func _fresh(at: Vector2) -> Dictionary:
	return {"at": at, "went": 0.0, "wound": 0.0, "turns": PackedFloat64Array([0.0]), "ways": PackedFloat64Array([0.0]), "head": 0}


## ---- for a test ----

func coast_points() -> PackedVector3Array:
	var out := PackedVector3Array()
	for p: Vector2 in outline(generation_index(), side)[0]: out.append(to_global(_on_floor(p, 0)))
	return out


## Who is walking the coast now: how far each has gone and how much of the round it has made.
func walking() -> Array:
	var out := []
	for b in _walkers: out.append({"went_m": float(_walkers[b].went), "round": float(_walkers[b].wound) / TAU})
	return out


func laps() -> Dictionary:
	return _laps


func lap_count() -> int:
	return _lap_count


func plate_centre(which: int) -> Vector3:
	return to_global(_plates[which])


func rebuild_ms() -> float:
	return float(_rebuild_usec) / 1000.0
