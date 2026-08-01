# @identity
# essence: a 2D grid of mass-spring oscillators where each cell nudges its neighbors via configurable coupling — independent at coupling=0, lattice-locked at high values, with central excitation driving the spectrum
# desire: to make the player feel that "wave" is not a thing but a relationship — when one oscillator moves, the lattice answers, and standing modes are simply patterns of agreement
# critical_parameter: coupling_strength — at 0 the grid is independent oscillators; at high values it locks into collective Chladni-like modes; the entire wave spectrum lives on this slider
# triggers: _physics_process() integrates each cell with its neighbors using natural_frequency and damping_coefficient; excitation_amplitude × excitation_frequency drives the central pulse outward through coupling_range
# emerges: standing waves on a grid — synchronization fronts, breathing modes, traveling pulses; the lattice becomes a tunable resonance instrument the player can walk into
# needs: VR walking through the lattice [has]; live coupling-strength slider [missing]; mode-visualization toggle [missing]; apply_grid_config [missing]
# relationships: pairs with wave_interference, sine_space, and seismograph in wavefunctions as the medium that the others measure or excite; reappears in advancedlaboratory's Systems Theory Laboratory as the keystone artifact
# truth: a wave is not a particle traveling — it is a pattern of agreement across coupled cells; the lattice IS the medium

@tool
extends Node3D

# Coupled Oscillator Lattice
# Grid of oscillators where each affects its neighbors
# Demonstrates wave modes, synchronization, and collective behavior

@export_group("Lattice Structure")
@export var lattice_size: Vector2i = Vector2i(12, 12)
@export var oscillator_spacing: float = 0.4
@export var base_height: float = 1.0

@export_group("Oscillator Properties")
@export var natural_frequency: float = 2.0  # Ï‰â‚€
@export var mass: float = 1.0
@export var damping_coefficient: float = 0.02

@export_group("Coupling")
@export var coupling_strength: float = 1.5  # How strongly neighbors affect each other
@export var coupling_range: int = 1  # 1 = nearest neighbors only

@export_group("Excitation")
@export var excite_center: bool = true
@export var excitation_amplitude: float = 0.5
@export var excitation_frequency: float = 2.0
@export_enum("Sine", "Pulse", "Random") var excitation_mode: String = "Sine"

@export_group("Visualization")
@export var oscillator_radius: float = 0.06
@export var color_by_displacement: bool = true
@export var show_connections: bool = false
@export var max_displacement_color: float = 0.8

@export_group("Fabric")
## AXIS — WHAT STANDS FOR THE MEDIUM in the picture.
##
## This artifact's own truth statement says "a wave is not a particle traveling — it is
## a pattern of agreement across coupled cells; the lattice IS the medium." The lattice
## then draws 144 separate balls and nothing between them: every relationship the
## sentence is about is invisible, and coupling_strength — the export the identity block
## calls critical — only becomes legible after seconds of propagation, which a still
## frame does not have. So the axis is not the coupling constant. It is which PART of
## the medium the artifact is willing to draw.
##
##   nodes     the legacy lineage: 144 spheres, nothing between them. The parts are
##             shown and the coupling is left to be inferred. What ships today.
##   bonds     a rod on every nearest-neighbour pair, following the two cells it joins.
##             The ball-and-stick model: the relations get a body, and the field of
##             dots becomes a woven net covering roughly a third of the plane.
##   sheet     the spheres go dark and a single continuous skin is stretched through
##             them, coloured by the same displacement law. The medium as ONE thing
##             rather than a set of things — the continuum reading of the same maths.
##   boundary  only the perimeter cells are drawn; the hundred interior ones go out.
##             The claim that a standing mode is made by its edges, and that most of
##             a medium is the part you are asked to take on trust.
##
## Nothing here changes the integration, the coupling force, the excitation or the
## displacement colouring. Every value reads the SAME oscillators[] array the physics
## writes; they disagree only about what a medium looks like.
@export var fabric: String = "nodes"
const FABRICS: PackedStringArray = ["nodes", "bonds", "sheet", "boundary"]
const BOND_THICKNESS := 0.035

# Internal data
var oscillators: Array[Dictionary] = []
var time: float = 0.0
var pulse_triggered: bool = false

# Fabric bodies (built only for a non-default value; null on the legacy path)
var _bond_pairs: Array[Vector2i] = []
var _bond_mm: MultiMeshInstance3D = null
var _sheet: MeshInstance3D = null
var _sheet_mesh: ImmediateMesh = null

func _ready() -> void:
	# The grid sets config metadata BEFORE add_child, so a map token lands here.
	# An unknown word keeps the default rather than emptying the lattice.
	if has_meta("config_fabric"):
		var token: String = str(get_meta("config_fabric")).strip_edges().to_lower()
		fabric = token if FABRICS.has(token) else fabric
	_build_lattice()
	# FABRIC, applied LAST so every Oscillator_N above keeps its index and its name.
	# "nodes" falls through and adds nothing at all.
	_apply_fabric()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	time += delta

	# Apply excitation
	if excite_center:
		_apply_excitation(delta)

	# Update oscillator physics
	_update_oscillators(delta)

	# Update visualization
	_update_visualization()

func _build_lattice() -> void:
	# Clear existing
	for child in get_children():
		child.queue_free()

	oscillators.clear()

	# Create oscillators
	for x in range(lattice_size.x):
		for y in range(lattice_size.y):
			var idx = x * lattice_size.y + y
			var grid_pos = Vector2(x, y)

			var oscillator_data = {
				"index": idx,
				"grid_pos": grid_pos,
				"position": Vector3(
					(x - lattice_size.x / 2.0) * oscillator_spacing,
					base_height,
					(y - lattice_size.y / 2.0) * oscillator_spacing
				),
				"displacement": 0.0,  # y displacement from equilibrium
				"velocity": 0.0,
				"acceleration": 0.0,
				"phase": randf() * TAU  # Random initial phase
			}

			oscillators.append(oscillator_data)

			# Create visual sphere
			_create_oscillator_visual(oscillator_data)

func _create_oscillator_visual(osc: Dictionary) -> void:
	var sphere = MeshInstance3D.new()
	sphere.name = "Oscillator_%d" % osc.index

	var mesh = SphereMesh.new()
	mesh.radius = oscillator_radius
	mesh.height = oscillator_radius * 2.0
	sphere.mesh = mesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.5, 1.0)
	mat.metallic = 0.0
	mat.roughness = 1.0
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.3, 0.8)
	mat.emission_energy_multiplier = 0.5
	sphere.material_override = mat

	sphere.position = osc.position
	add_child(sphere)

func _apply_excitation(_delta: float) -> void:
	# Find center oscillator
	var center_x = int(lattice_size.x / 2)
	var center_y = int(lattice_size.y / 2)
	var center_idx = center_x * lattice_size.y + center_y

	if center_idx >= oscillators.size():
		return

	var osc = oscillators[center_idx]

	match excitation_mode:
		"Sine":
			# Continuous sine wave
			var excitation = excitation_amplitude * sin(time * excitation_frequency * TAU)
			osc.displacement = excitation

		"Pulse":
			# Single pulse at start
			if not pulse_triggered and time > 0.5:
				osc.velocity += excitation_amplitude * 10.0
				pulse_triggered = true

		"Random":
			# Random excitation
			if randf() < 0.01:  # 1% chance per frame
				osc.velocity += excitation_amplitude * randf_range(-1.0, 1.0)

func _update_oscillators(delta: float) -> void:
	# Calculate forces from coupling
	var forces: Array[float] = []
	forces.resize(oscillators.size())

	for i in range(oscillators.size()):
		var osc = oscillators[i]
		var total_force = 0.0

		# Restoring force (like a spring to equilibrium)
		var omega_squared = natural_frequency * natural_frequency
		total_force -= omega_squared * osc.displacement

		# Coupling force from neighbors
		var neighbors = _get_neighbors(osc.grid_pos)
		for neighbor_idx in neighbors:
			if neighbor_idx >= 0 and neighbor_idx < oscillators.size():
				var neighbor = oscillators[neighbor_idx]
				# Force proportional to displacement difference
				var coupling_force = coupling_strength * (neighbor.displacement - osc.displacement)
				total_force += coupling_force

		# Damping
		total_force -= damping_coefficient * osc.velocity

		forces[i] = total_force

	# Integrate using velocity Verlet or simple Euler
	for i in range(oscillators.size()):
		var osc = oscillators[i]
		var force = forces[i]

		# F = ma, so a = F/m
		osc.acceleration = force / mass

		# Update velocity and position (Euler integration)
		osc.velocity += osc.acceleration * delta
		osc.displacement += osc.velocity * delta

func _get_neighbors(grid_pos: Vector2) -> Array[int]:
	"""Get indices of neighboring oscillators"""
	var neighbors: Array[int] = []

	for dx in range(-coupling_range, coupling_range + 1):
		for dy in range(-coupling_range, coupling_range + 1):
			if dx == 0 and dy == 0:
				continue  # Skip self

			var nx = int(grid_pos.x) + dx
			var ny = int(grid_pos.y) + dy

			# Check bounds
			if nx >= 0 and nx < lattice_size.x and ny >= 0 and ny < lattice_size.y:
				var neighbor_idx = nx * lattice_size.y + ny
				neighbors.append(neighbor_idx)

	return neighbors

func _update_visualization() -> void:
	for i in range(oscillators.size()):
		var osc = oscillators[i]
		var child_name = "Oscillator_%d" % i
		var child = get_node_or_null(NodePath(child_name))

		if child and child is MeshInstance3D:
			# Update position (oscillate in Y)
			child.position = osc.position + Vector3(0, osc.displacement, 0)

			# Update color based on displacement
			if color_by_displacement:
				var displacement_normalized = clamp(abs(osc.displacement) / max_displacement_color, 0.0, 1.0)
				var color = Color.from_hsv(0.6 - displacement_normalized * 0.3, 0.8, 1.0)

				var mat = child.material_override as StandardMaterial3D
				if mat:
					mat.albedo_color = color
					mat.emission = color * 0.5
					mat.emission_energy_multiplier = displacement_normalized + 0.2

	# The fabric bodies follow the same displacements the spheres just took. Gated on a
	# non-default value: on the legacy path this is one string compare and nothing else.
	if fabric != "nodes":
		_update_fabric()

func get_displacement_at(grid_x: int, grid_y: int) -> float:
	"""Get displacement of oscillator at grid position"""
	if grid_x >= 0 and grid_x < lattice_size.x and grid_y >= 0 and grid_y < lattice_size.y:
		var idx = grid_x * lattice_size.y + grid_y
		if idx < oscillators.size():
			return oscillators[idx].displacement
	return 0.0

func apply_displacement(grid_x: int, grid_y: int, displacement: float) -> void:
	"""Manually set displacement at specific oscillator"""
	if grid_x >= 0 and grid_x < lattice_size.x and grid_y >= 0 and grid_y < lattice_size.y:
		var idx = grid_x * lattice_size.y + grid_y
		if idx < oscillators.size():
			oscillators[idx].displacement = displacement

func get_total_energy() -> float:
	"""Calculate total energy in the system"""
	var total_energy = 0.0
	for osc in oscillators:
		# Kinetic energy
		var ke = 0.5 * mass * osc.velocity * osc.velocity
		# Potential energy
		var pe = 0.5 * mass * natural_frequency * natural_frequency * osc.displacement * osc.displacement
		total_energy += ke + pe
	return total_energy

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass


# ── FABRIC ───────────────────────────────────────────────────────────────────
# One axis, four answers to "what is the medium, in the picture". Every value reads the
# oscillators[] array the integrator writes and adds nothing to it: the coupling force,
# the excitation and the displacement colour law are untouched at all four.

func _apply_fabric() -> void:
	match fabric:
		"bonds":
			_build_bonds()
		"sheet":
			_veil_oscillators(false)
			_build_sheet()
		"boundary":
			_veil_oscillators(true)
		_:
			pass                                  # "nodes" — the legacy lineage


func _update_fabric() -> void:
	match fabric:
		"bonds":
			_update_bonds()
		"sheet":
			_update_sheet()
		_:
			pass


## Hide oscillator bodies with layers = 0, never visible = false. These spheres have no
## children today, but visibility resolves through is_visible_in_tree() and the habit of
## hiding a parent is how two values elsewhere in this corpus rendered empty frames.
## layers is per-instance, does not propagate, and leaves mesh and material alone.
## keep_edge = true keeps the perimeter ring (the "boundary" reading); false hides all.
func _veil_oscillators(keep_edge: bool) -> void:
	for x in range(lattice_size.x):
		for y in range(lattice_size.y):
			var edge: bool = (x == 0 or y == 0
				or x == lattice_size.x - 1 or y == lattice_size.y - 1)
			if keep_edge and edge:
				continue
			var idx: int = x * lattice_size.y + y
			var child = get_node_or_null(NodePath("Oscillator_%d" % idx))
			if child and child is VisualInstance3D:
				(child as VisualInstance3D).layers = 0


## BONDS — one rod per nearest-neighbour pair, in a single MultiMesh so 264 of them cost
## one draw call. The pair list is the same adjacency the coupling force uses, restricted
## to the four-neighbour cross; _get_neighbors() also returns diagonals at coupling_range
## 1, and drawing those would claim a lattice the springs do not have.
func _build_bonds() -> void:
	_bond_pairs.clear()
	for x in range(lattice_size.x):
		for y in range(lattice_size.y):
			var idx: int = x * lattice_size.y + y
			if x + 1 < lattice_size.x:
				_bond_pairs.append(Vector2i(idx, (x + 1) * lattice_size.y + y))
			if y + 1 < lattice_size.y:
				_bond_pairs.append(Vector2i(idx, idx + 1))
	if _bond_pairs.is_empty():
		return

	var rod: CylinderMesh = CylinderMesh.new()
	rod.top_radius = 1.0
	rod.bottom_radius = 1.0
	rod.height = 1.0
	rod.radial_segments = 6
	rod.rings = 0

	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = rod
	mm.instance_count = _bond_pairs.size()

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.42, 0.45, 0.72)
	mat.metallic = 0.0
	mat.roughness = 0.9
	mat.emission_enabled = true
	mat.emission = Color(0.20, 0.22, 0.52)
	mat.emission_energy_multiplier = 0.4

	_bond_mm = MultiMeshInstance3D.new()
	_bond_mm.name = "Bonds"
	_bond_mm.multimesh = mm
	_bond_mm.material_override = mat
	add_child(_bond_mm)
	_update_bonds()


func _update_bonds() -> void:
	if _bond_mm == null:
		return
	var mm: MultiMesh = _bond_mm.multimesh
	if mm == null:
		return
	for k in range(_bond_pairs.size()):
		var pair: Vector2i = _bond_pairs[k]
		var a: Vector3 = _osc_point(pair.x)
		var b: Vector3 = _osc_point(pair.y)
		var span: Vector3 = b - a
		var length: float = span.length()
		if length < 0.0001:
			continue
		var axis: Vector3 = span / length
		# Quaternion(from, to) is the shortest-arc rotation and is undefined for an
		# exactly antiparallel pair. Bonds are near-horizontal by construction (the
		# cells are 0.4 m apart in X or Z and displace only in Y), so this guard is
		# for the pathological case only.
		if absf(axis.y) > 0.999:
			continue
		var turn: Basis = Basis(Quaternion(Vector3.UP, axis))
		var shape: Basis = Basis.from_scale(Vector3(BOND_THICKNESS, length, BOND_THICKNESS))
		mm.set_instance_transform(k, Transform3D(turn * shape, a + span * 0.5))


## SHEET — one continuous skin through the oscillator points, rebuilt each visual update.
## Unshaded with vertex colour so it needs no normals and reads at any light angle, and
## double-sided so it is still a surface when you walk under the lattice. The colour law
## is copied verbatim from _update_visualization so the skin and the spheres would agree
## if you ever showed both.
func _build_sheet() -> void:
	_sheet_mesh = ImmediateMesh.new()
	_sheet = MeshInstance3D.new()
	_sheet.name = "Sheet"
	_sheet.mesh = _sheet_mesh

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_sheet.material_override = mat

	add_child(_sheet)
	_update_sheet()


func _update_sheet() -> void:
	if _sheet_mesh == null:
		return
	if lattice_size.x < 2 or lattice_size.y < 2:
		return
	_sheet_mesh.clear_surfaces()
	_sheet_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in range(lattice_size.x - 1):
		for y in range(lattice_size.y - 1):
			var i00: int = x * lattice_size.y + y
			var i10: int = (x + 1) * lattice_size.y + y
			var i01: int = i00 + 1
			var i11: int = i10 + 1
			_sheet_vertex(i00)
			_sheet_vertex(i10)
			_sheet_vertex(i11)
			_sheet_vertex(i00)
			_sheet_vertex(i11)
			_sheet_vertex(i01)
	_sheet_mesh.surface_end()


func _sheet_vertex(idx: int) -> void:
	var shade: float = 0.0
	if idx >= 0 and idx < oscillators.size():
		var d: float = oscillators[idx].displacement
		shade = clampf(absf(d) / maxf(max_displacement_color, 0.0001), 0.0, 1.0)
	_sheet_mesh.surface_set_color(Color.from_hsv(0.6 - shade * 0.3, 0.8, 1.0))
	_sheet_mesh.surface_add_vertex(_osc_point(idx))


## The live world position of one oscillator: its equilibrium seat plus the displacement
## the integrator wrote this frame. Exactly what _update_visualization gives its sphere.
func _osc_point(idx: int) -> Vector3:
	if idx < 0 or idx >= oscillators.size():
		return Vector3.ZERO
	var osc: Dictionary = oscillators[idx]
	var seat: Vector3 = osc.position
	var lift: float = osc.displacement
	return seat + Vector3(0, lift, 0)
