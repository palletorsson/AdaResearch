# becoming_jar.gd
# WAVE 21 SYNTHESIS — the two-member family `becoming`.
#
# SOURCES, both read in full before a line of this was written:
#   commons/artifacts/dna_specimen/dna_specimen.gd
#   commons/artifacts/queer_morphology_specimen/queer_morphology_specimen.gd
#
# THE HYPOTHESIS A TWO-MEMBER FAMILY IS. With three members you ask whether they agree;
# with two you can only ask whether the word is one word. It is — but not because two
# artifacts converged on it. dna_specimen's own registry says its four rungs were "taken
# character for character from queer_morphology_specimen" (and dna_specimen.gd:26-27 says
# it again in the code), so the agreement is a TRANSCRIPTION, not a corroboration. The one
# place the copy slipped is the one place they disagree: at `cracked`,
# queer_morphology_specimen.gd:272-273 shortens the glass by CRACK_RIM_CUT and builds an
# open rim, while dna_specimen's `cracked` (gd:190-193) never touches the jar at all — it
# moves the lid, drops the fluid and raises the helix. In one file the container is
# breached; in the other it is merely opened.
#
# WHAT READING THE CODE ACTUALLY FOUND, and it is not what the word promises. `becoming`
# looks like a ladder out of a container: jarred -> cracked -> escaped. Three of its four
# values are exactly that, and dna_specimen makes the nesting literal — `escaped` calls the
# same _lay_lid_down() that `cracked` calls (dna_specimen.gd:191 and gd:195). But `clouded`
# is not further along that ladder and it is not, as it is usually described, a change in
# the MEDIUM. The medium is untouched: dna_specimen restores the shipped fluid mesh
# (gd:182-183) and queer_morphology_specimen builds the fluid at its full height
# (gd:357) — at `clouded` BOTH files return the container to stage zero, sealed, lid on,
# full. What changes is the occupant: it stops being one body.
#
# So the word is not one axis with an outlier. It is a PRODUCT:
#
#                      | occupant single | occupant dispersed
#   container sealed   |     jarred      |      clouded
#   container breached |     cracked     |      (never built)
#   container absent   |     escaped     |      (never built)
#
# Four of six cells. A specimen that has come apart AND left is a thing neither file can
# say, because one word is carrying two questions. This artifact separates them: `becoming`
# keeps the sources' four values verbatim, and `reading` chooses which of the two factors
# the frame draws in full while the other stands as a constant grey.
#
# NOTHING IS DESTROYED AT ANY VALUE. The occupant is BEAD_N beads at every rung, the same
# beads, the same radius, the same 72 blue and 72 pink. At `escaped` they describe a helix
# twice as large and are therefore twice as far apart; at `clouded` they fill the jar.
# Neither source conserves its specimen — dna_specimen swaps a helix for 220 new grains
# (gd:264-291), queer_morphology_specimen swaps a soft body for 160 (gd:482-513) — so in
# both, "becoming" quietly imports a change in the AMOUNT of the thing. Here it cannot.
# Becoming is a change of arrangement and extent, not a loss.
#
# NO TRANSPARENCY ANYWHERE, and that is a measurement decision with a receipt.
# queer_morphology_specimen.gd:71-77 records that `clouded` once photographed as a twin of
# `jarred` at 5.5% — transparent grains inside transparent fluid inside transparent glass
# blend to the same haze. The vitrine here is therefore SECTIONED: opaque staves over the
# back STAVE_ARC_SPAN degrees with an open window facing the approach, and the fluid drawn
# as the coloured lower band of those staves rather than as a volume. A sectioned jar is
# also what a museum does when the container is in the way of the thing it preserves.
#
# @identity
# essence: becoming = (container_state, occupant_state), photographed one factor at a time
# desire: see which half of the word each of its four values is actually about
# critical_parameter: reading — which factor is drawn in full and which stands as a constant
# triggers: nothing. Every value is meshes and transforms resolved in _ready()
# emerges: at reading=container the pair (jarred, clouded) is one photograph twice, because
#   `clouded` never touches the container; at reading=occupant no two values coincide
# needs: a still [has], no animation [has], no randomness [has]
# relationships: synthesises dna_specimen and queer_morphology_specimen; kin to handed_pair,
#   which declined this same axis on the grounds that "the jar is the specimen's argument,
#   not the helix's" — a judgement the code here confirms from the other direction
# truth: a container's history and an occupant's dispersal are two facts, and `becoming`
#   is one word holding both, which is why two of its six cells cannot be named.

extends Node3D

class_name BecomingJar

## AXIS — the family word, four values verbatim from both sources and in their order
## (dna_specimen.gd:55, queer_morphology_specimen.gd:56).
##
##   jarred   sealed vitrine, one body suspended at mid-height. The shipped reading of
##            both sources
##   cracked  the seal is broken — the lid is off and tipped on the plinth LID_OFFSET to
##            the right, the top RIM_CUT of glass is not built, the fluid drops to
##            FLUID_BREACHED so the line reads, and the body rises CRACK_RISE
##   escaped  no glass and no fluid — only the ring and the discarded lid remain, and the
##            same beads describe a helix ESCAPE_SCALE times as large, standing on the ring.
##            Bigger and, necessarily, sparser: the matter did not grow
##   clouded  the vitrine is sealed and full exactly as at `jarred`, and the beads no longer
##            lie on the helix — they fill the interior. The volume is occupied, the order
##            is gone
@export_enum("jarred", "cracked", "escaped", "clouded") var becoming: String = "jarred"

## AXIS — which of the two things the word `becoming` conflates is drawn in full. The other
## is built at its CONSTANT state in flat grey, so it stays legible as context and
## contributes nothing to any difference between the four values.
##
##   container  the vitrine at full material — pale staves, dark fluid band, metal lid and
##              ring — with the occupant as a constant grey helix. Only the container moves
##   occupant   the beads at full colour and emission, against a constant grey sealed
##              vitrine with no lid and no fluid. Only the occupant moves
##
## There is deliberately no value that draws both in full. A value that is the union of the
## others measures as the loudest tile on the axis and answers nothing.
@export_enum("container", "occupant") var reading: String = "container"

## Allow-lists. A typo in a map token falls back to the shipped look rather than stranding a
## placement with a half-built vitrine — the pattern both sources use
## (dna_specimen.gd:70-71, queer_morphology_specimen.gd:60).
const BECOMINGS: PackedStringArray = ["jarred", "cracked", "escaped", "clouded"]
const READINGS: PackedStringArray = ["container", "occupant"]

# --- the vitrine ---------------------------------------------------------------------
# Dimensions are queer_morphology_specimen's, which are the fully specified pair
# (gd:25-26); dna_specimen's jar is 0.12 x 0.45 and disagrees. Where the two files use the
# SAME number it is cited on the line.
const JAR_R: float = 0.15                 # queer_morphology_specimen.gd:26
const JAR_H: float = 0.40                 # queer_morphology_specimen.gd:25
const PLINTH_W: float = 0.44
const PLINTH_H: float = 0.08
const FLOOR_Y: float = 0.08               # top face of the plinth
const RING_H: float = 0.025
const JAR_FLOOR: float = 0.105            # FLOOR_Y + RING_H — the inside floor of the jar
const RIM_CUT: float = 0.06               # queer_morphology_specimen.gd:66
const LID_OFFSET: float = 0.19            # BOTH sources, to the centimetre: qms gd:67, dna gd:216
const LID_TIP: float = 1.40               # radians — dna_specimen.gd:215
const LID_Y_TIPPED: float = 0.2526        # so the tipped disc rests on the plinth top
const FLUID_SEALED: float = 0.34          # JAR_H * 0.85 — queer_morphology_specimen.gd:357
const FLUID_BREACHED: float = 0.28        # queer_morphology_specimen.gd:69

# The section. Staves cover the back STAVE_ARC_SPAN and leave a window facing +Z, the
# approach side both sources face. The sweep camera stands at yaw 0.62 rad = 35.5 degrees
# off +Z, comfortably inside a 130-degree window, and looks through it at the back staves.
const STAVE_N: int = 22
const STAVE_ARC_LO: float = 70.0          # degrees from +Z toward +X
const STAVE_ARC_STEP: float = 10.0
const STAVE_W: float = 0.026              # tangential — 10 degrees of arc at STAVE_R
const STAVE_T: float = 0.012              # radial thickness of the glass shell
const STAVE_R: float = 0.156              # shell centre radius; inner face at JAR_R

# --- the occupant --------------------------------------------------------------------
# One bead count and one bead radius for every value of `becoming`. This is the whole
# conservation argument and it is a constant on purpose.
const BEAD_N: int = 144                   # 72 per strand
const BEAD_R: float = 0.0115
const HELIX_R: float = 0.075              # dna_specimen's measured helix radius
const HELIX_H: float = 0.30               # over which it makes HELIX_TURNS turns
const HELIX_TURNS: float = 3.0
const CRACK_RISE: float = 0.09            # dna_specimen.gd:192
const ESCAPE_SCALE: float = 2.0           # "twice its scale" — dna_specimen.gd:50
const GOLDEN: float = 2.399963229728653   # golden angle — dna_specimen.gd:75

# The suspension's radial jitter, borrowed whole from dna_specimen.gd:284. It is a fixed
# irrational stride through fmod, not a random number: no seed to pin, no RandomNumber-
# Generator to leak, the same still every capture.
const CLOUD_STRIDE: float = 0.7548776662

# --- palette -------------------------------------------------------------------------
# Every material is OPAQUE. See the header.
const C_GLASS: Color = Color(0.86, 0.90, 0.94)
const C_FLUID: Color = Color(0.10, 0.30, 0.25)
const C_METAL: Color = Color(0.25, 0.22, 0.20)     # queer_morphology_specimen.gd:260
const C_PLINTH: Color = Color(0.12, 0.12, 0.14)    # queer_morphology_specimen.gd:338
const C_GHOST: Color = Color(0.20, 0.21, 0.23)
const C_BEAD_A: Color = Color(0.2, 0.6, 1.0)       # dna_specimen.gd:35
const C_BEAD_B: Color = Color(1.0, 0.4, 0.6)       # dna_specimen.gd:36
const BEAD_GLOW: float = 0.35

## Everything this script added as a direct child. A rebuild frees only these — the grid
## adds framing, plates and grounding of its own and get_children() would take those with
## it (the lesson queer_morphology_specimen.gd:848-856 records).
var _created: Array[Node] = []
var _built: bool = false


func _ready() -> void:
	_build()
	_built = true


func _build() -> void:
	becoming = _pick(becoming, BECOMINGS, "jarred")
	reading = _pick(reading, READINGS, "container")

	if reading == "occupant":
		# The container is bracketed: its CONSTANT sealed state, no lid, no fluid, grey.
		_build_container("sealed", false)
		_build_occupant(becoming, true)
	else:
		# The occupant is bracketed: its CONSTANT `jarred` arrangement, grey.
		_build_container(_seal_of(becoming), true)
		_build_occupant("jarred", false)


## The container factor of `becoming`. THREE states across FOUR values, because `jarred`
## and `clouded` share one — which is the designed null and the whole finding. Written as
## one function of one argument so that the two frames are produced by identical calls.
func _seal_of(value: String) -> String:
	match value:
		"cracked":
			return "breached"
		"escaped":
			return "absent"
		_:
			# jarred AND clouded. queer_morphology_specimen builds full-height glass, a
			# seated lid and a full fluid column for both (gd:265-314, gd:357); dna_specimen
			# leaves the shipped vitrine untouched for both (gd:188, gd:202-208).
			return "sealed"


# --- container ------------------------------------------------------------------------

func _build_container(seal: String, full: bool) -> void:
	var metal: StandardMaterial3D = _mat(C_METAL if full else C_GHOST, 0.8 if full else 0.0, 0.4, 0.0)
	var stone: StandardMaterial3D = _mat(C_PLINTH if full else C_GHOST, 0.5 if full else 0.0, 0.6, 0.0)
	var glass: StandardMaterial3D = _mat(C_GLASS if full else C_GHOST, 0.05, 0.25 if full else 0.95, 0.0)
	var fluid: StandardMaterial3D = _mat(C_FLUID, 0.0, 0.35, 0.5)

	# Plinth
	var plinth_box: BoxMesh = BoxMesh.new()
	plinth_box.size = Vector3(PLINTH_W, PLINTH_H, PLINTH_W)
	_put("Plinth", plinth_box, stone, Vector3(0.0, PLINTH_H * 0.5, 0.0))

	# The ring the jar stands on. Survives every value; at `absent` it and the discarded
	# lid are all that is left of the apparatus — queer_morphology_specimen.gd:319-321.
	var ring: CylinderMesh = CylinderMesh.new()
	ring.top_radius = JAR_R * 1.2
	ring.bottom_radius = JAR_R * 1.3
	ring.height = RING_H
	ring.radial_segments = 32
	_put("BaseRing", ring, metal, Vector3(0.0, FLOOR_Y + RING_H * 0.5, 0.0))

	# The sectioned glass. `absent` builds none of it.
	if seal != "absent":
		var stave_h: float = JAR_H
		if seal == "breached":
			stave_h = JAR_H - RIM_CUT
		var fluid_col: float = 0.0
		if full:
			fluid_col = FLUID_BREACHED if seal == "breached" else FLUID_SEALED
		_build_staves(stave_h, fluid_col, glass, fluid)

	# The lid. Only the container reading draws it: in the occupant reading a seated lid
	# would be a ceiling the `escaped` helix passes through, and a tipped one would be the
	# container factor leaking into the frame that is supposed to hold it still.
	if full:
		var lid: CylinderMesh = CylinderMesh.new()
		lid.top_radius = JAR_R * 1.1
		lid.bottom_radius = JAR_R * 1.15
		lid.height = 0.03
		lid.radial_segments = 32
		if seal == "sealed":
			_put("Lid", lid, metal, Vector3(0.0, JAR_FLOOR + JAR_H + 0.015, 0.0))
		else:
			# Off the jar and tipped on the plinth. Both sources displace it by exactly
			# LID_OFFSET, and dna_specimen tips it by exactly LID_TIP.
			var node: MeshInstance3D = _put("LidDisplaced", lid, metal,
					Vector3(LID_OFFSET, LID_Y_TIPPED, 0.0))
			node.basis = Basis(Vector3(0.0, 0.0, 1.0), LID_TIP)


## Staves, each split at the fluid line into a dark lower box and a pale upper one. The
## fluid is a LEVEL, not a volume: what a still can hold of a fluid column is the line
## across the glass, which is what both sources say they are after ("so a meniscus reads
## across the glass", dna_specimen.gd:47; "the meniscus shows", queer_morphology_specimen
## gd:38-39). Drawn as a volume it would be a transparent cylinder in front of the
## occupant, which is the exact failure queer_morphology_specimen.gd:71-77 measured.
func _build_staves(stave_h: float, fluid_col: float, glass: StandardMaterial3D,
		fluid: StandardMaterial3D) -> void:
	var wet: float = clampf(fluid_col, 0.0, stave_h)
	var dry: float = stave_h - wet

	var wet_box: BoxMesh = BoxMesh.new()
	wet_box.size = Vector3(STAVE_W, maxf(wet, 0.001), STAVE_T)
	var dry_box: BoxMesh = BoxMesh.new()
	dry_box.size = Vector3(STAVE_W, maxf(dry, 0.001), STAVE_T)

	for i in range(STAVE_N):
		var deg: float = STAVE_ARC_LO + float(i) * STAVE_ARC_STEP
		var a: float = deg_to_rad(deg)
		var px: float = sin(a) * STAVE_R
		var pz: float = cos(a) * STAVE_R
		if wet > 0.0:
			var w: MeshInstance3D = _put("StaveWet%d" % i, wet_box, fluid,
					Vector3(px, JAR_FLOOR + wet * 0.5, pz))
			w.rotation.y = a
		if dry > 0.0:
			var d: MeshInstance3D = _put("StaveDry%d" % i, dry_box, glass,
					Vector3(px, JAR_FLOOR + wet + dry * 0.5, pz))
			d.rotation.y = a


# --- occupant -------------------------------------------------------------------------

## BEAD_N beads, always. `full` chooses the two strand colours and their emission; the
## bracketed version is the same beads in the same places in flat grey.
func _build_occupant(value: String, full: bool) -> void:
	var bead: SphereMesh = SphereMesh.new()
	bead.radius = BEAD_R
	bead.height = BEAD_R * 2.0
	bead.radial_segments = 12
	bead.rings = 6

	var mat_a: StandardMaterial3D = _mat(C_BEAD_A if full else C_GHOST, 0.1, 0.35,
			BEAD_GLOW if full else 0.0)
	var mat_b: StandardMaterial3D = _mat(C_BEAD_B if full else C_GHOST, 0.1, 0.35,
			BEAD_GLOW if full else 0.0)

	if value == "clouded":
		_build_suspension(bead, mat_a, mat_b)
		return

	var scale_f: float = ESCAPE_SCALE if value == "escaped" else 1.0
	var r: float = HELIX_R * scale_f
	var h: float = HELIX_H * scale_f
	# Where the body sits relative to the container it is leaving.
	var y0: float = JAR_FLOOR + (JAR_H - HELIX_H) * 0.5
	if value == "cracked":
		y0 += CRACK_RISE
	elif value == "escaped":
		y0 = JAR_FLOOR

	var per: int = BEAD_N / 2
	for s in range(2):
		var offset: float = PI * float(s)
		var mat: StandardMaterial3D = mat_a if s == 0 else mat_b
		for k in range(per):
			var u: float = float(k) / float(per - 1)
			var theta: float = TAU * HELIX_TURNS * u + offset
			_put("Bead%d_%d" % [s, k], bead, mat,
					Vector3(cos(theta) * r, y0 + u * h, sin(theta) * r))


## `clouded` — the SAME BEADS, no longer on the helix. Golden-angle placement with a fixed
## irrational radial stride, lifted from dna_specimen.gd:281-291: deterministic, so the
## same still comes back every capture and no seed has to be pinned in dna.fixture.
##
## The interior of the SEALED jar, which is where they go, because `clouded` leaves the
## container at stage zero in both sources.
func _build_suspension(bead: SphereMesh, mat_a: StandardMaterial3D,
		mat_b: StandardMaterial3D) -> void:
	var r_max: float = JAR_R * 0.9 - BEAD_R
	var y_lo: float = JAR_FLOOR + BEAD_R * 2.0
	var y_hi: float = JAR_FLOOR + FLUID_SEALED - BEAD_R * 2.0
	for i in range(BEAD_N):
		var t: float = (float(i) + 0.5) / float(BEAD_N)
		var angle: float = float(i) * GOLDEN
		var rad: float = r_max * sqrt(fmod(float(i) * CLOUD_STRIDE, 1.0))
		var yy: float = y_lo + t * (y_hi - y_lo)
		# i % 2 alternates the two strand colours, exactly as dna_specimen.gd:288 does, so
		# the cloud carries 72 of each — the same count the helix carried.
		_put("Grain%d" % i, bead, mat_a if i % 2 == 0 else mat_b,
				Vector3(cos(angle) * rad, yy, sin(angle) * rad))


# --- plumbing -------------------------------------------------------------------------

func _mat(albedo: Color, metallic: float, rough: float, emission: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = albedo
	m.metallic = metallic
	m.roughness = rough
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = albedo
		m.emission_energy_multiplier = emission
	return m


func _put(nm: String, mesh: Mesh, mat: StandardMaterial3D, pos: Vector3) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = nm
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
	_created.append(mi)
	return mi


func _pick(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


func _rebuild() -> void:
	for c in _created:
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_created.clear()
	_build()


## GUARDED, and geometry is rebuilt only when a geometry key actually moved — the pattern
## both sources arrived at (dna_specimen.gd:320-345, queer_morphology_specimen.gd:794-828).
## Config can arrive before _ready() as well as after.
func apply_grid_config(config_data: Dictionary) -> void:
	var before_becoming: String = becoming
	var before_reading: String = reading
	for key in config_data:
		if key == "becoming":
			becoming = _pick(str(config_data[key]), BECOMINGS, becoming)
		elif key == "reading":
			reading = _pick(str(config_data[key]), READINGS, reading)
		elif key in self:
			set(key, config_data[key])
	if not _built:
		return
	if becoming == before_becoming and reading == before_reading:
		return
	_rebuild()
