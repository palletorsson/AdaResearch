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

# ── Stage-2 DNA: support ──────────────────────────────────────────────
#
# `support` is the project's one word for "what apparatus holds this object up",
# reused VERBATIM here from science_screen / info_board / the fire pieces. The
# canonical vocabulary is eight lowercase nouns:
#
#   none | bracket | stand | cradle | frame | gantry | cabinet | pylon
#
# What never varies about this sign is that it is UNATTACHED. Colour and text are
# already the room's business and already differ per map; what all 40 placements
# share is a glowing rectangle hovering 2 cm off a wall with no fixing of any kind,
# which is why it reads as a decal rather than as building fabric. That is exactly
# the shared `support` question, so it is asked with the shared word.
#
# FOUR of the eight are declared, and they are the four a 0.45 m body can build
# without one degrading into a twin of its neighbour:
#
#   none     the emissive box alone — the pre-promotion look, zero nodes added
#   bracket  a small back plate on the wall plane with two arms out to the sign
#   frame    a dark bezel around all four edges, sign recessed into it, back panel
#   gantry   two rods up from the top edge to a plate overhead — the sign HANGS
#
# stand / cradle / cabinet / pylon are deliberately NOT declared and NOT silently
# degraded. They are architecture — a floor member, a base, a body of cabinetwork,
# a slab of building — and a sign this small cannot make an honest claim to any of
# them. See `refusal` in the promotion record.
@export_group("Support")
## What apparatus holds this sign up. `none` is the shipped look exactly (zero
## extra nodes); the other three add real, differently-shaped hardware. Worth
## varying because the sign's one constant flaw across 40 rooms is that nothing
## holds it and nothing says where the wall is.
@export_enum("none", "bracket", "frame", "gantry") var support: String = "none"

## Allow-list for the axis. Anything outside it is a typo and falls back.
const SUPPORTS: PackedStringArray = ["none", "bracket", "frame", "gantry"]

# Hardware proportions, all in metres. Named constants so a reader can check them
# against the spec without counting literals inside the build.
const BRACKET_PLATE: Vector3 = Vector3(0.14, 0.20, 0.006)  ## back plate on the wall plane
const BRACKET_ARM: float = 0.02                            ## square section of each arm
const BRACKET_ARM_Y: float = 0.055                         ## arms sit above/below centre
const FRAME_SECTION: float = 0.025                         ## bezel bar, face-on width
const FRAME_RECESS: float = 0.01                           ## how far the body sits behind the bezel face
const FRAME_PANEL_D: float = 0.006                         ## back panel thickness
const GANTRY_ROD_D: float = 0.008                          ## rod diameter
const GANTRY_RISE: float = 0.45                            ## rod length above the sign's top edge
const GANTRY_ROD_X: float = 0.10                           ## rods either side of centre
const GANTRY_PLATE: Vector3 = Vector3(0.30, 0.06, 0.02)    ## the plate the load comes from

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false
## Every node THIS script added, so teardown never touches grid-added label
## plates, packaging or tag markers that arrived as siblings.
var _owned: Array[Node3D] = []

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_all()
	_built = true


func apply_grid_config(config_data: Dictionary) -> void:
	# Snapshot every key that changes geometry. curation_station calls this with
	# {"emissive": false} one line after it has un-billboarded and dimmed the
	# labels — an unconditional rebuild there would throw that framing away.
	var before_text: String = text
	var before_arrow: String = arrow_direction
	var before_sign_color: Color = sign_color
	var before_text_color: Color = text_color
	var before_width: float = width
	var before_height: float = height
	var before_thickness: float = thickness
	var before_mount: float = mount_offset_z
	var before_glow: float = glow_energy
	var before_support: String = support

	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()

	if not _built:
		# Nothing exists yet; _ready() will build with the values just resolved.
		return

	if (text == before_text
			and arrow_direction == before_arrow
			and sign_color == before_sign_color
			and text_color == before_text_color
			and is_equal_approx(width, before_width)
			and is_equal_approx(height, before_height)
			and is_equal_approx(thickness, before_thickness)
			and is_equal_approx(mount_offset_z, before_mount)
			and is_equal_approx(glow_energy, before_glow)
			and support == before_support):
		# Nothing that shapes this sign moved. Touch nothing, say nothing.
		return

	_rebuild_now()
	print("[ExitSign] Config applied — support=%s, text=%s, arrow=%s" % [
		support, text, arrow_direction])


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
	if has_meta("config_support"):
		support = _pick_axis(str(get_meta("config_support")), SUPPORTS, support)


## Synchronous teardown + rebuild. remove_child() first so the old nodes leave the
## tree in this frame — a deferred rebuild would let _auto_ground_artifact measure
## an empty AABB and skip grounding the sign entirely.
func _rebuild_now() -> void:
	for c in _owned:
		if is_instance_valid(c):
			if c.get_parent() == self:
				remove_child(c)
			c.queue_free()
	_owned.clear()
	_build_all()


# ── Build ─────────────────────────────────────────────────────────────

func _build_all() -> void:
	_build_support()
	_build_body()
	_build_text()
	_build_arrow()


func _add_owned(n: Node3D) -> void:
	add_child(n)
	_owned.append(n)


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
	_add_owned(body)


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
	_add_owned(quad)


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
	_add_owned(quad)


# ── Support ───────────────────────────────────────────────────────────

## The hardware is deliberately NOT emissive: it is the dull thing that holds the
## bright thing, and the contrast is the whole point of the axis.
func _hardware_material(darker: bool = false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	var base: Color = Color(0.16, 0.17, 0.18) if darker else Color(0.28, 0.29, 0.31)
	mat.albedo_color = base
	mat.metallic = 0.65
	mat.roughness = 0.42
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	return mat


func _box(node_name: String, size: Vector3, pos: Vector3, mat: StandardMaterial3D) -> void:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	_add_owned(mi)


func _build_support() -> void:
	match support:
		"bracket":
			_build_support_bracket()
		"frame":
			_build_support_frame()
		"gantry":
			_build_support_gantry()
		_:
			# "none" — the pre-promotion look. Zero nodes added, so all 40 shipped
			# placements render exactly as they did before this axis existed.
			pass


## Minimal hardware fixing the sign to a vertical surface: a plate flat on the wall
## plane and two arms out to the sign's back face. The sign itself does not move or
## rotate — the bracket declares WHERE THE WALL IS, which is the thing the bare sign
## never said.
func _build_support_bracket() -> void:
	var mat := _hardware_material()
	# Plate: 0.14 x 0.20 x 0.006 m, back surface on the wall plane at z = 0.
	# Taller than the sign (0.20 vs 0.18) so it reads above and below the face.
	_box("BracketPlate",
		BRACKET_PLATE,
		Vector3(0.0, 0.0, BRACKET_PLATE.z * 0.5),
		mat)

	# Two square arms running forward from the plate to the sign's back face at
	# z = mount_offset_z. The gap is small by design — this is a flush fixing, not
	# a projecting signal arm.
	var arm_len: float = maxf(mount_offset_z, BRACKET_PLATE.z)
	var arm_size: Vector3 = Vector3(BRACKET_ARM, BRACKET_ARM, arm_len)
	var arm_y: float = minf(BRACKET_ARM_Y, maxf(height * 0.5 - BRACKET_ARM * 0.5, 0.0))
	for s in [1.0, -1.0]:
		var sy: float = float(s)
		_box("BracketArm%s" % ("Top" if sy > 0.0 else "Bottom"),
			arm_size,
			Vector3(0.0, arm_y * sy, arm_len * 0.5),
			mat)


## An upright structure standing AROUND the face: a dark bezel on all four edges
## with the emissive body recessed into it, closed by a back panel on the wall.
## The sign stops being a floating rectangle and becomes a fitting.
func _build_support_frame() -> void:
	var mat := _hardware_material(true)
	var outer_w: float = width + FRAME_SECTION * 2.0
	var outer_h: float = height + FRAME_SECTION * 2.0

	# Back panel flat on the wall plane — 0.50 x 0.23 x 0.006 m at default size.
	_box("FrameBackPanel",
		Vector3(outer_w, outer_h, FRAME_PANEL_D),
		Vector3(0.0, 0.0, FRAME_PANEL_D * 0.5),
		mat)

	# The bezel face sits FRAME_RECESS proud of the sign's own front face, so the
	# emissive body is recessed 0.01 m into the opening. The bars run back from
	# there to the panel, closing the frame rather than floating in front of it.
	var z_front: float = mount_offset_z + thickness + FRAME_RECESS
	var z_back: float = FRAME_PANEL_D
	var bar_d: float = maxf(z_front - z_back, FRAME_SECTION)
	var bar_z: float = z_back + bar_d * 0.5

	var y_bar: float = (outer_h - FRAME_SECTION) * 0.5
	_box("FrameBarTop", Vector3(outer_w, FRAME_SECTION, bar_d),
		Vector3(0.0, y_bar, bar_z), mat)
	_box("FrameBarBottom", Vector3(outer_w, FRAME_SECTION, bar_d),
		Vector3(0.0, -y_bar, bar_z), mat)

	var x_bar: float = (outer_w - FRAME_SECTION) * 0.5
	_box("FrameBarLeft", Vector3(FRAME_SECTION, height, bar_d),
		Vector3(-x_bar, 0.0, bar_z), mat)
	_box("FrameBarRight", Vector3(FRAME_SECTION, height, bar_d),
		Vector3(x_bar, 0.0, bar_z), mat)


## The load comes from ABOVE. Two slender rods rise from the sign's top edge to a
## plate overhead, and the sign hangs off it instead of resting against anything.
func _build_support_gantry() -> void:
	var mat := _hardware_material()
	var z_mid: float = mount_offset_z + thickness * 0.5
	var y_top: float = height * 0.5
	var rod_x: float = minf(GANTRY_ROD_X, GANTRY_PLATE.x * 0.5 - GANTRY_ROD_D)

	for s in [1.0, -1.0]:
		var sx: float = float(s)
		var rod := MeshInstance3D.new()
		rod.name = "GantryRod%s" % ("Right" if sx > 0.0 else "Left")
		var cyl := CylinderMesh.new()
		cyl.top_radius = GANTRY_ROD_D * 0.5
		cyl.bottom_radius = GANTRY_ROD_D * 0.5
		cyl.height = GANTRY_RISE
		cyl.radial_segments = 10
		rod.mesh = cyl
		rod.material_override = mat
		rod.position = Vector3(rod_x * sx, y_top + GANTRY_RISE * 0.5, z_mid)
		_add_owned(rod)

	# 0.30 x 0.06 x 0.02 m plate sitting on top of the rods — the ceiling fixing.
	_box("GantryPlate",
		GANTRY_PLATE,
		Vector3(0.0, y_top + GANTRY_RISE + GANTRY_PLATE.y * 0.5, z_mid),
		mat)


# ── Helpers ───────────────────────────────────────────────────────────

## Accept an axis value only if it names something we actually build. A typo in a
## map token falls back to the current value — a half-recognised value would strand
## a placement with hardware it never asked for.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


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
