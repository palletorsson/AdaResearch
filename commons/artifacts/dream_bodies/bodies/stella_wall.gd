extends RefCounted
## stella_wall — a Frank Stella-like wall relief built from flat painted cut-outs.
##
## Reference: scratchpad/refs/stella_wall.png (2048x536 panorama): a room-wide tangle of
## flat aluminium shapes - arcs, rings, spiral "French curve" ribbons, cones, notched
## slabs and one tall mustard slab with a round hole - stacked at several depths in front
## of a near-black wall, in dusty mauve, slate teal and mustard with a few coral pieces.
## The surfaces are matte paint with a fine speckle and scattered pinholes.
##
## What is reproduced, and how:
##   1. The black back wall          - one thin BoxMesh 2.4 x 1.6 x 0.03, front face on z = 0.
##   2. Annulus arcs and full rings  - SurfaceTool band meshes: inner/outer arc polylines joined
##                                     by quad strips, with side walls, 2-4 cm thick.
##   3. Spiral ribbons with tails    - tapering Archimedean spirals and S-swooshes, offset by a
##                                     width along the normal, through the same band extruder.
##   4. Cones, wedges and fans       - sector polygons (origin + arc) and a tall coral triangle,
##                                     triangulated with Geometry2D.triangulate_polygon, extruded.
##   5. The tall slab with a hole    - a closed band from a circle to the rectangle boundary
##                                     (a ray per angle, corners included), so the hole is real.
##   6. Big organic mauve plates     - radial-harmonic blobs and rectangles with a round bite
##                                     and a notch, as extruded polygons on the back plane.
##   7. Four tilted depth planes     - z = -0.045 / -0.125 / -0.205 / -0.285, each piece tilted
##                                     as far as its own depth budget allows, never past -0.35.
##   8. Painted-aluminium speckle    - three 128x128 code-made grain + pinhole textures,
##                                     sampled triplanar and multiplied under each albedo.
## Given up: the installation's room-high scale and its welded brackets; the shapes here are
## free-floating on their planes, and the perforations are texture, not geometry.
##
## THE TWO AXES (2026-09-03) - the relief as a family, not one wall:
##   cutout  - what every flat cut-out IS. `flat` solid painted plates (today) · `melt`
##             each shape stretched into a sagging teardrop, drips running off it and
##             blobs pooling on the floor · `swarm` every plate broken into a cluster of
##             small copies of its own outline · `fossil` the fill gone, only a rim of
##             each outline left (hoops, wire spirals, an empty frame where the holed
##             slab was) · `bloom` the plates shrunk and ringed with petal blades.
##   backing - what the tangle hangs on. `black` the one near-black slab (today) ·
##             `flood` the lower third poured solid, a wavy shore with islands surfacing
##             through it · `mirror` the wall folded so an exact twin of the tangle grows
##             out of the first, three centimetres in front of it · `unhoused` no wall at
##             all, every piece hung on a thread from a rail above.
## The default (flat, black) is the statue this file always built: every variant draw comes
## out of a SECOND generator, so the original random stream is untouched, number for number.

const WALL_W: float = 2.4
const WALL_H: float = 1.6
const MAX_DEPTH: float = 0.35
const SLAB_T: float = 0.03

const CUTOUTS: Array[String] = ["flat", "melt", "swarm", "fossil", "bloom"]
const BACKINGS: Array[String] = ["black", "flood", "mirror", "unhoused"]
## How far the mirrored twin slides out of its original, in metres.
const MIRROR_DX: float = 0.14
## The relief keeps to 40..260 meshes; a swarm, a drip or a petal stops adding at this
## many, and no piece at all is hung past HARD_PIECES - a fold on top of a bloom would
## otherwise walk straight through the ceiling. The default builds some fifty-odd.
const MAX_PIECES: int = 236
const HARD_PIECES: int = 250
## The size the contract gives a relief (the probe allows 2.60 x 1.75).
const FIT_W: float = 2.54
const FIT_H: float = 1.72


static func axes() -> Dictionary:
	return {
		"cutout": ["flat", "melt", "swarm", "fossil", "bloom"],
		"backing": ["black", "flood", "mirror", "unhoused"],
	}


static func describe() -> String:
	return "A Stella-like wall relief: some fifty flat cut-out arcs, rings, spiral ribbons, cones, notched plates and a holed slab in dusty mauve, slate teal and mustard with a few coral pieces, tilted on four depth planes in front of a black wall."


static func build(root: Node3D, seed: int, opts: Dictionary = {}) -> void:
	var cut: String = String(opts.get("cutout", "flat"))
	if not CUTOUTS.has(cut):
		cut = "flat"
	var backing: String = String(opts.get("backing", "black"))
	if not BACKINGS.has(backing):
		backing = "black"

	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	# Every variant draw comes out of THIS generator, never out of `rng`: the default
	# path has to consume the same numbers in the same order it consumed before the
	# axes existed, or build(root, seed) stops being the statue it was.
	var vrng := RandomNumberGenerator.new()
	vrng.seed = seed * 7919 + 104729

	var textures: Array[ImageTexture] = [_speckle(rng, 0.010), _speckle(rng, 0.017), _speckle(rng, 0.006)]
	var palette: Array[Color] = [
		Color(0.659, 0.455, 0.604),  # dusty mauve   #a8749a
		Color(0.431, 0.561, 0.596),  # slate teal    #6e8f98
		Color(0.839, 0.682, 0.282),  # mustard       #d6ae48
		Color(0.776, 0.353, 0.314),  # coral         #c65a50
	]
	var swarm_k: int = 2 if backing == "mirror" else 3
	var ctx: Dictionary = {"cut": cut, "back": backing, "vrng": vrng, "swarm": swarm_k, "mirror": false}

	# 1. the wall: a thin black slab whose front face is the z = 0 plane.
	#    `unhoused` takes it away and hangs the tangle on threads instead.
	if backing != "unhoused":
		var slab := BoxMesh.new()
		slab.size = Vector3(WALL_W, WALL_H, SLAB_T)
		var slab_mat := StandardMaterial3D.new()
		slab_mat.albedo_color = Color(0.10, 0.10, 0.11)
		slab_mat.roughness = 0.96
		slab_mat.metallic = 0.0
		_add(root, slab, slab_mat, Vector3(0.0, WALL_H * 0.5, -SLAB_T * 0.5), Vector3.ZERO)
	if backing == "mirror":
		# the fold: a second panel hinged behind the first, its edge showing past it
		var fold := BoxMesh.new()
		fold.size = Vector3(WALL_W * 0.62, WALL_H, SLAB_T)
		var fold_mat := StandardMaterial3D.new()
		fold_mat.albedo_color = Color(0.07, 0.07, 0.08)
		fold_mat.roughness = 0.94
		fold_mat.metallic = 0.0
		_add(root, fold, fold_mat, Vector3(MIRROR_DX * 2.4, WALL_H * 0.5 - 0.03, 0.05), Vector3(0.0, 11.0, 3.5))

	# the gesture: the whole tangle drifts one way, and the holed slab stands on the other side
	var side: float = 1.0 if rng.randf() < 0.5 else -1.0
	var lean: float = rng.randf_range(14.0, 26.0) * side

	# The stream is bookmarked here so the fold can REPLAY it: the twin is the same
	# fifty shapes, drawn again, placed at -x. A second seed would give a sibling; this
	# gives a mirror.
	var m_seed: int = int(rng.seed)
	var m_state: int = int(rng.state)
	_tangle(root, rng, textures, palette, side, lean, ctx)
	if backing == "mirror":
		var mrng := RandomNumberGenerator.new()
		mrng.seed = m_seed
		mrng.state = m_state
		var mctx: Dictionary = ctx.duplicate()
		mctx["mirror"] = true
		_tangle(root, mrng, textures, palette, side, lean, mctx)

	if backing == "flood":
		_pour(root, vrng, textures, palette)
	if backing == "unhoused":
		_threads(root, vrng)
	if cut == "melt":
		_puddle(root, vrng, textures, palette)

	# SETTLE ON ITS OWN BOTTOM EDGE. A tilted plate placed near y 0.2 can hang a
	# hand's width below the relief's origin, and that origin is what a wall or a
	# plinth is given: the piece would be buried. So the whole tangle is lifted by
	# however far its lowest corner dipped - measured, because every seed dips
	# differently (the gate caught -0.09 on seed 1).
	#
	# A variant can also GROW - a melt hangs below the floor, a bloom pushes past the
	# wall's edge, a fold widens it - so anything that is not (flat, black) is measured
	# and fitted back into the relief's box before it is floored and centred. The
	# default path keeps the old lift alone, untouched, so its statue does not move.
	if cut != "flat" or backing != "black":
		var box: AABB = _union(root)
		var wide: float = maxf(box.size.x, box.size.z)
		var kfit: float = minf(1.0, minf(FIT_W / maxf(wide, 0.001), FIT_H / maxf(box.size.y, 0.001)))
		if kfit < 1.0:
			for c in root.get_children():
				if c is MeshInstance3D:
					var mi: MeshInstance3D = c
					var tf: Transform3D = mi.transform
					mi.transform = Transform3D(tf.basis.scaled(Vector3(kfit, kfit, kfit)), tf.origin * kfit)
			box = _union(root)
		# x is centred and y is floored; z is NOT centred, because a relief's z origin is
		# its wall plane and that is the face a plinth or a wall is given.
		var ctr_x: float = box.position.x + box.size.x * 0.5
		for c in root.get_children():
			if c is Node3D:
				var n3: Node3D = c
				n3.position = Vector3(n3.position.x - ctr_x, n3.position.y - box.position.y, n3.position.z)
		return

	var low: float = 1.0e9
	for c in root.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh != null:
			var a: AABB = (c as MeshInstance3D).transform * ((c as MeshInstance3D).mesh as Mesh).get_aabb()
			low = minf(low, a.position.y)
	if low < 0.0 and low > -1.0e8:
		for c in root.get_children():
			if c is Node3D:
				(c as Node3D).position.y -= low


## The tangle itself: the back plane's big pieces, then three layers of arcs, rings, spirals,
## swooshes, cones and small plates. Called once for a relief, twice when the wall folds -
## the second call replays the same stream and `ctx.mirror` sends every piece to -x.
static func _tangle(root: Node3D, rng: RandomNumberGenerator, textures: Array[ImageTexture],
		palette: Array[Color], side: float, lean: float, ctx: Dictionary) -> void:
	var cut: String = String(ctx.get("cut", "flat"))

	# ---- layer 0: the back plane - the holed mustard slab, big mauve plates, two wide arcs, a fan ----
	var slab_w: float = rng.randf_range(0.42, 0.55)
	var slab_h: float = rng.randf_range(0.85, 1.05)
	var hole_r: float = slab_w * rng.randf_range(0.18, 0.24)
	var hole_at := Vector2(rng.randf_range(-0.05, 0.05) * slab_w, slab_h * rng.randf_range(0.18, 0.30))
	var slab_thick: float = 0.035
	# fossilised, the slab is only the frame it was drawn on - the hole eats the plate
	var slab_mesh: ArrayMesh = _holed_slab_mesh(slab_w, slab_h, hole_at, hole_r, slab_thick)
	if cut == "fossil":
		slab_mesh = _rim_mesh(_rect_pts(slab_w, slab_h), slab_thick, 0.05)
	_piece(root, rng, textures, slab_mesh,
		palette[2], Vector2(side * 0.9, slab_h * 0.5 + 0.02), 0, slab_h * 0.55,
		Vector2(slab_w * 0.5, slab_h * 0.5), rng.randf_range(-4.0, 4.0), slab_thick, ctx)

	var n_plates: int = rng.randi_range(5, 7)
	for k in range(n_plates):
		var r: float = rng.randf_range(0.28, 0.46)
		var tint: Color = _pick(rng, palette, 0.8, 0.05, 0.15, 0.0)
		var at := Vector2(clampf(rng.randfn(-side * 0.15, 0.5), -0.95, 0.95), rng.randf_range(0.35, 1.05))
		var thick: float = rng.randf_range(0.025, 0.04)
		if rng.randf() < 0.35:
			var w: float = r * rng.randf_range(1.2, 1.8)
			var h: float = r * rng.randf_range(1.4, 2.2)
			_piece(root, rng, textures, _plate(_bitten_slab_pts(rng, w, h), thick, ctx), tint, at, 0,
				sqrt(w * w + h * h) * 0.5, Vector2(w, h) * 0.45, rng.randf_range(-25.0, 25.0), thick, ctx)
		else:
			_piece(root, rng, textures, _plate(_blob_pts(rng, r * 0.78, 44), thick, ctx), tint, at, 0,
				r, Vector2(r, r) * 0.9, rng.randf_range(0.0, 360.0), thick, ctx)

	for k in range(2):
		var r_out: float = rng.randf_range(0.36, 0.5)
		_lay_arc(root, rng, textures, _pick(rng, palette, 0.7, 0.15, 0.15, 0.0),
			Vector2(clampf(rng.randfn(0.0, 0.5), -0.8, 0.8), rng.randf_range(0.5, 1.2)), 0,
			r_out, r_out * rng.randf_range(0.22, 0.32), rng.randf_range(200.0, 330.0), rng.randf_range(0.025, 0.04), ctx)

	_lay_sector(root, rng, textures, palette[2],
		Vector2(-side * rng.randf_range(0.1, 0.5), rng.randf_range(0.8, 1.2)), 0,
		rng.randf_range(0.38, 0.5), rng.randf_range(60.0, 110.0), 0.03, rng.randf_range(0.0, 360.0), ctx)

	# a coral wedge stands on the floor, leaning on the wall, on the drift side
	var wedge_w: float = rng.randf_range(0.28, 0.4)
	var wedge_h: float = rng.randf_range(0.55, 0.8)
	_piece(root, rng, textures, _plate(_wedge_pts(wedge_w, wedge_h, rng.randf_range(-0.3, 0.3) * wedge_w), 0.035, ctx),
		palette[3], Vector2(-side * rng.randf_range(0.25, 0.6), 0.0), 1, wedge_h, Vector2(wedge_w * 0.5, 0.0), 0.0, 0.035, ctx)

	# ---- layers 1-3: the tangle - arcs, rings, spirals, swooshes, cones, small plates ----
	for layer in range(1, 4):
		var count: int = rng.randi_range(12, 16) if layer < 3 else rng.randi_range(9, 12)
		var shrink: float = 1.0 - 0.18 * float(layer - 1)
		for k in range(count):
			var tint: Color = _pick_layer(rng, palette, layer)
			var at := Vector2(clampf(rng.randfn(0.0, 0.55), -1.0, 1.0), rng.randf_range(0.22, 1.38))
			var thick: float = rng.randf_range(0.02, 0.035)
			var roll: float = rng.randf()
			if roll < 0.36:
				var r_out: float = rng.randf_range(0.14, 0.34) * shrink
				var span: float = 360.0 if rng.randf() < 0.3 else rng.randf_range(120.0, 320.0)
				_lay_arc(root, rng, textures, tint, at, layer, r_out, r_out * rng.randf_range(0.2, 0.34), span, thick, ctx)
			elif roll < 0.62:
				var r_out: float = rng.randf_range(0.14, 0.34) * shrink
				_lay_spiral(root, rng, textures, tint, at, layer, r_out, r_out * rng.randf_range(0.16, 0.26),
					rng.randf_range(0.7, 2.2), thick, lean + rng.randf_range(-30.0, 30.0), ctx)
			elif roll < 0.74:
				var length: float = rng.randf_range(0.35, 0.7) * shrink
				_lay_swoosh(root, rng, textures, tint, at, layer, length, length * rng.randf_range(0.10, 0.16),
					rng.randf_range(0.035, 0.07) * shrink, thick, lean + rng.randf_range(-40.0, 40.0), ctx)
			elif roll < 0.87:
				_lay_sector(root, rng, textures, tint, at, layer, rng.randf_range(0.16, 0.34) * shrink,
					rng.randf_range(35.0, 100.0), thick, lean + rng.randf_range(-60.0, 60.0), ctx)
			else:
				var w: float = rng.randf_range(0.18, 0.34) * shrink
				var h: float = w * rng.randf_range(0.8, 1.6)
				_piece(root, rng, textures, _plate(_bitten_slab_pts(rng, w, h), thick, ctx), tint, at, layer,
					sqrt(w * w + h * h) * 0.5, Vector2(w, h) * 0.45, lean + rng.randf_range(-35.0, 35.0), thick, ctx)


# ----------------------------------------------------------------------------------------------
# placement
# ----------------------------------------------------------------------------------------------

## Adds one piece on its depth plane with a random z jitter and a tilt that stays inside
## the relief's depth budget (never past -MAX_DEPTH, never behind the wall face).
##
## This is also where the `cutout` axis lands, because every shape in the relief - arc,
## ring, spiral, swoosh, cone, plate - arrives here. `flat` and `fossil` hang the mesh as
## it came (fossil was already hollowed out where it was built); `melt` stretches it down
## from its own top edge and lets a drip run off it; `swarm` throws the mesh away as a
## handful of small copies; `bloom` shrinks it and rings it with petals. Every rng draw
## above the branch is the ORIGINAL one, in the original order.
static func _piece(root: Node3D, rng: RandomNumberGenerator, textures: Array[ImageTexture], mesh: ArrayMesh,
		tint: Color, at: Vector2, layer: int, radius: float, half: Vector2, rot_z_deg: float, thick: float,
		ctx: Dictionary = {}) -> void:
	var mir: bool = bool(ctx.get("mirror", false))
	var z_plane: float = -0.045 - 0.08 * float(layer) + rng.randf_range(-0.012, 0.012)
	if mir:
		z_plane -= 0.03
	var fwd: float = MAX_DEPTH - thick + z_plane
	var back: float = -z_plane - 0.005
	var room: float = clampf(minf(fwd, back) / maxf(radius, 0.05), 0.0, 1.0)
	var tilt_max: float = minf(rad_to_deg(asin(room)), 14.0)
	var tilt_x: float = rng.randf_range(-tilt_max, tilt_max) * 0.8
	var tilt_y: float = rng.randf_range(-tilt_max, tilt_max) * 0.5
	var clamped: Vector2 = _clamp_pos(at, half)
	var mat: StandardMaterial3D = _mat(rng, tint, textures[rng.randi_range(0, textures.size() - 1)])
	var px: float = clamped.x
	var rz: float = rot_z_deg
	if mir:
		px = -clamped.x + MIRROR_DX
		rz = -rot_z_deg
		tilt_y = -tilt_y
	var cut: String = String(ctx.get("cut", "flat"))
	if cut == "flat" or cut == "fossil":
		_add(root, mesh, mat, Vector3(px, clamped.y, z_plane), Vector3(tilt_x, tilt_y, rz))
		return

	var vrng: RandomNumberGenerator = ctx.get("vrng", rng)
	var box: AABB = mesh.get_aabb()

	if cut == "melt":
		# sagging: the top edge stays where it was pinned and everything below it runs.
		# The tilt and the spin are pulled most of the way out, so the run is downward.
		var sy: float = vrng.randf_range(1.5, 2.6)
		var sx: float = vrng.randf_range(0.62, 0.94)
		var topy: float = box.position.y + box.size.y
		var y_at: float = clamped.y + topy * (1.0 - sy)
		var mi: MeshInstance3D = _add(root, mesh, mat, Vector3(px, y_at, z_plane),
			Vector3(tilt_x * 0.4, tilt_y * 0.4, rz * 0.18))
		mi.scale = Vector3(sx, sy, 1.0)
		var bot: float = y_at + box.position.y * sy
		if bot > 0.14 and vrng.randf() < 0.42 and _room(root):
			var drip_len: float = minf(bot - 0.02, vrng.randf_range(0.14, 0.55))
			var path := PackedVector2Array()
			var n_d: int = 7
			for i in range(n_d + 1):
				var t: float = float(i) / float(n_d)
				path.append(Vector2(sin(t * 3.4 + float(layer)) * 0.018 * t, -drip_len * t))
			var w_top: float = maxf(thick * 1.4, 0.030)
			var widths: PackedFloat32Array = _taper(path.size(), w_top, w_top * 0.22)
			var drip_mat: StandardMaterial3D = _mat(vrng, tint, textures[vrng.randi_range(0, textures.size() - 1)])
			drip_mat.roughness = 0.55
			_add(root, _ribbon_mesh(path, widths, thick * 0.9), drip_mat,
				Vector3(px + vrng.randf_range(-0.03, 0.03), bot + 0.01, z_plane - 0.006), Vector3.ZERO)
		return

	if cut == "swarm":
		# the shape gives up being one thing: a scatter of small copies of its own outline
		var k_n: int = int(ctx.get("swarm", 3))
		for i in range(k_n):
			if not _room(root):
				return
			var s: float = vrng.randf_range(0.24, 0.46)
			var ox: float = vrng.randf_range(-1.0, 1.0) * radius * 1.25
			var oy: float = vrng.randf_range(-1.0, 1.0) * radius * 1.25
			var sm: StandardMaterial3D = _mat(vrng, tint, textures[vrng.randi_range(0, textures.size() - 1)])
			var mi2: MeshInstance3D = _add(root, mesh, sm,
				Vector3(clampf(px + ox, -WALL_W * 0.5 + 0.03, WALL_W * 0.5 - 0.03),
					maxf(clamped.y + oy, 0.05), z_plane + vrng.randf_range(-0.028, 0.028)),
				Vector3(tilt_x, tilt_y, vrng.randf_range(0.0, 360.0)))
			mi2.scale = Vector3(s, s, 1.0)
		return

	# bloom: the cut-out pulls back and flowers along the rim it used to fill
	var mi3: MeshInstance3D = _add(root, mesh, mat, Vector3(px, clamped.y, z_plane), Vector3(tilt_x, tilt_y, rz))
	mi3.scale = Vector3(0.78, 0.78, 1.0)
	if vrng.randf() > 0.64:
		return
	var n_pet: int = vrng.randi_range(3, 5)
	var a0: float = vrng.randf_range(0.0, TAU)
	for i in range(n_pet):
		if not _room(root):
			return
		var ang: float = a0 + TAU * float(i) / float(n_pet) + vrng.randf_range(-0.22, 0.22)
		var plen: float = radius * vrng.randf_range(0.55, 1.15)
		var pw: float = plen * vrng.randf_range(0.20, 0.36)
		var pr: float = radius * vrng.randf_range(0.45, 0.72)
		var petal_tint: Color = tint.lerp(Color(0.94, 0.78, 0.36), vrng.randf_range(0.25, 0.75))
		var pm: StandardMaterial3D = _mat(vrng, petal_tint, textures[vrng.randi_range(0, textures.size() - 1)])
		_add(root, _polygon_mesh(_petal_pts(plen, pw, 9), thick * 0.85), pm,
			Vector3(px + cos(ang) * pr, maxf(clamped.y + sin(ang) * pr, 0.05), z_plane - 0.014),
			Vector3(0.0, 0.0, rad_to_deg(ang)))


static func _clamp_pos(at: Vector2, half: Vector2) -> Vector2:
	var hx: float = minf(half.x, WALL_W * 0.5 - 0.02)
	var hy: float = minf(half.y, WALL_H * 0.5 - 0.02)
	return Vector2(clampf(at.x, -WALL_W * 0.5 + hx, WALL_W * 0.5 - hx), clampf(at.y, hy, WALL_H - hy))


static func _add(root: Node3D, mesh: Mesh, mat: StandardMaterial3D, at: Vector3, rot_deg: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = at
	mi.rotation_degrees = rot_deg
	root.add_child(mi)
	return mi


## Fossilised, a band keeps its path and loses its body: the arc becomes a hoop, the
## spiral and the swoosh become wire. One number, applied where the width is decided.
static func _thin(ctx: Dictionary) -> float:
	return 0.32 if String(ctx.get("cut", "flat")) == "fossil" else 1.0


static func _lay_arc(root: Node3D, rng: RandomNumberGenerator, textures: Array[ImageTexture], tint: Color,
		at: Vector2, layer: int, r_out: float, band: float, span_deg: float, thick: float,
		ctx: Dictionary = {}) -> void:
	var span: float = deg_to_rad(span_deg)
	var a0: float = rng.randf_range(0.0, TAU)
	var segs: int = maxi(12, int(span_deg / 6.0))
	var mesh: ArrayMesh = _arc_mesh(r_out - band * _thin(ctx), r_out, a0, a0 + span, segs, thick)
	_piece(root, rng, textures, mesh, tint, at, layer, r_out, Vector2(r_out, r_out) * 0.85, 0.0, thick, ctx)


static func _lay_spiral(root: Node3D, rng: RandomNumberGenerator, textures: Array[ImageTexture], tint: Color,
		at: Vector2, layer: int, r_out: float, width: float, turns: float, thick: float, rot_deg: float,
		ctx: Dictionary = {}) -> void:
	var r0: float = r_out * rng.randf_range(0.2, 0.4)
	var n: int = maxi(16, int(turns * 24.0))
	var tail: float = r_out * rng.randf_range(0.0, 0.9)
	var path: PackedVector2Array = _spiral_path(turns, r0, r_out, n, rng.randf_range(0.0, TAU), tail)
	var thin: float = _thin(ctx)
	var widths: PackedFloat32Array = _taper(path.size(), width * rng.randf_range(0.35, 0.7) * thin, width * thin)
	var mesh: ArrayMesh = _ribbon_mesh(path, widths, thick)
	var reach: float = r_out + tail + width * 0.5
	_piece(root, rng, textures, mesh, tint, at, layer, reach, Vector2(reach, reach) * 0.7, rot_deg, thick, ctx)


static func _lay_swoosh(root: Node3D, rng: RandomNumberGenerator, textures: Array[ImageTexture], tint: Color,
		at: Vector2, layer: int, length: float, amp: float, width: float, thick: float, rot_deg: float,
		ctx: Dictionary = {}) -> void:
	var n: int = 28
	var path: PackedVector2Array = _swoosh_path(length, amp, rng.randf_range(0.5, 1.0), rng.randf_range(0.0, TAU), n)
	var thin: float = _thin(ctx)
	var widths: PackedFloat32Array = _taper(path.size(), width * rng.randf_range(0.4, 0.8) * thin, width * thin)
	var mesh: ArrayMesh = _ribbon_mesh(path, widths, thick)
	_piece(root, rng, textures, mesh, tint, at, layer, length * 0.5, Vector2(length * 0.45, amp + width), rot_deg, thick, ctx)


static func _lay_sector(root: Node3D, rng: RandomNumberGenerator, textures: Array[ImageTexture], tint: Color,
		at: Vector2, layer: int, r: float, span_deg: float, thick: float, rot_deg: float,
		ctx: Dictionary = {}) -> void:
	var segs: int = maxi(8, int(span_deg / 8.0))
	var mesh: ArrayMesh = _plate(_sector_pts(r, deg_to_rad(span_deg), segs), thick, ctx)
	_piece(root, rng, textures, mesh, tint, at, layer, r, Vector2(r, r) * 0.7, rot_deg, thick, ctx)


# ----------------------------------------------------------------------------------------------
# colour and surface
# ----------------------------------------------------------------------------------------------

static func _pick(rng: RandomNumberGenerator, palette: Array[Color], w0: float, w1: float, w2: float, w3: float) -> Color:
	var total: float = w0 + w1 + w2 + w3
	var r: float = rng.randf() * total
	if r < w0:
		return palette[0]
	r -= w0
	if r < w1:
		return palette[1]
	r -= w1
	if r < w2:
		return palette[2]
	return palette[3]


static func _pick_layer(rng: RandomNumberGenerator, palette: Array[Color], layer: int) -> Color:
	if layer == 1:
		return _pick(rng, palette, 0.45, 0.4, 0.15, 0.0)
	if layer == 2:
		return _pick(rng, palette, 0.2, 0.6, 0.2, 0.0)
	return _pick(rng, palette, 0.1, 0.5, 0.2, 0.2)


static func _mat(rng: RandomNumberGenerator, tint: Color, tex: ImageTexture) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	var f: float = rng.randf_range(0.86, 1.10)
	m.albedo_color = Color(clampf(tint.r * f, 0.0, 1.0), clampf(tint.g * f, 0.0, 1.0), clampf(tint.b * f, 0.0, 1.0))
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(2.5, 2.5, 2.5)
	m.uv1_offset = Vector3(rng.randf(), rng.randf(), rng.randf())
	m.roughness = 0.82
	m.metallic = 0.06
	m.metallic_specular = 0.35
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


## A 128x128 grain with scattered dark pinholes; multiplied under the albedo colour.
static func _speckle(rng: RandomNumberGenerator, dot_density: float) -> ImageTexture:
	var px: int = 128
	var img := Image.create(px, px, false, Image.FORMAT_RGB8)
	for y in range(px):
		for x in range(px):
			var g: float = rng.randf_range(0.90, 1.0)
			img.set_pixel(x, y, Color(g, g, g))
	var n_dots: int = int(float(px * px) * dot_density)
	var dxs: PackedInt32Array = [1, -1, 0, 0]
	var dys: PackedInt32Array = [0, 0, 1, -1]
	for k in range(n_dots):
		var cx: int = rng.randi_range(0, px - 1)
		var cy: int = rng.randi_range(0, px - 1)
		var dark: float = rng.randf_range(0.25, 0.55)
		img.set_pixel(cx, cy, Color(dark, dark, dark))
		if rng.randf() < 0.3:
			var qx: int = posmod(cx + 1, px)
			var qy: int = posmod(cy + 1, px)
			img.set_pixel(qx, cy, Color(dark, dark, dark))
			img.set_pixel(cx, qy, Color(dark, dark, dark))
			img.set_pixel(qx, qy, Color(dark, dark, dark))
		var soft: float = dark + 0.3
		for j in range(4):
			var nx: int = posmod(cx + dxs[j], px)
			var ny: int = posmod(cy + dys[j], px)
			var here: Color = img.get_pixel(nx, ny)
			if here.r > soft:
				img.set_pixel(nx, ny, Color(soft, soft, soft))
	return ImageTexture.create_from_image(img)


# ----------------------------------------------------------------------------------------------
# 2D outlines
# ----------------------------------------------------------------------------------------------

static func _blob_pts(rng: RandomNumberGenerator, radius: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var a1: float = rng.randf_range(0.10, 0.28)
	var a2: float = rng.randf_range(0.08, 0.22)
	var a3: float = rng.randf_range(0.04, 0.14)
	var p1: float = rng.randf_range(0.0, TAU)
	var p2: float = rng.randf_range(0.0, TAU)
	var p3: float = rng.randf_range(0.0, TAU)
	var squash: float = rng.randf_range(0.6, 1.0)
	for i in range(n):
		var ang: float = TAU * float(i) / float(n)
		var r: float = radius * (1.0 + a1 * sin(ang + p1) + a2 * sin(2.0 * ang + p2) + a3 * sin(3.0 * ang + p3))
		pts.append(Vector2(cos(ang) * r, sin(ang) * r * squash))
	return pts


## A rectangle (centred, CCW) with a semicircular bite out of its right edge and a
## rectangular notch cut down from its top edge.
static func _bitten_slab_pts(rng: RandomNumberGenerator, w: float, h: float) -> PackedVector2Array:
	var hw: float = w * 0.5
	var hh: float = h * 0.5
	var pts := PackedVector2Array()
	pts.append(Vector2(-hw, -hh))
	pts.append(Vector2(hw, -hh))
	var bite_r: float = minf(h * rng.randf_range(0.15, 0.28), w * 0.4)
	var bite_y: float = rng.randf_range(-hh + bite_r + 0.01, hh - bite_r - 0.01)
	pts.append(Vector2(hw, bite_y - bite_r))
	var bite_n: int = 10
	for i in range(1, bite_n):
		var t: float = float(i) / float(bite_n)
		var ang: float = -PI * 0.5 - PI * t
		pts.append(Vector2(hw + bite_r * cos(ang), bite_y + bite_r * sin(ang)))
	pts.append(Vector2(hw, bite_y + bite_r))
	pts.append(Vector2(hw, hh))
	var notch_w: float = w * rng.randf_range(0.18, 0.35)
	var notch_d: float = h * rng.randf_range(0.15, 0.35)
	var nx0: float = rng.randf_range(-hw + 0.02, hw * 0.15 - notch_w)
	var nx1: float = nx0 + notch_w
	pts.append(Vector2(nx1, hh))
	pts.append(Vector2(nx1, hh - notch_d))
	pts.append(Vector2(nx0, hh - notch_d))
	pts.append(Vector2(nx0, hh))
	pts.append(Vector2(-hw, hh))
	return pts


## A pie sector: origin plus an arc, spanning `span` radians centred on +x. Convex, CCW.
static func _sector_pts(r: float, span: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.append(Vector2.ZERO)
	for i in range(n + 1):
		var ang: float = -span * 0.5 + span * float(i) / float(n)
		pts.append(Vector2(cos(ang) * r, sin(ang) * r))
	return pts


## A tall triangle standing on y = 0 with its base centred on the origin.
static func _wedge_pts(w: float, h: float, tip_x: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.append(Vector2(-w * 0.5, 0.0))
	pts.append(Vector2(w * 0.5, 0.0))
	pts.append(Vector2(tip_x, h))
	return pts


## An Archimedean spiral from r0 to r1 over `turns` turns, then a straight tail along the last tangent.
static func _spiral_path(turns: float, r0: float, r1: float, n: int, phase: float, tail: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(n + 1):
		var t: float = float(i) / float(n)
		var ang: float = phase + turns * TAU * t
		var r: float = lerpf(r0, r1, t)
		pts.append(Vector2(cos(ang) * r, sin(ang) * r))
	if tail > 0.001:
		var last_p: Vector2 = pts[pts.size() - 1]
		var prev_p: Vector2 = pts[pts.size() - 2]
		var dir: Vector2 = (last_p - prev_p).normalized()
		var m: int = 6
		for i in range(1, m + 1):
			pts.append(last_p + dir * (tail * float(i) / float(m)))
	return pts


## A sine swoosh along x: C, S or hump depending on frequency and phase.
static func _swoosh_path(length: float, amp: float, freq: float, phase: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(n + 1):
		var t: float = float(i) / float(n)
		var x: float = (t - 0.5) * length
		var y: float = amp * sin(TAU * freq * t + phase)
		pts.append(Vector2(x, y))
	return pts


static func _taper(count: int, w0: float, w1: float) -> PackedFloat32Array:
	var widths := PackedFloat32Array()
	for i in range(count):
		var t: float = float(i) / float(maxi(count - 1, 1))
		widths.append(lerpf(w0, w1, t))
	return widths


# ----------------------------------------------------------------------------------------------
# extrusion into thin plates (SurfaceTool, triangles, normals generated from winding)
# ----------------------------------------------------------------------------------------------

static func _begin() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


static func _finish(st: SurfaceTool) -> ArrayMesh:
	st.generate_normals()
	return st.commit()


static func _v3(p: Vector2, z: float) -> Vector3:
	return Vector3(p.x, p.y, z)


## Emits one triangle wound so its face normal agrees with `want`.
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, want: Vector3) -> void:
	var n: Vector3 = (b - a).cross(c - a)
	if n.dot(want) >= 0.0:
		st.add_vertex(a)
		st.add_vertex(b)
		st.add_vertex(c)
	else:
		st.add_vertex(a)
		st.add_vertex(c)
		st.add_vertex(b)


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, want: Vector3) -> void:
	_tri(st, a, b, c, want)
	_tri(st, a, c, d, want)


static func _signed_area(pts: PackedVector2Array) -> float:
	var a: float = 0.0
	var n: int = pts.size()
	for i in range(n):
		var p: Vector2 = pts[i]
		var q: Vector2 = pts[(i + 1) % n]
		a += p.x * q.y - q.x * p.y
	return a * 0.5


static func _fan_indices(count: int) -> PackedInt32Array:
	var idx := PackedInt32Array()
	for i in range(1, count - 1):
		idx.append(0)
		idx.append(i)
		idx.append(i + 1)
	return idx


## Front cap at z = -thick (normal -z, toward the viewer) and back cap at z = 0 (normal +z).
static func _caps_polygon(st: SurfaceTool, pts: PackedVector2Array, thick: float) -> void:
	var idx: PackedInt32Array = Geometry2D.triangulate_polygon(pts)
	if idx.size() < 3:
		idx = _fan_indices(pts.size())
	for k in range(0, idx.size() - 2, 3):
		var p0: Vector2 = pts[idx[k]]
		var p1: Vector2 = pts[idx[k + 1]]
		var p2: Vector2 = pts[idx[k + 2]]
		_tri(st, _v3(p0, -thick), _v3(p1, -thick), _v3(p2, -thick), Vector3(0.0, 0.0, -1.0))
		_tri(st, _v3(p0, 0.0), _v3(p1, 0.0), _v3(p2, 0.0), Vector3(0.0, 0.0, 1.0))


static func _walls_loop(st: SurfaceTool, pts: PackedVector2Array, thick: float, ccw: bool) -> void:
	var n: int = pts.size()
	for i in range(n):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % n]
		var d: Vector2 = b - a
		if d.length_squared() < 1e-10:
			continue
		var nrm: Vector2 = Vector2(d.y, -d.x) if ccw else Vector2(-d.y, d.x)
		_quad(st, _v3(a, 0.0), _v3(b, 0.0), _v3(b, -thick), _v3(a, -thick), Vector3(nrm.x, nrm.y, 0.0))


## A simple (non-self-intersecting) polygon extruded from z = 0 back to z = -thick front.
static func _polygon_mesh(pts: PackedVector2Array, thick: float) -> ArrayMesh:
	var st := _begin()
	_caps_polygon(st, pts, thick)
	_walls_loop(st, pts, thick, _signed_area(pts) > 0.0)
	return _finish(st)


## A band between two index-aligned polylines (inner, outer): quad-strip caps, side walls,
## and end caps when open. Handles arcs, full rings, ribbons and the holed slab.
static func _band_mesh(inner: PackedVector2Array, outer: PackedVector2Array, thick: float, closed: bool) -> ArrayMesh:
	var st := _begin()
	var n: int = mini(inner.size(), outer.size())
	var last: int = n if closed else n - 1
	var front: float = -thick
	for i in range(last):
		var j: int = (i + 1) % n
		var i0: Vector2 = inner[i]
		var i1: Vector2 = inner[j]
		var o0: Vector2 = outer[i]
		var o1: Vector2 = outer[j]
		_quad(st, _v3(i0, front), _v3(o0, front), _v3(o1, front), _v3(i1, front), Vector3(0.0, 0.0, -1.0))
		_quad(st, _v3(i0, 0.0), _v3(o0, 0.0), _v3(o1, 0.0), _v3(i1, 0.0), Vector3(0.0, 0.0, 1.0))
		var mid: Vector2 = (i0 + i1 + o0 + o1) * 0.25
		var out_o: Vector2 = (o0 + o1) * 0.5 - mid
		var out_i: Vector2 = (i0 + i1) * 0.5 - mid
		_quad(st, _v3(o0, 0.0), _v3(o1, 0.0), _v3(o1, front), _v3(o0, front), Vector3(out_o.x, out_o.y, 0.0))
		_quad(st, _v3(i0, 0.0), _v3(i1, 0.0), _v3(i1, front), _v3(i0, front), Vector3(out_i.x, out_i.y, 0.0))
	if not closed and n >= 2:
		var e0: Vector2 = (inner[0] + outer[0]) * 0.5 - (inner[1] + outer[1]) * 0.5
		_quad(st, _v3(inner[0], 0.0), _v3(outer[0], 0.0), _v3(outer[0], front), _v3(inner[0], front), Vector3(e0.x, e0.y, 0.0))
		var e1: Vector2 = (inner[n - 1] + outer[n - 1]) * 0.5 - (inner[n - 2] + outer[n - 2]) * 0.5
		_quad(st, _v3(inner[n - 1], 0.0), _v3(outer[n - 1], 0.0), _v3(outer[n - 1], front), _v3(inner[n - 1], front), Vector3(e1.x, e1.y, 0.0))
	return _finish(st)


static func _arc_mesh(r_in: float, r_out: float, a0: float, a1: float, segs: int, thick: float) -> ArrayMesh:
	var inner := PackedVector2Array()
	var outer := PackedVector2Array()
	var closed: bool = absf(a1 - a0) >= TAU - 0.001
	var count: int = segs if closed else segs + 1
	for i in range(count):
		var t: float = float(i) / float(segs)
		var ang: float = a0 + (a1 - a0) * t
		var ca: float = cos(ang)
		var sa: float = sin(ang)
		inner.append(Vector2(ca * r_in, sa * r_in))
		outer.append(Vector2(ca * r_out, sa * r_out))
	return _band_mesh(inner, outer, thick, closed)


static func _ribbon_mesh(path: PackedVector2Array, widths: PackedFloat32Array, thick: float) -> ArrayMesh:
	var inner := PackedVector2Array()
	var outer := PackedVector2Array()
	var n: int = path.size()
	for i in range(n):
		var ip: int = maxi(i - 1, 0)
		var inx: int = mini(i + 1, n - 1)
		var tng: Vector2 = (path[inx] - path[ip]).normalized()
		var nrm := Vector2(-tng.y, tng.x)
		var hw: float = widths[mini(i, widths.size() - 1)] * 0.5
		inner.append(path[i] - nrm * hw)
		outer.append(path[i] + nrm * hw)
	return _band_mesh(inner, outer, thick, false)


## A w x h rectangle centred on the origin with a round hole at `hole`: a closed band from the
## circle out to the rectangle boundary, one ray per angle, the four corner angles included.
static func _holed_slab_mesh(w: float, h: float, hole: Vector2, hole_r: float, thick: float) -> ArrayMesh:
	var hw: float = w * 0.5
	var hh: float = h * 0.5
	var angles := PackedFloat32Array()
	var n: int = 64
	for i in range(n):
		angles.append(TAU * float(i) / float(n))
	var corners: Array[Vector2] = [Vector2(hw, hh), Vector2(-hw, hh), Vector2(-hw, -hh), Vector2(hw, -hh)]
	for k in range(4):
		var ca: float = (corners[k] - hole).angle()
		angles.append(fposmod(ca, TAU))
	angles.sort()
	var inner := PackedVector2Array()
	var outer := PackedVector2Array()
	var prev_ang: float = -10.0
	for k in range(angles.size()):
		var ang: float = angles[k]
		if ang - prev_ang < 0.0005:
			continue
		prev_ang = ang
		var d := Vector2(cos(ang), sin(ang))
		inner.append(hole + d * hole_r)
		var tx: float = INF
		if absf(d.x) > 0.000001:
			var ex: float = hw if d.x > 0.0 else -hw
			tx = (ex - hole.x) / d.x
		var ty: float = INF
		if absf(d.y) > 0.000001:
			var ey: float = hh if d.y > 0.0 else -hh
			ty = (ey - hole.y) / d.y
		var t: float = minf(tx, ty)
		outer.append(hole + d * t)
	return _band_mesh(inner, outer, thick, true)


# ----------------------------------------------------------------------------------------------
# the axes: what a cut-out is (cutout), and what it hangs on (backing)
# ----------------------------------------------------------------------------------------------

## Every solid shape in the relief comes through here. Fossilised, it is emptied out: the
## outline survives as a rim and the plate it enclosed is gone.
static func _plate(pts: PackedVector2Array, thick: float, ctx: Dictionary) -> ArrayMesh:
	if String(ctx.get("cut", "flat")) == "fossil":
		return _rim_mesh(pts, thick, 0.032)
	return _polygon_mesh(pts, thick)


## A closed band between an outline and a copy of itself pulled in toward its own centroid,
## so any outline - blob, notched slab, wedge, cone - becomes a frame of about `rim` metres.
## Scaling about the centroid keeps the two loops index-aligned, which is what the band
## extruder wants; an offset routine would not, and a thin frame does not need the accuracy.
static func _rim_mesh(pts: PackedVector2Array, thick: float, rim: float) -> ArrayMesh:
	var n: int = pts.size()
	if n < 3:
		return _polygon_mesh(pts, thick)
	var c := Vector2.ZERO
	for i in range(n):
		c += pts[i]
	c /= float(n)
	var mean_r: float = 0.0
	for i in range(n):
		mean_r += (pts[i] - c).length()
	mean_r /= float(n)
	var k: float = clampf(1.0 - rim / maxf(mean_r, 0.02), 0.30, 0.90)
	var inner := PackedVector2Array()
	for i in range(n):
		inner.append(c + (pts[i] - c) * k)
	return _band_mesh(inner, pts, thick, true)


static func _rect_pts(w: float, h: float) -> PackedVector2Array:
	var hw: float = w * 0.5
	var hh: float = h * 0.5
	var pts := PackedVector2Array()
	pts.append(Vector2(-hw, -hh))
	pts.append(Vector2(hw, -hh))
	pts.append(Vector2(hw, hh))
	pts.append(Vector2(-hw, hh))
	return pts


## A leaf from the origin out along +x: a swelling that narrows to a point.
static func _petal_pts(length: float, wide: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(n + 1):
		var t: float = float(i) / float(n)
		pts.append(Vector2(length * t, wide * sin(PI * t) * (1.0 - 0.35 * t)))
	for i in range(n - 1, 0, -1):
		var t2: float = float(i) / float(n)
		pts.append(Vector2(length * t2, -wide * sin(PI * t2) * (1.0 - 0.35 * t2)))
	return pts


## The relief keeps to the contract's mesh count. A swarm of a fold of a bloom would run
## past it, so every added-on piece asks first, and stops adding rather than overflow.
static func _room(root: Node3D) -> bool:
	return root.get_child_count() < MAX_PIECES


static func _union(root: Node3D) -> AABB:
	var box := AABB()
	var first: bool = true
	for c in root.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh != null:
			var mi: MeshInstance3D = c
			var a: AABB = mi.transform * (mi.mesh as Mesh).get_aabb()
			if first:
				box = a
				first = false
			else:
				box = box.merge(a)
	return box


## FLOOD: the bottom of the wall is poured solid - one thick mass with a wavy shore,
## standing out of the wall far enough to drown whatever the tangle put down there, with a
## few plates surfacing through it like islands.
static func _pour(root: Node3D, vrng: RandomNumberGenerator, textures: Array[ImageTexture], palette: Array[Color]) -> void:
	var h: float = vrng.randf_range(0.36, 0.56)
	var depth: float = vrng.randf_range(0.20, 0.30)
	var hw: float = WALL_W * 0.5 + 0.04
	var p1: float = vrng.randf_range(0.0, TAU)
	var p2: float = vrng.randf_range(0.0, TAU)
	var p3: float = vrng.randf_range(0.0, TAU)
	var pts := PackedVector2Array()
	pts.append(Vector2(-hw, 0.0))
	pts.append(Vector2(hw, 0.0))
	var n: int = 48
	for i in range(n + 1):
		var t: float = float(i) / float(n)
		var x: float = lerpf(hw, -hw, t)
		var y: float = h * (1.0 + 0.17 * sin(t * TAU * 1.5 + p1) + 0.10 * sin(t * TAU * 3.0 + p2) + 0.05 * sin(t * TAU * 6.0 + p3))
		pts.append(Vector2(x, y))
	var tint: Color = _pick(vrng, palette, 0.45, 0.2, 0.3, 0.05)
	var mat: StandardMaterial3D = _mat(vrng, tint, textures[vrng.randi_range(0, textures.size() - 1)])
	mat.roughness = 0.44
	mat.metallic = 0.12
	_add(root, _polygon_mesh(pts, depth), mat, Vector3(0.0, 0.0, 0.0), Vector3.ZERO)

	var n_isl: int = vrng.randi_range(3, 6)
	for i in range(n_isl):
		if not _room(root):
			return
		var r: float = vrng.randf_range(0.10, 0.22)
		var it: float = vrng.randf_range(0.04, 0.07)
		var ix: float = vrng.randf_range(-hw + r, hw - r)
		var itint: Color = _pick(vrng, palette, 0.25, 0.3, 0.25, 0.2)
		var imat: StandardMaterial3D = _mat(vrng, itint, textures[vrng.randi_range(0, textures.size() - 1)])
		_add(root, _polygon_mesh(_blob_pts(vrng, r, 30), it), imat,
			Vector3(ix, h + vrng.randf_range(-0.02, 0.05), -depth * vrng.randf_range(0.25, 0.8)),
			Vector3(-90.0, vrng.randf_range(0.0, 360.0), 0.0))


## UNHOUSED: no wall. The tangle keeps its shape in the air and every piece that can reach
## the rail above is hung from it on a thread.
static func _threads(root: Node3D, vrng: RandomNumberGenerator) -> void:
	var kids: Array = root.get_children()
	var rail_y: float = WALL_H + 0.06
	var rail := BoxMesh.new()
	rail.size = Vector3(WALL_W + 0.10, 0.020, 0.020)
	var rail_mat := StandardMaterial3D.new()
	rail_mat.albedo_color = Color(0.14, 0.14, 0.15)
	rail_mat.roughness = 0.6
	rail_mat.metallic = 0.55
	_add(root, rail, rail_mat, Vector3(0.0, rail_y, -0.16), Vector3.ZERO)
	var thread_mat := StandardMaterial3D.new()
	thread_mat.albedo_color = Color(0.17, 0.17, 0.18)
	thread_mat.roughness = 0.85
	thread_mat.metallic = 0.0
	for c in kids:
		if not (c is MeshInstance3D):
			continue
		var mi: MeshInstance3D = c
		if mi.mesh == null or not _room(root):
			continue
		if vrng.randf() < 0.14:
			continue
		var a: AABB = mi.transform * (mi.mesh as Mesh).get_aabb()
		var top: float = a.position.y + a.size.y
		var span: float = rail_y - top
		if span < 0.05:
			continue
		var wire := BoxMesh.new()
		var gauge: float = vrng.randf_range(0.008, 0.014)
		wire.size = Vector3(gauge, span, gauge)
		_add(root, wire, thread_mat,
			Vector3(a.position.x + a.size.x * 0.5 + vrng.randf_range(-0.02, 0.02), top + span * 0.5,
				a.position.z + a.size.z * 0.5), Vector3.ZERO)


## MELT: what ran off the wall has to end somewhere. A few flat blobs lie on the floor in
## front of the relief, spread toward the viewer, the pool the drips are feeding.
static func _puddle(root: Node3D, vrng: RandomNumberGenerator, textures: Array[ImageTexture], palette: Array[Color]) -> void:
	var n: int = vrng.randi_range(3, 5)
	for i in range(n):
		if not _room(root):
			return
		var r: float = vrng.randf_range(0.18, 0.34)
		var t: float = vrng.randf_range(0.045, 0.085)
		var tint: Color = _pick(vrng, palette, 0.4, 0.25, 0.25, 0.1)
		var mat: StandardMaterial3D = _mat(vrng, tint, textures[vrng.randi_range(0, textures.size() - 1)])
		mat.roughness = 0.42
		mat.metallic = 0.14
		# rotated a quarter turn onto its back: the plate's own up becomes -z, so the
		# blob spreads out toward the viewer, and its extrusion goes down onto the floor.
		_add(root, _polygon_mesh(_blob_pts(vrng, r, 34), t), mat,
			Vector3(vrng.randf_range(-0.95, 0.95), t, -vrng.randf_range(0.02, 0.14)),
			Vector3(-90.0, vrng.randf_range(0.0, 360.0), 0.0))
