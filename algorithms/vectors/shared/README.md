# Vectors — Shared

Base classes and utility components shared across all vector algorithm scenes. This is a support folder, not a standalone algorithm.

## Base Classes

### VectorSceneBase

`vector_scene_base.gd` — Base class for all vector visualization scenes. Provides:
- Shared mesh resources (cylinder, cone, sphere, floor) via static lazy initialization to avoid duplication.
- Material cache keyed by color string.
- Environment and info root nodes.
- Origin marker creation.
- Scene scale constant (0.33) for consistent sizing.

### ForceContainmentBase

`force_containment_base.gd` — Base class for force-based vector scenes that need spatial containment boundaries.

### VectorInfoFrame

`vector_info_frame.gd` — Info display component for showing vector labels, values, and explanatory text alongside visualizations.

## Gadgets

The `gadgets/` subfolder contains physical props that respond to vector values in real time:

| Gadget | Description |
|--------|-------------|
| `gadget_base.gd` | Abstract base — `update_from_vectors(a, b)` interface, body/joint helpers, shared color palette |
| `balance_beam_gadget.gd` | Beam that tilts based on force magnitudes |
| `catapult_gadget.gd` | Catapult arm driven by vector magnitude |
| `gyroscope_gadget.gd` | Spinning gyroscope showing angular momentum |
| `hinge_panel_gadget.gd` | Panel on a hinge joint reacting to forces |
| `paddle_wheel_gadget.gd` | Water wheel driven by flow vectors |
| `piston_gadget.gd` | Linear piston showing projection/component |
| `spring_scale_gadget.gd` | Spring scale measuring vector magnitude |

All gadgets extend `GadgetBase` and override `update_from_vectors()` to translate abstract vector math into tangible physical motion.
