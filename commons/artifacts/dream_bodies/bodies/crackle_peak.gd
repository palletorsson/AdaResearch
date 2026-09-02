extends RefCounted

## dream_bodies / crackle_peak — one hooded peak lifted out of the patterned row.
##
## Reference: scratchpad/refs/jump_a.png (2048x536 panorama) — a shoulder-to-shoulder
## crowd of tall pointed hooded figures, conical cloaks standing on a black ground.
## Every square millimetre is drawn on: a black-and-white labyrinth of wandering worm
## lines, a deep blue mosaic crazing held together with red grout, a fine rose-lilac
## crackle, grey stone crackle, and slashes of flame yellow and red. The cloaks
## overlap; flat cut-out shards lean against them; the ground behind is black with a
## fine red craquelure.
##
## Reproduced, and how:
##   1. The hooded cone — a SurfaceTool loft over a keyed radius profile (wide floor
##      skirt to a 6 mm tip), cross-section a rounded polygon with 3-6 lobes, the
##      whole thing twisting up to 55 deg as it rises and leaning off its own axis,
##      emitted as 50-78 separate patches so the skin can change mid-body.
##   2. Collage regions — 4-6 seed points scattered in (azimuth, height); each patch
##      takes the skin of its nearest seed, so patterns hold big contiguous areas and
##      meet along hard irregular cut edges instead of dissolving into noise.
##   3. Pattern continuity — UVs are global (azimuth -> u, arc length up the profile
##      -> v, both in metres / 0.27), and every skin is drawn seamless, so one pattern
##      runs unbroken across a whole region and stops dead at the collage edge.
##   4. Labyrinth squiggle — contour bands of a seeded low-frequency sine field
##      (integer frequencies, so it wraps), inked where the fractional part is near
##      zero: wandering worm lines of hand-drawn varying width.
##   5. Mosaic crazing / stone crackle / black craquelure — one seamless jittered
##      Worley routine at four cell counts and palettes: deep blue with red grout,
##      rose-lilac with wine grout, grey stone with dark grout, near-black with a
##      thin red craquelure.
##   6. Flame slash — the same warped field ramped into yellow / red / cream ribbons
##      with black contour outlines, dealt to a region or forced onto one panel.
##   7. Cloak folds — 2-4 creased flanges standing 5-13 cm proud of the cone along a
##      generator line, fading in and out over their span.
##   8. Leaning cut-outs — 3-6 pointed panels, each an irregular star-shaped polygon
##      extruded 12-20 mm (front face, back face and rim as separate skins), pitched
##      so its tip rests on the cone; plus 12-20 scattered shards and prism wedges.
##
## Given up: the rest of the row (only one peak is built), the painted black backdrop,
## the true hand of the pen (these are procedural contours, not drawn strokes), and
## the places where the reference lets one figure's pattern bleed into its neighbour.

const TEX: int = 128
const TEX_WORLD: float = 0.27
const VSTEPS: int = 48
const BASE_KEYS: Array = [0.380, 0.376, 0.352, 0.312, 0.262, 0.206, 0.149, 0.089, 0.031, 0.006]


static func describe() -> String:
	return "A tall hooded cone like a standing cloak, leaning and twisting to a sharp tip, its whole surface a collage of black-and-white labyrinth squiggle, blue-and-red mosaic crazing, stone crackle and flame slashes, with folded flanges and cut-out shards leaning against it."


static func build(root: Node3D, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# ------------------------------------------------------------------ #
	# PHASE A — every geometric decision, drawn before any texture work so
	# the body is a pure function of the seed whatever skins get built.
	# ------------------------------------------------------------------ #
	var height: float = rng.randf_range(1.46, 1.62)
	var base_r: float = rng.randf_range(0.345, 0.392)
	var keys := PackedFloat32Array()
	for i in range(BASE_KEYS.size()):
		var bk: float = BASE_KEYS[i]
		var fade: float = 1.0 - float(i) / float(BASE_KEYS.size())
		var jit: float = 1.0 + rng.randf_range(-0.07, 0.07) * fade
		keys.append(bk * (base_r / 0.380) * jit)

	var lean_dir: float = rng.randf_range(0.0, TAU)
	var lean_amt: float = rng.randf_range(0.10, 0.19)
	var curl_dir: float = lean_dir + rng.randf_range(-1.3, 1.3)
	var curl_amt: float = rng.randf_range(0.025, 0.085)
	var prm: Dictionary = {
		"keys": keys,
		"height": height,
		"twist": deg_to_rad(rng.randf_range(-55.0, 55.0)),
		"lobes": float(rng.randi_range(3, 6)),
		"lobe_amp": rng.randf_range(0.055, 0.135),
		"lobe_phase": rng.randf_range(0.0, TAU),
		"asym": rng.randf_range(0.045, 0.105),
		"asym_phase": rng.randf_range(0.0, TAU),
		"lean_x": cos(lean_dir) * lean_amt,
		"lean_z": sin(lean_dir) * lean_amt,
		"curl_x": cos(curl_dir) * curl_amt,
		"curl_z": sin(curl_dir) * curl_amt,
	}

	var n_sides: int = rng.randi_range(10, 13)
	var n_blocks: int = rng.randi_range(5, 6)
	var t_edges := PackedFloat32Array()
	for j in range(n_blocks + 1):
		var f: float = float(j) / float(n_blocks)
		t_edges.append(pow(f, 1.25))

	# collage regions
	var n_reg: int = rng.randi_range(4, 6)
	var reg_a := PackedFloat32Array()
	var reg_t := PackedFloat32Array()
	for k in range(n_reg):
		reg_a.append(rng.randf_range(0.0, TAU))
		reg_t.append(rng.randf_range(0.02, 0.98))
	var pool: Array = [0, 1, 0, 2, 3, 4, 1, 6, 5, 0, 2]
	for i in range(pool.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: int = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
	var reg_skin: Array = []
	for k in range(n_reg):
		reg_skin.append(int(pool[k]))
	var has_lab: bool = false
	for k in range(n_reg):
		var sv: int = reg_skin[k]
		if sv == 0 or sv == 1:
			has_lab = true
	if not has_lab:
		reg_skin[0] = 0
	var has_flame: bool = false
	for k in range(n_reg):
		var sv2: int = reg_skin[k]
		if sv2 == 5:
			has_flame = true

	# folded flanges
	var n_flange: int = rng.randi_range(2, 4)
	var fl_a := PackedFloat32Array()
	var fl_t0 := PackedFloat32Array()
	var fl_t1 := PackedFloat32Array()
	var fl_half := PackedFloat32Array()
	var fl_out := PackedFloat32Array()
	var fl_skin: Array = []
	for k in range(n_flange):
		fl_a.append(rng.randf_range(0.0, TAU))
		fl_t0.append(rng.randf_range(0.03, 0.20))
		fl_t1.append(rng.randf_range(0.58, 0.88))
		fl_half.append(rng.randf_range(0.22, 0.42))
		fl_out.append(rng.randf_range(0.048, 0.128))
		fl_skin.append(int(reg_skin[rng.randi_range(0, n_reg - 1)]))

	# leaning cut-out panels
	var n_panel: int = rng.randi_range(3, 6)
	var pn_a := PackedFloat32Array()
	var pn_tilt := PackedFloat32Array()
	var pn_h := PackedFloat32Array()
	var pn_w := PackedFloat32Array()
	var pn_th := PackedFloat32Array()
	var pn_poly: Array = []
	var pn_front: Array = []
	var pn_back: Array = []
	for k in range(n_panel):
		var pw: float = rng.randf_range(0.22, 0.46)
		var phh: float = rng.randf_range(0.42, 0.98)
		pn_a.append(rng.randf_range(0.0, TAU))
		pn_tilt.append(deg_to_rad(rng.randf_range(9.0, 20.0)))
		pn_h.append(phh)
		pn_w.append(pw)
		pn_th.append(rng.randf_range(0.012, 0.020))
		pn_poly.append(_peak_poly(rng, pw, phh))
		pn_front.append(int(reg_skin[rng.randi_range(0, n_reg - 1)]))
		pn_back.append(int(reg_skin[rng.randi_range(0, n_reg - 1)]))
	var flame_panel: int = -1
	if not has_flame:
		flame_panel = rng.randi_range(0, n_panel - 1)
		pn_front[flame_panel] = 5

	# scattered shards
	var n_chip: int = rng.randi_range(12, 20)
	var chips: Array = []
	for k in range(n_chip):
		var roll_kind: float = rng.randf()
		var kind: int = 0
		if roll_kind >= 0.42 and roll_kind < 0.86:
			kind = 1
		elif roll_kind >= 0.86:
			kind = 2
		chips.append([
			kind,
			rng.randf_range(0.0, TAU),
			rng.randf_range(0.0, 1.0),
			rng.randf_range(0.075, 0.215),
			rng.randf_range(0.095, 0.290),
			rng.randf_range(-0.5, 0.5),
			rng.randf_range(0.0, TAU),
			rng.randi_range(0, n_reg - 1),
		])

	# ------------------------------------------------------------------ #
	# PHASE B — surfaces. Skins and materials are built on first use.
	# ------------------------------------------------------------------ #
	var texs: Dictionary = {}
	var mats: Dictionary = {}

	# arc-length table so the pattern keeps a constant world scale up the cone
	var v_tab := PackedFloat32Array()
	v_tab.append(0.0)
	var acc: float = 0.0
	var prev := Vector2(_peak_radius(0.0, keys), 0.0)
	for i in range(1, VSTEPS + 1):
		var tt: float = float(i) / float(VSTEPS)
		var cur := Vector2(_peak_radius(tt, keys), height * tt)
		acc += cur.distance_to(prev)
		prev = cur
		v_tab.append(acc / TEX_WORLD)
	var u_total: float = maxf(4.0, round(TAU * _peak_radius(0.40, keys) / TEX_WORLD))

	# --- the hooded cone, patch by patch ---
	var su: int = 3
	var sv_steps: int = 4
	for si in range(n_sides):
		for bj in range(n_blocks):
			var a0: float = TAU * float(si) / float(n_sides)
			var a1: float = TAU * float(si + 1) / float(n_sides)
			var tb0: float = t_edges[bj]
			var tb1: float = t_edges[bj + 1]
			var ac: float = (a0 + a1) * 0.5
			var tc: float = (tb0 + tb1) * 0.5
			var sid: int = _region_skin(ac, tc, reg_a, reg_t, reg_skin)
			var mat: StandardMaterial3D = _mat(mats, texs, rng, sid, 0)
			var pivot: Vector3 = _peak_point(tc, ac, prm)
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			for gi in range(sv_steps):
				var t_a: float = lerpf(tb0, tb1, float(gi) / float(sv_steps))
				var t_b: float = lerpf(tb0, tb1, float(gi + 1) / float(sv_steps))
				var ins: Vector3 = _axis((t_a + t_b) * 0.5, prm) - pivot
				var v_a: float = _v_of(t_a, v_tab)
				var v_b: float = _v_of(t_b, v_tab)
				for gj in range(su):
					var a_a: float = lerpf(a0, a1, float(gj) / float(su))
					var a_b: float = lerpf(a0, a1, float(gj + 1) / float(su))
					var p00: Vector3 = _peak_point(t_a, a_a, prm) - pivot
					var p01: Vector3 = _peak_point(t_a, a_b, prm) - pivot
					var p11: Vector3 = _peak_point(t_b, a_b, prm) - pivot
					var p10: Vector3 = _peak_point(t_b, a_a, prm) - pivot
					var u_a: float = u_total * a_a / TAU
					var u_b: float = u_total * a_b / TAU
					_quad_uv(st, p00, Vector2(u_a, v_a), p01, Vector2(u_b, v_a), p11, Vector2(u_b, v_b), p10, Vector2(u_a, v_b), ins)
			st.generate_normals()
			var mi: MeshInstance3D = _add(root, st.commit(), mat)
			mi.transform = Transform3D(Basis(), pivot)

	# --- underside cap, so the skirt reads solid from below ---
	var ring_n: int = n_sides * su
	var cap_pivot := Vector3.ZERO
	for k in range(ring_n):
		cap_pivot += _peak_point(0.0, TAU * float(k) / float(ring_n), prm)
	cap_pivot = cap_pivot / float(ring_n)
	var cap_st := SurfaceTool.new()
	cap_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cap_ins := Vector3(0.0, 0.30, 0.0) - cap_pivot
	var cap_hub: Vector3 = _axis(0.0, prm) - cap_pivot
	for k in range(ring_n):
		var a_a: float = TAU * float(k) / float(ring_n)
		var a_b: float = TAU * float(k + 1) / float(ring_n)
		var pa: Vector3 = _peak_point(0.0, a_a, prm) - cap_pivot
		var pb: Vector3 = _peak_point(0.0, a_b, prm) - cap_pivot
		_tri_uv(cap_st, cap_hub, Vector2(cap_hub.x / TEX_WORLD, cap_hub.z / TEX_WORLD), pa, Vector2(pa.x / TEX_WORLD, pa.z / TEX_WORLD), pb, Vector2(pb.x / TEX_WORLD, pb.z / TEX_WORLD), cap_ins)
	cap_st.generate_normals()
	var cap_mi: MeshInstance3D = _add(root, cap_st.commit(), _mat(mats, texs, rng, 6, 0))
	cap_mi.transform = Transform3D(Basis(), cap_pivot)

	# --- folded flanges: the overlapping cloak edges ---
	for f in range(n_flange):
		var fa: float = fl_a[f]
		var ft0: float = fl_t0[f]
		var ft1: float = fl_t1[f]
		var fh: float = fl_half[f]
		var fo: float = fl_out[f]
		var fs: int = fl_skin[f]
		var mat_f: StandardMaterial3D = _mat(mats, texs, rng, fs, 1)
		var nb: int = 4
		for b in range(nb):
			var ta0: float = lerpf(ft0, ft1, float(b) / float(nb))
			var tb_end: float = lerpf(ft0, ft1, float(b + 1) / float(nb))
			var pivot_f: Vector3 = _crease((ta0 + tb_end) * 0.5, fa, fo, ft0, ft1, prm)
			var st_f := SurfaceTool.new()
			st_f.begin(Mesh.PRIMITIVE_TRIANGLES)
			var steps: int = 3
			var u_l: float = u_total * (fa - fh) / TAU
			var u_c: float = u_total * fa / TAU
			var u_r: float = u_total * (fa + fh) / TAU
			for k in range(steps):
				var t_a: float = lerpf(ta0, tb_end, float(k) / float(steps))
				var t_b: float = lerpf(ta0, tb_end, float(k + 1) / float(steps))
				var la: Vector3 = _peak_point(t_a, fa - fh, prm) - pivot_f
				var lb: Vector3 = _peak_point(t_b, fa - fh, prm) - pivot_f
				var ra: Vector3 = _peak_point(t_a, fa + fh, prm) - pivot_f
				var rb: Vector3 = _peak_point(t_b, fa + fh, prm) - pivot_f
				var ca: Vector3 = _crease(t_a, fa, fo, ft0, ft1, prm) - pivot_f
				var cb: Vector3 = _crease(t_b, fa, fo, ft0, ft1, prm) - pivot_f
				var v_a: float = _v_of(t_a, v_tab)
				var v_b: float = _v_of(t_b, v_tab)
				var ins_f: Vector3 = _axis((t_a + t_b) * 0.5, prm) - pivot_f
				_quad_uv(st_f, la, Vector2(u_l, v_a), ca, Vector2(u_c, v_a), cb, Vector2(u_c, v_b), lb, Vector2(u_l, v_b), ins_f)
				_quad_uv(st_f, ca, Vector2(u_c, v_a), ra, Vector2(u_r, v_a), rb, Vector2(u_r, v_b), cb, Vector2(u_c, v_b), ins_f)
			st_f.generate_normals()
			var mi_f: MeshInstance3D = _add(root, st_f.commit(), mat_f)
			mi_f.transform = Transform3D(Basis(), pivot_f)

	# --- leaning cut-out panels ---
	for p in range(n_panel):
		var ang: float = pn_a[p]
		var tilt: float = pn_tilt[p]
		var ph: float = pn_h[p]
		var th: float = pn_th[p]
		var poly: PackedVector2Array = pn_poly[p]
		var top_t: float = clampf((ph * cos(tilt)) / height, 0.0, 0.995)
		var ps: Vector3 = _peak_point(top_t, ang, prm)
		var ax: Vector3 = _axis(top_t, prm)
		var rc: float = Vector2(ps.x - ax.x, ps.z - ax.z).length()
		var off: float = ax.x * cos(ang) + ax.z * sin(ang)
		var dist: float = clampf(rc + off + ph * sin(tilt) - 0.03, 0.20, 0.48)
		var n_out := Vector3(cos(ang), 0.0, sin(ang))
		var right := Vector3(-sin(ang), 0.0, cos(ang))
		var up_l: Vector3 = (Vector3.UP * cos(tilt) - n_out * sin(tilt)).normalized()
		var z_l: Vector3 = right.cross(up_l).normalized()
		# the slab's back face tips below the floor by half a thickness of sine; lift it
		var foot: float = th * 0.5 * sin(tilt) + 0.0005
		var xf := Transform3D(Basis(right, up_l, z_l), Vector3(n_out.x * dist, foot, n_out.z * dist))
		var mf: StandardMaterial3D = _mat(mats, texs, rng, int(pn_front[p]), 1)
		var mb: StandardMaterial3D = _mat(mats, texs, rng, int(pn_back[p]), 1)
		var mr: StandardMaterial3D = _mat(mats, texs, rng, 6, 1)
		_panel(root, poly, xf, th, mf, mb, mr)

	# --- scattered shards ---
	for k in range(chips.size()):
		var row: Array = chips[k]
		var kind: int = int(row[0])
		var ang: float = row[1]
		var rr: float = row[2]
		var cw2: float = row[3]
		var chh: float = row[4]
		var lean: float = row[5]
		var roll: float = row[6]
		var sk: int = reg_skin[int(row[7])]
		var mat_c: StandardMaterial3D = _mat(mats, texs, rng, sk, 2)
		if kind == 1:
			var t: float = lerpf(0.16, 0.88, rr)
			var ps2: Vector3 = _peak_point(t, ang, prm)
			var ax2: Vector3 = _axis(t, prm)
			var nrm: Vector3 = Vector3(ps2.x - ax2.x, 0.0, ps2.z - ax2.z).normalized()
			nrm = (nrm + Vector3(0.0, 0.30, 0.0)).normalized()
			var q := QuadMesh.new()
			q.size = Vector2(cw2 * 0.9, chh * 0.9)
			var mi_c: MeshInstance3D = _add(root, q, mat_c)
			mi_c.transform = Transform3D(_basis_z_to(nrm, roll), ps2 + nrm * 0.015)
		elif kind == 0:
			var dist2: float = lerpf(0.24, 0.44, rr)
			var q2 := QuadMesh.new()
			q2.size = Vector2(cw2, chh)
			var n_out2 := Vector3(cos(ang), 0.0, sin(ang))
			var bz: Basis = _basis_z_to(n_out2, 0.0) * Basis(Vector3(1.0, 0.0, 0.0), lean * 0.5) * Basis(Vector3(0.0, 0.0, 1.0), roll * 0.10)
			var lowest: float = 1.0e9
			for c in range(4):
				var sxg: float = -1.0 if (c % 2) == 0 else 1.0
				var syg: float = -1.0 if c < 2 else 1.0
				var cp: Vector3 = bz * Vector3(sxg * cw2 * 0.5, syg * chh * 0.5, 0.0)
				lowest = minf(lowest, cp.y)
			var org := Vector3(n_out2.x * dist2, 0.004 - lowest, n_out2.z * dist2)
			var mi_c2: MeshInstance3D = _add(root, q2, mat_c)
			mi_c2.transform = Transform3D(bz, org)
		else:
			var dist3: float = lerpf(0.22, 0.42, rr)
			var pr := PrismMesh.new()
			pr.size = Vector3(cw2 * 1.15, chh * 0.85, cw2 * 0.60)
			var mi_c3: MeshInstance3D = _add(root, pr, mat_c)
			var bz3: Basis = Basis(Vector3(0.0, 1.0, 0.0), ang + roll * 0.2)
			mi_c3.transform = Transform3D(bz3, Vector3(cos(ang) * dist3, chh * 0.425 + 0.002, sin(ang) * dist3))

	# ------------------------------------------------------------------ #
	# SETTLE — measured fit, centre on x/z, stand on the floor.
	# ------------------------------------------------------------------ #
	var box: AABB = _union_aabb(root)
	var kx: float = 1.20 / maxf(box.size.x, 0.001)
	var kz: float = 1.20 / maxf(box.size.z, 0.001)
	var ky: float = 1.68 / maxf(box.size.y, 0.001)
	var kfit: float = minf(1.0, minf(kx, minf(kz, ky)))
	if kfit < 1.0:
		for ch in root.get_children():
			if not (ch is MeshInstance3D):
				continue
			var cm: MeshInstance3D = ch
			var tf: Transform3D = cm.transform
			cm.transform = Transform3D(tf.basis.scaled(Vector3(kfit, kfit, kfit)), tf.origin * kfit)
		box = _union_aabb(root)
	var centre: Vector3 = box.position + box.size * 0.5
	var shift := Vector3(-centre.x, -box.position.y, -centre.z)
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm2: MeshInstance3D = ch
		cm2.transform = Transform3D(cm2.transform.basis, cm2.transform.origin + shift)


# ---------------------------------------------------------------------------
# the peak's surface

static func _peak_radius(t: float, keys: PackedFloat32Array) -> float:
	var n: int = keys.size() - 1
	var f: float = clampf(t, 0.0, 1.0) * float(n)
	var i: int = int(floor(f))
	if i >= n:
		return keys[n]
	var u: float = f - float(i)
	var s: float = u * u * (3.0 - 2.0 * u)
	var a: float = keys[i]
	var b: float = keys[i + 1]
	return lerpf(a, b, s)


static func _axis(t: float, prm: Dictionary) -> Vector3:
	var tc: float = clampf(t, 0.0, 1.0)
	var lx: float = prm["lean_x"]
	var lz: float = prm["lean_z"]
	var cx: float = prm["curl_x"]
	var cz: float = prm["curl_z"]
	var hh: float = prm["height"]
	var e1: float = pow(tc, 1.7)
	var e2: float = pow(tc, 3.4)
	return Vector3(lx * e1 + cx * e2, hh * tc, lz * e1 + cz * e2)


static func _peak_point(t: float, ang: float, prm: Dictionary) -> Vector3:
	var keys: PackedFloat32Array = prm["keys"]
	var tw: float = prm["twist"]
	var lb: float = prm["lobes"]
	var la: float = prm["lobe_amp"]
	var lp: float = prm["lobe_phase"]
	var asy: float = prm["asym"]
	var ap: float = prm["asym_phase"]
	var r0: float = _peak_radius(t, keys)
	var a: float = ang + tw * t
	var amp: float = la * (1.0 - 0.5 * t)
	var rr: float = r0 * (1.0 + amp * cos(lb * a + lp))
	rr *= 1.0 + asy * cos(a + ap) * (0.35 + 0.65 * t)
	var ax: Vector3 = _axis(t, prm)
	return Vector3(ax.x + rr * cos(a), ax.y, ax.z + rr * sin(a))


static func _crease(t: float, ang: float, out_amt: float, t0: float, t1: float, prm: Dictionary) -> Vector3:
	var ps: Vector3 = _peak_point(t, ang, prm)
	var ax: Vector3 = _axis(t, prm)
	var d := Vector3(ps.x - ax.x, 0.0, ps.z - ax.z)
	var ln: float = maxf(d.length(), 0.0001)
	var u: float = clampf((t - t0) / maxf(t1 - t0, 0.001), 0.0, 1.0)
	var bump: float = pow(maxf(sin(PI * u), 0.0), 0.7)
	return ax + (d / ln) * (ln + out_amt * bump)


static func _v_of(t: float, v_tab: PackedFloat32Array) -> float:
	var n: int = v_tab.size() - 1
	var f: float = clampf(t, 0.0, 1.0) * float(n)
	var i: int = int(floor(f))
	if i >= n:
		return v_tab[n]
	var u: float = f - float(i)
	var a: float = v_tab[i]
	var b: float = v_tab[i + 1]
	return lerpf(a, b, u)


static func _region_skin(a: float, t: float, reg_a: PackedFloat32Array, reg_t: PackedFloat32Array, reg_skin: Array) -> int:
	var best: int = 0
	var bd: float = 1.0e9
	for k in range(reg_a.size()):
		var da: float = absf(fposmod(a - reg_a[k] + PI, TAU) - PI) / PI
		var dt: float = absf(t - reg_t[k])
		var d: float = da * da + dt * dt * 1.9
		if d < bd:
			bd = d
			best = k
	var out_id: int = reg_skin[best]
	return out_id


# ---------------------------------------------------------------------------
# cut-out panels

static func _peak_poly(rng: RandomNumberGenerator, w: float, h: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var tip_x: float = rng.randf_range(-0.24, 0.24) * w
	var n_side: int = 4
	pts.append(Vector2(-w * 0.5, 0.0))
	var nb: int = rng.randi_range(1, 2)
	for k in range(nb):
		var fr: float = (float(k) + 1.0) / (float(nb) + 1.0)
		var bx: float = lerpf(-w * 0.5, w * 0.5, fr)
		pts.append(Vector2(bx, h * rng.randf_range(0.006, 0.048)))
	pts.append(Vector2(w * 0.5, 0.0))
	for k in range(1, n_side):
		var fr: float = float(k) / float(n_side)
		var yy: float = h * pow(fr, rng.randf_range(0.85, 1.15))
		var xx: float = lerpf(w * 0.5, tip_x, pow(fr, rng.randf_range(1.0, 1.6))) + rng.randf_range(-0.045, 0.030) * w
		pts.append(Vector2(xx, yy))
	pts.append(Vector2(tip_x, h))
	for k in range(n_side - 1, 0, -1):
		var fr: float = float(k) / float(n_side)
		var yy: float = h * pow(fr, rng.randf_range(0.85, 1.15))
		var xx: float = lerpf(-w * 0.5, tip_x, pow(fr, rng.randf_range(1.0, 1.6))) + rng.randf_range(-0.030, 0.045) * w
		pts.append(Vector2(xx, yy))
	return pts


static func _panel(root: Node3D, pts: PackedVector2Array, xf: Transform3D, th: float, mf: StandardMaterial3D, mb: StandardMaterial3D, mr: StandardMaterial3D) -> void:
	var n: int = pts.size()
	if n < 3:
		return
	var top_y: float = 0.0
	for i in range(n):
		top_y = maxf(top_y, pts[i].y)
	var hub := Vector2(0.0, top_y * 0.33)
	var ins := Vector3(hub.x, hub.y, 0.0)
	var hz: float = th * 0.5

	for face in range(2):
		var zf: float = hz if face == 0 else -hz
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in range(n):
			var a2: Vector2 = pts[i]
			var b2: Vector2 = pts[(i + 1) % n]
			var pa := Vector3(hub.x, hub.y, zf)
			var pb := Vector3(a2.x, a2.y, zf)
			var pc := Vector3(b2.x, b2.y, zf)
			_tri_uv(st, pa, hub / TEX_WORLD, pb, a2 / TEX_WORLD, pc, b2 / TEX_WORLD, ins)
		st.generate_normals()
		var mat: StandardMaterial3D = mf if face == 0 else mb
		var mi: MeshInstance3D = _add(root, st.commit(), mat)
		mi.transform = xf

	var st_r := SurfaceTool.new()
	st_r.begin(Mesh.PRIMITIVE_TRIANGLES)
	var run: float = 0.0
	for i in range(n):
		var a2: Vector2 = pts[i]
		var b2: Vector2 = pts[(i + 1) % n]
		var seg: float = a2.distance_to(b2)
		var u0: float = run / TEX_WORLD
		var u1: float = (run + seg) / TEX_WORLD
		run += seg
		var v0: float = 0.0
		var v1: float = th / TEX_WORLD
		_quad_uv(st_r,
			Vector3(a2.x, a2.y, hz), Vector2(u0, v0),
			Vector3(b2.x, b2.y, hz), Vector2(u1, v0),
			Vector3(b2.x, b2.y, -hz), Vector2(u1, v1),
			Vector3(a2.x, a2.y, -hz), Vector2(u0, v1),
			ins)
	st_r.generate_normals()
	var mi_r: MeshInstance3D = _add(root, st_r.commit(), mr)
	mi_r.transform = xf


# ---------------------------------------------------------------------------
# surface tool plumbing

static func _tri_uv(st: SurfaceTool, a: Vector3, ua: Vector2, b: Vector3, ub: Vector2, c: Vector3, uc: Vector2, inside: Vector3) -> void:
	# Godot's front face is the clockwise winding; flip so it points away from `inside`
	var nf: Vector3 = (c - a).cross(b - a)
	var cen: Vector3 = (a + b + c) / 3.0
	if nf.dot(cen - inside) >= 0.0:
		st.set_uv(ua)
		st.add_vertex(a)
		st.set_uv(ub)
		st.add_vertex(b)
		st.set_uv(uc)
		st.add_vertex(c)
	else:
		st.set_uv(ua)
		st.add_vertex(a)
		st.set_uv(uc)
		st.add_vertex(c)
		st.set_uv(ub)
		st.add_vertex(b)


static func _quad_uv(st: SurfaceTool, a: Vector3, ua: Vector2, b: Vector3, ub: Vector2, c: Vector3, uc: Vector2, d: Vector3, ud: Vector2, inside: Vector3) -> void:
	_tri_uv(st, a, ua, b, ub, c, uc, inside)
	_tri_uv(st, a, ua, c, uc, d, ud, inside)


static func _add(root: Node3D, mesh: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


static func _basis_z_to(n: Vector3, roll: float) -> Basis:
	var z: Vector3 = n.normalized()
	var up: Vector3 = Vector3.UP
	if absf(z.dot(up)) > 0.985:
		up = Vector3.FORWARD
	var x: Vector3 = up.cross(z).normalized()
	var y: Vector3 = z.cross(x).normalized()
	var b := Basis(x, y, z)
	return b * Basis(Vector3(0.0, 0.0, 1.0), roll)


static func _union_aabb(root: Node3D) -> AABB:
	var box := AABB()
	var first: bool = true
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
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
# skins, painted in code

static func _mat(mats: Dictionary, texs: Dictionary, rng: RandomNumberGenerator, id: int, kind: int) -> StandardMaterial3D:
	var key: String = str(id) + ":" + str(kind)
	if mats.has(key):
		var cached: StandardMaterial3D = mats[key]
		return cached
	if not texs.has(id):
		texs[id] = _skin_tex(id, rng)
	var tx: ImageTexture = texs[id]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 1.0, 1.0)
	m.albedo_texture = tx
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.roughness = 0.72
	m.metallic = 0.0
	if kind == 2:
		m.uv1_triplanar = true
		m.uv1_scale = Vector3(3.6, 3.6, 3.6)
	if kind >= 1:
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mats[key] = m
	return m


static func _skin_tex(id: int, rng: RandomNumberGenerator) -> ImageTexture:
	if id == 0:
		return _labyrinth_tex(rng, Color("#0C0C0E"), Color("#F2EFE6"), 2.30, 0.200)
	if id == 1:
		return _labyrinth_tex(rng, Color("#101012"), Color("#EBE6D9"), 3.45, 0.155)
	if id == 2:
		return _crazing_tex(rng, 8, [Color("#28349E"), Color("#1D2782"), Color("#3242B5"), Color("#2A2E8C")], Color("#B4232E"), 0.18, 0.33)
	if id == 3:
		return _crazing_tex(rng, 11, [Color("#E0A6C2"), Color("#D89AB8"), Color("#E8B4CC"), Color("#CE8FB0")], Color("#8E2B3E"), 0.13, 0.34)
	if id == 4:
		return _crazing_tex(rng, 13, [Color("#C9C9C4"), Color("#B7B7B2"), Color("#D8D8D3"), Color("#A8A8A4")], Color("#333330"), 0.13, 0.32)
	if id == 5:
		return _flame_tex(rng)
	return _crazing_tex(rng, 15, [Color("#0B0B0D"), Color("#111114"), Color("#08080A")], Color("#7E2A20"), 0.10, 0.30)


static func _field_params(rng: RandomNumberGenerator) -> Array:
	var comps: Array = []
	var fset: Array = [[1, 0, 1.00], [0, 1, 0.90], [2, 1, 0.46], [1, 2, 0.40], [3, 2, 0.19], [2, 4, 0.13]]
	for k in range(fset.size()):
		var row: Array = fset[k]
		var bx: int = int(row[0])
		var by: int = int(row[1])
		var am: float = row[2]
		var sx: int = 1 if rng.randf() < 0.5 else -1
		var sy: int = 1 if rng.randf() < 0.5 else -1
		var jx: int = bx + rng.randi_range(0, 1)
		var jy: int = by + rng.randi_range(0, 1)
		comps.append([float(sx * jx), float(sy * jy), am * rng.randf_range(0.82, 1.18), rng.randf_range(0.0, TAU)])
	return comps


static func _field_at(comps: Array, u: float, v: float) -> float:
	var s: float = 0.0
	for k in range(comps.size()):
		var c: Array = comps[k]
		var fx: float = c[0]
		var fy: float = c[1]
		var am: float = c[2]
		var ph: float = c[3]
		s += am * sin(TAU * (fx * u + fy * v) + ph)
	return s


static func _labyrinth_tex(rng: RandomNumberGenerator, ink: Color, paper: Color, bands: float, thick: float) -> ImageTexture:
	var comps: Array = _field_params(rng)
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	for y in range(TEX):
		var v: float = float(y) / float(TEX)
		for x in range(TEX):
			var u: float = float(x) / float(TEX)
			var g: float = _field_at(comps, u, v) * bands
			var fr: float = g - floor(g)
			var d0: float = minf(fr, 1.0 - fr)
			var e: float = clampf((d0 - thick) / 0.055, 0.0, 1.0)
			img.set_pixel(x, y, ink.lerp(paper, e))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func _flame_tex(rng: RandomNumberGenerator) -> ImageTexture:
	var comps: Array = _field_params(rng)
	var bands: float = rng.randf_range(1.10, 1.55)
	var yellow := Color("#F2C21C")
	var red := Color("#D22420")
	var cream := Color("#F3EEE2")
	var blk := Color("#0C0C0E")
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	for y in range(TEX):
		var v: float = float(y) / float(TEX)
		for x in range(TEX):
			var u: float = float(x) / float(TEX)
			var g: float = _field_at(comps, u, v) * bands
			var gi: int = int(floor(g))
			var fr: float = g - float(gi)
			var d0: float = minf(fr, 1.0 - fr)
			var col: Color = blk
			if d0 > 0.085:
				var m: int = posmod(gi, 3)
				if m == 0:
					col = yellow
				elif m == 1:
					col = red
				else:
					col = cream
			img.set_pixel(x, y, col)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func _crazing_tex(rng: RandomNumberGenerator, cells: int, cols: Array, grout: Color, gw: float, jit: float) -> ImageTexture:
	var cw: float = float(TEX) / float(cells)
	var sx := PackedFloat32Array()
	var sy := PackedFloat32Array()
	var ci := PackedInt32Array()
	var sh := PackedFloat32Array()
	for gy in range(cells):
		for gx in range(cells):
			sx.append((float(gx) + 0.5 + rng.randf_range(-jit, jit)) * cw)
			sy.append((float(gy) + 0.5 + rng.randf_range(-jit, jit)) * cw)
			ci.append(rng.randi_range(0, cols.size() - 1))
			sh.append(rng.randf_range(0.86, 1.10))
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	for y in range(TEX):
		var py: float = float(y) + 0.5
		var gy0: int = int(floor(py / cw))
		for x in range(TEX):
			var px: float = float(x) + 0.5
			var gx0: int = int(floor(px / cw))
			var d1: float = 1.0e9
			var d2: float = 1.0e9
			var best: int = 0
			for oy in range(-1, 2):
				for ox in range(-1, 2):
					var cx: int = gx0 + ox
					var cy: int = gy0 + oy
					var wx: int = posmod(cx, cells)
					var wy: int = posmod(cy, cells)
					var idx: int = wy * cells + wx
					var qx: float = sx[idx] + float(cx - wx) * cw
					var qy: float = sy[idx] + float(cy - wy) * cw
					var dd: float = (px - qx) * (px - qx) + (py - qy) * (py - qy)
					if dd < d1:
						d2 = d1
						d1 = dd
						best = idx
					elif dd < d2:
						d2 = dd
			var e1: float = sqrt(d1)
			var e2: float = sqrt(d2)
			var wob: float = 0.70 + 0.60 * absf(sin(px * 0.23 + py * 0.19))
			if e2 - e1 < gw * cw * wob:
				img.set_pixel(x, y, grout)
			else:
				var base: Color = cols[ci[best]]
				var edge: float = clampf((e2 - e1) / (cw * 0.55), 0.0, 1.0)
				var s: float = sh[best] * (0.90 + 0.16 * edge)
				img.set_pixel(x, y, Color(clampf(base.r * s, 0.0, 1.0), clampf(base.g * s, 0.0, 1.0), clampf(base.b * s, 0.0, 1.0)))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)
