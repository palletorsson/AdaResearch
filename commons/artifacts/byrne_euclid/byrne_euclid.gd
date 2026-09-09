# @identity
# essence: one proposition of Euclid printed twice at the same size on one panel — on the left as three identical grey squares that can only be told apart by the letters stuck to their corners, on the right as Byrne's red, yellow and blue, where a shape is its own name — and the key that decodes the letters standing behind the panel, where you have to walk to it
# desire: that a visitor start reading the left-hand proof, find that "the square BDEC" names nothing they can see, walk round the deck to the key, walk back, and feel a lookup in their legs
# critical_parameter: key_side — back / front / none. Back is the artifact: the key is a real round trip. Front is the control, and it is the honest one, because it is what a PAGE is — the key is right there and the round trip collapses to an eye movement nobody notices they are paying for. None is the limit case: a symbol table with no entries, which is what an unglossed notation actually is
# triggers: nothing. _ready draws both halves and stops. The only moving part in this artifact is the visitor, and that is the measurement
# emerges: the left half becomes unreadable in a way the right half never was — not harder, unreadable, because three identical grey squares carry no information about which is which and the letters are the whole of what separates them. Take the key away and the sentence under them stops referring
# needs: floor at y=0 [the grid provides it]; a walkable band behind the deck about a metre deep, or the key cannot be reached and the artifact is a diagram [spatial_needs.clearance.back]; commons/ui/text_screen.gd, which is the one text lane in this corpus with a legible capture behind it [present]; res://commons/render/pbr_kit.gd for the deck and the paper [present]
# relationships: NOT a second pythagorean_proof — that one (commons/primitives/pythagorean_proof) hands you draggable vertices and an area readout, and its subject is the theorem. This one never asks whether the theorem is true and would work as well on a false one; its subject is naming. Kin to serial_principle, which paid for the text lane used here and whose plate photographed bare twice before anyone found out why. Kin to eleven_dots on the other side: there what you see is a fact about where you stand, here what you can READ is
# truth: a name is a promise that the thing named can be found again, and the promise is only free on a page. "BDEC" and a red square make the same claim about the same figure. The difference is that one of them costs about 6.5 m of walking to cash and the other costs nothing — and on paper that difference is invisible, because the eye does the round trip in a tenth of a second and never sends a bill. Byrne's colours are not a teaching aid or a decoration. They are the removal of an indirection nobody was charging for.

extends Node3D
class_name ByrneEuclid

## BYRNE'S EUCLID — Oliver Byrne, *The First Six Books of the Elements of Euclid
## in which Coloured Diagrams and Symbols are used instead of Letters*, William
## Pickering, London, 1847. Byrne printed Euclid in vermilion, chrome yellow,
## ultramarine and black, and threw the lettering away. There are no lettered
## vertices in his plates and no legend anywhere in the book: the triangle you
## are talking about is the triangle you are pointing at.
##
## THE ARGUMENT THIS OBJECT MAKES IS NOT ABOUT PYTHAGORAS. I.47 is the vehicle
## because everyone already knows where it ends, which frees the whole of a
## visitor's attention for the thing that is actually different between the two
## halves. What is different is the NAMING:
##
##   LEFT   three squares filled in ONE grey, indistinguishable, plus nine
##          letter tags — A B C D E F G H K — and a sentence built out of them.
##          To find "the square BDEC" you must find B, D, E and C and trace the
##          quadrilateral they bound. The tags are a symbol table. The key that
##          says what the symbols mean is behind the panel.
##   RIGHT  the identical figure, the identical bars, drawn to the identical
##          size, with the three squares filled red, yellow and blue. No tags,
##          no key, and a sentence made of three coloured squares and two black
##          operators. Nothing to look up, because nothing was named.
##
## THE GEOMETRY OF THE TWO HALVES IS THE SAME CODE PATH — _build_figure runs
## twice with one boolean flipped. That is deliberate and it is the experimental
## control: if the halves were drawn by two functions, any difference a visitor
## saw could be a difference in draughtsmanship. Here the ONLY things that
## change are the fill colours, the bar colours and whether the nine tags are
## built. Everything else is provably identical, because it is one function.
##
## WHY THE LEFT FILLS ARE GREY AND NOT EMPTY. The first sketch drew the left as
## an engraved line diagram — bone paper, black outlines, no fill — against
## Byrne's colour blocks. That is what the two books actually look like, and it
## is a confounded comparison: the right half would then differ in FILLEDNESS as
## well as in naming, and a visitor could correctly say the coloured one is just
## easier to see. Filling all three left-hand squares with one identical grey
## removes that: both halves are three filled squares of the same size in the
## same places. One set is distinguishable; the other set is named. That is the
## only variable.
##
## THE COST, MEASURED, at the shipped defaults. A visitor reading the left half
## stands at the deck's front edge, around z = +0.45. The panel's back face is
## flush with the deck's at z = -0.25, so the key stands at -0.25 - 1.05 =
## z = -1.30, and is read from about z = -0.75. The deck is 1.92 m wide, so the
## path goes round its end at x = ±1.25:
##
##     (-0.45, +0.45) -> (-1.25, +0.45)   0.80 m
##     (-1.25, +0.45) -> (-1.25, -0.75)   1.20 m
##     (-1.25, -0.75) -> ( 0.00, -0.75)   1.25 m
##                                        ------
##                                        3.25 m one way, 6.50 m for the trip
##
## Six and a half metres, per lookup, for a thing your eye does for nothing. The
## number is not printed anywhere on the object, because an artifact that
## announces its own moral is a poster. It is in the walk.
##
## THE ORIGIN IS THE FLOOR at the centre of the deck. Nothing sits below y = 0 —
## the deck's underside and the key stand's foot are both exactly on it — so the
## piece seats correctly in the maps that skip auto-grounding, which is every map
## token carrying an explicit y. Place the token on the DECK cell; the key stand
## eats floor at -Z, BEHIND the deck, away from the approach.
##
## FACING: this corpus presents +Z and nothing here is turned. The panel's
## printed face looks at +Z, the two plates on it look at +Z, the deck's caption
## looks at +Z, and the key stand behind the deck ALSO looks at +Z — at the back
## of the panel — so a visitor who has walked round stands in the gap between
## them and reads it head on. That is why the key can be a plain untuned
## TextScreen instead of one flipped by PI, which is the mistake that cost
## serial_principle seven captures (see its _build_plate). It also means the key
## is invisible from all four capture angles, and that is correct: the still
## should show that there is something back there and not what it says.

const PbrKit := preload("res://commons/render/pbr_kit.gd")
## THE ONE TEXT LANE. Label3D draws nothing in this project's capture and
## BakedTextAlbedo.make_label_mesh — which is what HangarKit.stencil wraps —
## photographed blank twice on serial_principle's plate after the facing had
## already been corrected. commons/ui/text_screen.gd renders in the same
## capture, in the same session, on the same bench. Every word on this artifact
## goes through it, including the nine one-letter tags, which is heavier than
## nine baked quads and is the price of using the lane that is known to work.
const TextScreenScript := preload("res://commons/ui/text_screen.gd")

# ── Byrne's inks ──────────────────────────────────────────────────────────────
# Letterpress, 1847: vermilion, chrome yellow, ultramarine, black, on rag paper.
# These are NOT config keys and will not become config keys. The colours are the
# argument — a token that could recolour the right-hand half to three greys
# would be a token that switches the artifact off, and "off" is already spelled
# key_side:none, which at least stays honest about what it is doing.
const RED := Color(0.760, 0.150, 0.130)
const YELLOW := Color(0.930, 0.730, 0.110)
const BLUE := Color(0.160, 0.300, 0.580)
const INK_BLACK := Color(0.080, 0.080, 0.085)
const PAPER := Color(0.885, 0.860, 0.795)
const FRAME_INK := Color(0.640, 0.615, 0.560)
## The left-hand fill. ONE grey for all three squares — see the header. Chosen
## dark enough to read as a filled area against PAPER from across a hall and
## light enough that the black bars and the tags still separate from it.
const GREY := Color(0.605, 0.595, 0.565)
const DECK_INK := Color(0.230, 0.235, 0.250)

# ── the figure, in figure units (the 3-4-5 triangle has legs 3 and 4) ─────────
# Euclid I.47's own lettering, kept exactly: triangle ABC right-angled at A, the
# square BDEC on the hypotenuse BC, GFBA on AB, HKCA on AC. Solved rather than
# eyeballed: with BC on the x axis, B at the origin and |AB| = 3, |BC| = 5, the
# foot of A is at 9/5 and its height is 12/5.
const P_A := Vector2(1.8, 2.4)
const P_B := Vector2(0.0, 0.0)
const P_C := Vector2(5.0, 0.0)
const P_D := Vector2(0.0, -5.0)
const P_E := Vector2(5.0, -5.0)
const P_F := Vector2(-2.4, 1.8)
const P_G := Vector2(-0.6, 4.2)
const P_H := Vector2(4.2, 5.6)
const P_K := Vector2(7.4, 3.2)
## The figure's own bounding box: x from -2.4 to 7.4, y from -5.0 to 5.6.
const FIG_SPAN_X := 9.8
const FIG_CENTRE := Vector2(2.5, 0.3)

# ── reference dimensions, metres, at panel_width_m = PANEL_W_REF ──────────────
# Everything scales by one factor k. The text furniture is the exception and it
# is documented at TEXT_PROUD.
const PANEL_W_REF := 1.82
const PANEL_H_REF := 1.45
const PANEL_T_REF := 0.07
const DECK_W_REF := 1.92
const DECK_H_REF := 0.66
const DECK_D_REF := 0.50
## Half-centres on the panel: 0.06 m of outer margin, a 0.78 m content box per
## half, and a 0.14 m seam down the middle. The content box is wider than the
## figure because the LEFT half's tags stand outside it — and both halves get
## the same box, so the two figures are the same size and in the same place.
const HALF_CX_REF := 0.45
## Figure width, metres, at k = 1. The tagged extent is ~0.77 m; the figure
## itself is 0.50 x 0.54.
const FIG_W_REF := 0.50
## Panel-local heights, measured from the panel's bottom edge.
const PLATE_CY_REF := 0.295
const FIG_CY_REF := 0.98
const PLATE_W_REF := 0.62
const KEY_W_REF := 0.78
const KEY_H_REF := 1.20
## The PAD key's width — the `front` control. NOT 0.58, which is what the first
## build shipped and what the clamp argument at panel_width_m claimed was safe.
## TextScreen holds int(w * 0.41292 / MIN_GLYPH_M) body lines (0.62 aspect, 26%
## to the title bar, 90% of the rest usable, 0.035 m floor), so five lines need
## w >= 0.4238 m. At the smallest legal panel — #width:1.30, k = 0.7143 — a 0.58
## reference gives 0.4143 m and FOUR lines, and the key's last entry, "HKCA the
## square on AC", came back as an ellipsis. Silently, on the one square the
## coloured half is arguing about. 0.64 gives 0.4571 m and five lines with 0.39
## of a line of headroom, and still lands on the deck at every k: 4.8 mm of deck
## left in front at k = 0.7143, 14 mm at k = 1.0, 27 mm at k = 1.4286.
const PAD_W_REF := 0.64
const CAPTION_W_REF := 0.52
const CAPTION_CY_REF := 0.40

# ── text_screen.gd's own numbers, mirrored ────────────────────────────────────
## The colliders below are DERIVED from these rather than eyeballed against a
## screenshot, because a collider fitted by eye is the pink_gun fault waiting to
## happen. Grouped and named rather than sprinkled as magic floats so that if
## text_screen.gd ever moves them, the thing that goes wrong is findable.
const TS_ASPECT := 0.62         # screen height / width
const TS_BEZEL := 0.018         # frame border, metres
const TS_PAD_RECLINE := 58.0    # degrees the PAD lies back from vertical
const TS_PAD_BASE_H := 0.03     # the pad's wedge base
const TS_FOOT_H := 0.02         # the STAND's foot disc
const TS_POST_R := 0.012        # the STAND's post
## The screen's own z range about its node: the frame is 12 mm deep centred at
## z = -0.008, so its back is at -0.014; the baked quads sit at +0.004.
const TS_FACE_Z0 := -0.014
const TS_FACE_Z1 := 0.005

# ── ink thicknesses ───────────────────────────────────────────────────────────
## Proud of the panel face. The fills sit under the bars so a bar always wins at
## an edge; both are thin enough that the panel's own collider covers them.
const FILL_D := 0.009
const BAR_D := 0.016
const BAR_W := 0.012
## Every mark is sunk a millimetre INTO the paper rather than sat exactly on it.
## An ink slab whose back face is coplanar with the panel face is not wrong — the
## back face is culled and nothing z-fights — but it is one float rounding away
## from being wrong at a grazing angle, and this artifact is photographed at four
## of them. A millimetre also happens to be what letterpress does to a sheet.
const INK_SINK := 0.001
const TAG_W_REF := 0.085
## How far a tag stands off its vertex, along the ray from the figure's centre.
## Outward, not inward: a tag laid on top of the fill is a tag you have to read
## THROUGH the thing it names, which is a different and much weaker complaint
## than the one this artifact is making.
const TAG_OUT := 0.075
## TextScreen builds its frame 12 mm deep at z = -0.008 and its glass 6 mm deep
## at z = 0, so the back of the frame is 14 mm behind the node origin. 16 mm
## therefore stands a screen 2 mm clear of whatever it is mounted on, which is
## the same millimetre of daylight INK_SINK buys for the ink, in the opposite
## direction. NOT scaled by k: those 14 mm are constants inside text_screen.gd
## and they do not shrink when this artifact does.
const TEXT_PROUD := 0.016
const TOKEN_D := 0.008

# ── the knobs ─────────────────────────────────────────────────────────────────

@export_category("The lookup")
## "back" · "front" · "none". The whole artifact.
##
## back  — the key stands behind the panel, facing the panel's back. Reading the
##         left-hand proof is a round trip of about 6.5 m (arithmetic in the
##         header). This is the shipped case.
## front — the key lies flat on the deck under the lettered half, in reach. This
##         is the control, and it is the case that models a BOOK: the key has
##         not gone away, the walk has, and the indirection is now free. A
##         visitor who finds the front version obviously fine has understood the
##         argument, because that is exactly what a page does to the cost.
## none  — no key at all. The sentence under the left figure still says "the
##         square BDEC" and there is now nothing anywhere that says what BDEC
##         is. Not a broken artifact: an unglossed notation, drawn accurately.
@export var key_side: String = "back"
## Metres from the panel's back face to the key stand. Only used by "back".
## Larger is a longer walk and a bigger footprint; the default is the shortest
## distance that still leaves a body room to stand between the panel and the key
## and read it at arm's length.
@export_range(0.35, 6.0) var key_distance_m: float = 1.05

@export_category("The object")
## Overall width of the printed panel, metres. Everything else is derived from
## it. Clamped narrowly on purpose: TextScreen enforces a legibility floor by
## TRUNCATING the body, so a panel small enough to make the key illegible would
## silently publish a key with the last line cut off, which is a worse failure
## than a panel that is the wrong size for its hall.
@export_range(1.30, 2.60) var panel_width_m: float = 1.82
## Colliders on the deck, the panel and the key stand. The ink is not collided
## separately — every mark is under 16 mm proud of a panel face that is, so a
## hand that touches a red square is stopped by the panel it is printed on,
## where the visitor can see it is being stopped.
@export var solid: bool = true


func _ready() -> void:
	_build()


func _build() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()

	var k: float = clampf(panel_width_m, 1.30, 2.60) / PANEL_W_REF
	var key_d: float = clampf(key_distance_m, 0.35, 6.0)
	var side: String = key_side.strip_edges().to_lower()
	if not (side in ["back", "front", "none"]):
		push_warning("byrne_euclid: key_side '%s' is not back/front/none; standing the key behind the panel" % key_side)
		side = "back"

	var deck_w: float = DECK_W_REF * k
	var deck_h: float = DECK_H_REF * k
	var deck_d: float = DECK_D_REF * k
	var panel_w: float = PANEL_W_REF * k
	var panel_h: float = PANEL_H_REF * k
	var panel_t: float = PANEL_T_REF * k
	# The panel's back is flush with the deck's back, so the whole of the deck's
	# depth becomes a front ledge a visitor can stand at.
	var panel_z: float = -deck_d * 0.5 + panel_t * 0.5
	var panel_face: float = panel_z + panel_t * 0.5
	var panel_back: float = panel_z - panel_t * 0.5

	var deck := PbrKit.box(Vector3(0.0, deck_h * 0.5, 0.0),
		Vector3(deck_w, deck_h, deck_d), PbrKit.worn_metal(DECK_INK, 0.30), -1.0, 0.30)
	deck.name = "Deck"
	add_child(deck)

	var panel := PbrKit.box(Vector3(0.0, deck_h + panel_h * 0.5, panel_z),
		Vector3(panel_w, panel_h, panel_t), PbrKit.rams_body(PAPER, 0.05), -1.0, 0.05)
	panel.name = "Panel"
	add_child(panel)

	# Everything printed lives in this frame: local y is height above the panel's
	# bottom edge, local z is how far the ink stands proud of the paper. One
	# frame for both halves, so the two figures cannot drift apart.
	var face := Node3D.new()
	face.name = "Face"
	face.position = Vector3(0.0, deck_h, panel_face)
	add_child(face)

	_build_figure(face, -HALF_CX_REF * k, FIG_CY_REF * k, k, false)
	_build_figure(face, HALF_CX_REF * k, FIG_CY_REF * k, k, true)

	_build_lettered_plate(face, -HALF_CX_REF * k, PLATE_CY_REF * k, k, side)
	_build_coloured_plate(face, HALF_CX_REF * k, PLATE_CY_REF * k, k)

	var caption := _screen(CAPTION_W_REF * k, 0,
		"BYRNE'S EUCLID", "Oliver Byrne, 1847. one proposition, twice.")
	caption.name = "Caption"
	caption.position = Vector3(0.0, CAPTION_CY_REF * k, deck_d * 0.5 + TEXT_PROUD)
	add_child(caption)

	var key_z: float = panel_back - key_d
	match side:
		"back":
			_build_key_stand(k, key_z)
		"front":
			_build_key_pad(k, deck_h, deck_d)

	if solid:
		_build_collider(k, deck_w, deck_h, deck_d, panel_w, panel_h, panel_t, panel_z, side, key_z)


# ══ THE FIGURE ═══════════════════════════════════════════════════════════════

## Both halves. ONE function, one boolean — see the header. `coloured` false
## gives Byrne's counterpart: identical grey fills, black bars, nine tags.
func _build_figure(parent: Node3D, cx: float, cy: float, k: float, coloured: bool) -> void:
	var half := Node3D.new()
	half.name = "Coloured" if coloured else "Lettered"
	parent.add_child(half)

	var s: float = FIG_W_REF * k / FIG_SPAN_X
	# The rule weight scales with the figure. The alternative — a fixed 12 mm bar
	# at every panel size — would make the drawing heavier as it got smaller, and
	# the one thing that must be true of these two halves is that they are the
	# SAME drawing; letting a shared parameter drift with size would put a second
	# variable into a comparison built to have one.
	var bar_w: float = BAR_W * k
	var bar_mat_black: StandardMaterial3D = _ink(INK_BLACK)

	for sq in _squares():
		var pts: Array = sq["pts"]
		var hue: Color = sq["ink"]
		var fill_c: Color = hue if coloured else GREY
		var bar_c: Color = hue if coloured else INK_BLACK

		# The fill. A square's silhouette is rotation-invariant, so no rotation
		# is applied — the corner list only has to give the centre and the side.
		var q0: Vector2 = pts[0]
		var q1: Vector2 = pts[1]
		var mid := Vector2.ZERO
		for p in pts:
			var pv: Vector2 = p
			mid += pv
		mid *= 0.25
		var side_m: float = (q1 - q0).length() * s
		var fill := _slab(half,
			_at(mid, cx, cy, s) + Vector3(0.0, 0.0, FILL_D * 0.5 - INK_SINK),
			Vector3(side_m, side_m, FILL_D), 0.0, _ink(fill_c))
		fill.name = "Fill_%s" % str(sq["id"])

		# The four edges. The triangle's three sides ARE the inner edge of each
		# square, so drawing every square's perimeter draws the triangle too and
		# there is no separate triangle to keep in step with the squares. The
		# bars overrun by their own width so the corners close.
		var bar_mat: StandardMaterial3D = _ink(bar_c) if coloured else bar_mat_black
		for i in range(4):
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[(i + 1) % 4]
			var e: Vector2 = b - a
			var bar := _slab(half,
				_at((a + b) * 0.5, cx, cy, s) + Vector3(0.0, 0.0, BAR_D * 0.5 - INK_SINK),
				Vector3(e.length() * s + bar_w, bar_w, BAR_D), e.angle(), bar_mat)
			bar.name = "Bar_%s_%d" % [str(sq["id"]), i]

	if coloured:
		return

	# The symbol table. Nine tags, one letter each, standing off their vertex
	# along the ray from the figure's centre so they never sit on the line they
	# label. A was written down here as the one exception — the right angle, a
	# corner of two squares at once, nowhere outward to go. Solved rather than
	# assumed, it is not an exception. The outward ray from A leaves at 108.4
	# degrees; edge AG leaves at 143.1 and edge AH at 53.1, and the wedge between
	# them is open, because the angle at A is a right angle and both its squares
	# are built outward — which leaves 90 degrees of bare paper above it. All
	# nine tags sit on the sheet. None of them sits on a fill.
	for t in _tags():
		var p: Vector2 = t["p"]
		var dir: Vector2 = (p - FIG_CENTRE).normalized()
		# Title empty, letter in the BODY. TextScreen gives its title bar the top
		# 26% of the face and its body the rest, so a one-letter tag written as a
		# title comes out as a hairline strip along the top of an otherwise blank
		# plate. Written as a body it fills the tile, which is what a tag is.
		var tag := _screen(TAG_W_REF * k, 0, "", str(t["t"]))
		tag.name = "Tag_%s" % str(t["t"])
		var out := Vector3(dir.x, dir.y, 0.0) * (TAG_OUT * k)
		tag.position = _at(p, cx, cy, s) + out + Vector3(0.0, 0.0, TEXT_PROUD)
		half.add_child(tag)


## Figure units to the Face frame. z is the caller's business.
func _at(p: Vector2, cx: float, cy: float, s: float) -> Vector3:
	return Vector3(cx + (p.x - FIG_CENTRE.x) * s, cy + (p.y - FIG_CENTRE.y) * s, 0.0)


## The three squares, outward from the triangle, in Euclid's own corner order.
## Built in a function rather than declared as a const array: a const array of
## const Vector2s is legal and it is also the kind of thing that only fails at
## parse time on someone else's Godot build, and a parse failure here takes the
## whole artifact rather than one square.
func _squares() -> Array:
	return [
		{"id": "BDEC", "pts": [P_B, P_C, P_E, P_D], "ink": RED},
		{"id": "GFBA", "pts": [P_A, P_B, P_F, P_G], "ink": YELLOW},
		{"id": "HKCA", "pts": [P_A, P_C, P_K, P_H], "ink": BLUE},
	]


func _tags() -> Array:
	return [
		{"t": "A", "p": P_A}, {"t": "B", "p": P_B}, {"t": "C", "p": P_C},
		{"t": "D", "p": P_D}, {"t": "E", "p": P_E}, {"t": "F", "p": P_F},
		{"t": "G", "p": P_G}, {"t": "H", "p": P_H}, {"t": "K", "p": P_K},
	]


# ══ THE TWO SENTENCES ════════════════════════════════════════════════════════

## The lettered statement. A TextScreen tinted to look like the page it came
## from: bone ground, black type, a paper-coloured frame.
##
## The last clause is DERIVED from key_side and not typed, because a plate that
## says "the key is behind this panel" in a map that shipped `#key:none` is a
## plate that lies, and the one thing a symbol table must not do is promise an
## entry it does not have.
func _build_lettered_plate(parent: Node3D, cx: float, cy: float, k: float, side: String) -> void:
	var tail: String = "the key is behind this panel."
	if side == "front":
		tail = "the key lies on the deck below."
	elif side == "none":
		tail = "there is no key."
	var plate := _screen(PLATE_W_REF * k, 0, "I.47  LETTERED",
		"the square BDEC equals the squares GFBA and HKCA together. " + tail)
	plate.name = "PlateLettered"
	plate.position = Vector3(cx, cy, TEXT_PROUD)
	parent.add_child(plate)


## The same sentence, in Byrne's notation. Same TextScreen, same width, same
## frame, same title — and no body, because the statement is the coloured
## squares below it and they are not words.
##
## THE TOKENS ARE ALL THE SAME SIZE, and that is not laziness about the areas.
## The claim is that 25 = 9 + 16, and drawing the red token two and a half times
## the area of the yellow one would be drawing the ANSWER into the sentence. A
## token is a name. Byrne's coloured squares in running text are the same size
## as each other for the same reason a letter is.
func _build_coloured_plate(parent: Node3D, cx: float, cy: float, k: float) -> void:
	var holder := Node3D.new()
	holder.name = "PlateColoured"
	holder.position = Vector3(cx, cy, 0.0)
	parent.add_child(holder)

	var plate := _screen(PLATE_W_REF * k, 0, "I.47  COLOURED", "")
	plate.name = "Screen"
	plate.position = Vector3(0.0, 0.0, TEXT_PROUD)
	holder.add_child(plate)

	# Laid out below the title band. TextScreen gives its title the top 26% of
	# the screen, so the row drops by half of that to sit centred in what is
	# left — the same place the lettered plate puts its first line of type.
	var plate_h: float = PLATE_W_REF * k * 0.62
	var row_y: float = -plate_h * 0.26 * 0.5
	var row_z: float = TEXT_PROUD + 0.003 + TOKEN_D * 0.5 - INK_SINK

	var tile: float = 0.110 * k
	var op: float = 0.062 * k
	var gap: float = 0.026 * k
	# Five items, four gaps. The row is laid out by advancing a cursor and the
	# gap is added BETWEEN items only — an earlier version added one after every
	# item, which left a trailing gap and pushed the whole sentence half a gap
	# off the centre of a plate whose whole job is to rhyme with the one beside
	# it. The rhyme is the argument; half a centimetre of drift is visible when
	# two identical frames sit 0.9 m apart.
	var run: float = tile * 3.0 + op * 2.0 + gap * 4.0
	var x: float = -run * 0.5

	# red = yellow + blue. The square on the hypotenuse, then the two on the
	# legs, in the order Euclid states them.
	var row: Array = [
		{"kind": "tile", "ink": RED, "id": "BDEC"},
		{"kind": "equals"},
		{"kind": "tile", "ink": YELLOW, "id": "GFBA"},
		{"kind": "plus"},
		{"kind": "tile", "ink": BLUE, "id": "HKCA"},
	]
	for i in range(row.size()):
		var item: Dictionary = row[i]
		if item["kind"] == "tile":
			var hue: Color = item["ink"]
			var sq := _slab(holder, Vector3(x + tile * 0.5, row_y, row_z),
				Vector3(tile, tile, TOKEN_D), 0.0, _ink(hue))
			sq.name = "Token_%s" % str(item["id"])
			x += tile
		elif item["kind"] == "equals":
			_equals(holder, x + op * 0.5, row_y, row_z, op, k)
			x += op
		else:
			_plus(holder, x + op * 0.5, row_y, row_z, op, k)
			x += op
		if i < row.size() - 1:
			x += gap


func _equals(parent: Node3D, x: float, y: float, z: float, w: float, k: float) -> void:
	var t: float = 0.012 * k
	var mat: StandardMaterial3D = _ink(INK_BLACK)
	for i in range(2):
		var s: float = 1.0 if i == 0 else -1.0
		var bar := _slab(parent, Vector3(x, y + s * t * 1.15, z),
			Vector3(w, t, TOKEN_D), 0.0, mat)
		bar.name = "Equals_%d" % i


func _plus(parent: Node3D, x: float, y: float, z: float, w: float, k: float) -> void:
	var t: float = 0.012 * k
	var mat: StandardMaterial3D = _ink(INK_BLACK)
	var h := _slab(parent, Vector3(x, y, z), Vector3(w, t, TOKEN_D), 0.0, mat)
	h.name = "PlusH"
	var v := _slab(parent, Vector3(x, y, z), Vector3(t, w, TOKEN_D), 0.0, mat)
	v.name = "PlusV"


# ══ THE KEY ══════════════════════════════════════════════════════════════════

## The key, standing behind the panel and facing the panel's back — so it faces
## +Z like everything else here, and a visitor who has walked round the deck
## stands between the two and reads it head on. Nothing is rotated.
##
## A TextScreen in STAND mode is already a lectern: screen, post, foot, all
## procedural, all on the floor at y = 0. It is not a second component, it is
## the same one with a post under it.
func _build_key_stand(k: float, key_z: float) -> void:
	var key := _screen(KEY_W_REF * k, 1, "KEY TO THE LETTERS", _key_body(),
		KEY_H_REF * k, DECK_INK)
	key.name = "Key"
	key.position = Vector3(0.0, 0.0, key_z)
	add_child(key)


## The control. The same key, lying flat on the deck under the lettered half,
## where an arm can reach it. PAD mode reclines the screen on a low wedge, which
## is what a reading card on a museum ledge is, and it takes the walk out of the
## lookup without taking the lookup out of the proof.
func _build_key_pad(k: float, deck_h: float, deck_d: float) -> void:
	var key := _screen(PAD_W_REF * k, 2, "KEY TO THE LETTERS", _key_body())
	key.name = "Key"
	key.position = _pad_origin(k, deck_h, deck_d)
	add_child(key)


## Where the pad sits, in ONE place. The collider used to re-derive this from the
## same three constants, which is two implementations of one rule — and the pad
## width had already drifted between them.
func _pad_origin(k: float, deck_h: float, deck_d: float) -> Vector3:
	return Vector3(-HALF_CX_REF * k, deck_h, deck_d * 0.5 - 0.20 * k)


## Five lines, each short enough to survive the smallest legal panel. TextScreen
## truncates rather than shrinking below its own legibility floor, so a key
## written at comfortable length here would quietly lose its last line — the one
## naming the third square — on any map that set #width below about 1.5.
func _key_body() -> String:
	return "A  the right angle\nBC  the hypotenuse\nBDEC  the square on BC\nGFBA  the square on AB\nHKCA  the square on AC"


# ══ MATERIAL, MESH, BODY ═════════════════════════════════════════════════════

## Flat printed ink. Rough, unmetallic, almost no specular — a letterpress sheet
## has no gloss, and a highlight travelling across the red square as the visitor
## moves would say "this is a plastic tile" instead of "this is printed".
##
## Black is the exception and it gets the near-black recipe fetish_portal
## carries: a pure matte dark albedo with the Fresnel killed reads as a HOLE cut
## in the paper rather than as a black line on it. F0 restored, a thin clearcoat
## for a second specular lobe, and a faint cool backlight under the albedo so
## the bar has a terminator instead of falling off a cliff.
func _ink(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.94
	m.metallic = 0.0
	m.metallic_specular = 0.32
	if c.get_luminance() < 0.12:
		m.metallic_specular = 0.5
		m.clearcoat_enabled = true
		m.clearcoat = 0.28
		m.clearcoat_roughness = 0.35
		m.emission_enabled = true
		m.emission = Color(0.20, 0.20, 0.24)
		m.emission_energy_multiplier = 0.10
	return m


## A rectangle of ink lying on the panel, rotated in the panel's own plane.
## BoxMesh throughout: nothing here is hand-written, so the clockwise winding
## this engine wants is Godot's problem and not mine.
func _slab(parent: Node3D, pos: Vector3, size: Vector3, angle: float,
		mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	if not is_zero_approx(angle):
		mi.rotation.z = angle
	parent.add_child(mi)
	return mi


## Every word on this artifact, through the one lane that photographs. `mode` is
## TextScreen's own enum as an int: 0 SCREEN, 1 STAND, 2 PAD.
##
## The tint is the page, not the lab: TextScreen ships a dark-glass palette that
## would put fifteen blue-on-charcoal terminals on a sheet of 1847 rag paper.
##
## `stand_h` and `post_c` are parameters rather than something a caller sets
## afterwards, and that is not tidiness. The local var here is inferred from
## TextScreenScript.new(), so every assignment below is CHECKED against the
## component's real exports; a caller holding the return value has a Node3D and
## `key.stand_height = 1.2` on a Node3D is an unchecked dynamic write that would
## survive a rename of the property it is aiming at. Everything typed goes in
## here where the parser can see it.
func _screen(w: float, mode_i: int, title: String, body: String,
		stand_h: float = -1.0, post_c: Color = FRAME_INK) -> Node3D:
	var s := TextScreenScript.new()
	s.mode = mode_i
	s.width_m = w
	s.title = title
	s.body = body
	s.bg_color = PAPER
	s.frame_color = FRAME_INK
	s.title_color = INK_BLACK
	s.body_color = INK_BLACK
	s.post_color = post_c
	if stand_h > 0.0:
		s.stand_height = stand_h
	return s


## Colliders sized from the geometry above, not inherited from anywhere. The
## key stand gets THREE shapes rather than one box round the whole lectern: its
## foot is a 0.50 m disc 2 cm tall, its post is 2.4 cm across, and its screen is
## 0.82 m wide and floats at head height. One box enclosing all of that would be
## an invisible slab a visitor bounces off half a metre from anything they can
## see — which is the pink_gun fault in the other direction.
##
## Every number here is TS_* — text_screen.gd's own — because a collider fitted
## by eye against a screenshot is how the fault gets in. The front pad's box was
## fitted that way and was 14% short in height and 21% short in depth.
func _build_collider(k: float, deck_w: float, deck_h: float, deck_d: float,
		panel_w: float, panel_h: float, panel_t: float, panel_z: float,
		side: String, key_z: float) -> void:
	var body := StaticBody3D.new()
	body.name = "Solid"
	add_child(body)

	_shape(body, Vector3(0.0, deck_h * 0.5, 0.0), Vector3(deck_w, deck_h, deck_d))
	_shape(body, Vector3(0.0, deck_h + panel_h * 0.5, panel_z),
		Vector3(panel_w, panel_h, panel_t))

	if side == "back":
		var kw: float = KEY_W_REF * k
		var kh: float = kw * TS_ASPECT
		var stand: float = KEY_H_REF * k
		# foot, post, screen — TextScreen's own three parts, at its own numbers
		# (foot bottom radius width*0.32 and 0.02 tall, post radius 0.012, screen
		# width + 2*bezel). The foot box was 0.03 tall against a 0.02 disc, which
		# is a centimetre of invisible lip at ankle height; it is the disc now.
		# The post box is 0.03 across a 0.024 post — 3 mm of skin, kept rather
		# than shrunk to the millimetre because a paper-thin box shape jitters.
		_shape(body, Vector3(0.0, TS_FOOT_H * 0.5, key_z),
			Vector3(kw * 0.64, TS_FOOT_H, kw * 0.64))
		_shape(body, Vector3(0.0, (stand - kh * 0.5) * 0.5, key_z),
			Vector3(TS_POST_R * 2.5, stand - kh * 0.5, TS_POST_R * 2.5))
		_shape(body, Vector3(0.0, stand, key_z),
			Vector3(kw + TS_BEZEL * 2.0, kh + TS_BEZEL * 2.0, 0.05))
	elif side == "front":
		# The pad's envelope, DERIVED from text_screen's own build rather than
		# guessed at. The guess it replaces was a box pw+0.04 x ph*0.62 x ph*0.72
		# centred at ph*0.30 above the deck: measured against the geometry it
		# covers, it stopped 36 mm below the top of the reclined screen and 40 mm
		# short of its back edge — 14% and 21% of the object a visitor leans over.
		#
		# The union of two things: the wedge base (w + 2*bezel) x 0.03 x (h*0.5)
		# sitting at z = h*0.18, and the screen's own box turned -58 degrees about
		# X, which for y in +/-hy and z in [TS_FACE_Z0, TS_FACE_Z1] is
		#     y' =  cos(t)*y + sin(t)*z        z' = -sin(t)*y + cos(t)*z
		# At k = 1 that comes out y 0 .. 0.2759, z -0.1909 .. 0.1862.
		var o: Vector3 = _pad_origin(k, deck_h, deck_d)
		var pw: float = PAD_W_REF * k
		var ph: float = pw * TS_ASPECT
		var hy: float = (ph + TS_BEZEL * 2.0) * 0.5
		var ct: float = cos(deg_to_rad(TS_PAD_RECLINE))
		var st: float = sin(deg_to_rad(TS_PAD_RECLINE))
		var hold: float = TS_PAD_BASE_H + ph * 0.32
		var y_hi: float = maxf(TS_PAD_BASE_H, hold + ct * hy + st * TS_FACE_Z1)
		var z_lo: float = minf(-ph * 0.07, -st * hy + ct * TS_FACE_Z0)
		var z_hi: float = maxf(ph * 0.43, st * hy + ct * TS_FACE_Z1)
		_shape(body, Vector3(o.x, o.y + y_hi * 0.5, o.z + (z_lo + z_hi) * 0.5),
			Vector3(pw + TS_BEZEL * 2.0, y_hi, z_hi - z_lo))


func _shape(body: StaticBody3D, pos: Vector3, size: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = size
	cs.shape = bx
	cs.position = pos
	body.add_child(cs)


# ══ CONFIG ═══════════════════════════════════════════════════════════════════

## Per-cell configuration from a map token. Keys honoured:
##
##   #key:back | #key:front | #key:none   where the key stands
##   #outer:1.05                          metres from the panel's back to the key
##   #width:1.82                          panel width, metres (alias: #size)
##   #solid:false                         drop the colliders
##
## `outer`, `width` and `size` are all in GridInteractablesComponent's
## CONFIG_PARAM_NAMES (:16) and that is load-bearing, not tidy. A `#key:<number>`
## on a name OUTSIDE that list is read as the tutorial's positional shorthand at
## :1705 — the artifact is handed the boolean `true`, the number becomes a
## rotation, and the map looks configured while the object keeps its default.
## `#distance:` and `#offset:` would both be traps, so neither exists.
##
## `key` itself is safe under any name because every value it takes is a WORD,
## and a non-numeric value never reaches the shorthand branch.
##
## `solid` IS NOT in the list, so it must take a word value: `#solid:false`,
## `no` or `off` all fail is_valid_float() and arrive as values. `#solid:0` does
## NOT — "0" parses as a float, takes the shorthand branch, and hands the
## artifact a boolean `true`, so the one spelling that reads as "off" is the one
## that turns the collider ON. And when a lane does pass the raw string through,
## bool("false") is TRUE in GDScript, which is what _flag() is for. Same trap,
## same key, in fetish_portal, serial_principle and eleven_dots — a sweep, not a
## fix for this file.
func apply_grid_config(config_data: Dictionary) -> void:
	# `key` is the token spelling; `key_side` is the export's own name, which is
	# what the registry's parameters block and the DNA channel at
	# GridInteractablesComponent.gd:2236 hand over. Reading only the short one
	# left the long one a dead letter that still looked configured.
	for ks in ["key", "key_side"]:
		if config_data.has(ks):
			key_side = str(config_data[ks]).strip_edges().to_lower()
	for k in ["outer", "key_distance_m"]:
		if config_data.has(k):
			key_distance_m = clampf(float(config_data[k]), 0.35, 6.0)
	for k2 in ["width", "size", "panel_width_m"]:
		if config_data.has(k2):
			panel_width_m = clampf(float(config_data[k2]), 1.30, 2.60)
	if config_data.has("solid"):
		solid = _flag(config_data["solid"])
	if is_inside_tree():
		_build()


## Config values arrive as strings, and bool("0") and bool("false") are both
## true. The helper fetish_portal, eleven_dots and do_not_cross_barrier all
## carry, for the same reason.
func _flag(v) -> bool:
	if typeof(v) == TYPE_BOOL:
		return bool(v)
	return str(v).strip_edges().to_lower() in ["true", "1", "yes", "on"]
