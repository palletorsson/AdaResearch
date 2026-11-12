# vanishing_tile_crossing.gd
# A field of tiles over an opening. Each tile stands, leaves, is gone and returns; only the waits are drawn. Cross it.
#
# @identity
# essence: every tile runs the same four states in the same order - IT STANDS, IT LEAVES, IT IS GONE, IT RETURNS -
#   and draws its own waits from one seed: wait(stands) ~ U(2.5, 7) s, wait(gone) ~ U(1.5, 4) s. 144 half-metre
#   tiles fill the cells of a rib lattice over a 6 x 6 m opening. A clock runs from the first tile a body steps on
#   to the rim on the other side.
# desire: to be crossed fast. The order is public and the timing is not; a body reads the tiles ahead, takes the
#   ones that stand and gets off the ones that are about to leave.
# critical_parameter: notice - how long before a tile leaves it says so with a gold ring (early | late | none =
#   1.2 s | 0.4 s | nothing). The waits are the same draws under every value: what changes is what a body is told.
# triggers: stepping on from one rim starts the clock; stepping off on the other stops it; the NEW DRAW plate deals
#   new waits.
# emerges: with early notice a route can be planned two tiles ahead; with none, every step is a finding out.
# needs: an opening with something below it [shaft B]; ribs to sit in [a `lattices` layer of the place kit].
# relationships: [[r_c]]'s law at the scale of a field - three stones in a row there, 144 tiles here; the same four
#   states and the same stored deadline. Kin to [[random_removal_arena]] (a cell gives notice, then it and its
#   support are gone for good) - here they come back.
# truth: Knowing what comes next is not knowing when. (After r_c: "How can you plan when the next state is known
#   but its timing is not?")
# lineage: MATH - renewal processes: independent clocks, each restarting from its own draw. DESIGN - the collapsing
#   bridge of platform games; the glass bridge. ARCHITECTURE - the waffle slab: ribs carry, panels fill.
# history: 2026-11-12, the Void, floor Random_Game. The crossing there was three stones; the tower's walker could
#   not get onto the first. Palle, with a picture of a floor of square pits between ribs: "make real games based on
#   randomness that have a lot more tiles ... start with a structure like this and add tiles instead and see how
#   fast you can cross shaft B".

extends Node3D

const Stock := preload("res://commons/artifacts/construction_site/stock.gd")
enum {STANDS, LEAVES, GONE, RETURNS}
const NOTICE := {"early": 1.2, "late": 0.4, "none": 0.0}
const COLOURS: Array[Color] = [Color(0.30, 0.85, 0.80), Color(0.95, 0.55, 0.20), Color(0, 0, 0, 0), Color(0.35, 0.80, 0.40)]

## How long before a tile leaves it says so.
@export_enum("early", "late", "none") var notice := "early"
@export var seed_value := 91001
@export var size := Vector2(6, 6)              ## the opening, metres: east-west by north-south
@export var tile := 0.5                        ## metres: four tiles to each one-metre cell of the ribs
@export var stand_wait := Vector2(2.5, 7.0)    ## seconds a tile stands: drawn between these
@export var gone_wait := Vector2(1.5, 4.0)     ## seconds a tile is gone
@export var move_time := 0.5                   ## seconds to leave, and to return
@export var sink := 0.45                       ## metres a tile sinks as it leaves

var _nx := 0
var _nz := 0
var _state := PackedInt32Array()
var _until := PackedFloat32Array()
var _bodies: Array[StaticBody3D] = []
var _tiles: MultiMesh
var _rings: MultiMesh
var _rng := RandomNumberGenerator.new()
var _now := 0.0
var _inside := {}          # body id -> {side, since}
var _last := -1.0
var _best := -1.0
var _crossed := 0
var _fell := 0
var _board: Label3D
var _last_step := -10.0


func _ready() -> void:
	_read_config()
	_nx = maxi(1, roundi(size.x / tile))
	_nz = maxi(1, roundi(size.y / tile))
	_build()
	deal()


func _read_config() -> void:
	if has_meta("config_notice") and NOTICE.has(str(get_meta("config_notice"))):
		notice = str(get_meta("config_notice"))
	for meta in ["config_seed_value", "config_seed"]:
		if has_meta(meta): seed_value = int(str(get_meta(meta)).to_float())
	for key in ["tile", "move_time", "sink"]:
		if has_meta("config_" + key): set(key, str(get_meta("config_" + key)).to_float())


func apply_grid_config(config_data: Dictionary) -> void:
	for key in config_data:
		set_meta("config_" + str(key), config_data[key])
	_read_config()
	if is_inside_tree() and _tiles != null:
		deal()


func _centre(i: int, j: int) -> Vector3:
	return Vector3((i + .5) * tile - size.x / 2.0, 0, (j + .5) * tile - size.y / 2.0)


func _build() -> void:
	var count := _nx * _nz
	_state.resize(count)
	_until.resize(count)
	var slab := BoxMesh.new()
	slab.size = Vector3(tile - .04, .06, tile - .04)
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = .5
	material.emission_enabled = true
	material.emission = Color(0.30, 0.85, 0.80)
	material.emission_energy_multiplier = .12
	_tiles = MultiMesh.new()
	_tiles.transform_format = MultiMesh.TRANSFORM_3D
	_tiles.use_colors = true
	_tiles.mesh = slab
	_tiles.instance_count = count
	var tiles := MultiMeshInstance3D.new()
	tiles.name = "Tiles"
	tiles.multimesh = _tiles
	tiles.material_override = material
	tiles.custom_aabb = AABB(Vector3(-size.x / 2.0, -1, -size.y / 2.0), Vector3(size.x, 1.5, size.y))
	add_child(tiles)
	var ring := TorusMesh.new()
	ring.inner_radius = tile * .26
	ring.outer_radius = tile * .34
	ring.rings = 20
	ring.ring_segments = 6
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(1.0, 0.82, 0.25)
	gold.emission_enabled = true
	gold.emission = Color(1.0, 0.82, 0.25)
	gold.emission_energy_multiplier = 1.4
	_rings = MultiMesh.new()
	_rings.transform_format = MultiMesh.TRANSFORM_3D
	_rings.mesh = ring
	_rings.instance_count = count
	var rings := MultiMeshInstance3D.new()
	rings.name = "Notice"
	rings.multimesh = _rings
	rings.material_override = gold
	rings.custom_aabb = tiles.custom_aabb
	add_child(rings)
	var shape := BoxShape3D.new()
	shape.size = Vector3(tile, .06, tile)
	for index in count:
		var body := StaticBody3D.new()
		body.name = "Tile_%d" % index
		var collider := CollisionShape3D.new()
		collider.shape = shape
		body.add_child(collider)
		add_child(body)
		_bodies.append(body)
	var field := Area3D.new()
	field.name = "Field"
	field.collision_layer = 0
	field.collision_mask = 0xFFFFFFFF
	field.position.y = .5
	var bounds := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size.x, 3.0, size.y)
	bounds.shape = box
	field.add_child(bounds)
	add_child(field)
	field.body_entered.connect(_entered)
	field.body_exited.connect(_exited)
	# the board stands on the north rim and is read from the floor's middle and from both ends of the crossing
	var at := Vector3(0, 2.0, -size.y / 2.0 - .7)
	for dx in [-1.3, 1.3]:
		Stock.box(self, "BoardPost", Vector3(dx, at.y / 2.0, at.z), Vector3(.05, at.y, .05), Stock.finish("76695a", .95), false)
	var board := Stock.box(self, "Board", at, Vector3(2.8, .62, .03), Stock.finish("d9cfbd", .9), false)
	_board = Label3D.new()
	_board.font_size = 48
	_board.pixel_size = .0012
	_board.outline_size = 0
	_board.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	_board.modulate = Color("202329")
	_board.position = Vector3(0, 0, .02)
	board.add_child(_board)
	var plate_at := Vector3(-size.x / 2.0 - .9, .02, size.y / 2.0 + .9)
	var plate := Stock.box(self, "NewDraw", plate_at, Vector3(.8, .04, .8), Stock.finish("c8452f", .6), false)
	var words := Label3D.new()
	words.text = "NEW DRAW"
	words.font_size = 48
	words.pixel_size = .0017
	words.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	words.modulate = Color("f3ece2")
	words.rotation.x = -PI / 2
	words.position = Vector3(0, .025, 0)
	plate.add_child(words)
	var press := Area3D.new()
	press.name = "NewDrawArea"
	press.collision_layer = 0
	press.collision_mask = 0xFFFFFFFF
	press.position = plate_at + Vector3(0, .5, 0)
	var press_shape := CollisionShape3D.new()
	var press_box := BoxShape3D.new()
	press_box.size = Vector3(.8, 1.0, .8)
	press_shape.shape = press_box
	press.add_child(press_shape)
	add_child(press)
	press.body_entered.connect(func(body: Node) -> void:
		if not body is CharacterBody3D: return
		var now := Time.get_ticks_msec() / 1000.0
		if now - _last_step < 1.5: return
		_last_step = now
		seed_value += 1
		deal())


## Deal every tile a place in its cycle and its first wait, from the seed.
func deal() -> void:
	_rng.seed = seed_value
	for index in _state.size():
		var stands: bool = _rng.randf() < .62      # about the share of a cycle a tile spends standing
		_state[index] = STANDS if stands else GONE
		_until[index] = _now + _rng.randf() * (stand_wait.y if stands else gone_wait.y)
		_show(index)
	_write()


func _draw(band: Vector2) -> float:
	return _rng.randf_range(band.x, band.y)


func _show(index: int) -> void:
	var state := _state[index]
	var at := _centre(index % _nx, index / _nx)
	var drop := 0.0
	if state == LEAVES: drop = sink * (1.0 - clampf((_until[index] - _now) / move_time, 0, 1))
	elif state == RETURNS: drop = sink * clampf((_until[index] - _now) / move_time, 0, 1)
	var gone: bool = state == GONE
	_tiles.set_instance_transform(index, Transform3D(Basis().scaled(Vector3.ZERO if gone else Vector3.ONE), at + Vector3(0, -.01 - drop, 0)))
	_tiles.set_instance_color(index, COLOURS[state])
	var told: bool = state == STANDS and float(NOTICE[notice]) > 0.0 and _until[index] - _now <= float(NOTICE[notice])
	_rings.set_instance_transform(index, Transform3D(Basis().scaled(Vector3.ONE if told else Vector3.ZERO), at + Vector3(0, .035, 0)))
	var body := _bodies[index]
	body.position = at + Vector3(0, -.01 - drop, 0)
	body.process_mode = Node.PROCESS_MODE_DISABLED if gone else Node.PROCESS_MODE_INHERIT      # the support is gone with the tile


func _physics_process(delta: float) -> void:
	_now += delta
	var lead: float = float(NOTICE[notice])
	for index in _state.size():
		var left := _until[index] - _now
		var state := _state[index]
		if left <= 0.0:
			match state:
				STANDS: _state[index] = LEAVES; _until[index] = _now + move_time
				LEAVES: _state[index] = GONE; _until[index] = _now + _draw(gone_wait)
				GONE: _state[index] = RETURNS; _until[index] = _now + move_time
				_: _state[index] = STANDS; _until[index] = _now + _draw(stand_wait)
			_show(index)
		elif state == LEAVES or state == RETURNS or (state == STANDS and lead > 0.0 and left <= lead + delta):
			_show(index)


# ---------------------------------------------------------------- the game

func _side(local: Vector3) -> String:
	var across := local.x / (size.x / 2.0)
	var along := local.z / (size.y / 2.0)
	if absf(across) >= absf(along):
		return "east" if across > 0 else "west"
	return "south" if along > 0 else "north"


func _entered(body: Node) -> void:
	if body is CharacterBody3D:
		_inside[body.get_instance_id()] = {"side": _side(to_local((body as Node3D).global_position)), "since": _now}


func _exited(body: Node) -> void:
	var key := body.get_instance_id()
	if not _inside.has(key):
		return
	var began: Dictionary = _inside[key]
	_inside.erase(key)
	var local := to_local((body as Node3D).global_position)
	if local.y < -.6:
		_fell += 1
	else:
		var out := _side(local)
		var opposite: bool = (began.side == "west" and out == "east") or (began.side == "east" and out == "west") or (began.side == "north" and out == "south") or (began.side == "south" and out == "north")
		if opposite:
			_last = _now - float(began.since)
			_best = _last if _best < 0.0 else minf(_best, _last)
			_crossed += 1
	_write()


func _write() -> void:
	if _board == null:
		return
	var last := "-" if _last < 0.0 else "%.1f s" % _last
	var best := "-" if _best < 0.0 else "%.1f s" % _best
	_board.text = "CROSS SHAFT B\nlast %s    best %s    crossed %d    fell %d\nit stands, it leaves, it is gone, it returns\ndraw %d    notice: %s" % [last, best, _crossed, _fell, seed_value, notice]


# ---------------------------------------------------------------- for probes

func tiles_across() -> Vector2i:
	return Vector2i(_nx, _nz)


func tile_at(local: Vector3) -> Vector2i:
	return Vector2i(floori((local.x + size.x / 2.0) / tile), floori((local.z + size.y / 2.0) / tile))


func tile_centre(i: int, j: int) -> Vector3:
	return _centre(i, j)


## Can a body count on this tile for the next `margin` seconds?
func holds(i: int, j: int, margin: float = 0.6) -> bool:
	if i < 0 or j < 0 or i >= _nx or j >= _nz:
		return false
	var index := j * _nx + i
	return _state[index] == STANDS and _until[index] - _now > margin


func score() -> Dictionary:
	var standing := 0
	for s in _state:
		if s == STANDS: standing += 1
	return {"last": _last, "best": _best, "crossed": _crossed, "fell": _fell, "tiles": _state.size(), "standing": standing}
