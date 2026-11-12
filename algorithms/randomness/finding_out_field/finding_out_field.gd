# finding_out_field.gd
# A field of covered tiles. Which are live was drawn before anyone stepped on one; a step uncovers, it does not draw.
#
# @identity
# essence: at the start of a round one draw assigns every one-metre cell: a safe path from one end to the other is
#   written first, then every other cell is safe with P = 0.3 and live otherwise. 192 half-metre tiles cover the
#   48 cells. Stepping on a cell uncovers it: a safe cell turns green and shows how many of its eight neighbours
#   are live; a live cell turns red and takes charge.
# desire: to be crossed by reasoning. The assignment is fixed; what changes with every step is what a body knows.
# critical_parameter: tells - what an uncovered safe cell says (count | self | none). `count` gives the number of
#   live neighbours, and the path can be deduced; `self` only that this cell is safe; `none` nothing at all, so
#   only the shocks teach.
# triggers: a step uncovers a cell; COVER AGAIN hides everything and keeps the assignment; NEW DRAW deals another.
# emerges: after COVER AGAIN the field is the same and the crossing is not: memory belongs to the player as well
#   as the machine.
# needs: 6 x 8 m of floor with ribs to sit in [a `lattices` layer of the place kit]; the tower's charge.
# relationships: [[random_doors]]' rule at the scale of a field - three doors there, 48 cells here: "The passage
#   was assigned at the start of the round. Pressing reveals that decision. It does not make another draw. One
#   passage is guaranteed because we wrote that condition before choosing its index." Beside
#   [[vanishing_tile_crossing]] and [[stone_cross_crossing]], where the draw is in the timing; here it is in place.
# truth: A draw made before you arrived is not chance any more; it is something to find out.
# lineage: MATH - conditional probability: each uncovered count narrows where the live cells can be. DESIGN -
#   Minesweeper (the count), the glass bridge (the hidden assignment). ARCHITECTURE - the tiled floor as a board.
# history: 2026-11-12, the Void, floor Random_Game. Palle: "continue with the next real game with a lot more tiles."
#   The floor had the rule as three doors watched from behind a line.

extends Node3D

const Stock := preload("res://commons/artifacts/construction_site/stock.gd")
const COVERED := Color(0.33, 0.40, 0.52)
const SAFE := Color(0.35, 0.80, 0.45)
const LIVE := Color(0.92, 0.25, 0.22)

## What an uncovered safe cell says.
@export_enum("count", "self", "none") var tells := "count"
@export var seed_value := 91701
@export var cells := Vector2i(6, 8)        ## one-metre cells, east-west by north-south
@export var tile := 0.5
@export var safe_share := 0.3              ## how many of the cells off the path are safe
@export var shock := 20.0                  ## charge a live cell takes

var _live := PackedByteArray()
var _shown := PackedByteArray()
var _path: Array[Vector2i] = []
var _tiles: MultiMesh
var _labels := {}
var _inside := {}          # body id -> {body, cell, side, since}
var _last := -1.0
var _best := -1.0
var _crossed := 0
var _shocks := 0
var _now := 0.0
var _board: Label3D
var _last_step := -10.0


func _ready() -> void:
	_read_config()
	_build()
	deal()


func _read_config() -> void:
	if has_meta("config_tells") and str(get_meta("config_tells")) in ["count", "self", "none"]:
		tells = str(get_meta("config_tells"))
	for meta in ["config_seed_value", "config_seed"]:
		if has_meta(meta): seed_value = int(str(get_meta(meta)).to_float())
	for key in ["safe_share", "shock"]:
		if has_meta("config_" + key): set(key, str(get_meta("config_" + key)).to_float())


func apply_grid_config(config_data: Dictionary) -> void:
	for key in config_data:
		set_meta("config_" + str(key), config_data[key])
	_read_config()
	if is_inside_tree() and _tiles != null:
		deal()


func _index(c: Vector2i) -> int:
	return c.y * cells.x + c.x


func _inside_field(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < cells.x and c.y < cells.y


## The middle of a cell, in the work's own metres. Row 0 is the north end.
func cell_centre(c: Vector2i) -> Vector3:
	return Vector3(c.x + .5 - cells.x / 2.0, 0, c.y + .5 - cells.y / 2.0)


func cell_at(local: Vector3) -> Vector2i:
	return Vector2i(floori(local.x + cells.x / 2.0), floori(local.z + cells.y / 2.0))


func _build() -> void:
	var per := roundi(1.0 / tile)
	var slab := BoxMesh.new()
	slab.size = Vector3(tile - .04, .05, tile - .04)
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = .55
	_tiles = MultiMesh.new()
	_tiles.transform_format = MultiMesh.TRANSFORM_3D
	_tiles.use_colors = true
	_tiles.mesh = slab
	_tiles.instance_count = cells.x * cells.y * per * per
	var n := 0
	for cy in cells.y:
		for cx in cells.x:
			for j in per:
				for i in per:
					var at := Vector3(cx + (i + .5) * tile - cells.x / 2.0, .005, cy + (j + .5) * tile - cells.y / 2.0)
					_tiles.set_instance_transform(n, Transform3D(Basis(), at))
					n += 1
	var tiles := MultiMeshInstance3D.new()
	tiles.name = "Tiles"
	tiles.multimesh = _tiles
	tiles.material_override = material
	add_child(tiles)
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
			var local := to_local((body as Node3D).global_position)
			_inside[body.get_instance_id()] = {"body": body, "cell": Vector2i(-9, -9), "side": "south" if local.z > 0 else "north", "since": _now})
	field.body_exited.connect(_exited)
	var at := Vector3(0, 2.0, cells.y / 2.0 + .7)
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
	# the two plates lie at the south end, either side of the board: a body reads them as it arrives
	_plate("CoverAgain", "COVER AGAIN", Vector3(-2.2, .02, cells.y / 2.0 + .9), "3d6e78", cover)
	_plate("NewDraw", "NEW DRAW", Vector3(2.2, .02, cells.y / 2.0 + .9), "c8452f", func() -> void:
		seed_value += 1
		deal())


func _plate(title: String, text: String, at: Vector3, colour: String, action: Callable) -> void:
	var plate := Stock.box(self, title, at, Vector3(.8, .04, .8), Stock.finish(colour, .6), false)
	var words := Label3D.new()
	words.text = text
	words.font_size = 44
	words.pixel_size = .0015
	words.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	words.modulate = Color("f3ece2")
	words.rotation.x = -PI / 2
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
	area.body_entered.connect(func(body: Node) -> void:
		if not body is CharacterBody3D: return
		var now := Time.get_ticks_msec() / 1000.0
		if now - _last_step < 1.5: return
		_last_step = now
		action.call())


## The draw. The safe path is written first, from the south end to the north; then every other cell is drawn.
func deal() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var count := cells.x * cells.y
	_live.resize(count)
	_live.fill(1)
	_path.clear()
	var at := Vector2i(rng.randi_range(0, cells.x - 1), cells.y - 1)
	_path.append(at)
	while at.y > 0:
		var options: Array[Vector2i] = [at + Vector2i(0, -1)]
		if rng.randf() < .45:
			for side: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0)]:
				var to: Vector2i = at + side
				if _inside_field(to) and not _path.has(to): options.append(to)
		at = options[rng.randi_range(0, options.size() - 1)]
		_path.append(at)
	for c in _path:
		_live[_index(c)] = 0
	for index in count:
		if _live[index] == 1 and rng.randf() < safe_share: _live[index] = 0
	_shocks = 0
	cover()


## Hide what was uncovered. The assignment stays as it was dealt.
func cover() -> void:
	_shown.resize(cells.x * cells.y)
	_shown.fill(0)
	for label in _labels.values():
		if is_instance_valid(label): label.queue_free()
	_labels.clear()
	for index in _tiles.instance_count:
		_tiles.set_instance_color(index, COVERED)
	_write()


func _neighbours_live(c: Vector2i) -> int:
	var n := 0
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			var other := Vector2i(c.x + int(dx), c.y + int(dy))
			if other != c and _inside_field(other) and _live[_index(other)] == 1: n += 1
	return n


func _colour(c: Vector2i, colour: Color) -> void:
	var per := roundi(1.0 / tile)
	var first := _index(c) * per * per
	for k in per * per:
		_tiles.set_instance_color(first + k, colour)


func _step(c: Vector2i) -> void:
	var index := _index(c)
	var live: bool = _live[index] == 1
	if _shown[index] == 0:
		_shown[index] = 1
		if live:
			_colour(c, LIVE)
		elif tells != "none":
			_colour(c, SAFE)
			if tells == "count":
				var label := Label3D.new()
				label.text = str(_neighbours_live(c))
				label.font_size = 96
				label.pixel_size = .0045
				label.alpha_cut = Label3D.ALPHA_CUT_DISCARD
				label.modulate = Color("14301c")
				label.rotation.x = -PI / 2
				label.position = cell_centre(c) + Vector3(0, .04, 0)
				add_child(label)
				_labels[index] = label
	if live:
		_shocks += 1
		var battery := get_tree().get_first_node_in_group("void_health")
		if battery != null and battery.has_method("discharge"): battery.discharge(shock, "live tile")
	_write()


func _physics_process(delta: float) -> void:
	_now += delta
	for key in _inside:
		var entry: Dictionary = _inside[key]
		var body: Node3D = entry.body
		if not is_instance_valid(body):
			continue
		var c := cell_at(to_local(body.global_position))
		if c != entry.cell and _inside_field(c):
			entry.cell = c
			_step(c)


func _exited(body: Node) -> void:
	var key := body.get_instance_id()
	if not _inside.has(key):
		return
	var began: Dictionary = _inside[key]
	_inside.erase(key)
	var out := "south" if to_local((body as Node3D).global_position).z > 0 else "north"
	if out != str(began.side):
		_last = _now - float(began.since)
		_best = _last if _best < 0.0 else minf(_best, _last)
		_crossed += 1
	_write()


func _write() -> void:
	if _board == null:
		return
	var known := 0
	for s in _shown: known += s
	var last := "-" if _last < 0.0 else "%.1f s" % _last
	var best := "-" if _best < 0.0 else "%.1f s" % _best
	_board.text = "FINDING OUT\nlast %s    best %s    crossed %d\nshocks %d    uncovered %d of %d\ndraw %d    a safe cell tells: %s" % [last, best, _crossed, _shocks, known, _shown.size(), seed_value, tells]


# ---------------------------------------------------------------- for probes

## The path that was written first, from the south end to the north.
func safe_path() -> Array:
	return _path


func is_live(c: Vector2i) -> bool:
	return _live[_index(c)] == 1


func is_shown(c: Vector2i) -> bool:
	return _shown[_index(c)] == 1


func score() -> Dictionary:
	var known := 0
	for s in _shown: known += s
	var live := 0
	for l in _live: live += l
	return {"last": _last, "best": _best, "crossed": _crossed, "shocks": _shocks, "uncovered": known, "cells": _shown.size(), "live": live, "tiles": _tiles.instance_count}
