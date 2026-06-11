extends Node3D
class_name SlideProjector

const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: a rectangular dark-steel projector chassis with a translucent lamp-warm glass lens recessed into its front face, an emissive cone of light exiting the lens along +Z, a round slide carousel on top with `slide_count` radial slot strips, and a Label3D on the side reading the current frame number ("FRAME 7"). In the lab's grammar, the slide_projector is the SEQUENTIAL-FRAME / TIME-STEPPING / ANIMATION ENGINE — the textbook device for "the world is a sequence of static images shown one at a time, fast enough to look continuous".
# desire: every iteration / animation algorithm wants to be SEEN as a discrete sequence of frames. The slide_projector wants to be the architectural form of "here is the current frame number, here is the carousel of frames waiting, here is the BEAM that lights one frame at a time, and here is the time-step from one slide to the next". It wants the player to read current_slide_number as the loop variable i, and the carousel as the array being indexed.
# critical_parameter: current_slide_number — together with slide_count, this IS the time-stepping statement of the prop. slide_count is the total number of frames (the array length); current_slide_number is the index i ∈ [0, slide_count). Same projector, different stories: slide 0 = INITIAL STATE, slide_count/2 = MIDPOINT, slide_count-1 = TERMINAL STATE. The projector is the animation loop made physical.
# triggers: _ready() builds chassis + lens + beam + carousel disc + slide-count slot strips + frame label + accent stripe from exports; apply_grid_config rebuilds
# emerges: a projector with beam_visible reads as "the loop is RUNNING — one frame at a time". The carousel with many slots reads as DEEP TIME / many iterations remaining. The Label3D reading "FRAME 7" reads as the loop counter i=7 — the prop ENACTS the for-loop in geometry.
# needs: rectangular chassis [present]; recessed translucent lens [present]; emissive light cone exiting lens [present when beam_visible]; circular slide carousel disc on top [present when slide_carousel_visible]; radial slot strips on carousel [present]; frame-number baked text on front face [present, unshaded]; accent stripe along lens housing [present]
# relationships: sibling to oscilloscope (both VISUALISE the unfolding of a signal — scope shows a whole waveform at once, projector shows ONE FRAME at a time); cousin to wall_clock (both NAME the passage of time — clock is continuous, projector is discrete-stepped); peer to terrarium (both bound a small system — terrarium bounds a population in glass, projector bounds an animation in a carousel)
# truth: animation IS time-stepping: you advance an index, you redraw, you advance again. Numerical integration is animation with physics; iterative algorithms are animation with logic. The slide_projector is the lab's reminder that "for i in range(n)" is the same shape as "the carousel clicks one slot forward and the beam shows the next frame".

## A slide projector — chassis, lens, beam, carousel.
##
## Built procedurally from DNA exports. Origin is at the BOTTOM CENTER
## of the chassis footprint. Faces +Z (beam exits in +Z direction). The
## carousel sits on top of the body when slide_carousel_visible is true.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var body_width: float = 0.30
@export var body_height: float = 0.18
@export var body_depth: float = 0.45
@export var lens_radius: float = 0.040

@export_group("Color")
@export var body_color: Color = Color(0.22, 0.22, 0.25)
@export var lens_color: Color = Color(0.85, 0.92, 0.95, 0.50)
@export var lamp_color: Color = Color(1.0, 0.95, 0.80)
@export var beam_color: Color = Color(1.0, 0.95, 0.80)
@export var accent_color: Color = Color(1.0, 0.45, 0.10)

@export_group("Light")
@export var lamp_on: bool = true
@export_range(0.0, 4.0, 0.05) var lamp_glow: float = 1.4
@export var beam_visible: bool = true
@export_range(0.05, 2.0, 0.01) var beam_length: float = 0.60

@export_group("Carousel")
@export var slide_carousel_visible: bool = true
@export_range(0.02, 0.30, 0.005) var carousel_radius: float = 0.10
@export_range(1, 80) var slide_count: int = 40
@export var current_slide_number: int = 7

# ── Constants ─────────────────────────────────────────────────────────

const LENS_DEPTH: float = 0.020
const LENS_INSET: float = 0.010
const BEAM_TOP_RADIUS_FACTOR: float = 2.5    # cone widens to this factor of lens_radius
const CAROUSEL_DISC_HEIGHT: float = 0.014
const SLOT_LENGTH: float = 0.020
const SLOT_WIDTH: float = 0.0030
const SLOT_HEIGHT: float = 0.004
const ACCENT_STRIP_HEIGHT: float = 0.006

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_projector()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_projector()


func _read_metadata_overrides() -> void:
	if has_meta("config_body_width"):
		body_width = float(str(get_meta("config_body_width")))
	if has_meta("config_body_height"):
		body_height = float(str(get_meta("config_body_height")))
	if has_meta("config_body_depth"):
		body_depth = float(str(get_meta("config_body_depth")))
	if has_meta("config_lens_radius"):
		lens_radius = float(str(get_meta("config_lens_radius")))
	if has_meta("config_body_color"):
		body_color = _parse_color(str(get_meta("config_body_color")), body_color)
	if has_meta("config_lens_color"):
		lens_color = _parse_color(str(get_meta("config_lens_color")), lens_color)
	if has_meta("config_lamp_color"):
		lamp_color = _parse_color(str(get_meta("config_lamp_color")), lamp_color)
	if has_meta("config_beam_color"):
		beam_color = _parse_color(str(get_meta("config_beam_color")), beam_color)
	if has_meta("config_accent_color"):
		accent_color = _parse_color(str(get_meta("config_accent_color")), accent_color)
	if has_meta("config_lamp_on"):
		var lv := str(get_meta("config_lamp_on")).to_lower()
		lamp_on = lv in ["true", "1", "yes", "on"]
	if has_meta("config_lamp_glow"):
		lamp_glow = float(str(get_meta("config_lamp_glow")))
	if has_meta("config_beam_visible"):
		var bv := str(get_meta("config_beam_visible")).to_lower()
		beam_visible = bv in ["true", "1", "yes", "on"]
	if has_meta("config_beam_length"):
		beam_length = float(str(get_meta("config_beam_length")))
	if has_meta("config_slide_carousel_visible"):
		var scv := str(get_meta("config_slide_carousel_visible")).to_lower()
		slide_carousel_visible = scv in ["true", "1", "yes", "on"]
	if has_meta("config_carousel_radius"):
		carousel_radius = float(str(get_meta("config_carousel_radius")))
	if has_meta("config_slide_count"):
		slide_count = int(str(get_meta("config_slide_count")))
	if has_meta("config_current_slide_number"):
		current_slide_number = int(str(get_meta("config_current_slide_number")))


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_projector() -> void:
	_built = true
	_build_chassis()
	_build_lens()
	if beam_visible:
		_build_beam()
	if slide_carousel_visible:
		_build_carousel()
	_build_frame_label()
	_build_accent_strip()


func _build_chassis() -> void:
	var chassis := MeshInstance3D.new()
	chassis.name = "Chassis"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(body_width, body_height, body_depth)
	chassis.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	mat.roughness = 0.55
	mat.metallic = 0.45
	chassis.material_override = mat
	chassis.position = Vector3(0.0, body_height * 0.5, 0.0)
	add_child(chassis)


func _build_lens() -> void:
	# Translucent lens disc on +Z face, axis along +Z.
	var lens := MeshInstance3D.new()
	lens.name = "Lens"
	var mesh := CylinderMesh.new()
	mesh.top_radius = lens_radius
	mesh.bottom_radius = lens_radius
	mesh.height = LENS_DEPTH
	lens.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = lens_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.1
	mat.metallic = 0.05
	mat.emission_enabled = true
	if lamp_on:
		mat.emission = Color(lamp_color.r, lamp_color.g, lamp_color.b)
		mat.emission_energy_multiplier = lamp_glow
	else:
		mat.emission = Color(lens_color.r, lens_color.g, lens_color.b)
		mat.emission_energy_multiplier = 0.05
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	lens.material_override = mat
	lens.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Cylinder default axis is Y; lay it along Z by rotating about X.
	lens.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	# Slightly inset into the front face.
	lens.position = Vector3(0.0, body_height * 0.5, body_depth * 0.5 + LENS_DEPTH * 0.5 - LENS_INSET)
	add_child(lens)


func _build_beam() -> void:
	# Emissive cone (CylinderMesh with top_radius > lens_radius) extending +Z from the lens.
	var beam := MeshInstance3D.new()
	beam.name = "Beam"
	var mesh := CylinderMesh.new()
	# Top is the "far" end of the cone after rotation. The cone WIDENS as it exits the lens.
	mesh.top_radius = lens_radius * BEAM_TOP_RADIUS_FACTOR
	mesh.bottom_radius = lens_radius
	mesh.height = beam_length
	beam.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(beam_color.r, beam_color.g, beam_color.b, 0.45)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.9
	mat.metallic = 0.0
	mat.emission_enabled = true
	mat.emission = beam_color
	mat.emission_energy_multiplier = lamp_glow * 1.2 if lamp_on else 0.4
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	beam.material_override = mat
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Rotate so cone axis aligns with +Z, then position with bottom face flush at lens front.
	# After rotation about X by +90°, the "top" of the cylinder (positive local Y) points to +Z.
	beam.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	var lens_front_z: float = body_depth * 0.5 + LENS_DEPTH - LENS_INSET
	beam.position = Vector3(0.0, body_height * 0.5, lens_front_z + beam_length * 0.5)
	add_child(beam)


func _build_carousel() -> void:
	var root := Node3D.new()
	root.name = "Carousel"
	add_child(root)

	var disc := MeshInstance3D.new()
	disc.name = "CarouselDisc"
	var dm := CylinderMesh.new()
	dm.top_radius = carousel_radius
	dm.bottom_radius = carousel_radius
	dm.height = CAROUSEL_DISC_HEIGHT
	disc.mesh = dm
	var disc_mat := StandardMaterial3D.new()
	disc_mat.albedo_color = Color(body_color.r * 0.85, body_color.g * 0.85, body_color.b * 0.88)
	disc_mat.roughness = 0.45
	disc_mat.metallic = 0.55
	disc.material_override = disc_mat
	disc.position = Vector3(0.0, body_height + CAROUSEL_DISC_HEIGHT * 0.5, 0.0)
	root.add_child(disc)

	# Radial slot strips arranged in a ring at carousel_radius from center.
	var n: int = max(1, slide_count)
	var slot_mat := StandardMaterial3D.new()
	slot_mat.albedo_color = Color(0.10, 0.10, 0.12)
	slot_mat.roughness = 0.7
	slot_mat.metallic = 0.2

	var ring_radius: float = carousel_radius * 0.78
	for i in range(n):
		var angle: float = TAU * float(i) / float(n)
		var x: float = sin(angle) * ring_radius
		var z: float = cos(angle) * ring_radius
		var slot := MeshInstance3D.new()
		slot.name = "Slot_%d" % i
		var bm := BoxMesh.new()
		bm.size = Vector3(SLOT_WIDTH, SLOT_HEIGHT, SLOT_LENGTH)
		slot.mesh = bm
		slot.material_override = slot_mat
		slot.position = Vector3(x, body_height + CAROUSEL_DISC_HEIGHT + SLOT_HEIGHT * 0.5, z)
		slot.rotation = Vector3(0.0, -angle, 0.0)
		root.add_child(slot)


func _build_frame_label() -> void:
	# Baked text quad on the +Z front face of the chassis showing the current frame number.
	# Replaces the old Label3D. unshaded=true because the readout sits next to the emissive
	# accent strip and should glow with the same lamp-warm feel.
	var text := "FRAME %d" % current_slide_number
	# world_size: roughly the footprint the Label3D occupied (~80% of body_width × a thin strip)
	var quad: MeshInstance3D = BakedText.make_label_mesh(
			text, accent_color,
			Vector2(body_width * 0.80, body_height * 0.14),
			1400, true)
	if quad:
		quad.name = "FrameLabel"
		# Position proud of the +Z face, same height as the old Label3D.
		quad.position = Vector3(body_width * 0.30, body_height * 0.78, body_depth * 0.5 + 0.006)
		add_child(quad)


func _build_accent_strip() -> void:
	# Accent stripe along the lens housing (a band around the +Z face below the lens).
	var strip := MeshInstance3D.new()
	strip.name = "AccentStrip"
	var bm := BoxMesh.new()
	bm.size = Vector3(body_width, ACCENT_STRIP_HEIGHT, 0.004)
	strip.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent_color
	mat.emission_enabled = true
	mat.emission = accent_color
	mat.emission_energy_multiplier = 1.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	strip.material_override = mat
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Just under the lens, on the front face.
	var strip_y: float = max(ACCENT_STRIP_HEIGHT, body_height * 0.5 - lens_radius - 0.012)
	strip.position = Vector3(0.0, strip_y, body_depth * 0.5 + 0.003)
	add_child(strip)


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
