extends Node3D
class_name ExhibitPodium

## Shared parts. The exhibits family deliberately keeps its OWN gallery palette
## (museum stone, dark bases, warm downlight) instead of the hangar's Braun
## sci-fi look, so HangarKit is borrowed only for the two things that are
## palette-neutral WEAR — dust streaks down a face, and the grime band where a
## neglected base meets the floor. Importing more of it would quietly move the
## podium into the maintenance-bay family, which is a different building.
const HangarKit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")
const BakedText = preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: an EMPTY podium — the exhibit affordance itself, before any exhibit. A stone plinth with a soft top light and nothing on it: a promise, a slot, a place where an artifact will one day stand. The gallery-DNA generator plants these to mark hosting capacity. Since the stage-2 promotion it is a FAMILY: `regard` chooses which opinion the architecture is holding (plain / reliquary / didactic / derelict) and `reserve` chooses how the empty volume above the plate is declared (none / armature / ghost / shroud).
# desire: to hold something later — architecture rehearsing its collection.
# critical_parameter: regard — the register of the institution's claim on this spot; reserve — how loudly the absence is announced. Size/height/kind still set proportion.
# triggers: _ready builds plinth + downlight + regard apparatus + reserve declaration; apply_grid_config({height, size, kind, regard, reserve, label, reserve_h}).
# emerges: a room of empty podiums reads as anticipation, not absence — the space is FOR something, visibly. Mix the regards and the room stops being uniform: one spot is sacred, one is catalogued, one has been given up on, and the visitor reads the institution's hierarchy off the furniture alone.
# needs: nothing; pure affordance. No colliders, no triggers — the podium has never been solid and still isn't.
# relationships: the atom of [[gallery_dna]]; sibling of [[exhibit_vitrine]]; the empty half of [[exhibit_furniture]]'s vocabulary; filled later by the Curator or place.py.
# truth: an empty podium is not nothing — it is the architecture's opinion about where meaning should stand. And an opinion has a REGISTER: reverence, instruction, or neglect are all the same box with a different claim attached, which is why the axis had to be the claim and not the box.

## STAGE-2 DNA PROMOTION (2026-07-27).
##
## 226 placements, three exports, one appearance. Before this the only DNA was
## proportion — how big the box is — which is the least interesting thing about
## a podium. The identity block already said what the interesting thing was:
## "the architecture's OPINION about where meaning should stand". An opinion is
## not a size. So the axes were taken from the truth statement instead:
##
##   regard   which opinion is being held    plain · reliquary · didactic · derelict
##   reserve  how the emptiness is declared  none · armature · ghost · shroud
##
## regard="plain" + reserve="none" is the old build, number for number, and it is
## the default — all 226 existing placements are untouched and a visitor cannot
## tell this file changed. Every value on both axes is mass, colour, silhouette
## or light; nothing here animates, because a still is what this project judges by.
##
## What it cost: the podium is no longer only about hosting capacity. A derelict
## podium hosts nothing and says so, which means the artifact can now be used to
## make a room feel abandoned — a rhetorical power the generator did not ask for
## and can misuse. That is the trade, and it is deliberate: an affordance that
## can only ever mean "something good will go here" is a very obedient object.
##
## Usage in map_data.json:
##   "exhibit_podium"                                     (unchanged, legacy)
##   "exhibit_podium#regard:reliquary"
##   "exhibit_podium#regard:didactic#label:UNTITLED"
##   "exhibit_podium#regard:derelict#kind:dais"
##   "exhibit_podium#reserve:ghost"
##   "exhibit_podium#regard:reliquary#reserve:shroud"

@export var plinth_size: float = 0.55
@export var plinth_height: float = 0.95
@export var kind: String = "podium"      # podium | dais
## The register of the architecture's claim on this spot.
@export var regard: String = "plain"     # plain | reliquary | didactic | derelict
## How the reserved volume above the plate is declared.
@export var reserve: String = "none"     # none | armature | ghost | shroud
## The reserved volume's height, for armature/ghost/shroud.
@export var reserve_height: float = 1.05
## Text for the didactic label plate. Newlines split into lines.
@export var label_text: String = ""

## Size classes, sharing exhibit_furniture's plinth dimensions so the two
## artifacts agree about what "s" means. "m" is the legacy default exactly.
const SIZE_CLASSES := {
	"s": Vector2(0.40, 1.15),
	"m": Vector2(0.55, 0.95),
	"l": Vector2(0.85, 0.60),
}

## Every number under "plain" is the old hardcoded value. Do not tidy them into
## rounder figures — they ARE the regression test for the 226 live placements.
const REGARDS := {
	"plain": {
		"body": Color(0.82, 0.80, 0.75), "body_rough": 0.6, "body_metal": 0.0,
		"plate": Color(0.90, 0.88, 0.84), "plate_rough": 0.4, "plate_metal": 0.0,
		"lit": true, "beam": 26.0, "reach": 3.2, "energy": 1.1,
		"light": Color(1.0, 0.97, 0.9),
	},
	# Reverence: a dark polished base so the object floats out of shadow, a gilt
	# lip, a cordon that makes you stand back, and a beam tight enough to be a
	# spotlight rather than room light.
	"reliquary": {
		"body": Color(0.12, 0.11, 0.13), "body_rough": 0.22, "body_metal": 0.12,
		"plate": Color(0.74, 0.57, 0.24), "plate_rough": 0.26, "plate_metal": 0.85,
		"lit": true, "beam": 13.0, "reach": 4.2, "energy": 3.6,
		"light": Color(1.0, 0.92, 0.74),
	},
	# Instruction: the museum's teaching voice. Cool institutional grey, a broad
	# even wash with no drama in it, and a label lectern standing alongside —
	# the apparatus that tells you what to think before you have looked.
	"didactic": {
		"body": Color(0.70, 0.71, 0.74), "body_rough": 0.82, "body_metal": 0.0,
		"plate": Color(0.78, 0.79, 0.82), "plate_rough": 0.72, "plate_metal": 0.0,
		"lit": true, "beam": 37.0, "reach": 4.6, "energy": 1.7,
		"light": Color(0.88, 0.93, 1.0),
	},
	# Withdrawal: the opinion retracted. The fixture is dead, the stone has gone
	# grey and streaked, the plate has slipped, a corner is on the floor. The
	# building used to think meaning belonged here.
	"derelict": {
		"body": Color(0.26, 0.25, 0.23), "body_rough": 0.97, "body_metal": 0.0,
		"plate": Color(0.30, 0.29, 0.27), "plate_rough": 0.95, "plate_metal": 0.0,
		"lit": false, "beam": 26.0, "reach": 3.2, "energy": 0.0,
		"light": Color(1.0, 0.97, 0.9),
	},
}

var _built: bool = false
var _dna: String = ""


func _ready() -> void:
	_read_meta_overrides()
	_rebuild()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_meta_overrides()
	# The grid sets these metas BEFORE add_child and only then calls this
	# deferred, so on the normal path _ready has already built with the right
	# DNA and must NOT build again — a second pass would double every child on
	# all 226 placements. Only a caller that genuinely changes the DNA later
	# (the map-sim live bridge, a cluster re-fit) gets a rebuild.
	if _built and _signature() != _dna:
		_rebuild()


func _read_meta_overrides() -> void:
	if has_meta("config_size"):
		# Maps have been writing #size:s and #size:l since the prop-preview maps
		# were generated, and float("s") is 0.0 — those podiums have been
		# rendering as a degenerate zero-width box with a light over nothing.
		# Numeric tokens still parse exactly as before; only the class names,
		# which produced nothing at all, now resolve.
		var raw: String = str(get_meta("config_size")).strip_edges().to_lower()
		if SIZE_CLASSES.has(raw):
			var dims: Vector2 = SIZE_CLASSES[raw]
			plinth_size = dims.x
			if not has_meta("config_height"):
				plinth_height = dims.y
		else:
			plinth_size = raw.to_float()
	if has_meta("config_height"):
		plinth_height = float(str(get_meta("config_height")))
	if has_meta("config_kind"):
		kind = str(get_meta("config_kind"))
	if has_meta("config_regard"):
		regard = str(get_meta("config_regard")).strip_edges().to_lower()
	if has_meta("config_reserve"):
		reserve = str(get_meta("config_reserve")).strip_edges().to_lower()
	if has_meta("config_reserve_h"):
		reserve_height = float(str(get_meta("config_reserve_h")))
	if has_meta("config_label"):
		label_text = str(get_meta("config_label"))


func _signature() -> String:
	return "%s|%s|%s|%.3f|%.3f|%.3f|%s" % [
		kind, regard, reserve, plinth_size, plinth_height, reserve_height, label_text]


func _rebuild() -> void:
	# Remove before free (a queue_free'd child is still a child this frame and
	# would be counted by the AABB framing the captures use).
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()
	_built = true
	_dna = _signature()


func _build() -> void:
	var s: float = plinth_size
	var h: float = plinth_height
	if kind == "dais":
		s = maxf(s, 1.6)
		h = 0.22

	var r: Dictionary = REGARDS.get(regard, REGARDS["plain"])
	var body_col: Color = r["body"]
	var plate_col: Color = r["plate"]

	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_col
	mat.roughness = float(r["body_rough"])
	mat.metallic = float(r["body_metal"])

	var plinth := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(s, h, s)
	plinth.mesh = bm
	plinth.material_override = mat
	plinth.position = Vector3(0, h * 0.5, 0)
	add_child(plinth)

	# top plate, slightly proud — the surface that waits
	var plate := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(s + 0.06, 0.04, s + 0.06)
	plate.mesh = pm
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = plate_col
	pmat.roughness = float(r["plate_rough"])
	pmat.metallic = float(r["plate_metal"])
	plate.material_override = pmat
	plate.position = Vector3(0, h + 0.02, 0)
	add_child(plate)

	# the waiting light — absent entirely when the regard is derelict, because a
	# dead fixture that still emits is a lit ruin, which is a different claim
	if bool(r["lit"]):
		var light_col: Color = r["light"]
		var light := SpotLight3D.new()
		light.position = Vector3(0, h + 2.4, 0)
		light.rotation_degrees = Vector3(-90, 0, 0)
		light.spot_angle = float(r["beam"])
		light.spot_range = float(r["reach"])
		light.light_energy = float(r["energy"])
		light.light_color = light_col
		add_child(light)

	match regard:
		"reliquary":
			_cordon(s)
		"didactic":
			_lectern(s, h)
		"derelict":
			_withdraw(plate, s, h)

	# The plate's upper face — where the missing thing would rest.
	var top_y: float = h + 0.04
	match reserve:
		"armature":
			_armature(s, top_y)
		"ghost":
			_ghost(s, top_y)
		"shroud":
			_shroud(s, top_y)


# ── regard apparatus ──────────────────────────────────────────────────

## RELIQUARY — the cordon. It is the whole point of this regard: the podium can
## be reverent in its own colours, but only a barrier standing well off the base
## actually changes the visitor's body, and only a barrier reads as reverence
## from across a room. Ropes are built as two sagging segments rather than one
## straight bar, because a taut rope reads as a fence and a slack one as ceremony.
func _cordon(s: float) -> void:
	var brass: StandardMaterial3D = _mat(Color(0.62, 0.48, 0.20), 0.30, 0.85)
	var rope: StandardMaterial3D = _mat(Color(0.42, 0.06, 0.09), 0.92, 0.0)
	var reach: float = maxf(s * 0.5 + 0.62, 0.98)
	var post_h: float = 0.92
	var sxs := PackedFloat32Array([-1.0, 1.0, 1.0, -1.0])
	var szs := PackedFloat32Array([-1.0, -1.0, 1.0, 1.0])
	var tops: Array[Vector3] = []
	for i in range(4):
		var p := Vector3(sxs[i] * reach, 0.0, szs[i] * reach)
		_cyl(0.030, 0.030, post_h, p + Vector3(0, post_h * 0.5, 0), brass, 14)
		# weighted foot, so the post stands rather than sprouts
		_cyl(0.075, 0.110, 0.05, p + Vector3(0, 0.025, 0), brass, 16)
		# ball finial
		var ball := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.045
		sm.height = 0.09
		sm.radial_segments = 12
		sm.rings = 6
		ball.mesh = sm
		ball.material_override = brass
		ball.position = p + Vector3(0, post_h + 0.03, 0)
		add_child(ball)
		tops.append(p + Vector3(0, post_h - 0.12, 0))
	for i in range(4):
		var a: Vector3 = tops[i]
		var b: Vector3 = tops[(i + 1) % 4]
		var mid: Vector3 = (a + b) * 0.5 - Vector3(0, 0.14, 0)
		add_child(_rod(a, mid, 0.019, rope))
		add_child(_rod(mid, b, 0.019, rope))


## DIDACTIC — the label lectern. Stands beside the podium rather than on it, so
## the plate stays empty: the institution speaks NEXT to the work, never on its
## surface. The lectern is what carries this regard across a room — the cool
## grey and the flat wash alone are a colour change, and a colour change is the
## kind of axis that gets called decoration.
func _lectern(s: float, h: float) -> void:
	var post: StandardMaterial3D = _mat(Color(0.28, 0.28, 0.31), 0.5, 0.25)
	var stand_x: float = s * 0.5 + 0.42
	var stand_z: float = s * 0.5 + 0.06
	var post_h: float = 0.90
	var rake: float = 34.0
	_box(Vector3(0.055, post_h, 0.055), Vector3(stand_x, post_h * 0.5, stand_z), post)
	_box(Vector3(0.26, 0.025, 0.22), Vector3(stand_x, 0.012, stand_z), post)

	var raked := Vector3(stand_x, post_h + 0.14, stand_z + 0.05)
	var back: MeshInstance3D = _box(
		Vector3(0.46, 0.32, 0.028), raked, _mat(Color(0.90, 0.89, 0.86), 0.78, 0.0))
	back.rotation_degrees = Vector3(-rake, 0, 0)

	# One quad per line — the baked-text renderer lays glyphs out on a single
	# line and treats "\n" as an unrenderable codepoint, so a multi-line label
	# has to be a block, not a string with newlines in it.
	var lines: Array = ["UNTITLED", "ARTIST UNKNOWN", "COLLECTION"]
	if label_text.strip_edges() != "":
		lines = Array(label_text.split("\n"))
	var block: Node3D = BakedText.make_text_block(
		lines, Color(0.11, 0.11, 0.13), 0.058, 0.38, 0.020, false)
	if block:
		# Off the plate along its OWN normal, not world +Z — the plate is raked.
		var face := Vector3(0.0, sin(deg_to_rad(rake)), cos(deg_to_rad(rake)))
		block.position = raked + face * 0.020
		block.rotation_degrees = Vector3(-rake, 0, 0)
		add_child(block)

	# A catalogue number printed on the plinth front — the object reduced to an
	# accession, which is the didactic regard's actual opinion of it.
	var code: MeshInstance3D = BakedText.make_label_mesh(
		"CAT. 001", Color(0.30, 0.30, 0.33), Vector2(minf(s * 0.55, 0.30), 0.055), 1400, false)
	if code:
		code.position = Vector3(0, h * 0.28, s * 0.5 + 0.004)
		add_child(code)


## DERELICT — the withdrawal. The plate is slid and canted rather than removed,
## because a missing plate reads as unfinished construction while a slipped one
## reads as neglect; the difference is entirely in whether the piece looks like
## it was ever cared for.
func _withdraw(plate: MeshInstance3D, s: float, h: float) -> void:
	plate.rotation_degrees = Vector3(0.0, 6.0, 8.0)
	plate.position += Vector3(s * 0.14, -0.010, s * 0.09)

	var streaks: Node3D = HangarKit.dust_streaks(s * 0.86, h * 0.78, s * 0.5 + 0.004, 5)
	if streaks:
		streaks.position.y = h * 0.5
		add_child(streaks)
	var grime: MeshInstance3D = HangarKit.grime_band(
		s * 0.94, 0.07, s * 0.5 + 0.004, Color(0.26, 0.25, 0.23))
	if grime:
		add_child(grime)

	# a broken-off corner, on the floor where it fell
	var rubble: MeshInstance3D = _box(Vector3(0.20, 0.13, 0.17),
		Vector3(s * 0.5 + 0.26, 0.065, s * 0.5 + 0.20), _mat(Color(0.33, 0.32, 0.30), 0.95, 0.0))
	rubble.rotation_degrees = Vector3(9.0, 24.0, -6.0)
	# and the socket it left behind. Geometry cannot be subtracted from a BoxMesh,
	# so the missing corner is a near-black block straddling the corner it broke
	# off — at gallery light levels a dark solid in a bright face reads as a hole,
	# which is cheaper than rebuilding the plinth as a carved mesh.
	var socket: MeshInstance3D = _box(Vector3(0.19, 0.15, 0.17),
		Vector3(s * 0.5 - 0.03, h - 0.05, s * 0.5 - 0.03), _mat(Color(0.08, 0.08, 0.09), 1.0, 0.0))
	socket.rotation_degrees = Vector3(0.0, 12.0, 0.0)


# ── reserve: how the empty volume is declared ─────────────────────────

## ARMATURE — the reserved volume drawn in lines. The museum's actual practice:
## before the work arrives, the space it will occupy is marked out. Uprights are
## deliberately thick (34 mm, not a hairline) because a wireframe that is honest
## about being thin disappears at gallery distance, and an invisible axis is a
## decorative one.
func _armature(s: float, top_y: float) -> void:
	var steel: StandardMaterial3D = _mat(Color(0.19, 0.20, 0.23), 0.35, 0.6)
	var lit: StandardMaterial3D = _emissive(Color(0.95, 0.66, 0.18), 2.2)
	var half: float = s * 0.42
	var vol: float = maxf(reserve_height, 0.2)
	var t: float = 0.034
	var sxs := PackedFloat32Array([-1.0, 1.0, 1.0, -1.0])
	var szs := PackedFloat32Array([-1.0, -1.0, 1.0, 1.0])
	for i in range(4):
		_box(Vector3(t, vol, t),
			Vector3(sxs[i] * half, top_y + vol * 0.5, szs[i] * half), steel)
	# top rails closing the volume
	var span: float = half * 2.0 + t
	var cap_y: float = top_y + vol
	_box(Vector3(span, t, t), Vector3(0, cap_y, -half), steel)
	_box(Vector3(span, t, t), Vector3(0, cap_y, half), steel)
	_box(Vector3(t, t, span), Vector3(-half, cap_y, 0), steel)
	_box(Vector3(t, t, span), Vector3(half, cap_y, 0), steel)
	# the footprint painted on the plate — the object's outline, waiting
	var mark_y: float = top_y + 0.004
	_box(Vector3(span, 0.008, 0.022), Vector3(0, mark_y, -half), lit)
	_box(Vector3(span, 0.008, 0.022), Vector3(0, mark_y, half), lit)
	_box(Vector3(0.022, 0.008, span), Vector3(-half, mark_y, 0), lit)
	_box(Vector3(0.022, 0.008, span), Vector3(half, mark_y, 0), lit)


## GHOST — the shape of what is missing, standing in its own light. A tapered
## six-sided column with a head: specific enough to read as an object, generic
## enough not to name one. It carries an interior omni so the absence THROWS
## colour onto the plate — without that the ghost is a pale shape on a pale
## plinth and reads as haze from more than two metres away.
func _ghost(s: float, top_y: float) -> void:
	var vol: float = maxf(reserve_height, 0.3)
	var body_h: float = vol * 0.70
	var head_r: float = s * 0.24

	var g := StandardMaterial3D.new()
	g.albedo_color = Color(0.70, 0.85, 1.0, 0.24)
	g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	g.roughness = 0.10
	g.cull_mode = BaseMaterial3D.CULL_DISABLED   # the far wall of the form shows through
	g.emission_enabled = true
	g.emission = Color(0.52, 0.76, 1.0)
	g.emission_energy_multiplier = 1.1

	var col: MeshInstance3D = _cyl(s * 0.20, s * 0.40, body_h,
		Vector3(0, top_y + body_h * 0.5, 0), g, 6)
	col.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var head := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = head_r
	sm.height = head_r * 2.0
	sm.radial_segments = 16
	sm.rings = 8
	head.mesh = sm
	head.material_override = g
	head.position = Vector3(0, top_y + body_h + head_r * 0.72, 0)
	head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(head)

	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0, top_y + body_h * 0.55, 0)
	lamp.omni_range = maxf(s * 3.4, 1.8)
	lamp.light_energy = 1.5
	lamp.light_color = Color(0.55, 0.78, 1.0)
	add_child(lamp)


## SHROUD — the deinstalled state. The sheet is built to hang PAST the plate on
## every side, hiding the lip the podium is otherwise proud of; a cover that
## stops at the edge reads as a box sitting on a box. The tie cord is what makes
## the eye call it cloth rather than a lump.
func _shroud(s: float, top_y: float) -> void:
	var cloth: StandardMaterial3D = _mat(Color(0.86, 0.845, 0.80), 0.98, 0.0)
	var shade: StandardMaterial3D = _mat(Color(0.66, 0.65, 0.62), 0.98, 0.0)
	var vol: float = maxf(reserve_height, 0.3)
	var bulk_h: float = vol * 0.66
	var w: float = s * 0.86
	# The sheet is laid over the PLATE, not over the object — the plate is
	# 60 mm wider than the plinth, so the cloth has to clear that or the podium's
	# proud lip pokes out from under the cover and the illusion dies.
	var lip: float = (s + 0.06) * 0.5 + 0.05
	var sheet_y: float = top_y + 0.025
	_box(Vector3(lip * 2.0, 0.05, lip * 2.0), Vector3(0, sheet_y, 0), cloth)

	var base_y: float = sheet_y + 0.025
	_box(Vector3(w, bulk_h, w), Vector3(0, base_y + bulk_h * 0.5, 0), cloth)
	# softened crown, so the covered thing has no corners left to read as a box
	var cap := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = w * 0.55
	sm.height = w * 0.62
	sm.radial_segments = 16
	sm.rings = 8
	cap.mesh = sm
	cap.material_override = cloth
	cap.position = Vector3(0, base_y + bulk_h, 0)
	add_child(cap)

	# skirt: four panels hanging from the sheet's edge, splayed slightly, ending
	# well below the plate so the cover reads as fabric and not as a second box
	var drop: float = 0.36
	var flare: float = 8.0
	var skirt_y: float = sheet_y - drop * 0.5
	var span: float = lip * 2.0
	var sxs := PackedFloat32Array([0.0, 0.0, 1.0, -1.0])
	var szs := PackedFloat32Array([1.0, -1.0, 0.0, 0.0])
	for i in range(4):
		var horiz: bool = i < 2
		var size: Vector3 = Vector3(span, drop, 0.03) if horiz else Vector3(0.03, drop, span)
		var panel: MeshInstance3D = _box(size,
			Vector3(sxs[i] * lip, skirt_y, szs[i] * lip), cloth)
		# Signs chosen so the HEM swings outward. Inverted, the skirt tucks under
		# the plate and the whole thing reads as a lid, not a sheet.
		if horiz:
			panel.rotation_degrees = Vector3(-flare * szs[i], 0.0, 0.0)
		else:
			panel.rotation_degrees = Vector3(0.0, 0.0, flare * sxs[i])

	# the tie — what makes the eye call it cloth rather than a lump
	var tie_y: float = base_y + bulk_h * 0.45
	_box(Vector3(w + 0.03, 0.035, 0.028), Vector3(0, tie_y, w * 0.5), shade)
	_box(Vector3(w + 0.03, 0.035, 0.028), Vector3(0, tie_y, -w * 0.5), shade)
	_box(Vector3(0.028, 0.035, w + 0.03), Vector3(w * 0.5, tie_y, 0), shade)
	_box(Vector3(0.028, 0.035, w + 0.03), Vector3(-w * 0.5, tie_y, 0), shade)


# ── small builders ────────────────────────────────────────────────────

func _mat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	if c.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


func _emissive(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.5
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m


func _box(size: Vector3, pos: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
	return mi


func _cyl(top_r: float, bot_r: float, height: float, pos: Vector3,
		mat: StandardMaterial3D, segments: int) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = top_r
	cm.bottom_radius = bot_r
	cm.height = height
	cm.radial_segments = segments
	mi.mesh = cm
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
	return mi


## A cylinder spanning a -> b in any orientation (the rope segments).
func _rod(a: Vector3, b: Vector3, radius: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = maxf(a.distance_to(b), 0.001)
	cm.radial_segments = 8
	mi.mesh = cm
	mi.material_override = mat
	var yv: Vector3 = (b - a).normalized()
	var ref: Vector3 = Vector3.UP if absf(yv.dot(Vector3.UP)) < 0.985 else Vector3.RIGHT
	var xv: Vector3 = ref.cross(yv).normalized()
	var zv: Vector3 = xv.cross(yv).normalized()
	mi.transform = Transform3D(Basis(xv, yv, zv), (a + b) * 0.5)
	return mi
