extends RefCounted
## The air column: a branched network of short tube sections, stepped in time.
##
## Nodes carry pressure p (dyn/cm2) and a volume; branches carry volume velocity U (cm3/s) between two
## nodes. Leapfrog: branches take U from the pressures, then nodes take p from the flows. A branch keeps
## its momentum L*U, so a closing branch (L -> infinity) loses its flow without remembering it; its update
## solves  (L/T) U' + R U' + k |U'| U' = dp + momentum/T  exactly, k being the loss of a jet widening into
## the next section. Walls give (mass, spring, damper), open ends carry a radiation load, and what comes
## out is the rate of change of the radiated flow. CGS units throughout.
##
## A GDScript port, line for line, of the airway network of Chimera (c) 2026 Jameson Hodge, MIT licence:
## see audio/airway/LICENSE.chimera. Nothing here is native code.

const RHO := 1.14e-3
const C_SOUND := 35000.0
const MU := 1.86e-4
const NU := MU / RHO
const RHO_C2 := RHO * C_SOUND * C_SOUND
const CM_H2O := 980.665
const RE_CRIT := 1800.0
const WALL_SOFT := [1.5, 1600.0, 3.0e5]
const WALL_TRACHEA := [0.6, 1000.0, 1.0e6]
const WALL_NASAL := [1.0, 3000.0, 1.0e6]
const TINY := 1e-30
const KIND_SERIES := 0
const KIND_PORT := 1
const M32 := 0xFFFFFFFF

var fs := 0.0
var t := 0.0
var inv_t := 0.0

# tubes: first node, node count, first internal branch, current length
var tube_first := PackedInt32Array()
var tube_n := PackedInt32Array()
var tube_branch := PackedInt32Array()
var tube_length := PackedFloat64Array()
var tube_names: Array[String] = []
var _tube_specs: Array = []
var _finalized := false

var n_nodes := 0
var p := PackedFloat64Array()
var area := PackedFloat64Array()
var area_target := PackedFloat64Array()
var area_step := PackedFloat64Array()
var amin := PackedFloat64Array()
var amin_target := PackedFloat64Array()
var amin_step := PackedFloat64Array()
var is_junction := PackedByteArray()
var inv_lsum := PackedFloat64Array()
var inv_amin := PackedFloat64Array()
var nbr_start := PackedInt32Array()
var nbr_list := PackedInt32Array()
var spill := PackedFloat64Array()
var vol_src1 := PackedFloat64Array()
var vol_src2 := PackedFloat64Array()
var vol_lp_coef := 0.0
var volume_source_hz := 60.0
var squeeze_area := 0.12
var enable_volume_source := true
var enable_junction_floor := true
var energy_safe := true
var dx := PackedFloat64Array()
var dx_target := PackedFloat64Array()
var dx_step := PackedFloat64Array()
var vol := PackedFloat64Array()
var inv_a := PackedFloat64Array()
var half_l := PackedFloat64Array()
var half_r := PackedFloat64Array()
var sqrt_a := PackedFloat64Array()
var flow_sum := PackedFloat64Array()
var ext_flow := PackedFloat64Array()
var fixed := PackedByteArray()
var wall_m := PackedFloat64Array()
var wall_r := PackedFloat64Array()
var wall_k := PackedFloat64Array()
var wall_perim := PackedFloat64Array()
var wall_rad := PackedFloat64Array()
var has_wall := PackedByteArray()
var wall_y := PackedFloat64Array()
var wall_v := PackedFloat64Array()
var wall_u := PackedFloat64Array()
var visc_f := PackedFloat64Array()
var rad_of := PackedInt32Array()
## Nodes whose geometry never moves after the start (everything but the pharynx and the mouth): their
## per-sample geometry terms are computed once. Set by `freeze_static_nodes`.
var moving := PackedInt32Array()
var walled := PackedInt32Array()
var free_nodes := PackedInt32Array()

var n_branches := 0
var b_a := PackedInt32Array()
var b_b := PackedInt32Array()
var b_kind := PackedByteArray()
var _port_specs: Array = []
var u := PackedFloat64Array()
var mom := PackedFloat64Array()
var l_prev := PackedFloat64Array()
var psrc := PackedFloat64Array()
var port_area := PackedFloat64Array()
var port_area_target := PackedFloat64Array()
var port_area_step := PackedFloat64Array()
var port_len := PackedFloat64Array()
var port_kin := PackedFloat64Array()
var port_kex := PackedFloat64Array()
var port_slit := PackedFloat64Array()
var port_half := PackedByteArray()
var port_extra_r := PackedFloat64Array()
var branch_area := PackedFloat64Array()

var rad_nodes := PackedInt32Array()
var rad_ul := PackedFloat64Array()
var rad_l_prev := PackedFloat64Array()
var rad_u := PackedFloat64Array()
var rad_prev_total := 0.0

# turbulence sources, one row each
var ns_src := PackedInt32Array()
var ns_fwd := PackedInt32Array()
var ns_bwd := PackedInt32Array()
var ns_gain := PackedFloat64Array()
var ns_hp := PackedFloat64Array()
var ns_lp1 := PackedFloat64Array()
var ns_lp2 := PackedFloat64Array()
var ns_lpc := PackedFloat64Array()
var ns_hpc := PackedFloat64Array()
var ns_level := PackedFloat64Array()
var _rng := 12345
var _pending_fixed := PackedInt32Array()
var closed_area := 2e-4
var min_node_area := 0.02
var viscous_scale := 1.0
var viscous_omega := 2.0 * PI * 700.0
var noise_scale := 1.0
var out := 0.0


func _init(sample_rate: float) -> void:
	fs = sample_rate
	t = 1.0 / sample_rate
	inv_t = sample_rate


## A tube of `n` sections. `areas` is one number or one per section; `wall` is [mass, resistance,
## stiffness] per unit area, or empty for a rigid wall. Returns the tube's index.
func add_tube(tube_name: String, n: int, length: float, areas: Variant, wall: Array = [], perimeter := 1.0, viscous := 1.0, radiating := 0.0) -> int:
	assert(not _finalized)
	var index := tube_first.size()
	tube_first.append(n_nodes)
	tube_n.append(n)
	tube_branch.append(b_a.size())
	tube_length.append(length)
	tube_names.append(tube_name)
	for i in maxi(0, n - 1): _push_branch(n_nodes + i, n_nodes + i + 1, KIND_SERIES, [])
	n_nodes += n
	_tube_specs.append([n, length, areas, wall, perimeter, viscous, radiating])
	return index


func node_of(tube: int, i: int) -> int: return tube_first[tube] + i
func first_node(tube: int) -> int: return tube_first[tube]
func last_node(tube: int) -> int: return tube_first[tube] + tube_n[tube] - 1
func branch_of(tube: int, i: int) -> int: return tube_branch[tube] + clampi(i, 0, tube_n[tube] - 2)


## Two nodes joined through the half sections on either side (tube end to tube end).
func connect_nodes(a: int, b: int) -> int: return _push_branch(a, b, KIND_SERIES, [])


## Two nodes joined through a duct with its own area that changes in time: the glottis, the velum port,
## a neck. spec = [area, length, k_entrance, k_exit, slit_width, include_half_sections, extra_resistance].
func add_port(a: int, b: int, port_area_0: float, length: float, k_entrance := 0.4, k_exit := 1.0, slit := 0.0, half_sections := true, extra_r := 0.0) -> int:
	return _push_branch(a, b, KIND_PORT, [port_area_0, length, k_entrance, k_exit, slit, half_sections, extra_r])


## A lumped cavity (a Helmholtz volume). Returns its node.
func add_cavity(cavity_name: String, volume: float, wall: Array = []) -> int:
	var length := pow(volume, 1.0 / 3.0)
	return first_node(add_tube(cavity_name, 1, length, volume / length, wall, 1.2))


## A node whose pressure is given from outside (the lungs). Returns its node.
func add_pressure_node(node_name: String) -> int:
	var node := first_node(add_tube(node_name, 1, 1.0, 100.0))
	_pending_fixed.append(node)
	return node


## A radiation load at an open end. Returns the radiator's index.
func add_radiation(node: int) -> int:
	rad_nodes.append(node)
	return rad_nodes.size() - 1


func _push_branch(a: int, b: int, kind: int, spec: Array) -> int:
	b_a.append(a)
	b_b.append(b)
	b_kind.append(kind)
	_port_specs.append(spec)
	return b_a.size() - 1


static func _zeros(count: int) -> PackedFloat64Array:
	var z := PackedFloat64Array()
	z.resize(count)
	z.fill(0.0)
	return z


static func _bytes(count: int) -> PackedByteArray:
	var z := PackedByteArray()
	z.resize(count)
	z.fill(0)
	return z


func finalize() -> void:
	if _finalized: return
	_finalized = true
	var n := n_nodes
	var b := b_a.size()
	n_branches = b
	for name in ["p", "area", "area_target", "area_step", "amin", "amin_target", "amin_step", "inv_lsum", "inv_amin", "dx", "dx_target", "dx_step",
			"vol", "inv_a", "half_l", "half_r", "sqrt_a", "flow_sum", "ext_flow", "wall_m", "wall_r", "wall_k", "wall_perim", "wall_rad", "wall_y", "wall_v",
			"wall_u", "visc_f", "spill", "vol_src1", "vol_src2"]:
		set(name, _zeros(n))
	is_junction = _bytes(n)
	fixed = _bytes(n)
	has_wall = _bytes(n)
	rad_of.resize(n)
	rad_of.fill(-1)
	for ti in tube_first.size():
		var spec: Array = _tube_specs[ti]
		var count: int = spec[0]
		var d: float = float(spec[1]) / float(count)
		for i in count:
			var k := tube_first[ti] + i
			var a: float = float(spec[2][i]) if spec[2] is PackedFloat64Array or spec[2] is Array else float(spec[2])
			area[k] = a
			area_target[k] = a
			amin[k] = a
			amin_target[k] = a
			dx[k] = d
			dx_target[k] = d
			visc_f[k] = float(spec[5])
			var wall: Array = spec[3]
			if not wall.is_empty():
				has_wall[k] = 1
				wall_m[k] = float(wall[0])
				wall_r[k] = float(wall[1])
				wall_k[k] = float(wall[2])
			wall_perim[k] = float(spec[4]) * 2.0 * sqrt(PI)
			wall_rad[k] = float(spec[6])
	for k in _pending_fixed: fixed[k] = 1
	for name in ["u", "mom", "l_prev", "psrc", "port_area", "port_area_target", "port_area_step", "port_len", "port_kin", "port_kex", "port_slit",
			"port_extra_r", "branch_area"]:
		set(name, _zeros(b))
	port_half = _bytes(b)
	var degree := PackedInt32Array()
	degree.resize(n)
	degree.fill(0)
	for j in b:
		degree[b_a[j]] += 1
		degree[b_b[j]] += 1
	nbr_start.resize(n + 1)
	nbr_start[0] = 0
	for k in n:
		is_junction[k] = 1 if degree[k] >= 3 else 0
		nbr_start[k + 1] = nbr_start[k] + degree[k]
	nbr_list.resize(nbr_start[n])
	var fill_n := nbr_start.slice(0, n)
	for j in b:
		var a := b_a[j]
		var bb := b_b[j]
		nbr_list[fill_n[a]] = bb
		fill_n[a] += 1
		nbr_list[fill_n[bb]] = a
		fill_n[bb] += 1
	vol_lp_coef = 1.0 - exp((-2.0 * PI * volume_source_hz) / fs)
	for j in b:
		var s: Array = _port_specs[j]
		if s.is_empty(): continue
		port_area[j] = float(s[0])
		port_area_target[j] = float(s[0])
		port_len[j] = float(s[1])
		port_kin[j] = float(s[2])
		port_kex[j] = float(s[3])
		port_slit[j] = float(s[4])
		port_half[j] = 1 if bool(s[5]) else 0
		port_extra_r[j] = float(s[6])
	var nr := rad_nodes.size()
	rad_ul = _zeros(nr)
	rad_l_prev = _zeros(nr)
	rad_u = _zeros(nr)
	for r in nr: rad_of[rad_nodes[r]] = r
	moving.clear()
	walled.clear()
	free_nodes.clear()
	for k in n:
		vol[k] = maxf(area[k], min_node_area) * dx[k]
		inv_a[k] = 1.0 / maxf(area[k], 1e-6)
		moving.append(k)
		if has_wall[k] == 1: walled.append(k)
		if fixed[k] == 0: free_nodes.append(k)


## Courant number of the shortest section that is not a given pressure.
func check_cfl() -> float:
	var min_dx := INF
	for k in n_nodes:
		if fixed[k] == 0: min_dx = minf(min_dx, dx_target[k])
	return (C_SOUND * t) / min_dx


## From now on only these tubes' sections change shape; every other node keeps the geometry it has
## (its per-sample terms are worked out here, once). Exactly what the full loop computes for a node whose
## steps are zero, so the sound is the same.
func freeze_static_nodes(moving_tubes: Array) -> void:
	moving.clear()
	var is_moving := _bytes(n_nodes)
	for tube in moving_tubes:
		for i in tube_n[int(tube)]: is_moving[tube_first[int(tube)] + i] = 1
	for k in n_nodes:
		if is_moving[k] == 1:
			moving.append(k)
			continue
		var a := area[k]
		var ia := 1.0 / (a if a > 1e-6 else 1e-6)
		inv_a[k] = ia
		var amk := minf(amin[k], a)
		inv_amin[k] = 1.0 / (amk if amk > 1e-6 else 1e-6)
		var sa := sqrt(a)
		sqrt_a[k] = sa
		half_l[k] = dx[k] * ia
		half_r[k] = wall_perim[k] * dx[k] * sa * ia * ia * visc_f[k]
		vol[k] = (a if a > min_node_area else min_node_area) * dx[k]


# ---------------------------------------------------------------- control rate

## Areas (and the whole length) a tube is to reach at the end of the next block.
func set_tube_targets(tube: int, areas: PackedFloat64Array, length: float, min_areas: PackedFloat64Array) -> void:
	var first := tube_first[tube]
	var count := tube_n[tube]
	var with_min := not min_areas.is_empty()
	for i in count:
		var a := maxf(0.0, areas[i])
		area_target[first + i] = a
		amin_target[first + i] = maxf(0.0, minf(a, min_areas[i])) if with_min else a
	if length > 0.0:
		tube_length[tube] = length
		var d := length / float(count)
		for i in count: dx_target[first + i] = d


func set_port_target(branch: int, a: float) -> void:
	port_area_target[branch] = maxf(0.0, a)


## Set a port's area at once (the glottis calls this every sample).
func set_port_area(branch: int, a: float) -> void:
	var v := 0.0 if a < 0.0 else a
	port_area[branch] = v
	port_area_target[branch] = v
	port_area_step[branch] = 0.0


## Jump the geometry to its targets (at the start; no moving-wall transient).
func snap_to_targets() -> void:
	for k in n_nodes:
		area[k] = area_target[k]
		amin[k] = amin_target[k]
		dx[k] = dx_target[k]
		vol[k] = maxf(area[k], min_node_area) * dx[k]
		inv_a[k] = 1.0 / maxf(area[k], 1e-6)
		area_step[k] = 0.0
		amin_step[k] = 0.0
		dx_step[k] = 0.0
	for j in n_branches:
		if b_kind[j] == KIND_PORT:
			port_area[j] = port_area_target[j]
			port_area_step[j] = 0.0


## Straight ramps toward the targets over `samples` steps.
func begin_block(samples: int) -> void:
	var inv := 1.0 / maxf(1.0, float(samples))
	var max_p := 0.0
	for k in moving:
		area_step[k] = (area_target[k] - area[k]) * inv
		amin_step[k] = (amin_target[k] - amin[k]) * inv
		dx_step[k] = (dx_target[k] - dx[k]) * inv
	for k in free_nodes:
		var ap := absf(p[k])
		if ap > max_p: max_p = ap
	if max_p < 1e-9:
		var max_u := 0.0
		for j in n_branches: max_u = maxf(max_u, absf(u[j]))
		if max_u < 1e-9: _flush_state()
	for j in n_branches:
		if b_kind[j] == KIND_PORT: port_area_step[j] = (port_area_target[j] - port_area[j]) * inv
	_flush_tiny()


func _flush_tiny() -> void:
	for k in n_nodes:
		if fixed[k] == 0 and absf(p[k]) < TINY: p[k] = 0.0
		if absf(wall_v[k]) < TINY: wall_v[k] = 0.0
		if absf(wall_y[k]) < TINY: wall_y[k] = 0.0
		if absf(vol_src1[k]) < TINY: vol_src1[k] = 0.0
		if absf(vol_src2[k]) < TINY: vol_src2[k] = 0.0
	for j in n_branches:
		if absf(u[j]) < TINY: u[j] = 0.0
		if absf(mom[j]) < TINY: mom[j] = 0.0
	for r in rad_ul.size():
		if absf(rad_ul[r]) < TINY: rad_ul[r] = 0.0
		if absf(rad_u[r]) < TINY: rad_u[r] = 0.0
	if absf(rad_prev_total) < TINY: rad_prev_total = 0.0
	for i in ns_src.size():
		if absf(ns_hp[i]) < TINY: ns_hp[i] = 0.0
		if absf(ns_lp1[i]) < TINY: ns_lp1[i] = 0.0
		if absf(ns_lp2[i]) < TINY: ns_lp2[i] = 0.0
		if absf(ns_level[i]) < TINY: ns_level[i] = 0.0


func _flush_state() -> void:
	for k in n_nodes:
		if fixed[k] == 0: p[k] = 0.0
		wall_v[k] = 0.0
		if absf(wall_y[k]) < 1e-12: wall_y[k] = 0.0
	u.fill(0.0)
	mom.fill(0.0)
	rad_ul.fill(0.0)


## Replace the turbulence sources. Each row: [src, fwd, bwd, gain, lowpass_hz, highpass_hz]. A source
## whose (src, fwd) was there before keeps its filter state, so it does not click.
func set_noise_sources(list: Array) -> void:
	var count := list.size()
	var src := PackedInt32Array()
	var fwd := PackedInt32Array()
	var bwd := PackedInt32Array()
	src.resize(count)
	fwd.resize(count)
	bwd.resize(count)
	var gain := _zeros(count)
	var hp := _zeros(count)
	var lp1 := _zeros(count)
	var lp2 := _zeros(count)
	var lpc := _zeros(count)
	var hpc := _zeros(count)
	for i in count:
		var s: Array = list[i]
		src[i] = int(s[0])
		fwd[i] = int(s[1])
		bwd[i] = int(s[2])
		gain[i] = float(s[3])
		for o in ns_src.size():
			if ns_src[o] == src[i] and ns_fwd[o] == fwd[i]:
				hp[i] = ns_hp[o]
				lp1[i] = ns_lp1[o]
				lp2[i] = ns_lp2[o]
				break
		lpc[i] = 1.0 - exp((-2.0 * PI * float(s[4])) / fs)
		hpc[i] = exp((-2.0 * PI * float(s[5])) / fs)
	ns_src = src
	ns_fwd = fwd
	ns_bwd = bwd
	ns_gain = gain
	ns_hp = hp
	ns_lp1 = lp1
	ns_lp2 = lp2
	ns_lpc = lpc
	ns_hpc = hpc
	ns_level = _zeros(count)


# ---------------------------------------------------------------- one sample

## Advance one step. Returns the radiated pressure (in arbitrary units, the slope of the radiated flow).
func step() -> float:
	var n := n_nodes
	var nb := n_branches
	var tt := t
	var it := inv_t
	var min_a := min_node_area
	var a_area := area
	var a_amin := amin
	var a_dx := dx
	var a_inv_a := inv_a
	var a_inv_amin := inv_amin
	var a_half_l := half_l
	var a_half_r := half_r
	var a_sqrt_a := sqrt_a
	var a_vol := vol
	var a_flow := flow_sum
	var a_inv_lsum := inv_lsum
	var a_p := p
	var inj := spill

	# 1) geometry ramps and the volume the moving walls displace
	var sq := squeeze_area
	var vol_on := enable_volume_source
	if vol_on: inj.fill(0.0)
	a_inv_lsum.fill(0.0)
	for k in n:
		a_flow[k] = ext_flow[k]
	ext_flow.fill(0.0)
	for k in moving:
		var a := a_area[k] + area_step[k]
		if a < 0.0: a = 0.0
		a_area[k] = a
		var am := a_amin[k] + amin_step[k]
		if am < 0.0: am = 0.0
		var amk := a if am > a else am
		a_amin[k] = amk
		a_dx[k] += dx_step[k]
		var d := a_dx[k]
		var ia := 1.0 / (a if a > 1e-6 else 1e-6)
		a_inv_a[k] = ia
		a_inv_amin[k] = 1.0 / (amk if amk > 1e-6 else 1e-6)
		var sa := sqrt(a)
		a_sqrt_a[k] = sa
		a_half_l[k] = d * ia
		a_half_r[k] = wall_perim[k] * d * sa * ia * ia * visc_f[k]
		var v := (a if a > min_a else min_a) * d
		if vol_on:
			var raw := -(v - a_vol[k]) * it
			if raw != 0.0:
				var ae := amk if amk < a else a
				if ae < sq:
					var q := ae / sq
					var keep := q * q * (3.0 - 2.0 * q)
					inj[k] += raw * keep
					var sp := raw * (1.0 - keep)
					var s0 := nbr_start[k]
					var s1 := nbr_start[k + 1]
					var n_open := 0
					for e in range(s0, s1):
						var m := nbr_list[e]
						if minf(a_area[m], a_amin[m]) >= sq or amin_target[m] >= sq: n_open += 1
					if n_open > 0:
						var share := sp / float(n_open)
						for e in range(s0, s1):
							var m := nbr_list[e]
							if minf(a_area[m], a_amin[m]) >= sq or amin_target[m] >= sq: inj[m] += share
				else:
					inj[k] += raw
		a_vol[k] = v
	if vol_on:
		var c := vol_lp_coef
		var v1 := vol_src1
		var v2 := vol_src2
		for k in n:
			var s1 := v1[k] + c * (inj[k] - v1[k])
			v1[k] = s1
			var s2 := v2[k] + c * (s1 - v2[k])
			v2[k] = s2
			a_flow[k] += s2

	# 2) turbulence -> pressure sources in series with branches
	var a_psrc := psrc
	a_psrc.fill(0.0)
	if not ns_src.is_empty(): _compute_noise()

	# 3) branches
	var visc := sqrt((RHO * MU * viscous_omega) / 2.0) * viscous_scale
	var closed := closed_area
	var half_rho := 0.5 * RHO
	var safe := energy_safe
	var a_u := u
	var a_mom := mom
	var a_lprev := l_prev
	var a_barea := branch_area
	var a_parea := port_area
	var a_ba := b_a
	var a_bb := b_b
	var a_kind := b_kind
	var a_isj := is_junction
	for j in nb:
		var a := a_ba[j]
		var b := a_bb[j]
		var l := 0.0
		var r := 0.0
		var kf := 0.0
		var kb := 0.0
		var a_eff := 0.0
		if a_kind[j] == 0:
			var ma := a_amin[a]
			var mb := a_amin[b]
			a_eff = ma if ma < mb else mb
			var aa := a_area[a]
			var ab := a_area[b]
			if (aa if aa < ab else ab) < closed or a_eff < closed:
				a_u[j] = 0.0
				a_mom[j] = 0.0
				a_barea[j] = a_eff
				continue
			var ia := a_inv_a[a]
			var ib := a_inv_a[b]
			l = half_rho * (a_half_l[a] + a_half_l[b])
			r = 0.5 * visc * (a_half_r[a] + a_half_r[b])
			var ima := a_inv_amin[a]
			var imb := a_inv_amin[b]
			var ef := ima - ib
			var eb := imb - ia
			if ef > 0.0:
				kf = half_rho * ef * ef
				kb += 0.1 * half_rho * ef * ef
			if eb > 0.0:
				kb += half_rho * eb * eb
				kf += 0.1 * half_rho * eb * eb
		else:
			var ap := a_parea[j] + port_area_step[j]
			if ap < 0.0: ap = 0.0
			a_parea[j] = ap
			a_eff = ap
			if ap < closed:
				a_u[j] = 0.0
				a_mom[j] = 0.0
				a_barea[j] = ap
				continue
			var ip := 1.0 / ap
			var length := port_len[j]
			l = RHO * length * ip
			if port_half[j] == 1: l += half_rho * (a_half_l[a] + a_half_l[b])
			var w := port_slit[j]
			if w > 0.0: r = (12.0 * MU * length * w * w) * ip * ip * ip
			else: r = visc * 2.0 * sqrt(PI) * length * sqrt(ap) * ip * ip
			r += port_extra_r[j]
			var ex_f := ip - a_inv_a[b]
			var ex_b := ip - a_inv_a[a]
			var kin := port_kin[j] * half_rho * ip * ip
			kf = kin + port_kex[j] * half_rho * (ex_f * ex_f if ex_f > 0.0 else 0.0)
			kb = kin + port_kex[j] * half_rho * (ex_b * ex_b if ex_b > 0.0 else 0.0)
		a_barea[j] = a_eff
		var m0 := l * a_u[j] if safe and l < a_lprev[j] else a_mom[j]
		var c := a_p[a] - a_p[b] + a_psrc[j] + m0 * it
		var bq := l * it + r
		var flow := 0.0
		if c >= 0.0:
			flow = (2.0 * c) / (bq + sqrt(bq * bq + 4.0 * kf * c)) if kf > 0.0 else c / bq
		elif kb > 0.0:
			flow = (2.0 * c) / (bq + sqrt(bq * bq - 4.0 * kb * c))
		else:
			flow = c / bq
		a_u[j] = flow
		a_mom[j] = l * flow
		a_lprev[j] = l
		a_flow[a] -= flow
		a_flow[b] += flow
		if a_isj[a] == 1 or a_isj[b] == 1:
			var il := 1.0 / l
			a_inv_lsum[a] += il
			a_inv_lsum[b] += il

	# 4) walls
	var wall_rad_sum := 0.0
	var a_wv := wall_v
	var a_wy := wall_y
	var sqrt_min := sqrt(min_a)
	for k in walled:
		var m := wall_m[k]
		var r := wall_r[k]
		var v := ((m * it - 0.5 * r) * a_wv[k] + a_p[k] - wall_k[k] * a_wy[k]) / (m * it + 0.5 * r)
		a_wv[k] = v
		a_wy[k] += tt * v
		var sa := a_sqrt_a[k] if a_area[k] > min_a else sqrt_min
		var uw := wall_perim[k] * sa * a_dx[k] * v
		wall_u[k] = uw
		a_flow[k] -= uw
		wall_rad_sum += uw * wall_rad[k]

	# 5) nodes
	var t2 := tt * tt
	var rad_total := wall_rad_sum
	var a_radof := rad_of
	var floor_on := enable_junction_floor
	for k in free_nodes:
		var rr := a_radof[k]
		if a_area[k] < closed or a_amin[k] < closed:
			if rr >= 0:
				a_p[k] *= 0.98
				rad_ul[rr] *= 0.995
				rad_u[rr] = rad_ul[rr]
				rad_total += rad_ul[rr]
			else:
				var sum := 0.0
				var cnt := 0
				for e in range(nbr_start[k], nbr_start[k + 1]):
					var m := nbr_list[e]
					if a_area[m] >= closed and a_amin[m] >= closed:
						sum += a_p[m]
						cnt += 1
				if cnt > 0: a_p[k] += 0.02 * (sum / float(cnt) - a_p[k])
			continue
		var c := a_vol[k] / RHO_C2
		if floor_on and a_isj[k] == 1:
			var c_min := (t2 * a_inv_lsum[k]) / 2.4
			if c < c_min: c = c_min
		if rr < 0:
			a_p[k] += (tt / c) * a_flow[k]
		else:
			var a := a_area[k] if a_area[k] > 1e-4 else 1e-4
			var lr := (8.0 * RHO) / (3.0 * PI * sqrt(PI * a))
			var r_rad := (128.0 * RHO * C_SOUND) / (9.0 * PI * PI * a)
			var p_old := a_p[k]
			var lp := rad_l_prev[rr]
			var ul_prev := rad_ul[rr]
			if lp > 0.0 and lr > lp: ul_prev *= lp / lr
			rad_l_prev[rr] = lr
			var h := tt / (2.0 * lr)
			var g := 0.5 / r_rad
			var p_new := (p_old * (c * it - 0.5 * h - g) + a_flow[k] - ul_prev) / (c * it + 0.5 * h + g)
			a_p[k] = p_new
			var ul := ul_prev + h * (p_old + p_new)
			rad_ul[rr] = ul
			var ur := 0.5 * (ul_prev + ul) + g * (p_new + p_old)
			rad_u[rr] = ur
			rad_total += ur
	var result := (rad_total - rad_prev_total) * it
	rad_prev_total = rad_total
	out = result
	return result


func _compute_noise() -> void:
	var scale := noise_scale * sqrt(96000.0 / fs)
	var sat := 12000.0 * 12000.0 - RE_CRIT * RE_CRIT
	var state := _rng
	for i in ns_src.size():
		var src := ns_src[i]
		var a := branch_area[src]
		var flow := u[src]
		var amp := 0.0
		if a > closed_area:
			var re := (absf(flow) * 2.0) / (NU * sqrt(PI * a))
			if re > RE_CRIT:
				var x := re * re - RE_CRIT * RE_CRIT
				amp = (ns_gain[i] * scale * x) / (1.0 + x / sat)
		# the engine's generator (mulberry32), in 32-bit steps
		state = (state + 0x6d2b79f5) & M32
		var q := state
		var x1 := q ^ (q >> 15)
		var y1 := q | 1
		q = ((x1 & 0xFFFF) * y1 + ((((x1 >> 16) * y1) & 0xFFFF) << 16)) & M32
		var x2 := q ^ (q >> 7)
		var y2 := q | 61
		q = q ^ ((q + (((x2 & 0xFFFF) * y2 + ((((x2 >> 16) * y2) & 0xFFFF) << 16)) & M32)) & M32)
		var w := (float((q ^ (q >> 14)) & M32) / 4294967296.0 * 2.0 - 1.0) * 1.732
		var hp := ns_hp[i] + (1.0 - ns_hpc[i]) * (w - ns_hp[i])
		ns_hp[i] = hp
		var lp1 := ns_lp1[i] + ns_lpc[i] * ((w - hp) - ns_lp1[i])
		ns_lp1[i] = lp1
		var lp2 := ns_lp2[i] + ns_lpc[i] * (lp1 - ns_lp2[i])
		ns_lp2[i] = lp2
		ns_level[i] = amp
		if amp == 0.0: continue
		var v := amp * lp2
		if flow >= 0.0: psrc[ns_fwd[i]] += v
		else: psrc[ns_bwd[i]] -= v
	_rng = state


func reset() -> void:
	p.fill(0.0)
	u.fill(0.0)
	mom.fill(0.0)
	l_prev.fill(0.0)
	wall_y.fill(0.0)
	wall_v.fill(0.0)
	rad_ul.fill(0.0)
	rad_l_prev.fill(0.0)
	rad_prev_total = 0.0
