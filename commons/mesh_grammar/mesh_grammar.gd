## MeshGrammar — Rule orchestrator for the mesh grammar system.
## Holds a seed mesh and a list of rules. Applies rules in sequence per generation.
## Stores generation history for animation playback.
## Modeled after LSystem (utils/lsystem.gd) and origami solvers.
extends RefCounted
class_name MeshGrammar

var rules: Array[MeshRule] = []
var seed_mesh: MeshData = null
var current_mesh: MeshData = null
var generation: int = 0
var max_faces: int = 10000  # Safety limit to prevent runaway growth

var _history: Array[MeshData] = []

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

## Set the starting mesh.
func set_seed(mesh: MeshData) -> void:
	seed_mesh = mesh.duplicate_mesh()
	current_mesh = mesh.duplicate_mesh()
	generation = 0
	_history.clear()
	_history.append(current_mesh.duplicate_mesh())

## Add a rule to the grammar.
func add_rule(rule: MeshRule) -> void:
	rules.append(rule)

## Remove all rules.
func clear_rules() -> void:
	rules.clear()

# ---------------------------------------------------------------------------
# Generation
# ---------------------------------------------------------------------------

## Apply all rules once in sequence (one generation). Returns the resulting mesh.
func apply_step() -> MeshData:
	if current_mesh == null:
		return null

	for rule in rules:
		if current_mesh.face_count() >= max_faces:
			break
		rule.apply(current_mesh)

	generation += 1
	_history.append(current_mesh.duplicate_mesh())
	return current_mesh

## Apply n generations.
func apply_n(n: int) -> MeshData:
	for _i in range(n):
		apply_step()
		if current_mesh.face_count() >= max_faces:
			break
	return current_mesh

## Reset to seed state.
func reset() -> void:
	if seed_mesh:
		current_mesh = seed_mesh.duplicate_mesh()
	generation = 0
	_history.clear()
	if current_mesh:
		_history.append(current_mesh.duplicate_mesh())

# ---------------------------------------------------------------------------
# History & Animation
# ---------------------------------------------------------------------------

## Get the number of stored generations.
func get_history_size() -> int:
	return _history.size()

## Get mesh snapshot at a specific generation.
func get_mesh_at_generation(gen: int) -> MeshData:
	if gen >= 0 and gen < _history.size():
		return _history[gen]
	return current_mesh

## Interpolate between generation snapshots for smooth animation.
## t: 0.0 = generation 0 (seed), 1.0 = latest generation.
## When topologies differ between generations, snaps to nearest.
func interpolate_generation(t: float) -> MeshData:
	if _history.size() <= 1:
		return current_mesh

	var total_gens := float(_history.size() - 1)
	var exact := clampf(t, 0.0, 1.0) * total_gens
	var gen_low := int(floor(exact))
	var gen_high := mini(gen_low + 1, _history.size() - 1)
	var frac := exact - float(gen_low)

	var mesh_a: MeshData = _history[gen_low]
	var mesh_b: MeshData = _history[gen_high]

	# Can only interpolate if vertex counts match
	if mesh_a.vertex_count() != mesh_b.vertex_count():
		return mesh_b if frac > 0.5 else mesh_a

	# Interpolate vertex positions
	var result: MeshData = mesh_b.duplicate_mesh()
	for i in range(result.vertices.size()):
		result.vertices[i] = mesh_a.vertices[i].lerp(mesh_b.vertices[i], frac)
	return result

## Get current generation number.
func get_generation() -> int:
	return generation
