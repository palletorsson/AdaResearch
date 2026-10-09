# Evolution belongs to the journey

19 September 2026. User correction: the doors becoming banners is part of the
biome's evolution **between maps**, from abstract to alive. The twenty-second
loop was a movement study, not the desired progression model.

The governing distinction:

- **Evolution:** a hall grants a new capability; its result is retained in later
  halls through the cumulative vocabulary.
- **Behaviour:** once available, a capability may produce motion or interaction
  within a hall. Wind moving a future membrane would be behaviour. Becoming a
  membrane is a change in what the specimen can be.

The same form must carry its history. A later organism need not erase its earlier
sculptural or architectural identity. These are revisable possibilities, not a
claim that geometry naturally evolves into life or that biological life is a
mandatory endpoint for every object.

## Implemented correction

`biome_inheritance.tscn` now defaults to `evolution_stage = Pattern_Foundry`.
The stage comes from `apply_grid_config({stage: map_name})` before instancing or
`set_hall(map_name)` on the live prototype. `BiomeGrammar.closure` reads the
existing spine and hall ordering. Unknown stages are rejected. The habitat and
panels receive the same stage. No elapsed-time loop advances a map-driven state.

The existing five panel bodies, names and early walking archive survive live hall
changes. The habitat rebuilds with the same seed and DNA, using its established
layer gates. This is render reconstruction, not a biological growth process or
a cross-session save system. Stage history is included in the inspection record.

| Capability | Inherited face |
|---|---|
| Before face | Hidden, collision disabled |
| Face | Grey unpatterned panel at ground level |
| Translate | Raised 2.35 m; remains raised |
| Rotate | Yaw 45 degrees |
| Scale | Width changes from 1.1 to 0.66 m |
| Colour | Five plain palettes |
| Tile | Five geometric patterns |
| Later habitat layers | Fungi, creatures and trees arrive around the retained panels |

Colour and pattern are independently gated. A tall patterned banner no longer
appears fully formed during translation. Reviewing an earlier hall explicitly
restores its earlier capabilities; simply waiting never lowers a later banner.

The earlier periodic movement and width studies remain reproducible with an
empty `evolution_stage`. Their existing films are now secondary, labelled as
earlier tests on the review page.

## Review and evidence

<http://127.0.0.1:3003/biome-primitives/inheritance.html>

Nine native Godot views use a fixed camera and one live encounter, from Point_One
through LSystems_Growth. They show selected checkpoints, not every hall of the
spine. The review manifest is `commons/artifacts/biome_inheritance/evolution-review.json`.

167 checks pass, including preserved body identities and archive, correct feature
arrival, no evolution after waiting beyond the former cycle duration, unknown
stage rejection, direct map configuration, earlier-stage review and no support
node accumulation. Native records match the headless probe for all nine stages.

Evidence: `ada_run/biome_inheritance/evolution/`. Reproduce with
`commons/testing/probe_biome_map_evolution.gd`,
`commons/testing/capture_biome_map_evolution.gd` and
`tools/verify_biome_map_evolution.py`.

## What remains

This is the prototype contract, ready for hall configuration. It has not been
distributed through all museum maps or given a cross-session save path. The
original primitive encounter still owns its visitor-driven trace; the composed
prototype preserves an imported archive but does not yet join the museum's
continuous walking recorder. Depth, softness, forces, growth feedback and QFEP
rule revision need their own observable consequences on the inherited specimen.

The host vocabulary's existing arrivals—including flowers with colour—remain
design choices to review, not evidence that plants have been simulated from first
principles. Keep the lineage clear while we develop the later operations.
