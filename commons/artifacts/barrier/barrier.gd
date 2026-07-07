extends Node3D
class_name Barrier

# @identity
# essence: a portable road barrier in two bodies — an A-FRAME arrow barricade (a white plastic frame on splayed feet, a coloured top panel carrying a black arrow, a lower panel of orange/white hazard stripes, an amber beacon glowing on its crown) and a WHEEL-STOP (a low striped rubber mound bolted to the tarmac that catches a tyre and says "no further"). One is a SIGN that redirects you while you still move; the other is a LIP that halts you once you have arrived. Both are the architecture of channelled movement made cheap, portable, and repeatable — the everyday hardware of "this way, not that".
# desire: every road pretends its lanes are open and its bays are infinite. The barrier breaks that pretence. The A-frame wants to be SEEN FROM A DISTANCE and OBEYED BEFORE TOUCHED — beacon, arrow, stripes, all recognition-before-contact. The wheel-stop wants the opposite: to be UNSEEN UNTIL FELT, a low edge that does its whole job in the last centimetre of a parking manoeuvre. Together they are the two tenses of control over flow: the warning ahead and the stop underfoot.
# critical_parameter: kind — "aframe" is the TALL ARROW BARRICADE that REDIRECTS traffic still in motion (vertical, lit, legible at speed); "wheelstop" is the LOW RUBBER LIP that HALTS a tyre that has already arrived (horizontal, mute, felt not read). Same family of channelled passage, opposite gestures. panel_color + stripe_a/stripe_b decide loudness — saturated diagonals read ACTIVE / ROADWORKS / watch-out; muted reads SETTLED / long-standing.
# triggers: _ready() builds the frame+panels+arrow+beacon (aframe) or the swept rubber wedge on its base plate (wheelstop) from exports; apply_grid_config rebuilds when DNA changes.
# emerges: a single A-frame reads as A DIVERSION — one path nudged aside, follow the arrow. A row of wheel-stops reads as a CAR PARK GRID — bodies parked in rank, each tyre caught at the same line. The beacon lit reads LIVE / TONIGHT; unlit reads FORGOTTEN. The barrier is a spatial verb: it does not describe the boundary, it ENACTS it — once as a pointing sign, once as a tripping edge.
# needs: aframe — white plastic frame on splayed feet [present]; coloured arrow top panel [present]; orange/white hazard-stripe lower panel [present]; amber emissive beacon [present]. wheelstop — swept rubber wedge with yellow/black stripes [present]; thin black base plate [present].
# relationships: peer to concrete_barrier (all three ENACT a decision-about-movement made by someone absent — the concrete deflects mass, the A-frame redirects attention, the wheel-stop catches a tyre); cousin to fire_extinguisher (SIGNAL-BEFORE-OBJECT, hazard colour read before contact); sibling to any bollard or cone (the grammar of channelled passage).
# truth: a barrier is a choice about where you may go, rendered in plastic and rubber cheap enough to scatter by the dozen. The A-frame is that choice ANNOUNCED — beacon and arrow demanding to be seen before tested. The wheel-stop is that choice ENFORCED at the limit — the silent edge that decides exactly where the car ends. Every barrier is a small monument to control over flow, proof that paths and parking bays are not natural but drawn, by someone, in advance of you.

## A portable road barrier with two variants selected by `kind`.
##
## Built procedurally from DNA exports. Origin is at the BOTTOM CENTRE of
## the barrier (floor-resting, Y up). Front = +Z.
##   kind = "aframe"    — a white A-frame arrow barricade with a beacon.
##   kind = "wheelstop" — a low striped rubber parking wheel-stop / curb.
## The hazard stripes are a generated ImageTexture (orange/white for the
## A-frame, yellow/black for the wheel-stop). The wheel-stop wedge is a real
## swept solid built by MeshFactory.extrude_profile.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Variant")
## "aframe" = tall arrow barricade that redirects traffic; "wheelstop" =
## low rubber lip that halts a tyre.
@export var kind: String = "aframe"

@export_group("Frame")
@export var frame_width: float = 0.6
@export var frame_height: float = 0.9

@export_group("Markings")
## The top arrow panel colour (a road red/orange).
@export var panel_color: Color = Color(0.88, 0.20, 0.14)
## Hazard stripe band A (orange on the A-frame, yellow on the wheel-stop).
@export var stripe_a: Color = Color(0.95, 0.55, 0.10)
## Hazard stripe band B (white on the A-frame, black on the wheel-stop).
@export var stripe_b: Color = Color(0.95, 0.95, 0.92)
## Show the amber beacon on the A-frame's crown.
@export var show_beacon: bool = true

@export_group("Wheelstop")
@export var length: float = 1.4
@export var wedge_height: float = 0.18

# ── Constants ─────────────────────────────────────────────────────────

## The mesh factory that sweeps the wheel-stop cross-section into a solid.
const MF := preload("res://commons/artifacts/shared/mesh_factory.gd")
const TEX_SIZE: int = 64

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
	if has_meta("config_kind"):
		kind = str(get_meta("config_kind"))
	if has_meta("config_frame_width"):
		frame_width = float(str(get_meta("config_frame_width")))
	if has_meta("config_frame_height"):
		frame_height = float(str(get_meta("config_frame_height")))
	if has_meta("config_panel_color"):
		panel_color = _parse_color(str(get_meta("config_panel_color")), panel_color)
	if has_meta("config_stripe_a"):
		stripe_a = _parse_color(str(get_meta("config_stripe_a")), stripe_a)
	if has_meta("config_stripe_b"):
		stripe_b = _parse_color(str(get_meta("config_stripe_b")), stripe_b)
	if has_meta("config_show_beacon"):
		var s: String = str(get_meta("config_show_beacon")).to_lower()
		show_beacon = s == "true" or s == "1" or s == "yes" or s == "on"
	if has_meta("config_length"):
		length = float(str(get_meta("config_length")))
	if has_meta("config_wedge_height"):
		wedge_height = float(str(get_meta("config_wedge_height")))


func _parse_color(raw: String, fallback: Color) -> Color:
	var parts := raw.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	return fallback


# ── Build ─────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true
	if kind.to_lower() == "wheelstop":
		_build_wheelstop()
	else:
		_build_aframe()


# ── A-frame arrow barricade ────────────────────────────────────────────

func _build_aframe() -> void:
	var hw := frame_width * 0.5
	var fh := frame_height
	var bar := 0.05          # white frame bar thickness
	var depth := 0.05        # frame thickness along Z

	var white_color := Color(0.93, 0.93, 0.95)
	var white_mat := StandardMaterial3D.new()
	white_mat.albedo_color = white_color
	white_mat.roughness = 0.55
	white_mat.metallic = 0.0

	# ── 1. Upright rectangular frame (two posts + top + mid + bottom rails) ──
	var frame := Node3D.new()
	frame.name = "Frame"
	add_child(frame)

	# Left & right vertical posts.
	for sx in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		post.name = "Post"
		var pm := BoxMesh.new()
		pm.size = Vector3(bar, fh, depth)
		post.mesh = pm
		post.material_override = white_mat
		post.position = Vector3(sx * hw, fh * 0.5, 0.0)
		frame.add_child(post)

	# Horizontal rails: top, middle (panel divider), bottom.
	var rail_ys := [fh - bar * 0.5, fh * 0.5, bar * 0.5]
	var rail_names := ["RailTop", "RailMid", "RailBottom"]
	for i in range(rail_ys.size()):
		var rail := MeshInstance3D.new()
		rail.name = rail_names[i]
		var rm := BoxMesh.new()
		rm.size = Vector3(frame_width + bar, bar, depth)
		rail.mesh = rm
		rail.material_override = white_mat
		rail.position = Vector3(0.0, float(rail_ys[i]), 0.0)
		frame.add_child(rail)

	# ── 2. Splayed feet (horizontal white bars along Z + small foot pads) ──
	var foot_len := frame_width * 1.15
	for sx in [-1.0, 1.0]:
		var foot := MeshInstance3D.new()
		foot.name = "Foot"
		var fm := BoxMesh.new()
		fm.size = Vector3(bar, bar * 0.8, foot_len)
		foot.mesh = fm
		foot.material_override = white_mat
		# Splay the feet slightly wider than the posts.
		foot.position = Vector3(sx * (hw + bar * 0.5), bar * 0.4, 0.0)
		frame.add_child(foot)

		# Foot pads at each end of the foot bar.
		for sz in [-1.0, 1.0]:
			var pad := MeshInstance3D.new()
			pad.name = "FootPad"
			var pdm := BoxMesh.new()
			pdm.size = Vector3(bar * 1.6, bar * 0.6, bar * 1.6)
			pad.mesh = pdm
			pad.material_override = white_mat
			pad.position = Vector3(sx * (hw + bar * 0.5), bar * 0.3, sz * foot_len * 0.5)
			frame.add_child(pad)

	# ── 3. Top panel: coloured field + black arrow pointing right (+X) ──
	var panel_inset := bar * 0.5
	var panel_w := frame_width - bar
	var panel_depth := 0.012

	var panel_mat := StandardMaterial3D.new()
	panel_mat.albedo_color = panel_color
	panel_mat.roughness = 0.6
	panel_mat.metallic = 0.0

	var top_panel := MeshInstance3D.new()
	top_panel.name = "TopPanel"
	var tpm := BoxMesh.new()
	var top_panel_h := fh * 0.5 - bar * 1.5
	tpm.size = Vector3(panel_w, top_panel_h, panel_depth)
	top_panel.mesh = tpm
	top_panel.material_override = panel_mat
	var top_panel_cy := fh * 0.75
	top_panel.position = Vector3(0.0, top_panel_cy, depth * 0.5 + panel_inset)
	add_child(top_panel)

	# Black arrow (shaft + two angled head boxes), pointing +X.
	var black_mat := StandardMaterial3D.new()
	black_mat.albedo_color = Color(0.06, 0.06, 0.07)
	black_mat.roughness = 0.7
	black_mat.metallic = 0.0

	var arrow_z := depth * 0.5 + panel_inset + panel_depth * 0.5 + 0.004
	var shaft_w := panel_w * 0.5
	var shaft_t := top_panel_h * 0.18

	var shaft := MeshInstance3D.new()
	shaft.name = "ArrowShaft"
	var shm := BoxMesh.new()
	shm.size = Vector3(shaft_w, shaft_t, 0.008)
	shaft.mesh = shm
	shaft.material_override = black_mat
	shaft.position = Vector3(-panel_w * 0.08, top_panel_cy, arrow_z)
	add_child(shaft)

	# Two angled head bars forming the arrowhead at the +X end.
	var head_len := top_panel_h * 0.42
	var head_t := shaft_t
	var head_x := panel_w * 0.28
	for sgn in [1.0, -1.0]:
		var head := MeshInstance3D.new()
		head.name = "ArrowHead"
		var hm := BoxMesh.new()
		hm.size = Vector3(head_len, head_t, 0.008)
		head.mesh = hm
		head.material_override = black_mat
		head.position = Vector3(head_x, top_panel_cy, arrow_z)
		# Angle each head bar ~45° to meet at the tip.
		head.rotation = Vector3(0.0, 0.0, deg_to_rad(sgn * 45.0))
		add_child(head)

	# ── 4. Lower panel: orange/white diagonal hazard stripes ──
	var stripe_mat := _make_stripe_material(stripe_a, stripe_b)
	var lower_panel := MeshInstance3D.new()
	lower_panel.name = "LowerPanel"
	var lpm := BoxMesh.new()
	var lower_panel_h := fh * 0.5 - bar * 1.5
	lpm.size = Vector3(panel_w, lower_panel_h, panel_depth)
	lower_panel.mesh = lpm
	lower_panel.material_override = stripe_mat
	lower_panel.position = Vector3(0.0, fh * 0.25, depth * 0.5 + panel_inset)
	add_child(lower_panel)

	# ── 5. Beacon on the crown: black base box + emissive amber dome ──
	if show_beacon:
		var beacon_root := Node3D.new()
		beacon_root.name = "Beacon"
		beacon_root.position = Vector3(0.0, fh, 0.0)
		add_child(beacon_root)

		var base_mat := StandardMaterial3D.new()
		base_mat.albedo_color = Color(0.07, 0.07, 0.08)
		base_mat.roughness = 0.6
		base_mat.metallic = 0.2

		var base := MeshInstance3D.new()
		base.name = "BeaconBase"
		var bm := BoxMesh.new()
		bm.size = Vector3(0.12, 0.05, 0.10)
		base.mesh = bm
		base.material_override = base_mat
		base.position = Vector3(0.0, 0.025, 0.0)
		beacon_root.add_child(base)

		var amber_mat := StandardMaterial3D.new()
		amber_mat.albedo_color = Color(1.0, 0.6, 0.1)
		amber_mat.roughness = 0.3
		amber_mat.metallic = 0.0
		amber_mat.emission_enabled = true
		amber_mat.emission = Color(1.0, 0.55, 0.05)
		amber_mat.emission_energy = 2.5

		var dome := MeshInstance3D.new()
		dome.name = "BeaconDome"
		var dm := SphereMesh.new()
		dm.radius = 0.055
		dm.height = 0.11
		dome.mesh = dm
		dome.material_override = amber_mat
		# Flatten the sphere into a dome and sit it on the base.
		dome.scale = Vector3(1.0, 0.7, 1.0)
		dome.position = Vector3(0.0, 0.05 + 0.038, 0.0)
		beacon_root.add_child(dome)


# ── Wheel-stop / parking curb ──────────────────────────────────────────

func _build_wheelstop() -> void:
	# ── 1. Swept rubber wedge (MeshFactory.extrude_profile) ──
	# Cross-section in the Z-Y plane: a rounded low triangle — wide flat
	# bottom, sloped up both sides to a rounded crest. Swept along X by length.
	var hw := 0.22                      # half base width along Z
	var ch := wedge_height              # crest height
	var crest_half := hw * 0.18         # flat-ish rounded crest half-width

	var outline := PackedVector2Array([
		Vector2(hw, 0.0),               # bottom front edge
		Vector2(hw * 0.92, ch * 0.18),  # toe rise
		Vector2(hw * 0.55, ch * 0.72),  # front slope
		Vector2(crest_half, ch * 0.96), # near crest, front
		Vector2(0.0, ch),               # crest peak
		Vector2(-crest_half, ch * 0.96),# near crest, back
		Vector2(-hw * 0.55, ch * 0.72), # back slope
		Vector2(-hw * 0.92, ch * 0.18), # heel rise
		Vector2(-hw, 0.0),              # bottom back edge
	])

	var stripe_mat := _make_stripe_material(stripe_a, stripe_b)
	stripe_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var body := MeshInstance3D.new()
	body.name = "WheelstopBody"
	# uv_tile = length keeps the diagonal stripes ~square along the run.
	body.mesh = MF.extrude_profile(outline, length, length)
	body.material_override = stripe_mat
	add_child(body)

	# ── 2. Thin flat black base plate under the wedge ──
	var base_mat := StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.07, 0.07, 0.08)
	base_mat.roughness = 0.7
	base_mat.metallic = 0.1

	var plate := MeshInstance3D.new()
	plate.name = "BasePlate"
	var pm := BoxMesh.new()
	var plate_h := 0.02
	# Slightly wider and longer than the wedge so it reads as a footing.
	pm.size = Vector3(length * 1.06, plate_h, hw * 2.0 * 1.12)
	plate.mesh = pm
	plate.material_override = base_mat
	plate.position = Vector3(0.0, plate_h * 0.5, 0.0)
	add_child(plate)


# ── Shared hazard-stripe texture ───────────────────────────────────────

# Generate a diagonal two-colour hazard-stripe image (45° bands via u - v)
# and wrap it in a StandardMaterial3D. LINEAR filter. Same approach as
# concrete_barrier's _make_stripe_material(), parameterised by band colours.
func _make_stripe_material(col_a: Color, col_b: Color) -> StandardMaterial3D:
	var img := Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGBA8)
	var bands: int = 6
	for x in range(TEX_SIZE):
		for y in range(TEX_SIZE):
			var u := float(x) / float(TEX_SIZE)
			var v := float(y) / float(TEX_SIZE)
			# Diagonal band index from (u - v): a 45° hazard stripe.
			var diag := (u - v) * float(bands)
			var band := int(floor(diag))
			var idx := ((band % 2) + 2) % 2
			var col: Color = col_a if idx == 0 else col_b
			img.set_pixel(x, y, col)

	var tex := ImageTexture.create_from_image(img)

	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	mat.uv1_scale = Vector3(1.0, 1.0, 1.0)
	mat.roughness = 0.75
	mat.metallic = 0.0
	return mat
