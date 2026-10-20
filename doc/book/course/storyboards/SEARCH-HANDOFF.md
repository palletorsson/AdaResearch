# Search progression — 10 October 2026

User: put Graph Theory before Machine Learning; add BFS → Dijkstra → A*; keep the point and river. Completed as one expanded GT_Pathfinding tutorial and permanent Impatient River update. No new halls. Canonical order: Swarm → GT (21) → ML (22) → Foundations. Matching now hands over to ML; Swarm reflection hands over to GT. ML retains its existing draft status.

Carry PointBody, traversal.gd and BFS route.gd unchanged. New weighted_route.gd extends route.gd; same predecessor, adjacency and point. Dijkstra minimises sum of Euclidean edge lengths. A* adds Euclidean remaining distance (consistent lower bound). Seven-vertex study raises vertex0 y2.3→2.7 explicitly: BFS4edges/3.330m vs weighted5edges/2.932m. Tests caught the original incorrect comparison before this coordinate change. Do not remove this explanation. Controls: hold pauses; trigger/1 blocks0, blocks0+4, restores; 2/nearby button cycles search; R replays. Permanent river runs the same learner search class on its unchanged seeded stones. SINK STONE and SEARCH RULE share a nearby pedestal.

48 exact printed-code Godot4.6 checks pass, 12,544 weighted cases vs exhaustive oracle, independent coordinate edit, synthetic XRTools, five rejected faults. 45 native checks pass, including actual live museum pool and portal destination resolution, 60 weighted cases vs GodotAStar3D, same stone/spark identity, actual controls and 69 clearance samples. No physical headset, independent reader, Quest performance or full portal-walk claim.

Code: python tools/test_graph_pathfinding.py

Museum: python tools/run_encounter_probe.py GT_Pathfinding --sequence graphtheory --render --no-bridges --output-tag search-progression --probe tools/probes/graph_search_room.gd

Author tutorial: tools/write_graph_pathfinding.py (five printed source files; no longer overwrites reflection). Publish: python tools/publish_graph_search.py. The old publish_graph_pathfinding.py is for the historical BFS-only review and must not publish this revision. Updated write_graph_matching.py preserves the new prose handover; no Matching code change.

Review: doc/book/iterations/2026-10-10-search-the-same-river/index.html; parallel.html tutorial-left/reflection-right; separate full texts, before/after, checks, native images, search-review.zip. Museum receipts: ada_run/encounter_pilot/GT_Pathfinding/search-progression. Tutorial receipt hashes normalise line endings; canonical manifest hashes use raw bytes.

Spine reorder also applied to the actual museum artifact-order manifest (stable per-chapter, all objects retained) and long_museum strip (same geometry, recomputed offsets, not recaptured). No hand-order override exists. Historical Lab layouts are not regenerated; do not present them as the new route. Fresh museum sessions use the new order; existing saved stream cursors/exports have not been migrated. tools/align_graph_search_order.py is the narrow migration.

Atlas: regenerate native with tools/build_ada_relations.py, browser with tools/publish_ada_atlas.py; tools/check_ada_atlas.py passes for206halls/205photos/278files. New native river capture overrides the old image. Plan paragraphs/carry and sequence order are current. Existing art references and their evidence preserved.
