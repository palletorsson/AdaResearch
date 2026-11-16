extends RefCounted
## The human airway as one network:
##   lungs -> trachea -> glottis -> throat -+- mouth -> lips
##                                          +- velum port -> nose (+ a sinus) -> nostrils
## with the piriform fossae as a closed side branch above the glottis. Takes a posture, gets the passage
## areas from the head's geometry, limits how fast they may change (a closure seals more slowly than it
## releases), hands them to the network, and places the turbulence sources: at the glottis, at the
## narrowest point, and against the teeth.
##
## A GDScript port of Chimera's human airway, (c) 2026 Jameson Hodge, MIT licence (audio/airway/LICENSE.chimera).

const Net := preload("res://audio/airway/airway_network.gd")
const Tract := preload("res://audio/airway/human_tract.gd")

var net: Net
var tract: Tract
var body_scale := 1.0
var trachea := 0
var pharynx := 0
var oral := 0
var nasal := 0
var fossa := 0
var lungs := 0
var glottis_port := 0
var velum_port := 0
var n_ph := 0
var n_or := 0
var ph_areas := PackedFloat64Array()
var or_areas := PackedFloat64Array()
var ph_min := PackedFloat64Array()
var or_min := PackedFloat64Array()
var ph_len := 8.8
var or_len := 8.3
var dx_stable := 0.0
var noise_glottis := 3.2e-6
var noise_constriction := 2.2e-6
var noise_teeth := 3.0e-6
var max_area_rate := 45.0
var area_rate_gain := 40.0
var seal_rate := 5.0
var seal_lo := 0.03
var seal_hi := 0.4
var seal_ease := 0.03
var _sinus := 0
var _sinus_port := 0
var _has_base := false
var _base_ph := PackedFloat64Array()
var _base_or := PackedFloat64Array()
var _base_ph_min := PackedFloat64Array()
var _base_or_min := PackedFloat64Array()
var _base_dt := 0.0
# what the slew limit needs, set per commit
var _open_r := 0.0
var _seal_r := 0.0
var _lo := 0.0
var _hi := 0.0
var _ease := 0.0


## `fs`: the rate the network is stepped at (Hz). `body`: "male", "female", "child", or [scale, pharynx,
## tongue radius, lip width]. `min_sections`: the fewest sections the throat and the mouth may have.
func _init(fs: float, body: Variant, min_sections := 8) -> void:
	tract = Tract.new(body)
	var k := tract.scale
	body_scale = k
	net = Net.new(fs)
	var dx_min := (Net.C_SOUND / fs) / 0.93
	var ph_min_len := 8.7 * k * (0.55 + 0.45 * tract.pharynx) - 1.6 * k
	var or_min_len := 8.3 * k - 1.0 * k
	n_ph = int(maxf(float(min_sections), floorf(ph_min_len / dx_min)))
	n_or = int(maxf(float(min_sections), floorf(or_min_len / dx_min)))
	var tr_len := 12.0 * k
	trachea = net.add_tube("trachea", int(maxf(6.0, floorf(tr_len / maxf(dx_min, 0.9 * k)))), tr_len, 2.5 * k * k, Net.WALL_TRACHEA)
	pharynx = net.add_tube("pharynx", n_ph, 8.8 * k, 3.0 * k * k, Net.WALL_SOFT, 1.25, 1.0, 0.25)
	oral = net.add_tube("oral", n_or, 8.3 * k, 3.0 * k * k, Net.WALL_SOFT, 1.5, 1.0, 0.25)
	var na_len := 11.4 * k
	var n_na := int(maxf(8.0, floorf(na_len / maxf(dx_min, 0.5 * k))))
	var na_areas := PackedFloat64Array()
	for i in n_na:
		var w := (float(i) + 0.5) / float(n_na)
		var a := 1.0
		if w < 0.18: a = 2.6
		elif w < 0.75: a = 2.0 - 0.6 * (w - 0.18)
		elif w < 0.9: a = 1.4
		na_areas.append(a * k * k)
	nasal = net.add_tube("nasal", n_na, na_len, na_areas, Net.WALL_NASAL, 3.2, 2.5)
	var n_fo := int(maxf(1.0, minf(3.0, floorf(2.0 * k / dx_min))))
	fossa = net.add_tube("piriform", n_fo, 2.0 * k, 0.9 * k * k, Net.WALL_SOFT, 1.3)
	lungs = net.add_pressure_node("lungs")
	var tr_a := 2.5 * k * k
	net.add_port(lungs, net.first_node(trachea), tr_a, 1.0, 0.0, 0.0, 0.0, true, (0.5 * Net.RHO * Net.C_SOUND) / tr_a)
	glottis_port = net.add_port(net.last_node(trachea), net.first_node(pharynx), 0.0, 0.3 * k, 0.37, 1.0, 1.4 * k)
	net.connect_nodes(net.last_node(pharynx), net.first_node(oral))
	velum_port = net.add_port(net.last_node(pharynx), net.first_node(nasal), 0.0, 1.0 * k, 0.3, 0.8)
	# the piriform fossae branch off about 2.6 cm above the glottis
	var fossa_node := net.node_of(pharynx, int(minf(float(n_ph - 1), _round((2.6 / 8.8) * float(n_ph)))))
	net.connect_nodes(fossa_node, net.first_node(fossa))
	_sinus = net.add_cavity("sinus", 14.0 * k * k * k)
	_sinus_port = net.add_port(net.node_of(nasal, int(_round(float(n_na) * 0.45))), _sinus, 0.12 * k * k, 0.5 * k, 0.0, 0.0, 0.0, false)
	net.add_radiation(net.last_node(oral))
	net.add_radiation(net.last_node(nasal))
	net.finalize()
	ph_areas.resize(n_ph)
	or_areas.resize(n_or)
	ph_min.resize(n_ph)
	or_min.resize(n_or)
	ph_areas.fill(0.0)
	or_areas.fill(0.0)
	ph_min.fill(0.0)
	or_min.fill(0.0)
	dx_stable = (Net.C_SOUND / fs) / 0.97


## Once the network stands at its first posture: only the throat and the mouth change shape, and only the
## glottis and the velum port change area, so everything else is worked out once; and the nose (with its
## sinus) is left out of the stepping while the velum is shut and the nose is silent. Neither changes the
## sound beyond the network's own silence.
func settle() -> void:
	net.freeze_static_nodes([pharynx, oral], [glottis_port, velum_port])
	var nodes := PackedInt32Array()
	var group := PackedInt32Array([velum_port, _sinus_port])
	for i in net.tube_n[nasal]:
		nodes.append(net.node_of(nasal, i))
		if i < net.tube_n[nasal] - 1: group.append(net.tube_branch[nasal] + i)
	nodes.append(_sinus)
	net.set_sleep_group(nodes, group, velum_port)


static func _round(x: float) -> float:
	var r := floorf(x)
	return r + 1.0 if x - r >= 0.5 else r


static func _ss(e0: float, e1: float, x: float) -> float:
	var q := clampf((x - e0) / (e1 - e0), 0.0, 1.0)
	return q * q * (3.0 - 2.0 * q)


## The geometry for a posture becomes the next block's targets. `dt > 0` turns the slew limit on.
func apply(a: PackedFloat64Array, dt: float) -> void:
	if dt > 0.0:
		_base_ph = ph_areas.duplicate()
		_base_or = or_areas.duplicate()
		_base_ph_min = ph_min.duplicate()
		_base_or_min = or_min.duplicate()
		_has_base = true
	_base_dt = dt
	_commit(a, dt)


## Again within the same control step (a contact moved an articulator), limited against the same start.
func reapply(a: PackedFloat64Array) -> void:
	_commit(a, _base_dt)


# closing rate at an area: the release rate eased down to the seal rate near contact, and in the last
# part slowing with the square root of the area, so the seal is reached smoothly
func _close_r(area: float) -> float:
	if area < _ease: return _seal_r * sqrt(maxf(0.0, area) / _ease)
	var w := 0.0
	if area <= _lo: w = 0.0
	elif area >= _hi: w = 1.0
	else: w = (area - _lo) / (_hi - _lo)
	return _seal_r + (_open_r - _seal_r) * w * w * (3.0 - 2.0 * w)


func _limit(cur: PackedFloat64Array, old: PackedFloat64Array, mins: PackedFloat64Array, old_mins: PackedFloat64Array, dt: float) -> void:
	var gain := area_rate_gain
	for i in cur.size():
		var d := cur[i] - old[i]
		if d > 0.0:
			var lim := (_open_r + gain * cur[i]) * dt
			if d > lim: cur[i] = old[i] + lim
		else:
			var lim := (_close_r(old[i]) + gain * old[i]) * dt
			if d < -lim: cur[i] = old[i] - lim
		var dm := mins[i] - old_mins[i]
		if dm > 0.0:
			var lim_m := (_open_r + gain * mins[i]) * dt
			if dm > lim_m: mins[i] = old_mins[i] + lim_m
		else:
			var lim_m := (_close_r(old_mins[i]) + gain * old_mins[i]) * dt
			if dm < -lim_m: mins[i] = old_mins[i] - lim_m
		if mins[i] > cur[i]: mins[i] = cur[i]
		if mins[i] < 0.0: mins[i] = 0.0


func _commit(a: PackedFloat64Array, dt: float) -> void:
	tract.compute(a)
	var lens := tract.resample(a, ph_areas, or_areas, ph_min, or_min)
	if dt > 0.0 and _has_base:
		var k2 := body_scale * body_scale
		_open_r = max_area_rate * k2
		_seal_r = seal_rate * k2
		_lo = seal_lo * k2
		_hi = seal_hi * k2
		_ease = seal_ease * k2
		_limit(ph_areas, _base_ph, ph_min, _base_ph_min, dt)
		_limit(or_areas, _base_or, or_min, _base_or_min, dt)
	# a tube too short for the time step is stretched in the network only
	ph_len = lens[0]
	or_len = lens[1]
	net.set_tube_targets(pharynx, ph_areas, maxf(ph_len, float(n_ph) * dx_stable), ph_min)
	net.set_tube_targets(oral, or_areas, maxf(or_len, float(n_or) * dx_stable), or_min)
	net.set_port_target(velum_port, tract.velum_port)
	_update_noise()


func _to_branch(gi: int) -> int:
	if gi < n_ph: return net.branch_of(pharynx, gi)
	if gi == n_ph: return -1
	return net.branch_of(oral, gi - n_ph)


# Turbulence: at the glottis, at the narrowest open point above it, and where its jet meets the teeth.
# Every weight is a smooth function of the geometry, so sources fade in and out.
func _update_noise() -> void:
	var list: Array = []
	list.append([glottis_port, net.branch_of(pharynx, 1), net.branch_of(trachea, net.tube_n[trachea] - 2), noise_glottis, 3500.0, 300.0])
	var min_a := INF
	var min_i := -1
	for i in n_ph + n_or:
		var area := ph_min[i] if i < n_ph else or_min[i - n_ph]
		if area > 0.0 and area < min_a:
			min_a = area
			min_i = i
	var k2 := body_scale * body_scale
	var w_area := 1.0 - _ss(0.35 * k2, 0.9 * k2, min_a) if min_i >= 0 else 0.0
	if w_area > 0.0:
		var n_tot := n_ph + n_or
		var dx_ph := ph_len / float(n_ph)
		var dx_or := or_len / float(n_or)
		var dx := dx_ph if min_i < n_ph else dx_or
		var off := int(maxf(1.0, _round((0.9 * body_scale) / dx)))
		var src := _to_branch(mini(min_i, n_tot - 2))
		var fwd := _to_branch(mini(n_tot - 2, min_i + off))
		var bwd := _to_branch(maxi(0, min_i - off))
		if src >= 0 and fwd >= 0 and bwd >= 0:
			list.append([src, fwd, bwd, noise_constriction * w_area, 2600.0, 350.0])
			var s_min := (float(min_i) + 0.5) * dx_ph if min_i < n_ph else ph_len + (float(min_i - n_ph) + 0.5) * dx_or
			var behind := (tract.teeth_s - s_min) / body_scale
			var w_dist := _ss(0.15, 0.5, behind) * (1.0 - _ss(2.6, 4.0, behind))
			var w_jet := 1.0 - _ss(0.2 * k2, 0.5 * k2, min_a)
			var wt := w_dist * w_jet
			if wt > 1e-3:
				var teeth_i := n_ph + int(minf(float(n_or - 2), maxf(0.0, _round((tract.teeth_s - ph_len) / dx_or))))
				var tb := _to_branch(teeth_i)
				if tb >= 0: list.append([src, tb, bwd, noise_teeth * wt, 5000.0, 1200.0])
	net.set_noise_sources(list)
