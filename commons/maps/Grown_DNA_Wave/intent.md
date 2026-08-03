Concept: A grown map. The walker entered an empty bounding box, laid 90 floor cells as it walked, placed 26 artifacts with clearance (and 8 of them on tables for eye-level reading), and ended at the teleporter. The map is the record of the walk.

Actualizes: The inverse-placement principle — instead of placing artifacts INTO a pre-defined room, the room is what the placement leaves behind. The map's shape is the artifact set's necessary geometry, nothing more.

Sequence role: Demonstration map for the grow_walker strategy from placement_research. Generated 2026-05-15 by tools/grow_map.py.

Technical angle: Each artifact's `spatial_needs` (footprint_cells, clearance, isolation, wall_backing, preferred_zone, cluster_with) drives the floor-laying decision. Tables are emitted for small displays (footprint ≤ 2 cells, not wall-backed). The bounding box is then cropped to the laid cells + 1-cell margin.

Critical angle: This strategy produces the minimum walkable surface that satisfies the artifact set's constraints — no wasted floor, no empty back-fill. The shape of the map is an honest signature of which artifacts were given and what they needed from each other.

Key artifacts:
- GlassRack_BreakingBadCoffee
- RackAmbientDrone
- GlassRack_DistillationY
- BigPipe
- BigPipe_IndustrialBranch
- BigPipe_StraightRun
- BigPipe_VerticalBypass
- GlassRack_SimpleTube
- GlassRack_SpiralTube
- Rack303Acid
- MarioSoundController
- BigPipeSystem
- BigPipe_CrossManifold
- BigPipe_LBend
- BigPipe_Serpentine
- BigPipe_TDistribution
- GlassRack
- GlassRack_BranchingCondenser
- GlassRack_ComplexApparatus
- GlassRack_DistillationRack
- GlassRack_FractionalDistillation
- GlassRack_RefluxApparatus
- GlassRack_SbendManifold
- GlassRack_SpiralCondenser
- Rack808Drums
- RackDX7Piano

Gap: Tables don't (yet) emit a proper visible table prop — they're encoded as height-2 floor cells in the structure layer. Visible table primitives could be added by routing the table cells through a placement_rules action.