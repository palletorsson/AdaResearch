# ABM: what the point carries

Permanent furniture around the existing, complete printed ABM study. The scene instantiates `lesson/study.tscn`, a byte-identical runtime copy of `doc/book/studies/swarm-through-the-hands/SwarmIntelligence_Agent_Based_Modeling_ABM/study.tscn` and its three scripts. Runtime copies stay under `commons` because exports exclude `doc`; `tools/publish_abm_state_table.py` asserts equality. Its `foragers.gd`, `point_body.gd` and `study.gd` remain the code shown in the hall's tutorial. This adapter adds collision-backed furniture, short hand instructions, a selected-point ring and Run-button feedback. It does not supply another simulation.

Enter Swarm Intelligence → Agent-Based Modelling. The table is on the right near the north entrance. Hold one of the six points to pause all six. Trigger selects it for the readout. Move it to FOOD, release it and press ONE TICK. A small green cube shows its carrying state; the same body now requests a return to HOME and leaves a shared trace. Moving it home and stepping delivers once and returns it to searching.

RUN / PAUSE advances the original fixed-step model. REPLACE AGENTS resets individual records while retaining the field, delivery count and clock. CLEAR ALL clears those histories. Both controls reuse the same six sphere instances. Held points block stepping and resets. Keyboard equivalents remain 1, 2, 3 and R.

The model is a sixteen-cell square plane. Food/home contact is a distance test at the start of a tick; agents can overlap and wrap at the edge. The food source is not depleted. The cargo cube is a state indicator. This is the lesson's explicit abstraction, not a rigid-body insect simulation. The original large colony, navigator and full-size listening court remain separate exhibits.

The tabletop is 2.7 m square; points sit at 1.02 m. Four buttons share a close rail at 0.85 m. Routes around the sides let visitors reach the points; the central hall route stays open. The original tabletop supplies its visual surface, so the adapter adds collision only at that surface.

Validation: `tools/test_swarm_abm.py` reconstructs the exact printed code and runs 42 assertions, including numerical predictions, an independent variation, three deliberate faults and supplied XRTools inputs. `tools/probes/abm_table_museum.gd` exercises the installed scene, routes and controls; `abm_table_portals.gd` checks ABM → ACO → ABM. These are automated author-operated checks, not physical-headset or Quest-performance validation.
