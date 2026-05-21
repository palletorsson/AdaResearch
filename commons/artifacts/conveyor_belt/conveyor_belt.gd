extends Node3D
class_name ConveyorBelt

# @identity
# essence: a motorised conveyor belt — Portal 2 / industrial-test-chamber vocabulary. Long dark rubber deck on a pair of end rollers and a few smaller underbelly rollers, vertical steel support legs descending to the floor, a Portal-orange accent strip running along one long edge, and emissive triangular arrows painted along the deck pointing in the +X direction. Static-but-readable: the geometry SAYS "this thing moves" even when nothing is animating
# desire: every test chamber wants a thing that moves objects — a belt is the simplest "production line" affordance. A passive surface that nonetheless declares a direction. The belt wants to be a vector
# critical_parameter: belt_length + direction_arrow_count — length sets the scale (sample chamber vs. assembly line), arrow_count tunes how INSISTENT the directionality reads. 0 arrows = quiet conveyor; many arrows = aggressive throughput
# triggers: _ready() builds deck + end rollers + under rollers + legs + accent edge + emissive arrows from exports; apply_grid_config rebuilds
# emerges: short belt with 1 arrow = "a station". Long belt with many arrows = "a production line". Same script, different industrial scenes. The direction is part of the level grammar — the player sees which way the lab thinks of as 'forward'
# needs: dark rubber deck on top [present]; large end rollers + small under rollers [present]; vertical support legs [present]; emissive arrows along the deck +X [present]; accent edge strip [present]
# relationships: peer to large_table (table = horizontal substrate for THINKING; belt = horizontal substrate for MOVING); sibling to robotarm (the arm picks from a belt); cousin to sliding_door (both are vector affordances — door = pass-through, belt = carry-along); the lab's circulatory system
# truth: a belt is the only piece of architecture that admits "things go this way". A table holds, a window watches, a door opens — but a belt MOVES. Even static, the arrows do the political work: they say "the experiment flows in this direction". Direction is not neutral

## A motorised conveyor belt — Portal 2 / industrial vocabulary.
##
## Built procedurally from DNA exports. Origin is at the center of the
## deck. Belt extends along ±X (belt_length on X, belt_width on Z, deck
## top at y = belt_height). Belt direction is +X — arrows point that way.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var belt_length: float = 2.4   # X
@export var belt_width: float = 0.6    # Z
## Height of the deck surface above the floor.
@export var belt_height: float = 0.18

@export_group("Arrows")
## Small emissive arrows painted along the belt surface, pointing +X.
@export var direction_arrow_count: int = 5

@export_group("Color")
@export var belt_color: Color = Color(0.10, 0.10, 0.11)        # dark rubber
@export var support_color: Color = Color(0.18, 0.18, 0.20)     # dark steel
@export var accent_color: Color = Color(0.95, 0.55, 0.0)       # Portal orange
@export var arrow_color: Color = Color(0.95, 0.55, 0.0)        # Portal orange emissive

@export_group("Supports")
## Number of vertical support posts under the deck.
@export var support_legs: int = 4

# ── Constants ─────────────────────────────────────────────────────────

const DECK_THICKNESS: float = 0.035
const END_ROLLER_RADIUS_FACTOR: float = 0.45  # vs belt_height
const UNDER_ROLLER_RADIUS_FACTOR: float = 0.22
const UNDER_ROLLER_COUNT: int = 3
const LEG_THICKNESS: float = 0.06
const ACCENT_STRIP_HEIGHT: float = 0.012
const ACCENT_STRIP_THICKNESS: float = 0.005
const ARROW_LENGTH_FACTOR: float = 0.18   # vs belt_width
const ARROW_WIDTH_FACTOR: float = 0.45    # vs belt_width

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_belt()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_belt()


func _read_metadata_overrides() -> void:
	if has_meta("config_belt_length"):
		belt_length = float(String(get_meta("config_belt_length")))
	if has_meta("config_belt_width"):
		belt_width = float(String(get_meta("config_belt_width")))
	if has_meta("config_belt_height"):
		belt_height = float(String(get_meta("config_belt_height")))
	if has_meta("config_direction_arrow_count"):
		direction_arrow_count = int(String(get_meta("config_direction_arrow_count")))
	if has_meta("config_belt_color"):
		belt_color = _parse_color(String(get_meta("config_belt_color")), belt_color)
	if has_meta("config_support_color"):
		support_color = _parse_color(String(get_meta("config_support_color")), support_color)
	if has_meta("config_accent_color"):
		accent_color = _parse_color(String(get_meta("config_accent_color")), accent_color)
	if has_meta("config_arrow_color"):
		arrow_color = _parse_color(String(get_meta("config_arrow_color")), arrow_color)
	if has_meta("config_support_legs"):
		support_legs = int(String(get_meta("config_support_legs")))


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_belt() -> void:
	_built = true
	_build_deck()
	_build_end_rollers()
	_build_under_rollers()
	_build_support_legs()
	_build_accent_strip()
	_build_arrows()


func _build_deck() -> void:
	var deck := MeshInstance3D.new()
	deck.name = "Deck"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(belt_length, DECK_THICKNESS, belt_width)
	deck.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = belt_color
	mat.roughness = 0.85
	mat.metallic = 0.05
	deck.material_override = mat
	# Deck top is at belt_height; center at belt_height - DECK_THICKNESS/2.
	deck.position = Vector3(0.0, belt_height - DECK_THICKNESS * 0.5, 0.0)
	add_child(deck)


func _build_end_rollers() -> void:
	var rollers_root := Node3D.new()
	rollers_root.name = "EndRollers"
	add_child(rollers_root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = support_color
	mat.roughness = 0.35
	mat.metallic = 0.75

	# End rollers: large cylinders at ±X ends, axis along Z, sized to the deck height.
	var radius := belt_height * END_ROLLER_RADIUS_FACTOR
	var roller_h := belt_width + 0.02   # slightly wider than belt
	# Center y so roller sits centered just under the deck surface.
	var y: float = belt_height - DECK_THICKNESS - radius

	for sign_x in [1, -1]:
		var r := MeshInstance3D.new()
		r.name = "EndRoller_%d" % sign_x
		var cm := CylinderMesh.new()
		cm.top_radius = radius
		cm.bottom_radius = radius
		cm.height = roller_h
		r.mesh = cm
		r.material_override = mat
		# Default cylinder axis = +Y. Rotate so axis = +Z.
		r.rotation = Vector3(PI * 0.5, 0.0, 0.0)
		var x := (belt_length * 0.5 - radius * 0.6) * float(sign_x)
		r.position = Vector3(x, max(y, radius + 0.005), 0.0)
		rollers_root.add_child(r)


func _build_under_rollers() -> void:
	var rollers_root := Node3D.new()
	rollers_root.name = "UnderRollers"
	add_child(rollers_root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = support_color
	mat.roughness = 0.45
	mat.metallic = 0.6

	var radius := belt_height * UNDER_ROLLER_RADIUS_FACTOR
	var roller_h := belt_width * 0.85
	# Sit under the deck but above the floor.
	var y: float = max(radius + 0.005, belt_height * 0.35)
	# Distribute UNDER_ROLLER_COUNT evenly across the inner length.
	var span := belt_length * 0.6
	var count = UNDER_ROLLER_COUNT
	for i in range(count):
		var t := 0.5
		if count > 1:
			t = float(i) / float(count - 1)
		var r := MeshInstance3D.new()
		r.name = "UnderRoller_%d" % i
		var cm := CylinderMesh.new()
		cm.top_radius = radius
		cm.bottom_radius = radius
		cm.height = roller_h
		r.mesh = cm
		r.material_override = mat
		r.rotation = Vector3(PI * 0.5, 0.0, 0.0)
		var x: float = lerp(-span * 0.5, span * 0.5, t)
		r.position = Vector3(x, y, 0.0)
		rollers_root.add_child(r)


func _build_support_legs() -> void:
	if support_legs <= 0:
		return
	var legs_root := Node3D.new()
	legs_root.name = "SupportLegs"
	add_child(legs_root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = support_color
	mat.roughness = 0.5
	mat.metallic = 0.6

	# Legs span from floor (y=0) up to just under the deck surface.
	var leg_height := belt_height - DECK_THICKNESS * 0.5
	if leg_height <= 0.02:
		return

	# Pair the legs along ±Z edges so the deck stands on two rails of legs.
	var pairs = max(1, support_legs / 2)
	if support_legs == 1:
		pairs = 1
	var z_inset := belt_width * 0.5 - LEG_THICKNESS * 0.5 - 0.02
	# X positions: distributed across belt length minus an inset.
	var x_span := belt_length - LEG_THICKNESS * 2.0 - 0.20
	for i in range(pairs):
		var t := 0.5
		if pairs > 1:
			t = float(i) / float(pairs - 1)
		var x: float = lerp(-x_span * 0.5, x_span * 0.5, t)
		# Front leg (+Z), back leg (-Z) — only build the second if support_legs > pairs.
		_make_leg(legs_root, "Leg_%d_front" % i, Vector3(x, leg_height * 0.5, z_inset), leg_height, mat)
		if support_legs >= pairs * 2:
			_make_leg(legs_root, "Leg_%d_back" % i, Vector3(x, leg_height * 0.5, -z_inset), leg_height, mat)


func _make_leg(parent: Node3D, leg_name: String, pos: Vector3, h: float, mat: StandardMaterial3D) -> void:
	var leg := MeshInstance3D.new()
	leg.name = leg_name
	var m := BoxMesh.new()
	m.size = Vector3(LEG_THICKNESS, h, LEG_THICKNESS)
	leg.mesh = m
	leg.material_override = mat
	leg.position = pos
	parent.add_child(leg)


func _build_accent_strip() -> void:
	# Thin emissive strip along the +Z long edge of the deck.
	var strip := MeshInstance3D.new()
	strip.name = "AccentStrip"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(belt_length * 0.96, ACCENT_STRIP_HEIGHT, ACCENT_STRIP_THICKNESS)
	strip.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent_color
	mat.emission_enabled = true
	mat.emission = accent_color
	mat.emission_energy_multiplier = 1.6
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	strip.material_override = mat
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Position: along +Z edge, just under the deck top.
	var y := belt_height - DECK_THICKNESS - ACCENT_STRIP_HEIGHT * 0.5 - 0.002
	var z := belt_width * 0.5 + ACCENT_STRIP_THICKNESS * 0.5
	strip.position = Vector3(0.0, y, z)
	add_child(strip)


func _build_arrows() -> void:
	if direction_arrow_count <= 0:
		return
	var arrows_root := Node3D.new()
	arrows_root.name = "Arrows"
	add_child(arrows_root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = arrow_color
	mat.emission_enabled = true
	mat.emission = arrow_color
	mat.emission_energy_multiplier = 1.4
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

	# Each arrow is a small chevron: two diagonal Box pieces forming a ">".
	# Painted on top of the deck (just above the deck surface).
	var arrow_len := belt_width * ARROW_LENGTH_FACTOR
	var arrow_w := belt_width * ARROW_WIDTH_FACTOR
	var stripe_thickness := arrow_len * 0.18
	var stripe_height := 0.004
	var y_face := belt_height + stripe_height * 0.5 + 0.001

	# Distribute along the inner length so the first/last arrow aren't on top of the rollers.
	var inset := belt_length * 0.12
	var usable := belt_length - inset * 2.0
	var n = direction_arrow_count
	for i in range(n):
		var t := 0.5
		if n > 1:
			t = float(i) / float(n - 1)
		var x_center := -usable * 0.5 + usable * t
		# Build chevron: two thin diagonal stripes meeting at a +X point.
		var pivot := Node3D.new()
		pivot.name = "Arrow_%d" % i
		pivot.position = Vector3(x_center, y_face, 0.0)
		arrows_root.add_child(pivot)

		var stripe_len := sqrt((arrow_len * arrow_len) + (arrow_w * arrow_w * 0.25))
		# Upper stripe (top-left → bottom-right tip).
		var upper := MeshInstance3D.new()
		upper.name = "Upper"
		var um := BoxMesh.new()
		um.size = Vector3(stripe_len, stripe_height, stripe_thickness)
		upper.mesh = um
		upper.material_override = mat
		upper.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Angle so the stripe goes from upper-left to lower-right tip (in deck plane: X long, Z width).
		var ang := atan2(arrow_w * 0.5, arrow_len)
		upper.rotation = Vector3(0.0, -ang, 0.0)
		upper.position = Vector3(-arrow_len * 0.5 + stripe_len * 0.5 * cos(ang), 0.0,
			arrow_w * 0.5 - stripe_len * 0.5 * sin(ang))
		pivot.add_child(upper)

		# Lower stripe (bottom-left → upper-right? mirror of upper across Z=0).
		var lower := MeshInstance3D.new()
		lower.name = "Lower"
		var lm := BoxMesh.new()
		lm.size = Vector3(stripe_len, stripe_height, stripe_thickness)
		lower.mesh = lm
		lower.material_override = mat
		lower.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		lower.rotation = Vector3(0.0, ang, 0.0)
		lower.position = Vector3(-arrow_len * 0.5 + stripe_len * 0.5 * cos(ang), 0.0,
			-arrow_w * 0.5 + stripe_len * 0.5 * sin(ang))
		pivot.add_child(lower)


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
