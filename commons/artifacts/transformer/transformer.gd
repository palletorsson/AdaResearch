extends Node3D
class_name Transformer

# @identity
# essence: a pad-mounted electrical transformer cabinet — a squat galvanized-steel box sitting on its own poured concrete pad, an overhanging weatherproof "hat" lid with a dark parting seam, two recessed front doors that meet at a center latch, a vertical handle bar and lock, a louvered side vent breathing heat, and — by default — a yellow electrical-hazard triangle, the warning sign that is itself a triangle (a rectangular DANGER plaque is the alternate). The transformer is the neighborhood's hidden organ: it does not generate, it CONVERTS — stepping the grid's brutal high voltage down to the gentle current a house can drink. The box is the city's confession that power is not native to the home; it is piped in, transformed, distributed.
# desire: every street pretends electricity is ambient, free, weightless — it comes from the wall. The transformer breaks that pretence. It wants to be the THRESHOLD between two voltages, the place where the dangerous becomes domestic. Squat and locked and humming, it asks not to be opened. Its yellow plaque is not decoration; it is the box saying "the danger here is named, and it is enough to kill you".
# critical_parameter: cabinet_width / cabinet_height / cabinet_depth + door_count — a WIDE SQUAT body with TWO doors reads as a pad-mounted DISTRIBUTION transformer (the neighborhood workhorse, fed underground). A TALL NARROW body with ONE door reads as a CONTROL / FEEDER cabinet (switching, not stepping). top_cap toggles the weatherproof hat — present = OUTDOOR pad-mount in the rain; absent = INDOOR panel in a plant room.
# triggers: _ready() builds pad + body + top cap + seam + front doors + handle/lock + side vent + hazard plaque from exports; apply_grid_config rebuilds when DNA changes.
# emerges: a single locked box on a concrete pad reads as INFRASTRUCTURE-AT-REST — the grid is present but mute, working without witness. The yellow plaque + louvered vent read as LIVE AND DANGEROUS — heat is being shed, voltage is being held. Together they encode the city's quiet machinery: the boxes between the power plant and the lamp, the organs no one is meant to open.
# needs: concrete pad slab under the cabinet [present]; tall galvanized-steel body [present]; overhanging weatherproof top cap with parting seam [present]; one or two recessed front doors [present]; vertical handle bar + lock latch [present]; louvered side vent panel [present]; yellow hazard triangle (electrical sign, default) or rectangular DANGER plaque [present]
# relationships: peer to fire_extinguisher (both = NAMED DANGER made architectural, one for fire one for voltage); cousin to crate (both = sealed boxes with unseen contents, but the crate says "open me once unpacked" and the transformer says "do NOT open, ever"); structural sibling to ceiling_vent (both = utility-not-instrument, the lab's and the street's plumbing for power and air); placed in the triangle lab, its hazard sign doubles as the theme's own form — Δ as danger, the cost of difference made into a warning, beside the chalkboard that asks "what is the cost of Δ?".
# truth: a transformer is the architectural form of CONVERSION — the moment the grid's violence is made livable. By placing it, the street confesses that power has a supply chain, that the current in the wall was once lethal, that someone poured a pad and bolted a box so the danger could be held at arm's length. Every locked cabinet on a concrete slab is a small monument to the threshold between the dangerous and the domestic.

## A pad-mounted electrical transformer cabinet.
##
## Built procedurally from DNA exports. Origin is at the BOTTOM CENTRE of
## the cabinet body, resting on a concrete pad on the floor (Y up). The
## front doors face +Z. Default dimensions are a wide squat 2-door
## pad-mounted distribution transformer.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var cabinet_width: float = 1.1
@export var cabinet_height: float = 1.5
@export var cabinet_depth: float = 0.42

@export_group("Structure")
## Overhanging weatherproof "hat" lid on top (outdoor pad-mount look).
@export var top_cap: bool = true
## Number of recessed front doors (1 = control/feeder, 2 = distribution).
@export var door_count: int = 2
## Show the louvered side vent panel.
@export var vent_visible: bool = true
## Show the poured concrete pad slab under the cabinet.
@export var show_pad: bool = true

@export_group("Material")
## Galvanized bluish-gray steel body.
@export var body_color: Color = Color(0.62, 0.64, 0.66)
## Light-gray rough concrete pad.
@export var pad_color: Color = Color(0.7, 0.7, 0.68)

@export_group("Hazard")
## "triangle" = the electrical-hazard sign (yellow triangle, black border,
## lightning bolt). "plaque" = a rectangular DANGER sign with text.
@export var hazard_shape: String = "triangle"
## Short, all-caps reads best on the rectangular plaque.
@export var hazard_label: String = "DANGER"

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
	if has_meta("config_cabinet_width"):
		cabinet_width = float(str(get_meta("config_cabinet_width")))
	if has_meta("config_cabinet_height"):
		cabinet_height = float(str(get_meta("config_cabinet_height")))
	if has_meta("config_cabinet_depth"):
		cabinet_depth = float(str(get_meta("config_cabinet_depth")))
	if has_meta("config_top_cap"):
		top_cap = str(get_meta("config_top_cap")).to_lower() in ["true", "1", "yes", "on"]
	if has_meta("config_door_count"):
		door_count = int(str(get_meta("config_door_count")))
	if has_meta("config_vent_visible"):
		vent_visible = str(get_meta("config_vent_visible")).to_lower() in ["true", "1", "yes", "on"]
	if has_meta("config_show_pad"):
		show_pad = str(get_meta("config_show_pad")).to_lower() in ["true", "1", "yes", "on"]
	if has_meta("config_body_color"):
		body_color = _parse_color(str(get_meta("config_body_color")), body_color)
	if has_meta("config_pad_color"):
		pad_color = _parse_color(str(get_meta("config_pad_color")), pad_color)
	if has_meta("config_hazard_shape"):
		hazard_shape = str(get_meta("config_hazard_shape")).to_lower().strip_edges()
	if has_meta("config_hazard_label"):
		hazard_label = str(get_meta("config_hazard_label"))


func _parse_color(raw: String, fallback: Color) -> Color:
	var parts := raw.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	return fallback


# ── Build ─────────────────────────────────────────────────────────────

const PAD_HEIGHT: float = 0.12
const CAP_HEIGHT: float = 0.22
const CAP_OVERHANG: float = 0.06
const SEAM_THICKNESS: float = 0.02
const DOOR_INSET: float = 0.012      # how far the door panel sits proud of the body
const FRAME_WIDTH: float = 0.05      # raised perimeter frame width


func _build() -> void:
	_built = true

	if show_pad:
		_build_pad()
	_build_body()
	if top_cap:
		_build_top_cap()
	_build_doors()
	if vent_visible:
		_build_vent()
	_build_hazard_plaque()


func _make_steel_mat(c: Color, rough: float = 0.6, metal: float = 0.4) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _build_pad() -> void:
	# A flat concrete slab slightly larger than the cabinet footprint,
	# extending forward in +Z so the doors have a step to open over.
	var pad := MeshInstance3D.new()
	pad.name = "ConcretePad"
	var pm := BoxMesh.new()
	var pad_w: float = cabinet_width + 0.3
	var pad_d: float = cabinet_depth + 0.5
	pm.size = Vector3(pad_w, PAD_HEIGHT, pad_d)
	pad.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = pad_color
	mat.roughness = 0.95
	mat.metallic = 0.0
	pad.material_override = mat
	# The pad extends forward, so its center shifts +Z relative to the
	# cabinet (which sits centered-back on the pad). The cabinet back is at
	# -cabinet_depth/2; the pad back aligns there, the rest grows in +Z.
	var pad_z: float = (pad_d - cabinet_depth) * 0.5
	pad.position = Vector3(0.0, PAD_HEIGHT * 0.5, pad_z)
	add_child(pad)


func _build_body() -> void:
	var body := MeshInstance3D.new()
	body.name = "MainBody"
	var bm := BoxMesh.new()
	bm.size = Vector3(cabinet_width, cabinet_height, cabinet_depth)
	body.mesh = bm
	body.material_override = _make_steel_mat(body_color, 0.6, 0.4)
	# Bottom of body rests on top of the pad (or floor if no pad).
	var base_y: float = PAD_HEIGHT if show_pad else 0.0
	body.position = Vector3(0.0, base_y + cabinet_height * 0.5, 0.0)
	add_child(body)


func _build_top_cap() -> void:
	var base_y: float = PAD_HEIGHT if show_pad else 0.0
	var body_top: float = base_y + cabinet_height

	# A thin dark parting seam recess just below the cap.
	var seam := MeshInstance3D.new()
	seam.name = "PartingSeam"
	var seamm := BoxMesh.new()
	seamm.size = Vector3(cabinet_width * 1.002, SEAM_THICKNESS, cabinet_depth * 1.002)
	seam.mesh = seamm
	var seam_mat := StandardMaterial3D.new()
	seam_mat.albedo_color = Color(0.12, 0.12, 0.13)
	seam_mat.roughness = 0.8
	seam_mat.metallic = 0.2
	seam.material_override = seam_mat
	seam.position = Vector3(0.0, body_top - SEAM_THICKNESS * 0.5, 0.0)
	add_child(seam)

	# The overhanging weatherproof lid.
	var cap := MeshInstance3D.new()
	cap.name = "TopCap"
	var cm := BoxMesh.new()
	cm.size = Vector3(cabinet_width + CAP_OVERHANG * 2.0, CAP_HEIGHT,
		cabinet_depth + CAP_OVERHANG * 2.0)
	cap.mesh = cm
	# Slightly darker, more weathered than the body.
	cap.material_override = _make_steel_mat(body_color * 0.9, 0.65, 0.4)
	cap.position = Vector3(0.0, body_top + CAP_HEIGHT * 0.5, 0.0)
	add_child(cap)


func _build_doors() -> void:
	var base_y: float = PAD_HEIGHT if show_pad else 0.0
	var front_z: float = cabinet_depth * 0.5

	# Doors occupy most of the front face, leaving a margin top/bottom/sides.
	var margin: float = 0.06
	var doors_area_w: float = cabinet_width - margin * 2.0
	var door_h: float = cabinet_height - margin * 2.0
	var door_cy: float = base_y + cabinet_height * 0.5      # vertical center of doors

	var n: int = clampi(door_count, 1, 2)
	var door_w: float = doors_area_w / float(n)

	var panel_mat := _make_steel_mat(body_color * 1.04, 0.55, 0.45)
	var frame_mat := _make_steel_mat(body_color * 0.92, 0.6, 0.45)

	for i in range(n):
		var door_root := Node3D.new()
		door_root.name = "Door%d" % i
		# Center X of this door within the doors area.
		var cx: float = -doors_area_w * 0.5 + door_w * (i + 0.5)
		door_root.position = Vector3(cx, door_cy, front_z)
		add_child(door_root)

		# Raised flat panel.
		var panel := MeshInstance3D.new()
		panel.name = "Panel"
		var pmesh := BoxMesh.new()
		pmesh.size = Vector3(door_w * 0.94, door_h, DOOR_INSET)
		panel.mesh = pmesh
		panel.material_override = panel_mat
		panel.position = Vector3(0.0, 0.0, DOOR_INSET * 0.5)
		door_root.add_child(panel)

		# Raised perimeter frame: four thin bars around the panel edge.
		var inner_w: float = door_w * 0.94
		var frame_z: float = DOOR_INSET + 0.006
		# Top & bottom bars (run along X).
		for sy in [1.0, -1.0]:
			var bar := MeshInstance3D.new()
			bar.name = "FrameH"
			var bmesh := BoxMesh.new()
			bmesh.size = Vector3(inner_w, FRAME_WIDTH, 0.012)
			bar.mesh = bmesh
			bar.material_override = frame_mat
			bar.position = Vector3(0.0, sy * (door_h * 0.5 - FRAME_WIDTH * 0.5), frame_z * 0.5)
			door_root.add_child(bar)
		# Left & right bars (run along Y).
		for sx in [1.0, -1.0]:
			var bar2 := MeshInstance3D.new()
			bar2.name = "FrameV"
			var b2mesh := BoxMesh.new()
			b2mesh.size = Vector3(FRAME_WIDTH, door_h, 0.012)
			bar2.mesh = b2mesh
			bar2.material_override = frame_mat
			bar2.position = Vector3(sx * (inner_w * 0.5 - FRAME_WIDTH * 0.5), 0.0, frame_z * 0.5)
			door_root.add_child(bar2)

	# Hardware sits at the meeting point of the doors (center for double,
	# right edge of single).
	_build_hardware(base_y, front_z, door_cy, door_h, n, doors_area_w, door_w)


func _build_hardware(base_y: float, front_z: float, door_cy: float,
		door_h: float, n: int, doors_area_w: float, door_w: float) -> void:
	# X position of the handle: at the center seam for 2 doors, near the
	# right edge of the single door otherwise.
	var handle_x: float
	if n == 2:
		handle_x = 0.0
	else:
		handle_x = doors_area_w * 0.5 - door_w * 0.12

	var hw_mat := StandardMaterial3D.new()
	hw_mat.albedo_color = Color(0.16, 0.16, 0.18)
	hw_mat.roughness = 0.45
	hw_mat.metallic = 0.7

	var hw_z: float = front_z + DOOR_INSET + 0.02

	# Vertical handle bar (a thin tall box).
	var handle := MeshInstance3D.new()
	handle.name = "HandleBar"
	var hm := BoxMesh.new()
	hm.size = Vector3(0.035, door_h * 0.55, 0.035)
	handle.mesh = hm
	handle.material_override = hw_mat
	handle.position = Vector3(handle_x, door_cy, hw_z)
	add_child(handle)

	# Small lock / latch box near the middle of the handle.
	var lock := MeshInstance3D.new()
	lock.name = "LockLatch"
	var lm := BoxMesh.new()
	lm.size = Vector3(0.08, 0.10, 0.05)
	lock.mesh = lm
	var lock_mat := StandardMaterial3D.new()
	lock_mat.albedo_color = Color(0.10, 0.10, 0.11)
	lock_mat.roughness = 0.5
	lock_mat.metallic = 0.6
	lock.material_override = lock_mat
	lock.position = Vector3(handle_x, door_cy - door_h * 0.05, hw_z - 0.004)
	add_child(lock)


func _build_vent() -> void:
	# A louvered panel low on the +X side face: 4-5 thin horizontal slats,
	# recessed slightly, in darker metal.
	var base_y: float = PAD_HEIGHT if show_pad else 0.0
	var side_x: float = cabinet_width * 0.5

	var vent_root := Node3D.new()
	vent_root.name = "SideVent"
	# Low on the side face, toward the front.
	vent_root.position = Vector3(side_x, base_y + cabinet_height * 0.28, cabinet_depth * 0.12)
	# Face +X: rotate so local +Z points along world +X.
	vent_root.rotation = Vector3(0.0, deg_to_rad(90.0), 0.0)
	add_child(vent_root)

	var slat_mat := StandardMaterial3D.new()
	slat_mat.albedo_color = Color(0.28, 0.30, 0.32)
	slat_mat.roughness = 0.7
	slat_mat.metallic = 0.5

	var slat_count: int = 5
	var panel_w: float = cabinet_depth * 0.45
	var panel_h: float = cabinet_height * 0.22
	var slat_h: float = panel_h / float(slat_count) * 0.6
	var spacing: float = panel_h / float(slat_count)

	for i in range(slat_count):
		var slat := MeshInstance3D.new()
		slat.name = "Slat%d" % i
		var sm := BoxMesh.new()
		# Thin box; depth (local Z) is small so it sits just proud of face.
		sm.size = Vector3(panel_w, slat_h, 0.01)
		slat.mesh = sm
		slat.material_override = slat_mat
		var y: float = -panel_h * 0.5 + spacing * (i + 0.5)
		# Tilt each slat slightly like a real louver.
		slat.rotation = Vector3(deg_to_rad(-20.0), 0.0, 0.0)
		slat.position = Vector3(0.0, y, 0.006)
		vent_root.add_child(slat)


func _build_hazard_plaque() -> void:
	var base_y: float = PAD_HEIGHT if show_pad else 0.0
	var front_z: float = cabinet_depth * 0.5
	var hx: float = -cabinet_width * 0.26
	var hz: float = front_z + DOOR_INSET + 0.012

	if hazard_shape == "triangle":
		# The electrical-hazard sign: yellow triangle, black border, lightning bolt.
		# A triangle warning the danger inside — and, in the triangle lab, the
		# theme's own form turned into a sign: Δ as danger, the cost of difference.
		var r: float = cabinet_width * 0.16
		var hy: float = base_y + cabinet_height * 0.72
		var border := MeshInstance3D.new()
		border.name = "HazardBorder"
		border.mesh = _flat_tri(r * 1.16)
		border.material_override = _flat_mat(Color(0.06, 0.06, 0.06))
		border.position = Vector3(hx, hy, hz)
		add_child(border)
		var tri := MeshInstance3D.new()
		tri.name = "HazardTriangle"
		tri.mesh = _flat_tri(r)
		tri.material_override = _flat_mat(Color(0.95, 0.82, 0.05))
		tri.position = Vector3(hx, hy, hz + 0.003)
		add_child(tri)
		var bm := _bolt_mesh(r * 0.82)
		if bm != null:
			var bolt := MeshInstance3D.new()
			bolt.name = "HazardBolt"
			bolt.mesh = bm
			bolt.material_override = _flat_mat(Color(0.08, 0.07, 0.05))
			bolt.position = Vector3(hx, hy - r * 0.10, hz + 0.006)
			add_child(bolt)
		return

	# Rectangular DANGER plaque (alt look).
	var plaque := MeshInstance3D.new()
	plaque.name = "HazardPlaque"
	var pm := BoxMesh.new()
	pm.size = Vector3(cabinet_width * 0.22, cabinet_height * 0.10, 0.012)
	plaque.mesh = pm
	plaque.material_override = _flat_mat(Color(0.95, 0.82, 0.05))
	var plaque_y: float = base_y + cabinet_height * 0.78
	plaque.position = Vector3(hx, plaque_y, hz)
	add_child(plaque)
	if hazard_label.strip_edges().length() > 0:
		var lbl := Label3D.new()
		lbl.name = "HazardText"
		lbl.text = hazard_label
		lbl.font_size = 40
		lbl.outline_size = 0
		lbl.pixel_size = 0.0016
		lbl.modulate = Color(0.08, 0.07, 0.05)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		lbl.position = Vector3(hx, plaque_y, hz + 0.008)
		add_child(lbl)


# ── Hazard-sign mesh helpers ──────────────────────────────────────────────

func _flat_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


## A flat, point-up equilateral triangle in the XY plane (radius r to the apex).
func _flat_tri(r: float) -> ArrayMesh:
	var verts := PackedVector3Array([
		Vector3(0.0, r, 0.0),
		Vector3(-r * 0.866, -r * 0.5, 0.0),
		Vector3(r * 0.866, -r * 0.5, 0.0),
	])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2])
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m


## A flat lightning-bolt polygon, triangulated. Returns null if degenerate.
func _bolt_mesh(s: float) -> ArrayMesh:
	var p2 := PackedVector2Array([
		Vector2(0.12, 0.50), Vector2(-0.20, 0.05), Vector2(-0.02, 0.05),
		Vector2(-0.12, -0.50), Vector2(0.20, -0.05), Vector2(0.02, -0.05),
	])
	for i in p2.size():
		p2[i] = p2[i] * s
	var idx := Geometry2D.triangulate_polygon(p2)
	if idx.is_empty():
		return null
	var verts := PackedVector3Array()
	for v in p2:
		verts.append(Vector3(v.x, v.y, 0.0))
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m
