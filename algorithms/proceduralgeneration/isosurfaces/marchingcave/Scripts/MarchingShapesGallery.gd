extends Node3D

# --- DNA (stage 2, promoted 2026-08-12) -------------------------------------
#
# THE GALLERY'S CLAIM, and the two ways it was only half-made. This artifact
# stands six marching-cubes surfaces in a 3x2 grid and says: an SDF can be any
# thing. Until now it said that about a human, a chair, a house, a bottle, a cup
# and a computer — furniture and crockery — and it said it at exactly one
# threshold. Both halves were hardcoded, and both are the sequence's own truth
# line ("define a field, extract a surface; the boundary between inside and
# outside becomes geometry") sitting in the file as a literal.
#
# repertoire — WHAT THE FIELD IS ASKED TO PROVE IT CAN BE. Line 7 of the old file
#   hardcoded six names and line 11 hardcoded `for i in range(6)` with
#   generator.shape_type = i, while TerrainGeneratorShapes.ShapeType declares
#   THIRTEEN members and MarchingCubesShapes.glsl dispatches all thirteen (id
#   0..12, every branch present in evaluate()). Seven fully implemented objects —
#   microscope, flask, DNA helix, atom, sculpture, sphere, torus — had never been
#   placed in a world. Lifting the roster out of the hardcoded array is
#   csg_compose_workbench's algebra move exactly. Each value is a roster of six
#   shape ids:
#     household    [0,1,2,3,4,5]    SHIPPED. human/chair/house/bottle/cup/computer.
#                                   Term for term what `range(6)` already produced.
#     laboratory   [6,7,8,9,5,0]    microscope/flask/DNA/atom/computer/human —
#                                   apparatus and its operator.
#     abstract     [11,12,10,9,8,7] sphere/torus/sculpture/atom/DNA/flask — things
#                                   that were functions before they were objects.
#     survey       [0,1,6,8,10,12]  one from each register; the only value that
#                                   lets the three claims stand beside each other.
#   The labels are DERIVED from ShapeType, never a second hardcoded list, or the
#   caption would go on saying "Human" over a torus. The derivation is
#   String(key).capitalize(), which reproduces the six shipped captions exactly
#   and renders the acronym member as "Dna" — ugly and honest; a special case for
#   it would have to fire on "CUP" as well and would break the shipped six.
#
# likeness — WHERE YOU PUT THE LINE DECIDES WHETHER THE THING IS STILL ITSELF.
#   The old line 25 set iso_level = 0.0 on all six generators, and 0.0 on a signed
#   distance field IS the surface. Move it and every object dilates or erodes
#   uniformly. The numbers are read off the shader's own literals against the
#   sampling scale: chunk_scale 120 over num_voxels_per_axis 64 is a cell of 1.875
#   SDF units, so a shift of a few units is a real change and not a re-quantisation.
#     exact    0.0   SHIPPED, and a short-circuit — the literal 0.0, not a lookup
#                    that happens to land on it.
#     broken  -2.0   chair legs (sdBox half-extent 2), the cup handle (sdTorus
#                    minor radius 0.8), the human's arms (sdCapsule radius 2.5) and
#                    the monitor stand (half-extent 3) are all thinner than the
#                    erosion and vanish. What is left is seats, torsos and slabs:
#                    six things, no longer six nameable things.
#     padded  +4.0   everything swells, the cup's subtracted bore fills in, the
#                    objects go soft but stay identifiable.
#     fused  +10.0   the chair's legs are 20 units apart and each dilates by 10, so
#                    the gaps close and the chair becomes one rounded block. The
#                    object dissolves back into the field it came from — the
#                    sequence truth line run backwards, on purpose.
#   The value shipped is named `exact` and not `true`: "true" survives
#   cabinet_sweep.coerce() as a PYTHON BOOLEAN, which would be handed to a
#   String-typed property as `true` and silently refused, and would tag its frame
#   `likeness-True` against a registry that says "true". A value name that the
#   harness rewrites on the way in is the science_screen fault wearing a new hat.
#
# WHAT IS DECLINED. `spacing` and `shape_scale`, this artifact's only two previous
# exports, stay plain exports. Both are pure magnitudes that SELF-CANCEL under an
# AABB-fitted capture camera — a gallery spread twice as wide is photographed from
# twice as far and looks identical — which is what grabbable_line's promotion
# recorded when its length and thickness were demoted. No time-domain axis was
# available to refuse: this is the one artifact of the six in `isosurfaces` with no
# _process and no clock, because TerrainGeneratorBase calls set_process(false) once
# the first mesh exists. Also refused: invert_faces (a winding flag — it changes
# shading, not form) and the six per-shape hues (colour, not argument). The hue is
# taken from the SLOT index and not the shape id, so it stays a property of where a
# thing stands in the grid rather than of what it is.

## Roster per repertoire: six TerrainGeneratorShapes.ShapeType ids, in grid order.
const ROSTERS: Dictionary = {
	"household": [0, 1, 2, 3, 4, 5],
	"laboratory": [6, 7, 8, 9, 5, 0],
	"abstract": [11, 12, 10, 9, 8, 7],
	"survey": [0, 1, 6, 8, 10, 12],
}

## iso_level per likeness, in SDF units. See the header for where each comes from.
const ISO_LEVELS: Dictionary = {
	"exact": 0.0,
	"broken": -2.0,
	"padded": 4.0,
	"fused": 10.0,
}

## Which six objects the field is asked to be.
@export_enum("household", "laboratory", "abstract", "survey") var repertoire: String = "household"
## Where the surface is cut out of the field, and so how much of each object survives.
@export_enum("exact", "broken", "padded", "fused") var likeness: String = "exact"
@export var spacing : float = 4.0  # Meters between shapes
@export var shape_scale : float = 0.025  # Scale down from SDF units to VR meters
## CAPTURE ONLY — see _build_capture_anchor(). Reachable by direct property
## assignment (dna.fixture) and deliberately NOT by a map token: an anchor built
## in a map would change _compute_local_aabb and move every placement.
@export var capture_anchor: String = "off"
## Forwarded to every generator. false is the shipped value and the base class's
## own default, so this changes nothing; it exists so that "Creating fallback
## mesh" in a capture log is unambiguously a device failure and never an opt-in.
@export var use_fallback: bool = false

## The generators' sampling window, hoisted from the literal it was on the old
## line 26 so the capture anchor can be derived from the same number.
const CHUNK_SCALE: float = 120.0
const LABEL_Y: float = 1.5
const LABEL_FONT_SIZE: int = 32
## Ceiling on how far a framed caption reaches above LABEL_Y. LabelFramer sizes a
## plate from get_multiline_string_size().y — the LINE height, identical for every
## single-line caption at this font size — plus PAD_H 0.035 and a 0.03 bezel, so
## about 0.15. The extra is slack, not a measurement.
const LABEL_HEADROOM: float = 0.25
const SLOTS: int = 6

## Only what THIS script created. The old _exit_tree freed every child without an
## owner, which is also what GridInteractablesComponent's _RotationTimer is.
var _owned: Array[Node] = []
var _built: bool = false


func _ready() -> void:
	_read_metadata_overrides()
	_build()


## Guarded. The old body was a bare `pass`, so neither of this artifact's exports
## was reachable from any map token at all. It now rebuilds when, and only when, a
## value the build reads has actually changed. All 4 placements pass no keys, so
## none of them reaches an assignment and none of them rebuilds.
func apply_grid_config(config_data: Dictionary) -> void:
	var before: String = _config_signature()
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if not _built:
		return
	if _config_signature() == before:
		return
	_free_owned()
	_built = false
	_build()


func _config_signature() -> String:
	return "%s|%s|%.4f|%.4f|%s|%s" % [
		repertoire, likeness, spacing, shape_scale, capture_anchor, str(use_fallback)]


## capture_anchor and use_fallback are deliberately absent here: both are capture
## instruments, and a map token that could reach them would be able to move a
## placement (the anchor) or replace the artifact with six spheres (the fallback).
func _read_metadata_overrides() -> void:
	if has_meta("config_repertoire"):
		var r: String = str(get_meta("config_repertoire")).strip_edges().to_lower()
		if ROSTERS.has(r):
			repertoire = r
	if has_meta("config_likeness"):
		var k: String = str(get_meta("config_likeness")).strip_edges().to_lower()
		if ISO_LEVELS.has(k):
			likeness = k
	if has_meta("config_spacing"):
		spacing = float(str(get_meta("config_spacing")))
	if has_meta("config_shape_scale"):
		shape_scale = float(str(get_meta("config_shape_scale")))


# ── The two words resolved ────────────────────────────────────────────────────

## SHORT-CIRCUIT. household hands back the shipped list, which is term for term,
## in the same order, what `for i in range(6): generator.shape_type = i` produced.
## An unknown value falls back to it rather than to an empty roster.
func _roster() -> Array:
	if repertoire == "household" or not ROSTERS.has(repertoire):
		return ROSTERS["household"]
	return ROSTERS[repertoire]


## SHORT-CIRCUIT. `exact` returns the literal 0.0 the old line 25 assigned, rather
## than a dictionary lookup that happens to land on the same number.
func _iso_level() -> float:
	if likeness == "exact" or not ISO_LEVELS.has(likeness):
		return 0.0
	return float(ISO_LEVELS[likeness])


## The caption for a shape id, DERIVED from the enum. A second hardcoded name list
## is how a gallery ends up labelling a torus "Human"; the six shipped captions —
## Human, Chair, House, Bottle, Cup, Computer — are exactly capitalize() of the
## first six enum members, so the default is untouched.
func _shape_label(shape_id: int) -> String:
	var names: Array = TerrainGeneratorShapes.ShapeType.keys()
	var ids: Array = TerrainGeneratorShapes.ShapeType.values()
	var idx: int = ids.find(shape_id)
	if idx < 0:
		return "Shape %d" % shape_id
	return str(names[idx]).capitalize()


# ── Build ─────────────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true
	var roster: Array = _roster()
	var iso: float = _iso_level()

	for i in SLOTS:
		# DELIBERATELY UNTYPED. shape_type is an enum-typed property; the old loop
		# fed it `i` out of range(6), which is a Variant, and a Variant assigns to
		# an enum without the INT_AS_ENUM_WITHOUT_CAST warning an `int` local would
		# raise. Same value, same path, no new diagnostic.
		var shape_id = roster[i]
		var shape_name: String = _shape_label(int(shape_id))

		var generator := TerrainGeneratorShapes.new()
		generator.shape_type = shape_id
		generator.name = shape_name

		# Position in a 3x2 grid at ground level, in front of origin
		var col: int = i % 3
		var row: int = int(i / 3)
		var x: float = (col - 1) * spacing
		var z: float = -(row + 1) * spacing  # In front of player

		generator.position = Vector3(x, 0, z)
		generator.scale = Vector3.ONE * shape_scale

		# Settings
		generator.noise_scale = 1.0
		generator.iso_level = iso
		generator.chunk_scale = CHUNK_SCALE
		generator.center_position = Vector3(0, 0, 0)
		generator.invert_faces = true  # View from outside
		generator.use_fallback = use_fallback

		# Non-reflective material. The hue is the SLOT, not the shape — see the
		# declined list in the header.
		var material := StandardMaterial3D.new()
		material.albedo_color = Color.from_hsv(float(i) / 6.0, 0.6, 0.9)
		material.metallic = 0.0
		material.roughness = 1.0
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		generator.material_override = material

		_adopt(generator)

		# Add label
		var label := Label3D.new()
		label.text = shape_name
		label.position = Vector3(x, LABEL_Y, z)
		label.font_size = LABEL_FONT_SIZE
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_adopt(label)

		print("Spawned " + shape_name)

	if capture_anchor == "on":
		_build_capture_anchor()


func _adopt(n: Node) -> void:
	_owned.append(n)
	add_child(n)


## Free ONLY what this script made. Removing before freeing keeps a rebuild from
## colliding names with children that are queued but not yet gone.
func _free_owned() -> void:
	for n in _owned:
		if is_instance_valid(n):
			if n.get_parent() == self:
				remove_child(n)
			n.queue_free()
	_owned.clear()


func _exit_tree() -> void:
	_free_owned()


# ── The measured box ──────────────────────────────────────────────────────────

## Stand an INVISIBLE box (layers = 0, so it renders nothing and casts nothing)
## around the SAMPLING DOMAIN — not around this variant's geometry.
##
## WHY IT IS A CEILING AND NOT AN ENVELOPE. MarchingCubesShapes.glsl evaluates at
## worldPos = (coord / numVoxelsPerAxis - 0.5) * scale, so no vertex any generator
## can emit lies outside +/- chunk_scale/2 of its own origin — 1.5 m after the
## 0.025 shape_scale. A box over the whole 3x2 field of those domains is therefore
## an exact upper bound on the merged AABB for EVERY value of both axes, which
## makes the sweep's fixed-camera union identical between values, between partial
## sweeps, and between runs. An anchor sized to the shipped six objects instead
## would not be a bound at all: `fused` dilates every mesh by 10 SDF units and
## would push straight through it, and the camera would retreat for one value of
## one axis — the frame-relative comparison that made example_1_3's `flip` measure
## 12.8% against a 0.045% for the two figures it actually differs from.
##
## The top is raised to LABEL_Y + LABEL_HEADROOM because LabelFramer turns each
## caption into an opaque plate at spawn and that plate reaches above the domain.
## Its HEIGHT does not vary with the caption (LabelFramer measures the line box,
## not the glyphs), so covering it keeps the bound constant rather than merely
## larger.
##
## WHY IT IS GATED OFF. GridInteractablesComponent._compute_local_aabb walks
## MeshInstance3D regardless of its render layers and hands the result to
## _auto_ground_artifact, which lifts the artifact by its own min_y. This entry
## carries no auto_ground:false, so an anchor built in a map would raise all four
## placements by the difference between the domain floor (-1.5) and the deepest
## real mesh. capture_anchor defaults to "off" and is not read from config
## metadata, so no map token can build this node.
func _build_capture_anchor() -> void:
	var half: float = CHUNK_SCALE * shape_scale * 0.5
	var lo := Vector3(-spacing - half, -half, -2.0 * spacing - half)
	var hi := Vector3(spacing + half, LABEL_Y + LABEL_HEADROOM, -spacing + half)
	var anchor := MeshInstance3D.new()
	anchor.name = "CaptureAnchor"
	var bm := BoxMesh.new()
	bm.size = hi - lo
	anchor.mesh = bm
	anchor.position = (lo + hi) * 0.5
	# layers = 0, never visible = false: Godot visibility is hierarchical and the
	# render-layer mask is per-instance, so this leaves the AABB walk untouched.
	anchor.layers = 0
	_adopt(anchor)
