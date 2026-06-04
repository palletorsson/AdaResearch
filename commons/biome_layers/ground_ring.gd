# ground_ring.gd
# Accrual layer (order 1, always): the surrounding ground plane + fog-fade
# landscape AND the ring-zone MultiMesh ground-cover (grass / flower / mushroom
# scattered in the annulus around the grid). This is the world extending into
# mist past the grid edge — plus the walkable ground collider beneath it.
#
# CONSOLIDATION Phase 4b (2026-06-04): BiomeRingComponent used to be a
# GridSystem special-case, invoked directly in _handle_biome_ring() PARALLEL
# to the accrual stack. This layer folds it INTO the accrual stack so the biome
# comes from ONE populator (BiomeAccrualManager). The ring thereby inherits
# per-map biome_overrides (disable / tune) for free, exactly like every other
# layer, and GridSystem no longer special-cases it.
#
# Implementation note — we WRAP the existing, tested BiomeRingComponent rather
# than reimplement it. The ring owns the walkable ground collider (the floor
# players stand on beyond the grid) and the ring-zone ground-cover foliage;
# rewriting that risks the one piece of biome that affects locomotion. The
# wrapper keeps that code byte-for-byte and only changes WHERE it is invoked.
#
# `"always": true` in biome_contributions.json keeps this layer applying even
# in biome_lab mode (Biome_Spine / Biome_Zoo), matching the prior behaviour
# where GridSystem ran the ring unconditionally (the lab-mode skip otherwise
# drops every non-lab_only layer).

extends Node3D

const BiomeRingComponentClass = preload("res://commons/grid/BiomeRingComponent.gd")


func apply(ctx: Dictionary) -> void:
	var density: float = float(ctx.get("density", 0.0))
	# Barren maps (seq 1-2, density < 0.05): no ground ring. This mirrors the
	# component's own internal gate and the old GridSystem density gate, so the
	# clinical early sequences stay void with no surrounding landscape.
	if density < 0.05:
		return

	var grid_dims: Vector3i = ctx.get("grid_dims", Vector3i(10, 1, 10))
	var cube_size: float = float(ctx.get("cube_size", 1.0))
	var terrain_mode: String = str(ctx.get("terrain_mode", "flat"))
	var kingdoms: Array = ctx.get("kingdoms", [])

	var ring = BiomeRingComponentClass.new()
	ring.name = "BiomeRing"
	add_child(ring)
	ring.generate(grid_dims, cube_size, terrain_mode, kingdoms, density)
	print("[ground_ring] accrual layer → ring generated (density=%.2f, terrain=%s)" % [density, terrain_mode])
