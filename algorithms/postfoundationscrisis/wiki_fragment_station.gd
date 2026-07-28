# Wiki Fragment Station — the commons as response to incompleteness
#
# A round table holds many small paper-thin fragments, each glowing faintly. Each fragment
# carries a partial claim: a half-sentence, a citation, a question without an answer.
# Above the table, the fragments slowly *suggest themselves into* a larger emergent text
# without ever fully resolving — a wiki's living quality, not its frozen page.
#
# The point: the commons does not solve incompleteness; it *holds* it. The encyclopedia
# is a verb, not a noun.
#
# @identity: First map where the player meets shared knowledge as ongoing co-authoring.
# @qfep_term: Edge — collective, not totalized.

extends Node3D
class_name WikiFragmentStation

@export var table_color: Color = Color(0.35, 0.38, 0.45, 1.0)
@export var fragment_color: Color = Color(0.85, 0.95, 0.7, 1.0)
@export var halo_color: Color = Color(0.7, 0.95, 0.85, 1.0)
@export var fragment_count: int = 14
@export var table_radius: float = 0.55

# ═══════════════════════════════════════════════════════════════════
# STAGE-2 DNA AXIS — gathering
# ═══════════════════════════════════════════════════════════════════

## What the partial claims DO: whether they gather, totalize, multiply, or fall off
## the table. Fourteen plates under one halo staged the commons at exactly one scale
## and exactly one state of health, which made the header's claim — that the
## encyclopedia is a verb — unarguable in the worst way: nothing in the room ever
## showed the noun it refuses, or the neglect it survives.
##
##   drift      legacy look. 14 paper-thin plates orbiting the tabletop in one
##              plane, under the translucent halo. The commons holding itself open.
##   bound      the totalized encyclopedia. Every fragment stacked flush into one
##              closed block under an opaque cover plate; no halo at all. This is
##              the noun, built so a map can put the refusal beside the thing refused.
##   swarm      90 fragments in a 0.9 m cloud climbing to head height. The commons
##              at a scale one table cannot hold.
##   scattered  3 left on the table, the rest face-down on the FLOOR in a 1.6 m
##              ring, halo nearly gone. The commons neglected — still there,
##              no longer gathered.
##
## The reads are COUNT and WHERE THEY LIE (tabletop plane / volume / floor). The
## halo rides along; it is not what carries the difference at ten paces.
@export_enum("drift", "bound", "swarm", "scattered") var gathering: String = "drift"

## Allow-list for the axis. Anything outside it lands on the legacy look rather
## than half-applying — a typo in a map token must never strand a placement with
## a stacked block and a missing halo.
const GATHERINGS: PackedStringArray = ["drift", "bound", "swarm", "scattered"]

## Swarm: a fixed 90, not a multiple of fragment_count. The point of the value is
## a count that has outgrown its table, and 90 plates in a 0.9 m sphere is the
## smallest number that reads as a cloud rather than a crowded orbit.
const SWARM_COUNT: int = 90
const SWARM_RADIUS: float = 0.9
const SWARM_Y_LOW: float = 0.9
const SWARM_Y_HIGH: float = 1.5

## Scattered: how many stay up, and how far out the fallen ones lie. 1.6 m puts
## them clear of the 0.55 m tabletop and into the walking floor — the fragments
## are underfoot, which is the whole reading.
const SCATTERED_KEPT: int = 3
const SCATTERED_RING: float = 1.6
const SCATTERED_JITTER: float = 0.14
const FLOOR_Y: float = 0.004

## Bound: the closed block and its lid. 14 plates at 0.003214 m pitch make a
## 0.045 m body; the 0.14 x 0.01 x 0.10 cover overhangs it on every side so the
## silhouette is a sealed object and not a pile.
const BOUND_PITCH: float = 0.003214
const BOUND_COVER_SIZE: Vector3 = Vector3(0.14, 0.01, 0.10)

const FRAGMENT_SIZE: Vector3 = Vector3(0.12, 0.003, 0.08)
const TABLE_TOP_Y: float = 0.875

## Fixed seed for every jittered position in the build. Two builds of the same
## axis value have to land pixel-identical, otherwise a still-image diff reads
## our own scatter as movement and cannot tell a live axis from a dead one.
const BUILD_SEED: int = 0x57494B49

var _fragments: Array = []
## Every node THIS script parented. Rebuild frees only these — label plates,
## packaging and tags added by the grid system are not ours to destroy.
var _owned: Array[Node] = []
var _halo: MeshInstance3D
var _t: float = 0.0
var _built: bool = false
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_build_all()
	_built = true


func _build_all() -> void:
	_rng.seed = BUILD_SEED
	_build_table()
	_build_fragments()
	_build_halo()
	_build_label()


## Parent a node and remember it, so a later rebuild can take back exactly what
## this script put in and nothing else.
func _add_owned(node: Node) -> void:
	add_child(node)
	_owned.append(node)


func apply_grid_config(config_data: Dictionary) -> void:
	var before_gathering: String = gathering
	var before_count: int = fragment_count
	var before_radius: float = table_radius

	# Stage-2 DNA axis — #gathering:bound
	if config_data.has("gathering"):
		gathering = _pick_axis(str(config_data["gathering"]), GATHERINGS, gathering)

	# On the grid path this runs BEFORE _ready(): nothing is built yet, so there is
	# nothing to rebuild — _ready will build with the values just resolved.
	if not _built:
		return
	# Curation and other post-build callers pass configs that say nothing about
	# geometry (e.g. {"emissive": false}). Rebuilding on those would throw away the
	# label framing applied moments earlier and silently re-stage a shipped map.
	if (gathering == before_gathering
			and fragment_count == before_count
			and is_equal_approx(table_radius, before_radius)):
		return
	_rebuild_now()
	print("[WikiFragmentStation] Config applied — gathering=%s, fragments=%d" % [
		gathering, _planned_fragment_count()])


## Accept an axis value only if it names something we actually build. A typo in a
## map token has to fall back to the legacy look — a half-recognised value would
## leave the station in a state no author asked for.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## Reported in the config log. The rebuild is synchronous, so by the time the line
## prints this is also the count standing on the table.
func _planned_fragment_count() -> int:
	if gathering == "swarm":
		return SWARM_COUNT
	return fragment_count


## Synchronous teardown and rebuild. remove_child() takes the old nodes out of the
## tree in this same frame, so there is never a moment with two stations drawn, and
## the fresh geometry exists before this function returns — nothing downstream
## (grounding, label framing) ever measures an empty node.
func _rebuild_now() -> void:
	for child in _owned:
		if is_instance_valid(child):
			remove_child(child)
			child.queue_free()
	_owned.clear()
	_fragments.clear()
	_halo = null
	_build_all()


func _process(delta: float) -> void:
	_t += delta
	# Fragments drift gently around the table center. Entries flagged otherwise
	# stay exactly where they were placed — a bound block that slowly unstacked
	# itself, or floor litter creeping in a circle, would undo the value.
	for i in _fragments.size():
		var entry: Dictionary = _fragments[i]
		if not bool(entry.get("drift", true)):
			continue
		var frag: MeshInstance3D = entry["node"]
		var base_a: float = entry["angle"]
		var a: float = base_a + _t * 0.1
		frag.position.x = cos(a) * entry["r"]
		frag.position.z = sin(a) * entry["r"]
		frag.rotation.y = -a
	# Halo pulses.
	if is_instance_valid(_halo):
		var mat := _halo.material_override as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = 0.6 + 0.4 * sin(_t * 1.2)


func _build_table() -> void:
	var table := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = table_radius
	cyl.bottom_radius = table_radius
	cyl.height = 0.05
	table.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = table_color
	mat.roughness = 0.7
	table.material_override = mat
	table.position.y = 0.85
	_add_owned(table)
	# Stand.
	var stand := MeshInstance3D.new()
	var s_cyl := CylinderMesh.new()
	s_cyl.top_radius = 0.06
	s_cyl.bottom_radius = 0.18
	s_cyl.height = 0.85
	stand.mesh = s_cyl
	stand.material_override = mat
	stand.position.y = 0.425
	_add_owned(stand)


func _build_fragments() -> void:
	match gathering:
		"bound":
			_build_fragments_bound()
		"swarm":
			_build_fragments_swarm()
		"scattered":
			_build_fragments_scattered()
		_:
			_build_fragments_drift()


## Legacy look, untouched: one plane of plates orbiting between r 0.18 and
## r table_radius - 0.08, at 0.92-0.96 m.
func _build_fragments_drift() -> void:
	for i in fragment_count:
		var a: float = TAU * float(i) / float(fragment_count) + _rng.randf() * 0.2
		var r: float = _rng.randf_range(0.18, table_radius - 0.08)
		var frag: MeshInstance3D = _make_fragment(FRAGMENT_SIZE, 0.85)
		frag.position = Vector3(cos(a) * r, 0.92 + _rng.randf() * 0.04, sin(a) * r)
		_add_owned(frag)
		_fragments.append({"node": frag, "angle": a, "r": r, "drift": true})


## The encyclopedia as a noun. Every claim in the room compressed into one closed
## body at the table's centre, lidded, unreadable, and stationary.
func _build_fragments_bound() -> void:
	var base_y: float = TABLE_TOP_Y + 0.0015
	for i in fragment_count:
		var frag: MeshInstance3D = _make_fragment(FRAGMENT_SIZE, 1.0)
		frag.position = Vector3(0.0, base_y + float(i) * BOUND_PITCH, 0.0)
		_add_owned(frag)
		_fragments.append({"node": frag, "angle": 0.0, "r": 0.0, "drift": false})
	var block_top: float = base_y + float(max(fragment_count - 1, 0)) * BOUND_PITCH
	# Opaque cover plate — the seal, wider than the body it closes.
	var cover := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = BOUND_COVER_SIZE
	cover.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = table_color
	mat.roughness = 0.45
	cover.material_override = mat
	cover.position = Vector3(0.0, block_top + 0.0015 + BOUND_COVER_SIZE.y * 0.5, 0.0)
	_add_owned(cover)


## The commons at a scale the table cannot hold: 90 plates through a 0.9 m volume
## climbing from the tabletop to head height, so the still reads as depth rather
## than as a disc.
func _build_fragments_swarm() -> void:
	for i in SWARM_COUNT:
		var a: float = TAU * float(i) / float(SWARM_COUNT) * 5.0 + _rng.randf() * 0.4
		var r: float = _rng.randf_range(0.18, SWARM_RADIUS)
		var frag: MeshInstance3D = _make_fragment(FRAGMENT_SIZE, 0.85)
		frag.position = Vector3(
			cos(a) * r, _rng.randf_range(SWARM_Y_LOW, SWARM_Y_HIGH), sin(a) * r)
		frag.rotation.x = _rng.randf_range(-0.5, 0.5)
		frag.rotation.z = _rng.randf_range(-0.5, 0.5)
		_add_owned(frag)
		_fragments.append({"node": frag, "angle": a, "r": r, "drift": true})


## The commons neglected. Three claims still circling, the rest face-down on the
## floor in a wide ring — present, unread, no longer gathered.
func _build_fragments_scattered() -> void:
	var kept: int = min(SCATTERED_KEPT, fragment_count)
	for i in kept:
		var a: float = TAU * float(i) / float(kept) + _rng.randf() * 0.2
		var r: float = _rng.randf_range(0.18, table_radius - 0.08)
		var frag: MeshInstance3D = _make_fragment(FRAGMENT_SIZE, 0.85)
		frag.position = Vector3(cos(a) * r, 0.92 + _rng.randf() * 0.04, sin(a) * r)
		_add_owned(frag)
		_fragments.append({"node": frag, "angle": a, "r": r, "drift": true})
	var fallen: int = max(fragment_count - kept, 0)
	for i in fallen:
		var a: float = TAU * float(i) / float(max(fallen, 1)) + _rng.randf_range(-0.15, 0.15)
		var r: float = SCATTERED_RING + _rng.randf_range(-SCATTERED_JITTER, SCATTERED_JITTER)
		var frag: MeshInstance3D = _make_fragment(FRAGMENT_SIZE, 0.55)
		frag.position = Vector3(cos(a) * r, FLOOR_Y, sin(a) * r)
		frag.rotation.y = _rng.randf() * TAU
		_add_owned(frag)
		_fragments.append({"node": frag, "angle": a, "r": r, "drift": false})


func _make_fragment(size: Vector3, alpha: float) -> MeshInstance3D:
	var frag := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	frag.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = fragment_color
	mat.emission_enabled = true
	mat.emission = fragment_color
	mat.emission_energy_multiplier = 1.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = alpha
	frag.material_override = mat
	return frag


func _build_halo() -> void:
	# `bound` builds no halo. The emergent text is exactly what totalizing kills,
	# so its absence is the point rather than an omission.
	if gathering == "bound":
		return
	var radius: float = table_radius * 0.7
	var alpha: float = 0.18
	match gathering:
		"swarm":
			radius = 0.8
		"scattered":
			radius = 0.2
			alpha = 0.05
	_halo = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	_halo.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = halo_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = alpha
	mat.emission_enabled = true
	mat.emission = halo_color
	mat.emission_energy_multiplier = 0.6
	_halo.material_override = mat
	_halo.position.y = 1.2
	_add_owned(_halo)


func _build_label() -> void:
	var label := Label3D.new()
	label.text = "the commons"
	label.font_size = 28
	label.outline_size = 6
	label.modulate = halo_color
	label.position = Vector3(0, 1.7, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_add_owned(label)
