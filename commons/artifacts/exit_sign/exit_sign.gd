extends Node3D
class_name ExitSign

const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: a wall-mounted illuminated EXIT sign — Portal 2 / Half-Life vocabulary. A small emissive rectangle that names a way out and points at it. The cheapest, most legible piece of architectural narrative the room can hold.
# desire: every lab/chamber that has an exit gets a sign that SAYS so — readable from across the room, glowing enough to be a beacon, small enough to be ambient
# critical_parameter: sign_color — green = safe egress (the standard), red = warning/alarm exit, accent-color tint = "this exit belongs to THIS phase". The text stays white.
# triggers: _ready() builds the body, text, and arrow from exports; rebuilds on apply_grid_config
# emerges: same script, four signs — green "EXIT →", red "EMERGENCY ↓", phase-tinted "λ-S LAB ←", contextual "RETURN ↑"
# needs: emissive material with high glow_energy [present]; baked text quads painted onto the sign face [present]; arrow glyph baked as unshaded quad [present]
# relationships: sibling to lab_room (a chamber with no exit sign is a sealed room — the sign is the seal's release valve); peer to sliding_door (the sign names the door); descendant of the Half-Life test-chamber visual vocabulary the lab_room inherits from
# truth: a sign is not the way out. The sign is the PROMISE that there IS a way out. A room without an exit sign is a trap. A room with one is a stage.

## A wall-mounted illuminated EXIT sign with optional directional arrow.
##
## Built procedurally from DNA exports — no .tres dependencies. The sign
## faces +Z by default (mount on a -Z wall and the player will see it
## as they look into the room). Re-orient the parent transform to mount
## on other walls.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Text")
@export var text: String = "EXIT"
## "left", "right", "down", "up", "none". Default "none" — just the word EXIT.
@export var arrow_direction: String = "none"

@export_group("Color")
## Default emerald green — the international emergency-egress standard.
@export var sign_color: Color = Color(0.20, 0.80, 0.30)
@export var text_color: Color = Color(1.0, 1.0, 1.0)

@export_group("Dimensions")
@export var width: float = 0.45
@export var height: float = 0.18
## Sign body depth — how thick the box is (a solid sign, not a sticker).
@export var thickness: float = 0.06
## How far the sign protrudes from the wall it mounts to.
@export var mount_offset_z: float = 0.02

@export_group("Emission")
@export var glow_energy: float = 1.5

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_sign()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_sign()


func _read_metadata_overrides() -> void:
	if has_meta("config_text"):
		text = str(get_meta("config_text"))
	if has_meta("config_arrow_direction"):
		arrow_direction = str(get_meta("config_arrow_direction"))
	if has_meta("config_sign_color"):
		sign_color = _parse_color(str(get_meta("config_sign_color")), sign_color)
	if has_meta("config_text_color"):
		text_color = _parse_color(str(get_meta("config_text_color")), text_color)
	if has_meta("config_width"):
		width = float(str(get_meta("config_width")))
	if has_meta("config_height"):
		height = float(str(get_meta("config_height")))
	if has_meta("config_thickness"):
		thickness = float(str(get_meta("config_thickness")))
	if has_meta("config_mount_offset_z"):
		mount_offset_z = float(str(get_meta("config_mount_offset_z")))
	if has_meta("config_glow_energy"):
		glow_energy = float(str(get_meta("config_glow_energy")))


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_sign() -> void:
	_built = true
	_build_body()
	_build_text()
	_build_arrow()


func _build_body() -> void:
	# The body is a thin emissive box, offset from the wall by mount_offset_z.
	# Centered at local origin in X/Y; pushed forward in +Z by half its
	# thickness + mount_offset_z so the back surface sits at the local plane.
	var body := MeshInstance3D.new()
	body.name = "Body"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width, height, thickness)
	body.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = sign_color
	mat.emission_enabled = true
	mat.emission = sign_color
	mat.emission_energy_multiplier = glow_energy
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mat.roughness = 0.3
	mat.metallic = 0.0
	body.material_override = mat
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	body.position = Vector3(0.0, 0.0, mount_offset_z + thickness * 0.5)
	add_child(body)


func _build_text() -> void:
	# Baked text quad painted on the front face of the sign body.
	# Emissive/glowing sign — unshaded=true so the text reads as self-lit.
	if text.is_empty():
		return

	# Horizontal space: narrower when arrow shares the sign, full width otherwise.
	var dir := arrow_direction.to_lower()
	var arrow_width := height * 0.45
	var text_w: float
	var text_x_offset := 0.0
	if dir == "right" or dir == "left":
		# Arrow occupies ~arrow_width on one side; text takes the rest with a small gap.
		text_w = width - arrow_width - 0.01
		text_x_offset = (-arrow_width * 0.5) if dir == "right" else (arrow_width * 0.5)
	else:
		text_w = width - 0.02

	var text_h := height * 0.55
	var quad := BakedText.make_label_mesh(text, text_color, Vector2(text_w, text_h), 1400, true)
	if quad == null:
		return
	quad.name = "Text"
	# Push slightly forward of the body face.
	var z_face := mount_offset_z + thickness + 0.003
	quad.position = Vector3(text_x_offset, 0.0, z_face)
	add_child(quad)


func _build_arrow() -> void:
	var dir := arrow_direction.to_lower()
	if dir == "none":
		return

	# Arrow is a baked unicode glyph quad — unshaded so it glows with the sign.
	var glyph: String
	match dir:
		"left":  glyph = "←"
		"right": glyph = "→"
		"up":    glyph = "↑"
		"down":  glyph = "↓"
		_:       glyph = "→"

	var arrow_size := height * 0.65
	var quad := BakedText.make_label_mesh(glyph, text_color, Vector2(arrow_size, arrow_size), 1400, true)
	if quad == null:
		return
	quad.name = "Arrow"

	# Place arrow on the side opposite the text shift.
	var arrow_x_offset := 0.0
	if dir == "right":
		arrow_x_offset = width * 0.32
	elif dir == "left":
		arrow_x_offset = -width * 0.32

	var z_face := mount_offset_z + thickness + 0.003
	quad.position = Vector3(arrow_x_offset, 0.0, z_face)
	add_child(quad)


# ── Helpers ───────────────────────────────────────────────────────────

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
