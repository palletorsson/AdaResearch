extends RefCounted

## ROCAILLE - one body from refs/rocaille.png, the 2048x536 panorama of glazed
## porcelain figurines: blue-and-white wave stripes at the left, a pale green
## figure carrying raised white filigree scrolls, a mauve scale-lattice tangle
## in the middle, teal with black flowing lines, a plain yellow figure at the
## right. All of them boneless, bending, one leaning into the next.
##
## What is reproduced, and with what:
##   1. Two entwined bodies - a standing figure in contrapposto leaning over a
##      kneeling one; the stander's hand rests on the kneeler's far shoulder,
##      the kneeler's arm wraps the stander's hips. Spine and every limb are
##      Catmull-Rom curves sampled into chains of overlapping CapsuleMesh with
##      tapering radii, so there are no elbows or knees - the bodies bend like
##      the clay in the picture.
##   2. Wide hips, a tipped head, a shoulder line: fat first capsule of the
##      spine, SphereMesh ellipsoids (height != 2 * radius) with a z-rotation,
##      one capsule between the shoulders.
##   3. Blue-and-white wave stripes - an ImageTexture painted per pixel (rows
##      of stripes displaced by three sines), tiled by world-space triplanar
##      mapping so the stripes run unbroken across the capsule seams.
##   4. Mauve scale lattice - a fish-scale tiling with concentric bands and a
##      dark rim, painted by finding the top-most scale disc for each pixel.
##   5. Pale green with white filigree - volutes, comma flicks and pearls
##      stamped into the texture, AND raised white scrolls: SurfaceTool tubes
##      swept along a volute spiral projected onto the host limb's surface,
##      with a bead at the eye and loose pearls (small SphereMesh).
##   6. Teal with black flowing lines, and plain yellow - the two other skins.
##   7. THE QUEER GLAZE (2026-09-03). The colours named above are the
##      reference's; what is painted now is dealt from the loud palette, and the
##      surface under the pattern is dealt from DreamSkin. One firing chemistry
##      for the pair - patent, candy, wet, holographic foil, oil slick, pearl or
##      latex - and a second for the raised filigree - pearl, chrome, neon or
##      patent. A PATTERNED skin caps its metallic at 0.5 and hands its own
##      texture to the emission, so the pattern glows instead of photographing
##      black under a mirror finish; an unpatterned body keeps the finish's own
##      iridescent sweep. Porcelain keeps its glaze coat whatever the finish:
##      clearcoat >= 0.9, clearcoat roughness <= 0.06.
##   8. The one matte passage is the BISCUIT kiln, where by definition there is
##      no glaze - chalky armature rods, roughness 0.88, no clearcoat. Its hoops
##      are now glossy: the ghost of the glaze, still measuring out a body that
##      fired off the armature. Chalk against patent is the contrast, and the
##      matte fireclay stilts of the fused kiln are the same argument.
##   9. A seed is an individual: the finish of the firing and of the filigree,
##      which two skins (the stander is always patterned), every ink and ground
##      in them, the lean, the hip sway, the head tilt, the plumpness of each
##      body, the stripe phase, the band width, where the scrolls sit.
##
## Given up: faces and fingers (the reference has none either), the third and
## fourth bodies of the mauve tangle, and true relief for the small filigree -
## only the large scrolls stand off the glaze, the fine ones are painted.
##
## AXES - both are things that happen to porcelain, pushed past the reference:
##   kiln     - what the firing did to the pair. fired = as glazed today;
##              slumped = the heat took them, lower halves pancaking outward
##              into a poured puddle; burst = trapped steam blew the figures
##              apart, every piece hovering out along its own outward normal;
##              biscuit = the flesh never glazed and is gone, leaving thin
##              armature rods with glossy hoops where the bodies used to swell;
##              fused = they went into the saggar touching and came out ONE
##              body. The field is marched by DreamIso from the same joints and
##              radii every other value assembles - one tapered capsule per bone
##              instead of a chain of seven - so the arms GROW out of the torso
##              with a fillet, the two spines run together where they leaned,
##              and the gap under the draped arm is a hole because the field
##              never crossed zero there, not because a piece was cut away.
##              Only the stander's skin survives the melt; the kneeler's is left
##              in the glaze that ran off. The body is ONE mesh, so the value
##              carries its own trimmings - the saggar: a pool of run glaze,
##              six matte fireclay stilts, fourteen drips beaded at the tip,
##              pearls cooled where they landed. About 51 pieces, which is what
##              holds the value over the 40-mesh floor. If the mesher returns
##              nothing the pair is assembled from primitives instead, so the
##              plinth is never empty.
##   ornament - what grows out of the glaze. scrolls = the raised filigree as
##              today; shells = fluted rocaille scallops erupting from the
##              limbs; blooms = every hand and crown ending in a porcelain
##              flower; threads = the glaze unravelling into drooping coils.

const TEX: int = 256

const Gloss := preload("res://commons/artifacts/dream_bodies/dream_skin.gd")
const Iso := preload("res://commons/artifacts/dream_bodies/dream_iso.gd")

## The firing's chemistry. The pair share one - they went in together - and the
## raised filigree gets its own, so the ornament reads as a second material and
## not as a bump in the first.
const GLAZES: Array[String] = ["patent", "candy", "wet", "holo", "oilslick", "pearl", "latex"]
const RELIEF_FINISHES: Array[String] = ["pearl", "chrome", "neon", "patent"]


static func describe() -> String:
	return "Two Rocaille figurines, boneless and entwined - a standing body leaning into a kneeling one - their porcelain painted with wave stripes, a scale lattice or raised filigree and fired in a queer glaze: patent, candy, oil slick, holographic foil, pearl or latex."


static func axes() -> Dictionary:
	return {
		"kiln": ["fired", "slumped", "burst", "biscuit", "fused"],
		"ornament": ["scrolls", "shells", "blooms", "threads"],
	}


static func build(root: Node3D, seed: int, opts: Dictionary = {}) -> void:
	var kiln: String = String(opts.get("kiln", "fired"))
	var ornament: String = String(opts.get("ornament", "scrolls"))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	# --- one firing, one glaze chemistry for the pair; the filigree gets its own
	var finish: String = GLAZES[rng.randi_range(0, GLAZES.size() - 1)]
	var relief_finish: String = RELIEF_FINISHES[rng.randi_range(0, RELIEF_FINISHES.size() - 1)]
	# --- skins: the stander is always patterned, the kneeler wears anything else
	var patterned: Array = ["filigree", "scales", "waves"]
	var everything: Array = ["filigree", "scales", "waves", "flow", "plain"]
	var skin_a: String = patterned[rng.randi_range(0, patterned.size() - 1)]
	var rest: Array = []
	for k: String in everything:
		if k != skin_a:
			rest.append(k)
	var skin_b: String = rest[rng.randi_range(0, rest.size() - 1)]
	var mat_a: StandardMaterial3D = _skin(skin_a, finish, rng)
	var mat_b: StandardMaterial3D = _skin(skin_b, finish, rng)
	# the raised filigree: porcelain white most of the time, loud when it isn't
	var relief_col: Color = Color(0.98, 0.97, 0.93)
	if rng.randf() < 0.42:
		relief_col = _loud(rng)
	var relief: StandardMaterial3D = _glaze(relief_finish, null, relief_col, 1.0, rng)
	relief.cull_mode = BaseMaterial3D.CULL_DISABLED
	# --- the individual
	var lean: float = rng.randf_range(0.14, 0.26)
	var sway: float = rng.randf_range(0.02, 0.08)
	var plump_a: float = rng.randf_range(0.92, 1.10)
	var plump_b: float = rng.randf_range(0.92, 1.10)
	var tilt: float = rng.randf_range(-0.02, 0.06)
	var twist: float = rng.randf_range(0.0, 0.08)
	var ox: float = 0.06
	# --- the kiln decides how much flesh is left on the armature. the biscuit
	# bodies go chalk, but the relief stays glazed - the hoops are the ghost of
	# a glaze that fired off a body which is no longer there.
	var flesh: float = 1.0
	if kiln == "biscuit":
		flesh = 0.30
		mat_a = _bisque(0.93)
		mat_b = _bisque(0.85)
	var ja: Dictionary = _stander_joints(lean, sway, plump_a, tilt, ox, flesh)
	var jb: Dictionary = _kneeler_joints(plump_b, twist, ox, flesh)
	var hosts_a: Array = []
	var hosts_b: Array = []
	var tips_a: Array = []
	var tips_b: Array = []
	# --- FUSED marches the field. CHECK it: an empty mesh falls back to the
	# family's own primitive pair, from the same joints, rather than an empty
	# plinth. The mesher is new.
	var grown: bool = false
	if kiln == "fused":
		grown = _grow(root, ja, jb, mat_a, hosts_a, hosts_b, tips_a, tips_b)
	if not grown:
		_figure(root, mat_a, ja, hosts_a, tips_a)
		_figure(root, mat_b, jb, hosts_b, tips_b)
	if flesh < 0.999:
		_cage(root, relief, hosts_a, flesh)
		_cage(root, relief, hosts_b, flesh)
	match ornament:
		"shells":
			_shells(root, relief, hosts_a, hosts_b, rng)
		"blooms":
			_blooms(root, relief, mat_a, mat_b, tips_a, tips_b, rng)
		"threads":
			_threads(root, relief, hosts_a, hosts_b, rng)
		_:
			if skin_a == "filigree":
				_relief(root, relief, hosts_a, rng)
			if skin_b == "filigree":
				_relief(root, relief, hosts_b, rng)
	match kiln:
		"slumped":
			_slump(root, mat_a, mat_b, rng)
		"burst":
			_burst(root)
		"fused":
			_saggar(root, mat_a, mat_b, relief, hosts_a, hosts_b, rng)
	_settle(root)


# ---------------------------------------------------------------- the bodies

## THE JOINTS, in one place. Both bodies are the same shape driven by different
## numbers, so there is ONE assembler and ONE field builder below, and both read
## from these dictionaries. That is what makes the fused body the same body: the
## field is marched from the joints and radii the primitives are built from, not
## from a second set of numbers that would drift.
static func _stander_joints(lean: float, sway: float, plump: float, tilt: float, ox: float, flesh: float) -> Dictionary:
	var o := Vector3(ox, 0.0, 0.0)
	var pelvis: Vector3 = Vector3(0.12 + sway, 0.79, 0.0) + o
	var neck: Vector3 = Vector3(0.12 - lean, 1.32, 0.06) + o
	var head_c: Vector3 = neck + Vector3(-0.05 - tilt, 0.13, 0.03)
	return {
		# spine: the fat hips up to the neck
		"pelvis": pelvis,
		"waist": Vector3(0.10 + sway * 0.5, 0.97, 0.02) + o,
		"chest": Vector3(0.06 - lean * 0.5, 1.15, 0.05) + o,
		"neck": neck,
		"r_spine": [0.15 * plump * flesh, 0.10 * plump * flesh, 0.12 * plump * flesh, 0.06 * flesh],
		"sh_l": neck + Vector3(-0.15, -0.04, 0.02),
		"sh_r": neck + Vector3(0.15, -0.04, -0.02),
		"r_sh": 0.065 * plump * flesh,
		# head, tipped toward the kneeler
		"r_neck": 0.05 * flesh,
		"head_c": head_c,
		"head_r": 0.085,
		"head_h": 1.15,
		"head_rot": Basis(Vector3(0.0, 0.0, 1.0), 0.22 + tilt * 2.0),
		"s_head": 0.26,
		# legs: the right bears the weight under the pushed hip, the left knee drifts
		"hip_l": pelvis + Vector3(-0.07, -0.03, 0.0),
		"hip_r": pelvis + Vector3(0.07, -0.03, 0.0),
		"knee_l": Vector3(0.02, 0.43, 0.08) + o,
		"ankle_l": Vector3(0.0, 0.075, 0.06) + o,
		"knee_r": Vector3(0.26 + sway, 0.43, -0.03) + o,
		"ankle_r": Vector3(0.26 + sway, 0.075, -0.06) + o,
		"r_leg": [0.085 * plump * flesh, 0.062 * plump * flesh, 0.045 * flesh],
		"foot_l": Vector3(-0.2, 0.0, 1.0),
		"foot_r": Vector3(0.25, 0.0, 1.0),
		"r_foot": 0.046 * flesh,
		# left arm drapes behind the kneeler's head, right hand on the pushed hip
		"elbow_l": Vector3(-0.30 - lean * 0.3, 1.14, 0.02) + o,
		"wrist_l": Vector3(-0.43, 1.02, 0.06) + o,
		"hand_l": Vector3(-0.45, 0.99, 0.10) + o,
		"elbow_r": Vector3(0.32 + sway, 1.08, -0.04) + o,
		"wrist_r": Vector3(0.26 + sway, 0.88, 0.07) + o,
		"hand_r": Vector3(0.23 + sway, 0.84, 0.12) + o,
		"r_arm": [0.058 * plump * flesh, 0.046 * flesh, 0.036 * flesh],
		"r_hand": 0.036 * flesh,
		"s_hand_l": 0.21,
		"s_hand_r": 0.20,
	}


static func _kneeler_joints(plump: float, twist: float, ox: float, flesh: float) -> Dictionary:
	var o := Vector3(ox, 0.0, 0.0)
	var bx: float = -0.32
	var pelvis: Vector3 = Vector3(bx, 0.44, 0.0) + o
	var neck: Vector3 = Vector3(bx + 0.06, 0.96, 0.12 + twist) + o
	var head_c: Vector3 = neck + Vector3(0.03, 0.11, 0.03)
	return {
		"pelvis": pelvis,
		"waist": Vector3(bx - 0.01, 0.62, 0.05 + twist * 0.5) + o,
		"chest": Vector3(bx + 0.02, 0.80, 0.10 + twist) + o,
		"neck": neck,
		"r_spine": [0.14 * plump * flesh, 0.095 * plump * flesh, 0.115 * plump * flesh, 0.055 * flesh],
		"sh_l": neck + Vector3(-0.14, -0.03, -0.04),
		"sh_r": neck + Vector3(0.14, -0.03, 0.04),
		"r_sh": 0.06 * plump * flesh,
		"r_neck": 0.045 * flesh,
		"head_c": head_c,
		"head_r": 0.08,
		"head_h": 1.1,
		"head_rot": Basis(Vector3(0.0, 0.0, 1.0), -0.3),
		"s_head": 0.24,
		# kneeling legs: thigh down to a knee on the floor, shin back along it
		"hip_l": pelvis + Vector3(-0.08, -0.02, -0.02),
		"hip_r": pelvis + Vector3(0.08, -0.02, 0.02),
		"knee_l": Vector3(bx - 0.18, 0.10, 0.12) + o,
		"ankle_l": Vector3(bx - 0.21, 0.10, -0.20) + o,
		"knee_r": Vector3(bx + 0.12, 0.10, 0.22) + o,
		"ankle_r": Vector3(bx + 0.09, 0.10, -0.10) + o,
		"r_leg": [0.08 * plump * flesh, 0.065 * plump * flesh, 0.05 * flesh],
		"foot_l": Vector3(-0.15, 0.0, -1.0),
		"foot_r": Vector3(-0.1, 0.0, -1.0),
		"r_foot": 0.046 * flesh,
		# right arm wraps the stander's hips, left hand rests on the own thigh
		"elbow_l": Vector3(bx - 0.22, 0.72, 0.08) + o,
		"wrist_l": Vector3(bx - 0.16, 0.48, 0.20) + o,
		"hand_l": Vector3(bx - 0.11, 0.33, 0.14) + o,
		"elbow_r": Vector3(bx + 0.30, 0.86, 0.26) + o,
		"wrist_r": Vector3(bx + 0.46, 0.87, 0.21) + o,
		"hand_r": Vector3(bx + 0.52, 0.85, 0.17) + o,
		"r_arm": [0.055 * plump * flesh, 0.044 * flesh, 0.035 * flesh],
		"r_hand": 0.035 * flesh,
		"s_hand_l": 0.19,
		"s_hand_r": 0.19,
	}


## One figurine, ASSEMBLED - spline chains of overlapping capsules, so the limbs
## bend without elbows. 41 meshes.
static func _figure(root: Node3D, mat: Material, j: Dictionary, hosts: Array, tips: Array) -> void:
	var rs: Array = j["r_spine"]
	var rl: Array = j["r_leg"]
	var ra: Array = j["r_arm"]
	var neck: Vector3 = j["neck"]
	var head_c: Vector3 = j["head_c"]
	var sh_l: Vector3 = j["sh_l"]
	var sh_r: Vector3 = j["sh_r"]
	var r_sh: float = j["r_sh"]
	var head_r: float = j["head_r"]
	var head_h: float = j["head_h"]
	var head_rot: Basis = j["head_rot"]
	_tube(root, mat, [j["pelvis"], j["waist"], j["chest"], neck], rs, 8, hosts)
	_capsule_between(root, mat, sh_l, sh_r, r_sh)
	hosts.append({"a": sh_l, "b": sh_r, "r": r_sh})
	_capsule_between(root, mat, neck, head_c, float(j["r_neck"]))
	_ellipsoid(root, mat, head_c, head_r, head_h, head_rot)
	tips.append({"p": head_c + Vector3(0.0, head_r * head_h, 0.0), "n": (head_c - neck).normalized(), "s": float(j["s_head"])})
	var ankle_l: Vector3 = j["ankle_l"]
	var ankle_r: Vector3 = j["ankle_r"]
	var fr: float = j["r_foot"]
	var dir_l: Vector3 = j["foot_l"]
	var dir_r: Vector3 = j["foot_r"]
	_tube(root, mat, [j["hip_l"], j["knee_l"], ankle_l], rl, 7, hosts)
	_tube(root, mat, [j["hip_r"], j["knee_r"], ankle_r], rl, 7, hosts)
	_foot(root, mat, ankle_l, dir_l, fr)
	_foot(root, mat, ankle_r, dir_r, fr)
	var r_hand: float = j["r_hand"]
	var wrist_l: Vector3 = j["wrist_l"]
	var hand_l: Vector3 = j["hand_l"]
	_tube(root, mat, [sh_l, j["elbow_l"], wrist_l], ra, 6, hosts)
	_capsule_between(root, mat, wrist_l, hand_l, r_hand)
	tips.append({"p": hand_l, "n": (hand_l - wrist_l).normalized(), "s": float(j["s_hand_l"])})
	var wrist_r: Vector3 = j["wrist_r"]
	var hand_r: Vector3 = j["hand_r"]
	_tube(root, mat, [sh_r, j["elbow_r"], wrist_r], ra, 6, hosts)
	_capsule_between(root, mat, wrist_r, hand_r, r_hand)
	tips.append({"p": hand_r, "n": (hand_r - wrist_r).normalized(), "s": float(j["s_hand_r"])})


# ------------------------------------------------- fused: the body as a field

## The same joints, coarse: ONE tapered capsule per bone instead of a chain of
## seven, because the field is sampled on a grid and every part costs the whole
## grid again. 16 parts a body keeps the march honest. The bend the chain draws
## point by point, the smooth union draws as a fillet at the joint.
static func _bones(j: Dictionary, swell: float) -> Array:
	var rs: Array = j["r_spine"]
	var rl: Array = j["r_leg"]
	var ra: Array = j["r_arm"]
	var head_c: Vector3 = j["head_c"]
	var head_r0: float = j["head_r"]
	var head_h: float = j["head_h"]
	var head_r: float = head_r0 * swell
	var lift: float = maxf(0.0, head_r0 * head_h - head_r0)
	var fr: float = float(j["r_foot"]) * swell
	var r_hand: float = float(j["r_hand"]) * swell
	var f_l: Dictionary = _foot_seg(j["ankle_l"], j["foot_l"], fr)
	var f_r: Dictionary = _foot_seg(j["ankle_r"], j["foot_r"], fr)
	var out: Array = []
	out.append(_bone(j["pelvis"], j["waist"], float(rs[0]) * swell, float(rs[1]) * swell))
	out.append(_bone(j["waist"], j["chest"], float(rs[1]) * swell, float(rs[2]) * swell))
	out.append(_bone(j["chest"], j["neck"], float(rs[2]) * swell, float(rs[3]) * swell))
	out.append(_bone(j["sh_l"], j["sh_r"], float(j["r_sh"]) * swell, float(j["r_sh"]) * swell))
	out.append(_bone(j["neck"], head_c, float(j["r_neck"]) * swell, head_r * 0.75))
	# the ellipsoid head as a short capsule of its own height and radius
	out.append(_bone(head_c - Vector3(0.0, lift, 0.0), head_c + Vector3(0.0, lift, 0.0), head_r, head_r))
	out.append(_bone(j["hip_l"], j["knee_l"], float(rl[0]) * swell, float(rl[1]) * swell))
	out.append(_bone(j["knee_l"], j["ankle_l"], float(rl[1]) * swell, float(rl[2]) * swell))
	out.append(_bone(j["hip_r"], j["knee_r"], float(rl[0]) * swell, float(rl[1]) * swell))
	out.append(_bone(j["knee_r"], j["ankle_r"], float(rl[1]) * swell, float(rl[2]) * swell))
	out.append(_bone(f_l["a"], f_l["b"], fr, fr))
	out.append(_bone(f_r["a"], f_r["b"], fr, fr))
	out.append(_bone(j["sh_l"], j["elbow_l"], float(ra[0]) * swell, float(ra[1]) * swell))
	out.append(_bone(j["elbow_l"], j["hand_l"], float(ra[1]) * swell, r_hand))
	out.append(_bone(j["sh_r"], j["elbow_r"], float(ra[0]) * swell, float(ra[1]) * swell))
	out.append(_bone(j["elbow_r"], j["hand_r"], float(ra[1]) * swell, r_hand))
	return out


static func _bone(a: Vector3, b: Vector3, r: float, r2: float) -> Dictionary:
	return {"a": a, "b": b, "r": r, "r2": r2}


## FUSED - two figurines that went into the saggar touching. Every bone becomes
## one tapered capsule in an SDF, two bridges join the pair where they lean, and
## the smooth union does the rest: the arms grow OUT of the torso, the two spines
## run together, the gap under the draped arm stays a hole because the field
## never crossed zero there. Nothing is cut; nothing needs to be.
##
## Returns false if the mesher gives back nothing, and appends NOTHING in that
## case, so build() can assemble the pair from primitives on the same joints.
static func _grow(root: Node3D, ja: Dictionary, jb: Dictionary, mat: Material,
		hosts_a: Array, hosts_b: Array, tips_a: Array, tips_b: Array) -> bool:
	var swell: float = 1.05
	var bones_a: Array = _bones(ja, swell)
	var bones_b: Array = _bones(jb, swell)
	var parts: Array = []
	_field_parts(bones_a, parts)
	_field_parts(bones_b, parts)
	# where the two touch, the glaze ran and the bodies became one
	var rs_a: Array = ja["r_spine"]
	var a_hand_l: Vector3 = ja["hand_l"]
	var b_sh_l: Vector3 = jb["sh_l"]
	var b_hand_r: Vector3 = jb["hand_r"]
	var a_pelvis: Vector3 = ja["pelvis"]
	parts.append(Iso.capsule(a_hand_l, b_sh_l, float(ja["r_hand"]) * 1.15, float(jb["r_sh"]) * 0.85))
	parts.append(Iso.capsule(b_hand_r, a_pelvis, float(jb["r_hand"]) * 1.15, float(rs_a[0]) * 0.70))
	# 34 parts, a grid of about 20k corners. CHECK the result: the mesher is new.
	var mesh: ArrayMesh = Iso.mesh_of(parts, 0.052, 0.10, 0.06)
	if mesh == null:
		return false
	_mesh(root, mesh, mat, Transform3D.IDENTITY)
	_bone_hosts(bones_a, hosts_a)
	_bone_hosts(bones_b, hosts_b)
	_joint_tips(ja, tips_a)
	_joint_tips(jb, tips_b)
	return true


static func _field_parts(bones: Array, out_parts: Array) -> void:
	for b_v in bones:
		var b: Dictionary = b_v
		var a: Vector3 = b["a"]
		var c: Vector3 = b["b"]
		out_parts.append(Iso.capsule(a, c, float(b["r"]), float(b["r2"])))


## The ornament still needs somewhere to sit, and the bones are where the body
## is. The radius is carried a little proud of the bone, because the union's
## fillet swells the marched surface past the capsule it was built from.
static func _bone_hosts(bones: Array, hosts: Array) -> void:
	for b_v in bones:
		var b: Dictionary = b_v
		var rr: float = (float(b["r"]) + float(b["r2"])) * 0.5 + 0.028
		hosts.append({"a": b["a"], "b": b["b"], "r": rr})


static func _joint_tips(j: Dictionary, tips: Array) -> void:
	var neck: Vector3 = j["neck"]
	var head_c: Vector3 = j["head_c"]
	var head_r: float = j["head_r"]
	var head_h: float = j["head_h"]
	tips.append({"p": head_c + Vector3(0.0, head_r * head_h, 0.0), "n": (head_c - neck).normalized(), "s": float(j["s_head"])})
	var wrist_l: Vector3 = j["wrist_l"]
	var hand_l: Vector3 = j["hand_l"]
	tips.append({"p": hand_l, "n": (hand_l - wrist_l).normalized(), "s": float(j["s_hand_l"])})
	var wrist_r: Vector3 = j["wrist_r"]
	var hand_r: Vector3 = j["hand_r"]
	tips.append({"p": hand_r, "n": (hand_r - wrist_r).normalized(), "s": float(j["s_hand_r"])})


## THE SAGGAR - what a fused pair comes out standing in. The grown body is ONE
## mesh, so the value carries its trimmings as primitives: the pool of glaze that
## ran off it (both skins, the kneeler's surviving only here), matte fireclay
## stilts - the one unglazed thing in the piece - drips caught setting, beaded at
## the tip, and pearls cooled where they landed. 51 pieces.
static func _saggar(root: Node3D, mat_a: Material, mat_b: Material, relief: Material, hosts_a: Array, hosts_b: Array, rng: RandomNumberGenerator) -> void:
	var box: AABB = _union_aabb(root)
	var px: float = box.position.x + box.size.x * 0.5
	var pz: float = box.position.z + box.size.z * 0.5
	for k: int in range(9):
		var ang: float = rng.randf_range(0.0, TAU)
		var rr: float = rng.randf_range(0.0, box.size.x * 0.30)
		var pm: Material = mat_a if k % 2 == 0 else mat_b
		var disc: Vector3 = Vector3(px + cos(ang) * rr, 0.030, pz + sin(ang) * rr * 0.8)
		_ellipsoid(root, pm, disc, rng.randf_range(0.12, 0.22), 0.18, Basis.IDENTITY)
	var clay: StandardMaterial3D = _bisque(0.70)
	for _k2: int in range(6):
		var a2: float = rng.randf_range(0.0, TAU)
		var r2: float = rng.randf_range(box.size.x * 0.18, box.size.x * 0.42)
		var foot: Vector3 = Vector3(px + cos(a2) * r2, 0.012, pz + sin(a2) * r2 * 0.8)
		var top: Vector3 = foot + Vector3(rng.randf_range(-0.03, 0.03), rng.randf_range(0.10, 0.26), rng.randf_range(-0.03, 0.03))
		_capsule_between(root, clay, foot, top, 0.013)
	var wet: Array = []
	_drippable(hosts_a, wet)
	_drippable(hosts_b, wet)
	for _k3: int in range(14):
		if wet.is_empty():
			break
		var h: Dictionary = wet[rng.randi_range(0, wet.size() - 1)]
		_drip(root, relief, h, rng)
	for _k4: int in range(8):
		var a4: float = rng.randf_range(0.0, TAU)
		var r4: float = rng.randf_range(0.0, box.size.x * 0.34)
		var pearl: Vector3 = Vector3(px + cos(a4) * r4, rng.randf_range(0.035, 0.055), pz + sin(a4) * r4 * 0.8)
		_dot(root, mat_b, pearl, rng.randf_range(0.012, 0.022))


static func _drippable(hosts: Array, out_list: Array) -> void:
	for h_v in hosts:
		var h: Dictionary = h_v
		if float(h["r"]) >= 0.030:
			out_list.append(h)


## One drip: off the glaze, out along the normal, then straight down with a
## wander, thinning as it runs, and a bead where it stopped.
static func _drip(root: Node3D, mat: Material, h: Dictionary, rng: RandomNumberGenerator) -> void:
	var a: Vector3 = h["a"]
	var b: Vector3 = h["b"]
	var anchor: Vector3 = _surface_point(h, rng, 0.003)
	var nrm: Vector3 = _outward(anchor, a, b)
	var run: float = rng.randf_range(0.10, 0.26)
	var wob: float = rng.randf_range(0.010, 0.035)
	var ph: float = rng.randf_range(0.0, TAU)
	var steps: int = 10
	var pts: Array = []
	var radii: Array = []
	for k: int in range(steps + 1):
		var f: float = float(k) / float(steps)
		var p: Vector3 = anchor + nrm * (0.02 * (1.0 - f)) + Vector3(sin(ph + f * 3.1) * wob * f, -run * f, cos(ph + f * 2.3) * wob * f)
		pts.append(p)
		radii.append(lerpf(0.011, 0.0035, f))
	_mesh(root, _sweep_mesh(pts, radii, 6), mat, Transform3D.IDENTITY)
	var bead: Vector3 = pts[steps]
	_dot(root, mat, bead, 0.013)


# ------------------------------------------------------------ raised filigree

static func _relief(root: Node3D, mat: Material, hosts: Array, rng: RandomNumberGenerator) -> void:
	var big: Array = []
	for h: Dictionary in hosts:
		var r: float = h["r"]
		if r >= 0.055:
			big.append(h)
	if big.is_empty():
		return
	for _k: int in range(6):
		var hs: Dictionary = big[rng.randi_range(0, big.size() - 1)]
		_relief_stroke(root, mat, hs, rng, rng.randf_range(0.035, 0.06), rng.randf_range(1.2, 1.7), 24, 0.008, 0.005, 0.76, true)
	for _k: int in range(5):
		var hc: Dictionary = big[rng.randi_range(0, big.size() - 1)]
		_relief_stroke(root, mat, hc, rng, rng.randf_range(0.03, 0.045), rng.randf_range(0.28, 0.45), 8, 0.009, 0.002, 0.2, false)
	for _k: int in range(8):
		var hd: Dictionary = big[rng.randi_range(0, big.size() - 1)]
		_dot(root, mat, _surface_point(hd, rng, 0.002), rng.randf_range(0.007, 0.011))


## One white stroke standing proud of a host capsule: a volute (turns > 1,
## strong shrink) or a comma flick (a short arc, tapering to nothing).
static func _relief_stroke(root: Node3D, mat: Material, h: Dictionary, rng: RandomNumberGenerator, size_m: float, turns: float, steps: int, w0: float, w1: float, shrink: float, bead: bool) -> void:
	var a: Vector3 = h["a"]
	var b: Vector3 = h["b"]
	var r: float = h["r"]
	var anchor: Vector3 = _surface_point(h, rng, 0.0)
	var nrm: Vector3 = _outward(anchor, a, b)
	var tu: Vector3 = nrm.cross(Vector3.UP)
	if tu.length_squared() < 1.0e-4:
		tu = nrm.cross(Vector3.RIGHT)
	tu = tu.normalized()
	var tv: Vector3 = nrm.cross(tu).normalized()
	var spin: float = rng.randf_range(0.0, TAU)
	var flip: float = 1.0 if rng.randf() < 0.5 else -1.0
	var sz: float = minf(size_m, r * 0.95)
	var pts: Array = []
	var radii: Array = []
	for k: int in range(steps + 1):
		var f: float = float(k) / float(steps)
		var th: float = spin + flip * f * turns * TAU
		var rad: float = sz * (1.0 - shrink * f)
		var p: Vector3 = anchor + (tu * cos(th) + tv * sin(th)) * rad
		pts.append(_project_to_capsule(p, a, b, r + 0.004))
		radii.append(lerpf(w0, w1, f))
	var swept: ArrayMesh = _sweep_mesh(pts, radii, 8)
	_mesh(root, swept, mat, Transform3D.IDENTITY)
	if bead:
		var eye: Vector3 = pts[steps]
		_dot(root, mat, eye, w0 * 1.15)


## A random point on the surface of a host capsule (a == b makes it a sphere).
static func _surface_point(h: Dictionary, rng: RandomNumberGenerator, lift: float) -> Vector3:
	var a: Vector3 = h["a"]
	var b: Vector3 = h["b"]
	var r: float = h["r"]
	var axis: Vector3 = b - a
	var nrm: Vector3
	var q: Vector3
	if axis.length_squared() < 1.0e-8:
		var th: float = rng.randf_range(0.0, TAU)
		var z: float = rng.randf_range(-0.7, 0.9)
		var s: float = sqrt(maxf(0.0, 1.0 - z * z))
		nrm = Vector3(s * cos(th), z, s * sin(th))
		q = a
	else:
		var t: float = rng.randf_range(0.15, 0.85)
		q = a + axis * t
		var an: Vector3 = axis.normalized()
		var u: Vector3 = an.cross(Vector3.RIGHT)
		if u.length_squared() < 1.0e-4:
			u = an.cross(Vector3.FORWARD)
		u = u.normalized()
		var v: Vector3 = an.cross(u).normalized()
		var phi: float = rng.randf_range(0.0, TAU)
		nrm = u * cos(phi) + v * sin(phi)
	return q + nrm * (r + lift)


static func _outward(p: Vector3, a: Vector3, b: Vector3) -> Vector3:
	var axis: Vector3 = b - a
	var q: Vector3 = a
	var l2: float = axis.length_squared()
	if l2 > 1.0e-8:
		var t: float = clampf((p - a).dot(axis) / l2, 0.0, 1.0)
		q = a + axis * t
	var n: Vector3 = p - q
	if n.length_squared() < 1.0e-8:
		return Vector3.UP
	return n.normalized()


static func _project_to_capsule(p: Vector3, a: Vector3, b: Vector3, rr: float) -> Vector3:
	var axis: Vector3 = b - a
	var q: Vector3 = a
	var l2: float = axis.length_squared()
	if l2 > 1.0e-8:
		var t: float = clampf((p - a).dot(axis) / l2, 0.0, 1.0)
		q = a + axis * t
	return q + _outward(p, a, b) * rr


## A tube swept along a polyline with a radius per point, closed with fans.
## Clockwise winding seen from outside, which is Godot's front face.
static func _sweep_mesh(pts: Array, radii: Array, ring_n: int) -> ArrayMesh:
	var n: int = pts.size()
	var rings: Array = []
	var ref_n: Vector3 = Vector3.UP
	for i: int in range(n):
		var p: Vector3 = pts[i]
		var tng: Vector3
		if i == 0:
			var p_next: Vector3 = pts[1]
			tng = p_next - p
		elif i == n - 1:
			var p_prev: Vector3 = pts[n - 2]
			tng = p - p_prev
		else:
			var pa: Vector3 = pts[i + 1]
			var pb: Vector3 = pts[i - 1]
			tng = pa - pb
		tng = tng.normalized()
		var nn: Vector3 = ref_n - tng * ref_n.dot(tng)
		if nn.length_squared() < 1.0e-6:
			nn = tng.cross(Vector3.RIGHT)
			if nn.length_squared() < 1.0e-6:
				nn = tng.cross(Vector3.FORWARD)
		nn = nn.normalized()
		ref_n = nn
		var bb: Vector3 = tng.cross(nn).normalized()
		var rad: float = radii[i]
		var ring := PackedVector3Array()
		for j: int in range(ring_n):
			var th: float = TAU * float(j) / float(ring_n)
			ring.append(p + (nn * cos(th) + bb * sin(th)) * rad)
		rings.append(ring)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0)
	for i: int in range(n - 1):
		var r0: PackedVector3Array = rings[i]
		var r1: PackedVector3Array = rings[i + 1]
		for j: int in range(ring_n):
			var j1: int = (j + 1) % ring_n
			st.add_vertex(r0[j])
			st.add_vertex(r1[j])
			st.add_vertex(r1[j1])
			st.add_vertex(r0[j])
			st.add_vertex(r1[j1])
			st.add_vertex(r0[j1])
	var c0: Vector3 = pts[0]
	var ring0: PackedVector3Array = rings[0]
	var c1: Vector3 = pts[n - 1]
	var ring1: PackedVector3Array = rings[n - 1]
	for j: int in range(ring_n):
		var j1: int = (j + 1) % ring_n
		st.add_vertex(c0)
		st.add_vertex(ring0[j])
		st.add_vertex(ring0[j1])
		st.add_vertex(c1)
		st.add_vertex(ring1[j1])
		st.add_vertex(ring1[j])
	st.generate_normals()
	return st.commit()


# ------------------------------------------------------------- limb geometry

## Catmull-Rom through pts, sampled into segs capsules; radii interpolate
## point to point. Every segment is recorded in hosts for the relief.
static func _tube(root: Node3D, mat: Material, pts: Array, radii: Array, segs: int, hosts: Array) -> void:
	var span: float = float(pts.size() - 1)
	var prev: Vector3 = _spline(pts, 0.0)
	for k: int in range(1, segs + 1):
		var u: float = span * float(k) / float(segs)
		var um: float = span * (float(k) - 0.5) / float(segs)
		var cur: Vector3 = _spline(pts, u)
		var r: float = _radius_at(radii, um)
		_capsule_between(root, mat, prev, cur, r)
		hosts.append({"a": prev, "b": cur, "r": r})
		prev = cur


static func _spline(pts: Array, u: float) -> Vector3:
	var n: int = pts.size()
	var i: int = clampi(int(floor(u)), 0, n - 2)
	var t: float = clampf(u - float(i), 0.0, 1.0)
	var p0: Vector3 = pts[maxi(i - 1, 0)]
	var p1: Vector3 = pts[i]
	var p2: Vector3 = pts[i + 1]
	var p3: Vector3 = pts[mini(i + 2, n - 1)]
	var t2: float = t * t
	var t3: float = t2 * t
	return (p1 * 2.0 + (p2 - p0) * t + (p0 * 2.0 - p1 * 5.0 + p2 * 4.0 - p3) * t2 + (p1 * 3.0 - p0 - p2 * 3.0 + p3) * t3) * 0.5


static func _radius_at(radii: Array, u: float) -> float:
	var n: int = radii.size()
	var i: int = clampi(int(floor(u)), 0, n - 2)
	var t: float = clampf(u - float(i), 0.0, 1.0)
	var r0: float = radii[i]
	var r1: float = radii[i + 1]
	return lerpf(r0, r1, t)


static func _capsule_between(root: Node3D, mat: Material, a: Vector3, b: Vector3, r: float) -> MeshInstance3D:
	var d: Vector3 = b - a
	var cap := CapsuleMesh.new()
	cap.radius = r
	cap.height = d.length() + 2.0 * r
	cap.radial_segments = 24
	cap.rings = 6
	return _mesh(root, cap, mat, Transform3D(_basis_y_to(d), (a + b) * 0.5))


static func _ellipsoid(root: Node3D, mat: Material, c: Vector3, r: float, h_scale: float, rot: Basis) -> MeshInstance3D:
	var sph := SphereMesh.new()
	sph.radius = r
	sph.height = 2.0 * r * h_scale
	sph.radial_segments = 32
	sph.rings = 16
	return _mesh(root, sph, mat, Transform3D(rot, c))


static func _dot(root: Node3D, mat: Material, c: Vector3, r: float) -> MeshInstance3D:
	var sph := SphereMesh.new()
	sph.radius = r
	sph.height = 2.0 * r
	sph.radial_segments = 12
	sph.rings = 6
	return _mesh(root, sph, mat, Transform3D(Basis.IDENTITY, c))


## A foot: a capsule lying on the floor, from just behind the ankle forward
## along dir (the kneeler's point backward). The segment is computed apart from
## the mesh, so the field builds the same foot the primitives do.
static func _foot(root: Node3D, mat: Material, ankle: Vector3, dir: Vector3, fr: float) -> void:
	var seg: Dictionary = _foot_seg(ankle, dir, fr)
	var a: Vector3 = seg["a"]
	var b: Vector3 = seg["b"]
	_capsule_between(root, mat, a, b, fr)


static func _foot_seg(ankle: Vector3, dir: Vector3, fr: float) -> Dictionary:
	var d: Vector3 = Vector3(dir.x, 0.0, dir.z).normalized()
	var a: Vector3 = Vector3(ankle.x, fr + 0.001, ankle.z) - d * 0.03
	return {"a": a, "b": a + d * 0.15}


static func _basis_y_to(d: Vector3) -> Basis:
	var dn: Vector3 = d.normalized()
	if dn.length_squared() < 0.5:
		return Basis.IDENTITY
	var dotv: float = clampf(Vector3.UP.dot(dn), -1.0, 1.0)
	var axis: Vector3 = Vector3.UP.cross(dn)
	if axis.length_squared() < 1.0e-8:
		if dotv > 0.0:
			return Basis.IDENTITY
		return Basis(Vector3.RIGHT, PI)
	return Basis(axis.normalized(), acos(dotv))


static func _mesh(root: Node3D, mesh: Mesh, mat: Material, xf: Transform3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.transform = xf
	root.add_child(mi)
	return mi


# ------------------------------------------------------------------- skins

## The palette, dealt three ways: LOUD as it comes, PALE toward cream for the
## ground a pattern is painted on, DEEP toward ink for the line that draws it.
## The reference's blue-and-white, pale green and mauve are what these replace.
static func _loud(rng: RandomNumberGenerator) -> Color:
	return Gloss.queer_colour(rng)


static func _pale(rng: RandomNumberGenerator) -> Color:
	var c: Color = Gloss.queer_colour(rng)
	return c.lerp(Color(0.98, 0.96, 0.93), 0.74)


static func _deep(rng: RandomNumberGenerator) -> Color:
	var c: Color = Gloss.queer_colour(rng)
	return c.lerp(Color(0.05, 0.04, 0.09), 0.42)


static func _skin(kind: String, finish: String, rng: RandomNumberGenerator) -> StandardMaterial3D:
	match kind:
		"waves":
			return _glaze(finish, _tex_waves(rng, _deep(rng), _pale(rng)), Color.WHITE, 5.0, rng)
		"filigree":
			return _glaze(finish, _tex_filigree(rng, Color(0.98, 0.97, 0.94), _loud(rng)), Color.WHITE, 3.5, rng)
		"scales":
			return _glaze(finish, _tex_scales(rng, _deep(rng), _loud(rng), _pale(rng)), Color.WHITE, 5.0, rng)
		"flow":
			return _glaze(finish, _tex_flow(rng, _loud(rng), Color(0.07, 0.06, 0.10), _pale(rng)), Color.WHITE, 3.0, rng)
	# plain: no pattern, so the finish shows its own sweep - the loudest skin
	return _glaze(finish, null, _loud(rng), 1.0, rng)


## Porcelain glaze, now dealt from DreamSkin. A pattern texture is tiled in WORLD
## space by triplanar projection so it runs unbroken across the capsule seams of
## a limb - and past the seams the marched body does not have.
##
## Two things the finish must give up to carry a pattern: the mirror (metallic is
## capped, or the pattern photographs black in a bare hall) and its own sweep
## texture, which the pattern replaces. What it keeps is the emission - the
## pattern is handed straight to it, so the stripes and the scales GLOW rather
## than flattening under ACES. Porcelain keeps its glaze coat either way.
static func _glaze(finish: String, tex: ImageTexture, tint: Color, tiles: float, rng: RandomNumberGenerator) -> StandardMaterial3D:
	var m: StandardMaterial3D = Gloss.skin(finish, tint, rng)
	if tex != null:
		m.albedo_color = Color.WHITE
		m.albedo_texture = tex
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_triplanar_sharpness = 6.0
		m.uv1_scale = Vector3(tiles, tiles, tiles)
		var met: float = minf(m.metallic, 0.5)
		m.metallic = met
		if m.emission_enabled:
			# the sweep this replaces is a dark band and is meant to burn; a
			# porcelain pattern is mostly pale ground, so the glow is pulled back
			# to a lift rather than a white-out
			var glow: float = minf(m.emission_energy_multiplier, 0.35)
			m.emission_texture = tex
			m.emission = Color.WHITE
			m.emission_energy_multiplier = glow
	if finish != "matte":
		var coat: float = maxf(m.clearcoat, 0.9)
		var coat_r: float = minf(m.clearcoat_roughness, 0.06)
		m.clearcoat_enabled = true
		m.clearcoat = coat
		m.clearcoat_roughness = coat_r
	m.metallic_specular = 0.7
	return m


## Blue-and-white: horizontal stripes wobbled by three sines, tileable.
static func _tex_waves(rng: RandomNumberGenerator, ink: Color, paper: Color) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	var ph1: float = rng.randf_range(0.0, TAU)
	var ph2: float = rng.randf_range(0.0, TAU)
	var ph3: float = rng.randf_range(0.0, TAU)
	var period: float = 16.0
	var half: float = 0.5 + rng.randf_range(-0.06, 0.06)
	for y: int in range(TEX):
		for x: int in range(TEX):
			var fx: float = float(x) / float(TEX)
			var fy: float = float(y) / float(TEX)
			var wob: float = 3.0 * sin(TAU * 4.0 * fx + ph1) + 1.5 * sin(TAU * 9.0 * fx + TAU * 2.0 * fy + ph2) + 1.0 * sin(TAU * 17.0 * fx + TAU * 3.0 * fy + ph3)
			var v: float = fposmod(float(y) + wob, period) / period
			var d: float = (absf(v - half * 0.5) - half * 0.5) * period
			var mix: float = clampf(d / 1.2 + 0.5, 0.0, 1.0)
			img.set_pixel(x, y, ink.lerp(paper, mix))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## Pale green with white filigree: volutes, comma flicks and pearls.
static func _tex_filigree(rng: RandomNumberGenerator, ink: Color, paper: Color) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	img.fill(paper)
	for _k: int in range(9):
		var cx: float = rng.randf_range(0.0, float(TEX))
		var cy: float = rng.randf_range(0.0, float(TEX))
		var sz: float = rng.randf_range(11.0, 22.0)
		var turns: float = rng.randf_range(1.3, 2.0)
		var spin: float = rng.randf_range(0.0, TAU)
		var flip: float = 1.0 if rng.randf() < 0.5 else -1.0
		var steps: int = int(sz * turns * 3.0)
		for i: int in range(steps + 1):
			var f: float = float(i) / float(steps)
			var th: float = spin + flip * f * turns * TAU
			var rad: float = sz * (1.0 - 0.8 * f)
			var w: float = lerpf(2.6, 1.1, f)
			_stamp(img, cx + cos(th) * rad, cy + sin(th) * rad, w, ink)
	for _k: int in range(14):
		var cx: float = rng.randf_range(0.0, float(TEX))
		var cy: float = rng.randf_range(0.0, float(TEX))
		var rad: float = rng.randf_range(6.0, 13.0)
		var spin: float = rng.randf_range(0.0, TAU)
		var sweep: float = rng.randf_range(0.25, 0.45) * TAU
		var steps: int = int(rad * 2.5)
		for i: int in range(steps + 1):
			var f: float = float(i) / float(steps)
			var th: float = spin + f * sweep
			var w: float = lerpf(2.8, 0.6, f)
			_stamp(img, cx + cos(th) * rad, cy + sin(th) * rad, w, ink)
	for _k: int in range(26):
		_stamp(img, rng.randf_range(0.0, float(TEX)), rng.randf_range(0.0, float(TEX)), rng.randf_range(1.2, 2.6), ink)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## Mauve scale lattice: fish-scale tiling, concentric bands, dark rim.
static func _tex_scales(rng: RandomNumberGenerator, ink: Color, mid: Color, paper: Color) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	var cell_w: float = 32.0
	var row_h: float = 16.0
	var rad: float = 17.6
	var band: float = rng.randf_range(4.2, 5.4)
	var rim: float = 1.5
	for y: int in range(TEX):
		for x: int in range(TEX):
			var col: Color = paper
			var row0: int = int(floor(float(y) / row_h))
			var done: bool = false
			for rr: int in range(row0 + 2, row0 - 3, -1):
				if done:
					break
				var dy: float = float(y) - float(rr) * row_h
				if absf(dy) > rad:
					continue
				var offx: float = 0.0 if posmod(rr, 2) == 0 else cell_w * 0.5
				var c0: int = int(floor((float(x) - offx) / cell_w))
				for cc: int in range(c0, c0 + 2):
					var dx: float = float(x) - ((float(cc) + 0.5) * cell_w + offx)
					var d: float = sqrt(dx * dx + dy * dy)
					if d <= rad:
						done = true
						var edge: float = rad - d
						if edge < rim:
							col = ink
						else:
							var q: float = fposmod(d, band) / band
							if q < 0.42:
								col = mid
							else:
								col = paper
						break
			img.set_pixel(x, y, col)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## Teal with black flowing lines: six lanes bent by two sines, a pale halo.
static func _tex_flow(rng: RandomNumberGenerator, base_col: Color, ink: Color, light: Color) -> ImageTexture:
	var img: Image = Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	var ph1: float = rng.randf_range(0.0, TAU)
	var ph2: float = rng.randf_range(0.0, TAU)
	var ph3: float = rng.randf_range(0.0, TAU)
	var period: float = float(TEX) / 6.0
	for y: int in range(TEX):
		for x: int in range(TEX):
			var fx: float = float(x) / float(TEX)
			var fy: float = float(y) / float(TEX)
			var f: float = float(x) + 26.0 * sin(TAU * 2.0 * fy + ph1) + 9.0 * sin(TAU * 5.0 * fy + TAU * fx + ph2)
			var v: float = fposmod(f, period)
			var thick: float = 2.2 + 1.4 * sin(TAU * 3.0 * fy + TAU * fx + ph3)
			var col: Color = base_col
			if v < thick:
				col = ink
			elif v < thick + 7.0:
				col = base_col.lerp(light, 0.55 * (1.0 - (v - thick) / 7.0))
			img.set_pixel(x, y, col)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## Unglazed ware: chalky, dry, no clearcoat, no pattern, no emission - the one
## matte surface in a family that is otherwise all shine. Worn by the biscuit
## kiln, where there is nothing left to glaze, and by the fireclay stilts the
## fused pair stands on. It is what the gloss is loud AGAINST.
static func _bisque(v: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(v, v * 0.985, v * 0.945)
	m.roughness = 0.88
	m.metallic = 0.0
	m.metallic_specular = 0.18
	return m


## A filled disc stamped into the image, wrapping at the edges (tileable).
static func _stamp(img: Image, cx: float, cy: float, rad: float, col: Color) -> void:
	var n: int = img.get_width()
	var ir: int = int(ceil(rad))
	var xi: int = int(round(cx))
	var yi: int = int(round(cy))
	for dy: int in range(-ir, ir + 1):
		for dx: int in range(-ir, ir + 1):
			var dd: float = sqrt(float(dx * dx + dy * dy))
			if dd <= rad:
				img.set_pixel(posmod(xi + dx, n), posmod(yi + dy, n), col)


# ------------------------------------------------------ ornament: the growths

## The fattest segments of a body, found by proportion, so the filter still
## works when the kiln has taken the flesh off the armature.
static func _big_hosts(hosts: Array, out_list: Array) -> void:
	var rmax: float = 0.0
	for h: Dictionary in hosts:
		var r: float = h["r"]
		rmax = maxf(rmax, r)
	if rmax <= 0.0:
		return
	var cut: float = rmax * 0.55
	for h2: Dictionary in hosts:
		var r2: float = h2["r"]
		if r2 >= cut:
			out_list.append(h2)


## SHELLS - rocaille means rockwork and shellwork, so the shells come out of
## the bodies: fluted scallop fans hinged on the glaze, cupping as they flare.
static func _shells(root: Node3D, mat: Material, hosts_a: Array, hosts_b: Array, rng: RandomNumberGenerator) -> void:
	var big: Array = []
	_big_hosts(hosts_a, big)
	_big_hosts(hosts_b, big)
	if big.is_empty():
		return
	for _k: int in range(10):
		var h: Dictionary = big[rng.randi_range(0, big.size() - 1)]
		_shell(root, mat, h, rng)


static func _shell(root: Node3D, mat: Material, h: Dictionary, rng: RandomNumberGenerator) -> void:
	var a: Vector3 = h["a"]
	var b: Vector3 = h["b"]
	var hinge: Vector3 = _surface_point(h, rng, 0.004)
	var nrm: Vector3 = _outward(hinge, a, b)
	var tu: Vector3 = nrm.cross(Vector3.UP)
	if tu.length_squared() < 1.0e-4:
		tu = nrm.cross(Vector3.RIGHT)
	tu = tu.normalized()
	var tv: Vector3 = nrm.cross(tu).normalized()
	var rad: float = rng.randf_range(0.11, 0.22)
	var flutes: float = float(rng.randi_range(6, 10))
	var half: float = rng.randf_range(0.55, 0.85)
	var base_a: float = rng.randf_range(0.0, TAU)
	var flare: float = rng.randf_range(0.35, 0.72)
	var cols: int = 26
	var rows: int = 7
	var grid: Array = []
	for i: int in range(rows + 1):
		var u: float = lerpf(0.10, 1.0, float(i) / float(rows))
		var ring := PackedVector3Array()
		for j: int in range(cols + 1):
			var fj: float = float(j) / float(cols)
			var th: float = base_a + (fj - 0.5) * 2.0 * half * PI
			var tangent: Vector3 = tu * cos(th) + tv * sin(th)
			var dirv: Vector3 = (tangent + nrm * flare).normalized()
			var rip: float = rad * 0.14 * u * sin(fj * flutes * TAU)
			var cup: float = rad * 0.34 * u * u
			ring.append(hinge + dirv * (rad * u) + nrm * (cup + rip))
		grid.append(ring)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0)
	for i: int in range(rows):
		var r0: PackedVector3Array = grid[i]
		var r1: PackedVector3Array = grid[i + 1]
		for j: int in range(cols):
			st.add_vertex(r0[j])
			st.add_vertex(r1[j])
			st.add_vertex(r1[j + 1])
			st.add_vertex(r0[j])
			st.add_vertex(r1[j + 1])
			st.add_vertex(r0[j + 1])
	st.generate_normals()
	_mesh(root, st.commit(), mat, Transform3D.IDENTITY)
	_dot(root, mat, hinge, rad * 0.085)


## BLOOMS - every hand and every crown ends in a porcelain flower: a stem, a
## ring of thin petals, a glazed heart the colour of the body it grew out of.
static func _blooms(root: Node3D, petal_mat: Material, core_a: Material, core_b: Material, tips_a: Array, tips_b: Array, rng: RandomNumberGenerator) -> void:
	for t: Dictionary in tips_a:
		_bloom(root, petal_mat, core_a, t, rng)
	for t2: Dictionary in tips_b:
		_bloom(root, petal_mat, core_b, t2, rng)


static func _bloom(root: Node3D, petal_mat: Material, core_mat: Material, tip: Dictionary, rng: RandomNumberGenerator) -> void:
	var p: Vector3 = tip["p"]
	var sz: float = tip["s"]
	var an: Vector3 = tip["n"]
	if an.length_squared() < 1.0e-6:
		an = Vector3.UP
	an = an.normalized()
	var head_p: Vector3 = p + an * (sz * 0.52)
	_capsule_between(root, core_mat, p, head_p, sz * 0.075)
	var u: Vector3 = an.cross(Vector3.UP)
	if u.length_squared() < 1.0e-4:
		u = an.cross(Vector3.RIGHT)
	u = u.normalized()
	var v: Vector3 = an.cross(u).normalized()
	var spin: float = rng.randf_range(0.0, TAU)
	var flare: float = rng.randf_range(0.62, 0.95)
	var petals: int = 5
	for k: int in range(petals):
		var th: float = spin + TAU * float(k) / float(petals)
		var radial: Vector3 = (u * cos(th) + v * sin(th)).normalized()
		var out_dir: Vector3 = (radial * flare + an * (1.0 - flare * 0.55)).normalized()
		var wide: Vector3 = an.cross(out_dir)
		if wide.length_squared() < 1.0e-6:
			wide = u
		wide = wide.normalized()
		var thin: Vector3 = out_dir.cross(wide).normalized()
		var pl: float = sz * rng.randf_range(0.52, 0.74)
		var pw: float = sz * 0.34
		var pt: float = sz * 0.075
		_petal(root, petal_mat, head_p + out_dir * (pl * 0.52), wide * pw, thin * pt, out_dir * pl)
	_dot(root, core_mat, head_p + an * (sz * 0.05), sz * 0.15)


## One petal: the unit sphere squashed into an oval by three column vectors, so
## the scaling happens in the petal's own frame and not in the world's.
static func _petal(root: Node3D, mat: Material, c: Vector3, x_ax: Vector3, y_ax: Vector3, z_ax: Vector3) -> void:
	var sph := SphereMesh.new()
	sph.radius = 0.5
	sph.height = 1.0
	sph.radial_segments = 14
	sph.rings = 8
	_mesh(root, sph, mat, Transform3D(Basis(x_ax, y_ax, z_ax), c))


## THREADS - the glaze lets go and unravels: coils spun off the bodies, sagging
## as they run, each one thinning away to nothing.
static func _threads(root: Node3D, mat: Material, hosts_a: Array, hosts_b: Array, rng: RandomNumberGenerator) -> void:
	var big: Array = []
	_big_hosts(hosts_a, big)
	_big_hosts(hosts_b, big)
	if big.is_empty():
		return
	for _k: int in range(17):
		var h: Dictionary = big[rng.randi_range(0, big.size() - 1)]
		_thread(root, mat, h, rng)


static func _thread(root: Node3D, mat: Material, h: Dictionary, rng: RandomNumberGenerator) -> void:
	var a: Vector3 = h["a"]
	var b: Vector3 = h["b"]
	var anchor: Vector3 = _surface_point(h, rng, 0.002)
	var nrm: Vector3 = _outward(anchor, a, b)
	var tu: Vector3 = nrm.cross(Vector3.UP)
	if tu.length_squared() < 1.0e-4:
		tu = nrm.cross(Vector3.RIGHT)
	tu = tu.normalized()
	var tv: Vector3 = nrm.cross(tu).normalized()
	var steps: int = 32
	var run: float = rng.randf_range(0.24, 0.44)
	var coils: float = rng.randf_range(1.8, 3.8)
	var coil_r: float = rng.randf_range(0.028, 0.075)
	var spin: float = rng.randf_range(0.0, TAU)
	var droop: float = rng.randf_range(0.20, 0.55)
	var pts: Array = []
	var radii: Array = []
	for k: int in range(steps + 1):
		var f: float = float(k) / float(steps)
		var th: float = spin + f * coils * TAU
		var rr: float = coil_r * (0.30 + 0.70 * f)
		var p: Vector3 = anchor + nrm * (run * f) + (tu * cos(th) + tv * sin(th)) * rr
		p.y -= droop * run * f * f
		pts.append(p)
		radii.append(lerpf(0.0072, 0.0022, f))
	_mesh(root, _sweep_mesh(pts, radii, 6), mat, Transform3D.IDENTITY)


## BISCUIT CAGE - hoops at the girth the flesh used to have, so the body that
## is gone is still measured out in the air around the armature.
static func _cage(root: Node3D, mat: Material, hosts: Array, flesh: float) -> void:
	var i: int = 0
	for h: Dictionary in hosts:
		i += 1
		if i % 2 != 0:
			continue
		var r: float = h["r"]
		if r < 0.010:
			continue
		var a: Vector3 = h["a"]
		var b: Vector3 = h["b"]
		_hoop(root, mat, (a + b) * 0.5, b - a, (r / maxf(flesh, 0.01)) * 1.06, 0.0055)


static func _hoop(root: Node3D, mat: Material, c: Vector3, axis: Vector3, rad: float, wire: float) -> void:
	var an: Vector3 = axis.normalized()
	if an.length_squared() < 0.5:
		an = Vector3.UP
	var u: Vector3 = an.cross(Vector3.UP)
	if u.length_squared() < 1.0e-4:
		u = an.cross(Vector3.RIGHT)
	u = u.normalized()
	var v: Vector3 = an.cross(u).normalized()
	var n: int = 16
	var pts: Array = []
	var radii: Array = []
	for k: int in range(n + 1):
		var th: float = TAU * float(k) / float(n)
		pts.append(c + (u * cos(th) + v * sin(th)) * rad)
		radii.append(wire)
	_mesh(root, _sweep_mesh(pts, radii, 6), mat, Transform3D.IDENTITY)


# -------------------------------------------------------- kiln: the accidents

## SLUMPED - too hot, too long. Everything low in the pair pancakes and spreads,
## the height compresses, and a poured puddle of glaze sets around the base.
static func _slump(root: Node3D, mat_a: Material, mat_b: Material, rng: RandomNumberGenerator) -> void:
	var box: AABB = _union_aabb(root)
	var top: float = maxf(box.position.y + box.size.y, 0.001)
	var cx: float = box.position.x + box.size.x * 0.5
	var cz: float = box.position.z + box.size.z * 0.5
	for ch: Node in root.get_children():
		var mi: MeshInstance3D = ch as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var c: Vector3 = mi.transform * mi.mesh.get_aabb().get_center()
		var t: float = clampf(c.y / top, 0.0, 1.0)
		var sag: float = 1.0 - t
		var spread: float = 1.0 + 0.66 * pow(sag, 1.5)
		var flat: float = lerpf(0.36, 1.0, pow(t, 0.85))
		var ny: float = top * pow(t, 1.55) * 0.84
		var c2 := Vector3(cx + (c.x - cx) * spread, ny, cz + (c.z - cz) * spread)
		_place(mi, Vector3(spread, flat, spread), c, c2)
	var box2: AABB = _union_aabb(root)
	var px: float = box2.position.x + box2.size.x * 0.5
	var pz: float = box2.position.z + box2.size.z * 0.5
	for k: int in range(10):
		var ang: float = rng.randf_range(0.0, TAU)
		var rr: float = rng.randf_range(0.0, box2.size.x * 0.36)
		var pm: Material = mat_a if k % 2 == 0 else mat_b
		var disc := Vector3(px + cos(ang) * rr, 0.034, pz + sin(ang) * rr * 0.75)
		_ellipsoid(root, pm, disc, rng.randf_range(0.16, 0.30), 0.20, Basis.IDENTITY)


## BURST - water left in the clay, and the pair went off in the kiln. Every
## piece keeps its place in the pose and hovers out along its own normal.
static func _burst(root: Node3D) -> void:
	var box: AABB = _union_aabb(root)
	var cx: float = box.position.x + box.size.x * 0.5
	var cz: float = box.position.z + box.size.z * 0.5
	var mid: float = box.position.y + box.size.y * 0.5
	var i: int = 0
	for ch: Node in root.get_children():
		var mi: MeshInstance3D = ch as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		i += 1
		var c: Vector3 = mi.transform * mi.mesh.get_aabb().get_center()
		var arm := Vector3(c.x - cx, 0.0, c.z - cz)
		var dl: float = arm.length()
		var dirv: Vector3
		if dl > 1.0e-4:
			dirv = arm / dl
		else:
			var sp: float = float(i) * 2.39996
			dirv = Vector3(cos(sp), 0.0, sin(sp))
		var push: float = 0.06 + 0.58 * dl
		var lift: float = (c.y - mid) * 0.42
		var c2: Vector3 = c + dirv * push + Vector3(0.0, lift, 0.0)
		_place(mi, Vector3(0.88, 0.88, 0.88), c, c2)


## Scale a mesh instance about its own centre c and carry that centre to c2.
## Works for the primitives AND for the swept meshes whose vertices are baked
## in world space, because the map is one affine per instance.
static func _place(mi: MeshInstance3D, s: Vector3, c: Vector3, c2: Vector3) -> void:
	var sb: Basis = Basis.from_scale(s)
	var tf: Transform3D = mi.transform
	mi.transform = Transform3D(sb * tf.basis, c2 + sb * (tf.origin - c))


# -------------------------------------------------------------------- settle

## Fit the case, centre on x and z, stand the lowest point on the floor.
static func _settle(root: Node3D) -> void:
	var box: AABB = _union_aabb(root)
	var kx: float = 1.20 / maxf(box.size.x, 0.001)
	var kz: float = 1.20 / maxf(box.size.z, 0.001)
	var ky: float = 1.68 / maxf(box.size.y, 0.001)
	var kfit: float = minf(1.0, minf(kx, minf(kz, ky)))
	if kfit < 1.0:
		for ch: Node in root.get_children():
			var mi: MeshInstance3D = ch as MeshInstance3D
			if mi == null:
				continue
			var tf: Transform3D = mi.transform
			mi.transform = Transform3D(tf.basis.scaled(Vector3(kfit, kfit, kfit)), tf.origin * kfit)
		box = _union_aabb(root)
	var centre: Vector3 = box.position + box.size * 0.5
	var shift := Vector3(-centre.x, -box.position.y, -centre.z)
	for ch2: Node in root.get_children():
		var mi2: MeshInstance3D = ch2 as MeshInstance3D
		if mi2 == null:
			continue
		mi2.transform = Transform3D(mi2.transform.basis, mi2.transform.origin + shift)


static func _union_aabb(root: Node3D) -> AABB:
	var box := AABB()
	var first: bool = true
	for ch: Node in root.get_children():
		var mi: MeshInstance3D = ch as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var wb: AABB = mi.transform * mi.mesh.get_aabb()
		if first:
			box = wb
			first = false
		else:
			box = box.merge(wb)
	return box
