# Edge as Ground Capstone — the spine's literal last artifact
#
# A raised central platform. Around it: seven stations arranged in a ring, each station
# a small pedestal with a glowing emblem recalling one prior map of the postfoundation
# sequence:
#   1. bias_visualizer        → the limit
#   2. ethical_design         → ethics is shape
#   3. paraconsistent_engine  → hold contradiction
#   4. situated_compute       → knowledge has a body
#   5. collective_knowledge   → the commons
#   6. rhizome                → no hierarchy
#   7. molecular_design       → embodied formalism
#
# At the center: a slowly rotating thick disc of glass with the spine's final sentence
# inscribed: "The edge is the ground."
#
# The whole composition is the curriculum's argument made architectural. The player has
# walked everything. Now they stand at the spine's terminus and the rim recalls their
# journey. The capstone IS the closing of the thesis arc.
#
# STAGE-2 DNA. This is the only environment-sized object in its promotion cohort, and it
# holds two genuinely independent questions: what the RIM recalls, and what stands at the
# MIDDLE. Before this pass a map could vary exactly one thing — how far away the seven
# stations sat (`ring_radius`) — so the rim always closed and the sentence was always cast
# in one unbroken plate. A capstone whose sequence truth is "knowing the limits of
# formalization" rendered the most complete object in the project at the end of the
# argument against completeness. `rim:gapped` and `assertion:shards` let a map say the
# honest version. The defaults `closed` / `disc` rebuild the shipped look exactly.
#
# @identity: Final artifact in the spine.
# @qfep_term: All — the formula's argument landed as architecture.

extends Node3D
class_name EdgeAsGroundCapstone

@export var platform_color: Color = Color(0.18, 0.2, 0.26, 1.0)
@export var station_color: Color = Color(0.95, 0.85, 0.55, 1.0)
@export var center_color: Color = Color(0.7, 0.95, 0.95, 1.0)
@export var ring_radius: float = 1.6
@export var platform_radius: float = 0.7
@export var rotation_speed: float = 0.2

## RIM — whether the ring of recalled stations closes, and how near it presses.
##
## Worth varying because the rim IS the recollection: a closed seven-fold circle claims
## the walk was complete and evenly weighted, which is a claim this sequence spends every
## map disputing. `gapped` withholds one station and leaves its broken stump in the slot,
## so the absence is visible AS an absence rather than as a six-station ring nobody can
## count wrong. `arc` throws the whole memory onto the front half and leaves the back bare
## — the past is in front of you, not around you. `crowded` presses the stations in until
## they nearly touch the platform and lean over the sentence, so the recollection crowds
## the assertion instead of framing it. Every value moves seven objects by tens of
## centimetres or removes one outright; all four read from across the room.
@export_enum("closed", "gapped", "arc", "crowded") var rim: String = "closed"

## ASSERTION — what form the spine's final sentence takes at the middle of the platform.
##
## Worth varying because the centre is where the artifact states its conclusion, and the
## form of the statement is an argument in itself. `disc` is one whole plate: the thesis
## as a single finished surface. `void` removes it and cuts the platform through — the
## sentence hangs over a hole, asserted with nothing under it. `cairn` restacks it as five
## rough rotated blocks 1.15 m high: a conclusion piled up by hand, not cast. `shards`
## cuts the plate into its seven wedges and lets daylight run between them. The silhouette
## at the middle of the platform changes completely between all four.
@export_enum("disc", "void", "cairn", "shards") var assertion: String = "disc"

const RIMS: PackedStringArray = ["closed", "gapped", "arc", "crowded"]
const ASSERTIONS: PackedStringArray = ["disc", "void", "cairn", "shards"]

# ── rim:gapped ──
## Which of the seven slots stands empty. The seventh — `molecular`, the last thing walked
## and the most confident claim in the sequence — is the one withheld.
const GAP_SLOT: int = 6
const STUMP_HEIGHT: float = 0.15

# ── rim:arc ──
## 30° between stations, seven of them, so the run spans exactly 180° across the front
## (+Z) and the rear half of the circle is left as bare floor.
const ARC_STEP_DEG: float = 30.0

# ── rim:crowded ──
const CROWD_RADIUS: float = 0.85
const CROWD_PEDESTAL_H: float = 0.45
const CROWD_TILT_DEG: float = 12.0
## Extra inward offset on the emblem so the leaning heads actually overhang the disc
## (0.595 m) rather than stopping politely at the platform lip.
const CROWD_EMBLEM_LEAN: float = 0.12

# ── assertion:void ──
## A 0.30 m inner radius cut clean through the platform's full 0.4 m depth. Big enough to
# read as a hole from standing height, not as a drain.
const VOID_INNER_RADIUS: float = 0.30
const RING_SEGMENTS: int = 48

# ── assertion:cairn ──
## Five rough blocks, widest at the bottom, each turned ~18° off the one below.
const CAIRN_SIDES: PackedFloat32Array = [0.44, 0.38, 0.31, 0.24, 0.16]
const CAIRN_TOP_Y: float = 1.15
const CAIRN_TWIST_DEG: float = 18.0

# ── assertion:shards ──
const SHARD_COUNT: int = 7
const SHARD_LOW_Y: float = 0.40
const SHARD_HIGH_Y: float = 0.85
const SHARD_TILT_MIN_DEG: float = 6.0
const SHARD_TILT_MAX_DEG: float = 14.0
const SHARD_SPLAY: float = 0.10

# Each station: emblem-color, glyph (Label3D text), title
var _stations := [
	{"color": Color(1.0, 0.45, 0.4, 1.0), "title": "limit",          "emblem": "≠"},
	{"color": Color(0.85, 0.7, 0.4, 1.0),  "title": "ethics",         "emblem": "▢"},
	{"color": Color(0.95, 0.85, 0.3, 1.0), "title": "contradiction",  "emblem": "⊥"},
	{"color": Color(0.6, 0.95, 0.65, 1.0), "title": "situated",       "emblem": "⊕"},
	{"color": Color(0.7, 0.95, 0.85, 1.0), "title": "commons",        "emblem": "∞"},
	{"color": Color(0.55, 0.7, 0.95, 1.0), "title": "rhizome",        "emblem": "⌘"},
	{"color": Color(0.85, 0.55, 0.95, 1.0), "title": "molecular",      "emblem": "Φ"},
]
var _center_disc: MeshInstance3D
## Whatever the middle turns slowly — the disc, or the splayed shard group. `void` and
## `cairn` have nothing that turns and leave this null.
var _spin: Node3D
var _t: float = 0.0

## Exactly the nodes this script put in the tree. A rebuild frees these and only these —
## the grid system adds its own children after _ready (framed label plates, packaging,
## tag markers, grounding helpers) and those must survive.
var _owned: Array[Node] = []
## False until _ready has built once. apply_grid_config runs BEFORE _ready on the normal
## grid path (GridInteractablesComponent configures the artifact, then add_child's it), so
## a config arriving early must only set values and let _ready do the one build.
var _built: bool = false


func _ready() -> void:
	_build_all()
	_built = true


func _build_all() -> void:
	_build_platform()
	_build_stations()
	_build_assertion()
	_build_central_inscription()


## Every node this script builds goes through here, so a rebuild can free precisely what
## it made.
func _own(node: Node) -> void:
	add_child(node)
	_owned.append(node)


# ═══════════════════════════════════════════════════════════════════
# GRID CONFIG INTEGRATION
# ═══════════════════════════════════════════════════════════════════

func apply_grid_config(config_data: Dictionary) -> void:
	var before_rim: String = rim
	var before_assertion: String = assertion
	var before_ring_radius: float = ring_radius

	# `ring_radius` used to be silently inert — it set the var and never rebuilt. It is
	# live now, and it counts as a geometric change like the two axes do.
	if config_data.has("ring_radius"):
		ring_radius = float(config_data["ring_radius"])

	# Stage-2 DNA axes — #rim:gapped, #assertion:shards
	if config_data.has("rim"):
		rim = _pick_axis(str(config_data["rim"]), RIMS, rim)
	if config_data.has("assertion"):
		assertion = _pick_axis(str(config_data["assertion"]), ASSERTIONS, assertion)

	if not _built:
		return
	if rim == before_rim and assertion == before_assertion \
			and is_equal_approx(ring_radius, before_ring_radius):
		return
	_rebuild_now()
	print("[EdgeAsGroundCapstone] Config applied — rim=%s, assertion=%s, ring_radius=%.2f" % [
		rim, assertion, ring_radius])


## Accept an axis value only if it names something we actually build. A typo in a map
## token has to land on the legacy look — a half-recognised value would strand a shipped
## placement with no rim or no centre at all.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## Free what this script built and build it again from the resolved axis values, all in
## this call. Nodes leave the tree synchronously before queue_free so two rims never stand
## on top of each other; the rebuild is synchronous too, so the grid's grounding pass
## measures a real AABB and the label framer's work is not undone behind its back.
func _rebuild_now() -> void:
	_center_disc = null
	_spin = null
	for c in _owned:
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_owned.clear()
	_build_all()


func _process(delta: float) -> void:
	_t += delta * rotation_speed
	if is_instance_valid(_spin):
		_spin.rotation.y = _t * 0.4


# ═══════════════════════════════════════════════════════════════════
# PLATFORM
# ═══════════════════════════════════════════════════════════════════

func _build_platform() -> void:
	var platform := MeshInstance3D.new()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = platform_color
	mat.metallic = 0.5
	mat.roughness = 0.4
	mat.emission_enabled = true
	mat.emission = platform_color
	mat.emission_energy_multiplier = 0.4

	if assertion == "void":
		# The platform becomes a ring: the same tapered outer profile, bored through its
		# full 0.4 m depth. Nothing stands in the middle — the sentence hangs over the gap.
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		platform.mesh = _make_ring_mesh(
			platform_radius, platform_radius + 0.1, VOID_INNER_RADIUS, 0.4, RING_SEGMENTS)
	else:
		var cyl := CylinderMesh.new()
		cyl.top_radius = platform_radius
		cyl.bottom_radius = platform_radius + 0.1
		cyl.height = 0.4
		platform.mesh = cyl

	platform.material_override = mat
	platform.position.y = 0.2
	_own(platform)


# ═══════════════════════════════════════════════════════════════════
# RIM — the seven recalled stations
# ═══════════════════════════════════════════════════════════════════

func _build_stations() -> void:
	var count: int = _stations.size()
	for i in range(count):
		var station_data: Dictionary = _stations[i]
		if rim == "crowded":
			_build_crowded_station(station_data, _slot_angle(i, count))
		elif rim == "gapped" and i == GAP_SLOT:
			_build_stump(_slot_angle(i, count))
		else:
			_build_upright_station(station_data, _slot_angle(i, count), ring_radius)


## Where slot i sits on the circle. `arc` folds all seven into a 180° run across the
## front (+Z) at 30° spacing; every other value keeps the even 51.4° division.
func _slot_angle(i: int, count: int) -> float:
	if rim == "arc":
		return PI * 0.5 + deg_to_rad(float(i) * ARC_STEP_DEG - 90.0)
	return TAU * float(i) / float(count)


## The shipped station: 0.7 m pedestal, glowing emblem, glyph, title.
func _build_upright_station(station_data: Dictionary, a: float, radius: float) -> void:
	var pos := Vector3(cos(a) * radius, 0, sin(a) * radius)
	# Pedestal.
	var pedestal := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.3, 0.7, 0.3)
	pedestal.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = platform_color
	mat.metallic = 0.4
	mat.roughness = 0.5
	pedestal.material_override = mat
	pedestal.position = pos + Vector3(0, 0.35, 0)
	_own(pedestal)
	_build_station_head(station_data, pos + Vector3(0, 0.85, 0), pos + Vector3(0, 1.1, 0))


## rim:gapped — the seventh slot keeps its footprint and loses everything else. A 0.15 m
## snapped-off remnant, tilted where it broke: no emblem, no glyph, no title. The station
## is missing and the ring shows you WHERE it is missing.
func _build_stump(a: float) -> void:
	var pos := Vector3(cos(a) * ring_radius, 0, sin(a) * ring_radius)
	var stump := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.3, STUMP_HEIGHT, 0.3)
	stump.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = platform_color.darkened(0.25)
	mat.metallic = 0.3
	mat.roughness = 0.8
	stump.material_override = mat
	var lean := Basis(Vector3(0.7, 0.0, 0.7).normalized(), deg_to_rad(7.0))
	stump.transform = Transform3D(lean, pos + Vector3(0, STUMP_HEIGHT * 0.5, 0))
	_own(stump)


## rim:crowded — the station moves in to 0.85 m, drops to 0.45 m, and leans 12° toward
## the middle so its emblem hangs out over the disc.
func _build_crowded_station(station_data: Dictionary, a: float) -> void:
	var ground := Vector3(cos(a) * CROWD_RADIUS, 0, sin(a) * CROWD_RADIUS)
	var inward := Vector3(-cos(a), 0, -sin(a))
	var axis: Vector3 = Vector3.UP.cross(inward).normalized()
	var tilt: Basis = Basis(axis, deg_to_rad(CROWD_TILT_DEG))

	var pedestal := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.3, CROWD_PEDESTAL_H, 0.3)
	pedestal.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = platform_color
	mat.metallic = 0.4
	mat.roughness = 0.5
	pedestal.material_override = mat
	pedestal.transform = Transform3D(tilt, ground + tilt * Vector3(0, CROWD_PEDESTAL_H * 0.5, 0))
	_own(pedestal)

	var head: Vector3 = ground + tilt * Vector3(0, CROWD_PEDESTAL_H + 0.17, 0) \
		+ inward * CROWD_EMBLEM_LEAN
	_build_station_head(station_data, head, head + Vector3(0, 0.25, 0))


## Emblem sphere + glyph + title, wherever the rim has put the head.
func _build_station_head(station_data: Dictionary, head: Vector3, title_pos: Vector3) -> void:
	var emblem_glow := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.12
	s.height = 0.24
	emblem_glow.mesh = s
	var emat := StandardMaterial3D.new()
	emat.albedo_color = station_data["color"]
	emat.emission_enabled = true
	emat.emission = station_data["color"]
	emat.emission_energy_multiplier = 2.0
	emblem_glow.material_override = emat
	emblem_glow.position = head
	_own(emblem_glow)
	# Glyph label on emblem.
	var glyph := Label3D.new()
	glyph.text = station_data["emblem"]
	glyph.font_size = 36
	glyph.outline_size = 6
	glyph.modulate = Color(0.1, 0.1, 0.13, 1.0)
	glyph.position = head + Vector3(0, 0, 0.13)
	glyph.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_own(glyph)
	# Title.
	var title := Label3D.new()
	title.text = station_data["title"]
	title.font_size = 20
	title.outline_size = 4
	title.modulate = station_data["color"]
	title.position = title_pos
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_own(title)


# ═══════════════════════════════════════════════════════════════════
# ASSERTION — what stands at the middle
# ═══════════════════════════════════════════════════════════════════

func _build_assertion() -> void:
	match assertion:
		"void":
			pass  # The hole in the platform IS the assertion. Nothing is built here.
		"cairn":
			_build_cairn()
		"shards":
			_build_shards()
		_:
			_build_center_disc()


func _build_center_disc() -> void:
	_center_disc = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = platform_radius * 0.85
	cyl.bottom_radius = platform_radius * 0.85
	cyl.height = 0.05
	_center_disc.mesh = cyl
	_center_disc.material_override = _glass_material()
	_center_disc.position.y = 0.45
	_own(_center_disc)
	_spin = _center_disc


## assertion:cairn — the sentence is not cast, it is piled. Five rough blocks from 0.44 m
## down to 0.16 m, each turned 18° off the one below, standing on the platform top and
## reaching y 1.15. Heights are apportioned from the sides so the stack reads as slabs.
func _build_cairn() -> void:
	var base_y: float = 0.4
	var span: float = CAIRN_TOP_Y - base_y
	var side_sum: float = 0.0
	for i in range(CAIRN_SIDES.size()):
		side_sum += CAIRN_SIDES[i]
	var y: float = base_y
	for i in range(CAIRN_SIDES.size()):
		var side: float = CAIRN_SIDES[i]
		var h: float = span * side / side_sum
		var block := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(side, h, side)
		block.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = center_color.darkened(0.15 + 0.05 * float(i))
		mat.metallic = 0.25
		mat.roughness = 0.75
		mat.emission_enabled = true
		mat.emission = center_color
		mat.emission_energy_multiplier = 0.25
		block.material_override = mat
		var twist: Basis = Basis(Vector3.UP, deg_to_rad(CAIRN_TWIST_DEG * float(i)))
		block.transform = Transform3D(twist, Vector3(0, y + h * 0.5, 0))
		_own(block)
		y += h


## assertion:shards — the same plate, cut into its seven wedges. Each takes its own
## height between 0.40 and 0.85, its own tilt between 6° and 14°, and is pushed 0.10 m
## out along its own bisector so daylight runs between them.
func _build_shards() -> void:
	_spin = Node3D.new()
	_own(_spin)
	var radius: float = platform_radius * 0.85
	var sweep: float = TAU / float(SHARD_COUNT)
	for i in range(SHARD_COUNT):
		var f: float = float(i) / float(SHARD_COUNT - 1)
		var a0: float = sweep * float(i)
		var mid: float = a0 + sweep * 0.5
		var shard := MeshInstance3D.new()
		shard.mesh = _make_wedge_mesh(radius, 0.05, a0, sweep, 8)
		var mat: StandardMaterial3D = _glass_material()
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		shard.material_override = mat
		var tilt_deg: float = lerp(SHARD_TILT_MIN_DEG, SHARD_TILT_MAX_DEG, f)
		# Tilt about the tangent at the bisector, so the outer edge lifts or drops.
		var axis := Vector3(-sin(mid), 0.0, cos(mid))
		var tilt: Basis = Basis(axis, deg_to_rad(tilt_deg) * (1.0 if i % 2 == 0 else -1.0))
		var y: float = lerp(SHARD_LOW_Y, SHARD_HIGH_Y, f)
		var splay := Vector3(cos(mid), 0.0, sin(mid)) * SHARD_SPLAY
		shard.transform = Transform3D(tilt, splay + Vector3(0, y, 0))
		_spin.add_child(shard)


func _glass_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = center_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.4
	mat.metallic = 0.7
	mat.roughness = 0.1
	mat.emission_enabled = true
	mat.emission = center_color
	mat.emission_energy_multiplier = 0.8
	return mat


func _build_central_inscription() -> void:
	# The sentence sits above whatever the middle turned out to be.
	var y: float = 0.65
	match assertion:
		"cairn":
			y = 1.35
		"shards":
			y = 1.05
	var inscription := Label3D.new()
	inscription.text = "The edge is the ground."
	inscription.font_size = 38
	inscription.outline_size = 8
	inscription.modulate = center_color
	inscription.position = Vector3(0, y, 0)
	inscription.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_own(inscription)
	# Subtitle: the spine's terminus.
	var sub := Label3D.new()
	sub.text = "F − λE(S) + φΔE(S,t)"
	sub.font_size = 20
	sub.outline_size = 5
	sub.modulate = Color(0.8, 0.85, 0.95, 1.0)
	sub.position = Vector3(0, y - 0.15, 0)
	sub.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_own(sub)


# ═══════════════════════════════════════════════════════════════════
# PROCEDURAL MESHES
# ═══════════════════════════════════════════════════════════════════

## A tapered annulus prism — the platform with a hole through it.
func _make_ring_mesh(outer_top: float, outer_bottom: float, inner_r: float,
		height: float, segs: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half: float = height * 0.5
	for i in range(segs):
		var a0: float = TAU * float(i) / float(segs)
		var a1: float = TAU * float(i + 1) / float(segs)
		var c0 := Vector2(cos(a0), sin(a0))
		var c1 := Vector2(cos(a1), sin(a1))
		var ot0 := Vector3(c0.x * outer_top, half, c0.y * outer_top)
		var ot1 := Vector3(c1.x * outer_top, half, c1.y * outer_top)
		var it0 := Vector3(c0.x * inner_r, half, c0.y * inner_r)
		var it1 := Vector3(c1.x * inner_r, half, c1.y * inner_r)
		var ob0 := Vector3(c0.x * outer_bottom, -half, c0.y * outer_bottom)
		var ob1 := Vector3(c1.x * outer_bottom, -half, c1.y * outer_bottom)
		var ib0 := Vector3(c0.x * inner_r, -half, c0.y * inner_r)
		var ib1 := Vector3(c1.x * inner_r, -half, c1.y * inner_r)
		# Top annulus face.
		_tri(st, it0, ot0, ot1)
		_tri(st, it0, ot1, it1)
		# Bottom annulus face.
		_tri(st, ib1, ob1, ob0)
		_tri(st, ib1, ob0, ib0)
		# Outer wall.
		_tri(st, ot0, ob0, ob1)
		_tri(st, ot0, ob1, ot1)
		# Inner wall — the bore.
		_tri(st, it1, ib1, ib0)
		_tri(st, it1, ib0, it0)
	st.generate_normals()
	return st.commit()


## One pie-slice prism of the centre plate, spanning [a0, a0 + sweep] with its apex at
## the origin, so a whole set of them reassembles the disc exactly.
func _make_wedge_mesh(radius: float, thickness: float, a0: float, sweep: float,
		segs: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half: float = thickness * 0.5
	var apex_top := Vector3(0, half, 0)
	var apex_bot := Vector3(0, -half, 0)
	for i in range(segs):
		var b0: float = a0 + sweep * float(i) / float(segs)
		var b1: float = a0 + sweep * float(i + 1) / float(segs)
		var t0 := Vector3(cos(b0) * radius, half, sin(b0) * radius)
		var t1 := Vector3(cos(b1) * radius, half, sin(b1) * radius)
		var u0 := Vector3(cos(b0) * radius, -half, sin(b0) * radius)
		var u1 := Vector3(cos(b1) * radius, -half, sin(b1) * radius)
		_tri(st, apex_top, t0, t1)
		_tri(st, apex_bot, u1, u0)
		_tri(st, t0, u0, u1)
		_tri(st, t0, u1, t1)
	# The two straight cut faces, so the wedge reads as cut and not as a sliver.
	var e0 := Vector3(cos(a0) * radius, 0, sin(a0) * radius)
	var e1 := Vector3(cos(a0 + sweep) * radius, 0, sin(a0 + sweep) * radius)
	_tri(st, apex_top, apex_bot, e0 + Vector3(0, -half, 0))
	_tri(st, apex_top, e0 + Vector3(0, -half, 0), e0 + Vector3(0, half, 0))
	_tri(st, apex_bot, apex_top, e1 + Vector3(0, half, 0))
	_tri(st, apex_bot, e1 + Vector3(0, half, 0), e1 + Vector3(0, -half, 0))
	st.generate_normals()
	return st.commit()


func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)
