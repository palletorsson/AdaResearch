Concept: A grown map. The walker entered an empty bounding box, laid 116 floor cells as it walked, placed 20 artifacts with clearance (and 5 of them on tables for eye-level reading), and ended at the teleporter. The map is the record of the walk.

Actualizes: The inverse-placement principle — instead of placing artifacts INTO a pre-defined room, the room is what the placement leaves behind. The map's shape is the artifact set's necessary geometry, nothing more.

Sequence role: Demonstration map for the grow_walker strategy from placement_research. Generated 2026-05-15 by tools/grow_map.py.

Technical angle: Each artifact's `spatial_needs` (footprint_cells, clearance, isolation, wall_backing, preferred_zone, cluster_with) drives the floor-laying decision. Tables are emitted for small displays (footprint ≤ 2 cells, not wall-backed). The bounding box is then cropped to the laid cells + 1-cell margin.

Critical angle: This strategy produces the minimum walkable surface that satisfies the artifact set's constraints — no wasted floor, no empty back-fill. The shape of the map is an honest signature of which artifacts were given and what they needed from each other.

Key artifacts:
- laser_measure
- science_screen
- dgrid
- modulor_man_demo
- cube_scene
- laser_exploding_sphere
- lightrod
- line
- plus_line_puzzle
- parallel_line_puzzle
- scale_lines
- lab_room
- line_builder_3d
- dark_sphere
- floating_sphere_field
- grabbable_line
- fontana_puncture
- laser_sword
- klee_walking_point
- perspective_lines

Gap: Tables don't (yet) emit a proper visible table prop — they're encoded as height-2 floor cells in the structure layer. Visible table primitives could be added by routing the table cells through a placement_rules action.