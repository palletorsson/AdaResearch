# layer_sum_islands.gd
# The noise mixer's sum, taken apart and laid out for the feet: each layer as a ground of its own, then all of them added.
#
# @identity
# essence: h_i(x, z) = height * weigh^i * wave(f * 2^i * (x, z)) for i = 0..3, and h(x, z) = h_0 + h_1 + h_2 + h_3.
#   Five islands in a row from one seed: four hold one layer each (the same wave, twice as fine and `weigh` as tall
#   each time), the fifth holds their sum. Every island rises from the floor on its east shore and ends in cut
#   faces on the other three sides.
# desire: to be walked in order. One wave is hills. The same wave twice as fine is ripples; four times, gravel. On
#   the last island all of them are underfoot at once, and that is the one the eye calls land.
# critical_parameter: weigh - how much each finer layer weighs against the one before (fading | halving |
#   lingering = 0.35 | 0.5 | 0.7). At `halving` every layer is as steep as the first and the sum can be crossed. At
#   `lingering` each finer layer is steeper than the last and the sum is a rock field.
# triggers: the DRAW AGAIN plate draws new offsets for every layer; the WEIGH plate steps through the three weights.
# emerges: the cut faces of the last island show four bands lying on each other, and each band is the cut face of
#   one of the four islands before it. The sum is not a new thing; it is the four, stacked.
# needs: 4.4 x 16.4 m of floor [has in the west bay]; a body that walks [the tower's walker climbs under 45 degrees].
# relationships: the body-scale sibling of [[noise_mixer]] - the same wave function, the same seeded offsets, the
#   same colour ramp, so the last island seen from above IS the mixer's picture (its upper two thirds). Beside
#   [[random_space]], the ground where no height knows the next: here every height is a sum of waves and
#   neighbours agree at four scales. After [[noise_ground_pair]] (drawn alone | related).
# truth: Complexity is layered repetition. The same simple wave, run at four frequencies simultaneously, looks like
#   land. (Carried from noise_mixer.) What a body adds: you can stand on each term of the sum.
# lineage: MATH - Fourier's sum of waves; Mandelbrot's fractional Brownian surfaces (1975) and Musgrave's terrain
#   from summed octaves (1989): lacunarity and gain are his words. ART - Hokusai's Great Wave, a wave made of
#   smaller waves. DESIGN - the contour model of card layers. ARCHITECTURE - the geological section: a hill drawn as
#   strata.
# history: 2026-11-12, the Void. Floor Random_Space gives the body a ground of independent draws; its main work,
#   the noise mixer, is an 80 cm picture on a plinth with three sliders. Read as code the picture is a sum of four
#   terms, and nothing on the floor let a body meet a term.
# measured: 2026-11-12. Bench, seed 42, first layer 0.35 m: steepest rise over run of the sum is 0.74 at `fading`,
#   0.99 at `halving`, 1.53 at `lingering` (the layers alone: 0.41, 0.51, 0.36, 0.20 at `halving`). In the tower
#   the Void's walker stood at the same three spots on all five islands: its feet were within 4 cm of the drawn
#   height everywhere, and the four layers' heights added up to the fifth's. It crossed the sum from shore to cut
#   face on two of three lines at `halving` (stopped 0.8 m short on the third) and on one of three at `lingering`
#   (stopped 2.7 and 4.4 m short). So "can be crossed" is true of most lines, not of every line.

extends Node3D

const Stock := preload("res://commons/artifacts/construction_site/stock.gd")
const WEIGHTS := {"fading": .35, "halving": .5, "lingering": .7}
const LAYER_COLOURS: Array[Color] = [Color("3d6e78"), Color("c9a23f"), Color("b65a3c"), Color("e6dcc6"), Color("7a5c8e")]
## The noise mixer's earth-tone ramp, low to high.
const RAMP: Array[Color] = [
	Color(0.12, 0.18, 0.28), Color(0.18, 0.30, 0.22), Color(0.28, 0.42, 0.20), Color(0.52, 0.55, 0.30), Color(0.68, 0.58, 0.35),
	Color(0.75, 0.65, 0.45), Color(0.55, 0.45, 0.35), Color(0.72, 0.70, 0.68), Color(0.88, 0.86, 0.84)]

## How much each finer layer weighs against the one before.
@export_enum("fading", "halving", "lingering") var weigh := "halving"
@export var seed_value := 42                ## the noise mixer's own seed: the last island is its picture
@export_range(2, 5) var layers := 4
@export var island := Vector2(4.4, 2.8)     ## metres, east-west by north-south
@export var gap := 0.6                      ## floor between two islands: a corridor between two cut faces
@export var cell := 0.1
@export var height := 0.35                  ## the range of the first layer, metres: at `halving` the sum stays near 45 degrees at its worst
@export var lacunarity := 2.0
@export var base_frequency := 4.0
@export var shore := 1.4                    ## metres over which every island comes up from the floor on its east side

var _offsets: Array[Vector2] = []
var _heights: Array[PackedFloat32Array] = []      # per layer, at every corner of one island, shore included
var _tone := PackedFloat32Array()                 # the mixer's own normalised value at every corner
var _nx := 0
var _nz := 0
var _built: Array[Node] = []
var _fixed: Array[Node] = []
var _last_step := -10.0
var _ink: Material
var _post: Material


func _ready() -> void:
	_read_config()
	_ink = Stock.finish("d9cfbd", .9)
	_post = Stock.finish("76695a", .95)
	rebuild()


func _read_config() -> void:
	if has_meta("config_weigh") and WEIGHTS.has(str(get_meta("config_weigh"))):
		weigh = str(get_meta("config_weigh"))
	for key in ["seed_value", "layers"]:
		for meta in ["config_" + key, "config_seed" if key == "seed_value" else ""]:
			if meta != "" and has_meta(meta): set(key, int(str(get_meta(meta)).to_float()))
	for key in ["gap", "cell", "height", "lacunarity", "base_frequency", "shore"]:
		if has_meta("config_" + key): set(key, str(get_meta("config_" + key)).to_float())


func apply_grid_config(config_data: Dictionary) -> void:
	for key in config_data:
		set_meta("config_" + str(key), config_data[key])
	_read_config()
	if is_inside_tree() and _ink != null:
		rebuild()


func _weight() -> float:
	return float(WEIGHTS[weigh])


## The noise mixer's wave, line for line: five sines at angles that do not repeat together.
func _wave(x: float, y: float) -> float:
	var v := 0.0
	v += sin(x * 1.0 + y * 1.7)
	v += sin(x * 2.3 - y * 0.9)
	v += sin((x + y) * 1.3 + 0.5)
	v += sin((x - y) * 1.8 - 0.3)
	v += sin(x * 0.7 + y * 2.1 + x * y * 0.15)
	return v / 5.0


func _ramp(t: float) -> Color:
	t = clampf(t, 0.0, 1.0)
	var at := t * float(RAMP.size() - 1)
	var k := mini(int(at), RAMP.size() - 2)
	return RAMP[k].lerp(RAMP[k + 1], at - float(k))


## The layers at every corner of one island. All five islands are the same piece of the same field.
func _compute() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	_offsets.clear()
	for i in 8:      # the mixer draws eight pairs whatever it uses: the same stream, the same offsets
		_offsets.append(Vector2(rng.randf_range(-100.0, 100.0), rng.randf_range(-100.0, 100.0)))
	_nx = roundi(island.x / cell) + 1
	_nz = roundi(island.y / cell) + 1
	_heights.clear()
	var raw: Array[PackedFloat32Array] = []
	for i in layers:
		var one := PackedFloat32Array()
		one.resize(_nx * _nz)
		var unscaled := PackedFloat32Array()
		unscaled.resize(_nx * _nz)
		var amplitude := height * pow(_weight(), i)
		var frequency := base_frequency * pow(lacunarity, i)
		for j in _nz:
			for k in _nx:
				var u := float(k) * cell / island.x              # the mixer's picture is one unit wide
				var v := float(j) * cell / island.x
				var w := _wave(u * frequency + _offsets[i].x, v * frequency + _offsets[i].y)
				var rise := smoothstep(0.0, shore, island.x - float(k) * cell)      # the east shore: up from the floor
				one[j * _nx + k] = amplitude * (.5 + .5 * clampf(w, -1.0, 1.0)) * rise
				unscaled[j * _nx + k] = pow(_weight(), i) * w
		_heights.append(one)
		raw.append(unscaled)
	# the mixer normalises its sum over the whole unit square; so does the colour here
	var low := INF
	var high := -INF
	for j in 49:
		for k in 49:
			var total := 0.0
			for i in layers:
				var frequency := base_frequency * pow(lacunarity, i)
				total += pow(_weight(), i) * _wave(k / 48.0 * frequency + _offsets[i].x, j / 48.0 * frequency + _offsets[i].y)
			low = minf(low, total)
			high = maxf(high, total)
	_tone.resize(_nx * _nz)
	for index in _nx * _nz:
		var total := 0.0
		for i in layers:
			total += raw[i][index]
		_tone[index] = (total - low) / maxf(.0001, high - low)


## Island `which` holds layer `which`; the last one (which == layers) holds the sum.
func _island_z(which: int) -> float:
	var count := layers + 1
	var length := count * island.y + (count - 1) * gap
	return length / 2.0 - island.y / 2.0 - which * (island.y + gap)      # the first layer stands at the south end


func _height(which: int, index: int) -> float:
	if which < layers:
		return _heights[which][index]
	var total := 0.0
	for i in layers:
		total += _heights[i][index]
	return total


func _grounds() -> void:
	var points := PackedVector3Array()
	var normals := PackedVector3Array()
	var colours := PackedColorArray()
	var indices := PackedInt32Array()
	for which in layers + 1:
		var origin := Vector3(-island.x / 2.0, 0, _island_z(which) - island.y / 2.0)
		var base := points.size()
		for j in _nz:
			for k in _nx:
				var index := j * _nx + k
				var y := _height(which, index)
				points.append(origin + Vector3(k * cell, y + .012, j * cell))
				var west := _height(which, j * _nx + maxi(k - 1, 0))
				var east := _height(which, j * _nx + mini(k + 1, _nx - 1))
				var north := _height(which, maxi(j - 1, 0) * _nx + k)
				var south := _height(which, mini(j + 1, _nz - 1) * _nx + k)
				normals.append(Vector3(west - east, 2.0 * cell, north - south).normalized())
				colours.append(_ramp(_tone[index]) if which == layers else LAYER_COLOURS[which])
		for j in _nz - 1:
			for k in _nx - 1:
				var a := base + j * _nx + k
				indices.append_array([a, a + 1, a + _nx + 1, a, a + _nx + 1, a + _nx])
		# the cut faces: west, north and south. On the last island the layers lie on each other.
		var bands: Array = range(layers) if which == layers else [which]
		for edge in 3:
			var steps := _nz - 1 if edge == 0 else _nx - 1
			var outward := [Vector3.LEFT, Vector3.FORWARD, Vector3.BACK][edge] as Vector3
			for s in steps:
				var first := 0
				var second := 0
				match edge:
					0: first = (s + 1) * _nx; second = s * _nx                          # west: x = 0, walking north
					1: first = s; second = s + 1                                        # north: z = 0
					2: first = (_nz - 1) * _nx + s + 1; second = (_nz - 1) * _nx + s    # south: z = depth
				var p := origin + Vector3((first % _nx) * cell, 0, (first / _nx) * cell)
				var q := origin + Vector3((second % _nx) * cell, 0, (second / _nx) * cell)
				var under_p := 0.0
				var under_q := 0.0
				for band: int in bands:
					var top_p := under_p + _heights[band][first]
					var top_q := under_q + _heights[band][second]
					var start := points.size()
					points.append_array([p + Vector3(0, under_p, 0), q + Vector3(0, under_q, 0), q + Vector3(0, top_q + .012, 0), p + Vector3(0, top_p + .012, 0)])
					for n in 4:
						normals.append(outward)
						colours.append(LAYER_COLOURS[band].darkened(.12))
					indices.append_array([start, start + 1, start + 2, start, start + 2, start + 3])
					under_p = top_p
					under_q = top_q
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colours
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = .9
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var body := StaticBody3D.new()
	body.name = "Islands"
	add_child(body)
	_built.append(body)
	var instance := MeshInstance3D.new()
	instance.name = "Surface"
	instance.mesh = mesh
	instance.material_override = material
	body.add_child(instance)
	var faces := PackedVector3Array()
	faces.resize(indices.size())
	for n in indices.size():
		faces[n] = points[indices[n]]
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)


func _board(text: String, at: Vector3) -> void:
	for dz in [-.72, .72]:
		_fixed.append(Stock.box(self, "SignPost", Vector3(at.x, at.y / 2.0, at.z + dz), Vector3(.05, at.y, .05), _post, false))
	var board := Stock.box(self, "SignBoard", at, Vector3(.03, .42, 1.6), _ink, false)
	_fixed.append(board)
	var label := Label3D.new()
	label.text = text
	label.font_size = 48
	label.pixel_size = .0011
	label.outline_size = 0
	label.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	label.modulate = Color("202329")
	label.rotation.y = PI / 2.0      # the words face east, toward a body on the walk along the shore
	label.position = Vector3(.02, 0, 0)
	board.add_child(label)


func _plate(title: String, text: String, at: Vector3, colour: String, action: Callable) -> void:
	var plate := Stock.box(self, title, at, Vector3(.8, .04, .8), Stock.finish(colour, .6), false)
	_fixed.append(plate)
	var words := Label3D.new()
	words.text = text
	words.font_size = 44
	words.pixel_size = .0015
	words.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	words.modulate = Color("f3ece2")
	words.rotation_degrees = Vector3(-90, 90, 0)      # read by a body that comes along the shore from the south
	words.position = Vector3(0, .025, 0)
	plate.add_child(words)
	var area := Area3D.new()
	area.name = title + "Area"
	area.collision_layer = 0
	area.collision_mask = 0xFFFFFFFF
	area.position = at + Vector3(0, .5, 0)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(.8, 1.0, .8)
	shape.shape = box
	area.add_child(shape)
	add_child(area)
	_fixed.append(area)
	area.body_entered.connect(func(body: Node) -> void:
		if not body is CharacterBody3D: return
		var now := Time.get_ticks_msec() / 1000.0
		if now - _last_step < 1.5: return
		_last_step = now
		action.call())


func _furniture() -> void:
	var w := _weight()
	var east := island.x / 2.0 + .12
	for which in layers + 1:
		var text := "ALL %d, ADDED\nthe one the eye calls land" % layers
		if which == 0:
			text = "ONE WAVE\nat its full height"
		elif which < layers:
			text = "THE SAME WAVE, %d TIMES AS FINE\n%s as tall" % [roundi(pow(lacunarity, which)), String.num(pow(w, which), 2)]
		# the two end islands face a column of the tower: their boards stand toward the middle of the row
		var along := -.9 if which == 0 else (.9 if which == layers else 0.0)
		_board(text, Vector3(east, 2.2, _island_z(which) + along))
	var south := _island_z(0) + island.y / 2.0
	_plate("DrawAgain", "DRAW AGAIN\nseed %d" % seed_value, Vector3(east + .6, .02, south - 2.4), "c8452f", func() -> void:
		seed_value += 1
		rebuild())
	_plate("Weigh", "EACH FINER LAYER\nWEIGHS x %s" % String.num(w, 2), Vector3(east + .6, .02, south - 3.6), "3d6e78", func() -> void:
		var names := WEIGHTS.keys()
		weigh = names[(names.find(weigh) + 1) % names.size()]
		rebuild())


## Draw the five grounds again from the seed and the weight as they stand.
func rebuild() -> void:
	for node in _built + _fixed:
		if is_instance_valid(node):
			node.queue_free()
	_built.clear()
	_fixed.clear()
	_compute()
	_grounds()
	_furniture()


# ---------------------------------------------------------------- for probes

## The place on island `which` at (u, v) of its ground (0..1 east-west from the WEST face, 0..1 north to south), with
## the ground's height there, in the work's own metres.
func spot(which: int, u: float, v: float) -> Vector3:
	var k := clampi(roundi(u * (_nx - 1)), 0, _nx - 1)
	var j := clampi(roundi(v * (_nz - 1)), 0, _nz - 1)
	return Vector3(-island.x / 2.0 + k * cell, _height(which, j * _nx + k), _island_z(which) - island.y / 2.0 + j * cell)


## The steepest rise between two neighbouring corners of island `which`, as rise over run.
func steepest(which: int) -> float:
	var worst := 0.0
	for j in _nz:
		for k in _nx:
			var here := _height(which, j * _nx + k)
			if k + 1 < _nx: worst = maxf(worst, absf(_height(which, j * _nx + k + 1) - here) / cell)
			if j + 1 < _nz: worst = maxf(worst, absf(_height(which, (j + 1) * _nx + k) - here) / cell)
	return worst


func tallest(which: int) -> float:
	var best := 0.0
	for index in _nx * _nz:
		best = maxf(best, _height(which, index))
	return best
