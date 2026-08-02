extends Node3D

# @identity
# essence: snap(position) = round(position / grid_size) * grid_size — discretise continuous space
# desire: learner feels the tension between analog hand movement and digital quantized grid
# critical_parameter: grid_size — the quantization step that snaps position to nearest lattice point
# triggers: moving the grabbed sphere — each snap is a click, a discrete decision
# emerges: the grid as a constraint that makes space countable; infinite positions become finite choices
# needs: [has Label3D [has], grabbable sphere [has], missing grid_size VR slider]
# relationships: sibling to draw_dot (continuous vs discrete); foundation for voxel/pixel thinking
# truth: quantization is a choice about what differences are worth keeping

## Grab sphere point that snaps to grid and leaves a trail

@export var grab_point_path: NodePath = NodePath("GrabPoint")
@export var draw_sphere_path: NodePath = NodePath("GrabPoint/DrawSphere")

# Grid snapping
@export var snap_to_grid: bool = true
@export var grid_size: float = 1.0
@export var snap_on_drop: bool = true

# Trail settings
@export var trail_color: Color = Color(0.2, 1.0, 0.6, 1.0)
@export var trail_max_points: int = 4096
@export var min_segment_distance: float = 0.005
@export var record_only_when_grabbed: bool = true
@export var auto_clear_on_drop: bool = false

# Reference frame
@export var reference_frame_position: Vector3 = Vector3(0, 0, 0.2)
@export var reference_frame_size: float = 0.5
@export var show_reference_frame: bool = false

## AXIS — WHAT A MARK PERSISTS AS once the hand that made it has gone. Adopted word for
## word from [[mystic_writing_pad]] and shared with [[draw_dot]], [[draw_triangle_faces]]
## and [[interactive_point_origin_force]]. This artifact is the one that already had an
## opinion: snapping is a claim that a position must be LEGAL before it counts, and
## `lattice` is that claim taking its place among four rivals rather than being the only
## thing on offer. The ruling is drawn at this artifact's own grid_size, so the axis shows
## the quantum the code actually rounds to.
##
##   none      the legacy lineage, byte for byte. Nothing stands here: at rest the artifact
##             shows no mark, because it keeps none until a hand makes one
##   trace     one stroke in the trail colour, left exactly where the hand went — the raw
##             analogue path, admitted whole, nothing rounded away
##   lattice   the ruling itself, at grid_size, with the same path snapped onto it. The
##             argument the token's name already makes: legal positions, countable space
##   archive   nine paths at once, all kept, all bright. Quantisation is a choice about what
##             differences are worth keeping; this is the refusal to choose
##   wax       a dark slab behind a pale sheet, the paths sunk between them and fading with
##             age. The record is kept where rounding cannot reach it
@export var retention: String = "none"
const RETENTIONS: PackedStringArray = ["none", "trace", "lattice", "archive", "wax"]

# Data Table Display
@export_group("Data Table")
@export var show_data_table: bool = true
@export var data_table_height_offset: float = -0.35
@export var data_table_color: Color = Color(0.9, 0.95, 1.0, 1.0)
@export var data_table_font_size: int = 20
@export var data_table_update_interval: float = 0.15  # Seconds between updates

var _data_table_label: Label3D
var _data_table_timer: float = 0.0
var _total_trail_length: float = 0.0

var _grab_point: Node3D
var _draw_sphere: Node3D
var _trail_mesh: ImmediateMesh
var _trail_instance: MeshInstance3D
var _trail_points: Array[Vector3] = []
var _last_global_position: Vector3 = Vector3.ZERO
var _reference_frame: MeshInstance3D

func _ready() -> void:
	# Prevent gravity gun from affecting drag points
	add_to_group("no_gravity_gun")

	_grab_point = get_node_or_null(grab_point_path)
	_draw_sphere = get_node_or_null(draw_sphere_path)

	if not _grab_point:
		push_warning("GrabSpherePointSnap: Missing grab point in scene.")
		set_process(false)
		return

	# Use grab point position if no draw sphere
	if not _draw_sphere:
		_draw_sphere = _grab_point

	_setup_trail()
	if show_reference_frame:
		_setup_reference_frame()
	_setup_data_table()
	_last_global_position = _draw_sphere.global_position
	set_process(true)

	# Connect to grab point signals
	if _grab_point.has_signal("dropped"):
		_grab_point.dropped.connect(_on_grab_point_dropped)
	if _grab_point.has_signal("picked_up"):
		_grab_point.picked_up.connect(_on_grab_point_picked_up)

	# RETENTION last, so every child added above keeps its index. "none" is the legacy
	# lineage and adds nothing at all.
	_ret_read_config()
	_ret_build()

func _setup_trail() -> void:
	_trail_mesh = ImmediateMesh.new()
	_trail_instance = MeshInstance3D.new()
	_trail_instance.name = "SnapTrail"
	_trail_instance.mesh = _trail_mesh

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = trail_color
	material.emission_enabled = true
	material.emission = trail_color
	material.emission_energy_multiplier = 1.5
	_trail_instance.material_override = material

	# Trail in global space
	_trail_instance.set_as_top_level(true)
	add_child(_trail_instance)

func _setup_reference_frame() -> void:
	var frame_mesh := ImmediateMesh.new()
	_reference_frame = MeshInstance3D.new()
	_reference_frame.name = "ReferenceFrame"
	_reference_frame.mesh = frame_mesh
	_reference_frame.position = reference_frame_position

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.7, 0.7, 0.7, 0.8)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_reference_frame.material_override = material

	var half_size := reference_frame_size / 2.0

	frame_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	# Square frame
	frame_mesh.surface_add_vertex(Vector3(-half_size, half_size, 0))
	frame_mesh.surface_add_vertex(Vector3(half_size, half_size, 0))
	frame_mesh.surface_add_vertex(Vector3(-half_size, -half_size, 0))
	frame_mesh.surface_add_vertex(Vector3(half_size, -half_size, 0))
	frame_mesh.surface_add_vertex(Vector3(-half_size, -half_size, 0))
	frame_mesh.surface_add_vertex(Vector3(-half_size, half_size, 0))
	frame_mesh.surface_add_vertex(Vector3(half_size, -half_size, 0))
	frame_mesh.surface_add_vertex(Vector3(half_size, half_size, 0))
	frame_mesh.surface_end()

	add_child(_reference_frame)

func _process(delta: float) -> void:
	if not _draw_sphere:
		return

	var current_global = _draw_sphere.global_position

	# Only record when grabbed
	if record_only_when_grabbed and _grab_point and _grab_point.has_method("is_picked_up"):
		if not _grab_point.is_picked_up():
			_last_global_position = current_global
			# Hide data table when not grabbed
			if _data_table_label:
				_data_table_label.visible = false
			return

	# Snap current position to grid for tracing
	var snapped_global = snap_position_to_grid(current_global)

	# Minimum distance check (using snapped positions to ensure distinct grid points)
	if snapped_global.distance_to(_last_global_position) < min_segment_distance:
		return
	
	# If strict grid tracing is desired, we ensure we only add points that are exactly on grid nodes
	# But maybe they want lines between grid nodes?
	# Let's assume connecting grid points is what "trace the grid means"
	
	# Track trail length
	_total_trail_length += snapped_global.distance_to(_last_global_position)

	_last_global_position = snapped_global
	_trail_points.append(snapped_global)

	if _trail_points.size() > trail_max_points:
		_trail_points.pop_front()

	_rebuild_trail()

	# Update data table (throttled)
	_data_table_timer += delta
	if _data_table_timer >= data_table_update_interval:
		_data_table_timer = 0.0
		_update_data_table()

	# Optional: visually snap the draw sphere if we want the object to look like it's on grid?
	# _draw_sphere.global_position = snapped_global # This might jitter against hand smoothness
	# Better to let the trail be the grid trace.

func _rebuild_trail() -> void:
	_trail_mesh.clear_surfaces()
	if _trail_points.size() < 2:
		return

	_trail_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for point in _trail_points:
		_trail_mesh.surface_add_vertex(point)
	_trail_mesh.surface_end()

func snap_position_to_grid(pos: Vector3) -> Vector3:
	if not snap_to_grid:
		return pos
	return Vector3(
		round(pos.x / grid_size) * grid_size,
		round(pos.y / grid_size) * grid_size,
		round(pos.z / grid_size) * grid_size
	)

func _on_grab_point_dropped(_pickable) -> void:
	if auto_clear_on_drop:
		clear_trail()

	# Snap to grid on drop
	if snap_on_drop and _grab_point:
		var snapped_pos = snap_position_to_grid(_grab_point.global_position)
		_grab_point.global_position = snapped_pos
		print("GrabSpherePointSnap: Snapped to grid at %s" % snapped_pos)

		# Add snapped position to trail
		_trail_points.append(snapped_pos)
		_rebuild_trail()

func _on_grab_point_picked_up(_pickable) -> void:
	# Record starting position when picked up
	if _grab_point:
		_last_global_position = _grab_point.global_position

func clear_trail() -> void:
	_trail_points.clear()
	_total_trail_length = 0.0
	if _trail_mesh:
		_trail_mesh.clear_surfaces()
	if _draw_sphere:
		_last_global_position = _draw_sphere.global_position
	if _data_table_label:
		_data_table_label.visible = false

func get_trail_points() -> Array[Vector3]:
	return _trail_points.duplicate()

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
	var snapped_pos = snap_position_to_grid(current_pos)
	var point_count = _trail_points.size()

	# Build table text with two columns: Point (raw) | Snap (grid)
	var table_text = "GRID TRACE DATA\n"
	table_text += "Points: %d  Length: %.2f m\n" % [point_count, _total_trail_length]
	table_text += "─────────────────────────────────\n"
	table_text += "  POINT (raw)      │  SNAP (grid)\n"
	table_text += "─────────────────────────────────\n"

	# Show last 10 points with both raw and snapped values
	var start_idx = max(0, _trail_points.size() - 10)
	for i in range(start_idx, _trail_points.size()):
		var pt = _trail_points[i]
		var snapped = snap_position_to_grid(pt)
		var grid = snapped / grid_size
		table_text += "(%.1f,%.1f,%.1f) │ (%d,%d,%d)\n" % [pt.x, pt.y, pt.z, int(grid.x), int(grid.y), int(grid.z)]

	_data_table_label.text = table_text
	_data_table_label.visible = true

	# Position near trail start, offset to the side and forward
	var start_pos = _trail_points[0]
	_data_table_label.global_position = start_pos + Vector3(0.15, data_table_height_offset - 0.1, 0.2)


# ── RETENTION ────────────────────────────────────────────────────────────────
# One axis, five claims about whether space remembers being touched, shared word for word
# with mystic_writing_pad, draw_dot, draw_triangle_faces and interactive_point_origin_force.
# Appended LAST: the trail, the reference frame and the data table are built above and none
# of them move.
#
# APPEARANCE ONLY. snap_position_to_grid, snap_on_drop and the trail recording are not
# touched by any value. `lattice` DRAWS the artifact's quantum; it does not change it, and
# the ruling is read off grid_size rather than replacing it.

const RET_DOT_R := 0.007
const RET_SAMPLES := 50
const RET_PLANE_Z := -0.12          # the depth the DrawSphere writes at

var _ret_node: Node3D = null


func _ret_read_config() -> void:
	if has_meta("config_retention"):
		var r: String = str(get_meta("config_retention")).strip_edges().to_lower()
		retention = r if RETENTIONS.has(r) else retention


## Gated on the key: a config that says nothing about retention gets no work at all.
func apply_grid_config(config_data: Dictionary) -> void:
	if not config_data.has("retention"):
		return
	var r: String = str(config_data["retention"]).strip_edges().to_lower()
	if not RETENTIONS.has(r) or r == retention:
		return
	retention = r
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


func _ret_root() -> Node3D:
	if not is_instance_valid(_ret_node):
		_ret_node = Node3D.new()
		_ret_node.name = "RetentionRecord"
		_ret_node.position = Vector3(0, 0, RET_PLANE_Z)
		add_child(_ret_node)
	return _ret_node


## The ruling step — this artifact's OWN quantum, clamped only so a grid_size of 1 m does
## not draw a single node and a grid_size of 1 mm does not draw ten thousand.
func _ret_step() -> float:
	return clampf(grid_size, 0.022, 0.075)


## TRACE — the analogue path, admitted whole. Nothing rounded, nothing dropped.
func _ret_trace() -> void:
	_ret_stroke(0.77, 0.0, trail_color, 1.7, 0.0)


## LATTICE — the ruling first, at grid_size, then the same hand snapped onto it. Regular
## nodes where every other value shows wander; the path becomes a stair.
func _ret_lattice() -> void:
	var span: float = 0.16
	var step: float = _ret_step()
	var n: int = int(span * 2.0 / step) + 1
	var grid := _ret_mm("LatticeNodes", _ret_emissive(Color(0.52, 0.62, 0.70), 0.5))
	var gm: MultiMesh = grid.multimesh
	gm.instance_count = n * n
	var small: Basis = Basis.IDENTITY.scaled(Vector3.ONE * 0.55)
	var k: int = 0
	for cx in range(n):
		for cy in range(n):
			gm.set_instance_transform(k, Transform3D(small,
				Vector3(-span + float(cx) * step, -span + float(cy) * step, 0.0)))
			k += 1
	_ret_root().add_child(grid)
	_ret_stroke(0.77, 0.004, trail_color, 1.7, step)


## ARCHIVE — nine paths kept at once, none dimmed. Everything worth keeping was kept, and
## now no single decision is legible.
func _ret_archive() -> void:
	for i in range(9):
		_ret_stroke(0.77 + 0.83 * float(i), 0.003 * float(i), trail_color, 1.4, 0.0)


## WAX — the Wunderblock construction, borrowed from mystic_writing_pad: matte dark slab,
## pale translucent sheet, the paths sunk between them and fading with age.
func _ret_wax() -> void:
	var span: float = 0.17
	var root: Node3D = _ret_root()

	var slab := MeshInstance3D.new()
	slab.name = "WaxSlab"
	var sm := BoxMesh.new()
	sm.size = Vector3(span * 2.0, span * 2.0, 0.012)
	slab.mesh = sm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.10, 0.085, 0.095)
	smat.roughness = 0.95
	smat.metallic = 0.0
	slab.material_override = smat
	slab.position = Vector3(0, 0, -0.011)
	root.add_child(slab)

	var warm := Color(0.95, 0.62, 0.35)
	for i in range(5):
		var f: float = float(5 - i) / 5.0
		var c: Color = warm.lerp(Color(0.10, 0.085, 0.095), 1.0 - f)
		_ret_stroke(0.77 + 1.7 * float(i), -0.003 + 0.0013 * float(i), c, 0.45 + 1.1 * f, 0.0)

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
	sheet.position = Vector3(0, 0, 0.009)
	root.add_child(sheet)


## One dot-stroke in the record plane. `step` > 0 snaps it onto the ruling — the same
## rounding snap_position_to_grid does, done to a picture rather than to the live hand.
func _ret_stroke(phase: float, z: float, c: Color, energy: float, step: float) -> void:
	var span: float = 0.15
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
