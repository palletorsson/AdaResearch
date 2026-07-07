extends Node3D
class_name DigitalDisplayArray

# @identity
# essence: an overhead signage structure — futuristic roadside / transit vocabulary. Two variants share one DNA: a "gantry" portal slung between two lattice steel towers on concrete footings, and a single "pole" mounted at the roadside. Across the front face, saturated-red panels carry crossed white Xs and a dark center panel announces "DISPOSE" beside a white arrow. The array does not decorate the floor; it hangs OVER the path and tells the body where to go.
# desire: every space that wants to be READ as a route — a highway, a checkpoint, a recycling bay — needs a thing that floats above the walking plane and speaks in symbols before words. The display array wants to be SEEN OVERHEAD, an instruction you obey before you read. Red for "no", an arrow for "this way", "DISPOSE" for "leave it here". It is signage as architecture: the rule made structural.
# critical_parameter: mount + display_text/panel_color — mount="gantry" is a PORTAL you pass under (two towers, a header, three panels, speakers, a banner); mount="pole" is a single roadside marker you pass beside. Same red, same arrow, two utterly different rooms — one a checkpoint you transit, one a wayfinding post you glance at. display_text and panel_color decide WHAT the array announces and how loudly.
# triggers: _ready() builds footings + lattice towers + header + three display panels + speakers + banner (gantry) OR base + pole + main panel + side panel + sensor box (pole) from exports; apply_grid_config rebuilds when DNA changes.
# emerges: a red X overhead reads as PROHIBITION — this lane closed, this act forbidden. An arrow reads as DIRECTION — the body is being routed. "DISPOSE" reads as a COMMAND addressed to whatever you carry. A gantry reads as INFRASTRUCTURE, permanent and civic; a pole reads as LOCAL, a single instruction at a single spot. Together they encode a space that has been ORGANISED — someone decided where things go and built a structure to say so.
# needs: concrete footings on the floor [gantry]; two lattice steel towers with cross-braces [gantry]; a tilted header spanning the towers [gantry]; three display panels — red Xs + a DISPOSE arrow panel [gantry]; side speakers [gantry, optional]; a red banner strip [gantry, optional]; a base + vertical pole [pole]; a red arrow panel + a perpendicular side panel [pole]; a sensor/speaker box with lenses [pole]
# relationships: peer to exit_sign (both = wall/overhead wayfinding, one for escape one for routing); sibling to traffic_signal vocabulary (both = overhead instruction in saturated color); cousin to recycling_bin (the DISPOSE panel names what the bin receives); structural cousin to the crate (both confess the space is a NODE IN A NETWORK — the crate that goods arrive, the array that movement is governed).
# truth: an overhead sign is the architectural form of a RULE addressed to a moving body. By raising it on towers or a pole, the space confesses that it is not neutral ground but a managed route — someone owns the flow, names the forbidden, points the way, and tells you where to leave what you carry. The red is not decorative — red is the colour of "before you act, look up".

## A futuristic overhead digital display array.
##
## Built procedurally from DNA exports. Origin is at the BOTTOM CENTRE of
## the structure, sitting on the floor. The display reads from / faces +Z.
## The `mount` DNA selects between two silhouettes: a "gantry" portal on
## two lattice towers, or a single roadside "pole".

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Mount")
## "gantry" = portal on two lattice towers (default). "pole" = single roadside pole.
@export var mount: String = "gantry"

@export_group("Dimensions")
## Horizontal distance between the two gantry towers (centre to centre).
@export var span: float = 2.6
## Height of the gantry towers (footing top to header).
@export var tower_height: float = 2.1

@export_group("Color")
## Saturated alarm-red for the warning panels.
@export var panel_color: Color = Color(0.86, 0.16, 0.16)
## White accent — Xs, arrows, the DISPOSE text.
@export var accent_color: Color = Color(0.95, 0.95, 0.95)
## Dark steel for the frame, towers, header and dark panels.
@export var frame_color: Color = Color(0.16, 0.17, 0.19)

@export_group("Markings")
## The command announced on the centre / main panel.
@export var display_text: String = "DISPOSE"

@export_group("Hardware")
## Show the side speaker boxes near the tower tops (gantry only).
@export var show_speakers: bool = true
## Show the red banner strip below the header (gantry only).
@export var show_banner: bool = true

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
	if has_meta("config_mount"):
		mount = str(get_meta("config_mount"))
	if has_meta("config_span"):
		span = float(str(get_meta("config_span")))
	if has_meta("config_tower_height"):
		tower_height = float(str(get_meta("config_tower_height")))
	if has_meta("config_panel_color"):
		panel_color = _parse_color(str(get_meta("config_panel_color")), panel_color)
	if has_meta("config_accent_color"):
		accent_color = _parse_color(str(get_meta("config_accent_color")), accent_color)
	if has_meta("config_frame_color"):
		frame_color = _parse_color(str(get_meta("config_frame_color")), frame_color)
	if has_meta("config_display_text"):
		display_text = str(get_meta("config_display_text"))
	if has_meta("config_show_speakers"):
		var ss: String = str(get_meta("config_show_speakers")).to_lower()
		show_speakers = ss in ["true", "1", "yes", "on"]
	if has_meta("config_show_banner"):
		var sb: String = str(get_meta("config_show_banner")).to_lower()
		show_banner = sb in ["true", "1", "yes", "on"]


func _parse_color(raw: String, fallback: Color) -> Color:
	var parts := raw.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	return fallback


# ── Build ─────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true
	if mount.to_lower() == "pole":
		_build_pole()
	else:
		_build_gantry()


# ── Shared material helpers ───────────────────────────────────────────

func _make_frame_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = frame_color
	m.roughness = 0.5
	m.metallic = 0.65
	return m


func _make_panel_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = panel_color
	m.roughness = 0.45
	m.metallic = 0.1
	return m


func _make_accent_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = accent_color
	m.roughness = 0.4
	m.metallic = 0.1
	return m


func _make_dark_panel_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.09, 0.10, 0.12)
	m.roughness = 0.5
	m.metallic = 0.2
	return m


func _make_concrete_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.66, 0.66, 0.64)
	m.roughness = 0.9
	m.metallic = 0.0
	return m


func _add_box(parent: Node3D, node_name: String, size: Vector3,
		pos: Vector3, rot: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi


func _add_cylinder(parent: Node3D, node_name: String, radius: float,
		height: float, pos: Vector3, rot: Vector3,
		mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = height
	mi.mesh = cm
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi


# Build a white "X" (two crossed thin boxes) on the front face of a panel.
# Local frame: panel front is at local +Z; x_extent/y_extent are half-spans.
func _add_x_mark(parent: Node3D, node_name: String, x_extent: float,
		y_extent: float, z_front: float, mat: StandardMaterial3D) -> void:
	var diag := sqrt(x_extent * x_extent + y_extent * y_extent) * 2.0 * 0.92
	var ang := atan2(y_extent, x_extent)
	var bar := 0.035
	var thick := 0.02
	var a := _add_box(parent, node_name + "_A",
		Vector3(diag, bar, thick),
		Vector3(0, 0, z_front),
		Vector3(0, 0, ang), mat)
	a.name = node_name + "_A"
	var b := _add_box(parent, node_name + "_B",
		Vector3(diag, bar, thick),
		Vector3(0, 0, z_front),
		Vector3(0, 0, -ang), mat)
	b.name = node_name + "_B"


# Build a white arrow (shaft + two angled head boxes) pointing down/right,
# on the front face of a panel. Local +Z is forward.
func _add_arrow(parent: Node3D, node_name: String, scale_w: float,
		z_front: float, mat: StandardMaterial3D) -> void:
	var root := Node3D.new()
	root.name = node_name
	root.position = Vector3(0, 0, z_front)
	parent.add_child(root)

	var bar := 0.03
	var thick := 0.02
	# Shaft: a horizontal box pointing toward +X (right).
	_add_box(root, "Shaft",
		Vector3(scale_w, bar, thick),
		Vector3(0, 0, 0),
		Vector3(0, 0, 0), mat)
	# Arrowhead: two short angled boxes at the +X tip.
	var head_len := scale_w * 0.42
	var tip := scale_w * 0.5
	_add_box(root, "HeadUpper",
		Vector3(head_len, bar, thick),
		Vector3(tip - head_len * 0.35, head_len * 0.28, 0),
		Vector3(0, 0, deg_to_rad(135.0)), mat)
	_add_box(root, "HeadLower",
		Vector3(head_len, bar, thick),
		Vector3(tip - head_len * 0.35, -head_len * 0.28, 0),
		Vector3(0, 0, deg_to_rad(-135.0)), mat)


# Build a single dark speaker box with two round cones facing +Z.
func _add_speaker(parent: Node3D, node_name: String, pos: Vector3,
		frame_mat: StandardMaterial3D, dark_mat: StandardMaterial3D) -> void:
	var box_w := 0.18
	var box_h := 0.32
	var box_d := 0.12
	var box := _add_box(parent, node_name,
		Vector3(box_w, box_h, box_d), pos, Vector3.ZERO, frame_mat)
	var cone_r := 0.05
	var cone_h := 0.03
	var zf := box_d * 0.5 + cone_h * 0.5
	# Cones: short cylinders with axis along +Z (rotate 90° about X).
	_add_cylinder(box, node_name + "_ConeTop", cone_r, cone_h,
		Vector3(0, box_h * 0.22, zf), Vector3(deg_to_rad(90.0), 0, 0), dark_mat)
	_add_cylinder(box, node_name + "_ConeBot", cone_r, cone_h,
		Vector3(0, -box_h * 0.22, zf), Vector3(deg_to_rad(90.0), 0, 0), dark_mat)


# ── Gantry variant ────────────────────────────────────────────────────

func _build_gantry() -> void:
	var frame_mat := _make_frame_mat()
	var panel_mat := _make_panel_mat()
	var accent_mat := _make_accent_mat()
	var dark_mat := _make_dark_panel_mat()
	var concrete_mat := _make_concrete_mat()

	var half := span * 0.5

	# ── 1. Concrete footings ─────────────────────────────────────────
	var foot_w := 0.45
	var foot_h := 0.6
	var foot_d := 0.45
	for sx in [-1.0, 1.0]:
		_add_box(self, "Footing_%s" % ("R" if sx > 0 else "L"),
			Vector3(foot_w, foot_h, foot_d),
			Vector3(half * sx, foot_h * 0.5, 0),
			Vector3.ZERO, concrete_mat)

	# ── 2. Lattice towers ────────────────────────────────────────────
	for sx in [-1.0, 1.0]:
		_build_lattice_tower("Tower_%s" % ("R" if sx > 0 else "L"),
			Vector3(half * sx, foot_h, 0), foot_h, frame_mat)

	# Y of the header centre (top of towers).
	var header_y := foot_h + tower_height

	# ── 3. Header beam ───────────────────────────────────────────────
	var header_w := span + 0.6
	var header_h := 0.7
	var header_d := 0.4
	var header_tilt := deg_to_rad(14.0)   # top toward +Z
	var header := _add_box(self, "Header",
		Vector3(header_w, header_h, header_d),
		Vector3(0, header_y, 0),
		Vector3(header_tilt, 0, 0), frame_mat)

	# ── 4. Three display panels across the header front ──────────────
	# Panels are children of the header so they share its forward tilt.
	var panel_w := 0.8
	var panel_h := 0.55
	var panel_t := 0.06
	# Front face of header in header-local space: +Z half-depth.
	var panel_z := header_d * 0.5 + panel_t * 0.5
	var gap := 0.06
	var step := panel_w + gap
	var positions := [-step, 0.0, step]

	# Left panel — red with white X.
	var left_panel := _add_box(header, "PanelLeft",
		Vector3(panel_w, panel_h, panel_t),
		Vector3(positions[0], 0, panel_z),
		Vector3.ZERO, panel_mat)
	_add_x_mark(left_panel, "XLeft", panel_w * 0.5, panel_h * 0.5,
		panel_t * 0.5 + 0.012, accent_mat)

	# Centre panel — dark with DISPOSE + arrow.
	var centre_panel := _add_box(header, "PanelCentre",
		Vector3(panel_w, panel_h, panel_t),
		Vector3(positions[1], 0, panel_z),
		Vector3.ZERO, dark_mat)
	_add_dispose_label(centre_panel, panel_h, panel_t * 0.5 + 0.014, accent_mat)
	# Small white arrow below the text.
	var arrow_root := Node3D.new()
	arrow_root.name = "ArrowHolder"
	arrow_root.position = Vector3(0, -panel_h * 0.24, 0)
	centre_panel.add_child(arrow_root)
	_add_arrow(arrow_root, "DisposeArrow", panel_w * 0.42,
		panel_t * 0.5 + 0.012, accent_mat)

	# Right panel — red with white X.
	var right_panel := _add_box(header, "PanelRight",
		Vector3(panel_w, panel_h, panel_t),
		Vector3(positions[2], 0, panel_z),
		Vector3.ZERO, panel_mat)
	_add_x_mark(right_panel, "XRight", panel_w * 0.5, panel_h * 0.5,
		panel_t * 0.5 + 0.012, accent_mat)

	# ── 5. Side speakers ─────────────────────────────────────────────
	if show_speakers:
		var spk_y := foot_h + tower_height - 0.45
		# Inner side of each tower, facing +Z.
		_add_speaker(self, "SpeakerL",
			Vector3(-half + 0.18, spk_y, 0.16), frame_mat, dark_mat)
		_add_speaker(self, "SpeakerR",
			Vector3(half - 0.18, spk_y, 0.16), frame_mat, dark_mat)

	# ── 6. Banner strip below the header ─────────────────────────────
	if show_banner:
		var banner_y := header_y - header_h * 0.5 - 0.45
		_add_box(self, "Banner",
			Vector3(span, 0.3, 0.05),
			Vector3(0, banner_y, 0.22),
			Vector3.ZERO, panel_mat)


# A square lattice tower: 4 corner posts + several X cross-braces up the Z faces.
func _build_lattice_tower(node_name: String, base_pos: Vector3,
		base_y: float, mat: StandardMaterial3D) -> void:
	var tower := Node3D.new()
	tower.name = node_name
	tower.position = base_pos
	add_child(tower)

	var sq := 0.22                 # tower cross-section side
	var post_t := 0.05             # corner post thickness
	var hs := sq * 0.5
	var h := tower_height
	# 4 vertical corner posts.
	var corners := [
		Vector3(hs, 0, hs), Vector3(-hs, 0, hs),
		Vector3(hs, 0, -hs), Vector3(-hs, 0, -hs)
	]
	var ci := 0
	for c in corners:
		_add_box(tower, "Post%d" % ci,
			Vector3(post_t, h, post_t),
			Vector3(c.x, h * 0.5, c.z),
			Vector3.ZERO, mat)
		ci += 1

	# X cross-braces on the +Z and -Z faces (the faces seen from the path).
	var brace_count := 4
	var seg := h / float(brace_count)
	var brace_t := 0.03
	var brace_w := 0.04
	var diag := sqrt(sq * sq + seg * seg) * 0.96
	var ang := atan2(seg, sq)
	var b := 0
	for face_z in [hs, -hs]:
		for i in range(brace_count):
			var yc := seg * (i + 0.5)
			_add_box(tower, "Brace%d" % b,
				Vector3(diag, brace_w, brace_t),
				Vector3(0, yc, face_z),
				Vector3(0, 0, ang), mat)
			b += 1
			_add_box(tower, "Brace%d" % b,
				Vector3(diag, brace_w, brace_t),
				Vector3(0, yc, face_z),
				Vector3(0, 0, -ang), mat)
			b += 1


func _add_dispose_label(parent: Node3D, panel_h: float, z_front: float,
		mat: StandardMaterial3D) -> void:
	if display_text.strip_edges().length() == 0:
		return
	var lbl := Label3D.new()
	lbl.name = "DisposeText"
	lbl.text = display_text
	lbl.font_size = 48
	lbl.outline_size = 0
	lbl.pixel_size = 0.0022
	lbl.modulate = accent_color
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.position = Vector3(0, panel_h * 0.22, z_front)
	lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	parent.add_child(lbl)


# ── Pole variant ──────────────────────────────────────────────────────

func _build_pole() -> void:
	var frame_mat := _make_frame_mat()
	var panel_mat := _make_panel_mat()
	var accent_mat := _make_accent_mat()
	var dark_mat := _make_dark_panel_mat()

	var pole_h := 2.0
	var pole_r := 0.04

	# ── 1. Base foot ─────────────────────────────────────────────────
	var foot_r := 0.18
	var foot_h := 0.08
	_add_cylinder(self, "BaseFoot", foot_r, foot_h,
		Vector3(0, foot_h * 0.5, 0), Vector3.ZERO, frame_mat)

	# ── 2. Vertical pole ─────────────────────────────────────────────
	_add_cylinder(self, "Pole", pole_r, pole_h,
		Vector3(0, foot_h + pole_h * 0.5, 0), Vector3.ZERO, frame_mat)

	var top_y := foot_h + pole_h

	# ── 3. Main panel (red + white arrow), facing +Z near the top ────
	var panel_w := 0.55
	var panel_h := 0.42
	var panel_t := 0.05
	var panel_y := top_y - 0.38
	var panel_z := pole_r + panel_t * 0.5
	var main_panel := _add_box(self, "MainPanel",
		Vector3(panel_w, panel_h, panel_t),
		Vector3(0, panel_y, panel_z),
		Vector3.ZERO, panel_mat)
	_add_arrow(main_panel, "MainArrow", panel_w * 0.55,
		panel_t * 0.5 + 0.012, accent_mat)

	# ── 4. Side panel (smaller, dark, facing +X) behind the main ─────
	var side_w := 0.34
	var side_h := 0.3
	var side_t := 0.04
	# Mounted perpendicular: facing +X means its thin axis is along X, so
	# rotate 90° about Y. Place just behind the main panel along -Z.
	_add_box(self, "SidePanel",
		Vector3(side_w, side_h, side_t),
		Vector3(pole_r + side_t * 0.5, panel_y, -0.06),
		Vector3(0, deg_to_rad(90.0), 0), dark_mat)

	# ── 5. Sensor / speaker box at the very top, two lenses facing +Z ─
	var box_w := 0.16
	var box_h := 0.14
	var box_d := 0.12
	var box_y := top_y - 0.05
	var sensor := _add_box(self, "SensorBox",
		Vector3(box_w, box_h, box_d),
		Vector3(0, box_y, pole_r + box_d * 0.5 - 0.02),
		Vector3.ZERO, frame_mat)
	var lens_r := 0.035
	var lens_h := 0.025
	var lens_zf := box_d * 0.5 + lens_h * 0.5
	_add_cylinder(sensor, "LensL", lens_r, lens_h,
		Vector3(-box_w * 0.22, 0, lens_zf),
		Vector3(deg_to_rad(90.0), 0, 0), dark_mat)
	_add_cylinder(sensor, "LensR", lens_r, lens_h,
		Vector3(box_w * 0.22, 0, lens_zf),
		Vector3(deg_to_rad(90.0), 0, 0), dark_mat)
