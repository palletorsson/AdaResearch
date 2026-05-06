# The Atlas of Structures

Thirteen instruments. Each is a meta-structure — **graph**, **field**, **process**, **grammar**, **symmetry**, **fold-ladder**, **gradient**, **feedback ring**, **flow basin**, **probability well**, **phase door**, **emergence pool**, **membrane gate** — rendered as an interactable pedestal. You walk between them. Five transition zones (declared with `@hold` regions) mark where one structure can be translated into another: a field sampled into a graph, a grammar unrolled into emergence, a process closed into a feedback loop.

## Layout

Four rows, south → north:

| Row | Cells | Instruments |
|---|---|---|
| **Structures** | z = 3 | graph_lattice, field_plinth, process_wheel, grammar_desk |
| **Shapes** | z = 7 | symmetry_mirror, fold_ladder, gradient_slope |
| **Flows** | z = 11 | feedback_ring, flow_basin, probability_well |
| **Limits** | z = 15 | phase_door, emergence_pool, membrane_gate |

Spawn at (1, 1) south. Teleporter at (18, 17) north. Transition zones at z = 5, 9, 13 — each a one-cell-deep band across the whole room, declared as `@hold:11:1` or `@hold:13:1` so auto-structure leaves them alone.

## Status

**Stub.** The thirteen `@signature:<token>` annotations name the instruments but the artifact scripts do not exist yet. Auto-structure + the annotation pipeline respect the layout; walking the map right now you see pedestals in the right places with nothing on them. Authoring the thirteen instruments is the next pass.

## Why this map

Ada Research has been building pieces of these structures all along — `GraphSpace` is a graph lattice, the SDF bus is a field-plinth, `grammar_operations.json` is a grammar desk, `FoldChain` is a fold-ladder. This map gathers them into a single walkable gallery so a player (or author) can see the full vocabulary at once and learn the **transitions** that bridge one into another. A field becomes a graph once you sample it. A process becomes feedback once you close the loop. The transitions are the pedagogy.

## Intent ratio

When annotations were added, `python tools/map_to_spec.py Atlas_ReadingRoom --check` reports the map as strongly authored — every pedestal carries a `@signature`, every transition zone carries a `@hold`. The map's purpose is declared in utilities; auto-structure cannot overwrite it.
