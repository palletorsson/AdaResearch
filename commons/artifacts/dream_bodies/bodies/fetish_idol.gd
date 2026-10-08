extends RefCounted

## FETISH IDOL — the shader family (2026-09-03, Palle: "add crazy queer glossy
## fetish art — materials shaders").
##
## Every other dream body is primitives wearing StandardMaterial3D. This one is
## ONE marched surface wearing dream_gloss.gdshader, and it exists to put that
## shader where it can be measured: a body with no seams for the interference to
## break across, and no UV map for the harness to need.
##
## THE FIGURE IS A FIELD. Legs, hips, torso, arms and head are signed-distance
## capsules smooth-unioned at 0.075, so the thigh does not meet the hip, it
## BECOMES the hip. That is the whole reason to march a body rather than stack
## primitives: a fillet is not a joint you can see. The platform heels and the
## collar are part of the same field, which is why the boot swallows the ankle.
##
## AXES
##   surface — latex, patent, oilslick, holo, pvc, chrome. What the skin IS.
##             Two of these are impossible in a StandardMaterial3D: oilslick's
##             hue comes from film thickness over viewing cosine, and holo's
##             from a ruled grating, so both SLIDE across the body in one still.
##   harness — bare, strap, lace, buckle, cage, zip. Drawn in the fragment in
##             object space: leather with its own roughness and metal, and
##             hardware that reflects the shader's own procedural sky.
##
## THE TWO AXES ARE INDEPENDENT BY CONSTRUCTION, which is the point: the harness
## does not change the mesh and the surface does not change the straps, so the
## sweep's 36 frames are 6 skins x 6 bindings and the critic can read either.
##
## PREDICTED CLOSEST PAIR: bare-vs-zip at surface=chrome. The zip is a 9 cm tape
## down the front centre line, roughly 3.4% of the silhouette, and chrome is the
## one surface whose hardware colour nearly matches its own body — call it 2.2%
## of frame changed. Every other harness moves 8-20%.
##
## MEASURED: bare-vs-zip, right pair, 0.98% — the prediction was 2.2x HIGH, and
## the corpus's rule is that a prediction is a LOWER bound, so landing under it
## is the one result that means stop and look. The look says the render is fine:
## the zip is plainly there in surface=holo, black tape and teeth from hem to
## throat. The fault is in the arithmetic. 3.4% is the zip's share of the
## SILHOUETTE, and the silhouette is about 30% of the frame — so 3.4% of the
## body is ~1.0% of the picture, which is what was measured. A closest-pair
## number inherits its denominator, and this one was quoted against the wrong
## one. The four surfaces whose bare-vs-zip lands at 0.96-0.99% differ by less
## than the rounding, which is itself the check: the zip costs the same pixels
## whatever it is drawn over, exactly as an object-space overlay should.

const Iso := preload("res://commons/artifacts/dream_bodies/dream_iso.gd")
const Shaders := preload("res://commons/artifacts/dream_bodies/dream_shaders.gd")
const Gloss := preload("res://commons/artifacts/dream_bodies/dream_skin.gd")

const CELL: float = 0.034
const BLEND: float = 0.075


static func axes() -> Dictionary:
	return {
		"surface": ["latex", "patent", "oilslick", "holo", "pvc", "chrome"],
		"harness": ["bare", "strap", "lace", "buckle", "cage", "zip"],
	}


static func describe() -> String:
	return ("One marched body in latex, patent, oil slick, holographic foil, PVC or chrome, "
		+ "bound in a harness drawn in the fragment shader. The skin's colour is a function "
		+ "of the angle you stand at, not of a texture.")


static func build(root: Node3D, seed: int, opts: Dictionary = {}) -> void:
	var surface: String = String(opts.get("surface", "latex"))
	var harness: String = String(opts.get("harness", "bare"))

	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# --- proportions, dealt ---------------------------------------------------
	var hip_y: float = rng.randf_range(0.80, 0.90)
	var shoulder_y: float = hip_y + rng.randf_range(0.44, 0.52)
	var head_y: float = shoulder_y + rng.randf_range(0.18, 0.23)
	var hip_w: float = rng.randf_range(0.155, 0.205)
	var shoulder_w: float = rng.randf_range(0.150, 0.200)
	var lean: float = rng.randf_range(-0.075, 0.075)
	var contra: float = rng.randf_range(0.03, 0.085) * (1.0 if rng.randf() < 0.5 else -1.0)
	# the heel is the fetish object as much as the harness: a platform sole and
	# a stilt, which is why the ankle sits high and the calf runs almost straight
	var heel_h: float = rng.randf_range(0.16, 0.24)
	var sole_h: float = rng.randf_range(0.035, 0.060)

	var parts: Array = []

	# legs: sole, heel stilt, calf, thigh — one continuous run into the hip
	for s in [-1.0, 1.0]:
		var fx: float = s * hip_w * 0.55
		var fz: float = contra * s * 0.5
		parts.append(Iso.box(Vector3(fx, sole_h * 0.5, fz + 0.035),
			Vector3(0.062, sole_h * 0.5, 0.115), 0.02))
		parts.append(Iso.capsule(Vector3(fx, sole_h, fz - 0.05),
			Vector3(fx, sole_h + heel_h, fz - 0.03), 0.028, 0.036))
		parts.append(Iso.capsule(Vector3(fx, sole_h + heel_h * 0.6, fz),
			Vector3(fx + s * 0.012, hip_y * 0.52, fz + contra), 0.070, 0.085))
		parts.append(Iso.capsule(Vector3(fx + s * 0.012, hip_y * 0.52, fz + contra),
			Vector3(s * hip_w * 0.48, hip_y, 0.0), 0.085, 0.105))

	# hips and waist
	parts.append(Iso.capsule(Vector3(-hip_w * 0.42, hip_y, 0.0),
		Vector3(hip_w * 0.42, hip_y, 0.0), 0.155, 0.155))
	var waist_y: float = hip_y + (shoulder_y - hip_y) * 0.40
	parts.append(Iso.capsule(Vector3(lean * 0.3, hip_y + 0.02, 0.0),
		Vector3(lean * 0.6, waist_y, 0.01), 0.135, 0.115))
	# chest
	#
	# THE TOP RADIUS IS 0.125, NOT 0.150, AND THAT IS THE COLLAR'S DOING.
	# commons/testing/probe_iso_cell_cost.gd measures a feature by DELETING it and
	# remeshing — how far does the surface move if the part is not there? The
	# collar answered 4.49 mm max, 0.45 mm mean, which from cell 0.046 upward is
	# SMALLER than the deviation the march itself introduces. The collar was not
	# being lost by the mesher; it was being eaten by this capsule. A 0.150 cap at
	# the shoulder still spans 0.130 at collar height, against the collar's own
	# outer radius of 0.084 — the torus was inside the chest. The shoulder bar
	# below already carries the width, so the chest tapers to 0.125 and the collar
	# clears it. A fetish idol whose collar does not read is missing the point.
	parts.append(Iso.capsule(Vector3(lean * 0.6, waist_y, 0.01),
		Vector3(lean, shoulder_y, 0.0), 0.120, 0.125))
	parts.append(Iso.capsule(Vector3(lean - shoulder_w * 0.5, shoulder_y, 0.0),
		Vector3(lean + shoulder_w * 0.5, shoulder_y, 0.0), 0.098, 0.098))

	# arms — one down, one raised, so the silhouette is not symmetric
	var raised: float = 1.0 if rng.randf() < 0.5 else -1.0
	for s2 in [-1.0, 1.0]:
		var sx: float = lean + s2 * (shoulder_w * 0.5 + 0.03)
		if s2 == raised:
			var elb := Vector3(sx + s2 * 0.16, shoulder_y + 0.02, -0.04)
			parts.append(Iso.capsule(Vector3(sx, shoulder_y, 0.0), elb, 0.060, 0.048))
			parts.append(Iso.capsule(elb, Vector3(sx + s2 * 0.20, shoulder_y + 0.30, -0.02), 0.048, 0.038))
		else:
			var elb2 := Vector3(sx + s2 * 0.035, shoulder_y - 0.26, 0.02)
			parts.append(Iso.capsule(Vector3(sx, shoulder_y, 0.0), elb2, 0.060, 0.048))
			parts.append(Iso.capsule(elb2, Vector3(sx + s2 * 0.07, shoulder_y - 0.50, 0.05), 0.048, 0.036))

	# neck, collar, head
	parts.append(Iso.capsule(Vector3(lean, shoulder_y, 0.0), Vector3(lean, head_y - 0.10, 0.0), 0.052, 0.048))
	# the collar, lifted clear of the chest cap and thickened: outer radius
	# 0.062 + 0.030 = 0.092 against a chest that is 0.075 wide at this height
	parts.append(Iso.torus(Vector3(lean, shoulder_y + 0.100, 0.0), 0.062, 0.030, Vector3.UP))
	parts.append(Iso.sphere(Vector3(lean, head_y, 0.0), 0.105))
	# and one bored hole through the raised hand's reach, so the field's own
	# subtraction is on show in every frame
	parts.append(Iso.cut(Iso.sphere(Vector3(lean, waist_y + 0.05, 0.14), 0.105)))

	# THE CELL IS THE ONE THING A CALLER MAY OVERRIDE, and only a caller with a
	# reason to. CELL 0.034 is the bench value: it is what the DNA sweep and the
	# published gallery photograph, and it costs about 1.7 s a body. The museum
	# builds halls on the main thread while someone is walking through them, so
	# it stands a coarser individual — see _sculpt_axis_deal in
	# commons/scenes/endless_museum.gd. Both numbers stay comparable because
	# neither changes the other.
	#
	# A COARSER CELL IS AN AMPUTATION AND IT IS SILENT: dream_iso.mesh_of warns
	# only when it emits NOTHING, so a cell that melts the collar (minor radius
	# 0.026) or the platform heel (0.028) still commits thousands of triangles
	# and says nothing. So it is clamped to a range that has been MEASURED,
	# never taken on trust from a config file.
	var cell: float = clampf(float(opts.get("cell", CELL)), CELL, 0.052)
	var mesh: ArrayMesh = Iso.mesh_of(parts, cell, BLEND, 0.06)
	if mesh == null:
		push_warning("[fetish_idol] the field yielded no body")
		return
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var main: Color = Gloss.queer_colour(rng)
	var accent: Color = Gloss.queer_colour(rng)
	var tries: int = 0
	while accent.is_equal_approx(main) and tries < 6:
		accent = Gloss.queer_colour(rng)
		tries += 1
	var mat: ShaderMaterial = Shaders.skin(surface, harness, main, accent, seed)
	# the harness is drawn in OBJECT space, so its scale has to be told the size
	# of this body or the straps land as a moire instead of as leather
	mat.set_shader_parameter("harness_scale", 2.35)
	mi.material_override = mat
	root.add_child(mi)

	# --- the plinth: matte, because the body is the only wet thing here -------
	var slab := BoxMesh.new()
	slab.size = Vector3(0.72, 0.055, 0.72)
	var pm := MeshInstance3D.new()
	pm.mesh = slab
	pm.material_override = Gloss.skin("matte", Color(0.80, 0.79, 0.82), rng)
	pm.transform = Transform3D(Basis(), Vector3(0.0, -0.028, 0.0))
	root.add_child(pm)

	# --- fit, centre, settle -------------------------------------------------
	var box: AABB = _union_aabb(root)
	var kx: float = 1.20 / maxf(box.size.x, 0.01)
	var kz: float = 1.20 / maxf(box.size.z, 0.01)
	var ky: float = 1.68 / maxf(box.size.y, 0.01)
	var kfit: float = minf(1.0, minf(kx, minf(kz, ky)))
	if kfit < 1.0:
		for ch in root.get_children():
			if not (ch is MeshInstance3D):
				continue
			var cm: MeshInstance3D = ch
			cm.transform = Transform3D(cm.transform.basis.scaled(Vector3(kfit, kfit, kfit)),
				cm.transform.origin * kfit)
		box = _union_aabb(root)
	var centre: Vector3 = box.position + box.size * 0.5
	var shift := Vector3(-centre.x, -box.position.y, -centre.z)
	for ch in root.get_children():
		if not (ch is MeshInstance3D):
			continue
		var cm2: MeshInstance3D = ch
		cm2.transform = Transform3D(cm2.transform.basis, cm2.transform.origin + shift)


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


## The prediction, as data, so tools/dream_bodies_promote.py can carry it into
## the registry instead of anyone retyping it. Named pair, number, arithmetic —
## and the outcome, because a prediction nobody scores is a decoration.
static func predicted() -> Dictionary:
	return {
		"pair": "harness: bare vs zip (any surface)",
		"predicted_pct": 2.2,
		"measured_pct": 0.98,
		"reasoning": ("the zip is a 9 cm tape on a 1.68 m body, ~3.4% of the silhouette; "
			+ "chrome's hardware is closest in value to its own skin"),
		"outcome": ("right pair, 2.2x high — 3.4% of the SILHOUETTE against a subject that "
			+ "is ~30% of frame is ~1.0% of the picture; the number was quoted against the "
			+ "wrong denominator, not measured off a broken render"),
	}
