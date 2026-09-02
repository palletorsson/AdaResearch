extends RefCounted

## dream_bodies / dubuffet — one standing art-brut figure hacked out of painted blocks.
##
## Reference: scratchpad/refs/dubuffet.png (2048x536 panorama) — a gallery row of
## Dubuffet-ish standing figures built from chunky irregular slabs, each block tipped a
## few degrees off its neighbours so the limbs read as jammed stacks with visible steps
## and gaps. One matte colour per figure — dusty rose, saffron ochre, pale sky blue,
## cream — with a scatter of blocks in a second colour (a whole shin or forearm goes
## pale blue) and a cream wedge head laid on like a brick.
##
## Reproduced, and how:
##   1. The stacked-block body — every limb is a polyline SPINE (two legs, feet, hips,
##      torso, shoulder bar, two arms, neck) clad by walking its arclength and dropping
##      BoxMesh slabs; block length comes from the limb's girth, not the step, so a leg
##      shows pinches and gaps where a short block lands on a long stride.
##   2. Art-brut roughness — each block is turned 3..25 degrees on ALL THREE axes and
##      shoved up to 30% of the girth off the limb axis, so no two facets line up.
##   3. Contrapposto — weight on one leg (chosen by seed): that hip rides high and its
##      shoulder drops, the free leg steps out and back with the knee pushed forward,
##      and the torso sways toward the free side.
##   4. The hanging arm and the working arm — the free-side arm hangs long and nearly
##      straight past the thigh; the weight-side arm bends with the elbow out and the
##      forearm swung forward.
##   5. The cocked wedge head — 3..5 blocks around one wide horizontal brick, yawed
##      up to 26 deg and cocked 9..22 deg, painted in the cream head colour like the
##      pink figures in the reference.
##   6. Chalky paint — a 128x128 ImageTexture drawn in code (wrapped value-noise bloom,
##      fine grain, faint trowel streaks), triplanar so one grain runs unbroken across
##      the whole stack; roughness 0.95, no metal, no clearcoat.
##   7. Per-block colour jitter of a few percent, so the mass reads as painted plaster
##      rather than one flat plastic colour.
##   8. Jammed shims — seven extra slabs rammed into knees, hip corners, shoulders and
##      the pelvis front, protruding, the way a plaster figure gets patched.
##
## Given up: the neighbouring figures leaning on each other, the gallery, the sawn
## end-grain of the real material, the deep undercut hollows carved between the legs
## of the ochre group, and any face — the head stays a blank brick.

const TEX_SIZE: int = 128
const LAT: int = 8

# scheme: [main, accent, head]
const SCHEMES: Array = [
	["#DCA7BC", "#B2D0E2", "#F0DCBB"],
	["#E2BC6E", "#B2D0E2", "#F1E1BA"],
	["#B0CFE1", "#DCA7BC", "#F2E2C4"],
	["#EEDCB6", "#D69BB2", "#E2BC6E"],
	["#D69BB2", "#F0DCBB", "#B2D0E2"],
]


static func describe() -> String:
	return "A standing art-brut figure hacked out of chunky tipped slabs of matte chalky paint, weight on one leg, one arm hanging, a cream brick of a head cocked to the side."


static func build(root: Node3D, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	var scheme: Array = SCHEMES[rng.randi_range(0, SCHEMES.size() - 1)]
	var col_main: Color = Color(scheme[0])
	var col_accent: Color = Color(scheme[1])
	var col_head: Color = Color(scheme[2])
	var tex: ImageTexture = _chalk_texture(rng)

	var body: Dictionary = {"main": col_main, "accent": col_accent, "p": 0.05, "tex": tex}
	var hot: Dictionary = {"main": col_main, "accent": col_accent, "p": 0.80, "tex": tex}
	var mid: Dictionary = {"main": col_main, "accent": col_accent, "p": 0.13, "tex": tex}
	var skull: Dictionary = {"main": col_head, "accent": col_main, "p": 0.16, "tex": tex}

	# --- individual: stance, proportion, gesture ---------------------------------
	var wt: float = 1.0 if rng.randf() < 0.5 else -1.0
	var hip_y: float = rng.randf_range(0.79, 0.85)
	var hip_dx: float = rng.randf_range(0.112, 0.142)
	var hip_tilt: float = rng.randf_range(0.024, 0.048)
	var trunk: float = rng.randf_range(0.42, 0.49)
	var sh_y: float = hip_y + trunk
	var sh_dx: float = rng.randf_range(0.180, 0.220)
	var sh_tilt: float = rng.randf_range(0.020, 0.044)
	var lean_z: float = rng.randf_range(-0.050, 0.045)
	var sway: float = rng.randf_range(0.020, 0.055)
	var step_out: float = rng.randf_range(0.045, 0.085)
	var head_cock: float = _sang(rng, 9.0, 22.0)
	var head_yaw: float = _sang(rng, 6.0, 26.0)
	var head_pitch: float = _sang(rng, 3.0, 11.0)
	var accent_leg: float = 1.0 if rng.randf() < 0.5 else -1.0
	var accent_arm: float = 1.0 if rng.randf() < 0.5 else -1.0

	# --- skeleton ---------------------------------------------------------------
	# weight-bearing leg: hip rides high, the column is almost straight
	var st_hip := Vector3(wt * hip_dx, hip_y + hip_tilt, 0.006)
	var st_knee := Vector3(wt * (hip_dx + 0.010), hip_y * 0.50, -0.014)
	var st_ankle := Vector3(wt * (hip_dx - 0.008), 0.090, 0.020)
	var st_toe := Vector3(wt * (hip_dx - 0.012), 0.048, -0.085)

	# free leg: steps out and back, knee shoved forward
	var fr_hip := Vector3(-wt * hip_dx, hip_y - hip_tilt, 0.004)
	var fr_knee := Vector3(-wt * (hip_dx + step_out * 0.7), hip_y * 0.52, -0.062)
	var fr_ankle := Vector3(-wt * (hip_dx + step_out), 0.098, 0.038)
	var fr_toe := Vector3(-wt * (hip_dx + step_out + 0.012), 0.050, -0.062)

	var pelvis := Vector3(0.0, hip_y + hip_tilt * 0.1, 0.0)
	var waist_y: float = lerpf(hip_y, sh_y, 0.34)
	var chest_y: float = lerpf(hip_y, sh_y, 0.72)
	var waist := Vector3(-wt * sway * 0.55, waist_y, lean_z * 0.30)
	var chest := Vector3(-wt * sway, chest_y, lean_z * 0.85)
	var sh_c := Vector3(-wt * sway * 0.75, sh_y, lean_z)

	# shoulders counter-tilt against the hips
	var sh_wt := sh_c + Vector3(wt * sh_dx, -sh_tilt, 0.004)
	var sh_fr := sh_c + Vector3(-wt * sh_dx, sh_tilt, -0.004)

	# the free-side arm hangs; the weight-side arm bends forward
	var hang_el := sh_fr + Vector3(-wt * 0.036, -0.235, 0.014)
	var hang_wr := hang_el + Vector3(-wt * 0.022, -0.245, -0.032)
	var bent_el := sh_wt + Vector3(wt * 0.078, -0.215, 0.026)
	var bent_wr := bent_el + Vector3(-wt * 0.026, -0.168, -0.152)

	var neck_a := sh_c + Vector3(0.0, 0.010, lean_z * 0.10)
	var neck_b := neck_a + Vector3(sin(head_cock) * 0.040, 0.098, -0.012)

	# --- cladding ---------------------------------------------------------------
	var leg_hot: Dictionary = hot if accent_leg == wt else body
	var leg_cold: Dictionary = body if accent_leg == wt else hot
	var arm_hot: Dictionary = hot if accent_arm == wt else body
	var arm_cold: Dictionary = body if accent_arm == wt else hot

	_clad(root, [st_hip, st_knee], rng.randi_range(5, 6), 0.160, 0.135, 0.86, 0.55, 1.25, 0.26, body, rng)
	_clad(root, [st_knee, st_ankle], rng.randi_range(5, 6), 0.130, 0.108, 0.88, 0.55, 1.30, 0.28, leg_hot, rng)
	_clad(root, [st_ankle, st_toe], 3, 0.115, 0.098, 1.20, 0.60, 1.10, 0.20, body, rng)

	_clad(root, [fr_hip, fr_knee], rng.randi_range(5, 6), 0.156, 0.130, 0.86, 0.55, 1.25, 0.26, body, rng)
	_clad(root, [fr_knee, fr_ankle], rng.randi_range(5, 6), 0.126, 0.104, 0.88, 0.55, 1.30, 0.28, leg_cold, rng)
	_clad(root, [fr_ankle, fr_toe], 3, 0.112, 0.096, 1.20, 0.60, 1.10, 0.20, body, rng)

	_clad(root, [fr_hip, pelvis, st_hip], rng.randi_range(6, 7), 0.172, 0.172, 1.02, 0.60, 1.15, 0.22, mid, rng)
	_clad(root, [pelvis, waist, chest, sh_c], rng.randi_range(16, 21), 0.205, 0.248, 0.70, 0.45, 1.05, 0.30, body, rng)
	_clad(root, [sh_fr, sh_c, sh_wt], rng.randi_range(5, 6), 0.150, 0.150, 1.05, 0.60, 1.20, 0.24, mid, rng)

	_clad(root, [sh_fr, hang_el], rng.randi_range(5, 6), 0.118, 0.102, 0.90, 0.55, 1.25, 0.26, body, rng)
	_clad(root, [hang_el, hang_wr], rng.randi_range(5, 6), 0.100, 0.086, 0.90, 0.55, 1.30, 0.28, arm_hot, rng)
	_clad(root, [sh_wt, bent_el], rng.randi_range(5, 6), 0.118, 0.102, 0.90, 0.55, 1.25, 0.26, body, rng)
	_clad(root, [bent_el, bent_wr], rng.randi_range(5, 6), 0.100, 0.086, 0.90, 0.55, 1.30, 0.28, arm_cold, rng)

	_clad(root, [neck_a, neck_b], 3, 0.106, 0.094, 0.92, 0.55, 1.05, 0.16, body, rng)

	# hands: the only smooth pieces, and cut to six facets so they stay hacked
	for hand_i in range(2):
		var hp: Vector3 = hang_wr if hand_i == 0 else bent_wr
		var hd: Vector3 = (hang_wr - hang_el) if hand_i == 0 else (bent_wr - bent_el)
		var lump := SphereMesh.new()
		lump.radius = rng.randf_range(0.046, 0.056)
		lump.height = lump.radius * 1.75
		lump.radial_segments = 6
		lump.rings = 3
		var lm: MeshInstance3D = _add(root, lump, _paint(body, rng))
		lm.transform = Transform3D(_basis_y_to(hd) * _wobble(rng), hp + hd.normalized() * 0.030)

	# --- the head: a brick laid on, cocked ---------------------------------------
	var hb: Basis = Basis.from_euler(Vector3(head_pitch, head_yaw, head_cock))
	var h_org: Vector3 = neck_b + Vector3(sin(head_cock) * 0.050, 0.072, -0.008)
	var brick_w: float = rng.randf_range(0.235, 0.275)
	var brick_h: float = rng.randf_range(0.115, 0.145)
	var brick_d: float = rng.randf_range(0.145, 0.180)
	_block(root, h_org, hb * _wobble(rng), Vector3(brick_w, brick_h, brick_d), _paint(skull, rng))
	_block(root, h_org + hb * Vector3(rng.randf_range(-0.030, 0.030), brick_h * 0.60, rng.randf_range(-0.030, 0.020)), hb * _wobble(rng), Vector3(brick_w * 0.72, rng.randf_range(0.060, 0.085), brick_d * 0.78), _paint(skull, rng))
	_block(root, h_org + hb * Vector3(rng.randf_range(-0.040, 0.040), -brick_h * 0.34, -brick_d * 0.62), hb * _wobble(rng), Vector3(rng.randf_range(0.100, 0.145), rng.randf_range(0.075, 0.105), rng.randf_range(0.085, 0.120)), _paint(skull, rng))
	var extra_head: int = rng.randi_range(0, 2)
	for k in range(extra_head):
		var sd: float = 1.0 if k == 0 else -1.0
		var off: Vector3 = Vector3(sd * brick_w * rng.randf_range(0.34, 0.48), rng.randf_range(-0.045, 0.045), rng.randf_range(-0.030, 0.045))
		_block(root, h_org + hb * off, hb * _wobble(rng), Vector3(rng.randf_range(0.075, 0.110), rng.randf_range(0.070, 0.100), rng.randf_range(0.070, 0.105)), _paint(skull, rng))

	# --- shims: slabs rammed into the joints, left protruding ---------------------
	var shim_pts: Array = [st_knee, fr_knee, st_hip, fr_hip, sh_wt, sh_fr, pelvis + Vector3(0.0, 0.02, -0.09)]
	for k in range(shim_pts.size()):
		var sp: Vector3 = shim_pts[k]
		var jj: Vector3 = Vector3(rng.randf_range(-0.045, 0.045), rng.randf_range(-0.035, 0.035), rng.randf_range(-0.050, 0.050))
		var shim_paint: Dictionary = mid if (k % 3) == 0 else body
		_block(root, sp + jj, _wobble(rng), Vector3(rng.randf_range(0.090, 0.185), rng.randf_range(0.060, 0.105), rng.randf_range(0.075, 0.150)), _paint(shim_paint, rng))

	# --- centre on x/z, fit the 1.25 m box, then the measured settle ---------------
	var box: AABB = _union_aabb(root)
	var ctr: Vector3 = box.position + box.size * 0.5
	_shift_all(root, Vector3(-ctr.x, 0.0, -ctr.z))

	box = _union_aabb(root)
	var kx: float = 1.22 / maxf(box.size.x, 0.001)
	var kz: float = 1.22 / maxf(box.size.z, 0.001)
	var ky: float = 1.66 / maxf(box.size.y, 0.001)
	var kfit: float = minf(1.0, minf(kx, minf(kz, ky)))
	if kfit < 0.999:
		_scale_all(root, kfit)
		box = _union_aabb(root)
		ctr = box.position + box.size * 0.5
		_shift_all(root, Vector3(-ctr.x, 0.0, -ctr.z))

	# SETTLE: merge every child's world AABB and plant the lowest point on y = 0
	box = _union_aabb(root)
	if absf(box.position.y) > 0.0005:
		_shift_all(root, Vector3(0.0, -box.position.y, 0.0))


# ---------------------------------------------------------------------------
# cladding

static func _clad(root: Node3D, pts: Array, n: int, g0: float, g1: float, dk: float, lf0: float, lf1: float, jit: float, paint: Dictionary, rng: RandomNumberGenerator) -> void:
	for i in range(n):
		var t: float = (float(i) + 0.5) / float(n)
		var p: Vector3 = _poly_at(pts, t)
		var dir: Vector3 = _poly_dir(pts, t)
		var bs: Basis = _basis_y_to(dir)
		var g: float = lerpf(g0, g1, t)
		var w: float = clampf(g * rng.randf_range(0.82, 1.32), 0.060, 0.280)
		var d: float = clampf(g * dk * rng.randf_range(0.76, 1.24), 0.060, 0.280)
		var ln: float = clampf(g * rng.randf_range(lf0, lf1), 0.060, 0.280)
		var jx: float = g * rng.randf_range(-jit, jit)
		var jz: float = g * dk * rng.randf_range(-jit, jit)
		var jy: float = ln * rng.randf_range(-0.14, 0.14)
		var org: Vector3 = p + bs * Vector3(jx, jy, jz)
		_block(root, org, bs * _wobble(rng), Vector3(w, ln, d), _paint(paint, rng))


static func _wobble(rng: RandomNumberGenerator) -> Basis:
	return Basis.from_euler(Vector3(_sang(rng, 3.0, 25.0), _sang(rng, 3.0, 25.0), _sang(rng, 3.0, 25.0)))


static func _sang(rng: RandomNumberGenerator, lo: float, hi: float) -> float:
	var a: float = deg_to_rad(rng.randf_range(lo, hi))
	if rng.randf() < 0.5:
		return -a
	return a


static func _block(root: Node3D, org: Vector3, bs: Basis, sz: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var bx := BoxMesh.new()
	bx.size = sz
	var mi: MeshInstance3D = _add(root, bx, mat)
	mi.transform = Transform3D(bs, org)
	return mi


static func _add(root: Node3D, mesh: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
	return mi


# ---------------------------------------------------------------------------
# paint

static func _paint(paint: Dictionary, rng: RandomNumberGenerator) -> StandardMaterial3D:
	var main: Color = paint["main"]
	var accent: Color = paint["accent"]
	var p: float = paint["p"]
	var tex: ImageTexture = paint["tex"]
	var c: Color = accent if rng.randf() < p else main
	var lift: float = rng.randf_range(-0.045, 0.045)
	var warm: float = rng.randf_range(-0.016, 0.016)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(
		clampf(c.r + lift + warm, 0.0, 1.0),
		clampf(c.g + lift, 0.0, 1.0),
		clampf(c.b + lift - warm, 0.0, 1.0))
	m.roughness = 0.95
	m.metallic = 0.0
	m.metallic_specular = 0.18
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(1.9, 1.9, 1.9)
	return m


static func _chalk_texture(rng: RandomNumberGenerator) -> ImageTexture:
	# wrapped value-noise bloom + fine grain + faint trowel streaks, near-white so
	# albedo_color tints it; triplanar keeps one grain across the whole block stack
	var lat: Array = []
	for i in range(LAT * LAT):
		lat.append(rng.randf())
	var img: Image = Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGB8)
	var ph: float = rng.randf() * TAU
	var streak_n: float = float(rng.randi_range(2, 4))
	for y in range(TEX_SIZE):
		for x in range(TEX_SIZE):
			var fx: float = float(x) / float(TEX_SIZE) * float(LAT)
			var fy: float = float(y) / float(TEX_SIZE) * float(LAT)
			var x0: int = int(floor(fx))
			var y0: int = int(floor(fy))
			var ux: float = fx - float(x0)
			var uy: float = fy - float(y0)
			ux = ux * ux * (3.0 - 2.0 * ux)
			uy = uy * uy * (3.0 - 2.0 * uy)
			var v00: float = lat[posmod(y0, LAT) * LAT + posmod(x0, LAT)]
			var v10: float = lat[posmod(y0, LAT) * LAT + posmod(x0 + 1, LAT)]
			var v01: float = lat[posmod(y0 + 1, LAT) * LAT + posmod(x0, LAT)]
			var v11: float = lat[posmod(y0 + 1, LAT) * LAT + posmod(x0 + 1, LAT)]
			var top: float = lerpf(v00, v10, ux)
			var bot: float = lerpf(v01, v11, ux)
			var bloom: float = lerpf(top, bot, uy)
			var grain: float = rng.randf()
			var streak: float = sin(fy / float(LAT) * TAU * streak_n + ph + bloom * 2.4)
			var v: float = 0.965 + 0.070 * (bloom - 0.5) + 0.050 * (grain - 0.5) + 0.026 * streak
			v = clampf(v, 0.78, 1.0)
			img.set_pixel(x, y, Color(v, v * 0.996, v * 0.988))
	return ImageTexture.create_from_image(img)


# ---------------------------------------------------------------------------
# geometry helpers

static func _poly_len(pts: Array) -> float:
	var total: float = 0.0
	for i in range(pts.size() - 1):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		total += (b - a).length()
	return total


static func _poly_at(pts: Array, s: float) -> Vector3:
	var total: float = _poly_len(pts)
	var want: float = clampf(s, 0.0, 1.0) * total
	var acc: float = 0.0
	var last: int = pts.size() - 2
	for i in range(pts.size() - 1):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var ln: float = (b - a).length()
		if acc + ln >= want or i == last:
			var u: float = 0.0 if ln < 0.0001 else (want - acc) / ln
			return a + (b - a) * clampf(u, 0.0, 1.0)
		acc += ln
	return pts[pts.size() - 1]


static func _poly_dir(pts: Array, s: float) -> Vector3:
	var total: float = _poly_len(pts)
	var want: float = clampf(s, 0.0, 1.0) * total
	var acc: float = 0.0
	var last: int = pts.size() - 2
	for i in range(pts.size() - 1):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var ln: float = (b - a).length()
		if acc + ln >= want or i == last:
			var dd: Vector3 = b - a
			if dd.length() < 0.0001:
				return Vector3.UP
			return dd.normalized()
		acc += ln
	return Vector3.UP


static func _basis_y_to(dir: Vector3) -> Basis:
	var d: Vector3 = dir.normalized()
	if d.length() < 0.5:
		return Basis()
	var dot_up: float = d.dot(Vector3.UP)
	if dot_up > 0.9999:
		return Basis()
	if dot_up < -0.9999:
		return Basis(Vector3.RIGHT, PI)
	var ax: Vector3 = Vector3.UP.cross(d).normalized()
	var ang: float = acos(clampf(dot_up, -1.0, 1.0))
	return Basis(ax, ang)


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


static func _shift_all(root: Node3D, d: Vector3) -> void:
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		cm.transform = Transform3D(cm.transform.basis, cm.transform.origin + d)


static func _scale_all(root: Node3D, k: float) -> void:
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm: MeshInstance3D = ch
		var tf: Transform3D = cm.transform
		cm.transform = Transform3D(tf.basis.scaled(Vector3(k, k, k)), tf.origin * k)
