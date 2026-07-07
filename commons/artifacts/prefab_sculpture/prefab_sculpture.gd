extends Node3D
class_name PrefabSculpture

# @identity
# essence: a multi-mode generative sculpture standing where nature and the artificial meet — one plinth-less mass that, depending on its `mode` DNA, speaks six contemporary-sculpture vocabularies: cast solid (Rachel Whiteread's negative space made matter), twisted steel (Monika Sosnowska's bent architecture), accumulated unit (Tara Donovan's found object teeming into landscape), tensile web (Tomás Saraceno's airborne cosmos of nodes and strands), pop assemblage (Isa Genzken / Thomas Hirschhorn's precarious vernacular stacks), and bio-membrane (Anicka Yi / Pierre Huyghe's wet machine ecology). It is the boundary between manufactured and grown rendered as a single object that keeps changing its mind about which side it is on.
# desire: it wants to be UNDECIDABLE — to be read at once as found and composed, as living and fabricated, as raw material and finished artwork. Each mode is a different refusal of the nature/artifice border: the cast freezes absence into mass, the twist tortures the orthogonal grid into a lean, the accumulation lets one industrial unit breed a dune, the web hangs biology in tension, the assemblage glorifies trash into monument, the bio grows plastic into flesh. It desires the gallery's gaze and the swamp's indifference equally.
# critical_parameter: mode + seed + the color triad (color_a / color_b / accent) — mode picks the lineage and silhouette; seed varies the individual specimen deterministically so each is a sibling not a clone; the colors slide the same form between registers — pale color_a reads raw-material (plaster, pearl), saturated accent reads pop-artificial, translucent color_a reads bio-membrane. One genome, many species, infinite individuals. Two modes — apparatus and organ — are the "contradiction" modes: each fuses ≥3 INTERPENETRATING CONTRADICTORY materials (heavy concrete / hard chrome / brittle glass / soft wax-membrane / immaterial emissive glow) that pierce and embed into one another, plus 2-4 PSEUDO-FUNCTION features (dial / port / slot / nozzle / valve / vent) that imply operation while meaning nothing, on an ABSTRACT unnameable mass — the QFEP boundary-dissolution made object: the nature/artifice and material/immaterial borders collapsed inside a single thing.
# triggers: _ready() seeds the RNG from `seed`, reads DNA overrides, and branches on `mode` to a _build_<mode>() helper; apply_grid_config rewrites config metas, clears children (remove before free), and rebuilds when DNA changes.
# emerges: dropped into an auto-research gallery, a row of these reads as a TAXONOMY OF MAKING — six ways a hand or a machine turns matter into meaning, sampled and varied like specimens in a vitrine. Switch one mode and the whole room's argument about what art-from-material can be shifts; reseed and the species persists while the individual mutates. The piece is the gallery confessing that "sculpture" is not one thing but a set of grammars for crossing the nature/artifice line.
# needs: a seeded RNG for deterministic individuals [present]; six build branches each with a strong silhouette [present]; MultiMesh batching for the hundreds-of-units modes [present]; a color triad that re-registers the same form [present]; bottom-centre floor origin reading from +Z [present]
# relationships: peer to any single-vocabulary artifact (crate, barber_pole) — where they are ONE object saying one thing, the prefab_sculpture is a switchboard of object-grammars; cousin to the nature_system creatures (both blur living/manufactured, but the creatures grow over time while the sculpture freezes a single decision); sibling to the catalyst blocks (both are matter caught mid-transformation between states).
# truth: there is no base material that is purely natural and none purely artificial — every sculpture is a negotiation across that line, and the line itself is the subject. Whiteread casts the air a chair displaced; Donovan makes a styrofoam cup behave like coral; Saraceno hangs a spider's logic in steel cable; Yi grows bacteria into form. The prefab_sculpture holds all six negotiations in one genome and lets a single parameter choose which border-crossing the viewer witnesses. Nature and the artificial do not meet at an edge — they meet in the object, and the object is always already both.

## A multi-mode generative sculpture where nature and the artificial meet.
##
## Built procedurally from DNA exports. Origin is at the BOTTOM CENTRE of the
## piece (floor-resting, Y up); it reads from +Z. The `mode` export selects one
## of forty-five sculptural vocabularies, each riffing on a contemporary-sculpture
## lineage. A seeded RNG makes every individual deterministic from its `seed`.
##
## Modes: cast, twist, accumulation, web, assemblage, bio, apparatus, organ,
## botanical (bronze-cast flower), drape (slumped cast-cloth assemblage),
## totem (beaded/fringed ceremonial assemblage), judd (minimalist modular stack),
## vitrine (glass greenhouse on a plinth — nature under glass),
## mesh (Ernesto Neto open knit/net membrane tower),
## earthwork (earthen creature on twig legs over a soil mound + mirror),
## vessel (monumental translucent everyday object — bottle/amphora/funnel),
## column (Diana Al-Hadid broken marble columns on finned machined bases),
## lumenarch (dark portal arch studded with glowing blocks),
## threadfield (Chiharu Shiota red-thread web with suspended keys over a hull),
## glowmound (Pierre Huyghe bioluminescent mound + hanging turned-spiral pendant),
## blockfield (model-city heightfield of white cubes on a reflective plinth),
## lattice (Anila Quayyum Agha filigree shadow cube balanced on a vertex over water),
## spiralstack (golden-angle helix of curved rusty tiles threaded on a rod),
## gradientpillar (glossy rainbow tube emerging from a rough black-lava base),
## burst (radial spike supernova — thousands of spikes into a soft halo),
## lumicanopy (giant glowing mushroom canopy radiating light-strands across its underside),
## bioreactor (The Living / EcoLogicStudio white triangulated-lattice algae photobioreactor),
## netcave (Ernesto Neto draped overhead crochet net-cave anchored to dark floor clumps),
## pigment (Anish Kapoor / Wolfgang Laib pure matte pigment cone + loose-powder skirt),
## colorfield (Emmanuelle Moureaux suspended rainbow cube-grid volume),
## reedbed (bamboo thicket of tall thin poles rising from a green grass pad),
## dotgourd (Yayoi Kusama dotted ribbed pumpkin — polka-dot gourd with a stem),
## strutfield (crossing timber struts on small base plates — constructive lattice),
## horngarden (playful pop-coloured megaphone/horn array on thin dark stems),
## fabricarch (Do Ho Suh translucent fabric architecture — sheer ghost-house cluster),
## encrusted (Takuro Kuwata thickly-glazed beaded ceramic — candy-glaze urn on a
## gold foot, kairagi beads + molten drips + a stone bursting the crawled glaze),
## explodedshed (Cornelia Parker "Cold Dark Matter: An Exploded View" — a garden
## shed's charred debris frozen mid-blast in a radial cloud around a glowing bulb),
## spider (Louise Bourgeois "Maman" — a monumental arachnid arched high on eight
## spindly bronze legs, a slung segmented body, and a wire-cage marble egg sac),
## balloondog (Jeff Koons mirror-chrome balloon dog — one continuous over-inflated
## party balloon twisted into a standing dog of overlapping bulging capsule
## segments and squashed pinch knots, in glossy saturated coloured chrome),
## mobile (Alexander Calder hanging mobile — a top suspension ring drops to a bar
## that straddles the centre, each wing feeding a recursive cantilever cascade of
## thin arced black wires balanced like scales, hung with flat biomorphic plates
## in the primary palette that descend wide and tall and clear of the floor),
## pierced (Barbara Hepworth pierced-and-strung carved form — a biomorphic ovoid
## with a fused belly swell and foot, bored front-to-back by CSG booleans into a
## large strung opening + a small crown eye, two baked shells giving a pale
## painted interior behind the carved rim, a fanned drooping cream harp of strings
## across the big mouth, and thin pale rims flush at each hole mouth),
## lipstick (Claes Oldenburg & Coosje van Bruggen "Lipstick (Ascending) on
## Caterpillar Tracks", Yale 1969 — monumental pop: a glossy red waxy bullet
## ascends on a smooth slant-cut ogive out of a banded gold tube, the whole
## glamour perched on a brutal pair of military stadium-loop caterpillar treads
## with road wheels, end sprockets, a belt band, and a riveted deck),
## flavin (Dan Flavin fluorescent-tube light composition — a "monument to
## Tatlin" stepped skyline of unshaded glowing vertical tubes set into a dimmed
## matte corner, each tube throwing one tight saturated OmniLight so its colour
## washes the two walls; the coloured light on the corner IS the work),
## spiraljetty (Robert Smithson "Spiral Jetty", 1970 — a land-art earthwork: a
## flat counterclockwise basalt-and-earth coil read from above, a low open
## spiral causeway raised just over the rose-red Great Salt Lake, salt-crusted),
## lewitt (Sol LeWitt modular open-cube structure — an n³ lattice of OPEN cubes
## built from shared unique edges as thin white square-section struts with
## solid joint cubelets; the seed picks the specimen: full lattice, single-layer
## floor grid, stepped ziggurat, or an incomplete cube with one corner opened).

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Form")
## cast | twist | accumulation | web | assemblage | bio | apparatus | organ
## | botanical | drape | totem | judd | vitrine | mesh | earthwork
## | vessel | column | lumenarch | threadfield | glowmound | blockfield
## | lattice | spiralstack | gradientpillar | burst | lumicanopy | bioreactor
## | netcave | pigment | colorfield | reedbed | dotgourd | strutfield | horngarden
## | fabricarch | encrusted | explodedshed | spider | balloondog | mobile
## | pierced | lipstick | flavin | spiraljetty | lewitt
@export var mode: String = "cast"
@export var sculpt_height: float = 1.6
@export var sculpt_width: float = 1.0
## Stack count / twist segments / assemblage pieces / bio lobes.
@export var complexity: int = 6
## MultiMesh unit count for accumulation and web modes.
@export var unit_count: int = 220
## Deterministic seed — same seed always yields the same form.
@export var seed: int = 7

@export_group("Material")
## Primary colour (raw-material / pearl / membrane register).
@export var color_a: Color = Color(0.80, 0.80, 0.78)
## Secondary colour (steel / strand / plinth register).
@export var color_b: Color = Color(0.55, 0.57, 0.60)
## Accent / emissive (pop-artificial / node / sheen register).
@export var accent: Color = Color(0.95, 0.45, 0.15)
@export var metallic_amt: float = 0.2
@export var rough_amt: float = 0.7
## Add a low emissive glow to accent-coloured elements.
@export var emissive: bool = false

# ── State ─────────────────────────────────────────────────────────────

var _built: bool = false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_read_metadata_overrides()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for c in get_children():
			remove_child(c)
			c.queue_free()
		_built = false
		_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_mode"):
		mode = str(get_meta("config_mode")).to_lower().strip_edges()
	if has_meta("config_sculpt_height"):
		sculpt_height = float(str(get_meta("config_sculpt_height")))
	if has_meta("config_sculpt_width"):
		sculpt_width = float(str(get_meta("config_sculpt_width")))
	if has_meta("config_complexity"):
		complexity = int(str(get_meta("config_complexity")))
	if has_meta("config_unit_count"):
		unit_count = int(str(get_meta("config_unit_count")))
	if has_meta("config_seed"):
		seed = int(str(get_meta("config_seed")))
	if has_meta("config_color_a"):
		color_a = _parse_color(str(get_meta("config_color_a")), color_a)
	if has_meta("config_color_b"):
		color_b = _parse_color(str(get_meta("config_color_b")), color_b)
	if has_meta("config_accent"):
		accent = _parse_color(str(get_meta("config_accent")), accent)
	if has_meta("config_metallic_amt"):
		metallic_amt = float(str(get_meta("config_metallic_amt")))
	if has_meta("config_rough_amt"):
		rough_amt = float(str(get_meta("config_rough_amt")))
	if has_meta("config_emissive"):
		emissive = str(get_meta("config_emissive")).to_lower() in ["true", "1", "yes", "on"]


func _parse_color(raw: String, fallback: Color) -> Color:
	var parts := raw.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	return fallback


# ── Build dispatch ─────────────────────────────────────────────────────

func _build() -> void:
	_built = true
	_rng.seed = seed
	match mode:
		"cast":
			_build_cast()
		"twist":
			_build_twist()
		"accumulation":
			_build_accumulation()
		"web":
			_build_web()
		"assemblage":
			_build_assemblage()
		"bio":
			_build_bio()
		"apparatus":
			_build_apparatus()
		"organ":
			_build_organ()
		"botanical":
			_build_botanical()
		"drape":
			_build_drape()
		"totem":
			_build_totem()
		"judd":
			_build_judd()
		"vitrine":
			_build_vitrine()
		"mesh":
			_build_mesh()
		"earthwork":
			_build_earthwork()
		"vessel":
			_build_vessel()
		"column":
			_build_column()
		"lumenarch":
			_build_lumenarch()
		"threadfield":
			_build_threadfield()
		"glowmound":
			_build_glowmound()
		"blockfield":
			_build_blockfield()
		"lattice":
			_build_lattice()
		"spiralstack":
			_build_spiralstack()
		"gradientpillar":
			_build_gradientpillar()
		"burst":
			_build_burst()
		"lumicanopy":
			_build_lumicanopy()
		"bioreactor":
			_build_bioreactor()
		"netcave":
			_build_netcave()
		"pigment":
			_build_pigment()
		"colorfield":
			_build_colorfield()
		"reedbed":
			_build_reedbed()
		"dotgourd":
			_build_dotgourd()
		"strutfield":
			_build_strutfield()
		"horngarden":
			_build_horngarden()
		"fabricarch":
			_build_fabricarch()
		"encrusted":
			_build_encrusted()
		"explodedshed":
			_build_explodedshed()
		"spider":
			_build_spider()
		"balloondog":
			_build_balloondog()
		"mobile":
			_build_mobile()
		"pierced":
			_build_pierced()
		"lipstick":
			_build_lipstick()
		"flavin":
			_build_flavin()
		"spiraljetty":
			_build_spiraljetty()
		"lewitt":
			_build_lewitt()
		_:
			# Unknown mode falls back to the cast vocabulary.
			_build_cast()


# ── Material helpers ───────────────────────────────────────────────────

func _make_mat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	if c.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


func _make_emissive_mat(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.4
	m.metallic = 0.0
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m


# ── Material archetypes (contradictory physical registers) ─────────────
# Used by the apparatus / organ "contradiction" modes. Each returns a
# strongly distinct register so a single object can hold opposing
# materialities at once — hard mirror-metal vs brittle glass vs heavy
# matte mass vs soft translucent membrane vs immaterial glow.

# Hard mirror-metal — a polished chrome rod/dial/nozzle.
func _mat_chrome() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.80, 0.82, 0.85)
	m.metallic = 1.0
	m.roughness = 0.06
	return m


# Transparent brittle glass — a seated bead/dome you can see through.
func _mat_glass(tint: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(tint.r, tint.g, tint.b, 0.26)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.03
	m.metallic = 0.0
	return m


# Heavy matte concrete — the dense opaque core mass.
func _mat_concrete(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.96
	m.metallic = 0.0
	return m


# Soft warm translucent membrane — wax/flesh that light sinks into.
func _mat_wax(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, 0.88)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.3
	m.metallic = 0.0
	return m


# Soft dark rubber — matte non-reflective gasket/grommet.
func _mat_rubber(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c.darkened(0.5)
	m.roughness = 0.92
	m.metallic = 0.0
	return m


# A small box helper that adds a MeshInstance3D child.
func _add_box(nm: String, size: Vector3, pos: Vector3, rot: Vector3,
		mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	add_child(mi)
	return mi


# ── Mode: CAST (Rachel Whiteread — negative space made solid) ──────────
# A column of rough cuboids of varying size, each slightly offset/rotated,
# stacked to sculpt_height. Matte plaster/concrete. Reads as the solidified
# gaps between absent furniture.

func _build_cast() -> void:
	var plaster := _make_mat(color_a, 0.92, 0.0)
	var n: int = maxi(2, complexity)
	var seg_h: float = sculpt_height / float(n)
	var y: float = 0.0
	for i in range(n):
		# Each block tapers a little toward the top of the column.
		var t: float = float(i) / float(maxi(1, n - 1))
		var base_w: float = sculpt_width * lerpf(1.0, 0.55, t)
		var bw: float = base_w * _rng.randf_range(0.82, 1.0)
		var bd: float = base_w * _rng.randf_range(0.82, 1.0)
		var bh: float = seg_h * _rng.randf_range(0.85, 1.05)
		var off_x: float = _rng.randf_range(-1.0, 1.0) * base_w * 0.10
		var off_z: float = _rng.randf_range(-1.0, 1.0) * base_w * 0.10
		var yaw: float = _rng.randf_range(-1.0, 1.0) * deg_to_rad(7.0)
		_add_box("Cast%d" % i,
			Vector3(bw, bh, bd),
			Vector3(off_x, y + bh * 0.5, off_z),
			Vector3(0, yaw, 0),
			plaster)
		y += bh


# ── Mode: TWIST (Monika Sosnowska — bent steel) ────────────────────────
# A vertical box-frame lattice of `complexity` stacked segments; each
# segment = 4 corner posts + a top rung ring, rotated progressively about Y
# (cumulative ~120-220 deg) and leaned slightly so the tower warps.

func _build_twist() -> void:
	var steel := _make_mat(color_b, 0.35, maxf(metallic_amt, 0.7))
	var n: int = maxi(2, complexity)
	var seg_h: float = sculpt_height / float(n)
	var half: float = sculpt_width * 0.5
	var post_t: float = sculpt_width * 0.06            # post thickness
	var total_twist: float = deg_to_rad(_rng.randf_range(120.0, 220.0))

	var prev_offset := Vector2(0.0, 0.0)
	for i in range(n):
		var t0: float = float(i) / float(n)
		var twist: float = total_twist * t0
		var seg := Node3D.new()
		seg.name = "TwistSeg%d" % i
		# Lean accumulates so the tower warps off-axis.
		var lean_x: float = sin(twist) * sculpt_width * 0.06 + prev_offset.x
		var lean_z: float = cos(twist) * sculpt_width * 0.04 + prev_offset.y
		lean_x += _rng.randf_range(-1.0, 1.0) * sculpt_width * 0.02
		lean_z += _rng.randf_range(-1.0, 1.0) * sculpt_width * 0.02
		prev_offset = Vector2(lean_x, lean_z) * 0.4
		seg.position = Vector3(lean_x, seg_h * i, lean_z)
		seg.rotation = Vector3(0, twist, 0)
		add_child(seg)

		# 4 corner posts spanning this segment's height.
		for cx in [half, -half]:
			for cz in [half, -half]:
				var post := MeshInstance3D.new()
				post.name = "Post"
				var pm := BoxMesh.new()
				pm.size = Vector3(post_t, seg_h * 1.02, post_t)
				post.mesh = pm
				post.material_override = steel
				post.position = Vector3(cx, seg_h * 0.5, cz)
				seg.add_child(post)

		# Top rung ring — 4 thin cylinders framing the top of the segment.
		var ring_y: float = seg_h
		_add_twist_rung(seg, steel, Vector3(0, ring_y, half),
			Vector3(0, 0, deg_to_rad(90.0)), sculpt_width, post_t)
		_add_twist_rung(seg, steel, Vector3(0, ring_y, -half),
			Vector3(0, 0, deg_to_rad(90.0)), sculpt_width, post_t)
		_add_twist_rung(seg, steel, Vector3(half, ring_y, 0),
			Vector3(deg_to_rad(90.0), 0, 0), sculpt_width, post_t)
		_add_twist_rung(seg, steel, Vector3(-half, ring_y, 0),
			Vector3(deg_to_rad(90.0), 0, 0), sculpt_width, post_t)


func _add_twist_rung(parent: Node3D, mat: StandardMaterial3D, pos: Vector3,
		rot: Vector3, length: float, thick: float) -> void:
	var rung := MeshInstance3D.new()
	rung.name = "Rung"
	var cm := CylinderMesh.new()
	cm.top_radius = thick * 0.45
	cm.bottom_radius = thick * 0.45
	cm.height = length
	rung.mesh = cm
	rung.material_override = mat
	rung.position = pos
	rung.rotation = rot
	parent.add_child(rung)


# ── Mode: ACCUMULATION (Tara Donovan — found unit → landscape) ─────────
# A MultiMeshInstance3D of `unit_count` small identical units distributed
# over a hemisphere/mound so they teem into a landscape. Pale, pearly,
# slightly translucent.

func _build_accumulation() -> void:
	var n: int = maxi(8, unit_count)
	var radius: float = sculpt_width * 0.5
	var dome_h: float = sculpt_height

	# The repeated unit: a short open "cup" cylinder.
	var unit := CylinderMesh.new()
	unit.top_radius = radius * 0.10
	unit.bottom_radius = radius * 0.065
	unit.height = radius * 0.16

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = unit
	mm.instance_count = n

	for i in range(n):
		# Sample a point in a hemisphere volume, biased toward the surface
		# so the mound reads as a teeming skin rather than a solid blob.
		var dir := Vector3(
			_rng.randf_range(-1.0, 1.0),
			_rng.randf_range(0.05, 1.0),
			_rng.randf_range(-1.0, 1.0)).normalized()
		var r: float = radius * pow(_rng.randf(), 0.33)
		var px: float = dir.x * r
		var pz: float = dir.z * r
		var py: float = dir.y * r * (dome_h / maxf(radius, 0.001))
		py = clampf(py, 0.0, dome_h)

		var basis := Basis()
		# Random orientation + slight outward tilt away from centre.
		basis = basis.rotated(Vector3.UP, _rng.randf_range(0.0, TAU))
		basis = basis.rotated(Vector3.RIGHT, _rng.randf_range(-0.5, 0.5))
		basis = basis.rotated(Vector3.FORWARD, _rng.randf_range(-0.5, 0.5))
		var s: float = _rng.randf_range(0.7, 1.35)
		basis = basis.scaled(Vector3(s, s, s))
		mm.set_instance_transform(i, Transform3D(basis, Vector3(px, py, pz)))

	var mmi := MultiMeshInstance3D.new()
	mmi.name = "AccumulationField"
	mmi.multimesh = mm
	var pearl := _make_mat(Color(color_a.r, color_a.g, color_a.b, 0.85), 0.4, metallic_amt)
	mmi.material_override = pearl
	add_child(mmi)


# ── Mode: WEB (Tomás Saraceno — tensile network) ───────────────────────
# `min(unit_count/12, 18)` node points in a box volume; nodes are small
# emissive spheres (accent), strands are thin cylinders connecting each node
# to its 1-2 nearest neighbours. Airborne cosmos.

func _build_web() -> void:
	var node_n: int = clampi(int(unit_count / 12), 4, 18)
	var hw: float = sculpt_width * 0.5
	var hd: float = sculpt_width * 0.5

	# Scatter node positions in the box volume.
	var pts: Array[Vector3] = []
	for i in range(node_n):
		pts.append(Vector3(
			_rng.randf_range(-hw, hw),
			_rng.randf_range(sculpt_height * 0.08, sculpt_height),
			_rng.randf_range(-hd, hd)))

	# Node material (emissive accent) + node spheres.
	var node_mat: StandardMaterial3D
	if emissive:
		node_mat = _make_emissive_mat(accent, 1.4)
	else:
		node_mat = _make_emissive_mat(accent, 0.6)
	var node_r: float = sculpt_width * 0.035
	for i in range(pts.size()):
		var sph := MeshInstance3D.new()
		sph.name = "WebNode%d" % i
		var sm := SphereMesh.new()
		sm.radius = node_r
		sm.height = node_r * 2.0
		sph.mesh = sm
		sph.material_override = node_mat
		sph.position = pts[i]
		add_child(sph)

	# Strand material (dark thin) + connect each node to nearest neighbours.
	var strand_mat := _make_mat(color_b, 0.5, metallic_amt)
	var made := {}   # de-dupe edges by sorted "a-b" key
	for i in range(pts.size()):
		# Find the 1-2 nearest other nodes.
		var order: Array = []
		for j in range(pts.size()):
			if j == i:
				continue
			order.append({"j": j, "d": pts[i].distance_to(pts[j])})
		order.sort_custom(func(a, b): return a["d"] < b["d"])
		var links: int = mini(2, order.size())
		for k in range(links):
			var j: int = order[k]["j"]
			var a: int = mini(i, j)
			var b: int = maxi(i, j)
			var key := "%d-%d" % [a, b]
			if made.has(key):
				continue
			made[key] = true
			_add_strand(pts[a], pts[b], strand_mat, node_r * 0.45)


# Draw a thin cylinder spanning two points (oriented like a pipe between them).
func _add_strand(p0: Vector3, p1: Vector3, mat: StandardMaterial3D,
		thick: float) -> void:
	var diff := p1 - p0
	var length: float = diff.length()
	if length < 0.0001:
		return
	var strand := MeshInstance3D.new()
	strand.name = "Strand"
	var cm := CylinderMesh.new()
	cm.top_radius = thick
	cm.bottom_radius = thick
	cm.height = length
	strand.mesh = cm
	strand.material_override = mat
	strand.position = (p0 + p1) * 0.5
	# Orient the cylinder's +Y axis along the strand direction.
	var dir := diff.normalized()
	var up := Vector3.UP
	if absf(dir.dot(up)) > 0.999:
		up = Vector3.RIGHT
	var axis := up.cross(dir).normalized()
	var angle: float = acos(clampf(up.dot(dir), -1.0, 1.0))
	if axis.length() > 0.0001:
		strand.basis = Basis(axis, angle)
	add_child(strand)


# ── Mode: ASSEMBLAGE (Isa Genzken / Thomas Hirschhorn — pop vernacular) ─
# A base plinth topped by a chaotic leaning stack of `complexity` found
# fragments (boxes, rods, a tilted foil plane, tape-like bands) in clashing
# pop colours, jittered so it reads as precarious assemblage.

func _build_assemblage() -> void:
	# Base plinth.
	var plinth_h: float = sculpt_height * 0.18
	var plinth_mat := _make_mat(color_b, rough_amt, metallic_amt)
	_add_box("Plinth",
		Vector3(sculpt_width * 0.7, plinth_h, sculpt_width * 0.7),
		Vector3(0, plinth_h * 0.5, 0),
		Vector3.ZERO,
		plinth_mat)

	# A small palette of clashing saturated pop hues derived from accent.
	var pop: Array[Color] = []
	for h in [0.0, 0.5, 0.14, 0.66, 0.92]:
		var c := Color.from_hsv(fposmod(accent.h + h, 1.0), 0.85, 0.95)
		pop.append(c)

	var n: int = maxi(2, complexity)
	var stack_top: float = plinth_h
	var span: float = sculpt_height - plinth_h
	var seg: float = span / float(n)
	for i in range(n):
		var col: Color = pop[i % pop.size()]
		var mat := _make_mat(col, _rng.randf_range(0.3, 0.8), _rng.randf_range(0.0, 0.4))
		var jx: float = _rng.randf_range(-1.0, 1.0) * sculpt_width * 0.18
		var jz: float = _rng.randf_range(-1.0, 1.0) * sculpt_width * 0.18
		var tilt := Vector3(
			_rng.randf_range(-1.0, 1.0) * deg_to_rad(22.0),
			_rng.randf_range(0.0, TAU),
			_rng.randf_range(-1.0, 1.0) * deg_to_rad(22.0))
		var y: float = stack_top + seg * 0.5
		var pick: int = i % 3
		if pick == 0:
			# Chunky box fragment.
			var bw: float = sculpt_width * _rng.randf_range(0.28, 0.55)
			var bh: float = seg * _rng.randf_range(0.7, 1.1)
			var bd: float = sculpt_width * _rng.randf_range(0.18, 0.4)
			_add_box("Frag%d" % i, Vector3(bw, bh, bd),
				Vector3(jx, y, jz), tilt, mat)
		elif pick == 1:
			# Rod fragment.
			var rod := MeshInstance3D.new()
			rod.name = "Rod%d" % i
			var rm := CylinderMesh.new()
			rm.top_radius = sculpt_width * 0.04
			rm.bottom_radius = sculpt_width * 0.04
			rm.height = seg * _rng.randf_range(1.4, 2.2)
			rod.mesh = rm
			rod.material_override = mat
			rod.position = Vector3(jx, y, jz)
			rod.rotation = tilt
			add_child(rod)
		else:
			# Tilted thin plane (mirror / foil) — light metallic.
			var foil_mat := _make_mat(
				col.lerp(Color(0.9, 0.9, 0.95), 0.5), 0.15, 0.85)
			_add_box("Foil%d" % i,
				Vector3(sculpt_width * _rng.randf_range(0.35, 0.6),
					seg * _rng.randf_range(0.9, 1.4), sculpt_width * 0.02),
				Vector3(jx, y, jz), tilt, foil_mat)
		stack_top += seg

	# 1-2 tape-like bands wrapping the stack at jittered heights.
	var bands: int = 1 + (seed % 2)
	for bi in range(bands):
		var band_col: Color = pop[(seed + bi) % pop.size()]
		var band_mat := _make_mat(band_col, 0.5, 0.0)
		var by: float = plinth_h + span * _rng.randf_range(0.25, 0.85)
		_add_box("Tape%d" % bi,
			Vector3(sculpt_width * 0.62, span * 0.10, sculpt_width * 0.62),
			Vector3(_rng.randf_range(-0.05, 0.05), by, _rng.randf_range(-0.05, 0.05)),
			Vector3(0, _rng.randf_range(0.0, TAU), deg_to_rad(_rng.randf_range(-12.0, 12.0))),
			band_mat)


# ── Mode: BIO (Anicka Yi / Pierre Huyghe — machine ecology) ────────────
# An organic cluster of `complexity`+4 overlapping ellipsoids growing from a
# small base, sizes/positions jittered into a blobby mass; subtle emissive
# sheen + a few thin curved tendrils. Wet/translucent membrane look.

func _build_bio() -> void:
	var membrane := _make_mat(
		Color(color_a.r, color_a.g, color_a.b, 0.9), 0.25, metallic_amt)
	if emissive:
		membrane.emission_enabled = true
		membrane.emission = accent
		membrane.emission_energy_multiplier = 0.5
	else:
		# Subtle accent sheen even when not "emissive".
		membrane.emission_enabled = true
		membrane.emission = accent
		membrane.emission_energy_multiplier = 0.15

	var n: int = maxi(3, complexity + 4)
	var spread: float = sculpt_width * 0.5
	# Lobes grow upward from a small base, biased toward the lower-mid mass.
	for i in range(n):
		var t: float = float(i) / float(maxi(1, n - 1))
		var lobe := MeshInstance3D.new()
		lobe.name = "Lobe%d" % i
		var sm := SphereMesh.new()
		var base_r: float = spread * lerpf(0.55, 0.28, t)
		sm.radius = base_r
		sm.height = base_r * 2.0
		lobe.mesh = sm
		lobe.material_override = membrane
		# Cluster position: drift outward and upward with jitter.
		var ang: float = _rng.randf_range(0.0, TAU)
		var rad: float = spread * 0.45 * _rng.randf_range(0.0, 1.0) * (0.4 + t)
		var px: float = cos(ang) * rad
		var pz: float = sin(ang) * rad
		var py: float = base_r + sculpt_height * t * _rng.randf_range(0.7, 1.0)
		py = minf(py, sculpt_height - base_r * 0.4)
		lobe.position = Vector3(px, maxf(py, base_r * 0.6), pz)
		# Non-uniform scale gives the wet, swollen ellipsoid read.
		lobe.scale = Vector3(
			_rng.randf_range(0.8, 1.3),
			_rng.randf_range(0.9, 1.5),
			_rng.randf_range(0.8, 1.3))
		add_child(lobe)

	# 2-3 thin curved "tendrils" reaching up out of the mass.
	var tendril_mat := _make_mat(color_b, 0.3, metallic_amt)
	var tcount: int = 2 + (seed % 2)
	for ti in range(tcount):
		var segs: int = 4
		var ang2: float = _rng.randf_range(0.0, TAU)
		var base := Vector3(
			cos(ang2) * spread * 0.3,
			sculpt_height * 0.5,
			sin(ang2) * spread * 0.3)
		var dir := Vector3(
			_rng.randf_range(-0.3, 0.3),
			1.0,
			_rng.randf_range(-0.3, 0.3)).normalized()
		var p_prev := base
		var step: float = (sculpt_height * 0.5) / float(segs)
		for s in range(segs):
			# Curve the tendril by nudging direction each segment.
			dir = (dir + Vector3(
				_rng.randf_range(-0.25, 0.25),
				0.0,
				_rng.randf_range(-0.25, 0.25))).normalized()
			var p_next := p_prev + dir * step
			_add_strand(p_prev, p_next, tendril_mat, spread * 0.018)
			p_prev = p_next


# ── Shared parts for the contradiction modes ───────────────────────────

# A cylinder with independent top/bottom radii (rod, dial, tapered nozzle).
func _add_cyl(nm: String, top_r: float, bot_r: float, height: float,
		pos: Vector3, rot: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var cm := CylinderMesh.new()
	cm.top_radius = top_r
	cm.bottom_radius = bot_r
	cm.height = height
	mi.mesh = cm
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	add_child(mi)
	return mi


# A small sphere (seated bead / glowing nodule / glass dome).
func _add_sphere(nm: String, radius: float, pos: Vector3,
		mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	mi.mesh = sm
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
	return mi


# ── Mode: APPARATUS (heavy machined hybrid — the contradiction object) ──
# A CONCRETE core mass PIERCED by a CHROME rod (sticks out both faces),
# with a GLASS-or-EMISSIVE sphere SEATED half-sunk in a socket recess, and
# 3-4 pseudo-features (dial / port / slot / nozzle / port-row) that imply
# operation without doing anything. ≥3 contradictory, interpenetrating
# materials always present: heavy matte concrete vs hard mirror chrome vs
# brittle transparent glass (or immaterial emissive glow).

func _build_apparatus() -> void:
	_rng.seed = seed
	var concrete := _mat_concrete(color_a)
	var chrome := _mat_chrome()
	var dark := _mat_rubber(color_b)

	# CORE — a concrete rounded mass: a main block fused with a smaller
	# offset block so the silhouette is a strange undecidable lump.
	var core_w: float = sculpt_width
	var core_h: float = sculpt_height * _rng.randf_range(0.5, 0.6)
	var core_d: float = sculpt_width * _rng.randf_range(0.7, 0.95)
	_add_box("Core", Vector3(core_w, core_h, core_d),
		Vector3(0, core_h * 0.5, 0), Vector3.ZERO, concrete)
	# Fused second mass riding on top, shoved off-centre.
	var lump_w: float = core_w * _rng.randf_range(0.45, 0.7)
	var lump_h: float = core_h * _rng.randf_range(0.4, 0.65)
	var lump_d: float = core_d * _rng.randf_range(0.5, 0.8)
	var lump_x: float = _rng.randf_range(-1.0, 1.0) * core_w * 0.22
	var lump_z: float = _rng.randf_range(-1.0, 1.0) * core_d * 0.18
	var top_y: float = core_h + lump_h * 0.5 - lump_h * 0.35   # sink it in a bit
	_add_box("CoreLump", Vector3(lump_w, lump_h, lump_d),
		Vector3(lump_x, top_y, lump_z),
		Vector3(0, _rng.randf_range(-0.3, 0.3), 0), concrete)
	var core_top: float = core_h + lump_h * 0.65

	# PIERCE — a chrome rod passing fully THROUGH the core on a chosen axis,
	# protruding out both opposite faces.
	var rod_r: float = sculpt_width * 0.06
	var pierce_axis: int = _rng.randi_range(0, 1)   # 0 = X (left-right), 1 = Z (front-back)
	var pierce_y: float = core_h * _rng.randf_range(0.4, 0.7)
	if pierce_axis == 0:
		var rod_len_x: float = core_w + sculpt_width * _rng.randf_range(0.5, 0.9)
		_add_cyl("PierceRod", rod_r, rod_r, rod_len_x,
			Vector3(0, pierce_y, _rng.randf_range(-0.15, 0.15) * core_d),
			Vector3(0, 0, deg_to_rad(90.0)), chrome)
	else:
		var rod_len_z: float = core_d + sculpt_width * _rng.randf_range(0.5, 0.9)
		_add_cyl("PierceRod", rod_r, rod_r, rod_len_z,
			Vector3(_rng.randf_range(-0.15, 0.15) * core_w, pierce_y, 0),
			Vector3(deg_to_rad(90.0), 0, 0), chrome)

	# SEAT — a glass/emissive sphere half-embedded in a socket recess on top.
	# Carve a visible socket (dark inset ring box) then sink the bead into it.
	var bead_r: float = sculpt_width * 0.16
	var socket_x: float = _rng.randf_range(-0.18, 0.18) * core_w
	var socket_z: float = _rng.randf_range(-0.18, 0.18) * core_d
	_add_box("Socket", Vector3(bead_r * 2.3, bead_r * 0.5, bead_r * 2.3),
		Vector3(socket_x, core_top - bead_r * 0.1, socket_z), Vector3.ZERO, dark)
	var seat_mat: StandardMaterial3D
	if emissive:
		seat_mat = _make_emissive_mat(accent, 1.8)
	else:
		seat_mat = _mat_glass(accent)
	# Push it partway INTO the core so it is seated, not perched.
	_add_sphere("SeatBead", bead_r,
		Vector3(socket_x, core_top + bead_r * 0.35, socket_z), seat_mat)

	# PSEUDO-FEATURES — pick 3-4 from complexity. They imply operation.
	var feat_n: int = clampi(complexity, 3, 4)
	var face_choices := [Vector3.FORWARD, Vector3.RIGHT, Vector3.LEFT, Vector3.BACK]
	for fi in range(feat_n):
		var which: int = fi % 4
		# A face normal to mount the feature on (front/right/left/back).
		var fn: Vector3 = face_choices[fi % face_choices.size()]
		var fy: float = core_h * _rng.randf_range(0.3, 0.8)
		# Half-extent of the core along this face's normal.
		var half_ext: float = core_w * 0.5 if absf(fn.x) > 0.5 else core_d * 0.5
		var surf: Vector3 = fn * half_ext + Vector3(0, fy, 0)
		match which:
			0:
				# DIAL — short fat chrome cylinder protruding from a face,
				# its axis along the face normal (sunk slightly into the mass).
				var dial_r: float = sculpt_width * 0.11
				var dial_h: float = sculpt_width * 0.07
				var dpos: Vector3 = surf + fn * (dial_h * 0.3)
				var drot := Vector3.ZERO
				if absf(fn.x) > 0.5:
					drot = Vector3(0, 0, deg_to_rad(90.0))
				else:
					drot = Vector3(deg_to_rad(90.0), 0, 0)
				_add_cyl("Dial", dial_r, dial_r * 1.1, dial_h, dpos, drot, chrome)
			1:
				# PORT — a small dark recessed inset box on the face.
				var p_sz: float = sculpt_width * 0.13
				_add_box("Port", Vector3(p_sz, p_sz, p_sz * 0.5),
					surf - fn * (p_sz * 0.2),
					Vector3(0, atan2(fn.x, fn.z), 0), dark)
			2:
				# SLOT — a thin dark groove box cut across the face.
				var sl_w: float = sculpt_width * 0.34
				_add_box("Slot", Vector3(sl_w, sculpt_width * 0.045, sculpt_width * 0.09),
					surf - fn * (sculpt_width * 0.02),
					Vector3(0, atan2(fn.x, fn.z), 0), dark)
			3:
				# NOZZLE — a tapered chrome cylinder jutting from the face.
				var noz_h: float = sculpt_width * 0.22
				var npos: Vector3 = surf + fn * (noz_h * 0.4)
				var nrot := Vector3.ZERO
				if absf(fn.x) > 0.5:
					nrot = Vector3(0, 0, deg_to_rad(-90.0) if fn.x > 0 else deg_to_rad(90.0))
				else:
					nrot = Vector3(deg_to_rad(90.0) if fn.z > 0 else deg_to_rad(-90.0), 0, 0)
				_add_cyl("Nozzle", sculpt_width * 0.02, sculpt_width * 0.06,
					noz_h, npos, nrot, chrome)

	# A row of 3 tiny emissive/dark ports along the front upper edge — extra
	# "it does something" signal regardless of feature count.
	var row_mat: StandardMaterial3D = _make_emissive_mat(accent, 1.2) if emissive else dark
	var row_y: float = core_h * 0.85
	var row_z: float = core_d * 0.5 + sculpt_width * 0.005
	for pi in range(3):
		var px: float = (float(pi) - 1.0) * sculpt_width * 0.16
		_add_box("MicroPort%d" % pi,
			Vector3(sculpt_width * 0.045, sculpt_width * 0.045, sculpt_width * 0.03),
			Vector3(px, row_y, row_z), Vector3.ZERO, row_mat)


# ── Mode: ORGAN (bio-machine hybrid — the contradiction object) ────────
# A soft WAX MEMBRANE mass (overlapping non-uniform spheres) PIERCED by a
# cold CHROME tube, with an EMISSIVE nodule half-sunk in the flesh and a
# small GLASS dome seated on it, plus 2-3 pseudo-features (valve / nozzle /
# vent) that imply biological-mechanical operation. ≥3 contradictory,
# interpenetrating materials always present: warm translucent wax-membrane
# vs cold hard chrome vs immaterial emissive glow (+ brittle glass bead).

func _build_organ() -> void:
	_rng.seed = seed
	var membrane := _mat_wax(color_a)
	var chrome := _mat_chrome()
	var dark := _mat_rubber(color_b)

	# CORE — soft wax-membrane mass: 3-5 overlapping, non-uniformly scaled
	# spheres clustering up from the floor.
	var n: int = clampi(complexity, 3, 5)
	var spread: float = sculpt_width * 0.5
	var blob_centres: Array[Vector3] = []
	for i in range(n):
		var t: float = float(i) / float(maxi(1, n - 1))
		var base_r: float = spread * lerpf(0.6, 0.34, t)
		var ang: float = _rng.randf_range(0.0, TAU)
		var rad: float = spread * 0.4 * _rng.randf_range(0.0, 1.0) * (0.35 + t)
		var px: float = cos(ang) * rad
		var pz: float = sin(ang) * rad
		var py: float = base_r + sculpt_height * t * _rng.randf_range(0.6, 0.95)
		py = minf(py, sculpt_height - base_r * 0.4)
		var cpos := Vector3(px, maxf(py, base_r * 0.65), pz)
		blob_centres.append(cpos)
		var lobe := _add_sphere("Membrane%d" % i, base_r, cpos, membrane)
		lobe.scale = Vector3(
			_rng.randf_range(0.85, 1.35),
			_rng.randf_range(0.9, 1.5),
			_rng.randf_range(0.85, 1.35))

	# ARMATURE — a chrome tube that PIERCES the membrane (enters one blob,
	# exits elsewhere): contradiction of cold metal driven through warm flesh.
	var enter: Vector3 = blob_centres[0]
	var exit: Vector3 = blob_centres[blob_centres.size() - 1]
	# Extend the endpoints outward so the tube clearly stabs out both sides.
	var dir := (exit - enter)
	if dir.length() < 0.001:
		dir = Vector3(1, 0.4, 0.3)
	dir = dir.normalized()
	var p_a: Vector3 = enter - dir * spread * 0.7
	var p_b: Vector3 = exit + dir * spread * 0.7
	_add_strand(p_a, p_b, chrome, sculpt_width * 0.045)

	# GLOW — an emissive nodule half-sunk into the membrane (glowing port).
	var glow_mat := _make_emissive_mat(accent, 2.0 if emissive else 1.1)
	var glow_host: Vector3 = blob_centres[_rng.randi_range(0, blob_centres.size() - 1)]
	var glow_dir := Vector3(_rng.randf_range(-1, 1), _rng.randf_range(0.2, 1.0),
		_rng.randf_range(-1, 1)).normalized()
	var glow_r: float = spread * 0.16
	_add_sphere("GlowNodule", glow_r,
		glow_host + glow_dir * (spread * 0.28), glow_mat)

	# GLASS — a small brittle glass dome seated on the membrane.
	var glass_host: Vector3 = blob_centres[(_rng.randi_range(0, blob_centres.size() - 1))]
	var glass_dir := Vector3(_rng.randf_range(-1, 1), _rng.randf_range(0.4, 1.0),
		_rng.randf_range(-1, 1)).normalized()
	_add_sphere("GlassDome", spread * 0.12,
		glass_host + glass_dir * (spread * 0.3), _mat_glass(color_b))

	# PSEUDO-FEATURES — 2-3 implying bio-mechanical operation.
	var feat_n: int = clampi(complexity - 1, 2, 3)
	for fi in range(feat_n):
		var host: Vector3 = blob_centres[fi % blob_centres.size()]
		var out_dir := Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-0.2, 0.9),
			_rng.randf_range(-1, 1)).normalized()
		match fi % 3:
			0:
				# VALVE — a chrome torus ring flush on the membrane surface.
				var valve := MeshInstance3D.new()
				valve.name = "Valve"
				var tm := TorusMesh.new()
				tm.inner_radius = spread * 0.07
				tm.outer_radius = spread * 0.12
				valve.mesh = tm
				valve.material_override = chrome
				valve.position = host + out_dir * (spread * 0.32)
				# Face the ring outward along the surface normal.
				valve.look_at_from_position(valve.position, valve.position + out_dir, Vector3.UP)
				valve.rotate_object_local(Vector3.RIGHT, deg_to_rad(90.0))
				add_child(valve)
			1:
				# NOZZLE / spout — tapered chrome cylinder protruding outward.
				var noz_h: float = spread * 0.34
				var npos: Vector3 = host + out_dir * (spread * 0.3 + noz_h * 0.4)
				var noz := _add_cyl("Spout", spread * 0.02, spread * 0.06,
					noz_h, npos, Vector3.ZERO, chrome)
				noz.look_at_from_position(npos, npos + out_dir, Vector3.UP)
				noz.rotate_object_local(Vector3.RIGHT, deg_to_rad(90.0))
			2:
				# VENT — a small recessed dark slot sunk into the membrane.
				var vpos: Vector3 = host + out_dir * (spread * 0.26)
				var vent := _add_box("Vent",
					Vector3(spread * 0.22, spread * 0.05, spread * 0.1),
					vpos, Vector3.ZERO, dark)
				vent.look_at_from_position(vpos, vpos + out_dir, Vector3.UP)


# ── Mode: BOTANICAL (Kapwani Kiwanga / Marc Quinn — bronze-cast flower) ─
# A soft organic FORM rendered in hard cast BRONZE: a small dark base, a
# vertical bronze stem, a radial bloom of petals around an accent core, and
# 2-3 large bronze leaves low on the stem. The contradiction of register is
# the point — nature (a flower) frozen in metal (cast bronze).

func _build_botanical() -> void:
	_rng.seed = seed
	var bronze := _make_mat(color_b, 0.42, 0.9)
	var petal_mat := _make_mat(color_a, 0.45, 0.25)          # the flower hue
	var core_mat := _make_mat(accent, 0.4, 0.3)
	if emissive:
		core_mat = _make_emissive_mat(accent, 1.2)

	# BASE — a low dark disc the stem rises from.
	var base_r: float = sculpt_width * 0.32
	var base_h: float = sculpt_height * 0.05
	_add_cyl("Base", base_r, base_r * 1.15, base_h,
		Vector3(0, base_h * 0.5, 0), Vector3.ZERO, _mat_concrete(color_b.darkened(0.4)))

	# STEM — a bronze cylinder rising ~70% of the height, leaning a touch.
	var stem_h: float = sculpt_height * 0.7
	var stem_r: float = sculpt_width * 0.045
	var lean: float = _rng.randf_range(-1.0, 1.0) * deg_to_rad(5.0)
	var stem_top: float = base_h + stem_h
	_add_cyl("Stem", stem_r * 0.85, stem_r, stem_h,
		Vector3(0, base_h + stem_h * 0.5, 0), Vector3(lean, 0, lean * 0.5), bronze)

	# BLOOM — complexity+4 petals fanned radially around an accent core.
	var bloom_y: float = stem_top + sculpt_width * 0.04
	var petals: int = maxi(5, complexity + 4)
	var petal_len: float = sculpt_width * 0.42
	for i in range(petals):
		var ang: float = (TAU * float(i) / float(petals)) + _rng.randf_range(-0.08, 0.08)
		# Petals tilt outward AND upward (a cupped bloom), jittered per specimen.
		var out_tilt: float = deg_to_rad(_rng.randf_range(38.0, 58.0))
		var petal := MeshInstance3D.new()
		petal.name = "Petal%d" % i
		var psm := SphereMesh.new()
		psm.radius = 0.5
		psm.height = 1.0
		petal.mesh = psm
		petal.material_override = petal_mat
		# Flattened, elongated petal shape.
		petal.scale = Vector3(0.4, 0.12, 0.9) * petal_len
		# Orient: yaw to the radial angle, then pitch the tip up-and-out.
		petal.rotation = Vector3(out_tilt, ang, 0)
		# Push the petal out from centre along its radial direction.
		var rdir := Vector3(sin(ang), 0, cos(ang))
		petal.position = Vector3(0, bloom_y, 0) \
			+ rdir * (petal_len * 0.45) \
			+ Vector3(0, sin(out_tilt) * petal_len * 0.35, 0)
		add_child(petal)
	# CORE — a small bright nodule at the bloom centre.
	_add_sphere("BloomCore", sculpt_width * 0.1,
		Vector3(0, bloom_y + sculpt_width * 0.04, 0), core_mat)

	# LEAVES — 2-3 large bronze leaves lower on the stem, angled out.
	var leaves: int = 2 + (seed % 2)
	for li in range(leaves):
		var lang: float = TAU * float(li) / float(leaves) + _rng.randf_range(-0.3, 0.3)
		var ly: float = base_h + stem_h * _rng.randf_range(0.28, 0.5)
		var leaf := MeshInstance3D.new()
		leaf.name = "Leaf%d" % li
		var lsm := SphereMesh.new()
		lsm.radius = 0.5
		lsm.height = 1.0
		leaf.mesh = lsm
		leaf.material_override = bronze
		var leaf_len: float = sculpt_width * _rng.randf_range(0.32, 0.46)
		leaf.scale = Vector3(0.28, 0.08, 1.0) * leaf_len
		# Angle the leaf outward and gently downward.
		var droop: float = deg_to_rad(_rng.randf_range(-18.0, 8.0))
		leaf.rotation = Vector3(droop, lang, 0)
		var ldir := Vector3(sin(lang), 0, cos(lang))
		leaf.position = Vector3(0, ly, 0) + ldir * (leaf_len * 0.5)
		add_child(leaf)


# ── Mode: DRAPE (Mike Kelley / Jessica Jackson Hutchins — slumped cloth) ─
# A sagging cast-cloth mass draped over turned furniture legs, studded with
# coloured bulbs and trailing a striped flag scrap. Contradictory materials
# integrated: soft matte cloth + hard turned legs poking up through it +
# glowing electric bulbs + a flag fragment. Pseudo-domestic, abstract, slumped.

func _build_drape() -> void:
	_rng.seed = seed
	var cloth := _make_mat(Color(0.86, 0.84, 0.80), 0.9, 0.0)   # off-white matte

	# LEGS — 3 bulbous turned furniture legs standing on the floor. Each leg
	# is a stack of cylinders of varying radius so it reads as a lathe-turned
	# table leg. The cloth body later drapes across their tops at leg_top_y.
	var leg_top_y: float = sculpt_height * 0.55
	var leg_span: float = sculpt_width * 0.34
	for li in range(3):
		var lang: float = TAU * float(li) / 3.0 + _rng.randf_range(-0.15, 0.15)
		var lx: float = cos(lang) * leg_span
		var lz: float = sin(lang) * leg_span
		var segs: int = _rng.randi_range(3, 4)
		var y: float = 0.0
		var seg_h: float = leg_top_y / float(segs)
		for s in range(segs):
			# Bulbous profile: wider in the middle of each turned segment.
			var t: float = float(s) / float(maxi(1, segs - 1))
			var bulb: float = 1.0 - absf(t - 0.5) * 1.2
			var seg_r: float = sculpt_width * (0.05 + 0.045 * bulb) \
				* _rng.randf_range(0.85, 1.1)
			var top_r: float = seg_r * _rng.randf_range(0.7, 0.95)
			_add_cyl("Leg%d_%d" % [li, s], top_r, seg_r, seg_h,
				Vector3(lx, y + seg_h * 0.5, lz), Vector3.ZERO, cloth)
			y += seg_h

	# CLOTH BODY — 3 long low boxes draped across the leg-tops, drooping and
	# tilted at the ends so the mass reads as slumped and precarious.
	var span_w: float = sculpt_width * 1.05
	var body_y: float = leg_top_y
	for ci in range(3):
		var frac: float = (float(ci) - 1.0)            # -1, 0, +1
		var droop: float = absf(frac) * sculpt_height * 0.07   # ends sag lower
		var bx: float = frac * span_w * 0.28 + _rng.randf_range(-0.03, 0.03)
		var bz: float = _rng.randf_range(-1.0, 1.0) * sculpt_width * 0.06
		var tilt := Vector3(
			_rng.randf_range(-1.0, 1.0) * deg_to_rad(6.0),
			_rng.randf_range(-1.0, 1.0) * deg_to_rad(8.0),
			frac * deg_to_rad(9.0) + _rng.randf_range(-3.0, 3.0))
		_add_box("Cloth%d" % ci,
			Vector3(span_w * _rng.randf_range(0.5, 0.62),
				sculpt_height * 0.1, sculpt_width * _rng.randf_range(0.5, 0.66)),
			Vector3(bx, body_y - droop, bz), tilt, cloth)

	# BULBS — 4-6 small glowing bulbs embedded on the cloth, cycling R/G/B
	# from accent + two derived hues.
	var bulb_hues: Array[Color] = [
		accent,
		Color.from_hsv(fposmod(accent.h + 0.33, 1.0), 0.85, 1.0),
		Color.from_hsv(fposmod(accent.h + 0.66, 1.0), 0.85, 1.0)]
	var bulbs: int = _rng.randi_range(4, 6)
	for bi in range(bulbs):
		var hue: Color = bulb_hues[bi % bulb_hues.size()]
		var bmat := _make_emissive_mat(hue, 2.2 if emissive else 1.4)
		var bxp: float = _rng.randf_range(-1.0, 1.0) * span_w * 0.42
		var bzp: float = _rng.randf_range(-1.0, 1.0) * sculpt_width * 0.26
		var byp: float = body_y + sculpt_height * 0.05 + _rng.randf_range(-0.02, 0.03)
		_add_sphere("Bulb%d" % bi, sculpt_width * 0.04,
			Vector3(bxp, byp, bzp), bmat)

	# FLAG — a small striped scrap hanging off one end: a white box backing
	# with a few thin alternating red bands laid over it, drooping and tilted.
	var white_mat := _make_mat(Color(0.92, 0.90, 0.86), 0.85, 0.0)
	var red_mat := _make_mat(Color(0.78, 0.12, 0.12), 0.7, 0.0)
	var flag_x: float = span_w * 0.46
	var flag_y: float = body_y - sculpt_height * 0.16
	var flag_w: float = sculpt_width * 0.26
	var flag_h: float = sculpt_height * 0.22
	var flag_tilt := Vector3(0, _rng.randf_range(-0.4, 0.4),
		deg_to_rad(_rng.randf_range(-18.0, -6.0)))
	var flag_root := Node3D.new()
	flag_root.name = "Flag"
	flag_root.position = Vector3(flag_x, flag_y, _rng.randf_range(-0.04, 0.04))
	flag_root.rotation = flag_tilt
	add_child(flag_root)
	var backing := MeshInstance3D.new()
	backing.name = "FlagBacking"
	var bm := BoxMesh.new()
	bm.size = Vector3(flag_w, flag_h, sculpt_width * 0.01)
	backing.mesh = bm
	backing.material_override = white_mat
	flag_root.add_child(backing)
	# 3 thin red stripe bands across the backing.
	var stripes: int = 3
	for si in range(stripes):
		var band := MeshInstance3D.new()
		band.name = "FlagStripe%d" % si
		var band_h: float = flag_h / float(stripes * 2)
		var sbm := BoxMesh.new()
		sbm.size = Vector3(flag_w * 0.98, band_h, sculpt_width * 0.014)
		band.mesh = sbm
		band.material_override = red_mat
		var sy: float = flag_h * 0.5 - band_h * (2.0 * float(si) + 1.0)
		band.position = Vector3(0, sy, 0)
		flag_root.add_child(band)


# ── Mode: TOTEM (Jeffrey Gibson — beaded / fringed ceremonial assemblage) ─
# A SYMMETRIC vertical totem: a stacked-bead spine in cycling saturated
# colours, a radiating colourful feather-fan above it (with mirrored side
# fans), and a dominant cascading RAINBOW FRINGE — a MultiMesh of thin
# vertical strips of varying length hanging down toward the floor, mirrored
# across the width so it reads as a symmetric beaded curtain. Very colourful,
# ceremonial, accumulative.

func _build_totem() -> void:
	_rng.seed = seed

	# SPINE — a vertical stack of small saturated beads up to sculpt_height.
	var beads: int = maxi(5, complexity + 4)
	var bead_h: float = sculpt_height / float(beads)
	var bead_w: float = sculpt_width * 0.22
	var spine_top: float = 0.0
	for i in range(beads):
		var hue: float = fposmod(0.05 + float(i) / float(beads), 1.0)
		var col := Color.from_hsv(hue, 0.85, 0.95)
		var bmat := _make_mat(col, 0.25, 0.15)
		var y: float = bead_h * (float(i) + 0.5)
		var bw: float = bead_w * (1.0 - 0.35 * float(i) / float(beads))   # taper up
		_add_box("Bead%d" % i, Vector3(bw, bead_h * 0.92, bw),
			Vector3(0, y, 0), Vector3.ZERO, bmat)
		spine_top = bead_h * float(i + 1)

	# TOP FAN — 9-13 thin "feather" spikes fanning out in a semicircle above
	# the spine, plus mirrored small side fans left & right (symmetric).
	var feathers: int = _rng.randi_range(9, 13)
	var fan_y: float = spine_top
	var feather_len: float = sculpt_height * 0.3
	for fi in range(feathers):
		var ft: float = float(fi) / float(maxi(1, feathers - 1))    # 0..1
		# Sweep from -80deg to +80deg around vertical (semicircle in XY plane).
		var sweep: float = lerpf(deg_to_rad(-80.0), deg_to_rad(80.0), ft)
		var hue: float = fposmod(float(fi) / float(feathers), 1.0)
		var col := Color.from_hsv(hue, 0.8, 1.0)
		var fmat := _make_mat(col, 0.3, 0.1)
		_add_feather("Feather%d" % fi, feather_len, sculpt_width * 0.02,
			Vector3(0, fan_y, 0), Vector3(0, 0, sweep), fmat)
	# Mirrored small side fans (left & right of the spine), tilted out.
	for side in [-1.0, 1.0]:
		for sj in range(3):
			var st: float = float(sj) / 2.0
			var sweep2: float = lerpf(deg_to_rad(20.0), deg_to_rad(70.0), st) * side
			var hue2: float = fposmod(0.4 + float(sj) / 5.0, 1.0)
			var smat := _make_mat(Color.from_hsv(hue2, 0.8, 1.0), 0.3, 0.1)
			_add_feather("SideFeather%d_%d" % [int(side), sj],
				feather_len * 0.6, sculpt_width * 0.018,
				Vector3(side * bead_w * 0.4, spine_top * 0.78, 0),
				Vector3(0, 0, sweep2), smat)

	# FRINGE — the dominant element: a MultiMesh of unit_count thin vertical
	# strips hanging from the spine/fan area down toward (and pooling on) the
	# floor, varying length + slight x-jitter, RAINBOW per-instance colours,
	# laid symmetrically across the width so it reads as a beaded curtain.
	var n: int = maxi(8, unit_count)
	var strip := BoxMesh.new()
	strip.size = Vector3(0.02, 0.5, 0.01)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = strip
	mm.instance_count = n
	var curtain_w: float = sculpt_width * 0.7
	var hang_y: float = spine_top * 0.9                # strips hang from here
	for i in range(n):
		# Symmetric x: pair up instances mirrored across the centre line.
		var pair: int = i / 2
		var sign_x: float = 1.0 if (i % 2 == 0) else -1.0
		var span_frac: float = float(pair) / float(maxi(1, (n + 1) / 2 - 1))
		var bx: float = sign_x * span_frac * curtain_w * 0.5 \
			+ _rng.randf_range(-1.0, 1.0) * 0.02
		var bz: float = _rng.randf_range(-1.0, 1.0) * sculpt_width * 0.12
		# Length varies; longest strips reach (and pool on) the floor.
		var strip_len: float = hang_y * _rng.randf_range(0.45, 1.0)
		var by: float = hang_y - strip_len * 0.5         # top anchored near hang_y
		var basis := Basis().scaled(Vector3(1.0, strip_len / 0.5, 1.0))
		mm.set_instance_transform(i, Transform3D(basis, Vector3(bx, by, bz)))
		# Rainbow by horizontal position so the curtain reads as a spectrum.
		var hue: float = fposmod(0.5 + span_frac * 0.5 * sign_x + 0.5, 1.0)
		mm.set_instance_color(i, Color.from_hsv(hue, 0.85, 1.0))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "FringeCurtain"
	mmi.multimesh = mm
	var fringe_mat := StandardMaterial3D.new()
	fringe_mat.vertex_color_use_as_albedo = true
	fringe_mat.roughness = 0.4
	fringe_mat.metallic = 0.1
	mmi.material_override = fringe_mat
	add_child(mmi)


# A single thin "feather" spike (a tall thin box) for the totem's fans.
func _add_feather(nm: String, length: float, thick: float, pivot: Vector3,
		rot: Vector3, mat: StandardMaterial3D) -> void:
	var node := Node3D.new()
	node.name = nm
	node.position = pivot
	node.rotation = rot
	add_child(node)
	var mi := MeshInstance3D.new()
	mi.name = "Spike"
	var bm := BoxMesh.new()
	bm.size = Vector3(thick, length, thick)
	mi.mesh = bm
	mi.material_override = mat
	# Offset up so the feather grows OUT of the pivot (rotates about its base).
	mi.position = Vector3(0, length * 0.5, 0)
	node.add_child(mi)


# ── Mode: JUDD (Donald Judd — minimalist modular) ──────────────────────
# A clean stack of complexity+2 identical rectangular lacquer boxes, evenly
# spaced with gaps equal to the box height, climbing to sculpt_height. Each
# box is a crisp saturated lacquer colour cycling through a fixed sequence.
# Intentionally mono-material / multi-colour — that IS the Judd vocabulary;
# the cool minimalist counterpoint to the organic modes.

func _build_judd() -> void:
	_rng.seed = seed
	var lacquer_seq: Array[Color] = [
		Color(0.80, 0.10, 0.10),   # red
		Color(0.90, 0.45, 0.10),   # orange
		Color(0.10, 0.55, 0.55),   # teal
		Color(0.92, 0.80, 0.12),   # yellow
		Color(0.06, 0.06, 0.07),   # black
		Color(0.12, 0.30, 0.75),   # blue
		Color(0.92, 0.92, 0.90)]   # white

	var n: int = maxi(2, complexity + 2)
	var box_w: float = sculpt_width
	var box_h: float = 0.18
	var box_d: float = sculpt_width * 0.6
	# Gap equals box height: scale box+gap pitch so the top of the last box
	# reaches sculpt_height (pitch = one box + one gap unit above it).
	var pitch: float = sculpt_height / float(n)
	box_h = minf(box_h, pitch * 0.5)                   # ensure gap >= box height
	var gap: float = maxf(pitch - box_h, box_h)
	for i in range(n):
		var col: Color = lacquer_seq[i % lacquer_seq.size()]
		var mat := _make_mat(col, 0.3, 0.2)            # anodized lacquer sheen
		var y: float = float(i) * (box_h + gap) + box_h * 0.5
		_add_box("Judd%d" % i, Vector3(box_w, box_h, box_d),
			Vector3(0, y, 0), Vector3.ZERO, mat)


# ── Mode: VITRINE (architecture enclosing preserved nature) ────────────
# A glass greenhouse standing on a heavy concrete plinth, a patch of living
# grass sealed inside. The contradiction is the whole theme of the piece:
# heavy matte concrete + a hard thin chrome/white frame + transparent brittle
# glass + soft living green — architecture preserving nature behind glass.

func _build_vitrine() -> void:
	_rng.seed = seed
	var concrete := _mat_concrete(color_b)
	var frame_mat := _make_mat(Color(0.92, 0.93, 0.95), 0.3, 0.6)   # white/chrome edge bars
	var glass := _mat_glass(Color(0.85, 0.92, 1.0))
	var green := color_a                                            # living-green register
	var grass_mat := _make_mat(green, 0.85, 0.0)

	# PLINTH — a low heavy concrete box on the floor.
	var plinth_w: float = sculpt_width
	var plinth_d: float = sculpt_width * 0.8
	var plinth_h: float = 0.18
	_add_box("Plinth", Vector3(plinth_w, plinth_h, plinth_d),
		Vector3(0, plinth_h * 0.5, 0), Vector3.ZERO, concrete)

	# GREENHOUSE shell on the plinth. Rectangular footprint with a gable roof.
	var house_w: float = sculpt_width * 0.85
	var house_d: float = plinth_d * 0.82
	var house_h: float = sculpt_height * 0.7
	var wall_h: float = house_h * 0.62                  # vertical wall height
	var roof_rise: float = house_h - wall_h             # gable peak above the eaves
	var floor_y: float = plinth_h                       # greenhouse sits on the plinth top
	var bar_t: float = sculpt_width * 0.025             # thin frame bar thickness
	var hw: float = house_w * 0.5
	var hd: float = house_d * 0.5
	var eaves_y: float = floor_y + wall_h
	var ridge_y: float = floor_y + house_h

	# 4 vertical corner posts.
	for cx in [hw, -hw]:
		for cz in [hd, -hd]:
			_add_box("Post", Vector3(bar_t, wall_h, bar_t),
				Vector3(cx, floor_y + wall_h * 0.5, cz), Vector3.ZERO, frame_mat)

	# Top eaves rails (the rectangle where the walls meet the roof).
	_add_box("EaveFront", Vector3(house_w, bar_t, bar_t),
		Vector3(0, eaves_y, hd), Vector3.ZERO, frame_mat)
	_add_box("EaveBack", Vector3(house_w, bar_t, bar_t),
		Vector3(0, eaves_y, -hd), Vector3.ZERO, frame_mat)
	_add_box("EaveLeft", Vector3(bar_t, bar_t, house_d),
		Vector3(-hw, eaves_y, 0), Vector3.ZERO, frame_mat)
	_add_box("EaveRight", Vector3(bar_t, bar_t, house_d),
		Vector3(hw, eaves_y, 0), Vector3.ZERO, frame_mat)

	# Ridge beam running front-to-back at the peak.
	_add_box("Ridge", Vector3(bar_t, bar_t, house_d),
		Vector3(0, ridge_y, 0), Vector3.ZERO, frame_mat)

	# RAFTERS — thin bars from each eave up to the ridge, on both slopes.
	var slope_len: float = sqrt(hw * hw + roof_rise * roof_rise)
	var slope_pitch: float = atan2(roof_rise, hw)       # rafter tilt from horizontal
	var rafters: int = 3
	for ri in range(rafters):
		var rz: float = lerpf(-hd, hd, float(ri) / float(maxi(1, rafters - 1)))
		# Left slope rafter (rises toward +X... peak at centre).
		_add_box("RafterL%d" % ri, Vector3(slope_len, bar_t, bar_t),
			Vector3(-hw * 0.5, eaves_y + roof_rise * 0.5, rz),
			Vector3(0, 0, slope_pitch), frame_mat)
		_add_box("RafterR%d" % ri, Vector3(slope_len, bar_t, bar_t),
			Vector3(hw * 0.5, eaves_y + roof_rise * 0.5, rz),
			Vector3(0, 0, -slope_pitch), frame_mat)

	# GLASS WALL PANELS — thin transparent boxes filling the 4 walls.
	_add_box("GlassFront", Vector3(house_w, wall_h, bar_t * 0.4),
		Vector3(0, floor_y + wall_h * 0.5, hd), Vector3.ZERO, glass)
	_add_box("GlassBack", Vector3(house_w, wall_h, bar_t * 0.4),
		Vector3(0, floor_y + wall_h * 0.5, -hd), Vector3.ZERO, glass)
	_add_box("GlassLeft", Vector3(bar_t * 0.4, wall_h, house_d),
		Vector3(-hw, floor_y + wall_h * 0.5, 0), Vector3.ZERO, glass)
	_add_box("GlassRight", Vector3(bar_t * 0.4, wall_h, house_d),
		Vector3(hw, floor_y + wall_h * 0.5, 0), Vector3.ZERO, glass)

	# GLASS ROOF SLOPES — two thin tilted panels meeting at the ridge.
	_add_box("GlassRoofL", Vector3(slope_len, bar_t * 0.4, house_d),
		Vector3(-hw * 0.5, eaves_y + roof_rise * 0.5, 0),
		Vector3(0, 0, slope_pitch), glass)
	_add_box("GlassRoofR", Vector3(slope_len, bar_t * 0.4, house_d),
		Vector3(hw * 0.5, eaves_y + roof_rise * 0.5, 0),
		Vector3(0, 0, -slope_pitch), glass)

	# INTERIOR GRASS PATCH — a low green box on the plinth inside the house.
	var patch_w: float = house_w * 0.82
	var patch_d: float = house_d * 0.82
	var patch_h: float = sculpt_height * 0.04
	_add_box("GrassPatch", Vector3(patch_w, patch_h, patch_d),
		Vector3(0, floor_y + patch_h * 0.5, 0), Vector3.ZERO, grass_mat)

	# GRASS BLADES — a MultiMesh of ~80 tiny upright blade boxes scattered on
	# the patch with slight rotation jitter, so the sealed nature reads as alive.
	var blade_n: int = 80
	var blade := BoxMesh.new()
	blade.size = Vector3(0.01, 0.08, 0.01)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = blade
	mm.instance_count = blade_n
	var grass_y: float = floor_y + patch_h
	for i in range(blade_n):
		var bx: float = _rng.randf_range(-1.0, 1.0) * patch_w * 0.48
		var bz: float = _rng.randf_range(-1.0, 1.0) * patch_d * 0.48
		var hscale: float = _rng.randf_range(0.7, 1.4)
		var basis := Basis()
		basis = basis.rotated(Vector3.UP, _rng.randf_range(0.0, TAU))
		basis = basis.rotated(Vector3.RIGHT, _rng.randf_range(-0.18, 0.18))
		basis = basis.rotated(Vector3.FORWARD, _rng.randf_range(-0.18, 0.18))
		basis = basis.scaled(Vector3(1.0, hscale, 1.0))
		# Anchor base at the patch surface (blade pivots at its centre).
		mm.set_instance_transform(i,
			Transform3D(basis, Vector3(bx, grass_y + 0.04 * hscale, bz)))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "GrassBlades"
	mmi.multimesh = mm
	mmi.material_override = _make_mat(green.darkened(0.1), 0.85, 0.0)
	add_child(mmi)


# ── Mode: MESH (Ernesto Neto — open knit / net membrane tower) ─────────
# A tapering hollow tower whose SURFACE is an OPEN NET: a MultiMesh of small
# "stitch" links arranged in rows up the height × columns around a tapering,
# gently-bulging radius profile, so visible GAPS between links make it read
# as a soft hanging mesh (not a solid skin). Branching woody roots splay from
# the base to the floor. The openness — the holes — is the whole point.

func _build_mesh() -> void:
	_rng.seed = seed
	var membrane_mat := _make_mat(color_a, 0.5, 0.0)               # pale green/cream
	var root_mat := _make_mat(color_b, 0.8, 0.0)                   # woody

	var n: int = maxi(40, unit_count)
	var base_r: float = sculpt_width * 0.5
	var rows: int = maxi(6, int(round(sqrt(float(n) * sculpt_height / maxf(sculpt_width, 0.01)))))
	var cols: int = maxi(6, int(round(float(n) / float(rows))))
	var total: int = rows * cols

	# The repeated "stitch" link — a short thin box.
	var link := BoxMesh.new()
	link.size = Vector3(0.05, 0.05, 0.02)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = link
	mm.instance_count = total

	var idx: int = 0
	for r in range(rows):
		var v: float = float(r) / float(maxi(1, rows - 1))        # 0 (base) .. 1 (top)
		var y: float = v * sculpt_height
		# Tapering profile with a gentle bulge: wide base -> narrow top, bulge mid.
		var taper: float = lerpf(1.0, 0.32, v)
		var bulge: float = 1.0 + 0.22 * sin(v * PI)
		var ring_r: float = base_r * taper * bulge
		# Stagger every other row so the net reads as knit, not a grid of dots.
		var phase: float = (PI / float(cols)) * float(r % 2)
		for c in range(cols):
			if idx >= total:
				break
			var ang: float = TAU * float(c) / float(cols) + phase
			var jr: float = ring_r * (1.0 + _rng.randf_range(-0.04, 0.04))
			var jy: float = y + _rng.randf_range(-1.0, 1.0) * (sculpt_height / float(rows)) * 0.18
			var px: float = cos(ang) * jr
			var pz: float = sin(ang) * jr
			# Orient each link roughly tangent to the surface (face outward, lie along ring).
			var basis := Basis()
			basis = basis.rotated(Vector3.UP, ang + PI * 0.5)     # tangent around the ring
			basis = basis.rotated(Vector3.FORWARD, _rng.randf_range(-0.25, 0.25))
			var s: float = _rng.randf_range(0.8, 1.2)
			basis = basis.scaled(Vector3(s, s, s))
			mm.set_instance_transform(idx, Transform3D(basis, Vector3(px, jy, pz)))
			idx += 1
	# Park any unused trailing instances out of sight (rows*cols >= n guard).
	for j in range(idx, total):
		mm.set_instance_transform(j, Transform3D(Basis().scaled(Vector3.ONE * 0.001),
			Vector3(0, -10.0, 0)))

	var mmi := MultiMeshInstance3D.new()
	mmi.name = "NetSurface"
	mmi.multimesh = mm
	mmi.material_override = membrane_mat
	add_child(mmi)

	# BRANCHING ROOTS — 4-6 thin woody strands splaying from the base ring
	# down/out to the floor, anchoring the soft hanging net.
	var roots: int = _rng.randi_range(4, 6)
	for ri in range(roots):
		var ang: float = TAU * float(ri) / float(roots) + _rng.randf_range(-0.2, 0.2)
		var top := Vector3(cos(ang) * base_r * 0.9,
			sculpt_height * _rng.randf_range(0.08, 0.16),
			sin(ang) * base_r * 0.9)
		var reach: float = base_r * _rng.randf_range(1.2, 1.8)
		var foot := Vector3(cos(ang) * reach, 0.0, sin(ang) * reach)
		# Two-segment splay (slight elbow) so the roots read as branching.
		var mid := top.lerp(foot, 0.5) + Vector3(
			_rng.randf_range(-1.0, 1.0) * base_r * 0.15,
			_rng.randf_range(-0.04, 0.04),
			_rng.randf_range(-1.0, 1.0) * base_r * 0.15)
		_add_strand(top, mid, root_mat, sculpt_width * 0.022)
		_add_strand(mid, foot, root_mat, sculpt_width * 0.016)


# ── Mode: EARTHWORK (earthen creature on twig legs over a soil mound) ──
# A bulbous earthen body that arcs and droops forward (a grazing head dipping
# down), standing on thin splayed branch legs over a dark soil mound, with a
# hard mirror disc set in the soil. Found-nature (rough fiber-brown earth +
# woody legs + dark soil) meets reflective artifice (the chrome mirror).

func _build_earthwork() -> void:
	_rng.seed = seed
	var earth := _make_mat(color_a, 0.95, 0.0)                     # earthen brown, matte fiber
	var wood := _make_mat(color_b, 0.9, 0.0)                       # grey-brown branch legs
	var soil := _make_mat(color_a.darkened(0.7), 0.97, 0.0)        # very dark soil
	var mirror := _mat_chrome()                                    # hard reflective disc

	# SOIL MOUND — a low wide flattened cylinder on the floor.
	var mound_r: float = sculpt_width * 0.75
	var mound_h: float = sculpt_height * 0.06
	_add_cyl("SoilMound", mound_r * 0.92, mound_r, mound_h,
		Vector3(0, mound_h * 0.5, 0), Vector3.ZERO, soil)

	# MIRROR — a flat reflective metallic disc set into the soil.
	var mir_r: float = sculpt_width * 0.28
	_add_cyl("Mirror", mir_r, mir_r, mound_h * 0.4,
		Vector3(_rng.randf_range(-1.0, 1.0) * mound_r * 0.25,
			mound_h + 0.001,
			_rng.randf_range(-1.0, 1.0) * mound_r * 0.25),
		Vector3.ZERO, mirror)

	# BODY — two overlapping scaled SphereMesh ovoids forming a body that arcs
	# and droops forward: a rear haunch sphere + a front head sphere dipping low.
	var body_y: float = mound_h + sculpt_height * 0.42             # belly height on the legs
	var body_w: float = sculpt_width
	var haunch_r: float = body_w * 0.34
	var haunch := _add_sphere("Haunch", haunch_r,
		Vector3(-body_w * 0.22, body_y + sculpt_height * 0.12, 0), earth)
	haunch.scale = Vector3(1.15, 1.0, 1.0)
	# Mid-body bridging the two masses.
	var mid := _add_sphere("Torso", haunch_r * 0.9,
		Vector3(0, body_y + sculpt_height * 0.06, 0), earth)
	mid.scale = Vector3(1.3, 0.9, 0.95)
	# Head dips forward and DOWN (the grazing droop) toward +X / toward the soil.
	var head_r: float = body_w * 0.24
	var head := _add_sphere("Head", head_r,
		Vector3(body_w * 0.46, body_y - sculpt_height * 0.16, 0), earth)
	head.scale = Vector3(1.25, 0.85, 0.9)
	var underside_y: float = body_y - haunch_r * 0.6              # legs hang from here

	# LEGS — complexity+3 thin splayed tapered branch legs from the underside
	# of the body out to the floor at varied angles, like stilts / roots.
	var legs: int = maxi(4, complexity + 3)
	for li in range(legs):
		var ang: float = TAU * float(li) / float(legs) + _rng.randf_range(-0.2, 0.2)
		# Anchor under the torso/haunch mass, biased toward the body's long axis.
		var anchor := Vector3(
			cos(ang) * body_w * 0.3 - body_w * 0.05,
			underside_y + _rng.randf_range(-0.02, 0.04),
			sin(ang) * body_w * 0.22)
		var splay: float = body_w * _rng.randf_range(0.35, 0.6)
		var foot := Vector3(
			anchor.x + cos(ang) * splay,
			0.0,
			anchor.z + sin(ang) * splay)
		var leg_h: float = anchor.y
		var mid_pt := anchor.lerp(foot, 0.5)
		var leg := _add_cyl("Leg%d" % li, sculpt_width * 0.012, sculpt_width * 0.03,
			leg_h * 1.02, mid_pt, Vector3.ZERO, wood)
		# Tilt the leg so its +Y axis runs from foot up to the anchor.
		var dir := (anchor - foot).normalized()
		var up := Vector3.UP
		var axis := up.cross(dir)
		if axis.length() > 0.0001:
			leg.basis = Basis(axis.normalized(), acos(clampf(up.dot(dir), -1.0, 1.0)))


# ── Mode: VESSEL (a humble everyday object rendered monumental & precious) ─
# ONE giant smooth household vessel — bottle, amphora, or funnel, picked by
# (seed % 3) — built as a body of revolution: a vertical stack of tapered
# CylinderMesh sections following a hand-tuned profile. Pale translucent
# alabaster (soft wax membrane); an optional faint internal glow if emissive.
# A small thing made huge: the gallery's gaze on the ordinary.

func _build_vessel() -> void:
	_rng.seed = seed
	# Pale translucent alabaster — pull color_a toward white so it reads as
	# precious stone regardless of the incoming hue.
	var pale := color_a.lerp(Color(0.94, 0.92, 0.88), 0.6)
	var alabaster := _mat_wax(pale)
	alabaster.roughness = 0.5
	var kind: int = seed % 3
	var h: float = sculpt_height
	var w: float = sculpt_width

	# A profile is a list of [y_fraction, radius_fraction] rings; consecutive
	# rings become tapered cylinder sections (bottom radius -> top radius).
	var profile: Array = []
	if kind == 0:
		# BOTTLE — flat base, tall straight body, rounded shoulder, narrow neck.
		profile = [
			[0.00, 0.46], [0.05, 0.50], [0.50, 0.50], [0.62, 0.47],
			[0.72, 0.30], [0.80, 0.16], [0.92, 0.15], [1.00, 0.17]]
	elif kind == 1:
		# AMPHORA — narrow foot, swelling ovoid belly, narrow neck, flared lip.
		profile = [
			[0.00, 0.16], [0.06, 0.22], [0.30, 0.50], [0.46, 0.52],
			[0.62, 0.40], [0.74, 0.20], [0.88, 0.17], [0.95, 0.22], [1.00, 0.30]]
	else:
		# FUNNEL — a wide inverted cone resting on a narrow tubular stem.
		profile = [
			[0.00, 0.09], [0.40, 0.09], [0.45, 0.11], [0.55, 0.30],
			[1.00, 0.56]]

	for i in range(profile.size() - 1):
		var y0: float = float(profile[i][0]) * h
		var y1: float = float(profile[i + 1][0]) * h
		var r0: float = float(profile[i][1]) * w
		var r1: float = float(profile[i + 1][1]) * w
		var seg_h: float = y1 - y0
		if seg_h <= 0.0001:
			continue
		# CylinderMesh: bottom_radius is the lower ring, top_radius the upper.
		_add_cyl("VesselSeg%d" % i, r1, r0, seg_h,
			Vector3(0, (y0 + y1) * 0.5, 0), Vector3.ZERO, alabaster)

	# AMPHORA HANDLES — two curved torus handles bridging shoulder to neck.
	if kind == 1:
		var handle_y: float = h * 0.66
		var handle_r: float = w * 0.20
		for side in [1.0, -1.0]:
			var handle := MeshInstance3D.new()
			handle.name = "VesselHandle%d" % int(side)
			var tm := TorusMesh.new()
			tm.inner_radius = handle_r * 0.55
			tm.outer_radius = handle_r
			handle.mesh = tm
			handle.material_override = alabaster
			# Stand the ring up in the X/Y plane and push it out to the side.
			handle.position = Vector3(side * w * 0.34, handle_y, 0)
			handle.rotation = Vector3(deg_to_rad(90.0), 0, deg_to_rad(90.0))
			add_child(handle)

	# Optional faint internal glow — a soft sphere suspended inside the body.
	if emissive:
		var glow := _make_emissive_mat(accent, 1.0)
		glow.albedo_color = Color(accent.r, accent.g, accent.b, 0.5)
		glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_add_sphere("VesselGlow", w * 0.28, Vector3(0, h * 0.4, 0), glow)


# ── Mode: COLUMN (Diana Al-Hadid — broken marble on machined fin bases) ──
# 1-3 white MARBLE columns, each with a BROKEN jagged top (the cap is a few
# short offset chunks), standing on FINNED INDUSTRIAL bases — a short central
# hub ringed by ~16 thin radial heat-sink fins in dark metal. The whole point
# is the contradiction: classical fluted marble bolted onto a machined sink.

func _build_column() -> void:
	_rng.seed = seed
	var marble := _make_mat(color_a, 0.4, 0.1)
	var metal := _make_mat(color_b, 0.5, 0.7)
	var count: int = clampi(complexity, 1, 3)

	# Lay the columns out across the footprint (centred when there is one).
	var spread: float = sculpt_width * 1.1
	for ci in range(count):
		var cx: float = 0.0
		if count > 1:
			cx = lerpf(-spread * 0.5, spread * 0.5, float(ci) / float(count - 1))
		var cz: float = _rng.randf_range(-1.0, 1.0) * sculpt_width * 0.12
		var root := Vector3(cx, 0.0, cz)

		# FINNED BASE — a short central hub cylinder ringed by radial fins.
		var base_h: float = sculpt_height * 0.12
		var hub_r: float = sculpt_width * 0.26
		_add_cyl("ColBaseHub%d" % ci, hub_r, hub_r * 1.1, base_h,
			root + Vector3(0, base_h * 0.5, 0), Vector3.ZERO, metal)
		var fins: int = 16
		var fin_h: float = base_h * 0.9
		for fi in range(fins):
			var fang: float = TAU * float(fi) / float(fins)
			var fin_len: float = sculpt_width * 0.16
			var fr: float = hub_r + fin_len * 0.5
			_add_box("ColFin%d_%d" % [ci, fi],
				Vector3(fin_len, fin_h, sculpt_width * 0.015),
				root + Vector3(cos(fang) * fr, fin_h * 0.5, sin(fang) * fr),
				Vector3(0, -fang, 0), metal)

		# SHAFT — a tall fluted marble cylinder rising from the base.
		var shaft_h: float = sculpt_height * _rng.randf_range(0.62, 0.74)
		var shaft_r: float = sculpt_width * 0.20
		var shaft_base_y: float = base_h
		_add_cyl("ColShaft%d" % ci, shaft_r * 0.92, shaft_r, shaft_h,
			root + Vector3(0, shaft_base_y + shaft_h * 0.5, 0), Vector3.ZERO, marble)
		# Optional fluting — a ring of thin vertical grooves stuck to the shaft.
		var flutes: int = 12
		for fl in range(flutes):
			var flang: float = TAU * float(fl) / float(flutes)
			_add_box("ColFlute%d_%d" % [ci, fl],
				Vector3(sculpt_width * 0.012, shaft_h * 0.96, sculpt_width * 0.03),
				root + Vector3(cos(flang) * shaft_r, shaft_base_y + shaft_h * 0.5,
					sin(flang) * shaft_r),
				Vector3(0, -flang, 0), marble)

		# BROKEN TOP — instead of a clean capital, a few short offset marble
		# chunks of decreasing size, jittered, so the column reads as snapped.
		var top_y: float = shaft_base_y + shaft_h
		var chunks: int = _rng.randi_range(2, 3)
		for ch in range(chunks):
			var ct: float = float(ch) / float(maxi(1, chunks))
			var chunk_r: float = shaft_r * lerpf(0.95, 0.4, ct)
			var chunk_h: float = shaft_h * _rng.randf_range(0.05, 0.11)
			var jx: float = _rng.randf_range(-1.0, 1.0) * shaft_r * 0.5
			var jz: float = _rng.randf_range(-1.0, 1.0) * shaft_r * 0.5
			var tilt := Vector3(
				_rng.randf_range(-1.0, 1.0) * deg_to_rad(22.0),
				_rng.randf_range(0.0, TAU),
				_rng.randf_range(-1.0, 1.0) * deg_to_rad(22.0))
			_add_cyl("ColBreak%d_%d" % [ci, ch], chunk_r * 0.7, chunk_r, chunk_h,
				root + Vector3(jx, top_y + chunk_h * (0.4 + float(ch) * 0.8), jz),
				tilt, marble)


# ── Mode: LUMENARCH (a dark portal studded with glowing blocks) ─────────
# A leaning A-frame portal — two matte-black posts meeting at the top — its
# edges STUDDED with many small emissive blocks. Architectural dark mass made
# luminous: the immaterial glow riding the heavy frame.

func _build_lumenarch() -> void:
	_rng.seed = seed
	var matte := _make_mat(color_b, 0.6, 0.3)
	var glow := _make_emissive_mat(accent, 2.0)

	var h: float = sculpt_height
	var span: float = sculpt_width * 0.8        # half the foot separation
	var post_t: float = sculpt_width * 0.10
	# The two legs lean in to meet near a shared apex above centre.
	var apex := Vector3(0, h, 0)
	var foot_l := Vector3(-span, 0, 0)
	var foot_r := Vector3(span, 0, 0)

	# Each leg = one long box spanning foot -> apex, oriented along that line.
	var legs := [foot_l, foot_r]
	var leg_dirs: Array[Vector3] = []
	var leg_lens: Array[float] = []
	for li in range(legs.size()):
		var foot: Vector3 = legs[li]
		var diff := apex - foot
		var leg_len: float = diff.length()
		leg_dirs.append(diff.normalized())
		leg_lens.append(leg_len)
		var leg := MeshInstance3D.new()
		leg.name = "ArchLeg%d" % li
		var bm := BoxMesh.new()
		bm.size = Vector3(post_t, leg_len, post_t)
		leg.mesh = bm
		leg.material_override = matte
		leg.position = (foot + apex) * 0.5
		# Lean the post's +Y axis along the leg direction.
		var up := Vector3.UP
		var axis := up.cross(diff.normalized())
		if axis.length() > 0.0001:
			leg.basis = Basis(axis.normalized(), acos(clampf(up.dot(diff.normalized()), -1.0, 1.0)))
		add_child(leg)

	# A short lintel block capping the apex where the legs meet.
	_add_box("ArchApex", Vector3(span * 0.9, post_t * 1.1, post_t * 1.1),
		Vector3(0, h - post_t * 0.4, 0), Vector3.ZERO, matte)

	# STUDS — many small emissive blocks spaced evenly along both legs, sitting
	# proud of the dark frame so the edges read as a luminous outline.
	var studs_per_leg: int = maxi(6, complexity * 3)
	for li in range(legs.size()):
		var foot: Vector3 = legs[li]
		var d: Vector3 = leg_dirs[li]
		for si in range(studs_per_leg):
			var f: float = float(si) / float(maxi(1, studs_per_leg - 1))
			var p: Vector3 = foot + d * (leg_lens[li] * f)
			var jit: float = _rng.randf_range(-1.0, 1.0) * post_t * 0.15
			var stud_s: float = post_t * _rng.randf_range(0.32, 0.5)
			_add_box("ArchStud%d_%d" % [li, si],
				Vector3(stud_s, stud_s, stud_s),
				p + Vector3(jit, 0, post_t * 0.5 + stud_s * 0.3),
				Vector3(0, _rng.randf_range(0.0, TAU), 0), glow)


# ── Mode: THREADFIELD (Chiharu Shiota — red thread web + suspended keys) ─
# A dark hull-like boat resting on the floor, engulfed in a DENSE web of thin
# RED strands raining down from a high plane to scattered points around it,
# with small dark "keys" hanging suspended inside the thread volume. Both the
# web and the keys are MultiMesh batches. A red atmosphere of memory.

func _build_threadfield() -> void:
	_rng.seed = seed
	var hull_mat := _make_mat(color_b, 0.7, 0.1)

	# HULL — a tapered, scaled box "boat" lying on the floor.
	var hull_h: float = sculpt_height * 0.14
	var hull := _add_box("Hull",
		Vector3(sculpt_width * 0.9, hull_h, sculpt_width * 0.4),
		Vector3(0, hull_h * 0.5, 0), Vector3.ZERO, hull_mat)
	hull.scale = Vector3(1.0, 1.0, 0.7)        # narrow it toward a keel
	# A small raised prow chunk so the hull reads as a boat, not just a slab.
	_add_box("HullProw",
		Vector3(sculpt_width * 0.22, hull_h * 1.4, sculpt_width * 0.14),
		Vector3(sculpt_width * 0.4, hull_h * 0.8, 0),
		Vector3(0, 0, deg_to_rad(-12.0)), hull_mat)

	# RED THREAD WEB — unit_count thin red strands from a high plane down to
	# scattered points around the hull. Built as a MultiMesh of thin cylinders.
	var n: int = maxi(8, unit_count)
	var plane_y: float = sculpt_height
	var hw: float = sculpt_width * 0.6
	var red := color_a
	var thread := CylinderMesh.new()
	thread.top_radius = sculpt_width * 0.004
	thread.bottom_radius = sculpt_width * 0.004
	thread.height = 1.0                          # unit height; scaled per instance
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = thread
	mm.instance_count = n
	for i in range(n):
		# Top anchor on the high plane, bottom near/around the hull.
		var top := Vector3(_rng.randf_range(-hw, hw), plane_y,
			_rng.randf_range(-hw, hw))
		var bottom := Vector3(_rng.randf_range(-hw, hw),
			_rng.randf_range(hull_h, sculpt_height * 0.35),
			_rng.randf_range(-hw, hw))
		var diff := bottom - top
		var length: float = maxf(diff.length(), 0.001)
		var mid := (top + bottom) * 0.5
		# Orient the unit cylinder's +Y axis along the strand; scale Y to length.
		var dir := diff / length
		var up := Vector3.UP
		var basis := Basis()
		var axis := up.cross(dir)
		if axis.length() > 0.0001:
			basis = Basis(axis.normalized(), acos(clampf(up.dot(dir), -1.0, 1.0)))
		basis = basis.scaled(Vector3(1.0, length, 1.0))
		mm.set_instance_transform(i, Transform3D(basis, mid))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "ThreadWeb"
	mmi.multimesh = mm
	mmi.material_override = _make_mat(red, 0.6, 0.0)
	add_child(mmi)

	# SUSPENDED KEYS — ~20 tiny dark boxes hanging within the thread volume.
	var key_n: int = 20
	var key := BoxMesh.new()
	key.size = Vector3(sculpt_width * 0.03, sculpt_width * 0.06, sculpt_width * 0.008)
	var kmm := MultiMesh.new()
	kmm.transform_format = MultiMesh.TRANSFORM_3D
	kmm.mesh = key
	kmm.instance_count = key_n
	for i in range(key_n):
		var kp := Vector3(_rng.randf_range(-hw * 0.8, hw * 0.8),
			_rng.randf_range(sculpt_height * 0.3, sculpt_height * 0.9),
			_rng.randf_range(-hw * 0.8, hw * 0.8))
		var kbasis := Basis().rotated(Vector3.UP, _rng.randf_range(0.0, TAU))
		kbasis = kbasis.rotated(Vector3.FORWARD, _rng.randf_range(-0.3, 0.3))
		kmm.set_instance_transform(i, Transform3D(kbasis, kp))
	var kmmi := MultiMeshInstance3D.new()
	kmmi.name = "SuspendedKeys"
	kmmi.multimesh = kmm
	kmmi.material_override = _make_mat(color_b.darkened(0.3), 0.6, 0.4)
	add_child(kmmi)


# ── Mode: GLOWMOUND (Pierre Huyghe — bioluminescent flesh + dark spike) ─
# A low translucent BIO MOUND (a flattened glowing hemisphere) on the floor,
# and a hanging TURNED-SPIRAL PENDANT descending toward it — a vertical axis
# threaded with beads that shrink then swell, in dark wood. Soft living glow
# beneath a hard ceremonial spike.

func _build_glowmound() -> void:
	_rng.seed = seed
	# Pull color_a toward a hot bioluminescent register (red/pink/magenta).
	var bio_hue: Color = color_a.lerp(Color(0.95, 0.18, 0.42), 0.5)
	var mound_mat := _make_emissive_mat(bio_hue, 1.6)
	mound_mat.albedo_color = Color(bio_hue.r, bio_hue.g, bio_hue.b, 0.7)
	mound_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var wood := _make_mat(color_b, 0.6, 0.1)

	# MOUND — a flattened hemisphere sitting on the floor, glowing.
	var mound_r: float = sculpt_width * 0.6
	var mound := _add_sphere("BioMound", mound_r, Vector3(0, 0, 0), mound_mat)
	mound.scale = Vector3(1.0, 0.45, 1.0)
	# A second, smaller inner glow lobe for an underglow / depth feel.
	var inner := _add_sphere("BioMoundInner", mound_r * 0.6,
		Vector3(0, mound_r * 0.1, 0), _make_emissive_mat(bio_hue, 2.2))
	inner.scale = Vector3(1.0, 0.4, 1.0)

	# PENDANT — a vertical dark axis hanging from high above down toward the
	# mound, threaded with beads whose radius shrinks then swells (a spiral spike).
	var top_y: float = sculpt_height
	var bottom_y: float = mound_r * 0.55             # ends just above the mound
	var axis_h: float = top_y - bottom_y
	_add_cyl("PendantAxis", sculpt_width * 0.02, sculpt_width * 0.02, axis_h,
		Vector3(0, (top_y + bottom_y) * 0.5, 0), Vector3.ZERO, wood)
	var beads: int = clampi(complexity, 6, 18)
	for i in range(beads):
		var t: float = float(i) / float(maxi(1, beads - 1))     # 0 (top) .. 1 (bottom)
		var by: float = lerpf(top_y, bottom_y, t)
		# Decrease then increase: smallest at the waist, swelling at both ends.
		var waist: float = absf(t - 0.5) * 2.0                  # 1 at ends, 0 at middle
		var bead_r: float = sculpt_width * lerpf(0.03, 0.12, waist)
		# Spiral the beads slightly off the axis so it reads as a turned spike.
		var spin: float = t * TAU * 2.0
		var off: float = bead_r * 0.4
		_add_sphere("PendantBead%d" % i, bead_r,
			Vector3(cos(spin) * off, by, sin(spin) * off), wood)


# ── Mode: BLOCKFIELD (model-city heightfield — a data landscape) ────────
# A GRID of small white cubes of varying heights on a thin black reflective
# plinth. Each cube's height comes from a smooth pseudo-height field (layered
# sines + a little RNG jitter) so the field reads as a topographic city / data
# landscape. Cubes are a single MultiMesh batch. White matte on dark mirror.

func _build_blockfield() -> void:
	_rng.seed = seed
	var white := _make_mat(color_a, 0.6, 0.05)
	var plinth_mat := _make_mat(color_b, 0.2, 0.3)

	# PLINTH — a wide thin dark reflective slab on the floor.
	var plinth_w: float = sculpt_width * 1.1
	var plinth_d: float = sculpt_width * 1.1
	var plinth_h: float = sculpt_height * 0.04
	_add_box("CityPlinth", Vector3(plinth_w, plinth_h, plinth_d),
		Vector3(0, plinth_h * 0.5, 0), Vector3.ZERO, plinth_mat)

	# GRID — n x n small cubes covering the plinth, each scaled in Y by a smooth
	# height function of its (gx, gz) cell so the surface reads as a city.
	var n: int = maxi(4, int(round(sqrt(float(maxi(4, unit_count))))))
	var cube_w: float = (plinth_w * 0.92) / float(n)
	var cube_base: float = 0.06                  # base cube footprint reference
	var top_y: float = plinth_h
	var max_h: float = sculpt_height * 0.85

	var cube := BoxMesh.new()
	cube.size = Vector3(1.0, 1.0, 1.0)            # unit cube; scaled per instance
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = cube
	mm.instance_count = n * n
	var idx: int = 0
	for gx in range(n):
		for gz in range(n):
			var fx: float = float(gx) / float(maxi(1, n - 1))     # 0..1
			var fz: float = float(gz) / float(maxi(1, n - 1))
			# Layered sines give smooth ridges/valleys; jitter breaks the regularity.
			var height01: float = 0.5 \
				+ 0.30 * sin(fx * PI * 2.2 + 0.6) * cos(fz * PI * 1.8) \
				+ 0.18 * sin((fx + fz) * PI * 3.1) \
				+ _rng.randf_range(-0.08, 0.08)
			height01 = clampf(height01, 0.05, 1.0)
			var ch: float = max_h * height01
			var px: float = lerpf(-plinth_w * 0.46, plinth_w * 0.46, fx)
			var pz: float = lerpf(-plinth_d * 0.46, plinth_d * 0.46, fz)
			# Footprint slightly smaller than the cell for visible gaps (streets).
			var foot: float = minf(cube_w * 0.82, cube_base * 1.4)
			var basis := Basis().scaled(Vector3(foot, ch, foot))
			# Lift so the cube sits ON the plinth (origin is the cube centre).
			mm.set_instance_transform(idx,
				Transform3D(basis, Vector3(px, top_y + ch * 0.5, pz)))
			idx += 1
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "CityBlocks"
	mmi.multimesh = mm
	mmi.material_override = white
	add_child(mmi)


# ── Mode: LATTICE (Anila Quayyum Agha — filigree shadow cube) ──────────
# An OPENWORK lace cube balanced on a single VERTEX over a dark reflective
# floor disc that reads as water. The cube is NOT solid: each of its 6 faces
# is a grid of thin bars leaving square holes, plus an internal cross-bar
# lattice, all in dark metal. Tipped vertex-down (~45° about Z, ~35.26° about
# X) and lifted so the bottom corner just touches the floor. The many holes —
# the lace — are the whole point: the object is mostly the gaps light pours through.

func _build_lattice() -> void:
	_rng.seed = seed
	var metal := _make_mat(color_b, 0.4, 0.7)
	# Floor disc — dark glossy, reads as still water under the suspended cube.
	var water := _make_mat(Color(color_a.r * 0.2, color_a.g * 0.2, color_a.b * 0.2),
		0.05, 0.6)
	var disc_r: float = sculpt_width * 1.4
	_add_cyl("WaterFloor", disc_r, disc_r, sculpt_height * 0.01,
		Vector3(0, sculpt_height * 0.005, 0), Vector3.ZERO, water)

	# Build the perforated cube CENTRED ON ITS OWN ORIGIN, parented to a pivot
	# node so we can tip it vertex-down and lift it as one rigid piece.
	var pivot := Node3D.new()
	pivot.name = "LatticeCube"
	add_child(pivot)

	var side: float = sculpt_width
	var half: float = side * 0.5
	var bar_t: float = side * 0.04                     # thin lattice bar
	var div: int = clampi(complexity, 3, 7)            # holes per face edge

	# Edge frame — 12 edges of the cube (thicker than the face bars).
	var edge_t: float = bar_t * 1.3
	var edge_len: float = side + edge_t
	# 4 edges along X, 4 along Y, 4 along Z.
	for sy in [half, -half]:
		for sz in [half, -half]:
			_lat_bar(pivot, metal, Vector3(0, sy, sz),
				Vector3(edge_len, edge_t, edge_t))           # X edge
	for sx in [half, -half]:
		for sz in [half, -half]:
			_lat_bar(pivot, metal, Vector3(sx, 0, sz),
				Vector3(edge_t, edge_len, edge_t))           # Y edge
	for sx in [half, -half]:
		for sy in [half, -half]:
			_lat_bar(pivot, metal, Vector3(sx, sy, 0),
				Vector3(edge_t, edge_t, edge_len))           # Z edge

	# FACE LATTICES — for each of the 6 faces a grid of (div-1) interior bars
	# in each of the two in-plane directions, leaving square holes.
	# Faces normal to Z (front/back).
	for fz in [half, -half]:
		_lat_face(pivot, metal, "Z", fz, side, bar_t, div)
	# Faces normal to X (left/right).
	for fx in [half, -half]:
		_lat_face(pivot, metal, "X", fx, side, bar_t, div)
	# Faces normal to Y (top/bottom).
	for fy in [half, -half]:
		_lat_face(pivot, metal, "Y", fy, side, bar_t, div)

	# INTERNAL CROSS-BAR LATTICE — a few bars threading through the middle so
	# the interior is not empty (a 3D lace, not just a hollow shell).
	var inner: int = clampi(div - 1, 2, 5)
	for ii in range(inner):
		var u: float = lerpf(-half * 0.55, half * 0.55, float(ii) / float(maxi(1, inner - 1)))
		_lat_bar(pivot, metal, Vector3(0, u, 0), Vector3(side * 0.9, bar_t, bar_t))
		_lat_bar(pivot, metal, Vector3(u, 0, 0), Vector3(bar_t, side * 0.9, bar_t))

	# TIP IT VERTEX-DOWN — rotate so a corner points straight down, then lift
	# the whole pivot so that bottom vertex rests near y ≈ 0.05.
	pivot.rotation = Vector3(deg_to_rad(35.264), 0.0, deg_to_rad(45.0))
	# Half the body diagonal = the distance from cube centre to a vertex.
	var body_diag_half: float = half * sqrt(3.0)
	pivot.position = Vector3(0, body_diag_half + 0.05, 0)


# One lattice bar (a thin box) added to the cube pivot.
func _lat_bar(parent: Node3D, mat: StandardMaterial3D, pos: Vector3,
		size: Vector3) -> void:
	var mi := MeshInstance3D.new()
	mi.name = "LatBar"
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)


# A perforated face: a grid of interior bars on a face of the cube, leaving
# square holes. `axis` is the face normal ("X","Y","Z"); `coord` its position
# along that axis; `side` the cube side; `div` the number of holes per edge.
func _lat_face(parent: Node3D, mat: StandardMaterial3D, axis: String,
		coord: float, side: float, bar_t: float, div: int) -> void:
	var half: float = side * 0.5
	# (div-1) interior bars in each in-plane direction, evenly spaced.
	for k in range(1, div):
		var u: float = lerpf(-half, half, float(k) / float(div))
		match axis:
			"Z":
				# Face normal Z: bars run along X (varying Y) and along Y (varying X).
				_lat_bar(parent, mat, Vector3(0, u, coord),
					Vector3(side, bar_t, bar_t))
				_lat_bar(parent, mat, Vector3(u, 0, coord),
					Vector3(bar_t, side, bar_t))
			"X":
				# Face normal X: bars run along Z (varying Y) and along Y (varying Z).
				_lat_bar(parent, mat, Vector3(coord, u, 0),
					Vector3(bar_t, bar_t, side))
				_lat_bar(parent, mat, Vector3(coord, 0, u),
					Vector3(bar_t, side, bar_t))
			"Y":
				# Face normal Y: bars run along X (varying Z) and along Z (varying X).
				_lat_bar(parent, mat, Vector3(0, coord, u),
					Vector3(side, bar_t, bar_t))
				_lat_bar(parent, mat, Vector3(u, coord, 0),
					Vector3(bar_t, bar_t, side))


# ── Mode: SPIRALSTACK (curved-tile helix on a rod) ─────────────────────
# A thin vertical ROD threaded with curved rusty TILE shards that rise and
# spiral up it by a golden-angle increment, so the stack reads as a helix of
# overlapping curved tiles. Each tile is a thin shallow box given a slight
# rotation to suggest a curved shell. Rusty metal on a dark steel rod.

func _build_spiralstack() -> void:
	_rng.seed = seed
	var rod_mat := _make_mat(color_b, 0.5, 0.7)            # dark steel rod
	# color_a reads as rusty orange-brown for the tiles.
	var tile_mat := _make_mat(color_a, 0.6, 0.5)

	# ROD — a thin vertical cylinder spanning the full height.
	var rod_r: float = sculpt_width * 0.04
	_add_cyl("SpiralRod", rod_r, rod_r, sculpt_height,
		Vector3(0, sculpt_height * 0.5, 0), Vector3.ZERO, rod_mat)

	# TILES — clampi(complexity*2, 8, 24) curved shards rising up the rod, each
	# rotated about the rod (Y) axis by the golden angle so they spiral.
	var tiles: int = clampi(complexity * 2, 8, 24)
	var golden: float = 2.399963          # golden angle (radians)
	var y0: float = sculpt_height * 0.06
	var y1: float = sculpt_height * 0.94
	var tile_r: float = sculpt_width * 0.34               # how far tiles reach out
	for i in range(tiles):
		var t: float = float(i) / float(maxi(1, tiles - 1))
		var y: float = lerpf(y0, y1, t)
		var ang: float = golden * float(i)
		# Tile size varies slightly along the height (a touch larger mid-stack).
		var size_k: float = lerpf(1.0, 0.7, t) * _rng.randf_range(0.9, 1.05)
		var tile_w: float = sculpt_width * 0.36 * size_k
		var tile_h: float = sculpt_height * 0.10 * size_k
		var tile_d: float = sculpt_width * 0.05            # thin shell
		# Each tile is parented to a pivot at the rod, rotated about Y to spiral.
		var pivot := Node3D.new()
		pivot.name = "TilePivot%d" % i
		pivot.position = Vector3(0, y, 0)
		pivot.rotation = Vector3(0, ang, 0)
		add_child(pivot)
		var tile := MeshInstance3D.new()
		tile.name = "Tile%d" % i
		var bm := BoxMesh.new()
		bm.size = Vector3(tile_w, tile_h, tile_d)
		tile.mesh = bm
		tile.material_override = tile_mat
		# Push the tile out from the rod and tilt it to suggest a curved shell.
		tile.position = Vector3(tile_r, 0, 0)
		tile.rotation = Vector3(
			0,
			0,
			deg_to_rad(_rng.randf_range(-18.0, -8.0)))     # slight curl
		# A small extra random pitch so the helix reads as overlapping shards.
		tile.rotate_object_local(Vector3.RIGHT, _rng.randf_range(-0.12, 0.12))
		pivot.add_child(tile)


# ── Mode: GRADIENTPILLAR (glossy rainbow tube from black lava) ─────────
# A smooth glossy vertical TUBE rising from a rough BLACK CRAGGY base. The
# tube is a stack of thin bands climbing through a vertical RAINBOW gradient,
# capped by a hemisphere in the top hue. The base is a jittered pile of dark
# near-black lumps the tube emerges from. The contradiction is the point:
# candy-gloss spectrum vs rough black lava.

func _build_gradientpillar() -> void:
	_rng.seed = seed
	# Near-black rough rock for the base mound.
	var rock := _make_mat(color_b, 0.95, 0.0)

	var tube_r: float = sculpt_width * 0.18
	var base_h: float = sculpt_height * 0.16              # how high the rock piles
	var tube_h: float = sculpt_height - base_h
	var bands: int = clampi(complexity, 8, 16)
	var band_h: float = tube_h / float(bands)

	# TUBE — a stack of thin glossy bands, each a step along the rainbow.
	for i in range(bands):
		var t: float = float(i) / float(maxi(1, bands - 1))    # 0 (bottom) .. 1 (top)
		var hue := Color.from_hsv(t, 0.55, 0.95)
		var band_mat := _make_mat(hue, 0.15, 0.1)              # glossy
		var y: float = base_h + band_h * (float(i) + 0.5)
		# Slight overlap (1.04) so the bands read as one continuous tube.
		_add_cyl("PillarBand%d" % i, tube_r, tube_r, band_h * 1.04,
			Vector3(0, y, 0), Vector3.ZERO, band_mat)
	# CAP — a hemisphere in the top hue closing the tube.
	var top_hue := Color.from_hsv(1.0, 0.55, 0.95)
	var cap := _add_sphere("PillarCap", tube_r,
		Vector3(0, base_h + tube_h, 0), _make_mat(top_hue, 0.15, 0.1))
	cap.scale = Vector3(1.0, 0.6, 1.0)                        # squashed dome

	# BASE — a low irregular black rock mound the tube emerges from: a jittered
	# cluster of dark lumps piled around the tube foot.
	var lumps: int = _rng.randi_range(10, 16)
	var mound_r: float = sculpt_width * 0.55
	for li in range(lumps):
		var ang: float = _rng.randf_range(0.0, TAU)
		var rad: float = mound_r * pow(_rng.randf(), 0.5)
		var lx: float = cos(ang) * rad
		var lz: float = sin(ang) * rad
		# Lumps sit lower the further out they pile from the tube foot.
		var ly: float = base_h * _rng.randf_range(0.2, 0.95) * (1.0 - rad / mound_r * 0.6)
		var lump_s: float = sculpt_width * _rng.randf_range(0.12, 0.26)
		if _rng.randf() < 0.5:
			# Craggy box lump.
			var lump := _add_box("Lava%d" % li,
				Vector3(lump_s, lump_s * _rng.randf_range(0.6, 1.1), lump_s),
				Vector3(lx, maxf(ly, lump_s * 0.3), lz),
				Vector3(_rng.randf_range(0.0, TAU), _rng.randf_range(0.0, TAU),
					_rng.randf_range(0.0, TAU)),
				rock)
		else:
			# Rounded boulder lump.
			var b := _add_sphere("LavaRock%d" % li, lump_s * 0.6,
				Vector3(lx, maxf(ly, lump_s * 0.3), lz), rock)
			b.scale = Vector3(
				_rng.randf_range(0.8, 1.3),
				_rng.randf_range(0.6, 1.0),
				_rng.randf_range(0.8, 1.3))


# ── Mode: BURST (radial spike supernova) ───────────────────────────────
# Thousands of thin tapered SPIKES radiating from a single centre into a soft
# round halo, batched as one MultiMesh of `unit_count` cylinders. Directions
# are biased toward a DISC facing +Z (a wall sunburst) with some full-sphere
# scatter, so the tips form a fuzzy disc/sphere. White/pale spikes; if
# `emissive`, a faint glowing accent hub anchors the radiation at the centre.

func _build_burst() -> void:
	_rng.seed = seed
	var spike_mat := _make_mat(color_a, 0.7, 0.0)         # white / pale

	var n: int = maxi(8, unit_count)
	var centre := Vector3(0, sculpt_height * 0.55, 0)

	# The repeated spike — a thin tapered cylinder (unit height, scaled per spike).
	var spike := CylinderMesh.new()
	spike.top_radius = sculpt_width * 0.002               # tapered tip
	spike.bottom_radius = sculpt_width * 0.012            # fatter root
	spike.height = 1.0
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = spike
	mm.instance_count = n

	for i in range(n):
		# Mostly a disc facing +Z (XY plane, small Z spread); some full scatter.
		var dir: Vector3
		if _rng.randf() < 0.75:
			# Disc spike: pick an angle in the XY plane, add a little Z depth.
			var a: float = _rng.randf_range(0.0, TAU)
			dir = Vector3(cos(a), sin(a), _rng.randf_range(-0.25, 0.25)).normalized()
		else:
			# Full-sphere scatter so the halo reads as soft, not a flat plate.
			dir = Vector3(
				_rng.randf_range(-1.0, 1.0),
				_rng.randf_range(-1.0, 1.0),
				_rng.randf_range(-1.0, 1.0)).normalized()
		var length: float = sculpt_width * _rng.randf_range(0.4, 0.6)
		# Orient the unit cylinder's +Y axis along the spike direction, scale to length.
		var up := Vector3.UP
		var basis := Basis()
		var axis := up.cross(dir)
		if axis.length() > 0.0001:
			basis = Basis(axis.normalized(), acos(clampf(up.dot(dir), -1.0, 1.0)))
		else:
			# dir is (anti)parallel to UP — flip if pointing straight down.
			if dir.dot(up) < 0.0:
				basis = Basis(Vector3.RIGHT, PI)
		basis = basis.scaled(Vector3(1.0, length, 1.0))
		# Place the spike's MIDPOINT half a length out from the centre so the
		# root sits at the hub and the tip reaches into the halo.
		var pos: Vector3 = centre + dir * (length * 0.5)
		mm.set_instance_transform(i, Transform3D(basis, pos))

	var mmi := MultiMeshInstance3D.new()
	mmi.name = "BurstSpikes"
	mmi.multimesh = mm
	mmi.material_override = spike_mat
	add_child(mmi)

	# HUB — a small sphere anchoring the radiation at the centre; faint emissive
	# accent when `emissive`, otherwise a plain pale core.
	var hub_mat: StandardMaterial3D
	if emissive:
		hub_mat = _make_emissive_mat(accent, 0.6)
	else:
		hub_mat = _make_mat(color_a, 0.6, 0.0)
	_add_sphere("BurstHub", sculpt_width * 0.08, centre, hub_mat)


# ── Mode: LUMICANOPY (giant glowing mushroom canopy + radiating strands) ─
# A tapered teardrop STEM rises to ~60% height; a flattened domed CANOPY
# (a squashed hemisphere ringed by puffy lobe spheres) caps it. The signature
# is the RADIATING LIGHT-STRANDS — emissive threads sweeping from the stem-top
# centre out and down across the dome's UNDERSIDE to its rim, like glowing gills.
# Soft knit-rose membrane lit from within: a fungal lantern.

func _build_lumicanopy() -> void:
	_rng.seed = seed
	var flesh := _make_mat(color_a, 0.6, 0.0)                 # soft knit rose / mauve
	var glow := _make_emissive_mat(accent, 2.2)               # cyan/magenta strand glow

	# STEM — a tapered teardrop column: a vertical stack of scaled spheres that
	# widen toward a mid-bulge then narrow to the canopy mount, plus a cylinder
	# core so the silhouette reads as one continuous fleshy stalk.
	var stem_top: float = sculpt_height * 0.6
	var stem_r: float = sculpt_width * 0.16
	# Core cylinder for body (tapered: fatter low, narrow high).
	_add_cyl("CanopyStem", stem_r * 0.7, stem_r * 1.05, stem_top,
		Vector3(0, stem_top * 0.5, 0), Vector3.ZERO, flesh)
	# Stacked bulge spheres along the stem to give the teardrop swell.
	var stem_beads: int = maxi(4, complexity)
	for i in range(stem_beads):
		var t: float = float(i) / float(maxi(1, stem_beads - 1))   # 0 (foot) .. 1 (neck)
		var y: float = stem_top * lerpf(0.08, 0.92, t)
		# Widen toward the lower third (the teardrop belly), narrow at the neck.
		var bulge: float = sin(clampf(t, 0.0, 1.0) * PI) * 0.6 + 0.55
		var br: float = stem_r * bulge * (1.0 - 0.35 * t)
		var bead := _add_sphere("StemBulge%d" % i, br, Vector3(0, y, 0), flesh)
		bead.scale = Vector3(1.0, 1.15, 1.0)

	# CANOPY — a flattened domed hemisphere at the stem top, radius ~sculpt_width.
	var canopy_r: float = sculpt_width
	var canopy_y: float = stem_top
	var dome := _add_sphere("Canopy", canopy_r, Vector3(0, canopy_y, 0), flesh)
	dome.scale = Vector3(1.0, 0.5, 1.0)                       # flattened dome
	# SCALLOPED RIM — a ring of small puffy lobe spheres around the dome edge.
	var lobes: int = clampi(complexity * 2, 8, 16)
	var lobe_r: float = canopy_r * 0.18
	for li in range(lobes):
		var lang: float = TAU * float(li) / float(lobes)
		# Sit lobes just inside the rim radius, dipping slightly below the dome's
		# equator so they read as puffy scallops hanging off the edge.
		var lr: float = canopy_r * 0.94
		var lpos := Vector3(cos(lang) * lr,
			canopy_y - canopy_r * 0.06 + _rng.randf_range(-1.0, 1.0) * lobe_r * 0.2,
			sin(lang) * lr)
		var lobe := _add_sphere("CanopyLobe%d" % li,
			lobe_r * _rng.randf_range(0.85, 1.15), lpos, flesh)
		lobe.scale = Vector3(1.0, 0.7, 1.0)

	# RADIATING LIGHT-STRANDS — the signature. From the stem-top centre, many
	# thin emissive strands sweep outward and DOWN across the dome's underside to
	# its rim, evenly distributed around the circle (the glowing gills).
	var strands: int = clampi(complexity * 5, 18, 48)
	var hub := Vector3(0, canopy_y, 0)
	var rim_drop: float = canopy_r * 0.42                     # how far the rim hangs below centre
	var strand_r: float = canopy_r * 0.012
	for si in range(strands):
		var sang: float = TAU * float(si) / float(strands)
		var dirx: float = cos(sang)
		var dirz: float = sin(sang)
		# A mid control point bulges the strand down along the dome's curve, and
		# the end lands at the rim, dropped below the hub — a gentle outward sweep.
		var mid := Vector3(dirx * canopy_r * 0.55,
			canopy_y - canopy_r * 0.14, dirz * canopy_r * 0.55)
		var rim := Vector3(dirx * canopy_r * 0.97,
			canopy_y - rim_drop, dirz * canopy_r * 0.97)
		_add_strand(hub, mid, glow, strand_r)
		_add_strand(mid, rim, glow, strand_r)


# ── Mode: BIOREACTOR (The Living / EcoLogicStudio — algae photobioreactor) ─
# A biomorphic WHITE TOWER (a stack of lumpy translucent ellipsoids) skinned in
# a TRIANGULATED white LATTICE (a MultiMesh of small tetra cell-units scattered
# over the surface, like a 3D-printed shell) with GREEN ALGAE pockets — clusters
# of small glowing green blobs nestled in the lattice. Machine-ecology: a living
# culture grown inside a printed architecture.

func _build_bioreactor() -> void:
	_rng.seed = seed
	# Near-white translucent wax membrane for the organic column body.
	var pale := color_a.lerp(Color(0.95, 0.96, 0.97), 0.5)
	var body_mat := _mat_wax(pale)
	body_mat.roughness = 0.4
	var cell_mat := _make_mat(pale, 0.5, 0.0)                 # white lattice cells
	var algae_mat := _make_emissive_mat(Color(0.45, 0.95, 0.35), 0.7)   # living green glow

	# TOWER — an irregular lumpy vertical column: a stack of scaled ellipsoids
	# with horizontal jitter and varying radius forming an organic shell. Record
	# each lobe's centre + radius so lattice cells and algae can cling to the surface.
	var segs: int = clampi(complexity, 6, 12)
	var col_r: float = sculpt_width * 0.42
	var lobe_centres: Array[Vector3] = []
	var lobe_radii: Array[float] = []
	for i in range(segs):
		var t: float = float(i) / float(maxi(1, segs - 1))    # 0 (foot) .. 1 (crown)
		var y: float = sculpt_height * lerpf(0.06, 0.94, t)
		# Radius pinches and swells along the height (organic, not a clean taper).
		var swell: float = 0.75 + 0.35 * sin(t * PI * 1.7 + 0.5)
		var lr: float = col_r * swell * _rng.randf_range(0.9, 1.08)
		var jx: float = _rng.randf_range(-1.0, 1.0) * col_r * 0.18
		var jz: float = _rng.randf_range(-1.0, 1.0) * col_r * 0.18
		var c := Vector3(jx, y, jz)
		var lobe := _add_sphere("BioCol%d" % i, lr, c, body_mat)
		lobe.scale = Vector3(
			_rng.randf_range(0.9, 1.15), _rng.randf_range(1.0, 1.3),
			_rng.randf_range(0.9, 1.15))
		lobe_centres.append(c)
		lobe_radii.append(lr)

	# Helper closure: sample a point + outward normal on the lumpy column surface.
	# (Picks a host lobe, a random direction, returns surface point and its normal.)
	var sample_surface := func(rng: RandomNumberGenerator) -> Array:
		var hi: int = rng.randi_range(0, lobe_centres.size() - 1)
		var c: Vector3 = lobe_centres[hi]
		var lr: float = lobe_radii[hi]
		var d := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-0.6, 0.8),
			rng.randf_range(-1.0, 1.0)).normalized()
		return [c + d * lr, d]

	# TRIANGULATED LATTICE SKIN — a MultiMesh of small flat tetra/pyramid cell
	# units scattered over the column surface, each tipped to lie against the
	# shell, reading as a 3D-printed triangulated mesh.
	var cells: int = maxi(8, unit_count)
	var cell := PrismMesh.new()                               # a 3-sided wedge reads as a printed cell
	cell.size = Vector3(sculpt_width * 0.10, sculpt_width * 0.05, sculpt_width * 0.10)
	var cmm := MultiMesh.new()
	cmm.transform_format = MultiMesh.TRANSFORM_3D
	cmm.mesh = cell
	cmm.instance_count = cells
	for i in range(cells):
		var hit: Array = sample_surface.call(_rng)
		var p: Vector3 = hit[0]
		var nrm: Vector3 = hit[1]
		# Orient the cell so its +Y faces along the surface normal, with spin jitter.
		var basis := Basis()
		var up := Vector3.UP
		var axis := up.cross(nrm)
		if axis.length() > 0.0001:
			basis = Basis(axis.normalized(), acos(clampf(up.dot(nrm), -1.0, 1.0)))
		basis = basis.rotated(nrm, _rng.randf_range(0.0, TAU))
		var s: float = _rng.randf_range(0.8, 1.3)
		basis = basis.scaled(Vector3(s, s, s))
		cmm.set_instance_transform(i, Transform3D(basis, p + nrm * sculpt_width * 0.01))
	var cmmi := MultiMeshInstance3D.new()
	cmmi.name = "LatticeSkin"
	cmmi.multimesh = cmm
	cmmi.material_override = cell_mat
	add_child(cmmi)

	# GREEN ALGAE POCKETS — clusters of small glowing green blobs nestled in the
	# lattice across the surface (the living culture inside the printed shell).
	var pockets: int = clampi(complexity * 3, 12, 30)
	for pi in range(pockets):
		var hit2: Array = sample_surface.call(_rng)
		var base: Vector3 = hit2[0]
		var nrm2: Vector3 = hit2[1]
		# Each pocket is a small cluster of 2-4 green blobs huddled together.
		var blobs: int = _rng.randi_range(2, 4)
		for bi in range(blobs):
			var jitter := Vector3(_rng.randf_range(-1.0, 1.0),
				_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)) \
				* sculpt_width * 0.05
			var br2: float = sculpt_width * _rng.randf_range(0.03, 0.06)
			_add_sphere("Algae%d_%d" % [pi, bi], br2,
				base + nrm2 * (sculpt_width * 0.02) + jitter, algae_mat)


# ── Mode: NETCAVE (Ernesto Neto — draped overhead crochet net-cave) ────────
# A sagging OVERHEAD canopy (not a tower): an OPEN crochet net membrane drooping
# in a catenary over the footprint, built as a MultiMesh of small link units with
# visible gaps, MULTICOLOUR across the sheet (orange→red→green by position). A few
# warm ANCHOR TENDRILS drape from the membrane to the floor, each ending in a dark
# fibrous CLUMP. The space underneath stays open — a soft coloured cave overhead.

func _build_netcave() -> void:
	_rng.seed = seed
	var tendril_mat := _make_mat(color_a, 0.7, 0.0)           # warm net-colour fibre
	var clump_mat := _make_mat(color_b, 0.95, 0.0)            # dark near-black fibrous mass

	# DRAPED MEMBRANE — an open net sheet sagging in a gentle catenary at
	# ~sculpt_height, built as a MultiMesh of small link units over a grid. The
	# sheet dips lowest at centre and lifts toward the edges (held up at corners).
	var n: int = maxi(16, unit_count)
	var grid: int = maxi(4, int(round(sqrt(float(n)))))
	var total: int = grid * grid
	var half: float = sculpt_width * 0.7                      # half-span of the sheet
	var rim_y: float = sculpt_height                          # edge height of the canopy
	var sag: float = sculpt_height * 0.34                     # how far the centre droops

	# The repeated crochet "link" — a small flat box; gaps between links read as
	# the open weave.
	var link := BoxMesh.new()
	link.size = Vector3(sculpt_width * 0.05, sculpt_width * 0.015, sculpt_width * 0.05)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = link
	mm.instance_count = total
	# Record the sagging surface height at each (gx,gz) so tendrils can hang off it.
	var idx: int = 0
	for gx in range(grid):
		for gz in range(grid):
			var fx: float = float(gx) / float(maxi(1, grid - 1))   # 0..1
			var fz: float = float(gz) / float(maxi(1, grid - 1))
			var px: float = lerpf(-half, half, fx)
			var pz: float = lerpf(-half, half, fz)
			# Catenary-ish dip: deepest at centre (fx,fz=0.5), lifting to the rim.
			var dx: float = (fx - 0.5) * 2.0                       # -1..1
			var dz: float = (fz - 0.5) * 2.0
			var droop: float = (1.0 - (dx * dx + dz * dz) * 0.5)   # 1 centre .. ~0 corners
			droop = clampf(droop, 0.0, 1.0)
			var py: float = rim_y - sag * droop \
				+ _rng.randf_range(-1.0, 1.0) * sculpt_width * 0.01
			# Slight per-link tilt so the weave reads as soft cloth, not a rigid grid.
			var basis := Basis()
			basis = basis.rotated(Vector3.UP, _rng.randf_range(0.0, TAU))
			basis = basis.rotated(Vector3.RIGHT, _rng.randf_range(-0.2, 0.2))
			basis = basis.rotated(Vector3.FORWARD, _rng.randf_range(-0.2, 0.2))
			mm.set_instance_transform(idx, Transform3D(basis, Vector3(px, py, pz)))
			# MULTICOLOUR — slide hue across the sheet by x/z position
			# (orange ~0.08 → red ~0.0/0.97 → green ~0.33).
			var hue: float = fposmod(0.08 + fx * 0.25 + fz * 0.18, 1.0)
			mm.set_instance_color(idx, Color.from_hsv(hue, 0.8, 0.95))
			idx += 1
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "NetMembrane"
	mmi.multimesh = mm
	var net_mat := StandardMaterial3D.new()
	net_mat.vertex_color_use_as_albedo = true
	net_mat.roughness = 0.7
	net_mat.metallic = 0.0
	mmi.material_override = net_mat
	add_child(mmi)

	# ANCHOR TENDRILS — a few warm tendrils draping from the membrane down to the
	# floor, each ending in a dark fibrous clump. They descend from points spread
	# across the sheet (toward its sagging centre), leaving the space under open.
	var tendrils: int = clampi(complexity, 3, 6)
	for ti in range(tendrils):
		var ang: float = TAU * float(ti) / float(tendrils) + _rng.randf_range(-0.25, 0.25)
		# Hang point partway out on the sheet (where it sags toward the floor).
		var hr: float = half * _rng.randf_range(0.25, 0.7)
		var hx: float = cos(ang) * hr
		var hz: float = sin(ang) * hr
		# Surface height at the hang point (same catenary as the membrane).
		var hdx: float = hx / half
		var hdz: float = hz / half
		var hdroop: float = clampf(1.0 - (hdx * hdx + hdz * hdz) * 0.5, 0.0, 1.0)
		var hang_y: float = rim_y - sag * hdroop
		var hang := Vector3(hx, hang_y, hz)
		# Floor foot drifts a little outward from the hang point.
		var foot := Vector3(hx + _rng.randf_range(-1.0, 1.0) * half * 0.12,
			0.0, hz + _rng.randf_range(-1.0, 1.0) * half * 0.12)
		# Two-segment tapered drape (a slight elbow) so the tendril reads as soft.
		var mid := hang.lerp(foot, 0.5) + Vector3(
			_rng.randf_range(-1.0, 1.0) * half * 0.06,
			_rng.randf_range(-0.03, 0.03) * sculpt_height,
			_rng.randf_range(-1.0, 1.0) * half * 0.06)
		var upper := _add_cyl("Tendril%d_up" % ti, sculpt_width * 0.018,
			sculpt_width * 0.03, hang.distance_to(mid),
			(hang + mid) * 0.5, Vector3.ZERO, tendril_mat)
		_orient_between(upper, hang, mid)
		var lower := _add_cyl("Tendril%d_lo" % ti, sculpt_width * 0.03,
			sculpt_width * 0.05, mid.distance_to(foot),
			(mid + foot) * 0.5, Vector3.ZERO, tendril_mat)
		_orient_between(lower, mid, foot)
		# DARK FIBROUS CLUMP — a lumpy dark mass of jittered spheres on the floor.
		var clump_lumps: int = _rng.randi_range(4, 7)
		var clump_r: float = sculpt_width * 0.12
		for ci in range(clump_lumps):
			var jitter := Vector3(_rng.randf_range(-1.0, 1.0),
				_rng.randf_range(0.0, 0.6), _rng.randf_range(-1.0, 1.0)) * clump_r
			var lump_r: float = clump_r * _rng.randf_range(0.4, 0.7)
			var lump := _add_sphere("Clump%d_%d" % [ti, ci], lump_r,
				foot + Vector3(0, lump_r * 0.5, 0) + jitter, clump_mat)
			lump.scale = Vector3(
				_rng.randf_range(0.9, 1.3), _rng.randf_range(0.7, 1.0),
				_rng.randf_range(0.9, 1.3))


# Orient a cylinder MeshInstance3D so its +Y axis runs from p0 to p1 (already
# positioned at the midpoint with height = the distance between them).
func _orient_between(mi: MeshInstance3D, p0: Vector3, p1: Vector3) -> void:
	var dir := (p1 - p0)
	if dir.length() < 0.0001:
		return
	dir = dir.normalized()
	var up := Vector3.UP
	if absf(dir.dot(up)) > 0.999:
		up = Vector3.RIGHT
	var axis := up.cross(dir)
	if axis.length() > 0.0001:
		mi.basis = Basis(axis.normalized(), acos(clampf(up.dot(dir), -1.0, 1.0)))


# ── Mode: PIGMENT (Anish Kapoor "1000 Names" / Wolfgang Laib — pigment mound) ─
# A smooth CONE of pure saturated pigment with a thin wide loose-powder "spill"
# skirt at its base and 1-2 smaller satellite cones nearby. VERY matte (full
# roughness, zero metal, no glow) so it reads as raw loose powder, not a glazed
# solid. Pure, minimal, intense — colour as pure material.

func _build_pigment() -> void:
	_rng.seed = seed
	# Full-roughness, zero-metal matte pigment — colour as pure powder.
	var pigment := _make_mat(color_a, 1.0, 0.0)

	# MAIN CONE — a CylinderMesh with top_radius 0 (a true cone) of pigment.
	var base_r: float = sculpt_width * 0.5
	var cone_h: float = sculpt_height
	_add_cyl("PigmentCone", 0.0, base_r, cone_h,
		Vector3(0, cone_h * 0.5, 0), Vector3.ZERO, pigment)

	# SPILL SKIRT — a very flat wide cylinder hugging the floor so the mound
	# reads as loose powder spreading out from under the cone.
	var skirt_r: float = base_r * 1.35
	var skirt_h: float = sculpt_height * 0.02
	_add_cyl("PigmentSpill", skirt_r * 0.96, skirt_r, skirt_h,
		Vector3(0, skirt_h * 0.5, 0), Vector3.ZERO, pigment)

	# SATELLITES — 1-2 smaller pigment cones nearby (seed-jittered), each with
	# its own small spill, so the floor reads as a scattered pigment offering.
	var sats: int = 1 + (seed % 2)
	for si in range(sats):
		var ang: float = _rng.randf_range(0.0, TAU)
		var dist: float = base_r * _rng.randf_range(1.4, 2.0)
		var cx: float = cos(ang) * dist
		var cz: float = sin(ang) * dist
		var sr: float = base_r * _rng.randf_range(0.3, 0.5)
		var sh: float = cone_h * _rng.randf_range(0.35, 0.6)
		_add_cyl("PigmentSat%d" % si, 0.0, sr, sh,
			Vector3(cx, sh * 0.5, cz), Vector3.ZERO, pigment)
		# A small spill under each satellite cone.
		var ssr: float = sr * 1.3
		_add_cyl("PigmentSatSpill%d" % si, ssr * 0.96, ssr, skirt_h,
			Vector3(cx, skirt_h * 0.5, cz), Vector3.ZERO, pigment)


# ── Mode: COLORFIELD (Emmanuelle Moureaux — suspended rainbow cube-grid) ───
# A floating VOLUME of small colour cubes on a 3D grid (with gaps) filling a box
# above the floor, the per-instance hue sliding along one axis so the whole field
# reads as a suspended rainbow gradient. One MultiMesh batch with per-instance
# colour. Immersive, weightless, chromatic.

func _build_colorfield() -> void:
	_rng.seed = seed
	var n: int = maxi(8, unit_count)
	# Roughly cube-root the count into nx x ny x nz grid dims.
	var side_n: int = maxi(2, int(round(pow(float(n), 1.0 / 3.0))))
	var nx: int = side_n
	var ny: int = side_n
	var nz: int = side_n
	var total: int = nx * ny * nz

	# The repeated small cube.
	var cube_s: float = 0.05
	var cube := BoxMesh.new()
	cube.size = Vector3(cube_s, cube_s, cube_s)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = cube
	mm.instance_count = total

	# The volume the cubes fill: sculpt_width wide/deep, sculpt_height tall,
	# floated above the floor with a small lift so it reads as suspended.
	var vol_w: float = sculpt_width
	var vol_d: float = sculpt_width
	var vol_h: float = sculpt_height
	var lift: float = sculpt_height * 0.12              # gap under the field
	var idx: int = 0
	for ix in range(nx):
		for iy in range(ny):
			for iz in range(nz):
				var fx: float = float(ix) / float(maxi(1, nx - 1))
				var fy: float = float(iy) / float(maxi(1, ny - 1))
				var fz: float = float(iz) / float(maxi(1, nz - 1))
				var px: float = lerpf(-vol_w * 0.5, vol_w * 0.5, fx)
				var py: float = lift + fy * vol_h
				var pz: float = lerpf(-vol_d * 0.5, vol_d * 0.5, fz)
				var basis := Basis()                       # gaps come from grid pitch > cube size
				mm.set_instance_transform(idx, Transform3D(basis, Vector3(px, py, pz)))
				# Rainbow slides along the vertical axis through the volume.
				var t: float = fy
				mm.set_instance_color(idx, Color.from_hsv(t, 0.85, 1.0))
				idx += 1
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "ColorField"
	mmi.multimesh = mm
	var field_mat := StandardMaterial3D.new()
	field_mat.vertex_color_use_as_albedo = true
	field_mat.roughness = 0.5
	field_mat.metallic = 0.0
	mmi.material_override = field_mat
	add_child(mmi)


# ── Mode: REEDBED (bamboo thicket on a grass patch) ────────────────────────
# A low irregular green GRASS pad on the floor from which rise many tall thin
# VERTICAL bamboo POLES with slight leans + position jitter, plus a few short
# grass blades. A vertical reed-thicket: warm bamboo tan over grass green.

func _build_reedbed() -> void:
	_rng.seed = seed
	var grass_mat := _make_mat(color_b, 0.85, 0.0)            # grass green pad
	var bamboo_mat := _make_mat(color_a, 0.55, 0.0)           # warm bamboo tan

	# GRASS PAD — a wide flat low cylinder hugging the floor.
	var pad_r: float = sculpt_width * 0.55
	var pad_h: float = sculpt_height * 0.03
	_add_cyl("GrassPad", pad_r * 0.98, pad_r, pad_h,
		Vector3(0, pad_h * 0.5, 0), Vector3.ZERO, grass_mat)

	# POLES — many thin vertical bamboo cylinders rising from the pad, with
	# varied height, a small lean, and position jitter within the pad radius.
	var poles: int = clampi(unit_count, 30, 90)
	var pole_r: float = sculpt_width * 0.018
	for i in range(poles):
		var ang: float = _rng.randf_range(0.0, TAU)
		var rad: float = pad_r * 0.9 * sqrt(_rng.randf())     # even fill across the pad
		var px: float = cos(ang) * rad
		var pz: float = sin(ang) * rad
		var ph: float = sculpt_height * _rng.randf_range(0.4, 1.0)
		var lean := Vector3(
			_rng.randf_range(-1.0, 1.0) * deg_to_rad(6.0),
			0,
			_rng.randf_range(-1.0, 1.0) * deg_to_rad(6.0))
		_add_cyl("Reed%d" % i, pole_r * 0.85, pole_r, ph,
			Vector3(px, pad_h + ph * 0.5, pz), lean, bamboo_mat)

	# GRASS BLADES — a few short thin upright blades scattered on the pad for
	# ground texture under the reeds.
	var blades: int = _rng.randi_range(10, 18)
	for bi in range(blades):
		var bang: float = _rng.randf_range(0.0, TAU)
		var brad: float = pad_r * 0.9 * sqrt(_rng.randf())
		var bx: float = cos(bang) * brad
		var bz: float = sin(bang) * brad
		var bh: float = sculpt_height * _rng.randf_range(0.05, 0.12)
		var btilt := Vector3(
			_rng.randf_range(-1.0, 1.0) * deg_to_rad(20.0),
			_rng.randf_range(0.0, TAU),
			_rng.randf_range(-1.0, 1.0) * deg_to_rad(20.0))
		_add_box("Blade%d" % bi,
			Vector3(sculpt_width * 0.01, bh, sculpt_width * 0.01),
			Vector3(bx, pad_h + bh * 0.5, bz), btilt, grass_mat)


# ── Mode: DOTGOURD (Yayoi Kusama — dotted pumpkin) ─────────────────────────
# A squashed ribbed GOURD covered in dark polka DOTS. Body: a flattened sphere
# given pumpkin RIBS by a ring of vertical lobe-bulge spheres around the equator;
# a short stubby curved STEM on top; and a MultiMesh of small dark flattened
# discs scattered over the body surface. Iconic Kusama yellow + near-black dots.

func _build_dotgourd() -> void:
	_rng.seed = seed
	var body_mat := _make_mat(color_a, 0.5, 0.0)             # Kusama yellow
	var dot_mat := _make_mat(color_b, 0.5, 0.0)             # near-black dots
	var stem_mat := _make_mat(Color(0.18, 0.32, 0.12), 0.7, 0.0)   # dark green stem

	# BODY — a flattened sphere; record its scaled radii so ribs and dots cling.
	var body_r: float = sculpt_width * 0.5
	var squash: float = 0.8                                  # vertical squash
	var body_cy: float = body_r * squash                    # body centre height
	var body := _add_sphere("GourdBody", body_r,
		Vector3(0, body_cy, 0), body_mat)
	body.scale = Vector3(1.0, squash, 1.0)

	# RIBS — 8-12 thin vertical lobe bulges around the equator, each a small
	# scaled sphere sitting just proud of the body so it reads as a pumpkin.
	var ribs: int = _rng.randi_range(8, 12)
	for ri in range(ribs):
		var ang: float = TAU * float(ri) / float(ribs)
		var lobe := _add_sphere("GourdRib%d" % ri, body_r * 0.5,
			Vector3(cos(ang) * body_r * 0.92, body_cy, sin(ang) * body_r * 0.92),
			body_mat)
		# Tall thin lobe hugging the body — the pumpkin's vertical ridge.
		lobe.scale = Vector3(0.45, squash * 1.12, 0.45)

	# STEM — a short stubby curved stem on top (two stacked small cylinders, the
	# upper one tilted, so it reads as a bent pumpkin stalk).
	var stem_y: float = body_cy + body_r * squash * 0.9
	var stem_r: float = sculpt_width * 0.05
	var stem_h: float = sculpt_height * 0.1
	_add_cyl("GourdStem", stem_r * 0.8, stem_r, stem_h,
		Vector3(0, stem_y + stem_h * 0.5, 0), Vector3.ZERO, stem_mat)
	_add_cyl("GourdStemTip", stem_r * 0.6, stem_r * 0.8, stem_h * 0.8,
		Vector3(stem_h * 0.25, stem_y + stem_h * 1.1, 0),
		Vector3(0, 0, deg_to_rad(-35.0)), stem_mat)

	# DOTS — a MultiMesh of small dark flattened discs scattered over the body
	# surface (a sphere is the host; each dot tipped flat against the surface).
	var dots: int = _rng.randi_range(80, 150)
	var dot := CylinderMesh.new()                            # a flat disc dot
	dot.top_radius = sculpt_width * 0.035
	dot.bottom_radius = sculpt_width * 0.035
	dot.height = sculpt_width * 0.01
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = dot
	mm.instance_count = dots
	for i in range(dots):
		# Pick a direction; map it onto the squashed body surface.
		var d := Vector3(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-0.7, 0.9),
			_rng.randf_range(-1.0, 1.0)).normalized()
		var surf := Vector3(d.x * body_r, body_cy + d.y * body_r * squash, d.z * body_r)
		# Outward normal of the squashed ellipsoid (account for the Y squash).
		var nrm := Vector3(d.x, d.y / maxf(squash, 0.001), d.z).normalized()
		var basis := Basis()
		var up := Vector3.UP
		var axis := up.cross(nrm)
		if axis.length() > 0.0001:
			basis = Basis(axis.normalized(), acos(clampf(up.dot(nrm), -1.0, 1.0)))
		var s: float = _rng.randf_range(0.7, 1.2)
		basis = basis.scaled(Vector3(s, 1.0, s))
		mm.set_instance_transform(i, Transform3D(basis, surf + nrm * sculpt_width * 0.006))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "GourdDots"
	mmi.multimesh = mm
	mmi.material_override = dot_mat
	add_child(mmi)


# ── Mode: STRUTFIELD (crossing timber beams on bases) ──────────────────────
# A FIELD of crossing wooden STRUTS across the footprint: many long thin bars at
# varied positions / heights / angles — some leaning, some horizontal resting on
# short vertical posts — a chaotic constructive timber lattice. Light pine bars
# over small dark base plates under the support posts. Read as crossing chaos.

func _build_strutfield() -> void:
	_rng.seed = seed
	var pine := _make_mat(color_a, 0.7, 0.0)                 # light pine bars
	var base_mat := _make_mat(color_b, 0.4, 0.3)            # dark base plates

	var bars: int = clampi(complexity * 5, 20, 60)
	var foot: float = sculpt_width                          # half-footprint reach
	var bar_t: float = 0.04
	for i in range(bars):
		var bx: float = _rng.randf_range(-1.0, 1.0) * foot * 0.45
		var bz: float = _rng.randf_range(-1.0, 1.0) * foot * 0.45
		var length: float = _rng.randf_range(0.4, 1.0)
		# Mix of three constructive attitudes: leaning, horizontal-on-posts, upright.
		var pick: int = i % 3
		if pick == 0:
			# LEANING bar — tilted strut crossing the field at an angle.
			var by: float = sculpt_height * _rng.randf_range(0.2, 0.7)
			var tilt := Vector3(
				_rng.randf_range(-1.0, 1.0) * deg_to_rad(55.0),
				_rng.randf_range(0.0, TAU),
				_rng.randf_range(-1.0, 1.0) * deg_to_rad(55.0))
			_add_box("Strut%d" % i, Vector3(bar_t, bar_t, length),
				Vector3(bx, by, bz), tilt, pine)
		elif pick == 1:
			# HORIZONTAL bar resting on two short vertical posts (+ base plates).
			var post_h: float = sculpt_height * _rng.randf_range(0.18, 0.5)
			var yaw: float = _rng.randf_range(0.0, TAU)
			var hd := Vector3(cos(yaw), 0, sin(yaw)) * (length * 0.5)
			var a := Vector3(bx - hd.x, 0, bz - hd.z)
			var b := Vector3(bx + hd.x, 0, bz + hd.z)
			# The two support posts.
			_add_box("StrutPost%d_a" % i, Vector3(bar_t, post_h, bar_t),
				Vector3(a.x, post_h * 0.5, a.z), Vector3.ZERO, pine)
			_add_box("StrutPost%d_b" % i, Vector3(bar_t, post_h, bar_t),
				Vector3(b.x, post_h * 0.5, b.z), Vector3.ZERO, pine)
			# Dark base plates under each post.
			var plate := Vector3(bar_t * 2.4, sculpt_height * 0.02, bar_t * 2.4)
			_add_box("StrutBase%d_a" % i, plate,
				Vector3(a.x, plate.y * 0.5, a.z), Vector3.ZERO, base_mat)
			_add_box("StrutBase%d_b" % i, plate,
				Vector3(b.x, plate.y * 0.5, b.z), Vector3.ZERO, base_mat)
			# The horizontal bar laid across the post tops.
			_add_box("Strut%d" % i, Vector3(bar_t, bar_t, length),
				Vector3(bx, post_h, bz), Vector3(0, yaw, 0), pine)
		else:
			# UPRIGHT-ish leaning post planted on a base plate.
			var up_h: float = sculpt_height * _rng.randf_range(0.4, 0.95)
			var lean := Vector3(
				_rng.randf_range(-1.0, 1.0) * deg_to_rad(18.0),
				_rng.randf_range(0.0, TAU),
				_rng.randf_range(-1.0, 1.0) * deg_to_rad(18.0))
			_add_box("Strut%d" % i, Vector3(bar_t, up_h, bar_t),
				Vector3(bx, up_h * 0.5, bz), lean, pine)
			var plate2 := Vector3(bar_t * 2.6, sculpt_height * 0.02, bar_t * 2.6)
			_add_box("StrutBase%d" % i, plate2,
				Vector3(bx, plate2.y * 0.5, bz), Vector3.ZERO, base_mat)


# ── Mode: HORNGARDEN (coloured megaphone / horn array on stems) ────────────
# A cluster of bright POP-coloured HORNS — flared funnel bells on narrow throats
# — each mounted atop a thin dark STEM rising from the floor, tilted in varied
# directions. Colours cycle through a fixed red/yellow/green/blue/white array; a
# small glowing disc sits in each bell mouth when `emissive`. Playful pop cluster.

func _build_horngarden() -> void:
	_rng.seed = seed
	var stem_mat := _make_mat(color_b, 0.5, 0.2)             # thin dark stem
	# Fixed bright pop palette cycled per horn index.
	var pop: Array[Color] = [
		Color(0.85, 0.12, 0.12),   # red
		Color(0.92, 0.80, 0.12),   # yellow
		Color(0.16, 0.62, 0.24),   # green
		Color(0.14, 0.34, 0.78),   # blue
		Color(0.94, 0.94, 0.92)]   # white

	var horns: int = clampi(complexity * 2, 6, 16)
	var foot: float = sculpt_width                           # footprint reach
	for i in range(horns):
		var col: Color = pop[i % pop.size()]
		var horn_mat := _make_mat(col, 0.4, 0.0)
		# Stem placement + height across the footprint.
		var ang: float = TAU * float(i) / float(horns) + _rng.randf_range(-0.25, 0.25)
		var rad: float = foot * 0.5 * sqrt(_rng.randf())
		var sx: float = cos(ang) * rad
		var sz: float = sin(ang) * rad
		var stem_h: float = sculpt_height * _rng.randf_range(0.45, 0.85)
		var stem_r: float = sculpt_width * 0.025
		_add_cyl("HornStem%d" % i, stem_r * 0.8, stem_r, stem_h,
			Vector3(sx, stem_h * 0.5, sz), Vector3.ZERO, stem_mat)

		# Horn mounted on a tilted pivot at the stem top.
		var pivot := Node3D.new()
		pivot.name = "HornPivot%d" % i
		pivot.position = Vector3(sx, stem_h, sz)
		pivot.rotation = Vector3(
			_rng.randf_range(-1.0, 1.0) * deg_to_rad(45.0),
			_rng.randf_range(0.0, TAU),
			_rng.randf_range(-1.0, 1.0) * deg_to_rad(45.0))
		add_child(pivot)

		# Horn geometry (local +Y points "out" of the bell along the pivot tilt).
		var bell_r: float = sculpt_width * _rng.randf_range(0.16, 0.24)
		var bell_h: float = sculpt_width * 0.22
		var throat_r: float = bell_r * 0.18
		var throat_h: float = sculpt_width * 0.14
		# THROAT — a short narrow cylinder at the base of the horn.
		var throat := MeshInstance3D.new()
		throat.name = "HornThroat%d" % i
		var thm := CylinderMesh.new()
		thm.top_radius = throat_r * 1.3
		thm.bottom_radius = throat_r
		thm.height = throat_h
		throat.mesh = thm
		throat.material_override = horn_mat
		throat.position = Vector3(0, throat_h * 0.5, 0)
		pivot.add_child(throat)
		# BELL — a flared funnel: bottom_radius small (throat) -> top_radius large.
		var bell := MeshInstance3D.new()
		bell.name = "HornBell%d" % i
		var bm := CylinderMesh.new()
		bm.top_radius = bell_r
		bm.bottom_radius = throat_r * 1.3
		bm.height = bell_h
		bell.mesh = bm
		bell.material_override = horn_mat
		bell.position = Vector3(0, throat_h + bell_h * 0.5, 0)
		pivot.add_child(bell)

		# GLOWING MOUTH — a small emissive disc set in the bell opening.
		if emissive:
			var glow_mat := _make_emissive_mat(accent, 1.2)
			var glow := MeshInstance3D.new()
			glow.name = "HornGlow%d" % i
			var gm := CylinderMesh.new()
			gm.top_radius = bell_r * 0.85
			gm.bottom_radius = bell_r * 0.85
			gm.height = sculpt_width * 0.006
			glow.mesh = gm
			glow.material_override = glow_mat
			glow.position = Vector3(0, throat_h + bell_h * 0.96, 0)
			pivot.add_child(glow)


# ── Mode: FABRICARCH (Do Ho Suh — translucent fabric architecture) ─────
# A ghost-house cluster: a gabled SALMON (color_a) main house with framed,
# TRULY CUT door + window openings, an adjacent JADE (color_b) annex/tower,
# all stretched in sheer luminous polyester over a visible dark-steel
# armature. A faint inner emission makes the cloth read as glowing fabric
# rather than tinted glass. ACCENT supplies a layered veil over the door, an
# interior threshold curtain, and the pendant-bulb glow. Vertical seam bars
# (stitched gores) subdivide every panel. Interior pendant + OmniLight glow
# through the fabric (gated on `emissive`). Builds the opaque armature FIRST
# so AABB framing always has solids. complexity → seam-gore density + whether
# a window is cut; `_rng` picks a tasteful cluster nudge and which camera-
# facing wall (+Z front or +X side) the window lands on. Deterministic.

func _build_fabricarch() -> void:
	_rng.seed = seed

	# Dark medium-thick steel armature (v3 weight — v4's was too thin).
	var steel_col := Color(0.20, 0.21, 0.25)
	var bar := maxf(sculpt_width * 0.024, 0.022)

	# ---- Main house footprint (origin bottom-centre, reads from +Z) -------
	var hw := sculpt_width * 0.46           # half width  (x)
	var hd := sculpt_width * 0.40           # half depth  (z)
	var wall_h := sculpt_height * 0.72      # eave height
	var ridge_h := sculpt_height            # ridge peak ~ full height

	# A small deterministic cluster nudge for the whole piece.
	var nudge := Vector3(_rng.randf_range(-1.0, 1.0) * sculpt_width * 0.02, 0.0,
		_rng.randf_range(-1.0, 1.0) * sculpt_width * 0.02)
	var o := nudge

	# ---- Door opening (always on the +Z camera-facing front wall) ---------
	var door_w := sculpt_width * 0.30
	var door_h := wall_h * 0.72
	var dxl := o.x - door_w * 0.5
	var dxr := o.x + door_w * 0.5

	# ---- Window: cut when complexity is high enough; pick a CAMERA-FACING
	#      wall (+Z front-right, or +X side) deterministically. ------------
	var add_window: bool = complexity >= 4
	var win_on_x: bool = _rng.randi_range(0, 1) == 1   # true => +X side, false => +Z front
	var win_lo := wall_h * 0.42
	var win_hi := wall_h * 0.80
	# window span along its wall's free axis
	var wa0 := -sculpt_width * 0.13
	var wa1 := sculpt_width * 0.13

	# ====================================================================
	#  ARMATURE FIRST (opaque dark steel — solid AABB framing)
	# ====================================================================
	var corners := [
		Vector3(-hw, 0, -hd), Vector3(hw, 0, -hd),
		Vector3(hw, 0, hd), Vector3(-hw, 0, hd),
	]
	# 4 corner posts
	for c in corners:
		_fab_bar(o + c, o + c + Vector3(0, wall_h, 0), bar, steel_col)
	# sill ring + eave ring
	for yy in [bar * 0.5, wall_h]:
		for i in range(4):
			_fab_bar(o + corners[i] + Vector3(0, yy, 0),
				o + corners[(i + 1) % 4] + Vector3(0, yy, 0), bar, steel_col)

	# pitched roof armature: ridge beam (along z) + 4 rafters + 2 mid rafters
	var ridge_a := o + Vector3(0, ridge_h, -hd)
	var ridge_b := o + Vector3(0, ridge_h, hd)
	_fab_bar(ridge_a, ridge_b, bar * 1.15, steel_col)
	_fab_bar(o + Vector3(-hw, wall_h, -hd), ridge_a, bar, steel_col)
	_fab_bar(o + Vector3(hw, wall_h, -hd), ridge_a, bar, steel_col)
	_fab_bar(o + Vector3(-hw, wall_h, hd), ridge_b, bar, steel_col)
	_fab_bar(o + Vector3(hw, wall_h, hd), ridge_b, bar, steel_col)
	_fab_bar(o + Vector3(-hw, wall_h, 0), o + Vector3(0, ridge_h, 0), bar * 0.85, steel_col)
	_fab_bar(o + Vector3(hw, wall_h, 0), o + Vector3(0, ridge_h, 0), bar * 0.85, steel_col)

	# framed DOOR (front +Z) — jambs + lintel + threshold sill
	var dz := o.z + hd
	_fab_bar(Vector3(dxl, 0, dz), Vector3(dxl, door_h, dz), bar, steel_col)
	_fab_bar(Vector3(dxr, 0, dz), Vector3(dxr, door_h, dz), bar, steel_col)
	_fab_bar(Vector3(dxl, door_h, dz), Vector3(dxr, door_h, dz), bar, steel_col)
	_fab_bar(Vector3(dxl, 0.02, o.z + hd - 0.10),
		Vector3(dxr, 0.02, o.z + hd - 0.10), bar, steel_col)

	# framed WINDOW loop + muntin cross (only if cut)
	if add_window:
		if win_on_x:
			var wx := o.x + hw
			_fab_bar(Vector3(wx, win_lo, o.z + wa0), Vector3(wx, win_hi, o.z + wa0), bar * 0.8, steel_col)
			_fab_bar(Vector3(wx, win_lo, o.z + wa1), Vector3(wx, win_hi, o.z + wa1), bar * 0.8, steel_col)
			_fab_bar(Vector3(wx, win_lo, o.z + wa0), Vector3(wx, win_lo, o.z + wa1), bar * 0.8, steel_col)
			_fab_bar(Vector3(wx, win_hi, o.z + wa0), Vector3(wx, win_hi, o.z + wa1), bar * 0.8, steel_col)
			_fab_bar(Vector3(wx, (win_lo + win_hi) * 0.5, o.z + wa0),
				Vector3(wx, (win_lo + win_hi) * 0.5, o.z + wa1), bar * 0.5, steel_col)
			_fab_bar(Vector3(wx, win_lo, o.z), Vector3(wx, win_hi, o.z), bar * 0.5, steel_col)
		else:
			# window on +Z front, offset to the RIGHT so it does not hit the door
			var wz := o.z + hd
			var wcx := o.x + sculpt_width * 0.26
			_fab_bar(Vector3(wcx + wa0, win_lo, wz), Vector3(wcx + wa0, win_hi, wz), bar * 0.8, steel_col)
			_fab_bar(Vector3(wcx + wa1, win_lo, wz), Vector3(wcx + wa1, win_hi, wz), bar * 0.8, steel_col)
			_fab_bar(Vector3(wcx + wa0, win_lo, wz), Vector3(wcx + wa1, win_lo, wz), bar * 0.8, steel_col)
			_fab_bar(Vector3(wcx + wa0, win_hi, wz), Vector3(wcx + wa1, win_hi, wz), bar * 0.8, steel_col)
			_fab_bar(Vector3(wcx, win_lo, wz), Vector3(wcx, win_hi, wz), bar * 0.5, steel_col)

	# ====================================================================
	#  SHEER FABRIC PANELS (luminous translucent — drawn over the frame)
	# ====================================================================
	var fab_alpha := 0.32
	var seam_col := steel_col.lightened(0.10)

	# Back (-Z) + left (-X) full walls (with seam gores).
	_fab_wall_full(o + Vector3(-hw, 0, -hd), o + Vector3(hw, 0, -hd), wall_h,
		color_a, fab_alpha, seam_col, bar)                                   # back
	_fab_wall_full(o + Vector3(-hw, 0, hd), o + Vector3(-hw, 0, -hd), wall_h,
		color_a, fab_alpha, seam_col, bar)                                   # left

	# Right (+X) wall: holed strips if the window is on +X, else full.
	if add_window and win_on_x:
		_fab_wall_hole_x(o.x + hw, o.z, hd, wall_h, win_lo, win_hi,
			o.z + wa0, o.z + wa1, color_a, fab_alpha, seam_col, bar)
	else:
		_fab_wall_full(o + Vector3(hw, 0, hd), o + Vector3(hw, 0, -hd), wall_h,
			color_a, fab_alpha, seam_col, bar)

	# Front (+Z) wall: 3 strips around the TRUE door hole (+ optional window hole).
	_fab_wall_door_z(o.z + hd, hw, o.x, wall_h, door_h, dxl, dxr,
		color_a, fab_alpha, seam_col, bar)

	# Gable triangles (front & back end caps).
	var gmat := _fab_mat(color_a, fab_alpha, 0.17)
	_fab_tri(o + Vector3(-hw, wall_h, -hd), o + Vector3(hw, wall_h, -hd), ridge_a, gmat)
	_fab_tri(o + Vector3(-hw, wall_h, hd), o + Vector3(hw, wall_h, hd), ridge_b, gmat)

	# Roof: two pitched slopes (slightly lighter salmon).
	var roof_hue := color_a.lerp(Color(1, 1, 1), 0.10)
	var rmat := _fab_mat(roof_hue, fab_alpha + 0.04, 0.17)
	_fab_quad(o + Vector3(-hw, wall_h, -hd), o + Vector3(-hw, wall_h, hd),
		ridge_b, ridge_a, rmat)                                              # -X slope
	_fab_quad(o + Vector3(hw, wall_h, -hd), o + Vector3(hw, wall_h, hd),
		ridge_b, ridge_a, rmat)                                              # +X slope

	# WINDOW PANE — LOW alpha, ZERO emission so it stays coloured (tint fix).
	if add_window:
		var pane := _fab_mat(Color(0.60, 0.80, 0.95), 0.18, 0.0)
		if win_on_x:
			var wx2 := o.x + hw - 0.004
			_fab_quad(Vector3(wx2, win_lo, o.z + wa0), Vector3(wx2, win_lo, o.z + wa1),
				Vector3(wx2, win_hi, o.z + wa1), Vector3(wx2, win_hi, o.z + wa0), pane)
		else:
			var wz2 := o.z + hd - 0.004
			var wcx2 := o.x + sculpt_width * 0.26
			_fab_quad(Vector3(wcx2 + wa0, win_lo, wz2), Vector3(wcx2 + wa1, win_lo, wz2),
				Vector3(wcx2 + wa1, win_hi, wz2), Vector3(wcx2 + wa0, win_hi, wz2), pane)

	# ====================================================================
	#  LAYERED ACCENT (3rd hue) — veil over the door + interior threshold
	# ====================================================================
	var veil := _fab_mat(accent, 0.20, 0.14)
	var pad := sculpt_width * 0.03
	_fab_quad(
		o + Vector3(-hw - pad, 0, hd + 0.02), o + Vector3(hw + pad, 0, hd + 0.02),
		o + Vector3(hw + pad, wall_h + 0.06, hd + 0.02), o + Vector3(-hw - pad, wall_h + 0.06, hd + 0.02),
		veil)

	# Interior threshold: a low inner doorway frame + a hanging accent curtain.
	var tz := o.z + hd - sculpt_width * 0.30
	var tw := door_w * 0.55
	var th := door_h * 0.92
	_fab_bar(Vector3(o.x - tw, 0, tz), Vector3(o.x - tw, th, tz), bar * 0.85, steel_col)
	_fab_bar(Vector3(o.x + tw, 0, tz), Vector3(o.x + tw, th, tz), bar * 0.85, steel_col)
	_fab_bar(Vector3(o.x - tw, th, tz), Vector3(o.x + tw, th, tz), bar * 0.85, steel_col)
	_fab_quad(
		Vector3(o.x - tw + 0.02, 0.04, tz), Vector3(o.x + tw - 0.02, 0.04, tz),
		Vector3(o.x + tw - 0.02, th - 0.03, tz), Vector3(o.x - tw + 0.02, th - 0.03, tz),
		_fab_mat(accent, 0.24, 0.14))

	# ====================================================================
	#  INTERIOR GLOW — pendant bulb + OmniLight (gated on emissive)
	# ====================================================================
	if emissive:
		_fab_pendant(o + Vector3(0, ridge_h - sculpt_height * 0.02, 0.0),
			sculpt_height * 0.34, accent, bar)

	# ====================================================================
	#  SECOND VOLUME — adjacent JADE annex/tower (flat roof, color_b)
	# ====================================================================
	var aw := sculpt_width * 0.30           # half width
	var ad := sculpt_width * 0.28           # half depth
	var ah := sculpt_height * 0.92          # a touch shorter than the ridge
	var ax := o.x - hw - aw - sculpt_width * 0.06   # abuts the main house, to the -X
	var az := o.z - sculpt_width * 0.10
	var ann := Vector3(ax, 0, az)
	var acorn := [
		Vector3(-aw, 0, -ad), Vector3(aw, 0, -ad),
		Vector3(aw, 0, ad), Vector3(-aw, 0, ad),
	]
	# posts
	for c in acorn:
		_fab_bar(ann + c, ann + c + Vector3(0, ah, 0), bar, steel_col)
	# three rail rings (bottom / mid / top) for a layered-seam look
	for yy2 in [bar * 0.5, ah * 0.5, ah]:
		for i in range(4):
			_fab_bar(ann + acorn[i] + Vector3(0, yy2, 0),
				ann + acorn[(i + 1) % 4] + Vector3(0, yy2, 0), bar * 0.8, steel_col)
	# jade panels on all four sides, in two stacked bands (layered seams).
	for i in range(4):
		var a: Vector3 = ann + acorn[i]
		var b: Vector3 = ann + acorn[(i + 1) % 4]
		_fab_wall_full(a, b, ah * 0.5, color_b, fab_alpha, seam_col, bar)
		var a2: Vector3 = a + Vector3(0, ah * 0.5, 0)
		var b2: Vector3 = b + Vector3(0, ah * 0.5, 0)
		_fab_wall_full(a2, b2, ah * 0.5, color_b, fab_alpha, seam_col, bar)
	# flat translucent roof cap (pale blue).
	_fab_quad(
		ann + Vector3(-aw, ah, -ad), ann + Vector3(aw, ah, -ad),
		ann + Vector3(aw, ah, ad), ann + Vector3(-aw, ah, ad),
		_fab_mat(Color(0.60, 0.80, 0.95), 0.24, 0.10))
	# small interior pendant inside the annex (reads through jade).
	if emissive:
		_fab_pendant(ann + Vector3(0, ah - sculpt_height * 0.02, 0.0),
			sculpt_height * 0.22, accent, bar)


# ── fabricarch private helpers (_fab_ prefix) ──────────────────────────

## Sheer luminous polyester — the heart of the Do Ho Suh look.
## alpha = panel opacity; emis_energy = faint inner glow (0 keeps colour pure).
func _fab_mat(col: Color, alpha: float, emis_energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(col.r, col.g, col.b, alpha)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED              # double-sided sheer
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	m.roughness = 0.88
	m.metallic = 0.0
	if emis_energy > 0.0:
		m.emission_enabled = true
		m.emission = Color(col.r, col.g, col.b)
		m.emission_energy_multiplier = emis_energy         # ~0.17 reads as glowing cloth
	# soft rim so seams/edges catch light like stretched mesh (v3).
	m.rim_enabled = true
	m.rim = 0.4
	m.disable_receive_shadows = true
	return m


## A thin oriented steel box-bar spanning a..b (posts / rails / rafters / cords).
func _fab_bar(a: Vector3, b: Vector3, thick: float, col: Color) -> void:
	var diff := b - a
	var length: float = diff.length()
	if length < 0.0001:
		return
	var mi := MeshInstance3D.new()
	mi.name = "FabBar"
	var bm := BoxMesh.new()
	bm.size = Vector3(thick, length, thick)                 # built along +Y, then aimed
	mi.mesh = bm
	mi.material_override = _make_mat(col, 0.45, maxf(metallic_amt, 0.6))
	mi.position = (a + b) * 0.5
	var dir := diff.normalized()
	var up := Vector3.UP
	if absf(dir.dot(up)) > 0.999:
		pass                                                # already vertical
	else:
		var axis := up.cross(dir).normalized()
		var ang: float = acos(clampf(up.dot(dir), -1.0, 1.0))
		mi.transform.basis = Basis(axis, ang)
	add_child(mi)


## A flat double-sided sheer quad (p0..p3 wound CCW). Planar UVs are set so
## tangent generation (for the rim shading) succeeds.
func _fab_quad(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3,
		mat: Material) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := (p1 - p0).cross(p3 - p0).normalized()
	var verts := [p0, p1, p2, p0, p2, p3]
	var uvs := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1),
		Vector2(0, 0), Vector2(1, 1), Vector2(0, 1)]
	for i in range(verts.size()):
		st.set_normal(n)
		st.set_uv(uvs[i])
		st.add_vertex(verts[i])
	st.generate_tangents()
	var mi := MeshInstance3D.new()
	mi.name = "FabPanel"
	mi.mesh = st.commit()
	mi.material_override = mat
	add_child(mi)


## A flat double-sided sheer triangle (gable end cap). Planar UVs set so
## tangent generation (for the rim shading) succeeds.
func _fab_tri(a: Vector3, b: Vector3, c: Vector3, mat: Material) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := (b - a).cross(c - a).normalized()
	var verts := [a, b, c]
	var uvs := [Vector2(0, 0), Vector2(1, 0), Vector2(0.5, 1)]
	for i in range(verts.size()):
		st.set_normal(n)
		st.set_uv(uvs[i])
		st.add_vertex(verts[i])
	st.generate_tangents()
	var mi := MeshInstance3D.new()
	mi.name = "FabGable"
	mi.mesh = st.commit()
	mi.material_override = mat
	add_child(mi)


## A full wall panel between base corners a..b (eave height wh) PLUS thin
## vertical seam gores (stitched-polyester subdivisions). complexity drives
## how many gores. a and b are at y=0; the wall rises +wh.
func _fab_wall_full(a: Vector3, b: Vector3, wh: float, hue: Color,
		alpha: float, seam_col: Color, bar: float) -> void:
	var aT := a + Vector3(0, wh, 0)
	var bT := b + Vector3(0, wh, 0)
	_fab_quad(a, b, bT, aT, _fab_mat(hue, alpha, 0.17))
	# vertical seam gores
	var gores: int = clampi(complexity - 2, 1, 5)
	for g in range(1, gores + 1):
		var t := float(g) / float(gores + 1)
		var lo := a.lerp(b, t)
		var hi := aT.lerp(bT, t)
		_fab_bar(lo, hi, bar * 0.42, seam_col)


## Front (+Z) wall at world z=fz, split into 3 strips around a TRUE door hole,
## each strip seam-gored.
func _fab_wall_door_z(fz: float, hw: float, ox: float, wh: float, dh: float,
		dxl: float, dxr: float, hue: Color, alpha: float,
		seam_col: Color, bar: float) -> void:
	# left strip
	_fab_wall_full(Vector3(ox - hw, 0, fz), Vector3(dxl, 0, fz), wh,
		hue, alpha, seam_col, bar)
	# right strip
	_fab_wall_full(Vector3(dxr, 0, fz), Vector3(ox + hw, 0, fz), wh,
		hue, alpha, seam_col, bar)
	# header above the door (no gore — short)
	var m := _fab_mat(hue, alpha, 0.17)
	_fab_quad(Vector3(dxl, dh, fz), Vector3(dxr, dh, fz),
		Vector3(dxr, wh, fz), Vector3(dxl, wh, fz), m)


## Right (+X) wall at world x=wx, split into 4 border strips around a TRUE
## window hole. Side strips are seam-gored.
func _fab_wall_hole_x(wx: float, oz: float, hd: float, wh: float,
		wy0: float, wy1: float, wz0: float, wz1: float, hue: Color,
		alpha: float, seam_col: Color, bar: float) -> void:
	var m := _fab_mat(hue, alpha, 0.17)
	# below window
	_fab_quad(Vector3(wx, 0, oz + hd), Vector3(wx, 0, oz - hd),
		Vector3(wx, wy0, oz - hd), Vector3(wx, wy0, oz + hd), m)
	# above window
	_fab_quad(Vector3(wx, wy1, oz + hd), Vector3(wx, wy1, oz - hd),
		Vector3(wx, wh, oz - hd), Vector3(wx, wh, oz + hd), m)
	# +Z side strip (gored)
	_fab_wall_strip_x(wx, wy0, wy1, wz1, oz + hd, seam_col, bar, m)
	# -Z side strip (gored)
	_fab_wall_strip_x(wx, wy0, wy1, oz - hd, wz0, seam_col, bar, m)


## A vertical-band side strip of an +X wall between z=za..zb at heights y0..y1,
## with one seam gore down the middle.
func _fab_wall_strip_x(wx: float, y0: float, y1: float, za: float, zb: float,
		seam_col: Color, bar: float, mat: Material) -> void:
	_fab_quad(Vector3(wx, y0, za), Vector3(wx, y0, zb),
		Vector3(wx, y1, zb), Vector3(wx, y1, za), mat)
	var zm := (za + zb) * 0.5
	_fab_bar(Vector3(wx, y0, zm), Vector3(wx, y1, zm), bar * 0.42, seam_col)


## Hanging pendant: steel cord + emissive bulb + sheer shade + OmniLight that
## glows through the surrounding fabric. glow_col tints the light (= accent).
func _fab_pendant(top: Vector3, drop: float, glow_col: Color, bar: float) -> void:
	var bottom := top - Vector3(0, drop, 0)
	_fab_bar(top, bottom, bar * 0.45, Color(0.12, 0.12, 0.14))
	# emissive bulb
	var bulb_glow := glow_col.lerp(Color(1.0, 0.90, 0.70), 0.55)
	var bulb := _add_sphere("FabBulb", sculpt_width * 0.05, bottom,
		_make_emissive_mat(bulb_glow, 2.4))
	bulb.scale = Vector3(1.0, 1.05, 1.0)
	# sheer conical shade over the bulb (truncated cone)
	var shade := MeshInstance3D.new()
	shade.name = "FabShade"
	var cone := CylinderMesh.new()
	cone.top_radius = sculpt_width * 0.045
	cone.bottom_radius = sculpt_width * 0.12
	cone.height = sculpt_width * 0.12
	shade.mesh = cone
	shade.material_override = _fab_mat(Color(1.0, 0.80, 0.58), 0.34, 0.16)
	shade.position = bottom + Vector3(0, sculpt_width * 0.07, 0)
	add_child(shade)
	# OmniLight so the interior glows through the sheer panels
	var lamp := OmniLight3D.new()
	lamp.name = "FabLamp"
	lamp.light_color = bulb_glow
	lamp.light_energy = 1.6
	lamp.omni_range = sculpt_width * 2.4
	lamp.position = bottom
	add_child(lamp)


# ── Mode: ENCRUSTED (Takuro Kuwata — thickly-glazed beaded ceramic) ─────
# A bulging candy-glaze urn on a bright GOLD foot: narrow gold foot → swelling
# belly → pinched shoulder → flared open mouth (dark interior void). Drowned in
# a hand-troweled crust — a few HEAVY bead GOBS with bare patches between, mixed
# with SMOOTH tapered molten drips that fatten and pool at the base — and one
# grey angular stone bursting the belly, ringed by a white crawled-glaze halo
# (ishihaze). The gold foot, rim leaf and stone all carry a faint warm EMISSION
# FLOOR so the precious metal never crushes to black in an unlit capture.
# DNA: color_a = candy glaze hue · color_b = gold/metal tint (emission floored)
# · accent = secondary bead/glaze colour · complexity → bead-gob + drip count
# · unit_count → total bead count · emissive → extra glaze sheen (gold always on).

func _build_encrusted() -> void:
	_rng.seed = seed
	var h: float = sculpt_height
	var w: float = sculpt_width
	# Vertical split: a short gold foot below, the ceramic body above.
	var foot_h: float = h * 0.16
	var body_h: float = h - foot_h

	# Palette derived from DNA. color_a candy glaze; accent the contrast bead/
	# glaze colour; a small varied set keeps the crust from reading as one hue.
	var glaze_a: Color = color_a
	var glaze_b: Color = accent
	var glaze_c: Color = accent.lerp(Color(0.96, 0.93, 0.90), 0.55)   # pale crawl
	var glaze_d: Color = color_a.lerp(accent, 0.5)
	var palette: Array[Color] = [glaze_a, glaze_b, glaze_c, glaze_d]

	# ── GOLD FOOT (kept clear, above the drip skirt) ────────────────────
	# A stepped foot: wide base disc → tapered stem, all metallic gold with the
	# warm emission floor so it reads as gold even with no reflection probe.
	var gold := _enc_gold_mat(color_b)
	_add_cyl("EncFootBase", w * 0.30, w * 0.38, foot_h * 0.42,
		Vector3(0, foot_h * 0.21, 0), Vector3.ZERO, gold)
	_add_cyl("EncFootStem", _enc_radius_at(0.0, w), w * 0.30, foot_h * 0.62,
		Vector3(0, foot_h * 0.42 + foot_h * 0.31, 0), Vector3.ZERO, gold)
	# A couple of gold lumps where the leaf gathered (deterministic placement).
	for li in range(3):
		var la: float = TAU * float(li) / 3.0 + 0.4
		var lr: float = w * 0.30
		_add_sphere("EncFootLump%d" % li, w * _rng.randf_range(0.05, 0.08),
			Vector3(cos(la) * lr, foot_h * _rng.randf_range(0.3, 0.7), sin(la) * lr), gold)

	# ── CERAMIC BODY (stacked rings hugging the profile; solid core first) ──
	var glaze_body := _enc_glaze_mat(glaze_a, false)
	var ceramic := _make_mat(color_a.lerp(Color(0.72, 0.66, 0.56), 0.7), 0.88, 0.0)
	var rings: int = 22
	for i in range(rings):
		var t0: float = float(i) / float(rings)
		var t1: float = float(i + 1) / float(rings)
		var r0: float = _enc_radius_at(t0, w)
		var r1: float = _enc_radius_at(t1, w)
		var y0: float = foot_h + t0 * body_h
		var y1: float = foot_h + t1 * body_h
		var seg_h: float = y1 - y0
		# Raw matte clay band low on the belly; glossy candy glaze elsewhere.
		var ring_mat: StandardMaterial3D = ceramic if t0 < 0.16 else glaze_body
		_add_cyl("EncBody%d" % i, r1, r0, seg_h + 0.006,
			Vector3(0, (y0 + y1) * 0.5, 0), Vector3.ZERO, ring_mat)

	# ── FLARED RIM + DARK INTERIOR VOID (open-mouth vessel) ─────────────
	var mouth_y: float = foot_h + body_h
	var mouth_r: float = _enc_radius_at(1.0, w)
	var void_mat := _make_mat(Color(0.16, 0.05, 0.09), 0.55, 0.0)
	_add_cyl("EncMouthVoid", mouth_r - 0.06 * w, mouth_r - 0.12 * w, body_h * 0.22,
		Vector3(0, mouth_y - body_h * 0.10, 0), Vector3.ZERO, void_mat)
	# Thick glossy flared lip ring around the mouth.
	var rim := MeshInstance3D.new()
	rim.name = "EncRim"
	var rim_tm := TorusMesh.new()
	rim_tm.inner_radius = mouth_r - 0.05 * w
	rim_tm.outer_radius = mouth_r + 0.05 * w
	rim_tm.rings = 36
	rim_tm.ring_segments = 16
	rim.mesh = rim_tm
	rim.material_override = _enc_glaze_mat(glaze_a, false)
	rim.position = Vector3(0, mouth_y, 0)
	add_child(rim)

	# ── CONTRAST GLAZE POUR CAP on the shoulder (a fat over-pour dollop) ─
	var pour := _add_sphere("EncPour", _enc_radius_at(0.86, w) * 1.02,
		Vector3(0, foot_h + body_h * 0.86, 0), _enc_glaze_mat(glaze_b, false))
	pour.scale = Vector3(1.0, 0.62, 1.0)

	# ── KAIRAGI BEADS — a few HEAVY GOBS with BARE PATCHES between ──────
	# Seed-cluster the beads into clumps (hand-troweled), not an even ring.
	var gob_count: int = clampi(complexity + 2, 4, 12)
	var bead_total: int = maxi(40, unit_count)
	var beads_per_gob: int = int(bead_total / gob_count)
	var glaze_sheen: bool = emissive
	for g in range(gob_count):
		# Gob centre: biased toward the belly/shoulder band where eruption is heaviest.
		var c_t: float = _rng.randf_range(0.28, 0.86)
		var c_ang: float = _rng.randf_range(0.0, TAU)
		var gob_col: Color = palette[_rng.randi_range(0, palette.size() - 1)]
		# Tight angular + height spread per gob, so bare clay shows between gobs.
		var n_here: int = beads_per_gob + _rng.randi_range(-2, 3)
		for b in range(n_here):
			var t: float = clampf(c_t + _rng.randf_range(-0.08, 0.08), 0.12, 0.96)
			var ang: float = c_ang + _rng.randf_range(-0.32, 0.32)
			var r: float = _enc_radius_at(t, w)
			var bead_r: float = w * _rng.randf_range(0.022, 0.075)
			var rr: float = r + bead_r * 0.45                      # sit proud of the skin
			var y: float = foot_h + t * body_h + _rng.randf_range(-0.02, 0.02) * h
			# Mostly the gob colour; occasional contrast bead for richness.
			var bcol: Color = gob_col
			if _rng.randf() < 0.22:
				bcol = palette[_rng.randi_range(0, palette.size() - 1)]
			var bead := _add_sphere("EncBead%d_%d" % [g, b], bead_r,
				Vector3(cos(ang) * rr, y, sin(ang) * rr), _enc_glaze_mat(bcol, glaze_sheen))
			bead.scale = Vector3(_rng.randf_range(0.85, 1.15),
				_rng.randf_range(0.7, 1.05), _rng.randf_range(0.85, 1.15))
		# One oversized "popcorn" bead bursting out of each gob.
		var pt: float = clampf(c_t + _rng.randf_range(-0.04, 0.04), 0.2, 0.9)
		var pr: float = _enc_radius_at(pt, w) + w * 0.05
		var pop_bead := _add_sphere("EncPop%d" % g, w * _rng.randf_range(0.09, 0.14),
			Vector3(cos(c_ang) * pr, foot_h + pt * body_h, sin(c_ang) * pr),
			_enc_glaze_mat(palette[_rng.randi_range(0, palette.size() - 1)], glaze_sheen))
		pop_bead.scale = Vector3(1.0, 0.85, 1.0)

	# ── SMOOTH TAPERED DRIPS — molten runs that fatten then pool ────────
	# A mix of smooth glossy molten runs (tapered cylinders) and the same hue
	# as the body, fattening as they fall and pooling in a teardrop at the base.
	var drip_count: int = clampi(complexity + 6, 6, 20)
	for d in range(drip_count):
		var d_ang: float = TAU * float(d) / float(drip_count) + _rng.randf_range(-0.12, 0.12)
		var top_t: float = _rng.randf_range(0.58, 0.80)
		var bot_t: float = _rng.randf_range(0.06, 0.20)
		var d_col: Color = palette[_rng.randi_range(0, palette.size() - 1)]
		_enc_drip(d_ang, top_t, bot_t, foot_h, body_h, w, _enc_glaze_mat(d_col, glaze_sheen))

	# ── STONE ERUPTION bursting the belly + white crawled-glaze halo ────
	var stone := _enc_stone_mat()
	var rock_t: float = 0.60
	var rock_y: float = foot_h + rock_t * body_h
	var rock_ang: float = 0.45                                    # toward +Z reader
	var rock_r: float = _enc_radius_at(rock_t, w) + w * 0.04
	var rock_pos := Vector3(cos(rock_ang) * rock_r, rock_y, sin(rock_ang) * rock_r)
	# Faceted rock = a few rotated boxes clustered into an angular chunk.
	_add_box("EncRock0", Vector3(w * 0.22, w * 0.24, w * 0.20), rock_pos,
		Vector3(0.3, rock_ang + 0.5, 0.2), stone)
	_add_box("EncRock1", Vector3(w * 0.16, w * 0.18, w * 0.15),
		rock_pos + Vector3(w * 0.06, w * 0.05, w * 0.04),
		Vector3(-0.4, rock_ang + 0.9, 0.3), stone)
	_add_box("EncRock2", Vector3(w * 0.13, w * 0.14, w * 0.13),
		rock_pos + Vector3(-w * 0.05, -w * 0.04, w * 0.06),
		Vector3(0.7, rock_ang + 0.2, -0.5), stone)
	# White crawled-glaze ring crawling around the wound (ishihaze halo).
	var crawl_mat := _enc_glaze_mat(glaze_c, glaze_sheen)
	for k in range(12):
		var ka: float = TAU * float(k) / 12.0
		var krad: float = w * 0.20
		var koff := Vector3(cos(ka) * krad, sin(ka) * krad * 0.7,
			_rng.randf_range(-0.03, 0.03) * w).rotated(Vector3.UP, rock_ang)
		_add_sphere("EncCrawl%d" % k, w * _rng.randf_range(0.035, 0.06),
			rock_pos + koff, crawl_mat).scale = Vector3(1.0, 0.8, 1.0)

	# ── GOLD RIM LEAF — gold drips crowning the mouth + centre dollop ───
	for gi in range(8):
		var ga: float = TAU * float(gi) / 8.0 + 0.15
		var gx: float = cos(ga) * mouth_r
		var gz: float = sin(ga) * mouth_r
		_add_sphere("EncRimGold%d" % gi, w * _rng.randf_range(0.05, 0.085),
			Vector3(gx, mouth_y, gz), gold).scale = Vector3(1.0, 0.8, 1.0)
		# A short gold drip running a little way down from the lip.
		var steps: int = 4
		for s in range(steps):
			var f: float = float(s) / float(steps)
			var yy: float = mouth_y - f * _rng.randf_range(0.10, 0.26) * h
			var tt: float = clampf((yy - foot_h) / body_h, 0.0, 1.0)
			var dr: float = _enc_radius_at(tt, w) + 0.01 * w
			_add_sphere("EncRimDrip%d_%d" % [gi, s], lerpf(w * 0.045, w * 0.022, f),
				Vector3(cos(ga) * dr, yy, sin(ga) * dr), gold).scale = Vector3(0.8, 1.3, 0.8)
	# Crowning gold dollop sitting in the mouth centre (the precious heart).
	_add_sphere("EncCrown", w * 0.11, Vector3(0.0, mouth_y - 0.02 * h, 0.0),
		gold).scale = Vector3(1.0, 0.6, 1.0)


# ── Encrusted helpers (_enc_ prefix) ───────────────────────────────────

# Vessel profile radius (metres) at normalised body height t in [0,1], scaled
# by footprint w: narrow foot → swelling belly → pinched shoulder → flared mouth.
func _enc_radius_at(t: float, w: float) -> float:
	t = clampf(t, 0.0, 1.0)
	var f: float = w * 0.62                                       # belly max ~ 0.62 w
	if t < 0.10:
		return lerpf(f * 0.55, f * 0.48, t / 0.10)               # foot stem
	elif t < 0.55:
		var u: float = (t - 0.10) / 0.45
		return lerpf(f * 0.48, f, sin(u * PI * 0.5))            # swelling belly
	elif t < 0.80:
		var u2: float = (t - 0.55) / 0.25
		return lerpf(f, f * 0.64, u2)                           # shoulder pinch
	else:
		var u3: float = (t - 0.80) / 0.20
		return lerpf(f * 0.64, f * 0.80, u3)                    # flared mouth lip


# Glossy candy glaze — wet, high specular, clearcoat sheen + slight rim. When
# `sheen` is on (emissive DNA) add a faint self-emission so the candy glows.
func _enc_glaze_mat(c: Color, sheen: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.09
	m.metallic = 0.0
	m.metallic_specular = 0.9
	m.clearcoat_enabled = true
	m.clearcoat = 0.9
	m.clearcoat_roughness = 0.07
	m.rim_enabled = true
	m.rim = 0.35
	if sheen:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = 0.18
	return m


# Metallic gold leaf with a faint WARM EMISSION FLOOR so it never crushes to
# black in an unlit headless capture (the single most important learning).
func _enc_gold_mat(tint: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = tint
	m.metallic = 1.0
	m.roughness = 0.2
	m.metallic_specular = 1.0
	m.emission_enabled = true
	m.emission = tint
	m.emission_energy_multiplier = 0.32
	return m


# Rough grey volcanic stone bursting through the crawled glaze.
func _enc_stone_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.46, 0.46, 0.49)
	m.roughness = 0.93
	m.metallic = 0.0
	return m


# A single SMOOTH tapered drip: a stack of cone segments that follow the body
# profile and fatten as they descend, capped by a fat pooled teardrop blob.
func _enc_drip(ang: float, top_t: float, bot_t: float, foot_h: float,
		body_h: float, w: float, mat: StandardMaterial3D) -> void:
	var steps: int = 7
	var prev_r: float = w * 0.026
	for s in range(steps):
		var f0: float = float(s) / float(steps)
		var f1: float = float(s + 1) / float(steps)
		var t0: float = lerpf(top_t, bot_t, f0)
		var t1: float = lerpf(top_t, bot_t, f1)
		var br0: float = _enc_radius_at(t0, w) + 0.012 * w
		var br1: float = _enc_radius_at(t1, w) + 0.012 * w
		var y0: float = foot_h + t0 * body_h
		var y1: float = foot_h + t1 * body_h
		# Tendril thickens toward the base (gravity pools the glaze).
		var thick0: float = prev_r
		var thick1: float = lerpf(w * 0.028, w * 0.058, f1)
		var mid := Vector3((cos(ang) * br0 + cos(ang) * br1) * 0.5,
			(y0 + y1) * 0.5, (sin(ang) * br0 + sin(ang) * br1) * 0.5)
		var seg_len: float = Vector3(cos(ang) * br1 - cos(ang) * br0, y1 - y0,
			sin(ang) * br1 - sin(ang) * br0).length()
		# Cone segment oriented mostly downward (drips run ~vertically).
		_add_cyl("EncDripSeg", thick1, thick0, maxf(seg_len, 0.01 * w), mid,
			Vector3.ZERO, mat)
		prev_r = thick1
	# Fat pooled teardrop where the drip hits the foot region.
	var pr: float = _enc_radius_at(bot_t, w) + 0.03 * w
	var pool := _add_sphere("EncDripPool", w * _rng.randf_range(0.06, 0.10),
		Vector3(cos(ang) * pr, foot_h + bot_t * body_h - 0.015 * body_h, sin(ang) * pr),
		mat)
	pool.scale = Vector3(1.3, 0.6, 1.3)


# ── Mode: EXPLODEDSHED (Cornelia Parker — "Cold Dark Matter: An Exploded View") ─
# A garden shed detonated and frozen mid-blast: a radial cloud of charred
# splintered debris suspended around a single serene glowing bulb at the core.
# Each fragment's long axis points OUTWARD from the centre (a basis aligned to
# the outward direction + a small random tumble) so the whole mass reads as a
# frozen blast wave rather than a random scatter. An OmniLight at the core throws
# dramatic radial shadows; faint monofilament wires drop from a high ceiling
# anchor to a subset of pieces (the gallery rigging); a few feature panels (a
# shed wall, a door, a window frame) at the outer edge keep the shed legible,
# and a handful of fragments settle on the floor as fallout. The contradiction
# of the lineage is the point — violent destruction held in perfect stillness
# around a calm point of light.
#
# Synthesised from four trials: radial outward orientation (v3), Fibonacci-sphere
# distribution + outer-band bias (v4), bulb exclusion sphere so the light is
# never buried (v4) + filament/halo bulb (v1), ceiling-converging wires (v2),
# ground fallout (v4), dual-tone planks charred-outer/raw-split (v1).
#
# DNA: color_a → charred/raw wood tint, color_b → metal tint, accent → bulb glow,
# complexity → feature-fragment count + object variety, unit_count → fragment
# count, emissive → bulb light/glow boost.

func _build_explodedshed() -> void:
	_rng.seed = seed

	var core: Vector3 = Vector3(0.0, sculpt_height * 0.5, 0.0)
	# Mean blast radius scales with footprint (the cloud spans ~sculpt_width).
	var shell_r: float = maxf(0.3, sculpt_width * 0.92)
	# No fragment inside this radius — keeps the bulb visible at the heart.
	var excl_r: float = shell_r * 0.30

	# ── Wood + metal palette derived from DNA ───────────────────────────
	# Charred wood is pushed VERY dark so it survives the bright capture ambient.
	var charred: StandardMaterial3D = _make_mat(
		_exp_dark_wood(color_a, 0.06), 0.92, 0.0)
	# A slightly warmer singed variant for tonal variety in the char.
	var charred_warm: StandardMaterial3D = _make_mat(
		_exp_dark_wood(color_a, 0.11).lerp(Color(0.12, 0.07, 0.05), 0.4), 0.9, 0.0)
	# Paler RAW wood — fresh snapped breaks the fire never reached.
	var raw_wood: StandardMaterial3D = _make_mat(
		color_a.lerp(Color(0.42, 0.31, 0.18), 0.7), 0.86, 0.0)
	# Grey scorched tool/can metal.
	var metal: StandardMaterial3D = _make_mat(
		color_b.lerp(Color(0.34, 0.35, 0.37), 0.5),
		clampf(rough_amt * 0.6, 0.3, 0.55), maxf(metallic_amt, 0.85))

	# ── The glowing heart: bulb + filament + cap + halo + OmniLight ──────
	_exp_build_bulb(core)

	# ── The frozen blast shell ──────────────────────────────────────────
	var total: int = maxi(40, unit_count)
	var golden: float = PI * (3.0 - sqrt(5.0))
	for i in range(total):
		# Fibonacci-sphere direction → even angular coverage.
		var t: float = (float(i) + 0.5) / float(total)
		var y_unit: float = 1.0 - 2.0 * t
		# Soften the poles a touch — a shed's contents spray sideways more.
		y_unit *= 0.82
		var r_xz: float = sqrt(maxf(0.0, 1.0 - y_unit * y_unit))
		var phi: float = golden * float(i)
		var dir: Vector3 = Vector3(cos(phi) * r_xz, y_unit, sin(phi) * r_xz).normalized()

		# Bias debris toward the outer band so the centre stays airy around the
		# bulb; never inside the exclusion sphere.
		var rad: float = lerpf(excl_r * 1.12, shell_r * 1.18, pow(_rng.randf(), 0.5))
		rad += _rng.randf_range(-0.05, 0.07) * shell_r
		rad = maxf(rad, excl_r * 1.05)
		var pos: Vector3 = core + dir * rad
		# Keep everything above the floor (origin y = 0).
		if pos.y < 0.06:
			pos.y = 0.06 + _rng.randf() * 0.05

		var frag: Node3D = _exp_make_fragment(i, charred, charred_warm, raw_wood, metal)
		_exp_place_radial(frag, pos, dir)

	# ── Feature fragments — 2-3 LARGER recognisable pieces at the outer edge
	# (a shed-wall panel, a door, a window frame) for scale + recognition.
	var feature_n: int = clampi(complexity, 2, 4)
	for f in range(feature_n):
		var fdir: Vector3 = _exp_rand_dir()
		# Sit them at the outer edge, biased to the equatorial band (heavy panels).
		fdir.y = fdir.y * 0.5
		fdir = fdir.normalized()
		var frad: float = shell_r * _rng.randf_range(1.05, 1.32)
		var fpos: Vector3 = core + fdir * frad
		if fpos.y < 0.10:
			fpos.y = 0.10 + _rng.randf() * 0.08
		var panel: Node3D = _exp_make_feature(f, charred, charred_warm, raw_wood, metal)
		_exp_place_radial(panel, fpos, fdir)

	# ── Ceiling suspension wires (the monofilament that freezes the blast) ──
	# Brighter than barely-visible: converge from a HIGH gallery anchor down to a
	# subset of fragments so the cloud reads as "suspended".
	var wire_mat: StandardMaterial3D = _make_mat(
		Color(0.12, 0.12, 0.14), 0.5, 0.2)
	var anchor: Vector3 = core + Vector3(0.0, sculpt_height * 0.62, 0.0)
	var wire_n: int = 16
	for w in range(wire_n):
		var wdir: Vector3 = _exp_rand_dir()
		# Bias targets to the upper hemisphere so the wires read as hanging.
		wdir.y = absf(wdir.y) * 0.6 + 0.12
		wdir = wdir.normalized()
		var wrad: float = shell_r * _rng.randf_range(0.55, 1.18)
		var target: Vector3 = core + wdir * wrad
		_add_strand(anchor, target, wire_mat, sculpt_width * 0.0016)

	# ── Ground fallout — a few fragments already settled on the floor ───
	var fall_n: int = clampi(int(total / 10), 6, 16)
	for k in range(fall_n):
		var ang: float = _rng.randf_range(0.0, TAU)
		var dist: float = _rng.randf_range(shell_r * 0.25, shell_r * 0.95)
		var gpos: Vector3 = Vector3(cos(ang) * dist, 0.012, sin(ang) * dist)
		var groll: float = _rng.randf()
		var gfrag: Node3D
		if groll < 0.5:
			gfrag = _exp_frag_chunk(charred, charred_warm)
		elif groll < 0.8:
			gfrag = _exp_frag_splinter(charred, raw_wood)
		else:
			gfrag = _exp_frag_plank(charred, charred_warm, raw_wood)
		gfrag.position = gpos
		gfrag.rotation = Vector3(
			_rng.randf_range(-0.22, 0.22),
			_rng.randf_range(-PI, PI),
			_rng.randf_range(-0.22, 0.22))
		add_child(gfrag)


# ── Explodedshed helpers (_exp_ prefix) ────────────────────────────────

# Derive a VERY dark charred-wood colour from the DNA base tint. `lift` is the
# target near-black albedo (~0.04-0.11) so the char survives the bright ambient.
func _exp_dark_wood(base: Color, lift: float) -> Color:
	return Color(
		base.r * 0.10 + lift,
		base.g * 0.085 + lift * 0.9,
		base.b * 0.075 + lift * 0.8)


# A uniform-ish random unit vector on the sphere (drives feature/wire/fallout).
func _exp_rand_dir() -> Vector3:
	var z: float = _rng.randf_range(-1.0, 1.0)
	var a: float = _rng.randf_range(0.0, TAU)
	var r: float = sqrt(maxf(0.0, 1.0 - z * z))
	return Vector3(r * cos(a), z, r * sin(a))


# Build a basis whose local +Y (the fragment's long axis) points along `dir`.
func _exp_outward_basis(dir: Vector3) -> Basis:
	var up: Vector3 = dir.normalized()
	var ref: Vector3 = Vector3.RIGHT
	if absf(up.dot(ref)) > 0.95:
		ref = Vector3.FORWARD
	var x_axis: Vector3 = ref.cross(up).normalized()
	var z_axis: Vector3 = x_axis.cross(up).normalized()
	return Basis(x_axis, up, z_axis)


# Place a fragment node at `pos`, long axis pointing radially outward along
# `dir`, then add a small random tumble so it isn't too neat (the winning read).
func _exp_place_radial(frag: Node3D, pos: Vector3, dir: Vector3) -> void:
	frag.position = pos
	var basis: Basis = _exp_outward_basis(dir)
	# Tumble: free spin about the radial axis + a modest off-axis lean.
	basis = basis.rotated(basis.y.normalized(), _rng.randf_range(0.0, TAU))
	basis = basis.rotated(basis.x.normalized(), _rng.randf_range(-0.45, 0.45))
	frag.basis = basis
	add_child(frag)


# A box mesh as a child of `parent` (local placement — for compound fragments).
func _exp_child_box(parent: Node3D, size: Vector3, pos: Vector3, rot: Vector3,
		mat: StandardMaterial3D) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var bm: BoxMesh = BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi


# A cylinder mesh as a child of `parent` (local placement).
func _exp_child_cyl(parent: Node3D, top_r: float, bot_r: float, height: float,
		pos: Vector3, rot: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var cm: CylinderMesh = CylinderMesh.new()
	cm.top_radius = top_r
	cm.bottom_radius = bot_r
	cm.height = height
	cm.radial_segments = 10
	mi.mesh = cm
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi


# The glowing bulb at the heart: emissive glass sphere + hot filament + brass
# screw cap + a faint bloom halo, and the OmniLight3D that casts the shadows.
func _exp_build_bulb(core: Vector3) -> void:
	var bulb_r: float = maxf(0.05, sculpt_width * 0.085)
	# Glass envelope — accent-tinted warm glow.
	var glow_col: Color = accent.lerp(Color(1.0, 0.9, 0.66), 0.5)
	var glass_energy: float = 8.0 if emissive else 5.0
	var glass: StandardMaterial3D = _make_emissive_mat(glow_col, glass_energy)
	glass.roughness = 0.12
	_add_sphere("ExpBulb", bulb_r, core, glass)
	# Hot filament hint just inside the glass.
	var filament: StandardMaterial3D = _make_emissive_mat(
		Color(1.0, 0.6, 0.25), glass_energy * 1.5)
	_add_sphere("ExpFilament", bulb_r * 0.33, core, filament)
	# Brass screw cap below so it reads as a bulb, not a bare orb.
	var brass: StandardMaterial3D = _make_mat(Color(0.5, 0.42, 0.22), 0.35, 0.8)
	_add_cyl("ExpCap", bulb_r * 0.5, bulb_r * 0.62, bulb_r * 0.75,
		core + Vector3(0.0, -bulb_r * 1.25, 0.0), Vector3.ZERO, brass)

	# Faint unshaded bloom halo (fakes glow without post-processing).
	var halo: MeshInstance3D = MeshInstance3D.new()
	halo.name = "ExpHalo"
	var hm: SphereMesh = SphereMesh.new()
	hm.radius = bulb_r * 2.4
	hm.height = bulb_r * 4.8
	hm.radial_segments = 18
	hm.rings = 9
	halo.mesh = hm
	var hmat: StandardMaterial3D = StandardMaterial3D.new()
	hmat.albedo_color = Color(glow_col.r, glow_col.g, glow_col.b, 0.16)
	hmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hmat.cull_mode = BaseMaterial3D.CULL_FRONT
	hmat.emission_enabled = true
	hmat.emission = glow_col
	hmat.emission_energy_multiplier = 2.4 if emissive else 1.6
	halo.material_override = hmat
	halo.position = core
	add_child(halo)

	# OmniLight at the dead centre — carves the dramatic radial shadows.
	var light: OmniLight3D = OmniLight3D.new()
	light.name = "ExpCoreLight"
	light.position = core
	light.light_color = glow_col
	light.light_energy = 11.0 if emissive else 6.0
	light.omni_range = maxf(3.0, sculpt_width * 5.0)
	light.omni_attenuation = 1.5
	light.shadow_enabled = true
	add_child(light)


# Pick a debris archetype by index buckets (deterministic, well-mixed counts).
func _exp_make_fragment(i: int, charred: StandardMaterial3D,
		charred_warm: StandardMaterial3D, raw_wood: StandardMaterial3D,
		metal: StandardMaterial3D) -> Node3D:
	# More object variety as complexity rises; planks/splinters always dominate.
	var obj_every: int = clampi(20 - complexity, 12, 18)
	if i % obj_every == 0:
		match (i / obj_every) % 3:
			0:
				return _exp_obj_watering_can(metal, charred)
			1:
				return _exp_obj_tool(metal, raw_wood, charred)
			_:
				return _exp_obj_chair_leg(charred_warm)
	var kind: int = i % 8
	if kind <= 3:
		return _exp_frag_plank(charred, charred_warm, raw_wood)
	elif kind <= 5:
		return _exp_frag_splinter(charred, raw_wood)
	else:
		return _exp_frag_chunk(charred, charred_warm)


# Charred plank — thin long dark board. DUAL-TONE (v1): a paler RAW split face
# stub on one charred end so the break reads as fresh wood inside burnt skin.
# Long axis is local +Y (so _exp_place_radial flies it outward).
func _exp_frag_plank(charred: StandardMaterial3D, charred_warm: StandardMaterial3D,
		raw_wood: StandardMaterial3D) -> Node3D:
	var n: Node3D = Node3D.new()
	var length: float = _rng.randf_range(0.24, 0.5)
	var width: float = _rng.randf_range(0.05, 0.1)
	var thick: float = _rng.randf_range(0.014, 0.026)
	var body_mat: StandardMaterial3D = charred if _rng.randf() < 0.7 else charred_warm
	_exp_child_box(n, Vector3(width, length, thick), Vector3.ZERO, Vector3.ZERO, body_mat)
	# Raw-wood split face stub at one snapped end (dual-tone storytelling).
	if _rng.randf() < 0.45:
		var stub_h: float = _rng.randf_range(0.03, 0.07)
		_exp_child_box(n, Vector3(width * 0.92, stub_h, thick * 0.92),
			Vector3(0.0, length * 0.5 + stub_h * 0.4, 0.0),
			Vector3(0.0, _rng.randf_range(-0.3, 0.3), 0.0), raw_wood)
	# A jagged splinter tip jutting from the other end (not a clean box edge).
	if _rng.randf() < 0.5:
		_exp_child_box(n, Vector3(width * 0.4, _rng.randf_range(0.05, 0.11), thick * 0.6),
			Vector3(_rng.randf_range(-width * 0.25, width * 0.25),
				-length * 0.5 - 0.03, 0.0),
			Vector3(0.0, 0.0, _rng.randf_range(-0.5, 0.5)), body_mat)
	return n


# Splinter — a tapered jagged shard (cylinder tapering to a point), long axis +Y.
func _exp_frag_splinter(charred: StandardMaterial3D, raw_wood: StandardMaterial3D) -> Node3D:
	var n: Node3D = Node3D.new()
	var length: float = _rng.randf_range(0.12, 0.3)
	var base_r: float = _rng.randf_range(0.008, 0.02)
	var mat: StandardMaterial3D = raw_wood if _rng.randf() < 0.4 else charred
	# Tapered tip (top_radius ~0) gives a sharp shard rather than a clean box.
	_exp_child_cyl(n, base_r * 0.15, base_r, length, Vector3.ZERO, Vector3.ZERO, mat)
	return n


# Chunk — a small irregular blocky lump.
func _exp_frag_chunk(charred: StandardMaterial3D, charred_warm: StandardMaterial3D) -> Node3D:
	var n: Node3D = Node3D.new()
	var a: float = _rng.randf_range(0.04, 0.1)
	var b: float = _rng.randf_range(0.04, 0.1)
	var c: float = _rng.randf_range(0.03, 0.08)
	var mat: StandardMaterial3D = charred if _rng.randf() < 0.75 else charred_warm
	_exp_child_box(n, Vector3(a, b, c), Vector3.ZERO, Vector3.ZERO, mat)
	return n


# Watering can — body cylinder + angled spout + handle box (scorched grey metal).
func _exp_obj_watering_can(metal: StandardMaterial3D, charred: StandardMaterial3D) -> Node3D:
	var n: Node3D = Node3D.new()
	_exp_child_cyl(n, 0.065, 0.078, 0.14, Vector3.ZERO, Vector3.ZERO, metal)
	_exp_child_cyl(n, 0.012, 0.02, 0.16,
		Vector3(0.085, 0.05, 0.0), Vector3(0.0, 0.0, deg_to_rad(-55.0)), metal)
	_exp_child_box(n, Vector3(0.014, 0.11, 0.014),
		Vector3(-0.06, 0.07, 0.0), Vector3(0.0, 0.0, deg_to_rad(32.0)), metal)
	# A scorched wooden carry-grip across the handle top.
	_exp_child_box(n, Vector3(0.02, 0.02, 0.06),
		Vector3(-0.08, 0.11, 0.0), Vector3.ZERO, charred)
	return n


# Tool (spade/trowel) — raw-wood handle + flat metal blade + charred grip top.
func _exp_obj_tool(metal: StandardMaterial3D, raw_wood: StandardMaterial3D,
		charred: StandardMaterial3D) -> Node3D:
	var n: Node3D = Node3D.new()
	_exp_child_box(n, Vector3(0.02, 0.22, 0.024), Vector3.ZERO, Vector3.ZERO, raw_wood)
	_exp_child_box(n, Vector3(0.075, 0.015, 0.1),
		Vector3(0.0, -0.14, 0.0), Vector3.ZERO, metal)
	_exp_child_box(n, Vector3(0.1, 0.022, 0.022),
		Vector3(0.0, 0.11, 0.0), Vector3.ZERO, charred)
	return n


# Chair leg — a tapered turned leg with a foot knob (singed wood).
func _exp_obj_chair_leg(wood: StandardMaterial3D) -> Node3D:
	var n: Node3D = Node3D.new()
	var leg_h: float = _rng.randf_range(0.26, 0.36)
	_exp_child_cyl(n, 0.018, 0.03, leg_h, Vector3.ZERO, Vector3.ZERO, wood)
	_exp_child_sphere(n, 0.035, Vector3(0.0, leg_h * 0.5, 0.0), wood)
	return n


# A sphere mesh as a child of `parent` (local placement — knobs/lumps).
func _exp_child_sphere(parent: Node3D, radius: float, pos: Vector3,
		mat: StandardMaterial3D) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var sm: SphereMesh = SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = 12
	sm.rings = 7
	mi.mesh = sm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


# A LARGER recognisable feature fragment for scale + recognition at the outer
# edge: a shed-wall plank panel, a door (with a frame + handle), or a window
# frame (mullioned, with a cracked pane). Long faces run in the local XY plane
# so they fly outward edge-first when placed radially. Chosen by index.
func _exp_make_feature(f: int, charred: StandardMaterial3D,
		charred_warm: StandardMaterial3D, raw_wood: StandardMaterial3D,
		metal: StandardMaterial3D) -> Node3D:
	match f % 3:
		0:
			return _exp_feature_wall(charred, charred_warm, raw_wood)
		1:
			return _exp_feature_door(charred, charred_warm, metal)
		_:
			return _exp_feature_window(charred_warm, metal)


# Shed-wall panel — a few charred planks battened together into a ragged board.
func _exp_feature_wall(charred: StandardMaterial3D, charred_warm: StandardMaterial3D,
		raw_wood: StandardMaterial3D) -> Node3D:
	var n: Node3D = Node3D.new()
	var pw: float = sculpt_width * _rng.randf_range(0.4, 0.55)
	var ph: float = sculpt_width * _rng.randf_range(0.34, 0.46)
	var planks: int = 4
	var board_w: float = pw / float(planks)
	for p in range(planks):
		var px: float = (float(p) - float(planks - 1) * 0.5) * board_w
		var jh: float = ph * _rng.randf_range(0.82, 1.0)
		var mat: StandardMaterial3D = charred if _rng.randf() < 0.7 else charred_warm
		_exp_child_box(n, Vector3(board_w * 0.92, jh, 0.022),
			Vector3(px, _rng.randf_range(-0.02, 0.02) * ph, 0.0), Vector3.ZERO, mat)
	# Two cross-battens on the back, one showing a raw split.
	_exp_child_box(n, Vector3(pw * 1.02, 0.04, 0.018),
		Vector3(0.0, ph * 0.28, -0.022), Vector3.ZERO, raw_wood)
	_exp_child_box(n, Vector3(pw * 1.02, 0.04, 0.018),
		Vector3(0.0, -ph * 0.28, -0.022), Vector3.ZERO, charred)
	return n


# Door — a charred panel with a recessed inset, a frame edge, and a metal handle.
func _exp_feature_door(charred: StandardMaterial3D, charred_warm: StandardMaterial3D,
		metal: StandardMaterial3D) -> Node3D:
	var n: Node3D = Node3D.new()
	var dw: float = sculpt_width * 0.34
	var dh: float = sculpt_width * 0.62
	_exp_child_box(n, Vector3(dw, dh, 0.03), Vector3.ZERO, Vector3.ZERO, charred)
	# Two recessed warm panels on the face.
	_exp_child_box(n, Vector3(dw * 0.6, dh * 0.34, 0.012),
		Vector3(0.0, dh * 0.22, 0.018), Vector3.ZERO, charred_warm)
	_exp_child_box(n, Vector3(dw * 0.6, dh * 0.34, 0.012),
		Vector3(0.0, -dh * 0.22, 0.018), Vector3.ZERO, charred_warm)
	# Metal handle + a hinge plate at the edge.
	_exp_child_cyl(n, 0.014, 0.014, 0.08,
		Vector3(dw * 0.34, 0.0, 0.03), Vector3(deg_to_rad(90.0), 0.0, 0.0), metal)
	_exp_child_box(n, Vector3(0.03, 0.09, 0.012),
		Vector3(-dw * 0.46, dh * 0.3, 0.0), Vector3.ZERO, metal)
	return n


# Window frame — a mullioned charred frame around a faint cracked glass pane.
func _exp_feature_window(wood: StandardMaterial3D, metal: StandardMaterial3D) -> Node3D:
	var n: Node3D = Node3D.new()
	var s: float = sculpt_width * _rng.randf_range(0.3, 0.4)
	var bar: float = s * 0.08
	# Four frame sides.
	_exp_child_box(n, Vector3(s, bar, 0.03), Vector3(0.0, s * 0.5, 0.0), Vector3.ZERO, wood)
	_exp_child_box(n, Vector3(s, bar, 0.03), Vector3(0.0, -s * 0.5, 0.0), Vector3.ZERO, wood)
	_exp_child_box(n, Vector3(bar, s, 0.03), Vector3(s * 0.5, 0.0, 0.0), Vector3.ZERO, wood)
	_exp_child_box(n, Vector3(bar, s, 0.03), Vector3(-s * 0.5, 0.0, 0.0), Vector3.ZERO, wood)
	# Mullion cross-bars.
	_exp_child_box(n, Vector3(s, bar * 0.7, 0.024), Vector3.ZERO, Vector3.ZERO, wood)
	_exp_child_box(n, Vector3(bar * 0.7, s, 0.024), Vector3.ZERO, Vector3.ZERO, wood)
	# A faint cracked glass pane (dark translucent, barely there).
	var pane: StandardMaterial3D = _make_mat(Color(0.5, 0.55, 0.58, 0.22), 0.1, 0.0)
	_exp_child_box(n, Vector3(s * 0.92, s * 0.92, 0.006), Vector3.ZERO, Vector3.ZERO, pane)
	# A shard of broken glass hanging off one corner.
	_exp_child_box(n, Vector3(s * 0.18, s * 0.26, 0.005),
		Vector3(s * 0.28, -s * 0.34, 0.0),
		Vector3(0.0, 0.0, deg_to_rad(22.0)), pane)
	# A scorched metal corner bracket.
	_exp_child_box(n, Vector3(bar * 1.4, bar * 1.4, 0.02),
		Vector3(-s * 0.5, s * 0.5, 0.0), Vector3.ZERO, metal)
	return n


# ── Mode: SPIDER (Louise Bourgeois "Maman" — monumental arachnid) ──────
# A giant spider arched high on eight spindly, tapering BRONZE legs. Each leg
# is sampled along a Catmull-Rom arch through three control points — a high
# body attachment, a KNEE-APEX above the body top, and a fine FOOT point on a
# WIDE floor ring — radius tapering thick→mid→fine, with faceted cast-bronze
# knuckle segments, a ball joint at the knee, and a needle cone at the foot.
# A segmented body (large ABDOMEN slung back, smaller THORAX, small HEAD with
# fang stubs + dark torus segmentation rings) hangs where the legs converge.
# Beneath the abdomen an OPEN wire CAGE (meridian struts + hoops + gather-ring)
# cradles a tumbled cluster of pale, faintly-glowing MARBLE eggs.
#
# Three contradictory materials: dark patinated bronze (legs + body), pale
# smooth marble (eggs), thin dark wire (cage). Per-leg azimuth + length jitter
# and per-egg tumble are drawn from `_rng` so every seed is a distinct sibling.
#
# DNA: color_a = bronze body/leg tint; color_b = marble egg tint; accent =
# patina / egg-glow tint; complexity → leg segment count + egg count + knee
# detail; metallic_amt/rough_amt → bronze finish; emissive → marble egg glow.

func _build_spider() -> void:
	_rng.seed = seed

	var h: float = sculpt_height
	var w: float = sculpt_width
	# Body slung where the legs converge; arch peaks just above it; feet on a
	# wide ring scaled by sculpt_width.
	var body_y: float = h * 0.6
	var arch_peak_y: float = h * 1.0
	var foot_ring: float = w * 1.45
	var abdomen_centre := Vector3(0.0, body_y - h * 0.02, -h * 0.12)

	# --- Materials (3 contradictory registers) ---
	# Dark patinated bronze — legs + body. metallic from metallic_amt (≥0.7).
	var bronze := _make_mat(color_a.darkened(0.55), clampf(rough_amt * 0.7, 0.3, 0.6),
		maxf(metallic_amt, 0.7))
	# A near-black wire/joint register — darker, a touch rougher.
	var wire := _make_mat(color_a.darkened(0.82), 0.6, maxf(metallic_amt * 0.85, 0.6))
	# Pale precious marble — the eggs. Near-white, low roughness, faint glow.
	var egg_tint: Color = color_b.lerp(Color(0.95, 0.94, 0.9), 0.6)
	var marble: StandardMaterial3D
	if emissive:
		marble = _make_emissive_mat(egg_tint, 0.6)
		marble.roughness = 0.3
	else:
		marble = _make_mat(egg_tint, 0.3, 0.0)
		# Faint glow even when not "emissive" so eggs read out of body-shadow.
		marble.emission_enabled = true
		marble.emission = accent.lerp(egg_tint, 0.5)
		marble.emission_energy_multiplier = 0.18

	_spi_build_legs(bronze, wire, body_y, arch_peak_y, foot_ring)
	_spi_build_body(bronze, wire, abdomen_centre)
	_spi_build_egg_sac(bronze, wire, marble, abdomen_centre)


# Eight arched legs splayed radially, each with per-leg azimuth + reach jitter
# so the silhouettes separate rather than blur into a symmetric wheel.
func _spi_build_legs(bronze: StandardMaterial3D, wire: StandardMaterial3D,
		body_y: float, arch_peak_y: float, foot_ring: float) -> void:
	var legs := Node3D.new()
	legs.name = "Legs"
	add_child(legs)

	var leg_count: int = 8
	# complexity drives the per-leg segment count (more = smoother cast tube).
	var steps: int = clampi(complexity * 2 + 2, 12, 22)
	for i in range(leg_count):
		# Even spacing rotated 22.5° (so a pair straddles the +Z front cleanly),
		# plus a small deterministic azimuth jitter to break the wheel.
		var base_ang: float = (float(i) / float(leg_count)) * TAU + deg_to_rad(22.5)
		var ang: float = base_ang + _rng.randf_range(-1.0, 1.0) * deg_to_rad(7.0)
		var dir := Vector3(cos(ang), 0.0, sin(ang))

		# Per-leg arch height + reach variation so no two arches match.
		var reach: float = foot_ring * _rng.randf_range(0.9, 1.08)
		var peak_y: float = arch_peak_y * _rng.randf_range(0.94, 1.06)
		var knee_out: float = reach * _rng.randf_range(0.42, 0.5)

		var leg := Node3D.new()
		leg.name = "Leg_%d" % i
		legs.add_child(leg)

		_spi_leg(leg, bronze, wire, dir, body_y, peak_y, knee_out, reach, steps)


# Build one leg: a tapering bronze tube swept along a Catmull-Rom arch through
# attach → knee-apex → foot, with a ball joint at the knee and a needle foot.
func _spi_leg(parent: Node3D, bronze: StandardMaterial3D, wire: StandardMaterial3D,
		dir: Vector3, body_y: float, peak_y: float, knee_out: float,
		reach: float, steps: int) -> void:
	var h: float = sculpt_height
	# Attachment: high on the body where legs converge (a tight hub).
	var attach := Vector3(dir.x * h * 0.12, body_y + h * 0.05, dir.z * h * 0.12)
	# Knee/apex: ABOVE the body, pushed outward so each leg humps into its own
	# distinct peak — the signature high splayed arch.
	var knee := Vector3(dir.x * knee_out, peak_y, dir.z * knee_out)
	# Foot: a fine point far out on the floor (wide ring).
	var foot := Vector3(dir.x * reach, h * 0.01, dir.z * reach)

	# Sample a smooth arch through the three points (two Catmull-Rom halves with
	# fabricated end tangents → a clean continuous hump).
	var pts: Array[Vector3] = _spi_arch_points(attach, knee, foot, steps)

	# Radii: thick at the body, mid at the knee, vanishingly fine at the foot —
	# kept spindly/needle-thin per the elegance brief.
	var r_attach: float = h * 0.034
	var r_knee: float = h * 0.022
	var r_foot: float = h * 0.004
	var n: int = pts.size()
	for s in range(n - 1):
		var u0: float = float(s) / float(n - 1)
		var u1: float = float(s + 1) / float(n - 1)
		var r0: float = _spi_leg_radius(u0, r_attach, r_knee, r_foot)
		var r1: float = _spi_leg_radius(u1, r_attach, r_knee, r_foot)
		# Low radial-segment count keeps each section faceted, so the leg reads
		# as discrete CAST BRONZE knuckles rather than a smooth pipe.
		_spi_seg_between(parent, pts[s], pts[s + 1], r0, r1, bronze, 6)

	# Knee joint — a small ball nubbin at the apex so the joint reads.
	var knee_idx: int = int(round(0.5 * float(n - 1)))
	_spi_blob(parent, pts[knee_idx], r_knee * 1.6,
		Vector3(1.0, 0.85, 1.0), wire, 10)

	# Foot — a fine needle cone driving the point into the floor.
	_spi_seg_between(parent, pts[n - 1], foot + Vector3(0.0, -h * 0.012, 0.0),
		r_foot, r_foot * 0.4, bronze, 5)


# Radius profile along a leg: u=0 attach (thick) → u=0.5 knee (mid) → u=1 foot
# (fine point). The foot half eases (squared) so the tube stays slim then
# pinches sharply to a needle.
func _spi_leg_radius(u: float, r_attach: float, r_knee: float,
		r_foot: float) -> float:
	if u < 0.5:
		return lerpf(r_attach, r_knee, u / 0.5)
	var v: float = (u - 0.5) / 0.5
	return lerpf(r_knee, r_foot, v * v)


# Segmented body: a large ABDOMEN slung back (−Z), a smaller THORAX, a small
# HEAD forward (+Z) with two fang stubs, plus dark torus segmentation rings.
func _spi_build_body(bronze: StandardMaterial3D, wire: StandardMaterial3D,
		abdomen_centre: Vector3) -> void:
	var body := Node3D.new()
	body.name = "Body"
	add_child(body)

	var h: float = sculpt_height

	# ABDOMEN — large ovoid, elongated front-back, slung slightly back + down.
	_spi_blob(body, abdomen_centre, h * 0.21,
		Vector3(0.92, 0.86, 1.18), bronze, 22)
	# A second smaller lobe gives the abdomen a teardrop, segmented read.
	_spi_blob(body, abdomen_centre + Vector3(0.0, h * 0.012, -h * 0.16),
		h * 0.13, Vector3(1.0, 0.9, 1.0), bronze, 18)

	# Dark torus SEGMENTATION RINGS banding the abdomen front-back.
	var ring_count: int = 3
	for k in range(ring_count):
		var fz: float = lerpf(-h * 0.1, h * 0.1, float(k) / float(ring_count - 1))
		var ring := MeshInstance3D.new()
		ring.name = "AbdoRing_%d" % k
		var tm := TorusMesh.new()
		# Band radius narrows toward the ends of the ovoid.
		var seg_r: float = h * 0.205 * sqrt(maxf(0.0, 1.0 - pow(fz / (h * 0.20), 2.0)))
		tm.inner_radius = maxf(seg_r * 0.88, 0.01)
		tm.outer_radius = maxf(seg_r * 0.98, 0.02)
		tm.rings = 24
		tm.ring_segments = 12
		ring.mesh = tm
		ring.material_override = wire
		ring.position = abdomen_centre + Vector3(0.0, 0.0, fz)
		# Torus lies in XZ (hole along +Y); rotate so it bands front-back.
		ring.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
		ring.scale = Vector3(0.92, 1.0, 0.88)
		body.add_child(ring)

	# THORAX — smaller ovoid forward (+Z) and slightly up.
	var thorax_c: Vector3 = abdomen_centre + Vector3(0.0, h * 0.012, h * 0.26)
	_spi_blob(body, thorax_c, h * 0.105, Vector3(0.95, 0.9, 1.05), bronze, 18)
	# A short neck link so the body reads as one continuous segmented mass.
	_spi_seg_between(body, abdomen_centre + Vector3(0.0, 0.0, h * 0.11),
		thorax_c + Vector3(0.0, 0.0, -h * 0.06),
		h * 0.07, h * 0.075, bronze, 10)

	# HEAD — small node forward and a touch down.
	var head_c: Vector3 = thorax_c + Vector3(0.0, -h * 0.012, h * 0.14)
	_spi_blob(body, head_c, h * 0.05, Vector3(1.0, 0.95, 1.15), bronze, 14)

	# Two small fang stubs / pedipalps under the head for menace.
	for sgn in [-1.0, 1.0]:
		var base: Vector3 = head_c + Vector3(sgn * h * 0.028, -h * 0.014, h * 0.04)
		var tip: Vector3 = base + Vector3(sgn * h * 0.034, -h * 0.06, h * 0.06)
		_spi_seg_between(body, base, tip, h * 0.012, h * 0.0025, bronze, 5)


# Egg sac: an OPEN wire cage (meridian struts + hoops + top gather-ring) hung
# under the abdomen, enclosing a tumbled cluster of pale glowing marble eggs.
func _spi_build_egg_sac(bronze: StandardMaterial3D, wire: StandardMaterial3D,
		marble: StandardMaterial3D, abdomen_centre: Vector3) -> void:
	var sac := Node3D.new()
	sac.name = "EggSac"
	add_child(sac)

	var h: float = sculpt_height
	var sac_c: Vector3 = abdomen_centre + Vector3(0.0, -h * 0.30, h * 0.01)
	var sac_r: float = h * 0.17

	# A short bronze stalk hanging the cage off the abdomen underside.
	_spi_seg_between(sac,
		abdomen_centre + Vector3(0.0, -h * 0.1, 0.0),
		sac_c + Vector3(0.0, sac_r * 0.85, 0.0),
		h * 0.018, h * 0.01, bronze, 8)

	# --- Tumbled cluster of MARBLE eggs (varied size + orientation per seed) ---
	var egg_n: int = clampi(complexity + 1, 5, 9)
	var er: float = sac_r * 0.30
	for j in range(egg_n):
		# Sample a snug offset inside the cage volume (biased to the interior).
		var dir := Vector3(_rng.randf_range(-1.0, 1.0),
			_rng.randf_range(-1.0, 1.0),
			_rng.randf_range(-1.0, 1.0)).normalized()
		var rr: float = sac_r * 0.55 * pow(_rng.randf(), 0.5)
		var ec: Vector3 = sac_c + dir * rr
		var sc: float = _rng.randf_range(0.82, 1.12)
		# Tumble each egg: a slightly squashed ovoid at a random orientation.
		var squash := Vector3(sc, sc * _rng.randf_range(1.05, 1.22), sc)
		var basis := Basis()
		basis = basis.rotated(Vector3.UP, _rng.randf_range(0.0, TAU))
		basis = basis.rotated(Vector3.RIGHT, _rng.randf_range(-0.6, 0.6))
		basis = basis.scaled(squash * er * 2.0)
		var egg := MeshInstance3D.new()
		egg.name = "Egg_%d" % j
		var sm := SphereMesh.new()
		sm.radius = 0.5
		sm.height = 1.0
		sm.radial_segments = 18
		sm.rings = 12
		egg.mesh = sm
		egg.material_override = marble
		egg.transform = Transform3D(basis, ec)
		sac.add_child(egg)

	# --- Open wire CAGE: meridian struts bowing out at the equator ---
	var meridians: int = 8
	var strut_r: float = h * 0.005
	var top := Vector3(sac_c.x, sac_c.y + sac_r * 1.0, sac_c.z)
	var bot := Vector3(sac_c.x, sac_c.y - sac_r * 1.05, sac_c.z)
	var bow_steps: int = 7
	for m in range(meridians):
		var a: float = (float(m) / float(meridians)) * TAU
		var off := Vector3(cos(a), 0.0, sin(a))
		# Bulge control fully out at the equator → a rounded basket.
		var equ := Vector3(sac_c.x + off.x * sac_r, sac_c.y - sac_r * 0.04,
			sac_c.z + off.z * sac_r)
		var prev: Vector3 = top
		for s in range(1, bow_steps + 1):
			var t: float = float(s) / float(bow_steps)
			var p: Vector3 = _spi_bezier(top, equ, bot, t)
			_spi_seg_between(sac, prev, p, strut_r, strut_r, wire, 4)
			prev = p

	# --- A couple of horizontal hoops binding the struts ---
	_spi_hoop(sac, sac_c + Vector3(0.0, sac_r * 0.30, 0.0), sac_r * 0.92,
		strut_r, wire)
	_spi_hoop(sac, sac_c - Vector3(0.0, sac_r * 0.32, 0.0), sac_r * 0.66,
		strut_r, wire)

	# --- A small knotted gather-ring at the cage top ---
	_spi_hoop(sac, top, sac_r * 0.20, strut_r * 1.3, wire)
	_spi_blob(sac, top, strut_r * 2.2, Vector3.ONE, wire, 8)


# ── SPIDER private helpers (prefixed _spi_) ────────────────────────────

# A tapered bronze/wire tube between two world points, oriented via a
# basis-from-axis (CylinderMesh runs along +Y), parented to `parent`.
func _spi_seg_between(parent: Node3D, a: Vector3, b: Vector3, r0: float,
		r1: float, mat: StandardMaterial3D, sides: int) -> void:
	var axis: Vector3 = b - a
	var length: float = axis.length()
	if length < 0.0002:
		return
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = maxf(r1, 0.0008)
	cm.bottom_radius = maxf(r0, 0.0008)
	cm.height = length
	cm.radial_segments = sides
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = mat
	var dir: Vector3 = axis / length
	mi.transform = Transform3D(_spi_basis_from_y(dir), (a + b) * 0.5)
	parent.add_child(mi)


# Build an orthonormal basis whose +Y maps to `dir`.
func _spi_basis_from_y(dir: Vector3) -> Basis:
	var y: Vector3 = dir.normalized()
	var ref: Vector3 = Vector3.RIGHT
	if absf(y.dot(ref)) > 0.95:
		ref = Vector3.FORWARD
	var x: Vector3 = ref.cross(y).normalized()
	var z: Vector3 = x.cross(y).normalized()
	return Basis(x, y, z).orthonormalized()


# A scaled sphere ovoid (joint / lobe) parented to `parent`.
func _spi_blob(parent: Node3D, pos: Vector3, radius: float, scale: Vector3,
		mat: StandardMaterial3D, segs: int) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = segs
	sm.rings = int(maxf(float(segs) * 0.6, 6.0))
	mi.mesh = sm
	mi.material_override = mat
	mi.transform = Transform3D(Basis().scaled(scale), pos)
	parent.add_child(mi)


# A horizontal wire hoop (ring of short chords) at `centre`, radius `r`.
func _spi_hoop(parent: Node3D, centre: Vector3, r: float, wire_r: float,
		mat: StandardMaterial3D) -> void:
	var n: int = 16
	var prev := centre + Vector3(r, 0.0, 0.0)
	for k in range(1, n + 1):
		var a: float = (float(k) / float(n)) * TAU
		var p := centre + Vector3(cos(a) * r, 0.0, sin(a) * r)
		_spi_seg_between(parent, prev, p, wire_r, wire_r, mat, 4)
		prev = p


# Two Catmull-Rom halves through (a → apex → b) with fabricated end tangents,
# giving a smooth continuous hump that passes through all three points.
func _spi_arch_points(a: Vector3, apex: Vector3, b: Vector3,
		steps: int) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var pre: Vector3 = a + (a - apex) * 0.5
	var post: Vector3 = b + (b - apex) * 0.5
	var half: int = int(steps / 2)
	for s in range(half + 1):
		var u: float = float(s) / float(half)
		out.append(_spi_catmull(pre, a, apex, b, u))
	for s in range(1, steps - half + 1):
		var u: float = float(s) / float(steps - half)
		out.append(_spi_catmull(a, apex, b, post, u))
	return out


func _spi_catmull(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3,
		u: float) -> Vector3:
	var u2: float = u * u
	var u3: float = u2 * u
	return 0.5 * (
		(2.0 * p1)
		+ (-p0 + p2) * u
		+ (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * u2
		+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * u3
	)


# Quadratic Bézier sample (used for the egg-cage meridian bow).
func _spi_bezier(p0: Vector3, p1: Vector3, p2: Vector3, t: float) -> Vector3:
	var u: float = 1.0 - t
	return p0 * (u * u) + p1 * (2.0 * u * t) + p2 * (t * t)


# ── Mode: BALLOONDOG (Jeff Koons — mirror-chrome twisted party balloon) ─
# A child's twisted party-balloon dog rendered monumental in mirror-polished
# saturated chrome. Built as ONE continuous balloon: each limb is a smooth
# high-poly CapsuleMesh segment (radial ~36, rings ~16-28) oriented between two
# endpoints via a basis-from-axis helper. Neighbouring segments OVERLAP ~65% of
# girth so they fuse, and a mid-BULGE swell sphere at each segment's belly gives
# the authentic over-inflated pillow shape. Squashed, darkened PINCH knots sit
# at every twist (hips, shoulders, knees, neck, head-crown, ear roots, tail).
# Classic standing-dog anatomy (v4 pose): a fat horizontal BODY tube, four
# two-segment bent-knee LEGS, an upright NECK to a HEAD + snout nub, TWO long
# EARS that arc OUTWARD before drooping (so they separate from the head mass),
# and a short kinked-up TAIL. The whole dog is yawed ~32° to a readable 3/4 view.
#
# Chrome MUST read as glossy colour, never black: metallic = 1.0, roughness ~
# 0.05, a saturated Koons tint with a lightened albedo, a FAINT EMISSION FLOOR
# of the tint (always on, so an unlit headless capture never goes black), a rim,
# and a touch of clearcoat for a crisp highlight.
#
# DNA: color_a = chrome tint; color_b = pinch/darken tint; accent = highlight /
# emission-floor tint; complexity → segment ring-count + ear length; metallic_amt
# (default high) + rough_amt (~0.05) → chrome finish; emissive → boosts the glow
# floor (but the floor is ALWAYS on). `_rng` adds slight deterministic pose
# jitter (per-segment angle wobble) so each seed is a distinct sibling.

func _build_balloondog() -> void:
	_rng.seed = seed

	# --- Chrome materials (body + darkened pinch), both with an emission floor ---
	# color_a is the saturated chrome tint; accent tints the emission floor and
	# rim sheen; color_b darkens the pinch knots so twists read.
	var floor_tint: Color = accent if accent.get_luminance() > 0.02 else color_a
	var body_mat: StandardMaterial3D = _bd_chrome(color_a, floor_tint, 0.0)
	var pinch_tint: Color = color_b if color_b.get_luminance() > 0.02 else color_a.darkened(0.18)
	var pinch_mat: StandardMaterial3D = _bd_chrome(pinch_tint.darkened(0.12), floor_tint, 0.04)

	# Ring count for the smooth tubes scales with complexity (smoother = fatter
	# balloon read), clamped so it stays performant and warning-clean.
	var rings: int = clampi(complexity * 3 + 8, 16, 28)

	# Anatomy authored facing +Z. The capture camera sits at azimuth ~32° (from +Z
	# toward +X), so a 32° yaw pointed the nose straight AT the camera (head-on blob).
	# Yaw ~122° (perpendicular to the camera axis) presents the full side profile —
	# the readable balloon-dog silhouette. (+ a touch of seeded jitter, deterministic.)
	var pose := Node3D.new()
	pose.name = "BalloonDogPose"
	pose.rotation_degrees = Vector3(0.0, 122.0 + _rng.randf_range(-6.0, 6.0), 0.0)
	add_child(pose)

	# --- Balloon-animal proportions: FATTEN the body vs the thinner legs. ---
	# Scaled to ~sculpt_height tall; widths track sculpt_width a little.
	var s: float = sculpt_height / 1.7         # overall scale (design is ~1.7 m)
	var wfat: float = lerpf(1.0, 1.12, clampf(sculpt_width - 1.0, 0.0, 1.0))
	var body_girth: float = 0.165 * s * wfat
	var leg_girth: float = 0.130 * s
	var neck_girth: float = 0.150 * s
	var head_girth: float = 0.158 * s
	var ear_girth: float = 0.086 * s
	var tail_girth: float = 0.105 * s

	# Key reference points (origin bottom-centre, +Z = forward / front of dog).
	var belly_y: float = 0.92 * s              # height of the horizontal body tube
	var body_half: float = 0.46 * s
	var back_z: float = -body_half             # rear of body toward -Z
	var front_z: float = body_half             # front of body toward +Z

	# ---- BODY: one fat horizontal tube linking front and back ----
	var body_back := Vector3(0.0, belly_y, back_z)
	var body_front := Vector3(0.0, belly_y, front_z)
	_bd_segment(pose, body_back, body_front, body_girth, body_mat, rings, 1.06)
	# Mid-body twist pinch where the two halves meet.
	_bd_pinch(pose, Vector3(0.0, belly_y, (back_z + front_z) * 0.5), body_girth * 0.92,
		Vector3(0.0, 0.0, 1.0), pinch_mat)

	# ---- LEGS: each = two segments meeting at a bent knee (classic stance) ----
	var stance: float = 0.235 * s
	var foot_y: float = leg_girth              # feet rest so the balloon bottom ~ y=0
	var hip_back_z: float = back_z + 0.06 * s
	var hip_front_z: float = front_z - 0.06 * s
	_bd_leg(pose, Vector3(stance, belly_y - 0.02 * s, hip_front_z), foot_y,
		hip_front_z + 0.10 * s, leg_girth, body_mat, pinch_mat, rings)    # front-right
	_bd_leg(pose, Vector3(-stance, belly_y - 0.02 * s, hip_front_z), foot_y,
		hip_front_z + 0.10 * s, leg_girth, body_mat, pinch_mat, rings)    # front-left
	_bd_leg(pose, Vector3(stance, belly_y - 0.02 * s, hip_back_z), foot_y,
		hip_back_z - 0.10 * s, leg_girth, body_mat, pinch_mat, rings)     # back-right
	_bd_leg(pose, Vector3(-stance, belly_y - 0.02 * s, hip_back_z), foot_y,
		hip_back_z - 0.10 * s, leg_girth, body_mat, pinch_mat, rings)     # back-left

	# Hip / shoulder pinches where the legs twist onto the body.
	for hz in [hip_front_z, hip_back_z]:
		var hzf: float = float(hz)
		_bd_pinch(pose, Vector3(stance * 0.72, belly_y - 0.02 * s, hzf),
			leg_girth * 1.12, Vector3(0.4, 1.0, 0.0), pinch_mat)
		_bd_pinch(pose, Vector3(-stance * 0.72, belly_y - 0.02 * s, hzf),
			leg_girth * 1.12, Vector3(-0.4, 1.0, 0.0), pinch_mat)

	# ---- NECK / CHEST: tall upright balloon rising from the front of body ----
	var neck_base := Vector3(0.0, belly_y + 0.04 * s, front_z - 0.01 * s)
	var neck_top := Vector3(0.0, belly_y + 0.56 * s, front_z + 0.10 * s)
	_bd_segment(pose, neck_base, neck_top, neck_girth, body_mat, rings, 1.05)
	_bd_pinch(pose, neck_base + Vector3(0.0, 0.02 * s, 0.0), neck_girth * 1.05,
		Vector3(0.2, 1.0, 0.4), pinch_mat)

	# ---- HEAD: balloon projecting up & forward; snout clearly points +Z ----
	var head_back := neck_top + Vector3(0.0, 0.12 * s, 0.06 * s)
	var head_front := head_back + Vector3(0.0, 0.0, 0.46 * s)
	_bd_segment(pose, head_back, head_front, head_girth, body_mat, rings, 1.08)
	# Neck→head twist pinch.
	_bd_pinch(pose, neck_top + Vector3(0.0, 0.07 * s, 0.04 * s), head_girth * 0.85,
		Vector3(0.0, 0.5, 1.0), pinch_mat)
	# Snout nub at the tip of the muzzle (reuse the artifact's sphere helper).
	_bd_sphere(pose, head_front + Vector3(0.0, 0.0, 0.08 * s), head_girth * 0.66, body_mat)

	# ---- EARS: two long balloons that arc OUTWARD before drooping ----
	# (v3/v4 fix): route each ear out to the side first so it separates from the
	# head/neck mass, then it bends down and slightly back into the floppy droop.
	var ear_root := head_back + Vector3(0.0, 0.0, 0.10 * s)
	_bd_ear(pose, ear_root, 1.0, ear_girth, s, body_mat, pinch_mat, rings)   # right
	_bd_ear(pose, ear_root, -1.0, ear_girth, s, body_mat, pinch_mat, rings)  # left
	# Ear-root pinch where both ears twist off the head.
	_bd_pinch(pose, ear_root, ear_girth * 1.15, Vector3(1.0, 0.2, 0.0), pinch_mat)

	# ---- TAIL: short balloon at the rear, kinked upward ----
	var tail_base := Vector3(0.0, belly_y + 0.04 * s, back_z + 0.02 * s)
	var tail_kink := tail_base + Vector3(0.0, 0.14 * s, -0.18 * s)
	var tail_tip := tail_kink + Vector3(0.0, 0.20 * s, -0.10 * s)
	_bd_segment(pose, tail_base, tail_kink, tail_girth, body_mat, rings, 1.04)
	_bd_segment(pose, tail_kink, tail_tip, tail_girth * 0.85, body_mat, rings, 1.0)
	_bd_pinch(pose, tail_base, tail_girth * 1.1, Vector3(0.0, 1.0, 0.6), pinch_mat)
	_bd_sphere(pose, tail_tip, tail_girth * 0.78, body_mat)


# ── BALLOONDOG private helpers (prefixed _bd_) ─────────────────────────

# Glossy coloured chrome with a mandatory emission FLOOR. Mirror metal renders
# near-black in an unlit headless capture (no reflection probe), so the floor of
# its own tint + a lightened albedo + rim keep it reading as saturated chrome.
# `extra_floor` is added to the base floor energy (pinches sit a touch brighter).
func _bd_chrome(tint: Color, floor_tint: Color, extra_floor: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	# Lightened albedo so the candy-steel reads bright, not a dark silhouette.
	m.albedo_color = tint.lightened(0.22)
	m.metallic = maxf(metallic_amt, 0.9)
	m.metallic_specular = 1.0
	m.roughness = clampf(rough_amt, 0.02, 0.12) if rough_amt < 0.2 else 0.05
	# Emission floor — ALWAYS on. `emissive` only boosts it; it never turns off,
	# so the chrome never renders black.
	m.emission_enabled = true
	m.emission = floor_tint.lerp(tint, 0.5)
	var base_floor: float = 0.34 + extra_floor
	m.emission_energy_multiplier = base_floor + (0.12 if emissive else 0.0)
	# Rim so the round balloon volumes pop against a dark backdrop.
	m.rim_enabled = true
	m.rim = 0.5
	m.rim_tint = 0.4
	# A touch of clearcoat keeps the specular highlight crisp (party-balloon sheen).
	m.clearcoat_enabled = true
	m.clearcoat = 0.55
	m.clearcoat_roughness = 0.04
	return m


# One inflated balloon SEGMENT spanning a→b. A smooth high-poly CapsuleMesh
# (cylinder body + true hemispherical caps) so the section stays at FULL GIRTH
# along its length and only rounds at the ends — the genuine over-inflated
# sausage. Overshoots the span by ~65% of girth so adjacent segments OVERLAP and
# fuse into one continuous balloon. A mid-BULGE swell sphere at the belly gives
# the authentic pillow shape (v2). `bulge` ( >1 ) swells the cross-section.
func _bd_segment(parent: Node3D, a: Vector3, b: Vector3, girth: float,
		mat: StandardMaterial3D, rings: int, bulge: float = 1.0) -> void:
	var axis: Vector3 = b - a
	var length: float = axis.length()
	if length < 0.0001:
		return
	var mid: Vector3 = (a + b) * 0.5
	# Slight per-segment angle wobble (deterministic) so the dog reads hand-twisted.
	var jitter: float = _rng.randf_range(-0.02, 0.02)

	var mi := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = girth
	# CapsuleMesh.height is the TOTAL height including both hemispherical caps.
	cap.height = maxf(length + girth * 0.65, girth * 2.0 + 0.01)
	cap.radial_segments = 36
	cap.rings = rings
	mi.mesh = cap
	mi.material_override = mat
	# Cross-section swell for the inflated belly (long axis = local +Y stays 1).
	mi.scale = Vector3(bulge, 1.0, bulge)
	var basis: Basis = _bd_basis_from_y(axis.normalized())
	mi.transform = Transform3D(basis.rotated(basis.y.normalized(), jitter), mid)
	parent.add_child(mi)

	# Mid-belly BULGE: a swell sphere fatter than the tube so the segment pillows
	# in the middle like a real over-inflated balloon (the sin-profile peak at t=0.5).
	var swell := MeshInstance3D.new()
	var sm := SphereMesh.new()
	var swell_r: float = girth * bulge * 1.12
	sm.radius = swell_r
	sm.height = swell_r * 2.0
	sm.radial_segments = 28
	sm.rings = 16
	swell.mesh = sm
	swell.material_override = mat
	# Squash the swell slightly along the segment axis so it reads as a belly
	# bulge fused into the tube, not a bead stuck on.
	swell.transform = Transform3D(_bd_basis_from_y(axis.normalized())
		.scaled(Vector3(1.0, 0.62, 1.0)), mid)
	parent.add_child(swell)


# A PINCH constriction knot where balloon segments twist together — a small
# sphere squashed along the twist axis (so it reads as a tied-off, constricted
# pinch, not a ball) in the DARKENED pinch material so the twist reads.
func _bd_pinch(parent: Node3D, at: Vector3, radius: float, twist_axis: Vector3,
		mat: StandardMaterial3D) -> void:
	var mi := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 24
	sphere.rings = 16
	mi.mesh = sphere
	mi.material_override = mat
	# Squash along the twist axis (local Y), keep girth on the other two — a
	# pinched, constricted waist between two balloon bubbles.
	mi.transform = Transform3D(
		_bd_basis_from_y(twist_axis.normalized()).scaled(Vector3(1.18, 0.55, 1.18)),
		at)
	parent.add_child(mi)


# A plain inflated sphere nub (snout / tail tip), parented to `parent`.
# Wraps _add_sphere's idea but parents to the pose holder, not the root.
func _bd_sphere(parent: Node3D, at: Vector3, radius: float,
		mat: StandardMaterial3D) -> void:
	var mi := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 28
	sphere.rings = 18
	mi.mesh = sphere
	mi.material_override = mat
	mi.position = at
	parent.add_child(mi)


# One leg: upper segment (hip → knee) + lower segment (knee → foot), bent at the
# knee with a pinch and a rounded paw. The knee bows outward + toward the foot so
# the two segments meet at the characteristic balloon-dog bend.
func _bd_leg(parent: Node3D, hip: Vector3, foot_y: float, foot_z: float,
		girth: float, body_mat: StandardMaterial3D, pinch_mat: StandardMaterial3D,
		rings: int) -> void:
	var out_sign: float = signf(hip.x) if absf(hip.x) > 0.001 else 1.0
	var knee := Vector3(
		hip.x + out_sign * 0.11 * (sculpt_height / 1.7),
		(hip.y + foot_y) * 0.52,
		lerpf(hip.z, foot_z, 0.6))
	var foot := Vector3(hip.x + out_sign * 0.02 * (sculpt_height / 1.7), foot_y, foot_z)
	_bd_segment(parent, hip, knee, girth, body_mat, rings, 1.04)
	_bd_segment(parent, knee, foot, girth * 0.96, body_mat, rings, 1.02)
	# Knee pinch (squashed along the leg axis) + a rounded foot paw.
	_bd_pinch(parent, knee, girth * 0.62, (knee - hip).normalized(), pinch_mat)
	_bd_sphere(parent, foot, girth * 0.9, body_mat)


# One long ear that arcs OUTWARD first (separating it from the head/neck mass)
# then bends down and slightly back into the floppy droop. `side` = +1 right /
# -1 left. Two segments + a rounded tip, with a darkened pinch at the bend.
func _bd_ear(parent: Node3D, root: Vector3, side: float, girth: float, s: float,
		body_mat: StandardMaterial3D, pinch_mat: StandardMaterial3D, rings: int) -> void:
	# Ear length scales a little with complexity (more = longer floppier ear).
	var len_k: float = lerpf(0.9, 1.18, clampf(float(complexity - 4) / 6.0, 0.0, 1.0))
	# (1) OUT: arc out to the side and a touch up, clearly off the head.
	var out_pt := root + Vector3(side * 0.20 * s, 0.02 * s, 0.02 * s)
	# (2) BEND: now down and slightly back.
	var bend := root + Vector3(side * 0.24 * s, -0.24 * s * len_k, -0.06 * s)
	# (3) TIP: continue down and back into the droop.
	var tip := root + Vector3(side * 0.20 * s, -0.50 * s * len_k, -0.14 * s)
	_bd_segment(parent, out_pt, bend, girth, body_mat, rings, 1.02)
	_bd_segment(parent, bend, tip, girth * 0.9, body_mat, rings, 1.0)
	# Pinch at the outward bend (where the ear twists from out → down).
	_bd_pinch(parent, bend, girth * 0.9, (bend - out_pt).normalized(), pinch_mat)
	_bd_sphere(parent, tip, girth * 0.85, body_mat)


# Build an orthonormal basis whose local +Y maps to `y_dir` (capsules/spheres
# author along +Y). Mirrors the trials' and spider mode's basis-from-axis.
func _bd_basis_from_y(y_dir: Vector3) -> Basis:
	var y: Vector3 = y_dir.normalized()
	var ref: Vector3 = Vector3.RIGHT
	if absf(y.dot(ref)) > 0.95:
		ref = Vector3.FORWARD
	var x: Vector3 = ref.cross(y).normalized()
	var z: Vector3 = x.cross(y).normalized()
	return Basis(x, y, z).orthonormalized()


# ── Mode: MOBILE (Alexander Calder — the hanging mobile) ───────────────
# Synthesis of four trials into one definitive Calder. A top suspension
# RING + hook drops a short wire to a TOP BAR that STRADDLES the suspension
# point — reaching to BOTH sides (two wings), each feeding its own recursive
# cantilever cascade so the piece spreads WIDE and BALANCED, never leaning
# one way (structure from v4). Each arm is a thin, gently ARCED black wire
# balanced like a scale: a LONG end and a SHORT end, children hung BELOW on
# vertical drop wires, recursing `complexity` levels and shrinking toward the
# leaves, a tiny torus connector at every pivot (arm elegance from v2). The
# balance is made legible as a LEVER: the long arm carries a lighter shape or
# sub-cascade, the short arm a heavier COUNTERWEIGHT plate (v2/v3). Leaves are
# flat biomorphic plates — extruded radial silhouettes (leaf / petal / amoeba
# / disc / kidney) built with SurfaceTool, double-sided, tipped toward vertical
# with a per-plate roll/spin so they face outward and catch light (plates from
# v1/v3/v4); some are PIERCED with a true Calder keyhole (v1). Vertical drops
# are deepened so total HEIGHT ≈ total WIDTH (no flat pancake — good camera
# framing) and the lowest plate stays clear of the floor.
#
# DNA: color_a / color_b / accent → the saturated red / yellow / blue Calder
# plate colours, cycled alongside fixed black + white; complexity → recursion
# depth + plate count; sculpt_width → the two-wing spread; sculpt_height →
# drop height (top ring sits near sculpt_height); metallic_amt (low) +
# rough_amt (~0.72) → the matte paint/wire finish; emissive → a faint plate
# sheen only. `_rng` (seeded from `seed`) drives all deterministic asymmetry.

# Calder palette anchors — fixed black + white round out the primary triad.
const MOB_BLACK: Color = Color(0.06, 0.06, 0.07)
const MOB_WHITE: Color = Color(0.93, 0.93, 0.90)
const MOB_FLOOR_Y: float = 0.22       # lowest plate stays clear of the floor

# Mobile build state (reset at the top of _build_mobile each rebuild).
var _mob_palette: Array[Color] = []
var _mob_color_cursor: int = 0
var _mob_wire_mat: StandardMaterial3D = null
var _mob_plate_mats: Array[StandardMaterial3D] = []
var _mob_plate_count: int = 0          # global plate index (silhouette family)
var _mob_wing_counts: Array[int] = [0, 0]   # plates per wing (keep wings even)


func _build_mobile() -> void:
	_rng.seed = seed

	# Reset per-build mobile state so rebuilds are deterministic & clean.
	_mob_color_cursor = 0
	_mob_plate_count = 0
	_mob_wing_counts = [0, 0]
	_mob_plate_mats.clear()

	# Calder palette: saturate the DNA triad toward primaries, then add the
	# fixed black + white. Falls back to canonical Calder hues if a DNA colour
	# is near-grey, so the piece always reads as red / yellow / blue + B&W.
	var red: Color = _mob_saturate(color_a, Color(0.83, 0.13, 0.11))
	var yellow: Color = _mob_saturate(color_b, Color(0.96, 0.78, 0.10))
	var blue: Color = _mob_saturate(accent, Color(0.10, 0.28, 0.66))
	_mob_palette = [red, yellow, blue, MOB_BLACK, MOB_WHITE]

	# Shared wire material (matte black) + one plate material per palette colour.
	_mob_wire_mat = _make_mat(MOB_BLACK, clampf(rough_amt, 0.6, 0.85), minf(metallic_amt, 0.12))
	for c: Color in _mob_palette:
		var m: StandardMaterial3D = _make_mat(c, 0.72, minf(metallic_amt, 0.08))
		m.cull_mode = BaseMaterial3D.CULL_DISABLED   # flat plate, both faces
		if emissive:
			# A faint sheen only — Calder paint is matte; this just lifts it.
			m.emission_enabled = true
			m.emission = c
			m.emission_energy_multiplier = 0.12
		_mob_plate_mats.append(m)

	var depth: int = clampi(complexity, 3, 6)
	var top_y: float = maxf(sculpt_height, 1.5)

	# Suspension ring + little hook stub at the very top.
	_mob_ring(Vector3(0.0, top_y, 0.0), 0.16, 0.024)
	_mob_curved_wire([
		Vector3(0.0, top_y + 0.12, 0.0),
		Vector3(0.0, top_y + 0.30, 0.0),
		Vector3(0.06, top_y + 0.40, 0.0)], 0.020)

	# Short drop wire from the ring to the top bar's pivot.
	var pivot: Vector3 = Vector3(0.0, top_y - 0.50, 0.0)
	_mob_straight_wire(Vector3(0.0, top_y - 0.14, 0.0), pivot, 0.018)
	_mob_ring(pivot, 0.05, 0.012)

	# Budget the vertical descent so the cascade fills the height (height ≈
	# width) and the lowest plate lands near MOB_FLOOR_Y rather than the floor.
	var usable: float = (pivot.y - MOB_FLOOR_Y)
	var ddrop: float = usable / float(depth)

	# TOP BAR straddles the suspension point: a long reach to BOTH sides, each
	# wing feeding its own recursive sub-cascade (two balanced wings — v4).
	_mob_top_bar(pivot, sculpt_width * 0.5, ddrop, depth)


# Saturate a DNA colour toward a primary; if it is near-grey, use the
# canonical Calder hue so the palette always reads as red / yellow / blue.
func _mob_saturate(src: Color, fallback: Color) -> Color:
	var sat: float = src.s
	if sat < 0.25 or src.get_luminance() < 0.03:
		return fallback
	return Color.from_hsv(src.h, clampf(sat * 1.25, 0.6, 1.0), clampf(maxf(src.v, 0.55), 0.0, 1.0))


# The widest, top-most bar: two ~equal long ends around the centre (a balance
# beam), each end dropping to its own wing sub-cascade. Slight tilt + a touch
# of seeded asymmetry so it reads hand-hung, not mechanical.
func _mob_top_bar(pivot: Vector3, half_span: float, ddrop: float, depth: int) -> void:
	var left_len: float = half_span * _rng.randf_range(0.82, 1.0)
	var right_len: float = half_span * _rng.randf_range(0.80, 0.98)
	var tilt: float = deg_to_rad(_rng.randf_range(-5.0, 5.0))

	var left_end: Vector3 = pivot + Vector3(-left_len, sin(tilt) * left_len, -0.05 * left_len)
	var right_end: Vector3 = pivot + Vector3(right_len, -sin(tilt) * right_len, 0.05 * right_len)

	_mob_arc_arm(left_end, pivot, right_end, 0.021)
	_mob_ring(pivot, 0.045, 0.014)
	_mob_ring(left_end, 0.030, 0.010)
	_mob_ring(right_end, 0.030, 0.010)

	# Each wing drops a short wire to a sub-pivot, then a full balance sub-arm.
	# wing 0 = left, wing 1 = right (used to keep plate counts even).
	var ends: Array[Vector3] = [left_end, right_end]
	for w: int in range(2):
		var end_pt: Vector3 = ends[w]
		var hang: float = ddrop * _rng.randf_range(0.55, 0.85)
		var sub_pivot: Vector3 = end_pt + Vector3(0.0, -hang, 0.0)
		_mob_straight_wire(end_pt, sub_pivot, 0.016)
		# Long end of each wing faces AWAY from centre so wings open outward.
		var face_sign: float = -1.0 if w == 0 else 1.0
		_mob_arm(sub_pivot, 1, depth, half_span * _rng.randf_range(0.52, 0.66),
			ddrop, face_sign, w)


# Recursive balance arm.
#   pivot     : world point the arm hangs from (a connector ring sits here).
#   level     : 0 = top bar; increases toward the leaves.
#   depth     : total recursion depth (from complexity).
#   span      : max horizontal reach of the LONG end at this level.
#   ddrop     : vertical descent budget per level (drives height ≈ width).
#   facing    : +1 / -1 — which side the LONG (branching) end swings.
#   wing      : 0 = left wing, 1 = right wing (for even plate balancing).
func _mob_arm(pivot: Vector3, level: int, depth: int, span: float,
		ddrop: float, facing: float, wing: int) -> void:
	# Asymmetric lever: LONG end vs SHORT end (counterbalance reads as a scale).
	var long_len: float = span * _rng.randf_range(0.78, 1.0)
	var short_len: float = long_len * _rng.randf_range(0.34, 0.52)
	var tilt: float = deg_to_rad(_rng.randf_range(-7.0, 7.0))

	# Both ends sit a little BELOW the pivot so each tier steps downward (the
	# cascade fills the vertical volume instead of fanning out flat).
	var long_end: Vector3 = pivot + Vector3(
		facing * long_len,
		-sin(tilt) * long_len - ddrop * 0.32,
		_rng.randf_range(-0.12, 0.12) * long_len)
	var short_end: Vector3 = pivot + Vector3(
		-facing * short_len,
		sin(tilt) * short_len - ddrop * 0.26,
		_rng.randf_range(-0.12, 0.12) * short_len)

	# Arms thin toward the leaves.
	var rod_r: float = lerpf(0.020, 0.009, float(level) / float(depth))
	_mob_arc_arm(short_end, pivot, long_end, rod_r)
	_mob_ring(pivot, 0.035, 0.011)
	_mob_ring(long_end, 0.026, 0.009)
	_mob_ring(short_end, 0.026, 0.009)

	# Plate size shrinks with depth; the LEVER is legible — the SHORT (counter)
	# side carries a BIGGER, heavier counterweight plate than the LONG side.
	var plate_scale: float = lerpf(1.0, 0.42, float(level) / float(depth))

	# ── SHORT end: the heavier COUNTERWEIGHT plate (bigger of the pair). ──
	var short_hang: float = maxf(ddrop * _rng.randf_range(0.45, 0.8), 0.18)
	_mob_hang_plate(short_end, short_hang, plate_scale * _rng.randf_range(1.05, 1.35), level, depth, wing)

	# ── LONG end: a lighter sub-cascade (recurse), else a lighter plate. ──
	var long_hang: float = maxf(ddrop * _rng.randf_range(0.5, 0.9), 0.18)
	var branch_chance: float = lerpf(0.95, 0.45, float(level) / float(depth))
	if level < depth - 1 and _rng.randf() < branch_chance:
		var sub_pivot: Vector3 = long_end + Vector3(0.0, -long_hang, 0.0)
		_mob_straight_wire(long_end, sub_pivot, rod_r * 0.85)
		var next_facing: float = -facing if _rng.randf() < 0.7 else facing
		_mob_arm(sub_pivot, level + 1, depth,
			span * _rng.randf_range(0.5, 0.66), ddrop, next_facing, wing)
	else:
		_mob_hang_plate(long_end, long_hang, plate_scale * _rng.randf_range(0.6, 0.85),
			level, depth, wing)

	# Occasionally the SHORT end ALSO branches at shallow levels — a bushier,
	# livelier top, while leaves stay sparse.
	if level < 2 and _rng.randf() < 0.5:
		var sub_hang: float = maxf(ddrop * 0.7, 0.18)
		var sub_pivot2: Vector3 = short_end + Vector3(0.0, -sub_hang, 0.0)
		_mob_straight_wire(short_end, sub_pivot2, rod_r * 0.8)
		_mob_arm(sub_pivot2, level + 2, depth, span * 0.42, ddrop, facing, wing)


# Hang a flat biomorphic plate from `node_pos` on a short drop wire, tipped
# toward vertical with a per-plate roll/spin. Keeps the plate clear of the
# floor and cycles the Calder palette deterministically.
func _mob_hang_plate(node_pos: Vector3, hang: float, sscale: float,
		level: int, depth: int, wing: int) -> void:
	var plate_top: Vector3 = node_pos + Vector3(
		_rng.randf_range(-0.05, 0.05), -hang, _rng.randf_range(-0.05, 0.05))

	# Plate footprint (used to keep the bottom of the plate above the floor).
	var base_size: float = lerpf(0.92, 0.46, float(level) / float(depth)) * sscale
	base_size = clampf(base_size, 0.18, 1.05)

	# Centre hangs roughly half a plate below its attach point; clamp so the
	# lowest plates stay clear of the floor (suspended-in-air read).
	var centre_y: float = plate_top.y - base_size * 0.55
	centre_y = maxf(centre_y, MOB_FLOOR_Y + base_size * 0.5)
	var plate_centre: Vector3 = Vector3(plate_top.x, centre_y, plate_top.z)

	# Hang wire from the node down to the plate's top edge.
	_mob_straight_wire(node_pos, plate_centre + Vector3(0.0, base_size * 0.5, 0.0), 0.0085)
	_mob_ring(plate_top, 0.022, 0.008)

	# Palette colour (cycled) + matching material.
	var mat_idx: int = _mob_color_cursor % _mob_plate_mats.size()
	_mob_color_cursor += 1

	# Silhouette family cycles across all plates; ~1 in 3 plates is PIERCED
	# with a keyhole (a true Calder touch) — but never the tiny leaf shapes.
	var family: int = _mob_plate_count % 5
	var holed: bool = (_mob_plate_count % 3 == 1) and base_size > 0.34
	_mob_plate_count += 1
	_mob_wing_counts[wing] += 1

	var plate: MeshInstance3D = MeshInstance3D.new()
	plate.name = "MobilePlate%d" % _mob_plate_count
	plate.mesh = _mob_plate_mesh(base_size, family, holed)
	plate.material_override = _mob_plate_mats[mat_idx]
	plate.position = plate_centre
	# Tip toward vertical (so the silhouette faces outward) + free spin + roll.
	plate.rotation_degrees = Vector3(
		_rng.randf_range(-14.0, 14.0),     # face tip up/down a touch
		_rng.randf_range(0.0, 360.0),      # free spin about vertical
		_rng.randf_range(-12.0, 12.0))     # gentle roll to catch light
	add_child(plate)


# Build a flat biomorphic plate as a thin double-sided slab: an extruded radial
# silhouette (leaf / petal / amoeba / disc / kidney). Local plane is X (right) ×
# Y (up); thickness runs along Z. When `holed`, a small off-centre KEYHOLE is
# punched clean through (annular front/back faces + inner & outer rim walls).
func _mob_plate_mesh(radius: float, family: int, holed: bool) -> ArrayMesh:
	var n: int = 48
	var thickness: float = 0.022
	var hz: float = thickness * 0.5
	var ph: float = _rng.randf_range(0.0, TAU)

	# Outer rim points from the silhouette profile.
	var rim: PackedVector2Array = PackedVector2Array()
	rim.resize(n)
	for i: int in range(n):
		var a: float = TAU * float(i) / float(n)
		var rr: float = _mob_silhouette(a, family, radius, ph)
		rim[i] = Vector2(cos(a) * rr, sin(a) * rr)

	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	if holed:
		# Keyhole: a small circle offset from centre, punched through. Faces are
		# an annulus between the outer rim and the hole rim.
		var hole_r: float = radius * _rng.randf_range(0.14, 0.22)
		var off: Vector2 = Vector2(
			_rng.randf_range(-0.30, 0.30) * radius,
			_rng.randf_range(-0.10, 0.34) * radius)
		var hole: PackedVector2Array = PackedVector2Array()
		hole.resize(n)
		for i: int in range(n):
			var a2: float = TAU * float(i) / float(n)
			hole[i] = off + Vector2(cos(a2) * hole_r, sin(a2) * hole_r)

		# FRONT (+Z) and BACK (-Z) faces as a ring strip (outer → hole).
		for i: int in range(n):
			var o0: Vector2 = rim[i]
			var o1: Vector2 = rim[(i + 1) % n]
			var h0: Vector2 = hole[i]
			var h1: Vector2 = hole[(i + 1) % n]
			# Front (normal +Z): outer ring outside, hole ring inside.
			_mob_tri(st, Vector3(o0.x, o0.y, hz), Vector3(h0.x, h0.y, hz), Vector3(o1.x, o1.y, hz), Vector3(0, 0, 1))
			_mob_tri(st, Vector3(o1.x, o1.y, hz), Vector3(h0.x, h0.y, hz), Vector3(h1.x, h1.y, hz), Vector3(0, 0, 1))
			# Back (normal -Z): reversed winding.
			_mob_tri(st, Vector3(o0.x, o0.y, -hz), Vector3(o1.x, o1.y, -hz), Vector3(h0.x, h0.y, -hz), Vector3(0, 0, -1))
			_mob_tri(st, Vector3(o1.x, o1.y, -hz), Vector3(h1.x, h1.y, -hz), Vector3(h0.x, h0.y, -hz), Vector3(0, 0, -1))
		# OUTER rim wall.
		_mob_rim_wall(st, rim, hz, true)
		# INNER (hole) rim wall — normals point inward toward the hole centre.
		_mob_rim_wall(st, hole, hz, false)
	else:
		# Solid plate: fan front/back from centroid + an outer rim wall.
		var cen: Vector2 = Vector2.ZERO
		for p: Vector2 in rim:
			cen += p
		cen /= float(n)
		var cf: Vector3 = Vector3(cen.x, cen.y, hz)
		var cb: Vector3 = Vector3(cen.x, cen.y, -hz)
		for i: int in range(n):
			var a3: Vector2 = rim[i]
			var b3: Vector2 = rim[(i + 1) % n]
			_mob_tri(st, cf, Vector3(a3.x, a3.y, hz), Vector3(b3.x, b3.y, hz), Vector3(0, 0, 1))
			_mob_tri(st, cb, Vector3(b3.x, b3.y, -hz), Vector3(a3.x, a3.y, -hz), Vector3(0, 0, -1))
		_mob_rim_wall(st, rim, hz, true)

	return st.commit()


# A rim side-wall ribbon between the front (+hz) and back (-hz) perimeters of a
# closed loop. `outward` true → normals face out (outer rim); false → inward
# (a punched hole's inner wall).
func _mob_rim_wall(st: SurfaceTool, loop: PackedVector2Array, hz: float, outward: bool) -> void:
	var n: int = loop.size()
	for i: int in range(n):
		var a: Vector2 = loop[i]
		var b: Vector2 = loop[(i + 1) % n]
		var edge: Vector2 = b - a
		var nrm2: Vector2 = Vector2(edge.y, -edge.x).normalized()
		if not outward:
			nrm2 = -nrm2
		var sn: Vector3 = Vector3(nrm2.x, nrm2.y, 0.0)
		var af: Vector3 = Vector3(a.x, a.y, hz)
		var bf: Vector3 = Vector3(b.x, b.y, hz)
		var ab: Vector3 = Vector3(a.x, a.y, -hz)
		var bb: Vector3 = Vector3(b.x, b.y, -hz)
		if outward:
			_mob_tri(st, af, ab, bb, sn)
			_mob_tri(st, af, bb, bf, sn)
		else:
			_mob_tri(st, af, bb, ab, sn)
			_mob_tri(st, af, bf, bb, sn)


# Radial silhouette profile → the organic plate outline.
#   0 leaf  1 petal/teardrop  2 amoeba (summed harmonics)  3 disc  4 kidney/bean
func _mob_silhouette(ang: float, family: int, radius: float, ph: float) -> float:
	var r: float = radius
	match family:
		0:
			# LEAF — pointed at both poles, fat middle, slight asymmetry.
			r = radius * (0.42 + 0.58 * pow(absf(sin(ang * 0.5 + ph * 0.1)), 0.7))
			r *= 1.0 + 0.12 * sin(ang + ph)
		1:
			# PETAL / teardrop — one rounded lobe tapering to a point.
			var t: float = (ang + PI) / TAU
			r = radius * (0.30 + 0.85 * sin(PI * t) * (0.6 + 0.4 * sin(PI * t)))
			r *= 1.0 + 0.10 * sin(ang * 2.0 + ph)
		2:
			# AMOEBA — several soft lobes (classic Calder blob), summed harmonics.
			r = radius * (0.80
				+ 0.20 * sin(ang * 3.0 + ph)
				+ 0.12 * sin(ang * 5.0 + ph * 1.7)
				+ 0.07 * sin(ang * 2.0 + ph * 0.5))
		4:
			# KIDNEY / bean — a soft indentation on one side.
			r = radius * (0.92 + 0.20 * sin(ang) - 0.34 * exp(-pow(ang - PI, 2.0) * 3.0))
		_:
			# DISC — nearly round with a faint wobble.
			r = radius * (0.94 + 0.06 * sin(ang * 4.0 + ph))
	return maxf(r, radius * 0.18)


# A gently ARCED arm wire through three points (short_end → pivot → long_end):
# the pivot is lifted a little so the rod bows like a hanging balance bar.
func _mob_arc_arm(a: Vector3, mid: Vector3, b: Vector3, radius: float) -> void:
	var lift: Vector3 = mid + Vector3(0.0, absf(a.x - b.x) * 0.05 + 0.04, 0.0)
	var pts: Array[Vector3] = []
	var segs: int = 14
	for i: int in range(segs + 1):
		var t: float = float(i) / float(segs)
		var u: float = 1.0 - t
		pts.append(a * (u * u) + lift * (2.0 * u * t) + b * (t * t))
	_mob_tube(pts, radius)


# A gently curved wire through an arbitrary polyline (used for the hook).
func _mob_curved_wire(pts: Array[Vector3], radius: float) -> void:
	_mob_tube(pts, radius)


# A straight thin wire between two points.
func _mob_straight_wire(a: Vector3, b: Vector3, radius: float) -> void:
	if a.distance_to(b) < 0.001:
		return
	_mob_tube([a, b], radius)


# Sweep a circular cross-section along a polyline → a thin round tube. Reused
# for every wire and arm so joints read continuously (the cleanest of the four
# wire approaches — v4's parallel-transport-ish sweep).
func _mob_tube(pts: Array[Vector3], radius: float) -> void:
	if pts.size() < 2:
		return
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides: int = 7
	var rings: Array[PackedVector3Array] = []

	for i: int in range(pts.size()):
		var tangent: Vector3
		if i == 0:
			tangent = pts[1] - pts[0]
		elif i == pts.size() - 1:
			tangent = pts[i] - pts[i - 1]
		else:
			tangent = pts[i + 1] - pts[i - 1]
		if tangent.length() < 0.0001:
			tangent = Vector3.UP
		tangent = tangent.normalized()
		var up: Vector3 = Vector3.UP
		if absf(tangent.dot(up)) > 0.95:
			up = Vector3.RIGHT
		var nrm: Vector3 = tangent.cross(up).normalized()
		var bnm: Vector3 = tangent.cross(nrm).normalized()
		var ring: PackedVector3Array = PackedVector3Array()
		for s: int in range(sides):
			var ang: float = TAU * float(s) / float(sides)
			ring.append(pts[i] + nrm * (cos(ang) * radius) + bnm * (sin(ang) * radius))
		rings.append(ring)

	for i: int in range(rings.size() - 1):
		var r0: PackedVector3Array = rings[i]
		var r1: PackedVector3Array = rings[i + 1]
		for s: int in range(sides):
			var s2: int = (s + 1) % sides
			_mob_tri(st, r0[s], r1[s], r1[s2], Vector3.ZERO)
			_mob_tri(st, r0[s], r1[s2], r0[s2], Vector3.ZERO)

	st.generate_normals()
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = "MobileWire"
	mi.mesh = st.commit()
	mi.material_override = _mob_wire_mat
	add_child(mi)


# A small torus connector ring/loop at a pivot or hang point (every joint).
func _mob_ring(at: Vector3, major: float, minor: float) -> void:
	var t: TorusMesh = TorusMesh.new()
	t.inner_radius = maxf(major - minor, 0.001)
	t.outer_radius = major + minor
	t.rings = 10
	t.ring_segments = 7
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = "MobileRing"
	mi.mesh = t
	mi.material_override = _mob_wire_mat
	mi.position = at
	# Stand the loop in a vertical plane (reads as a hang loop), with a seeded
	# spin so successive rings don't all align.
	mi.rotation_degrees = Vector3(90.0, _rng.randf_range(0.0, 180.0), 0.0)
	add_child(mi)


# Add one triangle with an explicit normal (Vector3.ZERO → let generate_normals
# handle it, used by the tube sweep which calls generate_normals afterwards).
func _mob_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, nrm: Vector3) -> void:
	if nrm != Vector3.ZERO:
		st.set_normal(nrm)
	st.add_vertex(a)
	if nrm != Vector3.ZERO:
		st.set_normal(nrm)
	st.add_vertex(b)
	if nrm != Vector3.ZERO:
		st.set_normal(nrm)
	st.add_vertex(c)


# ── Mode: PIERCED (Barbara Hepworth — pierced-and-strung carved form) ───
# A biomorphic upright ovoid carved from one block (color_a outer), with a
# fused belly swell and a grounding foot and a slight seeded lean. CSG booleans
# bore it front-to-back (+Z) into a LARGE strung opening plus, when complexity
# allows, a SMALL crown eye. The pierce reads pale (color_b "painted" interior)
# via the TWO-SHELL bake technique: an outer STONE shell bored at the outer hole
# radii and a slightly smaller PALE shell bored at smaller inner radii, so the
# pale throat sits recessed behind the stone rim (real gap → no z-fight, clean
# painted bore). BOTH shells are baked to MeshInstance3D so the headless capture
# (which frames from MeshInstance3D AABBs only, never live CSG) sees the whole
# mass and the pierce actually renders. A fanned, faintly drooping cream harp of
# strings (accent) spans the big mouth; thin pale rims crisp each hole edge; a
# dark plinth grounds it. Deterministic from `seed`.
#
# DNA: color_a → carved outer · color_b → pale interior · accent → strings
#   complexity → hole count (+0..1 crown eye) and string count
#   metallic_amt / rough_amt → outer carved finish · emissive → faint sheen
#   seed (via _rng) → lean, hole placement/size jitter, string count, droop.

func _build_pierced() -> void:
	_rng.seed = seed

	# --- proportions from DNA --------------------------------------------
	var plinth_h: float = maxf(0.06, sculpt_height * 0.05)
	var mass_h: float = maxf(0.4, sculpt_height)            # carved mass height
	var ovoid_ry: float = mass_h * 0.5                      # ovoid half-height
	# Half-width / half-depth of the carved mass (a standing slab/wing, not a disc).
	var ovoid_rx: float = maxf(0.12, sculpt_width * 0.5)
	var ovoid_rz: float = maxf(0.10, sculpt_width * 0.42)
	var egg_cy: float = plinth_h + ovoid_ry                 # ovoid centre height
	var wall: float = minf(ovoid_rz * 0.5, ovoid_ry * 0.06 + 0.02)  # stone skin

	# Seeded biomorphic asymmetry.
	var lean_rad: float = deg_to_rad(_rng.randf_range(4.0, 9.0))
	var belly_x: float = _rng.randf_range(0.06, 0.18) * sculpt_width
	var shoulder_x: float = _rng.randf_range(0.02, 0.10) * sculpt_width

	# --- holes: a big strung opening + an optional crown eye -------------
	# complexity drives the hole count (1 or 2) and is clamped to +1 extra.
	var extra_holes: int = clampi(complexity - 4, 0, 1)
	var holes: Array[Dictionary] = []

	# Main opening — large, low-centre in the solid mass, slightly elliptical.
	var main_r_out: float = minf(ovoid_rx, ovoid_ry) * _rng.randf_range(0.46, 0.56)
	var main_y: float = egg_cy - ovoid_ry * _rng.randf_range(0.02, 0.16)
	var main_x: float = _rng.randf_range(-0.04, 0.04) * sculpt_width
	holes.append({
		"r_out": main_r_out,
		"r_in": main_r_out * 0.82,
		"pos": Vector3(main_x, main_y, 0.0),
		"x_scale": _rng.randf_range(1.10, 1.22),   # widen into a soft ellipse
	})

	# Crown eye — smaller, higher, offset to one side (Hepworth often pierced twice).
	if extra_holes >= 1:
		var top_r_out: float = main_r_out * _rng.randf_range(0.38, 0.5)
		var top_y: float = egg_cy + ovoid_ry * _rng.randf_range(0.42, 0.6)
		var top_x: float = _rng.randf_range(-0.5, 0.5) * ovoid_rx * 0.4
		holes.append({
			"r_out": top_r_out,
			"r_in": top_r_out * 0.78,
			"pos": Vector3(top_x, top_y, 0.0),
			"x_scale": 1.0,
		})

	# --- materials -------------------------------------------------------
	var stone_mat: StandardMaterial3D = _make_mat(color_a, clampf(rough_amt, 0.3, 0.95),
		clampf(metallic_amt, 0.0, 0.6))
	stone_mat.cull_mode = BaseMaterial3D.CULL_DISABLED   # show carved inner walls
	var pale_mat: StandardMaterial3D = _make_mat(color_b, 0.78, 0.0)
	pale_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emissive:
		pale_mat.emission_enabled = true
		pale_mat.emission = color_b
		pale_mat.emission_energy_multiplier = 0.12

	# --- STONE shell: outer mass bored at the OUTER radii ----------------
	var stone: CSGCombiner3D = _pie_shell(ovoid_rx, ovoid_ry, ovoid_rz, egg_cy,
		belly_x, shoulder_x, stone_mat, holes, "r_out", "PiercedStone")
	_pie_bake(stone, stone_mat, "PiercedStoneBaked", lean_rad)

	# --- PALE shell: smaller mass bored at the INNER radii (recessed) ----
	# Only its bore throats peek through the holes → the pale painted interior.
	var pale: CSGCombiner3D = _pie_shell(ovoid_rx - wall, ovoid_ry - wall,
		ovoid_rz - wall, egg_cy, belly_x, shoulder_x, pale_mat, holes, "r_in",
		"PiercedPale")
	_pie_bake(pale, pale_mat, "PiercedPaleBaked", lean_rad)

	# --- pale rims flush at each hole mouth (crisp the painted edge) -----
	for h: Dictionary in holes:
		_pie_rim(h, ovoid_rx, ovoid_ry, ovoid_rz, egg_cy, pale_mat, lean_rad)

	# --- string harp across the big opening ------------------------------
	_pie_strings(holes[0], ovoid_rx, ovoid_ry, ovoid_rz, egg_cy, lean_rad)

	# --- plinth ----------------------------------------------------------
	var plinth_mat: StandardMaterial3D = _make_mat(color_b.darkened(0.6), 0.7, 0.1)
	_add_box("PiercedPlinth",
		Vector3(ovoid_rx * 2.0 + 0.12, plinth_h, ovoid_rz * 2.0 + 0.12),
		Vector3(0.0, plinth_h * 0.5, 0.0), Vector3.ZERO, plinth_mat)


# Build one carved shell (CSGCombiner3D): an ovoid + a fused belly swell + a
# small shoulder swell + a grounding foot, minus a bore per hole. `radius_key`
# selects which hole radius ("r_out" or "r_in") to bore — the stone shell bores
# wide, the pale shell bores narrow so its throats recess behind the stone rim.
func _pie_shell(rx: float, ry: float, rz: float, cy: float, belly_x: float,
		shoulder_x: float, mat: StandardMaterial3D, holes: Array[Dictionary],
		radius_key: String, shell_name: String) -> CSGCombiner3D:
	var combiner: CSGCombiner3D = CSGCombiner3D.new()
	combiner.name = shell_name
	combiner.use_collision = false

	# Base solid: a sphere stretched into an upright slab-deep egg.
	var ovoid: CSGSphere3D = CSGSphere3D.new()
	ovoid.name = "Ovoid"
	ovoid.radius = 1.0
	ovoid.radial_segments = 56
	ovoid.rings = 40
	ovoid.smooth_faces = true
	ovoid.material = mat
	ovoid.scale = Vector3(rx, ry, rz)
	ovoid.position = Vector3(0.0, cy, 0.0)
	ovoid.operation = CSGShape3D.OPERATION_UNION
	combiner.add_child(ovoid)

	# Belly swell — a smaller sphere fused low-front-side: biomorphic asymmetry.
	var belly: CSGSphere3D = CSGSphere3D.new()
	belly.name = "Belly"
	belly.radius = 1.0
	belly.radial_segments = 44
	belly.rings = 30
	belly.smooth_faces = true
	belly.material = mat
	belly.scale = Vector3(rx * 0.74, ry * 0.5, rz * 1.02)
	belly.position = Vector3(belly_x, cy - ry * 0.34, rz * 0.06)
	belly.operation = CSGShape3D.OPERATION_UNION
	combiner.add_child(belly)

	# Shoulder swell — a small sphere up & forward so the crown curves like a wing.
	var shoulder: CSGSphere3D = CSGSphere3D.new()
	shoulder.name = "Shoulder"
	shoulder.radius = 1.0
	shoulder.radial_segments = 40
	shoulder.rings = 26
	shoulder.smooth_faces = true
	shoulder.material = mat
	shoulder.scale = Vector3(rx * 0.6, ry * 0.42, rz * 0.78)
	shoulder.position = Vector3(shoulder_x, cy + ry * 0.42, rz * 0.04)
	shoulder.operation = CSGShape3D.OPERATION_UNION
	combiner.add_child(shoulder)

	# Foot — a squat cylinder grounding the mass so it grows from the plinth.
	var foot: CSGCylinder3D = CSGCylinder3D.new()
	foot.name = "Foot"
	foot.radius = maxf(0.06, rx * 0.62)
	foot.height = maxf(0.12, ry * 0.42)
	foot.sides = 32
	foot.smooth_faces = true
	foot.material = mat
	foot.position = Vector3(0.0, (cy - ry) + foot.height * 0.4, 0.0)
	foot.operation = CSGShape3D.OPERATION_UNION
	combiner.add_child(foot)

	# Bores — one subtractive Z-axis cylinder per hole.
	for h: Dictionary in holes:
		var radius: float = float(h[radius_key])
		var x_scale: float = float(h["x_scale"])
		combiner.add_child(_pie_bore(radius, h["pos"] as Vector3, x_scale,
			rz, "Bore"))

	return combiner


# A subtractive bore cylinder oriented front-to-back (+Z): the default Y-axis
# cylinder rotated 90° about X. FLAT-shaded (smooth_faces=false) so the cut wall
# reads as a clean turned bore, not a smeared streak. High sides for a round mouth.
func _pie_bore(radius: float, pos: Vector3, x_scale: float, rz: float,
		bore_name: String) -> CSGCylinder3D:
	var c: CSGCylinder3D = CSGCylinder3D.new()
	c.name = bore_name
	c.radius = radius
	c.height = rz * 4.0 + 1.0          # long enough to pass fully through
	c.sides = 96
	c.smooth_faces = false
	c.operation = CSGShape3D.OPERATION_SUBTRACTION
	c.rotation = Vector3(PI * 0.5, 0.0, 0.0)   # Y-axis → Z-axis bore
	c.scale = Vector3(x_scale, 1.0, 1.0)       # widen into a soft ellipse
	c.position = pos
	return c


# Bake a live CSG shell to a MeshInstance3D and drop the combiner. The combiner
# is added to the tree and leaned now (so even before the bake completes it
# renders, correctly oriented), but the bake itself is DEFERRED one idle frame:
# a CSGShape only builds its brush geometry after it has processed once in-tree,
# so calling bake_static_mesh() synchronously in the same frame yields an empty
# mesh (especially headless). Deferring guarantees real baked geometry. Once the
# bake succeeds the live CSG is hidden and freed, leaving a clean MeshInstance3D.
func _pie_bake(combiner: CSGCombiner3D, mat: StandardMaterial3D,
		mesh_name: String, lean_rad: float) -> void:
	combiner.rotation = Vector3(-lean_rad, 0.0, 0.0)   # lean the wing back from the foot
	add_child(combiner)
	call_deferred("_pie_bake_now", combiner, mat, mesh_name, lean_rad)


# Deferred half of the bake: the CSG has now processed a frame, so its brush is
# built and bake_static_mesh() returns real geometry. Swap it for a baked mesh.
func _pie_bake_now(combiner: CSGCombiner3D, mat: StandardMaterial3D,
		mesh_name: String, lean_rad: float) -> void:
	if combiner == null or not is_instance_valid(combiner):
		return
	var baked: ArrayMesh = combiner.bake_static_mesh()
	if baked == null or baked.get_surface_count() == 0:
		return   # keep the live (leaned) CSG as a fallback — the pierce still shows
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = mesh_name
	mi.mesh = baked
	mi.material_override = mat
	mi.rotation = Vector3(-lean_rad, 0.0, 0.0)
	add_child(mi)
	combiner.queue_free()


# A thin pale TorusMesh ring flush at a hole's front mouth — crisps the painted
# rim and reads pale straight-on without filling the opening (inner radius = the
# pale throat, so it never intrudes).
func _pie_rim(h: Dictionary, _rx: float, ry: float, rz: float, cy: float,
		mat: StandardMaterial3D, lean_rad: float) -> void:
	var pos: Vector3 = h["pos"] as Vector3
	var r_in: float = float(h["r_in"])
	var x_scale: float = float(h["x_scale"])
	var z_front: float = _pie_front_z(pos.y, ry, rz, cy) - 0.008
	var rim: MeshInstance3D = MeshInstance3D.new()
	rim.name = "PiercedRim"
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = r_in
	torus.outer_radius = r_in + maxf(0.012, r_in * 0.12)
	torus.rings = 40
	torus.ring_segments = 12
	rim.mesh = torus
	rim.material_override = mat
	# TorusMesh lies in XZ (axis +Y); rotate to face +Z so it circles the bore.
	rim.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	rim.scale = Vector3(x_scale, 1.0, 1.0)
	rim.position = Vector3(pos.x, pos.y, z_front)
	_pie_lean_child(rim, lean_rad)


# A fanned, faintly drooping cream harp of strings across the big opening:
# compressed at the top and spread at the bottom (like a plucked harp), each
# strand bowing gently forward (a catenary droop). Chord-bounded so the fan
# stays inside the round mouth. Plain MeshInstance3D — never CSG.
func _pie_strings(h: Dictionary, _rx: float, ry: float, rz: float, cy: float,
		lean_rad: float) -> void:
	var holder: Node3D = Node3D.new()
	holder.name = "PiercedStrings"
	add_child(holder)
	_pie_lean_child(holder, lean_rad)

	var smat: StandardMaterial3D = _make_mat(accent, 0.4, 0.0)
	smat.emission_enabled = true
	smat.emission = accent
	smat.emission_energy_multiplier = 0.22 if emissive else 0.10

	var pos: Vector3 = h["pos"] as Vector3
	var r_in: float = float(h["r_in"])
	var x_scale: float = float(h["x_scale"])
	var rx_hole: float = r_in * x_scale          # elliptical half-width of the mouth
	var ry_hole: float = r_in                    # half-height of the mouth
	var inset: float = 0.9                        # keep strands inside the rim
	var z_front: float = _pie_front_z(pos.y, ry, rz, cy) - 0.006
	var droop: float = ry_hole * _rng.randf_range(0.14, 0.26)   # forward bow depth

	# String count from complexity (+ a little seeded variation), clamped sane.
	var n: int = clampi(complexity + (seed % 3), 7, 15)

	var i: int = 0
	while i < n:
		var t: float = 0.0
		if n > 1:
			t = float(i) / float(n - 1)            # 0..1 across the opening
		# Fan: x compressed at the top, spread at the bottom.
		var x_top: float = lerpf(-rx_hole * 0.32, rx_hole * 0.32, t) * inset
		var x_bot: float = lerpf(-rx_hole, rx_hole, t) * inset
		# Vertical extent = chord of the ellipse at the bottom x (taut to the rim).
		var ex: float = clampf(x_bot / (rx_hole * inset), -1.0, 1.0)
		var chord: float = sqrt(maxf(0.0, 1.0 - ex * ex))
		var v_half: float = ry_hole * inset * chord
		var top_p: Vector3 = Vector3(x_top, pos.y + v_half, z_front)
		var bot_p: Vector3 = Vector3(x_bot, pos.y - v_half, z_front)
		# Mid control point bowed forward (+Z) for the catenary droop.
		var mid_p: Vector3 = (top_p + bot_p) * 0.5 + Vector3(0.0, 0.0, droop)
		_pie_strand(holder, top_p, mid_p, bot_p, smat)
		i += 1


# One drooping strand: two short cylinder segments through a forward mid point,
# so the strand bows gently rather than drawing a dead-straight line.
func _pie_strand(parent: Node3D, a: Vector3, mid: Vector3, b: Vector3,
		mat: StandardMaterial3D) -> void:
	_pie_segment(parent, a, mid, mat)
	_pie_segment(parent, mid, b, mat)


# A single thin cylinder spanning two points (oriented like a string between them).
func _pie_segment(parent: Node3D, p0: Vector3, p1: Vector3,
		mat: StandardMaterial3D) -> void:
	var diff: Vector3 = p1 - p0
	var length: float = maxf(diff.length(), 0.001)
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = 0.0045
	cyl.bottom_radius = 0.0045
	cyl.height = length
	cyl.radial_segments = 6
	cyl.rings = 1
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = "PiercedString"
	mi.mesh = cyl
	mi.material_override = mat
	# Orient the +Y cylinder along the segment direction.
	var dir: Vector3 = diff.normalized()
	var up: Vector3 = Vector3.UP
	if absf(dir.dot(up)) > 0.999:
		mi.position = (p0 + p1) * 0.5
	else:
		var axis: Vector3 = up.cross(dir).normalized()
		var angle: float = acos(clampf(up.dot(dir), -1.0, 1.0))
		mi.basis = Basis(axis, angle)
		mi.position = (p0 + p1) * 0.5
	parent.add_child(mi)


# Front-face Z of the ovoid at a given world height y (so rims/strings seat on
# the opening rather than float). Derived from the ellipsoid equation.
func _pie_front_z(y: float, ry: float, rz: float, cy: float) -> float:
	var dy: float = (y - cy) / maxf(ry, 0.001)
	var k: float = 1.0 - dy * dy
	if k <= 0.0:
		return rz * 0.3
	return rz * sqrt(k)


# Lean a child about the bottom-centre origin (same axis as the baked shells) so
# it tracks the carved mass. The child's own position is already in mass space.
func _pie_lean_child(node: Node3D, lean_rad: float) -> void:
	var b: Basis = Basis(Vector3.RIGHT, -lean_rad)
	var xf: Transform3D = node.transform
	node.transform = Transform3D(b * xf.basis, b * xf.origin)


# ── Mode: LIPSTICK (Claes Oldenburg & Coosje van Bruggen — "Lipstick
# (Ascending) on Caterpillar Tracks", Yale 1969) ───────────────────────
# Monumental pop: a glossy RED waxy bullet ascends on a smooth slant-cut
# OGIVE out of a banded GOLD tube, the whole glamour perched on a brutal
# pair of military STADIUM-LOOP caterpillar treads (links + grouser cleats
# + a continuous belt band + road wheels + end sprockets + steel hubs) on
# a riveted DECK trimmed flush to the treads (a chassis, not a raft).
#
# A synthesis of four trials:
#   - tread chassis + sprockets/hubs   ← v2
#   - arc-length _lip_stadium_point()  ← v4 (links rotate to follow the loop)
#   - slim elegant bullet proportions  ← v3 (radius under the tube rim)
#   - 24-frustum ogive r=R√(1-t²)      ← v4 (smooth point, no stair-stepping)
# Improvements all four wanted, added here: a slanted/asymmetric "used
# lipstick" cut on the ogive tip, and a thin continuous belt band over the
# links so the tread reads as a band, not discrete boxes.
#
# Three+ contradictory materials: GOLD tube (metallic, emission floor so it
# reads gold not black in the unlit capture), glossy RED wax bullet, matte
# dark-OLIVE tracks, and STEEL wheels/hubs. Origin bottom-centre, faces +Z;
# the apex of the bullet reaches ~sculpt_height. Base built BEFORE the
# lipstick so the capture AABB locks on first.
#
# DNA → visual:
#   color_a → red wax bullet · color_b → gold tube · accent → olive track
#   complexity → link count + road-wheel count + decorative band detail
#   metallic_amt / rough_amt → tube + steel finishes
#   emissive → gold sheen + faint wax inner glow
#   seed → deterministic slant angle, band count, tread link count

func _build_lipstick() -> void:
	_rng.seed = seed

	# --- materials (≥3 contradictory registers) --------------------------
	# GOLD tube: bare metal renders near-black under the unlit headless
	# capture, so floor the emission with the gold's own tint + a warm rim.
	var gold: StandardMaterial3D = _make_mat(color_b, clampf(rough_amt * 0.42, 0.22, 0.40),
		clampf(maxf(metallic_amt, 0.78), 0.0, 1.0))
	gold.metallic_specular = 0.7
	gold.emission_enabled = true
	gold.emission = color_b
	gold.emission_energy_multiplier = 0.30 if emissive else 0.26
	gold.rim_enabled = true
	gold.rim = 0.55
	gold.rim_tint = 0.7

	# Darker brass for bands / rim / collar so the bullet-emergence reads.
	var gold_dark: StandardMaterial3D = _make_mat(color_b.darkened(0.32),
		clampf(rough_amt * 0.55, 0.30, 0.5), 0.8)
	gold_dark.emission_enabled = true
	gold_dark.emission = color_b.darkened(0.32)
	gold_dark.emission_energy_multiplier = 0.22

	# Glossy RED wax bullet — the hero; a faint warm glow so it stays vivid.
	var wax: StandardMaterial3D = _make_mat(color_a, 0.20, 0.0)
	wax.metallic_specular = 0.85
	wax.emission_enabled = true
	wax.emission = color_a * 0.45
	wax.emission_energy_multiplier = 0.18 if emissive else 0.12

	# Matte dark-OLIVE tracks — small emission floor so they don't crush.
	var olive: StandardMaterial3D = _make_mat(accent, clampf(maxf(rough_amt, 0.85), 0.6, 1.0), 0.1)
	olive.emission_enabled = true
	olive.emission = accent.darkened(0.55)
	olive.emission_energy_multiplier = 0.10
	var olive_light: StandardMaterial3D = _make_mat(accent.lightened(0.12),
		clampf(maxf(rough_amt, 0.80), 0.6, 1.0), 0.1)

	# STEEL wheels / hubs / rivets — a touch shinier, faint floor.
	var steel: StandardMaterial3D = _make_mat(Color(0.31, 0.33, 0.34), 0.55, 0.55)
	steel.emission_enabled = true
	steel.emission = Color(0.10, 0.10, 0.11)
	steel.emission_energy_multiplier = 0.16

	# --- proportions from DNA --------------------------------------------
	var total_h: float = maxf(0.6, sculpt_height)
	var span: float = maxf(0.4, sculpt_width)

	# Caterpillar pedestal sizing (slim, so the wax dominates the rise).
	var wheel_r: float = span * 0.165                       # end road-wheel radius
	var track_len: float = span * 1.15                      # tread length along Z
	var track_w: float = span * 0.24                        # width of one tread (X)
	var gauge: float = span * 0.82                          # centre-to-centre spacing
	var deck_thick: float = maxf(0.05, span * 0.085)
	# complexity drives link / wheel / band density.
	var cx: int = maxi(2, complexity)
	var link_count: int = clampi(24 + cx * 2 + (seed % 5), 22, 48)
	var road_wheels: int = clampi(3 + cx / 3, 3, 6)

	# --- BASE FIRST: two treads + deck (AABB locks on the chassis) --------
	var axle_y: float = wheel_r
	var straight_half: float = maxf(0.02, (track_len * 0.5) - wheel_r)
	for sx: float in [-gauge * 0.5, gauge * 0.5]:
		_lip_tread(sx, axle_y, straight_half, track_w, wheel_r, link_count,
			road_wheels, olive, olive_light, steel)

	# DECK: flush to the treads' OUTER edge (a chassis, not an overhanging
	# raft) so both treads stay visible from above and the sides.
	var deck_cy: float = axle_y + wheel_r + deck_thick * 0.5 + 0.012
	var deck_x: float = gauge + track_w - 0.02
	var deck_z: float = track_len - 0.06
	_add_box("LipDeck", Vector3(deck_x, deck_thick, deck_z),
		Vector3(0.0, deck_cy, 0.0), Vector3.ZERO, olive)
	# Inset steel sub-plate for material contrast on top.
	_add_box("LipDeckPlate", Vector3(deck_x - 0.10, deck_thick * 0.5, deck_z - 0.10),
		Vector3(0.0, deck_cy + deck_thick * 0.5, 0.0), Vector3.ZERO, steel)

	# Perimeter rivets around the deck edge (brutal-machine read).
	var deck_top: float = deck_cy + deck_thick * 0.5
	var hx: float = deck_x * 0.5 - 0.05
	var hz: float = deck_z * 0.5 - 0.05
	var nz: int = 7
	for i in range(nz):
		var tz: float = float(i) / float(nz - 1)
		var rz: float = lerpf(-hz, hz, tz)
		_add_sphere("LipRivetL%d" % i, 0.018, Vector3(-hx, deck_top, rz), steel)
		_add_sphere("LipRivetR%d" % i, 0.018, Vector3(hx, deck_top, rz), steel)
	var nxr: int = 5
	for i in range(nxr):
		var txr: float = float(i) / float(nxr - 1)
		var rxv: float = lerpf(-hx, hx, txr)
		_add_sphere("LipRivetF%d" % i, 0.018, Vector3(rxv, deck_top, -hz), steel)
		_add_sphere("LipRivetB%d" % i, 0.018, Vector3(rxv, deck_top, hz), steel)

	# --- THE LIPSTICK on top of the deck ---------------------------------
	# Mounting collar where the tube meets the deck.
	var tube_r: float = span * 0.180
	_add_cyl("LipMountCollar", tube_r + 0.05, tube_r + 0.05, 0.07,
		Vector3(0.0, deck_top + 0.035, 0.0), Vector3.ZERO, steel)
	var base_y: float = deck_top + 0.07

	# Tube takes ~40% of the remaining rise; the wax bullet dominates.
	var avail: float = maxf(0.2, total_h - base_y)
	var tube_h: float = avail * 0.30
	var tube_top: float = _lip_tube(base_y, tube_h, tube_r, gold, gold_dark)

	# Slim red wax bullet rising the rest of the way to ~total_h.
	var bullet_r: float = tube_r * 0.82                    # under the rim → it emerges
	var bullet_h: float = maxf(0.2, total_h - tube_top)
	_lip_bullet(tube_top, bullet_h, bullet_r, wax)


# One caterpillar tread: a stadium-loop belt of links (arc-length placed so
# they rotate to follow the loop) with grouser cleats, a thin CONTINUOUS
# belt band so the tread reads as a band, road wheels + larger end sprockets
# inside, and steel hub caps. Centred at world X = `sx`.
func _lip_tread(sx: float, axle_y: float, straight_half: float, track_w: float,
		wheel_r: float, link_count: int, road_wheels: int,
		olive: StandardMaterial3D, olive_light: StandardMaterial3D,
		steel: StandardMaterial3D) -> void:
	# Stable per-side suffix so repeated parts get unique deterministic names.
	var sd: String = "R" if sx >= 0.0 else "L"
	var link_thick: float = 0.085
	var link_depth: float = maxf(0.06, (PI * wheel_r + 2.0 * straight_half) / float(link_count) * 0.92)

	# --- track links wrapped around the stadium perimeter (v4 arc-length) ---
	for i in range(link_count):
		var phase: float = float(i) / float(link_count)
		var pt: Dictionary = _lip_stadium_point(phase, axle_y, straight_half, wheel_r)
		var pos: Vector3 = pt["pos"]
		var tang: Vector3 = pt["tan"]
		var ang: float = atan2(tang.y, tang.z)
		var lp: Vector3 = Vector3(sx, pos.y, pos.z)
		_add_box("LipLink%s%d" % [sd, i], Vector3(track_w, link_thick, link_depth),
			lp, Vector3(ang, 0.0, 0.0), olive)
		# Grouser cleat on the outer face of every other link.
		if i % 2 == 0:
			var radial: Vector3 = pos - Vector3(0.0, axle_y, 0.0)
			if radial.length() > 0.001:
				radial = radial.normalized()
			else:
				radial = Vector3(0.0, 1.0, 0.0)
			var cpos: Vector3 = lp + radial * (link_thick * 0.5 + 0.022)
			_add_box("LipCleat%s%d" % [sd, i], Vector3(track_w * 0.72, 0.04, link_depth * 0.42),
				cpos, Vector3(ang, 0.0, 0.0), olive_light)

	# --- thin CONTINUOUS belt band over the links (IMPROVEMENT) ----------
	# Two long flat boxes (top + bottom runs) + two slim end discs, sitting
	# just under the link layer so the silhouette reads as one rubber band.
	var band_r: float = wheel_r - link_thick * 0.5
	var band_w: float = track_w * 1.02
	var band_t: float = 0.022
	_add_box("LipBeltTop%s" % sd, Vector3(band_w, band_t, straight_half * 2.0),
		Vector3(sx, axle_y + band_r, 0.0), Vector3.ZERO, olive)
	_add_box("LipBeltBot%s" % sd, Vector3(band_w, band_t, straight_half * 2.0),
		Vector3(sx, axle_y - band_r, 0.0), Vector3.ZERO, olive)
	var ei: int = 0
	for ez: float in [straight_half, -straight_half]:
		_add_cyl("LipBeltEnd%s%d" % [sd, ei], band_r + band_t * 0.5, band_r + band_t * 0.5,
			band_w, Vector3(sx, axle_y, ez), Vector3(0.0, 0.0, PI * 0.5), olive)
		ei += 1

	# --- larger end sprockets at each end + steel hub caps ----------------
	var si: int = 0
	for ez: float in [straight_half, -straight_half]:
		_add_cyl("LipSprocket%s%d" % [sd, si], wheel_r * 0.92, wheel_r * 0.92, track_w + 0.02,
			Vector3(sx, axle_y, ez), Vector3(0.0, 0.0, PI * 0.5), steel)
		_add_cyl("LipSprocketRim%s%d" % [sd, si], wheel_r * 0.55, wheel_r * 0.55, track_w + 0.05,
			Vector3(sx, axle_y, ez), Vector3(0.0, 0.0, PI * 0.5), olive)
		_add_cyl("LipEndHub%s%d" % [sd, si], wheel_r * 0.30, wheel_r * 0.30, track_w + 0.07,
			Vector3(sx, axle_y, ez), Vector3(0.0, 0.0, PI * 0.5), steel)
		si += 1

	# --- interior road wheels along the bottom run (axis along X) ---------
	var rw_r: float = wheel_r * 0.74
	for j in range(road_wheels):
		var t: float = (float(j) + 0.5) / float(road_wheels)
		var wz: float = lerpf(-straight_half, straight_half, t)
		_add_cyl("LipRoadWheel%s%d" % [sd, j], rw_r, rw_r, track_w * 0.72,
			Vector3(sx, axle_y, wz), Vector3(0.0, 0.0, PI * 0.5), steel)
		_add_cyl("LipRoadHub%s%d" % [sd, j], rw_r * 0.30, rw_r * 0.30, track_w * 0.80,
			Vector3(sx, axle_y, wz), Vector3(0.0, 0.0, PI * 0.5), olive)


# Point + tangent on the stadium loop for a phase 0..1 (v4 arc-length param):
# top run → rear semicircle → bottom run → front semicircle, in the (z, y)
# plane with the axle at y=axle_y. Returns {"pos": Vector3, "tan": Vector3}.
func _lip_stadium_point(phase: float, axle_y: float, straight_half: float,
		wheel_r: float) -> Dictionary:
	var r: float = wheel_r
	var top_y: float = axle_y + r
	var bot_y: float = axle_y - r
	var run_len: float = 2.0 * straight_half
	var arc_len: float = PI * r
	var total: float = 2.0 * run_len + 2.0 * arc_len
	var d: float = phase * total

	var pos: Vector3
	var tan: Vector3
	if d < run_len:
		# TOP run: +z → -z at y=top_y.
		var u: float = d / run_len
		pos = Vector3(0.0, top_y, lerpf(straight_half, -straight_half, u))
		tan = Vector3(0.0, 0.0, -1.0)
	elif d < run_len + arc_len:
		# REAR semicircle at z=-straight_half, top → bottom.
		var a: float = ((d - run_len) / arc_len) * PI
		pos = Vector3(0.0, axle_y + r * cos(a), -straight_half - r * sin(a))
		tan = Vector3(0.0, -sin(a), -cos(a)).normalized()
	elif d < 2.0 * run_len + arc_len:
		# BOTTOM run: -z → +z at y=bot_y.
		var u: float = (d - run_len - arc_len) / run_len
		pos = Vector3(0.0, bot_y, lerpf(-straight_half, straight_half, u))
		tan = Vector3(0.0, 0.0, 1.0)
	else:
		# FRONT semicircle at z=+straight_half, bottom → top.
		var a: float = ((d - 2.0 * run_len - arc_len) / arc_len) * PI
		pos = Vector3(0.0, axle_y - r * cos(a), straight_half + r * sin(a))
		tan = Vector3(0.0, sin(a), cos(a)).normalized()
	return {"pos": pos, "tan": tan}


# The gold tube: a base flare, a slightly tapered case body, a couple of
# darker decorative bands, and a wider rim/collar at the top where the
# bullet emerges. Returns the world Y of the rim top (the bullet's base).
func _lip_tube(base_y: float, tube_h: float, tube_r: float,
		gold: StandardMaterial3D, gold_dark: StandardMaterial3D) -> float:
	# Base flare where the case meets the collar (wider at the bottom).
	var flare_h: float = maxf(0.04, tube_h * 0.10)
	_add_cyl("LipTubeFlare", tube_r, tube_r + 0.05, flare_h,
		Vector3(0.0, base_y + flare_h * 0.5, 0.0), Vector3.ZERO, gold_dark)

	# Main case body, very slight inward taper toward the rim.
	var body_bottom: float = base_y + flare_h
	var rim_h: float = maxf(0.035, tube_h * 0.07)
	var body_h: float = maxf(0.05, tube_h - flare_h - rim_h)
	var body_top: float = body_bottom + body_h
	_add_cyl("LipTubeBody", tube_r * 0.97, tube_r, body_h,
		Vector3(0.0, body_bottom + body_h * 0.5, 0.0), Vector3.ZERO, gold)

	# Decorative bands (swivel-case seam lines): count varies with seed.
	var bands: int = 2 + (seed % 2)
	for bi in range(bands):
		var bf: float = lerpf(0.26, 0.74, float(bi) / float(maxi(1, bands - 1)))
		var by: float = lerpf(body_bottom, body_top, bf)
		_add_cyl("LipBand%d" % bi, tube_r * 1.012, tube_r * 1.012, 0.03,
			Vector3(0.0, by, 0.0), Vector3.ZERO, gold_dark)

	# Rim / mounting lip at the very top where the bullet emerges.
	var rim_cy: float = body_top + rim_h * 0.5
	_add_cyl("LipTubeRim", tube_r * 1.03, tube_r * 1.05, rim_h,
		Vector3(0.0, rim_cy, 0.0), Vector3.ZERO, gold_dark)
	return body_top + rim_h


# The red wax bullet (the hero): a glossy cylindrical shaft that has emerged
# from the tube, topped by a SMOOTH ogive point built as a stack of ~24
# tapered cone frusta following r = R·√(1−t²) (v4 — no stair-stepping, no
# blunt sphere cap), at slim proportions (v3). IMPROVEMENT: the ogive is
# progressively SHEARED toward +X so the apex is cut off-axis — the real
# "used-lipstick" slant. Bullet base tucks just below `tube_top` so it
# appears to rise out of the rim.
func _lip_bullet(tube_top: float, bullet_h: float, bullet_r: float,
		wax: StandardMaterial3D) -> void:
	var base_y: float = tube_top - 0.02                    # tuck under the rim
	# Slim neck just above the rim (bullet slightly narrower than the bore).
	_add_cyl("LipBulletNeck", bullet_r, bullet_r * 0.985, 0.05,
		Vector3(0.0, base_y + 0.025, 0.0), Vector3.ZERO, wax)

	# Straight glossy red shaft for ~58% of the bullet height.
	var ogive_h: float = bullet_h * 0.34
	var shaft_h: float = maxf(0.05, bullet_h - ogive_h)
	var shaft_top: float = base_y + shaft_h
	_add_cyl("LipBulletShaft", bullet_r, bullet_r, shaft_h,
		Vector3(0.0, base_y + shaft_h * 0.5, 0.0), Vector3.ZERO, wax)

	# Slant amount: a few degrees of off-axis shear over the ogive (seeded).
	var slant: float = deg_to_rad(_rng.randf_range(8.0, 16.0))
	var shear: float = tan(slant)                          # total X drift / ogive_h

	# Ogive: stacked tapered frusta, radii meeting exactly so the silhouette
	# is a smooth pointed dome. Each frustum is offset in X by the running
	# shear so the whole point leans, cutting the apex off-axis.
	var rings: int = 24
	for i in range(rings):
		var t0: float = float(i) / float(rings)
		var t1: float = float(i + 1) / float(rings)
		var rf0: float = sqrt(maxf(0.0, 1.0 - t0 * t0))
		var rf1: float = sqrt(maxf(0.0, 1.0 - t1 * t1))
		var r0: float = maxf(bullet_r * rf0, 0.002)        # bottom radius of frustum
		var r1: float = maxf(bullet_r * rf1, 0.002)        # top radius of frustum
		var seg_h: float = ogive_h / float(rings)
		var y_mid: float = shaft_top + (float(i) + 0.5) * seg_h
		var x_off: float = shear * (float(i) + 0.5) * seg_h
		# slight vertical overlap kills any seam line between frusta
		_add_cyl("LipOgive%d" % i, r1, r0, seg_h * 1.06,
			Vector3(x_off, y_mid, 0.0), Vector3(0.0, 0.0, 0.0), wax)


# ── Mode: FLAVIN (Dan Flavin — fluorescent-tube light composition) ─────
# A "monument to Tatlin" stepped symmetric SKYLINE of unshaded glowing
# vertical tubes (centre tallest, descending outward) standing in a DIMMED
# matte CORNER (back wall at -Z + side wall at -X + a floor strip). Each
# tube is a thin emissive cylinder rendered UNSHADED so it reads as a solid
# bright bar immune to the capture rig's tonemap, wrapped in a fatter
# additive HALO sleeve to fake phosphor bloom, capped with dark metal end
# fixtures, and lit by ONE tight SATURATED OmniLight pushed toward the wall
# so its colour washes the corner WITHOUT summing with its neighbours into
# white. At higher complexity (and on roughly half of seeds) the skyline is
# enriched with a single diagonal, a low horizontal floor bar, and coloured
# side jambs. The coloured wash on the corner IS the work — not the tubes.
# DNA: color_a/color_b/accent → saturated tube hues (mixed with fixed
# whites); complexity → tube count + composition richness; sculpt_width /
# sculpt_height → corner + skyline size; seed → composition variant + hue
# assignment; emissive → boosts emission energy + halo.

const _FL_TUBE_R: float = 0.042
const _FL_CAP_R: float = 0.055
const _FL_CAP_H: float = 0.066
# Fixed Flavin whites — always present so the saturated DNA hues read against
# a cool/warm neutral spine (Flavin mixed colour temperatures deliberately).
const _FL_COOL_WHITE: Color = Color(0.62, 0.80, 1.00)
const _FL_WARM_WHITE: Color = Color(1.00, 0.86, 0.58)


func _build_flavin() -> void:
	_rng.seed = seed

	# -- size envelope from DNA ------------------------------------------
	var half_w: float = clampf(sculpt_width, 0.6, 3.0) * 0.5
	var peak_h: float = clampf(sculpt_height, 1.0, 3.2)
	# Tube columns: complexity drives how many flank the centre spine.
	var pairs: int = clampi(int(round(float(complexity) * 0.5)), 2, 5)
	var col_count: int = pairs * 2 + 1                 # always odd → a centre spine
	# Spacing fills the corner width but never lets columns collide.
	var spacing: float = clampf((half_w * 2.0) / float(col_count + 1), 0.14, 0.26)

	var back_z: float = -0.40
	var side_x: float = -(half_w + 0.10)
	var wall_h: float = peak_h + 0.30

	# -- saturated tube palette: DNA hues pushed to fluorescent vividness --
	# color_a/color_b/accent become the chromatic tubes; the two whites are
	# fixed. Saturating keeps each light separable on the wall.
	var sat_a: Color = _fl_saturate(color_a)
	var sat_b: Color = _fl_saturate(color_b)
	var sat_c: Color = _fl_saturate(accent)
	var chroma: Array[Color] = [sat_a, sat_b, sat_c]

	# -- composition variant (deterministic per seed) --------------------
	# Half the seeds are a pure skyline; the rest gain diagonal + floor bar +
	# jambs. Higher complexity forces the richer variant so dense pieces feel
	# fuller. Keep negative space so the lights don't pile into one hotspot.
	var rich: bool = (_rng.randf() < 0.5) or complexity >= 7

	_fl_build_corner(half_w, wall_h, back_z, side_x)
	_fl_build_skyline(col_count, spacing, peak_h, back_z, chroma)

	if rich:
		_fl_build_enrichment(half_w, peak_h, back_z, chroma)


# Backing corner — two dimmed matte walls + a floor strip. Kept GREY (~0.34-
# 0.42), never pale: under the capture rig a near-white wall blows out and the
# coloured wash dies. The wash on this corner is the signature.
func _fl_build_corner(half_w: float, wall_h: float, back_z: float,
		side_x: float) -> void:
	var wall_mat: StandardMaterial3D = StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.35, 0.36, 0.39)
	wall_mat.roughness = 1.0
	wall_mat.metallic = 0.0
	wall_mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED

	var span: float = half_w * 2.0 + 0.4
	var depth: float = half_w + 0.9

	# Back wall (-Z), facing +Z toward the viewer/tubes.
	_add_box("FlavinBackWall", Vector3(span, wall_h, 0.08),
		Vector3(0.0, wall_h * 0.5, back_z - 0.04), Vector3.ZERO, wall_mat)

	# Side wall (-X), facing +X — forms the corner so the wash reads across
	# two planes the way a Flavin corner piece does.
	_add_box("FlavinSideWall", Vector3(0.08, wall_h, depth),
		Vector3(side_x - 0.04, wall_h * 0.5, back_z + depth * 0.5 - 0.04),
		Vector3.ZERO, wall_mat)

	# Floor strip — catches the downward coloured pools. Slightly lighter so
	# the colours glow on it, but still dim.
	var floor_mat: StandardMaterial3D = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.41, 0.41, 0.44)
	floor_mat.roughness = 1.0
	floor_mat.metallic = 0.0
	floor_mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	_add_box("FlavinFloorStrip", Vector3(span, 0.04, depth),
		Vector3(0.0, 0.02, back_z + depth * 0.5 - 0.04), Vector3.ZERO, floor_mat)


# The "monument to Tatlin": a symmetric stepped skyline of vertical tubes,
# centre tallest, descending in steps outward. The centre spine + the inner
# step are fixed whites (cool/warm); the chromatic DNA hues take the outer
# steps so the colour lives at the silhouette's edges where it can wash freely.
func _fl_build_skyline(col_count: int, spacing: float, peak_h: float,
		back_z: float, chroma: Array[Color]) -> void:
	var centre: int = col_count / 2
	# Tubes stand WELL forward of the back wall so they read as solid lit bars
	# in front of it while their lights throw colour back onto the wall.
	var tube_z: float = back_z + 0.60
	var origin_x: float = -float(col_count - 1) * 0.5 * spacing
	# Per-step height falloff (ziggurat). Outer columns are ~55% of the peak.
	for i in range(col_count):
		var dist: int = absi(i - centre)
		var fall: float = 1.0 - float(dist) / float(maxi(1, centre)) * 0.45
		var h: float = clampf(peak_h * fall, 0.5, peak_h)
		var x: float = origin_x + float(i) * spacing
		var col: Color = _fl_skyline_colour(dist, chroma)
		_fl_tube(Vector3(x, 0.0, tube_z), Vector3(x, h, tube_z), col)


# Enrichment elements (v2 lineage): a single diagonal, a low horizontal floor
# bar, and two coloured side jambs tucked into the corner. Adds richness +
# carries the chromatic wash to the side wall and floor.
func _fl_build_enrichment(half_w: float, peak_h: float, back_z: float,
		chroma: Array[Color]) -> void:
	var tube_z: float = back_z + 0.52
	var c0: Color = chroma[_rng.randi_range(0, chroma.size() - 1)]
	var c1: Color = chroma[_rng.randi_range(0, chroma.size() - 1)]
	var c2: Color = chroma[_rng.randi_range(0, chroma.size() - 1)]

	# Single diagonal — the classic Flavin gesture — crossing the lower skyline.
	var dx: float = half_w * 0.7
	var dy0: float = peak_h * 0.12
	var dy1: float = peak_h * 0.62
	_fl_tube(Vector3(-dx, dy0, tube_z + 0.04), Vector3(dx, dy1, tube_z + 0.04), c0)

	# Low horizontal floor bar grounding the base (a Flavin "barrier").
	var bar_half: float = half_w * 0.78
	var bar_y: float = peak_h * 0.07 + _FL_CAP_H
	_fl_tube(Vector3(-bar_half, bar_y, tube_z + 0.10),
		Vector3(bar_half, bar_y, tube_z + 0.10), c1)

	# Coloured side jamb hard against the side wall — floods the -X plane.
	var jamb_x: float = -(half_w + 0.02)
	_fl_tube(Vector3(jamb_x, 0.0, tube_z - 0.04),
		Vector3(jamb_x, peak_h * 0.92, tube_z - 0.04), c2)


# Saturate a DNA colour toward fluorescent vividness while keeping its hue, so
# tube lights stay separable on the wall (desaturated lights sum to grey-white).
func _fl_saturate(c: Color) -> Color:
	var h: float = c.h
	var s: float = maxf(c.s, 0.78)
	var v: float = clampf(maxf(c.v, 0.85), 0.0, 1.0)
	return Color.from_hsv(h, s, v)


# Pick a tube colour for skyline column at step `dist` from centre. Centre +
# inner step = fixed whites (the Tatlin spine); outer steps cycle the chromatic
# DNA hues so colour lives at the edges of the silhouette.
func _fl_skyline_colour(dist: int, chroma: Array[Color]) -> Color:
	if dist == 0:
		return _FL_COOL_WHITE
	if dist == 1:
		return _FL_WARM_WHITE
	return chroma[(dist - 2) % chroma.size()]


# One Flavin tube between a and b: an UNSHADED emissive cylinder (reads as a
# solid bright bar past the tonemap) + a fatter additive HALO sleeve (fake
# phosphor bloom) + dark-metal end caps + ONE tight saturated OmniLight pushed
# toward the corner (two for long tubes) so the colour washes the wall.
func _fl_tube(a: Vector3, b: Vector3, col: Color) -> void:
	var axis: Vector3 = b - a
	var length: float = axis.length()
	if length < 0.001:
		return
	var dir: Vector3 = axis / length
	var mid: Vector3 = (a + b) * 0.5
	var basis: Basis = _fl_basis_from_axis(dir)

	# Glowing tube body — UNSHADED so its colour ignores the rig's fill light.
	var energy: float = 6.5 if emissive else 5.0
	var tube: MeshInstance3D = MeshInstance3D.new()
	tube.name = "FlavinTube"
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = _FL_TUBE_R
	cyl.bottom_radius = _FL_TUBE_R
	cyl.height = maxf(length - _FL_CAP_H, 0.05)
	cyl.radial_segments = 14
	tube.mesh = cyl
	tube.material_override = _fl_tube_mat(col, energy)
	tube.transform = Transform3D(basis, mid)
	add_child(tube)

	# Additive halo sleeve — fatter, low-alpha, unshaded; fakes the bloom a
	# real fluorescent throws (no WorldEnvironment glow is available here).
	var halo: MeshInstance3D = MeshInstance3D.new()
	halo.name = "FlavinHalo"
	var hcyl: CylinderMesh = CylinderMesh.new()
	hcyl.top_radius = _FL_TUBE_R * 2.1
	hcyl.bottom_radius = _FL_TUBE_R * 2.1
	hcyl.height = maxf(length * 1.02, 0.05)
	hcyl.radial_segments = 12
	halo.mesh = hcyl
	var hmat: StandardMaterial3D = StandardMaterial3D.new()
	hmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	hmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	hmat.albedo_color = Color(col.r, col.g, col.b, 0.08 if emissive else 0.07)
	hmat.emission_enabled = true
	hmat.emission = col
	hmat.emission_energy_multiplier = 1.1 if emissive else 0.9
	halo.material_override = hmat
	halo.transform = Transform3D(basis, mid)
	add_child(halo)

	# Dark-metal end-cap fixtures at both ends.
	var cap_mat: StandardMaterial3D = _make_mat(Color(0.10, 0.10, 0.11), 0.4, 0.85)
	for s: float in [-1.0, 1.0]:
		var cap_pos: Vector3 = mid + dir * (s * (length * 0.5 - _FL_CAP_H * 0.5))
		var cap: MeshInstance3D = MeshInstance3D.new()
		cap.name = "FlavinCap"
		var ccyl: CylinderMesh = CylinderMesh.new()
		ccyl.top_radius = _FL_CAP_R
		ccyl.bottom_radius = _FL_CAP_R
		ccyl.height = _FL_CAP_H
		ccyl.radial_segments = 12
		cap.mesh = ccyl
		cap.material_override = cap_mat
		cap.transform = Transform3D(basis, cap_pos)
		add_child(cap)

	# ONE tight saturated OmniLight per tube (two for long tubes), pushed BACK
	# toward the corner so each makes a localized colour pool that stays
	# SEPARATED from its neighbours instead of summing to white.
	var to_wall: Vector3 = Vector3(-0.10, 0.0, -0.24)   # bias toward -X / -Z corner
	var n_lights: int = 2 if length > 1.6 else 1
	for li in range(n_lights):
		var t: float = 0.5
		if n_lights > 1:
			t = lerpf(0.32, 0.68, float(li) / float(n_lights - 1))
		_fl_light(a.lerp(b, t) + to_wall, col, length)


# A tight, saturated OmniLight that washes the corner with the tube's colour.
func _fl_light(pos: Vector3, col: Color, length: float) -> void:
	var light: OmniLight3D = OmniLight3D.new()
	light.name = "FlavinLight"
	light.position = pos
	light.light_color = col
	# Energy scales with tube length; emissive DNA pushes it a touch hotter.
	var base_e: float = lerpf(1.5, 2.1, clampf(length / 2.2, 0.0, 1.0))
	light.light_energy = base_e * (1.0 if emissive else 0.85)
	light.omni_range = 1.6              # short — a localized pool, not a flood
	light.omni_attenuation = 2.6       # falls off fast so colours stay separated
	light.shadow_enabled = false       # soft even wash, no hard tube shadows
	add_child(light)


# UNSHADED emissive material for a tube: the body renders as its own bright
# colour past the rig's tonemap (a shaded emissive would wash out). Albedo is
# the hue with only a touch of white so the bar holds its colour at high energy.
func _fl_tube_mat(col: Color, energy: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = col.lerp(Color.WHITE, 0.18)
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = energy
	m.roughness = 0.25
	m.metallic = 0.0
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


# A rotation basis whose local +Y axis aligns with `dir` (CylinderMesh is
# Y-up). Deterministic; handles the degenerate parallel case.
func _fl_basis_from_axis(dir: Vector3) -> Basis:
	var y: Vector3 = dir.normalized()
	var reference: Vector3 = Vector3.FORWARD
	if absf(y.dot(reference)) > 0.99:
		reference = Vector3.RIGHT
	var x: Vector3 = reference.cross(y).normalized()
	var z: Vector3 = x.cross(y).normalized()
	return Basis(x, y, z)


# ── Mode: SPIRALJETTY (Robert Smithson — "Spiral Jetty", 1970) ─────────
# Land-art earthwork read FROM ABOVE: a counterclockwise Archimedean coil
# (r = r_inner + b·θ, ~3 turns) built as a low BERM/causeway of ANGULAR
# black-basalt rocks + brown earth, raised just over a wide rose-RED Great
# Salt Lake, salt-crusted at the waterline, with a built-up mud skirt and a
# brown shore patch at the outer mouth. Flat + wide so the capture frames it.
#
# A synthesis of four trials:
#   - OPEN Archimedean spiral, salt rims, shore patch  ← v2 (clearest coil)
#   - ANGULAR basalt rocks (tumbled boxes, 2 tones)    ← v3 (not uniform spheres)
#   - full-red water that holds its red at grazing      ← v4 + v3's desaturation
#     fix (saturated rose albedo + small matching emission)
#   - big enough r_inner for an OPEN centre eye + mud   ← v4 (no crowded core)
# THE legibility rule (all four): the berm half-width is held WELL UNDER the
# inter-arm gap (b·TAU) so rose water shows between every coil — that gap is
# what lets the spiral read from above.
#
# DNA mapping: color_a → dark basalt; color_b → rose-red water; accent →
# salt + earth tint; complexity → spiral turns + rock density; unit_count →
# total rock count; sculpt_width → lake/spiral size; sculpt_height → berm
# relief; emissive → faint salt glint (the water keeps its red regardless).
# The lake is a MeshInstance3D (the MultiMesh rock fields are invisible to the
# capture's AABB framing, so the disc frames the whole piece).

func _build_spiraljetty() -> void:
	_rng.seed = seed

	# --- canonical anchors: keep the work legible (red lake / black rock /
	# white salt) even under the artifact's pale default DNA, while still
	# sliding toward whatever color_a/b/accent a map sets. -----------------
	var basalt_a: Color = color_a.lerp(Color(0.075, 0.075, 0.085), 0.78)
	var basalt_b: Color = basalt_a.lerp(Color(0.155, 0.135, 0.125), 0.55)
	var water_red: Color = color_b.lerp(Color(0.66, 0.165, 0.175), 0.6)
	var earth_col: Color = Color(0.245, 0.155, 0.090).lerp(accent, 0.18)
	var earth_dark: Color = earth_col.darkened(0.38)
	var salt_col: Color = accent.lerp(Color(0.94, 0.94, 0.91), 0.82)

	# --- spiral parametrisation (counterclockwise Archimedean) -----------
	var width: float = maxf(sculpt_width, 2.0)
	var relief: float = maxf(sculpt_height, 0.2)
	var r_outer: float = width * 0.46
	var r_inner: float = maxf(width * 0.075, 0.40)          # open centre eye (v4)
	# complexity → turn count, clamped to the legible 2.6–3.2 band.
	var turns: float = clampf(2.6 + float(complexity - 6) * 0.07, 2.6, 3.2)
	turns += _rng.randf_range(-0.06, 0.06)                  # seeded individual
	var theta_max: float = turns * TAU
	var b_coef: float = (r_outer - r_inner) / theta_max     # radial growth/rad
	# THE rule: berm half-width well under the inter-arm gap (b·TAU) so red
	# water shows between coils. Cap at a third of the gap.
	var inter_arm: float = b_coef * TAU
	var berm_half: float = minf(width * 0.030, inter_arm * 0.33)
	berm_half = maxf(berm_half, 0.06)

	var water_top: float = 0.06                             # lake surface y

	# 1. the rose-red lake (MeshInstance3D — frames the capture) ----------
	_sj_lake(r_outer, width, water_red, water_top)

	# 2. brown earth/mud skirt under the berm (built causeway, v2/v4) ------
	_sj_earth_skirt(r_inner, b_coef, theta_max, berm_half, relief, earth_col)

	# 3. brown shore/entry patch at the outer mouth (v4) ------------------
	_sj_shore_patch(r_inner, b_coef, theta_max, relief, water_top,
		earth_col, earth_dark, basalt_a)

	# 4. angular basalt-rock berm + salt rims (v3 rocks, v2 salt) ---------
	_sj_berm(r_inner, b_coef, theta_max, berm_half, relief, water_top,
		basalt_a, basalt_b, earth_col, earth_dark, salt_col)


# Archimedean spiral point in XZ. Counterclockwise as read from above (+Y
# looking down): x = r·cos θ, z = -r·sin θ so increasing θ sweeps CCW.
func _sj_spiral_point(theta: float, r_inner: float, b_coef: float) -> Vector3:
	var r: float = r_inner + b_coef * theta
	return Vector3(r * cos(theta), 0.0, -r * sin(theta))


# Unit in-plane perpendicular (across the path) at θ, from the analytic tangent.
func _sj_across(theta: float, r_inner: float, b_coef: float) -> Vector3:
	var r: float = r_inner + b_coef * theta
	var dx: float = b_coef * cos(theta) - r * sin(theta)
	var dz: float = -(b_coef * sin(theta) + r * cos(theta))
	var across: Vector3 = Vector3(-dz, 0.0, dx)             # perpendicular in XZ
	if across.length() < 0.0001:
		return Vector3(1.0, 0.0, 0.0)
	return across.normalized()


# The wide rose-red Great Salt Lake. Saturated albedo + a small matching
# emission so the whole disc stays red (v3 found a plain rose greys at grazing
# angles). A darker, slightly lower silt ring beneath for shallow-edge depth.
func _sj_lake(r_outer: float, width: float, water_red: Color, water_top: float) -> void:
	var disc_r: float = r_outer + width * 0.14              # spiral + margin
	var water_mat: StandardMaterial3D = _make_mat(water_red, 0.62, 0.0)
	water_mat.emission_enabled = true
	water_mat.emission = water_red
	water_mat.emission_energy_multiplier = 0.16             # keeps it red, not grey
	# top face of the 0.10-thick disc lands at water_top.
	_add_cyl("SpiralLake", disc_r, disc_r, 0.10,
		Vector3(0.0, water_top - 0.05, 0.0), Vector3.ZERO, water_mat)

	var bed_col: Color = water_red.darkened(0.42)
	var bed_mat: StandardMaterial3D = _make_mat(bed_col, 0.9, 0.0)
	_add_cyl("SpiralLakeBed", disc_r * 1.03, disc_r * 1.03, 0.07,
		Vector3(0.0, water_top - 0.12, 0.0), Vector3.ZERO, bed_mat)


# A low brown mud ribbon following the spiral, just clearing the water, so the
# basalt sits on a built causeway rather than floating. An ArrayMesh strip;
# kept narrower than the rock band so no brown bridges the red water gaps.
func _sj_earth_skirt(r_inner: float, b_coef: float, theta_max: float,
		berm_half: float, relief: float, earth_col: Color) -> void:
	var samples: int = 300
	var rise: float = relief * 0.30                         # mud bank clears water
	var verts: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var indices: PackedInt32Array = PackedInt32Array()

	var i: int = 0
	while i <= samples:
		var t: float = float(i) / float(samples)
		var theta: float = lerpf(theta_max, 0.0, t)         # outer → inner
		var p: Vector3 = _sj_spiral_point(theta, r_inner, b_coef)
		var across: Vector3 = _sj_across(theta, r_inner, b_coef)
		# slightly wider at the shore, tapering toward the eye; under the rocks.
		var w: float = lerpf(berm_half * 1.05, berm_half * 0.70, t)
		var hl: Vector3 = p - across * w
		var hr: Vector3 = p + across * w
		hl.y = rise
		hr.y = rise
		verts.push_back(hl)
		verts.push_back(hr)
		normals.push_back(Vector3.UP)
		normals.push_back(Vector3.UP)
		i += 1

	var s: int = 0
	while s < samples:
		var a: int = s * 2
		var bb: int = s * 2 + 1
		var c: int = (s + 1) * 2
		var d: int = (s + 1) * 2 + 1
		indices.append_array([a, c, bb, bb, c, d])
		s += 1

	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = normals
	arr[Mesh.ARRAY_INDEX] = indices
	var am: ArrayMesh = ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = "SpiralEarthSkirt"
	mi.mesh = am
	mi.material_override = _make_mat(earth_col, 1.0, 0.0)
	add_child(mi)


# A blockier brown landfall where the spiral leaves the shore (the entry),
# pushed slightly outward so it reads as land, with a few loose rocks on it.
func _sj_shore_patch(r_inner: float, b_coef: float, theta_max: float,
		relief: float, water_top: float, earth_col: Color, earth_dark: Color,
		basalt_a: Color) -> void:
	var p: Vector3 = _sj_spiral_point(theta_max, r_inner, b_coef)
	var outward: Vector3 = p
	outward.y = 0.0
	if outward.length() < 0.01:
		outward = Vector3(0.0, 0.0, 1.0)
	outward = outward.normalized()
	var base: Vector3 = p + outward * 0.45
	var yaw: float = atan2(outward.x, outward.z)
	# a low brown earth pad (oriented by a manual yaw Basis — no out-of-tree look_at).
	_add_box("SpiralShore",
		Vector3(0.60 + r_inner * 0.6, relief * 0.34, 0.45 + r_inner * 0.4),
		Vector3(base.x, water_top + relief * 0.14, base.z),
		Vector3(0.0, yaw, 0.0), _make_mat(earth_col, 1.0, 0.0))
	# a handful of loose boulders clustered on the landfall.
	var across: Vector3 = _sj_across(theta_max, r_inner, b_coef)
	var k: int = 0
	while k < 7:
		var lat: float = _rng.randf_range(-0.34, 0.34)
		var along: float = _rng.randf_range(-0.30, 0.36)
		var rp: Vector3 = base + across * lat + outward * along
		var sz: float = _rng.randf_range(0.10, 0.18)
		rp.y = water_top + relief * _rng.randf_range(0.30, 0.55)
		var col: Color = earth_dark if _rng.randf() < 0.35 else basalt_a
		_sj_rock(k, rp, sz, col)
		k += 1


# The hero: the spiral berm built from ANGULAR basalt rocks (tumbled,
# clipped boxes in two charcoal tones, NOT uniform spheres) + brown earth,
# clustered along the coil and raised just above the water — plus white salt
# crystals rimming the waterline edges, thinning toward the eye. All rock and
# salt go into MultiMeshes (many instances); the lake handles framing.
func _sj_berm(r_inner: float, b_coef: float, theta_max: float,
		berm_half: float, relief: float, water_top: float,
		basalt_a: Color, basalt_b: Color, earth_col: Color, earth_dark: Color,
		salt_col: Color) -> void:
	# rock count from unit_count, scaled by complexity density; steps derived
	# so total instances land near unit_count (capped sane for determinism).
	var target_rocks: int = clampi(unit_count, 60, 1400)
	var density: float = clampf(0.6 + float(complexity) * 0.06, 0.7, 1.6)
	var per_step: int = clampi(int(round(2.0 * density)), 2, 4)
	var steps: int = clampi(int(round(float(target_rocks) / float(per_step))), 60, 460)

	var xf_a: Array[Transform3D] = []
	var xf_b: Array[Transform3D] = []
	var xf_earth: Array[Transform3D] = []
	var xf_salt: Array[Transform3D] = []

	var rock_top: float = relief * 0.52                     # crest above water (low berm)
	var i: int = 0
	while i <= steps:
		var t: float = float(i) / float(steps)
		var theta: float = lerpf(theta_max, 0.0, t)         # outer → inner eye
		var center: Vector3 = _sj_spiral_point(theta, r_inner, b_coef)
		var across: Vector3 = _sj_across(theta, r_inner, b_coef)
		# berm a touch wider at the shore, tightening inward; stays inside the
		# gap so red water reads between coils.
		var w: float = lerpf(berm_half * 1.10, berm_half * 0.70, t)

		var j: int = 0
		while j < per_step:
			# lateral offset across the berm (-1..1), biased toward the spine.
			var lat: float = _rng.randf_range(-1.0, 1.0)
			lat = signf(lat) * pow(absf(lat), 1.3)
			var off: Vector3 = across * (lat * w)
			off += Vector3(_rng.randf_range(-0.03, 0.03), 0.0,
				_rng.randf_range(-0.03, 0.03))
			# crest tallest on the spine, lower at the edges; smaller inward so
			# the centre eye stays open and legible.
			var edge_fade: float = 1.0 - absf(lat) * 0.55
			var crest: float = water_top + rock_top * edge_fade \
				* lerpf(1.0, 0.55, t) * _rng.randf_range(0.78, 1.04)
			var size: float = _rng.randf_range(0.065, 0.105) * lerpf(1.05, 0.70, t)
			var pos: Vector3 = center + off
			pos.y = crest - size * 0.35                     # bury the base
			var xform: Transform3D = _sj_rock_xform(pos, size)
			# ~78% angular basalt (two tones), ~22% brown earth/mud.
			var roll: float = _rng.randf()
			if roll < 0.22:
				xf_earth.append(xform)
			elif roll < 0.69:                               # ~0.47 of remainder
				xf_a.append(xform)
			else:
				xf_b.append(xform)
			j += 1

		# salt crust at the waterline edges — biased to the OUTER rim, thinning
		# toward the dry inner eye (toned: not every step, not both sides).
		if _rng.randf() < lerpf(0.85, 0.22, t):
			var edge_o: Vector3 = center + across * (w + 0.05)
			edge_o.y = water_top + 0.015
			xf_salt.append(_sj_salt_xform(edge_o))
		if _rng.randf() < lerpf(0.40, 0.10, t):
			var edge_i: Vector3 = center - across * (w + 0.05)
			edge_i.y = water_top + 0.015
			xf_salt.append(_sj_salt_xform(edge_i))
		i += 1

	# mix a hair of brown into the earth pile colour for variety.
	var earth_mix: Color = earth_col.lerp(earth_dark, 0.4)
	_sj_emit_rocks("SpiralBasaltA", xf_a, basalt_a, 0.97)
	_sj_emit_rocks("SpiralBasaltB", xf_b, basalt_b, 0.95)
	_sj_emit_rocks("SpiralEarthRocks", xf_earth, earth_mix, 1.0)
	_sj_emit_salt("SpiralSalt", xf_salt, salt_col)


# One angular boulder transform: a tumbled, non-uniformly squashed unit cube
# (the shared mesh is a clipped/faceted box — angular basalt, not a sphere).
func _sj_rock_xform(pos: Vector3, size: float) -> Transform3D:
	var sx: float = size * _rng.randf_range(0.78, 1.12)
	var sy: float = size * _rng.randf_range(0.50, 0.85)     # flattish (low relief)
	var sz: float = size * _rng.randf_range(0.78, 1.12)
	var basis: Basis = Basis()
	basis = basis.rotated(Vector3.UP, _rng.randf_range(0.0, TAU))
	basis = basis.rotated(Vector3.RIGHT, _rng.randf_range(-0.30, 0.30))
	basis = basis.rotated(Vector3.FORWARD, _rng.randf_range(-0.30, 0.30))
	basis = basis.scaled(Vector3(sx, sy, sz))
	return Transform3D(basis, pos)


# A single loose boulder as a MeshInstance3D (used on the shore patch). Named
# with its index so scene node names stay stable (no engine auto-suffixing).
func _sj_rock(idx: int, pos: Vector3, size: float, col: Color) -> void:
	var rock: MeshInstance3D = MeshInstance3D.new()
	rock.name = "SpiralShoreRock%d" % idx
	rock.mesh = _sj_rock_mesh()
	rock.material_override = _make_mat(col, 0.97, 0.0)
	var xform: Transform3D = _sj_rock_xform(pos, size)
	rock.transform = xform
	add_child(rock)


# Small salt-crystal transform: a tiny tumbled chip at the waterline.
func _sj_salt_xform(pos: Vector3) -> Transform3D:
	var cs: float = _rng.randf_range(0.045, 0.10)
	var basis: Basis = Basis().rotated(Vector3.UP, _rng.randf_range(0.0, TAU))
	basis = basis.scaled(Vector3(cs * _rng.randf_range(1.0, 1.7), cs * 0.55,
		cs * _rng.randf_range(1.0, 1.7)))
	return Transform3D(basis, pos)


# The shared ANGULAR rock mesh: a faceted, low-poly box (jagged basalt cobble),
# deliberately a box rather than a sphere so rims read as cut/cleaved stone.
func _sj_rock_mesh() -> Mesh:
	var bm: BoxMesh = BoxMesh.new()
	bm.size = Vector3(1.0, 1.0, 1.0)
	return bm


# Emit a basalt/earth rock field as one MultiMeshInstance3D (matte rock).
func _sj_emit_rocks(nm: String, xforms: Array[Transform3D], col: Color,
		rough: float) -> void:
	if xforms.is_empty():
		return
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _sj_rock_mesh()
	mm.instance_count = xforms.size()
	var k: int = 0
	while k < xforms.size():
		mm.set_instance_transform(k, xforms[k])
		k += 1
	var inst: MultiMeshInstance3D = MultiMeshInstance3D.new()
	inst.name = nm
	inst.multimesh = mm
	inst.material_override = _make_mat(col, rough, 0.0)
	add_child(inst)


# Emit the salt crust as one MultiMeshInstance3D. Pale; a faint glint only
# when `emissive` is on (toned so it reads as crust, not glow).
func _sj_emit_salt(nm: String, xforms: Array[Transform3D], col: Color) -> void:
	if xforms.is_empty():
		return
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var chip: BoxMesh = BoxMesh.new()
	chip.size = Vector3(1.0, 1.0, 1.0)
	mm.mesh = chip
	mm.instance_count = xforms.size()
	var k: int = 0
	while k < xforms.size():
		mm.set_instance_transform(k, xforms[k])
		k += 1
	var mat: StandardMaterial3D = _make_mat(col, 0.78, 0.0)
	if emissive:
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = 0.14                # faint glint only
	var inst: MultiMeshInstance3D = MultiMeshInstance3D.new()
	inst.name = nm
	inst.multimesh = mm
	inst.material_override = mat
	add_child(inst)


# ── Mode: LEWITT (Sol LeWitt — modular open-cube structure) ────────────
# A lattice of OPEN cubes: each cube is defined ONLY by its 12 edge struts (no
# faces). Adjacent cubes SHARE edges, so the structure is built from the set of
# UNIQUE edges over the cells' vertices — each edge emitted exactly once (no
# doubled struts). Every edge is axis-aligned, so each strut is a thin
# square-section BoxMesh sized directly along its axis (no quaternion). A small
# solid cubelet joints each occupied vertex for crisp corners. Monochrome matte
# white — the serial system is the subject.
#
# The seed picks the specimen (deterministic): a full n×n×n lattice; a single-
# layer n×n×1 FLOOR GRID; a STEPPED ZIGGURAT (layers shrinking upward); or an
# INCOMPLETE lattice with one front-top corner cube decisively opened (its top
# face + two verticals removed) so the capture camera (+Z) frames the gap.
# DNA: complexity → grid size n (2-4); sculpt_width/height → overall size;
# color_a → white strut tone; color_b/accent → faint base pad; rough/metallic →
# finish; seed (via _rng) → variant + which corner opens.

func _build_lewitt() -> void:
	_rng.seed = seed

	# Grid size from complexity (LeWitt's structures are 2..4 cubes per side).
	var n: int = clampi(complexity, 2, 4)

	# Choose the specimen variant deterministically from the seed.
	# 0 full · 1 floor-grid · 2 stepped ziggurat · 3 incomplete · 4 z-random field ·
	# 5 full grid whose corner NODES warp off-grid more and more along z.
	# Spread specimens across a curated set (per seed) so the gallery shows range.
	var lut: Array[int] = [4, 5, 2, 3, 0]    # field · warp · ziggurat · incomplete · full
	var variant: int = lut[posmod(seed, 5)]

	# Per-axis grid dimensions. Most variants are cubic n³; the FIELD and WARP
	# variants are an elongated 4(x) × 3(y) × 12(z) lattice along the long z axis.
	var nx: int = n
	var ny: int = n
	var nz: int = n
	if variant == 4 or variant == 5:
		nx = 4
		ny = 3
		nz = 12

	# Uniform cubic cells; size so the cross-section (x,y) fits sculpt_width.
	var span: float = maxf(sculpt_width, 0.2)
	var cell: float = span / float(maxi(nx, ny))
	var half_x: float = float(nx) * cell * 0.5         # x centring offset
	var half_z: float = float(nz) * cell * 0.5         # z centring offset

	# WARP (variant 5): corner-node displacement amplitude. Grows toward the back
	# of z (front stays a crisp lattice, the deep end dissolves into disorder).
	var warp_amp: float = (cell * 0.45) if variant == 5 else 0.0

	# Strut cross-section: thin square bars, proportional to the cell.
	var strut: float = cell * lerpf(0.06, 0.045, clampf(float(maxi(nx, ny) - 2) / 2.0, 0.0, 1.0))

	# Matte WHITE for every strut + joint. Lerp color_a toward white so it reads
	# white even if a non-white default DNA colour is supplied.
	var white_col: Color = color_a.lerp(Color(0.94, 0.94, 0.92), 0.7)
	var white: StandardMaterial3D = _make_mat(white_col,
		clampf(maxf(rough_amt, 0.6), 0.0, 1.0), clampf(metallic_amt, 0.0, 0.25))

	# Which cube cells are occupied (Vector3i index in [0,n) per axis). The edge
	# set is then the union of the 12 edges of every occupied cube, deduplicated —
	# so floor-grid and ziggurat fall out of the same emission code.
	var cells: Dictionary = _lw_cells(nx, ny, nz, variant)

	# Open a decisive front-top corner cube for the "incomplete" specimen.
	var omit: Dictionary = {}
	if variant == 3:
		omit = _lw_incomplete_corner(n)

	# Collect the unique edges (and the vertices they touch) of all occupied cells.
	var edges: Dictionary = {}            # edge_key -> [Vector3i a, Vector3i b]
	var verts: Dictionary = {}            # vert_key -> Vector3i (surviving only)
	for ck in cells.keys():
		var c: Vector3i = cells[ck]
		for e in _lw_cube_edges(c):
			var a: Vector3i = e[0]
			var b: Vector3i = e[1]
			var ek: String = _lw_edge_key(a, b)
			if omit.has(ek):
				continue
			if not edges.has(ek):
				edges[ek] = [a, b]
				verts[_lw_vkey(a)] = a
				verts[_lw_vkey(b)] = b

	var lattice: Node3D = Node3D.new()
	lattice.name = "OpenCubeLattice"
	add_child(lattice)

	# Emit one strut per unique surviving edge.
	var strut_count: int = 0
	for ek in edges.keys():
		var pair: Array = edges[ek]
		var pa: Vector3 = _lw_vpos(pair[0], cell, half_x, half_z, warp_amp, nz)
		var pb: Vector3 = _lw_vpos(pair[1], cell, half_x, half_z, warp_amp, nz)
		_lw_strut(lattice, pa, pb, strut, white)
		strut_count += 1

	# Joint cubelets at every surviving vertex (orphans already dropped: a vertex
	# only appears in `verts` if at least one surviving edge touched it).
	var joint_count: int = 0
	var js: float = strut * 1.04
	for vk in verts.keys():
		var p: Vector3 = _lw_vpos(verts[vk], cell, half_x, half_z, warp_amp, nz)
		_add_box("LewittJoint", Vector3(js, js, js), p, Vector3.ZERO, white)
		joint_count += 1

	# Thin base pad, SMALL and flush to the footprint (a faint cool-grey tone so
	# only the structure reads as the subject). Use color_b nudged toward accent.
	var base_col: Color = color_b.lerp(accent, 0.15).lerp(Color(0.82, 0.83, 0.85), 0.5)
	var base_mat: StandardMaterial3D = _make_mat(base_col, 0.85, 0.0)
	var pad_h: float = maxf(strut * 1.4, 0.02)
	var pad_w_x: float = float(nx) * cell + strut * 3.0
	var pad_w_z: float = float(nz) * cell + strut * 3.0
	_add_box("LewittBase", Vector3(pad_w_x, pad_h, pad_w_z),
		Vector3(0.0, -pad_h * 0.5, 0.0), Vector3.ZERO, base_mat)


# Occupied cube cells for the chosen variant. Cell index runs [0,n) per axis.
func _lw_cells(nx: int, ny: int, nz: int, variant: int) -> Dictionary:
	var d: Dictionary = {}
	match variant:
		1:
			# FLOOR GRID — a single layer of open cubes (nx×1×nz).
			for cx in range(nx):
				for cz in range(nz):
					var c1: Vector3i = Vector3i(cx, 0, cz)
					d[_lw_vkey(c1)] = c1
		2:
			# STEPPED ZIGGURAT — each layer up shrinks by one, centred, down to 1.
			for cy in range(ny):
				var size: int = maxi(1, nx - cy)
				var off: int = int(floor(float(nx - size) / 2.0))
				for cx in range(size):
					for cz in range(size):
						var c2: Vector3i = Vector3i(off + cx, cy, off + cz)
						d[_lw_vkey(c2)] = c2
		4:
			# FIELD — an elongated random open-cube field. Each (x,z) column gets a
			# random height; gaps and height-variance GROW toward the back so the
			# long z axis reads as increasingly random (front fuller, back sparse).
			for cx in range(nx):
				for cz in range(nz):
					var zf: float = float(cz) / float(maxi(nz - 1, 1))
					if _rng.randf() < lerpf(0.06, 0.34, zf):
						continue                       # empty column → a gap
					var hcol: int = ny
					if _rng.randf() < lerpf(0.15, 0.85, zf):
						hcol = _rng.randi_range(1, ny)
					for cy in range(hcol):
						var cf: Vector3i = Vector3i(cx, cy, cz)
						d[_lw_vkey(cf)] = cf
		_:
			# FULL (0) and INCOMPLETE (3) both start from the solid block;
			# the incomplete variant then removes edges via the omit set.
			for cx in range(nx):
				for cy in range(ny):
					for cz in range(nz):
						var c0: Vector3i = Vector3i(cx, cy, cz)
						d[_lw_vkey(c0)] = c0
	return d


# The 12 edges of one cube cell, as vertex-index pairs (Vector3i in [0,n]).
func _lw_cube_edges(c: Vector3i) -> Array:
	var v: Array[Vector3i] = [
		Vector3i(c.x, c.y, c.z),
		Vector3i(c.x + 1, c.y, c.z),
		Vector3i(c.x, c.y + 1, c.z),
		Vector3i(c.x, c.y, c.z + 1),
		Vector3i(c.x + 1, c.y + 1, c.z),
		Vector3i(c.x + 1, c.y, c.z + 1),
		Vector3i(c.x, c.y + 1, c.z + 1),
		Vector3i(c.x + 1, c.y + 1, c.z + 1),
	]
	# 12 edges: 4 along X, 4 along Y, 4 along Z, by the 8 corners above.
	return [
		[v[0], v[1]], [v[2], v[4]], [v[3], v[5]], [v[6], v[7]],   # X edges
		[v[0], v[2]], [v[1], v[4]], [v[3], v[6]], [v[5], v[7]],   # Y edges
		[v[0], v[3]], [v[1], v[5]], [v[2], v[6]], [v[4], v[7]],   # Z edges
	]


# Edges to remove for the "incomplete" specimen: open the FRONT-TOP corner cube
# at +X / +Z / top (cell index n-1,n-1,n-1) — its top face's 4 edges plus two
# of its vertical posts — so the +Z capture camera frames the opening squarely.
func _lw_incomplete_corner(n: int) -> Dictionary:
	var d: Dictionary = {}
	var x0: int = n - 1
	var y0: int = n - 1
	var z0: int = n - 1
	var x1: int = n
	var y1: int = n
	var z1: int = n
	# Top face (y == y1): its 4 edges.
	d[_lw_edge_key(Vector3i(x0, y1, z0), Vector3i(x1, y1, z0))] = true
	d[_lw_edge_key(Vector3i(x0, y1, z1), Vector3i(x1, y1, z1))] = true
	d[_lw_edge_key(Vector3i(x0, y1, z0), Vector3i(x0, y1, z1))] = true
	d[_lw_edge_key(Vector3i(x1, y1, z0), Vector3i(x1, y1, z1))] = true
	# Two front verticals (the +Z face's outer posts) of that corner cube.
	d[_lw_edge_key(Vector3i(x1, y0, z1), Vector3i(x1, y1, z1))] = true
	d[_lw_edge_key(Vector3i(x0, y0, z1), Vector3i(x0, y1, z1))] = true
	return d


# Vertex world position from lattice index. Origin bottom-centre, +Z forward.
# When warp_amp > 0 (the WARP variant) the node is displaced off-grid by a
# deterministic per-(index, seed) offset that GROWS toward the back of z — so the
# front reads as a crisp lattice and the deep end dissolves into disorder. The
# offset is a pure function of the index, so corners shared between adjacent cubes
# always move together and the struts stay connected.
func _lw_vpos(idx: Vector3i, cell: float, half_x: float, half_z: float,
		warp_amp: float, nz: int) -> Vector3:
	var p: Vector3 = Vector3(float(idx.x) * cell - half_x, float(idx.y) * cell,
		float(idx.z) * cell - half_z)
	if warp_amp > 0.0:
		var zf: float = pow(clampf(float(idx.z) / float(maxi(nz, 1)), 0.0, 1.0), 1.7)
		var h: float = float(idx.x) * 127.1 + float(idx.y) * 311.7 \
			+ float(idx.z) * 74.7 + float(seed) * 0.013
		var ox: float = _lw_fract(sin(h) * 43758.5453) * 2.0 - 1.0
		var oy: float = _lw_fract(sin(h + 1.7) * 43758.5453) * 2.0 - 1.0
		var oz: float = _lw_fract(sin(h + 3.3) * 43758.5453) * 2.0 - 1.0
		p += Vector3(ox, oy, oz) * (warp_amp * zf)
	return p


func _lw_fract(x: float) -> float:
	return x - floor(x)


# A single strut spanning a->b — an oriented thin box (local +Y aimed along the
# edge). Works for the rigid axis-aligned lattice AND the WARP variant's diagonal
# off-grid edges. Length extended by `thick` so struts butt into the joint cubes.
func _lw_strut(parent: Node3D, a: Vector3, b: Vector3, thick: float,
		mat: StandardMaterial3D) -> void:
	var d: Vector3 = b - a
	var length: float = d.length()
	if length <= 0.0001:
		return
	var yax: Vector3 = d / length
	var ref: Vector3 = Vector3.RIGHT if absf(yax.x) < 0.9 else Vector3.FORWARD
	var xax: Vector3 = ref.cross(yax).normalized()
	var zax: Vector3 = xax.cross(yax).normalized()
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = "LewittStrut"
	var bm: BoxMesh = BoxMesh.new()
	bm.size = Vector3(thick, length + thick, thick)
	mi.mesh = bm
	mi.material_override = mat
	mi.transform = Transform3D(Basis(xax, yax, zax), (a + b) * 0.5)
	parent.add_child(mi)


# Order-independent key for a lattice edge so a shared edge resolves to one key.
func _lw_edge_key(a: Vector3i, b: Vector3i) -> String:
	var lo: Vector3i = a
	var hi: Vector3i = b
	if (b.x < a.x) or (b.x == a.x and b.y < a.y) or (b.x == a.x and b.y == a.y and b.z < a.z):
		lo = b
		hi = a
	return "%d,%d,%d-%d,%d,%d" % [lo.x, lo.y, lo.z, hi.x, hi.y, hi.z]


# Key for a single lattice vertex.
func _lw_vkey(v: Vector3i) -> String:
	return "%d,%d,%d" % [v.x, v.y, v.z]
