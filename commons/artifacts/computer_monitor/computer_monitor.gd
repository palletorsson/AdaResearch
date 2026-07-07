extends Node3D
class_name ComputerMonitor

# @identity
# essence: a chunky beige CRT computer monitor on a flat tilt-swivel base — Half-Life break-room / late-80s office vocabulary. A deep-tubed plastic casing the colour of old cigarette-stained cream, a recessed dark glass screen framed by a moulded bezel, a single power LED, and a couple of soft control buttons. The defining feature is its DEPTH: the tube housing tapers back behind the front face like a fat wedge. In the lab's grammar, the monitor is the DEAD INTERFACE — the screen that may or may not be holding a signal.
# desire: every CRT wants to be either a black mirror or a glowing window, and the threshold between those two states is the whole drama of the object. Off, it is a slab of dark glass that reflects the room and asks nothing. Powered, it leaks a soft phosphor glow and insists there is a process running, a cursor blinking, someone logged in. The monitor wants to be READ as one or the other — never neutral.
# critical_parameter: screen_emission — 0 = DEAD MACHINE, the dark glass, an unplugged or sleeping terminal, the room before the experiment. >0 = POWERED, an interface present, a process running, the lab attended. body_depth is the secondary axis: a deep tube reads RETRO / HEAVY / period-correct CRT; a shallow body drifts toward flat-panel modernity and breaks the era.
# triggers: _ready() builds stand base + neck + rear tube housing + front casing + bezel + screen + power LED + buttons from exports; apply_grid_config rebuilds when DNA changes.
# emerges: a single dark monitor in a corner reads ABANDONED / BETWEEN-SHIFTS. A glowing one reads OCCUPIED / LIVE TERMINAL. A row of them, some lit some dark, reads CONTROL ROOM — partial attention, a system half-watched. The monitor is a status indicator at furniture scale: its glass tells you whether anyone is home.
# needs: flat rounded stand base [present]; short pivot neck [present]; deep tapering rear tube housing [present]; beige front casing [present]; recessed dark screen with bezel frame [present]; power LED [present]; small control buttons [present]
# relationships: peer to oscilloscope (both are SCREEN-FACED CRT vocabulary, but the scope DISPLAYS a known waveform while the monitor's content is withheld — its glass is a question, the scope's a statement); sibling to control_board (both are the room's terminals, the monitor is the single eye); cousin to crate (both confess the lab ARRIVED as equipment, hauled in and plugged into a wall).
# truth: a CRT monitor is the architectural form of MAYBE-SOMEONE-IS-WATCHING. The dark glass is not empty — it is withholding. By making the screen emissive or not, the lab declares whether its interface is alive. A dead monitor says the experiment is paused or unplugged; a glowing one says a process is running whether or not you can see it. The depth of the tube is the room's memory of a heavier era, when a screen had a body.

## A retro beige CRT computer monitor on a tilt-swivel stand.
##
## Built procedurally from DNA exports. Origin is at the BOTTOM CENTER of
## the stand base, resting on a desk or floor (Y up). The screen faces +Z.
## Default casing is a chunky ~0.40m beige box with a deep tube housing
## tapering back along -Z, giving the classic heavy-CRT silhouette.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var body_width: float = 0.40
@export var body_height: float = 0.36
@export var body_depth: float = 0.42

@export_group("Color")
## Beige plastic — old cream casing colour.
@export var body_color: Color = Color(0.80, 0.78, 0.72)
## Bezel frame around the screen — slightly darker beige.
@export var bezel_color: Color = Color(0.74, 0.72, 0.66)
## Dark glass when unpowered.
@export var screen_color: Color = Color(0.05, 0.06, 0.07)
## 0 = dead/off machine (dark glass); >0 = powered, an interface present.
@export_range(0.0, 3.0, 0.05) var screen_emission: float = 0.0
## Soft phosphor glow colour when powered.
@export var screen_tint: Color = Color(0.4, 0.9, 0.7)

@export_group("Hardware")
## Show the flat rounded tilt-swivel base + pivot neck.
@export var show_stand: bool = true
## Show the tiny power LED on the lower bezel.
@export var show_power_led: bool = true
## Power LED colour (green / amber).
@export var led_color: Color = Color(0.2, 0.9, 0.3)

# ── Constants ─────────────────────────────────────────────────────────

const STAND_RADIUS: float = 0.18
const STAND_HEIGHT: float = 0.035
const NECK_RADIUS: float = 0.05
const NECK_HEIGHT: float = 0.045
const BEZEL_DEPTH: float = 0.012
const BEZEL_FRAME_WIDTH: float = 0.035
const SCREEN_INSET: float = 0.018
const SCREEN_WIDTH_FACTOR: float = 0.74
const SCREEN_HEIGHT_FACTOR: float = 0.66
const TUBE_TAPER: float = 0.70                # rear housing vs front size
const LED_SIZE: float = 0.012
const BUTTON_WIDTH: float = 0.028
const BUTTON_HEIGHT: float = 0.012
const BUTTON_DEPTH: float = 0.010

# ── State ─────────────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

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
	if has_meta("config_body_width"):
		body_width = float(str(get_meta("config_body_width")))
	if has_meta("config_body_height"):
		body_height = float(str(get_meta("config_body_height")))
	if has_meta("config_body_depth"):
		body_depth = float(str(get_meta("config_body_depth")))
	if has_meta("config_body_color"):
		body_color = _parse_color(str(get_meta("config_body_color")), body_color)
	if has_meta("config_bezel_color"):
		bezel_color = _parse_color(str(get_meta("config_bezel_color")), bezel_color)
	if has_meta("config_screen_color"):
		screen_color = _parse_color(str(get_meta("config_screen_color")), screen_color)
	if has_meta("config_screen_emission"):
		screen_emission = float(str(get_meta("config_screen_emission")))
	if has_meta("config_screen_tint"):
		screen_tint = _parse_color(str(get_meta("config_screen_tint")), screen_tint)
	if has_meta("config_show_stand"):
		var ss: String = str(get_meta("config_show_stand")).to_lower()
		show_stand = ss in ["true", "1", "yes", "on"]
	if has_meta("config_show_power_led"):
		var sp: String = str(get_meta("config_show_power_led")).to_lower()
		show_power_led = sp in ["true", "1", "yes", "on"]
	if has_meta("config_led_color"):
		led_color = _parse_color(str(get_meta("config_led_color")), led_color)


func _parse_color(raw: String, fallback: Color) -> Color:
	var parts := raw.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	return fallback


# ── Build ─────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true

	# Height of the bottom of the casing above the origin. With a stand,
	# the casing sits on top of base + neck; without, it rests on the floor.
	var casing_bottom_y: float = 0.0
	if show_stand:
		casing_bottom_y = STAND_HEIGHT + NECK_HEIGHT
		_build_stand(casing_bottom_y)

	_build_tube_housing(casing_bottom_y)
	_build_front_casing(casing_bottom_y)
	_build_screen(casing_bottom_y)
	if show_power_led:
		_build_power_led(casing_bottom_y)
	_build_buttons(casing_bottom_y)


func _build_stand(casing_bottom_y: float) -> void:
	# Flat wide rounded disc base resting at the origin, slightly darker.
	var base := MeshInstance3D.new()
	base.name = "StandBase"
	var bm := CylinderMesh.new()
	bm.top_radius = STAND_RADIUS * 0.92
	bm.bottom_radius = STAND_RADIUS
	bm.height = STAND_HEIGHT
	bm.radial_segments = 24
	base.mesh = bm
	base.material_override = _make_plastic_mat(body_color.darkened(0.18), 0.7)
	base.position = Vector3(0.0, STAND_HEIGHT * 0.5, 0.0)
	add_child(base)

	# Short pivot neck connecting the base up to the casing.
	var neck := MeshInstance3D.new()
	neck.name = "PivotNeck"
	var nm := CylinderMesh.new()
	nm.top_radius = NECK_RADIUS
	nm.bottom_radius = NECK_RADIUS * 1.15
	nm.height = NECK_HEIGHT
	nm.radial_segments = 16
	neck.mesh = nm
	neck.material_override = _make_plastic_mat(body_color.darkened(0.12), 0.65)
	neck.position = Vector3(0.0, STAND_HEIGHT + NECK_HEIGHT * 0.5, 0.0)
	add_child(neck)


func _build_tube_housing(casing_bottom_y: float) -> void:
	# Deep CRT tube depth BEHIND the front casing, approximated as two
	# stacked shrinking boxes tapering back along -Z. Gives the heavy
	# silhouette its characteristic wedge.
	var front_depth: float = body_depth * 0.40
	var tube_depth: float = body_depth - front_depth
	var cy: float = casing_bottom_y + body_height * 0.5
	var mat := _make_plastic_mat(body_color.darkened(0.04), 0.72)

	# Wider near segment, narrower far segment.
	var near_w: float = body_width * 0.86
	var near_h: float = body_height * 0.86
	var far_w: float = body_width * TUBE_TAPER
	var far_h: float = body_height * TUBE_TAPER

	# Near tube box — directly behind the front casing.
	var near := MeshInstance3D.new()
	near.name = "TubeHousingNear"
	var nbm := BoxMesh.new()
	nbm.size = Vector3(near_w, near_h, tube_depth * 0.55)
	near.mesh = nbm
	near.material_override = mat
	near.position = Vector3(0.0, cy, -front_depth * 0.5 - tube_depth * 0.275)
	add_child(near)

	# Far tube box — the narrow neck of the tube at the very back.
	var far := MeshInstance3D.new()
	far.name = "TubeHousingFar"
	var fbm := BoxMesh.new()
	fbm.size = Vector3(far_w, far_h, tube_depth * 0.50)
	far.mesh = fbm
	far.material_override = mat
	far.position = Vector3(0.0, cy, -front_depth * 0.5 - tube_depth * 0.55 - tube_depth * 0.25)
	add_child(far)


func _build_front_casing(casing_bottom_y: float) -> void:
	# The main beige front box that holds the screen and bezel.
	var front_depth: float = body_depth * 0.40
	var cy: float = casing_bottom_y + body_height * 0.5
	var casing := MeshInstance3D.new()
	casing.name = "FrontCasing"
	var bm := BoxMesh.new()
	bm.size = Vector3(body_width, body_height, front_depth)
	casing.mesh = bm
	casing.material_override = _make_plastic_mat(body_color, 0.7)
	# Front face sits at +Z = front_depth * 0.5.
	casing.position = Vector3(0.0, cy, 0.0)
	add_child(casing)

	# Bezel frame: four thin boxes around the screen opening on the +Z face.
	var front_z: float = front_depth * 0.5
	var screen_w: float = body_width * SCREEN_WIDTH_FACTOR
	var screen_h: float = body_height * SCREEN_HEIGHT_FACTOR
	var bezel_mat := _make_plastic_mat(bezel_color, 0.6)
	var bz: float = front_z + BEZEL_DEPTH * 0.5
	var fw: float = BEZEL_FRAME_WIDTH
	var outer_w: float = screen_w + fw * 2.0
	var outer_h: float = screen_h + fw * 2.0

	# Top + bottom frame bars.
	_add_box("BezelTop", Vector3(outer_w, fw, BEZEL_DEPTH),
		Vector3(0.0, cy + screen_h * 0.5 + fw * 0.5, bz), bezel_mat)
	_add_box("BezelBottom", Vector3(outer_w, fw, BEZEL_DEPTH),
		Vector3(0.0, cy - screen_h * 0.5 - fw * 0.5, bz), bezel_mat)
	# Left + right frame bars.
	_add_box("BezelLeft", Vector3(fw, screen_h, BEZEL_DEPTH),
		Vector3(-screen_w * 0.5 - fw * 0.5, cy, bz), bezel_mat)
	_add_box("BezelRight", Vector3(fw, screen_h, BEZEL_DEPTH),
		Vector3(screen_w * 0.5 + fw * 0.5, cy, bz), bezel_mat)


func _build_screen(casing_bottom_y: float) -> void:
	# Recessed dark glass panel inside the bezel on the +Z face. Sits
	# slightly behind the bezel front so it reads as inset. Emissive when
	# screen_emission > 0 (powered); dark glass when 0 (dead machine).
	var front_depth: float = body_depth * 0.40
	var front_z: float = front_depth * 0.5
	var cy: float = casing_bottom_y + body_height * 0.5
	var screen_w: float = body_width * SCREEN_WIDTH_FACTOR
	var screen_h: float = body_height * SCREEN_HEIGHT_FACTOR

	var screen := MeshInstance3D.new()
	screen.name = "Screen"
	var bm := BoxMesh.new()
	bm.size = Vector3(screen_w, screen_h, 0.010)
	screen.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = screen_color
	mat.roughness = 0.22
	mat.metallic = 0.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	if screen_emission > 0.0:
		mat.emission_enabled = true
		mat.emission = screen_tint
		mat.emission_energy = screen_emission
	screen.material_override = mat
	# The front casing is a SOLID box whose +Z face is at front_z, so the
	# screen must sit JUST IN FRONT of that face or the beige face occludes
	# it. Place the dark glass slightly proud of the casing but still behind
	# the bezel lip (front_z + BEZEL_DEPTH) so it reads as recessed glass.
	screen.position = Vector3(0.0, cy, front_z + 0.003)
	add_child(screen)


func _build_power_led(casing_bottom_y: float) -> void:
	# Tiny emissive box on the lower bezel, lower-right.
	var front_depth: float = body_depth * 0.40
	var front_z: float = front_depth * 0.5
	var cy: float = casing_bottom_y + body_height * 0.5
	var screen_h: float = body_height * SCREEN_HEIGHT_FACTOR

	var led := MeshInstance3D.new()
	led.name = "PowerLED"
	var bm := BoxMesh.new()
	bm.size = Vector3(LED_SIZE, LED_SIZE * 0.7, LED_SIZE * 0.5)
	led.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = led_color
	mat.emission_enabled = true
	mat.emission = led_color
	mat.emission_energy = 2.2
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	led.material_override = mat
	led.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var led_y: float = cy - screen_h * 0.5 - BEZEL_FRAME_WIDTH * 0.5
	led.position = Vector3(body_width * 0.32, led_y, front_z + BEZEL_DEPTH + LED_SIZE * 0.25)
	add_child(led)


func _build_buttons(casing_bottom_y: float) -> void:
	# A couple of small control buttons on the lower bezel, lower-left.
	var front_depth: float = body_depth * 0.40
	var front_z: float = front_depth * 0.5
	var cy: float = casing_bottom_y + body_height * 0.5
	var screen_h: float = body_height * SCREEN_HEIGHT_FACTOR
	var btn_mat := _make_plastic_mat(body_color.darkened(0.10), 0.55)
	var btn_y: float = cy - screen_h * 0.5 - BEZEL_FRAME_WIDTH * 0.5
	var bz: float = front_z + BEZEL_DEPTH + BUTTON_DEPTH * 0.5

	for i in range(2):
		var x: float = -body_width * 0.30 + float(i) * (BUTTON_WIDTH + 0.012)
		_add_box("Button_%d" % i,
			Vector3(BUTTON_WIDTH, BUTTON_HEIGHT, BUTTON_DEPTH),
			Vector3(x, btn_y, bz), btn_mat)


# ── Helpers ───────────────────────────────────────────────────────────

func _make_plastic_mat(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.0
	return m


func _add_box(box_name: String, size: Vector3, pos: Vector3,
		mat: StandardMaterial3D) -> void:
	var mi := MeshInstance3D.new()
	mi.name = box_name
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
