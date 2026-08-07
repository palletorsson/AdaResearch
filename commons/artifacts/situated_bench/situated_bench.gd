extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name SituatedBench

## @identity
## name: Situated Bench — No View From Nowhere
## concept: Situated computation
## tier: medium
## lineage: Donna Haraway's situated knowledges, read as an engineering constraint after
##   the foundations crisis. There is no "view from nowhere" — every measurement, every
##   dataset reading, is taken from a standpoint, with a body, an instrument, a position.
##   The post-crisis move is not to lament this (as if objectivity were lost) but to BUILD
##   with it: make the standpoint explicit, render the same data three ways for three
##   viewers, and treat the disagreement between readings as data about position, not error.
## essence: a floor-standing bench with one central dataset object at the middle. Around it
##   sit three little viewpoints — three instrument "eyes" on posts. Each eye casts a
##   coloured sightline to the centre, and beside each eye a small readout shows the SHAPE
##   that standpoint sees: from one angle a cube, from another a ring, from another a spike.
##   Same data, three bodies, three readings.
## truth: there is no view from nowhere; every reading has a standpoint. The shape you
##   measure is a fact about the data AND about where you stood to measure it.

## SURFACE PASS — 2026-08-07. The bench was assembled out of Godot defaults: one
## roughness value per object, metallic 0.6 on the legs (which is neither metal nor
## dielectric), zero-radius edges that catch no highlight, and nothing underneath to
## say the thing stood on a floor. It is furniture in a laboratory — a phenolic-resin
## worktop on turned steel legs — and the whole argument of furniture is that somebody
## used it. So this pass is wear, not effects: chamfers rubbed bright, the underside
## darkened where a floor and a pair of shoes live, a two-scale patina across the top,
## metal shaded as metal, and a contact shadow so the bench sits instead of hovering.
## The instrument light is left exactly where it was — three eyes, three sightlines,
## one core. Not one position, size or rotation moved at any address; the single
## geometric edit is a hidden centimetre in parallax, and it is documented there.
const PBR := preload("res://commons/render/pbr_kit.gd")
const MK := preload("res://commons/render/mesh_kit.gd")

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var slate: Color = Color(0.20, 0.23, 0.30)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var accent_a: Color = Color(0.40, 0.85, 0.95)   # standpoint A — teal
@export var accent_b: Color = Color(0.98, 0.72, 0.32)   # standpoint B — amber
@export var accent_c: Color = Color(0.70, 0.55, 0.98)   # standpoint C — violet
@export var spin_speed: float = 0.4

# ── DNA ──────────────────────────────────────────────────────────────────────
## AXIS — WHAT THE BENCH DOES WITH THE POSITIONS ITS READINGS ARE TAKEN FROM.
## The word and all five values are [[situated_readout]]'s `address`, adopted
## exactly: same Haraway lineage, same question — a claim's authority depends on
## a fact the claim does not state, which is where it was made from. The one
## honest difference is the DEFAULT. The readout ships as `footnote` (its
## address is one dim line of type); this bench ships with three instrument
## eyes ON POSTS, sightlines cast to the data, and each standpoint named — the
## position already IS mass, standing somewhere, at a height, facing a way.
## That is the sibling's own definition of `witness`, so witness is the value
## that reproduces the shipped build byte for byte.
##
##   erasure   the standpoints are COVERED. The posts still stand, but a slab of
##             overpaint sits askew where each eye and its ring were; no
##             sightlines, no standpoint names. The three readings remain —
##             cube, ring, spike — floating free of any admitted origin: three
##             "objective" verdicts whose bodies someone painted out, with the
##             cover left as evidence.
##   footnote  the standpoints are ADMITTED SMALL. Tiny dim eyes, hairline dim
##             sightlines, no rings; each station keeps its reading full-size
##             while its name shrinks to the smallest, dimmest type on the
##             bench. The disagreement is loud, its origins disturb nothing.
##   witness   the shipped bench, byte for byte — the legacy lineage.
##   parallax  the bench FAILS TO CLOSE. There is no common table: three
##             separate island stands, one per standpoint, each with its own
##             leg, its own eye, its own sightline, and tie bars reaching for a
##             centre they never meet. The dataset — the one thing all three
##             agree exists — hangs over the gap with nothing under it.
##   survey    the bench drawn FROM standpoint A. A's eye grows into the
##             instrument of the piece; B and C appear as A has them — their
##             eyes and readings pulled toward A's teal and dimmed, their own
##             sightlines gone, replaced by A's thin account-lines of where
##             they stand. Even the dataset carries A's cast, and a line under
##             the title admits who surveyed the field.
@export_enum("erasure", "footnote", "witness", "parallax", "survey") var address: String = "witness"
const ADDRESSES: PackedStringArray = ["erasure", "footnote", "witness", "parallax", "survey"]

## Capture fixture — truthy stops _process so the idle pulse and readout spin
## cannot smear a sweep tile; every material then holds its built energy and the
## scene is fully deterministic. UNTYPED on purpose: the sweep writes fixture
## values with set() before _ready, and a typed bool silently rejects the
## string "true" (the catalyst_prompter_box trap). Default false = shipped.
var still = false

var _t: float = 0.0
var _center_mat: StandardMaterial3D
var _eye_mats: Array[StandardMaterial3D] = []
var _line_mats: Array[StandardMaterial3D] = []
var _readout_root: Array[Node3D] = []     # the three "what it sees" mini-shapes
var _center_pos: Vector3 = Vector3(0.0, 0.78, 0.0)


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint() and not _truthy(still))


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("spin_speed"):
		spin_speed = float(config["spin_speed"])
	# address: what the bench does with the positions its readings are taken
	# from. Normalised against ADDRESSES so a typo in a map token keeps the
	# shipped witness build instead of staging something undeclared.
	if config.has("address"):
		var a: String = str(config["address"]).strip_edges().to_lower()
		if ADDRESSES.has(a):
			address = a
	if config.has("still"):
		still = config["still"]
		set_process(not Engine.is_editor_hint() and not _truthy(still))
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


# Truthy check for the untyped fixture flag — native bool, "true"/"1"/"yes"/"on"
# strings, or non-zero numbers.
func _truthy(value) -> bool:
	if typeof(value) == TYPE_BOOL:
		return value
	if typeof(value) == TYPE_STRING:
		return str(value).to_lower() in ["true", "1", "yes", "on"]
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		return value != 0
	return false


# ─────────────────────────────────────────────────────────────────────────────
# SURFACES AND MESH. Every address arm builds through the same five primitives and
# three material builders it inherits from embodied_prop. Overriding them here
# re-finishes all five arms at once, and — because not one call site is touched —
# every position, size and rotation stays exactly where the shipped bench put it.
# ─────────────────────────────────────────────────────────────────────────────

## The dielectric surfaces: the worktop, the island tops, the slabs of overpaint.
## A lab bench top is cast phenolic resin, not paint — metallic 0, no clear coat, a
## fine speckle in the roughness so the highlight is a soft field instead of one flat
## wash, then grunge on a second, coarser scale for the patina of use.
##
## `rough` is honoured rather than replaced, but PRE-DIVIDED: Godot computes
## ROUGHNESS = roughness * texture, so a scalar handed over raw comes out glossier
## than asked for by the texture's mean. The 0.82 bias is deliberate — 0.85 dead flat
## was a guess, and a resin top that has been leaned on is satin. The spread between
## the worktop (0.70) and the chalkier overpaint (0.78) survives it.
func _matte_mat(c: Color, rough: float = 0.8, metal: float = 0.0) -> StandardMaterial3D:
	if metal > 0.35:
		return _steel_mat(c)
	var w: float = clampf(rough - 0.55, 0.0, 0.45)
	var m: StandardMaterial3D = PBR.rams_body(c, w)
	var target: float = clampf(rough * 0.82, 0.30, 0.92)
	var mean: float = (PBR.LO_PAINT + 1.0) * 0.5
	m.roughness = clampf(target / mean, 0.02, 1.0)
	# 0.24 + w*0.6 put the worktop at 0.42 and the render came back as bark. A lab
	# bench that has been leaned on is SATIN — the wear shows as a slight unevenness
	# in the sheen, not as texture you could feel through a glove. Halved, and the
	# kit's detail normal now scales with this number instead of ignoring it.
	PBR.weather(m, 0.12 + w * 0.3)
	PBR.crevice_ao(m, 0.45)
	return m


## Legs, posts, the pillar under the data. These are METAL and were not being shaded
## as metal: albedo 0.30 grey at metallic 0.6 sits in the physically meaningless
## middle, and it is the loudest amateur tell on the bench. A bench leg is turned bar
## stock, so machined rather than brushed — metallic 1.0, a measured steel
## reflectance the caller's grey is pulled toward, micro-pitting in the roughness.
##
## The parent lit these with a token emission — energy 0.1 over an emission colour
## already scaled to 0.3, so about 0.009 of radiance. It went. What replaces it is
## ROUGHNESS, not a trick: 0.47 rather than a polished 0.30, because a full metal
## with no reflection source has only the direct lights to work with and a tight
## lobe would leave the legs black between the two highlights. A satin leg catches
## both. Nobody polishes bench legs anyway.
##
## No Fresnel rim here, deliberately: Godot multiplies diffuse_light — which is
## where rim lands — by (1 - metallic), so edge_light() on a metallic 1.0 surface
## is a line of code that does nothing at all.
func _steel_mat(c: Color) -> StandardMaterial3D:
	var m: StandardMaterial3D = PBR.machined_metal(c.lerp(PBR.STEEL, 0.45), 0.42, 0.26)
	PBR.weather(m, 0.28)
	# Every upright on this bench is 2.8-6 cm across. The kit authors its triplanar
	# detail at 6 tiles/m, which never repeats on a part that thin and so reads as
	# flat colour; 8x lands the grain near a centimetre. Fitted here, and flagged so
	# _fit_detail leaves it alone.
	PBR.scale_detail(m, 8.0)
	m.set_meta("bench_fit", true)
	return m


## Instrument light — the eyes, the sightlines, the wire cage, the readings. Same
## energy rule as the parent (and as _process, which re-applies it every frame), so
## the `emissive` export behaves exactly as before. What changes is that the albedo
## is darkened relative to the emission: a surface carrying both at full value clips
## to white the moment any scene light lands on it, and a clipped white is the one
## colour mistake that cannot be graded back.
func _glow_mat(c: Color, energy: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = PBR.emissive(c, energy if emissive else energy * 0.3)
	m.roughness = 0.28
	return m


## Rescale a material's triplanar detail to the part it is about to dress. The kit's
## scale_detail MULTIPLIES, so a material shared by two meshes of different sizes
## would compound — the meta flag makes it once-only, at the first and largest use.
## Emissive parts are skipped: their surface is light, not finish.
func _fit_detail(mat: Material, longest: float) -> void:
	if not (mat is StandardMaterial3D):
		return
	var m: StandardMaterial3D = mat as StandardMaterial3D
	if m.emission_enabled or m.has_meta("bench_fit"):
		return
	m.set_meta("bench_fit", true)
	if longest >= 0.45:
		return
	PBR.scale_detail(m, clampf(1.0 / maxf(longest, 0.02), 1.0, 8.0))


## A chamfered box. Every real edge has a break on it, and that break is the
## highlight line that separates a slab from a rendered box. `wear` scales with the
## part: the metre-wide worktop takes the full vertex-colour gradient — chamfers
## rubbed bright where hands and hips pass, underside darkened where a floor and a
## pair of shoes live — while a 7 cm readout cube takes almost none.
func _box(center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var longest: float = maxf(size.x, maxf(size.y, size.z))
	_fit_detail(mat, longest)
	# Wear ceiling cut from 0.45: the metre-wide worktop hit the cap, and the baked
	# vertex darkening stacked on top of the grime multiply and the AO map until a
	# slate bench read as a black one. Three subtle effects agreeing on "darker" is
	# not subtle. The gradient is still there; it just no longer eats the colour.
	return PBR.box(center, size, mat, -1.0, clampf((longest - 0.06) * 0.6, 0.0, 0.20))


## A cylinder with chamfered rims. A raw CylinderMesh ends in a zero-radius corner
## that vanishes against any background; the chamfer draws a bright ring at the foot
## of every leg and the top of every post. 18 radial segments instead of Godot's 64 —
## a 6 cm bar does not need 64, and the saving is what pays for the chamfer.
func _cylinder(center: Vector3, radius: float, height: float, mat: Material) -> MeshInstance3D:
	_fit_detail(mat, maxf(radius * 2.0, height))
	var mi := MeshInstance3D.new()
	mi.mesh = MK.cylinder(radius, height, 18, clampf(minf(radius, height) * 0.16, 0.0009, 0.005))
	mi.material_override = mat
	mi.position = center
	return mi


## The sightlines and the tie bars. Thin glowing rods, so ten sides is plenty, and
## the kit's transform is the parent's to the last decimal — same basis convention,
## same midpoint, same fallback axis.
func _cylinder_between(a: Vector3, b: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	return PBR.pipe(a, b, radius, mat, 10)


## Godot's SphereMesh defaults to 64x32 — 4096 triangles for a 5 cm instrument eye.
## At 32x16 the silhouette of the largest sphere here moves by six tenths of a
## millimetre and the bench sheds three quarters of its triangles, which is where the
## VR budget for the chamfers and the noise comes from.
func _sphere(center: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	_fit_detail(mat, radius * 2.0)
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 32
	mesh.rings = 16
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


## Same argument as the sphere: TorusMesh ships at 64x32 and there are up to six of
## them on this bench. 36x14 on a 6 mm tube is smooth at any distance a body can
## stand at.
func _torus(center: Vector3, radius: float, tube: float, mat: Material) -> MeshInstance3D:
	_fit_detail(mat, tube * 2.0)
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - tube
	mesh.outer_radius = radius + tube
	mesh.rings = 36
	mesh.ring_segments = 14
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


## The parent outlines every label in pure black. Nothing in a lit room is 0,0,0;
## the outline takes the capture rig's own background instead, so it reads as depth
## behind the type rather than as ink drawn over it.
func _billboard_label(text: String, pos: Vector3, font: int, color: Color) -> Label3D:
	var l: Label3D = super._billboard_label(text, pos, font, color)
	l.outline_modulate = Color(0.045, 0.050, 0.062, 1.0)
	return l


## The contact shadow that makes the bench SIT. A Decal, so it conforms to whatever
## floor a map puts under it instead of z-fighting a flat quad, and a Decal is not a
## light, so it costs nothing against the VR light budget. It is also not a
## MeshInstance3D, so the capture AABB — and every framing number ever measured on
## this artifact — stays exactly where it was.
func _ground_shadow(radius: float, at: Vector3 = Vector3.ZERO) -> void:
	var d: Decal = PBR.ground_shadow(radius, 0.5, 0.10)
	d.position += at
	add_child(d)


func _build() -> void:
	_eye_mats = []
	_line_mats = []
	_readout_root = []

	# The witness arm is the shipped build, statement for statement; every other
	# address stages the same three claims with a different account of where
	# they were made from.
	match address:
		"erasure":
			_build_erasure()
		"footnote":
			_build_footnote()
		"parallax":
			_build_parallax()
		"survey":
			_build_survey()
		_:
			_build_witness()


## WITNESS — the legacy lineage. Every statement below is the shipped _build()
## body, unmoved and unedited, so address=witness still builds the same children
## in the same order, at the same positions and the same sizes, that the six
## placed benches have always built. The one addition is the contact shadow every
## address now carries: a Decal, not a mesh, so it changes no silhouette and no
## measured AABB — it only stops the bench hovering over a map's floor.
func _build_witness() -> void:
	# --- bench base ~1 m ---
	var base_mat: StandardMaterial3D = _matte_mat(slate, 0.85)
	add_child(_box(Vector3(0.0, 0.36, 0.0), Vector3(1.0, 0.16, 1.0), base_mat))
	var leg_mat: StandardMaterial3D = _steel_mat(Color(0.30, 0.31, 0.34))
	for sx in [-0.42, 0.42]:
		for sz in [-0.42, 0.42]:
			add_child(_cylinder(Vector3(sx, 0.18, sz), 0.03, 0.36, leg_mat))
	_ground_shadow(0.62)

	# --- central dataset object: a faceted, ambiguous core (the SAME data) ---
	_center_mat = _glow_mat(cool_white, 0.9)
	# pillar up to the core
	add_child(_cylinder(Vector3(0.0, 0.55, 0.0), 0.03, 0.32, _steel_mat(Color(0.34, 0.35, 0.38))))
	add_child(_sphere(_center_pos, 0.13, _center_mat))
	# wire cage around it — the raw, un-standpointed data
	add_child(_torus(_center_pos, 0.18, 0.006, _glow_mat(wire_purple, 0.7)))
	var ring2: MeshInstance3D = _torus(_center_pos, 0.18, 0.006, _glow_mat(wire_purple, 0.6))
	ring2.rotation = Vector3(PI / 2.0, 0.0, 0.0)
	add_child(ring2)
	add_child(_billboard_label("DATASET", _center_pos + Vector3(0.0, 0.26, 0.0), 16, cool_white))

	# --- three standpoints around the centre, each seeing a different shape ---
	var accents: Array[Color] = [accent_a, accent_b, accent_c]
	var see_names: Array[String] = ["a CUBE", "a RING", "a SPIKE"]
	var si: int = 0
	while si < 3:
		var ang: float = float(si) * TAU / 3.0 - PI / 2.0
		var eye_p: Vector3 = Vector3(cos(ang) * 0.42, 0.78, sin(ang) * 0.42)
		# instrument post
		add_child(_cylinder(Vector3(eye_p.x, 0.56, eye_p.z), 0.018, 0.30, _steel_mat(Color(0.32, 0.33, 0.37))))
		# the eye
		var em: StandardMaterial3D = _glow_mat(accents[si], 1.2)
		_eye_mats.append(em)
		add_child(_sphere(eye_p, 0.05, em))
		add_child(_torus(eye_p, 0.075, 0.005, _glow_mat(accents[si], 0.7)))
		# coloured sightline from eye to centre
		var lm: StandardMaterial3D = _glow_mat(accents[si], 0.9)
		_line_mats.append(lm)
		add_child(_cylinder_between(eye_p, _center_pos, 0.006, lm))
		# the readout: a small mini-shape next to the eye = what THIS standpoint sees
		var readout: Node3D = Node3D.new()
		readout.position = eye_p + Vector3(0.0, 0.16, 0.0)
		var shape_mat: StandardMaterial3D = _glow_mat(accents[si], 1.0)
		if si == 0:
			# CUBE
			readout.add_child(_box(Vector3.ZERO, Vector3(0.07, 0.07, 0.07), shape_mat))
		elif si == 1:
			# RING
			readout.add_child(_torus(Vector3.ZERO, 0.045, 0.012, shape_mat))
		else:
			# SPIKE — a cone via short tapered cylinder stack
			readout.add_child(_box(Vector3(0.0, 0.0, 0.0), Vector3(0.02, 0.09, 0.02), shape_mat))
			readout.add_child(_sphere(Vector3(0.0, 0.05, 0.0), 0.016, shape_mat))
		add_child(readout)
		_readout_root.append(readout)
		# standpoint label
		add_child(_billboard_label("STANDPOINT " + char(65 + si), eye_p + Vector3(0.0, -0.12, 0.0), 14, accents[si]))
		add_child(_billboard_label("sees " + see_names[si], eye_p + Vector3(0.0, 0.30, 0.0), 13, accents[si]))
		si += 1

	# --- title (medium tier: y ~ 1.5) ---
	add_child(_billboard_label("NO VIEW FROM NOWHERE", Vector3(0.0, 1.5, 0.0), 26, cool_white))
	add_child(_billboard_label("every reading has a standpoint", Vector3(0.0, 1.38, 0.0), 15, Color(0.78, 0.84, 0.96)))


# ─────────────────────────────────────────────────────────────────────────────
# THE OTHER ADDRESSES. Shared pieces for the four staged lineages only — the
# witness path above never calls these, so the shipped build stays untouchable.
# ─────────────────────────────────────────────────────────────────────────────

## The shipped bench base and legs, reused by every address that keeps a
## common table (erasure, footnote, survey) — including the one contact shadow
## that comes with having one table to stand on.
func _variant_base() -> void:
	var base_mat: StandardMaterial3D = _matte_mat(slate, 0.85)
	add_child(_box(Vector3(0.0, 0.36, 0.0), Vector3(1.0, 0.16, 1.0), base_mat))
	var leg_mat: StandardMaterial3D = _steel_mat(Color(0.30, 0.31, 0.34))
	for sx in [-0.42, 0.42]:
		for sz in [-0.42, 0.42]:
			add_child(_cylinder(Vector3(sx, 0.18, sz), 0.03, 0.36, leg_mat))
	_ground_shadow(0.62)


## The central dataset core. tint_amt 0 = the shipped neutral core; survey
## pulls every part toward one standpoint's colour. with_pillar=false lets
## parallax leave the data hanging over the gap.
func _variant_center(tint: Color, tint_amt: float, with_pillar: bool) -> void:
	var core_c: Color = cool_white.lerp(tint, tint_amt)
	var wire_c: Color = wire_purple.lerp(tint, tint_amt)
	_center_mat = _glow_mat(core_c, 0.9)
	if with_pillar:
		add_child(_cylinder(Vector3(0.0, 0.55, 0.0), 0.03, 0.32, _steel_mat(Color(0.34, 0.35, 0.38))))
	add_child(_sphere(_center_pos, 0.13, _center_mat))
	add_child(_torus(_center_pos, 0.18, 0.006, _glow_mat(wire_c, 0.7)))
	var ring2: MeshInstance3D = _torus(_center_pos, 0.18, 0.006, _glow_mat(wire_c, 0.6))
	ring2.rotation = Vector3(PI / 2.0, 0.0, 0.0)
	add_child(ring2)
	add_child(_billboard_label("DATASET", _center_pos + Vector3(0.0, 0.26, 0.0), 16, core_c))


## The two title labels every address keeps — the teaching is not the axis.
func _variant_titles() -> void:
	add_child(_billboard_label("NO VIEW FROM NOWHERE", Vector3(0.0, 1.5, 0.0), 26, cool_white))
	add_child(_billboard_label("every reading has a standpoint", Vector3(0.0, 1.38, 0.0), 15, Color(0.78, 0.84, 0.96)))


## One standpoint's reading — the mini-shape beside the eye. Registered in
## _readout_root so the idle spin keeps working at every address.
func _variant_readout(si: int, eye_p: Vector3, mat: StandardMaterial3D) -> void:
	var readout: Node3D = Node3D.new()
	readout.position = eye_p + Vector3(0.0, 0.16, 0.0)
	if si == 0:
		readout.add_child(_box(Vector3.ZERO, Vector3(0.07, 0.07, 0.07), mat))
	elif si == 1:
		readout.add_child(_torus(Vector3.ZERO, 0.045, 0.012, mat))
	else:
		readout.add_child(_box(Vector3(0.0, 0.0, 0.0), Vector3(0.02, 0.09, 0.02), mat))
		readout.add_child(_sphere(Vector3(0.0, 0.05, 0.0), 0.016, mat))
	add_child(readout)
	_readout_root.append(readout)


## ERASURE — the standpoints are covered, the claims remain. Each post still
## stands, but where the eye and its ring were there is a slab of overpaint,
## slightly askew, with a hard darker lip: not an absent position, the visible
## act of removing one. No sightlines, no standpoint names — three verdicts
## floating free of any admitted body.
func _build_erasure() -> void:
	_variant_base()
	_variant_center(cool_white, 0.0, true)
	var accents: Array[Color] = [accent_a, accent_b, accent_c]
	var see_names: Array[String] = ["a CUBE", "a RING", "a SPIKE"]
	var patch_mat: StandardMaterial3D = _matte_mat(Color(0.64, 0.63, 0.60), 0.95)
	var lip_mat: StandardMaterial3D = _matte_mat(Color(0.36, 0.35, 0.33), 0.9)
	var si: int = 0
	while si < 3:
		var ang: float = float(si) * TAU / 3.0 - PI / 2.0
		var eye_p: Vector3 = Vector3(cos(ang) * 0.42, 0.78, sin(ang) * 0.42)
		add_child(_cylinder(Vector3(eye_p.x, 0.56, eye_p.z), 0.018, 0.30, _steel_mat(Color(0.32, 0.33, 0.37))))
		# the overpaint slab where the instrument was — turned to face outward
		# from the bench centre, hung a touch off square
		var patch: Node3D = Node3D.new()
		patch.position = eye_p
		patch.rotation = Vector3(0.0, -ang + PI / 2.0, 0.07)
		patch.add_child(_box(Vector3.ZERO, Vector3(0.17, 0.17, 0.022), patch_mat))
		patch.add_child(_box(Vector3(0.0, 0.092, 0.002), Vector3(0.17, 0.012, 0.026), lip_mat))
		patch.add_child(_box(Vector3(0.0, -0.092, 0.002), Vector3(0.17, 0.012, 0.026), lip_mat))
		add_child(patch)
		# the claim survives its covered origin
		_variant_readout(si, eye_p, _glow_mat(accents[si], 1.0))
		add_child(_billboard_label("sees " + see_names[si], eye_p + Vector3(0.0, 0.30, 0.0), 13, accents[si]))
		si += 1
	_variant_titles()


## FOOTNOTE — the standpoints admitted in the smallest terms. Tiny dim eyes on
## the same posts, hairline dim sightlines, no rings; each reading keeps its
## full size and colour while its origin's name drops to the smallest, dimmest
## type on the bench. The sibling readout's shipped state, spoken as furniture.
func _build_footnote() -> void:
	_variant_base()
	_variant_center(cool_white, 0.0, true)
	var accents: Array[Color] = [accent_a, accent_b, accent_c]
	var see_names: Array[String] = ["a CUBE", "a RING", "a SPIKE"]
	var faint: Color = Color(0.55, 0.57, 0.62)
	var si: int = 0
	while si < 3:
		var ang: float = float(si) * TAU / 3.0 - PI / 2.0
		var eye_p: Vector3 = Vector3(cos(ang) * 0.42, 0.78, sin(ang) * 0.42)
		add_child(_cylinder(Vector3(eye_p.x, 0.56, eye_p.z), 0.018, 0.30, _steel_mat(Color(0.32, 0.33, 0.37))))
		var em: StandardMaterial3D = _glow_mat(accents[si], 0.35)
		_eye_mats.append(em)
		add_child(_sphere(eye_p, 0.018, em))
		var lm: StandardMaterial3D = _glow_mat(accents[si], 0.3)
		_line_mats.append(lm)
		add_child(_cylinder_between(eye_p, _center_pos, 0.0018, lm))
		_variant_readout(si, eye_p, _glow_mat(accents[si], 1.0))
		add_child(_billboard_label("standpoint " + char(97 + si), eye_p + Vector3(0.0, -0.12, 0.0), 8, faint))
		add_child(_billboard_label("sees " + see_names[si], eye_p + Vector3(0.0, 0.30, 0.0), 13, accents[si]))
		si += 1
	_variant_titles()


## PARALLAX — no common table. Three island stands, one per standpoint, each on
## its own leg with its own full apparatus; tie bars reach from every island
## toward a centre none of them touches, and the dataset — the one thing all
## three agree exists — hangs over the gap with nothing under it.
func _build_parallax() -> void:
	var accents: Array[Color] = [accent_a, accent_b, accent_c]
	var see_names: Array[String] = ["a CUBE", "a RING", "a SPIKE"]
	var leg_mat: StandardMaterial3D = _steel_mat(Color(0.30, 0.31, 0.34))
	var top_mat: StandardMaterial3D = _matte_mat(slate, 0.85)
	var si: int = 0
	while si < 3:
		var ang: float = float(si) * TAU / 3.0 - PI / 2.0
		var dir_v: Vector3 = Vector3(cos(ang), 0.0, sin(ang))
		var island_c: Vector3 = dir_v * 0.48
		# the island: its own tabletop on its own single leg. The leg used to stop
		# at exactly y = 0.28 and the tabletop's underside starts at exactly
		# y = 0.28 — two coplanar faces, which is a z-fight, not a joint. One
		# centimetre of embedment fixes it, and the extra length is buried inside an
		# opaque slab three times its width, so not a pixel of silhouette moves.
		add_child(_box(island_c + Vector3(0.0, 0.36, 0.0), Vector3(0.34, 0.16, 0.34), top_mat))
		add_child(_cylinder(island_c + Vector3(0.0, 0.145, 0.0), 0.03, 0.29, leg_mat))
		# each island answers to its own patch of floor — three contacts, no shared one
		_ground_shadow(0.26, island_c)
		# tie bar reaching for the centre and stopping short of it
		var tie: StandardMaterial3D = _glow_mat(accents[si].lightened(0.15), 0.6)
		add_child(_cylinder_between(dir_v * 0.34 + Vector3(0.0, 0.44, 0.0), dir_v * 0.12 + Vector3(0.0, 0.44, 0.0), 0.007, tie))
		# the full witness apparatus, per island — each stand still testifies
		var eye_p: Vector3 = dir_v * 0.42 + Vector3(0.0, 0.78, 0.0)
		add_child(_cylinder(Vector3(eye_p.x, 0.56, eye_p.z), 0.018, 0.30, _steel_mat(Color(0.32, 0.33, 0.37))))
		var em: StandardMaterial3D = _glow_mat(accents[si], 1.2)
		_eye_mats.append(em)
		add_child(_sphere(eye_p, 0.05, em))
		add_child(_torus(eye_p, 0.075, 0.005, _glow_mat(accents[si], 0.7)))
		var lm: StandardMaterial3D = _glow_mat(accents[si], 0.9)
		_line_mats.append(lm)
		add_child(_cylinder_between(eye_p, _center_pos, 0.006, lm))
		_variant_readout(si, eye_p, _glow_mat(accents[si], 1.0))
		add_child(_billboard_label("STANDPOINT " + char(65 + si), eye_p + Vector3(0.0, -0.12, 0.0), 14, accents[si]))
		add_child(_billboard_label("sees " + see_names[si], eye_p + Vector3(0.0, 0.30, 0.0), 13, accents[si]))
		si += 1
	# the dataset floats over the void where the shared bench refused to be
	_variant_center(cool_white, 0.0, false)
	_variant_titles()


## SURVEY — the bench drawn FROM standpoint A. A's eye becomes the instrument
## of the piece; B and C appear as A has them — eyes and readings pulled toward
## A's teal and dimmed, their own sightlines gone, replaced by A's thin
## account-lines of where they stand. The dataset itself carries A's cast, and
## a line under the title admits who surveyed the field.
func _build_survey() -> void:
	_variant_base()
	_variant_center(accent_a, 0.35, true)
	var accents: Array[Color] = [accent_a, accent_b, accent_c]
	var see_names: Array[String] = ["a CUBE", "a RING", "a SPIKE"]
	var a_eye: Vector3 = Vector3(cos(-PI / 2.0) * 0.42, 0.78, sin(-PI / 2.0) * 0.42)
	var si: int = 0
	while si < 3:
		var ang: float = float(si) * TAU / 3.0 - PI / 2.0
		var eye_p: Vector3 = Vector3(cos(ang) * 0.42, 0.78, sin(ang) * 0.42)
		if si == 0:
			# the origin: this instrument, larger, lit, and the only one that casts
			add_child(_cylinder(Vector3(eye_p.x, 0.56, eye_p.z), 0.026, 0.30, _steel_mat(Color(0.36, 0.37, 0.41))))
			var em: StandardMaterial3D = _glow_mat(accent_a, 1.5)
			_eye_mats.append(em)
			add_child(_sphere(eye_p, 0.07, em))
			add_child(_torus(eye_p, 0.10, 0.006, _glow_mat(accent_a, 0.8)))
			var lm: StandardMaterial3D = _glow_mat(accent_a, 1.2)
			_line_mats.append(lm)
			add_child(_cylinder_between(eye_p, _center_pos, 0.009, lm))
			_variant_readout(si, eye_p, _glow_mat(accent_a, 1.1))
			add_child(_billboard_label("STANDPOINT A", eye_p + Vector3(0.0, -0.12, 0.0), 14, accent_a))
			add_child(_billboard_label("sees " + see_names[si], eye_p + Vector3(0.0, 0.30, 0.0), 13, accent_a))
		else:
			# another station, as this one has it: tinted toward A, dimmed, and
			# reached only by A's account-line — not by its own sight
			var held_c: Color = accents[si].lerp(accent_a, 0.55).darkened(0.10)
			add_child(_cylinder(Vector3(eye_p.x, 0.56, eye_p.z), 0.014, 0.30, _steel_mat(Color(0.30, 0.31, 0.34))))
			var em2: StandardMaterial3D = _glow_mat(held_c, 0.5)
			_eye_mats.append(em2)
			add_child(_sphere(eye_p, 0.035, em2))
			add_child(_cylinder_between(a_eye, eye_p, 0.0035, _glow_mat(accent_a, 0.45)))
			_variant_readout(si, eye_p, _glow_mat(held_c, 0.6))
			add_child(_billboard_label("standpoint " + char(65 + si), eye_p + Vector3(0.0, -0.12, 0.0), 11, held_c))
			add_child(_billboard_label("sees " + see_names[si], eye_p + Vector3(0.0, 0.30, 0.0), 11, held_c))
		si += 1
	_variant_titles()
	add_child(_billboard_label("surveyed from STANDPOINT A", Vector3(0.0, 1.28, 0.0), 12, accent_a))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# the central data shimmers — it is genuinely ambiguous, not fixed
	if _center_mat != null:
		var sh: float = 0.7 + 0.4 * sin(_t * 1.8)
		_center_mat.emission_energy_multiplier = sh if emissive else sh * 0.3
	# each standpoint's readout slowly rotates and breathes on its own phase
	var i: int = 0
	while i < _readout_root.size():
		var r: Node3D = _readout_root[i]
		if r != null:
			r.rotation.y += delta * (0.6 + 0.2 * float(i))
		# sightlines pulse in turn — attention moving between standpoints
		if _line_mats.size() > i and _line_mats[i] != null:
			var beat: float = 0.5 + 0.5 * sin(_t * 1.2 - float(i) * (TAU / 3.0))
			_line_mats[i].emission_energy_multiplier = (0.5 + 0.9 * beat) if emissive else 0.3
		if _eye_mats.size() > i and _eye_mats[i] != null:
			var ebeat: float = 0.6 + 0.5 * sin(_t * 1.2 - float(i) * (TAU / 3.0))
			_eye_mats[i].emission_energy_multiplier = (0.7 + 0.7 * ebeat) if emissive else 0.3
		i += 1
