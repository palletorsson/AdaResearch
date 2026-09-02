extends RefCounted
## stijl_robot — one De Stijl toy robot in a dance pose, with its pink shop post.
##
## Reference: scratchpad/refs/stijl_robot.png — a 2048x536 panorama of Rietveld-style
## toy robots standing between the shelves and pink posts of a convenience store:
## bodies assembled from white, saffron and pink slabs, black ball joints exposed,
## smooth white domed helmets with a pink dot on the side.
##
## Reproduced, and how:
##   1. The smooth white domed helmet — one SphereMesh drawn taller than wide with a
##      clearcoat, a dark face plate set into its front and a graphite visor slit.
##   2. The pink dot on the helmet's side — a flat CylinderMesh disc sitting on the
##      dome; a small red tab on the other side, like the image's red ear plates.
##   3. The Rietveld overlap — BoxMesh slabs and bars that PASS each other instead of
##      meeting: a yellow shoulder bar runs through the white torso and out past both
##      shoulders, a white hip bar runs through the yellow pelvis, and every limb is a
##      white core bar overshooting its joints with a coloured block riding one face and
##      sliding past one joint and a thin strip on the other face sliding past the other.
##   4. Exposed dark joints — black SphereMesh balls at shoulder, elbow, wrist, hip,
##      knee and ankle, a dark waist cylinder, and dark CylinderMesh hinge pins through
##      the elbows and knees.
##   5. Signal-red accents — a red chest plate, red fingertips, a red tab on the post.
##   6. The dotted black-and-white rack from the middle of the image — a 64x64 dot-grid
##      ImageTexture on a slab worn as a back pack.
##   7. The pose — weight on one leg (that hip up, the torso counter-leaning), the free
##      leg forward with the heel lifted and the toe on the floor, one arm out sideways
##      and up with the forearm raised, the other arm reaching forward from the hip,
##      the head turned. The seed picks the side, the angles and the pelvis colour.
##   8. The pink post — a tall thin pink bar on a base plate, a crossbar running back
##      from it under a white cap, a low pink bar crossing it, one dark bolt.
##
## Given up: the crowd (one robot only), the shop shelves and the other posts, the
## loose robot parts lying on the floor, and the moulded ribbing along the image's
## limbs — the bars here are plain matte boxes.

const WHITE: Color = Color(0.94, 0.93, 0.90)
const SAFFRON: Color = Color(0.93, 0.78, 0.09)
const PINK: Color = Color(0.91, 0.49, 0.72)
const RED: Color = Color(0.86, 0.13, 0.10)
const INK: Color = Color(0.12, 0.12, 0.13)
const GRAPHITE: Color = Color(0.34, 0.34, 0.36)


static func describe() -> String:
	return "A De Stijl toy robot of white, saffron and pink slabs with black ball joints, dancing with its weight on one leg and one arm raised beside a thin pink shop post."


static func build(root: Node3D, seed: int) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed

	# ---- materials: matte toy plastic, one glazed helmet, dark joints ----
	var white: StandardMaterial3D = _mat(WHITE, 0.55, 0.0, 0.0)
	var helmet: StandardMaterial3D = _mat(WHITE, 0.32, 0.0, 0.7)
	var yellow: StandardMaterial3D = _mat(SAFFRON, 0.6, 0.0, 0.0)
	var pink: StandardMaterial3D = _mat(PINK, 0.6, 0.0, 0.0)
	var red: StandardMaterial3D = _mat(RED, 0.5, 0.0, 0.3)
	var ink: StandardMaterial3D = _mat(INK, 0.45, 0.25, 0.0)
	var graphite: StandardMaterial3D = _mat(GRAPHITE, 0.5, 0.4, 0.0)
	var dotted: StandardMaterial3D = _mat(Color(1.0, 1.0, 1.0), 0.7, 0.0, 0.0)
	dotted.albedo_texture = _dot_tex(rng.randi_range(0, 7))
	dotted.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	dotted.uv1_scale = Vector3(2.0, 2.0, 1.0)

	# ---- the individual: side, stance, gesture, colours ----
	var mirror: float = 1.0 if rng.randf() < 0.5 else -1.0    # side of the raised arm
	var wl: float = -mirror                                    # side of the weight leg
	var hip_y: float = rng.randf_range(0.77, 0.81)
	var hip_tilt: float = deg_to_rad(rng.randf_range(3.0, 7.0))
	var lean: float = deg_to_rad(rng.randf_range(2.0, 6.0))
	var arm_up: float = deg_to_rad(rng.randf_range(10.0, 22.0))
	var fore_up: float = deg_to_rad(rng.randf_range(58.0, 75.0))
	var knee_fwd: float = deg_to_rad(rng.randf_range(18.0, 30.0))
	var head_yaw: float = deg_to_rad(rng.randf_range(-30.0, 30.0))
	var torso_w: float = rng.randf_range(0.24, 0.28)
	var head_r: float = rng.randf_range(0.11, 0.12)
	var bar_w: float = rng.randf_range(0.055, 0.068)
	var pelvis_mat: StandardMaterial3D = pink if rng.randf() < 0.3 else yellow
	var groin_mat: StandardMaterial3D = pink if pelvis_mat == yellow else white
	var dot_mat: StandardMaterial3D = pink if rng.randf() < 0.8 else red
	var thigh_block_mat: StandardMaterial3D = pink if rng.randf() < 0.25 else yellow

	# ---- skeleton points ----
	var thigh: float = 0.37
	var shin: float = 0.35
	var hip_w: Vector3 = Vector3(wl * 0.11, hip_y + 0.015, 0.0)
	var hip_f: Vector3 = Vector3(mirror * 0.11, hip_y - 0.015, 0.0)
	# weight leg: straight under the hip, the knee locked a touch forward
	var ankle_w: Vector3 = Vector3(wl * 0.10, 0.085, -0.01)
	var knee_w: Vector3 = hip_w.lerp(ankle_w, thigh / (thigh + shin)) + Vector3(0.0, 0.0, 0.02)
	# free leg: thigh swings forward, shin drops back, the heel comes off the floor
	var thigh_dir: Vector3 = Vector3(mirror * 0.03, -cos(knee_fwd), sin(knee_fwd)).normalized()
	var knee_f: Vector3 = hip_f + thigh_dir * thigh
	var shin_dir: Vector3 = Vector3(mirror * 0.06, -cos(0.17), -sin(0.17)).normalized()
	var ankle_f: Vector3 = knee_f + shin_dir * shin

	# ---- feet ----
	var foot_w_b: Basis = Basis(Vector3.UP, wl * deg_to_rad(8.0))
	var foot_w_c: Vector3 = Vector3(ankle_w.x, 0.03, ankle_w.z + 0.05)
	_box(root, Vector3(0.11, 0.06, 0.24), white, foot_w_c, foot_w_b)
	_box(root, Vector3(0.115, 0.045, 0.06), yellow, foot_w_c + foot_w_b * Vector3(0.0, 0.01, 0.10), foot_w_b)
	var foot_f_c: Vector3 = Vector3(ankle_f.x, ankle_f.y - 0.05, ankle_f.z + 0.07)
	var heel: float = clampf(asin(clampf((foot_f_c.y - 0.03) / 0.12, 0.0, 0.95)), 0.0, 0.7)
	var foot_f_b: Basis = Basis(Vector3.UP, mirror * deg_to_rad(18.0)) * Basis(Vector3.RIGHT, heel)
	_box(root, Vector3(0.11, 0.06, 0.24), white, foot_f_c, foot_f_b)
	_box(root, Vector3(0.115, 0.045, 0.06), yellow, foot_f_c + foot_f_b * Vector3(0.0, 0.01, 0.10), foot_f_b)
	_ball(root, 0.035, ink, ankle_w)
	_ball(root, 0.035, ink, ankle_f)

	# ---- legs ----
	_limb(root, hip_w, knee_w, bar_w, white, yellow, white, 0.25, 1.0)
	_limb(root, knee_w, ankle_w, bar_w * 0.9, white, yellow, white, -0.25, 1.0)
	_limb(root, hip_f, knee_f, bar_w, white, thigh_block_mat, white, -0.25, 1.0)
	_limb(root, knee_f, ankle_f, bar_w * 0.9, white, yellow, white, 0.25, -1.0)
	_ball(root, 0.042, ink, knee_w)
	_ball(root, 0.042, ink, knee_f)
	var shin_w_b: Basis = _basis_along(ankle_w - knee_w)
	var shin_f_b: Basis = _basis_along(ankle_f - knee_f)
	_cyl(root, 0.018, bar_w + 0.07, graphite, knee_w, _basis_along(shin_w_b.x))
	_cyl(root, 0.018, bar_w + 0.07, graphite, knee_f, _basis_along(shin_f_b.x))
	_ball(root, 0.048, ink, hip_w)
	_ball(root, 0.048, ink, hip_f)

	# ---- pelvis: a coloured slab, the white hip bar running through it ----
	var pelvis_b: Basis = Basis(Vector3.BACK, wl * hip_tilt)
	var pelvis_c: Vector3 = Vector3(0.0, hip_y + 0.075, 0.0)
	_box(root, Vector3(0.30, 0.13, 0.14), pelvis_mat, pelvis_c, pelvis_b)
	_box(root, Vector3(0.40, 0.05, 0.05), white, pelvis_c + pelvis_b * Vector3(0.0, 0.03, -0.055), pelvis_b)
	_box(root, Vector3(0.15, 0.09, 0.025), groin_mat, pelvis_c + pelvis_b * Vector3(mirror * 0.03, -0.01, 0.075), pelvis_b)

	# ---- waist joint, then the torso counter-leaning over the weight leg ----
	var waist_c: Vector3 = Vector3(0.0, hip_y + 0.15, 0.0)
	_cyl(root, 0.045, 0.06, ink, waist_c, Basis.IDENTITY)
	var torso_b: Basis = Basis(Vector3.BACK, -wl * lean)
	var torso_h: float = 0.34
	var torso_c: Vector3 = Vector3(0.0, hip_y + 0.165 + torso_h * 0.5, 0.0)
	_box(root, Vector3(torso_w, torso_h, 0.13), white, torso_c, torso_b)
	_box(root, Vector3(torso_w + 0.06, 0.035, 0.10), pink, torso_c + torso_b * Vector3(0.0, -torso_h * 0.5 + 0.012, 0.0), torso_b)
	_box(root, Vector3(0.05, 0.24, 0.17), yellow, torso_c + torso_b * Vector3(wl * (torso_w * 0.5 - 0.005), -0.03, 0.0), torso_b)
	_box(root, Vector3(0.05, 0.11, 0.16), yellow, torso_c + torso_b * Vector3(mirror * (torso_w * 0.5 - 0.005), -0.10, 0.0), torso_b)
	var sh_y: float = torso_h * 0.5 - 0.05
	_box(root, Vector3(0.50, 0.09, 0.09), yellow, torso_c + torso_b * Vector3(0.0, sh_y, -0.015), torso_b)
	_box(root, Vector3(0.32, 0.04, 0.05), white, torso_c + torso_b * Vector3(0.0, sh_y + 0.035, 0.05), torso_b)
	_box(root, Vector3(0.09, 0.11, 0.012), red, torso_c + torso_b * Vector3(mirror * 0.05, 0.02, 0.068), torso_b)
	_box(root, Vector3(0.16, 0.20, 0.06), dotted, torso_c + torso_b * Vector3(0.0, -0.02, -0.09), torso_b)

	# ---- shoulders ----
	var sh_r: Vector3 = torso_c + torso_b * Vector3(mirror * 0.245, sh_y, -0.015)
	var sh_h: Vector3 = torso_c + torso_b * Vector3(wl * 0.245, sh_y, -0.015)
	_ball(root, 0.045, ink, sh_r)
	_ball(root, 0.045, ink, sh_h)
	_box(root, Vector3(0.09, 0.03, 0.11), white, sh_r + torso_b * Vector3(0.0, 0.055, 0.0), torso_b)
	_box(root, Vector3(0.09, 0.03, 0.11), white, sh_h + torso_b * Vector3(0.0, 0.055, 0.0), torso_b)

	# ---- arms: one out and up, the other reaching forward from the hip ----
	var ua: float = 0.23
	var fa: float = 0.21
	var up_dir: Vector3 = Vector3(mirror * cos(arm_up), sin(arm_up), 0.06).normalized()
	var elbow_r: Vector3 = sh_r + up_dir * ua
	var fore_dir: Vector3 = Vector3(mirror * cos(fore_up) * 0.9, sin(fore_up), -0.12).normalized()
	var wrist_r: Vector3 = elbow_r + fore_dir * fa
	var down_dir: Vector3 = Vector3(wl * 0.22, -0.95, -0.12).normalized()
	var elbow_h: Vector3 = sh_h + down_dir * ua
	var reach_dir: Vector3 = Vector3(wl * 0.12, -0.45, 0.85).normalized()
	var wrist_h: Vector3 = elbow_h + reach_dir * fa
	_limb(root, sh_r, elbow_r, bar_w, white, yellow, white, 0.25, 1.0)
	_limb(root, elbow_r, wrist_r, bar_w * 0.85, white, yellow, white, -0.25, -1.0)
	_limb(root, sh_h, elbow_h, bar_w, white, yellow, white, 0.25, -1.0)
	_limb(root, elbow_h, wrist_h, bar_w * 0.85, white, yellow, white, -0.25, 1.0)
	_ball(root, 0.036, ink, elbow_r)
	_ball(root, 0.036, ink, elbow_h)
	var pin_r: Vector3 = up_dir.cross(fore_dir)
	if pin_r.length() < 0.05:
		pin_r = Vector3.BACK
	var pin_h: Vector3 = down_dir.cross(reach_dir)
	if pin_h.length() < 0.05:
		pin_h = Vector3.RIGHT
	_cyl(root, 0.016, bar_w + 0.06, graphite, elbow_r, _basis_along(pin_r))
	_cyl(root, 0.016, bar_w + 0.06, graphite, elbow_h, _basis_along(pin_h))
	_ball(root, 0.028, graphite, wrist_r)
	_ball(root, 0.028, graphite, wrist_h)
	_hand(root, wrist_r, fore_dir, white, red)
	_hand(root, wrist_h, reach_dir, white, red)

	# ---- neck and the domed helmet ----
	var neck_c: Vector3 = torso_c + torso_b * Vector3(0.0, torso_h * 0.5 + 0.03, 0.0)
	_cyl(root, 0.028, 0.08, ink, neck_c, torso_b)
	var head_b: Basis = torso_b * Basis(Vector3.UP, head_yaw) * Basis(Vector3.RIGHT, deg_to_rad(-4.0))
	var head_c: Vector3 = torso_c + torso_b * Vector3(0.0, torso_h * 0.5 + 0.05 + head_r * 1.1, 0.0)
	var dome: SphereMesh = SphereMesh.new()
	dome.radius = head_r
	dome.height = head_r * 2.2
	dome.radial_segments = 48
	dome.rings = 24
	_place(root, dome, helmet, head_c, head_b)
	_box(root, Vector3(head_r * 0.85, head_r * 0.7, 0.06), ink, head_c + head_b * Vector3(0.0, -head_r * 0.28, head_r - 0.02), head_b)
	_box(root, Vector3(head_r * 0.7, 0.012, 0.012), graphite, head_c + head_b * Vector3(0.0, -head_r * 0.12, head_r + 0.008), head_b)
	var dot_b: Basis = head_b * _basis_along(Vector3(mirror, 0.0, 0.0))
	_cyl(root, 0.035, 0.012, dot_mat, head_c + head_b * Vector3(mirror * (head_r + 0.001), head_r * 0.05, head_r * 0.1), dot_b)
	_box(root, Vector3(0.025, 0.05, 0.04), red, head_c + head_b * Vector3(-mirror * (head_r + 0.004), -head_r * 0.05, 0.0), head_b)

	# ---- the pink post, standing a little behind the robot on the weight side ----
	var px: float = wl * 0.44
	var pz: float = -0.12
	_box(root, Vector3(0.06, 1.46, 0.06), pink, Vector3(px, 0.73, pz), Basis.IDENTITY)
	_box(root, Vector3(0.18, 0.03, 0.18), pink, Vector3(px, 0.015, pz), Basis.IDENTITY)
	_box(root, Vector3(0.05, 0.05, 0.30), pink, Vector3(px, 1.28, pz - 0.10), Basis.IDENTITY)
	_box(root, Vector3(0.09, 0.08, 0.09), white, Vector3(px, 1.49, pz), Basis.IDENTITY)
	_box(root, Vector3(0.02, 0.05, 0.035), red, Vector3(px + wl * 0.02, 1.235, pz - 0.23), Basis.IDENTITY)
	var low_y: float = rng.randf_range(0.30, 0.50)
	_box(root, Vector3(0.26, 0.05, 0.05), pink, Vector3(px + wl * 0.03, low_y, pz), Basis.IDENTITY)
	_ball(root, 0.03, ink, Vector3(px, 1.28, pz + 0.035))


## A Rietveld limb: a white core bar that overshoots both joints, a coloured block
## riding on one face and sliding past one joint, a thin strip on the side face
## sliding past the other. `slide` is the fraction of the length the block moves,
## `face` picks which face (+1 / -1) the block rides.
static func _limb(root: Node3D, a: Vector3, b: Vector3, w: float, core_mat: StandardMaterial3D, block_mat: StandardMaterial3D, strip_mat: StandardMaterial3D, slide: float, face: float) -> void:
	var dir: Vector3 = b - a
	var seg: float = dir.length()
	var bb: Basis = _basis_along(dir)
	var mid: Vector3 = (a + b) * 0.5
	_box(root, Vector3(w, seg + 0.05, w), core_mat, mid, bb)
	var block_pos: Vector3 = mid + bb * Vector3(0.0, slide * seg, face * (w * 0.5 + 0.018))
	_box(root, Vector3(w * 1.55, seg * 0.6, 0.05), block_mat, block_pos, bb)
	var strip_pos: Vector3 = mid + bb * Vector3(face * (w * 0.5 + 0.004), -slide * seg * 0.8, 0.0)
	_box(root, Vector3(0.016, seg * 0.8, w * 0.7), strip_mat, strip_pos, bb)


## A hand: a flat white block continuing the forearm, with a red fingertip block.
static func _hand(root: Node3D, wrist: Vector3, dir: Vector3, white: StandardMaterial3D, red: StandardMaterial3D) -> void:
	var d: Vector3 = dir.normalized()
	var bb: Basis = _basis_along(d)
	_box(root, Vector3(0.06, 0.065, 0.03), white, wrist + d * 0.042, bb)
	_box(root, Vector3(0.062, 0.018, 0.032), red, wrist + d * 0.083, bb)


## A basis whose Y axis runs along `dir`, with its Z axis kept as close to the
## world front (+Z) as possible so limb blocks land on predictable faces.
static func _basis_along(dir: Vector3) -> Basis:
	var y: Vector3 = dir.normalized()
	var ref: Vector3 = Vector3.BACK
	if absf(y.dot(ref)) > 0.92:
		ref = Vector3.UP
	var z: Vector3 = (ref - y * y.dot(ref)).normalized()
	var x: Vector3 = y.cross(z).normalized()
	return Basis(x, y, z)


static func _mat(c: Color, rough: float, metal: float, coat: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	if coat > 0.0:
		m.clearcoat_enabled = true
		m.clearcoat = coat
		m.clearcoat_roughness = 0.25
	return m


## The dotted rack from the reference: a black field with a square light dot every
## eight pixels; `phase` slides the grid so two seeds never share a pattern.
static func _dot_tex(phase: int) -> ImageTexture:
	var px: int = 64
	var img: Image = Image.create(px, px, false, Image.FORMAT_RGB8)
	for y in range(px):
		for x in range(px):
			var xx: int = (x + phase) % 8
			var yy: int = (y + phase) % 8
			var lit: bool = xx >= 2 and xx <= 4 and yy >= 2 and yy <= 4
			img.set_pixel(x, y, WHITE if lit else INK)
	return ImageTexture.create_from_image(img)


static func _place(root: Node3D, mesh: Mesh, mat: StandardMaterial3D, pos: Vector3, b: Basis) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.transform = Transform3D(b, pos)
	root.add_child(mi)
	return mi


static func _box(root: Node3D, size: Vector3, mat: StandardMaterial3D, pos: Vector3, b: Basis) -> MeshInstance3D:
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	return _place(root, box, mat, pos, b)


static func _ball(root: Node3D, r: float, mat: StandardMaterial3D, pos: Vector3) -> MeshInstance3D:
	var sph: SphereMesh = SphereMesh.new()
	sph.radius = r
	sph.height = r * 2.0
	sph.radial_segments = 24
	sph.rings = 12
	return _place(root, sph, mat, pos, Basis.IDENTITY)


static func _cyl(root: Node3D, r: float, h: float, mat: StandardMaterial3D, pos: Vector3, b: Basis) -> MeshInstance3D:
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = r
	cyl.bottom_radius = r
	cyl.height = h
	cyl.radial_segments = 24
	return _place(root, cyl, mat, pos, b)
