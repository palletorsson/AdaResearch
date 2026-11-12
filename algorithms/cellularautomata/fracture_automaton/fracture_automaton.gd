extends Node3D
## THE FRACTURE AUTOMATON (floor CA_EdgeOfChaos; Palle, 2026-11-12: "Can we use cellular automata to fracture
## objects?")
##
## A block of 12 x 10 x 6 cells, a quarter metre each. A BOND is the face two neighbouring cells share. Every bond
## has a STRENGTH (the grain, a seeded hash) and carries a LOAD. The rule is local and the same everywhere:
##   BLOW    a stone lands on a lattice point; its power is shared among the (up to twelve) live bonds round that
##           point: three planes.
##   STEP    every live bond whose load is more than its strength breaks. Breaking uses the strength up: the EXCESS
##           goes on, in equal shares, to the live bonds AHEAD of it in its own plane (across its four edges). Only
##           when none is left ahead does the crack turn the corner, to the live bonds of the other two directions
##           that touch its edges. With nothing live in reach the excess is lost.
##   PIECES  cells still joined through unbroken bonds. Nothing else decides the pieces.
## A load that did not break a bond stays in it: the next blow reads the stress the block already carries.
##
## The lattice is one thing and the bodies another. `Lattice` below is the rule alone and was predicted on a bench
## before the work was built (six blows on each grain; the tower probe checks the table). The work gives every piece
## a rigid body, so what the rule separates, gravity takes apart. A stone thrown later lands on whatever piece is in
## its way, in that piece's own lattice: a fallen piece breaks by the same rule.
##
## GRAIN is the axis: the same six blows on five strengths.
##   even      one spread of strengths                         rubble of every size
##   layered   weak beds every third horizontal plane          slabs
##   columnar  weak joints every third upright plane           columns
##   glass     weak and all alike                              shards and dust
##   knotted   tough knots in a weak mass                      one boulder and chips
## The skin shows the grain before the first blow: beds as bands, joints as a checker, knots as dark blocks. The
## inside is pink.
##
## It stands in a kit pool (the place's activity): the pool keeps the pieces in. After the sixth blow the pieces lie
## for a while, go back to their places, and the next grain begins. Blows come by themselves while a body is near;
## the STRIKE post on the deck throws one now, the NEXT GRAIN post mends and moves on.
const GRAINS := ["even", "layered", "columnar", "glass", "knotted"]
const SIZE := Vector3i(12, 10, 6)
const CELL := 0.25
const SEED := 7
const DEPTH := 1                      # the stone's point lies this many cells under the face it hits
const TARGETS: Array[Vector2i] = [Vector2i(9, 7), Vector2i(3, 6), Vector2i(6, 4), Vector2i(8, 3), Vector2i(3, 3), Vector2i(7, 2)]
const PIECE_BIT := 256                # the stone's ray sees only the block's pieces
const MAX_SINGLES := 60               # single cells with a body of their own; more than that is dust
const THROW := 0.28
const RAW := Color("f5a9b8")


## The rule alone: bonds, loads, strengths. No bodies, no scene.
class Lattice extends RefCounted:
	const AXES: Array[Vector3i] = [Vector3i(1, 0, 0), Vector3i(0, 1, 0), Vector3i(0, 0, 1)]
	var n: Vector3i
	var grain: String
	var seed_number: int
	var exists := PackedByteArray()
	var broken := PackedByteArray()
	var loads := PackedFloat64Array()
	var strength := PackedFloat64Array()
	var loaded := {}                  # bond -> true: the bonds that carry a load
	var steps := 0
	var broke := 0

	func _init(grain_name: String, size: Vector3i, seed_value: int) -> void:
		n = size
		grain = grain_name
		seed_number = seed_value
		var count := 3 * n.x * n.y * n.z
		exists.resize(count); exists.fill(0)
		broken.resize(count); broken.fill(0)
		loads.resize(count); loads.fill(0.0)
		strength.resize(count); strength.fill(0.0)
		for a in 3:
			for i in n.x:
				for j in n.y:
					for k in n.z:
						if inside(i + AXES[a].x, j + AXES[a].y, k + AXES[a].z):
							var b := bond(a, i, j, k)
							exists[b] = 1
							strength[b] = strength_of(grain, seed_number, a, i, j, k)

	static func hash01(key: Array) -> float:
		var h := 2166136261
		for v in key:
			h = ((h ^ (int(v) & 0xffffffff)) * 16777619) & 0xffffffff
			h ^= h >> 13
			h = (h * 1274126177) & 0xffffffff
		h ^= h >> 16
		return float(h & 0xffffff) / 16777216.0

	## The grain: what a bond can bear.
	static func strength_of(grain_name: String, seed_value: int, a: int, i: int, j: int, k: int) -> float:
		var h := hash01([seed_value, a, i, j, k])
		match grain_name:
			"glass":
				return 0.30 + 0.12 * h
			"layered":        # weak beds: every third horizontal plane parts easily
				return (0.16 + 0.1 * h) if (a == 1 and j % 3 == 2) else (0.75 + 0.6 * h)
			"columnar":       # weak joints: every third upright plane, both ways
				return (0.16 + 0.1 * h) if ((a == 0 and i % 3 == 2) or (a == 2 and k % 3 == 2)) else (0.75 + 0.6 * h)
			"knotted":        # tough knots, three cells a side, in a weak mass
				return (1.6 + 0.8 * h) if hash01([seed_value, 99, i / 3, j / 3, k / 3]) > 0.62 else (0.28 + 0.3 * h)
		return 0.35 + 0.65 * h

	func inside(i: int, j: int, k: int) -> bool:
		return i >= 0 and i < n.x and j >= 0 and j < n.y and k >= 0 and k < n.z

	func cell(i: int, j: int, k: int) -> int:
		return (i * n.y + j) * n.z + k

	func cell_at(c: int) -> Vector3i:
		return Vector3i(c / (n.y * n.z), (c / n.z) % n.y, c % n.z)

	## The face between cell (i, j, k) and its neighbour one step along axis a.
	func bond(a: int, i: int, j: int, k: int) -> int:
		return ((a * n.x + i) * n.y + j) * n.z + k

	func bond_at(b: int) -> Array:
		return [b / (n.z * n.y * n.x), Vector3i((b / (n.z * n.y)) % n.x, (b / n.z) % n.y, b % n.z)]

	## The bond's index if it is there and whole, else -1.
	func live(a: int, i: int, j: int, k: int) -> int:
		if not inside(i, j, k): return -1
		var b := bond(a, i, j, k)
		return b if exists[b] == 1 and broken[b] == 0 else -1

	## The live bonds that share an edge with bond b: [those ahead in its own plane, those round the corner].
	func touching(b: int) -> Array:
		var at: Array = bond_at(b)
		var a: int = at[0]
		var p: Vector3i = at[1]
		var ahead := PackedInt32Array()
		var around := PackedInt32Array()
		for t in 3:
			if t == a: continue
			for s in [1, -1]:
				var q: Vector3i = p + AXES[t] * s
				var x := live(a, q.x, q.y, q.z)
				if x >= 0: ahead.append(x)
				var base: Vector3i = p
				if s == -1: base -= AXES[t]
				x = live(t, base.x, base.y, base.z)
				if x >= 0: around.append(x)
				base += AXES[a]
				x = live(t, base.x, base.y, base.z)
				if x >= 0: around.append(x)
		return [ahead, around]

	## A stone on lattice point v: its power shared among the live bonds round it (of one piece, if one is named).
	func load_point(v: Vector3i, power: float, piece_of: PackedInt32Array = PackedInt32Array(), piece: int = -1) -> int:
		var bonds := PackedInt32Array()
		for a in 3:
			var others: Array = [0, 1, 2]
			others.erase(a)
			for da in [-1, 0]:
				for db in [-1, 0]:
					var c: Vector3i = v - AXES[a] + AXES[others[0]] * da + AXES[others[1]] * db
					var x := live(a, c.x, c.y, c.z)
					if x < 0: continue
					if piece >= 0 and piece_of[cell(c.x, c.y, c.z)] != piece: continue
					bonds.append(x)
		for b in bonds:
			loads[b] += power / float(maxi(1, bonds.size()))
			loaded[b] = true
		return bonds.size()

	## One step of the rule. Returns the bonds that broke.
	func step() -> PackedInt32Array:
		var breaking := PackedInt32Array()
		for b: int in loaded:
			if broken[b] == 0 and loads[b] > strength[b]: breaking.append(b)
		if breaking.is_empty(): return breaking
		breaking.sort()
		for b in breaking: broken[b] = 1
		var gains := {}
		for b in breaking:
			var near: Array = touching(b)
			var heirs: PackedInt32Array = near[0] if not (near[0] as PackedInt32Array).is_empty() else near[1]
			if heirs.is_empty(): continue
			var excess: float = loads[b] - strength[b]
			for q in heirs: gains[q] = float(gains.get(q, 0.0)) + excess / float(heirs.size())
		for b in breaking:
			loads[b] = 0.0
			loaded.erase(b)
		for q: int in gains:
			loads[q] += float(gains[q])
			loaded[q] = true
		steps += 1
		broke += breaking.size()
		return breaking

	func run() -> int:
		var before := broke
		while not step().is_empty(): pass
		return broke - before

	## The cells still joined through unbroken bonds, as lists of cells.
	func components() -> Array:
		var seen := PackedInt32Array()
		seen.resize(n.x * n.y * n.z); seen.fill(-1)
		var out := []
		for c in seen.size():
			if seen[c] >= 0: continue
			var comp := PackedInt32Array([c])
			seen[c] = out.size()
			var head := 0
			while head < comp.size():
				var x: Vector3i = cell_at(comp[head])
				head += 1
				for a in 3:
					for s in [1, -1]:
						var y: Vector3i = x + AXES[a] * s
						if not inside(y.x, y.y, y.z): continue
						var cy := cell(y.x, y.y, y.z)
						if seen[cy] >= 0: continue
						var lo: Vector3i = x if s == 1 else y
						if broken[bond(a, lo.x, lo.y, lo.z)] == 1: continue
						seen[cy] = out.size()
						comp.append(cy)
			out.append(comp)
		return out


@export_enum("even", "layered", "columnar", "glass", "knotted") var grain := "even"
@export var power := 90.0               ## the load of one stone
@export var blow_seconds := 5.0         ## between blows, when they come by themselves
@export var hold_seconds := 9.0         ## the pieces lie this long after the sixth blow
@export var mend_seconds := 2.6
@export var steps_per_second := 30.0    ## the rule's steps, slow enough to see the crack run
@export var kick := 4.5                 ## metres a second a new piece is thrown at the stone's point; less further off, and never enough to clear the pool
@export var cycle := true               ## blows come by themselves and the grains follow one another
@export var always := false             ## run with nobody near (a bench or a test)
@export var preblows := 0               ## blows already landed when the work appears: the rule alone, on the lattice's own points
@export var exploded := 0.0             ## above 0 the pieces are held apart by this share of their distance from the centre (a still)
@export var loudness_db := -14.0

var _lat: Lattice
var _piece_of := PackedInt32Array()     # cell -> piece id, -1 for dust
var _pieces := {}                       # id -> {body, cells, marks: MultiMeshInstance3D, mark_list: Array}
var _next_id := 0
var _dust := 0
var _root: Node3D                       # the lattice's frame: a piece at rest has the identity transform in it
var _furniture: Node3D
var _slot := Vector2(6, 6)
var _rim := 0.0                         # the deck's height above the work's own floor
var _slotted := false
var _phase := "whole"                   # whole | throw | cracking | fallen | rubble | mending
var _blows := 0
var _timer := 0.0
var _t := 0.0
var _acc := 0.0
var _now := 0.0
var _seated := false
var _strike_now := false
var _next_now := false
var _pressed := -10.0
var _near := {}
var _stone: MeshInstance3D
var _stone_from := Vector3.ZERO
var _stone_to := Vector3.ZERO
var _hit := {}
var _last := {}
var _mend_from := {}
var _board: Label3D
var _skin: StandardMaterial3D
var _ink: StandardMaterial3D
var _mark_mesh: BoxMesh
var _matter: PhysicsMaterial
var _clicks: Array[AudioStreamWAV] = []
var _voices: Array[AudioStreamPlayer3D] = []
var _voice := 0
var _posts: Array[Vector3] = []
var _own_floor: StaticBody3D
var _spent_usec := 0
var _frames := 0
var _worst_usec := 0


func _ready() -> void:
	var given := {}
	for key in ["slot_size", "slot_floor", "slot_rim", "grain", "power", "blow_seconds", "hold_seconds", "mend_seconds", "steps_per_second", "kick", "cycle", "always", "preblows", "exploded", "loudness_db"]:
		if has_meta("config_" + key): given[key] = get_meta("config_" + key)
	_take(given)
	_skin = StandardMaterial3D.new()
	_skin.vertex_color_use_as_albedo = true
	_skin.vertex_color_is_srgb = true
	_skin.roughness = 0.9
	_ink = StandardMaterial3D.new()
	_ink.albedo_color = Color(1.0, 0.42, 0.1)       # the orange of the crack plate that stands beside it
	_ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mark_mesh = BoxMesh.new()
	_mark_mesh.size = Vector3(CELL + 0.03, 0.03, 0.03)
	_matter = PhysicsMaterial.new()
	_matter.friction = 0.6
	_matter.bounce = 0.02
	_render_clicks()
	_build_furniture()
	_restart()


## Set what the config names. Returns what has to be rebuilt: 0 nothing, 1 the block, 2 the furniture too.
func _take(config_data: Dictionary) -> int:
	var redo := 0
	if config_data.has("slot_size") and config_data["slot_size"] is Array and (config_data["slot_size"] as Array).size() == 2:
		var size := Vector2(float(config_data["slot_size"][0]), float(config_data["slot_size"][1]))
		if size != _slot or not _slotted: redo = 2
		_slot = size
		_slotted = true
	if config_data.has("slot_rim") or config_data.has("slot_floor"):
		var rim: float = float(config_data.get("slot_rim", 0.0)) - float(config_data.get("slot_floor", 0.0))
		if config_data.has("slot_rim") and config_data.has("slot_floor") and not is_equal_approx(rim, _rim):
			_rim = rim
			redo = 2
	if config_data.has("grain") and str(config_data["grain"]) in GRAINS and str(config_data["grain"]) != grain:
		grain = str(config_data["grain"])
		redo = maxi(redo, 1)
	if config_data.has("preblows") and int(float(str(config_data["preblows"]))) != preblows:
		preblows = clampi(int(float(str(config_data["preblows"]))), 0, TARGETS.size())
		redo = maxi(redo, 1)
	if config_data.has("exploded") and not is_equal_approx(float(str(config_data["exploded"])), exploded):
		exploded = maxf(0.0, float(str(config_data["exploded"])))
		redo = maxi(redo, 1)
	for key in ["power", "blow_seconds", "hold_seconds", "mend_seconds", "steps_per_second", "kick", "loudness_db"]:
		if config_data.has(key): set(key, float(str(config_data[key])))
	for key in ["cycle", "always"]:
		if config_data.has(key): set(key, str(config_data[key]).to_lower() in ["true", "1", "yes"])
	return redo


func apply_grid_config(config_data: Dictionary) -> void:
	var redo := _take(config_data)
	if not is_inside_tree() or _skin == null: return
	if redo == 2: _build_furniture()
	if redo >= 1: _restart()


## ---- the block ----

func _block_origin() -> Vector3:
	return Vector3(-float(SIZE.x) * CELL * 0.5, 0.0, -float(SIZE.z) * CELL)      # its front face on the pool's middle line


func _restart() -> void:
	if _root != null:
		remove_child(_root)
		_root.queue_free()
	_root = Node3D.new()
	_root.name = "Block"
	_root.position = _block_origin()
	add_child(_root)
	_pieces.clear()
	_mend_from.clear()
	_lat = Lattice.new(grain, SIZE, SEED)
	_piece_of.resize(SIZE.x * SIZE.y * SIZE.z)
	_piece_of.fill(0)
	_next_id = 1
	_dust = 0
	_blows = 0
	_last = {}
	_hit = {}
	_seated = false
	_strike_now = false
	_next_now = false
	var all := PackedInt32Array()
	all.resize(_piece_of.size())
	for c in all.size(): all[c] = c
	_make_piece(0, all, Transform3D.IDENTITY)
	_phase = "whole"
	_timer = blow_seconds * 0.5
	if preblows > 0:
		for i in preblows:
			_lat.load_point(Vector3i(TARGETS[i].x, TARGETS[i].y, SIZE.z - DEPTH), power)
			_lat.run()
		_blows = preblows
		_split(Vector3.ZERO, false)
		_phase = "rubble" if _blows >= TARGETS.size() else "fallen"
		_timer = hold_seconds if _phase == "rubble" else blow_seconds
	if exploded > 0.0:
		var middle := Vector3(SIZE) * CELL * 0.5
		for id: int in _pieces:
			var body: RigidBody3D = _pieces[id].body
			body.freeze = true
			body.position = (_centre(_pieces[id].cells) - middle) * exploded
	if _stone != null: _stone.visible = false
	_write()


func _centre(cells: PackedInt32Array) -> Vector3:
	var sum := Vector3.ZERO
	for c in cells: sum += Vector3(_lat.cell_at(c))
	return (sum / float(maxi(1, cells.size())) + Vector3(0.5, 0.5, 0.5)) * CELL


func _make_piece(id: int, cells: PackedInt32Array, at: Transform3D, linear := Vector3.ZERO, angular := Vector3.ZERO, cracks := PackedInt32Array()) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.name = "Piece_%d" % id
	body.set_meta("piece", id)
	body.collision_layer = 1 | PIECE_BIT
	body.collision_mask = 1
	body.physics_material_override = _matter
	body.transform = at
	body.sleeping = linear == Vector3.ZERO and angular == Vector3.ZERO
	_root.add_child(body)
	body.linear_velocity = linear
	body.angular_velocity = angular
	_pieces[id] = {"body": body, "cells": cells, "marks": null, "mark_list": []}
	_dress(id, cracks)
	return body


## The piece's mesh, its colliders, its crack lines (`cracks`: the broken bonds inside it): all from its cells.
func _dress(id: int, cracks := PackedInt32Array()) -> void:
	var piece: Dictionary = _pieces[id]
	var body: RigidBody3D = piece.body
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	var cells: PackedInt32Array = piece.cells
	body.mass = 6.0 * float(cells.size())
	var shown := MeshInstance3D.new()
	shown.name = "Skin"
	shown.mesh = _mesh_for(id, cells)
	shown.material_override = _skin
	body.add_child(shown)
	for box in _boxes(cells):
		var shape := CollisionShape3D.new()
		var solid := BoxShape3D.new()
		solid.size = Vector3(box[1]) * CELL - Vector3.ONE * 0.006
		shape.shape = solid
		shape.position = (Vector3(box[0]) + Vector3(box[1]) * 0.5) * CELL
		body.add_child(shape)
	piece.marks = null
	piece.mark_list = []
	_mark(id, cracks)


func _skin_of(c: Vector3i) -> Color:
	var h: float = Lattice.hash01([SEED, 5, c.x, c.y, c.z])
	match grain:
		"layered":
			return [Color(0.58, 0.63, 0.71), Color(0.76, 0.80, 0.85)][(c.y / 3) % 2] * (0.96 + 0.04 * h)
		"columnar":
			return [Color(0.38, 0.40, 0.46), Color(0.53, 0.55, 0.61)][(c.x / 3 + c.z / 3) % 2] * (0.96 + 0.04 * h)
		"glass":
			return Color(0.78, 0.92, 0.98) * (0.97 + 0.03 * h)
		"knotted":
			return (Color(0.45, 0.33, 0.22) if Lattice.hash01([SEED, 99, c.x / 3, c.y / 3, c.z / 3]) > 0.62 else Color(0.86, 0.76, 0.61)) * (0.95 + 0.05 * h)
	return Color(0.80, 0.80, 0.78) * (0.93 + 0.07 * h)


func _mesh_for(id: int, cells: PackedInt32Array) -> ArrayMesh:
	var points := PackedVector3Array()
	var normals := PackedVector3Array()
	var colours := PackedColorArray()
	var order := PackedInt32Array()
	for c in cells:
		var p: Vector3i = _lat.cell_at(c)
		var skin := _skin_of(p)
		var middle := (Vector3(p) + Vector3(0.5, 0.5, 0.5)) * CELL
		for a in 3:
			for s in [1, -1]:
				var q: Vector3i = p + Lattice.AXES[a] * s
				var outside: bool = not _lat.inside(q.x, q.y, q.z)
				if not outside and _piece_of[_lat.cell(q.x, q.y, q.z)] == id: continue
				var normal := Vector3(Lattice.AXES[a]) * float(s)
				var u := Vector3(Lattice.AXES[(a + 1) % 3]) * CELL * 0.5
				var v := Vector3(Lattice.AXES[(a + 2) % 3]) * CELL * 0.5
				var o := middle + normal * CELL * 0.5
				var first := points.size()
				# clockwise seen from outside: Godot's front face
				var corners: Array = [o - u - v, o - u + v, o + u + v, o + u - v] if s == 1 else [o - u - v, o + u - v, o + u + v, o - u + v]
				for corner: Vector3 in corners:
					points.append(corner)
					normals.append(normal)
					colours.append(skin if outside else RAW)
				order.append_array([first, first + 1, first + 2, first, first + 2, first + 3])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colours
	arrays[Mesh.ARRAY_INDEX] = order
	var mesh := ArrayMesh.new()
	if not points.is_empty(): mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## A piece's cells as few boxes: a run along z, widened in y, then in x.
func _boxes(cells: PackedInt32Array) -> Array:
	var free := {}
	for c in cells: free[c] = true
	var sorted := cells.duplicate()
	sorted.sort()
	var out := []
	for c in sorted:
		if not free.has(c): continue
		var p: Vector3i = _lat.cell_at(c)
		var size := Vector3i(1, 1, 1)
		while p.z + size.z < SIZE.z and free.has(_lat.cell(p.x, p.y, p.z + size.z)): size.z += 1
		while p.y + size.y < SIZE.y:
			var whole := true
			for k in size.z:
				if not free.has(_lat.cell(p.x, p.y + size.y, p.z + k)): whole = false; break
			if not whole: break
			size.y += 1
		while p.x + size.x < SIZE.x:
			var whole := true
			for j in size.y:
				for k in size.z:
					if not free.has(_lat.cell(p.x + size.x, p.y + j, p.z + k)): whole = false; break
				if not whole: break
			if not whole: break
			size.x += 1
		for i in size.x:
			for j in size.y:
				for k in size.z: free.erase(_lat.cell(p.x + i, p.y + j, p.z + k))
		out.append([p, size])
	return out


## Crack lines: where a broken bond inside a piece meets that piece's surface, a dark line along the edge.
func _mark(id: int, bonds: PackedInt32Array) -> void:
	if not _pieces.has(id) or bonds.is_empty(): return
	var piece: Dictionary = _pieces[id]
	var list: Array = piece.mark_list
	for b in bonds:
		var at: Array = _lat.bond_at(b)
		var a: int = at[0]
		var p: Vector3i = at[1]
		var q: Vector3i = p + Lattice.AXES[a]
		var face := (Vector3(p) + Vector3(0.5, 0.5, 0.5)) * CELL + Vector3(Lattice.AXES[a]) * CELL * 0.5
		for t in 3:
			if t == a: continue
			var along: int = 3 - a - t
			for s in [1, -1]:
				var beside_p: Vector3i = p + Lattice.AXES[t] * s
				var beside_q: Vector3i = q + Lattice.AXES[t] * s
				var covered: bool = _lat.inside(beside_p.x, beside_p.y, beside_p.z) and _piece_of[_lat.cell(beside_p.x, beside_p.y, beside_p.z)] == id \
					and _piece_of[_lat.cell(beside_q.x, beside_q.y, beside_q.z)] == id
				if covered: continue
				var turn := Basis()
				if along == 1: turn = Basis(Vector3(0, 0, 1), PI * 0.5)
				elif along == 2: turn = Basis(Vector3(0, 1, 0), -PI * 0.5)
				list.append(Transform3D(turn, face + Vector3(Lattice.AXES[t]) * float(s) * CELL * 0.5))
	if list.is_empty(): return
	var shown: MultiMeshInstance3D = piece.marks
	if shown == null:
		shown = MultiMeshInstance3D.new()
		shown.name = "Cracks"
		shown.material_override = _ink
		shown.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var many := MultiMesh.new()
		many.transform_format = MultiMesh.TRANSFORM_3D
		many.mesh = _mark_mesh
		shown.multimesh = many
		(piece.body as Node3D).add_child(shown)
		piece.marks = shown
	var multi: MultiMesh = shown.multimesh
	var had: int = multi.visible_instance_count if multi.visible_instance_count >= 0 else 0
	if list.size() > multi.instance_count:
		multi.instance_count = maxi(64, list.size() * 2)      # growing clears the buffer: write them all again
		had = 0
	for i in range(had, list.size()): multi.set_instance_transform(i, list[i])
	multi.visible_instance_count = list.size()


## The rule has stopped: what is no longer joined becomes a piece of its own.
func _split(strike: Vector3, thrown: bool) -> Array:
	var by_piece := {}
	for comp: PackedInt32Array in _lat.components():
		var old: int = _piece_of[comp[0]]
		if old < 0: continue
		if not by_piece.has(old): by_piece[old] = []
		(by_piece[old] as Array).append(comp)
	var singles := 0
	for id: int in _pieces:
		if (_pieces[id].cells as PackedInt32Array).size() == 1: singles += 1
	var fresh := []
	var redress := {}
	for old: int in by_piece:
		var parts: Array = by_piece[old]
		if parts.size() == 1 and (parts[0] as PackedInt32Array).size() == (_pieces[old].cells as PackedInt32Array).size(): continue
		parts.sort_custom(func(x: PackedInt32Array, y: PackedInt32Array) -> bool:
			return x.size() > y.size() if x.size() != y.size() else x[0] < y[0])
		var parent: RigidBody3D = _pieces[old].body
		_pieces[old].cells = parts[0]
		redress[old] = true
		for i in range(1, parts.size()):
			var cells: PackedInt32Array = parts[i]
			if cells.size() == 1 and singles >= MAX_SINGLES:
				_piece_of[cells[0]] = -1
				_dust += 1
				continue
			if cells.size() == 1: singles += 1
			var id := _next_id
			_next_id += 1
			for c in cells: _piece_of[c] = id
			fresh.append([id, cells, parent])
	# the broken bonds that lie inside one piece: its crack lines
	var inside_of := {}
	for b in _lat.broken.size():
		if _lat.broken[b] == 0: continue
		var at: Array = _lat.bond_at(b)
		var p: Vector3i = at[1]
		var q: Vector3i = p + Lattice.AXES[at[0]]
		var id: int = _piece_of[_lat.cell(p.x, p.y, p.z)]
		if id < 0 or id != _piece_of[_lat.cell(q.x, q.y, q.z)]: continue
		if not inside_of.has(id): inside_of[id] = PackedInt32Array()
		(inside_of[id] as PackedInt32Array).append(b)
	for entry in fresh:
		var id: int = entry[0]
		var cells: PackedInt32Array = entry[1]
		var parent: RigidBody3D = entry[2]
		var linear := parent.linear_velocity
		var angular := parent.angular_velocity
		if thrown:
			# what the rule lets go is thrown: away from the stone and out from the block, a little up, slower the further
			# from the stone - and never so fast that it would clear the pool before it lands
			var here: Vector3 = parent.global_transform * _centre(cells)
			var from: Vector3 = here - strike
			var far: float = from.length()
			var out: Vector3 = here - _root.to_global(Vector3(SIZE) * CELL * 0.5)
			out.y = 0.0
			var flat: Vector3 = from / maxf(far, 0.01) * 0.5 + (out.normalized() if out.length() > 0.05 else Vector3.ZERO) * 0.7
			flat.y = 0.0
			var local: Vector3 = to_local(here)
			var room: float = maxf(0.0, minf(_slot.x * 0.5 - absf(local.x), _slot.y * 0.5 - absf(local.z)) - 0.45)
			var fall: float = sqrt(2.0 * maxf(local.y, 0.3) / 9.8) + 0.35
			var speed: float = minf(kick * (0.35 + 0.65 * exp(-far / 1.5)), room / fall)
			linear += (flat.normalized() if flat.length() > 0.01 else Vector3.ZERO) * speed + Vector3.UP * minf(1.4, kick * 0.3)
			var spin := Vector3(Lattice.hash01([id, 1]) - 0.5, Lattice.hash01([id, 2]) - 0.5, Lattice.hash01([id, 3]) - 0.5)
			angular += spin * 3.0
		_make_piece(id, cells, parent.transform, linear, angular, inside_of.get(id, PackedInt32Array()))
	for old: int in redress:
		_dress(old, inside_of.get(old, PackedInt32Array()))
		(_pieces[old].body as RigidBody3D).sleeping = false
	return fresh


## ---- the furniture: board, posts, the stone, who is near ----

func _build_furniture() -> void:
	if _furniture != null:
		remove_child(_furniture)
		_furniture.queue_free()
	_furniture = Node3D.new()
	_furniture.name = "Furniture"
	add_child(_furniture)
	_posts.clear()
	_voices.clear()
	var half := _slot.y * 0.5
	var deck := half + 1.0                 # the deck begins where the pool's rim ends
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.11, 0.115, 0.13)
	dark.roughness = 0.85
	# the board stands on the ground outside the deck and reads from the hall
	var stand := Node3D.new()
	stand.name = "Board"
	stand.position = Vector3(1.0, -0.03 if _slotted else 0.0, deck + 2.3 if _slotted else half + 1.4)
	_furniture.add_child(stand)
	var panel := MeshInstance3D.new()
	var face := BoxMesh.new()
	face.size = Vector3(2.6, 1.2, 0.06)
	panel.mesh = face
	panel.material_override = dark
	panel.position.y = _rim + 0.85
	stand.add_child(panel)
	for side in [-1.1, 1.1]:
		var post := MeshInstance3D.new()
		var leg := BoxMesh.new()
		leg.size = Vector3(0.08, _rim + 0.3, 0.06)
		post.mesh = leg
		post.material_override = dark
		post.position = Vector3(side, (_rim + 0.3) * 0.5, 0)
		stand.add_child(post)
	_board = Label3D.new()
	_board.pixel_size = 0.0022
	_board.font_size = 30
	_board.line_spacing = 2.0
	_board.modulate = Color(0.88, 0.94, 1.0)
	_board.outline_size = 4
	_board.outline_modulate = Color(0, 0, 0, 1)
	_board.width = 1120
	_board.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_board.position = Vector3(0, _rim + 0.85, 0.035)
	stand.add_child(_board)
	# two posts on the deck: walk up to one and it is pressed
	var words := ["STRIKE", "NEXT\nGRAIN"]
	for which in 2:
		var at := Vector3(2.3, _rim, deck + 1.3 - float(which) * 1.0)
		_posts.append(at)
		var post := MeshInstance3D.new()
		var pillar := BoxMesh.new()
		pillar.size = Vector3(0.22, 1.0, 0.22)
		post.mesh = pillar
		post.material_override = dark
		post.position = at + Vector3(0, 0.5, 0)
		_furniture.add_child(post)
		var word := Label3D.new()
		word.text = words[which]
		word.pixel_size = 0.0026
		word.font_size = 34
		word.modulate = Color(1.0, 0.82, 0.16)
		word.outline_size = 4
		word.outline_modulate = Color(0, 0, 0, 1)
		word.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		word.position = at + Vector3(0, 1.22, 0)
		_furniture.add_child(word)
		var area := Area3D.new()
		area.collision_layer = 0
		area.collision_mask = 0xFFFFFFFF
		var reach := CollisionShape3D.new()
		var column := CylinderShape3D.new()
		column.radius = 0.5
		column.height = 2.0
		reach.shape = column
		reach.position.y = 1.0
		area.add_child(reach)
		area.position = at
		area.body_entered.connect(func(b: Node) -> void:
			if b is CharacterBody3D: press(which))
		_furniture.add_child(area)
	_stone = MeshInstance3D.new()
	_stone.name = "Stone"
	var ball := SphereMesh.new()
	ball.radius = 0.09
	ball.height = 0.18
	_stone.mesh = ball
	var lit := StandardMaterial3D.new()
	lit.albedo_color = Color(1, 1, 1)
	lit.emission_enabled = true
	lit.emission = Color(1.0, 0.95, 0.8)
	lit.emission_energy_multiplier = 1.6
	_stone.material_override = lit
	_stone.visible = false
	_furniture.add_child(_stone)
	var zone := Area3D.new()
	zone.name = "Near"
	zone.collision_layer = 0
	zone.collision_mask = 0xFFFFFFFF
	var room := BoxShape3D.new()
	room.size = Vector3(_slot.x + 10.0, 6.0, _slot.y + 12.0)
	var room_shape := CollisionShape3D.new()
	room_shape.shape = room
	room_shape.position = Vector3(0, 2.0, 2.0)
	zone.add_child(room_shape)
	zone.body_entered.connect(func(b: Node) -> void:
		if b is CharacterBody3D: _near[b] = true)
	zone.body_exited.connect(func(b: Node) -> void: _near.erase(b))
	_furniture.add_child(zone)
	for i in 6:
		var voice := AudioStreamPlayer3D.new()
		voice.unit_size = 4.0
		voice.max_distance = 20.0
		_furniture.add_child(voice)
		_voices.append(voice)


func _render_clicks() -> void:
	_clicks.clear()
	for which in 4:
		var count := 1400 if which < 3 else 2600
		var data := PackedByteArray()
		data.resize(count * 2)
		var held := 0.0
		for i in count:
			var t: float = float(i) / 11025.0
			var noise: float = Lattice.hash01([which, i]) * 2.0 - 1.0
			var v: float
			if which < 3:       # a crack: bright noise that dies in a twentieth of a second
				held = lerpf(held, noise, 0.55 + 0.15 * float(which))
				v = (noise - held * 0.6) * exp(-t * (60.0 + 25.0 * float(which))) * 0.7
			else:               # the stone: a low knock
				v = sin(TAU * (95.0 + 60.0 * exp(-t * 30.0)) * t) * exp(-t * 14.0) * 0.9 + noise * exp(-t * 80.0) * 0.25
			data.encode_s16(i * 2, clampi(int(v * 32767.0), -32768, 32767))
		var audio := AudioStreamWAV.new()
		audio.format = AudioStreamWAV.FORMAT_16_BITS
		audio.mix_rate = 11025
		audio.data = data
		_clicks.append(audio)


func _sound(which: int, at: Vector3, pitch: float, quieter := 0.0) -> void:
	if not always and _near.is_empty(): return
	var voice: AudioStreamPlayer3D = _voices[_voice]
	_voice = (_voice + 1) % _voices.size()
	voice.stream = _clicks[which]
	voice.global_position = at
	voice.pitch_scale = pitch
	voice.volume_db = loudness_db - quieter
	voice.play()


func _write() -> void:
	if _board == null or _lat == null: return
	var state := "whole"
	match _phase:
		"throw", "cracking": state = "the crack is running"
		"fallen": state = "blow %d of %d has landed" % [_blows, TARGETS.size()]
		"rubble": state = "six blows have landed"
		"mending": state = "going back"
	_board.text = "\n".join(PackedStringArray(["A BLOCK BROKEN BY A RULE",
		"720 cells. A bond is the face two cells share: it has a strength and carries a load.",
		"A stone is a load. A bond breaks when its load is more than its strength and hands the rest to the bonds ahead in its own plane; with none left the crack turns the corner.",
		"The pieces are whatever is still joined. The same six blows land on every grain.", "",
		"GRAIN %s  |  %s  |  %d bonds broken  |  %d pieces" % [grain.to_upper(), state, _lat.broke, _pieces.size() + _dust]]))


## ---- the blows ----

## Post 0: a stone now. Post 1: mend and go on to the next grain.
func press(which: int) -> void:
	if _now - _pressed < 0.8: return
	_pressed = _now
	if which == 0: _strike_now = true
	else: _next_now = true


func strike() -> void:
	_strike_now = true


func next_grain() -> void:
	_next_now = true


func _sling() -> Vector3:
	return to_global(_posts[0] + Vector3(0, 1.35, 0))


func _begin_blow() -> void:
	var target: Vector2i = TARGETS[_blows % TARGETS.size()]
	var aim: Vector3 = _root.to_global(Vector3(target.x, target.y, SIZE.z) * CELL)
	var from := _sling()
	var way := (aim - from).normalized()
	var query := PhysicsRayQueryParameters3D.create(from, aim + way * 2.5, PIECE_BIT)
	var found: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	_hit = {}
	_stone_from = from
	_stone_to = aim + way * 2.5
	if not found.is_empty() and found.collider is RigidBody3D and (found.collider as Node).has_meta("piece"):
		var body: RigidBody3D = found.collider
		var inverse: Transform3D = body.global_transform.affine_inverse()
		var local: Vector3 = inverse * (found.position as Vector3)
		var inward: Vector3 = -(inverse.basis * (found.normal as Vector3)).normalized()
		var v := Vector3i(((local + inward * CELL * float(DEPTH)) / CELL).round())
		_hit = {"piece": int(body.get_meta("piece")), "vertex": v, "at": found.position}
		_stone_to = found.position
	_stone.visible = true
	_stone.global_position = from
	_t = 0.0
	_phase = "throw"
	_write()


func _land() -> void:
	_stone.visible = false
	_last = {"blow": _blows + 1, "hit": not _hit.is_empty(), "loaded": 0, "broke": 0, "new_pieces": 0, "broken_before": _lat.broke}
	if _hit.is_empty() or not _pieces.has(int(_hit.piece)):
		_after_blow()
		return
	_last["vertex"] = [_hit.vertex.x, _hit.vertex.y, _hit.vertex.z]
	_last["loaded"] = _lat.load_point(_hit.vertex, power, _piece_of, int(_hit.piece))
	_sound(3, _hit.at, 1.0)
	_acc = 0.0
	_phase = "cracking"


func _after_blow() -> void:
	_blows += 1
	_last["broke"] = _lat.broke - int(_last.broken_before)
	if _blows >= TARGETS.size():
		_phase = "rubble"
		_timer = hold_seconds
	else:
		_phase = "fallen"
		_timer = blow_seconds
	_write()


func _footprint_clear() -> bool:
	for b in _near:
		if not is_instance_valid(b): continue
		var here: Vector3 = to_local((b as Node3D).global_position)
		if here.y < float(SIZE.y) * CELL + 0.5 and absf(here.x) < float(SIZE.x) * CELL * 0.5 + 0.35 and here.z > -float(SIZE.z) * CELL - 0.35 and here.z < 0.35: return false
	return true


func _begin_mend() -> void:
	_mend_from.clear()
	for id: int in _pieces:
		var body: RigidBody3D = _pieces[id].body
		body.collision_layer = 0
		body.collision_mask = 0
		body.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		body.freeze = true
		_mend_from[id] = body.transform
	_t = 0.0
	_phase = "mending"
	_write()


## Put the block on what is under it; alone on a bench, on a floor of its own.
func _seat() -> void:
	_seated = true
	var top := to_global(Vector3(0, 1.2, -float(SIZE.z) * CELL * 0.5))
	var query := PhysicsRayQueryParameters3D.create(top, top + Vector3.DOWN * 2.6, 1)
	var skip: Array[RID] = []
	for id: int in _pieces: skip.append((_pieces[id].body as RigidBody3D).get_rid())
	if _own_floor != null: skip.append(_own_floor.get_rid())
	query.exclude = skip
	var found: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	var height := 0.0
	if not found.is_empty():
		height = to_local(found.position).y
		if _own_floor != null:
			_own_floor.queue_free()
			_own_floor = null
	elif _own_floor == null:
		_own_floor = StaticBody3D.new()
		_own_floor.name = "BenchFloor"
		var slab := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(9.0, 0.2, 9.0)
		slab.shape = box
		slab.position.y = -0.1
		_own_floor.add_child(slab)
		add_child(_own_floor)
	_root.position.y = height + 0.004


func _physics_process(delta: float) -> void:
	var began := Time.get_ticks_usec()
	_now += delta
	if not _seated: _seat()
	if exploded <= 0.0: _advance(delta)
	var spent := Time.get_ticks_usec() - began
	_spent_usec += spent
	_worst_usec = maxi(_worst_usec, spent)
	_frames += 1


func _advance(delta: float) -> void:
	var awake: bool = always or not _near.is_empty()
	match _phase:
		"whole", "fallen":
			if _next_now:
				_next_now = false
				if _blows > 0: _begin_mend()
				else:
					grain = GRAINS[(GRAINS.find(grain) + 1) % GRAINS.size()]
					_restart()
				return
			if awake: _timer -= delta
			if _strike_now or (cycle and awake and _timer <= 0.0):
				_strike_now = false
				_begin_blow()
		"throw":
			_t += delta
			var share := clampf(_t / THROW, 0.0, 1.0)
			_stone.global_position = _stone_from.lerp(_stone_to, share) + Vector3.UP * sin(share * PI) * 0.25
			if _t >= THROW: _land()
		"cracking":
			_acc += delta
			var done := 0
			while _acc >= 1.0 / steps_per_second and done < 6:
				_acc -= 1.0 / steps_per_second
				done += 1
				var broke: PackedInt32Array = _lat.step()
				if broke.is_empty():
					var fresh: Array = _split(_hit.get("at", global_position), true)
					_last["new_pieces"] = fresh.size()
					_after_blow()
					break
				var of_piece := {}
				for b in broke:
					var at: Array = _lat.bond_at(b)
					var id: int = _piece_of[_lat.cell(at[1].x, at[1].y, at[1].z)]
					if not of_piece.has(id): of_piece[id] = PackedInt32Array()
					(of_piece[id] as PackedInt32Array).append(b)
				for id: int in of_piece: _mark(id, of_piece[id])
				_sound(_lat.steps % 3, _hit.get("at", global_position), 0.8 + 0.5 * Lattice.hash01([_lat.steps, 7]), clampf(8.0 - float(broke.size()) * 0.5, 0.0, 8.0))
		"rubble":
			if awake: _timer -= delta
			if (_next_now or (cycle and awake and _timer <= 0.0)) and _footprint_clear():
				_next_now = false
				_begin_mend()
		"mending":
			_t += delta
			var share := smoothstep(0.0, 1.0, clampf(_t / mend_seconds, 0.0, 1.0))
			for id: int in _mend_from:
				if _pieces.has(id): (_pieces[id].body as RigidBody3D).transform = (_mend_from[id] as Transform3D).interpolate_with(Transform3D.IDENTITY, share)
			if _t >= mend_seconds:
				grain = GRAINS[(GRAINS.find(grain) + 1) % GRAINS.size()]
				_restart()


## ---- for a test ----

func state() -> Dictionary:
	return {"grain": grain, "phase": _phase, "blows": _blows, "broken": _lat.broke, "steps": _lat.steps, "pieces": _pieces.size(), "dust": _dust, "seated": _seated}


## What the last stone did: where it landed, what broke, what came off.
func last_blow() -> Dictionary:
	return _last


## Every piece: its cells, where its centre is now, how far that is from where it began.
func piece_rows() -> Array:
	var out := []
	for id: int in _pieces:
		var body: RigidBody3D = _pieces[id].body
		var home: Vector3 = _centre(_pieces[id].cells)
		var here: Vector3 = body.transform * home
		out.append({"id": id, "cells": (_pieces[id].cells as PackedInt32Array).size(), "moved_m": here.distance_to(home), "at": to_local(body.global_transform * home), "asleep": body.sleeping})
	return out


## The pieces are a partition of the cells by the unbroken bonds: counts of what is wrong.
func partition() -> Dictionary:
	var counted := 0
	var torn := 0             # pieces that are not one joined body
	var joined := 0           # unbroken bonds between two different pieces
	var parts: Array = _lat.components()
	var part_of := PackedInt32Array()
	part_of.resize(_piece_of.size())
	for i in parts.size():
		for c: int in parts[i]: part_of[c] = i
	for id: int in _pieces:
		var cells: PackedInt32Array = _pieces[id].cells
		counted += cells.size()
		for c in cells:
			if part_of[c] != part_of[cells[0]] or _piece_of[c] != id: torn += 1; break
	for b in _lat.exists.size():
		if _lat.exists[b] == 0 or _lat.broken[b] == 1: continue
		var at: Array = _lat.bond_at(b)
		var q: Vector3i = (at[1] as Vector3i) + Lattice.AXES[at[0]]
		if _piece_of[_lat.cell(at[1].x, at[1].y, at[1].z)] != _piece_of[_lat.cell(q.x, q.y, q.z)]: joined += 1
	return {"cells": counted + _dust, "torn": torn, "joined_across": joined}


func post_point(which: int) -> Vector3:
	return to_global(_posts[which])


func block_centre() -> Vector3:
	return _root.to_global(Vector3(SIZE) * CELL * 0.5)


func frame_ms() -> Dictionary:
	var out := {"mean": float(_spent_usec) / 1000.0 / maxf(1.0, float(_frames)), "worst": float(_worst_usec) / 1000.0}
	_spent_usec = 0
	_frames = 0
	_worst_usec = 0
	return out
