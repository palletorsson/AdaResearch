# This script generates a VR-optimized Koch snowflake fractal.
# It uses a single ArrayMesh instead of multiple CSG nodes for performance.
#
# @identity
# essence: koch_segment(p1, p2) = [p1, p1+1/3, peak, p1+2/3, p2], equilateral bump on middle third. Iterated on a triangle.
# desire: To cycle — iteration wraps from 0 to max_iterations and back, the snowflake assembling and resetting endlessly
# critical_parameter: max_iterations (4) — at 0 it is a triangle, at 4 it has 768 segments; the ribbon width keeps it VR-readable
# triggers: iteration_interval tick → advance iteration (wrapping); each step applies Koch rule to all segments then rebuilds ArrayMesh
# emerges: Color gradients per segment — iteration_intensity and segment position create a procedural aurora across the snowflake
# needs: VR manual iteration control [missing], zoom [missing]
# relationships: VR-optimized ArrayMesh Koch; contrasts with fractal_koch_curve (ImmediateMesh, depth slider) and koch_curve_3d (3D portal)
# truth: The Koch snowflake rebuilds itself from scratch each cycle — it does not remember its history, only its rule.

extends Node3D

# VR-Optimized State Variables
var time = 0.0
var current_iteration = 0
var max_iterations = 4
var iteration_timer = 0.0
var iteration_interval = 3.0
var total_segments = 0

# Koch curve generation data
var points = []

# VR-Optimized rendering (NO CSG!)
var koch_mesh_instance: MeshInstance3D
var iteration_mesh_instance: MeshInstance3D
var complexity_mesh_instance: MeshInstance3D

# Materials
var koch_material: StandardMaterial3D
var iter_material: StandardMaterial3D
var complexity_material: StandardMaterial3D

# ═══════════════════════════════════════════════════════════════════
# STAGE-2 DNA — `evidence`
# ═══════════════════════════════════════════════════════════════════
#
# WHAT THE FINISHED OBJECT SHOWS OF ITS OWN ITERATION. A recursive figure can
# stand in a room as a product with its making erased, or it can carry the
# making on its face. That is not a question about the Koch rule; it is a
# question about what a fractal is FOR in a teaching room, and it is the same
# question sine_wave_controller and wave_interference_tank already ask, so this
# takes THEIR WORD AND THEIR FIRST THREE VALUES rather than inventing a synonym.
#
#   result    the shipped snowflake: one curve, the timed cycle running, the
#             ladder it climbed nowhere on show. Byte for byte the legacy build.
#   trace     all five generations at once, drawn at the SAME scale (the Koch
#             curve nests — iteration 4 contains iteration 0) and pulled apart
#             along Z in 0.6 m steps. Five plates receding from the camera,
#             cold blue at the triangle to hot magenta at 768 segments: the
#             growth record of one figure instead of one frame of it.
#   longhand  the working shown. The curve keeps its place; underneath it the
#             production rule is drawn at 28 m — one straight bar, a chevron,
#             and the four-segment generator that replaces it. The rule beside
#             the result, the way a proof is written out rather than asserted.
#   axiom     the initiator alone: the bare 40 m equilateral triangle at triple
#             ribbon width, before the rule has ever been applied. The negative
#             space the whole apparatus exists against.
#
# The three non-default values STOP THE TIMED CYCLE. They are exhibits, not a
# loop — and an axis whose value is repainted every three seconds by _process
# would be an axis a still cannot photograph. `result` keeps the cycle exactly
# as shipped.
@export_enum("result", "trace", "longhand", "axiom") var evidence: String = "result"

## Allow-list. A typo in a map token falls back to the shipped snowflake rather
## than stranding a placement with an empty node.
const EVIDENCES: PackedStringArray = ["result", "trace", "longhand", "axiom"]

## Set by the non-default values: the exhibit stands still.
var _static_build: bool = false
## Multiplies the shipped 0.4 m ribbon half-width. 1.0 reproduces the legacy mesh.
var _ribbon_scale: float = 1.0
## Children built by `trace` / `longhand`, freed before a rebuild.
var _evidence_parts: Array[MeshInstance3D] = []

# Layout of the `longhand` panel, in metres (the triangle spans y -11.6 .. 23.1).
const RULE_SPAN: float = 28.0        # width of the before-bar and the generator
const RULE_BEFORE_Y: float = -18.0   # the segment as it stands
const RULE_AFTER_Y: float = -30.0    # the same segment after one application
const RULE_WIDTH: float = 0.9        # ribbon half-width of the rule diagram

func _ready() -> void:
	"""Initializes the scene, materials, and the base Koch curve."""
	setup_vr_optimized_scene()
	setup_materials()
	initialize_koch_curve()
	# The first iteration is generated immediately on start.
	generate_next_iteration()
	# APPENDED LAST so the legacy build above is untouched at the default value.
	_apply_evidence()

func setup_vr_optimized_scene() -> void:
	"""Setup VR-optimized mesh instances instead of CSG nodes."""
	
	# Main Koch curve mesh
	koch_mesh_instance = MeshInstance3D.new()
	koch_mesh_instance.name = "KochMesh"
	add_child(koch_mesh_instance)
	
	# Iteration control indicator (single mesh)
	iteration_mesh_instance = MeshInstance3D.new()
	iteration_mesh_instance.name = "IterationControl"
	iteration_mesh_instance.position = Vector3(-6, 0, 0)
	add_child(iteration_mesh_instance)
	
	# Complexity indicator (single mesh)
	complexity_mesh_instance = MeshInstance3D.new()
	complexity_mesh_instance.name = "ComplexityIndicator"
	complexity_mesh_instance.position = Vector3(6, 0, 0)
	add_child(complexity_mesh_instance)

func setup_materials() -> void:
	"""Setup VR-optimized materials."""
	
	# Koch curve material
	koch_material = StandardMaterial3D.new()
	koch_material.albedo_color = Color(0.2, 0.8, 1.0, 1.0)
	koch_material.emission_enabled = true
	koch_material.emission = Color(0.1, 0.4, 0.6)
	koch_material.emission_energy_multiplier = 1.5
	koch_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED  # VR optimization
	koch_mesh_instance.material_override = koch_material
	
	# Iteration control material
	iter_material = StandardMaterial3D.new()
	iter_material.albedo_color = Color(1.0, 0.3, 0.3, 1.0)
	iter_material.emission_enabled = true
	iter_material.emission = Color(0.5, 0.1, 0.1, 1.0)
	iter_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	iteration_mesh_instance.material_override = iter_material
	
	# Complexity indicator material
	complexity_material = StandardMaterial3D.new()
	complexity_material.albedo_color = Color(0.2, 1.0, 0.8, 1.0)
	complexity_material.emission_enabled = true
	complexity_material.emission = Color(0.05, 0.3, 0.2, 1.0)
	complexity_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	complexity_mesh_instance.material_override = complexity_material

func initialize_koch_curve() -> void:
	"""Resets the curve to its base equilateral triangle state."""
	points.clear()
	# Increase the size of the base triangle for better VR visibility
	var triangle_size = 40.0
	var height = triangle_size * sqrt(3) / 2.0
	
	# Three vertices of equilateral triangle
	points.append(Vector2(-triangle_size/2, -height/3))
	points.append(Vector2(triangle_size/2, -height/3))
	points.append(Vector2(0, 2*height/3))
	points.append(Vector2(-triangle_size/2, -height/3))  # Close the triangle
	
	# Reset iteration counter
	current_iteration = 0
	# Update visual for base state
	update_vr_optimized_visual()

func _process(delta: float) -> void:
	"""Main game loop, handles animations and timed iteration advancement."""
	# `trace` / `longhand` / `axiom` are exhibits, not the loop. False at the
	# shipped value, so the legacy cycle below runs exactly as before.
	if _static_build:
		return
	time += delta
	iteration_timer += delta
	
	# Advance iteration at a fixed interval
	if iteration_timer >= iteration_interval:
		iteration_timer = 0.0
		generate_next_iteration()
 

func generate_next_iteration() -> void:
	"""
	Applies a single Koch transformation and updates the visual.
	This prevents the recursive loop that caused the stack overflow.
	"""
	current_iteration = (current_iteration + 1) % (max_iterations + 1)
	
	if current_iteration == 0:
		# Reset to base triangle
		initialize_koch_curve()
	else:
		# Apply ONE Koch transformation step
		apply_koch_transformation()
		update_vr_optimized_visual()
	
	print("🔺 Koch iteration: %d, segments: %d" % [current_iteration, total_segments])

func apply_koch_transformation() -> void:
	"""Applies the Koch curve transformation rule to each segment."""
	var new_points = []
	
	for i in range(points.size() - 1):
		var start = points[i]
		var end = points[i + 1]
		
		# Apply Koch curve rule: replace each line segment with a new fractal segment
		var koch_points = generate_koch_segment(start, end)
		
		# Add all points except the last one (to avoid duplication with the next segment)
		for j in range(koch_points.size() - 1):
			new_points.append(koch_points[j])
	
	# Add the final point from the last segment to close the curve
	new_points.append(points[-1])
	points = new_points

func generate_koch_segment(start: Vector2, end: Vector2) -> Array:
	"""
	Implements the core Koch curve rule: divides a segment into thirds
	and creates an equilateral triangle on the middle third.
	"""
	var direction = end - start
	var length = direction.length()
	var unit_dir = direction.normalized()
	
	# Calculate the five points of the new segment
	var p1 = start
	var p2 = start + unit_dir * (length / 3.0)
	var p4 = start + unit_dir * (2.0 * length / 3.0)
	var p5 = end
	
	# Calculate the peak of the equilateral triangle
	var perpendicular = Vector2(-unit_dir.y, unit_dir.x)  # Rotate 90 degrees
	var triangle_height = (length / 3.0) * sqrt(3) / 2.0
	var p3 = p2 + perpendicular * triangle_height
	
	return [p1, p2, p3, p4, p5]

func update_vr_optimized_visual() -> void:
	"""
	Creates a single, optimized VR mesh from the generated points.
	This is much more efficient than using separate meshes for each segment.
	"""
	
	total_segments = points.size() - 1
	
	if points.size() < 2:
		return
	
	# Create single ArrayMesh for the entire Koch curve
	var array_mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	var colors = PackedColorArray()
	
	# Increased thickness for better VR visibility
	# _ribbon_scale is 1.0 at the shipped value, so this is still 0.4 exactly.
	var ribbon_width = 0.4 * _ribbon_scale
	var vertex_index = 0
	
	# Create a ribbon (series of quads) for each segment
	for i in range(points.size() - 1):
		var start = Vector3(points[i].x, points[i].y, 0)
		var end = Vector3(points[i + 1].x, points[i + 1].y, 0)
		
		var direction = (end - start).normalized()
		var perpendicular = Vector3(-direction.y, direction.x, 0) * ribbon_width
		
		# Create quad vertices
		var v1 = start + perpendicular
		var v2 = start - perpendicular
		var v3 = end - perpendicular
		var v4 = end + perpendicular
		
		# Add vertices, normals, and colors
		vertices.append(v1)
		vertices.append(v2)
		vertices.append(v3)
		vertices.append(v4)
		
		var normal = Vector3(0, 0, 1) # Facing towards the camera
		normals.append(normal)
		normals.append(normal)
		normals.append(normal)
		normals.append(normal)
		
		var u_coord = float(i) / float(points.size() - 1)
		uvs.append(Vector2(u_coord, 0))
		uvs.append(Vector2(u_coord, 1))
		uvs.append(Vector2(u_coord, 1))
		uvs.append(Vector2(u_coord, 0))
		
		var color_intensity = float(i) / total_segments
		var iteration_intensity = float(current_iteration) / max_iterations
		
		var segment_color = Color(
			0.2 + iteration_intensity * 0.8,
			0.8 - color_intensity * 0.4,
			0.3 + color_intensity * 0.7,
			1.0
		)
		
		colors.append(segment_color)
		colors.append(segment_color)
		colors.append(segment_color)
		colors.append(segment_color)
		
		# Add indices for the two triangles that form the quad
		indices.append(vertex_index)
		indices.append(vertex_index + 1)
		indices.append(vertex_index + 2)
		
		indices.append(vertex_index)
		indices.append(vertex_index + 2)
		indices.append(vertex_index + 3)
		
		vertex_index += 4
	
	# Build the final mesh from the arrays
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_COLOR] = colors
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, Mesh.ARRAY_FORMAT_NORMAL | Mesh.ARRAY_FORMAT_COLOR)
	koch_mesh_instance.mesh = array_mesh

 
func create_cylinder_mesh(mesh_instance: MeshInstance3D, radius: float, height: float) -> void:
	"""Creates a simple cylinder mesh without CSG."""
	
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = radius
	cylinder_mesh.bottom_radius = radius
	cylinder_mesh.height = height
	cylinder_mesh.segments = 12  # Lower segments for VR performance
	
	mesh_instance.mesh = cylinder_mesh

func get_fractal_info() -> Dictionary:
	"""Gets and returns fractal information for debugging/display."""
	return {
		"iteration": current_iteration,
		"segments": total_segments,
		"theoretical_length": pow(4.0/3.0, float(current_iteration)) * 12.0,
		"vr_optimized": true,
		"mesh_instances": 3  # Instead of hundreds of CSG nodes
	}

# Input handling for testing
func _input(event: InputEvent) -> void:
	"""Handles user input to manually advance the iteration."""
	if event.is_action_pressed("ui_accept"):  # Space key
		generate_next_iteration()
	
	if event.is_action_pressed("ui_select"):  # Enter key
		var info = get_fractal_info()
		print("📊 Fractal Info: ", info)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	# Only the declared axis is read. Everything else in the map token is left
	# alone, exactly as before.
	if config.has("evidence"):
		evidence = str(config["evidence"])
		_apply_evidence()


# ═══════════════════════════════════════════════════════════════════
# `evidence` — APPENDED LAST. Nothing above this line moved.
# ═══════════════════════════════════════════════════════════════════

func _apply_evidence() -> void:
	var want: String = String(evidence).strip_edges().to_lower()
	if not EVIDENCES.has(want):
		want = "result"          # unknown word keeps the shipped snowflake
	evidence = want

	for part in _evidence_parts:
		if is_instance_valid(part):
			part.queue_free()
	_evidence_parts.clear()

	if want == "result":
		_static_build = false
		_ribbon_scale = 1.0
		# Only ever true when a map token switches BACK from `trace`, which
		# blanks the main mesh. On the shipped path the mesh is already built by
		# generate_next_iteration() and this does not fire.
		if koch_mesh_instance != null and koch_mesh_instance.mesh == null:
			update_vr_optimized_visual()
		return

	# The exhibits stand still: a still cannot photograph a three-second cycle.
	_static_build = true
	match want:
		"axiom":
			# The initiator alone, at triple width so a bare triangle still owns
			# the frame the 768-segment curve owned.
			_ribbon_scale = 3.0
			initialize_koch_curve()
			current_iteration = 0
		"trace":
			# Every generation at once. The main mesh steps aside; five ribbons
			# stand in for it, pulled apart along Z.
			koch_mesh_instance.mesh = null
			_build_trace()
		"longhand":
			# The result keeps its place; the rule is written out beneath it.
			_build_longhand()


## Five generations of the same figure, drawn at one scale and separated in Z.
func _build_trace() -> void:
	var gen: Array = _base_triangle()
	for k in range(max_iterations + 1):
		if k > 0:
			gen = _koch_step(gen)
		var t: float = float(k) / float(max_iterations)
		var mi := MeshInstance3D.new()
		mi.name = "TraceGen%d" % k
		mi.position = Vector3(0, 0, -0.6 * float(k))
		mi.mesh = _ribbon_mesh(gen, 0.5 - 0.25 * t)
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.15, 0.55, 1.0).lerp(Color(1.0, 0.25, 0.85), t)
		mat.emission_enabled = true
		mat.emission = mat.albedo_color
		mat.emission_energy_multiplier = 0.6 + t * 1.4
		mi.material_override = mat
		add_child(mi)
		_evidence_parts.append(mi)


## The production rule, drawn full size under the curve: a straight bar, a
## chevron pointing down, and the four segments that replace the bar.
func _build_longhand() -> void:
	var half: float = RULE_SPAN * 0.5
	var before: Array = [Vector2(-half, RULE_BEFORE_Y), Vector2(half, RULE_BEFORE_Y)]
	var after: Array = generate_koch_segment(
		Vector2(-half, RULE_AFTER_Y), Vector2(half, RULE_AFTER_Y))
	var arrow: Array = [
		Vector2(-1.6, RULE_BEFORE_Y - 3.2),
		Vector2(0.0, RULE_BEFORE_Y - 6.0),
		Vector2(1.6, RULE_BEFORE_Y - 3.2),
	]
	_add_rule_part("RuleBefore", before, RULE_WIDTH, Color(0.85, 0.88, 0.95))
	_add_rule_part("RuleArrow", arrow, RULE_WIDTH * 0.7, Color(0.95, 0.72, 0.20))
	_add_rule_part("RuleAfter", after, RULE_WIDTH, Color(1.0, 0.35, 0.30))


func _add_rule_part(part_name: String, pts: Array, width: float, tint: Color) -> void:
	var mi := MeshInstance3D.new()
	mi.name = part_name
	mi.mesh = _ribbon_mesh(pts, width)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = tint
	mat.emission_enabled = true
	mat.emission = tint
	mat.emission_energy_multiplier = 1.2
	mi.material_override = mat
	add_child(mi)
	_evidence_parts.append(mi)


## The base equilateral triangle as a fresh point list (does not touch `points`).
func _base_triangle() -> Array:
	var triangle_size: float = 40.0
	var h: float = triangle_size * sqrt(3) / 2.0
	return [
		Vector2(-triangle_size / 2.0, -h / 3.0),
		Vector2(triangle_size / 2.0, -h / 3.0),
		Vector2(0, 2 * h / 3.0),
		Vector2(-triangle_size / 2.0, -h / 3.0),
	]


## One Koch application over a point list, returned as a new list. A pure copy of
## apply_koch_transformation's rule that does NOT mutate `points`, so the shipped
## cycle keeps its own state.
func _koch_step(src: Array) -> Array:
	var out: Array = []
	for i in range(src.size() - 1):
		var seg: Array = generate_koch_segment(src[i], src[i + 1])
		for j in range(seg.size() - 1):
			out.append(seg[j])
	out.append(src[-1])
	return out


## A flat ribbon through a 2D polyline, in the XY plane like the shipped mesh.
func _ribbon_mesh(pts: Array, half_width: float) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	if pts.size() < 2:
		return mesh
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var vi: int = 0
	for i in range(pts.size() - 1):
		var start := Vector3(pts[i].x, pts[i].y, 0)
		var end := Vector3(pts[i + 1].x, pts[i + 1].y, 0)
		var dir: Vector3 = (end - start).normalized()
		var perp: Vector3 = Vector3(-dir.y, dir.x, 0) * half_width
		vertices.append(start + perp)
		vertices.append(start - perp)
		vertices.append(end - perp)
		vertices.append(end + perp)
		var normal := Vector3(0, 0, 1)
		for _n in range(4):
			normals.append(normal)
		var u: float = float(i) / float(pts.size() - 1)
		uvs.append(Vector2(u, 0))
		uvs.append(Vector2(u, 1))
		uvs.append(Vector2(u, 1))
		uvs.append(Vector2(u, 0))
		indices.append(vi)
		indices.append(vi + 1)
		indices.append(vi + 2)
		indices.append(vi)
		indices.append(vi + 2)
		indices.append(vi + 3)
		vi += 4
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
