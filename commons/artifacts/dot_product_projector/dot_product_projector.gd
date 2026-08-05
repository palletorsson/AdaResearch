# dot_product_projector.gd
# Interactive dot product visualizer
# Shows: A · B = |A||B|cos(θ) = projection of A onto B × |B|
#
# VR-enabled with grabbable vector endpoints
# QFEP: Dot product as "alignment" - how much two directions agree
#
# UPGRADED VISUALS - Sleek modern look with glow effects
#
# @identity
# essence: A . B = |A||B|cos(theta). The dot product measures alignment. Positive = same direction, zero = perpendicular, negative = opposed.
# desire: To let the learner rotate two arrows and watch a number change sign — making orthogonality a felt threshold, not a definition.
# critical_parameter: The angle between vector_a and vector_b. At 90 degrees the dot product crosses zero — the phase transition of alignment.
# triggers: Handle drag → projection arrow slides along B, angle arc updates, result panel color-codes (green/yellow/red), preset buttons → aligned/ortho/opposed
# emerges: The perpendicular drop line from A's tip to the projection. The angle arc sweeping through the sign change at 90 degrees.
# needs: VR grabbable handles [has], preset buttons [has], angle arc visualization [has]. Missing: audio feedback at the orthogonal crossing.
# relationships: Foundation for work_energy_demo (W = F.d uses dot product). Feeds into hl_turret_vectors (FOV check = dot product). Contrasts with torque_demo (cross product).
# truth: The dot product is the question: how much do these two directions agree? The answer is a scalar — dimension collapses by design.

extends Node3D

class_name DotProductProjector

## Display settings
@export var max_vector_length: float = 1.2
@export var arrow_thickness: float = 0.012  # Thin like y_oscillation_cube

# The pose this bench has shipped in since it was written: 35.5 degrees, the acute
# case. `opening` hands these two back verbatim rather than re-deriving them.
const POSE_A := Vector3(0.7, 0.5, 0.0)
const POSE_B := Vector3(0.9, 0.0, 0.0)

## Vector A (the vector being projected)
@export var vector_a: Vector3 = POSE_A:
	set(value):
		vector_a = value.limit_length(max_vector_length)
		if is_inside_tree():
			_update_visualization()

## Vector B (the vector projected onto)
@export var vector_b: Vector3 = POSE_B:
	set(value):
		vector_b = value.limit_length(max_vector_length)
		if vector_b.length() < 0.01:
			vector_b = Vector3(0.9, 0, 0)
		if is_inside_tree():
			_update_visualization()

## AXIS — HOW MUCH OF THE ARITHMETIC THE BENCH DRAWS. Adopted word for word (and value
## for value, in order) from [[transform_composition_workbench]] and shared across the
## whole vector subject, so a room cannot show its sum as a walked route and its dot
## product as a bare answer.
##
##   outcome     the number, as a length. A, the orange rejection arrow, the white drop
##               line and the purple angle arc all leave the render layers; B stays as
##               the axis the answer is measured on, with the green projection lying on
##               it. You are handed how much, never what of.
##   trace       the halfway states get BUILT. A fan of pale ghost copies of A rotates
##               from B's direction up to A's, each dropping its own tick onto B, so the
##               projection is seen collapsing as the angle opens — the limit cos θ walks
##               through instead of the single value it arrives at.
##   operands    the legacy lineage, byte for byte — A and B from the SHARED origin with
##               the angle arc between them, the projection along B and the rejection
##               standing off it. Both ingredients from one tail.
##   expression  the algebra promoted over the geometry. The side formula panel is joined
##               by a board standing over the arrows writing A·B = |A||B|cos θ with the
##               numbers substituted, between two emissive rules in the projection green.
##
## The arc and the drop line are the construction; the two arrows are the ingredients;
## the green bar is the answer. Each value keeps a different one of those three.
@export_enum("outcome", "trace", "operands", "expression") var workings: String = "operands"
const WORKINGS: PackedStringArray = ["outcome", "trace", "operands", "expression"]

## AXIS — WHICH CASE THE BENCH IS FOUND IN. agreement_gauge's word with its four
## values in the same order, seconded by dot_aligner and exercise_5_9_angle_between:
## literally the same question asked of the same pair of directions, so a room can
## set the gauge, the exercise, the turret and this projector to one case and expect
## the four to MEASURE alike.
##
##   agreeing    the shipped pose, handed back verbatim — 35.5 degrees, dot +0.63,
##               the projection a short green bar lying along B.
##   strangers   90 degrees. The dot is exactly 0, the green bar vanishes to a point
##               at the shared tail, and the drop line lands on the origin. The
##               threshold this artifact's @identity calls its critical parameter.
##   opposing    140 degrees. The dot is negative and the projection arrow points
##               BACKWARDS down B — the sign change as a direction, not a minus sign.
##   parallel    0 degrees. The two arrows superimpose, the arc collapses (the arc
##               builder returns early under 0.05 rad) and the projection is the whole
##               of A: |A||B| at its ceiling.
##
## Why this is not a second word for a knob that already exists — the test
## projection_shadow applied when it declined this same word. vector_a and vector_b
## are exported, but they are two raw Vector3 literals: reaching "exactly 90 degrees"
## through them means computing components by hand, and NO map has ever done it. The
## artifact already thinks in these cases — ALIGNED / ORTHO / OPPOSED are three of the
## five hard-coded presets wired to the VR buttons — but that vocabulary was reachable
## only by a hand in the headset, never from a map token. This lifts the presets the
## artifact already has into the family's word for them.
##
## |A| and |B| are PRESERVED at every value: the pose turns theta and nothing else, so
## a sweep cannot be read as a fact about lengths.
@export_enum("agreeing", "strangers", "opposing", "parallel") var opening: String = "agreeing"
const OPENINGS: PackedStringArray = ["agreeing", "strangers", "opposing", "parallel"]
const OPENING_DEGREES := {"strangers": 90.0, "opposing": 140.0, "parallel": 0.0}

# Sleek color palette
var color_a: Color = Color(1.0, 0.35, 0.4)        # Coral - vector A
var color_b: Color = Color(0.3, 0.5, 1.0)         # Blue - vector B
var color_projection: Color = Color(0.4, 1.0, 0.5) # Green - projection
var color_perpendicular: Color = Color(1.0, 0.75, 0.3, 0.6)  # Orange - perp
var color_angle: Color = Color(0.8, 0.5, 1.0, 0.5) # Purple - angle arc

var _arrow_a: Node3D
var _arrow_b: Node3D
var _arrow_projection: Node3D
var _arrow_perpendicular: Node3D
var _drop_line: MeshInstance3D
var _angle_arc: MeshInstance3D
var _handle_a: Node3D
var _handle_b: Node3D
var _title_panel: Node3D
var _result_panel: Node3D
var _formula_panel: Node3D
var _control_panel: Node3D
var _ground: Node3D
var _axes: Node3D

# WORKINGS dressing lives here and nowhere else — created last in _ready() so the legacy
# tree above it is untouched, cleared and refilled on every _update_visualization().
var _workings_root: Node3D

# Vector labels
var _label_a: Label3D
var _label_b: Label3D
var _label_proj: Label3D
var _label_angle: Label3D

# Animation
var _time: float = 0.0


func _ready():
	# The pose comes first, so the handles are created already standing on it. At the
	# default this is a hard no-op: _apply_opening() is not even called.
	if _opening_value() != "agreeing":
		_apply_opening()

	_ground = VectorVisuals.create_ground(self, max_vector_length * 2.5)
	_axes = VectorVisuals.create_axes(self, max_vector_length * 1.3)
	
	_create_arrows()
	_create_projection_visuals()
	_create_handles()
	_create_labels()
	_create_vr_controls()
	# WORKINGS holder — created LAST, so every node above keeps the index and the
	# position it has today. Empty on the default; nothing above this line moves.
	_workings_root = Node3D.new()
	_workings_root.name = "Workings"
	add_child(_workings_root)
	_update_visualization()

func _create_arrows():
	_arrow_a = VectorVisuals.create_arrow(self, "ArrowA", color_a, arrow_thickness)
	_arrow_b = VectorVisuals.create_arrow(self, "ArrowB", color_b, arrow_thickness)
	_arrow_projection = VectorVisuals.create_arrow(self, "ArrowProjection", color_projection, arrow_thickness)
	_arrow_perpendicular = VectorVisuals.create_arrow(self, "ArrowPerpendicular", color_perpendicular, arrow_thickness, true)

func _create_projection_visuals():
	# Drop line (perpendicular from A tip to projection)
	_drop_line = MeshInstance3D.new()
	_drop_line.name = "DropLine"
	add_child(_drop_line)
	
	# Angle arc
	_angle_arc = MeshInstance3D.new()
	_angle_arc.name = "AngleArc"
	add_child(_angle_arc)

func _create_handles():
	_handle_a = VectorVisuals.create_handle(self, "HandleA", color_a, 0.045)
	_handle_a.position = vector_a
	
	_handle_b = VectorVisuals.create_handle(self, "HandleB", color_b, 0.045)
	_handle_b.position = vector_b

func _create_labels():
	# Title panel - behind artifact, facing player
	_title_panel = VectorVisuals.create_panel(self, "TitlePanel",
		"DOT PRODUCT",
		Vector3(0, max_vector_length + 0.45, -max_vector_length - 0.2),
		Vector2(0.42, 0.09), 26)
	# No rotation - faces +Z toward player
	
	# Result panel - below title
	_result_panel = VectorVisuals.create_panel(self, "ResultPanel", "",
		Vector3(0, max_vector_length + 0.28, -max_vector_length - 0.2),
		Vector2(0.6, 0.1), 18)
	# No rotation - faces +Z toward player
	
	# Formula panel - to the right, facing player
	_formula_panel = VectorVisuals.create_panel(self, "FormulaPanel", "",
		Vector3(max_vector_length + 0.28, max_vector_length * 0.4, 0),
		Vector2(0.6, 0.28), 12, HORIZONTAL_ALIGNMENT_LEFT)
	_formula_panel.rotation_degrees = Vector3(0, -90, 0)  # Face toward +Z
	
	# Vector labels
	_label_a = VectorVisuals.create_vector_label(self, "LabelA", "A⃗", color_a)
	_label_b = VectorVisuals.create_vector_label(self, "LabelB", "B⃗", color_b)
	_label_proj = VectorVisuals.create_vector_label(self, "LabelProj", "proj", color_projection)
	
	# Angle label
	_label_angle = Label3D.new()
	_label_angle.name = "LabelAngle"
	_label_angle.pixel_size = 0.0018
	_label_angle.font_size = 14
	_label_angle.modulate = color_angle
	_label_angle.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label_angle.outline_size = 6
	_label_angle.outline_modulate = Color(0, 0, 0, 0.7)
	add_child(_label_angle)

func _create_vr_controls():
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_panel("DOT PRODUCT", [
		[{"type": "button", "label": "ALIGNED"}, {"type": "button", "label": "ORTHO"}, {"type": "button", "label": "OPPOSED"}],
		[{"type": "button", "label": "ACUTE"}, {"type": "button", "label": "OBTUSE"}],
	])
	_control_panel.position = Vector3(0, 0.06, max_vector_length + 0.4)
	_control_panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(_control_panel)

	var presets = [
		[Vector3(0.6, 0.0, 0), Vector3(0.8, 0.0, 0)],
		[Vector3(0.0, 0.6, 0), Vector3(0.8, 0.0, 0)],
		[Vector3(-0.5, 0.0, 0), Vector3(0.8, 0.0, 0)],
		[Vector3(0.5, 0.4, 0), Vector3(0.8, 0.0, 0)],
		[Vector3(-0.3, 0.5, 0), Vector3(0.8, 0.0, 0)],
	]
	for i in range(presets.size()):
		var btn: Node = _control_panel.find_child("Btn_%d" % i, true, false)
		if btn:
			var area = btn.get_node_or_null("InteractableAreaButton")
			if area:
				var va = presets[i][0]
				var vb = presets[i][1]
				area.button_pressed.connect(func(_b): _apply_preset(va, vb))

func _apply_preset(va: Vector3, vb: Vector3):
	vector_a = va
	vector_b = vb
	_handle_a.position = vector_a
	_handle_b.position = vector_b

func _update_visualization():
	# The vector_a / vector_b setters fire this whenever the node is inside the tree,
	# and _ready() is inside the tree. Writing a pose before _create_arrows() would
	# otherwise reach a null arrow. Nothing calls this before the arrows exist today,
	# so the guard changes nothing that ships.
	if _arrow_a == null:
		return

	# Calculate dot product and projection
	var dot = vector_a.dot(vector_b)
	var b_normalized = vector_b.normalized()
	var projection_length = dot / vector_b.length() if vector_b.length() > 0.001 else 0.0
	var projection = b_normalized * projection_length
	var perpendicular = vector_a - projection
	
	# Calculate angle
	var cos_angle = dot / (vector_a.length() * vector_b.length()) if (vector_a.length() > 0.001 and vector_b.length() > 0.001) else 0.0
	cos_angle = clampf(cos_angle, -1.0, 1.0)
	var angle_rad = acos(cos_angle)
	var angle_deg = rad_to_deg(angle_rad)
	
	# Update arrows - all thin
	VectorVisuals.position_arrow(_arrow_a, Vector3.ZERO, vector_a, arrow_thickness)
	VectorVisuals.position_arrow(_arrow_b, Vector3.ZERO, vector_b, arrow_thickness)
	VectorVisuals.position_arrow(_arrow_projection, Vector3.ZERO, projection, arrow_thickness)
	VectorVisuals.position_arrow(_arrow_perpendicular, projection, vector_a, arrow_thickness)
	
	# Update labels - offset toward +Z for player visibility
	_label_a.position = vector_a * 0.5 + Vector3(0, 0.06, 0.08)
	_label_b.position = vector_b * 0.5 + Vector3(0, 0.06, 0.08)
	_label_proj.position = projection * 0.5 + Vector3(0, -0.06, 0.08)
	
	# Update drop line
	_update_drop_line(vector_a, projection)
	
	# Update angle arc and label
	_update_angle_arc(angle_rad)
	_label_angle.position = Vector3(0.15, 0.08, 0)
	_label_angle.text = "θ = %.1f°" % angle_deg
	
	# Update panels
	_update_panels(dot, projection_length, angle_deg)

	# WORKINGS, applied LAST so nothing above it moves. "operands" restores every layer
	# and builds nothing at all — the legacy lineage, byte for byte.
	_apply_workings(dot, projection, angle_deg)

func _update_drop_line(a_tip: Vector3, proj: Vector3):
	var perp = a_tip - proj
	if perp.length() < 0.01:
		_drop_line.visible = false
		return
	_drop_line.visible = true
	
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.004
	cylinder.bottom_radius = 0.004
	cylinder.height = perp.length()
	_drop_line.mesh = cylinder
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 1, 1, 0.4)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(1, 1, 1)
	mat.emission_energy_multiplier = 0.2
	_drop_line.material_override = mat
	
	var mid = (a_tip + proj) / 2.0
	_drop_line.position = mid
	
	var up = Vector3.UP
	if abs(perp.normalized().dot(up)) > 0.99:
		up = Vector3.FORWARD
	_drop_line.look_at(_drop_line.global_position + perp, up)
	_drop_line.rotate_object_local(Vector3.RIGHT, PI/2)

func _update_angle_arc(angle_rad: float):
	if angle_rad < 0.05 or angle_rad > PI - 0.05:
		_angle_arc.visible = false
		return
	_angle_arc.visible = true
	
	var arc_radius = 0.15
	var segments = int(angle_rad * 20) + 6
	
	var immediate_mesh = ImmediateMesh.new()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	
	var a_dir = vector_a.normalized()
	var b_dir = vector_b.normalized()
	
	for i in range(segments + 1):
		var t = float(i) / float(segments)
		var interp = b_dir.slerp(a_dir, t).normalized() * arc_radius
		
		immediate_mesh.surface_add_vertex(interp * 0.85)
		immediate_mesh.surface_add_vertex(interp * 1.0)
	
	immediate_mesh.surface_end()
	_angle_arc.mesh = immediate_mesh
	
	var arc_mat = StandardMaterial3D.new()
	arc_mat.albedo_color = color_angle
	arc_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	arc_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	arc_mat.emission_enabled = true
	arc_mat.emission = Color(color_angle.r, color_angle.g, color_angle.b, 1.0)
	arc_mat.emission_energy_multiplier = 0.3
	_angle_arc.material_override = arc_mat

func _update_panels(dot: float, proj_len: float, angle_deg: float):
	var alignment = "aligned" if dot > 0.01 else ("opposed" if dot < -0.01 else "orthogonal")
	
	# Result panel
	var result_label = VectorVisuals.get_panel_label(_result_panel)
	if result_label:
		result_label.text = "A⃗ · B⃗ = %.3f  (%s)" % [dot, alignment]
		if dot > 0:
			result_label.modulate = Color(0.4, 1.0, 0.5)
		elif dot < 0:
			result_label.modulate = Color(1.0, 0.4, 0.4)
		else:
			result_label.modulate = Color(1.0, 1.0, 0.4)
	
	# Formula panel
	var formula_label = VectorVisuals.get_panel_label(_formula_panel)
	if formula_label:
		formula_label.text = "A⃗ = (%.2f, %.2f, %.2f)\n" % [vector_a.x, vector_a.y, vector_a.z]
		formula_label.text += "|A⃗| = %.3f\n\n" % vector_a.length()
		formula_label.text += "B⃗ = (%.2f, %.2f, %.2f)\n" % [vector_b.x, vector_b.y, vector_b.z]
		formula_label.text += "|B⃗| = %.3f\n\n" % vector_b.length()
		formula_label.text += "A⃗ · B⃗ = |A⃗||B⃗|cos(θ)\n"
		formula_label.text += "θ = %.1f°   proj = %.3f" % [angle_deg, proj_len]

func _process(delta):
	_time += delta
	
	VectorVisuals.pulse_handle(_handle_a, delta, _time)
	VectorVisuals.pulse_handle(_handle_b, delta, _time + 1.0)
	VectorVisuals.pulse_arrow(_arrow_projection, delta, _time)
	
	if _handle_a.position != vector_a:
		vector_a = _handle_a.position
	if _handle_b.position != vector_b:
		vector_b = _handle_b.position

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: _apply_preset(Vector3(0.6, 0.0, 0), Vector3(0.8, 0.0, 0))
			KEY_2: _apply_preset(Vector3(0.0, 0.6, 0), Vector3(0.8, 0.0, 0))
			KEY_3: _apply_preset(Vector3(-0.5, 0.0, 0), Vector3(0.8, 0.0, 0))
			KEY_4: _apply_preset(Vector3(0.5, 0.4, 0), Vector3(0.8, 0.0, 0))
			KEY_5: _apply_preset(Vector3(-0.3, 0.5, 0), Vector3(0.8, 0.0, 0))

func set_vectors(a: Vector3, b: Vector3):
	vector_a = a
	vector_b = b
	_handle_a.position = vector_a
	_handle_b.position = vector_b

func get_dot_product() -> float:
	return vector_a.dot(vector_b)

func get_projection() -> Vector3:
	var dot = vector_a.dot(vector_b)
	return vector_b.normalized() * (dot / vector_b.length()) if vector_b.length() > 0.001 else Vector3.ZERO

func apply_grid_config(config_data: Dictionary):
	for key in config_data:
		if key in self:
			set(key, config_data[key])
	# `opening` MOVES the two arrows, so it is applied only when the config actually
	# names it — a placement that sets vector_a by hand is never overruled by a pose
	# it did not ask for. (The loop above has already written the enum string.)
	if config_data.has("opening"):
		_apply_opening()
		if _handle_a != null:
			_handle_a.position = vector_a
		if _handle_b != null:
			_handle_b.position = vector_b
	# `workings` is a plain export with no setter (the vector_* ones rebuild themselves),
	# so a config that only changes the axis has to ask for the rebuild explicitly.
	if is_inside_tree():
		_update_visualization()


# --- OPENING ----------------------------------------------------------------
# The case the bench is found in. Turns theta and nothing else.

func _opening_value() -> String:
	var o: String = String(opening).strip_edges().to_lower()
	return o if OPENINGS.has(o) else "agreeing"


## Swings A to the requested angle away from B, about the axis normal to the plane the
## two arrows already share, keeping |A| and B untouched. `agreeing` SHORT-CIRCUITS to
## the two shipped literals instead of re-deriving 35.5 degrees from them, so the
## default is the pose itself and not a ratio that could rescale under a map override.
func _apply_opening() -> void:
	var value: String = _opening_value()
	if not OPENING_DEGREES.has(value):
		vector_a = POSE_A                       # "agreeing" — the shipped pose, verbatim
		vector_b = POSE_B
		return

	var len_a: float = vector_a.length()
	var b_dir: Vector3 = vector_b.normalized()
	if len_a < 0.001 or b_dir.length() < 0.5:
		return
	# The plane the shipped pose lives in (A and B are both in XY), so a swung arrow
	# stays where the player is already looking rather than leaving toward the camera.
	var axis: Vector3 = b_dir.cross(vector_a.normalized())
	if axis.length() < 0.001:
		axis = Vector3.BACK
	axis = axis.normalized()
	vector_a = b_dir.rotated(axis, deg_to_rad(float(OPENING_DEGREES[value]))) * len_a


# --- WORKINGS ---------------------------------------------------------------
# One axis, four values, shared word for word with the rest of the vector subject.
# Every builder writes only into _workings_root; removal is always `layers = 0` on the
# MeshInstance3D / Label3D leaves — never `visible = false`, which in Godot takes a
# holder's whole subtree with it (and this artifact's arrows ARE holders).

func _workings_value() -> String:
	var w: String = String(workings).strip_edges().to_lower()
	return w if WORKINGS.has(w) else "operands"


func _set_layers(n: Node, bits: int) -> void:
	if n is VisualInstance3D:
		(n as VisualInstance3D).layers = bits
	for child in n.get_children():
		_set_layers(child, bits)


func _apply_workings(dot: float, projection: Vector3, angle_deg: float) -> void:
	if _workings_root == null:
		return
	for c in _workings_root.get_children():
		_workings_root.remove_child(c)
		c.queue_free()

	# Restore first, so a value change at runtime is reversible and the default is
	# always exactly today's build.
	for n in [_arrow_a, _arrow_perpendicular, _drop_line, _angle_arc, _label_a, _label_angle]:
		if n != null:
			_set_layers(n, 1)

	match _workings_value():
		"outcome":
			# The number, as a length. What was projected, what it cost to project it and
			# the angle that decided the price all leave the frame; B stays as the ruler
			# the answer lies on.
			for n in [_arrow_a, _arrow_perpendicular, _drop_line, _angle_arc,
					_label_a, _label_angle]:
				if n != null:
					_set_layers(n, 0)
		"trace":
			# The halfway states BUILT: ghost copies of A swept from B's direction round
			# to A's, each dropping a tick onto B. The projection is watched collapsing.
			_workings_trace(projection)
		"expression":
			_workings_root.add_child(_w_board(dot, projection.length(), angle_deg))
		_:
			pass                                   # "operands" — the legacy lineage


## TRACE — the sweep. Six ghost copies of A stand between B's direction and A's own, each
## with a tick where its tip falls onto B, so the run of ticks IS cos θ walking down from
## 1 to whatever this angle allows. The single green bar is the last tick in that run.
func _workings_trace(projection: Vector3) -> void:
	var a_len: float = vector_a.length()
	var b_dir: Vector3 = vector_b.normalized()
	var a_dir: Vector3 = vector_a.normalized()
	if a_len < 0.01 or vector_b.length() < 0.01:
		return
	var steps: int = 6
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var ghost_dir: Vector3 = b_dir.slerp(a_dir, t).normalized()
		var tip: Vector3 = ghost_dir * a_len
		var fade: float = 0.18 + 0.42 * (1.0 - t)
		var ghost := Color(color_a.r, color_a.g, color_a.b, fade)
		if i < steps:
			_workings_root.add_child(_w_rod(Vector3.ZERO, tip, 0.004, ghost, 0.5, true))
		var foot: Vector3 = b_dir * tip.dot(b_dir)
		_workings_root.add_child(_w_rod(foot, foot + Vector3(0.0, 0.055, 0.0), 0.008,
			color_projection, 1.6, false))
		if i < steps:
			_workings_root.add_child(_w_rod(tip, foot, 0.0025,
				Color(1.0, 1.0, 1.0, 0.22), 0.3, true))
	_workings_root.add_child(_w_rod(Vector3.ZERO, projection, 0.016, color_projection, 2.2, false))


## A straight rod between two points — ghost strokes, drop hairs and projection bars.
func _w_rod(from: Vector3, to: Vector3, radius: float, color: Color,
		energy: float, ghost: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var dir: Vector3 = to - from
	var length: float = maxf(dir.length(), 0.001)
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = length
	cyl.radial_segments = 8
	mi.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if ghost:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(color.r, color.g, color.b, 1.0)
	mat.emission_energy_multiplier = energy
	mi.material_override = mat
	mi.transform = Transform3D(_w_basis_y_to(dir), (from + to) * 0.5)
	return mi


## A basis whose +Y runs along `dir` — CylinderMesh is built on its own +Y.
func _w_basis_y_to(dir: Vector3) -> Basis:
	var y: Vector3 = dir.normalized()
	if y.length() < 0.0001:
		return Basis()
	var ref: Vector3 = Vector3.UP if absf(y.dot(Vector3.UP)) < 0.985 else Vector3.RIGHT
	var x: Vector3 = ref.cross(y).normalized()
	var z: Vector3 = x.cross(y).normalized()
	return Basis(x, y, z)


## EXPRESSION — a board standing over the arrows facing the player, writing the identity
## out with the numbers substituted, between two emissive rules in the projection green.
func _w_board(dot: float, proj_len: float, angle_deg: float) -> Node3D:
	var board := Node3D.new()
	board.name = "WorkingsBoard"
	board.position = Vector3(0.0, max_vector_length + 0.72, 0.0)
	var w: float = max_vector_length * 1.9
	var h: float = w * 0.28
	var plate := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(w, h, 0.02)
	plate.mesh = box
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color(0.81, 0.79, 0.75)
	pm.roughness = 0.92
	plate.material_override = pm
	board.add_child(plate)
	var rule_mat := StandardMaterial3D.new()
	rule_mat.albedo_color = color_projection
	rule_mat.emission_enabled = true
	rule_mat.emission = color_projection
	rule_mat.emission_energy_multiplier = 2.2
	for sy in [1.0, -1.0]:
		var rule := MeshInstance3D.new()
		var rb := BoxMesh.new()
		rb.size = Vector3(w, h * 0.07, 0.024)
		rule.mesh = rb
		rule.material_override = rule_mat
		rule.position = Vector3(0.0, sy * h * 0.5, 0.006)
		board.add_child(rule)
	var l := Label3D.new()
	l.name = "Algebra"
	l.text = "A · B  =  |A| |B| cos θ\n%.2f × %.2f × cos %.0f°  =  %.3f\nproj = %.3f" % [
		vector_a.length(), vector_b.length(), angle_deg, dot, proj_len]
	l.font_size = 30
	l.pixel_size = h / 320.0
	l.modulate = Color(0.17, 0.17, 0.19)
	l.outline_size = 5
	l.outline_modulate = Color(0.90, 0.88, 0.84, 0.9)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = Vector3(0.0, 0.0, 0.02)
	board.add_child(l)
	return board
