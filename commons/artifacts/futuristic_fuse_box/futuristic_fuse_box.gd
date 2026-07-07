extends Node3D
class_name FuturisticFuseBox

# @identity
# essence: a chunky concrete utility monolith — a vertical poured-concrete slab with one corner shaved at 45° (the top-right bevel), a dark graphite edge-cap running along that bevel and down the right flank, and a single yellow hazard sticker low on its face. It is the building's nervous system made into furniture: the fuse box, the junction, the place where the current is gathered, named, and made interruptible. Not an instrument you read but an organ you trust — until it fails, and then it is the only thing in the room. The slab is the architecture admitting that power arrives from elsewhere and must be SWITCHED, broken, made safe to touch.
# desire: every space pretends its power is ambient, free, just-there in the walls. The fuse box breaks that pretence — it wants to be the SINGLE POINT OF INTERRUPTION, the throat the current passes through, the thing you reach for when something must be cut. Even at rest it implies an emergency not yet arrived: the yellow sticker wants to be seen before it is needed, the bevel wants to read as deliberate (someone shaped this), the graphite cap wants to say "this edge is hard, this layer is newer than the concrete it covers".
# critical_parameter: chamfer + cap_color decide whether this reads as a FUTURISTIC SWITCHED MONOLITH (deep 45° bevel + dark graphite trim = a shaped, layered, deliberate object) or a PLAIN CAST BLOCK (no bevel, body-colour cap = anonymous poured infrastructure). Dimensions set the proportion: a tall narrow slab reads as a RISER / MAINS COLUMN, a squat wide slab reads as a GROUND-LEVEL JUNCTION. Same concrete, opposite statements about how designed the interruption is.
# triggers: _ready() sweeps the chamfered X-Y silhouette into a single solid mesh via MeshFactory.extrude_profile_z + lays the graphite cap along the bevel and right edge + a yellow warning sticker low on the front from exports; apply_grid_config rebuilds when DNA changes.
# emerges: a single fuse box reads as A SERVICED ROOM — power is managed here, someone can cut it. A ROW of them reads as a PLANT ROOM / SUBSTATION — the space is infrastructure, not destination. A bright sticker reads as LIVE / DO-NOT-OPEN; a faded one reads as DECOMMISSIONED. The bevel + graphite cap read as INTENTIONAL DESIGN against the dumb mass of concrete. The box is a spatial verb: it does not describe the power, it GATHERS and INTERRUPTS it.
# needs: a swept chamfered-slab mesh giving the beveled silhouette [present]; weathered concrete body [present]; a dark graphite cap along the bevel + right edge [present]; a cast seam / groove line across the upper face [present]; a yellow hazard sticker low on the front [present]
# relationships: peer to concrete_barrier (both are POURED-AUTHORITY objects — the barrier channels movement, the fuse box channels current; both wear hazard colour that announces itself before it is tested); cousin to ceiling_vent (both are UTILITY-NOT-INSTRUMENT, the lived plumbing of the room rather than its stagecraft); sibling to fire_extinguisher (both are SIGNALS-BEFORE-OBJECTS, the saturated warning recognised before it is read).
# truth: a fuse box is the physical confession that power is not free — that it arrives from somewhere, that it is dangerous, and that someone, somewhere, decided it must be interruptible. The yellow sticker is not decoration; it is the boundary announcing itself, demanding to be seen before it is touched. The graphite cap over the concrete is time made visible: a newer, harder layer added to an older mass. Every fuse box is a small monument to the management of force — proof that current is governed, that the wall is not just a wall, that the room can be made safe.

## A futuristic concrete fuse-box monolith.
##
## Built procedurally from DNA exports. Origin is at the BOTTOM CENTRE of the
## slab (floor-resting, Y up). Width runs along X, height along Y, depth along
## Z. The front face is +Z. The silhouette is a real chamfered-rectangle
## cross-section swept along the depth by MeshFactory (commons/artifacts/shared)
## into a single solid — the top-right corner is shaved at 45°.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var width: float = 0.8
@export var height: float = 1.0
@export var depth: float = 0.28
## How deep the top-right corner is shaved at 45° — the futuristic bevel.
@export var chamfer: float = 0.28

@export_group("Markings")
## Show the small yellow hazard sticker low on the front face.
@export var show_sticker: bool = true

@export_group("Material")
## Weathered poured-concrete grey for the slab body.
@export var body_color: Color = Color(0.66, 0.66, 0.64)
## Dark graphite for the bevel cap + right-edge trim — the "futuristic" layer.
@export var cap_color: Color = Color(0.16, 0.17, 0.20)
## Warning yellow for the hazard sticker.
@export var sticker_color: Color = Color(0.92, 0.82, 0.18)

# ── Constants ─────────────────────────────────────────────────────────

## The mesh factory that sweeps the chamfered cross-section into a real solid.
const MF := preload("res://commons/artifacts/shared/mesh_factory.gd")
const CAP_THICKNESS: float = 0.03    # how proud the graphite trim sits
const CAP_WIDTH: float = 0.07        # face-width of the graphite strips

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
	if has_meta("config_width"):
		width = float(str(get_meta("config_width")))
	if has_meta("config_height"):
		height = float(str(get_meta("config_height")))
	if has_meta("config_depth"):
		depth = float(str(get_meta("config_depth")))
	if has_meta("config_chamfer"):
		chamfer = float(str(get_meta("config_chamfer")))
	if has_meta("config_show_sticker"):
		var s: String = str(get_meta("config_show_sticker")).to_lower()
		show_sticker = s == "true" or s == "1" or s == "yes" or s == "on"
	if has_meta("config_body_color"):
		body_color = _parse_color(str(get_meta("config_body_color")), body_color)
	if has_meta("config_cap_color"):
		cap_color = _parse_color(str(get_meta("config_cap_color")), cap_color)
	if has_meta("config_sticker_color"):
		sticker_color = _parse_color(str(get_meta("config_sticker_color")), sticker_color)


func _parse_color(raw: String, fallback: Color) -> Color:
	var parts := raw.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	return fallback


# ── Build ─────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true

	var hd: float = depth * 0.5
	var ch: float = clampf(chamfer, 0.0, minf(width, height) * 0.8)
	var front_z: float = hd                       # +Z face of the swept solid

	# ── 1. Concrete body — a REAL swept mesh (MeshFactory) ───────────
	# A chamfered-rectangle silhouette (top-right corner sliced at 45°) is
	# extruded along the depth into a single solid with a true beveled face,
	# not stacked boxes. Front face is +Z.
	var outline := MF.chamfer_rect_outline(width, height, ch)
	var body := MeshInstance3D.new()
	body.name = "FuseBoxBody"
	body.mesh = MF.extrude_profile_z(outline, depth)
	body.material_override = _make_concrete_mat()
	add_child(body)

	# ── 2. Cast seam / groove line across the upper front ────────────
	# A thin horizontal box just below the chamfer — the cast seam, a touch
	# darker than the body, sitting slightly proud of the front face.
	var seam_y: float = height - ch - 0.02
	if seam_y > height * 0.5:
		var seam := MeshInstance3D.new()
		seam.name = "CastSeam"
		var seam_mesh := BoxMesh.new()
		seam_mesh.size = Vector3(width * 0.92, 0.02, 0.012)
		seam.mesh = seam_mesh
		seam.material_override = _make_flat_mat(body_color.darkened(0.18), 0.92)
		seam.position = Vector3(0.0, seam_y, front_z + 0.006)
		add_child(seam)

	# ── 3. Dark graphite cap — bevel trim + right-edge trim ──────────
	_add_bevel_cap(ch, hd)
	_add_right_edge_cap(ch, hd)

	# ── 4. Yellow hazard sticker low on the front face ───────────────
	if show_sticker:
		_add_sticker(front_z)


func _make_concrete_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = body_color
	m.roughness = 0.9
	m.metallic = 0.0
	# The swept solid lights via forced-outward normals; disabling back-face
	# cull keeps it reading solid from any angle.
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func _make_flat_mat(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.0
	return m


# A thin dark panel running ALONG the 45° chamfer edge — a box rotated 45°
# about Z, laid over the bevel so it reads as a hard graphite layer on the
# concrete. The bevel runs from (hw, height-ch) to (hw-ch, height).
func _add_bevel_cap(ch: float, hd: float) -> void:
	var hw: float = width * 0.5
	# Midpoint of the bevel edge in X-Y.
	var mid := Vector3((hw + (hw - ch)) * 0.5, ((height - ch) + height) * 0.5, hd)
	# Bevel edge length (45° -> ch * sqrt(2)).
	var edge_len: float = ch * sqrt(2.0)
	var cap := MeshInstance3D.new()
	cap.name = "GraphiteBevelCap"
	var cap_mesh := BoxMesh.new()
	cap_mesh.size = Vector3(edge_len, CAP_WIDTH, depth + CAP_THICKNESS)
	cap.mesh = cap_mesh
	cap.material_override = _make_flat_mat(cap_color, 0.55)
	cap.position = mid
	# Top-right bevel descends left-to-right, so rotate -45° about Z.
	cap.rotation = Vector3(0.0, 0.0, deg_to_rad(-45.0))
	add_child(cap)


# A thin dark vertical strip down the +X (right) edge — the graphite flank
# trim, stopping below the chamfer so it meets the bevel cap.
func _add_right_edge_cap(ch: float, hd: float) -> void:
	var hw: float = width * 0.5
	var strip_h: float = height - ch
	var cap := MeshInstance3D.new()
	cap.name = "GraphiteRightEdge"
	var cap_mesh := BoxMesh.new()
	cap_mesh.size = Vector3(CAP_WIDTH, strip_h, depth + CAP_THICKNESS)
	cap.mesh = cap_mesh
	cap.material_override = _make_flat_mat(cap_color, 0.55)
	cap.position = Vector3(hw - CAP_WIDTH * 0.5, strip_h * 0.5, hd)
	add_child(cap)


# A small square yellow hazard sticker low on the +Z face, with a thin dark
# border box behind it so the yellow reads as an applied label.
func _add_sticker(front_z: float) -> void:
	var sticker_size: float = 0.18
	var border_size: float = sticker_size + 0.03
	var sticker_y: float = height * 0.28

	var border := MeshInstance3D.new()
	border.name = "StickerBorder"
	var bm := BoxMesh.new()
	bm.size = Vector3(border_size, border_size, 0.004)
	border.mesh = bm
	border.material_override = _make_flat_mat(Color(0.08, 0.08, 0.09), 0.8)
	border.position = Vector3(0.0, sticker_y, front_z + 0.004)
	add_child(border)

	var sticker := MeshInstance3D.new()
	sticker.name = "WarningSticker"
	var sm := BoxMesh.new()
	sm.size = Vector3(sticker_size, sticker_size, 0.004)
	sticker.mesh = sm
	sticker.material_override = _make_flat_mat(sticker_color, 0.45)
	sticker.position = Vector3(0.0, sticker_y, front_z + 0.008)
	add_child(sticker)
