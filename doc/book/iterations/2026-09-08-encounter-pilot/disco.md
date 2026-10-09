# Tutorial_Disco encounter pilot

The room now lets a visitor change one stored cell, predict its next reading, and compare the note with the highlighted address. The sequencer previously sounded column `k` while highlighting `k + 1`. A floor in a later museum hall could also bind to an earlier hall's sequencer. Both faults were reproduced with the actual packed scenes and repaired.

The first experiment begins with the empty pattern and one active cell. Its immediate audition is distinguished from playback. The visitor predicts the returning note, turns the value off while its address remains, then turns it on again. This gives an observable negative case: revisiting an inactive cell adds no event.

## What changed

- `commons/audio/sequencer/step_sequencer.gd`: `_advance_playhead()` updates the visible column before sounding/emitting that column, then advances the internal next-step index. Silent columns receive the same visible reading.
- `commons/audio/sequencer/sequencer_ui.gd`: a silent preset setter keeps the dropdown aligned with the actual sound preset at startup and after configuration changes. The museum render exposed a stale `808_kit` label over a configured `90s_house` model. Synchronisation emits no feedback event and auditions no sound.
- `commons/context/discofloor/DiscoSequencerBridge.gd`: reference discovery stays inside the nearest `em_map` ancestor. A hall lacking a sequencer leaves its bridge unconnected rather than borrowing another hall's clock. Standalone scenes retain scene-wide discovery.
- `commons/maps/Tutorial_Disco/map_data.json`: the sequencer placement keeps its rotation, height and scale, replacing bare `#house` with explicit `#sound_preset:90s_house`. The real configuration method accepts this key; the explicit form also survives map-to-plan derivation.
- `commons/maps/Tutorial_Disco/final.md`: adds the inactive-cell comparison, distinguishes audition from playback, corrects attribution of the floor's independent animation, and makes the sixteen-step/twelve-column fold available to investigate.

No floor dimensions or step counts were changed. The first and thirteenth sequencer steps still brighten the same floor column. The chapter uses the second track for that comparison so the first-track/step-zero pattern-change behaviour does not add a second cause.

## Evidence and limits

Run `python tools/run_disco_encounter_probe.py --label final` from the repository root. The runner launches Godot headlessly with a hidden Windows process and writes dedicated logs and source hashes under `ada_run/encounter_pilot/Tutorial_Disco_behavior/`.

`before.json` records the reproduced defects. `after.json` records the initial passing fix; `configured_after.json` adds verification of the explicit map sound preset. The latest `final.json` passes 17 checks, including the sixteen-step boundary and preset UI synchronisation. Each run has its own `_sources.json` manifest. The durable copies here are `disco-runtime.json` and `disco-runtime-sources.json`; the separate museum render shows `90s_house` on the installed panel.

The probe instantiates the actual sequencer and floor scenes in two separate museum-labelled hall containers, plus a hall without a sequencer. It uses their real UI, data, audio and bridge methods with deterministic advancement. It does not instantiate the whole museum or simulate a controller pointing at the panel.

| Observation | Verified result |
| --- | --- |
| One active cell at track 1, step 5 | One event at that address; visible address is 5 during and after the event |
| Following inactive column | No added event; visible address advances to 6 |
| Turn that value off | Same button/address remains in the 4-by-16 grid; revisiting adds no event |
| Last step and wrap | Step 15 remains displayed when sounded; the following empty step 0 adds no event |
| Tempo 120 to 240 BPM | Step interval halves from 0.125 to 0.0625 seconds; grid bounds remain unchanged |
| Steps 0 and 12, non-kick track | Both brighten floor column 0 |
| Event in second hall | Only that hall's floor changes |
| Hall without a sequencer | No cross-hall binding |
| Sequencer stopped | Floor's own animation can still advance |
| Preset at startup and after configuration | Model and dropdown agree for default `808_kit`, configured `90s_house` and a later change, with no feedback signals or preview audio |

Audio verification means a generated stream reaches the actual audio player. Nobody has yet confirmed headset sound or understood the lesson through this probe. Headless logs contain viewport-texture errors and unrelated project autoload/audio-bus/debug-log messages, so passing behaviour checks are not a clean-render claim. Root's separate museum geometry/render probes cover placement and approach; controller reach, readable panel size and learner acceptance remain open.

The bridge still discovers references once after startup. This pilot checks correctly ordered hall construction and absence of a local peer; it does not establish automatic recovery when a sequencer is inserted later.

## Reuse demonstrated

Array and Disco both distinguish a persistent address from a changing value. The useful method is to preserve a visible reference, change exactly one value, predict the corresponding output, and inspect a negative case. In Array the occupant is collected and a table entry becomes zero. Here the cell stays visible when switched off, and the next reading adds no event. The probe checks that the same button instance and grid dimensions remain.

The representations have different limits. The sequencer revisits addresses in time; tempo changes their interval without changing their count. The floor compresses sixteen temporal addresses into twelve spatial columns and overlays events on its own animation. Reuse therefore carries the experimental method across rooms, while each room must expose the information its own representation preserves or loses.

The next learner check is small: without supplying the answer, ask a visitor to predict one note, silence that address, then explain why the empty slot still exists and why the floor alone cannot identify every step. Record their action and explanation separately from whether the controls technically worked.
