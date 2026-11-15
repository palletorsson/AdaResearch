extends Node3D
## THE LIGHT RECOMMENDS, THE FEET DECIDE (floor QFEP_Lambda_Spectrum; the pass, 2026-11-15)
##
## The hall: "Move LIT STRIP. The light slides across the floor; the rows do not follow ... Light has made a
## recommendation, not cleared a passage." "There are two kinds of preference visible now: the one you can move,
## and the one already built into the rows." "Would another visitor choose differently after seeing your version
## first?" "Even with that comparison, the slider records no reason for a visitor's choice." This is a field that
## keeps the three apart - a recommendation, an arrangement, and a record of use - a PLAYGROUND form.
##
## A field six metres by ten, of card tiles that darken where feet have gone. Three rows of posts cross it, each
## with one gap, and the gaps line up: the arrangement. A lit strip runs the field's length: the recommendation.
## At first it lies through the gaps. The plates move it west, or east, where it points straight at posts. Walk:
## the feet still go through the gaps, and the tiles show it to whoever comes next.
##
## A stand counts crossings, the share of steps taken on the lit strip, where the field is most worn, and how far
## the light lies from that. One plate lights what was worn: the recommendation follows use, and it is then the
## first walkers' version that is put to the next. SWEEP takes the wear away. The stand ends: it records where
## feet went; it records no reason.
##
## `lit` is the axis: gap, west, east - where the light lies when the field is found.
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const CELL := 0.5
const NX := 12                           # six metres across
const NZ := 20                           # ten metres long
const HALF_W := 3.0
const HALF_L := 5.0
const GAP_X := -1.25                     # the gaps line up here: the middle of a column of tiles
const GAP := 1.2
const ROWS_Z := [2.5, 0.0, -2.5]
const LIT := {"gap": -1.25, "west": -2.25, "east": 1.75}
const PLATES := [
	{"key": "west", "says": "LIGHT\nWEST", "at": Vector2(-2.6, 5.75)},
	{"key": "gap", "says": "LIGHT\nTHE GAPS", "at": Vector2(-1.5, 5.75)},
	{"key": "east", "says": "LIGHT\nEAST", "at": Vector2(-0.4, 5.75)},
	{"key": "worn", "says": "LIGHT WHAT\nWAS WORN", "at": Vector2(0.9, 5.75)},
	{"key": "sweep", "says": "SWEEP", "at": Vector2(2.2, 5.75)},
]
const PLATE := 0.84
const CARD := Color("c9bb9c")
const TROD := Color("3a2a1c")
const GLOW := Color(1.0, 0.94, 0.55, 0.42)
const DARK := Color("191e29")
const PALE := Color("efe9dc")
const AMBER := Color("f2a23a")

@export_enum("gap", "west", "east") var lit := "gap"

var _city = City.new()
var _tiles: MultiMesh
var _wear := PackedInt32Array()
var _strip: MeshInstance3D
var _plate_tiles: Array[MeshInstance3D] = []
var _lit_x := -1.25
var _lit_name := "gap"
var _cell := -1
var _steps := 0
var _on_lit := 0
var _crossings := 0
var _end := 0                            # the end the walker last stood at: 1 south, -1 north
var _region := ""
var _still := 0.0
var _last := Vector3.ZERO
var _light_words: Label3D
var _count_words: Label3D
var _worn_words: Label3D
var _status: Label3D
var _board: Label3D
var _build_ms := 0


func _ready() -> void:
	if has_meta("config_lit"): _take({"lit": get_meta("config_lit")})
	_wear.resize(NX * NZ)
	var began := Time.get_ticks_msec()
	_build_once()
	_build_ms = Time.get_ticks_msec() - began
	_light(lit)


func _take(config_data: Dictionary) -> void:
	if config_data.has("lit") and LIT.has(str(config_data["lit"])): lit = str(config_data["lit"])


func apply_grid_config(config_data: Dictionary) -> void:
	var before := lit
	_take(config_data)
	if is_inside_tree() and _board != null and lit != before:
		_sweep()
		_light(lit)


## ---- the rule ----

static func column_x(cx: int) -> float:
	return -HALF_W + (float(cx) + 0.5) * CELL


## The column of tiles most worn, or -1 when nothing is; of equals, the one first met from the west.
static func most_worn(wear: PackedInt32Array) -> int:
	var best := -1
	var most := 0
	for cx in NX:
		var sum := 0
		for cz in NZ: sum += wear[cz * NX + cx]
		if sum > most:
			most = sum
			best = cx
	return best


func worn_x() -> float:
	var cx: int = most_worn(_wear)
	return column_x(cx) if cx >= 0 else NAN


func _light(key: String) -> void:
	if key == "worn":
		if most_worn(_wear) < 0: return
		_lit_x = worn_x()
	else:
		_lit_x = float(LIT[key])
	_lit_name = key
	_steps = 0
	_on_lit = 0
	_show()
	_tell()


func _sweep() -> void:
	_wear.fill(0)
	for i in NX * NZ: _tiles.set_instance_color(i, CARD)
	_steps = 0
	_on_lit = 0
	_crossings = 0
	_show()
	_tell()


func _visitor() -> Node3D:
	var game: Node = get_tree().get_first_node_in_group("void_game")
	return game.get("body") as Node3D if game != null else null


func _physics_process(delta: float) -> void:
	var body := _visitor()
	if body == null: return
	var p := to_local(body.global_position)
	var region := ""
	var changed := false
	if absf(p.y) < 1.5:
		if absf(p.x) < HALF_W and absf(p.z) < HALF_L:
			region = "field"
			var cx: int = clampi(int(floor((p.x + HALF_W) / CELL)), 0, NX - 1)
			var cz: int = clampi(int(floor((p.z + HALF_L) / CELL)), 0, NZ - 1)
			var cell: int = cz * NX + cx
			if cell != _cell:
				_cell = cell
				_wear[cell] += 1
				_tiles.set_instance_color(cell, CARD.lerp(TROD, minf(float(_wear[cell]), 2.0) / 2.0))        # one crossing shows; two are as dark as it gets
				_steps += 1
				if absf(p.x - _lit_x) <= 0.5: _on_lit += 1
				changed = true
			var end: int = 1 if p.z > HALF_L - 1.0 else (-1 if p.z < -HALF_L + 1.0 else 0)
			if end != 0:
				if _end != 0 and end != _end:
					_crossings += 1
					changed = true
					_tell()
				_end = end
		else:
			_cell = -1
			_end = 0                          # a crossing is made on the field: going round it is not one
			for plate in PLATES:
				var at: Vector2 = plate["at"]
				if absf(p.x - at.x) < PLATE * 0.5 and absf(p.z - at.y) < PLATE * 0.5: region = str(plate["key"])
	var moved: float = Vector2(p.x - _last.x, p.z - _last.z).length()
	_last = p
	if region != _region or moved > 0.3 * delta:
		_still = 0.0
	elif _still >= 0.0:
		_still += delta
	_region = region
	if _still >= 0.8 and region != "" and region != "field":
		_still = -99.0
		if region == "sweep": _sweep()
		else: _light(region)
		changed = false
	if changed: _show()


static func _where(x: float) -> String:
	if absf(x - GAP_X) < 0.3: return "through the gaps"
	return "%.1f m %s of the gaps" % [absf(x - GAP_X), "west" if x < GAP_X else "east"]


func _show() -> void:
	_strip.position.x = _lit_x
	for i in PLATES.size():
		(_plate_tiles[i].material_override as StandardMaterial3D).albedo_color = Color("f6e39a") if str(PLATES[i]["key"]) == _lit_name else PALE
	var names := {"gap": "THROUGH THE GAPS", "west": "WEST OF THE GAPS", "east": "EAST OF THE GAPS, AT THE POSTS", "worn": "ON WHAT WAS WORN"}
	_light_words.text = "THE LIGHT LIES  " + str(names[_lit_name])
	_count_words.text = "crossings:  %d\nsteps since the light last moved:  %d,  on the lit strip:  %d" % [_crossings, _steps, _on_lit]
	var worn: float = worn_x()
	if is_nan(worn):
		_worn_words.text = "nothing is worn yet"
		_status.text = ""
	else:
		_worn_words.text = "most worn:  %s\nthe light lies %.1f m from the worn path" % [_where(worn), absf(worn - _lit_x)]
		var apart: bool = absf(worn - _lit_x) > 0.6
		_status.text = "THE LIGHT POINTED ONE WAY. THE FEET WENT ANOTHER." if apart and _steps >= 8 else ("THE LIGHT NOW FOLLOWS THE FEET THAT CAME FIRST." if _lit_name == "worn" else "")


func _tell() -> void:
	if _board == null: return
	var lines := PackedStringArray(["THE LIGHT RECOMMENDS, THE FEET DECIDE"])
	lines.append("Three things the hall keeps asking you to tell apart, kept apart here. The posts and their gaps: the arrangement. The lit strip: the recommendation. The darkened tiles: where feet have gone.")
	lines.append("Cross the field. Then stand on LIGHT EAST and cross again: the light now points at posts. It has made a recommendation, not cleared a passage. Look at the tiles afterwards.")
	lines.append("LIGHT WHAT WAS WORN puts the light where feet went. Then the next walker is shown the first walkers' version. SWEEP takes the wear away.")
	lines.append("The stand counts where. It records no reason: not why you took the gap, nor whether you saw the light at all.")
	if _crossings > 0: lines.append("So far: %d crossing%s." % [_crossings, "" if _crossings == 1 else "s"])
	_board.text = "\n".join(lines)


## ---- building, once ----

func _box(parent: Node3D, at: Vector3, size: Vector3, paint: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = paint
	mesh.position = at
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh)
	return mesh


func _words(parent: Node3D, at: Vector3, size: int, pixel: float, colour: Color) -> Label3D:
	var label3d := Label3D.new()
	label3d.font_size = size
	label3d.pixel_size = pixel
	label3d.modulate = colour
	label3d.outline_size = 0
	label3d.double_sided = false
	label3d.position = at
	parent.add_child(label3d)
	return label3d


func _build_once() -> void:
	# the tiles
	_tiles = MultiMesh.new()
	_tiles.transform_format = MultiMesh.TRANSFORM_3D
	_tiles.use_colors = true
	var tile := BoxMesh.new()
	tile.size = Vector3(CELL - 0.03, 0.012, CELL - 0.03)
	_tiles.mesh = tile
	_tiles.instance_count = NX * NZ
	for cz in NZ:
		for cx in NX:
			_tiles.set_instance_transform(cz * NX + cx, Transform3D(Basis.IDENTITY, Vector3(column_x(cx), 0.012, -HALF_L + (float(cz) + 0.5) * CELL)))
			_tiles.set_instance_color(cz * NX + cx, CARD)
	var field := MultiMeshInstance3D.new()
	field.multimesh = _tiles
	var paint := StandardMaterial3D.new()
	paint.vertex_color_use_as_albedo = true
	paint.roughness = 0.95
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED      # the wear must read in the tower's own shadow
	field.material_override = paint
	field.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(field)
	_box(self, Vector3(0, 0.003, 0), Vector3(HALF_W * 2.0 + 0.1, 0.006, HALF_L * 2.0 + 0.1), _city.flat(DARK, 0.9))
	# the lit strip: a wash over the tiles, so that the wear shows through it
	var glow := StandardMaterial3D.new()
	glow.albedo_color = GLOW
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_strip = _box(self, Vector3(_lit_x, 0.024, 0), Vector3(1.0, 0.004, HALF_L * 2.0), glow)
	# the posts: three rows, each with one gap, the gaps in line
	var solid := StaticBody3D.new()
	solid.name = "Posts"
	add_child(solid)
	var post := CylinderMesh.new()
	post.top_radius = 0.06
	post.bottom_radius = 0.06
	post.height = 0.95
	var iron: StandardMaterial3D = _city.flat(Color("3a3d45"), 0.7)
	for z in ROWS_Z:
		var x := -HALF_W + 0.15
		while x < HALF_W:
			if absf(x - GAP_X) > GAP * 0.5 + 0.06:
				var node := MeshInstance3D.new()
				node.mesh = post
				node.material_override = iron
				node.position = Vector3(x, 0.475, float(z))
				add_child(node)
			x += 0.38
		var west_end: float = GAP_X - GAP * 0.5
		var east_start: float = GAP_X + GAP * 0.5
		_city.wall(solid, Vector3((-HALF_W + west_end) * 0.5, 0, float(z)), Vector3(west_end + HALF_W, 1.0, 0.14))
		_city.wall(solid, Vector3((east_start + HALF_W) * 0.5, 0, float(z)), Vector3(HALF_W - east_start, 1.0, 0.14))
	# the plates, at the south end
	for plate in PLATES:
		var at: Vector2 = plate["at"]
		_plate_tiles.append(_box(self, Vector3(at.x, 0.012, at.y), Vector3(PLATE, 0.02, PLATE), _city.flat(PALE, 0.8)))
		_city.floor_words(self, Vector3(at.x, 0.035, at.y), str(plate["says"]), 26, DARK).outline_size = 0
	# the stand, at the north end
	var stand := Node3D.new()
	stand.name = "Stand"
	stand.position = Vector3(0, 0, -HALF_L - 0.9)
	add_child(stand)
	var held := StaticBody3D.new()
	stand.add_child(held)
	_box(stand, Vector3(0, 1.55, -0.05), Vector3(3.8, 2.3, 0.06), _city.flat(DARK, 0.85))
	_city.wall(held, Vector3(0, 0, -0.05), Vector3(3.8, 2.7, 0.12))
	for hand in [-1.0, 1.0]: _box(stand, Vector3(hand * 1.75, 0.2, -0.05), Vector3(0.08, 0.4, 0.08), _city.flat(DARK, 0.85))
	_light_words = _words(stand, Vector3(0, 2.4, 0), 40, 0.003, Color("f6e39a"))
	_count_words = _words(stand, Vector3(0, 1.98, 0), 28, 0.003, PALE)
	_worn_words = _words(stand, Vector3(0, 1.52, 0), 28, 0.003, Color("d9b990"))
	_status = _words(stand, Vector3(0, 1.1, 0), 31, 0.003, AMBER)
	_words(stand, Vector3(0, 0.7, 0), 24, 0.003, Color("b9c0cc")).text = "It records where feet went. It records no reason."
	_board = _city.board(self, Vector3(4.3, 0, 6.4), 3.2, 1.7)
	(_board.get_parent().get_parent() as Node3D).rotation.y = PI * 0.5      # turned east, toward whoever comes from the middle of the floor


## ---- for a test ----

func state() -> Dictionary:
	var worn: float = worn_x()
	var total := 0
	for n in _wear: total += n
	return {"lit": _lit_name, "lit_x": _lit_x, "gap_x": GAP_X, "steps": _steps, "on_lit": _on_lit, "crossings": _crossings, "worn_x": worn if not is_nan(worn) else -99.0, "wear_total": total,
		"apart_m": snappedf(absf(worn - _lit_x), 0.01) if not is_nan(worn) else -1.0, "status": _status.text, "says": _worn_words.text, "strip_x": snappedf(_strip.position.x, 0.001),
		"board": _board.text if _board != null else "", "build_ms": _build_ms}


## A place on the field: `x` metres east of its middle, `north` metres north of its middle.
func field_point(x: float, north: float) -> Vector3:
	return to_global(Vector3(x, 0, -north))


func plate_point(key: String) -> Vector3:
	for plate in PLATES:
		if str(plate["key"]) == key: return to_global(Vector3((plate["at"] as Vector2).x, 0, (plate["at"] as Vector2).y))
	return global_position
