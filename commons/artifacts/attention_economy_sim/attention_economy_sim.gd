extends Node3D
class_name AttentionEconomySim

# @identity
# essence: five content columns bidding against one horizontal attention bar that only ever pays out whole, so the four who lose each tick keep climbing — taller, brighter, flashing faster — until the resting state of the room is everyone screaming and one bar
# desire: to put the arithmetic of an attention market on a pad you can walk around, where the scarcity is a single physical bar and the demand is five things that never stop growing
# critical_parameter: escalation against tick_period — how fast an ignored stream raises its bid relative to how often the bar pays out; bids are unbounded and attention is not, which is the whole asymmetry
# triggers: _process runs a tick clock; each tick takes the argmax bid, awards the entire bar fill to it in that stream's colour, drops that bid to base, and adds each loser's own escalation rate to its bid — column height, emission and flash rate all read straight off the bid
# emerges: the winner's share of total demand falls tick after tick even though the winner always takes 100% of the bar — the market clears perfectly and satisfies less and less of what was asked
# needs: BoxMesh columns and bar [Godot built-ins]; Grid.gdshader for the pad and track [present]; Label3D for the share readout; nothing external
# relationships: the supply side of the criticalalgorithms room that filter_bubble_demo reads from the demand side — one artifact shows what competes for you, the other what that competition does to what you are shown
# truth: attention is conserved and bids are not. A market where one side is finite and the other is unbounded does not find equilibrium; it finds a permanent scream, and calls the loudest bidder a preference.

## Attention Economy Sim — a single shared bar, five unbounded bidders.
##
## Everything is built procedurally in _ready(). One pad, one horizontal
## attention bar, N vertical content-stream columns standing behind it.

const SHADER_PATH := "res://commons/resourses/shaders/Grid.gdshader"

@export var stream_count: int = 5
## Seconds between payouts. The bar sweeps full over exactly this long.
@export var tick_period: float = 1.2
## Bid a stream falls back to the moment it wins. Winning costs you your claim.
@export var base_bid: float = 0.12
## Bid at which a column is at full height and full brightness — the ceiling of
## the DISPLAY, never a ceiling on the bid itself. Bids keep climbing past it.
@export var display_ceiling: float = 1.0
## Base escalation added per ignored tick. Each stream gets its own multiple of
## this, so the argmax rotates instead of locking onto one column forever.
@export var escalation: float = 0.16

const PAD_W := 1.86
const COL_W := 0.20
const COL_D := 0.13
const COL_Z := -0.46
const COL_MIN_H := 0.10
const COL_MAX_H := 1.02
const BAR_Z := 0.52
const BAR_W := 1.52
const BAR_Y := 0.26

var _bids: Array[float] = []
var _rates: Array[float] = []
var _colors: Array[Color] = []
var _columns: Array[MeshInstance3D] = []
var _caps: Array[MeshInstance3D] = []
var _cap_mats: Array[StandardMaterial3D] = []
var _col_mats: Array[StandardMaterial3D] = []

var _fill: MeshInstance3D
var _fill_mat: StandardMaterial3D
var _readout: Label3D

var _winner: int = 0
var _share: float = 0.0
var _t: float = 0.0
var _accum: float = 0.0
var _built: bool = false

## Every node THIS script parented onto itself. A rebuild frees only these —
## label plates, packaging and tags the grid adds after us are not ours to kill.
var _created: Array[Node] = []


func _ready() -> void:
	_build_all()
	_built = true
	set_process(true)


# ═══════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════

func _build_all() -> void:
	var n: int = maxi(2, stream_count)
	_seed_market(n)
	_build_pad()
	_build_columns(n)
	_build_bar()
	_build_readout()
	# Resolve a winner immediately so the artifact is never photographed
	# mid-nothing: the market was running before you walked in.
	_award()


## Bids do not start at zero. The streams have been shouting for a while; each
## one carries a different escalation rate so no single column can own the argmax.
func _seed_market(n: int) -> void:
	_bids.clear()
	_rates.clear()
	_colors.clear()
	for i in range(n):
		var f: float = float(i) / float(maxi(1, n - 1))
		# Distinct rates, 0.7x to 1.3x the base. Distinct rates are what make the
		# winner rotate: equal rates plus a strict argmax means index 0 wins forever.
		_rates.append(escalation * (0.7 + 0.6 * f))
		# Pre-warmed to a staggered spread — a market already in progress.
		_bids.append(base_bid + display_ceiling * (0.25 + 0.7 * f))
		_colors.append(Color.from_hsv(fposmod(0.03 + 0.17 * float(i), 1.0), 0.72, 1.0))


func _build_pad() -> void:
	var pad := MeshInstance3D.new()
	pad.name = "Pad"
	var box := BoxMesh.new()
	box.size = Vector3(PAD_W, 0.04, PAD_W)
	pad.mesh = box
	pad.position = Vector3(0.0, 0.02, 0.0)
	pad.material_override = _grid_material(
		Color(0.15, 0.16, 0.20), Color(0.40, 0.45, 0.56), 0.4)
	_own(pad)


func _build_columns(n: int) -> void:
	_columns.clear()
	_caps.clear()
	_cap_mats.clear()
	_col_mats.clear()
	var span: float = PAD_W - 0.5
	for i in range(n):
		var f: float = 0.5 if n == 1 else float(i) / float(n - 1)
		var x: float = -span * 0.5 + span * f
		var tint: Color = _colors[i]

		# Socket — the slot the stream is plugged into. Fixed, unlit, so the
		# column's growth reads against something that does not move.
		var socket := MeshInstance3D.new()
		var sbox := BoxMesh.new()
		sbox.size = Vector3(COL_W + 0.06, 0.05, COL_D + 0.06)
		socket.mesh = sbox
		socket.position = Vector3(x, 0.065, COL_Z)
		socket.material_override = _grid_material(
			Color(0.22, 0.24, 0.29), Color(0.42, 0.46, 0.55), 0.3)
		_own(socket)

		# The bid column. Unit-height mesh, scaled in y each frame — cheaper and
		# safer than mutating a shared BoxMesh resource per frame.
		var col := MeshInstance3D.new()
		var cbox := BoxMesh.new()
		cbox.size = Vector3(COL_W, 1.0, COL_D)
		col.mesh = cbox
		var cmat := StandardMaterial3D.new()
		cmat.albedo_color = tint.darkened(0.35)
		cmat.roughness = 0.4
		cmat.emission_enabled = true
		cmat.emission = tint
		cmat.emission_energy_multiplier = 0.4
		col.material_override = cmat
		col.position = Vector3(x, 0.09, COL_Z)
		_own(col)
		_columns.append(col)
		_col_mats.append(cmat)

		# The cap — the flashing head of the column, the part that screams.
		var cap := MeshInstance3D.new()
		var capbox := BoxMesh.new()
		capbox.size = Vector3(COL_W + 0.03, 0.035, COL_D + 0.03)
		cap.mesh = capbox
		var capmat := StandardMaterial3D.new()
		capmat.albedo_color = tint
		capmat.emission_enabled = true
		capmat.emission = tint
		capmat.emission_energy_multiplier = 1.0
		capmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		cap.material_override = capmat
		cap.position = Vector3(x, 0.2, COL_Z)
		_own(cap)
		_caps.append(cap)
		_cap_mats.append(capmat)

	_apply_bids()


func _build_bar() -> void:
	# The track — one bar, fixed width, the entire supply of attention.
	var track := MeshInstance3D.new()
	track.name = "AttentionTrack"
	var tbox := BoxMesh.new()
	tbox.size = Vector3(BAR_W, 0.09, 0.16)
	track.mesh = tbox
	track.position = Vector3(0.0, BAR_Y, BAR_Z)
	track.material_override = _grid_material(
		Color(0.11, 0.12, 0.16), Color(0.50, 0.55, 0.66), 0.6)
	_own(track)

	# End stops, so the bar reads as bounded rather than as a strip that could
	# simply be made longer if demand asked nicely.
	for s in [-1.0, 1.0]:
		var stop := MeshInstance3D.new()
		var sbox := BoxMesh.new()
		sbox.size = Vector3(0.035, 0.15, 0.20)
		stop.mesh = sbox
		stop.position = Vector3(float(s) * (BAR_W * 0.5 + 0.017), BAR_Y, BAR_Z)
		stop.material_override = _grid_material(
			Color(0.30, 0.32, 0.38), Color(0.62, 0.68, 0.80), 0.8)
		_own(stop)

	# The fill — awarded WHOLE, one colour at a time. Unit-width mesh scaled in x
	# and slid so it grows from the left stop.
	_fill = MeshInstance3D.new()
	_fill.name = "AttentionFill"
	var fbox := BoxMesh.new()
	fbox.size = Vector3(1.0, 0.105, 0.175)
	_fill.mesh = fbox
	_fill_mat = StandardMaterial3D.new()
	_fill_mat.albedo_color = Color(0.8, 0.8, 0.8)
	_fill_mat.emission_enabled = true
	_fill_mat.emission = Color(0.8, 0.8, 0.8)
	_fill_mat.emission_energy_multiplier = 2.0
	_fill_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_fill.material_override = _fill_mat
	_fill.position = Vector3(-BAR_W * 0.5, BAR_Y, BAR_Z + 0.01)
	_fill.scale = Vector3(0.001, 1.0, 1.0)
	_own(_fill)


func _build_readout() -> void:
	_readout = Label3D.new()
	_readout.name = "ShareReadout"
	_readout.text = "ATTENTION ECONOMY"
	_readout.font_size = 30
	# pixel_size, not font_size, is what decides how wide four lines of text end up
	# in metres. At the default 0.005 the share line is over two metres across — a
	# 2x2 artifact would be captioned by something wider than its own pad.
	_readout.pixel_size = 0.0022
	_readout.outline_size = 6
	_readout.modulate = Color(0.92, 0.95, 1.0)
	_readout.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_readout.position = Vector3(0.0, 1.42, BAR_Z * 0.4)
	_own(_readout)


func _own(n: Node) -> void:
	add_child(n)
	_created.append(n)


# ═══════════════════════════════════════════════════════════════════
# THE MARKET
# ═══════════════════════════════════════════════════════════════════

## One clearing. The whole bar goes to the highest bid; that bid collapses to
## base; every loser adds its own rate. Nothing is divided, nothing is capped.
func _award() -> void:
	if _bids.is_empty():
		return
	var best: int = 0
	var total: float = 0.0
	for i in range(_bids.size()):
		total += _bids[i]
		if _bids[i] > _bids[best]:
			best = i
	_winner = best
	_share = 0.0 if total <= 0.0 else _bids[best] / total
	for i in range(_bids.size()):
		if i == best:
			_bids[i] = base_bid
		else:
			_bids[i] = _bids[i] + _rates[i]
	if _fill_mat:
		var tint: Color = _colors[best]
		_fill_mat.albedo_color = tint
		_fill_mat.emission = tint
	_apply_bids()
	_update_readout()


## Bid -> geometry. Height, body emission and cap size all track the bid, and
## every one of them saturates at display_ceiling while the bid does not.
func _apply_bids() -> void:
	for i in range(_columns.size()):
		if i >= _bids.size():
			break
		var norm: float = clampf(_bids[i] / maxf(0.001, display_ceiling), 0.0, 1.0)
		var h: float = COL_MIN_H + (COL_MAX_H - COL_MIN_H) * norm
		var col: MeshInstance3D = _columns[i]
		col.scale = Vector3(1.0, h, 1.0)
		col.position.y = 0.09 + h * 0.5
		var cap: MeshInstance3D = _caps[i]
		cap.position.y = 0.09 + h + 0.02
		var cmat: StandardMaterial3D = _col_mats[i]
		cmat.emission_energy_multiplier = 0.3 + 2.0 * norm


func _update_readout() -> void:
	if _readout == null:
		return
	var ignored: int = maxi(0, _bids.size() - 1)
	var at_ceiling: int = 0
	for i in range(_bids.size()):
		if i != _winner and _bids[i] >= display_ceiling:
			at_ceiling += 1
	_readout.text = "ATTENTION ECONOMY\nSTREAM %d TAKES THE WHOLE BAR\nSHARE OF WHAT WAS ASKED: %d%%\n%d IGNORED, %d AT THE CEILING" % [
		_winner + 1, int(round(_share * 100.0)), ignored, at_ceiling]


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	_accum += delta
	if _accum >= tick_period:
		_accum -= tick_period
		_award()

	# The bar sweeps across the tick — the winner is being paid, continuously and
	# entirely. It never splits.
	if is_instance_valid(_fill):
		var frac: float = clampf(_accum / maxf(0.001, tick_period), 0.0, 1.0)
		var w: float = maxf(0.001, BAR_W * frac)
		_fill.scale = Vector3(w, 1.0, 1.0)
		_fill.position.x = -BAR_W * 0.5 + w * 0.5

	# Losers flash, and flash faster the longer they have been ignored. The
	# winner, having just been paid, is briefly calm.
	for i in range(_cap_mats.size()):
		if i >= _bids.size():
			break
		var norm: float = clampf(_bids[i] / maxf(0.001, display_ceiling), 0.0, 1.0)
		var freq: float = 1.5 + 9.0 * norm
		var pulse: float = 0.5 + 0.5 * sin(_t * freq + float(i) * 1.7)
		var mat: StandardMaterial3D = _cap_mats[i]
		mat.emission_energy_multiplier = 0.4 + 3.4 * norm * pulse


# ═══════════════════════════════════════════════════════════════════
# MATERIAL + CONFIG
# ═══════════════════════════════════════════════════════════════════

func _grid_material(fill: Color, wire: Color, emit: float) -> Material:
	var shader: Shader = load(SHADER_PATH)
	if shader:
		var m := ShaderMaterial.new()
		m.shader = shader
		m.set_shader_parameter("modelColor", fill)
		m.set_shader_parameter("wireframeColor", wire)
		m.set_shader_parameter("emissionColor", wire)
		m.set_shader_parameter("width", 1.0)
		m.set_shader_parameter("blur", 1.0)
		m.set_shader_parameter("emission_strength", emit)
		m.set_shader_parameter("modelOpacity", 1.0)
		m.set_shader_parameter("wireframeOpacity", 1.0)
		m.set_shader_parameter("globalOpacity", 1.0)
		m.set_shader_parameter("show_interior", true)
		return m
	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = fill
	fallback.roughness = 0.4
	return fallback


## Free only what this script made, then build again — synchronously, in place.
## No call_deferred: a deferred rebuild that strips children first makes the
## grid's auto-ground measure a zero AABB and leave the artifact unseated.
func _rebuild_now() -> void:
	for c in _created:
		if is_instance_valid(c) and c.get_parent() == self:
			remove_child(c)
			c.queue_free()
	_created.clear()
	_columns.clear()
	_caps.clear()
	_cap_mats.clear()
	_col_mats.clear()
	_fill = null
	_fill_mat = null
	_readout = null
	_t = 0.0
	_accum = 0.0
	_build_all()


## Grid config. Keys: "streams", "tick_period", "escalation", "base_bid".
func apply_grid_config(config_data: Dictionary) -> void:
	var before_streams: int = stream_count
	var before_escalation: float = escalation

	if config_data.has("streams"):
		stream_count = clampi(int(config_data["streams"]), 2, 9)
	if config_data.has("tick_period"):
		tick_period = maxf(0.15, float(config_data["tick_period"]))
	if config_data.has("escalation"):
		escalation = maxf(0.0, float(config_data["escalation"]))
	if config_data.has("base_bid"):
		base_bid = maxf(0.0, float(config_data["base_bid"]))

	if not _built:
		return  # _ready has not run yet; it will build with these values.
	if stream_count == before_streams and is_equal_approx(escalation, before_escalation):
		# Only the clock moved. Rebuilding here would throw away the framing
		# curation_station applies one line after config, and never re-apply it.
		return

	_rebuild_now()
	print("[AttentionEconomySim] Config applied — streams=%d, escalation=%.3f" % [
		stream_count, escalation])
