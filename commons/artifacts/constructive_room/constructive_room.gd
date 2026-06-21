extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ConstructiveRoom

## @identity
## name: Constructive Room — Only What You Can Construct Exists
## concept: Brouwer & intuitionism
## tier: large
## lineage: L.E.J. Brouwer's intuitionism (1907 onward). Mathematics is mental
##   construction; a thing exists only once it is built. The law of the excluded
##   middle fails — "P or not-P" is not free, because neither may be constructed yet.
## essence: a room whose floor exists only where it has been laid. A path of solid tiles
##   builds itself forward, tile by tile, ahead of an unseen walker. Beyond the built
##   edge there is no floor and no void — an undetermined haze, neither true nor false
##   until a tile is placed.
## truth: existence is construction. The unbuilt is not "false floor" — it is undecided.
##   You cannot stand on a proof you have not yet made.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var accent: Color = Color(0.40, 0.92, 0.62)   # the construction edge glows
@export var room_size: float = 7.0
@export var build_period: float = 0.6                  # seconds per tile laid
@export var path_length: int = 18

var _t: float = 0.0
var _tiles: Array = []          # MeshInstance3D solid tiles (the built floor)
var _tile_mats: Array = []      # their materials
var _haze: Array = []           # MeshInstance3D fog cells over the unbuilt region
var _haze_mats: Array = []
var _path_cells: Array = []     # Vector3 cell centres along the constructed path
var _built_count: int = 0
var _walker: MeshInstance3D
var _edge_lamp: MeshInstance3D


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("room_size"):
		room_size = float(config["room_size"])
	if config.has("build_period"):
		build_period = float(config["build_period"])
	if config.has("path_length"):
		path_length = int(config["path_length"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_tiles = []
	_tile_mats = []
	_haze = []
	_haze_mats = []
	_path_cells = []
	_built_count = 0

	var purple_mat: StandardMaterial3D = _glow_mat(wire_purple, 0.45)
	var hs: float = room_size * 0.5
	var cell: float = 0.7

	# --- thin reference frame only (NO full floor — the floor is the point) ---
	# a faint chalk square marking where the room *could* be
	add_child(_box(Vector3(0.0, -0.06, hs - 0.05), Vector3(room_size, 0.02, 0.04), purple_mat))
	add_child(_box(Vector3(0.0, -0.06, -hs + 0.05), Vector3(room_size, 0.02, 0.04), purple_mat))
	add_child(_box(Vector3(hs - 0.05, -0.06, 0.0), Vector3(0.04, 0.02, room_size), purple_mat))
	add_child(_box(Vector3(-hs + 0.05, -0.06, 0.0), Vector3(0.04, 0.02, room_size), purple_mat))

	# --- plan a meandering path from one edge across the room ---
	var x: float = -hs + cell * 0.7
	var z: float = 0.0
	var n: int = path_length
	var i: int = 0
	while i < n:
		_path_cells.append(Vector3(x, 0.0, z))
		x += cell
		# gentle meander in z
		z += sin(float(i) * 0.9) * cell * 0.45
		z = clampf(z, -hs + cell, hs - cell)
		i += 1

	# --- build the tile + haze pair for every path cell (start invisible/hazed) ---
	var j: int = 0
	while j < _path_cells.size():
		var p: Vector3 = _path_cells[j]
		# solid tile (hidden until constructed)
		var tmat: StandardMaterial3D = _glow_mat(cool_white, 0.5)
		var tile: MeshInstance3D = _box(p + Vector3(0.0, -0.04, 0.0), Vector3(cell * 0.92, 0.08, cell * 0.92), tmat)
		tile.visible = false
		add_child(tile)
		_tiles.append(tile)
		_tile_mats.append(tmat)
		# undetermined haze over the same cell (visible until the tile is laid)
		var hmat: StandardMaterial3D = _glass_mat(wire_purple, 0.16)
		var fog: MeshInstance3D = _box(p + Vector3(0.0, 0.35, 0.0), Vector3(cell * 0.96, 0.8, cell * 0.96), hmat)
		add_child(fog)
		_haze.append(fog)
		_haze_mats.append(hmat)
		j += 1

	# --- the construction-edge lamp (rides at the building front) ---
	_edge_lamp = _sphere(Vector3(-hs, 0.5, 0.0), 0.12, _glow_mat(accent, 1.8))
	add_child(_edge_lamp)

	# --- the unseen walker (a faint marker just behind the edge) ---
	_walker = _box(Vector3(-hs, 0.45, 0.0), Vector3(0.22, 0.5, 0.22), _glass_mat(accent, 0.30))
	add_child(_walker)

	# --- overhead title ---
	add_child(_billboard_label("ONLY WHAT YOU CAN CONSTRUCT", Vector3(0.0, 3.6, 0.0), 32, cool_white))
	add_child(_billboard_label("EXISTS", Vector3(0.0, 3.3, 0.0), 32, accent))
	add_child(_billboard_label("Brouwer — intuitionism", Vector3(0.0, 3.04, 0.0), 16, wire_purple))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	# how many tiles should be built by now (loops: build across, then reset)
	var total: int = _tiles.size()
	if total == 0:
		return
	var full_cycle: float = build_period * float(total) + 2.5   # +pause at the end
	var local_t: float = fmod(_t, full_cycle)
	var target_built: int = int(local_t / build_period)
	target_built = clampi(target_built, 0, total)

	# reset on loop wrap
	if target_built < _built_count:
		var r: int = 0
		while r < total:
			(_tiles[r] as MeshInstance3D).visible = false
			(_haze[r] as MeshInstance3D).visible = true
			r += 1
		_built_count = 0

	# lay any newly-constructed tiles
	while _built_count < target_built:
		var idx: int = _built_count
		(_tiles[idx] as MeshInstance3D).visible = true
		(_haze[idx] as MeshInstance3D).visible = false
		_built_count += 1

	# pulse the haze (undetermined shimmer) — neither floor nor void
	var shimmer: float = 0.10 + 0.06 * (0.5 + 0.5 * sin(_t * 1.8))
	var h: int = 0
	while h < _haze_mats.size():
		if (_haze[h] as MeshInstance3D).visible:
			var m: StandardMaterial3D = _haze_mats[h]
			m.albedo_color.a = shimmer
		h += 1

	# edge lamp + walker ride the construction front
	var front_idx: int = clampi(_built_count - 1, 0, total - 1)
	if _path_cells.size() > 0 and is_instance_valid(_edge_lamp):
		var front: Vector3 = _path_cells[front_idx]
		# look ahead to the next (undetermined) cell for the lamp
		var ahead_idx: int = clampi(_built_count, 0, total - 1)
		var ahead: Vector3 = _path_cells[ahead_idx]
		_edge_lamp.position = ahead + Vector3(0.0, 0.45 + 0.05 * sin(_t * 4.0), 0.0)
		var lm: StandardMaterial3D = _edge_lamp.material_override as StandardMaterial3D
		if lm != null:
			lm.emission_energy_multiplier = (1.8 if emissive else 0.6) * (0.7 + 0.3 * sin(_t * 5.0))
		if is_instance_valid(_walker):
			_walker.position = front + Vector3(0.0, 0.25, 0.0)
