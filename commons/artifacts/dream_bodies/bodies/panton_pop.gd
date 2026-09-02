extends RefCounted

## dream_bodies / panton_pop — one glossy moulded pop body: a Panton-chair S
## stood up and treated as a figure.
##
## Reference: scratchpad/refs/panton.png (2048x536 panorama) — a garden crowd of
## Verner Panton furniture behaving like people. A hot-magenta figure sits with a
## huge round void punched through the loop of its arm; a green shell is drilled
## with big gold-lined ovals; pale pink cantilever shells are combed with ripple
## ribs; a green honeycomb lattice cone stands at the right. Everything is
## high-gloss moulded plastic against dark planting.
##
## Reproduced, and how:
##   1. The Panton S — ONE continuous swept ribbon: a flat sled foot on the floor,
##      a half turn up and over into the seat, a dip, then the back rising and
##      leaning away with the top curling forward again. The spine is integrated
##      from a keyed tangent angle, so the whole silhouette is one gesture.
##   2. A THICK shell, not a sheet — the ribbon is a 40-56 mm slab: outer face,
##      inner face and rim walls, all from one SurfaceTool grid (104 x 24 cells)
##      with generate_normals(), flat smooth-group on the walls for a crisp edge.
##   3. Big oval HOLES — 3..7 ellipses in (length, width) parameter space; every
##      quad whose centre lands inside one is skipped and the exposed edges close
##      themselves with a wall. Hole walls go to a SECOND surface in the lining
##      colour, so the pierced edges read gold / cream / pale like the reference.
##   4. The dish — each cross section is cambered along the surface normal:
##      crowned on the sled, a stiffening channel at the waist, cupped through the
##      seat and the back. That is what makes it a shell and not a strap.
##   5. Ripple ribs and a rolled edge — rows of beads riding proud of the concave
##      face (fat on the pale-pink scheme, faint quilting elsewhere) and two bead
##      chains down both long edges, the moulded lip that stops a Panton shell
##      looking cut out of card.
##   6. Head-ball, collar and chin nub on top of the back, and by seed a smaller
##      companion head on a stalk beside it — the second ball in the reference.
##   7. One thick LIMB LOOP — a cubic-Bezier arm from the shoulder out, forward
##      and down onto the seat lip, enclosing the big body void of the magenta
##      figure. Side, bulge and thickness are all seeded.
##   8. Colour by seed: hot magenta; mint with painted gold ovals; pale pink with
##      a ripple print; deep magenta with gold; leaf green with a honeycomb
##      lattice. Patterns are ImageTextures painted pixel by pixel and tiled over
##      the ribbon's own (u, length) coordinates; every material is clearcoated.
##
## Given up: the garden and the crowd (these bodies lean on each other), the
## woven-fabric figure, real openings in the honeycomb cone (printed, not
## pierced), and the soft subsurface glow the thin pink shells have on camera.

const TEX: int = 160
const NS: int = 104
const NU: int = 24

# scheme: [ground, ink, bead, lining, pattern kind]
const SCHEMES: Array = [
	["#D6199B", "#F2C63C", "#EC63BE", "#FFD9F0", 0],
	["#2FA173", "#E7B93A", "#E7B93A", "#F6E3B0", 1],
	["#F2C6C2", "#DCA0A0", "#FBE2DE", "#FFF1EC", 2],
	["#B71272", "#D9A82B", "#D9A82B", "#F6DFA8", 1],
	["#77BE86", "#3E8A57", "#B9E0BF", "#DFF2E0", 3],
]

const A_T: Array = [0.0, 0.22, 0.30, 0.42, 0.50, 0.62, 0.72, 0.84, 1.0]
const W_T: Array = [0.0, 0.20, 0.34, 0.50, 0.64, 0.78, 1.0]
const W_V: Array = [0.255, 0.275, 0.205, 0.300, 0.250, 0.215, 0.270]
const D_T: Array = [0.0, 0.22, 0.36, 0.50, 0.64, 0.80, 1.0]
const D_V: Array = [0.10, 0.14, 0.30, -0.30, -0.26, -0.30, -0.18]


static func describe() -> String:
	return "A glossy moulded pop body swept as one thick Panton S — floor sled, seat, leaning back — pierced by big ovals, ribbed and bead-edged, with a ball head and one thick arm loop around an empty middle."


static func build(root: Node3D, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# --- scheme -------------------------------------------------------------
	var si: int = rng.randi_range(0, SCHEMES.size() - 1)
	var sc: Array = SCHEMES[si]
	var col_ground: Color = _c(sc, 0)
	var col_ink: Color = _c(sc, 1)
	var col_bead: Color = _c(sc, 2)
	var col_line: Color = _c(sc, 3)
	var kind: int = int(sc[4])

	var tex: ImageTexture = _pattern(rng, kind, col_ground, col_ink)
	var uv_u: float = 2.0
	var uv_v: float = 6.0
	if kind == 1:
		uv_u = 2.0
		uv_v = 7.0
	elif kind == 2:
		uv_u = 1.0
		uv_v = 6.0
	elif kind == 3:
		uv_u = 2.5
		uv_v = 11.0

	var mat_shell := StandardMaterial3D.new()
	mat_shell.albedo_color = Color(1.0, 1.0, 1.0)
	mat_shell.albedo_texture = tex
	mat_shell.uv1_scale = Vector3(uv_u, uv_v, 1.0)
	mat_shell.roughness = 0.15
	mat_shell.metallic = 0.0
	mat_shell.clearcoat_enabled = true
	mat_shell.clearcoat = 0.95
	mat_shell.clearcoat_roughness = 0.05

	var mat_line: StandardMaterial3D = _gloss(col_line, 0.30, 0.55)
	var mat_body: StandardMaterial3D = _gloss(col_ground, 0.16, 0.95)
	var mat_bead: StandardMaterial3D = _gloss(col_bead, 0.18, 0.90)
	var mat_ink: StandardMaterial3D = _gloss(col_ink, 0.22, 0.80)
	var mat_head: StandardMaterial3D = _gloss(col_ground.lerp(col_bead, 0.25), 0.14, 1.0)

	# --- individual parameters ----------------------------------------------
	var arc: float = rng.randf_range(2.44, 2.76)
	var width_k: float = rng.randf_range(0.94, 1.14)
	var dish_k: float = rng.randf_range(0.85, 1.15)
	var ht: float = rng.randf_range(0.020, 0.028)
	var sway: float = rng.randf_range(-0.085, 0.085)
	var lean: float = rng.randf_range(-0.10, 0.10)
	var twist: float = deg_to_rad(rng.randf_range(-13.0, 13.0))
	var side: float = 1.0 if rng.randf() < 0.5 else -1.0
	var loop_k: float = rng.randf_range(0.88, 1.14)
	var n_loop: int = rng.randi_range(22, 28)
	var n_ribs: int = rng.randi_range(6, 11)
	var rib_r: float = 0.021 if kind == 2 else rng.randf_range(0.011, 0.015)
	var rim_step: int = rng.randi_range(5, 6)
	var head_r: float = rng.randf_range(0.134, 0.166)
	var has_twin: bool = rng.randf() < 0.5

	var a_v: Array = [
		0.0,
		0.0,
		deg_to_rad(rng.randf_range(48.0, 62.0)),
		deg_to_rad(rng.randf_range(142.0, 158.0)),
		deg_to_rad(rng.randf_range(190.0, 203.0)),
		deg_to_rad(rng.randf_range(177.0, 190.0)),
		deg_to_rad(rng.randf_range(123.0, 138.0)),
		deg_to_rad(rng.randf_range(97.0, 112.0)),
		deg_to_rad(rng.randf_range(74.0, 92.0)),
	]

	# --- spine: integrate the keyed tangent angle ---------------------------
	var ds_step: float = arc / float(NS)
	var pts: Array = []
	var cur := Vector3.ZERO
	pts.append(cur)
	for i in range(NS):
		var tm: float = (float(i) + 0.5) / float(NS)
		var ang: float = _key_lerp(tm, A_T, a_v)
		var d: Vector3 = Vector3(0.0, sin(ang), cos(ang))
		cur = cur + d * ds_step
		pts.append(cur)
	for i in range(NS + 1):
		var ti: float = float(i) / float(NS)
		var q: Vector3 = pts[i]
		var px: float = sway * sin(PI * ti) + lean * ti * ti * ti
		pts[i] = Vector3(px, q.y, q.z)

	# --- frames, half-widths, camber ----------------------------------------
	var tgs: Array = []
	var rts: Array = []
	var nrs: Array = []
	var hws: Array = []
	var dss: Array = []
	for i in range(NS + 1):
		var ti: float = float(i) / float(NS)
		var tg: Vector3 = _tangent(pts, i)
		var rt: Vector3 = Vector3.RIGHT - tg * tg.dot(Vector3.RIGHT)
		if rt.length() < 0.002:
			rt = Vector3.RIGHT
		rt = rt.normalized()
		var nr: Vector3 = tg.cross(rt).normalized()
		var tw: float = twist * ti * ti
		var bt := Basis(tg, tw)
		tgs.append(tg)
		rts.append((bt * rt).normalized())
		nrs.append((bt * nr).normalized())
		hws.append(_key_lerp(ti, W_T, W_V) * width_k)
		dss.append(_key_lerp(ti, D_T, D_V) * dish_k)

	# --- the big oval holes, in (length, width) parameter space --------------
	var n_holes: int = rng.randi_range(3, 7)
	var holes: Array = []
	var tries: int = 0
	while holes.size() < n_holes and tries < 260:
		tries += 1
		var hs: float = rng.randf_range(0.27, 0.93)
		var hu: float = rng.randf_range(-0.30, 0.30)
		var rs: float = rng.randf_range(0.040, 0.062)
		var ru: float = rng.randf_range(0.30, 0.50)
		if absf(hu) + ru > 0.82:
			continue
		if hs - rs < 0.235 or hs + rs > 0.965:
			continue
		var ok: bool = true
		for h in holes:
			var hh: Array = h
			var d_s: float = absf(hs - float(hh[0]))
			var d_u: float = absf(hu - float(hh[1]))
			if d_s < (rs + float(hh[2])) * 1.45 and d_u < (ru + float(hh[3])) * 1.20:
				ok = false
		if ok:
			holes.append([hs, hu, rs, ru])

	# --- mid surface, normals, the two faces --------------------------------
	var mids: Array = []
	for i in range(NS + 1):
		var row: Array = []
		var org: Vector3 = pts[i]
		var rt: Vector3 = rts[i]
		var nr: Vector3 = nrs[i]
		var hw: float = hws[i]
		var dsh: float = dss[i]
		for j in range(NU + 1):
			var uu: float = float(j) / float(NU) * 2.0 - 1.0
			row.append(org + rt * (uu * hw) + nr * (dsh * (uu * uu - 0.34) * hw))
		mids.append(row)

	var nms: Array = []
	for i in range(NS + 1):
		var row: Array = []
		var ia: int = maxi(i - 1, 0)
		var ib: int = mini(i + 1, NS)
		var fallback: Vector3 = nrs[i]
		for j in range(NU + 1):
			var ja: int = maxi(j - 1, 0)
			var jb: int = mini(j + 1, NU)
			var sa: Vector3 = mids[ia][j]
			var sb: Vector3 = mids[ib][j]
			var ua: Vector3 = mids[i][ja]
			var ub: Vector3 = mids[i][jb]
			var nn: Vector3 = (sb - sa).cross(ub - ua)
			if nn.length() < 0.000001:
				nn = fallback
			row.append(nn.normalized())
		nms.append(row)

	var top: Array = []
	var bot: Array = []
	for i in range(NS + 1):
		var rt_row: Array = []
		var rb_row: Array = []
		for j in range(NU + 1):
			var m: Vector3 = mids[i][j]
			var nn: Vector3 = nms[i][j]
			rt_row.append(m + nn * ht)
			rb_row.append(m - nn * ht)
		top.append(rt_row)
		bot.append(rb_row)

	var solid: Array = []
	for i in range(NS):
		var row: Array = []
		var ts: float = (float(i) + 0.5) / float(NS)
		for j in range(NU):
			var uu: float = (float(j) + 0.5) / float(NU) * 2.0 - 1.0
			row.append(not _in_hole(ts, uu, holes))
		solid.append(row)

	# --- the shell: faces in one surface, hole walls in another -------------
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var stw := SurfaceTool.new()
	stw.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wall_quads: int = 0
	for i in range(NS):
		for j in range(NU):
			if not bool(solid[i][j]):
				continue
			var t00: Vector3 = top[i][j]
			var t10: Vector3 = top[i + 1][j]
			var t11: Vector3 = top[i + 1][j + 1]
			var t01: Vector3 = top[i][j + 1]
			var b00: Vector3 = bot[i][j]
			var b10: Vector3 = bot[i + 1][j]
			var b11: Vector3 = bot[i + 1][j + 1]
			var b01: Vector3 = bot[i][j + 1]
			var u00: Vector2 = _uv(i, j)
			var u10: Vector2 = _uv(i + 1, j)
			var u11: Vector2 = _uv(i + 1, j + 1)
			var u01: Vector2 = _uv(i, j + 1)
			var n0: Vector3 = nms[i][j]
			var n1: Vector3 = nms[i + 1][j]
			var n2: Vector3 = nms[i + 1][j + 1]
			var n3: Vector3 = nms[i][j + 1]
			var navg: Vector3 = (n0 + n1 + n2 + n3).normalized()
			var mc: Vector3 = (t00 + t11 + b00 + b11) * 0.25
			_quad(st, t00, t10, t11, t01, u00, u10, u11, u01, navg, 0)
			_quad(st, b00, b10, b11, b01, u00, u10, u11, u01, -navg, 0)
			# four rim walls, wherever the neighbour is a hole or the ribbon ends
			for e in range(4):
				var open_hole: bool = false
				var open_edge: bool = false
				var ea: int = 0
				var eb: int = 0
				var fa: int = 0
				var fb: int = 0
				if e == 0:
					ea = i
					fa = j
					eb = i
					fb = j + 1
					if i == 0:
						open_edge = true
					elif not bool(solid[i - 1][j]):
						open_hole = true
				elif e == 1:
					ea = i + 1
					fa = j + 1
					eb = i + 1
					fb = j
					if i == NS - 1:
						open_edge = true
					elif not bool(solid[i + 1][j]):
						open_hole = true
				elif e == 2:
					ea = i + 1
					fa = j
					eb = i
					fb = j
					if j == 0:
						open_edge = true
					elif not bool(solid[i][j - 1]):
						open_hole = true
				else:
					ea = i
					fa = j + 1
					eb = i + 1
					fb = j + 1
					if j == NU - 1:
						open_edge = true
					elif not bool(solid[i][j + 1]):
						open_hole = true
				if not (open_hole or open_edge):
					continue
				var wa: Vector3 = top[ea][fa]
				var wb: Vector3 = top[eb][fb]
				var wc: Vector3 = bot[eb][fb]
				var wd: Vector3 = bot[ea][fa]
				var mid_e: Vector3 = (wa + wb + wc + wd) * 0.25
				var outw: Vector3 = mid_e - mc
				if outw.length() < 0.000001:
					outw = navg
				outw = outw.normalized()
				var qa: Vector2 = _uv(ea, fa)
				var qb: Vector2 = _uv(eb, fb)
				if open_hole:
					_quad(stw, wa, wb, wc, wd, qa, qb, qb, qa, outw, -1)
					wall_quads += 1
				else:
					_quad(st, wa, wb, wc, wd, qa, qb, qb, qa, outw, -1)
	st.generate_normals()
	_add(root, st.commit(), mat_shell)
	if wall_quads > 0:
		stw.generate_normals()
		_add(root, stw.commit(), mat_line)

	# --- the rolled edge: bead chains down both long sides -------------------
	var bead_r: float = ht * 1.30
	var i_b: int = 0
	while i_b <= NS:
		for j in [0, NU]:
			var jj: int = j
			var bp: Vector3 = mids[i_b][jj]
			var bs := SphereMesh.new()
			bs.radius = bead_r
			bs.height = bead_r * 2.0
			bs.radial_segments = 10
			bs.rings = 6
			var bm: MeshInstance3D = _add(root, bs, mat_bead)
			bm.transform = Transform3D(Basis(), bp)
		i_b += rim_step

	# --- ripple ribs across the concave face --------------------------------
	for k in range(n_ribs):
		var fk: float = float(k) / float(maxi(n_ribs - 1, 1))
		var tr: float = lerpf(0.265, 0.955, fk)
		var ir: int = clampi(int(round(tr * float(NS))), 0, NS)
		var rface: float = 1.0 if tr < 0.46 else -1.0
		for m in range(9):
			var fm: float = float(m) / 8.0
			var uu: float = lerpf(-0.72, 0.72, fm)
			if _in_hole(tr, uu, holes):
				continue
			var jr: int = clampi(int(round((uu + 1.0) * 0.5 * float(NU))), 0, NU)
			var nn: Vector3 = nms[ir][jr]
			var mp: Vector3 = mids[ir][jr]
			var bp: Vector3 = mp + nn * (rface * (ht + rib_r * 0.35))
			var rs_m := SphereMesh.new()
			rs_m.radius = rib_r
			rs_m.height = rib_r * 2.0
			rs_m.radial_segments = 10
			rs_m.rings = 6
			var rm: MeshInstance3D = _add(root, rs_m, mat_bead)
			rm.transform = Transform3D(Basis(), bp)

	# --- head ---------------------------------------------------------------
	var tg_top: Vector3 = tgs[NS]
	var nr_top: Vector3 = nrs[NS]
	var rt_top: Vector3 = rts[NS]
	var p_top: Vector3 = pts[NS]
	var head_c: Vector3 = p_top + tg_top * (head_r * 0.74) - nr_top * (head_r * 0.30)
	var hs_m := SphereMesh.new()
	hs_m.radius = head_r
	hs_m.height = head_r * 2.0
	hs_m.radial_segments = 24
	hs_m.rings = 14
	var hm: MeshInstance3D = _add(root, hs_m, mat_head)
	# columns must stay right-handed: nr = tg x rt, so the x column is negated
	hm.transform = Transform3D(Basis(-rt_top * 1.02, tg_top * 1.10, nr_top * 0.94), head_c)

	var col_m := SphereMesh.new()
	col_m.radius = head_r * 0.62
	col_m.height = head_r * 1.24
	col_m.radial_segments = 16
	col_m.rings = 10
	var cm: MeshInstance3D = _add(root, col_m, mat_head)
	cm.transform = Transform3D(Basis(), p_top - tg_top * (head_r * 0.10))

	_tube(root, p_top - tg_top * 0.05, head_c, head_r * 0.46, mat_head)

	var chin_m := SphereMesh.new()
	chin_m.radius = head_r * 0.44
	chin_m.height = head_r * 0.88
	chin_m.radial_segments = 14
	chin_m.rings = 9
	var chm: MeshInstance3D = _add(root, chin_m, mat_head)
	chm.transform = Transform3D(Basis(), head_c - nr_top * (head_r * 0.80) - tg_top * (head_r * 0.22))

	if has_twin:
		var i_tw: int = int(floor(float(NS) * 0.86))
		var j_tw: int = 0 if side > 0.0 else NU
		var base_tw: Vector3 = mids[i_tw][j_tw]
		var tg_tw: Vector3 = tgs[i_tw]
		var rt_tw: Vector3 = rts[i_tw]
		var top_tw: Vector3 = base_tw + tg_tw * 0.20 - rt_tw * (side * 0.06)
		_tube(root, base_tw, top_tw, head_r * 0.20, mat_head)
		var tw_m := SphereMesh.new()
		tw_m.radius = head_r * 0.56
		tw_m.height = head_r * 1.12
		tw_m.radial_segments = 18
		tw_m.rings = 11
		var twm: MeshInstance3D = _add(root, tw_m, mat_head)
		twm.transform = Transform3D(Basis(), top_tw + tg_tw * (head_r * 0.50))

	# --- one thick limb loop -------------------------------------------------
	var i_sh: int = int(floor(float(NS) * 0.90))
	var i_lp: int = int(floor(float(NS) * 0.455))
	var p_sh: Vector3 = pts[i_sh]
	var r_sh: Vector3 = rts[i_sh]
	var n_sh: Vector3 = nrs[i_sh]
	var p_lp: Vector3 = pts[i_lp]
	var r_lp: Vector3 = rts[i_lp]
	var p0: Vector3 = p_sh + r_sh * (side * float(hws[i_sh]) * 0.82) + n_sh * 0.02
	var p3: Vector3 = p_lp + r_lp * (side * float(hws[i_lp]) * 0.62)
	var fwd := Vector3(0.0, 0.0, 1.0)
	var p1: Vector3 = p0 + fwd * (0.30 * loop_k) + Vector3(side * 0.13, -0.10, 0.0)
	var p2: Vector3 = p3 + fwd * (0.25 * loop_k) + Vector3(side * 0.13, 0.42 * loop_k, 0.0)
	var prev: Vector3 = p0
	for i in range(1, n_loop + 1):
		var fl: float = float(i) / float(n_loop)
		var nxt: Vector3 = _bez(p0, p1, p2, p3, fl)
		var rr: float = 0.052 + 0.036 * sin(PI * fl)
		_tube(root, prev, nxt, rr, mat_body)
		prev = nxt
	var joint := SphereMesh.new()
	joint.radius = 0.062
	joint.height = 0.124
	joint.radial_segments = 14
	joint.rings = 9
	var jm: MeshInstance3D = _add(root, joint, mat_body)
	jm.transform = Transform3D(Basis(), p0)

	# --- glide pads under the sled ------------------------------------------
	var pad_spec: Array = [[4, 3], [4, NU - 3], [int(float(NS) * 0.19), int(float(NU) * 0.5)]]
	for s in pad_spec:
		var sp: Array = s
		var pi_i: int = int(sp[0])
		var pj_i: int = int(sp[1])
		var nn: Vector3 = nms[pi_i][pj_i]
		var pp: Vector3 = mids[pi_i][pj_i]
		var pad := SphereMesh.new()
		pad.radius = 0.056
		pad.height = 0.112
		pad.radial_segments = 14
		pad.rings = 8
		var pm: MeshInstance3D = _add(root, pad, mat_ink)
		var pr: Vector3 = rts[pi_i]
		var pn: Vector3 = nrs[pi_i]
		var pt_v: Vector3 = tgs[pi_i]
		var pb := Basis(pr, pn * 0.42, pt_v * 1.25)
		pm.transform = Transform3D(pb, pp - nn * (ht + 0.014))

	# --- settle: measure, fit the box, land on the floor, centre ------------
	var kids: Array = []
	for ch in root.get_children():
		if ch is MeshInstance3D:
			kids.append(ch)
	var box: AABB = _union(kids)
	var kmax: float = minf(1.2 / maxf(box.size.x, 0.001), minf(1.2 / maxf(box.size.z, 0.001), 1.68 / maxf(box.size.y, 0.001)))
	var kfit: float = minf(1.0, kmax)
	if box.size.y * kfit < 1.02:
		kfit = minf(kmax, 1.02 / maxf(box.size.y, 0.001))
	if absf(kfit - 1.0) > 0.001:
		for ch in kids:
			var cm2: MeshInstance3D = ch
			var tf: Transform3D = cm2.transform
			cm2.transform = Transform3D(tf.basis.scaled(Vector3(kfit, kfit, kfit)), tf.origin * kfit)
		box = _union(kids)
	var centre: Vector3 = box.position + box.size * 0.5
	var shift := Vector3(-centre.x, -box.position.y, -centre.z)
	for ch in kids:
		var cm3: MeshInstance3D = ch
		cm3.transform = Transform3D(cm3.transform.basis, cm3.transform.origin + shift)


# ---------------------------------------------------------------------------
# helpers

static func _c(sc: Array, i: int) -> Color:
	var code: String = sc[i]
	return Color(code)


static func _gloss(c: Color, rough: float, coat: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.0
	m.clearcoat_enabled = true
	m.clearcoat = coat
	m.clearcoat_roughness = 0.06
	return m


static func _add(root: Node3D, mesh: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


static func _uv(i: int, j: int) -> Vector2:
	return Vector2(float(j) / float(NU), float(i) / float(NS))


static func _key_lerp(t: float, ts: Array, vs: Array) -> float:
	var n: int = ts.size()
	if t <= float(ts[0]):
		return float(vs[0])
	for i in range(n - 1):
		var a: float = float(ts[i])
		var b: float = float(ts[i + 1])
		if t <= b:
			var u: float = (t - a) / maxf(b - a, 0.0001)
			var s: float = u * u * (3.0 - 2.0 * u)
			return lerpf(float(vs[i]), float(vs[i + 1]), s)
	return float(vs[n - 1])


static func _tangent(pts: Array, i: int) -> Vector3:
	var n: int = pts.size()
	var a: Vector3 = pts[maxi(i - 1, 0)]
	var b: Vector3 = pts[mini(i + 1, n - 1)]
	var d: Vector3 = b - a
	if d.length() < 0.0001:
		return Vector3.UP
	return d.normalized()


static func _in_hole(ts: float, uu: float, holes: Array) -> bool:
	for h in holes:
		var hh: Array = h
		var d_s: float = (ts - float(hh[0])) / float(hh[2])
		var d_u: float = (uu - float(hh[1])) / float(hh[3])
		if d_s * d_s + d_u * d_u < 1.0:
			return true
	return false


static func _bez(a: Vector3, b: Vector3, c: Vector3, d: Vector3, t: float) -> Vector3:
	var u: float = 1.0 - t
	var w0: float = u * u * u
	var w1: float = 3.0 * u * u * t
	var w2: float = 3.0 * u * t * t
	var w3: float = t * t * t
	return a * w0 + b * w1 + c * w2 + d * w3


static func _basis_y_to(dir: Vector3) -> Basis:
	var d: Vector3 = dir.normalized()
	var dot_up: float = d.dot(Vector3.UP)
	if dot_up > 0.9999:
		return Basis()
	if dot_up < -0.9999:
		return Basis(Vector3.RIGHT, PI)
	var ax: Vector3 = Vector3.UP.cross(d).normalized()
	var ang: float = acos(clampf(dot_up, -1.0, 1.0))
	return Basis(ax, ang)


static func _tube(root: Node3D, a: Vector3, b: Vector3, r: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.008)
	var cap := CapsuleMesh.new()
	cap.radius = r
	cap.height = ln + r * 2.0
	cap.radial_segments = 14
	cap.rings = 5
	var mi: MeshInstance3D = _add(root, cap, mat)
	mi.transform = Transform3D(_basis_y_to(d), (a + b) * 0.5)
	return mi


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, ua: Vector2, ub: Vector2, uc: Vector2, ud: Vector2, outward: Vector3, sg: int) -> void:
	st.set_smooth_group(sg)
	var nf: Vector3 = (c - a).cross(b - a)
	if nf.dot(outward) >= 0.0:
		st.set_uv(ua)
		st.add_vertex(a)
		st.set_uv(ub)
		st.add_vertex(b)
		st.set_uv(uc)
		st.add_vertex(c)
		st.set_uv(ua)
		st.add_vertex(a)
		st.set_uv(uc)
		st.add_vertex(c)
		st.set_uv(ud)
		st.add_vertex(d)
	else:
		st.set_uv(ua)
		st.add_vertex(a)
		st.set_uv(uc)
		st.add_vertex(c)
		st.set_uv(ub)
		st.add_vertex(b)
		st.set_uv(ua)
		st.add_vertex(a)
		st.set_uv(ud)
		st.add_vertex(d)
		st.set_uv(uc)
		st.add_vertex(c)


static func _union(kids: Array) -> AABB:
	var box := AABB()
	var first: bool = true
	for ch in kids:
		var cm: MeshInstance3D = ch
		if cm.mesh == null:
			continue
		var wb: AABB = cm.transform * cm.mesh.get_aabb()
		if first:
			box = wb
			first = false
		else:
			box = box.merge(wb)
	return box


# ---------------------------------------------------------------------------
# the printed surface: ovals, ripple ribs, honeycomb lattice — all seamless

static func _pattern(rng: RandomNumberGenerator, kind: int, ground: Color, ink: Color) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	var ph: float = rng.randf() * TAU
	var jitter: float = rng.randf_range(-0.06, 0.06)
	var cents: Array = [
		Vector2(0.25 + jitter, 0.18),
		Vector2(0.74, 0.32 + jitter),
		Vector2(0.46 - jitter, 0.68),
		Vector2(0.97, 0.83),
	]
	var ra: float = 0.190
	var rb: float = 0.152
	var ripples: float = 5.0
	var shadow: Color = ink.darkened(0.30)
	for y in range(TEX):
		var fv: float = (float(y) + 0.5) / float(TEX)
		for x in range(TEX):
			var fu: float = (float(x) + 0.5) / float(TEX)
			var c: Color = ground
			if kind == 1:
				var best: float = 9.0
				for k in range(cents.size()):
					var oc: Vector2 = cents[k]
					var du: float = absf(fu - oc.x)
					if du > 0.5:
						du = 1.0 - du
					var dv: float = absf(fv - oc.y)
					if dv > 0.5:
						dv = 1.0 - dv
					var e: float = sqrt((du / ra) * (du / ra) + (dv / rb) * (dv / rb))
					if e < best:
						best = e
				if best < 0.93:
					c = ink
				elif best < 1.03:
					c = ink.lerp(shadow, 0.75)
			elif kind == 2:
				var wv: float = fv * TAU * ripples + 0.40 * sin(fu * TAU + ph)
				var s: float = 0.5 + 0.5 * sin(wv)
				c = ground.lerp(ink, 0.34 * (1.0 - s))
				var sh: float = 0.86 + 0.22 * s
				c = Color(clampf(c.r * sh, 0.0, 1.0), clampf(c.g * sh, 0.0, 1.0), clampf(c.b * sh, 0.0, 1.0))
			elif kind == 3:
				var g: float = cos(TAU * 4.0 * fu) + cos(TAU * (-2.0 * fu + 4.0 * fv)) + cos(TAU * (-2.0 * fu - 4.0 * fv))
				var m: float = clampf((g + 0.30) / 1.70, 0.0, 1.0)
				c = ground.lerp(shadow, m * 0.92)
			var mot: float = 0.982 + 0.030 * sin(fu * TAU * 3.0 + ph) * sin(fv * TAU * 5.0 + ph * 1.7)
			img.set_pixel(x, y, Color(clampf(c.r * mot, 0.0, 1.0), clampf(c.g * mot, 0.0, 1.0), clampf(c.b * mot, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)
