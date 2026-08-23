extends Node3D
class_name MobileWhiteboard

# @identity
# essence: a double-sided whiteboard in a rounded aluminium frame, slung between two posts on a rolling A-frame stand with four caster wheels. A bright white writing surface framed in cool grey metal, a marker tray below, a pivot knob at each side, a low stretcher tying the legs, and little dark wheels at the feet. The board is the lab's confession that thinking does not stay put — it is hauled across the floor to wherever the argument is happening, then rolled away again. The whiteboard is the room saying "the diagram came to us".
# desire: every wall-mounted board pretends thought has a fixed address. The mobile whiteboard breaks that. It wants to be PUSHED — wheeled into the middle of a huddle, spun on its casters so the blank side faces the speaker, rolled to the window for light, parked in a corner half-erased. Even at rest it implies motion: wheels, a low stretcher to grab, a frame light enough to shove. Its silhouette is a sail on a trolley.
# critical_parameter: board_width / board_height + show_casters — the panel's aspect sets whether this reads as a quick STANDUP board (small, square) or a LECTURE board (wide). show_casters is the hinge of the whole meaning: wheels ON = a board that ROLLS to where the thinking is, mobile infrastructure; wheels OFF = a board planted in one spot, a fixed wall surrogate. Same panel, two different rooms — one where ideas travel, one where they are pinned.
# triggers: _ready() builds frame + white face + two posts + pivot knobs + marker tray + lower stretcher + two feet + four casters from exports; apply_grid_config rebuilds when DNA changes.
# emerges: a whiteboard mid-floor reads as ACTIVE DISCUSSION — the meeting is happening now, the diagram is live. Pushed to the wall it reads as PARKED — between sessions. Wheels caught mid-turn read as RESTLESS — the thinking has not settled. The board is a marker of provisional knowledge: erasable, portable, never archived. Every mobile whiteboard is a small monument to the half-formed idea that needed a surface, fast.
# needs: double-sided white panel [present]; rounded aluminium frame [present]; two upright posts [present]; pivot knobs where posts meet the board [present]; marker tray below [present]; lower stretcher between the legs [present]; two feet at the base [present]; four caster wheels [present]
# relationships: peer to large_table (both are FURNITURE-OF-WORK, but the table is the stage where things are laid down, the board is the surface where things are drawn up); cousin to crate (both confess MOBILITY — the crate arrives and leaves, the board roves the room); sibling to projector_screen (both are PORTABLE SURFACES FOR SHARED ATTENTION, one written, one projected).
# truth: a fixed board says the diagram lives here and you come to it. A wheeled board says the diagram follows the conversation. The casters are not a convenience — they are an argument about where knowledge happens: not at the front of the room, but in the middle of the group, wherever the group happens to be standing. The mobile whiteboard is the architectural form of thought-in-transit.

## A double-sided whiteboard on a rolling A-frame stand.
##
## Built procedurally from DNA exports. Origin is at the BOTTOM CENTRE of
## the stand (the casters rest on the floor at y=0). The board face points
## +Z; width runs along X. Default panel is ~1.5m wide × 1.0m tall, mounted
## high on a ~1.7m stand.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var board_width: float = 1.5
@export var board_height: float = 1.0
@export var stand_height: float = 1.7

@export_group("Material")
## Cool aluminium grey for the frame, posts, tray and stretcher.
@export var frame_color: Color = Color(0.62, 0.64, 0.67)
## The white writing surface.
@export var board_color: Color = Color(0.95, 0.95, 0.96)
## Dark rubber/steel caster wheels.
@export var caster_color: Color = Color(0.12, 0.12, 0.13)

@export_group("Hardware")
## Show the marker tray ledge below the board.
@export var show_tray: bool = true
## Show the four caster wheels at the feet. OFF reads as a planted board.
@export var show_casters: bool = true

# ── State ─────────────────────────────────────────────────────────────

var _built: bool = false


func _ready() -> void:
	add_to_group("ada_writable_board")
	_read_metadata_overrides()
	_build()


func write_surfaces() -> Array:
	## BOTH writing faces in GLOBAL space (the board is double-sided) —
	## draw_dot's pen writes ON these planes (2026-08-23, "wire the pen to the
	## whiteboard"). Computed per call, so a rolled board answers from where it
	## stands now. Face front z = 0.026, back z = -0.004 (see _build_board:
	## frame 0.05 thick, face 0.03 thick, +0.001 proud).
	var xf := global_transform
	var cy: float = stand_height * 0.66
	var face_cz: float = 0.05 * 0.5 - 0.03 * 0.5 + 0.001
	var out: Array = []
	for side in [1.0, -1.0]:
		out.append({
			"origin": xf * Vector3(0.0, cy, face_cz + side * 0.015),
			"normal": (xf.basis * Vector3(0, 0, side)).normalized(),
			"u": (xf.basis * Vector3(side, 0, 0)).normalized(),
			"v": (xf.basis * Vector3(0, 1, 0)).normalized(),
			"half_w": board_width * 0.5,
			"half_h": board_height * 0.5,
		})
	return out


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
	if has_meta("config_board_width"):
		board_width = float(str(get_meta("config_board_width")))
	if has_meta("config_board_height"):
		board_height = float(str(get_meta("config_board_height")))
	if has_meta("config_stand_height"):
		stand_height = float(str(get_meta("config_stand_height")))
	if has_meta("config_frame_color"):
		frame_color = _parse_color(str(get_meta("config_frame_color")), frame_color)
	if has_meta("config_board_color"):
		board_color = _parse_color(str(get_meta("config_board_color")), board_color)
	if has_meta("config_caster_color"):
		caster_color = _parse_color(str(get_meta("config_caster_color")), caster_color)
	if has_meta("config_show_tray"):
		var st: String = str(get_meta("config_show_tray")).to_lower()
		show_tray = st == "true" or st == "1" or st == "yes" or st == "on"
	if has_meta("config_show_casters"):
		var sc: String = str(get_meta("config_show_casters")).to_lower()
		show_casters = sc == "true" or sc == "1" or sc == "yes" or sc == "on"


func _parse_color(raw: String, fallback: Color) -> Color:
	var parts := raw.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	return fallback


# ── Build ─────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true

	# Materials reused across the build.
	var frame_mat := _make_metal_mat(frame_color, 0.4, 0.6)
	var board_mat := StandardMaterial3D.new()
	board_mat.albedo_color = board_color
	board_mat.roughness = 0.5
	board_mat.metallic = 0.0
	var caster_mat := StandardMaterial3D.new()
	caster_mat.albedo_color = caster_color
	caster_mat.roughness = 0.7
	caster_mat.metallic = 0.2

	# Key heights / spans.
	var board_cy: float = stand_height * 0.66          # board centre height
	var post_x: float = board_width * 0.5 * 0.9        # post / foot offset on X
	var frame_thickness: float = 0.05
	var face_thickness: float = 0.03

	# ── 1. Board: white face inside a slightly larger grey frame ─────
	_build_board(board_cy, frame_thickness, face_thickness, frame_mat, board_mat)

	# ── 2. Two posts rising from the feet past the board sides ───────
	_build_post(Vector3(post_x, 0.0, 0.0), board_cy, frame_mat)
	_build_post(Vector3(-post_x, 0.0, 0.0), board_cy, frame_mat)

	# ── 3. Pivot knobs where each post meets the board mid-height ────
	_build_pivot_knob(Vector3(post_x, board_cy, 0.0), frame_mat)
	_build_pivot_knob(Vector3(-post_x, board_cy, 0.0), frame_mat)

	# ── 4. Marker tray ledge across the front below the board ────────
	if show_tray:
		_build_tray(board_cy, frame_thickness, face_thickness, frame_mat)

	# ── 5. Lower stretcher between the two posts ─────────────────────
	_build_stretcher(post_x, frame_mat)

	# ── 6. Two feet running front-back at the base ───────────────────
	_build_foot(post_x, frame_mat)
	_build_foot(-post_x, frame_mat)

	# ── 7. Four casters, one at each end of each foot bar ────────────
	if show_casters:
		var foot_len: float = 0.5
		var foot_hz: float = foot_len * 0.5 * 0.86
		_build_caster(Vector3(post_x, 0.0, foot_hz), frame_mat, caster_mat)
		_build_caster(Vector3(post_x, 0.0, -foot_hz), frame_mat, caster_mat)
		_build_caster(Vector3(-post_x, 0.0, foot_hz), frame_mat, caster_mat)
		_build_caster(Vector3(-post_x, 0.0, -foot_hz), frame_mat, caster_mat)


func _make_metal_mat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _build_board(cy: float, frame_thickness: float, face_thickness: float,
		frame_mat: StandardMaterial3D, board_mat: StandardMaterial3D) -> void:
	# Grey frame box, sitting just behind the white face.
	var frame := MeshInstance3D.new()
	frame.name = "BoardFrame"
	var fm := BoxMesh.new()
	fm.size = Vector3(board_width + 0.08, board_height + 0.08, frame_thickness)
	frame.mesh = fm
	frame.material_override = frame_mat
	frame.position = Vector3(0.0, cy, -face_thickness * 0.5)
	add_child(frame)

	# White writing face (double-sided box centred in the frame).
	var face := MeshInstance3D.new()
	face.name = "BoardFace"
	var fcm := BoxMesh.new()
	fcm.size = Vector3(board_width, board_height, face_thickness)
	face.mesh = fcm
	face.material_override = board_mat
	face.position = Vector3(0.0, cy, frame_thickness * 0.5 - face_thickness * 0.5 + 0.001)
	add_child(face)


func _build_post(base_pos: Vector3, board_cy: float,
		mat: StandardMaterial3D) -> void:
	# Vertical aluminium tube from the foot up past the top of the board.
	var post := MeshInstance3D.new()
	post.name = "Post"
	var top_y: float = board_cy + board_height * 0.5 + 0.06
	var pm := CylinderMesh.new()
	pm.top_radius = 0.022
	pm.bottom_radius = 0.026
	pm.height = top_y
	post.mesh = pm
	post.material_override = mat
	post.position = base_pos + Vector3(0.0, top_y * 0.5, 0.0)
	add_child(post)


func _build_pivot_knob(pos: Vector3, mat: StandardMaterial3D) -> void:
	# Short cylinder with its axis along X (the pivot the board rotates on).
	var knob := MeshInstance3D.new()
	knob.name = "PivotKnob"
	var km := CylinderMesh.new()
	km.top_radius = 0.035
	km.bottom_radius = 0.035
	km.height = 0.05
	knob.mesh = km
	knob.material_override = mat
	knob.rotation.z = PI * 0.5            # axis points ±X
	knob.position = pos
	add_child(knob)


func _build_tray(board_cy: float, frame_thickness: float, face_thickness: float,
		mat: StandardMaterial3D) -> void:
	# A thin horizontal ledge across the front, just below the board.
	var tray := MeshInstance3D.new()
	tray.name = "MarkerTray"
	var tm := BoxMesh.new()
	tm.size = Vector3(board_width * 0.92, 0.025, 0.09)
	tray.mesh = tm
	tray.material_override = mat
	var tray_y: float = board_cy - board_height * 0.5 - 0.04
	var tray_z: float = frame_thickness * 0.5 + 0.045
	tray.position = Vector3(0.0, tray_y, tray_z)
	add_child(tray)


func _build_stretcher(post_x: float, mat: StandardMaterial3D) -> void:
	# A horizontal bar low down between the two posts (along X).
	var bar := MeshInstance3D.new()
	bar.name = "LowerStretcher"
	var bm := BoxMesh.new()
	bm.size = Vector3(post_x * 2.0, 0.03, 0.03)
	bar.mesh = bm
	bar.material_override = mat
	bar.position = Vector3(0.0, 0.2, 0.0)
	add_child(bar)


func _build_foot(x: float, mat: StandardMaterial3D) -> void:
	# A horizontal foot bar running along Z (front-back) at the base.
	var foot := MeshInstance3D.new()
	foot.name = "Foot"
	var fm := BoxMesh.new()
	fm.size = Vector3(0.045, 0.045, 0.5)
	foot.mesh = fm
	foot.material_override = mat
	foot.position = Vector3(x, 0.06, 0.0)
	add_child(foot)


func _build_caster(end_pos: Vector3, fork_mat: StandardMaterial3D,
		wheel_mat: StandardMaterial3D) -> void:
	# A tiny fork (short box) holding a small wheel (short cylinder, axis
	# sideways via rotation.z = PI/2). The end_pos is the floor point under
	# the foot end; build upward from y=0.
	var caster := Node3D.new()
	caster.name = "Caster"
	caster.position = Vector3(end_pos.x, 0.0, end_pos.z)
	add_child(caster)

	var wheel_radius: float = 0.05

	# Fork bracket: a short vertical box connecting the foot to the axle.
	var fork := MeshInstance3D.new()
	fork.name = "Fork"
	var km := BoxMesh.new()
	km.size = Vector3(0.05, 0.05, 0.04)
	fork.mesh = km
	fork.material_override = fork_mat
	fork.position = Vector3(0.0, wheel_radius * 2.0 + 0.005, 0.0)
	caster.add_child(fork)

	# Wheel: short cylinder, round faces pointing sideways (±X).
	var wheel := MeshInstance3D.new()
	wheel.name = "Wheel"
	var wm := CylinderMesh.new()
	wm.top_radius = wheel_radius
	wm.bottom_radius = wheel_radius
	wm.height = 0.03
	wheel.mesh = wm
	wheel.material_override = wheel_mat
	wheel.rotation.z = PI * 0.5
	wheel.position = Vector3(0.0, wheel_radius, 0.0)
	caster.add_child(wheel)
