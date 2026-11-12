extends Node3D
## THE PERCOLATION CROSSING (floor PG_Percolation_Network; the pass, 2026-11-12)
##
## The hall's lesson compares two cubes that touch by a face with two that touch by a corner, and asks what a
## construction permits a body, a signal or a representation to do. This is that question at the size of the floor.
## A field 12 cells across and 10 deep, 0.8 m a cell, between two side walls. Every cell holds ONE number in [0, 1)
## (a seeded hash). With a share `open` of the field open, a cell is floor when its number is under that share and a
## block when it is not - so opening more never closes a cell, and the same field is watched all the way through.
##   A BODY goes from floor to floor across a shared FACE. Two blocks that touch at a corner leave it no gap.
##   A SIGNAL also passes where two floor cells touch at a CORNER.
## From the visitor's side the field floods: blue where a body gets, pink where only a signal gets (and a thin pink
## post stands on every such cell, so the signal's reach is seen over the blocks). Somewhere
## between a third and two thirds open the pink reaches the far side and the blue does not: the signal crosses and
## you cannot. A little further and you can. On an endless field those two shares are 0.407 and 0.593; a field of 120
## cells decides near them, not on them, and every NEW FIELD decides a little differently.
## Predicted on a bench before the work was built (tools/probes/percolation_bench.py): field 11 lets a signal across
## from 35 % open and a body from 60 %.
##
## Three plates on the visitor's side: OPEN MORE, OPEN LESS, NEW FIELD. A cell with a body on it does not close.
const STEPS: Array[float] = [0.25, 0.30, 0.35, 0.40, 0.45, 0.50, 0.55, 0.60, 0.65, 0.70, 0.75]
const COLS := 12
const ROWS := 10
const CELL := 0.8
const TALL := 1.2
const BODY := Color("5bcefa")
const SIGNAL := Color("f07fa0")
const BARE := Color(0.80, 0.81, 0.84)
const BLOCK := Color(0.30, 0.33, 0.40)
const AROUND: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]

@export var field := 11                 ## which field: the seed of the cells' numbers
@export_range(0.25, 0.75, 0.05) var open := 0.5   ## the share of the field that is floor
@export var flood_cells_per_second := 14.0

var _numbers := PackedFloat64Array()
var _by_face := PackedInt32Array()      # steps from the near row for a body, -1 where it does not get
var _by_corner := PackedInt32Array()    # the same for a signal
var _height := PackedFloat32Array()     # 0 floor .. 1 block, as drawn now
var _solid := PackedByteArray()         # the block's collider is on
var _shapes: Array[CollisionShape3D] = []
var _blocks: MultiMesh
var _tiles: MultiMesh
var _posts: MultiMesh                   # a thin pink post on every cell only a signal reaches: seen over the blocks
var _goal: MeshInstance3D
var _board: Label3D
var _far: Array[Label3D] = []
var _plates: Array[Vector3] = []
var _near := {}
var _front := 0.0
var _pressed := -10.0
var _now := 0.0
var _crossed := 0
var _on_way := {}                       # body -> true once it has stood on the near row
var _spent_usec := 0
var _frames := 0


func _ready() -> void:
	var given := {}
	for key in ["field", "open", "flood_cells_per_second"]:
		if has_meta("config_" + key): given[key] = get_meta("config_" + key)
	_take(given)
	_build()
	_decide()


func _take(config_data: Dictionary) -> bool:
	var changed := false
	if config_data.has("field") and int(float(str(config_data["field"]))) != field:
		field = int(float(str(config_data["field"])))
		changed = true
	if config_data.has("open"):
		var share: float = _step_of(float(str(config_data["open"])))
		if not is_equal_approx(share, open):
			open = share
			changed = true
	if config_data.has("flood_cells_per_second"): flood_cells_per_second = maxf(1.0, float(str(config_data["flood_cells_per_second"])))
	return changed


func apply_grid_config(config_data: Dictionary) -> void:
	if _take(config_data) and is_inside_tree() and _blocks != null: _decide()


## ---- the field ----

static func hash01(key: Array) -> float:
	var h := 2166136261
	for v in key:
		h = ((h ^ (int(v) & 0xffffffff)) * 16777619) & 0xffffffff
		h ^= h >> 13
		h = (h * 1274126177) & 0xffffffff
	h ^= h >> 16
	return float(h & 0xffffff) / 16777216.0


func _step_of(share: float) -> float:
	var best: float = STEPS[0]
	for s in STEPS:
		if absf(s - share) < absf(best - share): best = s
	return best


func cell_index(c: int, r: int) -> int:
	return c * ROWS + r


func is_open(c: int, r: int) -> bool:
	return c >= 0 and c < COLS and r >= 0 and r < ROWS and _numbers[cell_index(c, r)] < open


## Steps from the near row to every floor cell it reaches; -1 elsewhere. `corners`: a signal, not a body.
func _reach(corners: bool) -> PackedInt32Array:
	var steps := PackedInt32Array()
	steps.resize(COLS * ROWS)
	steps.fill(-1)
	var line: Array[Vector2i] = []
	for c in COLS:
		if is_open(c, 0):
			steps[cell_index(c, 0)] = 0
			line.append(Vector2i(c, 0))
	var head := 0
	while head < line.size():
		var at: Vector2i = line[head]
		head += 1
		for k in (8 if corners else 4):
			var next: Vector2i = at + AROUND[k]
			if is_open(next.x, next.y) and steps[cell_index(next.x, next.y)] < 0:
				steps[cell_index(next.x, next.y)] = steps[cell_index(at.x, at.y)] + 1
				line.append(next)
	return steps


## The numbers of this field, who gets where at this share, and the flood begins again.
func _decide() -> void:
	_numbers.resize(COLS * ROWS)
	for c in COLS:
		for r in ROWS: _numbers[cell_index(c, r)] = hash01([field, c, r])
	_by_face = _reach(false)
	_by_corner = _reach(true)
	_front = 0.0
	_crossed = 0
	_on_way.clear()
	for i in _shapes.size():
		if _numbers[i] < open and _solid[i] == 1:        # a block that opens lets go at once
			_solid[i] = 0
			_shapes[i].disabled = true
	_paint()
	_write()


func crosses() -> Dictionary:
	var body := false
	var signal_only := false
	var floor_cells := 0
	var body_cells := 0
	var signal_cells := 0
	for c in COLS:
		for r in ROWS:
			var i := cell_index(c, r)
			if _numbers[i] < open: floor_cells += 1
			if _by_face[i] >= 0: body_cells += 1
			if _by_corner[i] >= 0: signal_cells += 1
			if r == ROWS - 1:
				if _by_face[i] >= 0: body = true
				if _by_corner[i] >= 0: signal_only = true
	return {"body": body, "signal": signal_only, "floor": floor_cells, "body_reach": body_cells, "signal_reach": signal_cells}


## ---- what stands ----

func _cell_at(c: int, r: int) -> Vector3:
	return Vector3((float(c) - float(COLS - 1) * 0.5) * CELL, 0.0, (float(ROWS - 1) * 0.5 - float(r)) * CELL)      # row 0 on the visitor's side (+z)


func _build() -> void:
	var count := COLS * ROWS
	_height.resize(count)
	_height.fill(0.0)
	_solid.resize(count)
	_solid.fill(0)
	var flat := StandardMaterial3D.new()
	flat.vertex_color_use_as_albedo = true
	flat.vertex_color_is_srgb = true
	flat.roughness = 0.9
	# the flood is a colour code, not a surface: under this hall's strong light a lit pink tile reads as white
	var paint := StandardMaterial3D.new()
	paint.vertex_color_use_as_albedo = true
	paint.vertex_color_is_srgb = true
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_tiles = MultiMesh.new()
	_tiles.transform_format = MultiMesh.TRANSFORM_3D
	_tiles.use_colors = true
	var tile := BoxMesh.new()
	tile.size = Vector3(CELL * 0.95, 0.02, CELL * 0.95)
	_tiles.mesh = tile
	_tiles.instance_count = count
	_blocks = MultiMesh.new()
	_blocks.transform_format = MultiMesh.TRANSFORM_3D
	_blocks.use_colors = true
	var cube := BoxMesh.new()
	cube.size = Vector3(CELL, TALL, CELL)
	_blocks.mesh = cube
	_blocks.instance_count = count
	var body := StaticBody3D.new()
	body.name = "Blocks"
	add_child(body)
	var box := BoxShape3D.new()
	box.size = Vector3(CELL, TALL, CELL)
	for c in COLS:
		for r in ROWS:
			var i := cell_index(c, r)
			_tiles.set_instance_transform(i, Transform3D(Basis(), _cell_at(c, r) + Vector3(0, 0.012, 0)))
			_blocks.set_instance_color(i, BLOCK)
			_blocks.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(1, 0.001, 1)), _cell_at(c, r)))
			var shape := CollisionShape3D.new()
			shape.shape = box
			shape.position = _cell_at(c, r) + Vector3(0, TALL * 0.5, 0)
			shape.disabled = true
			body.add_child(shape)
			_shapes.append(shape)
	_posts = MultiMesh.new()
	_posts.transform_format = MultiMesh.TRANSFORM_3D
	var post_mesh := BoxMesh.new()
	post_mesh.size = Vector3(0.07, TALL + 0.45, 0.07)
	_posts.mesh = post_mesh
	_posts.instance_count = count
	for i in count: _posts.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(1, 0.001, 1)), _cell_at(i / ROWS, i % ROWS)))
	var pink := StandardMaterial3D.new()
	pink.albedo_color = SIGNAL
	pink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var posts := MultiMeshInstance3D.new()
	posts.name = "SignalPosts"
	posts.multimesh = _posts
	posts.material_override = pink
	posts.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(posts)
	for pair in [["Floor", _tiles], ["Standing", _blocks]]:
		var shown := MultiMeshInstance3D.new()
		shown.name = pair[0]
		shown.multimesh = pair[1]
		shown.material_override = paint if pair[0] == "Floor" else flat
		add_child(shown)
	# the two side walls: the field is a channel from this side to the far one
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.16, 0.17, 0.21)
	dark.roughness = 0.85
	var deep: float = float(ROWS) * CELL
	for side in [-1.0, 1.0]:
		var wall := StaticBody3D.new()
		wall.name = "Side"
		wall.position = Vector3(side * (float(COLS) * 0.5 + 0.5) * CELL, TALL * 0.5, 0)
		var solid := BoxShape3D.new()
		solid.size = Vector3(CELL, TALL, deep)
		var shape := CollisionShape3D.new()
		shape.shape = solid
		wall.add_child(shape)
		var shown := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(CELL, TALL, deep)
		shown.mesh = mesh
		shown.material_override = dark
		wall.add_child(shown)
		add_child(wall)
	# the far side: a strip that takes the colour of whoever gets there
	_goal = MeshInstance3D.new()
	_goal.name = "FarSide"
	var strip := BoxMesh.new()
	strip.size = Vector3(float(COLS) * CELL, 0.03, 0.35)
	_goal.mesh = strip
	var glow := StandardMaterial3D.new()
	glow.albedo_color = BARE
	glow.emission_enabled = true
	glow.emission = BARE
	glow.emission_energy_multiplier = 0.0
	_goal.material_override = glow
	_goal.position = Vector3(0, 0.02, -deep * 0.5 - 0.25)
	add_child(_goal)
	# the far side says who has arrived, large enough to read from this side
	var banner := Node3D.new()
	banner.name = "FarSign"
	banner.position = Vector3(0, 0, -deep * 0.5 - 0.75)
	add_child(banner)
	var sheet := MeshInstance3D.new()
	var sheet_mesh := BoxMesh.new()
	sheet_mesh.size = Vector3(6.6, 1.5, 0.06)
	sheet.mesh = sheet_mesh
	sheet.material_override = dark
	sheet.position.y = 2.5
	banner.add_child(sheet)
	for side in [-3.1, 3.1]:
		var mast := MeshInstance3D.new()
		var pole := BoxMesh.new()
		pole.size = Vector3(0.08, 1.75, 0.06)
		mast.mesh = pole
		mast.material_override = dark
		mast.position = Vector3(side, 0.875, 0)
		banner.add_child(mast)
	for line in 3:
		var words := Label3D.new()
		words.pixel_size = [0.0075, 0.0055, 0.0035][line]
		words.font_size = 48
		words.outline_size = 8
		words.outline_modulate = Color(0, 0, 0, 1)
		words.position = Vector3(0, [2.95, 2.45, 2.0][line], 0.035)
		banner.add_child(words)
		_far.append(words)
	_far[0].text = "CAN YOU GET ACROSS?"
	_far[0].modulate = Color(0.92, 0.95, 1.0)
	# board and plates on the visitor's side, west of the channel: nothing to step on lies in front of a cell one enters by
	var stand := Node3D.new()
	stand.name = "Board"
	stand.position = Vector3(-float(COLS) * 0.5 * CELL - 1.8, 0, deep * 0.5 + 0.9)
	stand.rotation.y = 0.8
	add_child(stand)
	var panel := MeshInstance3D.new()
	var face := BoxMesh.new()
	face.size = Vector3(2.5, 1.3, 0.06)
	panel.mesh = face
	panel.material_override = dark
	panel.position.y = 1.35
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
	_board.position = Vector3(0, 1.35, 0.035)
	stand.add_child(_board)
	var pad := BoxMesh.new()
	pad.size = Vector3(0.7, 0.03, 0.7)
	var press := BoxShape3D.new()
	press.size = Vector3(0.6, 1.0, 0.6)
	var words := ["OPEN\nMORE", "OPEN\nLESS", "NEW\nFIELD"]
	for which in 3:
		var at := Vector3(-float(COLS) * 0.5 * CELL - 2.4 + float(which) * 1.05, 0.015, deep * 0.5 + 1.9)
		_plates.append(at)
		var plate := MeshInstance3D.new()
		plate.mesh = pad
		plate.material_override = dark
		plate.position = at
		add_child(plate)
		var word := Label3D.new()
		word.text = words[which]
		word.pixel_size = 0.003
		word.font_size = 34
		word.modulate = Color(1.0, 0.82, 0.16)
		word.rotation_degrees = Vector3(-90, 0, 0)
		word.position = at + Vector3(0, 0.02, 0)
		add_child(word)
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
		add_child(area)
	var zone := Area3D.new()
	zone.name = "Near"
	zone.collision_layer = 0
	zone.collision_mask = 0xFFFFFFFF
	var room := BoxShape3D.new()
	room.size = Vector3(float(COLS + 2) * CELL + 3.0, 3.0, deep + 5.0)
	var room_shape := CollisionShape3D.new()
	room_shape.shape = room
	room_shape.position = Vector3(0, 1.5, 0.5)
	zone.add_child(room_shape)
	zone.body_entered.connect(func(b: Node) -> void:
		if b is CharacterBody3D: _near[b] = true)
	zone.body_exited.connect(func(b: Node) -> void:
		_near.erase(b); _on_way.erase(b))
	add_child(zone)


func _paint() -> void:
	var reached_by_body := false
	var reached_by_signal := false
	for c in COLS:
		for r in ROWS:
			var i := cell_index(c, r)
			var tone := BARE
			if _numbers[i] >= open: tone = BLOCK
			elif _by_face[i] >= 0 and float(_by_face[i]) <= _front:
				tone = BODY
				if r == ROWS - 1: reached_by_body = true
			elif _by_corner[i] >= 0 and float(_by_corner[i]) <= _front:
				tone = SIGNAL
				if r == ROWS - 1: reached_by_signal = true
			_tiles.set_instance_color(i, tone)
			var up: float = 1.0 if tone == SIGNAL else 0.001
			_posts.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(1, up, 1)), _cell_at(c, r) + Vector3(0, (TALL + 0.45) * 0.5 * up, 0)))
	var far := BODY if reached_by_body else (SIGNAL if reached_by_signal else BARE)
	var glow: StandardMaterial3D = _goal.material_override
	glow.albedo_color = far
	glow.emission = far
	glow.emission_energy_multiplier = 0.0 if far == BARE else 0.9


func _write() -> void:
	if _board == null: return
	var now: Dictionary = crosses()
	if _far.size() == 3:
		_far[1].text = "A BODY GETS ACROSS." if now["body"] else ("A SIGNAL GETS ACROSS. A BODY DOES NOT." if now["signal"] else "NOTHING GETS ACROSS.")
		_far[1].modulate = BODY if now["body"] else (SIGNAL if now["signal"] else BARE)
		_far[2].text = "field %d    %d %% open" % [field, int(roundf(open * 100.0))]
		_far[2].modulate = BARE
	_board.text = "\n".join(PackedStringArray(["CAN YOU GET ACROSS?",
		"Each cell holds one number. It is floor when the number is under the share that is open, a block when it is not: opening more never closes a cell.",
		"BLUE is where a body gets from this side, floor to floor across a shared face. PINK is where only a signal gets: it also passes where two cells touch at a corner. Two blocks that touch at a corner leave a body no gap.", "",
		"field %d  |  open %d %%  |  a signal %s  |  a body %s%s" % [field, int(roundf(open * 100.0)), "crosses" if now["signal"] else "does not cross", "crosses" if now["body"] else "does not cross",
			"" if _crossed == 0 else "  |  crossed on foot: %d" % _crossed]]))


## Plate 0: open more. Plate 1: open less. Plate 2: a new field.
func press_plate(which: int) -> void:
	if _now - _pressed < 0.9: return
	_pressed = _now
	if which == 2: set_field(field + 1)
	else: set_open(open + (0.05 if which == 0 else -0.05))


func set_open(share: float) -> void:
	var next := _step_of(share)
	if is_equal_approx(next, open): return
	open = next
	_decide()


func set_field(number: int) -> void:
	if number == field: return
	field = number
	_decide()


func _process(delta: float) -> void:
	var began := Time.get_ticks_usec()
	_now += delta
	var moving := false
	for i in _height.size():
		var want: float = 0.0 if _numbers[i] < open else 1.0
		if is_equal_approx(_height[i], want): continue
		moving = true
		_height[i] = move_toward(_height[i], want, delta * 3.0)
		var at: Vector3 = _cell_at(i / ROWS, i % ROWS)
		_blocks.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(1, maxf(_height[i], 0.001), 1)), at + Vector3(0, TALL * 0.5 * _height[i], 0)))
	var deepest: float = float(COLS * ROWS)
	if _front < deepest:
		_front = minf(deepest, _front + delta * flood_cells_per_second)
		_paint()
	_spent_usec += Time.get_ticks_usec() - began
	_frames += 1


func _physics_process(_delta: float) -> void:
	# a block comes down only on a cell nobody stands on; who walks the near row and then the far one has crossed
	var taken := {}
	for b in _near:
		if not is_instance_valid(b): continue
		var here: Vector3 = to_local((b as Node3D).global_position)
		var c: int = floori(here.x / CELL + float(COLS) * 0.5)
		var r: int = floori(float(ROWS) * 0.5 - here.z / CELL)
		if c < 0 or c >= COLS or r < 0 or r >= ROWS or here.y > 0.6:
			continue
		for dc in [-1, 0, 1]:
			for dr in [-1, 0, 1]:
				var cc: int = c + dc
				var rr: int = r + dr
				if cc < 0 or cc >= COLS or rr < 0 or rr >= ROWS: continue
				var middle: Vector3 = _cell_at(cc, rr)
				if absf(here.x - middle.x) < CELL * 0.5 + 0.3 and absf(here.z - middle.z) < CELL * 0.5 + 0.3: taken[cell_index(cc, rr)] = true
		if r == 0: _on_way[b] = true
		elif r == ROWS - 1 and _on_way.has(b):
			_on_way.erase(b)
			_crossed += 1
			_write()
	for i in _shapes.size():
		if _numbers[i] >= open and _solid[i] == 0 and not taken.has(i):
			_solid[i] = 1
			_shapes[i].disabled = false


## ---- for a test ----

func is_solid(c: int, r: int) -> bool:
	return _solid[cell_index(c, r)] == 1


func cell_centre(c: int, r: int) -> Vector3:
	return to_global(_cell_at(c, r))


func plate_centre(which: int) -> Vector3:
	return to_global(_plates[which])


func crossed_on_foot() -> int:
	return _crossed


func settled() -> bool:
	for i in _height.size():
		if not is_equal_approx(_height[i], 0.0 if _numbers[i] < open else 1.0): return false
		if (_numbers[i] >= open) != (_solid[i] == 1): return false
	return _front >= float(COLS * ROWS)


func frame_ms() -> float:
	var ms := float(_spent_usec) / 1000.0 / maxf(1.0, float(_frames))
	_spent_usec = 0
	_frames = 0
	return ms
