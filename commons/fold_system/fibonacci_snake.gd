# @identity
# essence: a triangle strip coiled in a Fibonacci spiral unfolds into a sine-wave snake
# desire: golden ratio geometry becoming locomotion — the spiral IS the resting pose, the wave IS the motion
# critical_parameter: fold_amount — 0.0 is tight Fibonacci spiral, 1.0 is straight sine-wave snake
# triggers: vertices interpolate between spiral positions and sine-wave positions
# emerges: the snake slithers by phase-shifting the sine wave along its body
# truth: phi encodes rest. sin encodes motion. fold_amount transitions between them.

class_name FibonacciSnake
extends FoldCritter
## A triangle strip creature that starts coiled in a Fibonacci/golden spiral
## and unfolds into a slithering sine-wave snake.
## Same vertices, same faces throughout — only positions change.

const PrimitiveMeshBuilder: GDScript = preload("res://commons/primitives/shared/primitive_mesh_builder.gd")
const PHI: float = 1.618033988749895

@export var segment_count: int = 30        ## Triangle pairs along the body
@export var body_width: float = 0.008      ## Half-width of the ribbon
@export var spiral_scale: float = 0.008    ## Controls how tight the spiral is
@export var spiral_turns: float = 2.5      ## How many rotations in the spiral
@export var snake_length: float = 0.3      ## Total straight length when uncoiled
@export var sine_amplitude: float = 0.04   ## Lateral wave amplitude
@export var sine_frequency: float = 2.5    ## Wave periods along the body
@export var slither_speed: float = 2.0     ## Phase shift speed for locomotion
@export var base_color: Color = Color(0.45, 0.65, 0.35)

# Fixed topology
var _verts_spiral: Array[Vector3] = []
var _verts_snake: Array[Vector3] = []
var _faces: Array = []

# Mesh
var _mesh: ArrayMesh = null
var _mesh_instance: MeshInstance3D = null
var _material: StandardMaterial3D = null
var _last_fold: float = -1.0

# Locomotion
var _slither_phase: float = 0.0


func _ready() -> void:
	_generate_geometry()
	_create_material()
	_create_fold_rig()

	fold_state = FoldState.FOLDED
	fold_amount = 0.0
	target_fold = 0.0

	_build_fold_mesh()
	_create_collision()
	super._ready()


# ═════════════════════════════════════════════════════════════════════════
# GEOMETRY — Fibonacci spiral and sine snake share the same vertex/face count
# ═════════════════════════════════════════════════════════════════════════

func _generate_geometry() -> void:
	_verts_spiral.clear()
	_verts_snake.clear()
	_faces.clear()

	for i in (segment_count + 1):
		var t: float = float(i) / float(segment_count)

		# ── Fibonacci spiral position (fold_amount = 0) ──
		# Golden spiral: r = a * phi^(theta / 90°)
		# We parameterize by t (0→1) mapped to angle
		var angle: float = t * spiral_turns * TAU
		var r: float = spiral_scale * pow(PHI, angle / (PI * 0.5))

		var spiral_x: float = cos(angle) * r
		var spiral_z: float = sin(angle) * r

		# Left and right edges of the ribbon on the spiral
		# Perpendicular to the spiral tangent
		var tangent_angle: float = angle + PI * 0.5
		var perp_x: float = cos(tangent_angle) * body_width
		var perp_z: float = sin(tangent_angle) * body_width

		_verts_spiral.append(Vector3(spiral_x - perp_x, 0.0, spiral_z - perp_z))
		_verts_spiral.append(Vector3(spiral_x + perp_x, 0.0, spiral_z + perp_z))

		# ── Sine snake position (fold_amount = 1) ──
		# Straight along Z, lateral sine wave on X
		var snake_z: float = (t - 0.5) * snake_length
		var snake_x: float = sin(t * sine_frequency * TAU) * sine_amplitude

		# Width perpendicular to travel direction (mostly along X)
		var wave_deriv: float = cos(t * sine_frequency * TAU) * sine_frequency * TAU * sine_amplitude
		var forward: Vector2 = Vector2(wave_deriv, snake_length).normalized()
		var perp: Vector2 = Vector2(-forward.y, forward.x) * body_width

		_verts_snake.append(Vector3(snake_x - perp.x, 0.0, snake_z - perp.y))
		_verts_snake.append(Vector3(snake_x + perp.x, 0.0, snake_z + perp.y))

	# Triangle strip: two triangles per segment
	for i in segment_count:
		var base: int = i * 2
		_faces.append([base, base + 1, base + 2])
		_faces.append([base + 1, base + 3, base + 2])


func _create_material() -> void:
	_material = StandardMaterial3D.new()
	_material.albedo_color = base_color
	_material.roughness = 0.7
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material.emission_enabled = true
	_material.emission = base_color * 0.2
	_material.emission_energy_multiplier = 0.5


func _create_fold_rig() -> void:
	fold_rig = FoldRig.new()
	fold_rig.solver = BoneFoldSolver.new()
	fold_rig.base_stiffness = 10.0
	fold_rig.base_damping = 0.85
	fold_rig.max_fold_energy = 1.0
	fold_rig.supports_misfold = true

	var seg := FoldSegmentData.new()
	seg.segment_name = &"body"
	seg.mass = 1.0
	fold_rig.segments = [seg]


func _build_fold_mesh() -> void:
	_segment_nodes.clear()

	var body_node := Node3D.new()
	body_node.name = "body"
	add_child(body_node)
	_segment_nodes[&"body"] = body_node

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "SnakeMesh"
	body_node.add_child(_mesh_instance)

	_update_mesh()


func _create_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = snake_length * 0.5
	col.shape = shape
	add_child(col)


# ═════════════════════════════════════════════════════════════════════════
# FOLD + SLITHER — spiral at 0, sine snake at 1, slither adds phase shift
# ═════════════════════════════════════════════════════════════════════════

func _process_visual(_delta: float) -> void:
	_update_mesh()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	# Slither: phase-shift the sine wave when deployed
	if fold_amount > 0.5:
		_slither_phase += delta * slither_speed
		# Move forward
		var forward_dir := -global_basis.z
		velocity = forward_dir * (fold_amount - 0.5) * 2.0 * 0.5


func _update_mesh() -> void:
	if _verts_spiral.is_empty() or not _mesh_instance:
		return

	var t: float = fold_amount
	var verts: Array = []

	for i in (segment_count + 1):
		var body_t: float = float(i) / float(segment_count)

		# Compute current sine snake position with slither phase
		var snake_z: float = (body_t - 0.5) * snake_length
		var wave_phase: float = body_t * sine_frequency * TAU + _slither_phase
		var snake_x: float = sin(wave_phase) * sine_amplitude * t  # Amplitude scales with fold

		# Width perpendicular
		var wave_deriv: float = cos(wave_phase) * sine_frequency * TAU * sine_amplitude * t
		var forward: Vector2 = Vector2(wave_deriv, snake_length).normalized()
		var perp: Vector2 = Vector2(-forward.y, forward.x) * body_width

		var snake_left := Vector3(snake_x - perp.x, 0.0, snake_z - perp.y)
		var snake_right := Vector3(snake_x + perp.x, 0.0, snake_z + perp.y)

		# Interpolate between spiral and slithering snake
		var idx: int = i * 2
		verts.append(_verts_spiral[idx].lerp(snake_left, t))
		verts.append(_verts_spiral[idx + 1].lerp(snake_right, t))

	_mesh = PrimitiveMeshBuilder.build_mesh(verts, _faces, {"double_sided": true})
	if _mesh:
		_mesh_instance.mesh = _mesh
		_mesh_instance.material_override = _material


# ═════════════════════════════════════════════════════════════════════════
# CONFIG
# ═════════════════════════════════════════════════════════════════════════

func configure(config: Dictionary) -> void:
	if config.has("fold_amount"):
		fold_amount = float(config["fold_amount"])
		target_fold = fold_amount
	if config.has("segments"):
		segment_count = int(config["segments"])
	if config.has("amplitude"):
		sine_amplitude = float(config["amplitude"])


func apply_grid_config(config: Dictionary) -> void:
	configure(config)
