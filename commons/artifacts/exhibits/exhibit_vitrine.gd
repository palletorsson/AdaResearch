extends Node3D
class_name ExhibitVitrine

const HangarKit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# @identity
# essence: an EMPTY vitrine — a case with nothing in it. The wall-side exhibit affordance: where small and precious things will live. Planted by the gallery-DNA generator as hosting capacity. Now a FAMILY: `enclosure` sets how much glass stands between the visitor and the empty slot (sealed box / bell jar / laid-down cradle / open niche with the glass withdrawn), and `guard` sets how loudly the building declares that slot precious (none / lit / framed / guarded).
# desire: to protect something later — and to be caught deciding how much protection the nothing deserves.
# critical_parameter: enclosure (the degree of the glass) × guard (the volume of the claim). Both are readable across a room; both are pure appearance.
# triggers: _ready builds the enclosure, then dresses it by guard; apply_grid_config({enclosure, guard}).
# emerges: a wall of vitrines set to different enclosures reads as a collection that already has a hierarchy of worth — before a single object exists. The visitor learns what to slow down for from the furniture, not the label.
# needs: nothing; pure affordance.
# relationships: sibling of [[exhibit_podium]]; the small-treasures slot of [[gallery_dna]]; the tall cousin is exhibit_furniture#kind:vitrine_tall.
# truth: glass with nothing in it still says "this will matter" — and how much glass says how much.

# ── The two axes ──────────────────────────────────────────────────────────────
# 162 maps already hold this prop. enclosure="box" + guard="none" rebuilds the
# legacy body exactly — same two meshes, same sizes, same colours, same positions —
# so none of those rooms can tell the family arrived. Every new value is opt-in
# through a #token, and nothing here touches collision, triggers or timing: the
# vitrine has none and must keep having none.

## How much glass stands between the visitor and the slot.
##   box    — the legacy sealed case: a glass volume on a dark base  (DEFAULT)
##   bell   — a cloche: one narrow column, one dome, one thing
##   cradle — the reading-room case: the glass laid DOWN over a shallow tray
##   open   — the protection withdrawn: an open niche and a brass rail, no glass
@export var enclosure: String = "box"

## How loudly the building declares the empty slot precious.
##   plain   — bare case: no light, no frame, no barrier  (DEFAULT)
##   lit     — a visible fixture inside and a glowing deck: the slot is switched on
##   framed  — black members on every edge, brass corner caps, a bronze plate
##   guarded - framed, plus a rope on four brass stanchions: do not approach
@export var guard: String = "none"

# The legacy palette. Named, not inlined, because the whole additive promise rests
# on these three values staying exactly what they were.
const BASE_DARK := Color(0.25, 0.25, 0.28)
const GLASS_TINT := Color(0.8, 0.9, 0.95, 0.18)
const STONE_PALE := Color(0.62, 0.60, 0.56)
const BRASS := Color(0.72, 0.55, 0.25)
const BRONZE := Color(0.42, 0.31, 0.15)
const ROPE_RED := Color(0.42, 0.07, 0.09)
const FRAME_BLACK := Color(0.09, 0.09, 0.10)

func _ready() -> void:
	_read_meta_overrides()
	_build()

func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_meta_overrides()

func _read_meta_overrides() -> void:
	if has_meta("config_enclosure"):
		enclosure = str(get_meta("config_enclosure"))
	# accepts the new name; the old one is still honoured because the agent that wrote
	# this artifact shipped `regard` and something may already reference it
	if has_meta("config_guard"):
		guard = str(get_meta("config_guard"))
	elif has_meta("config_regard"):
		guard = str(get_meta("config_regard"))

func _build() -> void:
	match enclosure:
		"bell":
			_build_bell()
		"cradle":
			_build_cradle()
		"open":
			_build_open()
		_:
			_build_box()

	# The dressing reads the enclosure's measurements rather than hardcoding four
	# sets of numbers — otherwise every new enclosure would owe four new dressings.
	var m: Dictionary = _metrics()
	match guard:
		"lit":
			_dress_lit(m)
		"framed":
			_dress_framed(m)
		"guarded":
			_dress_framed(m)
			_dress_guard(m)
		_:
			pass

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
		"open":
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
	knob.material_override = HangarKit.painted_metal(BRASS, 0.1, 0.7, 0.3)
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

	var brass: StandardMaterial3D = HangarKit.painted_metal(BRASS, 0.1, 0.7, 0.35)
	var rail: MeshInstance3D = _cyl(0.018, 0.74, Vector3(0, 1.10, 0.235), brass)
	rail.rotation_degrees = Vector3(0, 0, 90)
	for sx_v in [-1.0, 1.0]:
		var sx: float = float(sx_v)
		_cyl(0.022, 0.20, Vector3(sx * 0.37, 1.00, 0.235), brass)

# ── Dressing (guard) ─────────────────────────────────────────────────────────

# Switched on. Deliberately NOT a light-energy knob: info_board proved that a knob
# a still cannot see is decoration. So the value ships hardware — a glowing deck
# plate, a fixture housing with a lens, the stems holding it — and the OmniLight is
# only the seasoning on top of geometry that would still read in a fullbright shot.
func _dress_lit(m: Dictionary) -> void:
	var deck_y: float = float(m["deck_y"])
	var rim_y: float = float(m["rim_y"])
	var hw: float = float(m["half_w"])
	var hd: float = float(m["half_d"])
	var is_round: bool = bool(m["round"])
	var glow: StandardMaterial3D = HangarKit.emissive(Color(1.0, 0.96, 0.88), 1.4)
	var lens: StandardMaterial3D = HangarKit.emissive(Color(1.0, 0.97, 0.90), 3.2)
	var dark := _mat(FRAME_BLACK, 0.4)

	if is_round:
		_cyl(hw - 0.05, 0.02, Vector3(0, deck_y + 0.015, 0), glow)
		_cyl(0.022, rim_y - deck_y - 0.14, Vector3(0, (deck_y + rim_y - 0.10) * 0.5, 0), dark)
		_cyl(0.075, 0.05, Vector3(0, rim_y - 0.10, 0), lens)
	else:
		_box(Vector3(hw * 2.0 - 0.08, 0.02, hd * 2.0 - 0.08), Vector3(0, deck_y + 0.015, 0), glow)
		var z_back: float = -hd + 0.07
		_box(Vector3(hw * 2.0 - 0.12, 0.05, 0.06), Vector3(0, rim_y - 0.09, z_back), dark)
		_box(Vector3(hw * 2.0 - 0.18, 0.02, 0.04), Vector3(0, rim_y - 0.12, z_back), lens)
		var stem_h: float = maxf(rim_y - deck_y - 0.12, 0.06)
		for sx_v in [-1.0, 1.0]:
			var sx: float = float(sx_v)
			_box(Vector3(0.022, stem_h, 0.022),
					Vector3(sx * (hw - 0.05), deck_y + stem_h * 0.5, z_back), dark)

	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0, deck_y + (rim_y - deck_y) * 0.55, 0)
	lamp.omni_range = maxf(1.6, hw * 4.0)
	lamp.light_energy = 2.4
	lamp.light_color = Color(1.0, 0.95, 0.85)
	add_child(lamp)

# Museum-grade. The frame is the institution's signature written in extrusion: black
# members on every edge the glass has, brass at the corners, a bronze plate on the
# front. It costs the legacy vitrine's frameless calm — which is the trade, since
# frameless calm is exactly what "this is ordinary" looks like.
func _dress_framed(m: Dictionary) -> void:
	var deck_y: float = float(m["deck_y"])
	var rim_y: float = float(m["rim_y"])
	var hw: float = float(m["half_w"])
	var hd: float = float(m["half_d"])
	var is_round: bool = bool(m["round"])
	var black := _mat(FRAME_BLACK, 0.35)
	var brass: StandardMaterial3D = HangarKit.painted_metal(BRASS, 0.1, 0.7, 0.35)
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

# The rope. The museum's oldest sentence, said in furniture: the case's footprint
# roughly triples and the visitor's line is drawn a stride back. This is the value
# that has to be legible from the doorway, so it is the one that spends floor area.
func _dress_guard(m: Dictionary) -> void:
	var hw: float = float(m["half_w"])
	var hd: float = float(m["half_d"])
	var r: float = maxf(hw, hd) + 0.55
	var brass: StandardMaterial3D = HangarKit.painted_metal(BRASS, 0.1, 0.7, 0.35)

	for sx_v in [-1.0, 1.0]:
		var sx: float = float(sx_v)
		for sz_v in [-1.0, 1.0]:
			var sz: float = float(sz_v)
			_cyl(0.05, 1.0, Vector3(sx * r, 0.5, sz * r), brass)
			var cap := MeshInstance3D.new()
			var cm := SphereMesh.new()
			cm.radius = 0.075
			cm.height = 0.15
			cap.mesh = cm
			cap.material_override = brass
			cap.position = Vector3(sx * r, 1.04, sz * r)
			add_child(cap)

	var rope := _mat(ROPE_RED, 0.85)
	for s_v in [-1.0, 1.0]:
		var s: float = float(s_v)
		_rope(true, s * r, r * 2.0, 0.88, rope)
		_rope(false, s * r, r * 2.0, 0.88, rope)

# A stanchion rope as three tilted segments. A real catenary would want a generated
# mesh; the sag only has to read at gallery distance, and three boxes buy that for
# nothing. The ropes are axis-aligned, which is why a single rotation axis suffices.
func _rope(along_x: bool, fixed: float, span: float, y: float, mat: StandardMaterial3D) -> void:
	var seg: float = span / 3.0
	var sag: float = 0.08
	for i in 3:
		var t: float = (float(i) - 1.0) * seg
		var drop: float = sag if i == 1 else sag * 0.5
		var tilt: float = 0.0 if i == 1 else (9.0 if i == 0 else -9.0)
		var piece: MeshInstance3D
		if along_x:
			piece = _box(Vector3(seg, 0.035, 0.035), Vector3(t, y - drop, fixed), mat)
			piece.rotation_degrees = Vector3(0, 0, tilt)
		else:
			piece = _box(Vector3(0.035, 0.035, seg), Vector3(fixed, y - drop, t), mat)
			piece.rotation_degrees = Vector3(-tilt, 0, 0)

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
