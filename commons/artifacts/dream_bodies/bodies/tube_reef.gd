extends RefCounted

## dream_bodies / tube_reef — one intertwined column of reef noodles, with eels.
##
## Reference: scratchpad/refs/sea_c.png (2048x536 panorama) — clumps of thick,
## smooth, uniform-diameter tubes rising from a grey coral floor in matt white,
## lemon yellow and magenta, winding around and through one another and hooking
## over at the top; among them, leopard-spotted eels (grey blotches on white)
## rise in S-curves, each ending in a small head with two round eyes and an
## open mouth. This builder takes ONE clump and stands it up as a statue.
##
## Reproduced, and how:
##   1. The noodles — 5..7 SurfaceTool swept tubes (12-sided rings on
##      parallel-transported frames) of constant radius 46..56 mm, each rising
##      from the common base on an arch, twisting around the column with its
##      own phase, twist sign, swirl and radial/vertical wobble, and landing
##      back on the coral. SphereMesh caps close both ends.
##   2. The weave — nothing is collision-checked: opposite twist signs and
##      differing wobble frequencies make the tubes cross and pass through one
##      another, which is what the reference actually shows.
##   3. Hairpin loops over the crown — about half the tubes get a full circle,
##      smoothstep-eased in and out (so the tangent never kinks), blended into
##      the path near the apex in the radial/up plane; it curls inward over the
##      top of the group.
##   4. Free hooked ends — one or two tubes stop just past the apex and hang in
##      mid-air over the others instead of returning to the floor.
##   5. Matt palette by seed — mostly white with one or two lemon yellow and
##      usually one magenta, all carrying a faint 64px grain so the surfaces
##      read as rubber rather than plastic.
##   6. One or two EELS — the same swept tube, tapering 52 -> 34 mm, on a rising
##      S path (sway in the tangential angle, drifting outward through the last
##      quarter), wearing a 128px leopard-spot texture painted in code onto the
##      tube's own arclength UVs, with a per-eel uv offset so no two match.
##   7. Eel heads — SphereMesh cranium + CapsuleMesh snout, two SurfaceTool
##      tapered-box jaws with the lower one hinged open 20..34 deg, a dark
##      mouth wedge between them, and two white eyes with dark pupils turned
##      outward.
##   8. The grey coral floor — a flattened SphereMesh mound carrying 46..62
##      nubs, a third of them growing one or two further spheres outward as
##      branches, all on a triplanar mottle texture.
##
## Given up: the black water and its caustic surface, the neighbouring reef
## clumps and branching fan corals, the octopus at the left, and the fine
## porous micro-perforation of the eel skin — a painted spot pattern stands in
## for it, without the holes.

const TEX: int = 128
const CORAL_TEX: int = 96
const GRAIN_TEX: int = 64

const WHITES: Array = ["#F2F0E8", "#EEEBE2", "#F7F5EF"]
const YELLOWS: Array = ["#E2DA16", "#DDD426", "#EAE22C"]
const MAGENTAS: Array = ["#C548D2", "#CE4BC0", "#B94FDA"]
const GREYS: Array = ["#8E9089", "#83857E", "#989A92"]


static func describe() -> String:
	return "A column of thick matt noodles in white, lemon and magenta winding through one another and hooking over at the top, with leopard-spotted eels rising among them from a bed of grey coral."


static func build(root: Node3D, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# --- palette -------------------------------------------------------------
	var s_white: String = WHITES[rng.randi_range(0, WHITES.size() - 1)]
	var s_yellow: String = YELLOWS[rng.randi_range(0, YELLOWS.size() - 1)]
	var s_magenta: String = MAGENTAS[rng.randi_range(0, MAGENTAS.size() - 1)]
	var s_grey: String = GREYS[rng.randi_range(0, GREYS.size() - 1)]
	var col_white := Color(s_white)
	var col_yellow := Color(s_yellow)
	var col_magenta := Color(s_magenta)
	var col_coral := Color(s_grey)

	var tex_grain: ImageTexture = _grain_texture(rng)
	var tex_coral: ImageTexture = _coral_texture(rng)
	var tex_spot: ImageTexture = _spot_texture(rng)

	var mat_coral: StandardMaterial3D = _matte(col_coral, 0.94)
	mat_coral.albedo_texture = tex_coral
	mat_coral.uv1_triplanar = true
	mat_coral.uv1_scale = Vector3(7.0, 7.0, 7.0)
	var mat_coral_dark: StandardMaterial3D = _matte(col_coral.darkened(0.22), 0.96)
	mat_coral_dark.albedo_texture = tex_coral
	mat_coral_dark.uv1_triplanar = true
	mat_coral_dark.uv1_scale = Vector3(5.0, 5.0, 5.0)
	var mat_coral_pale: StandardMaterial3D = _matte(col_coral.lightened(0.16), 0.92)
	mat_coral_pale.albedo_texture = tex_coral
	mat_coral_pale.uv1_triplanar = true
	mat_coral_pale.uv1_scale = Vector3(9.0, 9.0, 9.0)

	var mat_mouth: StandardMaterial3D = _matte(Color("#6E4048"), 0.80)
	var mat_eye: StandardMaterial3D = _matte(Color("#F6F4EE"), 0.30)
	var mat_pupil: StandardMaterial3D = _matte(Color("#221E22"), 0.22)

	# --- individual parameters -----------------------------------------------
	var n_tubes: int = rng.randi_range(5, 7)
	var n_eels: int = 1 if rng.randf() < 0.35 else 2
	var base_y: float = 0.075
	var col_r: float = rng.randf_range(0.30, 0.36)
	var arch_h0: float = rng.randf_range(1.30, 1.40)
	var tube_r: float = rng.randf_range(0.046, 0.056)
	var lean_a: float = rng.randf_range(0.0, TAU)
	var lean_amt: float = rng.randf_range(0.02, 0.07)
	var lean_x: float = cos(lean_a) * lean_amt
	var lean_z: float = sin(lean_a) * lean_amt
	var spin: float = rng.randf_range(0.0, TAU)

	# colour roles: 0 white, 1 yellow, 2 magenta — shuffled with our own rng
	var order: Array = []
	for i in range(n_tubes):
		order.append(i)
	for i in range(n_tubes - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: int = order[i]
		order[i] = order[j]
		order[j] = tmp
	var roles: Array = []
	for _i in range(n_tubes):
		roles.append(0)
	var take: int = 0
	var n_yellow: int = rng.randi_range(1, 2)
	for _k in range(n_yellow):
		if take < n_tubes - 1:
			roles[order[take]] = 1
			take += 1
	if rng.randf() < 0.85 and take < n_tubes - 1:
		roles[order[take]] = 2
		take += 1

	# which tubes end free in the air rather than returning to the floor
	var n_hooks: int = rng.randi_range(1, 2)
	var hooked: Array = []
	for _i in range(n_tubes):
		hooked.append(false)
	for k in range(n_hooks):
		var hi: int = order[(n_tubes - 1 - k) % n_tubes]
		hooked[hi] = true

	# --- the noodles ---------------------------------------------------------
	var steps: int = 88
	for ti in range(n_tubes):
		var ph: float = spin + TAU * float(ti) / float(n_tubes) + rng.randf_range(-0.26, 0.26)
		var twist: float = rng.randf_range(1.5, 3.0) * (1.0 if rng.randf() < 0.55 else -1.0)
		var swirl: float = rng.randf_range(0.16, 0.44)
		var swirl_ph: float = rng.randf_range(0.0, TAU)
		var arch_h: float = arch_h0 * rng.randf_range(0.90, 1.04)
		var arch_pw: float = rng.randf_range(0.80, 1.05)
		var r_here: float = col_r * rng.randf_range(0.86, 1.08)
		var wob_amp: float = rng.randf_range(0.030, 0.072)
		var wob_f: float = 2.0 if rng.randf() < 0.5 else 3.0
		var wob_ph: float = rng.randf_range(0.0, TAU)
		var ywob: float = rng.randf_range(0.028, 0.070)
		var ywob_f: float = 3.0 if rng.randf() < 0.5 else 4.0
		var ywob_ph: float = rng.randf_range(0.0, TAU)
		var has_loop: bool = rng.randf() < 0.55
		var loop_r: float = rng.randf_range(0.060, 0.090)
		var loop_u: float = rng.randf_range(0.42, 0.60)
		var loop_w: float = rng.randf_range(0.10, 0.16)
		var u_top: float = 1.0
		if hooked[ti]:
			u_top = rng.randf_range(0.66, 0.86)

		var pts: Array = []
		var radii: Array = []
		for i in range(steps + 1):
			var u: float = u_top * float(i) / float(steps)
			var sn: float = maxf(sin(PI * u), 0.0)
			var ang: float = ph + twist * u + swirl * sin(TAU * u + swirl_ph)
			var rad: float = r_here * (0.26 + 0.74 * pow(sn, 0.62)) + wob_amp * sin(wob_f * PI * u + wob_ph)
			rad = maxf(rad, 0.03)
			var yy: float = base_y + arch_h * pow(sn, arch_pw) + ywob * sn * sin(ywob_f * PI * u + ywob_ph)
			var p := Vector3(rad * cos(ang) + lean_x * sn, yy, rad * sin(ang) + lean_z * sn)
			if has_loop and u > loop_u - loop_w and u < loop_u + loop_w:
				var sl: float = (u - (loop_u - loop_w)) / (2.0 * loop_w)
				var se: float = sl * sl * (3.0 - 2.0 * sl)
				var e_out: Vector3 = Vector3(cos(ang), 0.0, sin(ang))
				p += e_out * (loop_r * (cos(TAU * se) - 1.0))
				p += Vector3(0.0, loop_r * sin(TAU * se), 0.0)
			pts.append(p)
			radii.append(tube_r)

		var role: int = roles[ti]
		var col_here: Color = col_white
		if role == 1:
			col_here = col_yellow
		elif role == 2:
			col_here = col_magenta
		var mat_tube: StandardMaterial3D = _matte(col_here, 0.58)
		mat_tube.albedo_texture = tex_grain
		mat_tube.uv1_scale = Vector3(3.0, 3.0, 1.0)
		mat_tube.uv1_offset = Vector3(rng.randf(), rng.randf(), 0.0)

		var body: ArrayMesh = _tube_mesh(pts, radii, 12, 2.0)
		var bm: MeshInstance3D = _add(root, body, mat_tube)
		bm.transform = Transform3D()
		var foot: Vector3 = pts[0]
		var crest: Vector3 = pts[pts.size() - 1]
		_ball(root, foot, tube_r, mat_tube)
		_ball(root, crest, tube_r, mat_tube)

	# --- the eels ------------------------------------------------------------
	for _ei in range(n_eels):
		var ph_e: float = spin + rng.randf_range(0.0, TAU)
		var h_e: float = rng.randf_range(1.06, 1.32)
		var r_e: float = col_r * rng.randf_range(0.78, 1.02)
		var sway: float = rng.randf_range(0.55, 1.05) * (1.0 if rng.randf() < 0.5 else -1.0)
		var swim_f: float = 1.6 if rng.randf() < 0.5 else 2.2
		var drift: float = rng.randf_range(-0.5, 0.5)
		var head_out: float = rng.randf_range(0.08, 0.17)
		var r_base: float = rng.randf_range(0.048, 0.055)
		var r_neck: float = rng.randf_range(0.030, 0.037)
		var e_steps: int = 72

		var epts: Array = []
		var eradii: Array = []
		for i in range(e_steps + 1):
			var u: float = float(i) / float(e_steps)
			var ang: float = ph_e + sway * sin(PI * u * swim_f) + drift * u
			var out_t: float = clampf((u - 0.70) / 0.30, 0.0, 1.0)
			var rad: float = r_e * (0.20 + 0.80 * pow(u, 0.58)) + head_out * out_t * out_t
			var yy: float = base_y + h_e * pow(u, 0.94)
			epts.append(Vector3(rad * cos(ang), yy, rad * sin(ang)))
			eradii.append(lerpf(r_base, r_neck, pow(u, 0.85)))

		# the spotted material is only ever worn by the swept tube, whose UVs are
		# built from arclength; a SphereMesh cap would stretch ONE spot over the
		# whole ball, so the cap wears the plain skin
		var mat_skin: StandardMaterial3D = _matte(Color("#EFEDE5"), 0.66)
		mat_skin.albedo_texture = tex_spot
		mat_skin.uv1_offset = Vector3(rng.randf(), rng.randf(), 0.0)
		var mat_plain: StandardMaterial3D = _matte(Color("#EFEDE5"), 0.66)
		var eel: ArrayMesh = _tube_mesh(epts, eradii, 12, 2.0)
		var em: MeshInstance3D = _add(root, eel, mat_skin)
		em.transform = Transform3D()
		var e_foot: Vector3 = epts[0]
		_ball(root, e_foot, r_base, mat_plain)

		var tip: Vector3 = epts[epts.size() - 1]
		var tang: Vector3 = _tangent(epts, epts.size() - 1)
		var pitch: float = rng.randf_range(-0.12, 0.36)
		var fwd: Vector3 = (tang + Vector3(0.0, pitch, 0.0)).normalized()
		var gape: float = deg_to_rad(rng.randf_range(20.0, 34.0))
		_eel_head(root, tip, fwd, r_neck * 1.32, gape, mat_skin, mat_mouth, mat_eye, mat_pupil)

	# --- the coral floor -----------------------------------------------------
	var dome_rx: float = 0.44
	var dome_h: float = 0.055
	var dome := SphereMesh.new()
	dome.radius = dome_rx
	dome.height = dome_h * 2.0
	dome.radial_segments = 30
	dome.rings = 10
	var dm: MeshInstance3D = _add(root, dome, mat_coral_dark)
	dm.transform = Transform3D(Basis(), Vector3(0.0, dome_h, 0.0))

	var n_nubs: int = rng.randi_range(46, 62)
	for _k in range(n_nubs):
		var ang: float = rng.randf_range(0.0, TAU)
		var rr: float = 0.50 * sqrt(rng.randf_range(0.015, 1.0))
		var nr: float = rng.randf_range(0.016, 0.044)
		var q: float = clampf(rr / dome_rx, 0.0, 1.0)
		var sy: float = dome_h * sqrt(maxf(1.0 - q * q, 0.0))
		var cy: float = maxf(dome_h + sy - nr * 0.35, nr)
		var pos := Vector3(cos(ang) * rr, cy, sin(ang) * rr)
		var mat_n: StandardMaterial3D = mat_coral
		var pick: float = rng.randf()
		if pick < 0.28:
			mat_n = mat_coral_pale
		elif pick > 0.86:
			mat_n = mat_coral_dark
		_ball(root, pos, nr, mat_n)
		if rng.randf() < 0.36:
			var lean_d: Vector3 = Vector3(cos(ang) * 0.4, 1.0, sin(ang) * 0.4).normalized()
			var p2: Vector3 = pos + lean_d * (nr * 1.05)
			_ball(root, p2, nr * 0.74, mat_n)
			if rng.randf() < 0.45:
				var p3: Vector3 = p2 + lean_d * (nr * 0.80)
				_ball(root, p3, nr * 0.54, mat_n)

	# --- fit, centre, settle -------------------------------------------------
	var box: AABB = _union_aabb(root)
	var kx: float = 1.20 / maxf(box.size.x, 0.01)
	var kz: float = 1.20 / maxf(box.size.z, 0.01)
	var ky: float = 1.66 / maxf(box.size.y, 0.01)
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
	var shift := Vector3(-centre.x, 0.0, -centre.z)
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		cm.transform = Transform3D(cm.transform.basis, cm.transform.origin + shift)
	# SETTLE: measured, never assumed — nothing may hang under the plinth top
	box = _union_aabb(root)
	if box.position.y < 0.0:
		var lift: float = -box.position.y
		for ch in root.get_children():
			if not (ch is MeshInstance3D):
				continue
			var cm: MeshInstance3D = ch
			var tf: Transform3D = cm.transform
			cm.transform = Transform3D(tf.basis, tf.origin + Vector3(0.0, lift, 0.0))


# ---------------------------------------------------------------------------
# the eel head

static func _eel_head(root: Node3D, p: Vector3, fwd: Vector3, rh: float, gape: float, mat_skin: StandardMaterial3D, mat_mouth: StandardMaterial3D, mat_eye: StandardMaterial3D, mat_pupil: StandardMaterial3D) -> void:
	var f: Vector3 = fwd.normalized()
	var up_ref := Vector3.UP
	if absf(f.dot(up_ref)) > 0.95:
		up_ref = Vector3(0.0, 0.0, -1.0)
	var uh: Vector3 = (up_ref - f * f.dot(up_ref)).normalized()
	var rt: Vector3 = f.cross(uh).normalized()
	var hb := Basis(rt, uh, -f)

	# the sphere/capsule of the head carry the primitives' own UVs — one tile
	# over the whole ball — so the spots need scaling down to body size here
	var mat_head: StandardMaterial3D = _matte(mat_skin.albedo_color, 0.66)
	mat_head.albedo_texture = mat_skin.albedo_texture
	mat_head.uv1_scale = Vector3(2.6, 2.6, 1.0)
	mat_head.uv1_offset = mat_skin.uv1_offset
	# the jaw wedges are SurfaceTool boxes with no UVs at all — plain skin
	var mat_jaw: StandardMaterial3D = _matte(mat_skin.albedo_color.lightened(0.04), 0.62)

	var cranium := SphereMesh.new()
	cranium.radius = rh
	cranium.height = rh * 2.0
	cranium.radial_segments = 20
	cranium.rings = 12
	var cm: MeshInstance3D = _add(root, cranium, mat_head)
	cm.transform = Transform3D(hb, p)

	var snout := CapsuleMesh.new()
	snout.radius = rh * 0.72
	snout.height = rh * 2.2
	snout.radial_segments = 16
	var sm: MeshInstance3D = _add(root, snout, mat_head)
	sm.transform = Transform3D(_basis_y_to(f), p + f * (rh * 0.72))

	var anchor: Vector3 = p + f * (rh * 0.45)
	var jaw_l: float = rh * 1.45
	var upper: ArrayMesh = _tapered_box(rh * 1.46, rh * 0.72, rh * 0.90, rh * 0.30, jaw_l, -rh * 0.06)
	var um: MeshInstance3D = _add(root, upper, mat_jaw)
	um.transform = Transform3D(hb, anchor + hb * Vector3(0.0, -rh * 0.08, 0.0))

	var hinge: Vector3 = anchor + hb * Vector3(0.0, -rh * 0.44, 0.0)
	var jb: Basis = hb * Basis(Vector3.RIGHT, -gape)
	var lower: ArrayMesh = _tapered_box(rh * 1.32, rh * 0.48, rh * 0.80, rh * 0.24, jaw_l * 0.94, 0.0)
	var lm: MeshInstance3D = _add(root, lower, mat_jaw)
	lm.transform = Transform3D(jb, hinge)

	var mb: Basis = hb * Basis(Vector3.RIGHT, -gape * 0.5)
	var gum := BoxMesh.new()
	gum.size = Vector3(rh * 1.02, rh * 0.30, jaw_l * 0.86)
	var gm: MeshInstance3D = _add(root, gum, mat_mouth)
	gm.transform = Transform3D(mb, hinge + (mb * Vector3(0.0, rh * 0.10, -jaw_l * 0.42)))

	for si in range(2):
		var sgn: float = -1.0 if si == 0 else 1.0
		var eye_c: Vector3 = p + hb * Vector3(sgn * rh * 0.66, rh * 0.34, -rh * 0.28)
		var eye := SphereMesh.new()
		eye.radius = rh * 0.33
		eye.height = rh * 0.66
		eye.radial_segments = 14
		eye.rings = 8
		var em: MeshInstance3D = _add(root, eye, mat_eye)
		em.transform = Transform3D(Basis(), eye_c)
		var out_d: Vector3 = (rt * (sgn * 0.6) + uh * 0.18 + f * 0.55).normalized()
		var pup := SphereMesh.new()
		pup.radius = rh * 0.175
		pup.height = rh * 0.35
		pup.radial_segments = 12
		pup.rings = 8
		var pm: MeshInstance3D = _add(root, pup, mat_pupil)
		pm.transform = Transform3D(Basis(), eye_c + out_d * (rh * 0.25))


# ---------------------------------------------------------------------------
# swept tube

static func _tube_mesh(pts: Array, radii: Array, sides: int, tiles_around: float) -> ArrayMesh:
	var n: int = pts.size()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# parallel-transported frames so the tube never spins on its own axis
	var nrms: Array = []
	var bins: Array = []
	var prev_n := Vector3.ZERO
	for i in range(n):
		var tg: Vector3 = _tangent(pts, i)
		var nv := Vector3.ZERO
		if i == 0:
			var sv := Vector3.UP
			if absf(tg.dot(sv)) > 0.9:
				sv = Vector3.RIGHT
			nv = sv - tg * sv.dot(tg)
		else:
			nv = prev_n - tg * prev_n.dot(tg)
			if nv.length() < 0.0001:
				var sv2 := Vector3.UP
				if absf(tg.dot(sv2)) > 0.9:
					sv2 = Vector3.RIGHT
				nv = sv2 - tg * sv2.dot(tg)
		nv = nv.normalized()
		prev_n = nv
		nrms.append(nv)
		bins.append(tg.cross(nv).normalized())

	# arclength for the v coordinate, mean radius for an isotropic pattern
	var arc: Array = []
	var acc: float = 0.0
	var rsum: float = 0.0
	for i in range(n):
		if i > 0:
			var q0: Vector3 = pts[i]
			var q1: Vector3 = pts[i - 1]
			acc += (q0 - q1).length()
		arc.append(acc)
		rsum += float(radii[i])
	var mean_r: float = maxf(rsum / float(n), 0.001)
	var v_scale: float = tiles_around / (TAU * mean_r)

	# rings carry exactly `sides` vertices; the seam re-uses index 0 so the two
	# seam corners are bit-identical and generate_normals() welds them (a seam
	# pair that differs by one float bit shades as a hard line down the tube)
	var rings: Array = []
	for i in range(n):
		var row: Array = []
		var r: float = radii[i]
		var pc: Vector3 = pts[i]
		var nv2: Vector3 = nrms[i]
		var bv: Vector3 = bins[i]
		for j in range(sides):
			var a: float = TAU * float(j) / float(sides)
			row.append(pc + nv2 * (cos(a) * r) + bv * (sin(a) * r))
		rings.append(row)

	for i in range(n - 1):
		var v0: float = float(arc[i]) * v_scale
		var v1: float = float(arc[i + 1]) * v_scale
		var row0: Array = rings[i]
		var row1: Array = rings[i + 1]
		for j in range(sides):
			var jn: int = (j + 1) % sides
			var u0: float = tiles_around * float(j) / float(sides)
			var u1: float = tiles_around * float(j + 1) / float(sides)
			var pa: Vector3 = row0[j]
			var pb: Vector3 = row0[jn]
			var pc2: Vector3 = row1[jn]
			var pd: Vector3 = row1[j]
			st.set_uv(Vector2(u0, v0))
			st.add_vertex(pa)
			st.set_uv(Vector2(u1, v1))
			st.add_vertex(pc2)
			st.set_uv(Vector2(u1, v0))
			st.add_vertex(pb)
			st.set_uv(Vector2(u0, v0))
			st.add_vertex(pa)
			st.set_uv(Vector2(u0, v1))
			st.add_vertex(pd)
			st.set_uv(Vector2(u1, v1))
			st.add_vertex(pc2)

	st.generate_normals()
	return st.commit()


# ---------------------------------------------------------------------------
# small helpers

static func _add(root: Node3D, mesh: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


static func _ball(root: Node3D, at: Vector3, r: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var sph := SphereMesh.new()
	sph.radius = r
	sph.height = r * 2.0
	sph.radial_segments = 16
	sph.rings = 9
	var mi: MeshInstance3D = _add(root, sph, mat)
	mi.transform = Transform3D(Basis(), at)
	return mi


static func _matte(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.0
	m.metallic_specular = 0.32
	return m


static func _tangent(pts: Array, i: int) -> Vector3:
	var n: int = pts.size()
	var a: Vector3 = pts[maxi(i - 1, 0)]
	var b: Vector3 = pts[mini(i + 1, n - 1)]
	var d: Vector3 = b - a
	if d.length() < 0.00001:
		return Vector3.UP
	return d.normalized()


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


static func _quad_out(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, inside: Vector3) -> void:
	# emit a quad whose Godot front face points away from `inside`
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


static func _tapered_box(w0: float, h0: float, w1: float, h1: float, ln: float, drop: float) -> ArrayMesh:
	# back face at z = 0 (w0 x h0), front face at z = -ln (w1 x h1), front lowered by `drop`
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var hw0: float = w0 * 0.5
	var hh0: float = h0 * 0.5
	var hw1: float = w1 * 0.5
	var hh1: float = h1 * 0.5
	var b0 := Vector3(-hw0, hh0, 0.0)
	var b1 := Vector3(hw0, hh0, 0.0)
	var b2 := Vector3(hw0, -hh0, 0.0)
	var b3 := Vector3(-hw0, -hh0, 0.0)
	var f0 := Vector3(-hw1, hh1 + drop, -ln)
	var f1 := Vector3(hw1, hh1 + drop, -ln)
	var f2 := Vector3(hw1, -hh1 + drop, -ln)
	var f3 := Vector3(-hw1, -hh1 + drop, -ln)
	var inside := Vector3(0.0, drop * 0.5, -ln * 0.5)
	_quad_out(st, b0, b1, b2, b3, inside)
	_quad_out(st, f0, f1, f2, f3, inside)
	_quad_out(st, b0, b1, f1, f0, inside)
	_quad_out(st, b3, b2, f2, f3, inside)
	_quad_out(st, b1, b2, f2, f1, inside)
	_quad_out(st, b0, b3, f3, f0, inside)
	st.generate_normals()
	return st.commit()


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


# ---------------------------------------------------------------------------
# textures painted in code

static func _blob(img: Image, cx: int, cy: int, rr: float, rim: float, core: float) -> void:
	var ri: int = int(ceil(rr)) + 1
	for dy in range(-ri, ri + 1):
		for dx in range(-ri, ri + 1):
			var dd: float = sqrt(float(dx * dx + dy * dy)) / maxf(rr, 0.5)
			if dd > 1.0:
				continue
			var edge: float = clampf((1.0 - dd) / 0.20, 0.0, 1.0)
			var inner: float = clampf((0.62 - dd) / 0.28, 0.0, 1.0)
			var g: float = lerpf(rim, core, inner)
			var px: int = posmod(cx + dx, TEX)
			var py: int = posmod(cy + dy, TEX)
			var was: Color = img.get_pixel(px, py)
			var nr: float = lerpf(was.r, g, edge)
			var ng: float = lerpf(was.g, g * 1.005, edge)
			var nb: float = lerpf(was.b, g * 0.99, edge)
			img.set_pixel(px, py, Color(nr, ng, nb))


static func _spot_texture(rng: RandomNumberGenerator) -> ImageTexture:
	# leopard skin: grey rosettes on off-white, seamless by wrapped rasterising
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	for y in range(TEX):
		for x in range(TEX):
			var fx: float = float(x) / float(TEX)
			var fy: float = float(y) / float(TEX)
			var m: float = 0.955 + 0.030 * sin(fx * TAU * 3.0 + 1.1) * sin(fy * TAU * 2.0)
			img.set_pixel(x, y, Color(m, m * 0.995, m * 0.975))
	var n_spots: int = rng.randi_range(19, 25)
	for _k in range(n_spots):
		var cx: int = rng.randi_range(0, TEX - 1)
		var cy: int = rng.randi_range(0, TEX - 1)
		var rr: float = rng.randf_range(7.5, 12.0)
		var rim: float = rng.randf_range(0.34, 0.44)
		var core: float = rng.randf_range(0.54, 0.64)
		_blob(img, cx, cy, rr, rim, core)
		var lobes: int = rng.randi_range(1, 2)
		for _l in range(lobes):
			var ox: int = cx + rng.randi_range(-9, 9)
			var oy: int = cy + rng.randi_range(-9, 9)
			_blob(img, ox, oy, rr * rng.randf_range(0.55, 0.85), rim, core)
	var n_dots: int = rng.randi_range(34, 52)
	for _k in range(n_dots):
		var dx2: int = rng.randi_range(0, TEX - 1)
		var dy2: int = rng.randi_range(0, TEX - 1)
		_blob(img, dx2, dy2, rng.randf_range(1.6, 3.2), 0.52, 0.58)
	return ImageTexture.create_from_image(img)


static func _grain_texture(rng: RandomNumberGenerator) -> ImageTexture:
	# near-white matt grain, so albedo_color carries the colour
	var img: Image = Image.create(GRAIN_TEX, GRAIN_TEX, false, Image.FORMAT_RGB8)
	var ph1: float = rng.randf_range(0.0, TAU)
	var ph2: float = rng.randf_range(0.0, TAU)
	for y in range(GRAIN_TEX):
		for x in range(GRAIN_TEX):
			var fx: float = float(x) / float(GRAIN_TEX)
			var fy: float = float(y) / float(GRAIN_TEX)
			var blot: float = 0.020 * sin(fx * TAU * 2.0 + ph1) * sin(fy * TAU * 3.0 + ph2)
			var speck: float = rng.randf_range(-0.022, 0.010)
			var v: float = clampf(0.985 + blot + speck, 0.86, 1.0)
			img.set_pixel(x, y, Color(v, v, v))
	return ImageTexture.create_from_image(img)


static func _coral_texture(rng: RandomNumberGenerator) -> ImageTexture:
	# pitted grey rubble, triplanar over the mound and its nubs
	var img: Image = Image.create(CORAL_TEX, CORAL_TEX, false, Image.FORMAT_RGB8)
	var ph1: float = rng.randf_range(0.0, TAU)
	var ph2: float = rng.randf_range(0.0, TAU)
	var ph3: float = rng.randf_range(0.0, TAU)
	for y in range(CORAL_TEX):
		for x in range(CORAL_TEX):
			var fx: float = float(x) / float(CORAL_TEX)
			var fy: float = float(y) / float(CORAL_TEX)
			var a: float = sin(fx * TAU * 4.0 + ph1) * sin(fy * TAU * 3.0 + ph2)
			var b: float = sin((fx + fy) * TAU * 7.0 + ph3)
			var v: float = 0.90 + 0.10 * a + 0.05 * b + rng.randf_range(-0.05, 0.05)
			# pits: a scatter of darker cells
			if rng.randf() < 0.05:
				v -= rng.randf_range(0.12, 0.26)
			v = clampf(v, 0.48, 1.0)
			img.set_pixel(x, y, Color(v, v * 1.005, v * 0.985))
	return ImageTexture.create_from_image(img)
