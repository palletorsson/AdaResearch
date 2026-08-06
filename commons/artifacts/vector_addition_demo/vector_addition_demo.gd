# vector_addition_demo.gd
# Interactive vector addition: A + B = C
# VR-enabled with grabbable arrow endpoints
#
# Visualizes the parallelogram law:
# Place vectors head-to-tail, resultant is the diagonal
#
# UPGRADED VISUALS - Sleek modern look with glow effects
#
# @identity
# essence: C = A + B. Head-to-tail construction. The parallelogram law.
# desire: To let the learner grab two arrows and watch a third arrow appear — the sum — making addition tangible rather than symbolic.
# critical_parameter: The angle between vector_a and vector_b. Parallel vectors add magnitudes; perpendicular vectors add by Pythagoras; opposed vectors cancel.
# triggers: Handle drag → resultant updates, preset buttons → snap to orthogonal/acute/3D configurations, ghost arrows → parallelogram appears
# emerges: The parallelogram from ghost arrows. The triangle inequality (|A+B| <= |A|+|B|) becomes visible without being stated.
# needs: VR grabbable handles [has], preset buttons [has]. Missing: slider to animate blending between A and B.
# relationships: Prerequisite for combined_forces_demo (force superposition is vector addition). Pairs with vector_subtraction_demo (inverse operation).
# truth: Addition is geometry, not arithmetic. Two directions become one.

extends Node3D

class_name VectorAdditionDemo

## Display settings
@export var max_vector_length: float = 1.2
@export var arrow_thickness: float = 0.006  # Small for exhibition

## Vector A
@export var vector_a: Vector3 = Vector3(0.8, 0.3, 0.0):
	set(value):
		vector_a = value.limit_length(max_vector_length)
		if is_inside_tree() and not _building:
			_update_vectors()

## Vector B
@export var vector_b: Vector3 = Vector3(0.2, 0.6, 0.3):
	set(value):
		vector_b = value.limit_length(max_vector_length)
		if is_inside_tree() and not _building:
			_update_vectors()

## AXIS — HOW MUCH OF THE ARITHMETIC THE BENCH DRAWS. Adopted word for word, and value for
## value in order, from [[transform_composition_workbench]], and carried on this bench's own
## twin [[vector_subtraction_demo]] — the file in the folder next door, same exports, same
## handles, same preset rack, same exhibition plate, written as the inverse of this one. A
## room cannot show its sum as a walked route and its difference as a bare answer.
##
##   outcome     the sum alone. A, B and both parallelogram ghosts leave the render layers
##               with their labels; one green arrow reaches from the origin and nothing in
##               the frame says which two directions made it.
##   trace       the legacy lineage, byte for byte — A and B from the origin, the resultant
##               closing them, and both translucent ghosts drawing the walk each way round.
##               A + B is a route you took, and you can take it in either order.
##   operands    the figure instead of the walk. The two ghost legs retire and the closure is
##               redrawn as dashed sides in the result's green, with the two operand tips and
##               the far corner marked: the sum read as the DIAGONAL of a parallelogram
##               rather than as a journey.
##   expression  the algebra promoted over the geometry. A board stands behind the arrows
##               facing the player, writing A + B = C with the components substituted,
##               between two emissive rules in the result's green.
##
## The five arrows are the pivot: they are the only saturated things in the frame, and
## `outcome` takes four of them out.
@export_enum("outcome", "trace", "operands", "expression") var workings: String = "trace"
const WORKINGS: PackedStringArray = ["outcome", "trace", "operands", "expression"]

## AXIS — HOW THE TWO OPERANDS STAND TO EACH OTHER. Taken character for character from
## [[VectorAddition]], the other bench in this corpus arguing A + B; one operation should not
## carry two vocabularies for the question of what kind of pair is being added. `workings`
## says how much of the sum is drawn, `pair` says what there is to draw — independent
## questions, and this artifact's own @identity already names the second one ("the angle
## between vector_a and vector_b ... parallel vectors add magnitudes; perpendicular vectors
## add by Pythagoras; opposed vectors cancel") without ever making it reachable from a map.
##
##   oblique     the shipped operands, at roughly 57 degrees. Returned untouched.
##   orthogonal  B turned perpendicular to A, same length. The parallelogram is a rectangle
##               and |A+B| is Pythagoras. This is the bench's own ORTHO preset, standing.
##   parallel    B laid along A, same length. The figure collapses onto the line and the
##               magnitudes simply add — the triangle inequality at its equality case.
##   opposed     B laid against A, same length. The green arrow shrinks to the difference;
##               addition seen doing the work of subtraction.
##
## THE MAGNITUDE OF B IS HELD AT 0.7 ACROSS ALL FOUR, so what moves in the frame is the
## ANGLE and nothing else. And note what this axis is NOT: the four preset BUTTONS on the
## rack ask this same question, and vector_subtraction_demo rightly refused to make an axis
## of them — a button is a player interaction, so a still photographs whichever preset was
## last pressed, which is never. `pair` is the opening STATE, resolved before _ready builds
## anything, which is the only form of this question a still frame can answer.
@export_enum("oblique", "orthogonal", "parallel", "opposed") var pair: String = "oblique"
const PAIRS: PackedStringArray = ["oblique", "orthogonal", "parallel", "opposed"]

# Sleek color palette
var color_a: Color = Color(1.0, 0.35, 0.4)      # Coral
var color_b: Color = Color(0.3, 0.85, 0.95)     # Cyan  
var color_result: Color = Color(0.4, 1.0, 0.5)  # Neon green
var color_ghost: Color = Color(0.5, 0.5, 0.6, 0.35)

var _arrow_a: Node3D
var _arrow_b: Node3D
var _arrow_result: Node3D
var _arrow_a_ghost: Node3D
var _arrow_b_ghost: Node3D
var _handle_a: Node3D
var _handle_b: Node3D
var _title_panel: Node3D
var _formula_panel: Node3D
var _ground: Node3D
var _axes: Node3D

# Vector labels
var _label_a: Label3D
var _label_b: Label3D
var _label_result: Label3D

# VR Controls
var _control_panel: Node3D

# Animation
var _time: float = 0.0

# WORKINGS dressing lives here and nowhere else — created last in _ready() so the legacy
# tree above it is untouched, cleared and refilled on every _update_vectors().
var _workings_root: Node3D

# True until _ready has finished building. The two vector setters call _update_vectors(),
# which dereferences arrows that do not exist yet; `pair` has to write vector_b BEFORE
# _create_arrows() runs, so the setters must be able to stay quiet for exactly that long.
# After _ready this is false forever and both setters behave exactly as they always have.
var _building: bool = true


func _ready():
	# PAIR, resolved before a single node is built, so the handles, the arrows, the ghosts,
	# the labels and every printed component all come from one pair of operands. At the
	# default this line reads `vector_b = vector_b`.
	vector_b = _paired_b()

	# Use the visual helper
	_ground = VectorVisuals.create_ground(self, max_vector_length * 2.5)
	_axes = VectorVisuals.create_axes(self, max_vector_length * 1.3)

	_create_arrows()
	_create_handles()
	_create_labels()
	_create_vr_controls()
	# WORKINGS holder — created LAST, so every node above keeps the index and the position
	# it has today. Empty on the default; nothing above this line moves.
	_workings_root = Node3D.new()
	_workings_root.name = "Workings"
	add_child(_workings_root)
	_building = false
	_update_vectors()

func _create_arrows():
	# Main arrows - thin
	_arrow_a = VectorVisuals.create_arrow(self, "ArrowA", color_a, arrow_thickness)
	_arrow_b = VectorVisuals.create_arrow(self, "ArrowB", color_b, arrow_thickness)
	_arrow_result = VectorVisuals.create_arrow(self, "ArrowResult", color_result, arrow_thickness)
	
	# Ghost arrows for parallelogram
	_arrow_a_ghost = VectorVisuals.create_arrow(self, "ArrowAGhost", color_a, arrow_thickness, true)
	_arrow_b_ghost = VectorVisuals.create_arrow(self, "ArrowBGhost", color_b, arrow_thickness, true)

func _create_handles():
	_handle_a = VectorVisuals.create_handle(self, "HandleA", color_a, 0.045)
	_handle_a.position = vector_a
	
	_handle_b = VectorVisuals.create_handle(self, "HandleB", color_b, 0.045)
	_handle_b.position = vector_b
	
	# Add XRToolsPickable if available
	_make_pickable(_handle_a)
	_make_pickable(_handle_b)

func _make_pickable(_handle: Node3D):
	if ResourceLoader.exists("res://addons/godot-xr-tools/objects/pickable.gd"):
		# Create a RigidBody3D wrapper for XR picking
		pass  # Handle via Area3D for now

func _create_labels():
	# Exhibition plate - in front, tilted like museum label
	_title_panel = VectorVisuals.create_exhibition_plate(self, "TitlePanel", 
		"VECTOR ADDITION",
		"Aâƒ— + Bâƒ— = Câƒ—\nHead-to-tail method",
		Vector3(0, 0.05, max_vector_length + 0.3),
		Vector2(0.4, 0.12))
	
	# Formula panel - to the right side, facing player
	_formula_panel = VectorVisuals.create_panel(self, "FormulaPanel", "",
		Vector3(max_vector_length + 0.25, max_vector_length * 0.5, 0),
		Vector2(0.48, 0.2), 11, HORIZONTAL_ALIGNMENT_LEFT)
	_formula_panel.rotation_degrees = Vector3(0, -90, 0)
	
	# Vector labels - smaller
	_label_a = VectorVisuals.create_vector_label(self, "LabelA", "Aâƒ—", color_a)
	_label_b = VectorVisuals.create_vector_label(self, "LabelB", "Bâƒ—", color_b)
	_label_result = VectorVisuals.create_vector_label(self, "LabelResult", "Aâƒ—+Bâƒ—", color_result)

func _create_vr_controls():
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_panel("VECTOR ADD", [
		[{"type": "button", "label": "ORTHO"}, {"type": "button", "label": "ACUTE"}, {"type": "button", "label": "3D"}, {"type": "button", "label": "RESET"}],
	])
	_control_panel.position = Vector3(0, 0.08, max_vector_length + 0.45)
	_control_panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(_control_panel)

	var presets = [
		[Vector3(0.9, 0, 0), Vector3(0, 0.8, 0)],
		[Vector3(0.7, 0.3, 0), Vector3(0.3, 0.7, 0)],
		[Vector3(0.6, 0.3, 0.3), Vector3(0.2, 0.5, 0.4)],
		[Vector3(0.8, 0.3, 0), Vector3(0.2, 0.6, 0.3)],
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

func _update_vectors():
	var result = vector_a + vector_b
	
	# Position main arrows - all same thin thickness
	VectorVisuals.position_arrow(_arrow_a, Vector3.ZERO, vector_a, arrow_thickness)
	VectorVisuals.position_arrow(_arrow_b, Vector3.ZERO, vector_b, arrow_thickness)
	VectorVisuals.position_arrow(_arrow_result, Vector3.ZERO, result, arrow_thickness)
	
	# Ghost arrows (parallelogram)
	VectorVisuals.position_arrow(_arrow_a_ghost, vector_b, vector_b + vector_a, arrow_thickness)
	VectorVisuals.position_arrow(_arrow_b_ghost, vector_a, vector_a + vector_b, arrow_thickness)
	
	# Update labels - offset toward +Z so they face the player
	_label_a.position = vector_a * 0.5 + Vector3(0, 0.06, 0.08)
	_label_b.position = vector_b * 0.5 + Vector3(0, 0.06, 0.08)
	_label_result.position = result * 0.5 + Vector3(0, 0.08, 0.1)
	
	# Update formula panel
	var formula_label = VectorVisuals.get_panel_label(_formula_panel)
	if formula_label:
		formula_label.text = "Aâƒ— = (%.2f, %.2f, %.2f)\n" % [vector_a.x, vector_a.y, vector_a.z]
		formula_label.text += "Bâƒ— = (%.2f, %.2f, %.2f)\n\n" % [vector_b.x, vector_b.y, vector_b.z]
		formula_label.text += "Aâƒ— + Bâƒ— = (%.2f, %.2f, %.2f)\n" % [result.x, result.y, result.z]
		formula_label.text += "|Aâƒ— + Bâƒ—| = %.3f" % result.length()

	# WORKINGS, applied LAST so nothing above it moves. "trace" restores every layer and
	# builds nothing at all - the legacy lineage, byte for byte.
	_apply_workings(result)

func _process(delta):
	_time += delta
	
	# Animate handles
	VectorVisuals.pulse_handle(_handle_a, delta, _time)
	VectorVisuals.pulse_handle(_handle_b, delta, _time + 1.0)
	
	# Animate arrows
	VectorVisuals.pulse_arrow(_arrow_result, delta, _time)
	
	# Check handle positions (for VR/dragging)
	if _handle_a.position != vector_a:
		vector_a = _handle_a.position
	if _handle_b.position != vector_b:
		vector_b = _handle_b.position

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: _apply_preset(Vector3(0.9, 0, 0), Vector3(0, 0.8, 0))
			KEY_2: _apply_preset(Vector3(0.7, 0.3, 0), Vector3(0.3, 0.7, 0))
			KEY_3: _apply_preset(Vector3(0.6, 0.3, 0.3), Vector3(0.2, 0.5, 0.4))
			KEY_R: _apply_preset(Vector3(0.8, 0.3, 0), Vector3(0.2, 0.6, 0.3))

func set_vectors(a: Vector3, b: Vector3):
	vector_a = a
	vector_b = b
	_handle_a.position = vector_a
	_handle_b.position = vector_b

func get_result() -> Vector3:
	return vector_a + vector_b

## Guarded on all three counts this corpus has been burned by: the key must be NAMED, the
## word must VALIDATE, and the value must actually DIFFER. Nothing is redrawn otherwise, and
## nothing is redrawn at all until _ready has built once - _workings_root is null before
## that, and the pending value is picked up by _ready's own _update_vectors().
##
## The generic set() loop underneath is the shipped behaviour and is left intact, minus the
## two axis names: letting it assign `workings` or `pair` directly would write the field and
## skip the redraw, so a map naming an axis would get the value stored and the picture not
## changed - the quietest possible way to publish a sweep of identical frames.
func apply_grid_config(config_data: Dictionary):
	var touched: bool = false
	if config_data.has("workings"):
		var w: String = String(config_data["workings"]).strip_edges().to_lower()
		if WORKINGS.has(w) and w != workings:
			workings = w
			touched = true
	if config_data.has("pair"):
		var p: String = String(config_data["pair"]).strip_edges().to_lower()
		if PAIRS.has(p) and p != pair:
			pair = p
			if _workings_root != null:
				# Re-derive B for the new relationship and carry its handle with it, or
				# _process drags the old operand straight back in on the next frame.
				_building = true
				vector_b = _paired_b()
				_building = false
				if _handle_b != null:
					_handle_b.position = vector_b
			touched = true
	for key in config_data:
		if key == "workings" or key == "pair":
			continue
		if key in self:
			set(key, config_data[key])
	if touched and is_inside_tree() and _workings_root != null:
		_update_vectors()


# --- PAIR --------------------------------------------------------------------
# What kind of pair is being added. The magnitude of B is held constant across every value,
# so the axis moves the ANGLE and nothing else - a longer arrow would be a size change, not
# a different argument.


## An unrecognised word falls back to the shipped operands rather than stranding a live
## placement with a bench nobody chose.
func _pair_value() -> String:
	var p: String = String(pair).strip_edges().to_lower()
	return p if PAIRS.has(p) else "oblique"


## B as `pair` reads it. `oblique` hands back the shipped vector itself rather than
## re-deriving it from an angle - bit-identical today, and a map that overrides vector_b
## alone still gets exactly the vector it asked for.
func _paired_b() -> Vector3:
	var p: String = _pair_value()
	if p == "oblique":
		return vector_b
	var mag: float = vector_b.length()
	if mag < 0.0001 or vector_a.length() < 0.0001:
		return vector_b
	var a_dir: Vector3 = vector_a.normalized()
	if p == "parallel":
		return a_dir * mag
	if p == "opposed":
		return -a_dir * mag
	# orthogonal - a perpendicular in the plane the shipped pair already lives in, so the
	# figure stays broadside to the player instead of turning edge-on.
	var ref: Vector3 = Vector3.FORWARD
	if absf(a_dir.dot(ref)) > 0.985:
		ref = Vector3.UP
	var perp: Vector3 = a_dir.cross(ref)
	if perp.length() < 0.0001:
		return vector_b
	return perp.normalized() * mag


# --- WORKINGS ----------------------------------------------------------------
# One axis, four values, shared word for word with the rest of the vector subject. Every
# builder writes only into _workings_root; removal is always `layers = 0` on the
# MeshInstance3D / Label3D leaves - never `visible = false`, which in Godot takes a holder's
# whole subtree with it, and which VectorVisuals.position_arrow owns on these arrows anyway.


func _workings_value() -> String:
	var w: String = String(workings).strip_edges().to_lower()
	return w if WORKINGS.has(w) else "trace"


func _set_layers(n: Node, bits: int) -> void:
	if n is VisualInstance3D:
		(n as VisualInstance3D).layers = bits
	for child in n.get_children():
		_set_layers(child, bits)


func _apply_workings(result: Vector3) -> void:
	if _workings_root == null:
		return
	for c in _workings_root.get_children():
		_workings_root.remove_child(c)
		c.queue_free()

	var mode: String = _workings_value()

	# Restore first, so a value change at runtime is reversible and the default is always
	# exactly today's build.
	for n in [_arrow_a, _arrow_b, _arrow_a_ghost, _arrow_b_ghost, _label_a, _label_b]:
		if n != null:
			_set_layers(n, 1)

	match mode:
		"outcome":
			# The sum alone. Both operands and both ghosts leave the render layers with
			# their labels; A + B stands from the origin with nothing to say where it came
			# from. The two grab handles stay, exactly as they do on the subtraction twin.
			for n in [_arrow_a, _arrow_b, _arrow_a_ghost, _arrow_b_ghost, _label_a, _label_b]:
				if n != null:
					_set_layers(n, 0)
		"operands":
			# The figure, not the walk. The two ghost legs retire and the same closure is
			# redrawn as dashed sides in the result's green, with the operand tips and the
			# far corner marked - the sum read as a DIAGONAL rather than as a journey.
			for n in [_arrow_a_ghost, _arrow_b_ghost]:
				if n != null:
					_set_layers(n, 0)
			var side: Color = Color(color_result.r, color_result.g, color_result.b, 0.5)
			_workings_root.add_child(_w_dashed(vector_a, result, side))
			_workings_root.add_child(_w_dashed(vector_b, result, side))
			_workings_root.add_child(_w_dot(vector_a, color_a))
			_workings_root.add_child(_w_dot(vector_b, color_b))
			_workings_root.add_child(_w_dot(result, color_result))
		"expression":
			_workings_root.add_child(_w_board(result))
		_:
			pass                                   # "trace" - the legacy lineage


## A dashed guide between two points - the parallelogram sides.
func _w_dashed(from: Vector3, to: Vector3, color: Color) -> Node3D:
	var root := Node3D.new()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(color.r, color.g, color.b, 1.0)
	mat.emission_energy_multiplier = 0.9
	var mesh := SphereMesh.new()
	mesh.radius = 0.011
	mesh.height = 0.022
	mesh.radial_segments = 8
	mesh.rings = 4
	var n: int = 13
	for i in range(n):
		if i % 2 == 1:
			continue
		var dot := MeshInstance3D.new()
		dot.mesh = mesh
		dot.material_override = mat
		dot.position = from.lerp(to, float(i) / float(n - 1))
		root.add_child(dot)
	return root


func _w_dot(at: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.022
	mesh.height = 0.044
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.4
	mi.material_override = mat
	mi.position = at
	return mi


## EXPRESSION - a board writing the sum out with the components substituted, between two
## emissive rules in the result's green.
##
## It stands BEHIND the figure at z = -(max_vector_length + 0.15), facing the player's side,
## rather than above it like the subtraction twin's board. That is a framing decision with a
## number behind it: the ground plane this bench builds is max_vector_length * 2.5 = 3.0 m
## square, so the capture AABB already spans +/-1.5 in X and Z and only ~1.1 in Y. A board
## overhead would have pushed the Y extent to ~2.0 and pulled the camera back on EVERY
## variant in the sweep, including the ones it does not appear in. Here it costs nothing:
## it sits inside the ground's own footprint and below the arrows' own height.
func _w_board(result: Vector3) -> Node3D:
	var board := Node3D.new()
	board.name = "WorkingsBoard"
	board.position = Vector3(0.0, 0.55, -(max_vector_length + 0.15))
	var w: float = max_vector_length * 1.6
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
	rule_mat.albedo_color = color_result
	rule_mat.emission_enabled = true
	rule_mat.emission = color_result
	rule_mat.emission_energy_multiplier = 2.0
	for sy in [1.0, -1.0]:
		var rule := MeshInstance3D.new()
		var rb := BoxMesh.new()
		rb.size = Vector3(w, h * 0.06, 0.024)
		rule.mesh = rb
		rule.material_override = rule_mat
		rule.position = Vector3(0.0, sy * h * 0.5, 0.012)
		board.add_child(rule)
	var l := Label3D.new()
	l.name = "Algebra"
	l.text = "A  +  B  =  C\n(%+.2f, %+.2f, %+.2f) + (%+.2f, %+.2f, %+.2f)\n=  (%+.2f, %+.2f, %+.2f)" % [
		vector_a.x, vector_a.y, vector_a.z,
		vector_b.x, vector_b.y, vector_b.z,
		result.x, result.y, result.z]
	l.font_size = 30
	l.pixel_size = h / 300.0
	l.modulate = Color(0.17, 0.17, 0.19)
	l.outline_size = 5
	l.outline_modulate = Color(0.90, 0.88, 0.84, 0.9)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = Vector3(0.0, 0.0, 0.02)
	board.add_child(l)
	return board
