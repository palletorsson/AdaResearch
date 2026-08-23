extends Node3D

# @identity
# essence: sample(hand_position) → ImmediateMesh trail — the hand writes points in 3D space
# desire: learner experiences themselves as a drawing instrument — hand motion becomes visible line
# critical_parameter: trail_length — how many hand positions are stored before the oldest disappears
# triggers: moving the grabbed sphere — total_distance accumulates and triggers unlock tags
# emerges: the understanding that a continuous curve is just many sampled points
# needs: [has Label3D [has], grabbable sphere [has], missing speed/density slider]
# relationships: contrasts with static_point (fixed vs dynamic); pairs with player_trace
# truth: a curve has no intrinsic form — it is just the limit of increasingly dense point samples

@export var grab_point_path: NodePath = NodePath("GrabPoint")
@export var draw_sphere_path: NodePath = NodePath("GrabPoint/DrawSphere")
@export var trail_color: Color = Color(1.0, 0.4, 0.9, 1.0)
@export var trail_max_points: int = 1024
@export var min_segment_distance: float = 0.01
@export var record_only_when_grabbed: bool = true
@export var auto_clear_on_drop: bool = false
@export var reference_frame_position: Vector3 = Vector3(0, 0, 0.2)
@export var reference_frame_size: float = 0.5
@export var show_reference_frame: bool = true

## AXIS — WHAT A MARK PERSISTS AS once the hand that made it has gone. The word is adopted
## from [[mystic_writing_pad]] and shared with [[grab_sphere_point_snap]],
## [[draw_triangle_faces]] and [[interactive_point_origin_force]]: all five put a mark into
## space and then have to say what space does with it. draw_dot is the bare case — a hand,
## a sample, a line — so the regime it stands in is the whole argument.
##
## The record is built INSIDE the reference frame, at the same plane and inside its
## bounds, so choosing a value changes what is in the frame and never how big the artifact
## is. Marks are drawn as dot-clouds, not as continuous line, because this artifact's own
## truth statement is that a curve is only ever a dense set of point samples.
##
##   none      the legacy lineage, byte for byte. The frame is empty: at rest this artifact
##             shows no mark, and it never claimed to. Space keeps nothing you did not just do
##   trace     one stroke hangs in the frame in the ink colour, exactly where it was drawn —
##             the mark stays put and stays visible
##   lattice   a ruled field of pale nodes fills the frame and the stroke is quantised onto
##             it: stair-stepped, right-angled. A position had to be legal before it counted
##   archive   nine strokes at once, every one kept at full brightness, overlapping into a
##             thicket. Nothing is discarded, so nothing can be read
##   wax       a dark slab behind a pale translucent sheet, with faint warm strokes sunk
##             between them. The surface is clean; the record is underneath, at an angle
@export var retention: String = "none"
const RETENTIONS: PackedStringArray = ["none", "trace", "lattice", "archive", "wax"]

## AXIS — THE INK the hand writes with (2026-08-23, built for collations: several
## draw_dots in one room, each writing in its own colour). A named palette so a map
## token can say it (#ink:cyan); "magenta" maps byte-for-byte onto the legacy
## trail_color default, so a map that says nothing gets exactly the artifact that
## shipped. When ink is default, a scene's own trail_color override still rules —
## the palette never fights an existing hand-tuned colour.
## Visible in a still ONLY when a retention record shows a stroke — the sweep
## fixture pins retention:trace for exactly that reason.
@export_enum("magenta", "cyan", "amber", "lime", "white") var ink: String = "magenta"
const INKS: Dictionary = {
	"magenta": Color(1.0, 0.4, 0.9, 1.0),
	"cyan": Color(0.25, 0.85, 1.0, 1.0),
	"amber": Color(1.0, 0.72, 0.15, 1.0),
	"lime": Color(0.55, 1.0, 0.3, 1.0),
	"white": Color(0.95, 0.95, 1.0, 1.0),
}

## GRAIN — the sampling distance: how far the hand travels before the trail records
## another point (min_segment_distance). Config key only, NEVER a dna.axis — a
## sampling rate is invisible in a still (the info_board lesson). Named steps or a
## bare number: #grain:coarse or #grain:0.02.
const GRAINS: Dictionary = {
	"fine": 0.004,
	"standard": 0.01,
	"coarse": 0.03,
	"chunky": 0.08,
}

## RESOLUTION — the grid the hand's line is snapped ONTO, in millimetres
## (2026-08-23, Palle: "so the line becomes more in larger grid pattern —
## 0.1, 1, 10, 20, 40, 80"). Every recorded point lands on a world-aligned
## lattice of this pitch, so a coarse value stair-steps the stroke into
## blocks; 0 = off, the legacy continuous line, and 0.1 mm is effectively
## continuous. Reaches the retention record too, so a collation of draw_dots
## with different resolutions reads across a room. Config key `resolution`
## (#resolution:40) — a natural custom-key collation series. Distinct from
## grain: grain is WHEN the hand is sampled, resolution is WHERE a sample is
## allowed to stand.
@export var resolution_mm: float = 0.0

var _grab_point: Node3D
var _draw_sphere: Node3D
var _trail_mesh: ImmediateMesh
var _trail_instance: MeshInstance3D
var _trail_points: Array[Vector3] = []
var _last_global_position: Vector3 = Vector3.ZERO
var _reference_frame: MeshInstance3D



func _setup_trail() -> void:
	# A LINE (2026-08-23, Palle: "it should be a line since that is where we
	# see the resolution of the line") — the vertices are the shaped samples
	# (_shape_sample: resolution grid, whiteboard plane), so on a coarse
	# resolution the line stair-steps corner to corner through the grid. The
	# line is where the resolution becomes visible.
	_trail_mesh = ImmediateMesh.new()
	_trail_instance = MeshInstance3D.new()
	_trail_instance.name = "DrawTrail"
	_trail_instance.mesh = _trail_mesh

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = trail_color
	material.emission_enabled = true
	material.emission = trail_color
	material.emission_energy_multiplier = 1.25
	_trail_instance.material_override = material

	# Important: Trail should be in global space, not moving with the hand
	_trail_instance.set_as_top_level(true)

	add_child(_trail_instance)

func _setup_reference_frame() -> void:
	var frame_mesh := ImmediateMesh.new()
	_reference_frame = MeshInstance3D.new()
	_reference_frame.name = "ReferenceFrame"
	_reference_frame.mesh = frame_mesh
	_reference_frame.position = reference_frame_position
	
	# Reference frame moves with the object (it's a local guide)
	# So we don't set top_level here

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.7, 0.7, 0.7, 0.8)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_reference_frame.material_override = material

	var half_size := reference_frame_size / 2.0
	var horizon_half := half_size / 2.0

	frame_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	# Top edge
	frame_mesh.surface_add_vertex(Vector3(-half_size, half_size, 0))
	frame_mesh.surface_add_vertex(Vector3(half_size, half_size, 0))

	# Bottom edge
	frame_mesh.surface_add_vertex(Vector3(-half_size, -half_size, 0))
	frame_mesh.surface_add_vertex(Vector3(half_size, -half_size, 0))

	# Left edge
	frame_mesh.surface_add_vertex(Vector3(-half_size, -half_size, 0))
	frame_mesh.surface_add_vertex(Vector3(-half_size, half_size, 0))

	# Right edge
	frame_mesh.surface_add_vertex(Vector3(half_size, -half_size, 0))
	frame_mesh.surface_add_vertex(Vector3(half_size, half_size, 0))

	# Horizon line (thinner - half width in middle)
	frame_mesh.surface_add_vertex(Vector3(-horizon_half, 0, 0))
	frame_mesh.surface_add_vertex(Vector3(horizon_half, 0, 0))

	frame_mesh.surface_end()

	add_child(_reference_frame)

func _setup_progress_indicator() -> void:
	# Create progress indicator as world-space element (not child of grab point)
	var progress_shader = load("res://commons/scenes/main_menu/components/linear_progress.gdshader")
	if not progress_shader:
		push_warning("DrawDot: Could not load progress shader")
		return

	_progress_indicator = MeshInstance3D.new()
	_progress_indicator.name = "ProgressIndicator"

	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(0.2, 0.04)
	_progress_indicator.mesh = quad_mesh

	var material = ShaderMaterial.new()
	material.render_priority = 100
	material.shader = progress_shader
	material.set_shader_parameter("progress", 0.0)
	material.set_shader_parameter("color", unlock_progress_color)
	_progress_indicator.material_override = material

	# Make it world-space so it doesn't follow the hand
	_progress_indicator.set_as_top_level(true)
	_progress_indicator.visible = false

	add_child(_progress_indicator)

func _update_progress_indicator_position() -> void:
	if not _progress_indicator or _trail_points.is_empty():
		return

	# Position above the first trail point (start of drawing)
	var start_pos = _trail_points[0]
	_progress_indicator.global_position = start_pos + Vector3(0, progress_bar_height_offset, 0)

func _setup_data_table() -> void:
	if not show_data_table:
		return

	_data_table_label = Label3D.new()
	_data_table_label.name = "DataTable"
	_data_table_label.font_size = data_table_font_size
	_data_table_label.pixel_size = 0.001  # Sharper text
	_data_table_label.modulate = data_table_color
	_data_table_label.outline_size = 2
	_data_table_label.outline_modulate = Color(0.1, 0.1, 0.2, 0.9)

	# NOT billboard - fixed orientation
	_data_table_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_data_table_label.fixed_size = false

	# World-space positioning
	_data_table_label.set_as_top_level(true)
	_data_table_label.visible = false

	# Horizontal alignment
	_data_table_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	# Rotate 90° in X (parallel to ground) and 180° in Y
	_data_table_label.rotation_degrees.x = -90
	_data_table_label.rotation_degrees.y = 180

	# Scale for sharper text
	_data_table_label.scale = Vector3(1.0, 1.0, 1.0)

	add_child(_data_table_label)

func _update_data_table() -> void:
	if not _data_table_label or _trail_points.is_empty():
		return

	var current_pos = _draw_sphere.global_position if _draw_sphere else Vector3.ZERO
	var trail_length = _total_movement
	var point_count = _trail_points.size()
	var dist_from_origin = current_pos.length()

	# Build table text with last 10 points
	var table_text = "TRACE DATA\n"
	table_text += "─────────────────\n"
	table_text += "Points: %d  Length: %.2f m\n" % [point_count, trail_length]
	table_text += "─────────────────\n"
	table_text += "LAST 10 POSITIONS\n"

	# Show last 10 points (or fewer if less than 10 exist)
	var start_idx = max(0, _trail_points.size() - 10)
	for i in range(start_idx, _trail_points.size()):
		var pt = _trail_points[i]
		var idx = i - start_idx + 1
		table_text += "%2d: (%.2f, %.2f, %.2f)\n" % [idx, pt.x, pt.y, pt.z]

	_data_table_label.text = table_text
	_data_table_label.visible = true

	# Position near trail start, offset to the side and forward
	var start_pos = _trail_points[0]
	_data_table_label.global_position = start_pos + Vector3(0.15, data_table_height_offset - 0.1, 0.2)

@export var fade_trail: bool = false
@export var fade_duration: float = 2.0
@export var progress_bar_height_offset: float = 0.15  # Height above trail start point

# Data Table Display
@export_group("Data Table")
@export var show_data_table: bool = true
@export var data_table_height_offset: float = -0.35  # Height relative to trail start
@export var data_table_color: Color = Color(0.9, 0.95, 1.0, 1.0)
@export var data_table_font_size: int = 20
@export var data_table_update_interval: float = 0.15  # Seconds between updates

var _data_table_label: Label3D
var _data_table_timer: float = 0.0


# Tag System
@export_group("Tag System")
@export var trigger_tag: String = ""
@export var trigger_action: String = "shrink_and_remove"
@export var movement_threshold: float = 6.0 # Meters of drawing movement required (trail length)
@export var unlock_progress_color: Color = Color(0.2, 1.0, 0.4) # Green when finished

@export var unlock_sound: AudioStream

var _trail_times: Array[float] = []
var _time_elapsed: float = 0.0

var _total_movement: float = 0.0
var _triggered: bool = false
var _original_color: Color

var _success_player: AudioStreamPlayer3D
var _progress_indicator: MeshInstance3D

func _ready() -> void:
	print("DrawDot: _ready called")
	var trace_data = get_node_or_null("/root/TraceData")
	print("DrawDot: TraceData status: " + str(trace_data))

	_grab_point = get_node_or_null(grab_point_path)
	_draw_sphere = get_node_or_null(draw_sphere_path)

	# INK / GRAIN before _setup_trail — the trail material bakes trail_color in,
	# so the colour must be settled before the material exists.
	_ink_read_config()

	# Setup progress indicator as world-space (not child of grab point)
	_setup_progress_indicator()

	# Setup data table display
	_setup_data_table()

	if not _grab_point or not _draw_sphere:
		push_warning("DrawDot: Missing grab point or draw sphere in scene.")
		set_process(false)
		return

	_setup_trail()
	_setup_success_audio()
	if show_reference_frame:
		_setup_reference_frame()
	_last_global_position = _draw_sphere.global_position
	set_process(true)

	# Always connect to dropped to handle saving, regardless of auto-clear
	if _grab_point.has_signal("dropped"):
		if not _grab_point.is_connected("dropped", _on_grab_point_dropped):
			_grab_point.dropped.connect(_on_grab_point_dropped)

	# RETENTION last, so every child added above keeps its index. "none" is the legacy
	# lineage and adds nothing at all.
	_ret_read_config()
	_ret_build()

func _process(delta: float) -> void:
	if not is_instance_valid(_draw_sphere):
		return

	_time_elapsed += delta

	var current_global = _draw_sphere.global_position

	if record_only_when_grabbed and is_instance_valid(_grab_point) and _grab_point.has_method("is_picked_up"):
		if not _grab_point.is_picked_up():
			_last_global_position = current_global
			# If we are not recording, we should still process fading if enabled
			if fade_trail:
				_cleanup_old_points()
				_rebuild_trail()
			
			# Hide progress indicator and data table when not grabbed
			if _progress_indicator:
				_progress_indicator.visible = false
			if _data_table_label:
				_data_table_label.visible = false

			return
	
	# Calculate movement since last frame
	var dist = current_global.distance_to(_last_global_position)

	if dist < min_segment_distance:
		if fade_trail:
			_cleanup_old_points()
			_rebuild_trail()
		return

	_last_global_position = current_global
	# Shape the sample: ON a nearby whiteboard face (pen-on-board — projected
	# onto the plane and snapped in BOARD space, so the grid pattern hangs as
	# wall work) or in free space (world-grid snap). One vertex per grid cell —
	# the line's corners sit on the grid, which is where the resolution shows.
	var rec: Vector3 = _shape_sample(current_global)
	if not _trail_points.is_empty() and _trail_points[_trail_points.size() - 1].is_equal_approx(rec):
		return
	# Use global position for the trail points since the mesh is top_level
	_trail_points.append(rec)

	# Only count movement when actually drawing (adding trail points)
	_total_movement += dist
	_check_unlock_progress()

	# Position progress indicator above trail start point
	_update_progress_indicator_position()

	# Update data table (throttled)
	_data_table_timer += delta
	if _data_table_timer >= data_table_update_interval:
		_data_table_timer = 0.0
		_update_data_table()

	if fade_trail:
		_trail_times.append(_time_elapsed)

	if _trail_points.size() > trail_max_points:
		_trail_points.pop_front()
		if fade_trail and _trail_times.size() > 0:
			_trail_times.pop_front()
			
	if fade_trail:
		_cleanup_old_points()

	_rebuild_trail()

func _check_unlock_progress() -> void:
	if _triggered or trigger_tag == "":
		return
		
	var progress = clamp(_total_movement / movement_threshold, 0.0, 1.0)
	
	# Update progress indicator
	if _progress_indicator:
		_progress_indicator.visible = true
		if _progress_indicator.material_override:
			_progress_indicator.material_override.set_shader_parameter("progress", progress)
	

	
	if progress >= 1.0:
		_trigger_unlock()

func _trigger_unlock() -> void:
	_triggered = true
	
	# Trigger sequence: Sound -> Wait -> Action
	if _success_player:
		_success_player.play()
	
	# Wait for 1 second
	await get_tree().create_timer(1.0).timeout
	
	print("DrawDot: Movement threshold reached! Triggering tag '%s' action '%s'" % [trigger_tag, trigger_action])
	
	# Trigger action on the tag (e.g. "remove")
	# Assuming TagSystem is a global class or autoload
	if TagSystem:
		# Safety: Ensure WE are not about to be removed if we accidentally share the tag
		if trigger_action == "remove" or trigger_action == "shrink_and_remove":
			TagSystem.unregister_tagged_node(trigger_tag, self)
			if _grab_point:
				TagSystem.unregister_tagged_node(trigger_tag, _grab_point)
			
		TagSystem.trigger_tag_action(trigger_tag, trigger_action)
	else:
		push_warning("DrawDot: TagSystem not found!")

func _setup_success_audio() -> void:
	_success_player = AudioStreamPlayer3D.new()
	_success_player.name = "SuccessPlayer"
	if unlock_sound:
		_success_player.stream = unlock_sound
	else:
		_success_player.stream = _build_default_success_stream()
	_success_player.unit_size = 5.0 # Hearable from distance
	add_child(_success_player)

func _build_default_success_stream() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 44100
	stream.stereo = true
	var duration := 0.5
	var length := int(stream.mix_rate * duration)
	var data := PackedByteArray()
	data.resize(length * 4) # 16-bit stereo = 4 bytes per sample
	
	for i in length:
		var t: float = float(i) / stream.mix_rate
		# Simple "ding" - high pitch sine wave with decay
		var envelope: float = exp(-5.0 * t)
		var sample: float = sin(TAU * 1200.0 * t) * 0.5 * envelope
		# Add a harmonic
		sample += sin(TAU * 2400.0 * t) * 0.2 * envelope
		
		var int_sample: int = int(sample * 32767.0)
		# Stereo copy
		var low = int_sample & 0xFF
		var high = (int_sample >> 8) & 0xFF
		
		data[4 * i] = low
		data[4 * i + 1] = high
		data[4 * i + 2] = low
		data[4 * i + 3] = high
		
	stream.data = data
	return stream

func _cleanup_old_points() -> void:
	if _trail_times.is_empty():
		return
		
	var cutoff = _time_elapsed - fade_duration
	while _trail_times.size() > 0 and _trail_times[0] < cutoff:
		_trail_times.pop_front()
		_trail_points.pop_front()

func _rebuild_trail() -> void:
	# A line through the shaped samples — on a coarse resolution the segments
	# jump grid point to grid point, so the stair-steps ARE the resolution.
	_trail_mesh.clear_surfaces()
	if _trail_points.size() < 2:
		return

	_trail_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	if fade_trail and _trail_times.size() == _trail_points.size():
		for i in range(_trail_points.size()):
			var age = _time_elapsed - _trail_times[i]
			var alpha = 1.0 - clamp(age / fade_duration, 0.0, 1.0)
			var color = trail_color
			color.a = alpha
			_trail_mesh.surface_set_color(color)
			_trail_mesh.surface_add_vertex(_trail_points[i])
	else:
		for point in _trail_points:
			_trail_mesh.surface_add_vertex(point)

	_trail_mesh.surface_end()


func clear_trail() -> void:
	_trail_points.clear()
	if _trail_mesh:
		_trail_mesh.clear_surfaces()
	if is_instance_valid(_draw_sphere):
		_last_global_position = _draw_sphere.global_position

func _on_grab_point_dropped(_pickable) -> void:
	var trace_data = get_node_or_null("/root/TraceData")
	if trace_data:
		trace_data.add_trace(_trail_points)

	if _progress_indicator:
		_progress_indicator.visible = false

	if auto_clear_on_drop:
		clear_trail()


# ── RETENTION ────────────────────────────────────────────────────────────────
# One axis, five claims about whether space remembers being touched, shared word for word
# with mystic_writing_pad, grab_sphere_point_snap, draw_triangle_faces and
# interactive_point_origin_force. Appended LAST: the live trail, the reference frame, the
# progress indicator and the data table are all built above and none of them move.
#
# APPEARANCE ONLY. Nothing here touches the trail recording, the grab point, the unlock
# threshold or TraceData — a variant changes what a standing visitor SEES the space has
# kept, never what the hand does or what gets saved when it lets go.

# Dot size is a legibility decision, not a taste one: the record sits inside a 0.5 m
# reference frame, so a dot below ~1 cm renders under 10 px in a fitted 760 px shot and a
# whole stroke disappears into the noise floor the bite critic measures against.
const RET_DOT_R := 0.010
const RET_SAMPLES := 54

var _ret_node: Node3D = null


func _ret_read_config() -> void:
	if has_meta("config_retention"):
		var r: String = str(get_meta("config_retention")).strip_edges().to_lower()
		retention = r if RETENTIONS.has(r) else retention


func _ink_color(v: String) -> Color:
	## The colour a config `ink` value names: a palette word, or RAW HEX
	## (ff0000 — no leading '#', since '#' is the token's own config separator)
	## — the escape hatch past the five named inks, the way `grain` accepts a
	## bare number (2026-08-23, "color rgb"). Alpha 0 = not a colour, refused.
	var g: String = v.strip_edges().to_lower()
	if INKS.has(g):
		return INKS[g]
	if Color.html_is_valid(g):
		return Color.html(g)
	return Color(0, 0, 0, 0)


func _ink_read_config() -> void:
	## Meta path — a map token's #ink / #grain land as config_* metadata before
	## _ready (the bricolage pattern). Runs before _setup_trail.
	var ink_set: bool = false
	if has_meta("config_ink"):
		var v: String = str(get_meta("config_ink")).strip_edges().to_lower()
		var ic: Color = _ink_color(v)
		if ic.a > 0.0:
			ink = v
			trail_color = ic
			ink_set = true
	# Sync export → colour: a non-default ink rules; on the default ink an existing
	# scene's hand-tuned trail_color keeps ruling (additive, defaults sacred).
	if not ink_set and ink != "magenta":
		var ec: Color = _ink_color(ink)
		if ec.a > 0.0:
			trail_color = ec
	if has_meta("config_grain"):
		_set_grain(str(get_meta("config_grain")))
	if has_meta("config_resolution"):
		_set_resolution(str(get_meta("config_resolution")))


func _set_grain(v: String) -> void:
	var g: String = v.strip_edges().to_lower()
	if GRAINS.has(g):
		min_segment_distance = GRAINS[g]
	elif g.is_valid_float():
		min_segment_distance = clampf(g.to_float(), 0.001, 0.5)


func _set_resolution(v: String) -> void:
	var g: String = v.strip_edges().to_lower()
	if g.is_valid_float():
		resolution_mm = clampf(g.to_float(), 0.0, 500.0)


# ── PEN ON THE WHITEBOARD (2026-08-23, "wire the pen to the whiteboard") ──
# Whiteboards join the "ada_writable_board" group and answer write_surfaces()
# with their face planes in global space. When the pen tip samples within
# board_write_distance of a face, the dot lands ON the board: projected onto
# the plane, snapped on a 2D grid IN BOARD SPACE (a true grid pattern on the
# board — wall work), lifted just proud of the surface so it reads as ink.

const BOARD_GROUP := "ada_writable_board"
## Pen tip within this distance of a board face writes ON the board.
@export var board_write_distance: float = 0.05


func _nearest_board_face(p: Vector3) -> Dictionary:
	var best: Dictionary = {}
	var bd: float = board_write_distance
	if not is_inside_tree():
		return best
	for b in get_tree().get_nodes_in_group(BOARD_GROUP):
		if not (b as Node).has_method("write_surfaces"):
			continue
		for srf in (b.call("write_surfaces") as Array):
			var s: Dictionary = srf
			var d: Vector3 = p - (s["origin"] as Vector3)
			var dist: float = absf(d.dot(s["normal"] as Vector3))
			if dist <= bd \
					and absf(d.dot(s["u"] as Vector3)) <= float(s["half_w"]) + 0.02 \
					and absf(d.dot(s["v"] as Vector3)) <= float(s["half_h"]) + 0.02:
				bd = dist
				best = s
	return best


func _shape_sample(p: Vector3) -> Vector3:
	## Where a hand sample actually lands: ON a nearby whiteboard face, or in
	## free space with the world-grid resolution snap.
	var srf: Dictionary = _nearest_board_face(p)
	if not srf.is_empty():
		var o: Vector3 = srf["origin"]
		var u_ax: Vector3 = srf["u"]
		var v_ax: Vector3 = srf["v"]
		var d: Vector3 = p - o
		var u: float = d.dot(u_ax)
		var v: float = d.dot(v_ax)
		var rs: float = _res_step()
		if rs > 0.0:
			u = snappedf(u, rs)
			v = snappedf(v, rs)
		u = clampf(u, -float(srf["half_w"]), float(srf["half_w"]))
		v = clampf(v, -float(srf["half_h"]), float(srf["half_h"]))
		# a few millimetres proud of the face so the line reads as ink
		return o + u_ax * u + v_ax * v + (srf["normal"] as Vector3) * 0.004
	var rec: Vector3 = p
	if resolution_mm > 0.0:
		var s: float = resolution_mm / 1000.0
		rec = Vector3(snappedf(rec.x, s), snappedf(rec.y, s), snappedf(rec.z, s))
	return rec


func _res_step() -> float:
	## The snap pitch in metres — 0.0 when resolution is off, which is the
	## value _ret_stroke reads as "no quantisation".
	return resolution_mm / 1000.0 if resolution_mm > 0.0 else 0.0


func _apply_ink() -> void:
	## Re-tint the live trail material — it baked trail_color in at _setup_trail.
	if _trail_instance and is_instance_valid(_trail_instance):
		var m := _trail_instance.material_override as StandardMaterial3D
		if m:
			m.albedo_color = trail_color
			m.emission = trail_color


## Gated per key: a map that says nothing about a key leaves its path untouched, so a
## config carrying only other keys cannot disturb the legacy lineage.
func apply_grid_config(config_data: Dictionary) -> void:
	var dirty: bool = false
	if config_data.has("ink"):
		var v: String = str(config_data["ink"]).strip_edges().to_lower()
		var ic: Color = _ink_color(v)
		if ic.a > 0.0 and v != ink:
			ink = v
			trail_color = ic
			dirty = true
	if config_data.has("grain"):
		_set_grain(str(config_data["grain"]))
	if config_data.has("resolution"):
		var res0 := resolution_mm
		_set_resolution(str(config_data["resolution"]))
		if not is_equal_approx(res0, resolution_mm):
			dirty = true   # the record strokes are drawn AT the resolution
	if config_data.has("retention"):
		var r: String = str(config_data["retention"]).strip_edges().to_lower()
		if RETENTIONS.has(r) and r != retention:
			retention = r
			dirty = true
	if not dirty:
		return
	_apply_ink()
	_ret_build()


func _ret_build() -> void:
	if is_instance_valid(_ret_node):
		_ret_node.queue_free()
	_ret_node = null

	match retention:
		"none":
			pass
		"trace":
			_ret_trace()
		"lattice":
			_ret_lattice()
		"archive":
			_ret_archive()
		"wax":
			_ret_wax()
		_:
			pass


## The record plane — a container sitting exactly where the reference frame does, so the
## record is INSIDE the frame the artifact already draws and the silhouette is unchanged.
func _ret_root() -> Node3D:
	if not is_instance_valid(_ret_node):
		_ret_node = Node3D.new()
		_ret_node.name = "RetentionRecord"
		_ret_node.position = reference_frame_position
		add_child(_ret_node)
	return _ret_node


## TRACE — one stroke, left where the hand left it, in the ink the hand writes with.
func _ret_trace() -> void:
	_ret_stroke(1.31, 0.0, trail_color, 1.6, _res_step())


## LATTICE — the ruling first (a regular field of pale nodes over the whole plane), then
## the same handwriting admitted onto it. The ruling is the dominant read: regular
## pinpricks where every other value shows wander.
func _ret_lattice() -> void:
	var span: float = reference_frame_size * 0.44
	var step: float = 0.042
	var n: int = int(span * 2.0 / step) + 1
	var grid := _ret_mm("LatticeNodes", _ret_emissive(Color(0.52, 0.60, 0.68), 0.5))
	var gm: MultiMesh = grid.multimesh
	gm.instance_count = n * n
	var small: Basis = Basis.IDENTITY.scaled(Vector3.ONE * 0.5)
	var k: int = 0
	for cx in range(n):
		for cy in range(n):
			gm.set_instance_transform(k, Transform3D(small,
				Vector3(-span + float(cx) * step, -span + float(cy) * step, 0.0)))
			k += 1
	_ret_root().add_child(grid)
	_ret_stroke(1.31, 0.0, trail_color, 1.6, maxf(step, _res_step()))


## ARCHIVE — nine strokes kept at once, none dimmed by age. The frame fills; the individual
## mark stops being findable. Total retention and total illegibility are the same picture.
func _ret_archive() -> void:
	for i in range(9):
		_ret_stroke(1.31 + 0.83 * float(i), 0.004 * float(i), trail_color, 1.35, _res_step())


## WAX — the Wunderblock construction, borrowed straight from mystic_writing_pad: a matte
## dark slab, a pale translucent sheet in front of it, and the strokes sunk BETWEEN them,
## each older one fainter. The surface reads clean; the record is underneath.
func _ret_wax() -> void:
	var span: float = reference_frame_size * 0.46
	var root: Node3D = _ret_root()

	var slab := MeshInstance3D.new()
	slab.name = "WaxSlab"
	var sm := BoxMesh.new()
	sm.size = Vector3(span * 2.0, span * 2.0, 0.014)
	slab.mesh = sm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.10, 0.085, 0.095)
	smat.roughness = 0.95
	smat.metallic = 0.0
	slab.material_override = smat
	slab.position = Vector3(0, 0, -0.012)
	root.add_child(slab)

	var warm := Color(0.95, 0.62, 0.35)
	for i in range(5):
		var f: float = float(5 - i) / 5.0
		var c: Color = warm.lerp(Color(0.10, 0.085, 0.095), 1.0 - f)
		_ret_stroke(1.31 + 1.7 * float(i), -0.004 + 0.0016 * float(i), c, 0.45 + 1.1 * f, _res_step())

	var sheet := MeshInstance3D.new()
	sheet.name = "ClearingSheet"
	var shm := BoxMesh.new()
	shm.size = Vector3(span * 2.0, span * 2.0, 0.004)
	sheet.mesh = shm
	var shmat := StandardMaterial3D.new()
	shmat.albedo_color = Color(0.62, 0.65, 0.70, 0.30)
	shmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shmat.roughness = 0.25
	shmat.metallic = 0.0
	sheet.material_override = shmat
	sheet.position = Vector3(0, 0, 0.010)
	root.add_child(sheet)


## One dot-stroke in the record plane. `step` > 0 quantises it onto the ruling.
func _ret_stroke(phase: float, z: float, c: Color, energy: float, step: float) -> void:
	var span: float = reference_frame_size * 0.42
	var mmi := _ret_mm("Stroke", _ret_emissive(c, energy))
	var mm: MultiMesh = mmi.multimesh
	mm.instance_count = RET_SAMPLES
	for i in range(RET_SAMPLES):
		var p: Vector3 = _ret_curve(float(i) / float(RET_SAMPLES - 1), phase, span)
		if step > 0.0:
			p = Vector3(round(p.x / step) * step, round(p.y / step) * step, 0.0)
		p.z = z
		mm.set_instance_transform(i, Transform3D(Basis(), p))
	_ret_root().add_child(mmi)


## A deterministic hand — no randf anywhere in the record path, so five variants differ by
## the axis and by nothing else.
func _ret_curve(u: float, phase: float, span: float) -> Vector3:
	var a: float = u * TAU * 1.15 + phase
	var x: float = span * ((u - 0.5) * 1.85 + 0.22 * sin(a * 1.6))
	var y: float = span * 0.80 * sin(a * 0.95 + phase * 1.3) * (0.55 + 0.45 * sin(a * 0.42))
	return Vector3(clampf(x, -span, span), clampf(y, -span, span), 0.0)


func _ret_mm(nm: String, mat: Material) -> MultiMeshInstance3D:
	var mmi := MultiMeshInstance3D.new()
	mmi.name = nm
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var dot := SphereMesh.new()
	dot.radius = RET_DOT_R
	dot.height = RET_DOT_R * 2.0
	dot.radial_segments = 6
	dot.rings = 3
	mm.mesh = dot
	mm.instance_count = 0
	mmi.multimesh = mm
	mmi.material_override = mat
	return mmi


func _ret_emissive(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m
