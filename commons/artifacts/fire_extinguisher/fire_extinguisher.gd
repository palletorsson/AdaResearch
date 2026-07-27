extends Node3D
class_name FireExtinguisher

# @identity
# essence: a wall-mounted red cylinder — Half-Life / industrial-corridor vocabulary. Bright alarm-red body, narrower steel valve and pinch handle on top, a coiled black hose curving down one side, a small steel wall bracket holding the cylinder against the wall, a white accent band around the middle and a white "FIRE" Label3D on the front. The artifact does not promise safety; it promises that danger is anticipated
# desire: every lab corridor wants a single, unmistakable signal that says THE DANGER HERE IS NAMED. The extinguisher wants to be visible from across the room — a saturated red against neutral lab walls. Recognition before reading. The eye finds it before the mind interprets it
# critical_parameter: wall_bracket + hose_visible — bracket OFF + hose OFF reads as a free-standing emergency object on the floor. Bracket ON + hose ON reads as fully-mounted corridor infrastructure. Same cylinder, two very different rooms — one where the device has been deployed, one where it is permanently at-the-ready
# triggers: _ready() builds bracket + body + neck + valve + handle + hose segments + accent band + label from exports; apply_grid_config rebuilds
# emerges: bright red against pale walls = ALARM PRESENT. Coiled hose = USED OR MAINTAINED. Wall bracket = INSTITUTIONAL. Together they encode the lab's confession that fire is one of the things that can happen here
# needs: vertical cylinder body in alarm red [present]; narrow neck/valve on top [present]; pinch handle (small box) [present]; coiled black hose curving down to one side [present]; wall bracket box behind cylinder [present]; white accent band wrapping the middle [present]; "FIRE" Label3D on the front [present]
# relationships: peer to safety_shower (both = response-to-named-hazard, one for fire one for chemical); sibling to exit_sign (both = wall-mounted emergency vocabulary, one for ignition one for escape); cousin to emergency_button (the corridor's grammar of TROUBLE-IS-ANTICIPATED); the lab's quiet admission that its experiments can fail loudly
# truth: a fire extinguisher is the architectural form of NAMED DANGER. By placing it, the lab confesses what it fears. A space without one says either "nothing burns here" or "we have not thought about what burns here." A space WITH one says "we have thought about it; here is the answer." The red is not decorative — red is the colour of "you will see me before you need me"

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-07-27) — SHARED VOCABULARY WITH fire_hose_box.
# 302 placements here, 439 there. These two are the same institution's safety
# equipment; they are promoted together and they answer to THE SAME TWO TOKENS
# with THE SAME VALUE NAMES. If you add a value to one file, add it to the other
# in the same commit or the family forks. The long comment in fire_hose_box.gd is
# the canonical statement of the axis; this is the short form.
#
#   station   HOW IT IS HELD        bracket · cabinet · stand
#   statute   WHAT THE BUILDING     issue · notice · joinery · lapse
#             DID WITH THE LAW
#
# This identity says "visible from across the room", "recognition before reading",
# "you will see me before you need me". Its whole claim is about how legible the
# named danger is made — and this is the one class of object whose appearance is
# written down in law rather than chosen. So: what did this building do with that
# law? `issue` is the object as delivered and nothing more (legacy). `notice` is
# full submission — backing board, mandatory sign, projecting flag, painted floor
# zone. `joinery` is absorption: the alarm red retinted into the building's own
# cabinetwork, one small engraved plate instead of the shout. `lapse` is the
# promise left to rot — chalked paint, rust, an expired service tag.
#
# `station` is body: the steel bracket (legacy), a glazed wall cabinet, or a
# free-standing weighted post — the site fire point, safety wheeled in.
#
# station=bracket and statute=issue are the legacy lineage exactly: _build_station()
# and _build_statute() return on the first line for those values, _lv()/_ink() are
# identity functions unless the statute entry carries a tint, and NOTHING mutates
# body_color / accent_color / label_color (a rebuild must not compound a fade, and
# an explicit #body_color: override must still be the colour that gets faded). All
# 302 existing placements — none of which sets a single config token today, and
# including the ones this scene is instantiated INTO by shelf_wedge and the prop
# ring — are untouched.
#
# Deliberately NOT retinted: SIGN_RED. A sign is the law speaking, and the law is
# not the building's decorator (exhibit_furniture makes the same carve-out for
# EXIT green and FIRE red). Under `joinery` that leaves one red mark the building
# could not repaint.
# ─────────────────────────────────────────────────────────────────────────────

## A wall-mounted red fire extinguisher.
##
## Built procedurally from DNA exports. Origin is at the bottom center of
## the cylinder body, on the floor (or on the mounting surface). The
## label faces +Z (the device reads from the +Z side). Wall bracket sits
## behind the cylinder along -Z.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var extinguisher_height: float = 0.55
@export var extinguisher_radius: float = 0.075

@export_group("Color")
## Alarm red — the canonical extinguisher body color.
@export var body_color: Color = Color(0.78, 0.08, 0.08)
@export var accent_color: Color = Color(0.96, 0.96, 0.96)        # white accent band
@export var label_color: Color = Color(0.98, 0.98, 0.98)         # white label

@export_group("Hardware")
@export var hose_visible: bool = true
@export var wall_bracket: bool = true

@export_group("Label")
@export var label_text: String = "FIRE"
## When TRUE (default), the label text is baked into the cylinder body's
## albedo_texture via a SubViewport-rendered ImageTexture — the FIRE
## reads as paint on the cylinder, lit by scene lights. When FALSE the
## artifact falls back to the original Label3D floating in front.
@export var bake_label_into_body: bool = true
## U coordinate (0..1) around the cylinder where the baked text appears.
## CylinderMesh default UV: 0=+X, 0.25=+Z (front), 0.5=-X, 0.75=-Z.
@export_range(0.0, 1.0, 0.01) var label_uv_x: float = 0.5
## V coordinate (0..1) along the cylinder height. 0.5 = middle.
@export_range(0.0, 1.0, 0.01) var label_uv_y: float = 0.5

@export_group("Family")
## AXIS 1 — how the building HOLDS the equipment. Shared verbatim with
## fire_hose_box: bracket (legacy default, the steel bracket against the wall) |
## cabinet (a glazed red wall cabinet around the cylinder) | stand (a weighted
## free-standing post with a sign, safety wheeled in rather than built in).
@export var station: String = "bracket"
## AXIS 2 — what the building did with the law that specifies this object's
## appearance. Shared verbatim with fire_hose_box: issue (legacy default, as
## delivered, nothing added) | notice (full submission — backing board, mandatory
## sign, projecting flag, painted floor zone) | joinery (absorbed into the
## building's cabinetwork, retinted, one small engraved plate) | lapse (the
## promise left to rot — chalked paint, rust, an expired tag).
@export var statute: String = "issue"

# ── External helpers ──────────────────────────────────────────────────

const BakedTextAlbedoScript := preload("res://commons/utils/baked_text_albedo.gd")

# ── Constants ─────────────────────────────────────────────────────────

const NECK_HEIGHT_FACTOR: float = 0.085          # vs extinguisher_height
const NECK_RADIUS_FACTOR: float = 0.42           # vs extinguisher_radius
const VALVE_HEIGHT_FACTOR: float = 0.07
const VALVE_RADIUS_FACTOR: float = 0.55
const HANDLE_LENGTH_FACTOR: float = 1.2          # vs extinguisher_radius
const HANDLE_HEIGHT: float = 0.022
const HANDLE_DEPTH: float = 0.024
const ACCENT_BAND_HEIGHT: float = 0.022
const HOSE_SEGMENT_COUNT: int = 3
const HOSE_RADIUS: float = 0.011
const BRACKET_WIDTH_FACTOR: float = 1.6          # vs extinguisher_radius (wider than the cylinder)
const BRACKET_HEIGHT_FACTOR: float = 0.45        # vs extinguisher_height
const BRACKET_DEPTH: float = 0.035
const LABEL_PIXEL_SIZE: float = 0.0028
const LABEL_FONT_SIZE: int = 40

# ── Family axes ───────────────────────────────────────────────────────

## The statute's own colours. NOT routed through `statute` — see the note above.
## Kept numerically identical to fire_hose_box.gd: the two must sign in one hand.
const SIGN_RED: Color = Color(0.70, 0.09, 0.10)
const BOARD_WHITE: Color = Color(0.93, 0.93, 0.91)

## How `statute` treats the equipment's own skin. Identical table to
## fire_hose_box.gd — the same building treats both pieces the same way.
## `issue` and `notice` carry NO keys, so _lv()/_ink() hand the legacy colours
## straight back. An unknown value degrades the same way.
const STATUTES: Dictionary = {
	"issue": {},
	"notice": {},
	# Alarm red 0.78/0.08 lands near (0.33, 0.27, 0.24) — a dark taupe. The
	# cylinder stops being red, which is the loudest read in the family and, in
	# most jurisdictions, illegal.
	"joinery": {"tint": Color(0.27, 0.29, 0.26), "amt": 0.88, "rough": 0.90,
			"metal": 0.06, "ink": Color(0.44, 0.46, 0.42), "ink_amt": 1.0},
	# Twenty years of corridor light: red chalks up toward (0.69, 0.28, 0.27),
	# a washed brick pink, and goes flat.
	"lapse": {"tint": Color(0.60, 0.45, 0.42), "amt": 0.58, "rough": 0.95,
			"metal": 0.03, "ink": Color(0.56, 0.53, 0.48), "ink_amt": 0.85},
}

const CAB_PLINTH: float = 0.035    # cabinet plinth under the cylinder's foot
const STAND_BASE: float = 0.048    # stand base-plate thickness below the cylinder's foot
const STAND_POST: float = 1.55     # sign post height — the thing you see over a bench

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_extinguisher()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_extinguisher()


func _read_metadata_overrides() -> void:
	if has_meta("config_extinguisher_height"):
		extinguisher_height = float(str(get_meta("config_extinguisher_height")))
	if has_meta("config_extinguisher_radius"):
		extinguisher_radius = float(str(get_meta("config_extinguisher_radius")))
	if has_meta("config_body_color"):
		body_color = _parse_color(str(get_meta("config_body_color")), body_color)
	if has_meta("config_accent_color"):
		accent_color = _parse_color(str(get_meta("config_accent_color")), accent_color)
	if has_meta("config_label_color"):
		label_color = _parse_color(str(get_meta("config_label_color")), label_color)
	if has_meta("config_hose_visible"):
		var hv := str(get_meta("config_hose_visible")).to_lower()
		hose_visible = hv in ["true", "1", "yes", "on"]
	if has_meta("config_wall_bracket"):
		var wb := str(get_meta("config_wall_bracket")).to_lower()
		wall_bracket = wb in ["true", "1", "yes", "on"]
	if has_meta("config_label_text"):
		label_text = str(get_meta("config_label_text"))
	if has_meta("config_station"):
		station = str(get_meta("config_station"))
	if has_meta("config_statute"):
		statute = str(get_meta("config_statute"))


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_extinguisher() -> void:
	_built = true
	if wall_bracket:
		_build_bracket()
	_build_body()
	_build_neck_and_valve()
	_build_handle()
	_build_accent_band()
	if hose_visible:
		_build_hose()
	if bake_label_into_body:
		# New path — TextServer renders the label glyphs into an Image,
		# the Image becomes a Decal's albedo, the Decal projects the
		# label onto the cylinder body's surface. No SubViewport, no
		# per-instance material composite. Works under --no-window.
		_build_label_decal()
	else:
		_build_label()
	# Both return on their first line for the legacy values — see the promotion
	# note at the top. station=bracket + statute=issue adds not one mesh.
	_build_station()
	_build_statute()


func _build_bracket() -> void:
	# A simple steel mounting bracket behind the cylinder on -Z.
	var bracket := MeshInstance3D.new()
	bracket.name = "Bracket"
	var mesh := BoxMesh.new()
	var bw: float = extinguisher_radius * BRACKET_WIDTH_FACTOR
	var bh: float = extinguisher_height * BRACKET_HEIGHT_FACTOR
	mesh.size = Vector3(bw, bh, BRACKET_DEPTH)
	bracket.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.32, 0.32, 0.34)
	mat.roughness = 0.55
	mat.metallic = 0.55
	bracket.material_override = mat
	# Centered on cylinder midpoint along Y, behind on -Z.
	var by: float = extinguisher_height * 0.5
	var bz: float = -extinguisher_radius - BRACKET_DEPTH * 0.5
	bracket.position = Vector3(0.0, by, bz)
	add_child(bracket)


func _build_body() -> void:
	var body := MeshInstance3D.new()
	body.name = "Body"
	var mesh := CylinderMesh.new()
	mesh.top_radius = extinguisher_radius
	mesh.bottom_radius = extinguisher_radius * 1.02
	mesh.height = extinguisher_height
	body.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _lv(body_color)
	mat.roughness = _lv_rough(0.35)
	mat.metallic = _lv_metal(0.3)
	body.material_override = mat
	body.position = Vector3(0.0, extinguisher_height * 0.5, 0.0)
	add_child(body)


func _build_neck_and_valve() -> void:
	# Narrower cylinder above the body (the neck), then a small dark valve cap.
	var neck := MeshInstance3D.new()
	neck.name = "Neck"
	var nm := CylinderMesh.new()
	var neck_h: float = extinguisher_height * NECK_HEIGHT_FACTOR
	var neck_r: float = extinguisher_radius * NECK_RADIUS_FACTOR
	nm.top_radius = neck_r * 0.9
	nm.bottom_radius = neck_r
	nm.height = neck_h
	neck.mesh = nm
	var nmat := StandardMaterial3D.new()
	nmat.albedo_color = Color(0.20, 0.20, 0.22)
	nmat.roughness = 0.45
	nmat.metallic = 0.7
	neck.material_override = nmat
	neck.position = Vector3(0.0, extinguisher_height + neck_h * 0.5, 0.0)
	add_child(neck)

	# Valve cap (slightly wider disc) on top of the neck.
	var valve := MeshInstance3D.new()
	valve.name = "Valve"
	var vm := CylinderMesh.new()
	var valve_h: float = extinguisher_height * VALVE_HEIGHT_FACTOR
	var valve_r: float = extinguisher_radius * VALVE_RADIUS_FACTOR
	vm.top_radius = valve_r
	vm.bottom_radius = valve_r * 1.05
	vm.height = valve_h
	valve.mesh = vm
	var vmat := StandardMaterial3D.new()
	vmat.albedo_color = Color(0.18, 0.18, 0.20)
	vmat.roughness = 0.5
	vmat.metallic = 0.6
	valve.material_override = vmat
	valve.position = Vector3(0.0, extinguisher_height + neck_h + valve_h * 0.5, 0.0)
	add_child(valve)


func _build_handle() -> void:
	# A small horizontal box across the top of the valve — the pinch handle.
	var handle := MeshInstance3D.new()
	handle.name = "Handle"
	var hm := BoxMesh.new()
	var hw: float = extinguisher_radius * HANDLE_LENGTH_FACTOR
	hm.size = Vector3(hw, HANDLE_HEIGHT, HANDLE_DEPTH)
	handle.mesh = hm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.18, 0.20)
	mat.roughness = 0.45
	mat.metallic = 0.7
	handle.material_override = mat
	# Slight rotation around Z so it tilts up like a pinch lever.
	handle.rotation = Vector3(0.0, 0.0, deg_to_rad(-8.0))
	var neck_h: float = extinguisher_height * NECK_HEIGHT_FACTOR
	var valve_h: float = extinguisher_height * VALVE_HEIGHT_FACTOR
	var y: float = extinguisher_height + neck_h + valve_h + HANDLE_HEIGHT * 0.55
	handle.position = Vector3(0.0, y, 0.0)
	add_child(handle)


func _build_accent_band() -> void:
	# A white band wrapping the middle of the cylinder body.
	var band := MeshInstance3D.new()
	band.name = "AccentBand"
	var mesh := CylinderMesh.new()
	mesh.top_radius = extinguisher_radius * 1.015
	mesh.bottom_radius = extinguisher_radius * 1.015
	mesh.height = ACCENT_BAND_HEIGHT
	band.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _ink(accent_color)
	mat.roughness = 0.45
	mat.metallic = 0.15
	band.material_override = mat
	band.position = Vector3(0.0, extinguisher_height * 0.55, 0.0)
	add_child(band)


func _build_hose() -> void:
	# Approximated coiled hose: a few short cylinder segments hanging down
	# the side, each rotated to form a gentle curve toward -X.
	var root := Node3D.new()
	root.name = "Hose"
	add_child(root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.07, 0.07, 0.08)
	mat.roughness = 0.6
	mat.metallic = 0.0

	var neck_h: float = extinguisher_height * NECK_HEIGHT_FACTOR
	var valve_h: float = extinguisher_height * VALVE_HEIGHT_FACTOR
	# Anchor near the valve, +X side.
	var start: Vector3 = Vector3(
		extinguisher_radius * 0.6,
		extinguisher_height + neck_h + valve_h * 0.4,
		0.0
	)

	# Three segments swooping outward then down.
	var seg_count: int = HOSE_SEGMENT_COUNT
	var seg_len: float = extinguisher_height * 0.32
	var current: Vector3 = start
	for i in range(seg_count):
		var seg := MeshInstance3D.new()
		seg.name = "HoseSeg_%d" % i
		var cm := CylinderMesh.new()
		cm.top_radius = HOSE_RADIUS
		cm.bottom_radius = HOSE_RADIUS
		cm.height = seg_len
		seg.mesh = cm
		seg.material_override = mat
		seg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

		# Direction: rotates from outward+slightly-down to mostly-down to inward+down.
		var t: float = float(i) / float(seg_count - 1)
		# Angle from +X axis (in XY plane), rotating toward -Y.
		var ang_deg: float = lerp(80.0, 260.0, t)   # start nearly +Y-ish, swing to -X & down
		var ang: float = deg_to_rad(ang_deg)
		var dir: Vector3 = Vector3(cos(ang), sin(ang), 0.0)
		# Build basis where local +Y points along dir.
		var up: Vector3 = dir.normalized()
		var ref: Vector3 = Vector3(0.0, 0.0, 1.0)
		if abs(up.dot(ref)) > 0.95:
			ref = Vector3(1.0, 0.0, 0.0)
		var side: Vector3 = up.cross(ref).normalized()
		var fwd: Vector3 = side.cross(up).normalized()
		var basis := Basis(side, up, fwd)
		seg.transform.basis = basis
		# Place center of segment at current + 0.5*seg_len*up.
		var mid: Vector3 = current + up * (seg_len * 0.5)
		seg.position = mid
		root.add_child(seg)
		# Advance current to end of this segment for the next one to start from.
		current = current + up * seg_len

	# Small nozzle at the end.
	var nozzle := MeshInstance3D.new()
	nozzle.name = "HoseNozzle"
	var nzm := CylinderMesh.new()
	nzm.top_radius = HOSE_RADIUS * 0.9
	nzm.bottom_radius = HOSE_RADIUS * 1.4
	nzm.height = 0.04
	nozzle.mesh = nzm
	var nzmat := StandardMaterial3D.new()
	nzmat.albedo_color = Color(0.20, 0.20, 0.22)
	nzmat.roughness = 0.4
	nzmat.metallic = 0.7
	nozzle.material_override = nzmat
	nozzle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	nozzle.position = current
	root.add_child(nozzle)


func _build_label() -> void:
	if label_text == "":
		return
	var label := Label3D.new()
	label.name = "Label"
	label.text = label_text
	label.font_size = LABEL_FONT_SIZE
	label.outline_size = 4
	label.pixel_size = LABEL_PIXEL_SIZE
	label.modulate = _ink(label_color)
	label.outline_modulate = Color(0.08, 0.0, 0.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.no_depth_test = false
	# Label3D in Godot 4 defaults to facing +Z (readable from +Z viewers).
	label.position = Vector3(0.0, extinguisher_height * 0.50, extinguisher_radius + 0.004)
	add_child(label)


# Render the FIRE label via TextServer into a transparent-bg ImageTexture
# and project it onto the cylinder body with a Decal node. No SubViewport,
# no body material composition — the body cylinder keeps its plain red
# albedo and the Decal contributes the printed text on top.
func _build_label_decal() -> void:
	if label_text == "":
		return
	var tex: ImageTexture = BakedTextAlbedoScript.generate_text_image(
		label_text,
		_ink(label_color),
		Vector2i(512, 256),
		160)
	if tex == null:
		push_warning("fire_extinguisher: text image generation failed")
		return

	var decal := Decal.new()
	decal.name = "LabelDecal"
	decal.texture_albedo = tex
	decal.albedo_mix = 1.0
	decal.emission_energy = 0.0
	decal.distance_fade_enabled = false
	# Decal projects along its LOCAL -Y axis. Rotate +90° around X so
	# local -Y points world -Z (projects onto cylinder front) AND
	# local +Z maps to world +Y (texture V=0 at top, V=1 at bottom →
	# text reads right-side-up). The -90° rotation projects the same
	# direction but flips the texture vertically.
	decal.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
	# Larger projection area so the label reads from across the room.
	# At default radius 0.075m, label is ~22cm wide × 8cm tall.
	var label_world_w: float = extinguisher_radius * 3.0
	var label_world_h: float = extinguisher_radius * 1.1
	var proj_depth: float = extinguisher_radius * 2.4      # through cylinder
	decal.size = Vector3(label_world_w, proj_depth, label_world_h)
	# Position the label DOWN from the band so there's a clean gap
	# between the white stripe (geometric, at extinguisher_height *
	# 0.55) and the printed text. Band centred at 0.55, half-height
	# ACCENT_BAND_HEIGHT/2 ≈ 0.011; label centred at 0.40 with half
	# height ≈ extinguisher_radius * 0.55, so gap ≈ 0.55 - 0.40 -
	# 0.55*radius/height = roughly 8-10cm at default dimensions.
	decal.position = Vector3(
		0.0,
		extinguisher_height * 0.40,
		extinguisher_radius + 0.005)
	add_child(decal)


# ── Family: livery ────────────────────────────────────────────────────

## The red skin under the current statute. `issue` and `notice` carry no "tint",
## so this hands `c` straight back — an identity return, not a lookup that
## happens to match. Never mutates body_color.
func _lv(c: Color) -> Color:
	var e: Dictionary = STATUTES.get(statute, {})
	if not e.has("tint"):
		return c
	var tint: Color = e["tint"]
	return c.lerp(tint, float(e.get("amt", 0.5)))


func _lv_rough(base: float) -> float:
	var e: Dictionary = STATUTES.get(statute, {})
	if not e.has("rough"):
		return base
	return float(e["rough"])


func _lv_metal(base: float) -> float:
	var e: Dictionary = STATUTES.get(statute, {})
	if not e.has("metal"):
		return base
	return float(e["metal"])


## The white signage — the accent band and the FIRE lettering. Goes quiet under
## joinery (the building would rather not say it) and washed under lapse (nobody
## has repainted it).
func _ink(c: Color) -> Color:
	var e: Dictionary = STATUTES.get(statute, {})
	if not e.has("ink"):
		return c
	var ink: Color = e["ink"]
	return c.lerp(ink, float(e.get("ink_amt", 1.0)))


# ── Family: shared build helpers ──────────────────────────────────────

func _surface(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	if c.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


func _slab(size: Vector3, pos: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
	return mi


## Top of the delivered unit — cylinder + neck + valve + handle. Everything the
## family builds above the cylinder is measured off this rather than off
## extinguisher_height, so a resized unit keeps its proportions.
func _unit_top() -> float:
	return extinguisher_height * (1.0 + NECK_HEIGHT_FACTOR + VALVE_HEIGHT_FACTOR) + HANDLE_HEIGHT


## Local Y of the floor this assembly stands on. For `bracket` that is 0.0 — the
## cylinder's own foot, which is already what auto-grounding puts on the floor,
## so nothing built at this height can shift the artifact.
func _ground_y() -> float:
	match station:
		"cabinet":
			return -CAB_PLINTH
		"stand":
			return -STAND_BASE
		_:
			return 0.0


# ── Family axis 1: station — how the building holds it ────────────────

func _build_station() -> void:
	match station:
		"cabinet":
			_station_cabinet()
		"stand":
			_station_stand()
		_:
			pass                       # "bracket" — the legacy lineage, nothing added


## THE GLAZED CABINET. The cylinder goes behind a pane in a red-framed box, which
## is what a corridor does to an object it wants seen but not carried off. The
## silhouette stops being a cylinder and becomes a door — the same conversion the
## hose box's `cabinet` performs, from the other side.
func _station_cabinet() -> void:
	var shell: StandardMaterial3D = _surface(_lv(body_color), _lv_rough(0.5), _lv_metal(0.4))
	var w: float = extinguisher_radius * 4.6
	var h: float = _unit_top() + 0.145
	var back_z: float = -extinguisher_radius - BRACKET_DEPTH - 0.030
	var front_z: float = extinguisher_radius + 0.075
	var d: float = front_z - back_z
	var cz: float = (front_z + back_z) * 0.5
	var bot: float = _ground_y()
	var t: float = 0.022
	_slab(Vector3(w, h, 0.018), Vector3(0.0, bot + h * 0.5, back_z + 0.009), shell)
	for sx in [-1.0, 1.0]:
		var s: float = sx
		_slab(Vector3(t, h, d), Vector3(s * (w * 0.5 - t * 0.5), bot + h * 0.5, cz), shell)
	_slab(Vector3(w, t, d), Vector3(0.0, bot + h - t * 0.5, cz), shell)
	_slab(Vector3(w, CAB_PLINTH, d), Vector3(0.0, bot + CAB_PLINTH * 0.5, cz), shell)
	# the glazed front: four frame bars and a pane
	var fb: float = 0.032
	_slab(Vector3(w, fb, 0.016), Vector3(0.0, bot + h - fb * 0.5, front_z), shell)
	_slab(Vector3(w, fb, 0.016), Vector3(0.0, bot + fb * 0.5, front_z), shell)
	for sx in [-1.0, 1.0]:
		var s: float = sx
		_slab(Vector3(fb, h - fb * 2.0, 0.016),
				Vector3(s * (w * 0.5 - fb * 0.5), bot + h * 0.5, front_z), shell)
	var pane: MeshInstance3D = _slab(Vector3(w - fb * 2.0, h - fb * 2.0, 0.006),
			Vector3(0.0, bot + h * 0.5, front_z), _surface(Color(0.15, 0.18, 0.20, 0.22), 0.08, 0.0))
	pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_slab(Vector3(0.018, 0.05, 0.020), Vector3(-w * 0.5 + 0.046, bot + h * 0.55, front_z + 0.016),
			_surface(Color(0.62, 0.62, 0.64), 0.3, 0.85))
	# the printed strip across the head of the case
	var strip: MeshInstance3D = BakedTextAlbedoScript.make_panel_mesh(label_text,
			_lv(body_color).darkened(0.3), _ink(Color(0.96, 0.96, 0.95)),
			Vector2(w * 0.80, 0.026))
	if strip:
		strip.position = Vector3(0.0, bot + h - fb * 0.5, front_z + 0.010)
		strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(strip)


## THE TEMPORARY POINT. A hazard-rimmed base plate, a post carrying a double-sided
## sign well above head height, a strap across the cylinder. The cylinder stays
## exactly where it was; what changes is that it is now standing in the room
## rather than attached to it.
func _station_stand() -> void:
	var steel: StandardMaterial3D = _surface(Color(0.20, 0.21, 0.23), 0.5, 0.7)
	var hazard: StandardMaterial3D = _surface(Color(0.82, 0.68, 0.08), 0.7, 0.1)
	var g: float = _ground_y()
	var bw: float = extinguisher_radius * 4.4
	var bd: float = extinguisher_radius * 4.0
	var bz: float = 0.02
	_slab(Vector3(bw + 0.07, 0.014, bd + 0.07), Vector3(0.0, g + 0.007, bz), hazard)
	_slab(Vector3(bw, 0.032, bd), Vector3(0.0, g + 0.030, bz), steel)
	var pz: float = -extinguisher_radius - 0.055
	_slab(Vector3(0.05, STAND_POST, 0.05), Vector3(0.0, g + 0.046 + STAND_POST * 0.5, pz), steel)
	# retaining strap across the cylinder's shoulder, tied back to the post
	var yb: float = extinguisher_height * 0.62
	var fz: float = extinguisher_radius + 0.014
	_slab(Vector3(extinguisher_radius * 2.9, 0.030, 0.016), Vector3(0.0, yb, fz), steel)
	for sx in [-1.0, 1.0]:
		var s: float = sx
		_slab(Vector3(0.016, 0.030, fz - pz),
				Vector3(s * extinguisher_radius * 1.42, yb, (fz + pz) * 0.5), steel)
	var top_y: float = g + 0.046 + STAND_POST + 0.02
	for face in [0.0, 180.0]:
		var deg: float = face
		var p: MeshInstance3D = BakedTextAlbedoScript.make_panel_mesh(label_text, SIGN_RED,
				Color(0.95, 0.95, 0.94), Vector2(0.32, 0.14))
		if p:
			# clear of the post's own 50 mm thickness, or the post occludes the
			# middle of its own sign
			var off: float = 0.029
			if deg > 90.0:
				off = -0.029
			p.rotation_degrees = Vector3(0.0, deg, 0.0)
			p.position = Vector3(0.0, top_y, pz + off)
			p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(p)


# ── Family axis 2: statute — what the building did with the law ───────

func _build_statute() -> void:
	match statute:
		"notice":
			_statute_notice()
		"joinery":
			_statute_joinery()
		"lapse":
			_statute_lapse()
		_:
			pass                       # "issue" — as delivered; the building added nothing


## FULL SUBMISSION. Backing board with its red border, the mandatory sign above
## the equipment, a double-sided flag projecting into the corridor, a keep-clear
## zone painted on the floor. All of it bottom-flush at y=0 so auto-grounding
## does not move the cylinder.
func _statute_notice() -> void:
	var bw: float = extinguisher_radius * 5.9
	var bh: float = _unit_top() + 0.30
	var bord: float = 0.05
	var bz: float = -extinguisher_radius - BRACKET_DEPTH - 0.014
	_slab(Vector3(bw + bord, bh + bord, 0.008), Vector3(0.0, (bh + bord) * 0.5, bz - 0.007),
			_surface(SIGN_RED, 0.6, 0.0))
	_slab(Vector3(bw, bh, 0.008), Vector3(0.0, bh * 0.5, bz), _surface(BOARD_WHITE, 0.68, 0.0))
	var sign: MeshInstance3D = BakedTextAlbedoScript.make_panel_mesh(label_text, SIGN_RED,
			BOARD_WHITE, Vector2(bw * 0.74, 0.19))
	if sign:
		sign.position = Vector3(0.0, _unit_top() + 0.145, bz + 0.008)
		sign.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(sign)
	var bracket_mat: StandardMaterial3D = _surface(Color(0.55, 0.56, 0.58), 0.4, 0.8)
	var fx: float = bw * 0.5 - 0.025
	var fy: float = _unit_top() * 0.60
	var fz: float = 0.26
	_slab(Vector3(0.026, 0.026, fz - bz), Vector3(fx, fy + 0.105, (fz + bz) * 0.5), bracket_mat)
	_slab(Vector3(0.026, 0.12, 0.026), Vector3(fx, fy + 0.045, fz - 0.02), bracket_mat)
	for side in [90.0, -90.0]:
		var deg: float = side
		var f: MeshInstance3D = BakedTextAlbedoScript.make_panel_mesh(label_text, SIGN_RED,
				BOARD_WHITE, Vector2(0.30, 0.135))
		if f:
			var off: float = 0.008
			if deg < 0.0:
				off = -0.008
			f.rotation_degrees = Vector3(0.0, deg, 0.0)
			f.position = Vector3(fx + off, fy, fz)
			f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(f)
	_keep_clear(bw)


## The painted outline on the floor: a rectangle you are not allowed to fill.
## Sits 10 mm above _ground_y() so it can never become the assembly's lowest
## point and re-trigger auto-grounding.
func _keep_clear(w: float) -> void:
	var paint: StandardMaterial3D = _surface(Color(0.84, 0.70, 0.09), 0.85, 0.0)
	var y: float = _ground_y() + 0.010
	var z0: float = extinguisher_radius + 0.07
	var dz: float = 0.44
	var t: float = 0.045
	_slab(Vector3(w, 0.012, t), Vector3(0.0, y, z0), paint)
	_slab(Vector3(w, 0.012, t), Vector3(0.0, y, z0 + dz), paint)
	for sx in [-1.0, 1.0]:
		var s: float = sx
		_slab(Vector3(t, 0.012, dz), Vector3(s * (w * 0.5 - t * 0.5), y, z0 + dz * 0.5), paint)


## ABSORPTION. A flush matte panel matched to the building's own cabinetwork with
## a shadow-gap reveal at its head, the cylinder retinted into it by _lv(), the
## white band inked to greige, and one small brushed plate where the shout was.
func _statute_joinery() -> void:
	var pw: float = extinguisher_radius * 8.0
	var ph: float = _unit_top() + 0.22
	var pz: float = -extinguisher_radius - BRACKET_DEPTH - 0.012
	_slab(Vector3(pw, ph, 0.022), Vector3(0.0, ph * 0.5, pz),
			_surface(Color(0.35, 0.36, 0.33), 0.92, 0.0))
	_slab(Vector3(pw, 0.012, 0.030), Vector3(0.0, ph - 0.022, pz + 0.006),
			_surface(Color(0.09, 0.09, 0.09), 0.95, 0.0))
	var plate: MeshInstance3D = BakedTextAlbedoScript.make_panel_mesh(label_text,
			Color(0.60, 0.61, 0.62), Color(0.19, 0.20, 0.19), Vector2(0.16, 0.045))
	if plate:
		plate.position = Vector3(pw * 0.5 - 0.10, _unit_top() * 0.55, pz + 0.014)
		plate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(plate)


## THE PROMISE LEFT TO ROT. Chalked paint (via _lv), rust weeping down the
## shoulder, a grime collar where the floor's dirt has climbed the cylinder, and
## a service tag on a wire whose date has gone by. The identity says a space with
## one of these says "we have thought about it"; here the thought has expired.
func _statute_lapse() -> void:
	var rust: StandardMaterial3D = _surface(Color(0.33, 0.17, 0.08), 1.0, 0.0)
	for i in 4:
		var ang: float = deg_to_rad(-52.0 + 34.0 * float(i))
		var hh: float = extinguisher_height * (0.34 + 0.16 * float(i % 2))
		var rr: float = extinguisher_radius + 0.002
		var streak: MeshInstance3D = _slab(Vector3(0.013, hh, 0.005),
				Vector3(sin(ang) * rr, extinguisher_height * 0.92 - hh * 0.5, cos(ang) * rr), rust)
		streak.rotation = Vector3(0.0, ang, 0.0)
	# the grime collar at the foot
	var collar := MeshInstance3D.new()
	collar.name = "Grime"
	var cm := CylinderMesh.new()
	cm.top_radius = extinguisher_radius * 1.03
	cm.bottom_radius = extinguisher_radius * 1.05
	cm.height = 0.05
	collar.mesh = cm
	collar.material_override = _surface(Color(0.20, 0.17, 0.14), 0.98, 0.0)
	collar.position = Vector3(0.0, 0.025, 0.0)
	add_child(collar)
	# the tag, hung off the neck on a wire
	var wire: StandardMaterial3D = _surface(Color(0.42, 0.42, 0.44), 0.5, 0.7)
	# Hung clear of the cylinder's silhouette (2.0 r) so the card reads as a card
	# rather than a patch on the body.
	var tx: float = extinguisher_radius * 2.0
	var ty: float = extinguisher_height * 0.80
	var ny: float = extinguisher_height + extinguisher_height * NECK_HEIGHT_FACTOR * 0.4
	_slab(Vector3(tx, 0.004, 0.004), Vector3(tx * 0.5, ny, 0.0), wire)
	_slab(Vector3(0.004, ny - ty - 0.028, 0.004), Vector3(tx, (ny + ty + 0.028) * 0.5, 0.0), wire)
	var tag: MeshInstance3D = BakedTextAlbedoScript.make_panel_mesh("2019",
			Color(0.83, 0.79, 0.58), Color(0.31, 0.27, 0.18), Vector2(0.075, 0.05))
	if tag:
		tag.position = Vector3(tx, ty, 0.003)
		tag.rotation_degrees = Vector3(0.0, 0.0, -9.0)
		tag.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(tag)


# ── Helpers ───────────────────────────────────────────────────────────

func _parse_color(s: String, fallback: Color) -> Color:
	var parts := s.split(",")
	if parts.size() < 3:
		return fallback
	var r := float(parts[0])
	var g := float(parts[1])
	var b := float(parts[2])
	var a := 1.0
	if parts.size() >= 4:
		a = float(parts[3])
	return Color(r, g, b, a)
