# Release Gates Report

- Measured: 2026-09-03T09:19:33+02:00 by tools/run_release_gates.py at f18306832 (393 dirty / 488 untracked)
- Overall: FAIL
- Enabled gates: 9/11 passing

| Gate | Status | Key Metrics |
|---|---|---|
| A: Sequence Contract | PASS | missing_declared_maps=0, duplicate_entries_within_sequence=0, undeclared_map_folders=1850 |
| B: Artifact Registry Integrity | PASS | unresolved_scene_files=0, missing_scene_path=0, invalid_biome_token=0, unsupported_scene_path=0, missing_map_ready=130, missing_include_in_map_data=130 |
| C: Map Validation | PASS | grade_A=2274, grade_B=368, grade_C=152, grade_F=0, max_grade_c=None, grade_c_blocking=False, max_grade_f=0 |
| D: Lab Progression Continuity | PASS | lost_count=0, changed_count=12, total_issues=39, ok_superset_pairs=5 |
| E: Museum Template Integrity | PASS | failing_templates=0, chain_pairs_pass=900, chain_pairs_total=900 |
| F: Museum Walkthrough (autopilot) | FAIL | museums=-1, z_reached=-1.0, goal_z=-1.0, walked_s=-1.0, cells_unlearned=-1, stall_events=-1, frontier_z=-1, reason=contended_builder |
| G: Map Token Resolution | PASS | detector_selftest=PASS, maps_scanned=185, maps_named=185, maps_without_data=none, placements=1318, unresolved_placements=0, unresolved_tokens=, malformed_empty_cells=0 |
| H: Gate Chain Integrity | PASS | tools_referenced=51, absent_on_disk=none, present_but_untracked=none, unreachable_from_a_clone=0 |
| I: Edge Anchors | PASS | detector_selftest=PASS, edges=255, held=251, near=4, lost=0, ungrounded=0, lost_rooms=none |
| J: Artifact Citations | PASS | citations=219, held=212, near=4, lost=0, elsewhere=3, no_such_work=0 |
| K: Wants Closed Honestly | FAIL | detector_selftest=PASS, token_lines=833, closed_dishonestly=4, ghost=0, echo=4, no_registry=0, broken_body=0, hero_ghost=0, open_not_counted=empty 104 · stub 32 · elsewhere 35 · no_body 30 · no_subject 50 |

