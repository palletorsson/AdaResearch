extends Node3D
class_name PatternTunnel

## Pattern Tunnel — a subway-tiled walkway that paints itself.
##
## You stand at the mouth of a square tube — floor, two walls, ceiling, all gridded
## in white tiles. A reveal front travels down the tunnel and the tiles fill in, step
## by step: floor, then the walls, then the ceiling of each ring, the pattern crawling
## away from you down the corridor. The pattern is a WallpaperGroups tiling of a source
## motif (the same engine as pattern_studio_plate) — change the group / motif / palette
## and the whole tube re-skins; touching a control speeds the fill up (boost()).
##
## Phase 1 here = the tube + the self-painting reveal. The machine interface (the large
## pattern-maker console at the mouth) is built by pattern_tunnel_machine on top of this.

const WallpaperGroups = preload("res://commons/primitives/arrays/wallpaper_groups.gd")

@export var tunnel_length: int = 14      # rings down -Z
@export var ring_floor: int = 4          # tiles across floor / ceiling
@export var ring_wall: int = 4           # tiles up each wall
@export var tile_size: float = 0.62
@export var group_index: int = 10        # P4M (index into the 17 groups)
@export var motif_index: int = 7         # Hex Rosette
@export_range(0.0, 1.0, 0.01) var reveal: float = 1.0   # static reveal for captures
@export var fill_speed: float = 2.2      # rings per second at runtime
@export var auto_run: bool = true
@export var period_index: int = 1        # Imperial palette

# ── palette + motifs (mirrors pattern_studio_plate's ITALY_PACK) ─────────────
var palette: Array[Color] = [
	Color(0.95, 0.92, 0.85), Color(0.80, 0.20, 0.15), Color(0.15, 0.25, 0.50),
	Color(0.70, 0.55, 0.20), Color(0.20, 0.40, 0.25), Color(0.40, 0.20, 0.15),
	Color(0.10, 0.10, 0.12), Color(0.60, 0.30, 0.50), Color(0.50, 0.70, 0.80),
]
const PERIODS: Array[Dictionary] = [
	{"name": "Republican", "colors": ["#141418","#EBE6D9","#B8603C","#8B7355","#4A3728","#C4B99A","#6B4423","#2B1810"]},
	{"name": "Imperial", "colors": ["#141418","#EBE6D9","#B32719","#C09933","#267366","#D4A0A0","#5C3A1E","#8C7B6B"]},
	{"name": "Cosmatesque", "colors": ["#E8E0D4","#264D26","#8C1A26","#CCA329","#1A1A2E","#6B3A3A","#3D5C3D","#B8A88A"]},
	{"name": "Renaissance", "colors": ["#1F3380","#D9B333","#2D6633","#F0EAD6","#4D2666","#CC6644","#1A4D4D","#8C7B6B"]},
	{"name": "Baroque", "colors": ["#1A3399","#CCA329","#1A4D26","#CC6633","#F5F0E1","#0D0D0D","#8C1A3A","#5C4A32"]},
]
var MOTIFS: Array[Dictionary] = [
	{"name": "Checkerboard", "group": 10, "size": 2, "data": [[0,1],[1,0]]},
	{"name": "Greek Key", "group": 4, "size": 8, "data": [
		[1,1,1,1,1,1,1,0],[0,0,0,0,0,0,1,0],[0,1,1,1,1,0,1,0],[0,1,0,0,1,0,1,0],
		[0,1,0,1,1,0,1,0],[0,1,0,0,0,0,1,0],[0,1,1,1,1,1,1,0],[0,0,0,0,0,0,0,0]]},
	{"name": "Hex Rosette", "group": 16, "size": 8, "data": [
		[0,0,0,1,1,0,0,0],[0,0,1,2,2,1,0,0],[0,1,2,1,1,2,1,0],[1,2,1,0,0,1,2,1],
		[1,2,1,0,0,1,2,1],[0,1,2,1,1,2,1,0],[0,0,1,2,2,1,0,0],[0,0,0,1,1,0,0,0]]},
	{"name": "Eight-Point Star", "group": 10, "size": 8, "data": [
		[0,0,0,1,1,0,0,0],[0,0,1,1,1,1,0,0],[0,1,1,0,0,1,1,0],[1,1,0,0,0,0,1,1],
		[1,1,0,0,0,0,1,1],[0,1,1,0,0,1,1,0],[0,0,1,1,1,1,0,0],[0,0,0,1,1,0,0,0]]},
]

# motif_index here indexes MOTIFS; group_index can be overridden independently.
var _motif: Array = []
var _gs: int = 8
var _perimeter: int = 0
var _tiles: Array = []        # each: {mi, seg, threshold, color_idx, revealed}
var _mat_cache: Dictionary = {}
var _white_mat: StandardMaterial3D
var _reveal_front: float = 0.0
var _boost: float = 0.0
var _built := false


func _ready() -> void:
	if not _built:
		_build()


func _build() -> void:
	_built = true
	_apply_period(period_index)
	_load_motif(motif_index)
	_white_mat = _flat(Color(0.97, 0.97, 0.99), 0.82)
	_perimeter = 2 * ring_floor + 2 * ring_wall
	for c in get_children():
		c.queue_free()
	_build_shell()
	_build_tunnel()
	_add_capture_camera()
	_reveal_front = reveal * float(tunnel_length + 2)
	_refresh_reveal()
	set_process(auto_run)


func _process(delta: float) -> void:
	if not auto_run:
		return
	var speed: float = fill_speed + _boost
	_boost = maxf(0.0, _boost - delta * 2.0)            # boost decays
	_reveal_front += speed * delta
	var loop_len: float = float(tunnel_length + 2) + 2.0
	if _reveal_front > loop_len:                        # loop the reveal so it keeps painting
		_reveal_front = 0.0
		for t in _tiles:
			t["revealed"] = false
			(t["mi"] as MeshInstance3D).material_override = _white_mat
	_refresh_reveal()


## Speed the fill up — called by the machine when a control is touched.
func boost(amount: float = 6.0) -> void:
	_boost = minf(_boost + amount, 16.0)


# ── geometry ─────────────────────────────────────────────────────────────────

func _build_shell() -> void:
	var w: float = ring_floor * tile_size
	var h: float = ring_wall * tile_size
	var half: float = w * 0.5
	var L: float = tunnel_length * tile_size
	var zc: float = -L * 0.5
	var dark := _flat(Color(0.08, 0.08, 0.10), 0.95)
	add_child(_slab(Vector3(0.0, -0.02, zc), Vector3(w + 0.06, 0.04, L), dark))            # floor
	add_child(_slab(Vector3(0.0, h + 0.02, zc), Vector3(w + 0.06, 0.04, L), dark))         # ceiling
	add_child(_slab(Vector3(half + 0.02, h * 0.5, zc), Vector3(0.04, h + 0.08, L), dark))  # right wall
	add_child(_slab(Vector3(-half - 0.02, h * 0.5, zc), Vector3(0.04, h + 0.08, L), dark)) # left wall


func _slab(pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.position = pos
	mi.material_override = mat
	return mi


func _add_capture_camera() -> void:
	var h: float = ring_wall * tile_size
	var cam := Camera3D.new()
	cam.name = "CaptureCamera"
	cam.position = Vector3(0.0, h * 0.52, 1.0)
	cam.rotation_degrees = Vector3(-7.0, 0.0, 0.0)
	cam.fov = 72.0
	add_child(cam)


func _build_tunnel() -> void:
	_tiles.clear()
	var w: float = ring_floor * tile_size
	var h: float = ring_wall * tile_size
	var half: float = w * 0.5
	for seg in range(tunnel_length):
		var z: float = -(float(seg) + 0.5) * tile_size
		var v: int = 0
		# floor (facing up)
		for c in range(ring_floor):
			var x: float = -half + (float(c) + 0.5) * tile_size
			_add_tile(Vector3(x, 0.0, z), Vector3(-90.0, 0.0, 0.0), seg, v, 0.0); v += 1
		# right wall (facing -X), bottom to top
		for k in range(ring_wall):
			var y: float = (float(k) + 0.5) * tile_size
			_add_tile(Vector3(half, y, z), Vector3(0.0, -90.0, 0.0), seg, v, 0.34); v += 1
		# ceiling (facing down), far to near so the pattern wraps
		for c2 in range(ring_floor):
			var xc: float = half - (float(c2) + 0.5) * tile_size
			_add_tile(Vector3(xc, h, z), Vector3(90.0, 0.0, 0.0), seg, v, 0.66); v += 1
		# left wall (facing +X), top to bottom
		for k2 in range(ring_wall):
			var yl: float = h - (float(k2) + 0.5) * tile_size
			_add_tile(Vector3(-half, yl, z), Vector3(0.0, 90.0, 0.0), seg, v, 0.34); v += 1


func _add_tile(pos: Vector3, rot_deg: Vector3, seg: int, v: int, surf_frac: float) -> void:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(tile_size * 0.92, tile_size * 0.92)
	mi.mesh = q
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.material_override = _white_mat
	add_child(mi)
	var ci: int = _pattern_index(seg, v)
	_tiles.append({"mi": mi, "seg": seg, "v": v, "threshold": float(seg) + surf_frac, "color_idx": ci, "revealed": false})


func _pattern_index(seg: int, v: int) -> int:
	var idx: int = WallpaperGroups.get_symmetric_color(seg, v, _gs, _motif, group_index)
	return clampi(idx, 0, palette.size() - 1)


func _refresh_reveal() -> void:
	for t in _tiles:
		if t["revealed"]:
			continue
		if _reveal_front >= t["threshold"]:
			t["revealed"] = true
			(t["mi"] as MeshInstance3D).material_override = _pattern_mat(t["color_idx"])


# ── pattern source ───────────────────────────────────────────────────────────

func _load_motif(idx: int) -> void:
	if idx < 0 or idx >= MOTIFS.size():
		idx = 0
	motif_index = idx
	var m: Dictionary = MOTIFS[idx]
	_motif = m["data"]
	_gs = int(m["size"])
	if group_index < 0:
		group_index = int(m["group"])


func _apply_period(idx: int) -> void:
	if idx < 0 or idx >= PERIODS.size():
		return
	period_index = idx
	var cols: Array = PERIODS[idx]["colors"]
	for i in range(palette.size()):
		if i < cols.size():
			palette[i] = Color.html(String(cols[i]))


## Re-skin the whole tube with a new group / motif / palette (machine calls this).
func reskin(new_group: int = -1, new_motif: int = -1, new_period: int = -1) -> void:
	if new_period >= 0:
		_apply_period(new_period)
		_mat_cache.clear()
	if new_motif >= 0:
		_load_motif(new_motif)
	if new_group >= 0:
		group_index = new_group
	for t in _tiles:
		t["color_idx"] = _pattern_index(t["seg"], t["v"])
		if t["revealed"]:
			(t["mi"] as MeshInstance3D).material_override = _pattern_mat(t["color_idx"])
	boost()


# ── materials ────────────────────────────────────────────────────────────────

func _flat(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.0
	return m


func _pattern_mat(ci: int) -> StandardMaterial3D:
	if _mat_cache.has(ci):
		return _mat_cache[ci]
	var col: Color = palette[ci] if ci < palette.size() else Color.WHITE
	var m := _flat(col, 0.7)
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = 0.12
	_mat_cache[ci] = m
	return m


# ── map / config integration ─────────────────────────────────────────────────

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("tunnel_length"): tunnel_length = int(config_data["tunnel_length"])
	if config_data.has("group_index"): group_index = int(config_data["group_index"])
	if config_data.has("motif_index"): motif_index = int(config_data["motif_index"])
	if config_data.has("period_index"): period_index = int(config_data["period_index"])
	if config_data.has("reveal"): reveal = clampf(float(config_data["reveal"]), 0.0, 1.0)
	if config_data.has("fill_speed"): fill_speed = float(config_data["fill_speed"])
	if config_data.has("auto_run"): auto_run = bool(config_data["auto_run"])
	_built = false
	_build()
