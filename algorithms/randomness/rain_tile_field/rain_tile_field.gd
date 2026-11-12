# rain_tile_field.gd
# Drops fall on a field of tiles at drawn moments and drawn places. Stay dry for a round; then read where it fell.
#
# @identity
# essence: arrivals are drawn one after another - the wait to the next drop ~ Exp(rate), the tile it falls on
#   uniform over 192 - and the rate climbs from 3 to 9 a second over a 40 s round. A drop is seen coming for a
#   second. Every tile keeps count of its hits.
# desire: to be stood in. A body watches the drops come, steps off the tile one is falling to, and afterwards sees
#   on the floor what "at random" did: some tiles untouched, some hit four times.
# critical_parameter: falls - where a drop lands (even | clumped | aimed). `even` is uniform; `clumped` prefers
#   the neighbours of earlier hits; `aimed` goes for the tile a body stands on half the time. The same rate under
#   all three: what changes is whether the rain knows where you are.
# triggers: stepping onto the field starts a round; the NEW DRAW plate deals another seed.
# emerges: after a round the board sets the tiles hit 0, 1, 2, 3 and more times beside the numbers Poisson's law
#   gives for that many drops. Even rain is not even ground.
# needs: 6 x 8 m of floor with ribs to sit in [a `lattices` layer of the place kit]; the tower's charge.
# relationships: beside [[waiting_profile]] (the waits between arrivals) and [[cube_projectile_spawner]] (cubes that
#   fall on a field): here the arrivals are a game and the field remembers them. Third of the floor's tile games
#   after [[vanishing_tile_crossing]] (drawn timing) and [[finding_out_field]] (a draw made beforehand): here
#   both the when and the where are drawn, live.
# truth: Independent arrivals clump. Nothing aims, and still some ground is hit again and again.
# lineage: MATH - the Poisson process; von Bortkiewicz's horse kicks (1898); R. D. Clarke's map of V-1 hits on
#   London in quarter-kilometre squares (1946), which fitted Poisson and so showed nobody was aiming. DESIGN - the
#   bullet-hell dodge. ART - rain on a pavement, read as a drawing.
# history: 2026-11-12, the Void, floor Random_Game. Palle: "continue with the next real game with a lot more tiles."

extends Node3D

const Stock := preload("res://commons/artifacts/construction_site/stock.gd")
const SHADES: Array[Color] = [Color(0.33, 0.40, 0.52), Color(0.42, 0.62, 0.86), Color(0.36, 0.42, 0.90), Color(0.56, 0.34, 0.84), Color(0.80, 0.30, 0.62)]

## Where a drop lands.
@export_enum("even", "clumped", "aimed") var falls := "even"
@export var seed_value := 91901
@export var cells := Vector2i(6, 8)          ## one-metre cells of the ribs, east-west by north-south
@export var tile := 0.5
@export var round_seconds := 40.0
@export var rate := Vector2(3.0, 9.0)        ## drops a second, at the start and at the end of a round
@export var notice := 1.0                    ## seconds a drop is seen coming
@export var shock := 10.0                    ## charge a drop takes from a body it lands on

var _nx := 0
var _nz := 0
var _hits := PackedInt32Array()
var _tiles: MultiMesh
var _drops: MultiMesh
var _pending := []           # {tile, lands}
var _rng := RandomNumberGenerator.new()
var _now := 0.0
var _running := false
var _began := 0.0
var _next := 0.0
var _fallen := 0
var _wet := 0
var _best := -1
var _rounds := 0
var _stayed := true
var _inside := {}
var _board: Label3D
var _last_step := -10.0
var _ended := -10.0


func _ready() -> void:
	_read_config()
	_nx = roundi(cells.x / tile)
	_nz = roundi(cells.y / tile)
	_build()
	_clear()


func _read_config() -> void:
	if has_meta("config_falls") and str(get_meta("config_falls")) in ["even", "clumped", "aimed"]:
		falls = str(get_meta("config_falls"))
	for meta in ["config_seed_value", "config_seed"]:
		if has_meta(meta): seed_value = int(str(get_meta(meta)).to_float())
	for key in ["round_seconds", "notice", "shock"]:
		if has_meta("config_" + key): set(key, str(get_meta("config_" + key)).to_float())


func apply_grid_config(config_data: Dictionary) -> void:
	for key in config_data:
		set_meta("config_" + str(key), config_data[key])
	_read_config()


func tile_centre(index: int) -> Vector3:
	return Vector3((index % _nx + .5) * tile - cells.x / 2.0, 0, (index / _nx + .5) * tile - cells.y / 2.0)


func tile_at(local: Vector3) -> int:
	var i := floori((local.x + cells.x / 2.0) / tile)
	var j := floori((local.z + cells.y / 2.0) / tile)
	return j * _nx + i if i >= 0 and j >= 0 and i < _nx and j < _nz else -1


func _build() -> void:
	var slab := BoxMesh.new()
	slab.size = Vector3(tile - .04, .05, tile - .04)
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = .55
	_tiles = MultiMesh.new()
	_tiles.transform_format = MultiMesh.TRANSFORM_3D
	_tiles.use_colors = true
	_tiles.mesh = slab
	_tiles.instance_count = _nx * _nz
	_hits.resize(_nx * _nz)
	for index in _nx * _nz:
		_tiles.set_instance_transform(index, Transform3D(Basis(), tile_centre(index) + Vector3(0, .005, 0)))
	var tiles := MultiMeshInstance3D.new()
	tiles.name = "Tiles"
	tiles.multimesh = _tiles
	tiles.material_override = material
	add_child(tiles)
	var drop := BoxMesh.new()
	drop.size = Vector3(.22, .22, .22)
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(1.0, 0.82, 0.25)
	gold.emission_enabled = true
	gold.emission = Color(1.0, 0.82, 0.25)
	gold.emission_energy_multiplier = 1.2
	_drops = MultiMesh.new()
	_drops.transform_format = MultiMesh.TRANSFORM_3D
	_drops.mesh = drop
	_drops.instance_count = 32
	_drops.visible_instance_count = 0
	var drops := MultiMeshInstance3D.new()
	drops.name = "Drops"
	drops.multimesh = _drops
	drops.material_override = gold
	drops.custom_aabb = AABB(Vector3(-cells.x / 2.0, 0, -cells.y / 2.0), Vector3(cells.x, 4, cells.y))
	add_child(drops)
	var field := Area3D.new()
	field.name = "Field"
	field.collision_layer = 0
	field.collision_mask = 0xFFFFFFFF
	field.position.y = 1.0
	var bounds := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(cells.x, 2.0, cells.y)
	bounds.shape = box
	field.add_child(bounds)
	add_child(field)
	field.body_entered.connect(func(body: Node) -> void:
		if body is CharacterBody3D:
			_inside[body.get_instance_id()] = body
			if not _running and _now - _ended > 2.0: start())
	field.body_exited.connect(func(body: Node) -> void:
		_inside.erase(body.get_instance_id())
		if _running and _inside.is_empty(): _stayed = false)
	# the board stands beyond the east edge and is read across the field
	var at := Vector3(cells.x / 2.0 + .6, 2.1, 0)
	for dz in [-1.5, 1.5]:
		Stock.box(self, "BoardPost", Vector3(at.x, at.y / 2.0, dz), Vector3(.05, at.y, .05), Stock.finish("76695a", .95), false)
	var board := Stock.box(self, "Board", at, Vector3(.03, .9, 3.2), Stock.finish("d9cfbd", .9), false)
	_board = Label3D.new()
	_board.font_size = 48
	_board.pixel_size = .0015
	_board.outline_size = 0
	_board.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	_board.modulate = Color("202329")
	_board.rotation.y = -PI / 2.0      # the words face west, across the field
	_board.position = Vector3(-.02, 0, 0)
	board.add_child(_board)
	var plate_at := Vector3(cells.x / 2.0 + .55, .02, -cells.y / 2.0 + .6)
	var plate := Stock.box(self, "NewDraw", plate_at, Vector3(.8, .04, .8), Stock.finish("c8452f", .6), false)
	var words := Label3D.new()
	words.text = "NEW DRAW"
	words.font_size = 44
	words.pixel_size = .0015
	words.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	words.modulate = Color("f3ece2")
	words.rotation_degrees = Vector3(-90, -90, 0)
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
		if not body is CharacterBody3D or _running: return
		var now := Time.get_ticks_msec() / 1000.0
		if now - _last_step < 1.5: return
		_last_step = now
		seed_value += 1
		_clear())


func _clear() -> void:
	_hits.fill(0)
	_pending.clear()
	_fallen = 0
	_wet = 0
	for index in _nx * _nz:
		_tiles.set_instance_color(index, SHADES[0])
	_drops.visible_instance_count = 0
	_write()


## Begin a round: the field is cleared and the first wait is drawn from the seed.
func start() -> void:
	_rng.seed = seed_value + _rounds
	_clear()
	_running = true
	_stayed = true
	_began = _now
	_next = _now + _wait()


func _rate_now() -> float:
	return lerpf(rate.x, rate.y, clampf((_now - _began) / round_seconds, 0, 1))


func _wait() -> float:
	return -log(1.0 - _rng.randf() * .999999) / _rate_now()


func _target() -> int:
	var count := _nx * _nz
	if falls == "aimed" and _rng.randf() < .5:
		for body in _inside.values():
			if is_instance_valid(body):
				var under := tile_at(to_local((body as Node3D).global_position))
				if under >= 0: return under
	if falls == "clumped" and _fallen > 0 and _rng.randf() < .6:
		for attempt in 12:
			var seed_tile := _rng.randi_range(0, count - 1)
			if _hits[seed_tile] == 0: continue
			var i := seed_tile % _nx + _rng.randi_range(-1, 1)
			var j := seed_tile / _nx + _rng.randi_range(-1, 1)
			if i >= 0 and j >= 0 and i < _nx and j < _nz: return j * _nx + i
	return _rng.randi_range(0, count - 1)


func _physics_process(delta: float) -> void:
	_now += delta
	if _running:
		while _now >= _next and _now - _began < round_seconds:
			_pending.append({"tile": _target(), "lands": _next + notice})
			_next += _wait()
		if _now - _began >= round_seconds + notice + .1:
			_finish()
	var kept := []
	for drop in _pending:
		if _now >= float(drop.lands):
			_land(int(drop.tile))
		else:
			kept.append(drop)
	_pending = kept
	_drops.visible_instance_count = mini(_pending.size(), _drops.instance_count)
	for k in _drops.visible_instance_count:
		var left: float = (float(_pending[k].lands) - _now) / notice
		_drops.set_instance_transform(k, Transform3D(Basis(), tile_centre(int(_pending[k].tile)) + Vector3(0, .15 + 3.2 * clampf(left, 0, 1), 0)))
	if _running and Engine.get_physics_frames() % 15 == 0:
		_write()


func _land(index: int) -> void:
	_hits[index] += 1
	_fallen += 1
	_tiles.set_instance_color(index, SHADES[mini(_hits[index], SHADES.size() - 1)])
	for body in _inside.values():
		if is_instance_valid(body) and tile_at(to_local((body as Node3D).global_position)) == index:
			_wet += 1
			var battery := get_tree().get_first_node_in_group("void_health")
			if battery != null and battery.has_method("discharge"): battery.discharge(shock, "rain")


func _finish() -> void:
	_running = false
	_ended = _now
	_rounds += 1
	if _stayed and not _inside.is_empty():
		_best = _wet if _best < 0 else mini(_best, _wet)
	_write()


## How many tiles were hit 0, 1, 2 and 3 or more times, and what Poisson's law gives for as many drops.
func tally() -> Dictionary:
	var drawn := [0, 0, 0, 0]
	for h in _hits: drawn[mini(h, 3)] += 1
	var count := float(_nx * _nz)
	var mean := _fallen / count
	var expected := [count * exp(-mean), count * exp(-mean) * mean, count * exp(-mean) * mean * mean / 2.0]
	expected.append(count - expected[0] - expected[1] - expected[2])
	return {"drawn": drawn, "expected": expected.map(func(v: float) -> float: return snappedf(v, .1)), "drops": _fallen, "mean": snappedf(mean, .01)}


func _write() -> void:
	if _board == null:
		return
	var t: Dictionary = tally()
	var state := "walk on to start a round" if not _running else "%.0f s left   %.1f drops a second" % [maxf(0.0, round_seconds - (_now - _began)), _rate_now()]
	var best := "-" if _best < 0 else str(_best)
	_board.text = "RAIN\n%s\nhit this round %d      best round %s\ntiles hit   0x   1x   2x   3x+\ndrawn      %3d  %3d  %3d  %3d\nPoisson    %3.0f  %3.0f  %3.0f  %3.0f\ndraw %d    it falls: %s" % [
		state, _wet, best, t.drawn[0], t.drawn[1], t.drawn[2], t.drawn[3], t.expected[0], t.expected[1], t.expected[2], t.expected[3], seed_value, falls]


# ---------------------------------------------------------------- for probes

func tiles() -> int:
	return _nx * _nz


func running() -> bool:
	return _running


## Seconds until the next drop lands on this tile; -1 when none is coming.
func coming(index: int) -> float:
	var soonest := -1.0
	for drop in _pending:
		if int(drop.tile) == index:
			var left: float = float(drop.lands) - _now
			if soonest < 0.0 or left < soonest: soonest = left
	return soonest


func score() -> Dictionary:
	return {"wet": _wet, "best": _best, "rounds": _rounds, "drops": _fallen, "stayed": _stayed}
