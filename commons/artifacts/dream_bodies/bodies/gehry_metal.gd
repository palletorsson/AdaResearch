extends RefCounted

## dream_bodies / gehry_metal — one standing crumple of mirror-polished sheet metal.
##
## Reference: scratchpad/refs/gehry_glitter.png (2048x536 panorama) — a row of
## Gehry-style metal crumples: huge curving folded panels in silver, warm
## bronze-gold and hot magenta, leaning and twisting past each other around a
## boxy core, several panels perforated with a grid of small square windows,
## hard specular highlights, the whole row mirror-bright against dark trees.
##
## Reproduced, and how:
##   1. Curving folded panels — 13..21 ArrayMesh sheets built with SurfaceTool
##      from a bent (u,v) grid: a parabolic cross-bow, a sine S-bend up the
##      height, a diagonal crumple ripple and a wobbling top edge. Each sheet
##      gets 2..3.4 cm of real thickness (front shell, back shell, rim strips,
##      in three smooth groups so the rims stay hard while the faces stay smooth).
##   2. Leaning past each other — every panel is dealt an azimuth and a radius on
##      one common vertical axis, then tipped, rolled and twisted about its own
##      base, so the sheets overlap, cross and pass through one another the way
##      the reference's sheets do.
##   3. Perforation — 2..6 panels drop a lattice of single cells (every third
##      cell, phase by seed, with occasional panes filled back in), and every
##      hole gets its own rim quads, so the windows are real openings through
##      the sheet thickness rather than painted squares.
##   4. Palette dealt by seed — silver / bronze-gold / magenta families with four
##      deals weighting them differently, so one individual is a cold silver
##      crumple and the next is a warm bronze one flashing magenta.
##   5. Mirror finish — metallic 1.0, roughness 0.10..0.25, plus a code-painted
##      128x128 brushed-metal texture (vertical streaks, horizontal scratches,
##      sparse white glitter specks) run triplanar so the streaks cross from
##      sheet to sheet unbroken.
##   6. The boxy window mass — 14..24 BoxMesh chunks stacked inside the crumple
##      wearing a painted window-grid texture with a few magenta-lit panes, seen
##      in the gaps between the sheets exactly as in the reference.
##   7. The gesture — a lean direction chosen by seed that grows with height, and
##      a crown tier whose roll and twist all curl the same way, so the thing
##      breaks like a wave instead of standing symmetrical on its axis.
##   8. Armature and offcuts — thin steel ribs rising through the core, 8..16
##      small twisted shards tucked between the big sheets, and 12..22 tiny
##      mirror chips clinging to the panels for glitter.
##
## Given up: true mirror reflection (nothing here reflects the room, so the streak
## texture plus a trace of emission stand in for it), the rest of the row, the
## trees and sky behind it, and the paper-thin torn edges — every sheet here is a
## 2-3 cm slab, because a zero-thickness one cannot carry a window rim.

const TEX: int = 128

const SILVER: Array = ["#C4C9D0", "#DCE2E8", "#A7AFB8", "#EDF1F5"]
const BRONZE: Array = ["#BE8845", "#DCA65B", "#8E5E2B", "#E6BE81"]
const MAGENTA: Array = ["#C22BAE", "#E14BCE", "#9A1590", "#EF74DE"]

# [silver weight, bronze weight, magenta weight] — the rest falls to magenta
const DEALS: Array = [
	[0.60, 0.22, 0.18],
	[0.44, 0.14, 0.42],
	[0.38, 0.42, 0.20],
	[0.54, 0.30, 0.16],
]


static func describe() -> String:
	return "A standing crumple of mirror-polished sheet metal — silver, bronze-gold and hot magenta panels leaning and twisting past each other, some perforated with small square windows, over a boxy window-gridded core."


static func build(root: Node3D, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	var brushed: ImageTexture = _brushed_texture(rng)
	var windows: ImageTexture = _window_texture(rng)
	var deal: Array = DEALS[rng.randi_range(0, DEALS.size() - 1)]

	var mat_rib: StandardMaterial3D = _metal(Color("#7B8189"), 0.34, null, 0.05, 1.0)
	var mat_core: StandardMaterial3D = _clad(Color("#C6CBD2"), windows, 0.06)
	var mat_core_hot: StandardMaterial3D = _clad(Color("#D08CC4"), windows, 0.38)
	var mat_base := StandardMaterial3D.new()
	mat_base.albedo_color = Color("#9DA2A6")
	mat_base.roughness = 0.82
	mat_base.metallic = 0.15

	# --- the individual ------------------------------------------------------
	var top_h: float = rng.randf_range(1.44, 1.60)
	var phi0: float = rng.randf_range(0.0, TAU)
	var spin: float = rng.randf_range(0.70, 1.05)
	var lean_a: float = rng.randf_range(0.0, TAU)
	var lax: float = cos(lean_a)
	var laz: float = sin(lean_a)
	var lean_amt: float = rng.randf_range(0.09, 0.18)
	var curl: float = 1.0
	if rng.randf() < 0.5:
		curl = -1.0
	var n_base: int = rng.randi_range(5, 7)
	var n_mid: int = rng.randi_range(5, 8)
	var n_top: int = rng.randi_range(3, 6)
	var n_hole_left: int = rng.randi_range(2, 6)

	var tiers: Array = [
		{"n": n_base, "ylo": 0.02, "yhi": 0.15, "hlo": 0.58, "hhi": 0.92, "rlo": 0.13, "rhi": 0.30, "wlo": 0.34, "whi": 0.60, "tw": 0.55, "hole": 0.26, "cell": 0.050},
		{"n": n_mid, "ylo": 0.40, "yhi": 0.66, "hlo": 0.44, "hhi": 0.74, "rlo": 0.09, "rhi": 0.26, "wlo": 0.28, "whi": 0.52, "tw": 0.85, "hole": 0.36, "cell": 0.046},
		{"n": n_top, "ylo": 0.86, "yhi": 1.06, "hlo": 0.34, "hhi": 0.58, "rlo": 0.05, "rhi": 0.20, "wlo": 0.24, "whi": 0.46, "tw": 1.20, "hole": 0.24, "cell": 0.042},
	]

	# --- the boxy window mass inside the crumple -----------------------------
	var n_core: int = rng.randi_range(14, 24)
	for i in range(n_core):
		var by: float = rng.randf_range(0.03, 1.02)
		var bh: float = rng.randf_range(0.10, 0.30)
		var bw: float = rng.randf_range(0.10, 0.24)
		var bd: float = rng.randf_range(0.10, 0.24)
		var br: float = rng.randf_range(0.0, 0.13)
		var ba: float = rng.randf_range(0.0, TAU)
		var bx: float = cos(ba) * br
		var bz: float = sin(ba) * br
		var lf: float = _lean_factor(by)
		var bmesh := BoxMesh.new()
		bmesh.size = Vector3(bw, bh, bd)
		var mm: StandardMaterial3D = mat_core
		if rng.randf() < 0.17:
			mm = mat_core_hot
		var mi: MeshInstance3D = _add(root, bmesh, mm)
		var yaw: float = rng.randf_range(0.0, TAU)
		var pos := Vector3(bx + lax * lean_amt * lf, by + bh * 0.5, bz + laz * lean_amt * lf)
		mi.transform = Transform3D(Basis(Vector3.UP, yaw), pos)

	# --- armature ribs -------------------------------------------------------
	var n_rib: int = rng.randi_range(9, 15)
	for i in range(n_rib):
		var ra: float = rng.randf_range(0.0, TAU)
		var rr: float = rng.randf_range(0.05, 0.18)
		var rh: float = rng.randf_range(0.45, 1.25)
		var rx: float = cos(ra) * rr
		var rz: float = sin(ra) * rr
		var lf: float = _lean_factor(rh)
		var bot := Vector3(rx, 0.03, rz)
		var top := Vector3(rx + lax * lean_amt * lf, 0.03 + rh, rz + laz * lean_amt * lf)
		_tapered_cyl(root, bot, top, 0.013, 0.007, mat_rib)

	# --- the big sheets, three tiers around one axis -------------------------
	var anchors: Array = []
	for ti in range(3):
		var spec: Dictionary = tiers[ti]
		var n: int = spec["n"]
		for k in range(n):
			var y_lo: float = spec["ylo"]
			var y_hi: float = spec["yhi"]
			var h_lo: float = spec["hlo"]
			var h_hi: float = spec["hhi"]
			var y0: float = rng.randf_range(y_lo, y_hi)
			var ph: float = rng.randf_range(h_lo, h_hi)
			if ti == 2 and k == 0:
				# the hero sheet — placed so its tip lands the statue's height
				ph = rng.randf_range(0.46, 0.58)
				y0 = top_h - ph * 0.94
			var w_lo: float = spec["wlo"]
			var w_hi: float = spec["whi"]
			var pw: float = rng.randf_range(w_lo, w_hi)
			var r_lo: float = spec["rlo"]
			var r_hi: float = spec["rhi"]
			var r0: float = rng.randf_range(r_lo, r_hi)
			var fk: float = float(k) / float(maxi(n - 1, 1))
			var phi: float = phi0 + TAU * fk * spin + float(ti) * 1.31 + rng.randf_range(-0.25, 0.25)
			var tw_max: float = spec["tw"]
			var twist: float = rng.randf_range(-tw_max, tw_max)
			var tip: float = rng.randf_range(-0.26, 0.30)
			var roll: float = rng.randf_range(-0.42, 0.42)
			if ti == 2:
				twist = curl * rng.randf_range(0.50, 1.0) * tw_max
				roll = curl * rng.randf_range(0.18, 0.55)
			var hole_p: float = spec["hole"]
			var holes: bool = false
			if n_hole_left > 0 and rng.randf() < hole_p:
				holes = true
				n_hole_left -= 1
			var cell: float = spec["cell"]
			var p: Dictionary = _params(rng, pw, ph, cell, holes, 1.0)
			p["twist"] = twist

			var col: Color = _deal_colour(rng, deal)
			var rough: float = rng.randf_range(0.10, 0.25)
			var tri: float = rng.randf_range(1.0, 2.0)
			var mat: StandardMaterial3D = _metal(col, rough, brushed, 0.12, tri)
			var lf: float = _lean_factor(y0)
			var pos := Vector3(cos(phi) * r0 + lax * lean_amt * lf, y0, sin(phi) * r0 + laz * lean_amt * lf)
			var bas: Basis = Basis(Vector3.UP, PI * 0.5 - phi) * Basis(Vector3.RIGHT, tip) * Basis(Vector3.BACK, roll)
			_panel(root, mat, Transform3D(bas, pos), p, rng)
			anchors.append(pos)

	# --- offcuts: small twisted shards between the sheets --------------------
	var n_shard: int = rng.randi_range(8, 16)
	for i in range(n_shard):
		var sw: float = rng.randf_range(0.10, 0.24)
		var sh: float = rng.randf_range(0.09, 0.26)
		var sy: float = rng.randf_range(0.08, 1.22)
		var sr: float = rng.randf_range(0.10, 0.32)
		var sa: float = rng.randf_range(0.0, TAU)
		var sp: Dictionary = _params(rng, sw, sh, 0.038, false, 1.6)
		sp["twist"] = rng.randf_range(-1.5, 1.5)
		var col: Color = _deal_colour(rng, deal)
		var rough: float = rng.randf_range(0.10, 0.22)
		var mat: StandardMaterial3D = _metal(col, rough, brushed, 0.14, rng.randf_range(1.6, 3.0))
		var lf: float = _lean_factor(sy)
		var pos := Vector3(cos(sa) * sr + lax * lean_amt * lf, sy, sin(sa) * sr + laz * lean_amt * lf)
		var bas: Basis = Basis(Vector3.UP, PI * 0.5 - sa) * Basis(Vector3.RIGHT, rng.randf_range(-0.9, 0.9)) * Basis(Vector3.BACK, rng.randf_range(-1.1, 1.1))
		_panel(root, mat, Transform3D(bas, pos), sp, rng)

	# --- glitter chips clinging to the sheets --------------------------------
	var n_chip: int = rng.randi_range(12, 22)
	for i in range(n_chip):
		var a_i: int = rng.randi_range(0, maxi(anchors.size() - 1, 0))
		var anchor: Vector3 = anchors[a_i]
		var cw: float = rng.randf_range(0.020, 0.055)
		var chip := BoxMesh.new()
		chip.size = Vector3(cw, cw * rng.randf_range(0.6, 1.6), cw * rng.randf_range(0.15, 0.5))
		var col: Color = _deal_colour(rng, deal)
		var mat: StandardMaterial3D = _metal(col.lightened(0.15), 0.10, brushed, 0.18, 4.0)
		var mi: MeshInstance3D = _add(root, chip, mat)
		var off := Vector3(rng.randf_range(-0.14, 0.14), rng.randf_range(-0.05, 0.22), rng.randf_range(-0.14, 0.14))
		var bas: Basis = Basis(Vector3.UP, rng.randf_range(0.0, TAU)) * Basis(Vector3.RIGHT, rng.randf_range(-1.4, 1.4))
		mi.transform = Transform3D(bas, anchor + off)

	# --- centre on the axis --------------------------------------------------
	var box: AABB = _union_aabb(root)
	var mid_x: float = box.position.x + box.size.x * 0.5
	var mid_z: float = box.position.z + box.size.z * 0.5
	_shift_all(root, Vector3(-mid_x, 0.0, -mid_z))
	box = _union_aabb(root)

	# --- aim: this body wants to stand 1.40..1.66 m off the floor ------------
	# (the two-step base adds ~48 mm under the crumple, so aim a little low)
	var kaim: float = 1.0
	if box.size.y < 1.36 or box.size.y > 1.60:
		kaim = top_h / maxf(box.size.y, 0.05)
	var widest: float = maxf(box.size.x, box.size.z)
	if widest * kaim > 1.16:
		kaim = 1.16 / maxf(widest, 0.01)
	if absf(kaim - 1.0) > 0.005:
		_scale_all(root, kaim)
		box = _union_aabb(root)

	# --- a shallow two-step base, sized to the footprint ---------------------
	_shift_all(root, Vector3(0.0, 0.048 - box.position.y, 0.0))
	box = _union_aabb(root)
	var pw2: float = minf(1.16, box.size.x + 0.10)
	var pd2: float = minf(1.16, box.size.z + 0.10)
	var slab := BoxMesh.new()
	slab.size = Vector3(pw2, 0.030, pd2)
	var sm: MeshInstance3D = _add(root, slab, mat_base)
	sm.transform = Transform3D(Basis(), Vector3(0.0, 0.015, 0.0))
	var slab2 := BoxMesh.new()
	slab2.size = Vector3(pw2 * 0.84, 0.020, pd2 * 0.84)
	var sm2: MeshInstance3D = _add(root, slab2, mat_base)
	sm2.transform = Transform3D(Basis(), Vector3(0.0, 0.040, 0.0))

	# --- SETTLE: measured, on the finished statue ----------------------------
	box = _union_aabb(root)
	var kfit: float = 1.0
	var wide: float = maxf(box.size.x, box.size.z)
	if wide > 1.2:
		kfit = minf(kfit, 1.2 / wide)
	if box.size.y > 1.68:
		kfit = minf(kfit, 1.68 / box.size.y)
	if kfit < 1.0:
		_scale_all(root, kfit)
		box = _union_aabb(root)
	if box.position.y < 0.0:
		_shift_all(root, Vector3(0.0, -box.position.y, 0.0))


# ---------------------------------------------------------------------------
# the sheet

static func _lean_factor(y: float) -> float:
	var f: float = clampf(y / 1.4, 0.0, 1.0)
	return pow(f, 1.3)


static func _params(rng: RandomNumberGenerator, pw: float, ph: float, cell: float, holes: bool, wild: float) -> Dictionary:
	var bow: float = rng.randf_range(0.05, 0.17) * wild
	if rng.randf() < 0.45:
		bow = -bow
	var nu: int = clampi(int(round(pw / cell)), 5, 16)
	var nv: int = clampi(int(round(ph / cell)), 5, 16)
	return {
		"w": pw,
		"h": ph,
		"bow": bow,
		"sbend": rng.randf_range(0.03, 0.12) * wild,
		"wave": rng.randf_range(0.6, 1.5),
		"phase": rng.randf_range(0.0, 1.0),
		"crum": rng.randf_range(0.008, 0.030),
		"ku": rng.randf_range(0.8, 2.2),
		"kv": rng.randf_range(0.6, 1.8),
		"cph": rng.randf_range(0.0, TAU),
		"crumy": rng.randf_range(0.010, 0.050),
		"ku2": rng.randf_range(0.5, 1.5),
		"cph2": rng.randf_range(0.0, TAU),
		"flare": rng.randf_range(-0.25, 0.45),
		"twist": 0.0,
		"lean_x": rng.randf_range(-0.10, 0.10),
		"lean_z": rng.randf_range(-0.06, 0.15),
		"thick": rng.randf_range(0.020, 0.034),
		"nu": nu,
		"nv": nv,
		"holes": holes,
		"hp": rng.randi_range(0, 2),
		"hq": rng.randi_range(0, 2),
		"hstep": 3,
	}


static func _pt(p: Dictionary, u: float, v: float) -> Vector3:
	var pw: float = p["w"]
	var ph: float = p["h"]
	var bow: float = p["bow"]
	var sbend: float = p["sbend"]
	var wave: float = p["wave"]
	var phase: float = p["phase"]
	var crum: float = p["crum"]
	var ku: float = p["ku"]
	var kv: float = p["kv"]
	var cph: float = p["cph"]
	var crumy: float = p["crumy"]
	var ku2: float = p["ku2"]
	var cph2: float = p["cph2"]
	var flare: float = p["flare"]
	var twist: float = p["twist"]
	var lean_x: float = p["lean_x"]
	var lean_z: float = p["lean_z"]

	var x: float = u * pw * (1.0 + flare * v)
	var y: float = v * ph
	var z: float = bow * (1.0 - 4.0 * u * u)
	z += sbend * sin(PI * (v * wave + phase))
	z += crum * sin(TAU * (u * ku + v * kv) + cph)
	y += crumy * sin(TAU * u * ku2 + cph2) * v
	var tw: float = twist * v
	var ct: float = cos(tw)
	var stt: float = sin(tw)
	var xr: float = x * ct + z * stt
	var zr: float = -x * stt + z * ct
	xr += lean_x * v * v
	zr += lean_z * v * v
	return Vector3(xr, y, zr)


static func _pt_normal(p: Dictionary, u: float, v: float) -> Vector3:
	var e: float = 0.012
	var du: Vector3 = _pt(p, u + e, v) - _pt(p, u - e, v)
	var dv: Vector3 = _pt(p, u, v + e) - _pt(p, u, v - e)
	var n: Vector3 = du.cross(dv)
	if n.length() < 0.000001:
		return Vector3.BACK
	return n.normalized()


static func _kept(keep: Array, nu: int, nv: int, i: int, j: int) -> bool:
	if i < 0 or j < 0 or i >= nu or j >= nv:
		return false
	var row: Array = keep[i]
	var k: bool = row[j]
	return k


static func _panel(root: Node3D, mat: StandardMaterial3D, xf: Transform3D, p: Dictionary, rng: RandomNumberGenerator) -> MeshInstance3D:
	var nu: int = p["nu"]
	var nv: int = p["nv"]
	var thick: float = p["thick"]

	var front: Array = []
	var back: Array = []
	for i in range(nu + 1):
		var u: float = -0.5 + float(i) / float(nu)
		var cf: Array = []
		var cb: Array = []
		for j in range(nv + 1):
			var v: float = float(j) / float(nv)
			var q: Vector3 = _pt(p, u, v)
			var n: Vector3 = _pt_normal(p, u, v)
			cf.append(q + n * (thick * 0.5))
			cb.append(q - n * (thick * 0.5))
		front.append(cf)
		back.append(cb)

	var holes: bool = p["holes"]
	var hp: int = p["hp"]
	var hq: int = p["hq"]
	var hstep: int = p["hstep"]
	var keep: Array = []
	for i in range(nu):
		var row: Array = []
		for j in range(nv):
			var k: bool = true
			if holes and i >= 1 and i <= nu - 2 and j >= 1 and j <= nv - 2:
				if posmod(i + hp, hstep) == 0 and posmod(j + hq, hstep) == 0:
					k = false
					if rng.randf() < 0.14:
						k = true
			row.append(k)
		keep.append(row)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(nu):
		for j in range(nv):
			if not _kept(keep, nu, nv, i, j):
				continue
			var fa: Array = front[i]
			var fb: Array = front[i + 1]
			var ba: Array = back[i]
			var bb: Array = back[i + 1]
			var a: Vector3 = fa[j]
			var b: Vector3 = fb[j]
			var c: Vector3 = fb[j + 1]
			var d: Vector3 = fa[j + 1]
			var a2: Vector3 = ba[j]
			var b2: Vector3 = bb[j]
			var c2: Vector3 = bb[j + 1]
			var d2: Vector3 = ba[j + 1]
			var mid: Vector3 = (a + b + c + d + a2 + b2 + c2 + d2) / 8.0
			st.set_smooth_group(0)
			_quad_out(st, a, b, c, d, mid)
			st.set_smooth_group(1)
			_quad_out(st, a2, b2, c2, d2, mid)
			st.set_smooth_group(2)
			if not _kept(keep, nu, nv, i - 1, j):
				_quad_out(st, a, d, d2, a2, mid)
			if not _kept(keep, nu, nv, i + 1, j):
				_quad_out(st, b, c, c2, b2, mid)
			if not _kept(keep, nu, nv, i, j - 1):
				_quad_out(st, a, b, b2, a2, mid)
			if not _kept(keep, nu, nv, i, j + 1):
				_quad_out(st, d, c, c2, d2, mid)
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	var mi: MeshInstance3D = _add(root, mesh, mat)
	mi.transform = xf
	return mi


static func _quad_out(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, inside: Vector3) -> void:
	# emit a quad whose Godot front face (clockwise) points away from `inside`
	var n_front: Vector3 = (c - a).cross(b - a)
	var centroid: Vector3 = (a + b + c + d) * 0.25
	if n_front.dot(centroid - inside) >= 0.0:
		st.add_vertex(a)
		st.add_vertex(b)
		st.add_vertex(c)
		st.add_vertex(a)
		st.add_vertex(c)
		st.add_vertex(d)
	else:
		st.add_vertex(a)
		st.add_vertex(c)
		st.add_vertex(b)
		st.add_vertex(a)
		st.add_vertex(d)
		st.add_vertex(c)


# ---------------------------------------------------------------------------
# materials, textures, small helpers

static func _deal_colour(rng: RandomNumberGenerator, deal: Array) -> Color:
	var r: float = rng.randf()
	var w0: float = deal[0]
	var w1: float = deal[1]
	var fam: Array = SILVER
	if r > w0 + w1:
		fam = MAGENTA
	elif r > w0:
		fam = BRONZE
	var idx: int = rng.randi_range(0, fam.size() - 1)
	var code: String = fam[idx]
	return Color(code)


static func _metal(c: Color, rough: float, tex: ImageTexture, emit_e: float, tri: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 1.0
	m.roughness = rough
	if tex != null:
		m.albedo_texture = tex
		m.uv1_triplanar = true
		m.uv1_scale = Vector3(tri, tri, tri)
	if emit_e > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit_e
	return m


static func _clad(c: Color, tex: ImageTexture, emit_e: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.55
	m.roughness = 0.36
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(3.0, 3.0, 3.0)
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = emit_e
	return m


static func _brushed_texture(rng: RandomNumberGenerator) -> ImageTexture:
	# vertical brush streaks + a few scratches + glitter specks, near-white so
	# albedo_color tints it; triplanar, so it runs across a whole crumple
	var n: int = TEX
	var img: Image = Image.create(n, n, false, Image.FORMAT_RGB8)
	var cols: Array = []
	for x in range(n):
		cols.append(rng.randf_range(0.74, 1.0))
	var smooth: Array = []
	for x in range(n):
		var ca: float = cols[posmod(x - 1, n)]
		var cb: float = cols[x]
		var cc: float = cols[posmod(x + 1, n)]
		var s: float = (ca + cb * 2.0 + cc) * 0.25
		smooth.append(s)
	for y in range(n):
		var fy: float = float(y)
		for x in range(n):
			var base: float = smooth[x]
			var wob: float = 1.0 + 0.035 * sin(fy * 0.35 + float(x) * 0.11)
			var v: float = clampf(base * wob, 0.45, 1.0)
			img.set_pixel(x, y, Color(v, v, v))
	for s_i in range(14):
		var sy: int = rng.randi_range(0, n - 1)
		var x0: int = rng.randi_range(0, n - 1)
		var ln: int = rng.randi_range(8, 48)
		var bright: float = rng.randf_range(0.92, 1.0)
		for k in range(ln):
			var xx: int = posmod(x0 + k, n)
			img.set_pixel(xx, sy, Color(bright, bright, bright))
	for g in range(70):
		var gx: int = rng.randi_range(0, n - 1)
		var gy: int = rng.randi_range(0, n - 1)
		img.set_pixel(gx, gy, Color(1.0, 1.0, 1.0))
	return ImageTexture.create_from_image(img)


static func _window_texture(rng: RandomNumberGenerator) -> ImageTexture:
	# a grid of small square panes, a few of them lit magenta
	var n: int = TEX
	var img: Image = Image.create(n, n, false, Image.FORMAT_RGB8)
	var cells: int = 8
	var cw: float = float(n) / float(cells)
	for y in range(n):
		for x in range(n):
			var v: float = clampf(0.80 + 0.06 * sin(float(x) * 0.5) * cos(float(y) * 0.37), 0.0, 1.0)
			img.set_pixel(x, y, Color(v, v, v))
	for cy in range(cells):
		for cx in range(cells):
			var dark: float = rng.randf_range(0.10, 0.26)
			var col := Color(dark, dark, clampf(dark * 1.2, 0.0, 1.0))
			if rng.randf() < 0.18:
				col = Color(0.88, 0.18, 0.70)
			var x0: int = int(floor(float(cx) * cw + cw * 0.24))
			var x1: int = int(floor(float(cx) * cw + cw * 0.80))
			var y0: int = int(floor(float(cy) * cw + cw * 0.24))
			var y1: int = int(floor(float(cy) * cw + cw * 0.80))
			for y in range(y0, y1):
				for x in range(x0, x1):
					img.set_pixel(posmod(x, n), posmod(y, n), col)
	return ImageTexture.create_from_image(img)


static func _add(root: Node3D, mesh: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


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


static func _tapered_cyl(root: Node3D, a: Vector3, b: Vector3, r0: float, r1: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.01)
	var cyl := CylinderMesh.new()
	cyl.bottom_radius = r0
	cyl.top_radius = r1
	cyl.height = ln
	cyl.radial_segments = 10
	var mi: MeshInstance3D = _add(root, cyl, mat)
	mi.transform = Transform3D(_basis_y_to(d), (a + b) * 0.5)
	return mi


static func _union_aabb(root: Node3D) -> AABB:
	var box := AABB()
	var first: bool = true
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		if cm.mesh == null:
			continue
		var local: AABB = cm.mesh.get_aabb()
		var wb: AABB = cm.transform * local
		if first:
			box = wb
			first = false
		else:
			box = box.merge(wb)
	return box


static func _shift_all(root: Node3D, by: Vector3) -> void:
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		cm.transform = Transform3D(cm.transform.basis, cm.transform.origin + by)


static func _scale_all(root: Node3D, k: float) -> void:
	# uniform, about the floor origin, so the footprint centre and y = 0 hold
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		var tf: Transform3D = cm.transform
		cm.transform = Transform3D(tf.basis.scaled(Vector3(k, k, k)), tf.origin * k)
