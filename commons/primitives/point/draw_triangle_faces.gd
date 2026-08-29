extends Node3D

# @identity
# essence: fan_triangulate(loop) → colored mesh face — closed point loops become surfaces
# desire: learner discovers that faces are just organized points — drop points, close the loop, get geometry
# critical_parameter: the loop-closing gesture — dropping the sphere near the first point closes and fills
# triggers: dropping the sphere — each drop places a point; proximity to first point triggers triangulation
# emerges: the mesh as a collection of closed loops; surfaces as a social contract between points
# needs: [has Label3D [has], grabbable sphere [has], missing undo control]
# relationships: extends draw_dot into 2D; prerequisite understanding for triangle, quad, and all mesh faces
# truth: a surface is not a thing — it is an agreement among boundary points

## Draw triangle faces by placing points and closing loops

@export var grab_point_path: NodePath = NodePath("GrabPoint")
@export var draw_sphere_path: NodePath = NodePath("GrabPoint/DrawSphere")

# Drawing mode
@export var continuous_drawing: bool = true  # Keep drawing after placing points (no need to re-grab)

# Grid snapping
@export var snap_to_grid: bool = true
@export var grid_size: float = 0.1
@export var point_snap_distance: float = 0.15  # Distance to snap to existing points

# Haptic feedback
@export var haptic_snap_intensity: float = 0.5
@export var haptic_snap_duration: float = 0.1
@export var haptic_triangle_intensity: float = 0.8
@export var haptic_triangle_duration: float = 0.2

# Visual settings
@export var point_indicator_size: float = 0.025  # Grab sphere size
@export var line_color: Color = Color(0.2, 1.0, 0.6, 1.0)
@export var active_line_color: Color = Color(1.0, 0.8, 0.2, 1.0)
@export var point_color: Color = Color(0.2, 0.8, 0.3, 0.7)
@export var snap_indicator_color: Color = Color(1.0, 0.3, 0.3, 1.0)
@export var editable_points: bool = true  # Allow grabbing and moving points

## HOLD TO DRAW (2026-08-29, Palle: "define a point every second when you hold it
## so it create meches faster").
##
## Until now a point cost a whole grab: pick up, move, RELEASE — one point per
## release, and a twelve-point outline is twelve grabs. Held, the tool now lays a
## point on a timer, so you draw a path the way you would draw a line, by moving
## your hand. Set to 0 to get the old release-per-point behaviour back.
@export var hold_place_seconds: float = 1.0
## AND THE HAND MUST HAVE MOVED. A timer alone lays a point on top of the last
## one every second while you stand still, and the snap logic then refuses each
## of them in silence (a point cannot snap to the point just placed) — a tool
## that looks broken because it is politely doing nothing. A point is laid only
## once the hand has travelled this far from the last one, so a still hand draws
## nothing and a moving hand draws a trail. Default is the snap radius, which is
## already this artifact's idea of "the same place".
@export var hold_place_min_travel: float = 0.15

# Preload grab sphere scene for editable points (same as animatedcubebuilder)
const GRAB_SPHERE_SCENE = preload("res://commons/primitives/point/grab_sphere_point.tscn")

# Triangle mesh settings
@export var triangle_colors: Array[Color] = [
	Color(1.0, 0.2, 0.5, 0.6),  # Pink
	Color(0.2, 0.5, 1.0, 0.6),  # Blue
	Color(0.5, 1.0, 0.2, 0.6),  # Green
	Color(1.0, 0.8, 0.2, 0.6),  # Yellow
	Color(0.8, 0.2, 1.0, 0.6),  # Purple
]
@export var wireframe_color: Color = Color(0.9, 0.9, 0.9, 0.8)

## AXIS — WHAT A MARK PERSISTS AS once the hand that made it has gone. Adopted word for
## word from [[mystic_writing_pad]] and shared with [[draw_dot]],
## [[grab_sphere_point_snap]] and [[interactive_point_origin_force]]. Here the mark is a
## LOOP, and this artifact's own truth is that a surface is not a thing but an agreement
## among boundary points — so each value is a different answer to how long an agreement
## holds after the parties have gone.
##
##   none      the legacy lineage, byte for byte. Nothing stands here: at rest there are no
##             points, no path and no faces, because nobody has agreed to anything yet
##   trace     one open path with its points on it — the loop unclosed. The marks are kept
##             and the agreement is not made; a boundary with no surface
##   lattice   the ruling at grid_size with the path snapped onto it. A vertex counts only
##             at a legal position, so the agreement is between LAWFUL points or none
##   archive   six closed faces at once, filled, overlapping, every colour in the palette.
##             Every agreement ever made, kept, until no single one can be read
##   wax       a dark slab behind a pale sheet with faint warm loops sunk between them —
##             the faces are gone from the surface and the boundary is still down there
@export var retention: String = "none"
const RETENTIONS: PackedStringArray = ["none", "trace", "lattice", "archive", "wax"]

var _grab_point: Node3D
var _draw_sphere: Node3D
var _is_grabbed: bool = false

# Point tracking
var placed_points: Array[Vector3] = []
var point_indicators: Array[Node3D] = []  # Can be MeshInstance3D or pickable RigidBody3D
var current_path: Array[int] = []  # Indices into placed_points

# Line visualization
var line_mesh: ImmediateMesh
var line_instance: MeshInstance3D
var active_line_mesh: ImmediateMesh
var active_line_instance: MeshInstance3D

# Triangle tracking
var completed_triangles: Array[Dictionary] = []  # {points: Array[int], mesh: MeshInstance3D}
var triangle_color_index: int = 0

# Snap indicator
var snap_indicator: MeshInstance3D
var snap_target_index: int = -1
var _draw_ring: MeshInstance3D
var _ring_pulse_time: float = 0.0
var _previous_snap_target: int = -1
var _hold_timer: float = 0.0            # seconds held since the last auto point
var _auto_placed: int = 0               # how many this grab laid without a release

func _ready() -> void:
	_grab_point = get_node_or_null(grab_point_path)
	_draw_sphere = get_node_or_null(draw_sphere_path)
	_draw_ring = get_node_or_null("GrabPoint/DrawRing")

	if not _grab_point:
		push_warning("DrawTriangleFaces: Missing grab point in scene.")
		set_process(false)
		return

	if not _draw_sphere:
		_draw_sphere = _grab_point

	_setup_line_visualization()
	_setup_snap_indicator()

	# Connect to grab point signals
	if _grab_point.has_signal("dropped"):
		_grab_point.dropped.connect(_on_grab_point_dropped)
	if _grab_point.has_signal("picked_up"):
		_grab_point.picked_up.connect(_on_grab_point_picked_up)

	set_process(true)
	print("DrawTriangleFaces: Ready! Pick up the sphere and start drawing.")

	# RETENTION last, so every child added above keeps its index. "none" is the legacy
	# lineage and adds nothing at all.
	_ret_read_config()
	_ret_build()

func _setup_line_visualization() -> void:
	# Completed lines
	line_mesh = ImmediateMesh.new()
	line_instance = MeshInstance3D.new()
	line_instance.name = "Lines"
	line_instance.mesh = line_mesh
	line_instance.set_as_top_level(true)
	
	var line_material := StandardMaterial3D.new()
	line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line_material.albedo_color = line_color
	line_material.emission_enabled = true
	line_material.emission = line_color
	line_material.roughness = 1.0
	line_material.metallic = 0.0
	line_material.metallic_specular = 0.0
	line_material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	line_instance.material_override = line_material
	add_child(line_instance)
	
	# Active drawing line
	active_line_mesh = ImmediateMesh.new()
	active_line_instance = MeshInstance3D.new()
	active_line_instance.name = "ActiveLine"
	active_line_instance.mesh = active_line_mesh
	active_line_instance.set_as_top_level(true)
	
	var active_material := StandardMaterial3D.new()
	active_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	active_material.albedo_color = active_line_color
	active_material.emission_enabled = true
	active_material.emission = active_line_color
	active_material.roughness = 1.0
	active_material.metallic = 0.0
	active_material.metallic_specular = 0.0
	active_material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	active_line_instance.material_override = active_material
	add_child(active_line_instance)

func _setup_snap_indicator() -> void:
	snap_indicator = MeshInstance3D.new()
	snap_indicator.name = "SnapIndicator"
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = point_snap_distance * 0.5
	sphere_mesh.height = point_snap_distance
	snap_indicator.mesh = sphere_mesh
	
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = snap_indicator_color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = snap_indicator_color
	material.roughness = 1.0
	material.metallic = 0.0
	material.metallic_specular = 0.0
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	snap_indicator.material_override = material
	snap_indicator.visible = false
	snap_indicator.set_as_top_level(true)
	add_child(snap_indicator)

func _process(delta: float) -> void:
	# Pulse the ring when grabbed
	if _draw_ring and _is_grabbed:
		_ring_pulse_time += delta * 3.0
		var pulse = 0.8 + sin(_ring_pulse_time) * 0.2
		_draw_ring.scale = Vector3.ONE * pulse

	if not _draw_sphere or not _is_grabbed:
		return

	var current_pos = _draw_sphere.global_position
	var snapped_pos = snap_position_to_grid(current_pos)

	# Check if near an existing point
	snap_target_index = _find_nearby_point(snapped_pos)

	# Haptic feedback when entering snap range
	if snap_target_index >= 0 and snap_target_index != _previous_snap_target:
		if snap_target_index != _get_last_point_in_path():
			_trigger_haptic(haptic_snap_intensity * 0.5, haptic_snap_duration * 0.5)
	_previous_snap_target = snap_target_index

	# Update snap indicator
	if snap_target_index >= 0 and snap_target_index != _get_last_point_in_path():
		snap_indicator.global_position = placed_points[snap_target_index]
		snap_indicator.visible = true
		# Pulse snap indicator
		var pulse = 1.0 + sin(_ring_pulse_time * 2.0) * 0.15
		snap_indicator.scale = Vector3.ONE * pulse
	else:
		snap_indicator.visible = false

	# HOLD TO DRAW: a point on the timer, once the hand has moved off the last one.
	# Placed here rather than in a separate tick because this is where the snapped
	# position and the snap target have already been worked out for this frame —
	# a second opinion about where the hand is would be a second implementation.
	if hold_place_seconds > 0.0:
		_hold_timer += delta
		if _hold_timer >= hold_place_seconds and _travelled_enough(snapped_pos):
			_place_or_snap(snapped_pos)
			_auto_placed += 1
			_trigger_haptic(haptic_snap_intensity, haptic_snap_duration)

	# Update active line preview
	_update_active_line_preview(snapped_pos)

## Has the hand left the last point behind? An empty path always has, so the
## first point of a drawing lands the moment the timer comes round.
func _travelled_enough(pos: Vector3) -> bool:
	var last := _get_last_point_in_path()
	if last < 0 or last >= placed_points.size():
		return true
	return pos.distance_to(placed_points[last]) >= maxf(hold_place_min_travel, 0.001)


func _update_active_line_preview(current_pos: Vector3) -> void:
	active_line_mesh.clear_surfaces()
	
	if current_path.is_empty():
		return
	
	var last_point_index = current_path[-1]
	var last_point = placed_points[last_point_index]
	
	active_line_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	active_line_mesh.surface_add_vertex(last_point)
	
	# If snapping, show line to snap target
	if snap_target_index >= 0 and snap_target_index != last_point_index:
		active_line_mesh.surface_add_vertex(placed_points[snap_target_index])
	else:
		active_line_mesh.surface_add_vertex(current_pos)
	
	active_line_mesh.surface_end()

func _on_grab_point_picked_up(_pickable) -> void:
	_is_grabbed = true
	_hold_timer = 0.0
	_auto_placed = 0

	# If path is empty but we have points, allow starting from any existing point
	if current_path.is_empty() and not placed_points.is_empty():
		# Find nearest point to start from
		var nearest_idx = _find_nearby_point(_draw_sphere.global_position)
		if nearest_idx >= 0:
			current_path.append(nearest_idx)
			print("DrawTriangleFaces: Continuing from point %d" % nearest_idx)
		else:
			print("DrawTriangleFaces: Grabbed! Move near a point or place a new one.")
	else:
		print("DrawTriangleFaces: Grabbed! Continue drawing.")

## Lay a point here, or close onto the one already here. The single path both a
## RELEASE and the hold timer go through, so the two cannot drift apart.
func _place_or_snap(snapped_pos: Vector3) -> void:
	var nearby_index := _find_nearby_point(snapped_pos)
	if nearby_index >= 0:
		_handle_snap_to_point(nearby_index)
	else:
		_create_new_point(snapped_pos)
	_rebuild_lines()
	_hold_timer = 0.0


func _on_grab_point_dropped(_pickable) -> void:
	if not _is_grabbed:
		return

	var drop_pos = _draw_sphere.global_position
	_place_or_snap(snap_position_to_grid(drop_pos))

	# In continuous mode, keep drawing active
	if continuous_drawing:
		# Stay in grabbed state - drawing continues
		# Just clear the snap indicator, keep active line showing
		snap_indicator.visible = false
		print("DrawTriangleFaces: point placed (%d laid by holding this grab), continue drawing..." % _auto_placed)
	else:
		# Standard mode - stop drawing until next pickup
		_is_grabbed = false
		active_line_mesh.clear_surfaces()
		snap_indicator.visible = false

func _handle_snap_to_point(point_index: int) -> void:
	var last_point = _get_last_point_in_path()

	# Don't snap to the same point we just placed
	if point_index == last_point:
		print("DrawTriangleFaces: Cannot snap to the last placed point.")
		return

	# Add this point to current path
	current_path.append(point_index)

	# Haptic feedback for snap
	_trigger_haptic(haptic_snap_intensity, haptic_snap_duration)

	# Check if we've closed a loop with at least 3 points
	if _is_loop_closed():
		var loop_size = current_path.size()
		print("DrawTriangleFaces: Loop closed with %d points!" % loop_size)

		# Stronger haptic for triangle completion
		_trigger_haptic(haptic_triangle_intensity, haptic_triangle_duration)
		_play_triangle_sound()

		# Create triangles from the closed loop
		_create_triangles_from_path()

		# Start new path from this point
		current_path.clear()
		current_path.append(point_index)

	print("DrawTriangleFaces: Snapped to point %d" % point_index)

func _create_new_point(position: Vector3) -> void:
	var point_index = placed_points.size()
	placed_points.append(position)
	current_path.append(point_index)

	if editable_points:
		_create_editable_point(point_index, position)
	else:
		_create_static_point(point_index, position)

	print("DrawTriangleFaces: Created point %d at %v" % [point_index, position])

func _create_editable_point(point_index: int, position: Vector3) -> void:
	# Create grab sphere point (same as animatedcubebuilder)
	var handle = GRAB_SPHERE_SCENE.instantiate()
	handle.name = "Point_%d" % point_index
	handle.position = position
	handle.alter_freeze = false
	handle.freeze = true
	handle.set_meta("point_index", point_index)

	# Scale the grab sphere to match point_indicator_size
	var scale_factor = point_indicator_size / 0.05  # grab_sphere default is ~0.05
	handle.scale = Vector3.ONE * scale_factor

	# Add to tree
	add_child(handle)
	if owner:
		handle.owner = owner

	# Connect signals for editing
	if handle.has_signal("picked_up"):
		handle.picked_up.connect(_on_edit_point_picked_up.bind(point_index))
	if handle.has_signal("dropped"):
		handle.dropped.connect(_on_edit_point_dropped.bind(point_index))

	point_indicators.append(handle)

func _create_static_point(point_index: int, position: Vector3) -> void:
	# Create non-editable visual indicator
	var indicator = MeshInstance3D.new()
	indicator.name = "Point_%d" % point_index
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = point_indicator_size
	sphere_mesh.height = point_indicator_size * 2
	indicator.mesh = sphere_mesh

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = point_color
	material.emission_enabled = true
	material.emission = point_color
	material.roughness = 1.0
	material.metallic = 0.0
	material.metallic_specular = 0.0
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	indicator.material_override = material

	indicator.set_as_top_level(true)
	add_child(indicator)
	indicator.global_position = position
	point_indicators.append(indicator)

func _on_edit_point_picked_up(_pickable, point_index: int) -> void:
	print("DrawTriangleFaces: Editing point %d" % point_index)

func _on_edit_point_dropped(_pickable, point_index: int) -> void:
	# Update the point position in our array
	var new_pos = point_indicators[point_index].position
	if snap_to_grid:
		new_pos = snap_position_to_grid(new_pos)
		point_indicators[point_index].position = new_pos

	placed_points[point_index] = new_pos
	print("DrawTriangleFaces: Point %d moved to %v" % [point_index, new_pos])

	# Rebuild all visuals
	_rebuild_lines()
	_rebuild_all_triangles()

func _find_nearby_point(position: Vector3) -> int:
	for i in range(placed_points.size()):
		var dist = position.distance_to(placed_points[i])
		if dist < point_snap_distance:
			return i
	return -1

func _get_last_point_in_path() -> int:
	if current_path.is_empty():
		return -1
	return current_path[-1]

func _is_loop_closed() -> bool:
	if current_path.size() < 3:
		return false
	
	# Check if the last point equals an earlier point in the path
	var last_point = current_path[-1]
	for i in range(current_path.size() - 1):
		if current_path[i] == last_point:
			return true
	
	return false

func _create_triangles_from_path() -> void:
	if current_path.size() < 3:
		return
	
	# Find where the loop closes
	var last_point = current_path[-1]
	var loop_start_index = -1
	
	for i in range(current_path.size() - 1):
		if current_path[i] == last_point:
			loop_start_index = i
			break
	
	if loop_start_index < 0:
		return
	
	# Extract the loop (from loop_start_index to end)
	var loop_points: Array[int] = []
	for i in range(loop_start_index, current_path.size()):
		loop_points.append(current_path[i])
	
	# Remove duplicate at the end
	if loop_points.size() > 1 and loop_points[0] == loop_points[-1]:
		loop_points.pop_back()
	
	if loop_points.size() < 3:
		return
	
	print("DrawTriangleFaces: Creating triangles from %d-point loop" % loop_points.size())
	
	# Create mesh instance for this triangle group
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Triangle_%d" % completed_triangles.size()
	mesh_instance.set_as_top_level(true)
	add_child(mesh_instance)
	
	# Build the mesh using fan triangulation
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Get triangle color
	var tri_color = triangle_colors[triangle_color_index % triangle_colors.size()]
	triangle_color_index += 1
	
	# Fan triangulation from first point
	var first_point = placed_points[loop_points[0]]
	
	for i in range(1, loop_points.size() - 1):
		var v0 = first_point
		var v1 = placed_points[loop_points[i]]
		var v2 = placed_points[loop_points[i + 1]]
		
		# Calculate normal
		var edge1 = v1 - v0
		var edge2 = v2 - v0
		var normal = edge1.cross(edge2).normalized()
		
		# Front face
		st.set_normal(normal)
		st.set_color(tri_color)
		st.set_uv(Vector2(0, 0))
		st.add_vertex(v0)
		
		st.set_normal(normal)
		st.set_color(tri_color)
		st.set_uv(Vector2(1, 0))
		st.add_vertex(v1)
		
		st.set_normal(normal)
		st.set_color(tri_color)
		st.set_uv(Vector2(0.5, 1))
		st.add_vertex(v2)
		
		# Back face (double-sided)
		st.set_normal(-normal)
		st.set_color(tri_color)
		st.set_uv(Vector2(0, 0))
		st.add_vertex(v0)
		
		st.set_normal(-normal)
		st.set_color(tri_color)
		st.set_uv(Vector2(0.5, 1))
		st.add_vertex(v2)
		
		st.set_normal(-normal)
		st.set_color(tri_color)
		st.set_uv(Vector2(1, 0))
		st.add_vertex(v1)
	
	mesh_instance.mesh = st.commit()
	
	# Apply material
	var material = StandardMaterial3D.new()
	material.albedo_color = tri_color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = tri_color * 0.5
	material.roughness = 1.0
	material.metallic = 0.0
	material.metallic_specular = 0.0
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_instance.material_override = material
	
	# Store completed triangle
	completed_triangles.append({
		"points": loop_points.duplicate(),
		"mesh": mesh_instance
	})
	
	print("DrawTriangleFaces: Created %d triangles from loop" % (loop_points.size() - 2))

func _rebuild_lines() -> void:
	line_mesh.clear_surfaces()

	if current_path.size() < 2:
		return

	line_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	for i in range(current_path.size() - 1):
		var p0 = placed_points[current_path[i]]
		var p1 = placed_points[current_path[i + 1]]
		line_mesh.surface_add_vertex(p0)
		line_mesh.surface_add_vertex(p1)

	line_mesh.surface_end()

func _rebuild_all_triangles() -> void:
	# Rebuild all triangle meshes with updated point positions
	for tri_data in completed_triangles:
		var loop_points: Array = tri_data.points
		var mesh_instance: MeshInstance3D = tri_data.mesh

		if loop_points.size() < 3:
			continue

		# Rebuild the mesh
		var st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)

		# Get the existing material color
		var tri_color = Color.WHITE
		if mesh_instance.material_override:
			tri_color = mesh_instance.material_override.albedo_color

		# Fan triangulation from first point
		var first_point = placed_points[loop_points[0]]

		for i in range(1, loop_points.size() - 1):
			var v0 = first_point
			var v1 = placed_points[loop_points[i]]
			var v2 = placed_points[loop_points[i + 1]]

			# Calculate normal
			var edge1 = v1 - v0
			var edge2 = v2 - v0
			var normal = edge1.cross(edge2).normalized()

			# Front face
			st.set_normal(normal)
			st.set_color(tri_color)
			st.add_vertex(v0)
			st.set_normal(normal)
			st.set_color(tri_color)
			st.add_vertex(v1)
			st.set_normal(normal)
			st.set_color(tri_color)
			st.add_vertex(v2)

			# Back face
			st.set_normal(-normal)
			st.set_color(tri_color)
			st.add_vertex(v0)
			st.set_normal(-normal)
			st.set_color(tri_color)
			st.add_vertex(v2)
			st.set_normal(-normal)
			st.set_color(tri_color)
			st.add_vertex(v1)

		mesh_instance.mesh = st.commit()

func snap_position_to_grid(pos: Vector3) -> Vector3:
	if not snap_to_grid:
		return pos
	return Vector3(
		round(pos.x / grid_size) * grid_size,
		round(pos.y / grid_size) * grid_size,
		round(pos.z / grid_size) * grid_size
	)

func clear_all() -> void:
	# Clear points
	for indicator in point_indicators:
		indicator.queue_free()
	point_indicators.clear()
	placed_points.clear()
	current_path.clear()
	
	# Clear triangles
	for tri_data in completed_triangles:
		tri_data.mesh.queue_free()
	completed_triangles.clear()
	triangle_color_index = 0
	
	# Clear lines
	line_mesh.clear_surfaces()
	active_line_mesh.clear_surfaces()
	
	print("DrawTriangleFaces: All cleared!")

func undo_last_point() -> void:
	if placed_points.is_empty():
		return

	# Remove last point indicator
	var last_indicator = point_indicators.pop_back()
	last_indicator.queue_free()

	# Remove from placed points
	placed_points.pop_back()

	# Remove from current path if it's there
	if not current_path.is_empty() and current_path[-1] == placed_points.size():
		current_path.pop_back()

	_rebuild_lines()
	print("DrawTriangleFaces: Undid last point")


func _trigger_haptic(intensity: float, duration: float) -> void:
	if not _grab_point:
		return

	# Find the hand holding this object
	var picker = _grab_point.get("picked_up_by") if _grab_point.has_method("get") else null
	if not picker:
		# Try alternative property names
		if "picked_up_by" in _grab_point:
			picker = _grab_point.picked_up_by

	if picker and picker.has_method("trigger_haptic_pulse"):
		picker.trigger_haptic_pulse("haptic", intensity, duration, 0.0, 0.0)


func _play_triangle_sound() -> void:
	if not has_node("/root/SoundBank"):
		return

	var sound_bank = get_node("/root/SoundBank")
	var sound_stream = sound_bank.get_sound("AudioSynthesizer.COIN_COLLECT")

	if not sound_stream:
		sound_stream = sound_bank.get_sound("AudioSynthesizer.BLIP_SELECT")

	if not sound_stream:
		return

	var player = AudioStreamPlayer3D.new()
	player.stream = sound_stream
	player.volume_db = -3.0
	player.max_distance = 10.0
	player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_LOGARITHMIC
	add_child(player)
	player.global_position = _draw_sphere.global_position if _draw_sphere else global_position

	player.finished.connect(player.queue_free)
	player.play()


func get_stats() -> Dictionary:
	return {
		"points": placed_points.size(),
		"triangles": completed_triangles.size(),
		"current_path_length": current_path.size()
	}


# ── RETENTION ────────────────────────────────────────────────────────────────
# One axis, five claims about whether space remembers being touched, shared word for word
# with mystic_writing_pad, draw_dot, grab_sphere_point_snap and
# interactive_point_origin_force. Appended LAST: the lines, the active-line preview and the
# snap indicator are built above and none of them move.
#
# APPEARANCE ONLY. The record is a separate subtree and never enters placed_points,
# current_path or completed_triangles — undo, snapping, loop closing and fan triangulation
# behave exactly as they did, and a variant cannot be grabbed, edited or triangulated.

const RET_DOT_R := 0.009
const RET_PLANE_Z := -0.12          # the depth the DrawSphere writes at
const RET_RING_N := 5

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


## TRACE — the boundary kept, the agreement never made. An open path with its vertices
## standing on it: five points, four edges, no fill.
func _ret_trace() -> void:
	var pts: Array = _ret_ring(0.4, 0.135, 0.0)
	_ret_edges(pts, false, line_color, 0.009, 0.0)
	_ret_nodes(pts, point_color, 0.004)


## LATTICE — the ruling at grid_size, and the loop admitted only at its nodes. Regular
## pinpricks and right angles where every other value shows free wander.
func _ret_lattice() -> void:
	var span: float = 0.16
	# grid_size is this artifact's own quantum (0.1 in the shipped scene); it is clamped
	# only so a 1 m or 1 mm setting does not draw one bar or ten thousand.
	var step: float = clampf(grid_size, 0.04, 0.09)
	var n: int = int(span * 2.0 / step) + 1
	var rule: StandardMaterial3D = _ret_emissive(Color(0.46, 0.56, 0.66), 0.45)
	var root: Node3D = _ret_root()
	for c in range(n):
		var o: float = -span + float(c) * step
		root.add_child(_ret_bar(Vector3(0, o, -0.004), Vector3(span * 2.0, 0.0022, 0.0022), 0.0, rule))
		root.add_child(_ret_bar(Vector3(o, 0, -0.004), Vector3(span * 2.0, 0.0022, 0.0022), PI * 0.5, rule))
	var grid := _ret_mm("LatticeNodes", _ret_emissive(Color(0.62, 0.72, 0.80), 0.7), RET_DOT_R * 0.62)
	var gm: MultiMesh = grid.multimesh
	gm.instance_count = n * n
	var k: int = 0
	for cx in range(n):
		for cy in range(n):
			gm.set_instance_transform(k, Transform3D(Basis(),
				Vector3(-span + float(cx) * step, -span + float(cy) * step, -0.002)))
			k += 1
	root.add_child(grid)
	var pts: Array = _ret_ring(0.4, 0.135, step)
	_ret_edges(pts, true, line_color, 0.009, 0.004)
	_ret_nodes(pts, snap_indicator_color, 0.008)


## One thin ruling bar in the record plane, rotated about Z. Used for the lattice's ruled
## lines; the loop's own edges go through _ret_edges.
func _ret_bar(at: Vector3, size: Vector3, rot_z: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "Rule"
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = at
	mi.rotation = Vector3(0, 0, rot_z)
	mi.material_override = mat
	return mi


## ARCHIVE — six closed faces at once, filled, in every colour the palette holds. Each was
## a real agreement; kept all together they cancel into a single unreadable stack.
func _ret_archive() -> void:
	for i in range(6):
		var c: Color = line_color
		if triangle_colors.size() > 0:
			c = triangle_colors[i % triangle_colors.size()]
		var pts: Array = _ret_ring(0.4 + 0.61 * float(i), 0.085 + 0.011 * float(i), 0.0)
		_ret_face(pts, c, 0.002 * float(i))
		_ret_edges(pts, true, wireframe_color, 0.005, 0.002 * float(i) + 0.001)


## WAX — the Wunderblock construction, borrowed from mystic_writing_pad: matte dark slab,
## pale translucent sheet, four loops sunk between them and fading with age. Nothing is on
## the surface; the boundaries are all underneath it.
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
	for i in range(4):
		var f: float = float(4 - i) / 4.0
		var c: Color = warm.lerp(Color(0.10, 0.085, 0.095), 1.0 - f)
		var pts: Array = _ret_ring(0.4 + 1.37 * float(i), 0.075 + 0.018 * float(i), 0.0)
		_ret_edges(pts, true, c, 0.007, -0.003 + 0.0015 * float(i))
		_ret_nodes(pts, c, -0.003 + 0.0015 * float(i))

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


## A deterministic closed loop in the record plane — no randf anywhere in the record path,
## so five variants differ by the axis and by nothing else. `step` > 0 snaps the vertices
## onto the ruling, the same rounding snap_position_to_grid does to a live hand.
func _ret_ring(phase: float, radius: float, step: float) -> Array:
	var pts: Array = []
	for i in range(RET_RING_N):
		var a: float = TAU * float(i) / float(RET_RING_N) + phase
		var r: float = radius * (0.74 + 0.26 * sin(a * 2.0 + phase * 1.7))
		var p: Vector3 = Vector3(cos(a) * r, sin(a) * r, 0.0)
		if step > 0.0:
			p = Vector3(round(p.x / step) * step, round(p.y / step) * step, 0.0)
		pts.append(p)
	return pts


func _ret_edges(pts: Array, closed: bool, c: Color, t: float, z: float) -> void:
	var mat: StandardMaterial3D = _ret_emissive(c, 1.6)
	var last: int = pts.size() if closed else pts.size() - 1
	for i in range(last):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[(i + 1) % pts.size()]
		var d: Vector3 = b - a
		var length: float = d.length()
		if length < 0.0005:
			continue
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(length, t, t)
		mi.mesh = bm
		mi.position = (a + b) * 0.5 + Vector3(0, 0, z)
		mi.rotation = Vector3(0, 0, atan2(d.y, d.x))
		mi.material_override = mat
		_ret_root().add_child(mi)


func _ret_nodes(pts: Array, c: Color, z: float) -> void:
	var mmi := _ret_mm("Vertices", _ret_emissive(c, 1.8), RET_DOT_R)
	var mm: MultiMesh = mmi.multimesh
	mm.instance_count = pts.size()
	for i in range(pts.size()):
		var p: Vector3 = pts[i]
		mm.set_instance_transform(i, Transform3D(Basis(), Vector3(p.x, p.y, z)))
	_ret_root().add_child(mmi)


## Fan-triangulate a kept loop into a filled face — the same construction
## _create_triangles_from_path uses, run over the record's own points.
func _ret_face(pts: Array, c: Color, z: float) -> void:
	if pts.size() < 3:
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var v0: Vector3 = Vector3(pts[0].x, pts[0].y, z)
	for i in range(1, pts.size() - 1):
		var v1: Vector3 = Vector3(pts[i].x, pts[i].y, z)
		var v2: Vector3 = Vector3(pts[i + 1].x, pts[i + 1].y, z)
		st.set_normal(Vector3.BACK)
		st.set_color(c)
		st.add_vertex(v0)
		st.set_normal(Vector3.BACK)
		st.set_color(c)
		st.add_vertex(v1)
		st.set_normal(Vector3.BACK)
		st.set_color(c)
		st.add_vertex(v2)
	var mi := MeshInstance3D.new()
	mi.name = "Face"
	mi.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = c * 0.5
	mat.roughness = 1.0
	mat.metallic = 0.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	_ret_root().add_child(mi)


func _ret_mm(nm: String, mat: Material, r: float) -> MultiMeshInstance3D:
	var mmi := MultiMeshInstance3D.new()
	mmi.name = nm
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var dot := SphereMesh.new()
	dot.radius = r
	dot.height = r * 2.0
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
