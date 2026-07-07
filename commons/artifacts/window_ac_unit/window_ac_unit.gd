extends Node3D
class_name WindowAcUnit

# @identity
# essence: a wall-mounted outdoor heat-pump condenser — the cream powder-coat box that hangs on the OUTSIDE of every apartment, the thing the inside of a room never sees but the inside of a room depends on. A horizontal off-white body on two galvanized steel brackets, a recessed dark fan grille with concentric wire-guard rings dominating the front face, vent louvers along the top, a removable service-panel seam on one side, and a small cyan-lit brand plaque. The condenser is the room's metabolism turned inside-out: the heat the room rejects has to go SOMEWHERE, and this is where. It is comfort's exhaust.
# desire: a room wants to pretend its climate is free — that cool air simply IS. The condenser breaks that pretence. It wants to be the visible cost: the box bolted to the brickwork, humming, breathing, moving heat from where it is unwanted to where nobody is looking. It wants to read as INFRASTRUCTURE-MADE-EXTERNAL — the machine exiled to the wall so the interior can stay clean. Recognition before reading: the eye finds the fan grille first, the way the eye finds a face.
# critical_parameter: wall_brackets + dimensions — brackets ON reads as an INSTALLED condenser hung on a wall, breathing into open air; brackets OFF reads as the same unit resting on a ground pad or a shop shelf, not yet deployed. The dimensions set the register: wide+shallow = domestic split-system; tall+deep = light-commercial. Same box, two very different stories — one already serving a room, one still in the catalogue. The fan grille is the dominant front feature in both.
# triggers: _ready() builds body + top louvers + recessed fan grille (disc + concentric guard rings + radial spokes + center hub) + side service seam + brand plaque + Label3D + two wall brackets from exports; apply_grid_config rebuilds when DNA changes.
# emerges: a single condenser on a bare wall reads as ONE DWELLING, ONE CLIMATE — a private comfort made public. A GRID of them up a façade reads as a HOUSING BLOCK — many private climates, one shared exterior, each box confessing a room behind it. The fan grille reads as ALIVE when imagined spinning, DEAD when still. The condenser is a thermodynamic marker: heat has a direction, comfort has an outside, the clean interior is paid for in warm air dumped onto a wall.
# needs: horizontal cream powder-coat body [present]; top vent louvers [present]; recessed dark fan grille with concentric wire-guard rings + radial spokes + center hub [present]; removable service-panel seam on the side [present]; dark brand plaque + cyan Label3D [present]; two galvanized steel wall brackets reaching down and back to the wall [present]
# relationships: peer to fire_extinguisher (both = wall-mounted infrastructure facing +Z into the room, both confess what the architecture must handle — one names fire, one names heat); cousin to ceiling_vent (both = the building's breathing apparatus, plumbing for the lived life of a space, one indoor and discreet, one outdoor and exiled); sibling to crate (both = the machine's confession that the clean room has an outside it depends on — the crate says "this arrived", the condenser says "this exhausts").
# truth: a condenser is the architectural form of EXTERNALISED COST. Cool air inside is warm air somewhere else, and the somewhere-else is this box on the wall. By hanging it outside, the building hides its own thermodynamics from the people it serves. A façade without condensers says "no one regulates climate here, or the cost is hidden deeper"; a façade studded with them says "every room here buys its comfort, and here is the receipt, bolted to the brick." The cream paint is not decorative — it is the colour of a thing meant to disappear against a wall while it works.

## A wall-mounted outdoor AC / heat-pump condenser unit.
##
## Built procedurally from DNA exports. Origin is at the BOTTOM CENTER of
## the UNIT BODY at local (0,0,0); the body spans y 0..unit_height. The
## front fan grille faces +Z (into the room); the wall is behind at -Z.
## Wall brackets extend DOWN (-Y) and BACK (-Z) toward the wall plane,
## holding the unit ~0.34 above their lowest point.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var unit_width: float = 0.9
@export var unit_height: float = 0.55
@export var unit_depth: float = 0.30

@export_group("Features")
## Recessed dark fan circle + concentric wire-guard rings on the +Z face.
@export var fan_grille: bool = true
## Two galvanized steel brackets beneath the unit reaching back to the wall.
## Critical parameter: ON = installed on a wall, OFF = resting on ground/shelf.
@export var wall_brackets: bool = true
## Thin horizontal vent slats on the +Y top face.
@export var top_louvers: bool = true
## Dark brand plaque + cyan Label3D on the front upper-right.
@export var show_display: bool = true

@export_group("Material")
## Cream / off-white powder-coat body.
@export var body_color: Color = Color(0.92, 0.92, 0.90)
## Recessed fan-disc dark color.
@export var grille_color: Color = Color(0.18, 0.18, 0.20)

@export_group("Label")
## Short brand text on the front plaque — all caps reads best.
@export var brand_text: String = "BYHEAT"

# ── Constants ─────────────────────────────────────────────────────────

const LOUVER_COUNT: int = 5
const GUARD_RING_COUNT: int = 4
const SPOKE_COUNT: int = 6
const BRACKET_LIFT: float = 0.34          # how far the unit sits above the bracket's lowest point
const STEEL_COLOR: Color = Color(0.45, 0.45, 0.47)
const LOUVER_COLOR: Color = Color(0.78, 0.78, 0.78)
const GUARD_COLOR: Color = Color(0.62, 0.64, 0.68)   # light steel wire guard
const HUB_COLOR: Color = Color(0.22, 0.22, 0.24)
const PLAQUE_COLOR: Color = Color(0.10, 0.10, 0.12)
const LABEL_TINT: Color = Color(0.45, 0.85, 0.95)    # cyan / blue

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
	if has_meta("config_unit_width"):
		unit_width = float(str(get_meta("config_unit_width")))
	if has_meta("config_unit_height"):
		unit_height = float(str(get_meta("config_unit_height")))
	if has_meta("config_unit_depth"):
		unit_depth = float(str(get_meta("config_unit_depth")))
	if has_meta("config_fan_grille"):
		fan_grille = str(get_meta("config_fan_grille")).to_lower() in ["true", "1", "yes", "on"]
	if has_meta("config_wall_brackets"):
		wall_brackets = str(get_meta("config_wall_brackets")).to_lower() in ["true", "1", "yes", "on"]
	if has_meta("config_top_louvers"):
		top_louvers = str(get_meta("config_top_louvers")).to_lower() in ["true", "1", "yes", "on"]
	if has_meta("config_show_display"):
		show_display = str(get_meta("config_show_display")).to_lower() in ["true", "1", "yes", "on"]
	if has_meta("config_body_color"):
		body_color = _parse_color(str(get_meta("config_body_color")), body_color)
	if has_meta("config_grille_color"):
		grille_color = _parse_color(str(get_meta("config_grille_color")), grille_color)
	if has_meta("config_brand_text"):
		brand_text = str(get_meta("config_brand_text"))


func _parse_color(raw: String, fallback: Color) -> Color:
	var parts := raw.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	return fallback


# ── Build ─────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true
	_build_body()
	if top_louvers:
		_build_louvers()
	if fan_grille:
		_build_fan_grille()
	_build_service_seam()
	if show_display:
		_build_display()
	if wall_brackets:
		_build_wall_brackets()


func _build_body() -> void:
	var body := MeshInstance3D.new()
	body.name = "Body"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(unit_width, unit_height, unit_depth)
	body.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	mat.roughness = 0.6
	mat.metallic = 0.1
	body.material_override = mat
	body.position = Vector3(0.0, unit_height * 0.5, 0.0)
	add_child(body)


func _build_louvers() -> void:
	# Several thin horizontal slats slightly raised off the +Y top face.
	var root := Node3D.new()
	root.name = "TopLouvers"
	add_child(root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = LOUVER_COLOR
	mat.roughness = 0.55
	mat.metallic = 0.25

	var n: int = LOUVER_COUNT
	var slat_h: float = 0.012
	var slat_thick: float = unit_depth * 0.12
	var top_y: float = unit_height + slat_h * 0.4
	# Distribute the slats across the depth, leaving a margin front and back.
	var span: float = unit_depth * 0.74
	for i in range(n):
		var slat := MeshInstance3D.new()
		slat.name = "Louver%d" % i
		var bm := BoxMesh.new()
		bm.size = Vector3(unit_width * 0.86, slat_h, slat_thick)
		slat.mesh = bm
		slat.material_override = mat
		var t: float = (float(i) / float(n - 1)) - 0.5 if n > 1 else 0.0
		var z: float = t * span
		slat.position = Vector3(0.0, top_y, z)
		root.add_child(slat)


func _build_fan_grille() -> void:
	# Recessed dark disc + concentric wire-guard rings + radial spokes + hub,
	# centered on the +Z face.
	var root := Node3D.new()
	root.name = "FanGrille"
	add_child(root)

	var grille_radius: float = 0.22
	# Keep the grille inside the body face with a small margin.
	var max_r: float = min(unit_width, unit_height) * 0.5 - 0.04
	grille_radius = min(grille_radius, max_r)

	var cy: float = unit_height * 0.5
	var face_z: float = unit_depth * 0.5

	# Recessed dark disc — a thin cylinder lying flat against the front face.
	var disc := MeshInstance3D.new()
	disc.name = "FanDisc"
	var dm := CylinderMesh.new()
	dm.top_radius = grille_radius
	dm.bottom_radius = grille_radius
	dm.height = 0.012
	disc.mesh = dm
	var disc_mat := StandardMaterial3D.new()
	disc_mat.albedo_color = grille_color
	disc_mat.roughness = 0.7
	disc_mat.metallic = 0.2
	disc.material_override = disc_mat
	# Rotate so the disc's flat faces point along +Z; recess it slightly.
	disc.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
	disc.position = Vector3(0.0, cy, face_z - 0.004)
	root.add_child(disc)

	# Concentric wire-guard rings (thin tori) of increasing radius.
	var guard_mat := StandardMaterial3D.new()
	guard_mat.albedo_color = GUARD_COLOR
	guard_mat.roughness = 0.4
	guard_mat.metallic = 0.7

	var ring_z: float = face_z + 0.006
	for i in range(GUARD_RING_COUNT):
		var frac: float = float(i + 1) / float(GUARD_RING_COUNT)
		var ring_r: float = grille_radius * frac
		var ring := MeshInstance3D.new()
		ring.name = "GuardRing%d" % i
		var tm := TorusMesh.new()
		tm.outer_radius = ring_r
		tm.inner_radius = ring_r - 0.006
		ring.mesh = tm
		ring.material_override = guard_mat
		# TorusMesh lies in the XZ plane by default; rotate so it faces +Z.
		ring.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
		ring.position = Vector3(0.0, cy, ring_z)
		root.add_child(ring)

	# Radial spoke bars (thin boxes rotated around the center).
	for i in range(SPOKE_COUNT):
		var spoke := MeshInstance3D.new()
		spoke.name = "Spoke%d" % i
		var sm := BoxMesh.new()
		sm.size = Vector3(grille_radius * 2.0, 0.008, 0.006)
		spoke.mesh = sm
		spoke.material_override = guard_mat
		var ang: float = deg_to_rad(180.0 * float(i) / float(SPOKE_COUNT))
		spoke.rotation = Vector3(0.0, 0.0, ang)
		spoke.position = Vector3(0.0, cy, ring_z)
		root.add_child(spoke)

	# Small center hub.
	var hub := MeshInstance3D.new()
	hub.name = "FanHub"
	var hm := CylinderMesh.new()
	hm.top_radius = grille_radius * 0.14
	hm.bottom_radius = grille_radius * 0.14
	hm.height = 0.03
	hub.mesh = hm
	var hub_mat := StandardMaterial3D.new()
	hub_mat.albedo_color = HUB_COLOR
	hub_mat.roughness = 0.5
	hub_mat.metallic = 0.6
	hub.material_override = hub_mat
	hub.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
	hub.position = Vector3(0.0, cy, ring_z + 0.004)
	root.add_child(hub)


func _build_service_seam() -> void:
	# A thin recessed vertical seam on the +X side face — a removable
	# service panel suggestion.
	var seam := MeshInstance3D.new()
	seam.name = "ServiceSeam"
	var bm := BoxMesh.new()
	bm.size = Vector3(0.012, unit_height * 0.82, 0.010)
	seam.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color.darkened(0.3)
	mat.roughness = 0.65
	mat.metallic = 0.15
	seam.material_override = mat
	# Sit just proud of the +X face, toward the front (+Z) third of the depth.
	seam.position = Vector3(unit_width * 0.5 - 0.002, unit_height * 0.5, unit_depth * 0.18)
	add_child(seam)


func _build_display() -> void:
	# Small dark plaque on the front upper-right + cyan brand Label3D.
	var face_z: float = unit_depth * 0.5
	var px: float = unit_width * 0.30
	var py: float = unit_height * 0.74

	var plaque := MeshInstance3D.new()
	plaque.name = "BrandPlaque"
	var bm := BoxMesh.new()
	bm.size = Vector3(unit_width * 0.26, unit_height * 0.16, 0.006)
	plaque.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = PLAQUE_COLOR
	mat.roughness = 0.4
	mat.metallic = 0.3
	plaque.material_override = mat
	plaque.position = Vector3(px, py, face_z + 0.003)
	add_child(plaque)

	if brand_text.strip_edges().length() > 0:
		var lbl := Label3D.new()
		lbl.name = "BrandText"
		lbl.text = brand_text
		lbl.font_size = 40
		lbl.outline_size = 0
		lbl.pixel_size = 0.0016
		lbl.modulate = LABEL_TINT
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		# Label3D in Godot 4 defaults to facing +Z (readable from +Z viewers).
		lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		lbl.position = Vector3(px, py, face_z + 0.008)
		add_child(lbl)


func _build_wall_brackets() -> void:
	# Two galvanized steel brackets beneath the unit, one near each end in X.
	# Each bracket = a horizontal arm box (under the unit) + a diagonal strut
	# angling from the front-bottom back-and-down to the wall (-Z).
	var root := Node3D.new()
	root.name = "WallBrackets"
	add_child(root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = STEEL_COLOR
	mat.roughness = 0.5
	mat.metallic = 0.7

	var arm_len: float = unit_depth * 1.05
	var arm_thick: float = 0.04
	var inset_x: float = unit_width * 0.36
	var wall_z: float = -unit_depth * 0.5            # wall plane just behind the body

	for side in [-1.0, 1.0]:
		var bx: float = inset_x * side

		# Horizontal arm directly under the unit, running along Z.
		var arm := MeshInstance3D.new()
		arm.name = "BracketArm_%s" % ("L" if side < 0 else "R")
		var am := BoxMesh.new()
		am.size = Vector3(arm_thick, arm_thick, arm_len)
		arm.mesh = am
		arm.material_override = mat
		# Arm sits just below the body bottom (y=0), centered over the depth.
		arm.position = Vector3(bx, -arm_thick * 0.5, 0.0)
		root.add_child(arm)

		# Diagonal strut from the front end of the arm down-and-back to the
		# wall plane, BRACKET_LIFT below the arm.
		var top_pt := Vector3(bx, -arm_thick, unit_depth * 0.5)   # front-bottom of arm
		var bot_pt := Vector3(bx, -BRACKET_LIFT, wall_z)          # at the wall, lowest point
		var delta := bot_pt - top_pt
		var strut_len: float = delta.length()

		var strut := MeshInstance3D.new()
		strut.name = "BracketStrut_%s" % ("L" if side < 0 else "R")
		var stm := BoxMesh.new()
		stm.size = Vector3(arm_thick * 0.7, strut_len, arm_thick * 0.7)
		strut.mesh = stm
		strut.material_override = mat
		# Orient local +Y along the strut direction.
		var up: Vector3 = delta.normalized()
		var ref: Vector3 = Vector3(1.0, 0.0, 0.0)
		if abs(up.dot(ref)) > 0.95:
			ref = Vector3(0.0, 0.0, 1.0)
		var s_side: Vector3 = up.cross(ref).normalized()
		var fwd: Vector3 = s_side.cross(up).normalized()
		strut.transform.basis = Basis(s_side, up, fwd)
		strut.position = top_pt + up * (strut_len * 0.5)
		root.add_child(strut)

		# Short vertical wall plate where the strut meets the wall.
		var plate := MeshInstance3D.new()
		plate.name = "BracketWallPlate_%s" % ("L" if side < 0 else "R")
		var pm := BoxMesh.new()
		pm.size = Vector3(arm_thick * 1.4, BRACKET_LIFT * 0.7, 0.02)
		plate.mesh = pm
		plate.material_override = mat
		plate.position = Vector3(bx, -BRACKET_LIFT * 0.55, wall_z - 0.01)
		root.add_child(plate)
