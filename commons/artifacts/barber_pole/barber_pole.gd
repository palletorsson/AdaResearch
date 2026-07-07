extends Node3D
class_name BarberPole

# @identity
# essence: a floor-standing barber pole — a turned white base, a glass-cased column of red/white/blue helical stripes that appear to climb forever, a white cap, and a glowing globe finial on top. The stripes do not actually move up; the cylinder spins (or the texture scrolls) and the diagonal bands READ as endless ascent. The pole is motion turned into a sign: a machine whose only output is the appearance of going somewhere while standing still. It is the street's oldest animated logo — a barber's open-for-business beacon rendered as a perpetual optical climb.
# desire: the pole wants to be SEEN AS RUNNING. It is a signal before it is an object — the eye catches the climbing stripes from across the street and reads "open, working, alive" before the mind names "barber." It desires to convert rotation into the illusion of infinite upward flow, to be the purest demonstration that a closed loop can fake an open line. Even at rest its silhouette promises movement.
# critical_parameter: stripe_turns + colors + spin — turns sets the helix density (few = lazy spiral, many = tight barber-shop candy); spin ON reads ACTIVE / shop-open, spin OFF reads CLOSED / dead sign; colors switch the cultural register (US red/white/blue vs. plain red/white elsewhere). Same column, three different statements about whether anyone is home.
# triggers: _ready() builds turned base + striped cylinder + optional glass shell + cap + glowing globe from exports; _process scrolls the stripe texture's uv1_offset so the bands climb; apply_grid_config rebuilds when DNA changes.
# emerges: a spinning pole reads as A SHOP THAT IS OPEN — labor present, a service waiting. A still pole reads as CLOSED or ABANDONED. Tight turns read as classic candy-stripe nostalgia; loose turns read as modern/minimal signage. The globe lit at the top reads as a beacon — visible at night, a small lighthouse for the haircut. The pole is a time-marker: its motion is the only proof the street is awake.
# needs: a turned white base of stacked cylinders [present]; a striped cylinder with a generated red/white/blue helix texture [present]; an optional faint glass shell over the stripes [present]; a white cap above the stripes [present]; a glowing emissive globe finial [present]
# relationships: peer to fire_extinguisher (both are SIGNALS-BEFORE-OBJECTS — recognition before reading, saturated against neutral walls); cousin to exit_sign (both are wall/street vocabulary that says "here, this way, this service"); sibling to any rotating beacon (the lighthouse, the police light) — closed loops that fake open direction; the street's quiet promise that motion means someone is working.
# truth: a barber pole is the illusion of progress made physical. Nothing climbs — the stripes return to where they started on every turn — yet the eye insists on ascent. It is the architectural form of MOTION-AS-MESSAGE: a sign whose content IS its movement. Turn it off and the meaning dies with the spin. The pole confesses that some signals exist only while they run, and that a perfect loop, lit and turning, can read as an open road.

## A classic floor-standing barber pole.
##
## Built procedurally from DNA exports. Origin is at the BOTTOM CENTRE of
## the base (floor-resting, Y up). Total height is roughly 1.7m. The red/
## white/blue helical stripes are a generated ImageTexture; when `spin` is
## true the texture scrolls so the stripes appear to climb endlessly.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Pole")
@export var pole_height: float = 1.0
@export var pole_radius: float = 0.09
## How many times the helix wraps over the stripe column's height. More
## turns = tighter candy-stripe; fewer = lazy spiral.
@export var stripe_turns: float = 4.0

@export_group("Colors")
## The "red" band (band 0). Classic US barber red.
@export var stripe_color_a: Color = Color(0.85, 0.12, 0.12)
## The "blue" band (band 2). The white band between them is fixed white.
@export var stripe_color_b: Color = Color(0.12, 0.20, 0.70)
## The emissive globe finial colour.
@export var globe_color: Color = Color(1.0, 1.0, 1.0)

@export_group("Hardware")
## Show the emissive globe finial on top.
@export var show_globe: bool = true
## Show the faint transparent glass shell over the stripes.
@export var show_glass: bool = true

@export_group("Motion")
## When TRUE the stripe texture scrolls so the bands appear to climb —
## the shop reads as OPEN. When FALSE the pole is static (CLOSED).
@export var spin: bool = true
## Scroll speed of the stripe texture (UV units per second).
@export var spin_speed: float = 0.5

# ── Constants ─────────────────────────────────────────────────────────

const BASE_HEIGHT: float = 0.35              # top of the turned base / bottom of stripes
const FOOT_RADIUS: float = 0.16
const FOOT_HEIGHT: float = 0.05
const BULB_RADIUS: float = 0.13
const CAP_HEIGHT: float = 0.10
const GLOBE_RADIUS: float = 0.10
const TEX_WIDTH: int = 64
const TEX_HEIGHT: int = 256

# ── State ─────────────────────────────────────────────────────────────

var _built: bool = false
var _stripe_mat: StandardMaterial3D = null


func _ready() -> void:
	_read_metadata_overrides()
	_build()


func _process(delta: float) -> void:
	if spin and _stripe_mat != null:
		# Scroll the stripe texture downward in UV space so the diagonal
		# bands appear to climb UP the pole. Wrap to keep the offset bounded.
		var off := _stripe_mat.uv1_offset
		off.y = fposmod(off.y - spin_speed * delta, 1.0)
		_stripe_mat.uv1_offset = off


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for c in get_children():
			remove_child(c)
			c.queue_free()
		_built = false
		_stripe_mat = null
		_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_pole_height"):
		pole_height = float(str(get_meta("config_pole_height")))
	if has_meta("config_pole_radius"):
		pole_radius = float(str(get_meta("config_pole_radius")))
	if has_meta("config_stripe_turns"):
		stripe_turns = float(str(get_meta("config_stripe_turns")))
	if has_meta("config_stripe_color_a"):
		stripe_color_a = _parse_color(str(get_meta("config_stripe_color_a")), stripe_color_a)
	if has_meta("config_stripe_color_b"):
		stripe_color_b = _parse_color(str(get_meta("config_stripe_color_b")), stripe_color_b)
	if has_meta("config_globe_color"):
		globe_color = _parse_color(str(get_meta("config_globe_color")), globe_color)
	if has_meta("config_show_globe"):
		var sg := str(get_meta("config_show_globe")).to_lower()
		show_globe = sg in ["true", "1", "yes", "on"]
	if has_meta("config_show_glass"):
		var sgl := str(get_meta("config_show_glass")).to_lower()
		show_glass = sgl in ["true", "1", "yes", "on"]
	if has_meta("config_spin"):
		var sp := str(get_meta("config_spin")).to_lower()
		spin = sp in ["true", "1", "yes", "on"]
	if has_meta("config_spin_speed"):
		spin_speed = float(str(get_meta("config_spin_speed")))


func _parse_color(raw: String, fallback: Color) -> Color:
	var parts := raw.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	return fallback


# ── Build ─────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true
	_build_base()
	_build_stripes()
	if show_glass:
		_build_glass_shell()
	_build_cap()
	if show_globe:
		_build_globe()


# The turned white base: a wide foot disc, a bulbous mid, and a narrowing
# neck that meets the stripe cylinder at BASE_HEIGHT.
func _build_base() -> void:
	var white_mat := StandardMaterial3D.new()
	white_mat.albedo_color = Color(0.9, 0.9, 0.9)
	white_mat.roughness = 0.5
	white_mat.metallic = 0.1

	# Foot disc — wide and flat, resting on the floor.
	var foot := MeshInstance3D.new()
	foot.name = "Foot"
	var fm := CylinderMesh.new()
	fm.top_radius = FOOT_RADIUS * 0.85
	fm.bottom_radius = FOOT_RADIUS
	fm.height = FOOT_HEIGHT
	foot.mesh = fm
	foot.material_override = white_mat
	foot.position = Vector3(0.0, FOOT_HEIGHT * 0.5, 0.0)
	add_child(foot)

	# Bulbous mid — the turned belly of the base.
	var bulb := MeshInstance3D.new()
	bulb.name = "Bulb"
	var bm := SphereMesh.new()
	bm.radius = BULB_RADIUS
	bm.height = BULB_RADIUS * 1.6
	bulb.mesh = bm
	bulb.material_override = white_mat
	var bulb_y: float = FOOT_HEIGHT + BULB_RADIUS * 0.5
	bulb.position = Vector3(0.0, bulb_y, 0.0)
	add_child(bulb)

	# Narrowing neck — tapers up from the bulb to the stripe cylinder.
	var neck := MeshInstance3D.new()
	neck.name = "BaseNeck"
	var nm := CylinderMesh.new()
	nm.top_radius = pole_radius * 1.05
	nm.bottom_radius = BULB_RADIUS * 0.7
	var neck_bottom: float = FOOT_HEIGHT + BULB_RADIUS * 0.55
	var neck_h: float = BASE_HEIGHT - neck_bottom
	if neck_h < 0.02:
		neck_h = 0.02
	nm.height = neck_h
	neck.mesh = nm
	neck.material_override = white_mat
	neck.position = Vector3(0.0, neck_bottom + neck_h * 0.5, 0.0)
	add_child(neck)


# The striped column with the generated red/white/blue helix texture.
func _build_stripes() -> void:
	var stripe := MeshInstance3D.new()
	stripe.name = "Stripes"
	var sm := CylinderMesh.new()
	sm.top_radius = pole_radius
	sm.bottom_radius = pole_radius
	sm.height = pole_height
	stripe.mesh = sm
	stripe.material_override = _make_stripe_material()
	stripe.position = Vector3(0.0, BASE_HEIGHT + pole_height * 0.5, 0.0)
	add_child(stripe)


# Generate the diagonal red/white/blue stripe image and wrap it in a
# StandardMaterial3D cached on _stripe_mat for animation.
func _make_stripe_material() -> StandardMaterial3D:
	var img := Image.create(TEX_WIDTH, TEX_HEIGHT, false, Image.FORMAT_RGBA8)
	var white := Color(0.95, 0.95, 0.95)
	for x in range(TEX_WIDTH):
		for y in range(TEX_HEIGHT):
			var u := float(x) / float(TEX_WIDTH)
			var v := float(y) / float(TEX_HEIGHT)
			var diag := u * 1.0 - v * stripe_turns
			var band := int(floor(diag * 3.0))
			var idx := ((band % 3) + 3) % 3
			var col: Color
			if idx == 0:
				col = stripe_color_a
			elif idx == 1:
				col = white
			else:
				col = stripe_color_b
			img.set_pixel(x, y, col)

	var tex := ImageTexture.create_from_image(img)

	_stripe_mat = StandardMaterial3D.new()
	_stripe_mat.albedo_texture = tex
	_stripe_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	_stripe_mat.roughness = 0.4
	_stripe_mat.metallic = 0.1
	return _stripe_mat


# A faint transparent glass shell over the stripes.
func _build_glass_shell() -> void:
	var glass := MeshInstance3D.new()
	glass.name = "GlassShell"
	var gm := CylinderMesh.new()
	gm.top_radius = pole_radius * 1.06
	gm.bottom_radius = pole_radius * 1.06
	gm.height = pole_height
	glass.mesh = gm
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.95, 0.97, 1.0, 0.15)
	mat.roughness = 0.08
	mat.metallic = 0.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	glass.material_override = mat
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	glass.position = Vector3(0.0, BASE_HEIGHT + pole_height * 0.5, 0.0)
	add_child(glass)


# A white cap (short cone) above the stripe column.
func _build_cap() -> void:
	var white_mat := StandardMaterial3D.new()
	white_mat.albedo_color = Color(0.9, 0.9, 0.9)
	white_mat.roughness = 0.5
	white_mat.metallic = 0.1

	var cap := MeshInstance3D.new()
	cap.name = "Cap"
	var cm := CylinderMesh.new()
	cm.top_radius = pole_radius * 0.25
	cm.bottom_radius = pole_radius * 1.15
	cm.height = CAP_HEIGHT
	cap.mesh = cm
	cap.material_override = white_mat
	var cap_y: float = BASE_HEIGHT + pole_height + CAP_HEIGHT * 0.5
	cap.position = Vector3(0.0, cap_y, 0.0)
	add_child(cap)


# The glowing emissive globe finial on top.
func _build_globe() -> void:
	var globe := MeshInstance3D.new()
	globe.name = "Globe"
	var gm := SphereMesh.new()
	gm.radius = GLOBE_RADIUS
	gm.height = GLOBE_RADIUS * 2.0
	globe.mesh = gm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = globe_color
	mat.emission_enabled = true
	mat.emission = globe_color
	mat.emission_energy = 2.0
	mat.roughness = 0.3
	mat.metallic = 0.0
	globe.material_override = mat
	var globe_y: float = BASE_HEIGHT + pole_height + CAP_HEIGHT + GLOBE_RADIUS * 0.9
	globe.position = Vector3(0.0, globe_y, 0.0)
	add_child(globe)
