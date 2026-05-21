extends Node3D
class_name Pendulum

# @identity
# essence: an inverted-U metal stand with a string hanging from the center of its
#   top bar, terminating in a polished brass bob — Aperture / lecture-hall
#   vocabulary. The string is rotated to a frozen swing angle so the bob hangs
#   off-vertical. Optional faint arc-dots trace the swept path. In the lab's
#   grammar, the pendulum IS the HARMONIC OSCILLATOR in object form. Length =
#   period. Angle = phase. Bob = the mass that proves x(t) = A·cos(ωt + φ).
# desire: every lab that teaches oscillation needs a stilled clock — an artifact
#   that holds a single instant of the cosine, the way a photograph holds a
#   single instant of a face. The pendulum wants to be the FROZEN SECOND of the
#   harmonic equation, not the simulation of it
# critical_parameter: string_length + swing_angle_degrees — together they ARE
#   the algorithm's key knob. Length determines ω = √(g/L). Angle determines
#   the realised amplitude. Period and phase, fixed in wood and brass
# triggers: _ready() builds posts + top bar + string (rotated to angle) + bob +
#   optional arc dots + accent stripe; apply_grid_config rebuilds
# emerges: a small angle reads QUIET RESTING. A large angle reads CAUGHT MID-
#   SWING. Arc-dots on reads MOTION TRAIL. arc-dots off reads SINGLE FRAME. Same
#   script, the same equation captured in different moments
# needs: 2 posts + top bar [present]; string from top bar [present]; bob at
#   string end [present]; optional arc dots [present]; accent stripe on top bar
#   [present]
# relationships: peer to probability_box (oscillator = deterministic time; box =
#   stochastic time); sibling to entropy_meter (both measure across cycles —
#   pendulum is mechanical, meter is statistical); cousin to large_table (a
#   pendulum without a frame to mount on is just a falling weight); the lab's
#   sworn statement that NOT EVERYTHING REQUIRES RANDOMNESS
# truth: a harmonic oscillator is the claim that a system displaced from
#   equilibrium will return through a sinusoid whose frequency depends only on
#   the system, not the displacement. The pendulum IS that rule embodied — the
#   length picks the frequency, the angle picks the amplitude, and the bob
#   promises to come back. To still it at a moment is to NAME the equation.

## A bench-top pendulum on an inverted-U stand, frozen at swing_angle_degrees.
##
## Built procedurally from DNA exports. Origin is at the bottom center
## between the two posts. The pendulum swings in the XY plane: the string
## hangs from the top-bar center, rotated by swing_angle_degrees around the
## Z axis. Positive angle leans the bob toward +X.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Stand")
@export var stand_height: float = 0.55
@export var stand_width: float = 0.32
@export var post_thickness: float = 0.020
@export var stand_color: Color = Color(0.22, 0.22, 0.25)

@export_group("String")
@export var string_length: float = 0.40
@export var string_color: Color = Color(0.10, 0.10, 0.12)

@export_group("Bob")
@export var bob_radius: float = 0.035
@export var bob_color: Color = Color(0.85, 0.65, 0.20)
@export var bob_emission: float = 0.0

@export_group("Swing")
@export var swing_angle_degrees: float = 25.0

@export_group("Arc")
@export var arc_visible: bool = false
@export_range(1, 21) var arc_dot_count: int = 7
@export var arc_color: Color = Color(0.55, 0.55, 0.60)

@export_group("Accent")
@export var accent_color: Color = Color(0.95, 0.55, 0.0)

# ── Constants ─────────────────────────────────────────────────────────

const ACCENT_STRIP_HEIGHT: float = 0.004
const ACCENT_STRIP_DEPTH: float = 0.003
const ARC_DOT_RADIUS_FACTOR: float = 0.18  # vs bob_radius

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_pendulum()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_pendulum()


func _read_metadata_overrides() -> void:
	if has_meta("config_stand_height"):
		stand_height = float(String(get_meta("config_stand_height")))
	if has_meta("config_stand_width"):
		stand_width = float(String(get_meta("config_stand_width")))
	if has_meta("config_post_thickness"):
		post_thickness = float(String(get_meta("config_post_thickness")))
	if has_meta("config_stand_color"):
		stand_color = _parse_color(String(get_meta("config_stand_color")), stand_color)
	if has_meta("config_string_length"):
		string_length = float(String(get_meta("config_string_length")))
	if has_meta("config_string_color"):
		string_color = _parse_color(String(get_meta("config_string_color")), string_color)
	if has_meta("config_bob_radius"):
		bob_radius = float(String(get_meta("config_bob_radius")))
	if has_meta("config_bob_color"):
		bob_color = _parse_color(String(get_meta("config_bob_color")), bob_color)
	if has_meta("config_bob_emission"):
		bob_emission = float(String(get_meta("config_bob_emission")))
	if has_meta("config_swing_angle_degrees"):
		swing_angle_degrees = float(String(get_meta("config_swing_angle_degrees")))
	if has_meta("config_arc_visible"):
		arc_visible = _parse_bool(String(get_meta("config_arc_visible")), arc_visible)
	if has_meta("config_arc_dot_count"):
		arc_dot_count = int(String(get_meta("config_arc_dot_count")))
	if has_meta("config_arc_color"):
		arc_color = _parse_color(String(get_meta("config_arc_color")), arc_color)
	if has_meta("config_accent_color"):
		accent_color = _parse_color(String(get_meta("config_accent_color")), accent_color)


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_pendulum() -> void:
	_built = true
	_build_posts()
	_build_top_bar()
	if arc_visible:
		_build_arc_dots()
	_build_string_and_bob()
	_build_accent_stripe()


func _build_posts() -> void:
	var root := Node3D.new()
	root.name = "Posts"
	add_child(root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = stand_color
	mat.roughness = 0.45
	mat.metallic = 0.65

	var half_w: float = stand_width * 0.5
	for sx in [-1, 1]:
		var post := MeshInstance3D.new()
		post.name = "Post_%d" % sx
		var mesh := BoxMesh.new()
		mesh.size = Vector3(post_thickness, stand_height, post_thickness)
		post.mesh = mesh
		post.material_override = mat
		post.position = Vector3(float(sx) * half_w, stand_height * 0.5, 0.0)
		root.add_child(post)


func _build_top_bar() -> void:
	var bar := MeshInstance3D.new()
	bar.name = "TopBar"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(stand_width + post_thickness, post_thickness, post_thickness)
	bar.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = stand_color
	mat.roughness = 0.45
	mat.metallic = 0.65
	bar.material_override = mat
	bar.position = Vector3(0.0, stand_height - post_thickness * 0.5, 0.0)
	add_child(bar)


func _build_string_and_bob() -> void:
	var root := Node3D.new()
	root.name = "Pendulum"
	add_child(root)

	# Pivot point: center of top bar.
	var pivot_y: float = stand_height - post_thickness
	var ang_rad: float = deg_to_rad(swing_angle_degrees)

	# String: a thin cylinder of length=string_length, pivot at the top.
	# Local +Y is "up"; we want the cylinder hanging DOWN from the pivot, so
	# we rotate around Z by (PI + ang) — that flips down then offsets by angle.
	# Easier: build a Node3D pivot at the top bar, rotate it by -ang_rad about Z
	# (positive angle leans the bob toward +X), then place the string CHILD with
	# its top end at the pivot.
	var pivot := Node3D.new()
	pivot.name = "Pivot"
	pivot.position = Vector3(0.0, pivot_y, 0.0)
	pivot.rotation = Vector3(0.0, 0.0, -ang_rad)
	root.add_child(pivot)

	var string := MeshInstance3D.new()
	string.name = "String"
	var sm := CylinderMesh.new()
	var s_r: float = max(0.0008, string_length * 0.005)
	sm.top_radius = s_r
	sm.bottom_radius = s_r
	sm.height = string_length
	string.mesh = sm
	var s_mat := StandardMaterial3D.new()
	s_mat.albedo_color = string_color
	s_mat.roughness = 0.85
	s_mat.metallic = 0.0
	string.material_override = s_mat
	# In the rotated pivot frame, hang along -Y: center at -length/2.
	string.position = Vector3(0.0, -string_length * 0.5, 0.0)
	pivot.add_child(string)

	# Bob at the bottom end of the string.
	var bob := MeshInstance3D.new()
	bob.name = "Bob"
	var bm := SphereMesh.new()
	bm.radius = bob_radius
	bm.height = bob_radius * 2.0
	bob.mesh = bm
	var b_mat := StandardMaterial3D.new()
	b_mat.albedo_color = bob_color
	b_mat.roughness = 0.25
	b_mat.metallic = 0.75
	if bob_emission > 0.0:
		b_mat.emission_enabled = true
		b_mat.emission = bob_color
		b_mat.emission_energy_multiplier = bob_emission
		b_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	bob.material_override = b_mat
	bob.position = Vector3(0.0, -string_length - bob_radius * 0.3, 0.0)
	pivot.add_child(bob)


func _build_arc_dots() -> void:
	var root := Node3D.new()
	root.name = "Arc"
	add_child(root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = arc_color
	mat.roughness = 0.7
	mat.metallic = 0.1
	mat.emission_enabled = true
	mat.emission = arc_color
	mat.emission_energy_multiplier = 0.4
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

	var n: int = clampi(arc_dot_count, 1, 21)
	var pivot_y: float = stand_height - post_thickness
	var radius: float = string_length + bob_radius * 0.3
	var ang_max: float = deg_to_rad(swing_angle_degrees)
	var dot_r: float = bob_radius * ARC_DOT_RADIUS_FACTOR

	for i in range(n):
		var t: float = 0.0
		if n > 1:
			t = float(i) / float(n - 1)
		var ang: float = lerpf(-ang_max, ang_max, t)
		# Pivot rotates around Z by -ang; bob position relative to pivot is (0, -radius, 0)
		# rotated by -ang around Z → (sin(ang)*radius, -cos(ang)*radius, 0).
		var x: float = sin(ang) * radius
		var y: float = pivot_y - cos(ang) * radius
		var dot := MeshInstance3D.new()
		dot.name = "ArcDot_%d" % i
		var sm := SphereMesh.new()
		sm.radius = dot_r
		sm.height = dot_r * 2.0
		dot.mesh = sm
		dot.material_override = mat
		dot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		dot.position = Vector3(x, y, 0.0)
		root.add_child(dot)


func _build_accent_stripe() -> void:
	# Thin emissive stripe along the front face of the top bar.
	var strip := MeshInstance3D.new()
	strip.name = "AccentStripe"
	var mesh := BoxMesh.new()
	mesh.size = Vector3((stand_width + post_thickness) * 0.92, ACCENT_STRIP_HEIGHT, ACCENT_STRIP_DEPTH)
	strip.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent_color
	mat.emission_enabled = true
	mat.emission = accent_color
	mat.emission_energy_multiplier = 1.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	strip.material_override = mat
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	strip.position = Vector3(
		0.0,
		stand_height - post_thickness * 0.5,
		post_thickness * 0.5 + ACCENT_STRIP_DEPTH * 0.5
	)
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


func _parse_bool(s: String, fallback: bool) -> bool:
	var v := s.to_lower()
	if v in ["true", "1", "yes", "on"]:
		return true
	if v in ["false", "0", "no", "off"]:
		return false
	return fallback
