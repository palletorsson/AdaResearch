extends Node3D
class_name BiomeObject
## biome_object.gd — THE BIOME AS ONE OBJECT (2026-09-18, Palle: "skip the glass cage and the
## whole museum for now, just make the biome... look at the old biome and make it better and
## better. Use RSI to make the object and the integrated tiles").
##
## July's biome shot every kingdom alone on a bare platform (/biome-gallery: a tree, a web, a
## grub, each in its own cell). This is the other picture: one ground, and everything on it
## placed by ECOLOGY and CONNECTED —
##
##   substrate   a height field with a basin: relief from noise, the basin dug where the seed
##               puts the water; a flat floor under the pool and a wet shelf round it as the
##               shore (gen 1); the moisture PAINTED on as wet, dry and silt brush layers (gen 1)
##   water       a pool in the basin (the old biome's own pool: disc, ripple rings, reeds), the
##               disc lapping the shelf and the reeds standing on the shore (gen 1)
##   mineral     crystal clusters on the dry ridge
##   fungus      mycelium filaments on the wet rim of the pool, and a mycelium PATH from the
##               pool out to every tree — the network that joins water to wood
##   flora       trees on the mid-moist slope, flowers in the wet meadow, tiers by moisture
##   fauna       creatures beside the flowers and the fungus
##   cover       grass and stubble by moisture, on the surface, everywhere
##
## Every organism is the old biome's builder, reached through BiomePaintDispatcher exactly as
## a painted map cell would reach it, only the CELL is chosen by moisture, height and slope
## instead of by hand. The DNA is five numbers: seed, size, moisture, relief, wildness.
##
## RSI: this file carries its GENERATION and CHANGELOG; tools/biome_rsi.py renders the same
## six DNAs every generation, measures the tiles (integration-v1: kingdoms present +
## connections, named), records the lineage, and a critic proposes the next change. A
## generation that measures worse is culled and the code returns to its parent.
##
## Record: with record=on the build writes res://ada_run/biome_rsi/state/<label>.json — the
## counts the driver reads (organisms per kingdom, connections, cover, heights, build ms).

const Dispatcher := preload("res://commons/biome_layers/biome_paint_dispatcher.gd")
const Ground := preload("res://commons/biome_layers/biome_ground_substrate.gd")
const Cover := preload("res://commons/biome_layers/ground_cover.gd")

const GENERATION := 1
const CHANGELOG: Array[String] = [
	"gen 0: the object — basin terrain, pool, ridge crystals, rim mycelium + a mycelium path to every tree, slope trees, meadow flowers, creatures beside them, cover by moisture",
	"gen 1: the basin filled (a flat floor under the water, a wet shelf as shore, the disc lapping the shelf, reeds on the shore, a bluer water material) and the moisture painted onto the ground as wet, dry and silt brush layers",
]
const STATE_DIR := "res://ada_run/biome_rsi/state"
const K_TREE := 0
const K_CREATURE := 1
const K_FLOWER := 2
const K_FUNGUS := 3

@export var seed: int = 7
## Cells across (one metre each).
@export_range(4, 24) var size: int = 12
## How wet the ground is: the basin's reach, the meadow's extent, the cover's density.
@export_range(0.0, 1.0) var moisture: float = 0.5
## Height of the terrain: 0 is a plain, 1 a hill of two metres with a ridge.
@export_range(0.0, 1.0) var relief: float = 0.5
## How much grows: tree count, flower density, creature count, cover.
@export_range(0.0, 1.0) var wildness: float = 0.6
@export_enum("on", "off") var record: String = "on"

var _built: bool = false
var _field: PackedFloat32Array = PackedFloat32Array()   # per cell 0..1
var _max_h: float = 1.0
var _water: Dictionary = {}          # Vector2i -> true
var _basin_c: Vector2 = Vector2.ZERO
var _basin_r: float = 2.0
var _moist: PackedFloat32Array = PackedFloat32Array()
var _cells: Dictionary = {}          # Vector2i -> {kingdom: String, inten: int, algo: String}
var _trees: Array[Vector2i] = []
var _patch: Node3D
var _dispatcher: Node3D
var _counts: Dictionary = {}
var _build_ms: int = 0


func apply_grid_config(config: Dictionary) -> void:
	if config.has("seed"):
		seed = int(str(config["seed"]).to_int())
	if config.has("size"):
		size = clampi(int(str(config["size"]).to_int()), 4, 24)
	if config.has("moisture"):
		moisture = clampf(float(str(config["moisture"]).to_float()), 0.0, 1.0)
	if config.has("relief"):
		relief = clampf(float(str(config["relief"]).to_float()), 0.0, 1.0)
	if config.has("wildness"):
		wildness = clampf(float(str(config["wildness"]).to_float()), 0.0, 1.0)
	if config.has("record"):
		record = "off" if str(config["record"]).to_lower() in ["off", "0", "false"] else "on"
	if _built and is_inside_tree():
		_rebuild()


func _ready() -> void:
	if _built:
		return
	_build()


func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	_built = false
	_build()


func label() -> String:
	return "s%d_m%02d_r%02d_w%02d" % [seed, int(round(moisture * 100.0)), int(round(relief * 100.0)), int(round(wildness * 100.0))]


func _build() -> void:
	_built = true
	var t0 := Time.get_ticks_msec()
	_counts = {"water": 0, "mineral": 0, "fungus": 0, "fungus_path": 0, "tree": 0, "flower": 0,
		"creature": 0, "cover": 0, "connections": 0, "paint": 0}
	_patch = Node3D.new()
	_patch.name = "Biome"
	add_child(_patch)
	_terrain()
	_ecology()
	_ground()
	_water_pool()
	_minerals()
	_dispatch()
	_cover()
	_build_ms = Time.get_ticks_msec() - t0
	print("[biome_object] gen %d %s: water %d, mineral %d, fungus %d (path %d), trees %d, flowers %d, creatures %d, cover %d, connections %d, paint %d — %d ms" % [
		GENERATION, label(), _counts["water"], _counts["mineral"], _counts["fungus"], _counts["fungus_path"],
		_counts["tree"], _counts["flower"], _counts["creature"], _counts["cover"], _counts["connections"], _counts["paint"], _build_ms])
	if record == "on":
		_write_state()


# ── the ground: a height field with a basin ────────────────────────────────────
func _terrain() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, "terrain"])
	var noise := FastNoiseLite.new()
	noise.seed = seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.13
	noise.fractal_octaves = 3
	noise.fractal_gain = 0.45
	_max_h = 0.5 + 1.7 * relief
	# the basin: where the seed puts the water, its reach grows with moisture
	_basin_c = Vector2(rng.randf_range(0.28, 0.72) * float(size), rng.randf_range(0.28, 0.72) * float(size))
	_basin_r = 1.4 + 2.2 * moisture + 0.15 * float(size) / 12.0
	_field.resize(size * size)
	var lo := 9.0
	var hi := -9.0
	for z in range(size):
		for x in range(size):
			var n: float = (noise.get_noise_2d(float(x) + 0.5, float(z) + 0.5) + 1.0) * 0.5
			_field[z * size + x] = n
			lo = minf(lo, n)
			hi = maxf(hi, n)
	for i in range(size * size):
		_field[i] = (_field[i] - lo) / maxf(0.001, hi - lo)
	_water.clear()
	# gen 1: the basin is FILLED, not dug to a point: a flat floor under the water cells and a
	# wet shelf one metre wide round them, rising 0.16 per metre. The shelf is the wet rim as
	# geometry; its cells (h <= 0.18) fall out of the tree rule, so trees step back from the shore.
	var pool_r: float = _basin_r * 0.62
	for z in range(size):
		for x in range(size):
			var d: float = Vector2(float(x) + 0.5, float(z) + 0.5).distance_to(_basin_c)
			var w: float = clampf(1.0 - d / _basin_r, 0.0, 1.0)
			w = w * w * (3.0 - 2.0 * w)
			var h: float = _field[z * size + x] * (1.0 - w) * (0.75 + 0.25 * relief) + 0.08 * (1.0 - w)
			if d < pool_r:
				h = minf(h, 0.02)                          # flat floor under the water
			elif d < pool_r + 1.0:
				h = minf(h, 0.02 + 0.16 * (d - pool_r))    # the wet shelf, a shore
			_field[z * size + x] = h
			if d < pool_r:
				_water[Vector2i(x, z)] = true


func _h_cell(x: int, z: int) -> float:
	return _field[clampi(z, 0, size - 1) * size + clampi(x, 0, size - 1)] * _max_h


## Surface height at a world xz (bilinear over cell centres).
func _h_at(wx: float, wz: float) -> float:
	var fx: float = wx + float(size) * 0.5 - 0.5
	var fz: float = wz + float(size) * 0.5 - 0.5
	var x0 := int(floor(fx))
	var z0 := int(floor(fz))
	var tx: float = fx - float(x0)
	var tz: float = fz - float(z0)
	var a: float = lerpf(_h_cell(x0, z0), _h_cell(x0 + 1, z0), tx)
	var b: float = lerpf(_h_cell(x0, z0 + 1), _h_cell(x0 + 1, z0 + 1), tx)
	return lerpf(a, b, tz)


func _cell_world(x: int, z: int) -> Vector3:
	var wx: float = float(x) - float(size) * 0.5 + 0.5
	var wz: float = float(z) - float(size) * 0.5 + 0.5
	return Vector3(wx, _h_at(wx, wz), wz)


func _water_level() -> float:
	var lo := 9.0
	for k in _water.keys():
		lo = minf(lo, _h_cell(k.x, k.y))
	return lo + 0.08


# ── the ecology: moisture, then the rules that place every kingdom ───────────────
func _ecology() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, "ecology"])
	_moist.resize(size * size)
	_cells.clear()
	_trees.clear()
	var reach: float = float(size) * (0.35 + 0.35 * moisture)
	for z in range(size):
		for x in range(size):
			var d: float = _water_dist(x, z)
			var h: float = _field[z * size + x]
			var m: float = 0.25 * moisture + 0.75 * clampf(1.0 - d / reach, 0.0, 1.0) - 0.45 * h + rng.randf_range(-0.06, 0.06)
			_moist[z * size + x] = clampf(m, 0.0, 1.0)
	# minerals: the driest high cells, spaced
	var ridge: Array = []
	for z in range(size):
		for x in range(size):
			var key := Vector2i(x, z)
			if _water.has(key):
				continue
			var h: float = _field[z * size + x]
			if h > 0.62 and _moist[z * size + x] < 0.42:
				ridge.append({"key": key, "h": h})
	ridge.sort_custom(func(p, q): return float(p["h"]) > float(q["h"]))
	var n_min: int = clampi(1 + int(round(relief * 3.0)), 1, 4)
	for r in ridge:
		if _counts["mineral"] >= n_min:
			break
		if _spaced(r["key"], 2):
			_cells[r["key"]] = {"kingdom": "mineral", "inten": 3, "algo": ""}
			_counts["mineral"] += 1
	# trees: the mid-moist slope, spaced two cells apart
	var cand: Array = []
	for z in range(size):
		for x in range(size):
			var key := Vector2i(x, z)
			if _water.has(key) or _cells.has(key):
				continue
			var m: float = _moist[z * size + x]
			var h: float = _field[z * size + x]
			if m > 0.32 and m < 0.78 and h > 0.18 and h < 0.8 and _water_dist(x, z) > 1.4:
				cand.append({"key": key, "s": m * (1.0 - absf(h - 0.45)) + rng.randf() * 0.15})
	cand.sort_custom(func(p, q): return float(p["s"]) > float(q["s"]))
	var n_tree: int = clampi(2 + int(round(wildness * 4.0)), 1, 7)
	for c in cand:
		if _trees.size() >= n_tree:
			break
		if _spaced(c["key"], 2):
			var inten: int = clampi(2 + int(round(wildness * 3.0)) + rng.randi_range(-1, 0), 1, 5)
			_cells[c["key"]] = {"kingdom": "tree", "inten": inten, "algo": ""}
			_trees.append(c["key"])
			_counts["tree"] += 1
	# fungus: the wet rim of the pool
	var rim: Array = []
	for z in range(size):
		for x in range(size):
			var key := Vector2i(x, z)
			if _water.has(key) or _cells.has(key):
				continue
			var d: float = _water_dist(x, z)
			if d >= 0.9 and d <= 2.3 and _moist[z * size + x] > 0.45:
				rim.append(key)
	_shuffle(rim, rng)
	var n_rim: int = clampi(2 + int(round(moisture * 5.0)), 2, 7)
	for key in rim:
		if _counts["fungus"] >= n_rim:
			break
		if _spaced(key, 1):
			_cells[key] = {"kingdom": "fungus", "inten": clampi(2 + int(round(moisture * 2.0)), 1, 4), "algo": "mycelium"}
			_counts["fungus"] += 1
	# the mycelium PATH: from the pool rim out to every tree — a chain of cells along the line
	for t in _trees:
		var from := Vector2(_basin_c)
		var to := Vector2(float(t.x) + 0.5, float(t.y) + 0.5)
		var steps: int = int(ceil(from.distance_to(to)))
		for i in range(1, steps):
			var p: Vector2 = from.lerp(to, float(i) / float(steps))
			var key := Vector2i(int(floor(p.x)), int(floor(p.y)))
			if _water.has(key) or _cells.has(key) or key.x < 0 or key.y < 0 or key.x >= size or key.y >= size:
				continue
			if _water_dist(key.x, key.y) < 0.9:
				continue
			if _counts["fungus"] + _counts["fungus_path"] >= 16:
				break
			_cells[key] = {"kingdom": "fungus", "inten": 2, "algo": "mycelium"}
			_counts["fungus_path"] += 1
	# flowers: the wet meadow, density by wildness
	var meadow: Array = []
	for z in range(size):
		for x in range(size):
			var key := Vector2i(x, z)
			if _water.has(key) or _cells.has(key):
				continue
			var m: float = _moist[z * size + x]
			if m > 0.42 and _field[z * size + x] < 0.7:
				meadow.append({"key": key, "m": m + rng.randf() * 0.1})
	meadow.sort_custom(func(p, q): return float(p["m"]) > float(q["m"]))
	var n_fl: int = clampi(int(round(float(meadow.size()) * (0.25 + 0.5 * wildness))), 3, 24)
	for f in meadow:
		if _counts["flower"] >= n_fl:
			break
		var inten: int = clampi(1 + int(round(float(f["m"]) * 4.5)), 1, 5)
		_cells[f["key"]] = {"kingdom": "flower", "inten": inten, "algo": ""}
		_counts["flower"] += 1
	# creatures: beside the flowers and the fungus
	var beside: Array = []
	for z in range(size):
		for x in range(size):
			var key := Vector2i(x, z)
			if _water.has(key) or _cells.has(key):
				continue
			var near := 0
			for dz in range(-1, 2):
				for dx in range(-1, 2):
					var nk := Vector2i(x + dx, z + dz)
					if _cells.has(nk) and String(_cells[nk]["kingdom"]) in ["flower", "fungus"]:
						near += 1
			if near >= 2:
				beside.append(key)
	_shuffle(beside, rng)
	var n_cr: int = clampi(1 + int(round(wildness * 3.0)), 1, 4)
	for key in beside:
		if _counts["creature"] >= n_cr:
			break
		# a creature lives BESIDE things, so the spacing is against other creatures only
		if _spaced_from(key, 2, "creature"):
			_cells[key] = {"kingdom": "creature", "inten": 2 + rng.randi_range(0, 1), "algo": ""}
			_counts["creature"] += 1
	# connections: fungus cells with a tree or flower next to them — the network touches the wood
	for key in _cells.keys():
		if String(_cells[key]["kingdom"]) != "fungus":
			continue
		for dz in range(-1, 2):
			for dx in range(-1, 2):
				var nk: Vector2i = key + Vector2i(dx, dz)
				if nk != key and _cells.has(nk) and String(_cells[nk]["kingdom"]) in ["tree", "flower"]:
					_counts["connections"] += 1
	_counts["water"] = _water.size()


## Array.shuffle() draws from the GLOBAL random and would make the same seed grow two
## different worlds; this one draws from the ecology's rng.
func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var t = arr[i]
		arr[i] = arr[j]
		arr[j] = t


func _water_dist(x: int, z: int) -> float:
	var best := 99.0
	var p := Vector2(float(x), float(z))
	for k in _water.keys():
		best = minf(best, p.distance_to(Vector2(float(k.x), float(k.y))))
	return best


func _spaced(key: Vector2i, r: int) -> bool:
	for dz in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if (dx != 0 or dz != 0) and _cells.has(key + Vector2i(dx, dz)):
				return false
	return true


func _spaced_from(key: Vector2i, r: int, kingdom: String) -> bool:
	for dz in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var nk: Vector2i = key + Vector2i(dx, dz)
			if (dx != 0 or dz != 0) and _cells.has(nk) and String(_cells[nk]["kingdom"]) == kingdom:
				return false
	return true


# ── the bodies ────────────────────────────────────────────────────────────────
func _ground() -> void:
	var g = Ground.new()
	g.name = "Ground"
	g.set_base_offset(0.0)
	g.configure(size, size, 1.0, Vector3.ZERO)
	g.set_field(_field, size, size, _max_h)
	g.set_paint_layers(_moisture_paint(), seed)
	_patch.add_child(g)


## gen 1: the moisture painted onto the ground. Three "shader" brush layers, the shape the
## substrate reads (element / mode / density / color / brush{w, d, cells[[x, z, v]]}), composed
## into its paint texture: moss where the ground is wet, ochre where it is dry AND high, silt
## under the water. The field that placed every organism becomes visible.
func _moisture_paint() -> Array:
	var wet: Array = []
	var dry: Array = []
	var silt: Array = []
	for z in range(size):
		for x in range(size):
			var i: int = z * size + x
			var m: float = _moist[i]
			var vw: float = clampf((m - 0.35) / 0.45, 0.0, 1.0)
			if vw > 0.0:
				wet.append([x, z, vw])
			var vd: float = clampf((0.42 - m) / 0.3, 0.0, 1.0) * clampf((_field[i] - 0.5) / 0.3, 0.0, 1.0)
			if vd > 0.0:
				dry.append([x, z, vd])
			if _water.has(Vector2i(x, z)):
				silt.append([x, z, 1.0])
	_counts["paint"] = wet.size() + dry.size() + silt.size()
	return [_brush_layer([0.20, 0.34, 0.18], wet), _brush_layer([0.74, 0.66, 0.50], dry),
		_brush_layer([0.16, 0.14, 0.11], silt)]


func _brush_layer(color: Array, cells: Array) -> Dictionary:
	return {"element": "shader", "mode": "brush", "density": 1.0, "color": color,
		"brush": {"w": size, "d": size, "cells": cells}}


func _water_pool() -> void:
	if _water.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, "pool"])
	var holder := Node3D.new()
	holder.name = "Pool"
	var c: Vector3 = Vector3(_basin_c.x - float(size) * 0.5, _water_level(), _basin_c.y - float(size) * 0.5)
	holder.position = c
	_patch.add_child(holder)
	var r: float = _basin_r * 0.62 + 0.35   # gen 1: the disc laps the shelf
	var disc := MeshInstance3D.new()
	disc.name = "Disc"
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = 0.02
	disc.mesh = cm
	var wmat := StandardMaterial3D.new()
	wmat.albedo_color = Color(0.18, 0.42, 0.66, 0.85)   # gen 1: water, not slate
	wmat.metallic = 0.25
	wmat.roughness = 0.05
	wmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wmat.emission_enabled = true
	wmat.emission = Color(0.1, 0.3, 0.5) * 0.25
	disc.material_override = wmat
	holder.add_child(disc)
	for k in range(2):
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = r * (0.30 + 0.30 * float(k))
		tm.outer_radius = r * (0.34 + 0.30 * float(k))
		ring.mesh = tm
		var rmat := StandardMaterial3D.new()
		rmat.albedo_color = Color(0.5, 0.75, 0.9, 0.5)
		rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		rmat.emission_enabled = true
		rmat.emission = Color(0.4, 0.7, 0.95) * 0.4
		ring.material_override = rmat
		ring.position = Vector3(0.0, 0.015, 0.0)
		holder.add_child(ring)
	var reeds: int = 3 + int(round(moisture * 5.0))
	for i in range(reeds):
		var reed := MeshInstance3D.new()
		reed.name = "Reed_%d" % i
		var rc := CylinderMesh.new()
		rc.top_radius = 0.012
		rc.bottom_radius = 0.02
		var rh: float = rng.randf_range(0.35, 0.7)
		rc.height = rh
		reed.mesh = rc
		var remat := StandardMaterial3D.new()
		remat.albedo_color = Color(0.3, 0.5, 0.42)
		reed.material_override = remat
		var a: float = rng.randf_range(0.0, TAU)
		# gen 1: the reeds stand on the SHORE, past the water's edge, their feet on the shelf
		var rr: float = r * rng.randf_range(0.95, 1.15)
		var lx: float = cos(a) * rr
		var lz: float = sin(a) * rr
		reed.position = Vector3(lx, _h_at(c.x + lx, c.z + lz) - c.y + rh * 0.5, lz)
		reed.rotation = Vector3(rng.randf_range(-0.12, 0.12), 0.0, rng.randf_range(-0.12, 0.12))
		holder.add_child(reed)


func _minerals() -> void:
	for key in _cells.keys():
		if String(_cells[key]["kingdom"]) != "mineral":
			continue
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([seed, "crystal", key.x, key.y])
		var holder := Node3D.new()
		holder.name = "Crystal_%d_%d" % [key.x, key.y]
		var p: Vector3 = _cell_world(key.x, key.y)
		p.x += rng.randf_range(-0.25, 0.25)
		p.z += rng.randf_range(-0.25, 0.25)
		p.y = _h_at(p.x, p.z)
		holder.position = p
		holder.rotation.y = rng.randf_range(0.0, TAU)
		_patch.add_child(holder)
		var scale: float = (0.9 + 0.5 * relief) * 1.4
		var shards: int = rng.randi_range(6, 9)
		for _i in range(shards):
			var mi := MeshInstance3D.new()
			var pm := PrismMesh.new()
			var hgt: float = rng.randf_range(0.24, 0.62) * scale
			pm.size = Vector3(0.11 * scale, hgt, 0.11 * scale)
			mi.mesh = pm
			var tint: float = rng.randf_range(-0.04, 0.14)
			var col := Color(0.58 + tint, 0.66 + tint, 0.86 + tint * 0.4)
			var mat := StandardMaterial3D.new()
			mat.albedo_color = col
			mat.metallic = 0.4
			mat.roughness = 0.22
			mat.emission_enabled = true
			mat.emission = col * 0.5
			mi.material_override = mat
			var off := Vector2(rng.randf_range(-0.17, 0.17), rng.randf_range(-0.17, 0.17)) * scale
			mi.position = Vector3(off.x, hgt * 0.5, off.y)
			mi.rotation = Vector3(rng.randf_range(-0.42, 0.42), rng.randf_range(0.0, TAU), rng.randf_range(-0.42, 0.42))
			holder.add_child(mi)


## The living kingdoms go through the old biome's dispatcher, one deposit per cell, each
## carrying its exact surface position — the same road a painted map cell takes.
func _dispatch() -> void:
	_dispatcher = Dispatcher.new()
	_dispatcher.name = "Dispatcher"
	_patch.add_child(_dispatcher)
	var ctx := {
		"biome_paint": [],
		"stage_order": 999,
		"parent": _patch,
		"grid_center": Vector3.ZERO,
		"grid_dims": Vector3i(size, 1, size),
		"cube_size": 1.0,
	}
	var ids := {"tree": K_TREE, "creature": K_CREATURE, "flower": K_FLOWER, "fungus": K_FUNGUS}
	var keys: Array = _cells.keys()
	keys.sort_custom(func(a, b): return (a.y * size + a.x) < (b.y * size + b.x))
	for key in keys:
		var c: Dictionary = _cells[key]
		var kname := String(c["kingdom"])
		if not ids.has(kname):
			continue
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([seed, "cell", key.x, key.y])
		var wp: Vector3 = _cell_world(key.x, key.y)
		wp.x += rng.randf_range(-0.3, 0.3)
		wp.z += rng.randf_range(-0.3, 0.3)
		wp.y = _h_at(wp.x, wp.z)
		# the dispatcher's builders place by GLOBAL position (a painted map cell's world_pos
		# is global), so the surface point goes out in the patch's global frame
		var deposit := {"x": key.x, "z": key.y, "kingdom": int(ids[kname]),
			"strength": float(int(c["inten"])) / 5.0, "sterile": false,
			"raw": "%s%d" % [kname.substr(0, 1), int(c["inten"])], "world_pos": _patch.global_position + wp,
			"density": 0.8 + 0.2 * moisture}
		if String(c["algo"]) != "":
			deposit["algo"] = String(c["algo"])
		_dispatcher.spawn_cell(deposit, 999, ctx, _patch)


## Cover by zone — the old ring's small covers (its "tree" type is a 2.5 m column and its
## "bush" a 0.7 m ball; neither is cover). Reeds at the water's rim, ferns and toadstools in
## the wet ground near the fungus, blooms in the meadow, grass by moisture everywhere.
func _cover() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, "cover"])
	var want: int = clampi(int(round(float(size * size) * (1.2 + 2.6 * wildness) * (0.5 + 0.6 * moisture))), 40, 480)
	var by_type: Dictionary = {}
	var placed := 0
	var tries := 0
	while placed < want and tries < want * 4:
		tries += 1
		var wx: float = rng.randf_range(-float(size) * 0.5 + 0.2, float(size) * 0.5 - 0.2)
		var wz: float = rng.randf_range(-float(size) * 0.5 + 0.2, float(size) * 0.5 - 0.2)
		var cx: int = clampi(int(floor(wx + float(size) * 0.5)), 0, size - 1)
		var cz: int = clampi(int(floor(wz + float(size) * 0.5)), 0, size - 1)
		var key := Vector2i(cx, cz)
		if _water.has(key):
			continue
		var m: float = _moist[cz * size + cx]
		if rng.randf() > 0.15 + 0.85 * m:
			continue
		var d: float = _water_dist(cx, cz)
		var near_fungus: bool = _cells.has(key) and String(_cells[key]["kingdom"]) == "fungus"
		var t := "grass"
		var r: float = rng.randf()
		if d < 1.6 and r < 0.45:
			t = "reed"
		elif (near_fungus or m > 0.62) and r < 0.35:
			t = "fern" if r < 0.2 else "mushroom"
		elif m > 0.45 and r < 0.55:
			t = "flower"
		if not by_type.has(t):
			by_type[t] = []
		var sc: float = 0.6 + 0.5 * m
		var xf := Transform3D(Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(Vector3(sc, sc, sc)), Vector3(wx, _h_at(wx, wz), wz))
		(by_type[t] as Array).append(xf)
		placed += 1
	for t in by_type.keys():
		var xfs: Array = by_type[t]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = Cover.mesh_for(String(t))
		mm.instance_count = xfs.size()
		for i in range(xfs.size()):
			mm.set_instance_transform(i, xfs[i])
			mm.set_instance_color(i, Cover.color_for(String(t), rng))
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Cover_%s" % String(t)
		mmi.multimesh = mm
		mmi.material_override = Cover.foliage_material()
		_patch.add_child(mmi)
	_counts["cover"] = placed


# ── the record ────────────────────────────────────────────────────────────────
func get_state() -> Dictionary:
	var kinds := {}
	for key in _cells.keys():
		var k := String(_cells[key]["kingdom"])
		kinds[k] = int(kinds.get(k, 0)) + 1
	var lo := 9.0
	var hi := -9.0
	for i in range(size * size):
		lo = minf(lo, _field[i] * _max_h)
		hi = maxf(hi, _field[i] * _max_h)
	return {"generation": GENERATION, "label": label(),
		"dna": {"seed": seed, "size": size, "moisture": moisture, "relief": relief, "wildness": wildness},
		"cells": kinds, "counts": _counts.duplicate(), "trees": _trees.size(),
		"kingdoms_present": _present(), "height_range": [lo, hi], "water_level": _water_level(),
		"organisms": _patch.get_child_count() if _patch != null else 0, "build_ms": _build_ms,
		"changelog": CHANGELOG}


func _present() -> Array:
	var out: Array = []
	if _counts["water"] > 0:
		out.append("water")
	if _counts["mineral"] > 0:
		out.append("mineral")
	if _counts["fungus"] + _counts["fungus_path"] > 0:
		out.append("fungus")
	if _counts["tree"] + _counts["flower"] > 0:
		out.append("flora")
	if _counts["creature"] > 0:
		out.append("fauna")
	if _counts["cover"] > 0:
		out.append("cover")
	return out


func _write_state() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(STATE_DIR))
	var f := FileAccess.open("%s/%s.json" % [STATE_DIR, label()], FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(get_state(), " "))
	f.close()
