# ChunkData.gd — Lightweight data container for a single spatial chunk
#
# Part of the chunk-based LOD system. Each chunk is a square cell in the
# XZ plane, holding references to organisms spawned within it and their
# current LOD state.

class_name ChunkData
extends RefCounted

# ── Identity ─────────────────────────────────────────────────────

## Chunk grid coordinate (XZ index, not world position).
var coord: Vector2i = Vector2i.ZERO

## World-space center of this chunk (Y = 0).
var center: Vector3 = Vector3.ZERO


# ── Organism tracking ────────────────────────────────────────────

## Static organisms (tree, flower, fungus) — don't move after spawn.
var plant_entities: Array[CritterEntity] = []

## Mobile organisms (creature) — may move between chunks.
var creature_entities: Array[CritterEntity] = []

## DNA cache parallel to plant_entities — needed for LOD rebuild.
var plant_dna_cache: Array[CritterDNA] = []


# ── LOD state ────────────────────────────────────────────────────

## Current LOD tier (0 = distant/minimal, 3 = near/full detail). -1 = unset.
var current_lod_tier: int = -1

## Flagged true when tier changed and entities need LOD rebuild.
var needs_lod_update: bool = false


# ═══════════════════════════════════════════════════════════════
# METHODS
# ═══════════════════════════════════════════════════════════════

## Add a static plant with its DNA (for later LOD rebuild).
func add_plant(entity: CritterEntity, dna: CritterDNA) -> void:
	plant_entities.append(entity)
	plant_dna_cache.append(dna)


## Add a mobile creature.
func add_creature(entity: CritterEntity) -> void:
	creature_entities.append(entity)


## All organisms in this chunk.
func get_all_entities() -> Array[CritterEntity]:
	var all: Array[CritterEntity] = []
	all.append_array(plant_entities)
	all.append_array(creature_entities)
	return all


## Total organism count.
func get_entity_count() -> int:
	return plant_entities.size() + creature_entities.size()


## Remove freed or invalid entity references.
func remove_invalid() -> void:
	# Plants — keep DNA cache in sync
	var i: int = plant_entities.size() - 1
	while i >= 0:
		if not is_instance_valid(plant_entities[i]):
			plant_entities.remove_at(i)
			plant_dna_cache.remove_at(i)
		i -= 1

	# Creatures
	var j: int = creature_entities.size() - 1
	while j >= 0:
		if not is_instance_valid(creature_entities[j]):
			creature_entities.remove_at(j)
		j -= 1


## Clear all references and reset state.
func clear() -> void:
	plant_entities.clear()
	plant_dna_cache.clear()
	creature_entities.clear()
	current_lod_tier = -1
	needs_lod_update = false
