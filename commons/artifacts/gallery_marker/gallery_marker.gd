# Gallery Marker — a "you-are-here" sub-gallery anchor placed inside larger sequence maps.
#
# Single cell, procedural. The label is set via `apply_grid_config({"label": "..."})`
# so the same scene serves every `gallery_marker_<sequence>` alias.
#
# STAGE-2 DNA PROMOTION (2026-07-28). The registry entry for this artifact already
# said the quiet part out loud: "only the label FACADE, injected through
# apply_grid_config, distinguishes it from its siblings. You-are-here turns out to
# be a config string, not a geometry." Twenty-one placements, one geometry, twenty-one
# strings. That is a confession, not a description, and `mode` is the answer to it.
#
# `mode` is REUSED VERBATIM from request_note — same word, same level of the grammar,
# same meaning, same four values in the same order. There it already means "the body
# this text-carrying marker has", with the ladder float | plate | stake | decal, and
# gallery_marker as shipped IS request_note's `stake`: a mark on a post that meets the
# floor. So this is one artifact joining an existing family, not founding a synonym.
# The word is fixed to that scope: it names the BODY of a text-carrying MARKER and
# nothing else in this vocabulary may spend it on anything else.
#
# Default `stake` is the pre-promotion look exactly — all 21 placements are untouched.
#
# Usage in map_data.json:
#   "gallery_marker_facade:0:0.5"                  (unchanged — builds the stake)
#   "gallery_marker_facade:0:0.5#mode:decal"       (a mark on the floor instead)

extends Node3D
class_name GalleryMarker

## The BODY this marker has — the one axis, reused verbatim from request_note.
##
##   float  billboard text with no body at all; a word hanging over an empty cell
##   plate  a card the text sits on; the marker acquires a front and a face
##   stake  a mark on a post that MEETS THE FLOOR (the shipped build, default)
##   decal  laid flat on the ground and read by looking down
##
## Worth varying because a signpost's body is its whole claim about where the thing
## it points at is: `float` says "somewhere near here", `stake` says "this spot",
## `decal` says "you are standing on it". Twenty-one maps currently make the same
## claim in the same posture and differ only in a word printed on it.
@export_enum("float", "plate", "stake", "decal") var mode: String = "stake"

@export var label_text: String = "GALLERY"
@export var marker_color: Color = Color(0.78, 0.58, 0.22, 1.0)
@export var stake_height: float = 0.9
@export var pedestal_radius: float = 0.18

## Allow-list. Anything outside it is a typo in a map token and must land back on
## the shipped look rather than strand a placement with no marker at all.
const MODES: PackedStringArray = ["float", "plate", "stake", "decal"]

# plate — a bronze card standing on nothing, lower edge at chest-plate height.
const PLATE_W: float = 0.36
const PLATE_H: float = 0.24
const PLATE_T: float = 0.012
const PLATE_BOTTOM: float = 0.95

# decal — a floor roundel. Wide enough to be a place rather than a plaque, and
# nothing on it stands above 0.02 m, so it is walked over and never walked into.
const DECAL_RADIUS: float = 0.31
const DECAL_THICK: float = 0.015
const DECAL_RING_RADIUS: float = 0.25
const DECAL_RING_INNER: float = 0.235

## Nodes THIS script created. The teardown frees these and only these — grid-added
## label plates, packaging and tag markers are other people's children.
var _spawned: Array[Node] = []
var _label: Label3D = null
var _built: bool = false


func _ready() -> void:
	_build_all()
	_built = true


# ═══════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════

## The height the billboarded label rides at on the shipped build: pedestal top,
## plus the post, plus the gap above it. 0.08 + 0.9 + 0.18 = 1.16 m.
func _label_height() -> float:
	return 0.08 + stake_height + 0.18


func _build_all() -> void:
	match mode:
		"float":
			_build_float()
		"plate":
			_build_plate()
		"decal":
			_build_decal()
		_:
			_build_stake_body()


## LEGACY LINEAGE — pixel-identical to every one of the 21 shipped placements.
## Bronze disc pedestal, tapered emissive post, billboarded label at 1.16 m.
func _build_stake_body() -> void:
	_build_pedestal()
	_build_stake()
	_build_label()


## No body at all: the word alone, in the air, over an empty cell. What a marker
## looks like when it has nothing to stand on and still insists.
func _build_float() -> void:
	_build_label()


## The card. A signpost with a front — bronze, vertical, its lower edge at 0.95 m,
## the label printed on its face rather than turning to follow the viewer.
func _build_plate() -> void:
	var card: MeshInstance3D = MeshInstance3D.new()
	card.name = "Plate"
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(PLATE_W, PLATE_H, PLATE_T)
	card.mesh = box
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = marker_color.darkened(0.25)
	mat.roughness = 0.5
	mat.metallic = 0.55
	card.material_override = mat
	var centre_y: float = PLATE_BOTTOM + PLATE_H * 0.5
	card.position.y = centre_y
	_adopt(card)

	# A thin emissive band along the top edge — the stake's glow, kept in the family
	# so the plate reads as the same object in another body, not a different artifact.
	var band: MeshInstance3D = MeshInstance3D.new()
	band.name = "PlateEdge"
	var bbox: BoxMesh = BoxMesh.new()
	bbox.size = Vector3(PLATE_W, 0.012, PLATE_T + 0.002)
	band.mesh = bbox
	band.material_override = _glow_material()
	band.position = Vector3(0.0, centre_y + PLATE_H * 0.5 - 0.006, 0.0)
	_adopt(band)

	var lbl: Label3D = _make_label()
	lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	lbl.font_size = 32
	lbl.pixel_size = 0.0018
	lbl.width = 190
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.position = Vector3(0.0, centre_y, PLATE_T * 0.5 + 0.002)
	_adopt(lbl)
	_label = lbl


## Laid flat and read from above. A 0.62 m roundel with a ring inlay at 0.5 m,
## the label face-up inside it. You do not look AT this marker, you stand on it.
func _build_decal() -> void:
	var disc: MeshInstance3D = MeshInstance3D.new()
	disc.name = "Roundel"
	var dc: CylinderMesh = CylinderMesh.new()
	dc.top_radius = DECAL_RADIUS
	dc.bottom_radius = DECAL_RADIUS
	dc.height = DECAL_THICK
	dc.radial_segments = 48
	disc.mesh = dc
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = marker_color.darkened(0.4)
	mat.roughness = 0.65
	mat.metallic = 0.4
	disc.material_override = mat
	disc.position.y = DECAL_THICK * 0.5
	_adopt(disc)

	# The inlay ring: an emissive band set into the disc top, then the field filled
	# back in at 0.235 m so what survives is an annulus 0.235–0.25 m.
	var band: MeshInstance3D = MeshInstance3D.new()
	band.name = "RingInlay"
	var bc: CylinderMesh = CylinderMesh.new()
	bc.top_radius = DECAL_RING_RADIUS
	bc.bottom_radius = DECAL_RING_RADIUS
	bc.height = 0.010
	bc.radial_segments = 48
	band.mesh = bc
	band.material_override = _glow_material()
	band.position.y = 0.0145
	_adopt(band)

	var fill: MeshInstance3D = MeshInstance3D.new()
	fill.name = "RingField"
	var fc: CylinderMesh = CylinderMesh.new()
	fc.top_radius = DECAL_RING_INNER
	fc.bottom_radius = DECAL_RING_INNER
	fc.height = 0.010
	fc.radial_segments = 48
	fill.mesh = fc
	var fmat: StandardMaterial3D = StandardMaterial3D.new()
	fmat.albedo_color = marker_color.darkened(0.4)
	fmat.roughness = 0.65
	fmat.metallic = 0.4
	fill.material_override = fmat
	fill.position.y = 0.0135
	_adopt(fill)

	var lbl: Label3D = _make_label()
	lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	lbl.font_size = 32
	lbl.pixel_size = 0.0026
	lbl.width = 180
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# -90 about X lays the text face-up, its top toward -Z. Same rotation
	# request_note's decal uses, so the two read as one gesture.
	lbl.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	lbl.position = Vector3(0.0, 0.0198, 0.0)
	_adopt(lbl)
	_label = lbl


func _build_pedestal() -> void:
	var ped: MeshInstance3D = MeshInstance3D.new()
	ped.name = "Pedestal"
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = pedestal_radius
	cyl.bottom_radius = pedestal_radius + 0.02
	cyl.height = 0.08
	ped.mesh = cyl
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = marker_color.darkened(0.4)
	mat.roughness = 0.65
	mat.metallic = 0.4
	ped.material_override = mat
	ped.position.y = 0.04
	_adopt(ped)


func _build_stake() -> void:
	var stake: MeshInstance3D = MeshInstance3D.new()
	stake.name = "Stake"
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = 0.015
	cyl.bottom_radius = 0.02
	cyl.height = stake_height
	stake.mesh = cyl
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = marker_color
	mat.emission_enabled = true
	mat.emission = marker_color
	mat.emission_energy_multiplier = 0.9
	stake.material_override = mat
	stake.position.y = 0.08 + stake_height * 0.5
	_adopt(stake)


func _build_label() -> void:
	var lbl: Label3D = _make_label()
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.font_size = 32
	lbl.pixel_size = 0.004
	lbl.position.y = _label_height()
	_adopt(lbl)
	_label = lbl


## The shared label. Kept named "Label3D" because the grid's _update_artifact_labels
## and every existing lookup ask for that name.
func _make_label() -> Label3D:
	var lbl: Label3D = Label3D.new()
	lbl.name = "Label3D"
	lbl.text = label_text
	lbl.outline_size = 6
	lbl.modulate = Color(1.0, 0.95, 0.85)
	lbl.outline_modulate = Color(0.05, 0.05, 0.05)
	return lbl


func _glow_material() -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = marker_color
	mat.emission_enabled = true
	mat.emission = marker_color
	mat.emission_energy_multiplier = 0.9
	return mat


func _adopt(node: Node) -> void:
	add_child(node)
	_spawned.append(node)


# ═══════════════════════════════════════════════════════════════════
# GRID CONFIG INTEGRATION
# ═══════════════════════════════════════════════════════════════════

func apply_grid_config(config_data: Dictionary) -> void:
	var before_mode: String = mode
	var before_color: Color = marker_color

	if config_data.has("mode"):
		mode = _pick_axis(str(config_data["mode"]), MODES, mode)
	if config_data.has("marker_color"):
		marker_color = config_data["marker_color"]
	if config_data.has("label"):
		label_text = String(config_data["label"])

	if not _built:
		# Called before _ready — nothing to tear down, and _build_all will use
		# whatever we just resolved.
		return

	if _label:
		_label.text = label_text

	if mode == before_mode and marker_color == before_color:
		# curation_station's {"emissive": false} lands here for every artifact it
		# curates, one line after it has framed our labels. Rebuilding would throw
		# that framing away and it is never re-applied. Touch nothing, say nothing.
		return

	_rebuild_now()
	print("[GalleryMarker] Config applied — mode=%s" % [mode])


## Accept an axis value only if it names something we actually build. A typo in a
## map token falls back to the shipped look rather than stranding the placement.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## Synchronous, inline. No call_deferred: a deferred rebuild that removes children
## first makes _auto_ground_artifact measure a zero AABB and bail, and the marker
## never gets grounded.
func _rebuild_now() -> void:
	for c in _spawned:
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_spawned.clear()
	_label = null
	_build_all()
