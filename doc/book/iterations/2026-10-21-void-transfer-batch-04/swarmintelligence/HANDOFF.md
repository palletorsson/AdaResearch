# Swarm Intelligence â€” transfer handoff

Codex, 21 October 2026. Batch 04. Transfer first; curation and chapter changes wait.

Eight original placements from `SwarmIntelligence_PhysarumColony` and
`SwarmIntelligence_FlowFields` are individually editable on trial floors 1 and 2.
The original maps, texts and algorithms are unchanged. Source tokens, cells and
configurations are recorded in `source-inventory.json`.

## What is here

Floor 1: the original science screen in scatter mode, standalone ant agent,
legacy particle swarm, and Physarum trace gallery. The gallery runs the original
300-agent colony in its private 50 m simulation world. Wall, table and drawing
pad share one live image. The handheld point writes directly into that colony's
field, including while its simulation is paused. Both original buttons remain.

Floor 2: direction-painting table, Ant Colony V2 table, ecosystem stand and
24-body crowd. The flow table keeps its original 200 agents and 40 Ã— 40 field,
pause/reset and scenario tour. Moving the crowd's point toward A or B chooses a
route; dropping it sends the same bodies home. Trigger toggles field arrows.

## Integration changes

- Trial storeys are 8 m to fit the trace gallery's 7.1 m title and six-metre image.
  The main tower is untouched. Both shafts remain open with corner landing pads.
- The legacy particle swarm retains its 50 particles, 20 m search volume and
  original solver, displayed west of the slab. Its landscape is at local y -10,
  measured at world x -43..-23, y -18, z -10..10 on floor 1. This is an oversize
  specimen to curate later, not a traversable floor installation.
- `legacy_pso.tscn` inherits that original scene. Its local script changes only
  presentation: the original screen-overlay readings are copied to a Label3D
  beside the slab for desktop/VR parity. The original solver is called unchanged.
  The catalog alias is `void_swarm_legacy_pso`.

## Controls and verification

Desktop: right click to carry/drop the black points, left click/hold for their
action, mouse wheel for carry distance. VR: grip and trigger. The existing
buttons use the normal pointer on either rig.

`python tools/test_transfer_native.py swarmintelligence` passed 79 checks on the
native Mobile renderer: actual desktop pickup/actions and synthetic tracked XR,
trace drawing while paused, release/return/reset, direction painting and its
persistence, tour, relocated/turned control mapping, ant pause/resume, crowd A/B
routes and obstacle clearance, shaft descent, simulation sleep and checkpoint
retry. All eight originals instantiate. No physical headset playtest was done.

`python tools/audit_void_transfer.py swarmintelligence` passed all 58 checks.
Web geometry and save acceptance is recorded separately in `evidence/editor-checks.json`
when export is complete. The web model is an arrangement snapshot; Godot runs the
original simulations.

## Open for curation

- The oversize particle swarm needs a final architectural decision; no shrinking
  or invented walkable deck has been applied.
- The standalone ant remains the original autonomous wanderer, without a bound
  colony, pheromone terrain or a containment rule. It is not a substitute for the
  separate Ant Colony V2 instrument.
- The science screen retains its scatter configuration and its original automatic
  dependency search. Its original scatter code expects a
  `boid_count` source, absent in this original map, and falls back to its built-in
  demonstration swarm. It is not telemetry from Physarum or PSO.
- Native tests are functional acceptance, not headset comfort or performance certification.
- No encounter ordering, new hazards, chapter prose or main-tower integration.

Editor acceptance completed: all eight original placements exported as real GLB geometry; all 11 editor checks passed, including every object copied/moved/turned, save/reload, Desktop mirror and stale-save rejection.
