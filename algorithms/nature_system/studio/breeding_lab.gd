# BreedingLab.gd — Select two parents, visualize crossover, produce offspring
#
# Two pedestals for placing parent specimens. When both are occupied,
# the lab previews predicted offspring and allows the player to breed them.
# Cross-kingdom breeding is always allowed in the lab (experimentation zone).
#
# Usage:
#   var lab := BreedingLab.new()
#   add_child(lab)
#   lab.set_parent_a(dna_a)
#   lab.set_parent_b(dna_b)
#   lab.breed()  # or player pulls VR lever

class_name BreedingLab
extends Node3D

# ─────────────────────────────────────────────────────────────
#  Configuration
# ─────────────────────────────────────────────────────────────

## Number of offspring previews to show.
@export var preview_count: int = 3

## Mutation rate for breeding (matches EvolutionSystem default).
@export var mutation_rate: float = 0.05

## Mutation strength.
@export var mutation_strength: float = 0.1

## Spacing between preview specimens.
@export var preview_spacing: float = 1.0

## LOD for parent display (high detail).
@export var parent_lod: int = 0

## LOD for preview specimens (slightly lower for performance).
@export var preview_lod: int = 1


# ─────────────────────────────────────────────────────────────
#  Signals
# ─────────────────────────────────────────────────────────────

## Fired when both parents are placed and previews are generated.
signal parents_ready(parent_a: CritterDNA, parent_b: CritterDNA, distance: float)

## Fired when breeding produces a child.
signal breeding_complete(child_dna: CritterDNA, parent_a: CritterDNA, parent_b: CritterDNA)

## Fired when a parent slot is updated.
signal parent_changed(slot: String, dna: CritterDNA)


# ─────────────────────────────────────────────────────────────
#  Runtime state
# ─────────────────────────────────────────────────────────────

## Parent DNA (slot A — left pedestal).
var _parent_a_dna: CritterDNA = null

## Parent DNA (slot B — right pedestal).
var _parent_b_dna: CritterDNA = null

## Parent entities (visual display).
var _parent_a_entity: CritterEntity = null
var _parent_b_entity: CritterEntity = null

## Preview offspring entities.
var _preview_entities: Array[CritterEntity] = []

## Preview offspring DNAs.
var _preview_dnas: Array[CritterDNA] = []

## Genetic distance between parents (cached).
var _genetic_distance: float = 0.0

## Whether both parents are set and previews are showing.
var _ready_to_breed: bool = false

## Shared trait mapper.
var _trait_mapper: CritterTraitMapper = null

## Pedestal nodes.
var _pedestal_a: Node3D = null
var _pedestal_b: Node3D = null
var _preview_area: Node3D = null

## RNG for reproducible previews.
var _preview_rng: RandomNumberGenerator = null


# ═══════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════

func _ready() -> void:
	_trait_mapper = CritterTraitMapper.new()
	_preview_rng = RandomNumberGenerator.new()
	_preview_rng.randomize()
	_build_lab_structure()


# ═══════════════════════════════════════════════════════════════
# PUBLIC API — Setting Parents
# ═══════════════════════════════════════════════════════════════

## Place a DNA on the left (A) pedestal.
func set_parent_a(dna: CritterDNA) -> void:
	_parent_a_dna = dna
	_display_parent(dna, _pedestal_a, "_parent_a_entity")
	parent_changed.emit("a", dna)
	_check_both_parents()


## Place a DNA on the right (B) pedestal.
func set_parent_b(dna: CritterDNA) -> void:
	_parent_b_dna = dna
	_display_parent(dna, _pedestal_b, "_parent_b_entity")
	parent_changed.emit("b", dna)
	_check_both_parents()


## Clear a parent slot.
func clear_parent(slot: String) -> void:
	if slot == "a":
		_parent_a_dna = null
		if _parent_a_entity and is_instance_valid(_parent_a_entity):
			_parent_a_entity.queue_free()
		_parent_a_entity = null
	elif slot == "b":
		_parent_b_dna = null
		if _parent_b_entity and is_instance_valid(_parent_b_entity):
			_parent_b_entity.queue_free()
		_parent_b_entity = null

	_ready_to_breed = false
	_clear_previews()
	parent_changed.emit(slot, null)


## Clear both parents and all previews.
func clear_all() -> void:
	clear_parent("a")
	clear_parent("b")


# ═══════════════════════════════════════════════════════════════
# PUBLIC API — Breeding
# ═══════════════════════════════════════════════════════════════

## Perform breeding. Returns the child DNA, or null if parents aren't set.
func breed() -> CritterDNA:
	if not _ready_to_breed or not _parent_a_dna or not _parent_b_dna:
		push_warning("[BreedingLab] Cannot breed: parents not set")
		return null

	# Crossover
	var child_dna: CritterDNA = CritterDNA.crossover(_parent_a_dna, _parent_b_dna)

	# Mutation
	CritterDNA.mutate(child_dna, mutation_rate, mutation_strength)

	breeding_complete.emit(child_dna, _parent_a_dna, _parent_b_dna)
	return child_dna


## Get the genetic distance between the current parents.
func get_genetic_distance() -> float:
	return _genetic_distance


## Check if both parents are placed and lab is ready to breed.
func is_ready() -> bool:
	return _ready_to_breed


## Get the current preview offspring DNAs.
func get_preview_dnas() -> Array[CritterDNA]:
	return _preview_dnas


## Get a mutation report for a child DNA relative to its parents.
## Returns Array of { gene, parent_source, parent_value, child_value, delta }.
func get_mutation_report(child_dna: CritterDNA) -> Array[Dictionary]:
	if not _parent_a_dna or not _parent_b_dna:
		return []

	var report: Array[Dictionary] = []
	for gene_name in child_dna.mutations:
		var child_val = child_dna.get(gene_name)
		var a_val = _parent_a_dna.get(gene_name)
		var b_val = _parent_b_dna.get(gene_name)

		if child_val is float and a_val is float and b_val is float:
			# Figure out which parent was closer to the original value
			var dist_a: float = absf(child_val - a_val)
			var dist_b: float = absf(child_val - b_val)
			var source: String = "a" if dist_a < dist_b else "b"
			var parent_val: float = a_val if source == "a" else b_val

			report.append({
				"gene": gene_name,
				"parent_source": source,
				"parent_value": parent_val,
				"child_value": child_val,
				"delta": child_val - parent_val,
				"category": CritterDNA._categorize_gene(gene_name),
			})

	return report


## Get compatibility info between the current parents.
func get_compatibility_info() -> Dictionary:
	if not _parent_a_dna or not _parent_b_dna:
		return {}

	var ka: int = _parent_a_dna.get_kingdom()
	var kb: int = _parent_b_dna.get_kingdom()
	var same_kingdom: bool = ka == kb

	# Predict child body_type range
	var min_bt: float = minf(_parent_a_dna.body_type, _parent_b_dna.body_type)
	var max_bt: float = maxf(_parent_a_dna.body_type, _parent_b_dna.body_type)

	return {
		"same_kingdom": same_kingdom,
		"kingdom_a": _parent_a_dna.get_kingdom_name(),
		"kingdom_b": _parent_b_dna.get_kingdom_name(),
		"genetic_distance": _genetic_distance,
		"predicted_body_type_range": [min_bt, max_bt],
		"will_produce_hybrid": not same_kingdom,
		"distance_category": _categorize_distance(_genetic_distance),
	}


# ═══════════════════════════════════════════════════════════════
# INTERNAL
# ═══════════════════════════════════════════════════════════════

## Check if both parents are placed, generate previews if so.
func _check_both_parents() -> void:
	if not _parent_a_dna or not _parent_b_dna:
		_ready_to_breed = false
		_clear_previews()
		return

	# Calculate distance
	_genetic_distance = CritterDNA.distance(_parent_a_dna, _parent_b_dna)

	# Generate previews
	_generate_previews()

	_ready_to_breed = true
	parents_ready.emit(_parent_a_dna, _parent_b_dna, _genetic_distance)


## Generate preview offspring with different RNG seeds.
func _generate_previews() -> void:
	_clear_previews()
	_preview_dnas.clear()

	for i in preview_count:
		# Use different seed for each preview
		_preview_rng.seed = hash(_parent_a_dna.body_type + _parent_b_dna.body_type) + i * 1000

		var preview_dna: CritterDNA = CritterDNA.crossover(_parent_a_dna, _parent_b_dna)
		CritterDNA.mutate(preview_dna, mutation_rate, mutation_strength)
		_preview_dnas.append(preview_dna)

		# Create visual entity
		var entity := CritterEntity.new()
		entity.name = "Preview_%d_%s" % [i, preview_dna.get_kingdom_name()]
		_preview_area.add_child(entity)

		# Position in a row
		var x_offset: float = (float(i) - float(preview_count - 1) / 2.0) * preview_spacing
		entity.position = Vector3(x_offset, 0.3, 0.0)

		# Build morphology
		MorphologyRouter.build(preview_dna, entity, _trait_mapper, preview_lod)
		entity.init_from_dna(preview_dna)

		_preview_entities.append(entity)


## Clear all preview entities.
func _clear_previews() -> void:
	for entity in _preview_entities:
		if is_instance_valid(entity):
			entity.queue_free()
	_preview_entities.clear()
	_preview_dnas.clear()


## Display a parent DNA on a pedestal.
func _display_parent(dna: CritterDNA, pedestal: Node3D, entity_field: String) -> void:
	# Remove old entity
	var old_entity = get(entity_field)
	if old_entity and is_instance_valid(old_entity):
		(old_entity as CritterEntity).queue_free()

	if not dna or not pedestal:
		set(entity_field, null)
		return

	# Create new entity
	var entity := CritterEntity.new()
	entity.name = "Parent_%s_%s" % [entity_field.trim_prefix("_parent_").trim_suffix("_entity"), dna.get_kingdom_name()]
	pedestal.add_child(entity)
	entity.position = Vector3(0, 0.4, 0)

	MorphologyRouter.build(dna, entity, _trait_mapper, parent_lod)
	entity.init_from_dna(dna)

	set(entity_field, entity)


## Categorize genetic distance for UI display.
static func _categorize_distance(dist: float) -> String:
	if dist < 0.1:
		return "near_identical"
	elif dist < 0.25:
		return "close_relatives"
	elif dist < 0.4:
		return "moderate"
	elif dist < 0.6:
		return "diverse"
	else:
		return "very_distant"


## Build the physical lab structure (two pedestals + preview area).
func _build_lab_structure() -> void:
	# Parent A pedestal (left)
	_pedestal_a = Node3D.new()
	_pedestal_a.name = "PedestalA"
	_pedestal_a.position = Vector3(-1.5, 0, 0)
	add_child(_pedestal_a)
	_build_pedestal_mesh(_pedestal_a, Color(0.2, 0.1, 0.25))

	# Parent B pedestal (right)
	_pedestal_b = Node3D.new()
	_pedestal_b.name = "PedestalB"
	_pedestal_b.position = Vector3(1.5, 0, 0)
	add_child(_pedestal_b)
	_build_pedestal_mesh(_pedestal_b, Color(0.1, 0.15, 0.25))

	# Preview area (center, slightly forward)
	_preview_area = Node3D.new()
	_preview_area.name = "PreviewArea"
	_preview_area.position = Vector3(0, 0, 2.0)
	add_child(_preview_area)

	# Preview platform
	var platform := MeshInstance3D.new()
	platform.name = "PreviewPlatform"
	var box := BoxMesh.new()
	box.size = Vector3(preview_count * preview_spacing + 1.0, 0.08, 1.0)
	platform.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.1, 0.15)
	mat.roughness = 0.4
	platform.material_override = mat
	_preview_area.add_child(platform)


## Build a simple pedestal mesh.
func _build_pedestal_mesh(parent: Node3D, color: Color) -> void:
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "PedestalMesh"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.4
	cyl.bottom_radius = 0.5
	cyl.height = 0.2
	cyl.radial_segments = 16
	mesh_inst.mesh = cyl

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.25
	mat.metallic = 0.15
	mesh_inst.material_override = mat

	parent.add_child(mesh_inst)
