extends Node3D
class_name LockBox

const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: a small rectangular dark-steel strongbox with a slightly lighter steel lid that pivots open along its back edge, a row of brass combination dials across the front face (each with a red indicator notch rotated to a specific digit 0-9), a dark clasp on the lid front, a Label3D showing the combination as a number, and an accent stripe across the lid's leading edge. In the lab's grammar, the lock_box is the HASH / COMMITMENT / ENCRYPTION OBJECT — a box whose CONTENTS are concealed by its CLOSED STATE, where a specific configuration of dial positions is the KEY that authorises opening, and the configuration itself is publicly visible (a commitment) without revealing what is inside.
# desire: every cryptographic primitive wants to be SEEN as a closed object that COULD be opened. The lock_box wants to be the architectural form of "here is an opaque container; here are the dials whose positions are the key; here is the lid, and you can see whether it is open or closed". It wants the player to read dial_positions as a literal password / hash digest and lid_open_amount as a 0-to-1 reveal slider.
# critical_parameter: dial_positions — together with combination_dial_count, this IS the cryptographic statement of the prop. Each dial has 10 positions (0-9), so combination_dial_count dials encode a number in [0, 10^N): 4 dials = 10000 keys, the textbook combination-lock keyspace. The dial_positions array IS the secret (when closed) or the witness (when revealed). The same box with [0,0,0,0] reads as DEFAULT / UNINITIALISED; with [3,7,1,5] reads as a SPECIFIC COMMITMENT. The dials are public-visible — the BOX is the encrypted message.
# triggers: _ready() builds box body + pivoting lid + dial discs with indicator notches + clasp + combination label + accent stripe from exports; apply_grid_config rebuilds
# emerges: a closed box with random-looking dial positions reads as SEALED COMMITMENT. A box with lid_open_amount=1 reveals a dark interior cavity, reading as REVEAL / DECOMMITMENT. Same DNA, two phases of the same cryptographic protocol — the box LITERALLY enacts cryptographic commit-then-reveal.
# needs: rectangular box body [present]; lid pivoting on back edge by lid_open_amount × 90° [present]; combination_dial_count brass dials with indicator notches [present]; dark clasp on lid front [present]; combination label below dials [present — baked text quad, not Label3D]; accent stripe across lid's leading edge [present]
# relationships: sibling to specimen_jar (both CONTAIN something — jar transparent and observable, lock_box opaque and SEALED); cousin to safe_deposit_box / lockable cabinet vocabulary (the lock_box is the small bench version); peer to oscilloscope (both EMBODY an algorithm in physical form — scope shows Fourier in shape, lock_box shows cryptographic commitment in geometry)
# truth: a hash function maps a large input to a small fixed-size digest, and a commitment scheme lets you commit to a value without revealing it. A combination lock is the everyday version: you commit to a number by setting the dials and closing the lid; the LID's closed state binds your commitment. The lock_box is the lab's physical-form proof that "encryption" is just "a hidden volume behind a publicly-visible key configuration".

## A small combination lockbox with a pivoting lid.
##
## Built procedurally from DNA exports. Origin is at the BOTTOM CENTER
## of the box footprint. Box faces +Z (dials and clasp on +Z face). The
## lid pivots around its back edge (-Z side) by lid_open_amount × 90°.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var box_width: float = 0.20
@export var box_height: float = 0.16
@export var box_depth: float = 0.14

@export_group("Color")
@export var body_color: Color = Color(0.20, 0.20, 0.24)
@export var lid_color: Color = Color(0.28, 0.28, 0.32)
@export var dial_color: Color = Color(0.85, 0.65, 0.20)
@export var dial_indicator_color: Color = Color(0.95, 0.20, 0.20)
@export var clasp_color: Color = Color(0.10, 0.10, 0.12)
@export var accent_color: Color = Color(1.0, 0.45, 0.10)

@export_group("Lock State")
@export_range(0.0, 1.0, 0.01) var lid_open_amount: float = 0.0
@export_range(1, 6) var combination_dial_count: int = 4
@export var dial_positions: PackedInt32Array = PackedInt32Array([3, 7, 1, 5])
@export var clasp_visible: bool = true

# ── Constants ─────────────────────────────────────────────────────────

const BODY_BOTTOM_INSET: float = 0.001
const LID_THICKNESS: float = 0.024
const DIAL_RADIUS: float = 0.022
const DIAL_DEPTH: float = 0.012
const DIAL_ROW_MARGIN: float = 0.012
const CLASP_WIDTH: float = 0.024
const CLASP_HEIGHT: float = 0.022
const CLASP_DEPTH: float = 0.012
const ACCENT_STRIP_HEIGHT: float = 0.006
const INTERIOR_CAVITY_INSET: float = 0.012

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_lock_box()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_lock_box()


func _read_metadata_overrides() -> void:
	if has_meta("config_box_width"):
		box_width = float(str(get_meta("config_box_width")))
	if has_meta("config_box_height"):
		box_height = float(str(get_meta("config_box_height")))
	if has_meta("config_box_depth"):
		box_depth = float(str(get_meta("config_box_depth")))
	if has_meta("config_body_color"):
		body_color = _parse_color(str(get_meta("config_body_color")), body_color)
	if has_meta("config_lid_color"):
		lid_color = _parse_color(str(get_meta("config_lid_color")), lid_color)
	if has_meta("config_dial_color"):
		dial_color = _parse_color(str(get_meta("config_dial_color")), dial_color)
	if has_meta("config_dial_indicator_color"):
		dial_indicator_color = _parse_color(str(get_meta("config_dial_indicator_color")), dial_indicator_color)
	if has_meta("config_clasp_color"):
		clasp_color = _parse_color(str(get_meta("config_clasp_color")), clasp_color)
	if has_meta("config_accent_color"):
		accent_color = _parse_color(str(get_meta("config_accent_color")), accent_color)
	if has_meta("config_lid_open_amount"):
		lid_open_amount = float(str(get_meta("config_lid_open_amount")))
	if has_meta("config_combination_dial_count"):
		combination_dial_count = int(str(get_meta("config_combination_dial_count")))
	if has_meta("config_dial_positions"):
		var raw := str(get_meta("config_dial_positions"))
		dial_positions = _parse_int_array(raw)
	if has_meta("config_clasp_visible"):
		var cv := str(get_meta("config_clasp_visible")).to_lower()
		clasp_visible = cv in ["true", "1", "yes", "on"]


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_lock_box() -> void:
	_built = true
	_build_body()
	_build_interior_cavity()
	_build_lid()
	_build_dials()
	if clasp_visible:
		_build_clasp()
	_build_combination_label()
	_build_accent_strip()


func _build_body() -> void:
	# Box body — sits on the table from y=0. The lid space is RESERVED at the top.
	var body_h: float = max(0.001, box_height - LID_THICKNESS)
	var body := MeshInstance3D.new()
	body.name = "Body"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(box_width, body_h, box_depth)
	body.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	mat.roughness = 0.45
	mat.metallic = 0.6
	body.material_override = mat
	body.position = Vector3(0.0, body_h * 0.5, 0.0)
	add_child(body)


func _build_interior_cavity() -> void:
	# A small dark recess inside the body (visible when lid opens).
	var body_h: float = max(0.001, box_height - LID_THICKNESS)
	var cavity_w: float = max(0.001, box_width - INTERIOR_CAVITY_INSET * 2.0)
	var cavity_h: float = max(0.001, body_h * 0.35)
	var cavity_d: float = max(0.001, box_depth - INTERIOR_CAVITY_INSET * 2.0)
	var cavity := MeshInstance3D.new()
	cavity.name = "Cavity"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(cavity_w, cavity_h, cavity_d)
	cavity.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.04, 0.04, 0.05)
	mat.roughness = 0.9
	mat.metallic = 0.0
	cavity.material_override = mat
	# Sits just below the top surface of the body so it reads as a darker insetted volume.
	cavity.position = Vector3(0.0, body_h - cavity_h * 0.5 - 0.002, 0.0)
	add_child(cavity)


func _build_lid() -> void:
	# Lid pivots around the BACK edge (at z = -box_depth/2). Use a pivot Node3D.
	var body_h: float = max(0.001, box_height - LID_THICKNESS)
	var pivot := Node3D.new()
	pivot.name = "LidPivot"
	# Pivot at top-back edge of body.
	pivot.position = Vector3(0.0, body_h, -box_depth * 0.5)
	# Open by rotating lid backward around X (so lid lifts up and back).
	var open_angle: float = clampf(lid_open_amount, 0.0, 1.0) * (PI * 0.5)
	# Positive rotation about X tilts the lid back/up.
	pivot.rotation = Vector3(-open_angle, 0.0, 0.0)
	add_child(pivot)

	var lid := MeshInstance3D.new()
	lid.name = "Lid"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(box_width, LID_THICKNESS, box_depth)
	lid.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = lid_color
	mat.roughness = 0.4
	mat.metallic = 0.65
	lid.material_override = mat
	# Lid extends from pivot (back edge) FORWARD into +Z by box_depth.
	# Centered: x=0, y=LID_THICKNESS/2 (above pivot), z=box_depth/2 (forward of pivot).
	lid.position = Vector3(0.0, LID_THICKNESS * 0.5, box_depth * 0.5)
	pivot.add_child(lid)


func _build_dials() -> void:
	if combination_dial_count <= 0:
		return
	var root := Node3D.new()
	root.name = "Dials"
	add_child(root)

	var body_h: float = max(0.001, box_height - LID_THICKNESS)
	var dial_y: float = body_h * 0.55
	# Distribute dials horizontally across +Z face.
	var span: float = box_width * 0.78
	var n: int = max(1, combination_dial_count)

	var dial_mat := StandardMaterial3D.new()
	dial_mat.albedo_color = dial_color
	dial_mat.roughness = 0.35
	dial_mat.metallic = 0.85

	var ind_mat := StandardMaterial3D.new()
	ind_mat.albedo_color = dial_indicator_color
	ind_mat.emission_enabled = true
	ind_mat.emission = dial_indicator_color
	ind_mat.emission_energy_multiplier = 1.6
	ind_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

	for i in range(n):
		var t: float = 0.0
		if n > 1:
			t = float(i) / float(n - 1)
		var x: float = (t - 0.5) * span

		# Wrapper node so the indicator can rotate WITH the dial face.
		var dial_root := Node3D.new()
		dial_root.name = "DialRoot_%d" % i
		dial_root.position = Vector3(x, dial_y, box_depth * 0.5 + DIAL_DEPTH * 0.5 - 0.002)
		root.add_child(dial_root)

		var dial := MeshInstance3D.new()
		dial.name = "Dial_%d" % i
		var cm := CylinderMesh.new()
		cm.top_radius = DIAL_RADIUS
		cm.bottom_radius = DIAL_RADIUS * 1.04
		cm.height = DIAL_DEPTH
		dial.mesh = cm
		dial.material_override = dial_mat
		# Lay cylinder along Z (default along Y), so face points +Z.
		dial.rotation = Vector3(PI * 0.5, 0.0, 0.0)
		dial_root.add_child(dial)

		# Indicator notch: a thin BoxMesh strip on the dial face, offset from dial center.
		var digit: int = _digit_at(i)
		# 0..9 maps to 0..324 degrees clockwise from "12" position.
		var angle_deg: float = float(digit) * 36.0
		var angle_rad: float = deg_to_rad(angle_deg)

		# Indicator is positioned in the dial-root's local frame, on a circle of radius DIAL_RADIUS*0.55 around dial center, on the +Z face.
		var ind_offset_radius: float = DIAL_RADIUS * 0.55
		var ind_x: float = sin(angle_rad) * ind_offset_radius
		var ind_y: float = cos(angle_rad) * ind_offset_radius
		var ind := MeshInstance3D.new()
		ind.name = "DialInd_%d" % i
		var ib := BoxMesh.new()
		ib.size = Vector3(0.003, DIAL_RADIUS * 0.55, 0.0020)
		ind.mesh = ib
		ind.material_override = ind_mat
		# Place at the offset, rotate around dial center so the bar POINTS outward.
		ind.position = Vector3(ind_x, ind_y, DIAL_DEPTH * 0.5 + 0.0012)
		ind.rotation = Vector3(0.0, 0.0, -angle_rad)
		dial_root.add_child(ind)


func _build_clasp() -> void:
	# A small dark clasp at the bottom-front of the lid (on the lid's leading edge).
	# It belongs to the lid pivot, so it moves with the lid.
	var lid_pivot: Node3D = get_node_or_null("LidPivot") as Node3D
	if lid_pivot == null:
		return

	var clasp := MeshInstance3D.new()
	clasp.name = "Clasp"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(CLASP_WIDTH, CLASP_HEIGHT, CLASP_DEPTH)
	clasp.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = clasp_color
	mat.roughness = 0.4
	mat.metallic = 0.75
	clasp.material_override = mat
	# Position on the FRONT face of the lid (in lid-local +Z direction), centered horizontally,
	# protruding downward below the lid's bottom face.
	clasp.position = Vector3(0.0, -CLASP_HEIGHT * 0.35, box_depth + CLASP_DEPTH * 0.4)
	lid_pivot.add_child(clasp)


func _build_combination_label() -> void:
	# Baked-text quad showing the combination digits separated by spaces,
	# below the dials on the body face (+Z surface). Replaces the old Label3D.
	var body_h: float = max(0.001, box_height - LID_THICKNESS)
	var text_parts: Array = []
	for i in range(combination_dial_count):
		text_parts.append(str(_digit_at(i)))
	var combo_text: String = " ".join(text_parts)
	# World size: width spans ~75% of box_width, height ~one-digit row.
	var quad_w: float = box_width * 0.75
	var quad_h: float = quad_w * 0.28
	var quad: MeshInstance3D = BakedText.make_label_mesh(
		combo_text, accent_color, Vector2(quad_w, quad_h))
	if quad:
		quad.name = "CombinationLabel"
		# Same position as the old Label3D — slightly proud of the front face.
		quad.position = Vector3(0.0, body_h * 0.18, box_depth * 0.5 + 0.006)
		add_child(quad)


func _build_accent_strip() -> void:
	# Accent stripe along the LEADING edge of the lid (the front face of the lid, at top of body).
	var body_h: float = max(0.001, box_height - LID_THICKNESS)
	var lid_pivot: Node3D = get_node_or_null("LidPivot") as Node3D
	if lid_pivot == null:
		# Fallback: place on body.
		var strip_fb := MeshInstance3D.new()
		strip_fb.name = "AccentStrip"
		var bm_fb := BoxMesh.new()
		bm_fb.size = Vector3(box_width, ACCENT_STRIP_HEIGHT, 0.004)
		strip_fb.mesh = bm_fb
		var mat_fb := StandardMaterial3D.new()
		mat_fb.albedo_color = accent_color
		mat_fb.emission_enabled = true
		mat_fb.emission = accent_color
		mat_fb.emission_energy_multiplier = 1.5
		mat_fb.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		strip_fb.material_override = mat_fb
		strip_fb.position = Vector3(0.0, body_h, box_depth * 0.5 + 0.003)
		add_child(strip_fb)
		return

	var strip := MeshInstance3D.new()
	strip.name = "AccentStrip"
	var bm := BoxMesh.new()
	bm.size = Vector3(box_width, ACCENT_STRIP_HEIGHT, 0.004)
	strip.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent_color
	mat.emission_enabled = true
	mat.emission = accent_color
	mat.emission_energy_multiplier = 1.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	strip.material_override = mat
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Pin to the front edge of the lid, just above its top face.
	strip.position = Vector3(0.0, LID_THICKNESS + ACCENT_STRIP_HEIGHT * 0.5, box_depth - 0.004)
	lid_pivot.add_child(strip)


# ── Helpers ───────────────────────────────────────────────────────────

func _digit_at(i: int) -> int:
	# Pad/truncate dial_positions to combination_dial_count, modulo 10.
	if dial_positions.size() == 0:
		return 0
	if i < dial_positions.size():
		var v: int = dial_positions[i]
		return int(posmod(v, 10))
	# Pad: repeat last entry mod 10.
	var last_idx: int = dial_positions.size() - 1
	var v2: int = dial_positions[last_idx]
	return int(posmod(v2, 10))


func _parse_int_array(s: String) -> PackedInt32Array:
	var out := PackedInt32Array()
	var cleaned: String = s.strip_edges()
	cleaned = cleaned.replace("[", "").replace("]", "")
	var parts := cleaned.split(",")
	for p in parts:
		var ps: String = str(p).strip_edges()
		if ps == "":
			continue
		out.append(int(ps))
	if out.size() == 0:
		return PackedInt32Array([3, 7, 1, 5])
	return out


func _parse_color(s: String, fallback: Color) -> Color:
	var parts := s.split(",")
	if parts.size() < 3:
		return fallback
	var r := float(parts[0])
	var g := float(parts[1])
	var b := float(parts[2])
	var a := 1.0
	if parts.size() >= 4:
		a = float(parts[3])
	return Color(r, g, b, a)
