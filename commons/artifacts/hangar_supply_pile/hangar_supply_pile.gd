extends Node3D
class_name HangarSupplyPile

# Preload (not the global class_name) so a freshly-created kit resolves headless too.
const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# @identity
# essence: a staged pile of supplies in a maintenance-bay corner — stacked crates, a red gas cylinder with a draping hose, and a striped warning cone. The clutter that says "work happens here, and it has not been tidied".
# desire: to make a corner of a hangar map read as lived-in and provisioned — to be the staging area a crew left mid-shift, not an empty floor.
# critical_parameter: crate_count — how big the pile reads. 2 = a small drop-off; 5 = a fully-stocked supply corner. Base crates are bigger; the stack tapers and offsets as it climbs.
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config rebuilds with a new count/palette/contents.
# emerges: tan crates read "cardboard shipment"; brown read "wooden freight"; the cylinder + cone read "hazard, handle with care"; FRAGILE/KEEP DRY stencils read "someone owns this".
# truth: a room is furnished by its leftovers. The pile no one cleared is more honest about the place than anything on a plinth.

# ── DNA ───────────────────────────────────────────────────────────────
@export_group("Pile")
## THE parameter — how many crates stack into the pile (2..5). Base crates are bigger.
@export var crate_count: int = 4
## "cardboard" (tan) | "wood" (brown) | "metal" (grey) — what the crates are made of.
@export var palette: String = "cardboard"
## Stencilled warning labels (FRAGILE / KEEP DRY) on a couple of crate front faces.
@export var hazard_labels: bool = true

@export_group("Contents")
## A red gas cylinder beside the pile — vertical body + dome top + a draping hose.
@export var with_cylinder: bool = true
## A striped warning cone in front of the pile.
@export var with_cone: bool = true

@export_group("Color")
## Gas-cylinder body colour (red by default).
@export var cylinder_color: Color = Color(0.80, 0.12, 0.10)

@export_group("Surface")
## Weathering 0..1 — darkens + roughens toward scuffed/battered.
@export var wear: float = 0.3

# ── Constants ─────────────────────────────────────────────────────────
# Fixed per-index crate sizes (base → top, biggest first). DETERMINISTIC.
const CRATE_SIZES := [
	Vector3(0.62, 0.46, 0.58),
	Vector3(0.54, 0.42, 0.50),
	Vector3(0.46, 0.38, 0.44),
	Vector3(0.40, 0.34, 0.40),
	Vector3(0.34, 0.30, 0.34),
]
# Fixed per-index horizontal offset (a believable lean, not a perfect tower).
const CRATE_OFFSETS := [
	Vector2(0.0, 0.0),
	Vector2(0.05, -0.04),
	Vector2(-0.06, 0.05),
	Vector2(0.04, 0.06),
	Vector2(-0.03, -0.05),
]
# Fixed per-index yaw in degrees.
const CRATE_YAW := [4.0, -7.0, 9.0, -5.0, 6.0]

var _built := false

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
			c.queue_free()
		_built = false
		_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_crate_count"): crate_count = int(float(str(get_meta("config_crate_count"))))
	if has_meta("config_palette"): palette = str(get_meta("config_palette")).to_lower()
	if has_meta("config_hazard_labels"): hazard_labels = str(get_meta("config_hazard_labels")).to_lower() in ["true", "1", "yes", "on"]
	if has_meta("config_with_cylinder"): with_cylinder = str(get_meta("config_with_cylinder")).to_lower() in ["true", "1", "yes", "on"]
	if has_meta("config_with_cone"): with_cone = str(get_meta("config_with_cone")).to_lower() in ["true", "1", "yes", "on"]
	if has_meta("config_cylinder_color"): cylinder_color = _pc(str(get_meta("config_cylinder_color")), cylinder_color)
	if has_meta("config_wear"): wear = float(str(get_meta("config_wear")))


# ── Build ─────────────────────────────────────────────────────────────
func _build() -> void:
	_built = true
	var n: int = clampi(crate_count, 2, 5)
	var crate_mat := _mat(_palette_color(), 0.7, 0.2)
	var edge_mat := HangarKit.worn_metal(_palette_color())

	# Stack the crates, base first, each resting on the previous one's top.
	var y: float = 0.0
	for i in range(n):
		var s: Vector3 = CRATE_SIZES[i]
		var off: Vector2 = CRATE_OFFSETS[i]
		var crate := _box(Vector3(off.x, y + s.y * 0.5, off.y), s, crate_mat)
		crate.rotation_degrees = Vector3(0, CRATE_YAW[i], 0)
		add_child(crate)
		# A thin band of corner-edge trim so the crate reads as a sealed box.
		_add_crate_band(off, y, s, edge_mat)
		# Hazard stencils on the front face of the bottom two crates.
		if hazard_labels and i < 2:
			_add_crate_label(i, off, y, s)
		y += s.y

	if with_cylinder:
		_build_cylinder()
	if with_cone:
		_build_cone()


# Thin trim band wrapping the top edge of a crate (a strap / lid seam).
func _add_crate_band(off: Vector2, base_y: float, s: Vector3, mat: Material) -> void:
	var band_h := 0.03
	var by: float = base_y + s.y - band_h * 0.5
	var t := 0.012
	var band := _box(Vector3(off.x, by, off.y), Vector3(s.x + t, band_h, s.z + t), mat)
	band.rotation_degrees = Vector3(0, _yaw_for(off), 0)
	add_child(band)


# Stencilled warning text painted proud of a crate's front (+Z) face.
func _add_crate_label(index: int, off: Vector2, base_y: float, s: Vector3) -> void:
	var text: String = "FRAGILE" if index == 0 else "KEEP DRY"
	var q: MeshInstance3D = HangarKit.stencil(text, Vector2(s.x * 0.7, s.y * 0.26), Color(0.16, 0.16, 0.18))
	if q == null:
		return
	var yaw: float = CRATE_YAW[index]
	var node := Node3D.new()
	node.rotation_degrees = Vector3(0, yaw, 0)
	node.position = Vector3(off.x, base_y + s.y * 0.5, off.y)
	# Place proud of the front face (local +Z), z += 0.01.
	q.position = Vector3(0, 0, s.z * 0.5 + 0.01)
	node.add_child(q)
	add_child(node)


# A red gas cylinder beside the pile — vertical body + dome top + a draping hose.
func _build_cylinder() -> void:
	var pos := Vector3(0.55, 0.0, 0.18)
	var body_h := 0.72
	var body_r := 0.11
	var body_mat := HangarKit.painted_metal(cylinder_color, wear, 0.35, 0.5)
	# Body.
	add_child(_cyl(pos + Vector3(0, body_h * 0.5, 0), body_r, body_r, body_h, body_mat))
	# Dome top (a short wider cap).
	var cap_mat := HangarKit.worn_metal(cylinder_color.lightened(0.1))
	add_child(_cyl(pos + Vector3(0, body_h + 0.03, 0), body_r * 0.55, body_r * 0.85, 0.07, cap_mat))
	# Valve stub.
	add_child(_cyl(pos + Vector3(0, body_h + 0.11, 0), 0.022, 0.022, 0.06, cap_mat))
	# Hose — 3 thin cylinders draping from the valve down toward the pile.
	var hose_mat := HangarKit.painted_metal(Color(0.10, 0.10, 0.12), 0.2, 0.1, 0.8)
	var hr := 0.018
	var p0 := pos + Vector3(0, body_h + 0.11, 0)
	var p1 := pos + Vector3(-0.14, body_h - 0.06, 0.04)
	var p2 := pos + Vector3(-0.26, body_h * 0.45, 0.02)
	var p3 := pos + Vector3(-0.30, 0.10, -0.06)
	_add_hose_segment(p0, p1, hr, hose_mat)
	_add_hose_segment(p1, p2, hr, hose_mat)
	_add_hose_segment(p2, p3, hr, hose_mat)


# One thin cylinder spanning a→b (a hose link).
func _add_hose_segment(a: Vector3, b: Vector3, radius: float, mat: Material) -> void:
	var diff: Vector3 = b - a
	var length: float = diff.length()
	if length < 0.001:
		return
	var seg := _cyl(Vector3.ZERO, radius, radius, length, mat)
	var node := Node3D.new()
	node.position = a.lerp(b, 0.5)
	# CylinderMesh runs along local +Y; aim it from a to b.
	var dir: Vector3 = diff.normalized()
	var up := Vector3.UP
	if absf(dir.dot(up)) > 0.999:
		up = Vector3.RIGHT
	node.look_at_from_position(node.position, node.position + dir, up)
	# look_at points local -Z at the target; rotate so local +Y aligns instead.
	node.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	node.add_child(seg)
	add_child(node)


# A striped warning cone in front of the pile, on a small base.
func _build_cone() -> void:
	var pos := Vector3(-0.05, 0.0, 0.62)
	var stripe := HangarKit.striped_mat()
	# Small base plate.
	var base_mat := HangarKit.worn_metal(Color(0.18, 0.16, 0.14))
	add_child(_box(pos + Vector3(0, 0.018, 0), Vector3(0.26, 0.036, 0.26), base_mat))
	# Cone body — CylinderMesh with small top_radius + large bottom_radius.
	var cone_h := 0.40
	add_child(_cyl(pos + Vector3(0, 0.036 + cone_h * 0.5, 0), 0.02, 0.14, cone_h, stripe))


# ── Local helpers (delegate to the shared HangarKit for the family look) ──
func _palette_color() -> Color:
	match palette:
		"wood": return Color(0.45, 0.32, 0.20)
		"metal": return Color(0.55, 0.56, 0.60)
		_: return Color(0.62, 0.48, 0.32)  # cardboard (tan)


func _yaw_for(off: Vector2) -> float:
	for i in range(CRATE_OFFSETS.size()):
		if CRATE_OFFSETS[i] == off:
			return CRATE_YAW[i]
	return 0.0


func _mat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	return HangarKit.painted_metal(c, wear, metal, rough)


func _box(center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


func _cyl(center: Vector3, top_r: float, bottom_r: float, height: float, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_r
	mesh.bottom_radius = bottom_r
	mesh.height = height
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


func _pc(s: String, fallback: Color) -> Color:
	var p := s.split(",")
	if p.size() < 3:
		return fallback
	return Color(float(p[0]), float(p[1]), float(p[2]), 1.0 if p.size() < 4 else float(p[3]))
