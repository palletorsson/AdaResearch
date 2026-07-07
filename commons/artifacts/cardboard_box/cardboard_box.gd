extends Node3D
class_name CardboardBox

# @identity
# essence: an open kraft cardboard box — a light tan/brown carton with a thin bottom panel, four thin upright walls, and four top flaps splayed open at varying angles on their hinged edges. Where the crate is heavy timber sealed for transit, the box is the crate's disposable cousin: corrugated paper, cheap, single-trip, already opened. The flaps stand up and out like a flower mid-bloom. The box is the room saying "this arrived, and somebody already unpacked it".
# desire: the box wants to be CAUGHT IN THE ACT of being unpacked — not the sealed parcel, not the folded-flat recycling, but the in-between moment when the tape is cut and the flaps spring open and the contents are about to come out. It wants to read as RECENT, CASUAL, and TEMPORARY: the thing you flatten and throw away after one use. Its open mouth is an invitation and a small mess.
# critical_parameter: flap_open_deg — 0 = sealed flaps lying flat across the top, a closed box ready to ship; ~75-100 = flaps standing open, the box unpacked and in use. The same carton tells two different stories: arrival-not-yet-begun vs arrival-already-happened. box_width / box_height / box_depth set the parcel's aspect — flat = document/poster, tall = bottle/instrument, cube = dry goods.
# triggers: _ready() builds bottom panel + 4 walls + 4 hinged flaps from exports; apply_grid_config rebuilds when DNA changes.
# emerges: one open box in a corner reads as JUST DELIVERED, mid-unpacking — the lab is in motion, casual, lived-in. A sealed box (flap_open_deg 0) reads as INBOUND, untouched. Where the crate is a monument to the supply chain's weight, the cardboard box is its lightness: the everyday, throwaway packaging that surrounds every real workspace. Disposable, recyclable, honest about being cheap.
# needs: thin bottom panel [present]; four thin upright walls open at the top [present]; four flaps hinged at the top edge of each wall [present]; flaps at varied open angles for a natural look [present]; kraft cardboard material [present]; slightly darker interior tone [present]
# relationships: cousin to crate (both are CONTAINERS-IN-TRANSIT, but the crate is heavy sealed timber that says "you may open once unpacked"; the box is light disposable kraft that says "already opened, take what you need"); peer to lock_box (both hold contents, but the box hides nothing — its mouth is open); structural cousin to ceiling_vent (both are utility-not-instrument, the plumbing of the lab's lived life).
# truth: the cardboard box is the supply chain's lightest form — the throwaway skin that everything ships inside. Where the crate remembers the freight and the forklift, the box remembers the doorstep and the box-cutter. It is the most honest object in the room about being temporary: made to be opened once, flattened, and recycled. Every open box is a small monument to the ordinary, daily act of receiving.

## An open kraft cardboard box.
##
## Built procedurally from DNA exports. Origin is at the BOTTOM CENTRE
## of the box (floor-stack friendly). Default dimensions are a small
## carton ~0.4m wide with its four top flaps splayed open.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var box_width: float = 0.4
@export var box_height: float = 0.35
@export var box_depth: float = 0.4
@export var wall_thickness: float = 0.012

@export_group("Flaps")
## How far the top flaps swing open from the closed (flat) position.
## 0 = sealed/closed box ready to ship; ~75-100 = open/unpacked/in-use.
@export var flap_open_deg: float = 75.0
## Toggle the four top flaps. OFF = an open-topped tray with no lid.
@export var show_flaps: bool = true

@export_group("Material")
@export var box_color: Color = Color(0.76, 0.64, 0.45)
@export var interior_color: Color = Color(0.66, 0.55, 0.39)

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
	if has_meta("config_box_width"):
		box_width = float(str(get_meta("config_box_width")))
	if has_meta("config_box_height"):
		box_height = float(str(get_meta("config_box_height")))
	if has_meta("config_box_depth"):
		box_depth = float(str(get_meta("config_box_depth")))
	if has_meta("config_wall_thickness"):
		wall_thickness = float(str(get_meta("config_wall_thickness")))
	if has_meta("config_flap_open_deg"):
		flap_open_deg = float(str(get_meta("config_flap_open_deg")))
	if has_meta("config_show_flaps"):
		var s: String = str(get_meta("config_show_flaps")).to_lower()
		show_flaps = s == "true" or s == "1" or s == "yes"
	if has_meta("config_box_color"):
		box_color = _parse_color(str(get_meta("config_box_color")), box_color)
	if has_meta("config_interior_color"):
		interior_color = _parse_color(str(get_meta("config_interior_color")), interior_color)


func _parse_color(raw: String, fallback: Color) -> Color:
	var parts := raw.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	return fallback


# ── Build ─────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true

	var hw := box_width * 0.5
	var hd := box_depth * 0.5
	var t := wall_thickness

	# Kraft cardboard material (outer) + a slightly darker interior tone.
	var box_mat := _make_card_mat(box_color)
	var inner_mat := _make_card_mat(interior_color)

	# ── 1. Bottom panel ──────────────────────────────────────────────
	# A thin slab at the base, sitting just above the floor.
	var bottom := MeshInstance3D.new()
	bottom.name = "BottomPanel"
	var bm := BoxMesh.new()
	bm.size = Vector3(box_width, t, box_depth)
	bottom.mesh = bm
	bottom.material_override = inner_mat
	bottom.position = Vector3(0, t * 0.5, 0)
	add_child(bottom)

	# ── 2. Four upright walls (open at the top) ──────────────────────
	# Front (+Z) and Back (-Z) span the full width; Left/Right span the
	# inner depth so the four panels meet at the corners without overlap.
	var wall_y := box_height * 0.5
	var inner_depth := box_depth - t * 2.0

	# Front (+Z)
	_add_wall("FrontWall",
		Vector3(0, wall_y, hd - t * 0.5),
		Vector3(box_width, box_height, t), box_mat)
	# Back (-Z)
	_add_wall("BackWall",
		Vector3(0, wall_y, -hd + t * 0.5),
		Vector3(box_width, box_height, t), box_mat)
	# Left (-X)
	_add_wall("LeftWall",
		Vector3(-hw + t * 0.5, wall_y, 0),
		Vector3(t, box_height, inner_depth), box_mat)
	# Right (+X)
	_add_wall("RightWall",
		Vector3(hw - t * 0.5, wall_y, 0),
		Vector3(t, box_height, inner_depth), box_mat)

	# ── 3. Four hinged top flaps ─────────────────────────────────────
	# Each flap hinges at the TOP edge of its wall. A flap covers half the
	# opposing span (so two opposite flaps would meet if closed). Vary the
	# open angle by ±15° around flap_open_deg for a natural splayed look.
	if show_flaps:
		# Front/back flaps fold over the depth; their length is half the
		# inner depth. Left/right flaps fold over the width.
		var fb_len := inner_depth * 0.5
		var lr_len := (box_width - t * 2.0) * 0.5

		# Front flap — hinge at the front-top edge, swings outward toward +Z.
		_add_flap("FrontFlap",
			Vector3(0, box_height, hd - t * 0.5),
			Vector3(box_width, t, fb_len),
			fb_len,
			deg_to_rad(-(flap_open_deg + 12.0)),
			Vector3(1, 0, 0),
			Vector3(0, 0, 1),
			box_mat, inner_mat)

		# Back flap — hinge at the back-top edge, swings outward toward -Z.
		_add_flap("BackFlap",
			Vector3(0, box_height, -hd + t * 0.5),
			Vector3(box_width, t, fb_len),
			fb_len,
			deg_to_rad(flap_open_deg - 14.0),
			Vector3(1, 0, 0),
			Vector3(0, 0, -1),
			box_mat, inner_mat)

		# Left flap — hinge at the left-top edge, swings outward toward -X.
		_add_flap("LeftFlap",
			Vector3(-hw + t * 0.5, box_height, 0),
			Vector3(lr_len, t, inner_depth),
			lr_len,
			deg_to_rad(flap_open_deg + 10.0),
			Vector3(0, 0, 1),
			Vector3(-1, 0, 0),
			box_mat, inner_mat)

		# Right flap — hinge at the right-top edge, swings outward toward +X.
		_add_flap("RightFlap",
			Vector3(hw - t * 0.5, box_height, 0),
			Vector3(lr_len, t, inner_depth),
			lr_len,
			deg_to_rad(-(flap_open_deg - 6.0)),
			Vector3(0, 0, 1),
			Vector3(1, 0, 0),
			box_mat, inner_mat)


func _make_card_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.92
	m.metallic = 0.0
	return m


# Add one upright wall as a thin box.
func _add_wall(wall_name: String, pos: Vector3, size: Vector3,
		mat: StandardMaterial3D) -> void:
	var w := MeshInstance3D.new()
	w.name = wall_name
	var mesh := BoxMesh.new()
	mesh.size = size
	w.mesh = mesh
	w.material_override = mat
	w.position = pos
	add_child(w)


# Add one hinged flap.
#
# A child Node3D acts as the HINGE pivot, placed at the top edge of the
# wall (hinge_pos). The pivot rotates by open_angle around hinge_axis so
# the flap swings open from its hinged edge — like a real flap. The flap
# mesh is then offset from the pivot by half its length along out_dir so
# its near edge sits ON the hinge and the panel extends outward.
func _add_flap(flap_name: String,
		hinge_pos: Vector3, size: Vector3, length: float,
		open_angle: float, hinge_axis: Vector3, out_dir: Vector3,
		outer_mat: StandardMaterial3D, inner_mat: StandardMaterial3D) -> void:
	var pivot := Node3D.new()
	pivot.name = flap_name + "Hinge"
	pivot.position = hinge_pos
	pivot.rotate(hinge_axis.normalized(), open_angle)
	add_child(pivot)

	var flap := MeshInstance3D.new()
	flap.name = flap_name
	var mesh := BoxMesh.new()
	mesh.size = size
	flap.mesh = mesh
	# Interior tone faces up/in; outer kraft faces out — use the outer
	# tone for the flap so the splayed panels read as cardboard.
	flap.material_override = outer_mat
	# Offset the flap so its hinged edge sits at the pivot and the panel
	# extends outward by half its length (in the pivot's LOCAL space, the
	# closed-flat orientation lies along out_dir).
	flap.position = out_dir.normalized() * (length * 0.5)
	pivot.add_child(flap)
