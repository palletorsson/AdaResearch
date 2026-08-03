Concept: A grown map. The walker entered an empty bounding box, laid 150 floor cells as it walked, placed 36 artifacts with clearance (and 0 of them on tables for eye-level reading), and ended at the teleporter. The map is the record of the walk.

Actualizes: The inverse-placement principle — instead of placing artifacts INTO a pre-defined room, the room is what the placement leaves behind. The map's shape is the artifact set's necessary geometry, nothing more.

Sequence role: Demonstration map for the grow_walker strategy from placement_research. Generated 2026-05-15 by tools/grow_map.py.

Technical angle: Each artifact's `spatial_needs` (footprint_cells, clearance, isolation, wall_backing, preferred_zone, cluster_with) drives the floor-laying decision. Tables are emitted for small displays (footprint ≤ 2 cells, not wall-backed). The bounding box is then cropped to the laid cells + 1-cell margin.

Critical angle: This strategy produces the minimum walkable surface that satisfies the artifact set's constraints — no wasted floor, no empty back-fill. The shape of the map is an honest signature of which artifacts were given and what they needed from each other.

Key artifacts:
- RackSineBasic
- WavePaintings
- holographicdisplay
- double_helix_scene
- dual_display_test
- RackMario
- modulor_man_demo
- bernini_columns
- coupled_oscillator_lattice
- kusama_sine
- math_objects
- sine_wall_corridor
- line_builder_3d
- colonization_bench
- wfc_room_bench
- wfc_tile_bench
- seismograph
- RackMoogBass
- biomagneticresonator
- mc_field_bench
- sdf_sculpt_bench
- slime_bench
- voronoi_bench
- foucault_pendulum
- hallway_scene
- sine_cylinder_staircase
- cable_builder
- armadillo_eggling
- chord_tension_spring
- atmosphericmonitoring
- chemicalapparatus
- chladni_plate
- multimeter
- samplevialrack
- kaleidocycle_enemy
- miura_crawler

Gap: Tables don't (yet) emit a proper visible table prop — they're encoded as height-2 floor cells in the structure layer. Visible table primitives could be added by routing the table cells through a placement_rules action.