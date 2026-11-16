extends RefCounted
## The head, cut down the middle: where the walls of the throat and mouth are for a given posture of jaw,
## tongue, lips, velum and larynx, and from that the area of the air passage from the glottis to the lips.
##
## Head frame in cm, x forward, y up, glottis at (0, 0) with the larynx at rest (a man's head, scaled for
## other bodies). The outer wall is the back of the throat, the velum, the palate, the upper teeth and
## lip; the inner wall is the epiglottis, the tongue (a circle for its body, a blade, a tip), the floor
## of the mouth, the lower teeth and lip, the lower parts carried by the jaw. A fan of lines (level in
## the throat, radial in the mouth, upright at the teeth and lips) is cut by both walls; the gap d along
## each gives an area alpha * d^beta, at the lips a slit. Where the tongue nears the roof, the gap is the
## distance to the tongue's own surface, so a closure seals over a length and opens all at once.
##
## A GDScript port of Chimera's human articulatory model, (c) 2026 Jameson Hodge, MIT licence
## (audio/airway/LICENSE.chimera). Points are kept as separate x and y numbers: a Vector2 is 32-bit.

const N_ARTIC := 17
const NAMES: Array[String] = ["jaw", "tbX", "tbY", "ttX", "ttY", "ttCurl", "root", "lipAp", "lipProt", "lipWidth", "labiodental", "velum", "larynx",
	"epilarynx", "ventricular", "lateral", "dorsum"]
const JAW := 0
const TB_X := 1
const TB_Y := 2
const TT_X := 3
const TT_Y := 4
const TT_CURL := 5
const ROOT := 6
const LIP_AP := 7
const LIP_PROT := 8
const LIP_WIDTH := 9
const LABIODENTAL := 10
const VELUM := 11
const LARYNX := 12
const EPILARYNX := 13
const VENTRICULAR := 14
const LATERAL := 15
const DORSUM := 16
## Neutral (schwa-like) posture, in the man's head before scaling.
const NEUTRAL: Array[float] = [0.6, 2.9, 6.85, 6.45, 7.3, 0.0, 0.0, 0.7, 0.2, 0.5, 0.0, -0.15, 0.0, 0.0, 0.0, 0.0, 0.0]
## scale, pharynx, tongue radius, lip width
const BODIES := {"male": [1.0, 1.0, 2.25, 4.6], "female": [0.9, 0.88, 2.2, 4.4], "child": [0.74, 0.8, 2.15, 4.0]}

const DEG := PI / 180.0
const LAB_HANDOVER := 0.5
const LAB_GAP := 0.3
const LAB_FRONT_OPENS := 0.7
const LAB_FRONT_RAMP := 0.1
const ARC_POINTS := 32
const MAX_CROSS := 64

var scale := 1.0
var pharynx := 1.0
var tongue_radius := 2.25
var lip_width := 4.6
var _k := 1.0

# fixed landmarks, scaled
var _wall_x := PackedFloat64Array()
var _wall_y := PackedFloat64Array()
var _pal_x := PackedFloat64Array()
var _pal_y := PackedFloat64Array()
var _pns_x := 0.0
var _pns_y := 0.0
var _con_x := 0.0
var _con_y := 0.0
var _c1_x := 0.0
var _c1_y := 0.0
var _c2_x := 0.0
var _c2_y := 0.0
var _jaw_sin := 0.0
var _jaw_cos := 1.0

## Area laws [alpha, beta]: throat, mouth, front, and in front of a raised tongue tip.
var law_pharynx := [2.0, 1.4]
var law_oral := [2.6, 1.4]
var law_front := [2.0, 1.4]
var law_ahead := [1.6, 1.4]

# the last frame
var g_in_x := PackedFloat64Array()
var g_in_y := PackedFloat64Array()
var g_out_x := PackedFloat64Array()
var g_out_y := PackedFloat64Array()
var g_mid_x := PackedFloat64Array()
var g_mid_y := PackedFloat64Array()
var g_d := PackedFloat64Array()
var g_area := PackedFloat64Array()
var g_s := PackedFloat64Array()
var g_ray := PackedFloat64Array()
var g_region := PackedInt32Array()
var length := 0.0
var pharynx_length := 0.0
var teeth_s := 0.0
var lip_s := 0.0
var velum_port := 0.0
var lip_area := 0.0
var split_index := -1
var tip_x := 0.0
var tip_y := 0.0
## Closest approach (cm, negative = pressed in) of the tongue's tip and body to the roof, and the roof's
## normal there, pointing into the air.
var contact_tip := 1.0
var contact_body := 1.0
var contact_tip_nx := 0.0
var contact_tip_ny := -1.0
var contact_body_nx := 0.0
var contact_body_ny := -1.0

# scratch
var _tmp := PackedFloat64Array()
var _cross_t := PackedFloat64Array()
var _cross_exit := PackedByteArray()
var _vo_x := PackedFloat64Array()
var _vo_y := PackedFloat64Array()
var _out_x := PackedFloat64Array()
var _out_y := PackedFloat64Array()
var _inn_x := PackedFloat64Array()
var _inn_y := PackedFloat64Array()
var _ul_x := PackedFloat64Array()
var _ul_y := PackedFloat64Array()
var _ll_x := PackedFloat64Array()
var _ll_y := PackedFloat64Array()
var _root_x := PackedFloat64Array()
var _root_y := PackedFloat64Array()
var _arc_x := PackedFloat64Array()
var _arc_y := PackedFloat64Array()
var _blade_x := PackedFloat64Array()
var _blade_y := PackedFloat64Array()
var _under_x := PackedFloat64Array()
var _under_y := PackedFloat64Array()
var _back_x := PackedFloat64Array()
var _back_y := PackedFloat64Array()
var _roof_x := PackedFloat64Array()
var _roof_y := PackedFloat64Array()
var _cum := PackedFloat64Array()
var _tipp_x := PackedFloat64Array()
var _tipp_y := PackedFloat64Array()
var _outl_x := PackedFloat64Array()
var _outl_y := PackedFloat64Array()
var _floor_x := PackedFloat64Array()
var _floor_y := PackedFloat64Array()
var _lt_x := PackedFloat64Array()
var _lt_y := PackedFloat64Array()
# what a ray measured, and a projection onto a line
var _m_in_x := 0.0
var _m_in_y := 0.0
var _m_out_x := 0.0
var _m_out_y := 0.0
var _m_d := 0.0
var _pr_s := 0.0
var _pr_dist := 0.0
var _pr_signed := 0.0
var _pr_seg := 0
var _ca_d := 0.0
var _ca_nx := 0.0
var _ca_ny := 0.0


func _init(body: Variant = "male") -> void:
	var b: Array = BODIES[body] if body is String else body
	scale = float(b[0])
	pharynx = float(b[1])
	tongue_radius = float(b[2])
	lip_width = float(b[3])
	_k = scale
	_tmp.resize(MAX_CROSS)
	_cross_t.resize(MAX_CROSS)
	_cross_exit.resize(MAX_CROSS)
	_catmull([-1.0, -1.5, -1.1, 1.5, -1.2, 3.6, -1.3, 5.6, -1.38, 7.5, -1.33, 8.9, -1.05, 10.1, -0.45, 10.9, 0.4, 11.3], 4, _wall_x, _wall_y)
	_pns_x = _px(1.0)
	_pns_y = _py(9.75)
	_catmull([1.0, 9.6, 1.8, 9.92, 2.7, 10.18, 3.6, 10.3, 4.4, 10.25, 5.1, 10.05, 5.7, 9.72, 6.15, 9.36, 6.5, 9.05, 6.78, 8.7, 6.98, 8.3, 7.12, 7.95], 3, _pal_x, _pal_y)
	_con_x = _px(-2.5)
	_con_y = _py(10.5)
	_c1_x = _px(2.6)
	_c1_y = _py(6.95)
	_c2_x = _px(5.0)
	_c2_y = _py(6.85)


## A point of the man's head, in this body: the mouth (x > 0.5) is compressed by 0.86, the throat
## (y < 7) shortened by the body's pharynx factor, all of it scaled.
func _px(x: float) -> float:
	return (0.5 + (x - 0.5) * 0.86 if x > 0.5 else x) * _k


func _py(y: float) -> float:
	return (7.0 - (7.0 - y) * pharynx if y < 7.0 else y) * _k


# a point carried by the jaw (turned about the condyle)
func _jx(x: float, y: float) -> float:
	return _con_x + (_px(x) - _con_x) * _jaw_cos - (_py(y) - _con_y) * _jaw_sin


func _jy(x: float, y: float) -> float:
	return _con_y + (_px(x) - _con_x) * _jaw_sin + (_py(y) - _con_y) * _jaw_cos


static func _ss(e0: float, e1: float, x: float) -> float:
	var q := clampf((x - e0) / (e1 - e0), 0.0, 1.0)
	return q * q * (3.0 - 2.0 * q)


## Where the tongue's tip rests for a given jaw and tongue body: behind the lower teeth.
static func rest_tip(jaw: float, tb_x: float, tb_y: float) -> PackedFloat64Array:
	var ang := -jaw / 9.84
	var ddx := 6.45 - (-2.5)
	var ddy := 7.35 - 10.5
	var x := -2.5 + ddx * cos(ang) - ddy * sin(ang)
	var y := 10.5 + ddx * sin(ang) + ddy * cos(ang)
	return PackedFloat64Array([x + 0.3 * (tb_x - NEUTRAL[TB_X]), y + 0.35 * (tb_y - NEUTRAL[TB_Y])])


# Catmull-Rom through template points (given as x, y, x, y ...), `per` samples a segment, scaled to the body.
func _catmull(flat: Array, per: int, xs: PackedFloat64Array, ys: PackedFloat64Array) -> void:
	var count := flat.size() >> 1
	var px := PackedFloat64Array()
	var py := PackedFloat64Array()
	for i in count:
		px.append(_px(float(flat[2 * i])))
		py.append(_py(float(flat[2 * i + 1])))
	xs.clear()
	ys.clear()
	for i in count - 1:
		var i0 := maxi(0, i - 1)
		var i3 := mini(i + 2, count - 1)
		for q in per:
			var u := float(q) / float(per)
			var u2 := u * u
			var u3 := u2 * u
			xs.append(0.5 * (2.0 * px[i] + (-px[i0] + px[i + 1]) * u + (2.0 * px[i0] - 5.0 * px[i] + 4.0 * px[i + 1] - px[i3]) * u2 + (-px[i0] + 3.0 * px[i] - 3.0 * px[i + 1] + px[i3]) * u3))
			ys.append(0.5 * (2.0 * py[i] + (-py[i0] + py[i + 1]) * u + (2.0 * py[i0] - 5.0 * py[i] + 4.0 * py[i + 1] - py[i3]) * u2 + (-py[i0] + 3.0 * py[i] - 3.0 * py[i + 1] + py[i3]) * u3))
	xs.append(px[count - 1])
	ys.append(py[count - 1])


static func _bezier3(x0: float, y0: float, x1: float, y1: float, x2: float, y2: float, x3: float, y3: float, count: int, xs: PackedFloat64Array, ys: PackedFloat64Array) -> void:
	xs.clear()
	ys.clear()
	for i in count:
		var q := float(i) / (float(count) - 1.0)
		var w := 1.0 - q
		var a := w * w * w
		var b := 3.0 * w * w * q
		var c := 3.0 * w * q * q
		var d := q * q * q
		xs.append(a * x0 + b * x1 + c * x2 + d * x3)
		ys.append(a * y0 + b * y1 + c * y2 + d * y3)


static func _bezier2(x0: float, y0: float, x1: float, y1: float, x2: float, y2: float, count: int, xs: PackedFloat64Array, ys: PackedFloat64Array) -> void:
	xs.clear()
	ys.clear()
	for i in count:
		var q := float(i) / (float(count) - 1.0)
		var w := 1.0 - q
		xs.append(w * w * x0 + 2.0 * w * q * x1 + q * q * x2)
		ys.append(w * w * y0 + 2.0 * w * q * y1 + q * q * y2)


# Every crossing of the ray o + t d (t in [t_min, t_max]) with a line of points, into `into`. Returns how
# many. A segment crosses only if its ends lie on different sides, a point on the ray counting as the
# positive side. With `exits`, also whether the ray leaves tissue (the line's right) for air there.
func _ray(ox: float, oy: float, ddx: float, ddy: float, xs: PackedFloat64Array, ys: PackedFloat64Array, t_min: float, t_max: float, into: PackedFloat64Array, exits: bool) -> int:
	var count := 0
	var last := xs.size() - 1
	if last < 1: return 0
	var ax := xs[0]
	var ay := ys[0]
	var sa := ddx * (ay - oy) - ddy * (ax - ox) >= 0.0
	for i in last:
		var bx := xs[i + 1]
		var by := ys[i + 1]
		var sb := ddx * (by - oy) - ddy * (bx - ox) >= 0.0
		if sa != sb:
			var ex := bx - ax
			var ey := by - ay
			var den := ddx * ey - ddy * ex
			if absf(den) >= 1e-15:
				var q := ((ax - ox) * ey - (ay - oy) * ex) / den
				if q >= t_min and q <= t_max and count < MAX_CROSS:
					into[count] = q
					if exits: _cross_exit[count] = 1 if ddx * ey - ddy * ex < 0.0 else 0
					count += 1
		ax = bx
		ay = by
		sa = sb
	return count


# The inner surface along a ray of the mouth's fan, which starts inside the tongue: the gap begins where
# the ray leaves it (or at the surface behind, if the tongue has moved off the origin), and tissue the ray
# passes through on the way to the roof is taken out by its thickness.
func _fan_inner(ox: float, oy: float, ddx: float, ddy: float, t_out: float) -> float:
	var k := _k
	var count := _ray(ox, oy, ddx, ddy, _inn_x, _inn_y, 0.0, t_out + 1.5 * k, _cross_t, true)
	for i in range(1, count):
		var q := _cross_t[i]
		var e := _cross_exit[i]
		var jj := i - 1
		while jj >= 0 and _cross_t[jj] > q:
			_cross_t[jj + 1] = _cross_t[jj]
			_cross_exit[jj + 1] = _cross_exit[jj]
			jj -= 1
		_cross_t[jj + 1] = q
		_cross_exit[jj + 1] = e
	var t_in := 0.0
	var i := 0
	if count > 0 and _cross_exit[0] == 1:
		t_in = _cross_t[0]
		i = 1
	else:
		var back := 2.5 * k
		var n_back := _ray(ox, oy, -ddx, -ddy, _inn_x, _inn_y, 0.0, back, _tmp, false)
		var tb := back
		for q in n_back: tb = minf(tb, _tmp[q])
		t_in = -tb
	var tissue := 0.0
	while i < count and _cross_t[i] < t_out:
		if _cross_exit[i] == 1:
			i += 1
			continue
		var bb := _cross_t[i + 1] if i + 1 < count else t_out + 1.5 * k
		tissue += minf(bb, t_out) - _cross_t[i]
		i += 2
	return t_in + tissue


# Walk from o along d: the last inner crossing before the first outer crossing. False if the ray meets
# no outer wall. `fan`: a ray of the mouth's fan.
func _measure(ox: float, oy: float, ddx: float, ddy: float, max_len: float, fan: bool) -> bool:
	var k := _k
	var n_out := _ray(ox, oy, ddx, ddy, _out_x, _out_y, 0.0, max_len, _tmp, false)
	if n_out == 0: return false
	var t_out := INF
	for i in n_out: t_out = minf(t_out, _tmp[i])
	var t_in := 0.0
	if fan:
		t_in = _fan_inner(ox, oy, ddx, ddy, t_out)
	else:
		var n_in := _ray(ox, oy, ddx, ddy, _inn_x, _inn_y, 0.0, t_out + 1.5 * k, _tmp, false)
		t_in = -INF
		for i in n_in:
			if _tmp[i] > t_in and _tmp[i] < t_out + 1.5 * k: t_in = _tmp[i]
		if t_in == -INF: t_in = maxf(0.0, t_out - 3.5 * k)
	_m_d = maxf(0.0, t_out - t_in)
	var q := minf(t_in, t_out)
	_m_in_x = ox + ddx * q
	_m_in_y = oy + ddy * q
	_m_out_x = ox + ddx * t_out
	_m_out_y = oy + ddy * t_out
	return true


func _push_sample(region: int) -> void:
	g_in_x.append(_m_in_x)
	g_in_y.append(_m_in_y)
	g_out_x.append(_m_out_x)
	g_out_y.append(_m_out_y)
	g_mid_x.append(_m_in_x + (_m_out_x - _m_in_x) * 0.5)
	g_mid_y.append(_m_in_y + (_m_out_y - _m_in_y) * 0.5)
	g_d.append(_m_d)
	g_area.append(0.0)
	g_s.append(0.0)
	g_ray.append(_m_d)
	g_region.append(region)


# A point projected onto a line of points: how far along, how far off, and the side (negative = in the wall).
func _project(xs: PackedFloat64Array, ys: PackedFloat64Array, cum: PackedFloat64Array, px: float, py: float) -> void:
	var best := INF
	var bs := 0.0
	var sgn := 1.0
	var bseg := 0
	for i in xs.size() - 1:
		var ax := xs[i]
		var ay := ys[i]
		var ex := xs[i + 1] - ax
		var ey := ys[i + 1] - ay
		var l2 := ex * ex + ey * ey
		if l2 < 1e-12: continue
		var q := ((px - ax) * ex + (py - ay) * ey) / l2
		if q < 0.0: q = 0.0
		elif q > 1.0: q = 1.0
		var qx := ax + ex * q
		var qy := ay + ey * q
		var d := sqrt((px - qx) * (px - qx) + (py - qy) * (py - qy))
		if d < best:
			best = d
			bs = cum[i] + q * sqrt(l2)
			sgn = 1.0 if ex * (py - ay) - ey * (px - ax) < 0.0 else -1.0
			bseg = i
	_pr_s = bs
	_pr_dist = best
	_pr_signed = sgn * best
	_pr_seg = bseg


# Distance from a point to a closed outline (its last point repeats its first), negative inside.
func _signed_gap(xs: PackedFloat64Array, ys: PackedFloat64Array, px: float, py: float) -> float:
	var best := INF
	var inside := false
	var ax := xs[0]
	var ay := ys[0]
	for i in xs.size() - 1:
		var bx := xs[i + 1]
		var by := ys[i + 1]
		var ex := bx - ax
		var ey := by - ay
		var l2 := ex * ex + ey * ey
		var q := ((px - ax) * ex + (py - ay) * ey) / l2 if l2 > 1e-12 else 0.0
		if q < 0.0: q = 0.0
		elif q > 1.0: q = 1.0
		var ddx := px - ax - ex * q
		var ddy := py - ay - ey * q
		var d2 := ddx * ddx + ddy * ddy
		if d2 < best: best = d2
		if (ay > py) != (by > py) and px < ax + ((py - ay) * ex) / ey: inside = not inside
		ax = bx
		ay = by
	var d := sqrt(best)
	return -d if inside else d


# Closest approach of tissue points to the roof, and the roof's inward normal there.
func _closest_approach(pxs: PackedFloat64Array, pys: PackedFloat64Array) -> void:
	var d := INF
	var seg := 0
	for i in pxs.size():
		_project(_roof_x, _roof_y, _cum, pxs[i], pys[i])
		if _pr_signed < d:
			d = _pr_signed
			seg = _pr_seg
	var ex := _roof_x[seg + 1] - _roof_x[seg]
	var ey := _roof_y[seg + 1] - _roof_y[seg]
	var l := sqrt(ex * ex + ey * ey)
	if l == 0.0 or is_nan(l): l = 1.0
	_ca_d = d
	_ca_nx = ey / l
	_ca_ny = -ex / l


static func _append(xs: PackedFloat64Array, ys: PackedFloat64Array, fx: PackedFloat64Array, fy: PackedFloat64Array, from: int) -> void:
	for i in range(from, fx.size()):
		xs.append(fx[i])
		ys.append(fy[i])


## The walls and the grid of gaps and areas for a posture (17 numbers, in NAMES order).
func compute(a: PackedFloat64Array) -> void:
	var k := _k
	var lar := a[LARYNX] * k
	var glottis_y := _py(0.0) + lar

	# ---- jaw, turned about the condyle
	var jrx := _con_x - _px(6.95)
	var jry := _con_y - _py(7.75)
	var jaw_r := sqrt(jrx * jrx + jry * jry)
	var phi := -clampf(a[JAW], -0.2, 3.0) * k / jaw_r
	_jaw_sin = sin(phi)
	_jaw_cos = cos(phi)

	# ---- velum: a flap from the back of the hard palate, its angle from the port's area
	var v_open := clampf(a[VELUM] / 1.2, 0.0, 1.0)
	var v_ang := (194.0 + 46.0 * v_open) * DEG
	var v_len := 2.8 * k
	_vo_x.clear()
	_vo_y.clear()
	var nrm_x := -sin(v_ang)
	var nrm_y := cos(v_ang)
	for i in 11:
		var s := float(i) / 10.0
		var sag := sin(s * PI) * k * (0.3 * v_open - 0.12)
		var cx := _pns_x + v_len * s * cos(v_ang)
		var cy := _pns_y + v_len * s * sin(v_ang) + (-sag)
		var th := (0.48 - 0.2 * s) * k
		_vo_x.append(cx + nrm_x * th)
		_vo_y.append(cy + nrm_y * th)
	var pal0_x := _pal_x[0]
	var pal0_y := _pal_y[0]
	for i in 11:
		var w := float(i) / 10.0 / 0.35
		if w < 1.0:
			var q := (1.0 - w) * (1.0 - w)
			_vo_x[i] = _vo_x[i] + (pal0_x - _vo_x[i]) * q
			_vo_y[i] = _vo_y[i] + (pal0_y - _vo_y[i]) * q

	# ---- outer wall: back of the throat up to just under the uvula, the velum's oral face, the palate,
	# the upper teeth, the upper lip
	_out_x.clear()
	_out_y.clear()
	var uv_y := _vo_y[10] - 0.3 * k
	for i in _wall_x.size():
		var wy := _wall_y[i]
		if wy < uv_y:
			_out_x.append(_wall_x[i])
			_out_y.append(wy)
			continue
		if i > 0:
			var ax := _wall_x[i - 1]
			var ay := _wall_y[i - 1]
			var q := clampf((uv_y - ay) / maxf(1e-9, wy - ay), 0.0, 1.0)
			_out_x.append(ax + (_wall_x[i] - ax) * q)
			_out_y.append(ay + (wy - ay) * q)
		break
	var roof_start := _out_x.size()
	for i in range(10, -1, -1):
		_out_x.append(_vo_x[i])
		_out_y.append(_vo_y[i])
	_append(_out_x, _out_y, _pal_x, _pal_y, 1)
	var roof_end := _out_x.size() - 1
	var prot := clampf(a[LIP_PROT], -0.2, 1.6) * k
	var spread_w := clampf(a[LIP_WIDTH], 0.0, 1.0)
	var y_mid := (7.85 - 0.3 * a[JAW]) * k
	var lab := clampf(a[LABIODENTAL], 0.0, 1.0)
	var ap := a[LIP_AP] * k
	var lip_front_x := _px(8.15 + 0.12 * (1.0 - spread_w)) + prot * 0.95
	var ule_x := lip_front_x - 0.15 * k
	var ule_y := y_mid + ap * 0.35 + lab * 0.35 * k
	var lle_x := lip_front_x - 0.25 * k
	var lle_y := y_mid - ap * 0.65
	var inc_x := _pal_x[_pal_x.size() - 1]
	var inc_y := _pal_y[_pal_y.size() - 1]
	if lab > 0.0:
		# the lower lip tucks under the upper teeth for f and v
		var tx := inc_x + 0.05 * k
		var ty := inc_y - maxf(a[LIP_AP] * k, -0.1)
		lle_x = lle_x + (tx - lle_x) * lab
		lle_y = lle_y + (ty - lle_y) * lab
		var q := lab * 0.7
		ule_x = ule_x + ((inc_x + 0.55 * k) - ule_x) * q
		ule_y = ule_y + ((inc_y + 0.45 * k) - ule_y) * q
	var ulb_x := _px(7.32)
	var ulb_y := _py(8.35)
	_bezier3(ulb_x, ulb_y, ulb_x + (0.3 * k + prot * 0.4), ulb_y + 0.05 * k, ule_x + (-0.35 * k), ule_y + 0.12 * k, ule_x, ule_y, 7, _ul_x, _ul_y)
	_append(_out_x, _out_y, _ul_x, _ul_y, 0)

	# ---- tongue
	var r := tongue_radius * k
	var bx := _px(a[TB_X])
	var by := _py(a[TB_Y])
	var b0x := _px(NEUTRAL[TB_X])
	var b0y := _py(NEUTRAL[TB_Y])
	var val_x := _px(0.75) + (0.45 * (bx - b0x) + a[ROOT] * k)
	var val_y := _py(3.3) + (0.3 * (by - b0y) + 0.55 * lar)
	var epb_x := _px(0.3) + 0.0
	var epb_y := _py(2.4) + lar
	var ept_x := _px(0.0) + 0.35 * (val_x - 0.75 * k)
	var ept_y := _py(4.5) + (lar * 0.8 + 0.15 * (by - b0y))
	var th_b := 200.0 * DEG
	var pb_x := bx + r * cos(th_b)
	var pb_y := by + r * sin(th_b)
	var tanb_x := sin(th_b)
	var tanb_y := -cos(th_b)
	var h_r := sqrt((val_x - pb_x) * (val_x - pb_x) + (val_y - pb_y) * (val_y - pb_y)) / 3.0
	_bezier3(val_x, val_y, val_x + 0.08 * k, val_y + h_r, pb_x - tanb_x * h_r, pb_y - tanb_y * h_r, pb_x, pb_y, 9, _root_x, _root_y)
	var tx0 := _px(a[TT_X])
	var ty0 := _py(a[TT_Y])
	# keep the tip outside the body's circle
	var d_t := sqrt((tx0 - bx) * (tx0 - bx) + (ty0 - by) * (ty0 - by))
	if d_t < r * 1.05:
		var nx := tx0 - bx
		var ny := ty0 - by
		var nl := sqrt(nx * nx + ny * ny)
		if nl == 0.0 or is_nan(nl): nl = 1.0
		tx0 = bx + (nx / nl) * (r * 1.05)
		ty0 = by + (ny / nl) * (r * 1.05)
	var th_f := 0.0
	var d_tip := sqrt((bx - tx0) * (bx - tx0) + (by - ty0) * (by - ty0))
	if d_tip <= r * 1.0001: th_f = atan2(ty0 - by, tx0 - bx)
	else: th_f = atan2(ty0 - by, tx0 - bx) + acos(r / d_tip)
	while th_f > th_b: th_f -= 2.0 * PI
	while th_f < th_b - 2.0 * PI: th_f += 2.0 * PI
	_arc_x.clear()
	_arc_y.clear()
	for i in ARC_POINTS:
		var ang := th_b + ((th_f - th_b) * float(i)) / (float(ARC_POINTS) - 1.0)
		_arc_x.append(bx + r * cos(ang))
		_arc_y.append(by + r * sin(ang))
	var pf_x := _arc_x[ARC_POINTS - 1]
	var pf_y := _arc_y[ARC_POINTS - 1]
	var tanf_x := sin(th_f)
	var tanf_y := -cos(th_f)
	var bl := sqrt((pf_x - tx0) * (pf_x - tx0) + (pf_y - ty0) * (pf_y - ty0))
	var curl := clampf(a[TT_CURL], 0.0, 1.0)
	var ctrl_x := (pf_x + tanf_x * (bl * 0.5)) + 0.0
	var ctrl_y := (pf_y + tanf_y * (bl * 0.5)) + (0.18 + 0.5 * curl) * k
	_bezier2(pf_x, pf_y, ctrl_x, ctrl_y, tx0, ty0, 7, _blade_x, _blade_y)
	if a[DORSUM] > 0.0:
		# hollow the tongue between the back contact and the tip (clicks)
		var span := maxf(1e-6, tx0 - bx)
		for i in ARC_POINTS:
			var w := (_arc_x[i] - bx) / span
			if w > 0.0 and w < 1.0:
				var q := sin(PI * pow(w, 0.8))
				_arc_y[i] = _arc_y[i] + (-a[DORSUM] * 0.9 * k * q * q)
		for i in range(1, _blade_x.size() - 1):
			var w := (_blade_x[i] - bx) / span
			if w > 0.0 and w < 1.0:
				var q := sin(PI * pow(w, 0.8))
				_blade_y[i] = _blade_y[i] + (-a[DORSUM] * 0.9 * k * q * q)
	# the underside back to the floor of the mouth, which the jaw carries
	var fren_x := _jx(5.7, 6.15)
	var fren_y := _jy(5.7, 6.15)
	_bezier2(tx0, ty0, tx0 + (-0.3 * k - curl * 0.4 * k), ty0 + (-0.6 * k), fren_x, fren_y, 6, _under_x, _under_y)
	_floor_x = PackedFloat64Array([fren_x, _jx(6.2, 6.25), _jx(6.45, 6.55)])
	_floor_y = PackedFloat64Array([fren_y, _jy(6.2, 6.25), _jy(6.45, 6.55)])
	_lt_x = PackedFloat64Array([_jx(6.45, 6.55), _jx(6.72, 7.15), _jx(6.95, 7.75), _jx(7.12, 7.45)])
	_lt_y = PackedFloat64Array([_jy(6.45, 6.55), _jy(6.72, 7.15), _jy(6.95, 7.75), _jy(7.12, 7.45)])
	var llb_x := _jx(7.12, 7.45)
	var llb_y := _jy(7.12, 7.45)
	_bezier3(llb_x, llb_y, llb_x + (0.25 * k + prot * 0.3), llb_y + (-0.05 * k), lle_x + (-0.3 * k), lle_y + (-0.12 * k), lle_x, lle_y, 7, _ll_x, _ll_y)

	# the inner wall the sound meets: the epiglottis, then the tongue's back from where it first rises
	# above the epiglottis's tip
	_inn_x.clear()
	_inn_y.clear()
	_inn_x.append(epb_x)
	_inn_y.append(epb_y)
	_inn_x.append(ept_x)
	_inn_y.append(ept_y)
	var y_root := ept_y + 0.05 * k
	_back_x.clear()
	_back_y.clear()
	_append(_back_x, _back_y, _root_x, _root_y, 0)
	_append(_back_x, _back_y, _arc_x, _arc_y, 1)
	var root_len := _root_x.size()
	var start := _back_x.size() - 1
	for s in _back_x.size():
		if _back_y[s] > y_root:
			if s > 0:
				var ay := _back_y[s - 1]
				var q := clampf((y_root - ay) / maxf(1e-9, _back_y[s] - ay), 0.0, 1.0)
				_inn_x.append(_back_x[s - 1] + (_back_x[s] - _back_x[s - 1]) * q)
				_inn_y.append(ay + (_back_y[s] - ay) * q)
			start = s
			break
	if start < root_len:
		_append(_inn_x, _inn_y, _root_x, _root_y, start)
		_append(_inn_x, _inn_y, _arc_x, _arc_y, 1)
	else:
		# the rest of the arc, less its first point (as the engine's append with skip_first does)
		_append(_inn_x, _inn_y, _arc_x, _arc_y, start - root_len + 2)
	_append(_inn_x, _inn_y, _blade_x, _blade_y, 1)
	_append(_inn_x, _inn_y, _under_x, _under_y, 1)
	_append(_inn_x, _inn_y, _floor_x, _floor_y, 1)
	_append(_inn_x, _inn_y, _lt_x, _lt_y, 1)
	_append(_inn_x, _inn_y, _ll_x, _ll_y, 0)

	# ---- the grid
	g_in_x.clear()
	g_in_y.clear()
	g_out_x.clear()
	g_out_y.clear()
	g_mid_x.clear()
	g_mid_y.clear()
	g_d.clear()
	g_area.clear()
	g_s.clear()
	g_ray.clear()
	g_region.clear()
	var y_epi_top := glottis_y + 2.4 * k * pharynx
	var y_phar_top := _c1_y
	var n_ph := 12
	var split := -1
	for i in n_ph:
		var y := lerpf(y_epi_top + 0.12 * k, y_phar_top, float(i) / float(n_ph))
		if _measure(4.6 * k, y, -1.0, 0.0, 9.0 * k, false): _push_sample(1)
	# the mouth: rays from a centre that glides forward while the angle sweeps back, up, forward
	for i in 31:
		var q := float(i) / 30.0
		var ang := lerpf(180.0, 36.0, q) * DEG
		var w := 0.0 if q < 0.45 else (q - 0.45) / 0.55
		var e := w * w * (3.0 - 2.0 * w)
		var cx := _c1_x + (_c2_x - _c1_x) * e
		var cy := _c1_y + (_c2_y - _c1_y) * e
		if not _measure(cx, cy, cos(ang), sin(ang), 8.0 * k, true): continue
		if split < 0 and ang <= 150.0 * DEG: split = g_d.size()
		_push_sample(1 if split < 0 else 2)
	# the front: upright lines from the upper teeth's edge to the lips' opening
	var x_start := inc_x + 0.03 * k
	var x_end := maxf(x_start + 0.3 * k, minf(ule_x, lle_x) - 0.04 * k)
	var teeth_idx := g_d.size()
	for i in 6:
		var x := lerpf(x_start, x_end, float(i) / 5.0)
		if _measure(x, 4.0 * k, 0.0, 1.0, 8.0 * k, false):
			if x > lle_x:
				var face := minf(lle_y - (x - lle_x) * 4.0 / 3.0, _m_out_y)
				var open := _ss(LAB_FRONT_OPENS, 1.0, lab) * _ss(0.0, LAB_FRONT_RAMP * k, x - lle_x)
				var y_in := lerpf(face, _m_out_y - 3.5 * k, open)
				_m_in_x = x
				_m_in_y = y_in
				_m_d = _m_out_y - y_in
			_push_sample(3)
	split_index = split
	var count := g_d.size()
	var lip_w := (1.1 + (lip_width - 1.1) * spread_w) * k

	# ---- soft contact: near the roof, the gap at each roof point is its distance to the tongue itself
	_roof_x = _out_x.slice(roof_start, roof_end + 1)
	_roof_y = _out_y.slice(roof_start, roof_end + 1)
	_cum.resize(_roof_x.size())
	_cum[0] = 0.0
	for i in range(1, _roof_x.size()):
		var ex := _roof_x[i] - _roof_x[i - 1]
		var ey := _roof_y[i] - _roof_y[i - 1]
		_cum[i] = _cum[i - 1] + sqrt(ex * ex + ey * ey)
	_tipp_x.clear()
	_tipp_y.clear()
	_append(_tipp_x, _tipp_y, _blade_x, _blade_y, 2)
	_tipp_x.append(_under_x[1])
	_tipp_y.append(_under_y[1])
	_tipp_x.append(_under_x[2])
	_tipp_y.append(_under_y[2])
	_closest_approach(_tipp_x, _tipp_y)
	contact_tip = _ca_d
	contact_tip_nx = _ca_nx
	contact_tip_ny = _ca_ny
	_closest_approach(_arc_x, _arc_y)
	contact_body = _ca_d
	contact_body_nx = _ca_nx
	contact_body_ny = _ca_ny
	_outl_x.clear()
	_outl_y.clear()
	_append(_outl_x, _outl_y, _root_x, _root_y, 0)
	_append(_outl_x, _outl_y, _arc_x, _arc_y, 1)
	_append(_outl_x, _outl_y, _blade_x, _blade_y, 1)
	_append(_outl_x, _outl_y, _under_x, _under_y, 1)
	_append(_outl_x, _outl_y, _floor_x, _floor_y, 1)
	_outl_x.append(_root_x[0])
	_outl_y.append(_root_y[0])
	var press := 1.0 - _ss(-0.06 * k, 0.0, minf(contact_tip, contact_body))
	var half := 0.1 * k * (1.0 + press)
	var roof_len := _cum[_cum.size() - 1]
	var fractions: Array[float] = [-1.0, -0.5, 0.5, 1.0]
	for g in count:
		if g_region[g] == 0: continue
		var ox := g_out_x[g]
		var oy := g_out_y[g]
		_project(_roof_x, _roof_y, _cum, ox, oy)
		var pr_s := _pr_s
		var pr_dist := _pr_dist
		var on_roof := 1.0 - _ss(0.15 * k, 0.25 * k, pr_dist)
		if on_roof <= 0.0: continue
		var dc := _signed_gap(_outl_x, _outl_y, ox, oy)
		if dc - half - pr_dist <= 0.6 * k:
			for fr in fractions:
				# the point at that length along the roof
				var s := clampf(pr_s + fr * half, 0.0, roof_len)
				var i := 0
				while i + 2 < _cum.size() and _cum[i + 1] < s: i += 1
				var l := _cum[i + 1] - _cum[i]
				var w := clampf((s - _cum[i]) / l, 0.0, 1.0) if l > 1e-9 else 0.0
				dc = minf(dc, _signed_gap(_outl_x, _outl_y, _roof_x[i] + (_roof_x[i + 1] - _roof_x[i]) * w, _roof_y[i] + (_roof_y[i + 1] - _roof_y[i]) * w))
		var w2 := (1.0 - _ss(0.15 * k, 0.6 * k, dc)) * on_roof
		var cap := (1.0 - _ss(0.45 * k, 0.6 * k, dc)) * on_roof
		if w2 <= 0.0 and cap <= 0.0: continue
		var dp := maxf(0.0, dc)
		var dm := g_d[g] + (minf(g_d[g], dp) - g_d[g]) * cap
		g_d[g] = dm + (dp - dm) * w2

	# the lips: between them the gap follows the aperture back from the edge, so pressed lips seal over a length
	var edge_x := minf(ule_x, lle_x)
	var rl := 0.6 * k
	var lab_open := _ss(0.0, LAB_HANDOVER, lab)
	var ap_eff := INF if lab_open >= 1.0 else ap + LAB_GAP * k * lab_open / (1.0 - lab_open)
	for g in count:
		if g_region[g] != 3 or g_mid_x[g] < inc_x: continue
		var dxl := maxf(0.0, edge_x - g_mid_x[g])
		g_d[g] = minf(g_d[g], maxf(0.0, ap_eff + (dxl * dxl) / (2.0 * rl)))

	# ---- areas
	var a_p: float = law_pharynx[0]
	var b_p: float = law_pharynx[1]
	var a_o: float = law_oral[0]
	var b_o: float = law_oral[1]
	var a_f: float = law_front[0]
	var b_f: float = law_front[1]
	var a_h: float = law_ahead[0]
	var b_h: float = law_ahead[1]
	for g in count:
		var d := g_d[g]
		var region := g_region[g]
		if region == 1:
			g_area[g] = a_p * pow(d, b_p)
		elif region == 2:
			var ahead := _ss(0.0, 0.4 * k, g_mid_x[g] - tx0)
			g_area[g] = lerpf(a_o * pow(d, b_o), a_h * pow(d, b_h), ahead)
		else:
			var w := clampf((g_mid_x[g] - inc_x) / (0.45 * k), 0.0, 1.0)
			g_area[g] = lerpf(a_f * pow(d, b_f), (PI / 4.0) * d * lip_w, w)
	# take out lone spikes: no open sample above 1.35 times the larger of its neighbours
	for i in range(1, count - 1):
		var lim := 1.35 * maxf(g_area[i - 1], g_area[i + 1])
		if g_area[i] > lim: g_area[i] = lim
	# a side channel round a midline closure of the tip (l)
	if a[LATERAL] > 0.0:
		for g in count:
			if g_region[g] >= 2:
				var ex := g_mid_x[g] - tx0
				var ey := g_mid_y[g] - ty0
				if sqrt(ex * ex + ey * ey) < 1.4 * k: g_area[g] = maxf(g_area[g], a[LATERAL] * 0.35 * k * k)

	# ---- distance along the middle of the passage
	var s_along := 2.4 * k * pharynx
	for i in count:
		if i > 0:
			var ex := g_mid_x[i] - g_mid_x[i - 1]
			var ey := g_mid_y[i] - g_mid_y[i - 1]
			s_along += sqrt(ex * ex + ey * ey)
		g_s[i] = s_along
	var last := count - 1
	teeth_s = g_s[teeth_idx] if teeth_idx < count else g_s[last]
	lip_s = g_s[last]
	pharynx_length = g_s[split] if split > 0 else g_s[n_ph]
	length = lip_s
	lip_area = g_area[last]
	velum_port = maxf(0.0, a[VELUM]) * k * k
	tip_x = tx0
	tip_y = ty0


func _epi_shape(x: float, vent: float, top: float) -> float:
	if x < 0.3: return 1.3
	if x < 0.5: return vent
	return lerpf(1.2, top, (x - 0.5) / 0.5)


## The short tube above the glottis: its area at s in [0, epi_len].
func epilarynx_area(a: PackedFloat64Array, s: float, epi_len: float) -> float:
	var w := s / epi_len
	var vent := 0.95 * (1.0 - 0.75 * clampf(a[VENTRICULAR], 0.0, 1.0))
	var top := lerpf(1.9, 0.35, clampf(a[EPILARYNX], 0.0, 1.0))
	var ramp := 0.03
	var result := _epi_shape(w, vent, top)
	if absf(w - 0.3) < ramp: result = lerpf(_epi_shape(0.3 - ramp, vent, top), _epi_shape(0.3 + ramp, vent, top), (w - (0.3 - ramp)) / (2.0 * ramp))
	if absf(w - 0.5) < ramp: result = lerpf(_epi_shape(0.5 - ramp, vent, top), _epi_shape(0.5 + ramp, vent, top), (w - (0.5 - ramp)) / (2.0 * ramp))
	return result * _k * _k


func _area_at(a: PackedFloat64Array, s: float, epi_len: float, flare: float) -> float:
	if s <= epi_len - flare: return epilarynx_area(a, s, epi_len)
	if s <= epi_len: return lerpf(epilarynx_area(a, s, epi_len), g_area[0], (s - (epi_len - flare)) / flare)
	if s <= g_s[0]: return g_area[0]
	var lo := 0
	var hi := g_s.size() - 1
	if s >= g_s[hi]: return g_area[hi]
	while hi - lo > 1:
		var m := (lo + hi) >> 1
		if g_s[m] <= s: lo = m
		else: hi = m
	var q := (s - g_s[lo]) / maxf(1e-9, g_s[hi] - g_s[lo])
	return lerpf(g_area[lo], g_area[hi], q)


func _fill(a: PackedFloat64Array, s0: float, s1: float, into: PackedFloat64Array, mins: PackedFloat64Array, epi_len: float, flare: float) -> void:
	var n := into.size()
	var d := (s1 - s0) / float(n)
	var gi := 0
	var count := g_s.size()
	for i in n:
		var inv := 0.0
		var closed := false
		var mn := INF
		for jj in 8:
			var area_here := _area_at(a, s0 + d * (float(i) + (float(jj) + 0.5) / 8.0), epi_len, flare)
			if area_here < mn: mn = area_here
			if area_here <= 1e-5:
				closed = true
				break
			inv += 1.0 / area_here
		# the grid's own samples inside the section: a closure at a point must seal the section
		var a0 := s0 + d * float(i)
		var a1 := s0 + d * (float(i) + 1.0) + (1e-6 if i == n - 1 else 0.0)
		while gi < count and g_s[gi] < a0: gi += 1
		var q := gi
		while q < count and g_s[q] <= a1:
			if g_area[q] < mn: mn = g_area[q]
			if g_area[q] <= 1e-5: closed = true
			q += 1
		into[i] = 0.0 if closed else 8.0 / inv
		mins[i] = 0.0 if closed else minf(mn, into[i])


## The passage as two tubes of equal sections (throat: glottis to velum; mouth: velum to lips), each
## section the harmonic mean of the area along it, with the narrowest point of each beside it. Returns
## [throat length, mouth length].
func resample(a: PackedFloat64Array, out_ph: PackedFloat64Array, out_or: PackedFloat64Array, min_ph: PackedFloat64Array, min_or: PackedFloat64Array) -> PackedFloat64Array:
	var epi_len := 2.4 * _k * pharynx
	var flare := 0.1 * epi_len
	var sp := pharynx_length
	_fill(a, 0.0, sp, out_ph, min_ph, epi_len, flare)
	_fill(a, sp, lip_s, out_or, min_or, epi_len, flare)
	return PackedFloat64Array([sp, lip_s - sp])
