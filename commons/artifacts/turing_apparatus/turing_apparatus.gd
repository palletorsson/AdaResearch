extends Node3D
class_name TuringApparatus

# @identity
# essence: the Turing machine laid out as physical lab apparatus. Conveyor belt
#   in the middle = the tape. Robot arm above it = the read/write head.
#   Server rack to the left = the program (state-transition table). Electrical
#   panel to the right = the state register (which symbol is "current"). Info
#   screen on the back wall = the live state output. Emergency button on a
#   podium at the back = the HALT control. Exit sign above the entrance =
#   terminate. Walking the room IS executing the machine.
# desire: every spine sequence wants a chamber that IS the algorithm. The
#   Turing apparatus is the proof-of-concept: a room you walk through to
#   understand Turing's model without ever opening a paper.
# critical_parameter: belt_arrow_count (the tape's read direction count) +
#   panel_breakers_on_count (the current state encoded in bits) + button_pressed
#   (HALT or RUNNING) — together they ARE the machine's instantaneous state.
# triggers: _ready() loads each prop scene, sets its DNA, positions it in the
#   apparatus pattern, and adds it as a child. The whole thing is mounted
#   inside a lab_room as that room's mounted_artifact_scene.
# emerges: same prop catalogue, different chamber: when you swap the apparatus,
#   the room teaches a different algorithm. The lab_room is the substrate, the
#   apparatus is the curriculum.
# needs: conveyor_belt (the tape) [present]; robot_arm (the head) [present];
#   server_rack (the program) [present]; electrical_panel (the state register)
#   [present]; info_screen (the output) [present]; emergency_button (the HALT)
#   [present]; exit_sign (the terminate) [present].
# relationships: this is the FIRST algorithm-trajectory apparatus. Future
#   apparatuses (qfep_phase_chamber, foundations_crisis_hall, monte_carlo_room)
#   follow the same pattern: a Node3D composer that arranges props.
# truth: an algorithm is a way of moving through space, not a way of writing
#   symbols on paper. The Turing machine becomes obvious when you can walk it.

## Composes the existing lab props into a Turing-machine layout.
## Origin is at the CENTER of the apparatus floor footprint.
##
## Player enters from +Z (the lab_room's glass wall) facing -Z (the signage
## wall). The apparatus is arranged so the conveyor belt (tape) runs across
## the room left-to-right (-X to +X), perpendicular to the player's gaze.
## Read/write head (robot arm) sits above the belt's center. The program
## (server rack) stands on the left, the state register (electrical panel)
## on the right. Halt-control (emergency button on podium) at the back-
## center. Info screen high above on the back wall. Exit sign above the
## entrance (back to player).

# ── Props ─────────────────────────────────────────────────────────────

const SCENE_CONVEYOR: PackedScene = preload("res://commons/artifacts/conveyor_belt/conveyor_belt.tscn")
const SCENE_ROBOT_ARM: PackedScene = preload("res://commons/artifacts/robot_arm/robot_arm.tscn")
const SCENE_SERVER_RACK: PackedScene = preload("res://commons/artifacts/server_rack/server_rack.tscn")
const SCENE_ELECTRICAL_PANEL: PackedScene = preload("res://commons/artifacts/electrical_panel/electrical_panel.tscn")
const SCENE_INFO_SCREEN: PackedScene = preload("res://commons/artifacts/info_screen/info_screen.tscn")
const SCENE_EMERGENCY_BUTTON: PackedScene = preload("res://commons/artifacts/emergency_button/emergency_button.tscn")
const SCENE_EXIT_SIGN: PackedScene = preload("res://commons/artifacts/exit_sign/exit_sign.tscn")
const SCENE_WHITEBOARD: PackedScene = preload("res://commons/artifacts/whiteboard/whiteboard.tscn")

# ── DNA — apparatus-wide state (becomes the machine's instantaneous state)

@export_group("Machine state")
## Current symbol on the tape under the head — number of belt arrows = read
## position. 5 = mid-tape, 9 = near end (almost done), 2 = early.
@export_range(1, 12, 1) var belt_arrow_count: int = 5
## State register — the bits currently held in the state register. 12 breakers
## are 12 bits. 8 of 12 ON = state value 0xAA-ish.
@export_range(0, 12, 1) var panel_breakers_on_count: int = 8
## When true, the machine has HALTED. The button is depressed, the LED status
## switches color, the info screen reads HALTED.
@export var button_pressed: bool = false
## Number of objectives on the rules turret (server faces = number of state
## transitions visible on the program side).
@export_range(2, 12, 1) var program_server_count: int = 6
## Current pose of the read/write head (joint angles).
@export var head_pose_degrees: PackedFloat32Array = PackedFloat32Array([15.0, -45.0, 65.0, -20.0])

@export_group("Apparatus colors")
## Phase tint — the room's QFEP color. F_order blue = the canonical Turing
## machine room (deterministic, mechanical, ordered). Other phases re-tint the
## apparatus to fit a different chamber's mood.
@export var accent_color: Color = Color(0.227, 0.482, 1.0)

# ── Internal ──────────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_apparatus()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for child in get_children():
			child.queue_free()
		_built = false
		_build_apparatus()


func _read_metadata_overrides() -> void:
	if has_meta("config_belt_arrow_count"):
		belt_arrow_count = int(String(get_meta("config_belt_arrow_count")))
	if has_meta("config_panel_breakers_on_count"):
		panel_breakers_on_count = int(String(get_meta("config_panel_breakers_on_count")))
	if has_meta("config_button_pressed"):
		var v: String = String(get_meta("config_button_pressed")).to_lower()
		button_pressed = (v == "true" or v == "1" or v == "yes")
	if has_meta("config_program_server_count"):
		program_server_count = int(String(get_meta("config_program_server_count")))
	if has_meta("config_accent_color"):
		accent_color = _parse_color(String(get_meta("config_accent_color")), accent_color)


func _parse_color(s: String, fallback: Color) -> Color:
	var parts: PackedStringArray = s.split(",")
	if parts.size() < 3:
		return fallback
	var r: float = float(parts[0])
	var g: float = float(parts[1])
	var b: float = float(parts[2])
	var a: float = 1.0
	if parts.size() >= 4:
		a = float(parts[3])
	return Color(r, g, b, a)


# ── Build ─────────────────────────────────────────────────────────────

func _build_apparatus() -> void:
	# ── The tape: conveyor_belt running left-right across the room ─────
	# Belt is 4m long, 0.6m wide, deck height ~0.18m. Position it
	# slightly toward the signage wall (-Z) so there's clear walking
	# space on the player's side (+Z).
	var belt: Node3D = SCENE_CONVEYOR.instantiate()
	belt.set("belt_length", 4.0)
	belt.set("belt_width", 0.6)
	belt.set("direction_arrow_count", belt_arrow_count)
	belt.set("support_legs", 6)
	belt.set("accent_color", accent_color)
	belt.set("arrow_color", accent_color)
	belt.position = Vector3(0.0, 0.0, -0.6)
	add_child(belt)

	# ── The read/write head: robot_arm mounted at belt center ─────────
	# Robot arm origin is at the base bottom. Sit it on top of the belt
	# deck (y = belt_height = 0.18) at belt center.
	var arm: Node3D = SCENE_ROBOT_ARM.instantiate()
	arm.set("arm_segment_count", 3)
	arm.set("pose_angles_degrees", head_pose_degrees)
	arm.set("gripper_visible", true)
	arm.set("accent_color", accent_color)
	arm.position = Vector3(0.0, 0.20, -0.6)
	add_child(arm)

	# ── The program: server_rack on the player's left ─────────────────
	# Front face +Z = toward player. Slightly behind belt level so the
	# eye sees rack + belt + head as three stations in depth.
	var rack: Node3D = SCENE_SERVER_RACK.instantiate()
	rack.set("rack_height_u", 32)
	rack.set("server_count", program_server_count)
	rack.set("led_density", 5)
	rack.set("door_open", true)  # exposed = legible rules
	rack.set("led_color", Color(0.30, 0.85, 0.40) if not button_pressed else Color(0.95, 0.20, 0.20))
	rack.set("accent_color", accent_color)
	rack.position = Vector3(-2.2, 0.0, -1.8)
	rack.rotation = Vector3(0.0, deg_to_rad(20.0), 0.0)  # angled toward player
	add_child(rack)

	# ── The state register: electrical_panel on the player's right ────
	# Wall-mounted at chest height. Door open so breaker levers are
	# visible — the bits are the machine's current state.
	var panel: Node3D = SCENE_ELECTRICAL_PANEL.instantiate()
	panel.set("panel_width", 0.55)
	panel.set("panel_height", 0.80)
	panel.set("breaker_count", 12)
	panel.set("breakers_on_count", panel_breakers_on_count)
	panel.set("door_open", true)
	panel.set("status_color", Color(0.30, 0.85, 0.40) if not button_pressed else Color(0.95, 0.20, 0.20))
	panel.set("accent_color", Color(0.98, 0.78, 0.12))  # hazard yellow — register is critical
	panel.set("signage_text", "STATE")
	panel.position = Vector3(2.2, 1.45, -1.8)
	panel.rotation = Vector3(0.0, deg_to_rad(-20.0), 0.0)
	add_child(panel)

	# ── The output: info_screen high above the apparatus ──────────────
	# Above the belt, mounted on the back-wall plane, showing current
	# machine state. When button_pressed=true, the screen reads HALTED.
	var screen: Node3D = SCENE_INFO_SCREEN.instantiate()
	screen.set("screen_width", 1.40)
	screen.set("screen_height", 0.85)
	if button_pressed:
		screen.set("header_text", "HALTED")
		screen.set("text_lines", PackedStringArray([
			"input accepted at step %d" % belt_arrow_count,
			"state register: %d / 12 bits ON" % panel_breakers_on_count,
			"output: final tape symbol",
		]))
		screen.set("text_color", Color(0.95, 0.30, 0.32))
		screen.set("header_color", Color(1.0, 0.40, 0.40))
	else:
		screen.set("header_text", "RUNNING")
		screen.set("text_lines", PackedStringArray([
			"step: %d" % belt_arrow_count,
			"state: 0b%s" % _bits_string(panel_breakers_on_count, 12),
			"head: pose %s" % str(head_pose_degrees),
		]))
		screen.set("text_color", Color(0.45, 0.95, 0.55))
		screen.set("header_color", Color(0.95, 0.72, 0.30))
	screen.set("text_size", 22)
	screen.position = Vector3(0.0, 2.45, -2.50)
	add_child(screen)

	# ── The HALT control: emergency_button on a podium at the back ────
	# Podium mount = freestanding button column. Sits in front of the
	# back wall, behind the belt. When pressed, the machine halts —
	# this is the button the operator hits to stop the world.
	var button: Node3D = SCENE_EMERGENCY_BUTTON.instantiate()
	button.set("button_color", Color(0.95, 0.10, 0.10))
	button.set("plate_color", Color(0.98, 0.85, 0.10))
	button.set("label_text", "HALT")
	button.set("pressed", button_pressed)
	button.set("mounting", "podium")
	button.set("button_radius", 0.065)
	button.position = Vector3(1.2, 0.0, -2.0)
	add_child(button)

	# ── Terminate: exit_sign above the entrance (back of player) ──────
	# The exit sign points at the way OUT — when the machine halts
	# (button_pressed=true), the sign's color shifts to indicate the
	# computation has returned a result. Sign faces -Z so a player
	# turning around to leave sees it.
	var sign_node: Node3D = SCENE_EXIT_SIGN.instantiate()
	sign_node.set("text", "RETURN" if button_pressed else "EXIT")
	sign_node.set("arrow_direction", "down")
	sign_node.set("sign_color", Color(0.20, 0.80, 0.30) if button_pressed else Color(0.95, 0.65, 0.20))
	sign_node.set("width", 0.55)
	sign_node.set("glow_energy", 2.0)
	sign_node.position = Vector3(0.0, 2.30, 2.50)
	sign_node.rotation = Vector3(0.0, deg_to_rad(180.0), 0.0)  # face -Z (so player turning to leave sees text)
	add_child(sign_node)

	# ── The formal proof: whiteboard on the right wall behind the panel
	# Carries the formal Turing-machine definition so the room reads as
	# both physical apparatus AND symbolic statement.
	var board: Node3D = SCENE_WHITEBOARD.instantiate()
	board.set("board_width", 1.40)
	board.set("board_height", 0.95)
	board.set("text_lines", PackedStringArray([
		"Turing Machine M = (Q, Σ, Γ, δ, q0, F)",
		"  Q  states     Σ  input alphabet",
		"  Γ  tape symbols    δ : Q × Γ -> Q × Γ × {L, R}",
		"  q0 start    F  accept states",
		"",
		"the room IS M — server_rack=δ, panel=q, belt=Γ*",
	]))
	board.set("text_size", 22)
	board.position = Vector3(-2.85, 1.35, 0.5)
	board.rotation = Vector3(0.0, deg_to_rad(90.0), 0.0)  # face into the room (+X) from -X wall
	add_child(board)

	_built = true


func _bits_string(value: int, width: int) -> String:
	# Quick "8 -> 000000001000" style placeholder; we encode breakers_on as
	# a count, so just show as N ones followed by zeros (decorative).
	var out: String = ""
	for i in range(width):
		if i < value:
			out += "1"
		else:
			out += "0"
	return out
