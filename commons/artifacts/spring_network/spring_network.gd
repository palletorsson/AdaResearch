extends Node3D
class_name SpringNetwork

## @identity
## name: "A cloth that remembers its shape"
## tier: medium
## lineage: A lattice of masses tied to their neighbors — horizontal, vertical, diagonal — by
##   rest-length springs, solved each frame with position-based constraints and Verlet integration.
##   Fixed corners anchor it; a random kick on startup sets the whole sheet ringing until it settles.
## truth: "STIFFNESS IS NOT A MATERIAL — IT IS A NETWORK OF AGREEMENTS BETWEEN NEIGHBORS"
## applications: mass-spring systems, cloth and soft-body simulation, Verlet/PBD integration,
##   emergent elasticity, how local constraints produce global form.

## Mass-spring lattice — a grid of masses connected by springs with Verlet integration.
## Each mass point is connected to its horizontal, vertical, and diagonal neighbors via
## springs with configurable stiffness and damping. Corner masses are fixed anchors.
## The algorithm: (1) build lattice positions, (2) connect neighbors with rest-length springs,
## (3) each frame run PBD constraint solving + Verlet integration for stable oscillation.
## Random perturbation on _ready() kicks the network so it oscillates and settles.

# --- Configuration ---

## Number of masses along each axis (total masses = grid_size^2)
@export_range(2, 20) var grid_size: int = 6
## Distance between adjacent masses at rest
@export_range(0.01, 1.0, 0.01) var spacing: float = 0.1
## Spring stiffness — higher values make springs snap back faster
@export_range(1.0, 500.0, 1.0) var stiffness: float = 80.0
## Velocity damping per frame (0 = frozen, 1 = no damping)
@export_range(0.8, 1.0, 0.01) var damping: float = 0.97
## Radius of each mass sphere
@export_range(0.002, 0.05, 0.001) var mass_radius: float = 0.008

# --- Internal ---

var _positions: Array = []       # Array[Vector3] — current positions
var _old_positions: Array = []   # Array[Vector3] — previous positions (Verlet)
var _anchored: Array = []        # Array[bool] — fixed masses

# Spring connections: Array of [idx_a, idx_b, rest_length]
var _springs: Array = []

# Visual references
var _mass_mm: MultiMesh              # MultiMesh for mass spheres
var _mass_mmi: MultiMeshInstance3D   # MultiMeshInstance3D node
var _spring_mesh: MeshInstance3D
var _spring_mat: StandardMaterial3D
var _im: ImmediateMesh               # Reused each frame for spring lines
var _title_label: Label3D

# VR interaction
var _stiffness_slider: Node
var _damping_slider: Node
var _control_panel: Node3D

# Colors
var _mass_color: Color = Color(0.95, 0.55, 0.2)
var _anchor_color: Color = Color(0.3, 0.85, 0.5)
var _spring_color: Color = Color(0.4, 0.55, 0.8, 0.7)
var _spring_stretched: Color = Color(0.9, 0.3, 0.2, 0.8)
var _spring_compressed: Color = Color(0.3, 0.4, 0.9, 0.8)


func _ready() -> void:
	_build_lattice()
	_create_springs()
	_create_mass_visuals()
	_create_spring_visual()
	_create_label()
	_setup_controls()
	_apply_perturbation()


# ------------------------------------------------------------------
# Lattice construction
# ------------------------------------------------------------------

## Builds the NxN grid of mass positions and marks corners as anchored.
func _build_lattice() -> void:
	var total = grid_size * grid_size
	_positions.resize(total)
	_old_positions.resize(total)
	_anchored.resize(total)

	var half = (grid_size - 1) * spacing / 2.0
	var idx := 0

	for row in range(grid_size):
		for col in range(grid_size):
			var x = col * spacing - half
			var y = row * spacing - half
			var pos = Vector3(x, y, 0)
			_positions[idx] = pos
			_old_positions[idx] = pos

			# Anchor corners
			var is_corner = (
				(row == 0 and col == 0) or
				(row == 0 and col == grid_size - 1) or
				(row == grid_size - 1 and col == 0) or
				(row == grid_size - 1 and col == grid_size - 1)
			)
			_anchored[idx] = is_corner
			idx += 1


## Converts row/col to flat array index.
func _idx(row: int, col: int) -> int:
	return row * grid_size + col


## Connects each mass to its horizontal, vertical, and diagonal neighbors.
func _create_springs() -> void:
	for row in range(grid_size):
		for col in range(grid_size):
			var i = _idx(row, col)

			# Horizontal spring (right neighbor)
			if col < grid_size - 1:
				var j = _idx(row, col + 1)
				var rest = _positions[i].distance_to(_positions[j])
				_springs.append([i, j, rest])

			# Vertical spring (down neighbor)
			if row < grid_size - 1:
				var j = _idx(row + 1, col)
				var rest = _positions[i].distance_to(_positions[j])
				_springs.append([i, j, rest])

			# Diagonal spring (down-right) — structural shear
			if row < grid_size - 1 and col < grid_size - 1:
				var j = _idx(row + 1, col + 1)
				var rest = _positions[i].distance_to(_positions[j])
				_springs.append([i, j, rest])

			# Diagonal spring (down-left) — structural shear
			if row < grid_size - 1 and col > 0:
				var j = _idx(row + 1, col - 1)
				var rest = _positions[i].distance_to(_positions[j])
				_springs.append([i, j, rest])


# ------------------------------------------------------------------
# Visuals — mass spheres (MultiMesh)
# ------------------------------------------------------------------

## Creates a MultiMesh with one instance per mass point for GPU instancing.
func _create_mass_visuals() -> void:
	var sphere := SphereMesh.new()
	sphere.radius = mass_radius
	sphere.height = mass_radius * 2.0
	sphere.radial_segments = 8
	sphere.rings = 4

	var count = _positions.size()

	_mass_mm = MultiMesh.new()
	_mass_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mass_mm.use_colors = true
	_mass_mm.mesh = sphere
	_mass_mm.instance_count = count

	for i in range(count):
		var xf := Transform3D()
		xf.origin = _positions[i]
		_mass_mm.set_instance_transform(i, xf)
		_mass_mm.set_instance_color(i, _anchor_color if _anchored[i] else _mass_color)

	_mass_mmi = MultiMeshInstance3D.new()
	_mass_mmi.multimesh = _mass_mm

	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = _mass_color
	mat.emission_energy_multiplier = 0.6
	_mass_mmi.material_override = mat

	add_child(_mass_mmi)


# ------------------------------------------------------------------
# Visuals — spring lines (ImmediateMesh, rebuilt each frame)
# ------------------------------------------------------------------

## Creates the MeshInstance3D and reusable ImmediateMesh for spring lines.
func _create_spring_visual() -> void:
	_spring_mesh = MeshInstance3D.new()
	_spring_mesh.name = "SpringLines"

	_im = ImmediateMesh.new()
	_spring_mesh.mesh = _im

	_spring_mat = StandardMaterial3D.new()
	_spring_mat.vertex_color_use_as_albedo = true
	_spring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_spring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_spring_mesh.material_override = _spring_mat
	add_child(_spring_mesh)


## Creates the title label above the network.
func _create_label() -> void:
	_title_label = Label3D.new()
	_title_label.name = "TitleLabel"
	_title_label.text = "SPRING NETWORK"
	_title_label.font_size = 20
	_title_label.pixel_size = 0.001
	var half = (grid_size - 1) * spacing / 2.0
	_title_label.position = Vector3(0, half + 0.04, 0)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.modulate = Color(0.85, 0.88, 0.95)
	_title_label.outline_size = 3
	_title_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_title_label)


# ------------------------------------------------------------------
# VR interaction
# ------------------------------------------------------------------

## Adds VR control panel for stiffness and damping.
func _setup_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_panel("SPRING NETWORK", [
		[
			{"type": "slider_h", "label": "STIFFNESS", "default": stiffness / 500.0},
			{"type": "slider_h", "label": "DAMPING", "default": (damping - 0.8) / 0.2},
		],
		[{"type": "button", "label": "PERTURB"}],
	])
	_control_panel.position = Vector3(0, -0.15, 0.15)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)

	_stiffness_slider = _control_panel.find_child("Param_0", true, false)
	_damping_slider = _control_panel.find_child("Param_1", true, false)

	if _stiffness_slider and _stiffness_slider.has_signal("slider_moved"):
		_stiffness_slider.slider_moved.connect(_on_stiffness_changed)
	if _damping_slider and _damping_slider.has_signal("slider_moved"):
		_damping_slider.slider_moved.connect(_on_damping_changed)

	var perturb_btn: Node = _control_panel.find_child("Btn_0", true, false)
	if perturb_btn:
		var area = perturb_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _apply_perturbation())


func _on_stiffness_changed(_val = null) -> void:
	if _stiffness_slider and _stiffness_slider.has_method("get_normalized_value"):
		stiffness = _stiffness_slider.get_normalized_value() * 500.0


func _on_damping_changed(_val = null) -> void:
	if _damping_slider and _damping_slider.has_method("get_normalized_value"):
		damping = 0.8 + _damping_slider.get_normalized_value() * 0.2


# ------------------------------------------------------------------
# Perturbation — kick the lattice so it oscillates
# ------------------------------------------------------------------

## Applies random displacement to non-anchored masses to start oscillation.
func _apply_perturbation() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = hash("spring_network_42")

	for i in range(_positions.size()):
		if _anchored[i]:
			continue
		# Random displacement in XY plane + small Z
		var offset = Vector3(
			rng.randf_range(-0.02, 0.02),
			rng.randf_range(-0.02, 0.02),
			rng.randf_range(-0.01, 0.01)
		)
		_positions[i] += offset
		# old_positions stays at rest — Verlet will infer velocity from gap


# ------------------------------------------------------------------
# Physics — Verlet integration
# ------------------------------------------------------------------

func _process(delta: float) -> void:
	# Substep for stability
	var substeps := 3
	var sub_dt = delta / maxi(substeps, 1)
	for _s in range(substeps):
		_verlet_step(sub_dt)

	_update_mass_visuals()
	_update_spring_lines()


## Runs one PBD constraint-solve + Verlet integration substep.
func _verlet_step(dt: float) -> void:
	# Position-based dynamics (PBD) spring constraints
	# Stiffness controls how much of the error is corrected per step
	var stiff_factor = clampf(stiffness * dt, 0.0, 1.0)

	for spring in _springs:
		var ia: int = spring[0]
		var ib: int = spring[1]
		var rest: float = spring[2]

		var diff = _positions[ib] - _positions[ia]
		var dist = diff.length()
		if dist < 0.0001:
			continue

		var error = dist - rest
		var dir = diff / dist
		var correction = dir * error * 0.5 * stiff_factor

		if not _anchored[ia]:
			_positions[ia] += correction
		if not _anchored[ib]:
			_positions[ib] -= correction

	# Verlet integration: new_pos = pos + (pos - old_pos) * damping
	for i in range(_positions.size()):
		if _anchored[i]:
			continue

		var velocity = (_positions[i] - _old_positions[i]) * damping
		_old_positions[i] = _positions[i]
		_positions[i] += velocity


## Updates MultiMesh transforms to match current mass positions.
func _update_mass_visuals() -> void:
	for i in range(_positions.size()):
		var xf := Transform3D()
		xf.origin = _positions[i]
		_mass_mm.set_instance_transform(i, xf)


## Rebuilds spring line geometry from current positions with strain coloring.
func _update_spring_lines() -> void:
	_im.clear_surfaces()
	_im.surface_begin(Mesh.PRIMITIVE_LINES)

	for spring in _springs:
		var ia: int = spring[0]
		var ib: int = spring[1]
		var rest: float = spring[2]

		var a = _positions[ia]
		var b = _positions[ib]
		var dist = a.distance_to(b)

		# Color based on strain: compressed=blue, rest=neutral, stretched=red
		var strain = (dist - rest) / rest if rest > 0.001 else 0.0
		var col: Color
		if strain > 0.0:
			col = _spring_color.lerp(_spring_stretched, clampf(strain * 8.0, 0.0, 1.0))
		else:
			col = _spring_color.lerp(_spring_compressed, clampf(-strain * 8.0, 0.0, 1.0))

		_im.surface_set_color(col)
		_im.surface_add_vertex(a)
		_im.surface_set_color(col)
		_im.surface_add_vertex(b)

	_im.surface_end()


# ------------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------------

func _exit_tree() -> void:
	for child in get_children():
		if is_instance_valid(child):
			child.queue_free()


# ------------------------------------------------------------------
# Grid system integration
# ------------------------------------------------------------------

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("grid_size"):
		grid_size = int(config_data["grid_size"])
	if config_data.has("stiffness"):
		stiffness = float(config_data["stiffness"])
	if config_data.has("damping"):
		damping = float(config_data["damping"])
	if config_data.has("spacing"):
		spacing = float(config_data["spacing"])
