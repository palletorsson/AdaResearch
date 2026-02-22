# CritterEntity.gd — Base class for every living thing in the Nature System
#
# All five kingdoms (Tree, Creature, Flower, Fungus, Cave) extend this.
# A CritterEntity owns a CritterDNA Resource and uses CritterTraitMapper
# to express its genes as visual form. Subclasses override the virtual
# hooks to build kingdom-specific meshes and behaviors.
#
# Lifecycle:
#   1. Instantiate scene
#   2. Call init_from_dna(dna) — or assign dna in inspector
#   3. _apply_visual_traits() builds mesh + materials
#   4. _apply_gameplay_traits() sets behavior parameters
#   5. dna_applied signal fires — external systems can react

class_name CritterEntity
extends Node3D

# ─────────────────────────────────────────────────────────────
#  DNA & Identity
# ─────────────────────────────────────────────────────────────
@export var dna: CritterDNA = null:
	set(value):
		dna = value
		if is_inside_tree() and dna:
			_on_dna_changed()

@export var debug_mode: bool = false

# ─────────────────────────────────────────────────────────────
#  Runtime state
# ─────────────────────────────────────────────────────────────
var _trait_mapper: CritterTraitMapper = null
var _mesh_instances: Array[MeshInstance3D] = []
var _multimesh_instances: Array[MultiMeshInstance3D] = []
var _bond_level: float = 0.0  ## Player bond (0-1), drives transmutation overlay
var _age: float = 0.0
var _energy: float = 100.0
var _max_energy: float = 100.0

# ─────────────────────────────────────────────────────────────
#  Signals
# ─────────────────────────────────────────────────────────────
signal dna_applied(entity: CritterEntity)
signal bond_changed(entity: CritterEntity, level: float)
signal energy_changed(current: float, maximum: float)
signal transmutation_ready(entity: CritterEntity)


# ═══════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════

func _ready() -> void:
	_trait_mapper = CritterTraitMapper.new()

	# If DNA was assigned in inspector, apply it now
	if dna:
		_on_dna_changed()


## Main entry point — inject DNA at runtime (e.g., from spawner or evolution).
func init_from_dna(new_dna: CritterDNA) -> void:
	dna = new_dna  # Triggers setter → _on_dna_changed()


## Called whenever DNA changes (initial assignment or runtime mutation).
func _on_dna_changed() -> void:
	if not dna:
		return

	if debug_mode:
		print("[CritterEntity: %s] DNA changed — kingdom: %s, gen: %d" % [
			name, dna.get_kingdom_name(), dna.generation
		])

	# Store DNA reference in metadata for debug tools
	set_meta("dna", dna)
	set_meta("kingdom", dna.get_kingdom_name())

	# Build the body first, then apply materials
	_apply_visual_traits()
	_apply_gameplay_traits()

	dna_applied.emit(self)


# ═══════════════════════════════════════════════════════════════
# VIRTUAL HOOKS — Subclasses override these
# ═══════════════════════════════════════════════════════════════

## Build or update mesh(es) from DNA. Override in kingdom subclasses.
## After building meshes, call _collect_mesh_instances() and _apply_materials().
func _apply_visual_traits() -> void:
	# Default: collect existing meshes and apply DNA shader
	_collect_mesh_instances()
	_apply_materials()

	if debug_mode:
		print("[CritterEntity: %s] Applied visual traits to %d meshes" % [
			name, _mesh_instances.size()
		])


## Set gameplay parameters from DNA (speed, energy, behavior).
## Override in kingdom subclasses for specific behavior.
func _apply_gameplay_traits() -> void:
	if not dna:
		return

	# Base energy from efficiency
	_max_energy = dna.efficiency * 100.0
	_energy = _max_energy

	# Scale from DNA
	scale = Vector3.ONE * dna.scale

	if debug_mode:
		print("[CritterEntity: %s] Applied gameplay traits — energy: %.1f, scale: %.2f" % [
			name, _max_energy, dna.scale
		])


# ═══════════════════════════════════════════════════════════════
# MESH & MATERIAL MANAGEMENT
# ═══════════════════════════════════════════════════════════════

## Recursively collect all MeshInstance3D and MultiMeshInstance3D children.
func _collect_mesh_instances() -> void:
	_mesh_instances.clear()
	_multimesh_instances.clear()
	_collect_meshes_recursive(self)


func _collect_meshes_recursive(node: Node) -> void:
	if node is MeshInstance3D:
		if not node in _mesh_instances:
			_mesh_instances.append(node)
	elif node is MultiMeshInstance3D:
		if not node in _multimesh_instances:
			_multimesh_instances.append(node)
	for child in node.get_children():
		_collect_meshes_recursive(child)


## Apply DNA-driven materials to all collected meshes.
## Each mesh gets a unique ShaderMaterial with per-instance variation.
func _apply_materials() -> void:
	if not dna or not _trait_mapper:
		return

	var base_seed: int = get_instance_id()

	for i in _mesh_instances.size():
		var mesh := _mesh_instances[i]
		if not is_instance_valid(mesh):
			continue

		# Create a unique material per mesh
		var material := _trait_mapper.create_material_from_dna(dna, base_seed + i)

		# Add per-instance variation for organic look
		_trait_mapper.apply_variation(material, base_seed + i * 100)

		# Apply bond overlay if bonded
		if _bond_level > 0.01:
			_trait_mapper.apply_bond_overlay(material, dna, _bond_level)

		mesh.material_override = material

	# MultiMeshInstance3D nodes: apply bond overlay to their existing material
	# (morphology generators already set material_override with the base material)
	for mmi in _multimesh_instances:
		if not is_instance_valid(mmi):
			continue
		if _bond_level > 0.01 and mmi.material_override is ShaderMaterial:
			_trait_mapper.apply_bond_overlay(mmi.material_override, dna, _bond_level)

	if debug_mode:
		print("[CritterEntity: %s] Applied materials to %d meshes + %d multimeshes (seed: %d)" % [
			name, _mesh_instances.size(), _multimesh_instances.size(), base_seed
		])


# ═══════════════════════════════════════════════════════════════
# BOND / TRANSMUTATION (Player relationship system)
# ═══════════════════════════════════════════════════════════════

## Change bond level. Visual overlay updates automatically.
func set_bond_level(level: float) -> void:
	var old_level := _bond_level
	_bond_level = clampf(level, 0.0, 1.0)

	if absf(_bond_level - old_level) > 0.001:
		_update_bond_visuals()
		bond_changed.emit(self, _bond_level)

		# Check for transmutation threshold
		if _bond_level >= 0.95 and old_level < 0.95:
			transmutation_ready.emit(self)


func get_bond_level() -> float:
	return _bond_level


## Increase bond from a player interaction.
func interact(action: String) -> void:
	if not dna:
		return

	var delta := 0.0
	match action:
		"observe":
			delta = 0.02
		"feed":
			delta = 0.1
		"touch":
			delta = 0.05
		"survive":
			delta = 0.15
		"fight":
			delta = -0.3

	# Affinity gene modulates how easily this critter bonds
	delta *= (0.5 + dna.affinity)

	set_bond_level(_bond_level + delta)

	if debug_mode:
		print("[CritterEntity: %s] Interaction '%s' → bond: %.2f (delta: %.3f)" % [
			name, action, _bond_level, delta
		])


## Update all mesh materials to reflect current bond level.
func _update_bond_visuals() -> void:
	if not dna or not _trait_mapper:
		return

	for mesh in _mesh_instances:
		if is_instance_valid(mesh) and mesh.material_override is ShaderMaterial:
			_trait_mapper.apply_bond_overlay(mesh.material_override, dna, _bond_level)

	for mmi in _multimesh_instances:
		if is_instance_valid(mmi) and mmi.material_override is ShaderMaterial:
			_trait_mapper.apply_bond_overlay(mmi.material_override, dna, _bond_level)


# ═══════════════════════════════════════════════════════════════
# ENERGY / METABOLISM
# ═══════════════════════════════════════════════════════════════

func consume_energy(amount: float) -> bool:
	if _energy >= amount:
		_energy -= amount
		energy_changed.emit(_energy, _max_energy)
		return true
	return false


func restore_energy(amount: float) -> void:
	_energy = minf(_energy + amount, _max_energy)
	energy_changed.emit(_energy, _max_energy)


func get_energy_ratio() -> float:
	if _max_energy <= 0.0:
		return 0.0
	return _energy / _max_energy


# ═══════════════════════════════════════════════════════════════
# AGING
# ═══════════════════════════════════════════════════════════════

func advance_age(delta: float) -> void:
	_age += delta * (dna.growth_speed if dna else 1.0)


func get_age() -> float:
	return _age


# ═══════════════════════════════════════════════════════════════
# REPRODUCTION
# ═══════════════════════════════════════════════════════════════

## Create child DNA from this entity and a partner.
func breed_with(partner: CritterEntity) -> CritterDNA:
	if not dna or not partner.dna:
		push_error("[CritterEntity] Cannot breed: missing DNA")
		return null

	var child_dna := CritterDNA.crossover(dna, partner.dna)
	CritterDNA.mutate(child_dna, 0.05)

	if debug_mode:
		print("[CritterEntity: %s] Bred with %s → gen %d child (distance: %.3f)" % [
			name, partner.name, child_dna.generation,
			CritterDNA.distance(dna, child_dna)
		])

	return child_dna


## Self-reproduce with mutation only (asexual / budding).
func reproduce_asexual(mutation_rate: float = 0.08) -> CritterDNA:
	if not dna:
		return null

	var child_dna := dna.duplicate()
	child_dna.generation = dna.generation + 1
	child_dna.parent_a_id = str(get_instance_id())
	child_dna.parent_b_id = ""
	child_dna.mutations = []
	CritterDNA.mutate(child_dna, mutation_rate)
	return child_dna


# ═══════════════════════════════════════════════════════════════
# UTILITY
# ═══════════════════════════════════════════════════════════════

## Which kingdom this entity belongs to (derived from DNA).
func get_kingdom() -> int:
	return dna.get_kingdom() if dna else -1

func get_kingdom_name() -> String:
	return dna.get_kingdom_name() if dna else "none"

## How hybrid is this entity (0 = pure kingdom, 0.5 = max hybrid).
func get_hybridity() -> float:
	return dna.get_hybridity() if dna else 0.0
