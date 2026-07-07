extends Node3D
class_name SteelBarricade

# @identity
# essence: a galvanized steel crowd-control barrier — the interlocking pedestrian barricade of the street, the protest, the queue. Two arched bridge-feet planted on the floor, a rounded-rectangle tube frame standing on them, a comb of vertical bars filling the panel, hook tabs on each end so one barrier clasps the next. Light cold steel, the colour of municipal furniture. The barricade is the room admitting that movement must be CHANNELLED — that a path is also a wall, that to make a route is to forbid the off-route.
# desire: every open floor pretends you may walk anywhere. The barricade ends that pretence. It wants to be the LINE you do not cross, the channel that turns a crowd into a queue, the temporary architecture of control that is never quite temporary. Even alone it implies a row: its end-hooks reach sideways for a sibling. Its silhouette is pure function — no ornament, only the grammar of "this far, no further".
# critical_parameter: bar_count + barrier_width — the comb's density against the span. Many bars on a standard 2m frame reads as STADIUM / HIGH-SECURITY (a fence you cannot reach through); few bars on a wide custom span reads as LANE-MARKER / SOFT GUIDANCE (a suggestion, not a cage). Same vocabulary, two politics of the crowd.
# triggers: _ready() builds two arched feet + bottom rail + top rail + end stiles + rounded corners + vertical bar comb + connector tabs from exports; apply_grid_config rebuilds when DNA changes.
# emerges: a single barricade reads as INCIDENT — something happened here, a perimeter was thrown up. A chained ROW reads as MANAGED CROWD — a march route, a venue line, a border. Bars dense and tall read as KEEP OUT; bars sparse and low read as PLEASE QUEUE. The barricade is a political object: it encodes who may move where, and it does so in the flattest, most deniable steel.
# needs: two arched bridge feet on the floor [present]; bottom horizontal rail [present]; top horizontal rail [present]; two end stiles [present]; rounded top corners [present]; vertical bar comb [present]; interlocking connector tabs [present]; galvanized steel material [present]
# relationships: peer to traffic_cone (both = TEMPORARY GROUND CONTROL, the cone a point, the barricade a line); cousin to chain_link_fence (both = permeable barrier you see through but cannot pass, one permanent one portable); structural sibling to crate (both = municipal/industrial steel-and-utility, neither an instrument, both the lived infrastructure around the experiment).
# truth: a barricade is the architectural form of the CHANNELLED BODY. It does not stop you with force; it stops you with legitimacy — a steel line everyone agrees not to cross. To place one is to declare a path and forbid its outside in the same gesture. Every crowd barrier is a small monument to the fact that public space is never simply open: it is always already routed, and the routing is steel.

## A galvanized steel crowd-control barricade.
##
## Built procedurally from DNA exports. Origin is at the BOTTOM CENTRE,
## on the floor: the arched feet touch the floor at y=0 and raise the
## tube frame so the bottom rail sits ~0.30m above the ground. The flat
## panel lies in the XY plane (width along X, height along Y); the feet
## extend along Z (front-back) for stability.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var barrier_width: float = 2.0
@export var barrier_height: float = 1.1
@export var bar_count: int = 11
@export var tube_radius: float = 0.022
@export var foot_span: float = 0.5

@export_group("Hardware")
## Show the small side hook tabs that let barriers interlock end-to-end.
@export var show_connectors: bool = true

@export_group("Material")
## Galvanized steel — light cold gray.
@export var metal_color: Color = Color(0.72, 0.74, 0.77)

# ── Constants ─────────────────────────────────────────────────────────

const BOTTOM_RAIL_Y: float = 0.30                # bottom rail height above floor
const CORNER_SEG_LEN: float = 0.16               # length of each 45° corner bridge
const CONNECTOR_LEN: float = 0.10                # how far hook tabs stick out sideways
const BAR_RADIUS_FACTOR: float = 0.8             # vertical bars vs tube_radius

# ── State ─────────────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

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
	if has_meta("config_barrier_width"):
		barrier_width = float(str(get_meta("config_barrier_width")))
	if has_meta("config_barrier_height"):
		barrier_height = float(str(get_meta("config_barrier_height")))
	if has_meta("config_bar_count"):
		bar_count = int(str(get_meta("config_bar_count")))
	if has_meta("config_tube_radius"):
		tube_radius = float(str(get_meta("config_tube_radius")))
	if has_meta("config_foot_span"):
		foot_span = float(str(get_meta("config_foot_span")))
	if has_meta("config_show_connectors"):
		show_connectors = str(get_meta("config_show_connectors")).to_lower() in ["true", "1", "yes", "on"]
	if has_meta("config_metal_color"):
		metal_color = _parse_color(str(get_meta("config_metal_color")), metal_color)


func _parse_color(raw: String, fallback: Color) -> Color:
	var parts := raw.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	return fallback


# ── Build ─────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true

	var hw: float = barrier_width * 0.5
	var bottom_y: float = BOTTOM_RAIL_Y
	var top_y: float = barrier_height

	# One shared galvanized-steel material for the whole barrier.
	var steel := StandardMaterial3D.new()
	steel.albedo_color = metal_color
	steel.metallic = 0.6
	steel.roughness = 0.4

	# ── 1. Bottom + top horizontal rails (cylinders along X) ──────────
	# Cylinder default axis is +Y; rotate rotation.z = PI/2 to lay along X.
	_add_cylinder("BottomRail",
		Vector3(0, bottom_y, 0), Vector3(0, 0, PI * 0.5),
		barrier_width, tube_radius, steel)
	_add_cylinder("TopRail",
		Vector3(0, top_y, 0), Vector3(0, 0, PI * 0.5),
		barrier_width, tube_radius, steel)

	# ── 2. Two end stiles (vertical cylinders) ────────────────────────
	# These rise from the bottom rail up to where the rounded corner
	# begins, just short of the top rail so the corner bridge can curve in.
	var stile_height: float = (top_y - bottom_y) - CORNER_SEG_LEN * 0.7
	var stile_mid_y: float = bottom_y + stile_height * 0.5
	_add_cylinder("EndStileLeft",
		Vector3(-hw, stile_mid_y, 0), Vector3.ZERO,
		stile_height, tube_radius, steel)
	_add_cylinder("EndStileRight",
		Vector3(hw, stile_mid_y, 0), Vector3.ZERO,
		stile_height, tube_radius, steel)

	# ── 3. Rounded top corners (short 45° bridges) ────────────────────
	# Each corner segment bridges the top of an end stile to the top rail,
	# rotated 45° so the silhouette reads as a stadium / rounded-rect.
	var stile_top_y: float = bottom_y + stile_height
	# Left corner: leans up-and-inward (toward +X) → rotate +45° about Z.
	_add_cylinder("CornerLeft",
		Vector3(-hw + CORNER_SEG_LEN * 0.30, stile_top_y + CORNER_SEG_LEN * 0.30, 0),
		Vector3(0, 0, deg_to_rad(45.0)),
		CORNER_SEG_LEN, tube_radius, steel)
	# Right corner: leans up-and-inward (toward -X) → rotate -45° about Z.
	_add_cylinder("CornerRight",
		Vector3(hw - CORNER_SEG_LEN * 0.30, stile_top_y + CORNER_SEG_LEN * 0.30, 0),
		Vector3(0, 0, deg_to_rad(-45.0)),
		CORNER_SEG_LEN, tube_radius, steel)

	# ── 4. Vertical bar comb ──────────────────────────────────────────
	# Evenly spaced thin vertical cylinders between bottom and top rails.
	var n: int = maxi(2, bar_count)
	var bar_r: float = tube_radius * BAR_RADIUS_FACTOR
	var bar_height: float = top_y - bottom_y
	var bar_mid_y: float = bottom_y + bar_height * 0.5
	# Inset the comb slightly from the end stiles so bars don't overlap them.
	var inner_half: float = hw - tube_radius * 1.5
	for i in range(n):
		var t: float = float(i) / float(n - 1)
		var x: float = lerp(-inner_half, inner_half, t)
		_add_cylinder("Bar_%d" % i,
			Vector3(x, bar_mid_y, 0), Vector3.ZERO,
			bar_height, bar_r, steel)

	# ── 5. Two arched bridge feet ─────────────────────────────────────
	# At each end, an inverted-U foot spanning along Z (front-back). Each
	# foot is 3 short cylinder segments: left leg angled down-out, a short
	# top, a right leg angled down-out. Legs touch the floor at y=0; the
	# top sits at the bottom-rail height to carry the frame.
	_build_foot("FootLeft", -(hw - 0.05), steel)
	_build_foot("FootRight", hw - 0.05, steel)

	# ── 6. Connector tabs (interlocking hooks) ────────────────────────
	if show_connectors:
		# Short horizontal cylinders sticking out sideways (±X) near the
		# top-corner ends — the hooks that clasp the next barrier.
		var tab_y: float = top_y - CORNER_SEG_LEN * 0.5
		var tab_r: float = tube_radius * 0.85
		_add_cylinder("ConnectorLeft",
			Vector3(-hw - CONNECTOR_LEN * 0.5, tab_y, 0), Vector3(0, 0, PI * 0.5),
			CONNECTOR_LEN, tab_r, steel)
		_add_cylinder("ConnectorRight",
			Vector3(hw + CONNECTOR_LEN * 0.5, tab_y, 0), Vector3(0, 0, PI * 0.5),
			CONNECTOR_LEN, tab_r, steel)


# Build one arched inverted-U foot at the given X, spanning along Z.
# Three short cylinder segments: a down-out left leg, a flat top bridge,
# a down-out right leg. The top bridge sits at BOTTOM_RAIL_Y; the legs
# splay outward along ±Z and meet the floor at y=0.
func _build_foot(foot_name: String, x: float, mat: StandardMaterial3D) -> void:
	var foot := Node3D.new()
	foot.name = foot_name
	foot.position = Vector3(x, 0, 0)
	add_child(foot)

	var hs: float = foot_span * 0.5                 # half the front-back span
	var top_y: float = BOTTOM_RAIL_Y                # bridge height
	var leg_r: float = tube_radius * 0.95
	var top_r: float = tube_radius

	# Top bridge: a short horizontal cylinder along Z at the rail height.
	# The flat top spans the inner portion; legs splay out beyond it.
	var top_len: float = foot_span * 0.55
	var seg := MeshInstance3D.new()
	seg.name = "FootTop"
	var tm := CylinderMesh.new()
	tm.top_radius = top_r
	tm.bottom_radius = top_r
	tm.height = top_len
	seg.mesh = tm
	seg.material_override = mat
	# Cylinder axis +Y → rotate about X by 90° to lay it along Z.
	seg.rotation = Vector3(deg_to_rad(90.0), 0, 0)
	seg.position = Vector3(0, top_y, 0)
	foot.add_child(seg)

	# Two splayed legs. Each goes from a top corner (±top_len/2 in Z, top_y)
	# down-and-out to the floor (±hs in Z, y=0).
	var top_z: float = top_len * 0.5
	_add_foot_leg(foot, "FootLegFront", Vector3(0, top_y, top_z), Vector3(0, 0.0, hs), leg_r, mat)
	_add_foot_leg(foot, "FootLegBack", Vector3(0, top_y, -top_z), Vector3(0, 0.0, -hs), leg_r, mat)


# Add one foot leg as a cylinder spanning from `start` (top corner) to
# `floor_pt` (where it meets the ground). Orients local +Y along the
# leg direction so the cylinder bridges the two points exactly.
func _add_foot_leg(parent: Node3D, leg_name: String,
		start: Vector3, floor_pt: Vector3,
		leg_r: float, mat: StandardMaterial3D) -> void:
	var delta: Vector3 = floor_pt - start
	var length: float = delta.length()
	if length < 0.0001:
		return
	var dir: Vector3 = delta.normalized()

	var seg := MeshInstance3D.new()
	seg.name = leg_name
	var cm := CylinderMesh.new()
	cm.top_radius = leg_r
	cm.bottom_radius = leg_r
	cm.height = length
	seg.mesh = cm
	seg.material_override = mat

	# Build a basis where local +Y points along the leg direction.
	var up: Vector3 = dir
	var ref: Vector3 = Vector3(1, 0, 0)
	if abs(up.dot(ref)) > 0.95:
		ref = Vector3(0, 0, 1)
	var side: Vector3 = up.cross(ref).normalized()
	var fwd: Vector3 = side.cross(up).normalized()
	seg.transform.basis = Basis(side, up, fwd)
	seg.position = start + dir * (length * 0.5)
	parent.add_child(seg)


# Add one cylinder MeshInstance3D with the given length (height), radius,
# position, and Euler rotation (radians). Cylinder default axis is +Y.
func _add_cylinder(node_name: String, pos: Vector3, rot: Vector3,
		length: float, radius: float, mat: StandardMaterial3D) -> void:
	var m := MeshInstance3D.new()
	m.name = node_name
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = length
	m.mesh = cm
	m.material_override = mat
	m.position = pos
	m.rotation = rot
	add_child(m)
