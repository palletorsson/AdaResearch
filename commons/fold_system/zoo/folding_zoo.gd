# @identity
# essence: six zones demonstrate the fold system's full range — bone, chain, shell, states, misfold, tension
# desire: a living laboratory where every fold family breathes, oscillates, and responds to inspection
# critical_parameter: _global_fold — sinusoidal oscillation that drives all non-frozen creatures
# triggers: placed as artifact in map; self-contained environment with floor, lighting, labels
# emerges: side-by-side comparison reveals how one fold variable (fold_amount) creates radically different motion across solvers
# needs: FoldCritter [has]; all three solvers [has]; FoldDemoCritter [has]
# relationships: test harness for the entire fold system; visual proof that the architecture works
# truth: If you can see all fold families breathing in one room, the system is real.
class_name FoldingZoo
extends Node3D
## Interactive showcase of all fold states and solver types.
## Six zones demonstrate bone, chain, shell, state parade, misfold, and spring tension.

const ZONE_SPACING: float = 3.0
const ZONE_COUNT: int = 6
const CREATURE_Y: float = 0.5
const OSCILLATION_PERIOD: float = 4.0

# Zone labels for identification.
const ZONE_NAMES: PackedStringArray = [
	"Bone Fold",
	"Chain Fold",
	"Shell Fold",
	"Fold States",
	"Misfold",
	"Spring Tension",
]

# Emissive colors per zone.
var _zone_colors: Array[Color] = [
	Color(0.3, 0.6, 1.0),   # Bone: blue
	Color(0.2, 0.9, 0.4),   # Chain: green
	Color(0.9, 0.4, 0.8),   # Shell: pink
	Color(0.9, 0.8, 0.2),   # States: gold
	Color(1.0, 0.2, 0.2),   # Misfold: red
	Color(0.4, 0.9, 0.9),   # Tension: cyan
]

# ---- Zone 1: Bone fold demo critter ----
var _bone_critter: FoldCritter = null

# ---- Zone 2: Chain fold inline demo ----
var _chain_solver: ChainFoldSolver = null
var _chain_segments: Array[FoldSegmentData] = []
var _chain_nodes: Array[Node3D] = []
var _chain_root: Node3D = null

# ---- Zone 3: Shell fold inline demo ----
var _shell_solver: ShellFoldSolver = null
var _shell_segments: Array[FoldSegmentData] = []
var _shell_nodes: Array[Node3D] = []
var _shell_root: Node3D = null

# ---- Zone 4: State parade (frozen critters) ----
var _parade_critters: Array[FoldCritter] = []

# ---- Zone 5: Misfold critter ----
var _misfold_critter: FoldCritter = null

# ---- Zone 6: Tension spring critter ----
var _tension_critter: FoldCritter = null

# Global oscillating fold amount for driven zones.
var _global_fold: float = 0.0

# Debug overlay labels attached to critters.
var _debug_labels: Array[Label3D] = []
var _bone_debug_label: Label3D = null
var _misfold_debug_label: Label3D = null
var _tension_debug_label: Label3D = null


func _ready() -> void:
	_build_environment()
	_build_floor()

	var x_start: float = -ZONE_SPACING * (ZONE_COUNT - 1) * 0.5

	for i in ZONE_COUNT:
		var zone_x: float = x_start + i * ZONE_SPACING
		_build_zone_label(ZONE_NAMES[i], Vector3(zone_x, 1.8, 0.0))

	# Zone 1 - Bone Fold Demo
	_bone_critter = _build_demo_critter(BoneFoldSolver.new(), _zone_colors[0])
	_bone_critter.position = Vector3(x_start, CREATURE_Y, 0.0)
	add_child(_bone_critter)
	_bone_debug_label = _create_debug_label(_bone_critter, Vector3(0, 0.5, 0))

	# Zone 2 - Chain Fold Demo (inline)
	_chain_root = Node3D.new()
	_chain_root.position = Vector3(x_start + ZONE_SPACING, CREATURE_Y, 0.0)
	add_child(_chain_root)
	_build_chain_demo()

	# Zone 3 - Shell Fold Demo (inline)
	_shell_root = Node3D.new()
	_shell_root.position = Vector3(x_start + ZONE_SPACING * 2, CREATURE_Y, 0.0)
	add_child(_shell_root)
	_build_shell_demo()

	# Zone 4 - State Parade (5 frozen critters)
	var parade_x: float = x_start + ZONE_SPACING * 3
	var frozen_values: PackedFloat64Array = [0.0, 0.25, 0.5, 0.75, 1.0]
	for j in frozen_values.size():
		var critter := _build_demo_critter(BoneFoldSolver.new(), _zone_colors[3])
		critter.scale = Vector3(0.6, 0.6, 0.6)
		var offset_z: float = (j - 2) * 0.5
		critter.position = Vector3(parade_x, CREATURE_Y, offset_z)
		add_child(critter)
		# Set fold_amount directly and freeze by setting target to match.
		critter.fold_amount = frozen_values[j]
		critter.target_fold = frozen_values[j]
		_parade_critters.append(critter)

	# Zone 5 - Misfold Demo
	_misfold_critter = _build_demo_critter(BoneFoldSolver.new(), _zone_colors[4])
	_misfold_critter.position = Vector3(x_start + ZONE_SPACING * 4, CREATURE_Y, 0.0)
	_misfold_critter.misfold_amount = 0.6
	add_child(_misfold_critter)
	_misfold_debug_label = _create_debug_label(_misfold_critter, Vector3(0, 0.5, 0))

	# Zone 6 - Tension Spring Demo
	_tension_critter = _build_demo_critter(BoneFoldSolver.new(), _zone_colors[5])
	_tension_critter.position = Vector3(x_start + ZONE_SPACING * 5, CREATURE_Y, 0.0)
	add_child(_tension_critter)
	_tension_debug_label = _create_debug_label(_tension_critter, Vector3(0, 0.5, 0))


func _process(delta: float) -> void:
	# Global oscillation: sinusoidal 0..1 with period OSCILLATION_PERIOD seconds.
	var t: float = Time.get_ticks_msec() * 0.001
	_global_fold = (sin(t * TAU / OSCILLATION_PERIOD) + 1.0) * 0.5

	# Drive bone critter (zone 1).
	if _bone_critter:
		_bone_critter.target_fold = _global_fold

	# Drive chain demo (zone 2).
	_update_chain_demo()

	# Drive shell demo (zone 3).
	_update_shell_demo()

	# Parade critters (zone 4) stay frozen -- no update.

	# Misfold critter (zone 5): keep misfold high, gentle fold.
	if _misfold_critter:
		_misfold_critter.target_fold = _global_fold * 0.5
		_misfold_critter.misfold_amount = maxf(_misfold_critter.misfold_amount, 0.55)

	# Tension critter (zone 6): oscillate rapidly to show spring dynamics.
	if _tension_critter:
		var rapid: float = (sin(t * TAU / 1.5) + 1.0) * 0.5
		_tension_critter.target_fold = rapid

	# Debug overlay updates.
	if _bone_critter and _bone_debug_label:
		_bone_debug_label.text = "fold: %.2f  tension: %.2f\nenergy: %.2f  misfold: %.2f\nstate: %s" % [_bone_critter.fold_amount, _bone_critter.fold_tension, _bone_critter.fold_energy, _bone_critter.misfold_amount, FoldCritter.FoldState.keys()[_bone_critter.fold_state]]
	if _misfold_critter and _misfold_debug_label:
		_misfold_debug_label.text = "fold: %.2f  tension: %.2f\nenergy: %.2f  misfold: %.2f\nstate: %s" % [_misfold_critter.fold_amount, _misfold_critter.fold_tension, _misfold_critter.fold_energy, _misfold_critter.misfold_amount, FoldCritter.FoldState.keys()[_misfold_critter.fold_state]]
	if _tension_critter and _tension_debug_label:
		_tension_debug_label.text = "fold: %.2f  tension: %.2f\nenergy: %.2f  misfold: %.2f\nstate: %s" % [_tension_critter.fold_amount, _tension_critter.fold_tension, _tension_critter.fold_energy, _tension_critter.misfold_amount, FoldCritter.FoldState.keys()[_tension_critter.fold_state]]


# ── Environment ─────────────────────────────────────────────────────────────

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.06, 0.07, 0.1)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.15, 0.18, 0.25)
	env.ambient_light_energy = 0.6

	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var dir_light := DirectionalLight3D.new()
	dir_light.position = Vector3(0, 5, 3)
	dir_light.rotation_degrees = Vector3(-45, 30, 0)
	dir_light.light_energy = 0.8
	dir_light.shadow_enabled = true
	add_child(dir_light)


func _build_floor() -> void:
	var mesh_instance := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(20.0, 20.0)
	mesh_instance.mesh = plane

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.09, 0.12)
	mat.roughness = 0.9
	mesh_instance.material_override = mat

	mesh_instance.position = Vector3.ZERO
	add_child(mesh_instance)


# ── Zone Label ──────────────────────────────────────────────────────────────

func _build_zone_label(text: String, pos: Vector3) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 48
	label.pixel_size = 0.005
	label.modulate = Color(0.9, 0.9, 0.95)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = pos
	add_child(label)


# ── Demo Critter Builder ────────────────────────────────────────────────────
# Creates a 4-segment wing+tail creature using FoldCritter with a BoneFoldSolver.

func _build_demo_critter(solver: FoldSolver, color: Color) -> FoldCritter:
	var critter := FoldCritter.new()

	# Build the rig.
	var rig := FoldRig.new()
	rig.solver = solver
	rig.base_stiffness = 10.0
	rig.base_damping = 0.82
	rig.supports_misfold = true

	# Four segments: body, wing_left, wing_right, tail.
	var seg_body := FoldSegmentData.new()
	seg_body.segment_name = &"body"
	seg_body.fold_axis = Vector3.RIGHT
	seg_body.angle_closed = 0.0
	seg_body.angle_open = 10.0
	seg_body.mass = 2.0

	var seg_wing_l := FoldSegmentData.new()
	seg_wing_l.segment_name = &"wing_left"
	seg_wing_l.fold_axis = Vector3.FORWARD
	seg_wing_l.angle_closed = -5.0
	seg_wing_l.angle_open = 70.0
	seg_wing_l.parent_segment = &"body"
	seg_wing_l.parent_min_fold = 0.1
	seg_wing_l.mass = 0.8

	var seg_wing_r := FoldSegmentData.new()
	seg_wing_r.segment_name = &"wing_right"
	seg_wing_r.fold_axis = Vector3.FORWARD
	seg_wing_r.angle_closed = 5.0
	seg_wing_r.angle_open = -70.0
	seg_wing_r.parent_segment = &"body"
	seg_wing_r.parent_min_fold = 0.1
	seg_wing_r.mass = 0.8

	var seg_tail := FoldSegmentData.new()
	seg_tail.segment_name = &"tail"
	seg_tail.fold_axis = Vector3.RIGHT
	seg_tail.angle_closed = 0.0
	seg_tail.angle_open = -30.0
	seg_tail.parent_segment = &"body"
	seg_tail.parent_min_fold = 0.2
	seg_tail.mass = 0.5

	rig.segments = [seg_body, seg_wing_l, seg_wing_r, seg_tail]

	# Simple constraints.
	var con_wing_l := FoldConstraintData.new()
	con_wing_l.segment_name = &"wing_left"
	con_wing_l.min_angle = -10.0
	con_wing_l.max_angle = 75.0

	var con_wing_r := FoldConstraintData.new()
	con_wing_r.segment_name = &"wing_right"
	con_wing_r.min_angle = -75.0
	con_wing_r.max_angle = 10.0

	rig.constraints = [con_wing_l, con_wing_r]

	critter.fold_rig = rig

	# Build geometry as child nodes named after segments.
	var mat_body := _make_emissive_material(color, 0.6)
	var mat_wing := _make_emissive_material(color.lightened(0.2), 0.4)
	var mat_tail := _make_emissive_material(color.darkened(0.2), 0.5)

	# Body: small ellipsoid (sphere scaled).
	var body_mesh := _make_sphere_mesh(0.12, mat_body)
	body_mesh.name = "body"
	body_mesh.scale = Vector3(1.0, 0.8, 1.3)
	critter.add_child(body_mesh)

	# Wing left.
	var wing_l_mesh := _make_sphere_mesh(0.06, mat_wing)
	wing_l_mesh.name = "wing_left"
	wing_l_mesh.position = Vector3(-0.15, 0.0, 0.0)
	wing_l_mesh.scale = Vector3(1.8, 0.3, 1.0)
	critter.add_child(wing_l_mesh)

	# Wing right.
	var wing_r_mesh := _make_sphere_mesh(0.06, mat_wing)
	wing_r_mesh.name = "wing_right"
	wing_r_mesh.position = Vector3(0.15, 0.0, 0.0)
	wing_r_mesh.scale = Vector3(1.8, 0.3, 1.0)
	critter.add_child(wing_r_mesh)

	# Tail.
	var tail_mesh := _make_sphere_mesh(0.05, mat_tail)
	tail_mesh.name = "tail"
	tail_mesh.position = Vector3(0.0, 0.0, -0.2)
	tail_mesh.scale = Vector3(0.5, 0.5, 2.0)
	critter.add_child(tail_mesh)

	# Initial state: folded with energy so it can respond.
	critter.fold_state = FoldCritter.FoldState.FOLDED
	critter.fold_energy = 1.0
	critter.affect = "curious"

	return critter


# ── Chain Demo (Zone 2) ─────────────────────────────────────────────────────

func _build_chain_demo() -> void:
	_chain_solver = ChainFoldSolver.new()
	_chain_solver.curve_length_open = 1.5
	_chain_solver.curvature_folded = 0.6
	_chain_solver.curvature_open = 0.1

	var mat := _make_emissive_material(_zone_colors[1], 0.5)

	for i in 6:
		var seg := FoldSegmentData.new()
		seg.segment_name = StringName("chain_%d" % i)
		seg.fold_axis = Vector3.RIGHT
		seg.angle_closed = 0.0
		seg.angle_open = 30.0
		seg.mass = 0.5
		_chain_segments.append(seg)

		var sphere := _make_sphere_mesh(0.08, mat)
		sphere.name = "chain_%d" % i
		_chain_root.add_child(sphere)
		_chain_nodes.append(sphere)


func _update_chain_demo() -> void:
	if _chain_solver == null or _chain_nodes.is_empty():
		return

	var result: Dictionary = _chain_solver.compute_fold(
		_global_fold, 0.0, _chain_segments, []
	)

	for i in _chain_nodes.size():
		var seg_name := StringName("chain_%d" % i)
		if result.has(seg_name):
			_chain_nodes[i].transform = result[seg_name]


# ── Shell Demo (Zone 3) ─────────────────────────────────────────────────────

func _build_shell_demo() -> void:
	_shell_solver = ShellFoldSolver.new()
	_shell_solver.layer_spacing_open = 0.15
	_shell_solver.rotation_per_layer = 20.0

	for i in 5:
		var seg := FoldSegmentData.new()
		seg.segment_name = StringName("shell_%d" % i)
		seg.fold_axis = Vector3.UP
		seg.angle_closed = 0.0
		seg.angle_open = 45.0
		seg.mass = 1.0 - float(i) * 0.15
		_shell_segments.append(seg)

		var torus := MeshInstance3D.new()
		var torus_mesh := TorusMesh.new()
		torus_mesh.inner_radius = 0.02 + float(i) * 0.005
		torus_mesh.outer_radius = 0.06 + float(i) * 0.03
		torus.mesh = torus_mesh

		var layer_t: float = float(i) / 4.0
		var layer_color: Color = _zone_colors[2].lerp(Color(1.0, 0.8, 0.95), layer_t * 0.4)
		var mat := _make_emissive_material(layer_color, 0.4 + layer_t * 0.3)
		torus.material_override = mat

		torus.name = "shell_%d" % i
		_shell_root.add_child(torus)
		_shell_nodes.append(torus)


func _update_shell_demo() -> void:
	if _shell_solver == null or _shell_nodes.is_empty():
		return

	var result: Dictionary = _shell_solver.compute_fold(
		_global_fold, 0.0, _shell_segments, []
	)

	for i in _shell_nodes.size():
		var seg_name := StringName("shell_%d" % i)
		if result.has(seg_name):
			_shell_nodes[i].transform = result[seg_name]


# ── Material Helpers ────────────────────────────────────────────────────────

func _make_emissive_material(color: Color, emission_strength: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = emission_strength
	mat.roughness = 0.4
	mat.metallic = 0.2
	return mat


func _make_sphere_mesh(radius: float, material: StandardMaterial3D) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	mesh_inst.mesh = sphere
	mesh_inst.material_override = material
	return mesh_inst


# ── Debug Overlay ──────────────────────────────────────────────────────────

func _create_debug_label(parent: Node3D, offset: Vector3) -> Label3D:
	var label := Label3D.new()
	label.font_size = 32
	label.pixel_size = 0.003
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(0.7, 1.0, 0.7, 0.9)
	label.position = offset
	parent.add_child(label)
	_debug_labels.append(label)
	return label


# ── Grid Config (map placement) ─────────────────────────────────────────────

func apply_grid_config(config: Dictionary) -> void:
	pass
