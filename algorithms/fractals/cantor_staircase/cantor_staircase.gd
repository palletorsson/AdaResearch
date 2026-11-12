extends Node3D
## THE CANTOR STAIRCASE (floor Fractal_CantorSet; the pass, 2026-11-12)
##
## The floor has the Cantor set as bars (how many pieces, how little length) and as a pagoda (which gaps a body
## fits through). This is the third thing the same cut makes, at the size of a walk: the Cantor FUNCTION.
##   Lay a ramp. Make its middle third level, at half its height, and steepen the two ends so they still meet it.
##   Do the same to every ramp that is left.
## After n cuts the stair still arrives at the top, and
##   what rises is the Cantor set of that depth: 2^n ramps, (2/3)^n of the length, each (3/2)^n times as steep;
##   every level stretch stays where it was put: a landing made by cut k is at an odd multiple of 1/2^k of the rise,
##   and no later cut moves it.
## In the limit all of the rise happens on a set of length zero. A body meets that limit early: with a rise of 2 m on
## 13.5 m the ramps pass 45 degrees at the fifth cut (48.4), and the stair that still "arrives" cannot be climbed.
##
## `cut` is the axis: whole | once | twice | thrice | four_times | five_times.
## The ramps are pink (what is left of the line), the landings pale (the thirds taken away); the wall under each
## carries the same colour, so the side of the stair is the set's own row of bars standing up under its graph.
## Two plates by the board: CUT AGAIN, PUT BACK.
const CUTS := ["whole", "once", "twice", "thrice", "four_times", "five_times"]
const SET := Color("f5a9b8")              # what is left: it rises
const GONE := Color("dff1fa")             # the thirds taken away: level
const SET_WALL := Color("e58aa0")
const GONE_WALL := Color("7fc4e6")
const UNDER := Color(0.20, 0.22, 0.27)

@export_enum("whole", "once", "twice", "thrice", "four_times", "five_times") var cut := "thrice"
@export var rise := 2.0                 ## metres from the foot to the top
@export var length := 13.5              ## metres along the floor: half of 27, so three cuts leave half-metre ramps
@export var width := 1.6
@export var lip := 0.3                  ## a level run past the top, onto whatever landing stands there. A kit deck's edge rod stands
                                        ## 4 cm proud of a ramp that ends on it: end the climb 10 cm short and let the lip lie over the rod

var _built: Node3D
var _furniture: Node3D
var _board: Label3D
var _plates: Array[Vector3] = []
var _pressed := -10.0
var _now := 0.0
var _rebuild_usec := 0


func _ready() -> void:
	var given := {}
	for key in ["cut", "rise", "length", "width", "lip"]:
		if has_meta("config_" + key): given[key] = get_meta("config_" + key)
	_take(given)
	_build_furniture()
	_build()


func _take(config_data: Dictionary) -> bool:
	var changed := false
	if config_data.has("cut") and str(config_data["cut"]) in CUTS and str(config_data["cut"]) != cut:
		cut = str(config_data["cut"])
		changed = true
	for key in ["rise", "length", "width", "lip"]:
		if config_data.has(key) and not is_equal_approx(float(str(config_data[key])), float(get(key))):
			set(key, maxf(0.05, float(str(config_data[key]))))
			changed = true
	return changed


func apply_grid_config(config_data: Dictionary) -> void:
	var changed := _take(config_data)
	if changed and is_inside_tree() and _furniture != null:
		_build_furniture()
		_build()


## ---- the function ----

## The stair after `depth` cuts, foot to top: [x0, x1, y0, y1] for every stretch, ramps and landings in order.
static func stretches(depth: int, run: float, climb: float) -> Array:
	var out := []
	_stretch(out, 0.0, run, 0.0, climb, depth)
	return out


static func _stretch(out: Array, x0: float, x1: float, y0: float, y1: float, depth: int) -> void:
	if depth == 0:
		out.append([x0, x1, y0, y1])
		return
	var third: float = (x1 - x0) / 3.0
	var half: float = (y0 + y1) * 0.5
	_stretch(out, x0, x0 + third, y0, half, depth - 1)
	out.append([x0 + third, x0 + 2.0 * third, half, half])
	_stretch(out, x0 + 2.0 * third, x1, half, y1, depth - 1)


func cuts_made() -> int:
	return CUTS.find(cut)


func slope_degrees(at_depth: int = -1) -> float:
	return rad_to_deg(atan(rise / length * pow(1.5, float(cuts_made() if at_depth < 0 else at_depth))))


## ---- the stair ----

func _quad(points: PackedVector3Array, normals: PackedVector3Array, colours: PackedColorArray, order: PackedInt32Array,
		a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3, colour: Color) -> void:
	# Godot's front face is clockwise seen from outside: (c - a) x (b - a) must point along the normal
	if (c - a).cross(b - a).dot(normal) < 0.0:
		var keep := b
		b = d
		d = keep
	var first := points.size()
	for p: Vector3 in [a, b, c, d]:
		points.append(p)
		normals.append(normal)
		colours.append(colour)
	order.append_array([first, first + 1, first + 2, first, first + 2, first + 3])


func _build() -> void:
	var began := Time.get_ticks_usec()
	if _built != null:
		remove_child(_built)
		_built.queue_free()
	_built = Node3D.new()
	_built.name = "Stair"
	add_child(_built)
	var points := PackedVector3Array()
	var normals := PackedVector3Array()
	var colours := PackedColorArray()
	var order := PackedInt32Array()
	var half := width * 0.5
	var parts: Array = stretches(cuts_made(), length, rise)
	for part in parts:
		var x0: float = part[0]
		var x1: float = part[1]
		var y0: float = part[2]
		var y1: float = part[3]
		var rises: bool = y1 > y0
		var up := Vector3(-(y1 - y0), x1 - x0, 0).normalized()
		_quad(points, normals, colours, order, Vector3(x0, y0, -half), Vector3(x1, y1, -half), Vector3(x1, y1, half), Vector3(x0, y0, half), up, SET if rises else GONE)
		for side in [1.0, -1.0]:
			_quad(points, normals, colours, order, Vector3(x0, 0, half * side), Vector3(x1, 0, half * side), Vector3(x1, y1, half * side), Vector3(x0, y0, half * side),
				Vector3(0, 0, side), SET_WALL if rises else GONE_WALL)
	# the lip onto the landing, a hair higher at its end so a foot steps down, never up
	var top := Vector3(length + lip, rise + 0.008, 0)
	_quad(points, normals, colours, order, Vector3(length, rise, -half), Vector3(top.x, top.y, -half), Vector3(top.x, top.y, half), Vector3(length, rise, half), Vector3.UP, GONE)
	for side in [1.0, -1.0]:
		_quad(points, normals, colours, order, Vector3(length, 0, half * side), Vector3(top.x, 0, half * side), Vector3(top.x, top.y, half * side), Vector3(length, rise, half * side), Vector3(0, 0, side), GONE_WALL)
	_quad(points, normals, colours, order, Vector3(top.x, 0, -half), Vector3(top.x, 0, half), Vector3(top.x, top.y, half), Vector3(top.x, top.y, -half), Vector3.RIGHT, GONE_WALL)
	_quad(points, normals, colours, order, Vector3(0, 0, -half), Vector3(top.x, 0, -half), Vector3(top.x, 0, half), Vector3(0, 0, half), Vector3.DOWN, UNDER)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colours
	arrays[Mesh.ARRAY_INDEX] = order
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var skin := StandardMaterial3D.new()
	skin.vertex_color_use_as_albedo = true
	skin.vertex_color_is_srgb = true
	skin.roughness = 0.85
	var shown := MeshInstance3D.new()
	shown.name = "Graph"
	shown.mesh = mesh
	shown.material_override = skin
	_built.add_child(shown)
	# what a body meets: the same faces, and the first ramp carried on under the floor so a foot meets a slope
	var faces := PackedVector3Array()
	for i in order: faces.append(points[i])
	var first: Array = parts[0]
	var grade: float = (float(first[3]) - float(first[2])) / (float(first[1]) - float(first[0]))
	var under := [Vector3(-0.2, -0.2 * grade, -half), Vector3(0, 0, -half), Vector3(0, 0, half), Vector3(-0.2, -0.2 * grade, half)]
	faces.append_array([under[0], under[1], under[2], under[0], under[2], under[3]])
	var body := StaticBody3D.new()
	body.name = "Ground"
	var shape := CollisionShape3D.new()
	var ground := ConcavePolygonShape3D.new()
	ground.backface_collision = true
	ground.set_faces(faces)
	shape.shape = ground
	body.add_child(shape)
	_built.add_child(body)
	# the landings a cut made keep their height: name it on the first three cuts' landings
	for part in parts:
		if float(part[3]) > float(part[2]) or float(part[1]) - float(part[0]) < 0.45: continue
		var share: float = float(part[2]) / rise
		var over := 2
		while over < 64 and absf(share * float(over) - roundf(share * float(over))) > 0.001: over *= 2
		var word := Label3D.new()
		word.text = "%d/%d" % [int(roundf(share * float(over))), over]
		word.pixel_size = 0.0032
		word.font_size = 40
		word.modulate = Color(0.1, 0.12, 0.18)
		word.outline_size = 5
		word.outline_modulate = Color(1, 1, 1, 0.9)
		word.position = Vector3((float(part[0]) + float(part[1])) * 0.5, float(part[2]) + 0.16, half + 0.01)
		_built.add_child(word)
	_rebuild_usec = Time.get_ticks_usec() - began
	_write()


## ---- board and plates ----

func _build_furniture() -> void:
	if _furniture != null:
		remove_child(_furniture)
		_furniture.queue_free()
	_furniture = Node3D.new()
	_furniture.name = "Furniture"
	add_child(_furniture)
	_plates.clear()
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.11, 0.115, 0.13)
	dark.roughness = 0.85
	var stand := Node3D.new()
	stand.name = "Board"
	stand.position = Vector3(2.4, 0, width * 0.5 + 1.9)
	_furniture.add_child(stand)
	var panel := MeshInstance3D.new()
	var face := BoxMesh.new()
	face.size = Vector3(2.5, 1.25, 0.06)
	panel.mesh = face
	panel.material_override = dark
	panel.position.y = 1.3
	stand.add_child(panel)
	for side in [-1.05, 1.05]:
		var leg := MeshInstance3D.new()
		var post := BoxMesh.new()
		post.size = Vector3(0.08, 0.7, 0.06)
		leg.mesh = post
		leg.material_override = dark
		leg.position = Vector3(side, 0.35, 0)
		stand.add_child(leg)
	_board = Label3D.new()
	_board.pixel_size = 0.0022
	_board.font_size = 30
	_board.line_spacing = 2.0
	_board.modulate = Color(0.88, 0.94, 1.0)
	_board.outline_size = 4
	_board.outline_modulate = Color(0, 0, 0, 1)
	_board.width = 1080
	_board.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_board.position = Vector3(0, 1.3, 0.035)
	stand.add_child(_board)
	var pad := BoxMesh.new()
	pad.size = Vector3(0.7, 0.03, 0.7)
	var press := BoxShape3D.new()
	press.size = Vector3(0.6, 1.0, 0.6)
	var words := ["CUT\nAGAIN", "PUT\nBACK"]
	for which in 2:
		var at := Vector3(1.75 + float(which) * 1.3, 0.015, width * 0.5 + 2.9)
		_plates.append(at)
		var plate := MeshInstance3D.new()
		plate.mesh = pad
		plate.material_override = dark
		plate.position = at
		_furniture.add_child(plate)
		var word := Label3D.new()
		word.text = words[which]
		word.pixel_size = 0.003
		word.font_size = 34
		word.modulate = Color(1.0, 0.82, 0.16)
		word.rotation_degrees = Vector3(-90, 0, 0)
		word.position = at + Vector3(0, 0.02, 0)
		_furniture.add_child(word)
		var area := Area3D.new()
		area.collision_layer = 0
		area.collision_mask = 0xFFFFFFFF
		var reach := CollisionShape3D.new()
		reach.shape = press
		reach.position.y = 0.5
		area.add_child(reach)
		area.position = at
		area.body_entered.connect(func(b: Node) -> void:
			if b is CharacterBody3D: press_plate(which))
		_furniture.add_child(area)


func _write() -> void:
	if _board == null: return
	var n := cuts_made()
	var steep := slope_degrees()
	_board.text = "\n".join(PackedStringArray(["03 / WHERE DOES IT RISE?",
		"Lay a ramp. Make its middle third level, at half its height, and steepen the two ends. Do the same to every ramp that is left.",
		"The stair still arrives. What rises is the Cantor set, and a landing, once made, never moves.", "",
		"cut %d times  |  %d ramps  |  %.0f %% of the length rises  |  %.1f degrees%s" % [n, int(pow(2.0, float(n))), pow(2.0 / 3.0, float(n)) * 100.0, steep,
			"\nPast 45 degrees: the stair arrives and a body does not." if steep > 45.0 else ""]]))


## Plate 0: one more cut. Plate 1: one cut back.
func press_plate(which: int) -> void:
	if _now - _pressed < 1.0: return
	_pressed = _now
	set_cut(clampi(cuts_made() + (1 if which == 0 else -1), 0, CUTS.size() - 1))


func set_cut(index: int) -> void:
	var next: String = CUTS[clampi(index, 0, CUTS.size() - 1)]
	if next == cut: return
	cut = next
	_build()


func _process(delta: float) -> void:
	_now += delta


## ---- for a test ----

func stretches_now() -> Array:
	return stretches(cuts_made(), length, rise)


func foot_point() -> Vector3:
	return to_global(Vector3.ZERO)


func top_point() -> Vector3:
	return to_global(Vector3(length + lip * 0.5, rise, 0))


func plate_centre(which: int) -> Vector3:
	return to_global(_plates[which])


func rebuild_ms() -> float:
	return float(_rebuild_usec) / 1000.0
