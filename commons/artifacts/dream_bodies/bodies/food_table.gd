extends RefCounted

## dream_bodies / food_table — a Wesselmann still life stacked into a tower.
##
## Reference: scratchpad/refs/wesselmann.png (2048x536 panorama) — a long banquet
## of glossy plastic-looking food raised on white porcelain cake stands: golden
## bread wedges and pale cut cubes, maroon ham slabs stacked like masonry, red
## tomatoes, dark and dusty-red grape bunches, chopped orange carrot, curly green
## lettuce, a lemon, a white bottle, a white bowl heaped with red berries, a
## whipped-cream swirl, a pink high-heeled shoe standing at the left and a dark
## pitted cake at the right. I build ONE stand-tower out of it, not the table.
##
## Reproduced, and how:
##   1. The three-tier stand — CylinderMesh foot / stem / plate with a turned
##      SphereMesh knop and a TorusMesh rim, each tier smaller and offset from
##      the one below, so the stems climb up THROUGH the food the way the
##      reference's stands do rather than standing clear of it.
##   2. The heap, not a ring — every solid is placed by polar sampling with a
##      dome-shaped rise (middle high, rim low) and a random lean, so the food
##      piles, leans on itself and hangs over the plate edges.
##   3. Bread — ArrayMesh loaves: a half-ellipse profile extruded along Z and
##      tapered to one end (a cut wedge with a flat bottom), plus small pale cut
##      cubes; both wear a crumb texture painted in code, run triplanar so the
##      speckle does not break at the wedge's edges.
##   4. Ham — chunky boxes at random leans wearing a horizontally stretched
##      marbling texture (white fat streaks through maroon): the reference's
##      stacked meat masonry.
##   5. Grapes — 3..4 bunches of 14..22 spheres on a spiralling cone hung from a
##      stem, each cascading over a plate rim, dark blue-black or dusty red, the
##      berry size and the drop of every bunch drawn from the seed.
##   6. Lettuce — ArrayMesh blades: a lofted grid with a leaf-shaped width, a
##      curl that lifts along the length and a sine ruffle at the edges, double
##      sided, planted at the rims and splayed outward.
##   7. Turned porcelain — one lathe helper revolves a closed 2D profile into
##      both the bottle and the berry bowl; the cream on top is a swirl of
##      squashed spheres shrinking up a spiral with a berry set in it.
##   8. The pink stiletto — a lofted sole ribbon that climbs from toe to heel,
##      squashed-sphere vamp and heel counter, a tapered spike, tipped toward
##      the stand with its toe turned out, its own low point solved for so it
##      stands on the same floor as the foot.
##
## Given up: the table and the second and third stands of the panorama, the
## forks and spoons lying in the food, the egg, the pancakes and the printed
## label on the tube of cream, and the painted cast shadows.

const TEX: int = 128


static func describe() -> String:
	return "A Wesselmann still life built as a statue: three white cake stands climbing through a glossy heap of bread, ham, tomatoes, grapes, carrots and lettuce, with a bottle, a bowl of berries, a cream swirl on top and a pink stiletto leaning at the foot."


static func build(root: Node3D, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# ---- palette ----------------------------------------------------------
	var c_porcelain: Color = Color("#F2F0EA").lerp(Color("#FCFBF6"), rng.randf())
	var c_crust: Color = Color("#CE9C5E").lerp(Color("#E3BA80"), rng.randf())
	var c_pale: Color = Color("#E7CB96").lerp(Color("#F3E0B6"), rng.randf())
	var c_ham: Color = Color("#A2454F").lerp(Color("#C06A70"), rng.randf())
	var c_tomato: Color = Color("#CE3227").lerp(Color("#DC4536"), rng.randf())
	var c_berry := Color("#C62A22")
	var c_carrot: Color = Color("#DE6C1B").lerp(Color("#F08A2C"), rng.randf())
	var c_leaf: Color = Color("#6AA338").lerp(Color("#8CC24E"), rng.randf())
	var c_lemon := Color("#EFC220")
	var c_cake := Color("#46301F")
	var c_cream := Color("#FBF4E6")
	var c_shoe: Color = Color("#EFA9BC").lerp(Color("#F7C8D5"), rng.randf())
	var c_shoe_deep := Color("#C9647F")
	var c_stem := Color("#7C8C4A")
	var grape_cols: Array = [Color("#38334E"), Color("#2E2C42"), Color("#9A6572"), Color("#8A5A68")]

	# ---- painted surfaces --------------------------------------------------
	var tex_crumb: ImageTexture = _mottle(rng, 0.86, 0.60, 1.00, 240, 1.4, 3.8, 1.0)
	var tex_marble: ImageTexture = _mottle(rng, 0.80, 0.72, 1.00, 150, 1.2, 3.0, 3.4)
	var tex_pit: ImageTexture = _mottle(rng, 0.74, 0.40, 1.00, 420, 0.9, 2.4, 1.0)
	var tex_rind: ImageTexture = _mottle(rng, 0.92, 0.78, 1.00, 620, 0.7, 1.5, 1.0)

	var mat_white: StandardMaterial3D = _gloss(c_porcelain, 0.13)
	var mat_cream: StandardMaterial3D = _gloss(c_cream, 0.20)
	var mat_stem: StandardMaterial3D = _gloss(c_stem, 0.30)

	var kit := {
		"crust": c_crust,
		"pale": c_pale,
		"ham": c_ham,
		"tomato": c_tomato,
		"carrot": c_carrot,
		"leaf": c_leaf,
		"crumb": tex_crumb,
		"marble": tex_marble,
	}

	# ---- the three tiers ---------------------------------------------------
	var r_a: float = rng.randf_range(0.300, 0.340)
	var y_a: float = rng.randf_range(0.300, 0.340)
	var r_b: float = rng.randf_range(0.185, 0.220)
	var y_b: float = y_a + rng.randf_range(0.395, 0.445)
	var r_c: float = rng.randf_range(0.105, 0.130)
	var y_c: float = y_b + rng.randf_range(0.315, 0.360)
	var off_b := Vector3(rng.randf_range(-0.050, 0.050), 0.0, rng.randf_range(-0.045, 0.045))
	var off_c: Vector3 = off_b + Vector3(rng.randf_range(-0.038, 0.038), 0.0, rng.randf_range(-0.038, 0.038))

	var top_a := Vector3(0.0, y_a, 0.0)
	var top_b := Vector3(off_b.x, y_b, off_b.z)
	var top_c := Vector3(off_c.x, y_c, off_c.z)

	_stand(root, Vector3.ZERO, y_a, r_a, mat_white)
	_stand(root, Vector3(off_b.x, y_a, off_b.z), y_b, r_b, mat_white)
	_stand(root, Vector3(off_c.x, y_b, off_c.z), y_c, r_c, mat_white)

	# the sector kept clear on the bottom plate for the bottle and the cake
	var keep_a: float = rng.randf_range(0.0, TAU)
	var keep_b: float = rng.randf_range(0.0, TAU)

	# ---- the bottom heap ---------------------------------------------------
	_heap(root, rng, kit, top_a, r_a * 0.98, 0.115, 1.00, keep_a, 0.80,
		rng.randi_range(6, 9), rng.randi_range(5, 8), rng.randi_range(3, 5),
		rng.randi_range(5, 8), rng.randi_range(4, 7), rng.randi_range(2, 3))

	# bottle, standing in the kept sector at the back of the bottom plate
	var b_ang: float = keep_a - 0.34
	var b_rad: float = r_a * rng.randf_range(0.58, 0.70)
	var bottle_pos := Vector3(top_a.x + cos(b_ang) * b_rad, y_a + 0.006, top_a.z + sin(b_ang) * b_rad)
	var bottle_h: float = rng.randf_range(0.290, 0.335)
	_bottle(root, bottle_pos, bottle_h, mat_white, rng.randf_range(0.0, TAU))

	# the dark pitted cake, leaning in the same kept sector
	var k_ang: float = keep_a + 0.40
	var k_rad: float = r_a * rng.randf_range(0.60, 0.78)
	var cake_pos := Vector3(top_a.x + cos(k_ang) * k_rad, y_a, top_a.z + sin(k_ang) * k_rad)
	var cake_w: float = rng.randf_range(0.062, 0.082)
	var cake_h: float = rng.randf_range(0.085, 0.115)
	var cake_msh: ArrayMesh = _extrude(_loaf_profile(cake_w, cake_h, 6), rng.randf_range(0.10, 0.14), rng.randf_range(0.28, 0.48))
	var mat_cake: StandardMaterial3D = _tex_mat(c_cake, tex_pit, 9.0, 0.22)
	var cake_bs: Basis = _rand_basis(rng, 0.16)
	_add(root, cake_msh, mat_cake, cake_bs, cake_pos + Vector3(0.0, 0.010, 0.0))
	for i in range(3):
		var lump := SphereMesh.new()
		lump.radius = rng.randf_range(0.020, 0.030)
		lump.height = lump.radius * 1.7
		var lp: Vector3 = cake_pos + cake_bs * Vector3(rng.randf_range(-0.030, 0.030), cake_h * rng.randf_range(0.86, 1.02), rng.randf_range(-0.045, 0.045))
		_add(root, lump, mat_cake, _rand_basis(rng, 0.5), lp)

	# ---- the middle heap ---------------------------------------------------
	_heap(root, rng, kit, top_b, r_b * 0.98, 0.095, 0.86, keep_b, 0.72,
		rng.randi_range(3, 5), rng.randi_range(3, 5), rng.randi_range(2, 3),
		rng.randi_range(3, 5), rng.randi_range(2, 4), rng.randi_range(1, 2))

	# the white bowl of berries, in the middle plate's kept sector
	var bowl_rad: float = r_b * rng.randf_range(0.42, 0.56)
	var bowl_pos := Vector3(top_b.x + cos(keep_b) * bowl_rad, y_b + 0.004, top_b.z + sin(keep_b) * bowl_rad)
	var bowl_r: float = rng.randf_range(0.062, 0.078)
	var bowl_h: float = rng.randf_range(0.050, 0.064)
	_add(root, _bowl_mesh(bowl_r, bowl_r * 0.52, bowl_h, 0.008), mat_white, Basis(), bowl_pos)
	var n_bowl: int = rng.randi_range(10, 15)
	for i in range(n_bowl):
		var t: float = float(i) / float(n_bowl)
		var ba: float = t * 6.2 + rng.randf_range(-0.4, 0.4)
		var br: float = bowl_r * 0.72 * sqrt(rng.randf())
		var brad: float = rng.randf_range(0.015, 0.021)
		var sph := SphereMesh.new()
		sph.radius = brad
		sph.height = brad * 1.9
		var bp: Vector3 = bowl_pos + Vector3(cos(ba) * br, bowl_h * 0.78 + rng.randf_range(-0.006, 0.026), sin(ba) * br)
		_add(root, sph, _gloss(c_berry.lightened(rng.randf_range(0.0, 0.16)), 0.14), _rand_basis(rng, 0.9), bp)

	# a whole lemon, wedged into the middle heap
	var l_ang: float = keep_b + rng.randf_range(2.0, 4.2)
	var l_rad: float = r_b * rng.randf_range(0.50, 0.80)
	var lemon_r: float = rng.randf_range(0.040, 0.050)
	var lemon_pos := Vector3(top_b.x + cos(l_ang) * l_rad, y_b + lemon_r * 0.80, top_b.z + sin(l_ang) * l_rad)
	var lemon_bs: Basis = _rand_basis(rng, 0.7).scaled(Vector3(1.0, 0.84, 1.0))
	var lemon := SphereMesh.new()
	lemon.radius = lemon_r
	lemon.height = lemon_r * 2.0
	var mat_lemon: StandardMaterial3D = _tex_mat(c_lemon, tex_rind, 14.0, 0.14)
	_add(root, lemon, mat_lemon, lemon_bs, lemon_pos)
	for s in [-1.0, 1.0]:
		var sg: float = s
		var nub_dir: Vector3 = (lemon_bs * Vector3(sg, 0.0, 0.0)).normalized()
		_cone(root, lemon_pos + nub_dir * (lemon_r * 0.92), nub_dir, 0.016, 0.010, mat_lemon)

	# ---- the crown: berries and cream on the top plate ---------------------
	var n_top_berry: int = rng.randi_range(6, 10)
	for i in range(n_top_berry):
		var ta: float = rng.randf_range(0.0, TAU)
		var tr: float = r_c * rng.randf_range(0.45, 0.95)
		var brad2: float = rng.randf_range(0.016, 0.023)
		var sph2 := SphereMesh.new()
		sph2.radius = brad2
		sph2.height = brad2 * 1.9
		var cal: Vector3 = top_c + Vector3(cos(ta) * tr, brad2 * 0.85, sin(ta) * tr)
		_add(root, sph2, _gloss(c_berry.lightened(rng.randf_range(0.0, 0.20)), 0.14), _rand_basis(rng, 1.0), cal)
	var n_cream: int = rng.randi_range(6, 8)
	var cream_phase: float = rng.randf_range(0.0, TAU)
	var cream_top: float = 0.0
	for i in range(n_cream):
		var t2: float = float(i) / float(n_cream - 1)
		var swr: float = r_c * 0.42 * (1.0 - t2) + 0.004
		var sa: float = cream_phase + t2 * rng.randf_range(4.4, 6.4)
		var crad: float = lerpf(r_c * 0.48, r_c * 0.15, t2)
		var dol := SphereMesh.new()
		dol.radius = crad
		dol.height = crad * 1.6
		var cy: float = 0.020 + t2 * rng.randf_range(0.130, 0.160)
		cream_top = cy + crad
		_add(root, dol, mat_cream, Basis(Vector3.UP, sa), top_c + Vector3(cos(sa) * swr, cy, sin(sa) * swr))
	var crown := SphereMesh.new()
	crown.radius = 0.022
	crown.height = 0.042
	_add(root, crown, _gloss(c_berry, 0.13), _rand_basis(rng, 1.0), top_c + Vector3(0.0, cream_top + 0.006, 0.0))

	# ---- grape bunches, cascading over the rims ----------------------------
	var n_bunch: int = rng.randi_range(3, 4)
	for i in range(n_bunch):
		var plate_c: Vector3 = top_a
		var plate_r: float = r_a
		if i == 1:
			plate_c = top_b
			plate_r = r_b
		elif i == 3:
			plate_c = top_c
			plate_r = r_c
		var ga: float = rng.randf_range(0.0, TAU)
		if i == 0:
			ga = keep_a + PI + rng.randf_range(-0.6, 0.6)
		var outw := Vector3(cos(ga), 0.0, sin(ga))
		var hang_in: bool = (i == 2)
		# one bunch lies ACROSS the heap and spills toward the rim; the others
		# are hung on the rim itself and fall clear of the plate
		var f_rad: float = 0.30 if hang_in else 0.94
		var f_lift: float = 0.085 if hang_in else 0.02
		var f_out: float = 0.90 if hang_in else 0.60
		var f_down: float = 0.42 if hang_in else 1.00
		var anchor: Vector3 = plate_c + outw * (plate_r * f_rad) + Vector3(0.0, f_lift, 0.0)
		var drop: Vector3 = (outw * f_out + Vector3(0.0, -f_down, 0.0)).normalized()
		var gc: Color = grape_cols[rng.randi_range(0, grape_cols.size() - 1)]
		_grapes(root, rng, anchor, drop, rng.randi_range(14, 22), gc, mat_stem)

	# ---- the pink shoe, leaning on the foot of the stand -------------------
	_shoe(root, rng, r_a, c_shoe, c_shoe_deep)

	# ---- measured settle: fit, centre on x/z, stand on y = 0 ---------------
	var box: AABB = _union_aabb(root)
	var k_max: float = minf(1.20 / maxf(box.size.x, 0.001), minf(1.20 / maxf(box.size.z, 0.001), 1.68 / maxf(box.size.y, 0.001)))
	var k_min: float = 1.06 / maxf(box.size.y, 0.001)
	var kfit: float = 1.0
	if k_max < 1.0:
		kfit = k_max
	elif k_min > 1.0:
		kfit = minf(k_min, k_max)
	if absf(kfit - 1.0) > 0.001:
		for ch in root.get_children():
			if not (ch is MeshInstance3D):
				continue
			var cm: MeshInstance3D = ch
			var tf: Transform3D = cm.transform
			cm.transform = Transform3D(tf.basis.scaled(Vector3(kfit, kfit, kfit)), tf.origin * kfit)
		box = _union_aabb(root)
	var ctr: Vector3 = box.position + box.size * 0.5
	var shift := Vector3(-ctr.x, -box.position.y, -ctr.z)
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm2: MeshInstance3D = ch
		cm2.transform = Transform3D(cm2.transform.basis, cm2.transform.origin + shift)


# ---------------------------------------------------------------------------
# the stand

static func _stand(root: Node3D, base: Vector3, top_y: float, plate_r: float, mat: StandardMaterial3D) -> void:
	var foot := CylinderMesh.new()
	foot.top_radius = plate_r * 0.34
	foot.bottom_radius = plate_r * 0.50
	foot.height = 0.030
	foot.radial_segments = 28
	_add(root, foot, mat, Basis(), base + Vector3(0.0, 0.015, 0.0))

	var stem_h: float = maxf(top_y - base.y - 0.062, 0.06)
	var stem := CylinderMesh.new()
	stem.top_radius = plate_r * 0.115
	stem.bottom_radius = plate_r * 0.170
	stem.height = stem_h
	stem.radial_segments = 20
	_add(root, stem, mat, Basis(), base + Vector3(0.0, 0.030 + stem_h * 0.5, 0.0))

	var knop := SphereMesh.new()
	knop.radius = plate_r * 0.165
	knop.height = plate_r * 0.230
	_add(root, knop, mat, Basis(), base + Vector3(0.0, 0.030 + stem_h * 0.46, 0.0))

	var plate := CylinderMesh.new()
	plate.top_radius = plate_r
	plate.bottom_radius = plate_r * 0.88
	plate.height = 0.020
	plate.radial_segments = 40
	_add(root, plate, mat, Basis(), Vector3(base.x, top_y - 0.010, base.z))

	var rim := TorusMesh.new()
	rim.inner_radius = maxf(plate_r - 0.011, 0.02)
	rim.outer_radius = plate_r + 0.005
	rim.rings = 40
	rim.ring_segments = 8
	_add(root, rim, mat, Basis(), Vector3(base.x, top_y, base.z))


# ---------------------------------------------------------------------------
# the heap

static func _heap(root: Node3D, rng: RandomNumberGenerator, kit: Dictionary, centre: Vector3, r_out: float, rise: float, sc: float, avoid: float, half: float, n_bread: int, n_ham: int, n_tom: int, n_car: int, n_cube: int, n_leaf: int) -> void:
	var c_crust: Color = kit["crust"]
	var c_pale: Color = kit["pale"]
	var c_ham: Color = kit["ham"]
	var c_tom: Color = kit["tomato"]
	var c_car: Color = kit["carrot"]
	var c_lf: Color = kit["leaf"]
	var tex_crumb: ImageTexture = kit["crumb"]
	var tex_marble: ImageTexture = kit["marble"]
	var r_in: float = r_out * 0.16

	# bread loaves, cut wedges
	for i in range(n_bread):
		var hw: float = rng.randf_range(0.048, 0.074) * sc
		var hh: float = rng.randf_range(0.044, 0.070) * sc
		var dp: float = rng.randf_range(0.090, 0.145) * sc
		var msh: ArrayMesh = _extrude(_loaf_profile(hw, hh, 6), dp, rng.randf_range(0.52, 0.96))
		var col: Color = c_crust.lerp(c_pale, rng.randf_range(0.0, 0.45)).darkened(rng.randf_range(0.0, 0.09))
		var pos: Vector3 = _heap_pos(rng, centre, r_in, r_out, rise, avoid, half)
		_add(root, msh, _tex_mat(col, tex_crumb, 7.5, 0.20), _rand_basis(rng, 0.30), pos + Vector3(0.0, 0.012, 0.0))

	# ham slabs
	for i in range(n_ham):
		var bx := BoxMesh.new()
		var sy: float = rng.randf_range(0.042, 0.082) * sc
		bx.size = Vector3(rng.randf_range(0.072, 0.126) * sc, sy, rng.randf_range(0.058, 0.104) * sc)
		var col2: Color = c_ham.darkened(rng.randf_range(0.0, 0.16)).lightened(rng.randf_range(0.0, 0.10))
		var pos2: Vector3 = _heap_pos(rng, centre, r_in, r_out, rise, avoid, half)
		_add(root, bx, _tex_mat(col2, tex_marble, 6.0, 0.16), _rand_basis(rng, 0.36), pos2 + Vector3(0.0, sy * 0.5 + 0.006, 0.0))

	# tomatoes with a green calyx
	for i in range(n_tom):
		var tr: float = rng.randf_range(0.036, 0.050) * sc
		var sph := SphereMesh.new()
		sph.radius = tr
		sph.height = tr * 2.0
		var pos3: Vector3 = _heap_pos(rng, centre, r_in, r_out, rise, avoid, half)
		var seat: Vector3 = pos3 + Vector3(0.0, tr * 0.86, 0.0)
		_add(root, sph, _gloss(c_tom.lightened(rng.randf_range(0.0, 0.12)), 0.12), _rand_basis(rng, 0.5).scaled(Vector3(1.0, 0.86, 1.0)), seat)
		var cal := SphereMesh.new()
		cal.radius = tr * 0.38
		cal.height = tr * 0.30
		_add(root, cal, _gloss(c_lf.darkened(0.22), 0.34), _rand_basis(rng, 0.3), seat + Vector3(0.0, tr * 0.74, 0.0))

	# chopped carrot
	for i in range(n_car):
		var cs: float = rng.randf_range(0.030, 0.052) * sc
		var pr := PrismMesh.new()
		pr.size = Vector3(cs, cs * rng.randf_range(0.9, 1.4), cs * rng.randf_range(0.8, 1.2))
		pr.left_to_right = rng.randf_range(0.2, 0.8)
		var pos4: Vector3 = _heap_pos(rng, centre, r_in, r_out, rise, avoid, half)
		_add(root, pr, _gloss(c_car.lightened(rng.randf_range(0.0, 0.14)), 0.16), _rand_basis(rng, 1.2), pos4 + Vector3(0.0, cs * 0.55, 0.0))

	# pale cut bread cubes
	for i in range(n_cube):
		var qs: float = rng.randf_range(0.038, 0.062) * sc
		var bx2 := BoxMesh.new()
		bx2.size = Vector3(qs, qs * rng.randf_range(0.7, 1.1), qs * rng.randf_range(0.8, 1.2))
		var col3: Color = c_pale.darkened(rng.randf_range(0.0, 0.12))
		var pos5: Vector3 = _heap_pos(rng, centre, r_in, r_out, rise, avoid, half)
		_add(root, bx2, _tex_mat(col3, tex_crumb, 11.0, 0.26), _rand_basis(rng, 0.9), pos5 + Vector3(0.0, qs * 0.55, 0.0))

	# lettuce blades, planted at the rim and splayed out
	for i in range(n_leaf):
		var la: float = rng.randf_range(0.0, TAU - 2.0 * half)
		var ang: float = fposmod(avoid + half + la, TAU)
		var lr: float = r_out * rng.randf_range(0.72, 0.98)
		var ln: float = rng.randf_range(0.115, 0.175) * sc
		var wd: float = rng.randf_range(0.036, 0.055) * sc
		var msh2: ArrayMesh = _leaf_mesh(rng, ln, wd)
		var bs: Basis = Basis(Vector3.UP, PI * 0.5 - ang) * Basis(Vector3.RIGHT, rng.randf_range(-0.75, -0.30))
		var mat_leaf: StandardMaterial3D = _gloss(c_lf.darkened(rng.randf_range(0.0, 0.18)), 0.24)
		mat_leaf.cull_mode = BaseMaterial3D.CULL_DISABLED
		_add(root, msh2, mat_leaf, bs, centre + Vector3(cos(ang) * lr, rng.randf_range(0.010, 0.045), sin(ang) * lr))


static func _heap_pos(rng: RandomNumberGenerator, centre: Vector3, r_in: float, r_out: float, rise: float, avoid: float, half: float) -> Vector3:
	var a: float = rng.randf_range(0.0, TAU - 2.0 * half)
	var ang: float = fposmod(avoid + half + a, TAU)
	var rad: float = lerpf(r_in, r_out, sqrt(rng.randf()))
	var f: float = clampf((rad - r_in) / maxf(r_out - r_in, 0.001), 0.0, 1.0)
	var dome: float = rise * pow(1.0 - f, 1.25)
	var y: float = dome * rng.randf_range(0.10, 1.0)
	return centre + Vector3(cos(ang) * rad, y, sin(ang) * rad)


# ---------------------------------------------------------------------------
# the set pieces

static func _grapes(root: Node3D, rng: RandomNumberGenerator, anchor: Vector3, dir: Vector3, n: int, col: Color, mat_stem: StandardMaterial3D) -> void:
	var d: Vector3 = dir.normalized()
	var e1: Vector3 = Vector3.UP.cross(d)
	if e1.length() < 0.001:
		e1 = Vector3.RIGHT
	e1 = e1.normalized()
	var e2: Vector3 = d.cross(e1).normalized()
	var ln: float = rng.randf_range(0.150, 0.225)
	var cluster: float = rng.randf_range(0.038, 0.055)
	var brad: float = rng.randf_range(0.017, 0.022)
	_taper_cyl(root, anchor - d * 0.02, anchor + d * (ln * 0.30), 0.008, 0.005, mat_stem)
	for i in range(n):
		var t: float = float(i) / float(n - 1)
		var a: float = float(i) * 2.399 + rng.randf_range(-0.25, 0.25)
		var rad: float = cluster * (1.0 - 0.82 * t) * (0.35 + 0.65 * sqrt(clampf(t * 3.0, 0.0, 1.0)))
		var along: float = ln * (0.10 + 0.90 * t)
		var pos: Vector3 = anchor + d * along + e1 * (cos(a) * rad) + e2 * (sin(a) * rad)
		pos += Vector3(rng.randf_range(-0.006, 0.006), rng.randf_range(-0.006, 0.006), rng.randf_range(-0.006, 0.006))
		var r: float = brad * rng.randf_range(0.84, 1.10)
		var sph := SphereMesh.new()
		sph.radius = r
		sph.height = r * 1.94
		sph.radial_segments = 14
		sph.rings = 8
		var c: Color = col.lightened(rng.randf_range(0.0, 0.14)).darkened(rng.randf_range(0.0, 0.10))
		_add(root, sph, _gloss(c, 0.14), _rand_basis(rng, 1.0), pos)


static func _bottle(root: Node3D, base: Vector3, h: float, mat: StandardMaterial3D, yaw: float) -> void:
	var prof := PackedVector2Array()
	prof.append(Vector2(0.0, 0.0))
	prof.append(Vector2(0.048, 0.004))
	prof.append(Vector2(0.052, 0.018))
	prof.append(Vector2(0.052, h * 0.55))
	prof.append(Vector2(0.046, h * 0.66))
	prof.append(Vector2(0.024, h * 0.82))
	prof.append(Vector2(0.019, h * 0.90))
	prof.append(Vector2(0.019, h))
	prof.append(Vector2(0.0, h))
	_add(root, _lathe(prof, 26), mat, Basis(Vector3.UP, yaw), base)
	var cap := CylinderMesh.new()
	cap.top_radius = 0.021
	cap.bottom_radius = 0.022
	cap.height = 0.030
	cap.radial_segments = 20
	_add(root, cap, mat, Basis(), base + Vector3(0.0, h - 0.006, 0.0))
	var ring := TorusMesh.new()
	ring.inner_radius = 0.019
	ring.outer_radius = 0.025
	ring.rings = 20
	ring.ring_segments = 6
	_add(root, ring, mat, Basis(), base + Vector3(0.0, h * 0.90, 0.0))


static func _shoe(root: Node3D, rng: RandomNumberGenerator, stand_r: float, c_pink: Color, c_deep: Color) -> void:
	var mat_pink: StandardMaterial3D = _gloss(c_pink, 0.12)
	var mat_deep: StandardMaterial3D = _gloss(c_deep, 0.18)
	var ln: float = rng.randf_range(0.215, 0.250)
	var heel_y: float = rng.randf_range(0.088, 0.108)

	# side view of the sole: (half width, height, along) from toe (-ln) to heel (0)
	var st_list: Array = [
		Vector3(0.011, 0.009, -ln * 1.00),
		Vector3(0.029, 0.010, -ln * 0.88),
		Vector3(0.041, 0.013, -ln * 0.72),
		Vector3(0.040, 0.021, -ln * 0.55),
		Vector3(0.031, 0.040, -ln * 0.38),
		Vector3(0.029, heel_y * 0.68, -ln * 0.22),
		Vector3(0.031, heel_y * 0.92, -ln * 0.08),
		Vector3(0.030, heel_y, 0.0),
	]
	var sole: ArrayMesh = _ribbon_slab(st_list, 0.010)

	var tilt: float = rng.randf_range(0.10, 0.20)
	var side: float = 1.0 if rng.randf() < 0.5 else -1.0
	var out_ang: float = PI + rng.randf_range(-0.55, 0.55)
	var outw := Vector3(cos(out_ang), 0.0, sin(out_ang))
	var frame: Basis = Basis(Vector3.UP, atan2(-outw.x, -outw.z)) * Basis(Vector3.BACK, tilt * side)

	# solve the low point so the leaning shoe stands on the same floor as the
	# stand's foot: nothing in the shoe sits below local y = 0 (the spike tip)
	var probe: Array = [
		Vector3(-0.030, 0.0, 0.004),
		Vector3(0.030, 0.0, 0.004),
		Vector3(-0.041, 0.009, -ln * 0.72),
		Vector3(0.041, 0.009, -ln * 0.72),
		Vector3(0.0, 0.009, -ln),
	]
	var low: float = 1.0e9
	for p in probe:
		var pv: Vector3 = p
		low = minf(low, (frame * pv).y)
	var org: Vector3 = -outw * (stand_r * 0.50 + rng.randf_range(0.055, 0.095)) + Vector3(0.0, -low, 0.0)

	_add(root, sole, mat_deep, frame, org)

	# spike heel: from under the sole's heel end down to the floor
	var heel_top: Vector3 = org + frame * Vector3(0.0, heel_y * 0.96, -0.012)
	var heel_bot: Vector3 = org + frame * Vector3(0.0, 0.0, 0.004)
	var up_heel: Vector3 = (heel_top - heel_bot).normalized()
	_taper_cyl(root, heel_top, heel_bot, 0.017, 0.008, mat_pink)
	var tip := CylinderMesh.new()
	tip.top_radius = 0.009
	tip.bottom_radius = 0.010
	tip.height = 0.008
	tip.radial_segments = 12
	_add(root, tip, mat_deep, _basis_y_to(up_heel), heel_bot + up_heel * 0.004)

	# vamp over the ball, toe cap, heel counter, insole — all squashed in the
	# shoe's own frame, so the lean carries them with it
	var vamp := SphereMesh.new()
	vamp.radius = 1.0
	vamp.height = 2.0
	vamp.radial_segments = 20
	vamp.rings = 12
	_add(root, vamp, mat_pink, frame * Basis.from_scale(Vector3(0.038, 0.038, 0.082)), org + frame * Vector3(0.0, 0.048, -ln * 0.70))

	var toe := SphereMesh.new()
	toe.radius = 1.0
	toe.height = 2.0
	toe.radial_segments = 18
	toe.rings = 10
	_add(root, toe, mat_pink, frame * Basis.from_scale(Vector3(0.022, 0.019, 0.038)), org + frame * Vector3(0.0, 0.028, -ln * 0.92))

	var counter := SphereMesh.new()
	counter.radius = 1.0
	counter.height = 2.0
	counter.radial_segments = 20
	counter.rings = 12
	_add(root, counter, mat_pink, frame * Basis.from_scale(Vector3(0.028, 0.046, 0.044)), org + frame * Vector3(0.0, heel_y + 0.030, -ln * 0.10))

	var insole := BoxMesh.new()
	insole.size = Vector3(0.048, 0.006, ln * 0.34)
	_add(root, insole, mat_deep, frame * Basis(Vector3.RIGHT, 0.30), org + frame * Vector3(0.0, 0.056, -ln * 0.42))


# ---------------------------------------------------------------------------
# mesh factories

static func _loaf_profile(hw: float, hh: float, steps: int) -> PackedVector2Array:
	var prof := PackedVector2Array()
	prof.append(Vector2(-hw, 0.0))
	prof.append(Vector2(hw, 0.0))
	for k in range(1, steps):
		var a: float = PI * float(k) / float(steps)
		prof.append(Vector2(hw * cos(a), hh * sin(a)))
	return prof


static func _extrude(prof: PackedVector2Array, depth: float, s_back: float) -> ArrayMesh:
	# convex XY profile with a flat bottom, extruded along Z and tapered at -Z
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var n: int = prof.size()
	var hz: float = depth * 0.5
	var f := PackedVector3Array()
	var b := PackedVector3Array()
	var acc := Vector3.ZERO
	for i in range(n):
		var p: Vector2 = prof[i]
		var vf := Vector3(p.x, p.y, hz)
		var vb := Vector3(p.x * s_back, p.y * s_back, -hz)
		f.append(vf)
		b.append(vb)
		acc += vf + vb
	var inside: Vector3 = acc / float(n * 2)
	for i in range(n):
		var j: int = (i + 1) % n
		_quad_out(st, f[i], f[j], b[j], b[i], inside)
	for i in range(1, n - 1):
		_tri_out(st, f[0], f[i], f[i + 1], inside)
		_tri_out(st, b[0], b[i], b[i + 1], inside)
	st.generate_normals()
	return st.commit()


static func _lathe(prof: PackedVector2Array, segs: int) -> ArrayMesh:
	# closed 2D profile (radius, height), traversed counter-clockwise, revolved
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = prof.size()
	for i in range(n):
		var p0: Vector2 = prof[i]
		var p1: Vector2 = prof[(i + 1) % n]
		if p0.x < 0.0002 and p1.x < 0.0002:
			continue
		var out2 := Vector2(p1.y - p0.y, -(p1.x - p0.x))
		if out2.length() < 0.000001:
			continue
		out2 = out2.normalized()
		for k in range(segs):
			var a0: float = TAU * float(k) / float(segs)
			var a1: float = TAU * float(k + 1) / float(segs)
			var am: float = (a0 + a1) * 0.5
			var v00 := Vector3(p0.x * cos(a0), p0.y, p0.x * sin(a0))
			var v01 := Vector3(p0.x * cos(a1), p0.y, p0.x * sin(a1))
			var v10 := Vector3(p1.x * cos(a0), p1.y, p1.x * sin(a0))
			var v11 := Vector3(p1.x * cos(a1), p1.y, p1.x * sin(a1))
			var outw := Vector3(out2.x * cos(am), out2.y, out2.x * sin(am))
			var mid: Vector3 = (v00 + v01 + v10 + v11) * 0.25
			var inside: Vector3 = mid - outw * 0.5
			if p0.x < 0.0002:
				_tri_out(st, v00, v10, v11, inside)
			elif p1.x < 0.0002:
				_tri_out(st, v00, v01, v10, inside)
			else:
				_quad_out(st, v00, v01, v11, v10, inside)
	st.generate_normals()
	return st.commit()


static func _bowl_mesh(r_top: float, r_bot: float, h: float, th: float) -> ArrayMesh:
	var prof := PackedVector2Array()
	prof.append(Vector2(0.0, 0.0))
	prof.append(Vector2(r_bot, 0.006))
	prof.append(Vector2(r_top, h))
	prof.append(Vector2(r_top - th, h))
	prof.append(Vector2(maxf(r_bot - th * 0.7, 0.004), 0.006 + th))
	prof.append(Vector2(0.0, th))
	return _lathe(prof, 30)


static func _ribbon_slab(stations: Array, th: float) -> ArrayMesh:
	# each station is (half width, height, along Z); lofts a curved tapering slab
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var n: int = stations.size()
	for i in range(n - 1):
		var s0: Vector3 = stations[i]
		var s1: Vector3 = stations[i + 1]
		var a0 := Vector3(-s0.x, s0.y, s0.z)
		var a1 := Vector3(s0.x, s0.y, s0.z)
		var a2 := Vector3(s0.x, s0.y + th, s0.z)
		var a3 := Vector3(-s0.x, s0.y + th, s0.z)
		var b0 := Vector3(-s1.x, s1.y, s1.z)
		var b1 := Vector3(s1.x, s1.y, s1.z)
		var b2 := Vector3(s1.x, s1.y + th, s1.z)
		var b3 := Vector3(-s1.x, s1.y + th, s1.z)
		var inside := Vector3(0.0, (s0.y + s1.y) * 0.5 + th * 0.5, (s0.z + s1.z) * 0.5)
		_quad_out(st, a0, a1, b1, b0, inside)
		_quad_out(st, a3, a2, b2, b3, inside)
		_quad_out(st, a0, a3, b3, b0, inside)
		_quad_out(st, a1, a2, b2, b1, inside)
		if i == 0:
			_quad_out(st, a0, a1, a2, a3, inside)
		if i == n - 2:
			_quad_out(st, b0, b1, b2, b3, inside)
	st.generate_normals()
	return st.commit()


static func _leaf_mesh(rng: RandomNumberGenerator, ln: float, wd: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nu: int = 8
	var nv: int = 6
	var curl: float = rng.randf_range(0.20, 0.46)
	var ruf: float = rng.randf_range(0.010, 0.026)
	var waves: float = rng.randf_range(2.0, 4.0)
	var twist: float = rng.randf_range(-0.40, 0.40)
	var grid: Array = []
	for i in range(nu + 1):
		var u: float = float(i) / float(nu)
		var hwid: float = wd * sin(PI * pow(u, 0.62)) + 0.004
		var row: Array = []
		for j in range(nv + 1):
			var v: float = float(j) / float(nv) * 2.0 - 1.0
			var x: float = v * hwid
			var y: float = curl * ln * u * u + ruf * sin(v * PI * waves + u * 5.0) * absf(v) * u + twist * x * u
			row.append(Vector3(x, y, u * ln))
		grid.append(row)
	for i in range(nu):
		var r0: Array = grid[i]
		var r1: Array = grid[i + 1]
		for j in range(nv):
			var p00: Vector3 = r0[j]
			var p01: Vector3 = r0[j + 1]
			var p10: Vector3 = r1[j]
			var p11: Vector3 = r1[j + 1]
			st.add_vertex(p00)
			st.add_vertex(p10)
			st.add_vertex(p11)
			st.add_vertex(p00)
			st.add_vertex(p11)
			st.add_vertex(p01)
	st.generate_normals()
	return st.commit()


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


static func _tri_out(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, inside: Vector3) -> void:
	var n_front: Vector3 = (c - a).cross(b - a)
	var centroid: Vector3 = (a + b + c) / 3.0
	if n_front.dot(centroid - inside) >= 0.0:
		st.add_vertex(a)
		st.add_vertex(b)
		st.add_vertex(c)
	else:
		st.add_vertex(a)
		st.add_vertex(c)
		st.add_vertex(b)


# ---------------------------------------------------------------------------
# small helpers

static func _add(root: Node3D, msh: Mesh, mat: StandardMaterial3D, bs: Basis, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = msh
	mi.material_override = mat
	root.add_child(mi)
	mi.transform = Transform3D(bs, pos)
	return mi


static func _gloss(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.0
	m.clearcoat_enabled = true
	m.clearcoat = 0.8
	m.clearcoat_roughness = 0.10
	return m


static func _tex_mat(c: Color, tex: ImageTexture, tri_scale: float, rough: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = _gloss(c, rough)
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(tri_scale, tri_scale, tri_scale)
	return m


static func _rand_basis(rng: RandomNumberGenerator, tilt: float) -> Basis:
	var yaw: float = rng.randf_range(0.0, TAU)
	var ax := Vector3(rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-1.0, 1.0))
	if ax.length() < 0.001:
		ax = Vector3.RIGHT
	ax = ax.normalized()
	var ang: float = rng.randf_range(-tilt, tilt)
	return Basis(ax, ang) * Basis(Vector3.UP, yaw)


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


static func _taper_cyl(root: Node3D, a: Vector3, b: Vector3, r0: float, r1: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = b - a
	var ln: float = maxf(d.length(), 0.006)
	var cyl := CylinderMesh.new()
	cyl.bottom_radius = r0
	cyl.top_radius = r1
	cyl.height = ln
	cyl.radial_segments = 14
	return _add(root, cyl, mat, _basis_y_to(d), (a + b) * 0.5)


static func _cone(root: Node3D, base: Vector3, dir: Vector3, h: float, r: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var d: Vector3 = dir.normalized()
	var cyl := CylinderMesh.new()
	cyl.bottom_radius = r
	cyl.top_radius = 0.0
	cyl.height = h
	cyl.radial_segments = 12
	return _add(root, cyl, mat, _basis_y_to(d), base + d * (h * 0.5))


static func _mottle(rng: RandomNumberGenerator, base: float, lo: float, hi: float, n_spots: int, r_min: float, r_max: float, stretch: float) -> ImageTexture:
	# near-white stamped mottle, so albedo_color still does the tinting
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	var buf := PackedFloat32Array()
	buf.resize(TEX * TEX)
	for i in range(TEX * TEX):
		buf[i] = base + rng.randf_range(-0.035, 0.035)
	for s in range(n_spots):
		var cx: float = rng.randf() * float(TEX)
		var cy: float = rng.randf() * float(TEX)
		var rr: float = rng.randf_range(r_min, r_max)
		var rx: float = rr * stretch
		var val: float = rng.randf_range(lo, hi)
		var x0: int = int(floor(cx - rx)) - 1
		var x1: int = int(ceil(cx + rx)) + 1
		var y0: int = int(floor(cy - rr)) - 1
		var y1: int = int(ceil(cy + rr)) + 1
		for y in range(y0, y1 + 1):
			for x in range(x0, x1 + 1):
				var dx: float = (float(x) - cx) / maxf(rx, 0.001)
				var dy: float = (float(y) - cy) / maxf(rr, 0.001)
				var dd: float = dx * dx + dy * dy
				if dd > 1.0:
					continue
				var idx: int = posmod(y, TEX) * TEX + posmod(x, TEX)
				var w: float = (1.0 - dd) * 0.85
				buf[idx] = lerpf(buf[idx], val, w)
	for y in range(TEX):
		for x in range(TEX):
			var v: float = clampf(buf[y * TEX + x], 0.0, 1.0)
			img.set_pixel(x, y, Color(v, v, v))
	return ImageTexture.create_from_image(img)


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
