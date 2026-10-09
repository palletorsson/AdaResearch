# WaveFunctions_AirMusic

**Active hall 5 in wavefunctions. Batch: W3 review. Claude staging retained; sampled scope added and 67 independent desktop checks passed; headset/listening pending.**

[Current review, images and listening](/research/possible-bodies/air-music.html)

[Read the shared handoff](../HANDOFF.md) · [All maps](../all-maps.md)

## What continues after your hand has left?

Body/layer: A struck instrument, overlapping decays and a chosen tuning.

Proposed primary encounter: `resonating_metallophone`.

## Starting evidence

The existing striker, eight bars, table, cradle and return remain. The table scope now reads 512 samples over 12 ms near each bar's own playback position, including player gain and the final PCM fade, before spatial/bus/device processing. Independent decoding and ribbon geometry checks pass alongside the retained collision, overlap, return and route checks. Book hero and primary now both name the metallophone. The audio generator is unchanged.

Current map dimensions: {'width': 13, 'depth': 12, 'max_height': 3}. Current final: 765 words.

Current primaries: resonating_metallophone. Book anchors: resonating_metallophone.

Source agreement is not proof of runtime reachability or lesson quality.

## Build the encounter

1. Keep the tested table, left-end striker rest, protected operating strip and independent bar voices.
2. On the later headset visit, test actual held-stick reach, safe return and readout legibility with more voices.
3. Assess the secondary captions and ambient layers by standing and listening in the room before changing them.

## Revise final.md

1. Completed: connect Effect Sound to contact ending before its response.
2. Completed: distinguish same-bar restart from two simultaneous voices, with separate ages.
3. Completed: explain generated PCM, the three-second decay constant, finite ending and 12 ms source window.
4. Next: carry separate terms and timing into the existing Synthesis Lab; use listener observations to refine the prose.

**Code to trace and quote after implementation:** ResonatingMetallophone.gd: _create_single_bar, _create_stick, _tuned_scale; follow resonating_bar.tscn to the actual synthesis/strike code.

## Evidence to return

- 67 checks, zero failures, engine exit 0. Original saved hand and Claude's dated reports preserved.
- New scope samples independently compared with PCM, player gains and the actual ribbon vertices; two differing playback ages recorded.
- Two unchanged bar buffers exported; the review page compares them sequentially and overlapping. Listening and tracked-hand evidence remain pending.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

## Room for a better solution

Fable can dress the instrument lavishly or make it very spare. Keep the contact and continuing response easy to distinguish.

**Reusable method:** R1 controlled comparison; R2 housed readout; R8 bounded simulation.

## Open and inspect

- Map: `commons/maps/WaveFunctions_AirMusic/map_data.json`
- Book and supporting texts: `commons/maps/WaveFunctions_AirMusic/`
- [Primary view](http://localhost:3003/necklace/thread?map=WaveFunctions_AirMusic&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=wavefunctions&room=WaveFunctions_AirMusic)
- `res://algorithms/wavefunctions/resonance/resonating_metallophone.tscn`
- `algorithms/wavefunctions/resonance/ResonatingMetallophone.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.
