extends Node3D
class_name Crate

# @identity
# essence: a wooden shipping crate — a stout cube/cuboid made of vertical planks on each face, dark corner reinforcement strips, a diagonal X-brace on the front, and a faint stencilled stamp (a number, a destination, an arrow). The crate is the lab's confession that the space did not invent itself: the equipment ARRIVED, in containers, from somewhere else. The crate carries the smell of the supply chain. The crate is the room saying "this came in a box".
# desire: every lab pretends to be self-sufficient — desks, instruments, screens. The crate breaks that pretence. It wants to be the OBJECT IN TRANSIT, the thing not yet unpacked, the thing about to leave. Even at rest it implies movement: an arrow, a label, a destination, a "this side up". Its silhouette refuses the architecture's polish.
# critical_parameter: crate_width / crate_depth / crate_height — the box's aspect. A wide flat crate reads as ARTWORK or PANEL shipment. A tall narrow crate reads as INSTRUMENT shipment. A near-cube reads as DRY GOODS / STOCK. plank_count controls how MANY vertical boards span each face (the visual rhythm). show_x_brace toggles the diagonal cross — present = "this end up, fragile equipment"; absent = "bulk goods, stack them".
# triggers: _ready() builds 6 plank-faced sides + corner strips + optional X-brace + stamp/label from exports; apply_grid_config rebuilds when DNA changes.
# emerges: a single crate in a lab corner reads as RECENTLY DELIVERED — the experiment is new, the lab is in motion. A STACK of crates reads as LOGISTICS HUB — the space is a transit point, not a destination. Crates with arrow-stamps pointing up read as PROPER STORAGE; arrows on their side read as MISHANDLED. The crate is a temporal marker: time has a direction, equipment moves through space, the lab is a node in a network.
# needs: 6 plank-clad faces [present]; corner reinforcement strips [present]; optional diagonal X-brace on the front [present]; stamped label area [present]; weathered wood material [present]; metal strap edges [present]
# relationships: peer to lock_box (both contain unknown contents, but the lock_box says "you may NOT open"; the crate says "you may, once unpacked"); cousin to large_table (both are FURNITURE-OF-WORK but the table is the stage, the crate is the wings); structural cousin to ceiling_vent (both are utility-not-instrument, plumbing for the lab's lived life).
# truth: the lab does not begin with the experiment. It begins with the delivery. The crate is the lab's memory of arrival — proof that science has a supply chain, that equipment is hauled in by humans, that no instrument is born in place. Every crate is a small monument to the workers between the manufacturer and the bench.

## A wooden shipping crate.
##
## Built procedurally from DNA exports. Origin is at the BOTTOM CENTRE
## of the crate (floor-stack friendly). Default dimensions are a near-cube
## around 0.7m on each side — bigger than a typical box, smaller than
## a person.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var crate_width: float = 0.72
@export var crate_depth: float = 0.72
@export var crate_height: float = 0.68
@export var plank_count: int = 5
@export var plank_thickness: float = 0.018
@export var corner_strip_width: float = 0.04
@export var corner_strip_thickness: float = 0.012

@export_group("Markings")
## Show the diagonal cross brace on the front face (the classic
## "this end up, fragile" look).
@export var show_x_brace: bool = true
## Show stencilled stamp area on the front face.
@export var show_stamp: bool = true
## Optional stamp label — short, all caps reads best.
@export var stamp_label: String = "ADA-LAB"
## Show a small "up arrow" symbol next to the stamp.
@export var show_up_arrow: bool = true

@export_group("Material")
@export var plank_color: Color = Color(0.45, 0.32, 0.22)
@export var plank_color_alt: Color = Color(0.51, 0.36, 0.24)
@export var strip_color: Color = Color(0.18, 0.16, 0.14)
@export var stamp_color: Color = Color(0.08, 0.07, 0.06)
@export var brace_color: Color = Color(0.38, 0.26, 0.18)

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
			c.queue_free()
		_built = false
		_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_crate_width"):
		crate_width = float(str(get_meta("config_crate_width")))
	if has_meta("config_crate_depth"):
		crate_depth = float(str(get_meta("config_crate_depth")))
	if has_meta("config_crate_height"):
		crate_height = float(str(get_meta("config_crate_height")))
	if has_meta("config_plank_count"):
		plank_count = int(str(get_meta("config_plank_count")))
	if has_meta("config_show_x_brace"):
		var s: String = str(get_meta("config_show_x_brace")).to_lower()
		show_x_brace = s == "true" or s == "1" or s == "yes"
	if has_meta("config_show_stamp"):
		var s2: String = str(get_meta("config_show_stamp")).to_lower()
		show_stamp = s2 == "true" or s2 == "1" or s2 == "yes"
	if has_meta("config_stamp_label"):
		stamp_label = str(get_meta("config_stamp_label"))
	if has_meta("config_plank_color"):
		plank_color = _parse_color(str(get_meta("config_plank_color")), plank_color)


func _parse_color(raw: String, fallback: Color) -> Color:
	var parts := raw.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	return fallback


# ── Build ─────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true

	var hw := crate_width * 0.5
	var hd := crate_depth * 0.5
	var ch := crate_height

	# Materials reused across the build.
	var plank_mat_a := _make_wood_mat(plank_color)
	var plank_mat_b := _make_wood_mat(plank_color_alt)
	var strip_mat := StandardMaterial3D.new()
	strip_mat.albedo_color = strip_color
	strip_mat.roughness = 0.55
	strip_mat.metallic = 0.4

	# ── 1. Build six faces, each a row of vertical planks ────────────
	# Faces: front (+Z), back (-Z), left (-X), right (+X), top (+Y), bottom (-Y).
	# For top/bottom the planks run along +X.

	# Front (+Z)
	_build_plank_face("FrontFace",
		Vector3(0, ch * 0.5, hd),
		Vector3(0, 0, 0),
		crate_width, ch, plank_count, false,
		plank_mat_a, plank_mat_b)
	# Back (-Z)
	_build_plank_face("BackFace",
		Vector3(0, ch * 0.5, -hd),
		Vector3(0, PI, 0),
		crate_width, ch, plank_count, false,
		plank_mat_a, plank_mat_b)
	# Left (-X)
	_build_plank_face("LeftFace",
		Vector3(-hw, ch * 0.5, 0),
		Vector3(0, -PI * 0.5, 0),
		crate_depth, ch, plank_count, false,
		plank_mat_b, plank_mat_a)
	# Right (+X)
	_build_plank_face("RightFace",
		Vector3(hw, ch * 0.5, 0),
		Vector3(0, PI * 0.5, 0),
		crate_depth, ch, plank_count, false,
		plank_mat_b, plank_mat_a)
	# Top (+Y) — planks run along X
	_build_plank_face("TopFace",
		Vector3(0, ch, 0),
		Vector3(-PI * 0.5, 0, 0),
		crate_width, crate_depth, plank_count, true,
		plank_mat_a, plank_mat_b)
	# Bottom (-Y) — planks run along X
	_build_plank_face("BottomFace",
		Vector3(0, 0, 0),
		Vector3(PI * 0.5, 0, 0),
		crate_width, crate_depth, plank_count, true,
		plank_mat_b, plank_mat_a)

	# ── 2. Corner reinforcement strips ───────────────────────────────
	# Twelve strips: 4 vertical at the corners, 4 horizontal top edge, 4 bottom.
	_add_vertical_strip(Vector3(hw, ch * 0.5, hd), ch, strip_mat)
	_add_vertical_strip(Vector3(-hw, ch * 0.5, hd), ch, strip_mat)
	_add_vertical_strip(Vector3(hw, ch * 0.5, -hd), ch, strip_mat)
	_add_vertical_strip(Vector3(-hw, ch * 0.5, -hd), ch, strip_mat)

	_add_horizontal_strip_x(Vector3(0, ch - corner_strip_width * 0.5, hd),  crate_width, strip_mat)
	_add_horizontal_strip_x(Vector3(0, ch - corner_strip_width * 0.5, -hd), crate_width, strip_mat)
	_add_horizontal_strip_x(Vector3(0, corner_strip_width * 0.5, hd),       crate_width, strip_mat)
	_add_horizontal_strip_x(Vector3(0, corner_strip_width * 0.5, -hd),      crate_width, strip_mat)

	_add_horizontal_strip_z(Vector3(hw,  ch - corner_strip_width * 0.5, 0), crate_depth, strip_mat)
	_add_horizontal_strip_z(Vector3(-hw, ch - corner_strip_width * 0.5, 0), crate_depth, strip_mat)
	_add_horizontal_strip_z(Vector3(hw,  corner_strip_width * 0.5, 0),      crate_depth, strip_mat)
	_add_horizontal_strip_z(Vector3(-hw, corner_strip_width * 0.5, 0),      crate_depth, strip_mat)

	# ── 3. Diagonal X-brace on the front face ────────────────────────
	if show_x_brace:
		var brace_mat := _make_wood_mat(brace_color)
		var diag := sqrt(crate_width * crate_width + ch * ch) * 0.94
		var ang := atan2(ch * 0.94, crate_width * 0.94)
		var brace_thickness := 0.022
		var brace_width := 0.06
		var z_off := hd + plank_thickness * 0.5 + brace_thickness * 0.5

		var b1 := MeshInstance3D.new()
		b1.name = "XBrace1"
		var b1m := BoxMesh.new()
		b1m.size = Vector3(diag, brace_width, brace_thickness)
		b1.mesh = b1m
		b1.material_override = brace_mat
		b1.position = Vector3(0, ch * 0.5, z_off)
		b1.rotation = Vector3(0, 0, ang)
		add_child(b1)

		var b2 := MeshInstance3D.new()
		b2.name = "XBrace2"
		var b2m := BoxMesh.new()
		b2m.size = Vector3(diag, brace_width, brace_thickness)
		b2.mesh = b2m
		b2.material_override = brace_mat
		b2.position = Vector3(0, ch * 0.5, z_off)
		b2.rotation = Vector3(0, 0, -ang)
		add_child(b2)

	# ── 4. Stamp / label on the front face ───────────────────────────
	if show_stamp:
		var stamp_mat := StandardMaterial3D.new()
		stamp_mat.albedo_color = stamp_color
		stamp_mat.roughness = 0.8
		stamp_mat.metallic = 0.0

		var stamp_box := MeshInstance3D.new()
		stamp_box.name = "StampPlaque"
		var sm := BoxMesh.new()
		sm.size = Vector3(crate_width * 0.36, ch * 0.13, 0.003)
		stamp_box.mesh = sm
		stamp_box.material_override = stamp_mat
		# Sit just below centre on the front face — clear of the X-brace
		# intersection if both are shown.
		stamp_box.position = Vector3(-crate_width * 0.18,
			ch * 0.30, hd + plank_thickness * 0.5 + 0.004)
		add_child(stamp_box)

		# A short Label3D for the stamp text itself.
		if stamp_label.strip_edges().length() > 0:
			var lbl := Label3D.new()
			lbl.name = "StampText"
			lbl.text = stamp_label
			lbl.font_size = 48
			lbl.outline_size = 0
			lbl.pixel_size = 0.0025
			lbl.modulate = Color(0.85, 0.78, 0.7)
			lbl.position = Vector3(-crate_width * 0.18,
				ch * 0.30, hd + plank_thickness * 0.5 + 0.008)
			lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
			add_child(lbl)

		if show_up_arrow:
			# Arrow plaque on the right side of the front face.
			var arrow_box := MeshInstance3D.new()
			arrow_box.name = "ArrowPlaque"
			var am := BoxMesh.new()
			am.size = Vector3(crate_width * 0.16, ch * 0.22, 0.003)
			arrow_box.mesh = am
			arrow_box.material_override = stamp_mat
			arrow_box.position = Vector3(crate_width * 0.30,
				ch * 0.30, hd + plank_thickness * 0.5 + 0.004)
			add_child(arrow_box)

			var arrow_lbl := Label3D.new()
			arrow_lbl.name = "UpArrowText"
			arrow_lbl.text = "↑"
			arrow_lbl.font_size = 64
			arrow_lbl.outline_size = 0
			arrow_lbl.pixel_size = 0.0035
			arrow_lbl.modulate = Color(0.85, 0.78, 0.7)
			arrow_lbl.position = Vector3(crate_width * 0.30,
				ch * 0.30, hd + plank_thickness * 0.5 + 0.008)
			arrow_lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
			add_child(arrow_lbl)


func _make_wood_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.78
	m.metallic = 0.0
	return m


# Build one face as a row of planks.
# Planks run along the local-X axis of the parent face; the face is
# positioned and rotated so that local +Z is OUTWARD.
func _build_plank_face(face_name: String,
		pos: Vector3, rot: Vector3,
		face_width: float, face_height: float,
		count: int, planks_run_x: bool,
		mat_a: StandardMaterial3D, mat_b: StandardMaterial3D) -> void:
	var face := Node3D.new()
	face.name = face_name
	face.position = pos
	face.rotation = rot
	add_child(face)

	# Number of planks across the width.
	var n: int = maxi(2, count)
	var plank_w: float = face_width / float(n)
	# Each plank is a thin box: width x height x thickness.
	# Stagger colors a/b across the planks for visual rhythm.
	for i in range(n):
		var p := MeshInstance3D.new()
		p.name = "Plank%d" % i
		var pm := BoxMesh.new()
		# Add a tiny gap between planks so the seams read on camera.
		pm.size = Vector3(plank_w * 0.96, face_height * 0.98, plank_thickness)
		p.mesh = pm
		p.material_override = (mat_a if i % 2 == 0 else mat_b)
		var x := -face_width * 0.5 + plank_w * (i + 0.5)
		p.position = Vector3(x, 0, 0)
		face.add_child(p)


func _add_vertical_strip(pos: Vector3, height: float,
		mat: StandardMaterial3D) -> void:
	var s := MeshInstance3D.new()
	s.name = "VerticalStrip"
	var bm := BoxMesh.new()
	bm.size = Vector3(corner_strip_width, height, corner_strip_thickness)
	s.mesh = bm
	s.material_override = mat
	s.position = pos
	add_child(s)


func _add_horizontal_strip_x(pos: Vector3, width: float,
		mat: StandardMaterial3D) -> void:
	var s := MeshInstance3D.new()
	s.name = "HorizontalStripX"
	var bm := BoxMesh.new()
	bm.size = Vector3(width, corner_strip_width, corner_strip_thickness)
	s.mesh = bm
	s.material_override = mat
	s.position = pos
	add_child(s)


func _add_horizontal_strip_z(pos: Vector3, depth: float,
		mat: StandardMaterial3D) -> void:
	var s := MeshInstance3D.new()
	s.name = "HorizontalStripZ"
	var bm := BoxMesh.new()
	bm.size = Vector3(corner_strip_thickness, corner_strip_width, depth)
	s.mesh = bm
	s.material_override = mat
	s.position = pos
	add_child(s)
