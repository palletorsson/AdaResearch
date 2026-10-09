# coincident_face.gd — THE EXACT BOUNDARY IS A COIN TOSS PER PIXEL.
#
# The boolean-surfaces seam. Constructive solid geometry promises exact cuts:
# subtract one solid from another and the boundary is a clean mathematical
# surface. But when the two surfaces are coincident — the cut plane lands exactly
# on a face — they claim the same depth, and the float grid cannot say which is
# in front. So the renderer flickers: pixel by pixel it awards the surface to
# whichever number rounded higher this frame. Amber solid, blue solid, and along
# the shared face a stripe of z-fighting where the exact answer dissolves into
# floating-point noise. The clean boolean was exact everywhere except the one
# place you asked it to be.
extends Node3D
class_name CoincidentFace

# --- DNA (stage 2, promoted 2026-08-11) --------------------------------------
# THE PROBLEM. The headline above is this artifact's whole content, and it has
# only ever drawn the coin toss. One state, asserted, with no account of what
# surrounds it — no reading of the same diagram when the boundary is NOT
# contested, and therefore no way to tell whether the flicker is a property of
# Booleans or of one particular pair of numbers. It is the boolean_surfaces
# station of the bias landscape, charged with "bias is conserved; show the seam",
# and it was showing the seam without showing what a seam is measured against.
#
# separation — THE GAP BETWEEN THE TWO FACES, IN UNITS OF THE FLOAT GRID. What it
#   argues: THAT EXACTNESS HAS A GRAIN SIZE, AND THAT CROSSING IT IS TOTAL.
#     clear       a_max.x -0.04 against b_min.x +0.04. An 0.08 gap, no shared
#                 face, nothing to contest — the exact boundary CSG actually
#                 promises, and the control this diagram has never had.
#     hairline    an 0.008 gap. The two solids all but touching and the depth
#                 order still decided cleanly: a thin dark seam and no band. This
#                 is the rung that turns the claim into a claim about SIZE.
#     coincident  SHIPPED. a_max.x 0.02 against b_min.x -0.02, and the 0.04 band
#                 of 26 alternating slivers standing in the overlap.
#     inverted    the shipped bounds, with B advanced 0.004 toward the viewer, so
#                 the band goes solid blue. One step of the grid — and the answer
#                 does not degrade, it flips entirely.
#   The ladder is deliberately NOT monotone: the failure sits in the middle of it,
#   with order on both sides. The verdict tag and the plate body follow the rung,
#   because this artifact's text is half its ink and a still that kept "z-fight:
#   the shared face flickers" over a clean cut would be lying.
#
# WHY THE WORD IS NEW. Nothing in the corpus asks what distance an exact answer
# needs in order to stay exact. The two nearest words are taken and mean something
# else: `seam` (escher_staircase, florensky_sphere — none|hairline|gap|scaffold|
# field) names the joint of an impossible object, and `grain` on six artifacts
# names how a solid is divided. separation says the bias is not in the flicker; it
# is in the threshold that decides whether there is one.
#
# WHAT IS DECLINED. tiebreak (stripes | blotch | split | toss) — HOW the contest is
# decided, pixel by pixel — is this artifact's headline turned into an axis, is
# deterministic once seeded, and its four rungs are four real policies: the shipped
# alternation; the seeded blotching a real coincident face actually shows; a clean
# rule awarding left to A and right to B, which abolishes the flicker and relocates
# the arbitrariness into the rule, the seam family's whole thesis; and the literal
# per-sliver coin toss. It is REFUSED ON ARITHMETIC. Every rung changes only the
# band — 0.04 x 0.40 m of an 0.86 x 0.66 m plate, 2.8% of the subject face and
# under 2% of frame even at framing 0.55 — so the critic's hottest-5% window would
# be more than half unchanged pixels and the verdict would be a fact about the
# band's width. It becomes shippable the moment the plate is redrawn at a wider
# band, and redrawing the plate changes the shipped picture: a decision to take on
# its own, not to smuggle in under a promotion.
# Also declined: `evidence` (result|trace|longhand|axiom, 45 artifacts). There is
# no derivation here to show more or less of — this artifact does not compute an
# answer, it exhibits a place where the answer does not exist.
const SEPARATIONS: PackedStringArray = ["clear", "hairline", "coincident", "inverted"]

## The bounds the axis does NOT touch, lifted out of _ready so the two that DO
## move can be named. A's left edge, both solids' top and bottom, B's right edge.
const A_MIN: Vector2 = Vector2(-0.34, -0.20)
const B_MAX: Vector2 = Vector2(0.34, 0.20)
const A_TOP: float = 0.20
const B_BOTTOM: float = -0.20
## Slivers across the contested band. A literal in the loop before this promotion.
const SLIVERS: int = 26
## The one step of the float grid that ends the contest, at `inverted`.
const DEPTH_STEP: float = 0.004

@export_enum("clear", "hairline", "coincident", "inverted") var separation: String = "coincident"

## The two contested faces in x: A's right face, then B's left face. This is the
## shipped pair, and a placement that names it directly still WINS over separation
## — the named axis is a vocabulary laid over the raw numbers, never a replacement
## for them. Positive x on the first and negative on the second is an OVERLAP, and
## the width of that overlap is the width of the band.
@export var face_x: Vector2 = Vector2(0.02, -0.02)

@export var color_a: Color = Color(1.0, 0.62, 0.18)
@export var color_b: Color = Color(0.3, 0.7, 1.0)

var _built: bool = false
var _faces_explicit: bool = false


func _ready() -> void:
	_read_metadata_overrides()
	_build()


## Guarded. The old body stamped every config key into metadata and stopped there,
## and nothing anywhere read it back — so this was not a knob without a rebuild, it
## was a knob without a wire. It now reads the keys it understands, and rebuilds
## when, and only when, a value the build actually reads has changed. The stamping
## is kept verbatim so anything that inspected that metadata still finds it.
func apply_grid_config(config_data: Dictionary) -> void:
	var before: String = _config_signature()
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if not _built:
		return
	if _config_signature() == before:
		return
	for c in get_children():
		c.queue_free()
	_built = false
	_build()


func _config_signature() -> String:
	return "%s|%s|%s|%s" % [separation, str(_faces()), str(color_a), str(color_b)]


func _read_metadata_overrides() -> void:
	if has_meta("config_separation"):
		var s: String = str(get_meta("config_separation")).strip_edges().to_lower()
		if SEPARATIONS.has(s):
			separation = s
	if has_meta("config_face_x"):
		var f = get_meta("config_face_x")
		if f is Vector2:
			face_x = f
		else:
			var parts: PackedStringArray = str(f).split(",")
			if parts.size() >= 2:
				face_x = Vector2(float(parts[0]), float(parts[1]))
		_faces_explicit = true
	if has_meta("config_color_a"):
		var ca = get_meta("config_color_a")
		if ca is Color:
			color_a = ca
		else:
			color_a = _parse_color(str(ca), color_a)
	if has_meta("config_color_b"):
		var cb = get_meta("config_color_b")
		if cb is Color:
			color_b = cb
		else:
			color_b = _parse_color(str(cb), color_b)


func _parse_color(raw: String, fallback: Color) -> Color:
	var parts: PackedStringArray = raw.split(",")
	if parts.size() >= 3:
		var a: float = 1.0
		if parts.size() > 3:
			a = float(parts[3])
		return Color(float(parts[0]), float(parts[1]), float(parts[2]), a)
	return fallback


# ── The gap ───────────────────────────────────────────────────────────

## separation resolved to the two face positions the diagram draws: (A's right,
## B's left). "coincident" returns face_x UNTOUCHED — the export itself, not a
## formula that happens to reproduce 0.02 / -0.02 — so the shipped picture cannot
## drift by a rounding. "inverted" takes the same fallthrough on purpose: it keeps
## the shipped bounds exactly and settles the contest in z instead, which is the
## whole point of that rung.
func _faces() -> Vector2:
	if _faces_explicit:
		return face_x
	match separation:
		"clear":
			return Vector2(-0.04, 0.04)
		"hairline":
			return Vector2(-0.004, 0.004)
		_:
			return face_x


## B's depth. Zero everywhere the artifact has ever shipped; one DEPTH_STEP at
## "inverted", where B stops being tied and starts winning.
func _b_depth() -> float:
	if separation == "inverted":
		return DEPTH_STEP
	return 0.0


## The line under the diagram. The shipped text is the fallthrough, verbatim.
func _verdict() -> String:
	match separation:
		"clear":
			return "0.08 apart: two depths, no contest"
		"hairline":
			return "0.008 apart: still decided, cleanly"
		"inverted":
			return "B ahead by 0.004: the face is B's"
		_:
			return "z-fight: the shared face flickers"


func _verdict_color() -> Color:
	match separation:
		"clear":
			return Color(0.55, 0.88, 0.72)
		"hairline":
			return Color(0.62, 0.82, 0.95)
		"inverted":
			return color_b
		_:
			return Color(0.95, 0.6, 0.4)


## The plate reads the rung. The shipped body is the fallthrough, verbatim.
func _plate_body() -> String:
	match separation:
		"clear":
			return "CSG promises an exact cut — a clean surface\nhold the two faces 0.08 apart and the promise keeps:\nevery pixel has one depth and one owner"
		"hairline":
			return "CSG promises an exact cut — a clean surface\nat 0.008 the faces all but touch and it still holds —\nexactness has a grain size, and this is inside it"
		"inverted":
			return "CSG promises an exact cut — a clean surface\nadvance B by 0.004 and the coin toss stops:\nthe answer does not degrade, it flips — the face is B's"
		_:
			return "CSG promises an exact cut — a clean surface\nwhere the cut plane lands on a coincident face,\ntwo surfaces claim one depth and the pixel is a coin toss"


# ── Build ─────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true
	_backing()
	# two solids and the face between them. Where that face falls is the axis.
	var f: Vector2 = _faces()
	var bz: float = _b_depth()
	var a_min: Vector2 = A_MIN
	var a_max: Vector2 = Vector2(f.x, A_TOP)
	var b_min: Vector2 = Vector2(f.y, B_BOTTOM)
	var b_max: Vector2 = B_MAX
	_rect_outline(a_min, a_max, color_a, 0.006)
	_rect_fill(a_min, a_max, Color(color_a.r, color_a.g, color_a.b, 0.10))
	_rect_outline(b_min, b_max, color_b, 0.006, bz)
	_rect_fill(b_min, b_max, Color(color_b.r, color_b.g, color_b.b, 0.10), bz)
	# the coincident face: a vertical band of alternating amber/blue slivers —
	# the two surfaces fighting for one depth. It exists only where the two solids
	# OVERLAP, so pulling them apart leaves nothing to contest and nothing to draw,
	# which is the entire argument of the clear and hairline rungs.
	var band_x0: float = b_min.x
	var band_x1: float = a_max.x
	if band_x1 > band_x0:
		var slivers: int = SLIVERS
		var sw: float = (band_x1 - band_x0) / float(slivers)
		for i in range(slivers):
			var x: float = band_x0 + (float(i) + 0.5) * sw
			# at "inverted" the contest is over and every sliver is B's.
			var col: Color = color_b
			if separation != "inverted":
				col = color_a if (i % 2 == 0) else color_b
			_bar(Vector2(x, a_min.y), Vector2(x, a_max.y), col, sw * 0.9, bz)
	_tag("solid A", Vector2(-0.22, a_max.y + 0.05), color_a, 26)
	_tag("solid B", Vector2(0.22, b_max.y + 0.05), color_b, 26)
	_tag(_verdict(), Vector2(0.0, a_min.y - 0.06), _verdict_color(), 26)
	_plate("BOOLEAN", _plate_body(), Vector3(0.0, a_max.y + 0.2, 0.0), color_b)


func _backing() -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.86, 0.66, 0.006)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.07, 0.08, 0.10)
	mat.roughness = 0.7
	mi.material_override = mat
	mi.position = Vector3(0.0, 0.02, -0.016)
	add_child(mi)


func _rect_outline(mn: Vector2, mx: Vector2, color: Color, thick: float, z_off: float = 0.0) -> void:
	_seg(Vector2(mn.x, mn.y), Vector2(mx.x, mn.y), color, thick, z_off)
	_seg(Vector2(mx.x, mn.y), Vector2(mx.x, mx.y), color, thick, z_off)
	_seg(Vector2(mx.x, mx.y), Vector2(mn.x, mx.y), color, thick, z_off)
	_seg(Vector2(mn.x, mx.y), Vector2(mn.x, mn.y), color, thick, z_off)


func _rect_fill(mn: Vector2, mx: Vector2, color: Color, z_off: float = 0.0) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(absf(mx.x - mn.x), absf(mx.y - mn.y), 0.004)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(color.r, color.g, color.b)
	mat.emission_energy_multiplier = 0.15
	mi.material_override = mat
	mi.position = Vector3((mn.x + mx.x) * 0.5, (mn.y + mx.y) * 0.5, -0.006 + z_off)
	add_child(mi)


func _bar(a: Vector2, b: Vector2, color: Color, width: float, z_off: float = 0.0) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(width, absf(b.y - a.y), 0.007)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.6
	mi.material_override = mat
	mi.position = Vector3((a.x + b.x) * 0.5, (a.y + b.y) * 0.5, 0.004 + z_off)
	add_child(mi)


func _seg(a: Vector2, b: Vector2, color: Color, thick: float, z_off: float = 0.0) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	var d: float = a.distance_to(b)
	bm.size = Vector3(maxf(d, 0.001), thick, thick)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.5
	mi.material_override = mat
	mi.position = Vector3((a.x + b.x) * 0.5, (a.y + b.y) * 0.5, z_off)
	mi.rotation = Vector3(0.0, 0.0, atan2(b.y - a.y, b.x - a.x))
	add_child(mi)


func _tag(text: String, pos: Vector2, color: Color, fs: int) -> void:
	var t := Label3D.new()
	t.text = text
	t.font_size = fs
	t.pixel_size = 0.00044
	t.modulate = color
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = Vector3(pos.x, pos.y, 0.02)
	add_child(t)


func _plate(title: String, body: String, pos: Vector3, accent: Color) -> void:
	var panel := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.86, 0.15, 0.008)
	panel.mesh = pm
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.09, 0.10, 0.12)
	pmat.roughness = 0.6
	panel.material_override = pmat
	panel.position = pos
	add_child(panel)
	var strip := MeshInstance3D.new()
	var sbm := BoxMesh.new()
	sbm.size = Vector3(0.86, 0.01, 0.012)
	strip.mesh = sbm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = accent
	smat.emission_enabled = true
	smat.emission = accent
	strip.material_override = smat
	strip.position = pos + Vector3(0.0, 0.083, 0.006)
	add_child(strip)
	var t := Label3D.new()
	t.text = title + "\n" + body
	t.font_size = 30
	t.pixel_size = 0.00040
	t.modulate = Color(0.93, 0.95, 0.99)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = pos + Vector3(0.0, 0.0, 0.006)
	add_child(t)
