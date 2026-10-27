# machinelearning_03 — placed for curation

Original scenes, token config, scale and height preserved. Standard floors; each occurrence independently editable. Desktop and VR share rooms.json. Artifact buttons and gameplay intentionally untested.

- All six source occurrences from Sequence Memory, Generative and Synthesis are placed on three standard floors with their original scenes/config/scales/heights. Recurrent LSTM mode is retained, not replaced with a hand-authored outcome. Source chapters/maps remain unchanged.
- Basic desktop and synthetic XR loads pass 37 checks with no engine errors. No LSTM gates, token grabs, training, network decisions, or RL actions were tested. No new source adapter was required.
- Native Sequence Memory screenshot and broad bounds inspected. Actual exported GLBs are nonempty and independently parsed. Per-occurrence editor copy/move/rotate validation and save/reload to native rooms/Desktop mirror with stale-save rejection pass.
- The original joint-learn-walk scene carries a 50-metre standalone floor plus a larger grid. At original scale 0.6 its measured aggregate footprint reaches x -24..24 and z -16..32, beyond the standard slab and over its shafts. This extra source floor is retained for the as-is transfer; removing it or seating the creature is deferred to integration. Its live body/reset coordinates are not placement-certified.
- The source Transformers extends roughly 3.9 metres below the floor; XAI extends about 2.8 metres below and 6.8 metres above. Original centred meshes/platforms remain where authored, without shrinking. These snapshot loads do not establish complete clearance, walkability or moved/rotated simulation/input behavior.
- Editor models are static source-state snapshots. Learning/convergence, physical headset operation, performance, hand interactions and curricular effectiveness remain untested. Separate batch30 live soft-body placement remains open.

Evidence: {"source_checks": 62, "native_load_checks": 37, "editor_checks": 9, "valid_nonempty_glbs": 42, "mesh_count": 1981}
