# stone_cross_crossing.gd
# Four three-stone crossings meet in a cross over an opening. A live grid lies a metre below; health waits in the middle.
#
# @identity
# essence: twelve stones in four arms run the same four states in the same order - IT STANDS, IT LEAVES, IT IS
#   DOWN, IT RETURNS - each on its own drawn waits: wait(stands) ~ U(3, 8) s, wait(down) ~ U(1.5, 4) s. A stone
#   that leaves takes whoever stands on it down to a live grid; a stone that returns brings them back up.
# desire: to be crossed by a body that weighs a cost against a reward: the grid below takes charge with every
#   shock, the cross in the middle gives it back, and the way to the middle is three stones whose timing is drawn.
# critical_parameter: notice - how long before a stone moves it says so with a ring, gold before it leaves and
#   green before it returns (early | late | none = 1.2 s | 0.4 s | nothing).
# triggers: stepping onto a stone from a rim starts the clock; stepping off at another rim stops it; the NEW DRAW
#   plate deals new waits.
# emerges: going down is not the end of a try. A body on the grid looks for the stone that returns next, stands on
#   it and is carried up: the floor that left you is the floor that fetches you.
# needs: an opening [shaft A]; a floor a metre below it and a platform in the middle [two decks of the place kit];
#   a health cross on that platform [health_cross]; the tower's charge [commons/void/health.gd].
# relationships: [[r_c]]'s crossing four times over, with its own rule kept: a sunken stone rests on the bed and
#   carries you back. Sibling of [[vanishing_tile_crossing]] over the other shaft (144 tiles, a fall is a fall).
#   Uses the tower's electric zone (commons/void/electric_zone.gd) and [[health_cross]].
# truth: Knowing what comes next is not knowing when - and what it costs to be wrong can be paid back.
# lineage: MATH - renewal processes; a gambler's ruin with a refill. DESIGN - the stepping-stone level with a
#   hazard below and a pickup at the centre. ARCHITECTURE - the crossing of a nave: four arms and a middle.
# history: 2026-11-12, the Void, floor Random_Game. Palle: "continue with the next real game with a lot more tiles,
#   make it a 4 3-stone crossing, cross and in the middle health cross but a basin in the shaft that is electric
#   grid."

extends Node3D

const Stock := preload("res://commons/artifacts/construction_site/stock.gd")
const Zone := preload("res://commons/void/electric_zone.gd")
enum {STANDS, LEAVES, DOWN, RETURNS}
const NOTICE := {"early": 1.2, "late": 0.4, "none": 0.0}
const COLOURS: Array[Color] = [Color(0.30, 0.85, 0.80), Color(0.95, 0.55, 0.20), Color(0.27, 0.31, 0.36), Color(0.35, 0.80, 0.40)]
const ARMS: Array[Vector3] = [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]      # east, west, south, north
const ARM_NAMES: Array[String] = ["east", "west", "south", "north"]

## How long before a stone moves it says so.
@export_enum("early", "late", "none") var notice := "early"
@export var seed_value := 91411
@export var reach := 3.0                       ## metres from the middle to a rim
@export var middle := 1.0                      ## half the platform in the middle
@export var drop := 1.0                        ## the live grid lies this far below the rims
@export var stand_wait := Vector2(3.0, 8.0)
@export var down_wait := Vector2(1.5, 4.0)
@export var move_time := 0.9

var _state := PackedInt32Array()
var _until := PackedFloat32Array()
var _stones: Array[AnimatableBody3D] = []
var _faces: Array[StandardMaterial3D] = []
var _rings: Array[MeshInstance3D] = []
var _ring_mats: Array[StandardMaterial3D] = []
var _rng := RandomNumberGenerator.new()
var _now := 0.0
var _inside := {}
var _down := {}
var _last := -1.0
var _best := -1.0
var _crossed := 0
var _went_down := 0
var _shocks := 0
var _board: Label3D
var _last_step := -10.0


func _ready() -> void:
	_read_config()
	_build()
	deal()


func _read_config() -> void:
	if has_meta("config_notice") and NOTICE.has(str(get_meta("config_notice"))):
		notice = str(get_meta("config_notice"))
	for meta in ["config_seed_value", "config_seed"]:
		if has_meta(meta): seed_value = int(str(get_meta(meta)).to_float())
	for key in ["reach", "middle", "drop", "move_time"]:
		if has_meta("config_" + key): set(key, str(get_meta("config_" + key)).to_float())


func apply_grid_config(config_data: Dictionary) -> void:
	for key in config_data:
		set_meta("config_" + str(key), config_data[key])
	_read_config()
	if is_inside_tree() and not _stones.is_empty():
		deal()


func _pitch() -> float:
	return (reach - middle) / 3.0


## Where stone `index` stands, in the work's own metres, at the height of its top when it stands.
func stone_place(index: int) -> Vector3:
	return ARMS[index / 3] * (middle + (index % 3 + .5) * _pitch()) + Vector3(0, .02, 0)


func _build() -> void:
	var along := _pitch() - .05
	for index in 12:
		var arm: Vector3 = ARMS[index / 3]
		var body := AnimatableBody3D.new()
		body.name = "Stone_%s_%d" % [ARM_NAMES[index / 3], index % 3]
		body.sync_to_physics = true
		var size := Vector3(along if arm.x != 0 else .9, .12, along if arm.z != 0 else .9)
		var mesh := MeshInstance3D.new()
		var slab := BoxMesh.new()
		slab.size = size
		mesh.mesh = slab
		var face := StandardMaterial3D.new()
		face.roughness = .5
		face.emission_enabled = true
		face.emission_energy_multiplier = .15
		mesh.material_override = face
		body.add_child(mesh)
		var collider := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		collider.shape = box
		body.add_child(collider)
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = .17
		torus.outer_radius = .23
		torus.rings = 20
		torus.ring_segments = 6
		ring.mesh = torus
		var ring_mat := StandardMaterial3D.new()
		ring_mat.emission_enabled = true
		ring_mat.emission_energy_multiplier = 1.5
		ring.material_override = ring_mat
		ring.position.y = .075
		ring.visible = false
		body.add_child(ring)
		add_child(body)
		_stones.append(body); _faces.append(face); _rings.append(ring); _ring_mats.append(ring_mat)
	_state.resize(12)
	_until.resize(12)
	# the live grid: the tower's own electric zone over the floor below, and lines that show where it runs
	var zone := Zone.new()
	zone.name = "LiveGrid"
	zone.position = Vector3(0, -drop + .5, 0)
	var extent := CollisionShape3D.new()
	extent.name = "CollisionShape3D"
	var extent_box := BoxShape3D.new()
	extent_box.size = Vector3(reach * 2.0 - .2, .9, reach * 2.0 - .2)
	extent.shape = extent_box
	zone.add_child(extent)
	add_child(zone)
	zone.damage_dealt.connect(func(_amount: float, _kind: int) -> void:
		_shocks += 1
		_write())
	var wire := StandardMaterial3D.new()
	wire.albedo_color = Color(0.35, 0.95, 1.0)
	wire.emission_enabled = true
	wire.emission = Color(0.35, 0.95, 1.0)
	wire.emission_energy_multiplier = 2.2
	var strip := BoxMesh.new()
	strip.size = Vector3(reach * 2.0 - .1, .014, .03)
	var lines := MultiMesh.new()
	lines.transform_format = MultiMesh.TRANSFORM_3D
	lines.mesh = strip
	var count := int(reach * 4.0) + 1
	lines.instance_count = count * 2
	for k in count:
		var offset := -reach + .05 + k * (reach * 2.0 - .1) / float(count - 1)
		lines.set_instance_transform(k, Transform3D(Basis(), Vector3(0, -drop + .03, offset)))
		lines.set_instance_transform(count + k, Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(offset, -drop + .03, 0)))
	var wires := MultiMeshInstance3D.new()
	wires.name = "GridLines"
	wires.multimesh = lines
	wires.material_override = wire
	add_child(wires)
	var field := Area3D.new()
	field.name = "Field"
	field.collision_layer = 0
	field.collision_mask = 0xFFFFFFFF
	field.position.y = .2
	var bounds := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(reach * 2.0, 3.4, reach * 2.0)
	bounds.shape = box
	field.add_child(bounds)
	add_child(field)
	field.body_entered.connect(func(body: Node) -> void:
		if body is CharacterBody3D: _inside[body.get_instance_id()] = {"side": _side(to_local((body as Node3D).global_position)), "since": _now, "body": body})
	field.body_exited.connect(_exited)
	var at := Vector3(0, 2.0, -reach - .7)
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
	var plate_at := Vector3(reach + .9, .02, reach + .9)
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


## Deal every stone its first wait from the seed. All twelve begin standing: a crossing starts whole.
func deal() -> void:
	_rng.seed = seed_value
	for index in 12:
		_state[index] = STANDS
		_until[index] = _now + _rng.randf_range(stand_wait.x * .5, stand_wait.y)
		_show(index)
	_write()


func _show(index: int) -> void:
	var state := _state[index]
	var left := _until[index] - _now
	var sunk := 0.0
	if state == LEAVES: sunk = 1.0 - clampf(left / move_time, 0, 1)
	elif state == DOWN: sunk = 1.0
	elif state == RETURNS: sunk = clampf(left / move_time, 0, 1)
	var at := stone_place(index)
	_stones[index].position = Vector3(at.x, .02 - .06 - sunk * (drop - .02), at.z)      # down, it rests 2 cm proud of the grid
	_faces[index].albedo_color = COLOURS[state]
	_faces[index].emission = COLOURS[state]
	var lead: float = float(NOTICE[notice])
	var told: bool = lead > 0.0 and left <= lead and (state == STANDS or state == DOWN)
	_rings[index].visible = told
	if told:
		var colour := Color(1.0, 0.82, 0.25) if state == STANDS else Color(0.35, 0.95, 0.45)
		_ring_mats[index].albedo_color = colour
		_ring_mats[index].emission = colour


func _physics_process(delta: float) -> void:
	_now += delta
	for index in 12:
		var left := _until[index] - _now
		if left <= 0.0:
			match _state[index]:
				STANDS: _state[index] = LEAVES; _until[index] = _now + move_time
				LEAVES: _state[index] = DOWN; _until[index] = _now + _rng.randf_range(down_wait.x, down_wait.y)
				DOWN: _state[index] = RETURNS; _until[index] = _now + move_time
				_: _state[index] = STANDS; _until[index] = _now + _rng.randf_range(stand_wait.x, stand_wait.y)
		_show(index)
	for key in _inside:
		var body: Node3D = _inside[key].body
		if not is_instance_valid(body):
			continue
		var y := to_local(body.global_position).y
		if y < -.5 and not _down.has(key):
			_down[key] = true
			_went_down += 1
			_write()
		elif y > -.12 and _down.has(key):
			_down.erase(key)


func _side(local: Vector3) -> String:
	if absf(local.x) >= absf(local.z):
		return "east" if local.x > 0 else "west"
	return "south" if local.z > 0 else "north"


func _exited(body: Node) -> void:
	var key := body.get_instance_id()
	if not _inside.has(key):
		return
	var began: Dictionary = _inside[key]
	_inside.erase(key)
	_down.erase(key)
	var local := to_local((body as Node3D).global_position)
	if local.y > -.3 and _side(local) != str(began.side):
		_last = _now - float(began.since)
		_best = _last if _best < 0.0 else minf(_best, _last)
		_crossed += 1
	_write()


func _write() -> void:
	if _board == null:
		return
	var last := "-" if _last < 0.0 else "%.1f s" % _last
	var best := "-" if _best < 0.0 else "%.1f s" % _best
	_board.text = "THE STONE CROSS\nlast %s    best %s    crossed %d\nwent down %d    shocks %d\ndraw %d    notice: %s" % [last, best, _crossed, _went_down, _shocks, seed_value, notice]


# ---------------------------------------------------------------- for probes

## The stones of one arm, from the rim to the middle.
func arm(side: String) -> Array:
	var a := ARM_NAMES.find(side)
	return [a * 3 + 2, a * 3 + 1, a * 3]


## Can a body count on this stone standing for the next `margin` seconds?
func holds(index: int, margin: float = 0.8) -> bool:
	return _state[index] == STANDS and _until[index] - _now > margin


func is_down(index: int) -> bool:
	return _state[index] == DOWN


## Seconds until a stone that is down starts back up; -1 when it is not down.
func returns_in(index: int) -> float:
	return _until[index] - _now if _state[index] == DOWN else -1.0


func score() -> Dictionary:
	return {"last": _last, "best": _best, "crossed": _crossed, "went_down": _went_down, "shocks": _shocks}
