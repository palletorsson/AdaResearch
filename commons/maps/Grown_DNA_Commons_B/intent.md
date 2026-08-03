Concept: A grown map. The walker entered an empty bounding box, laid 140 floor cells as it walked, placed 35 artifacts with clearance (and 0 of them on tables for eye-level reading), and ended at the teleporter. The map is the record of the walk.

Actualizes: The inverse-placement principle — instead of placing artifacts INTO a pre-defined room, the room is what the placement leaves behind. The map's shape is the artifact set's necessary geometry, nothing more.

Sequence role: Demonstration map for the grow_walker strategy from placement_research. Generated 2026-05-15 by tools/grow_map.py.

Technical angle: Each artifact's `spatial_needs` (footprint_cells, clearance, isolation, wall_backing, preferred_zone, cluster_with) drives the floor-laying decision. Tables are emitted for small displays (footprint ≤ 2 cells, not wall-backed). The bounding box is then cropped to the laid cells + 1-cell margin.

Critical angle: This strategy produces the minimum walkable surface that satisfies the artifact set's constraints — no wasted floor, no empty back-fill. The shape of the map is an honest signature of which artifacts were given and what they needed from each other.

Key artifacts:
- station_wall
- panel_bridge_loom
- soft_stage_dashboard
- pattern_maker_station
- balance_puzzle
- visual_color_mixing
- chair_assembly_puzzle
- shelf_assembly_puzzle
- stool_assembly_puzzle
- table_assembly_puzzle
- grabcolorcollection
- math_objects_gallery
- fractal_arch_bench
- julia_bench
- sierpinski_bench
- station_floorline
- configurable_portal
- path_cube
- path_wedge
- grid_3d_capture
- mandelbrot_bench
- station_micropod
- station_plinth
- life_zoo_bench
- pattern_loom
- pattern_machine_c
- pattern_mill
- facade_builder
- vr_tile_editor
- vr_tile_editor_mirror
- mirrored_cellular_automata
- tech_crate
- scissor_stalker
- catalyst_pickup
- superposition_display

Gap: Tables don't (yet) emit a proper visible table prop — they're encoded as height-2 floor cells in the structure layer. Visible table primitives could be added by routing the table cells through a placement_rules action.