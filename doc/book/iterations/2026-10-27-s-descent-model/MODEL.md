# S descent / model first

A 1:10 cutaway study, saved in the independent `s_descent_model` Void trial. The main tower arrangement is not changed.

Canonical route: entry at +12 m, upper slide to +6 m, level semicircular turning landing, lower slide to 0 m, exit deck. Two six-metre storeys. The model has a 1.2 m drop on a standard 2.44 × 1.215 m timber board with temporary plinths.

The passage has 1.6 m clear width and 2.8 m vertical headroom. Both descending legs have smooth, level ends; they are steep slides, not accessible ramps. The landing centreline radius is 1.2 m. A pink centreline links entry, landing and exit. Three wire frames indicate the storeys. Translucent roofs and near walls reveal the interior; they retain collision in Godot.

## Reusable grammar

```json
{"t":"s_descent_model","with":{"model_scale":0.1,"cutaway_alpha":0.12,"yaw":18}}
```

The `sweep` primitive uses a solid polygonal profile and an explicit 3D path, with horizontal cross-section width and world-up height. Editable floor, wall and roof strips compose the hollow section. This is a swept hollow passage, not a runtime CSG subtraction of a massive outer building.

The 25 member insertion points survive export to the lab editor. Each slide floor, wall, roof, landing, mouth, trace, level guide and model stand can be moved, rotated, copied and saved through the existing member contract. Native geometry and Three.js use the same canonical recipe; only Godot owns collision.

## Next spatial decision

Review the model before installing a full-size descent. A full-size connection still needs openings through the chosen slabs, landing approach, safe arrival, intended slide behaviour, recovery/health rules and desktop/VR traversal. A 4 × 4 m shaft cannot contain this model's complete switchback footprint at the stated clear width without redesign. Do not silently shrink the player passage to fit it.
