extends Node3D

# @identity
# essence: koch_arch = map_to_arch(koch_points(iterations)) + koch_legs, fractal curve bent into a portal
# desire: To be walked through — a Koch-curve arch with fractal legs, the boundary between order and chaos made into a doorway
# critical_parameter: iterations — each level adds finer bumps to the arch and legs; reachable from a map as `tick`
# triggers: depth_layers create Z-depth volume; rotation_speed enables slow rotation for display
# emerges: The arch shape from mapping a linear fractal onto a semicircle — the Koch bumps become architectural ornament
# needs: VR walk-through [has via geometry], iteration control [has, via `tick`], head shape [has, via `head`]
# relationships: 3D architectural interpretation of the Koch curve; contrasts flat fractal_koch_curve with volumetric space
# truth: A doorway made of fractals is a threshold with infinite detail — you can never fully see what you are walking through.

@export var iterations: int = 4
@export var line_width: float = 0.03
@export var portal_width: float = 2.0
@export var portal_height: float = 2.5
@export var leg_height: float = 1.5
@export var depth_layers: int = 3
@export var layer_spacing: float = 0.15
@export var rotation_speed: float = 0.0  # Set > 0 for slow rotation animation

# ─────────────────────────────────────────────────────────────────────
#  STAGE-2 DNA — promoted 2026-08-06 (hand promotion; the runner refused
#  this token for NO TURNABLE KNOBS, which was a fact about the KIND of
#  knob — eight exports and not one categorical among them — and about a
#  scene shape that made every one of them unreachable, see THE SCENE
#  DEFECT below).
#
#  tick  — how many Koch generations the portal carries. cantor_set's,
#          zeno_staircase's, sierpinski_pyramid's and menger_sponge's
#          word; once | coarse | fine are the first three of the family's
#          five names, character for character.
#
#          THE LADDER IS THREE RUNGS AND IT IS SHORT FOR A REASON THAT IS
#          NOT MENGER'S. Menger stops at three because its cube count
#          multiplies by 20. Koch's multiplies by only 4, so cost is not
#          the wall here — THE LINE THICKNESS IS. Every segment is drawn
#          as a cylinder of radius `line_width`, and the .tscn ships
#          line_width = 0.2 m against a curve of arc length
#          PI * portal_width / 2 = 4.71 m. The bump this rule adds at
#          generation n has amplitude (L / 3^n) * sqrt(3)/2 * 0.5:
#
#              n=1  0.680 m   n=2  0.227 m   n=3  0.076 m
#              n=4  0.025 m   n=5  0.008 m   n=6  0.003 m
#
#          From n=3 down the new detail is smaller than the tube that is
#          supposed to draw it. MEASURED, not asserted — the geometry was
#          re-implemented in Python and the tube union rasterised at the
#          sweep's own framing: against the shipped iterations = 4,
#          iteration 3 changes 0.27% of frame and iteration 5 changes
#          0.03%. They are the same photograph. So TICK_LEVELS skips 3
#          and stops at 4; declaring `dense` and `limit` would be the
#          example_8_4 fault, rungs that exist in the enum and cannot be
#          told apart.
#
#          THE FINDING THAT COMES WITH IT, and it is worth more than the
#          rung: this artifact ships at iterations = 4 and saturates at
#          2. Its README's table runs to iteration 4 and its @identity
#          said "at 4 the portal shimmers with fractal detail". At the
#          thickness it is actually drawn with, iterations 3, 4, 5 and 6
#          are one object. Three maps have been paying for 2304 cylinders
#          to draw a picture 144 of them already made.
#
#  head  — WHAT SHAPE THE LINEAR CURVE IS BENT INTO. This is the thing
#          this artifact argues and no other Koch in the corpus does:
#          koch_curve (2D) asks `evidence`, what the finished figure
#          shows of its own iteration. This one is a DOORWAY, and its
#          own @identity says the bumps "become architectural ornament".
#          So the question is which architecture — and the answer is a
#          curve law, held to the same span (portal_width) and, except
#          for the flat head, the same crown (leg_height + portal_width/2),
#          so the axis is about curvature and not about size.
#
#            arch      the shipped semicircle. Arcuated, constant
#                      curvature, the Roman answer.
#            lintel    a straight beam on the springing line. Trabeated:
#                      no curvature at all, the Greek answer, and the one
#                      that admits the fractal is ornament on a beam.
#            gable     two straight rakes to the crown. A pitched head:
#                      curvature nowhere except at the apex, where all of
#                      it is.
#            catenary  the hanging chain inverted. The head that stands
#                      in pure compression — the shape a rope finds by
#                      itself, decorated by a rule that cannot.
#
#          Every value maps the SAME Koch point list; only the curve the
#          points are laid along, and the outward normal the fractal
#          displacement is thrown along, change. Measured against arch at
#          the shipped iterations: lintel 15.2%, gable 8.8%, catenary
#          4.1% of frame, and no pair closer than 4.1%.
#
#  THE SCENE DEFECT, repaired here. KochCurve3D.tscn was shaped
#
#      [Main]              <- unscripted Node3D, the ROOT
#        ├── KochCurve3D   <- this script, and every @export on it
#        ├── Camera3D
#        └── DirectionalLight3D
#
#  and GridInteractablesComponent addresses the ROOT and only the root
#  (set_meta("config_*") then call_deferred("apply_grid_config") at
#  line 1672). The root had no script, so no map token could ever reach
#  `iterations` — the @identity's own declared critical_parameter — and
#  the README's documented usage, `portal.iterations = 5` on the
#  instantiated scene, has never done anything. The script now sits on
#  the root and the intermediate node is gone. The child was at the
#  identity transform and carried the four .tscn overrides, which moved
#  up with it, so the geometry is unchanged to the millimetre; the
#  camera and the light keep their place as the root's children and are
#  suppressed by the capture bench and by the grid exactly as before.
#
#  DEAD EXPORT, reported and left alone: `portal_height` is read by
#  nothing. The arch crown has always been leg_height + portal_width/2.
#  Giving it meaning now would change what a scene setting it draws, so
#  it stays dead and stays documented.
# ─────────────────────────────────────────────────────────────────────

## Koch generations per rung. `fine` SHORT-CIRCUITS to the shipped
## `iterations` rather than to this table's 4, so a scene that overrides the
## count in the inspector is not silently retuned by this promotion. 3 is
## absent because it is not a different picture — see the note above.
const TICK_LEVELS := {"once": 1, "coarse": 2, "fine": 4}
const HEADS := ["arch", "lintel", "gable", "catenary"]
## Shape parameter of the inverted catenary. 2.0 puts the haunches visibly
## inside the semicircle while keeping the same springing points and crown.
const CATENARY_K: float = 2.0

@export_enum("once", "coarse", "fine") var tick: String = "fine"
@export_enum("arch", "lintel", "gable", "catenary") var head: String = "arch"

var line_material: StandardMaterial3D
var _time: float = 0.0
var _built: bool = false
## `iterations` as authored, read once in _ready before any rebuild writes to it.
var _shipped_iterations: int = 4
## The depth-layer nodes this script created, so a rebuild frees its own work
## and never touches the camera or the light the scene brought with it.
var _layers: Array[Node3D] = []

func _ready() -> void:
	# Read BEFORE any rebuild writes to `iterations`. Reading it inside
	# _levels() would latch: a config setting tick=once leaves iterations at 1,
	# and a later `fine` would then short-circuit to 1 instead of the shipped 4.
	_shipped_iterations = iterations
	setup_material()
	_rebuild()

func _process(delta: float) -> void:
	if rotation_speed > 0:
		_time += delta
		rotation.y = _time * rotation_speed

func setup_material() -> void:
	line_material = StandardMaterial3D.new()
	line_material.albedo_color = Color(0.9, 0.95, 1.0)
	line_material.emission_enabled = true
	line_material.emission = Color(0.6, 0.8, 1.0)
	line_material.emission_energy_multiplier = 1.5

## How many generations this portal carries. `fine` short-circuits.
func _levels() -> int:
	if tick == "fine":
		return _shipped_iterations
	return int(TICK_LEVELS.get(tick, _shipped_iterations))

## Tear down and build. Only ever reached from _ready() and from
## apply_grid_config when a declared value ACTUALLY changed after the first
## build — an unguarded rebuild here would re-run the whole construction on
## every shipped placement that passes any config key at all.
func _rebuild() -> void:
	for layer in _layers:
		if is_instance_valid(layer):
			layer.queue_free()
	_layers.clear()
	iterations = _levels()
	generate_portal()
	_built = true

func generate_portal() -> void:
	# Create multiple depth layers for volume
	for layer in range(depth_layers):
		var z_offset = (layer - depth_layers / 2.0) * layer_spacing
		create_portal_layer(z_offset, layer)

func create_portal_layer(z_offset: float, layer_index: int) -> void:
	var layer_node = Node3D.new()
	layer_node.position.z = z_offset
	add_child(layer_node)
	_layers.append(layer_node)

	# Create the arch (Koch curve bent into the declared head)
	create_koch_arch(layer_node)

	# Create the base legs
	create_legs(layer_node)

func create_koch_arch(parent: Node3D) -> void:
	# Generate Koch points for a straight line
	var koch_points = get_koch_points(iterations)

	# Map these points onto the head shape
	var arch_points = map_to_arch(koch_points)

	# Create 3D lines from arch points
	for i in range(arch_points.size() - 1):
		var line_mesh = create_line_segment(arch_points[i], arch_points[i + 1])
		parent.add_child(line_mesh)

func map_to_arch(points: Array[Vector3]) -> Array[Vector3]:
	var arch_points: Array[Vector3] = []

	# Map the linear Koch curve onto the head curve
	var total_length: float = points[-1].x - points[0].x
	var start_x: float = points[0].x

	if head == "arch":
		# SHORT-CIRCUIT. The shipped body, line for line: the default value
		# recomputes nothing and cannot drift from what three maps already draw.
		for point in points:
			# Normalize position along the curve (0 to 1)
			var t: float = (point.x - start_x) / total_length

			# Map to angle (PI to 0 for arch from left to right)
			var angle: float = PI * (1.0 - t)

			# Calculate arch position
			var arch_radius: float = portal_width / 2.0
			var x: float = cos(angle) * arch_radius
			var y: float = sin(angle) * arch_radius + leg_height

			# Add the Koch fractal displacement perpendicular to the arch
			# The original Z displacement becomes radial displacement
			var radial_offset: float = point.z * 0.5  # Scale down the fractal effect
			x += cos(angle) * radial_offset
			y += sin(angle) * radial_offset

			arch_points.append(Vector3(x, y, 0))

		return arch_points

	# Any other head: the identical Koch list, laid along a different curve,
	# with the same displacement thrown along that curve's outward normal.
	for point in points:
		var u: float = (point.x - start_x) / total_length
		var base: Vector2 = _head_pos(u)
		var normal: Vector2 = _head_normal(u)
		var offset: float = point.z * 0.5
		arch_points.append(Vector3(base.x + normal.x * offset,
			base.y + normal.y * offset, 0.0))

	return arch_points

## Position on the head curve at parameter u in [0, 1], left springing to right.
## Every head shares the springing points (+/- portal_width/2, leg_height); all
## but `lintel` also share the crown at leg_height + portal_width/2.
func _head_pos(u: float) -> Vector2:
	var r: float = portal_width / 2.0
	var crown: float = leg_height + r
	match head:
		"lintel":
			return Vector2((2.0 * u - 1.0) * r, leg_height)
		"gable":
			if u <= 0.5:
				var rise: float = u / 0.5
				return Vector2(-r + rise * r, leg_height + rise * r)
			var fall: float = (u - 0.5) / 0.5
			return Vector2(fall * r, crown - fall * r)
		"catenary":
			var s: float = 2.0 * u - 1.0
			var span: float = cosh(CATENARY_K) - 1.0
			var y: float = leg_height + r * (cosh(CATENARY_K) - cosh(CATENARY_K * s)) / span
			return Vector2(s * r, y)
	var angle: float = PI * (1.0 - u)
	return Vector2(cos(angle) * r, sin(angle) * r + leg_height)

## Outward unit normal of the head curve at u — the direction the Koch
## displacement is thrown along, away from the opening below.
func _head_normal(u: float) -> Vector2:
	match head:
		"lintel":
			return Vector2(0.0, 1.0)
		"gable":
			var rake: Vector2 = Vector2(1.0, 1.0)
			if u > 0.5:
				rake = Vector2(1.0, -1.0)
			return Vector2(-rake.y, rake.x).normalized()
		"catenary":
			var s: float = 2.0 * u - 1.0
			var span: float = cosh(CATENARY_K) - 1.0
			var slope: float = -CATENARY_K * sinh(CATENARY_K * s) / span
			var tangent: Vector2 = Vector2(1.0, slope)
			return Vector2(-tangent.y, tangent.x).normalized()
	var angle: float = PI * (1.0 - u)
	return Vector2(cos(angle), sin(angle))

func create_legs(parent: Node3D) -> void:
	var half_width = portal_width / 2.0

	# Left leg - Koch pattern going down
	var left_leg_points = get_vertical_koch_points(-half_width, 0, leg_height)
	for i in range(left_leg_points.size() - 1):
		var line_mesh = create_line_segment(left_leg_points[i], left_leg_points[i + 1])
		parent.add_child(line_mesh)

	# Right leg - Koch pattern going down
	var right_leg_points = get_vertical_koch_points(half_width, 0, leg_height)
	for i in range(right_leg_points.size() - 1):
		var line_mesh = create_line_segment(right_leg_points[i], right_leg_points[i + 1])
		parent.add_child(line_mesh)

func get_vertical_koch_points(x_pos: float, y_start: float, height: float) -> Array[Vector3]:
	# Generate Koch curve points and rotate them to be vertical
	var points: Array[Vector3] = []
	points.append(Vector3(0, 0, 0))
	points.append(Vector3(height, 0, 0))

	for i in range(max(1, iterations - 1)):  # Slightly fewer iterations for legs
		points = koch_iteration(points)

	# Rotate and position for vertical leg
	var vertical_points: Array[Vector3] = []
	for p in points:
		# Rotate 90 degrees: x becomes y, and scale the fractal displacement
		vertical_points.append(Vector3(x_pos + p.z * 0.3, y_start + p.x, 0))

	return vertical_points

func get_koch_points(iter: int) -> Array[Vector3]:
	var points: Array[Vector3] = []
	var curve_length = PI * portal_width / 2.0  # Arc length
	points.append(Vector3(-curve_length/2, 0, 0))
	points.append(Vector3(curve_length/2, 0, 0))

	for i in range(iter):
		points = koch_iteration(points)

	return points

func koch_iteration(points: Array[Vector3]) -> Array[Vector3]:
	var new_points: Array[Vector3] = []

	for i in range(points.size() - 1):
		var p1 = points[i]
		var p2 = points[i + 1]

		# Calculate the four points of the Koch segment
		var segment = p2 - p1
		var third = segment / 3.0

		var a = p1
		var b = p1 + third
		var d = p1 + 2.0 * third

		# Calculate the peak point (equilateral triangle)
		var mid = (b + d) / 2.0
		var height_vec = Vector3(-segment.z, 0, segment.x).normalized()
		if height_vec.length() < 0.001:
			height_vec = Vector3(0, 0, 1)
		var height = third.length() * sqrt(3.0) / 2.0
		var c = mid + height_vec * height

		new_points.append(a)
		new_points.append(b)
		new_points.append(c)
		new_points.append(d)

	new_points.append(points[-1])
	return new_points

func create_line_segment(start: Vector3, end: Vector3) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()

	# Set cylinder properties for volume
	cylinder_mesh.radial_segments = 6
	cylinder_mesh.rings = 1
	cylinder_mesh.top_radius = line_width
	cylinder_mesh.bottom_radius = line_width

	var length = start.distance_to(end)
	if length < 0.001:
		length = 0.001
	cylinder_mesh.height = length

	mesh_instance.mesh = cylinder_mesh
	mesh_instance.material_override = line_material

	# Position and orient the cylinder
	var center = (start + end) / 2.0
	mesh_instance.position = center

	# Align cylinder with the line direction
	var direction = (end - start).normalized()
	if direction.length() > 0.001:
		# Use a proper up vector that isn't parallel to direction
		var up = Vector3.UP
		if abs(direction.dot(up)) > 0.99:
			up = Vector3.RIGHT
		mesh_instance.look_at_from_position(mesh_instance.position, center + direction, up)
		mesh_instance.rotate_object_local(Vector3.RIGHT, PI/2)

	return mesh_instance

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## Config from a map token. Guarded twice — a word is taken only when it
## validates AND differs, and _rebuild() fires only after _ready has built once
## — so the three existing placements, which pass no key at all, reach no
## assignment and never rebuild.
func apply_grid_config(config: Dictionary) -> void:
	if config.is_empty():
		return

	var changed: bool = false

	if config.has("tick"):
		var v: String = str(config["tick"]).to_lower()
		if TICK_LEVELS.has(v) and v != tick:
			tick = v
			changed = true

	if config.has("head"):
		var h: String = str(config["head"]).to_lower()
		if HEADS.has(h) and h != head:
			head = h
			changed = true

	if not changed:
		return
	# Before the first build there is nothing to tear down — _ready() will pick
	# the new values up when it runs.
	if not _built:
		return
	_rebuild()
