extends Node3D
class_name ExhibitVitrine

const HangarKit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")
## The family's senior term — exhibit_furniture holds the shared cordon and the
## shared brass, because it is the most-placed member of the three.
const ExhibitFamily = preload("res://commons/artifacts/exhibits/exhibit_furniture.gd")

# @identity
# essence: an EMPTY vitrine — a case with nothing in it. The wall-side exhibit affordance: where small and precious things will live. Planted by the gallery-DNA generator as hosting capacity. Now a FAMILY: `enclosure` sets how much glass stands between the visitor and the empty slot (sealed box / bell jar / laid-down cradle / open niche with the glass withdrawn), and `guard` sets how much apparatus the institution puts between a body and the thing — one ordered ladder shared with exhibit_furniture (none < label < fixture < frame < hood < cordon).
# desire: to protect something later — and to be caught deciding how much protection the nothing deserves.
# critical_parameter: enclosure (the degree of the glass) × guard (the rung of apparatus). Both are readable across a room; both are pure appearance.
# triggers: _ready builds the enclosure, then dresses it by guard; apply_grid_config({enclosure, guard, label}).
# emerges: a wall of vitrines set to different enclosures reads as a collection that already has a hierarchy of worth — before a single object exists. The visitor learns what to slow down for from the furniture, not the label.
# needs: nothing; pure affordance.
# relationships: sibling of [[exhibit_podium]]; the small-treasures slot of [[gallery_dna]]; the tall cousin is exhibit_furniture#kind:vitrine_tall — which is also where the family's cordon and brass now live, so a roped case and a roped plinth are the same barrier in the same metal.
# truth: glass with nothing in it still says "this will matter" — and how much glass says how much.

# ── The two axes ──────────────────────────────────────────────────────────────
# 162 maps already hold this prop. enclosure="box" + guard="none" rebuilds the
# legacy body exactly — same two meshes, same sizes, same colours, same positions —
# so none of those rooms can tell the family arrived. Every new value is opt-in
# through a #token, and nothing here touches collision, triggers or timing: the
# vitrine has none and must keep having none.

## How much glass stands between the visitor and the slot.
##   box          — the legacy sealed case: a glass volume on a dark base  (DEFAULT)
##   bell         — a cloche: one narrow column, one dome, one thing
##   cradle       — the reading-room case: the glass laid DOWN over a shallow tray
##   open / niche — the protection withdrawn: an open niche and a brass rail, no glass
@export var enclosure: String = "box"

## How much apparatus the institution puts between a body and the thing. ONE
## ordered ladder, shared with exhibit_furniture and monotone in apparatus — rungs
## 1-2 declare without stopping you, rungs 3-5 put material between:
##   none    — bare case: no word, no light, no frame, no barrier  (DEFAULT)
##   label   — a floor-standing lectern beside the case, with a printed card
##   fixture — a visible housing and a glowing deck: the slot is switched on
##   frame   — black members on every edge, brass corner caps, a bronze plate
##   hood    — degrades to frame: this body IS glass, so what "glass round it"
##             still has to give here is the hardware, not a second pane
##   cordon  — the family barrier: brass stanchions and a crimson rope, alone
## Old spellings (lit, framed, guarded, rail, plain) all still parse — see
## ExhibitFamily.GUARD_ALIASES, which is the family's single table.
@export var guard: String = "none"

## The line printed on the lectern's card at guard=label. Empty falls back to the
## family's default text. Additive and off the default path — nothing reads it
## unless a map both sets #guard:label and writes #label:.
@export var label_text: String = ""

# The legacy palette. Named, not inlined, because the whole additive promise rests
# on these three values staying exactly what they were.
const BASE_DARK := Color(0.25, 0.25, 0.28)
const GLASS_TINT := Color(0.8, 0.9, 0.95, 0.18)
const STONE_PALE := Color(0.62, 0.60, 0.56)
const BRONZE := Color(0.42, 0.31, 0.15)
const FRAME_BLACK := Color(0.09, 0.09, 0.10)

# CONVERGENCE PASS (2026-07-27). BRASS and ROPE_RED used to live here, at
# Color(0.72, 0.55, 0.25) through HangarKit.painted_metal and Color(0.42, 0.07,
# 0.09) — a third brass and a third crimson for the same museum rope the podium
# and the furniture had each already drawn. Both now come from the family
# (ExhibitFamily.brass_material / .rope_material), which is exhibit_furniture's
# own wunderkammer brass and white_cube crimson, so the case's metal matches the
# cabinet standing next to it. None of it is on a default path: guard defaults to
# "none" and no map in the corpus carries a #guard: or #enclosure: token, so the
# 163 live placements are the untouched legacy box.
func _brass() -> StandardMaterial3D:
	return ExhibitFamily.brass_material()

func _ready() -> void:
	_read_meta_overrides()
	_build()

func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_meta_overrides()

func _read_meta_overrides() -> void:
	if has_meta("config_enclosure"):
		enclosure = str(get_meta("config_enclosure")).strip_edges().to_lower()
	# CONVERGENCE: the private GUARD_ALIASES table and _guard_name() that used to sit
	# below are gone. Both artifacts read #guard: through the ONE family reader now,
	# so all ten spellings work on either body and the two vocabularies cannot drift
	# apart again. Two of them resolve differently than they did this morning:
	# `rail` and `guarded` land on `cordon` (one hop further than the local table's
	# rail -> guarded), and they no longer drag the frame along with the rope.
	if has_meta("config_guard"):
		guard = ExhibitFamily.guard_name(str(get_meta("config_guard")))
	if has_meta("config_label"):
		label_text = str(get_meta("config_label"))

func _build() -> void:
	match enclosure:
		"bell":
			_build_bell()
		"cradle":
			_build_cradle()
		# `niche` is what commons/artifacts/registry/exhibits.json advertises for
		# this value; the code has always spelled it `open`, so the token was a
		# ghost — it fell through to the default box and rendered an inert
		# variant. Both spellings now reach the withdrawn niche.
		"open", "niche":
			_build_open()
		_:
			_build_box()

	# The dressing reads the enclosure's measurements rather than hardcoding four
	# sets of numbers — otherwise every new enclosure would owe four new dressings.
	#
	# THE LADDER (see the @export docstring): none < label < fixture < frame < hood
	# < cordon. Five are native; `hood` degrades DOWN one rung to `frame`, because
	# this body already IS glass — box, bell and cradle all keep a transparent
	# shell, and `niche` is defined as that shell withdrawn. A second glass shell
	# over a glass case is the least legible thing this artifact can do and would
	# measure near zero against frame anyway. What "glass round it" still has to
	# give here is precisely the hood's rim cage — members on every edge, brass at
	# the corners — minus the pane the case already owns. One rung, exact.
	var m: Dictionary = _metrics()
	var extent: float = maxf(float(m["half_w"]), float(m["half_d"]))
	match guard:
		"none":
			pass                          # rung 0 — the legacy lineage, 162 rooms
		"label":
			# No new geometry: the lectern is the family's now, at the family's
			# defaults, which are white_cube's — i.e. exactly the object
			# exhibit_furniture has always drawn. This case has no house palette to
			# feed it and needs none.
			ExhibitFamily.lectern(self, extent, {"text": label_text,
					"card_bg": Color(0.93, 0.91, 0.86), "card_fg": Color(0.12, 0.12, 0.12)})
		"fixture":
			# This file's own lamp, now family canon (nothing else in the family had
			# one), called back from where it lives.
			ExhibitFamily.fixture(self, m)
		"frame":
			_dress_framed(m)
		"hood":
			_dress_framed(m)              # degrade: the pane is already here — see above
		"cordon":
			# UNBUNDLED. `guarded` used to build the frame AND the rope; canonical
			# cordon is the rope alone on every sibling. Declared cost: a map can no
			# longer ask for frame and cordon in one token. Accepted — a rung that
			# silently contains a lower rung on one sibling only is not one axis,
			# which is the disease this pass exists to cure. Zero rooms affected.
			ExhibitFamily.cordon(self, extent)
		_:
			pass                          # an unrecognised word is the absence

# Where the case's surfaces are, so `guard` can dress any enclosure:
#   deck_y — the shelf the absent object would sit on
#   rim_y  — where the case's vertical structure stops (a frame cap lands here)
#   top_y  — the very top of the body
#   half_w / half_d — the case's horizontal half-extents
#   round  — true when the case has no corners to put a post on
func _metrics() -> Dictionary:
	match enclosure:
		"bell":
			return {"deck_y": 1.05, "rim_y": 1.65, "top_y": 1.89,
					"half_w": 0.24, "half_d": 0.24, "round": true}
		"cradle":
			return {"deck_y": 0.75, "rim_y": 1.00, "top_y": 1.00,
					"half_w": 0.65, "half_d": 0.33, "round": false}
		"open", "niche":
			return {"deck_y": 0.93, "rim_y": 1.55, "top_y": 1.58,
					"half_w": 0.40, "half_d": 0.275, "round": false}
		_:
			return {"deck_y": 0.90, "rim_y": 1.50, "top_y": 1.50,
					"half_w": 0.37, "half_d": 0.25, "round": false}

# ── Bodies ────────────────────────────────────────────────────────────────────

# The legacy vitrine, unchanged: a dark base 0..0.9 with a faint glass volume
# 0.9..1.5 sitting on it. Every number here is the original one.
func _build_box() -> void:
	var base := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.8, 0.9, 0.55)
	base.mesh = bm
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = BASE_DARK
	bmat.roughness = 0.5
	base.material_override = bmat
	base.position = Vector3(0, 0.45, 0)
	add_child(base)

	var glass := MeshInstance3D.new()
	var gm := BoxMesh.new()
	gm.size = Vector3(0.74, 0.6, 0.5)
	glass.mesh = gm
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = GLASS_TINT
	gmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gmat.roughness = 0.05
	glass.material_override = gmat
	glass.position = Vector3(0, 1.2, 0)
	add_child(glass)

# The cloche. The footprint is cut to a third and the height goes up by a metre,
# because a bell jar that merely rounded the box's corners would be an inert axis:
# the difference has to survive being seen from the far wall, so it is carried by
# the silhouette (narrow column, domed top) and not by a fillet.
func _build_bell() -> void:
	var dark := _mat(BASE_DARK, 0.5)
	_cyl(0.26, 1.0, Vector3(0, 0.5, 0), dark)
	_cyl(0.31, 0.05, Vector3(0, 1.025, 0), _mat(STONE_PALE, 0.55))   # the collar it stands on
	var jar: MeshInstance3D = _cyl(0.24, 0.60, Vector3(0, 1.35, 0), _mat(GLASS_TINT, 0.05))
	jar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var dome := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.24
	sm.height = 0.24          # radius == height is Godot's condition for a true hemisphere
	sm.is_hemisphere = true
	dome.mesh = sm
	dome.material_override = _mat(GLASS_TINT, 0.05)
	dome.position = Vector3(0, 1.65, 0)
	dome.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(dome)

	var knob := MeshInstance3D.new()
	var km := SphereMesh.new()
	km.radius = 0.05
	km.height = 0.10
	knob.mesh = km
	knob.material_override = _brass()
	knob.position = Vector3(0, 1.89, 0)
	add_child(knob)

# The reading-room case: the glass stops standing and lies down. Trades all the
# vertical presence for horizontal spread — a cradle is a body you lean over, not
# one you walk around, and the posture change is the whole point of the value.
func _build_cradle() -> void:
	var dark := _mat(BASE_DARK, 0.5)
	_box(Vector3(1.30, 0.72, 0.66), Vector3(0, 0.36, 0), dark)
	_box(Vector3(1.24, 0.03, 0.60), Vector3(0, 0.735, 0), _mat(Color(0.34, 0.19, 0.17), 0.9))  # felt tray

	# +18° about X, not -18°: the glass has to fall AWAY from the visitor, high at the
	# back and low at the front, or the case reads as a lectern facing the wall.
	var pane: MeshInstance3D = _box(Vector3(1.28, 0.02, 0.66), Vector3(0, 0.90, 0), _mat(GLASS_TINT, 0.05))
	pane.rotation_degrees = Vector3(18, 0, 0)
	pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_box(Vector3(1.28, 0.07, 0.02), Vector3(0, 0.775, 0.325), _mat(GLASS_TINT, 0.05))   # front lip
	for sx_v in [-1.0, 1.0]:
		var sx: float = float(sx_v)
		var rail: MeshInstance3D = _box(Vector3(0.04, 0.09, 0.66), Vector3(sx * 0.645, 0.865, 0), dark)
		rail.rotation_degrees = Vector3(18, 0, 0)   # the side rails follow the glass

# The protection withdrawn. Same base, same footprint, no glass — replaced by an
# opaque niche (back, cheeks, ledge) and a single brass rail. Deleting the glass
# alone would have been a weak value, since the legacy glass is only 18% opaque;
# what makes this read from the doorway is the solid shell arriving where a
# transparent one left.
func _build_open() -> void:
	var dark := _mat(BASE_DARK, 0.5)
	var stone := _mat(Color(0.55, 0.54, 0.52), 0.65)
	_box(Vector3(0.80, 0.90, 0.55), Vector3(0, 0.45, 0), dark)
	_box(Vector3(0.78, 0.03, 0.53), Vector3(0, 0.915, 0), _mat(STONE_PALE, 0.5))
	_box(Vector3(0.80, 0.62, 0.05), Vector3(0, 1.22, -0.25), stone)
	for sx_v in [-1.0, 1.0]:
		var sx: float = float(sx_v)
		_box(Vector3(0.05, 0.62, 0.50), Vector3(sx * 0.375, 1.22, 0), stone)
	_box(Vector3(0.80, 0.06, 0.55), Vector3(0, 1.55, 0), stone)

	var brass: StandardMaterial3D = _brass()
	var rail: MeshInstance3D = _cyl(0.018, 0.74, Vector3(0, 1.10, 0.235), brass)
	rail.rotation_degrees = Vector3(0, 0, 90)
	for sx_v in [-1.0, 1.0]:
		var sx: float = float(sx_v)
		_cyl(0.022, 0.20, Vector3(sx * 0.37, 1.00, 0.235), brass)

# ── Dressing (guard) ─────────────────────────────────────────────────────────

# CONVERGENCE: `_dress_lit` used to live here — the glowing deck plate, the housing
# with its emissive lens, the stems, the OmniLight. It is ExhibitFamily.fixture()
# now, number for number, because the family's rule out of this pass is that a
# builder becomes canon exactly when TWO members build it, and exhibit_furniture
# had no lamp of its own to offer its `fixture` rung. Nothing moved but the file.
# (The lens and the glow are built through the family's own emissive material
# rather than HangarKit's, which is the same material with the same energies.)

# Museum-grade. The frame is the institution's signature written in extrusion: black
# members on every edge the glass has, brass at the corners, a bronze plate on the
# front. It costs the legacy vitrine's frameless calm — which is the trade, since
# frameless calm is exactly what "this is ordinary" looks like.
#
# Stays PRIVATE, unlike the lamp: only this member builds a frame (a plinth has no
# glazing to edge, so exhibit_furniture answers `frame` with its hood), and a
# builder only one member builds is not family canon.
func _dress_framed(m: Dictionary) -> void:
	var deck_y: float = float(m["deck_y"])
	var rim_y: float = float(m["rim_y"])
	var hw: float = float(m["half_w"])
	var hd: float = float(m["half_d"])
	var is_round: bool = bool(m["round"])
	var black := _mat(FRAME_BLACK, 0.35)
	var brass: StandardMaterial3D = _brass()
	var post_h: float = maxf(rim_y - deck_y, 0.08)

	if is_round:
		# No corners to stand on: the bell gets two brass collars and four straps
		# spaced around the jar — the cloche's own idiom rather than a box's.
		_cyl(hw + 0.05, 0.04, Vector3(0, deck_y + 0.02, 0), brass)
		_cyl(hw + 0.03, 0.035, Vector3(0, rim_y - 0.017, 0), brass)
		for i in 4:
			var a: float = float(i) * PI * 0.5 + PI * 0.25
			_box(Vector3(0.03, post_h, 0.03),
					Vector3(sin(a) * (hw + 0.02), deck_y + post_h * 0.5, cos(a) * (hw + 0.02)), brass)
	else:
		for sx_v in [-1.0, 1.0]:
			var sx: float = float(sx_v)
			for sz_v in [-1.0, 1.0]:
				var sz: float = float(sz_v)
				_box(Vector3(0.045, post_h, 0.045),
						Vector3(sx * hw, deck_y + post_h * 0.5, sz * hd), black)
				_box(Vector3(0.075, 0.05, 0.075),
						Vector3(sx * hw, deck_y + 0.025, sz * hd), brass)
		# Four top rails, not one solid cap: a plate would read as a closed lid on the
		# low cradle, and a frame that only frames when the case is tall is half an axis.
		var cap_y: float = rim_y + 0.025
		for sz2_v in [-1.0, 1.0]:
			var sz2: float = float(sz2_v)
			_box(Vector3(hw * 2.0 + 0.10, 0.05, 0.05), Vector3(0, cap_y, sz2 * hd), black)
			_box(Vector3(0.05, 0.05, hd * 2.0 + 0.10), Vector3(sz2 * hw, cap_y, 0), black)

	var plate: MeshInstance3D = _box(Vector3(0.30, 0.16, 0.02),
			Vector3(0, deck_y * 0.55, hd + 0.06), HangarKit.painted_metal(BRONZE, 0.2, 0.8, 0.4))
	plate.rotation_degrees = Vector3(-32, 0, 0)

# The rope — rung 5, and the top of the ladder — is ExhibitFamily.cordon(), called
# straight from the match block above. The museum's oldest sentence, said in
# furniture: the case's footprint roughly triples and the visitor's line is drawn a
# stride back. It is the rung that spends floor area, which is why it is the one
# legible from the doorway.
#
# CONVERGENCE: this was 40 lines of its own stanchions — 1.0 m posts at Ø0.10, a
# sphere cap, three tilted BOXES per span for the sag, standing 0.55 m off the case
# in a crimson one hundredth off the other two in the family. What changed when it
# became a call into the shared cordon: the ring came in 11 cm, the posts lost
# 14 cm and gained the family's turned knob, the rope became round rods with a
# deeper 0.14 sag, and the brass is the family's. What changed today: it arrives
# WITHOUT the frame. Not a default path — guard defaults to none, and no map in the
# corpus carries the token.

# ── Primitives ────────────────────────────────────────────────────────────────

func _mat(c: Color, rough: float = 0.6) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if c.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m

func _box(size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi: MeshInstance3D = HangarKit.box(pos, size, mat)
	add_child(mi)
	return mi

func _cyl(radius: float, height: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = height
	var mi := MeshInstance3D.new()
	mi.mesh = cm
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
	return mi
