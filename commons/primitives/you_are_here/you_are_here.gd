extends Node3D
class_name YouAreHere

# @identity
# essence: a text decal on the floor — the words YOU ARE HERE lying flat under your feet, the way they are printed on a mall map, a transit platform, a parking garage, the floor of a museum lobby. Not a beacon, not a pin: a flat indexical inscription you stand ON. The most-printed sentence in wayfinding, the phrase that only means anything when a body is over it. The point reduced to language and laid into the ground — position spoken as a command and a comfort at once.
# desire: it wants the player to look down and find themselves already addressed — "here" is wherever they are reading it. It wants the banality of the floor-sticker to do the conceptual work: that "here" is not a place but a relation between a body and a coordinate, printed in advance for whoever arrives. It wants to put the wayfinding decal in drag — to let the most corporate, most neutral floor-text carry the queer charge of "you, specifically, are located."
# critical_parameter: deixis — what the inscription claims (words_and_mark / words_only / mark_only / arrow / plan_fragment): whether the sentence and the mark that gives it a referent are both on the floor, only one of them is, or the whole thing has been moved inside a drawing of the room. Under it: text + pride_gradient. text is the inscription (default "YOU ARE HERE"); change it and the floor speaks differently. pride_gradient off is the neutral civic decal (one flat colour, the platform's voice); on, the letters run the spectrum — the located self reclaimed from the wayfinding system that named it.
# triggers: _ready builds a TextMesh laid flat on the floor plus an optional thin ring around it; _process optionally cycles the pride gradient; apply_grid_config rebuilds on DNA change.
# emerges: alone on a lab floor it reads as orientation; placed over the floor-window above the origin it becomes a caption for coordinate zero — "you are here" written across the glass you can see the point through. Beside `origin` (the absolute 0,0,0) it stages the difference between THE origin and the indexical here: one zero, many bodies, each standing on the same four words.
# needs: flat text on the ground [TextMesh, present]; a reading orientation from above [laid in the XZ plane, present]; a mark to ring the spot [optional ring, present]; lift off the floor so it never z-fights [present]
# relationships: sibling to `origin` and `static_point` (the point at rest, but this one is indexed to YOU and made of language); the contemporary pop term in the point-trilogy with `klee_walking_point` (1925, the point moving) and `fontana_puncture` (1958, the point cutting) — this is the point in 2005 / 2036, the point as wayfinding; cousin to the spawn marker and teleporter (all inscribe "a body is / will be here").
# truth: a point is position without extension — and "you are here" is what a civilisation writes when it agrees to render every body as a coordinate it has already labelled. The decal helps you and locates you in the same breath; that is the friendliest face of algorithmic capture, the fence shaped like an arrow pointing at your own feet. Laid on the lab floor, flat and calm, it asks the player to notice they were expected.

## "You are here" — a floor text decal (the point as wayfinding language).
##
## Built procedurally with TextMesh (real geometry: captures AND exports).
## Origin at the floor; text lies flat in the XZ plane, readable from
## above, lifted a hair off the floor to avoid z-fighting.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Text")
@export var text: String = "YOU ARE HERE"
@export var strike_first_word: bool = true     # YOU, crossed out (Palle, 2026-08-19)
@export var text_color: Color = Color(0.18, 0.52, 1.0)   # civic blue
@export var font_size: int = 96
## World height of the text (TextMesh pixel_size scaler).
@export var text_scale: float = 0.004
@export_group("Decal")
@export var show_ring: bool = true
@export var ring_radius: float = 0.9
@export var ring_color: Color = Color(0.18, 0.52, 1.0)
@export var pride_gradient: bool = false

# ── STAGE-2 DNA — promoted 2026-08-03 ─────────────────────────────────
#
# `deixis` — what the inscription actually claims.
#
# Everything this object is made of is deixis: four words that mean nothing
# until a body is standing over them. Until now it could only ever make the
# full claim — the sentence AND a ring drawn round the spot — because the
# sentence and the mark were welded together in _build. They are two different
# halves of the same act, and separating them is the artifact's own subject:
#
#   words_and_mark — the shipped decal. The sentence, and a ring saying where
#                    "here" is. Claim plus referent, the complete wayfinding
#                    speech act.
#   words_only     — the sentence with nothing marked. "Here" is wherever you
#                    happen to be reading it and the floor declines to say
#                    where that is. The claim is still true and now says
#                    nothing — the purest case of pure deixis.
#   mark_only      — the ring with no sentence. The corporate blue dot: you
#                    are located, and nobody addresses you. The system knows
#                    the coordinate and has stopped bothering to tell you.
#   arrow          — the sentence with a chevron pointing back at it. The sign
#                    that points, pointing at itself, because the only thing
#                    it can indicate is the place where it is being read.
#   plan_fragment  — the sentence and the ring inside a scrap of floorplan:
#                    walls, a partition, the doorway you came through. "Here"
#                    relocated from the room into a REPRESENTATION of the
#                    room — the mall-map move, where finding yourself means
#                    finding your dot on someone else's drawing.
@export_enum("words_and_mark", "words_only", "mark_only", "arrow", "plan_fragment") var deixis: String = "words_and_mark"

## The same list as the @export_enum above. The enum is what the editor and the
## declaration gate read; this is what an incoming map token is checked against.
const DEIXIS_VALUES: Array[String] = ["words_and_mark", "words_only", "mark_only", "arrow", "plan_fragment"]

## Which claims put the sentence on the floor, and which put a ring round it.
const DEIXIS_HAS_WORDS: Array[String] = ["words_and_mark", "words_only", "arrow", "plan_fragment"]
const DEIXIS_HAS_RING: Array[String] = ["words_and_mark", "mark_only", "plan_fragment"]

# ── State ─────────────────────────────────────────────────────────────

var _built: bool = false
var _text_mat: StandardMaterial3D = null
var _ring_mat: StandardMaterial3D = null
var _phase: float = 0.0


func _ready() -> void:
	_read_metadata_overrides()
	_build()


## Contract: this runs AFTER _ready(), via call_deferred from
## GridInteractablesComponent — and curation_station calls it on artifacts it
## has just framed, with keys this decal has never heard of. A config that
## changes none of the values the build reads must leave the built decal alone;
## tearing the floor text down and putting an identical one back is a rebuild
## nobody asked for, on 31 placements.
func apply_grid_config(config_data: Dictionary) -> void:
	var before: String = "%s|%s|%d|%s|%s|%s" % [
		text, text_color, font_size, str(show_ring), str(pride_gradient), deixis]
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	var after: String = "%s|%s|%d|%s|%s|%s" % [
		text, text_color, font_size, str(show_ring), str(pride_gradient), deixis]
	if not _built:
		return   # _ready has not run yet; it will build with these values.
	if after == before:
		return
	for c in get_children():
		c.queue_free()
	_built = false
	_text_mat = null
	_ring_mat = null
	_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_text"):
		text = str(get_meta("config_text"))
	if has_meta("config_strike_first_word"):
		strike_first_word = str(get_meta("config_strike_first_word")).to_lower() in ["true", "1", "yes"]
	if has_meta("config_text_color"):
		text_color = _parse_color(str(get_meta("config_text_color")), text_color)
	if has_meta("config_font_size"):
		font_size = int(str(get_meta("config_font_size")))
	if has_meta("config_show_ring"):
		var s: String = str(get_meta("config_show_ring")).to_lower()
		show_ring = s == "true" or s == "1" or s == "yes"
	if has_meta("config_pride_gradient"):
		var s2: String = str(get_meta("config_pride_gradient")).to_lower()
		pride_gradient = s2 == "true" or s2 == "1" or s2 == "yes"
	if has_meta("config_deixis"):
		deixis = _pick_axis(str(get_meta("config_deixis")), DEIXIS_VALUES, deixis)


## Accept an axis value only if it names a claim we actually build.
func _pick_axis(raw: String, allowed: Array[String], fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


func _parse_color(raw: String, fallback: Color) -> Color:
	var parts := raw.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	return fallback


# ── Build ─────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true

	if deixis in DEIXIS_HAS_WORDS:
		_build_words()
	if show_ring and deixis in DEIXIS_HAS_RING:
		_build_ring()
	if deixis == "arrow":
		_build_arrow()
	elif deixis == "plan_fragment":
		_build_plan()

	_phase = 0.0
	set_process(pride_gradient)


## The sentence — TextMesh laid flat on the floor. Unchanged from the shipped
## build, node name and transform included.
func _build_words() -> void:
	# The text itself — TextMesh laid flat on the floor.
	var label := MeshInstance3D.new()
	label.name = "FloorText"
	var tm := TextMesh.new()
	tm.text = text
	tm.font_size = font_size
	tm.pixel_size = text_scale
	tm.depth = 0.0                                  # flat decal, no extrusion
	tm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mesh = tm

	_text_mat = StandardMaterial3D.new()
	_text_mat.albedo_color = text_color
	_text_mat.emission_enabled = true
	_text_mat.emission = text_color
	_text_mat.emission_energy_multiplier = 1.4
	_text_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED  # reads as printed decal
	_text_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	label.material_override = _text_mat

	# Lay flat: text plane (XY) -> floor plane (XZ), facing up (+Y).
	label.rotation = Vector3(-PI * 0.5, 0, 0)
	label.position = Vector3(0, 0.012, 0)
	add_child(label)
	# THE STRIKE (Palle, 2026-08-19: "in you are here make the word you strike over").
	# The first word is crossed out — the located self, named and struck: a thin bar
	# laid over YOU, the rest of the sentence standing. strike_first_word off = the
	# civic decal as printed.
	if strike_first_word and " " in text:
		var font: Font = tm.font if tm.font != null else ThemeDB.fallback_font
		var first: String = text.split(" ")[0]
		var w_all: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x * text_scale
		var w_first: float = font.get_string_size(first, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x * text_scale
		var bar := MeshInstance3D.new()
		bar.name = "Strike"
		var bm := BoxMesh.new()
		bm.size = Vector3(w_first, 0.004, maxf(font_size * text_scale * 0.11, 0.01))
		bar.mesh = bm
		bar.material_override = _text_mat
		bar.position = Vector3(-w_all * 0.5 + w_first * 0.5, 0.016, 0.0)
		add_child(bar)


## The mark's material — one instance shared by the ring and the floorplan bars
## so `pride_gradient` still tints every printed line the same way.
func _mark_material() -> StandardMaterial3D:
	if _ring_mat == null:
		_ring_mat = StandardMaterial3D.new()
		_ring_mat.albedo_color = ring_color
		_ring_mat.emission_enabled = true
		_ring_mat.emission = ring_color
		_ring_mat.emission_energy_multiplier = 1.1
		_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return _ring_mat


## The thin ring marking the spot. Unchanged from the shipped build.
func _build_ring() -> void:
	var ring := MeshInstance3D.new()
	ring.name = "Ring"
	var rm := TorusMesh.new()
	rm.inner_radius = ring_radius - 0.03
	rm.outer_radius = ring_radius
	rm.rings = 48
	rm.ring_segments = 8
	ring.mesh = rm
	ring.material_override = _mark_material()
	# Torus lies in the XZ plane already (its hole faces +Y).
	ring.position = Vector3(0, 0.008, 0)
	add_child(ring)


## A chevron on the reader's side of the words, apex pointing back at them.
## The prism's apex sits at +Y in its own plane; the same -90 degrees about X
## that lays the text flat sends that apex toward -Z, so an arrow parked at
## +Z points at the sentence — the sign indicating the only thing it can.
func _build_arrow() -> void:
	var arrow := MeshInstance3D.new()
	arrow.name = "Arrow"
	var pm := PrismMesh.new()
	pm.size = Vector3(ring_radius * 0.62, ring_radius * 0.66, 0.012)
	arrow.mesh = pm
	arrow.material_override = _text_mat if _text_mat != null else _mark_material()
	arrow.rotation = Vector3(-PI * 0.5, 0, 0)
	arrow.position = Vector3(0, 0.010, ring_radius * 1.05)
	add_child(arrow)


## A scrap of floorplan around the spot: three walls, a partition, and the gap
## you walked in through. Flat bars, same printed look as the ring.
func _build_plan() -> void:
	var w: float = ring_radius * 4.4
	var d: float = ring_radius * 3.2
	var t: float = 0.06
	_plan_bar(0.0, -d * 0.5, w, t)                  # far wall
	_plan_bar(-w * 0.5, 0.0, t, d)                  # left wall
	_plan_bar(w * 0.5, 0.0, t, d)                   # right wall
	_plan_bar(-w * 0.28, d * 0.5, w * 0.44, t)      # near wall, left of the doorway
	_plan_bar(w * 0.34, d * 0.5, w * 0.32, t)       # near wall, right of the doorway
	_plan_bar(w * 0.2, -d * 0.22, t, d * 0.56)      # interior partition


func _plan_bar(px: float, pz: float, sx: float, sz: float) -> void:
	var bar := MeshInstance3D.new()
	bar.name = "PlanBar"
	var bm := BoxMesh.new()
	bm.size = Vector3(sx, 0.012, sz)
	bar.mesh = bm
	bar.material_override = _mark_material()
	bar.position = Vector3(px, 0.006, pz)
	add_child(bar)


func _process(delta: float) -> void:
	if not pride_gradient:
		return
	_phase += delta * 0.15
	var hue: float = fmod(_phase, 1.0)
	var c := Color.from_hsv(hue, 0.85, 1.0)
	if _text_mat:
		_text_mat.albedo_color = c
		_text_mat.emission = c
	if _ring_mat:
		var c2 := Color.from_hsv(fmod(hue + 0.5, 1.0), 0.85, 1.0)
		_ring_mat.albedo_color = c2
		_ring_mat.emission = c2
