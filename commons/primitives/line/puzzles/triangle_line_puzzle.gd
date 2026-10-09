extends LineSnapPuzzleBase
class_name TriangleLinePuzzle
const MUSEUM_STYLE = preload("res://commons/primitives/line/museum_line_style.gd")

# @identity
# essence: triangle = 3 edges connecting 3 vertices — the minimal closed polygon
# desire: learner discovers that three lines can close into the simplest possible bounded shape
# critical_parameter: closure — all 3 snap targets must be occupied with shared endpoints to complete
# triggers: snapping all 3 line endpoints into the 3 triangle vertex targets
# emerges: the triangle as the atomic unit of all mesh geometry — every surface is triangles beneath
# needs: [missing VR controls — all interaction is line-endpoint snapping]
# relationships: extends LineSnapPuzzleBase; logical predecessor to snap_tetrahedron_puzzle
# truth: three points that are not collinear always define a triangle — and a unique plane

## TriangleLinePuzzle - Interactive puzzle to form a triangle from three lines
## Any endpoint can snap to any of the 3 triangle vertices

# --- DNA (stage 2 — variation) ---
#
# The truth line above says the three points define a unique PLANE, but the shipped puzzle only
# ever offered one plane and one way of handing you the parts. Both were hard-coded literals in
# _init(). They are now axes.

## Which plane the three points close in.
## "upright" is the shipped layout — the triangle stands in the local ZY plane like a picture you
## face. "ground" lays the same triangle flat, so you assemble a floor facet rather than a sign.
## "tilted" hangs it at 45°, where neither reading is available and the plane has to be read as a
## choice rather than a default.
@export_enum("upright", "ground", "tilted") var target_plane: String = "upright"

## How the three unformed lines are presented before assembly.
## "racked" is the shipped stock — three identical parallel lines stacked off to the side, parts
## issued from a rack. "strewn" drops them at unrelated angles, so the triangle is a recognition
## you impose on debris. "ringed" shortens each line along its triangle edge, so the gaps
## invite you to connect the ends.
@export_enum("racked", "strewn", "ringed") var stock: String = "racked"

# Canonical triangle in plane coordinates (u across, v up): ~96 cm sides, apex up.
const TRI_UV: Array = [
	Vector2(-0.48, -0.25),
	Vector2(0.48, -0.25),
	Vector2(0.0, 0.58),
]
var discovery_face: MeshInstance3D

const TILT_DEG: float = 45.0
const GROUND_Y: float = -0.25
const STOCK_HALF: float = 0.15  # half-length of an unformed line, as shipped


func _init() -> void:
	# Shipped defaults, kept here verbatim so the puzzle is valid even before _ready runs.
	# Equilateral triangle in ZY plane, ~40cm sides
	target_positions = [
		Vector3(0, -0.173, -0.2),  # Bottom-left vertex
		Vector3(0, -0.173, 0.2),   # Bottom-right vertex
		Vector3(0, 0.173, 0)       # Top apex
	]

	# Define starting positions for each line [start, end]
	# Three horizontal lines in front of the player
	line_start_positions = [
		[Vector3(0.2, -0.2, -0.15), Vector3(0.2, -0.2, 0.15)],  # Line 1: top
		[Vector3(0.2, -0.3, -0.15), Vector3(0.2, -0.3, 0.15)],  # Line 2: middle
		[Vector3(0.2, -0.4, -0.15), Vector3(0.2, -0.4, 0.15)]   # Line 3: bottom
	]

	# Customize success message
	success_message = "Triangle Complete!"

	# Form constraints: Triangle requires 3 connected lines forming a closed loop
	form_constraints = FormConstraint.triangle_constraints()


func _ready() -> void:
	stock=str(get_meta("config_stock",stock))
	line_color=MUSEUM_STYLE.PINK;line_locked_color=MUSEUM_STYLE.PINK
	completion_color=MUSEUM_STYLE.PINK
	_apply_dna()
	super._ready()
	MUSEUM_STYLE.plinth(self,Vector3(0,-0.85,0),Vector3(0.9,1.1,1.5))
	var display=get_node_or_null("TriangleLogicDisplay")
	if display:display.visible=false
	if str(get_meta("config_discovery", "0")) == "1":
		var panel = preload("res://commons/ui/triangle_workbench.gd").new()
		panel.name = "ExperimentPanel"
		panel.position = Vector3(.64,-.31,0)
		panel.rotation_degrees = Vector3(-65,90,0)
		add_child(panel)
	print("TriangleLinePuzzle: 3 lines, 3 vertices, plane=%s stock=%s, constraints: CONNECTED + CLOSED_LOOP" % [target_plane, stock])


func _complete_puzzle() -> void:
	if is_completed:return
	is_completed=true
	_play_completion_sound()
	var shown_corners: Array[Vector3]=[]
	for line in snap_lines:
		line.lock_line()
		line.endpoint_a.enabled=false;line.endpoint_b.enabled=false
		# Either end can reach either target. Keep one skin at each shared corner.
		for endpoint in [line.endpoint_a,line.endpoint_b]:
			var already_shown:=false
			for corner in shown_corners:
				if endpoint.global_position.distance_to(corner)<0.001:already_shown=true;break
			endpoint.get_node("MeshInstance3D").visible=not already_shown
			if not already_shown:shown_corners.append(endpoint.global_position)
	for marker in target_markers:marker.visible=false
	all_lines_aligned.emit();puzzle_completed.emit()
	if trigger_tag!="":TagSystem.trigger_tag_action(trigger_tag,trigger_action if trigger_action!="" else "shrink_and_remove")

func _setup_lines() -> void:
	await super._setup_lines()
	for line in snap_lines:
		line.line_width=0.014;line.radial_segments=16;line.snap_tolerance=0.10
		line.material=MUSEUM_STYLE.pink();line.line_mesh.material_override=line.material
		for endpoint in [line.endpoint_a,line.endpoint_b]:
			MUSEUM_STYLE.point(endpoint,0.045)
			endpoint.snap_distance=0.0;endpoint.show_snap_preview=false
			endpoint.release_mode=XRToolsPickable.ReleaseMode.FROZEN;endpoint.freeze=true
		line._update_line_geometry()

func _validate_puzzle() -> void:
	# Near a corner is a preview. Closure belongs to the release that snaps it.
	for line in snap_lines:
		for endpoint in [line.endpoint_a,line.endpoint_b]:
			if endpoint.is_picked_up():return
			var exact:=false
			for target in line.shared_targets:
				if endpoint.global_position.distance_to(target)<0.001:exact=true;break
			if not exact:return
	super._validate_puzzle()

func _create_alyx_marker(_index: int) -> Node3D:
	var marker:=Node3D.new();marker.name="CornerTarget"
	var mesh:=MeshInstance3D.new();var ring:=TorusMesh.new()
	ring.inner_radius=0.052;ring.outer_radius=0.058;ring.rings=24;ring.ring_segments=8
	mesh.mesh=ring;mesh.rotation.z=PI*0.5;mesh.material_override=MUSEUM_STYLE.white()
	marker.add_child(mesh)
	return marker


# --- DNA layout ---

## Recompute targets and starting segments from the selected plane and stock.
func _apply_dna() -> void:
	target_positions = _dna_targets()
	line_start_positions = _dna_stock()


## Map a point in the triangle's own plane coordinates into the puzzle's local space.
## The "upright" branch is the shipped mapping: (u, v) -> (0, v, u).
func _to_local(u: float, v: float) -> Vector3:
	if target_plane == "ground":
		return Vector3(v, GROUND_Y, u)
	if target_plane == "tilted":
		var a: float = deg_to_rad(TILT_DEG)
		return Vector3(v * sin(a), v * cos(a), u)
	return Vector3(0.0, v, u)


func _dna_targets() -> Array[Vector3]:
	var pts: Array[Vector3] = []
	for uv in TRI_UV:
		pts.append(_to_local(uv.x, uv.y))
	return pts


func _dna_stock() -> Array[Array]:
	if stock == "strewn":
		return _strewn_lines()
	if stock == "ringed":
		return _ringed_lines()
	return _racked_lines()


## The shipped stock: three parallel lines racked beside the target, verbatim.
func _racked_lines() -> Array[Array]:
	var out: Array[Array] = []
	out.append([Vector3(0.2, -0.2, -0.15), Vector3(0.2, -0.2, 0.15)])
	out.append([Vector3(0.2, -0.3, -0.15), Vector3(0.2, -0.3, 0.15)])
	out.append([Vector3(0.2, -0.4, -0.15), Vector3(0.2, -0.4, 0.15)])
	return out


## Three lines dropped at unrelated angles in the same side plane. Fixed constants, not randf —
## this artifact ships in sequences where randomness has not been taught yet.
func _strewn_lines() -> Array[Array]:
	var centers: Array[Vector3] = [
		Vector3(0.2, -0.18, -0.22),
		Vector3(0.2, -0.34, 0.06),
		Vector3(0.2, -0.46, -0.04),
	]
	var angles: Array[float] = [18.0, -55.0, 78.0]

	var out: Array[Array] = []
	for i in centers.size():
		var a: float = deg_to_rad(angles[i])
		var half: Vector3 = Vector3(0.0, sin(a), cos(a)) * STOCK_HALF
		out.append([centers[i] - half, centers[i] + half])
	return out


## Short segments on the triangle's edge axes. Follows target_plane.
func _ringed_lines() -> Array[Array]:
	var out: Array[Array] = []
	for i in TRI_UV.size():
		var a: Vector2 = TRI_UV[i]
		var b: Vector2 = TRI_UV[(i + 1) % TRI_UV.size()]
		# Already on the edge's axis, but 16% short at each end. The gaps invite
		# the visitor to bring endpoints to their common corner, not find a rack.
		var p0: Vector2 = a.lerp(b,0.16)
		var p1: Vector2 = b.lerp(a,0.16)
		out.append([_to_local(p0.x, p0.y), _to_local(p1.x, p1.y)])
	return out


## Grid system integration — accept DNA from map data.
## Guarded: the grid call_deferreds this for every placement, so do nothing unless an axis
## actually moved, and only re-seat nodes that the base class has already created.
func apply_grid_config(config_data: Dictionary) -> void:
	var changed := false

	if config_data.has("target_plane"):
		var p: String = str(config_data["target_plane"]).strip_edges().to_lower()
		if p in ["upright", "ground", "tilted"] and p != target_plane:
			target_plane = p
			changed = true

	if config_data.has("stock"):
		var s: String = str(config_data["stock"]).strip_edges().to_lower()
		if s in ["racked", "strewn", "ringed"] and s != stock:
			stock = s
			changed = true

	if not changed:
		return

	_apply_dna()

	# The base class builds markers and lines from these arrays on a deferred call. If that has not
	# happened yet (the usual case — the grid configures right after add_child) the refreshed arrays
	# are simply picked up, and nothing needs moving.
	if target_markers.is_empty() and snap_lines.is_empty():
		return

	_reseat()


## Move already-built markers and lines onto the refreshed layout.
func _reseat() -> void:
	var global_targets: Array[Vector3] = []
	for p in target_positions:
		global_targets.append(global_transform * p)

	for i in range(target_markers.size()):
		if i < global_targets.size() and is_instance_valid(target_markers[i]):
			target_markers[i].global_position = global_targets[i]

	for i in range(snap_lines.size()):
		var line = snap_lines[i]
		if not is_instance_valid(line):
			continue
		line.set_shared_targets(global_targets)
		if i < line_start_positions.size() and line.endpoint_a and line.endpoint_b:
			line.endpoint_a.global_position = global_transform * line_start_positions[i][0]
			line.endpoint_b.global_position = global_transform * line_start_positions[i][1]
			line._update_line_geometry()

func toggle_discovery_face() -> void:
	if not is_completed: return
	if discovery_face == null:
		discovery_face = MeshInstance3D.new()
		discovery_face.name = "DiscoveredFace"
		var mesh := ImmediateMesh.new()
		mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		for p: Vector3 in target_positions: mesh.surface_add_vertex(p)
		mesh.surface_end()
		discovery_face.mesh = mesh
		discovery_face.material_override = MUSEUM_STYLE.face()
		add_child(discovery_face)
	else:
		discovery_face.visible = not discovery_face.visible

func reset_puzzle() -> void:
	if is_instance_valid(discovery_face):
		discovery_face.queue_free()
		discovery_face = null
	super.reset_puzzle()
	for line in snap_lines:
		for endpoint in [line.endpoint_a,line.endpoint_b]:
			endpoint.enabled=true;endpoint.freeze=true
			endpoint.get_node("MeshInstance3D").visible=true
