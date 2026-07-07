extends Node3D
class_name ConcreteBarrier

# @identity
# essence: a Jersey-profile concrete traffic barrier — a low, heavy, stepped wall of poured concrete with the classic tapered silhouette (wide foot, sloped shoulder, narrow crown), wrapped in weathered RED/WHITE diagonal hazard stripes, with two steel lifting hooks bolted into its top. The barrier is the architecture of FORBIDDEN PASSAGE made portable. It is not a building and not a fence; it is a line in space that says "not through here" and means it with the full mass of cured concrete. The barrier is the room admitting that some movement must be channeled, deflected, refused.
# desire: every space pretends its paths are open. The barrier breaks that pretence — it wants to be the OBSTACLE THAT REDIRECTS, the thing that takes your intended straight line and bends it. Even at rest it implies a decision already made elsewhere: someone decided traffic flows THIS way, not THAT way. Its hazard stripes want to be seen before you reach them — recognition of a boundary before you test it. It desires to be temporary-but-immovable: light enough to lift, heavy enough to stop a car.
# critical_parameter: stripe_color_a / stripe_color_b + dimensions decide whether this reads as a HAZARD-STRIPED TEMPORARY BARRIER (saturated red/white diagonals = active roadworks, a boundary in flux) or PLAIN CONCRETE (muted, stripe-free = permanent infrastructure, a settled border). show_hooks toggles LIFTABLE/TEMPORARY (hooks present = a crane will move this, the boundary is provisional) vs PERMANENT (hooks absent = poured in place, the line is final). Same stepped profile, opposite statements about how fixed the refusal is.
# triggers: _ready() sweeps the Jersey cross-section into a single solid mesh via MeshFactory + the generated diagonal hazard-stripe texture + optional steel lifting hooks from exports; apply_grid_config rebuilds when DNA changes.
# emerges: a single barrier reads as A LANE CLOSURE — one path foreclosed, traffic nudged aside. A ROW of barriers reads as a CORRIDOR OF CONTROL — movement fully channeled, no choice left. Bright stripes read as ACTIVE / WATCH-OUT; faded stripes read as FORGOTTEN / LONG-STANDING. Hooks on top read as PROVISIONAL — this will be lifted away when the work is done. The barrier is a spatial verb: it does not describe the boundary, it ENACTS it.
# needs: a swept Jersey-profile mesh giving the tapered silhouette [present]; weathered concrete body [present]; diagonal red/white hazard-stripe texture on the long faces [present]; two steel lifting hooks on the crown [present]; symmetric front/back profile [present]
# relationships: peer to crate (both are OBJECTS-IN-TRANSIT that confess the space did not invent itself — the crate carries equipment in, the barrier channels movement; both have lifting hardware, both are provisional); cousin to fire_extinguisher (both are SIGNALS-BEFORE-OBJECTS, saturated hazard color recognized before read); sibling to any bollard or gate (the grammar of CHANNELED PASSAGE — here, this way, not there).
# truth: a concrete barrier is the physical form of a DECISION ABOUT MOVEMENT made by someone who is not present. It is poured authority — a boundary you meet long after the meeting that drew it. The hazard stripes are not decoration; they are the boundary announcing itself, demanding to be seen before it is tested. Every barrier is a small monument to control over flow: proof that paths are not natural, that someone chose where you may and may not go, and rendered that choice in concrete heavy enough to stop you.

## A Jersey-profile concrete traffic barrier (K-rail).
##
## Built procedurally from DNA exports. Origin is at the BOTTOM CENTRE of
## the barrier (floor-resting, Y up). Length runs along X; the barrier is
## symmetric front/back along Z. The silhouette is a real Jersey cross-
## section swept along the length by MeshFactory (commons/artifacts/shared).
## The red/white diagonal hazard stripes are a generated ImageTexture.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var barrier_length: float = 2.0
@export var barrier_height: float = 0.8
@export var base_width: float = 0.6
@export var top_width: float = 0.22

@export_group("Stripes")
## The "red" hazard band — a weathered, muted road red.
@export var stripe_color_a: Color = Color(0.74, 0.30, 0.24)
## The alternating off-white band.
@export var stripe_color_b: Color = Color(0.85, 0.85, 0.82)
## How many diagonal stripes appear along the barrier's length.
@export var stripe_count: int = 8

@export_group("Hardware")
## Show the two steel lifting hooks on the crown. ON = liftable /
## temporary; OFF = permanent / poured-in-place.
@export var show_hooks: bool = true

# ── Constants ─────────────────────────────────────────────────────────

## The mesh factory that sweeps the Jersey cross-section into a real solid.
const MF := preload("res://commons/artifacts/shared/mesh_factory.gd")
const TEX_SIZE: int = 64
const HOOK_INSET: float = 0.3            # fraction of half-length from centre
const HOOK_TUBE_RADIUS_FACTOR: float = 0.20   # vs hook loop radius

# ── State ─────────────────────────────────────────────────────────────

var _built: bool = false


func _ready() -> void:
	_read_metadata_overrides()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for c in get_children():
			remove_child(c)
			c.queue_free()
		_built = false
		_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_barrier_length"):
		barrier_length = float(str(get_meta("config_barrier_length")))
	if has_meta("config_barrier_height"):
		barrier_height = float(str(get_meta("config_barrier_height")))
	if has_meta("config_base_width"):
		base_width = float(str(get_meta("config_base_width")))
	if has_meta("config_top_width"):
		top_width = float(str(get_meta("config_top_width")))
	if has_meta("config_stripe_color_a"):
		stripe_color_a = _parse_color(str(get_meta("config_stripe_color_a")), stripe_color_a)
	if has_meta("config_stripe_color_b"):
		stripe_color_b = _parse_color(str(get_meta("config_stripe_color_b")), stripe_color_b)
	if has_meta("config_stripe_count"):
		stripe_count = int(str(get_meta("config_stripe_count")))
	if has_meta("config_show_hooks"):
		var s: String = str(get_meta("config_show_hooks")).to_lower()
		show_hooks = s == "true" or s == "1" or s == "yes" or s == "on"


func _parse_color(raw: String, fallback: Color) -> Color:
	var parts := raw.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	return fallback


# ── Build ─────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true

	# The hazard-stripe material is shared across the three body boxes so
	# the diagonal bands read continuously up the stepped silhouette.
	var stripe_mat := _make_stripe_material()

	# ── 1. Jersey-profile body — a REAL swept mesh (MeshFactory) ─────
	# A symmetric Jersey cross-section (wide foot, vertical toe, steep lower
	# slope, gentler upper slope, narrow crown) is extruded along the length
	# into a single solid with true sloped faces — not stacked boxes.
	var outline := MF.jersey_outline(base_width, top_width, barrier_height)
	var body := MeshInstance3D.new()
	body.name = "BarrierBody"
	# uv_tile = barrier_height keeps the diagonal stripes ~square, so they
	# repeat (length / height) times along the run.
	body.mesh = MF.extrude_profile(outline, barrier_length, barrier_height)
	body.material_override = stripe_mat
	add_child(body)

	# ── 2. Steel lifting hooks on the crown ──────────────────────────
	if show_hooks:
		var hx: float = barrier_length * HOOK_INSET
		var crown_top: float = barrier_height
		_add_lifting_hook("HookLeft", Vector3(-hx, crown_top, 0.0))
		_add_lifting_hook("HookRight", Vector3(hx, crown_top, 0.0))


# Generate the diagonal red/white hazard-stripe image and wrap it in a
# StandardMaterial3D. uv1_scale is set so several stripes appear along the
# barrier's length. Weathered red + off-white per the DNA.
func _make_stripe_material() -> StandardMaterial3D:
	var img := Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGBA8)
	# Number of diagonal bands across one texture tile.
	var bands: int = maxi(2, stripe_count)
	for x in range(TEX_SIZE):
		for y in range(TEX_SIZE):
			var u := float(x) / float(TEX_SIZE)
			var v := float(y) / float(TEX_SIZE)
			# Diagonal band index from (u - v): a 45° hazard stripe.
			var diag := (u - v) * float(bands)
			var band := int(floor(diag))
			var idx := ((band % 2) + 2) % 2
			var col: Color = stripe_color_a if idx == 0 else stripe_color_b
			img.set_pixel(x, y, col)

	var tex := ImageTexture.create_from_image(img)

	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	# Repeat the stripe tile several times along the length (U) so the
	# diagonals stay crisp on a long barrier; one tile across the height (V).
	# The mesh factory bakes U in tile units (U already spans length/height
	# tiles along the run), so no extra uv1_scale is needed.
	mat.uv1_scale = Vector3(1.0, 1.0, 1.0)
	# Double-sided: the swept profile lights via forced-outward normals, but
	# disabling back-face cull keeps it reading solid from any angle.
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	# Weathered concrete reads matte, not glossy.
	mat.roughness = 0.85
	mat.metallic = 0.0
	return mat


# A single steel lifting hook standing up out of the crown: a vertical
# torus loop anchored by two short cylinder posts. Dark steel.
func _add_lifting_hook(hook_name: String, base_pos: Vector3) -> void:
	var root := Node3D.new()
	root.name = hook_name
	root.position = base_pos
	add_child(root)

	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color(0.20, 0.21, 0.23)
	steel.roughness = 0.45
	steel.metallic = 0.85

	# Loop size scales gently with the barrier so it stays proportional.
	var loop_radius: float = clampf(barrier_height * 0.10, 0.04, 0.09)
	var tube_radius: float = loop_radius * HOOK_TUBE_RADIUS_FACTOR
	var post_height: float = loop_radius * 0.8
	var post_offset: float = loop_radius * 0.55

	# Two short posts anchoring the loop into the crown, set apart along X.
	for sx in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		post.name = "HookPost"
		var pm := CylinderMesh.new()
		pm.top_radius = tube_radius
		pm.bottom_radius = tube_radius
		pm.height = post_height
		post.mesh = pm
		post.material_override = steel
		post.position = Vector3(sx * post_offset, post_height * 0.5, 0.0)
		root.add_child(post)

	# The vertical loop (torus), standing up out of the crown. A TorusMesh
	# lies in the XZ plane by default; rotate 90° about X so the ring stands
	# vertical and reads as a liftable eye facing along the length.
	var loop := MeshInstance3D.new()
	loop.name = "HookLoop"
	var tm := TorusMesh.new()
	tm.inner_radius = loop_radius - tube_radius
	tm.outer_radius = loop_radius + tube_radius
	loop.mesh = tm
	loop.material_override = steel
	loop.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
	loop.position = Vector3(0.0, post_height + loop_radius * 0.85, 0.0)
	root.add_child(loop)
