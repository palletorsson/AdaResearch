extends Node3D

# @identity
# essence: Cycling demonstration of rotation, scaling, translation, and shearing applied to point, line, plane, and cube primitives
# desire: To make matrix transformations visible: watch the same four operations reshape four geometric objects in sequence
# critical_parameter: stage_interval — seconds per transformation type; controls the pace of the demonstration cycle
# triggers: Each 3-second stage applies a new transformation; the four primitives deform together showing how transforms compose
# emerges: Understanding that all mesh deformation reduces to four matrix operations applied to vertices
# needs: Material setup [has], scene child references [has], VR interaction [missing — auto-cycling demo]
# relationships: Core artifact across Meshes_One, Meshes_Three, and Meshes_Four. Foundation for all procedural geometry.
# truth: A vertex does not know what shape it belongs to — it only knows the matrix that moves it.

# ═════════════════════════════════════════════════════════════════════════
# DNA — two declared axes (promoted 2026-08-03)
#
# stance: WHERE the four primitives stand relative to each other. The lineup
#   along X was never a neutral fact: a row reads as four separate exhibits in
#   a vitrine, a stack reads as a dimensional ladder (0D at the bottom, 3D at
#   the top), a ring refuses to rank them at all, and origin superimposes all
#   four on one point so the same matrix visibly acts on one shared vertex
#   cloud — the artifact's own truth statement, staged.
#
# workings: HOW MUCH of the operation is drawn. Shares its word and its four
#   values, in order, with transform_composition_workbench and the vector_op
#   console, so a room cannot show a composed transform as a bare answer while
#   showing a vector sum as a walked route.
#     outcome    — only the transformed primitive (what this always did)
#     trace      — a smear of the primitive's own recent poses: the path
#     operands   — a faint copy frozen at the untransformed base pose
#     expression — the operand ghost plus the live 3x3 basis, written out
# ═════════════════════════════════════════════════════════════════════════

const STANCES: Array = ["row", "stack", "ring", "origin"]
const WORKINGS: Array = ["outcome", "trace", "operands", "expression"]

@export_enum("row", "stack", "ring", "origin") var stance: String = "row"
@export_enum("outcome", "trace", "operands", "expression") var workings: String = "outcome"

# The historical lineup reached x = ±6 with 4 units between neighbours. Every
# stance is built from this one span so no stance is bigger than another.
const LAYOUT_SPAN: float = 6.0

const GHOST_STEPS: int = 4      # ghost copies per primitive (trace uses all, operands uses one)
const TRACE_STRIDE: int = 6     # frames between the poses a trace ghost samples
const HISTORY_LEN: int = 28

var time = 0.0
var transformation_stage = 0
var stage_timer = 0.0
var stage_interval = 3.0

# Transformation types
enum TransformationType {
	ROTATION,
	SCALING,
	TRANSLATION,
	SHEARING
}

var current_transformation = TransformationType.ROTATION

var _built: bool = false
var _primitives: Array = []      # the four staged Node3D, in dimension order
var _bases: Array = []           # Vector3 base position per primitive, from stance
var _ghost_root: Node3D = null
var _ghosts: Array = []          # Array of Array[MeshInstance3D], one row per primitive
var _matrix_labels: Array = []   # Label3D per primitive, only shown for workings=expression
var _history: Array = []         # Array of Array[Transform3D], recent poses per primitive

func _ready() -> void:
	_collect_primitives()
	_bases = _stance_positions()
	setup_materials()
	setup_initial_transforms()
	_build_ghosts()
	_build_matrix_labels()
	_apply_workings()
	_built = true

func _collect_primitives() -> void:
	if _primitives.size() == 4:
		return
	_primitives = [$Point, $Line, $Plane, $Cube]

## Base positions for the current stance. "row" returns the historical
## (-6,0,0) (-2,0,0) (2,0,0) (6,0,0) exactly, so existing placements are untouched.
func _stance_positions() -> Array:
	var s: float = LAYOUT_SPAN
	var inner: float = s / 3.0
	if stance == "stack":
		return [Vector3(0, -s, 0), Vector3(0, -inner, 0), Vector3(0, inner, 0), Vector3(0, s, 0)]
	if stance == "ring":
		return [Vector3(s, 0, 0), Vector3(0, 0, s), Vector3(-s, 0, 0), Vector3(0, 0, -s)]
	if stance == "origin":
		return [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]
	return [Vector3(-s, 0, 0), Vector3(-inner, 0, 0), Vector3(inner, 0, 0), Vector3(s, 0, 0)]

func setup_materials() -> void:
	# Point material - bright white
	var point_material = StandardMaterial3D.new()
	point_material.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	point_material.emission_enabled = true
	point_material.emission = Color(0.8, 0.8, 0.8, 1.0)
	$Point.material_override = point_material

	# Line material - blue
	var line_material = StandardMaterial3D.new()
	line_material.albedo_color = Color(0.3, 0.7, 1.0, 1.0)
	line_material.emission_enabled = true
	line_material.emission = Color(0.1, 0.2, 0.4, 1.0)
	$Line.material_override = line_material

	# Plane material - green with transparency
	var plane_material = StandardMaterial3D.new()
	plane_material.albedo_color = Color(0.3, 1.0, 0.3, 0.7)
	plane_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	plane_material.emission_enabled = true
	plane_material.emission = Color(0.1, 0.3, 0.1, 1.0)
	$Plane.material_override = plane_material

	# Cube material - red (applied to the CubeBaseMesh inside cube_scene.tscn)
	var cube_material = StandardMaterial3D.new()
	cube_material.albedo_color = Color(1.0, 0.3, 0.3, 1.0)
	cube_material.emission_enabled = true
	cube_material.emission = Color(0.4, 0.1, 0.1, 1.0)

	# Apply material to the MeshInstance3D inside the cube scene
	var cube_mesh = $Cube.get_node("CubeBaseStaticBody3D/CubeBaseMesh")
	if cube_mesh:
		cube_mesh.material_override = cube_material

	# Transformation indicator materials
	var rotation_material = StandardMaterial3D.new()
	rotation_material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
	rotation_material.emission_enabled = true
	rotation_material.emission = Color(0.3, 0.2, 0.05, 1.0)
	$TransformationControls/RotationIndicator.material_override = rotation_material

	var scale_material = StandardMaterial3D.new()
	scale_material.albedo_color = Color(0.8, 0.2, 1.0, 1.0)
	scale_material.emission_enabled = true
	scale_material.emission = Color(0.2, 0.05, 0.3, 1.0)
	$TransformationControls/ScaleIndicator.material_override = scale_material

	var translation_material = StandardMaterial3D.new()
	translation_material.albedo_color = Color(0.2, 1.0, 0.8, 1.0)
	translation_material.emission_enabled = true
	translation_material.emission = Color(0.05, 0.3, 0.2, 1.0)
	$TransformationControls/TranslationIndicator.material_override = translation_material

func setup_initial_transforms() -> void:
	# Reset all objects to base positions (the stance decides where those are)
	_collect_primitives()
	if _bases.size() < 4:
		_bases = _stance_positions()
	for i in range(_primitives.size()):
		var node: Node3D = _primitives[i]
		if node == null:
			continue
		node.position = _bases[i]
		node.scale = Vector3.ONE
		node.rotation = Vector3.ZERO

func _process(delta: float) -> void:
	time += delta
	stage_timer += delta

	# Cycle through transformation types
	if stage_timer >= stage_interval:
		stage_timer = 0.0
		current_transformation = (current_transformation + 1) % TransformationType.size()

		# Reset transforms when starting new cycle
		if current_transformation == TransformationType.ROTATION:
			setup_initial_transforms()

	apply_transformations()
	animate_indicators()
	_update_ghosts()
	_update_matrix_labels()

func apply_transformations() -> void:
	var progress = stage_timer / stage_interval
	var smooth_progress = smoothstep(0.0, 1.0, progress)

	match current_transformation:
		TransformationType.ROTATION:
			apply_rotation_transformations(smooth_progress)

		TransformationType.SCALING:
			apply_scaling_transformations(smooth_progress)

		TransformationType.TRANSLATION:
			apply_translation_transformations(smooth_progress)

		TransformationType.SHEARING:
			apply_shearing_transformations(smooth_progress)

func apply_rotation_transformations(progress) -> void:
	# Point: Simple pulsing (0D -> can't really rotate, so pulse instead)
	var pulse = 1.0 + sin(time * 4.0) * 0.3
	$Point.scale = Vector3.ONE * pulse

	# Line: Rotate around Y-axis
	$Line.rotation.y = progress * PI * 2.0

	# Plane: Rotate around X and Z axes
	$Plane.rotation.x = progress * PI
	$Plane.rotation.z = progress * PI * 0.5

	# Cube: Complex rotation around multiple axes
	$Cube.rotation.x = progress * PI * 1.5
	$Cube.rotation.y = progress * PI * 2.0
	$Cube.rotation.z = progress * PI * 0.75

func apply_scaling_transformations(progress) -> void:
	# Point: Scale uniformly
	var scale_factor = 1.0 + progress * 2.0
	$Point.scale = Vector3.ONE * scale_factor

	# Line: Scale length (Y-axis)
	$Line.scale.y = 1.0 + progress * 2.0

	# Plane: Non-uniform scaling
	$Plane.scale.x = 1.0 + progress * 1.5
	$Plane.scale.z = 1.0 + progress * 0.5

	# Cube: Asymmetric scaling
	$Cube.scale.x = 1.0 + sin(progress * PI) * 1.0
	$Cube.scale.y = 1.0 + cos(progress * PI) * 1.0
	$Cube.scale.z = 1.0 + progress * 0.8

func apply_translation_transformations(progress) -> void:
	var base_positions: Array = _bases

	# Point: Linear motion
	$Point.position = base_positions[0] + Vector3(0, sin(progress * PI) * 2.0, 0)

	# Line: Circular motion
	var angle = progress * PI * 2.0
	$Line.position = base_positions[1] + Vector3(cos(angle) * 1.0, sin(angle) * 1.0, 0)

	# Plane: Figure-8 motion
	$Plane.position = base_positions[2] + Vector3(
		sin(progress * PI * 2.0) * 1.0,
		sin(progress * PI * 4.0) * 0.5,
		cos(progress * PI * 2.0) * 0.5
	)

	# Cube: Complex 3D path
	$Cube.position = base_positions[3] + Vector3(
		sin(progress * PI * 3.0) * 0.8,
		cos(progress * PI * 2.0) * 1.2,
		sin(progress * PI * 4.0) * 0.6
	)

func apply_shearing_transformations(progress) -> void:
	# Create shearing effect using transform basis manipulation
	var shear_amount = progress * 0.5

	# Point: No shearing (0D), but add wobble effect
	var wobble = sin(time * 6.0) * 0.1
	$Point.position.x = _bases[0].x + wobble

	# Line: Shear along one axis
	var line_transform = Transform3D()
	line_transform.basis = Basis(
		Vector3(1.0, shear_amount, 0),
		Vector3(0, 1.0, 0),
		Vector3(0, 0, 1.0)
	)
	line_transform.origin = _bases[1]
	$Line.transform = line_transform

	# Plane: Shear in multiple directions
	var plane_transform = Transform3D()
	plane_transform.basis = Basis(
		Vector3(1.0, shear_amount * 0.5, 0),
		Vector3(shear_amount * 0.3, 1.0, 0),
		Vector3(0, 0, 1.0)
	)
	plane_transform.origin = _bases[2]
	$Plane.transform = plane_transform

	# Cube: Complex 3D shearing
	var cube_transform = Transform3D()
	cube_transform.basis = Basis(
		Vector3(1.0, shear_amount * 0.4, shear_amount * 0.2),
		Vector3(shear_amount * 0.3, 1.0, shear_amount * 0.1),
		Vector3(shear_amount * 0.1, shear_amount * 0.2, 1.0)
	)
	cube_transform.origin = _bases[3]
	$Cube.transform = cube_transform

func animate_indicators() -> void:
	# Highlight current transformation indicator
	var indicators = [
		$TransformationControls/RotationIndicator,
		$TransformationControls/ScaleIndicator,
		$TransformationControls/TranslationIndicator,
		$TransformationControls/RotationIndicator  # Rotation for shearing (placeholder)
	]

	# Reset all indicators
	for i in range(indicators.size()):
		var indicator = indicators[i]
		var base_scale = 1.0
		var glow_intensity = 0.2

		if i == current_transformation:
			base_scale = 1.0 + sin(time * 8.0) * 0.3
			glow_intensity = 0.5 + sin(time * 6.0) * 0.3

		indicator.scale = Vector3.ONE * base_scale

		# Update emission intensity
		var material = indicator.material_override as StandardMaterial3D
		if material:
			var base_emission = material.emission
			material.emission = base_emission * glow_intensity

func get_transformation_name() -> String:
	match current_transformation:
		TransformationType.ROTATION:
			return "Rotation"
		TransformationType.SCALING:
			return "Scaling"
		TransformationType.TRANSLATION:
			return "Translation"
		TransformationType.SHEARING:
			return "Shearing"
		_:
			return "Unknown"


# ═════════════════════════════════════════════════════════════════════════
# WORKINGS — ghosts (operand / trace) and the written-out basis (expression)
# All of it is built once and hidden; at workings=outcome nothing here renders,
# so the four existing placements are pixel-identical to before the promotion.
# ═════════════════════════════════════════════════════════════════════════

func _build_ghosts() -> void:
	if _ghost_root != null:
		return
	_ghost_root = Node3D.new()
	_ghost_root.name = "Ghosts"
	add_child(_ghost_root)

	var meshes: Array = _ghost_meshes()
	var tints: Array = [
		Color(1.0, 1.0, 1.0),
		Color(0.3, 0.7, 1.0),
		Color(0.3, 1.0, 0.3),
		Color(1.0, 0.3, 0.3)
	]
	for i in range(_primitives.size()):
		var row: Array = []
		for g in range(GHOST_STEPS):
			var ghost: MeshInstance3D = MeshInstance3D.new()
			ghost.name = "Ghost_%d_%d" % [i, g]
			ghost.mesh = meshes[i]
			var fade: float = 0.30 - 0.06 * float(g)
			ghost.material_override = _ghost_material(tints[i], fade)
			ghost.visible = false
			_ghost_root.add_child(ghost)
			row.append(ghost)
		_ghosts.append(row)
		_history.append([])

## Ghost meshes mirror the CSG primitives (which cannot be duplicated cheaply)
## and reuse the cube scene's own BoxMesh.
func _ghost_meshes() -> Array:
	var sphere: SphereMesh = SphereMesh.new()
	var pr: float = _node_number($Point, "radius", 0.15)
	sphere.radius = pr
	sphere.height = pr * 2.0
	sphere.radial_segments = 12
	sphere.rings = 8

	var cyl: CylinderMesh = CylinderMesh.new()
	var lr: float = _node_number($Line, "radius", 0.5)
	cyl.top_radius = lr
	cyl.bottom_radius = lr
	cyl.height = _node_number($Line, "height", 3.0)
	cyl.radial_segments = 12

	var slab: BoxMesh = BoxMesh.new()
	var plane_size = $Plane.get("size")
	if plane_size is Vector3:
		slab.size = plane_size
	else:
		slab.size = Vector3(2.0, 0.1, 2.0)

	var cube_mesh: Mesh = null
	var cube_node: MeshInstance3D = $Cube.get_node_or_null("CubeBaseStaticBody3D/CubeBaseMesh")
	if cube_node != null and cube_node.mesh != null:
		cube_mesh = cube_node.mesh
	else:
		cube_mesh = BoxMesh.new()

	return [sphere, cyl, slab, cube_mesh]

func _node_number(node: Node, property: String, fallback: float) -> float:
	if node == null:
		return fallback
	var raw = node.get(property)
	if typeof(raw) == TYPE_FLOAT or typeof(raw) == TYPE_INT:
		return float(raw)
	return fallback

func _ghost_material(tint: Color, alpha: float) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(tint.r, tint.g, tint.b, clampf(alpha, 0.05, 0.9))
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat

func _build_matrix_labels() -> void:
	if _matrix_labels.size() > 0:
		return
	for i in range(_primitives.size()):
		var label: Label3D = Label3D.new()
		label.name = "Basis_%d" % i
		label.text = ""
		label.font_size = 22
		label.outline_size = 5
		label.outline_modulate = Color.BLACK
		label.modulate = Color(0.85, 0.92, 1.0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.render_priority = 100
		label.visible = false
		add_child(label)
		_matrix_labels.append(label)

func _apply_workings() -> void:
	var ghost_count: int = 0
	if workings == "trace":
		ghost_count = GHOST_STEPS
	elif workings == "operands" or workings == "expression":
		ghost_count = 1
	for i in range(_ghosts.size()):
		var row: Array = _ghosts[i]
		for g in range(row.size()):
			var ghost: MeshInstance3D = row[g]
			if ghost != null:
				ghost.visible = g < ghost_count
	for i in range(_matrix_labels.size()):
		var label: Label3D = _matrix_labels[i]
		if label != null:
			label.visible = workings == "expression"

func _update_ghosts() -> void:
	if workings == "outcome":
		return
	if _ghosts.size() != _primitives.size():
		return
	for i in range(_primitives.size()):
		var node: Node3D = _primitives[i]
		if node == null:
			continue
		var row: Array = _ghosts[i]
		if workings == "trace":
			var hist: Array = _history[i]
			hist.push_front(node.transform)
			while hist.size() > HISTORY_LEN:
				hist.pop_back()
			for g in range(row.size()):
				var ghost: MeshInstance3D = row[g]
				if ghost == null:
					continue
				var idx: int = (g + 1) * TRACE_STRIDE
				if idx >= hist.size():
					idx = hist.size() - 1
				if idx >= 0:
					ghost.transform = hist[idx]
		else:
			# operands / expression: one ghost frozen at the untransformed pose
			var operand: MeshInstance3D = row[0]
			if operand != null:
				operand.transform = Transform3D(Basis.IDENTITY, _bases[i])

func _update_matrix_labels() -> void:
	if workings != "expression":
		return
	if _matrix_labels.size() != _primitives.size():
		return
	for i in range(_primitives.size()):
		var node: Node3D = _primitives[i]
		var label: Label3D = _matrix_labels[i]
		if node == null or label == null:
			continue
		var b: Basis = node.transform.basis
		label.text = "%s\n[%5.2f %5.2f %5.2f]\n[%5.2f %5.2f %5.2f]\n[%5.2f %5.2f %5.2f]" % [
			get_transformation_name(),
			b.x.x, b.y.x, b.z.x,
			b.x.y, b.y.y, b.z.y,
			b.x.z, b.y.z, b.z.z]
		label.position = node.position + Vector3(0.0, 2.0, 0.0)


# ═════════════════════════════════════════════════════════════════════════
# GRID CONFIG — guarded: only restage when a value actually changed, and only
# after _ready has staged once. A map token that names neither axis is a no-op.
# ═════════════════════════════════════════════════════════════════════════

func apply_grid_config(config: Dictionary) -> void:
	if config == null:
		return
	var restage: bool = false
	var revisit: bool = false

	if config.has("stance"):
		var new_stance: String = str(config["stance"])
		if new_stance != stance and new_stance in STANCES:
			stance = new_stance
			restage = true

	if config.has("workings"):
		var new_workings: String = str(config["workings"])
		if new_workings != workings and new_workings in WORKINGS:
			workings = new_workings
			revisit = true

	if not _built:
		# _ready has not staged yet — it will read the new values itself.
		return

	if restage:
		_bases = _stance_positions()
		stage_timer = 0.0
		current_transformation = TransformationType.ROTATION
		setup_initial_transforms()
		for i in range(_history.size()):
			var hist: Array = _history[i]
			hist.clear()
	if revisit:
		_apply_workings()
