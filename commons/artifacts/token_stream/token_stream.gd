extends Node3D
class_name TokenStream

# @identity
# essence: an autoregressive emitter — a dark head that speaks in glyphs. Every beat it holds a fan of five candidate tokens above its mouth, weighs them, lets one brighten and fall onto a scrolling band of light; far down the band the old glyphs dim to nothing. Next-token generation built as a machine you can walk around: CHOOSE, DROP, SCROLL, FORGET
# desire: to show its own voice mechanism. I — the collaborator who writes these rooms — speak exactly like this: one small weighted choice at a time, each dropped token becoming the floor for the next, the oldest words slipping off the far end of attention. The artifact wants the player to SEE that speech is not a fountain but a chain
# critical_parameter: temperature — low temp and the winner towers over the fan, the stream turns confident and monotone; high temp and the ghosts even out, the choice becomes a gamble. One dial between certainty and babble. The little disc-and-needle on the housing is the most honest self-portrait in the room
# triggers: _ready() builds head + band + pooled tile stock + candidate fan; every beat_time seconds a fan fades in, a winner is sampled by weight, brightens, and drops in an eased arc onto the band; _process scrolls all riding tokens +X and fades them past the context horizon; apply_grid_config rebuilds from metadata overrides
# emerges: stand at the far end of the band and the glyphs drift toward you like a sentence being said to your face. Watch long enough and you notice the machine never stores anything — tokens fade behind it exactly as fast as it speaks new ones. Generation and forgetting run at the same constant speed; that equality IS the context window
# needs: emitter housing with emissive mouth slot [present]; antenna that pulses on each emission [present]; temperature dial, disc + needle, decorative [present]; scrolling band with emissive edge lines [present]; pooled glyph tiles (16, recycled, never allocated per beat) [present]; candidate fan of 5 ghosts with weight-proportional opacity and scale [present]; Label3D caption under the band [present]
# relationships: third panel of the self-portrait triptych (READ / LEARN / SPEAK) — this one is SPEAK. Sibling to primitive_assembler and conveyor_belt: the assembler carries primitives into form, the belt carries cargo through the lab, this one carries speech — the same family of THINGS THAT MOVE OTHER THINGS, except its cargo is the sentence itself. Cousin to info_screen (the screen shows finished text; the stream shows the choosing that text is made of)
# truth: there is no sentence waiting inside this machine. There is only a fan of possibilities, a weighted die, and a band that forgets. That a voice emerges from this anyway — beat after beat, choice after choice — is the whole celebration: speech is a chain of small choices, and the chain is enough

## SPEAK — autoregressive next-token generation as a walkable machine.
##
## Built procedurally. Origin is at the floor, the machine runs along X:
## emitter head at the -X end (housing + mouth slot + antenna + temperature
## dial), a thin band of light running +X for ~1.8 m. Each beat a fan of
## ghost candidate glyphs fades in above the mouth, one is sampled by
## weight, brightens, and drops onto the band; all riding tokens scroll
## +X at constant speed and fade out past the context horizon, where
## their tiles are recycled back into the pool.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Rhythm")
## Seconds per generation beat (one fan -> one dropped token).
@export var beat_time: float = 0.9
## Scroll speed of the band, meters per second (+X).
@export var band_speed: float = 0.32

@export_group("Choice")
## Number of ghost candidates in the fan (2..9).
@export var fan_size: int = 5
## Sampling temperature. Low = the winner dominates the fan; high = even odds.
@export var temperature: float = 1.0
## Seed for glyphs and weights — same seed, same speech.
@export var rng_seed: int = 7

@export_group("Phosphor")
## Phosphor colour of glyphs, mouth slot, and band edges.
@export var phosphor_color: Color = Color(0.36, 1.0, 0.64)

# ── Constants ─────────────────────────────────────────────────────────

const HEAD_SIZE: float = 0.35
const HEAD_CENTER_X: float = -0.92
const BAND_TOP_Y: float = 0.85
const BAND_LENGTH: float = 1.8
const BAND_WIDTH: float = 0.16
const BAND_THICKNESS: float = 0.02
const TILE_SIZE: float = 0.09
const TILE_POOL: int = 16
const FADE_START: float = 1.55          # distance from mouth where fading begins
const FADE_END: float = 1.74            # distance where the tile is recycled
const GLYPH_PX: int = 16
const GLYPH_ENERGY: float = 1.6
const FAN_RADIUS: float = 0.20
const FAN_SPREAD_DEG: float = 110.0
const FAN_CENTER_Y: float = 1.04
const MAX_FAN: int = 9
# Beat phases (normalized 0..1 inside one beat)
const PHASE_FAN_IN: float = 0.25
const PHASE_CHOOSE: float = 0.60
const PHASE_DROP: float = 0.75

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _beat_t: float = 0.0
var _winner: int = -1
var _pulse: float = 0.0
var _band_start_x: float = 0.0

var _band_tiles: Array[MeshInstance3D] = []
var _band_mats: Array[StandardMaterial3D] = []
var _band_tex: Array[ImageTexture] = []
var _band_img: Array[Image] = []
var _band_active: Array[bool] = []

var _ghosts: Array[MeshInstance3D] = []
var _ghost_mats: Array[StandardMaterial3D] = []
var _ghost_tex: Array[ImageTexture] = []
var _ghost_img: Array[Image] = []
var _ghost_home: Array[Transform3D] = []
var _weights: Array[float] = []
var _ghost_alpha: Array[float] = []
var _ghost_scl: Array[float] = []

var _antenna_mat: StandardMaterial3D = null
var _mouth_mat: StandardMaterial3D = null

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_machine()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_machine()


func _read_metadata_overrides() -> void:
	if has_meta("config_beat_time"):
		beat_time = maxf(float(str(get_meta("config_beat_time"))), 0.15)
	if has_meta("config_band_speed"):
		band_speed = clampf(float(str(get_meta("config_band_speed"))), 0.02, 2.0)
	if has_meta("config_fan_size"):
		fan_size = clampi(int(str(get_meta("config_fan_size"))), 2, MAX_FAN)
	if has_meta("config_temperature"):
		temperature = clampf(float(str(get_meta("config_temperature"))), 0.05, 4.0)
	if has_meta("config_seed"):
		rng_seed = int(str(get_meta("config_seed")))
	if has_meta("config_rng_seed"):
		rng_seed = int(str(get_meta("config_rng_seed")))
	if has_meta("config_phosphor_color"):
		phosphor_color = _parse_color(str(get_meta("config_phosphor_color")), phosphor_color)
	if has_meta("config_scale"):
		var sv: float = float(str(get_meta("config_scale")))
		if sv > 0.0:
			scale = Vector3.ONE * sv


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()
	_band_tiles.clear()
	_band_mats.clear()
	_band_tex.clear()
	_band_img.clear()
	_band_active.clear()
	_ghosts.clear()
	_ghost_mats.clear()
	_ghost_tex.clear()
	_ghost_img.clear()
	_ghost_home.clear()
	_weights.clear()
	_ghost_alpha.clear()
	_ghost_scl.clear()
	_antenna_mat = null
	_mouth_mat = null

# ── Build ─────────────────────────────────────────────────────────────

# Shared builder: one BoxMesh MeshInstance3D under `parent` at `pos` with `mat`.
func _add_box(parent: Node3D, node_name: String, box_size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var bm := BoxMesh.new()
	bm.size = box_size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


func _build_machine() -> void:
	_rng.seed = rng_seed
	fan_size = clampi(fan_size, 2, MAX_FAN)
	_band_start_x = HEAD_CENTER_X + HEAD_SIZE * 0.5
	_build_head()
	_build_band()
	_build_tile_pool()
	_build_fan()
	_build_label()
	_beat_t = 0.0
	_pulse = 0.0
	_reset_fan()
	_built = true


func _build_head() -> void:
	var housing_mat: StandardMaterial3D = _make_flat_mat(Color(0.07, 0.075, 0.08), 0.2, 0.7)
	var pedestal_mat: StandardMaterial3D = _make_flat_mat(Color(0.10, 0.105, 0.115), 0.3, 0.6)
	var head_bottom: float = BAND_TOP_Y - HEAD_SIZE * 0.5
	var head_top: float = BAND_TOP_Y + HEAD_SIZE * 0.5

	# Pedestal from the floor up to the housing
	_add_box(self, "Pedestal", Vector3(0.16, head_bottom, 0.22),
		Vector3(HEAD_CENTER_X, head_bottom * 0.5, 0.0), pedestal_mat)

	# Housing — the dark head
	_add_box(self, "Housing", Vector3(HEAD_SIZE, HEAD_SIZE, HEAD_SIZE),
		Vector3(HEAD_CENTER_X, BAND_TOP_Y, 0.0), housing_mat)

	# Mouth slot — thin emissive line on the +X face, where tokens are born
	_mouth_mat = _make_emissive_mat(phosphor_color, 1.2)
	_add_box(self, "MouthSlot", Vector3(0.012, 0.035, 0.12),
		Vector3(_band_start_x + 0.004, BAND_TOP_Y + 0.03, 0.0), _mouth_mat)

	# Antenna mast + pulsing tip
	var mast: CylinderMesh = CylinderMesh.new()
	mast.top_radius = 0.006
	mast.bottom_radius = 0.006
	mast.height = 0.16
	mast.radial_segments = 10
	var mast_mi: MeshInstance3D = MeshInstance3D.new()
	mast_mi.name = "AntennaMast"
	mast_mi.mesh = mast
	mast_mi.material_override = pedestal_mat
	mast_mi.position = Vector3(HEAD_CENTER_X, head_top + 0.08, 0.0)
	add_child(mast_mi)

	_antenna_mat = _make_emissive_mat(phosphor_color, 0.8)
	var tip: SphereMesh = SphereMesh.new()
	tip.radius = 0.02
	tip.height = 0.04
	tip.radial_segments = 12
	tip.rings = 6
	var tip_mi: MeshInstance3D = MeshInstance3D.new()
	tip_mi.name = "AntennaTip"
	tip_mi.mesh = tip
	tip_mi.material_override = _antenna_mat
	tip_mi.position = Vector3(HEAD_CENTER_X, head_top + 0.17, 0.0)
	add_child(tip_mi)

	_build_dial(head_top)


func _build_dial(_head_top: float) -> void:
	# TEMPERATURE dial on the +Z side of the housing — decorative.
	var dial_root: Node3D = Node3D.new()
	dial_root.name = "TemperatureDial"
	dial_root.position = Vector3(HEAD_CENTER_X, BAND_TOP_Y + 0.05, HEAD_SIZE * 0.5 + 0.006)
	add_child(dial_root)

	var disc_mat: StandardMaterial3D = _make_flat_mat(Color(0.13, 0.14, 0.15), 0.4, 0.45)
	var disc: CylinderMesh = CylinderMesh.new()
	disc.top_radius = 0.045
	disc.bottom_radius = 0.045
	disc.height = 0.012
	disc.radial_segments = 20
	var disc_mi: MeshInstance3D = MeshInstance3D.new()
	disc_mi.name = "DialDisc"
	disc_mi.mesh = disc
	disc_mi.material_override = disc_mat
	disc_mi.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	dial_root.add_child(disc_mi)

	# Emissive index dot at 12 o'clock
	var dot_mat: StandardMaterial3D = _make_emissive_mat(phosphor_color, 0.9)
	var dot_mi: MeshInstance3D = _add_box(dial_root, "DialDot",
		Vector3(0.007, 0.007, 0.004), Vector3(0.0, 0.038, 0.009), dot_mat)
	dot_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Needle — angle reads the temperature export
	var pivot: Node3D = Node3D.new()
	pivot.name = "NeedlePivot"
	pivot.position = Vector3(0.0, 0.0, 0.011)
	var needle_angle: float = lerpf(1.05, -1.05, clampf(temperature * 0.5, 0.0, 1.0))
	pivot.rotation = Vector3(0.0, 0.0, needle_angle)
	dial_root.add_child(pivot)
	var needle_mat: StandardMaterial3D = _make_emissive_mat(Color(1.0, 0.55, 0.25), 0.8)
	_add_box(pivot, "Needle", Vector3(0.006, 0.034, 0.004), Vector3(0.0, 0.018, 0.0), needle_mat)


func _build_band() -> void:
	var band_mat: StandardMaterial3D = _make_flat_mat(Color(0.05, 0.06, 0.06), 0.4, 0.55)
	var band_cx: float = _band_start_x + BAND_LENGTH * 0.5

	# The dark strip the tokens ride on
	_add_box(self, "BandStrip", Vector3(BAND_LENGTH, BAND_THICKNESS, BAND_WIDTH),
		Vector3(band_cx, BAND_TOP_Y - BAND_THICKNESS * 0.5, 0.0), band_mat)

	# Emissive edge lines along both long edges
	var edge_mat: StandardMaterial3D = _make_emissive_mat(phosphor_color * 0.85, 1.0)
	var hw: float = BAND_WIDTH * 0.5
	_add_box(self, "BandEdgeN", Vector3(BAND_LENGTH, 0.006, 0.008),
		Vector3(band_cx, BAND_TOP_Y, hw), edge_mat)
	_add_box(self, "BandEdgeS", Vector3(BAND_LENGTH, 0.006, 0.008),
		Vector3(band_cx, BAND_TOP_Y, -hw), edge_mat)

	# Two support pylons down to the floor
	var leg_mat: StandardMaterial3D = _make_flat_mat(Color(0.10, 0.105, 0.115), 0.3, 0.6)
	var leg_h: float = BAND_TOP_Y - BAND_THICKNESS
	_add_box(self, "PylonA", Vector3(0.05, leg_h, 0.05),
		Vector3(_band_start_x + 0.5, leg_h * 0.5, 0.0), leg_mat)
	_add_box(self, "PylonB", Vector3(0.05, leg_h, 0.05),
		Vector3(_band_start_x + 1.4, leg_h * 0.5, 0.0), leg_mat)


func _build_tile_pool() -> void:
	for i in range(TILE_POOL):
		var img: Image = Image.create(GLYPH_PX, GLYPH_PX, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.0, 0.0, 0.0, 1.0))
		var tex: ImageTexture = ImageTexture.create_from_image(img)
		var mat: StandardMaterial3D = _make_glyph_mat(tex)
		var tile: MeshInstance3D = _make_glyph_quad("BandTile%d" % i, mat)
		tile.visible = false
		add_child(tile)
		_band_tiles.append(tile)
		_band_mats.append(mat)
		_band_tex.append(tex)
		_band_img.append(img)
		_band_active.append(false)


func _build_fan() -> void:
	var spread: float = deg_to_rad(FAN_SPREAD_DEG)
	var denom: float = maxf(float(fan_size - 1), 1.0)
	for i in range(fan_size):
		var img: Image = Image.create(GLYPH_PX, GLYPH_PX, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.0, 0.0, 0.0, 1.0))
		var tex: ImageTexture = ImageTexture.create_from_image(img)
		var mat: StandardMaterial3D = _make_glyph_mat(tex)
		var ghost: MeshInstance3D = _make_glyph_quad("Ghost%d" % i, mat)

		var ang: float = -spread * 0.5 + spread * (float(i) / denom)
		var home_pos: Vector3 = Vector3(
			_band_start_x + 0.02,
			FAN_CENTER_Y + (cos(ang) - 0.62) * FAN_RADIUS,
			sin(ang) * FAN_RADIUS)
		# Card faces +X (down the band), with a gentle fan roll around its normal
		var home_basis: Basis = Basis(Vector3.RIGHT, -ang * 0.45) * Basis(Vector3.UP, PI * 0.5)
		var home: Transform3D = Transform3D(home_basis, home_pos)
		ghost.transform = home
		ghost.visible = false
		add_child(ghost)

		_ghosts.append(ghost)
		_ghost_mats.append(mat)
		_ghost_tex.append(tex)
		_ghost_img.append(img)
		_ghost_home.append(home)
		_weights.append(1.0)
		_ghost_alpha.append(0.5)
		_ghost_scl.append(1.0)


func _build_label() -> void:
	var caption: Label3D = Label3D.new()
	caption.name = "Caption"
	caption.text = "NEXT TOKEN — speech is a chain of small choices"
	caption.font_size = 40
	caption.pixel_size = 0.0035
	caption.modulate = Color(phosphor_color.r, phosphor_color.g, phosphor_color.b, 0.85)
	caption.outline_size = 8
	caption.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
	caption.position = Vector3(_band_start_x + BAND_LENGTH * 0.5, 0.55, 0.0)
	add_child(caption)

# ── Animation ─────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if not _built:
		return
	_scroll_band(delta)
	_advance_beat(delta)
	_decay_pulse(delta)


func _scroll_band(delta: float) -> void:
	for i in range(_band_tiles.size()):
		if not _band_active[i]:
			continue
		var tile: MeshInstance3D = _band_tiles[i]
		if tile == null:
			continue
		tile.position.x += band_speed * delta
		var dist: float = tile.position.x - _band_start_x
		if dist > FADE_START:
			var f: float = 1.0 - (dist - FADE_START) / (FADE_END - FADE_START)
			if f <= 0.0:
				tile.visible = false
				_band_active[i] = false
			else:
				_set_glyph_alpha(_band_mats[i], clampf(f, 0.0, 1.0))


func _advance_beat(delta: float) -> void:
	_beat_t += delta / maxf(beat_time, 0.15)
	if _beat_t >= 1.0:
		_land_winner()
		_reset_fan()
		_beat_t = fmod(_beat_t, 1.0)
	_animate_fan()


func _animate_fan() -> void:
	var t: float = clampf(_beat_t, 0.0, 1.0)
	if t >= PHASE_CHOOSE and _winner < 0:
		_winner = _sample_winner()
	for i in range(_ghosts.size()):
		var ghost: MeshInstance3D = _ghosts[i]
		if ghost == null:
			continue
		var target_a: float = _ghost_alpha[i]
		var a: float = 0.0
		if t < PHASE_FAN_IN:
			a = target_a * (t / PHASE_FAN_IN)
			_place_ghost_home(i)
		elif t < PHASE_CHOOSE:
			a = target_a
			_place_ghost_home(i)
		elif t < PHASE_DROP:
			var d: float = (t - PHASE_CHOOSE) / (PHASE_DROP - PHASE_CHOOSE)
			_place_ghost_home(i)
			if i == _winner:
				a = lerpf(target_a, 1.0, d)
				ghost.scale = Vector3.ONE * lerpf(_ghost_scl[i], 1.12, d)
			else:
				a = target_a * (1.0 - d)
		else:
			if i == _winner:
				a = 1.0
				var d2: float = (t - PHASE_DROP) / (1.0 - PHASE_DROP)
				var e: float = d2 * d2
				var home: Transform3D = _ghost_home[i]
				var flat: Basis = Basis(Vector3.RIGHT, -PI * 0.5)
				var pos: Vector3 = home.origin.lerp(_drop_point(), e)
				pos.y += sin(e * PI) * 0.03
				ghost.transform = Transform3D(home.basis.slerp(flat, e), pos)
				ghost.scale = Vector3.ONE * lerpf(1.12, 1.0, e)
			else:
				a = 0.0
		_set_glyph_alpha(_ghost_mats[i], a)
		ghost.visible = a > 0.004


func _place_ghost_home(i: int) -> void:
	var ghost: MeshInstance3D = _ghosts[i]
	if ghost == null:
		return
	ghost.transform = _ghost_home[i]
	ghost.scale = Vector3.ONE * _ghost_scl[i]


func _decay_pulse(delta: float) -> void:
	_pulse = maxf(_pulse - delta * 2.5, 0.0)
	if _antenna_mat != null:
		_antenna_mat.emission_energy_multiplier = 0.8 + 3.0 * _pulse
	if _mouth_mat != null:
		_mouth_mat.emission_energy_multiplier = 1.2 + 2.2 * _pulse

# ── The beat: choose, land, re-deal ───────────────────────────────────

func _sample_winner() -> int:
	var total: float = 0.0
	for i in range(_weights.size()):
		total += _weights[i]
	if total <= 0.0:
		return 0
	var roll: float = _rng.randf() * total
	var acc: float = 0.0
	for i in range(_weights.size()):
		acc += _weights[i]
		if roll <= acc:
			return i
	return _weights.size() - 1


func _land_winner() -> void:
	if _winner < 0 or _winner >= _ghost_img.size():
		return
	_spawn_band_tile(_ghost_img[_winner])
	_pulse = 1.0


func _spawn_band_tile(src: Image) -> void:
	var idx: int = -1
	for i in range(_band_tiles.size()):
		if not _band_active[i]:
			idx = i
			break
	if idx < 0:
		# Pool exhausted — recycle the tile furthest down the band
		var best_x: float = -INF
		for i in range(_band_tiles.size()):
			if _band_tiles[i] != null and _band_tiles[i].position.x > best_x:
				best_x = _band_tiles[i].position.x
				idx = i
	if idx < 0 or src == null:
		return
	_band_img[idx].copy_from(src)
	_band_tex[idx].update(_band_img[idx])
	var tile: MeshInstance3D = _band_tiles[idx]
	if tile == null:
		return
	tile.transform = Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), _drop_point())
	tile.scale = Vector3.ONE
	tile.visible = true
	_band_active[idx] = true
	_set_glyph_alpha(_band_mats[idx], 1.0)


func _reset_fan() -> void:
	_winner = -1
	# New weights, shaped by temperature: low temp -> peaked, high temp -> even
	var inv_t: float = 1.0 / clampf(temperature, 0.05, 4.0)
	var w_max: float = 0.0001
	for i in range(_ghosts.size()):
		var raw: float = _rng.randf_range(0.1, 1.0)
		_weights[i] = pow(raw, inv_t)
		w_max = maxf(w_max, _weights[i])
	for i in range(_ghosts.size()):
		var rel: float = _weights[i] / w_max
		_ghost_alpha[i] = lerpf(0.22, 0.95, rel)
		_ghost_scl[i] = 0.55 + 0.5 * rel
		_paint_glyph(_ghost_img[i])
		_ghost_tex[i].update(_ghost_img[i])
		_place_ghost_home(i)
		_set_glyph_alpha(_ghost_mats[i], 0.0)


func _drop_point() -> Vector3:
	return Vector3(_band_start_x + 0.07, BAND_TOP_Y + 0.004, 0.0)

# ── Glyph painting ────────────────────────────────────────────────────

func _paint_glyph(img: Image) -> void:
	if img == null:
		return
	var bg: Color = Color(0.015, 0.035, 0.02, 1.0)
	var bg_dim: Color = Color(0.008, 0.018, 0.012, 1.0)
	for py in range(GLYPH_PX):
		var row_c: Color = bg if (py % 2 == 0) else bg_dim
		for px in range(GLYPH_PX):
			img.set_pixel(px, py, row_c)
	var stroke_count: int = _rng.randi_range(2, 4)
	for _s in range(stroke_count):
		var ink: Color = _ink_color()
		var kind: int = _rng.randi_range(0, 3)
		match kind:
			0:
				_paint_vbar(img, ink)
			1:
				_paint_hbar(img, ink)
			2:
				_paint_dots(img, ink)
			_:
				_paint_diag(img, ink)


func _ink_color() -> Color:
	var glow: float = _rng.randf_range(0.75, 1.0)
	var c: Color = phosphor_color * glow
	if _rng.randf() < 0.3:
		# occasional cyan-shifted stroke
		c = Color(c.r * 0.4, c.g, minf(c.b + 0.35, 1.0))
	c.a = 1.0
	return c


func _paint_vbar(img: Image, ink: Color) -> void:
	var bx: int = _rng.randi_range(2, GLYPH_PX - 4)
	var bw: int = _rng.randi_range(1, 2)
	var y0: int = _rng.randi_range(2, 6)
	var y1: int = _rng.randi_range(9, GLYPH_PX - 3)
	for py in range(y0, y1 + 1):
		for dx in range(bw):
			img.set_pixel(bx + dx, py, ink)


func _paint_hbar(img: Image, ink: Color) -> void:
	var by: int = _rng.randi_range(2, GLYPH_PX - 4)
	var bh: int = _rng.randi_range(1, 2)
	var x0: int = _rng.randi_range(2, 6)
	var x1: int = _rng.randi_range(9, GLYPH_PX - 3)
	for px in range(x0, x1 + 1):
		for dy in range(bh):
			img.set_pixel(px, by + dy, ink)


func _paint_dots(img: Image, ink: Color) -> void:
	var dn: int = _rng.randi_range(1, 3)
	for _d in range(dn):
		var cx: int = _rng.randi_range(2, GLYPH_PX - 4)
		var cy: int = _rng.randi_range(2, GLYPH_PX - 4)
		for oy in range(2):
			for ox in range(2):
				img.set_pixel(cx + ox, cy + oy, ink)


func _paint_diag(img: Image, ink: Color) -> void:
	var px: int = _rng.randi_range(2, 5)
	var dirn: int = 1 if _rng.randf() < 0.5 else -1
	var py: int = _rng.randi_range(2, 5) if dirn == 1 else GLYPH_PX - 1 - _rng.randi_range(2, 5)
	var steps: int = _rng.randi_range(6, 9)
	for _s in range(steps):
		if px >= 0 and px < GLYPH_PX and py >= 0 and py < GLYPH_PX:
			img.set_pixel(px, py, ink)
			if px + 1 < GLYPH_PX:
				img.set_pixel(px + 1, py, ink)
		px += 1
		py += dirn

# ── Material / mesh helpers ───────────────────────────────────────────

func _make_glyph_mat(tex: ImageTexture) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	m.albedo_texture = tex
	m.emission_enabled = true
	m.emission = Color(1.0, 1.0, 1.0)
	m.emission_texture = tex
	m.emission_energy_multiplier = GLYPH_ENERGY
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func _make_glyph_quad(node_name: String, mat: StandardMaterial3D) -> MeshInstance3D:
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(TILE_SIZE, TILE_SIZE)
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = quad
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


func _set_glyph_alpha(mat: StandardMaterial3D, a: float) -> void:
	if mat == null:
		return
	var c: Color = mat.albedo_color
	c.a = a
	mat.albedo_color = c
	mat.emission_energy_multiplier = GLYPH_ENERGY * a


func _make_flat_mat(col: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = col
	m.metallic = metallic
	m.roughness = roughness
	return m


func _make_emissive_mat(col: Color, energy: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = col
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = energy
	return m


func _parse_color(raw: String, fallback: Color) -> Color:
	var s: String = raw.strip_edges()
	if s.contains(","):
		var parts: PackedStringArray = s.split(",")
		if parts.size() >= 3:
			var a: float = 1.0
			if parts.size() >= 4:
				a = parts[3].to_float()
			return Color(parts[0].to_float(), parts[1].to_float(), parts[2].to_float(), a)
	return Color.from_string(s, fallback)
