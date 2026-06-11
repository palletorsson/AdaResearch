extends Node3D
class_name PatternTunnel

## Pattern Tunnel — a subway-tiled walkway that paints itself.
##
## You stand at the mouth of a square tube — floor, two walls, ceiling. Each surface is a
## single large quad driven by pattern_tunnel.gdshader, which draws the small subway tiles
## (grout grid) coloured by a WallpaperGroups tiling of a source motif. A reveal front
## travels down the tunnel (world -Z): floor fills first, then the walls, then the ceiling,
## the pattern crawling away from you. Change the group / motif / palette and the whole
## tube re-skins instantly (the shader just samples a new swatch texture); touching a
## control speeds the fill up (boost()).
##
## Shader surfaces replace the old per-tile meshes, so the corridor can be large and the
## tiles small without spawning thousands of nodes.

const WallpaperGroups = preload("res://commons/primitives/arrays/wallpaper_groups.gd")
const TUNNEL_SHADER = preload("res://commons/artifacts/pattern_tunnel/pattern_tunnel.gdshader")

@export var tunnel_length: float = 14.0      # metres down -Z
@export var corridor_width: float = 3.6      # metres across the floor / ceiling
@export var corridor_height: float = 3.2     # metres up each wall
@export var tile_size: float = 0.34          # subway tile size (small)
@export var group_index: int = 10            # P4M (index into the 17 groups)
@export var motif_index: int = 2             # Hex Rosette
@export_range(0.0, 1.3, 0.01) var reveal: float = 1.2   # static reveal for captures
@export var fill_speed: float = 2.2          # metres/second the front travels
@export var auto_run: bool = true
@export var period_index: int = 1            # Imperial palette

const SWATCH := 32     # wallpaper swatch resolution (cells); the shader tiles it

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

var _motif: Array = []
var _gs: int = 8
var _mats: Array[ShaderMaterial] = []
var _pattern_tex: ImageTexture
var _reveal: float = 0.0
var _boost: float = 0.0
var _built := false


func _ready() -> void:
	if not _built:
		_build()


func _build() -> void:
	_built = true
	_apply_period(period_index)
	_load_motif(motif_index)
	for c in get_children():
		c.queue_free()
	_mats.clear()
	_pattern_tex = _gen_tex()
	_build_surfaces()
	_add_capture_camera()
	_reveal = reveal
	_apply_reveal()
	set_process(auto_run)


func _process(delta: float) -> void:
	if not auto_run:
		return
	var speed: float = fill_speed + _boost
	_boost = maxf(0.0, _boost - delta * 2.0)              # boost decays
	_reveal += speed / maxf(tunnel_length, 0.1) * delta
	if _reveal > 1.35:                                    # loop the reveal so it keeps painting
		_reveal = 0.0
	_apply_reveal()


## Speed the fill up — called by the machine when a control is touched.
func boost(amount: float = 6.0) -> void:
	_boost = minf(_boost + amount, 16.0)


# ── geometry ─────────────────────────────────────────────────────────────────

func _build_surfaces() -> void:
	var w: float = corridor_width
	var h: float = corridor_height
	var l: float = tunnel_length
	var half: float = w * 0.5
	var zc: float = -l * 0.5
	# floor, ceiling, right wall, left wall — surf_offset staggers the fill
	_surface(Vector3(0.0, 0.0, zc), w, l, Vector3(-90.0, 0.0, 0.0), 0.0)     # floor
	_surface(Vector3(0.0, h, zc), w, l, Vector3(90.0, 0.0, 0.0), 0.2)        # ceiling
	_surface(Vector3(half, h * 0.5, zc), l, h, Vector3(0.0, -90.0, 0.0), 0.1)   # right wall
	_surface(Vector3(-half, h * 0.5, zc), l, h, Vector3(0.0, 90.0, 0.0), 0.1)   # left wall


func _surface(center: Vector3, qw: float, qh: float, rot_deg: Vector3, surf_offset: float) -> void:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(qw, qh)
	mi.mesh = q
	mi.position = center
	mi.rotation_degrees = rot_deg
	var mat := ShaderMaterial.new()
	mat.shader = TUNNEL_SHADER
	var tile_reps := Vector2(qw / tile_size, qh / tile_size)
	mat.set_shader_parameter("pattern_tex", _pattern_tex)
	mat.set_shader_parameter("tile_reps", tile_reps)
	mat.set_shader_parameter("pattern_reps", tile_reps / float(SWATCH))
	mat.set_shader_parameter("tunnel_len", tunnel_length)
	mat.set_shader_parameter("surf_offset", surf_offset)
	mat.set_shader_parameter("reveal", _reveal)
	mat.set_shader_parameter("grout", 0.07)
	mi.material_override = mat
	add_child(mi)
	_mats.append(mat)


func _apply_reveal() -> void:
	for mat in _mats:
		mat.set_shader_parameter("reveal", _reveal)


func _add_capture_camera() -> void:
	var cam := Camera3D.new()
	cam.name = "CaptureCamera"
	cam.position = Vector3(0.0, corridor_height * 0.5, 1.4)
	cam.rotation_degrees = Vector3(-6.0, 0.0, 0.0)
	cam.fov = 74.0
	add_child(cam)


# ── pattern source ───────────────────────────────────────────────────────────

func _gen_tex() -> ImageTexture:
	var img := Image.create(SWATCH, SWATCH, false, Image.FORMAT_RGBA8)
	for py in range(SWATCH):
		for px in range(SWATCH):
			var ci: int = WallpaperGroups.get_symmetric_color(px, py, _gs, _motif, group_index)
			img.set_pixel(px, py, palette[clampi(ci, 0, palette.size() - 1)])
	return ImageTexture.create_from_image(img)


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
	if new_motif >= 0:
		_load_motif(new_motif)
	if new_group >= 0:
		group_index = new_group
	_pattern_tex = _gen_tex()
	for mat in _mats:
		mat.set_shader_parameter("pattern_tex", _pattern_tex)
	boost()


# ── map / config integration ─────────────────────────────────────────────────

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("tunnel_length"): tunnel_length = float(config_data["tunnel_length"])
	if config_data.has("corridor_width"): corridor_width = float(config_data["corridor_width"])
	if config_data.has("corridor_height"): corridor_height = float(config_data["corridor_height"])
	if config_data.has("tile_size"): tile_size = float(config_data["tile_size"])
	if config_data.has("group_index"): group_index = int(config_data["group_index"])
	if config_data.has("motif_index"): motif_index = int(config_data["motif_index"])
	if config_data.has("period_index"): period_index = int(config_data["period_index"])
	if config_data.has("reveal"): reveal = clampf(float(config_data["reveal"]), 0.0, 1.3)
	if config_data.has("fill_speed"): fill_speed = float(config_data["fill_speed"])
	if config_data.has("auto_run"): auto_run = bool(config_data["auto_run"])
	_built = false
	_build()
