# WaveFunctions_John_Cage

**Authored extension — outside the current museum route. Batch: W-EXT. Implementation pending.**

[Read the shared handoff](../HANDOFF.md) · [All maps](../all-maps.md)

## What has already been composed before chance begins?

Body/layer: A listening body inside a scheduled sound collection.

Proposed primary encounter: `john_cage_tech_noir`.

## Starting evidence

Outside the active route. The scene generates a finite vocabulary of sounds and schedules events. There are separate RNG paths for threaded generation and other operations; chance_seed does not by itself establish full audio replay. Names and visuals do not establish spatialised sound sources. Structure recovery on 10 September: interior 2 cells are one-metre platforms, perimeter 2 cells are explicit w walls, museum.wall_height is 3, and gate_depth_rows is 0. Preserve this contract; see recovery.html and the dated doc/space archive.

Current map dimensions: {'width': 13, 'depth': 14, 'max_height': 6}. Current final: 419 words.

Current primaries: john_cage_tech_noir. Book anchors: john_cage_tech_noir.

Source agreement is not proof of runtime reachability or lesson quality.

## Build the encounter

1. Provide a listening position, a small event ledger and an optional view of the available vocabulary. The first encounter should allow attention to settle before explanations accumulate.
2. If offering repeat, seed both generation and scheduling or record/replay the event schedule. A frozen visual ensemble must not be labelled repeated audio.
3. Inspect generation time, memory and thread teardown; avoid concurrent heavy sound generation from neighbouring halls. Add a reliable local stop/leave path while preserving the intended composition.

## Revise final.md

1. Begin with an event arriving against a continuing background; ask what could arrive next.
2. Listen again for a recurring vocabulary rather than demanding a melody.
3. Show the actual selection/scheduling fragment after that discovery.
4. Treat the Cage title as a reference, not a performance of a named score. Carry finite choice into Randomness or return to AirMusic in an extension path.

**Code to trace and quote after implementation:** john_cage_tech_noir.gd: _thread_generate_sounds, _process, play_random_effect, RNG setup and visual chance configuration. Audit the per-frame threshold draw.

## Evidence to return

- Capture a short timestamped event sequence and identify its eligible sound pool.
- If replay is implemented, compare two complete event logs, not only colours.
- Check leaving during generation and re-entering without leaked threads or audio.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

## Room for a better solution

Let silence, delay and spatial arrangement matter. No need to turn this into a quiz or make every sound visible.

**Reusable method:** R3 explicit time; R6 local state/seed; R8 bounded simulation.

## Open and inspect

- Map: `commons/maps/WaveFunctions_John_Cage/map_data.json`
- Book and supporting texts: `commons/maps/WaveFunctions_John_Cage/`
- [Primary view](http://localhost:3003/necklace/thread?map=WaveFunctions_John_Cage&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=wavefunctions&room=WaveFunctions_John_Cage)
- `res://algorithms/wavefunctions/technoirgameaudio/john_cage_tech_noir.tscn`
- `algorithms/wavefunctions/technoirgameaudio/john_cage_tech_noir.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.
