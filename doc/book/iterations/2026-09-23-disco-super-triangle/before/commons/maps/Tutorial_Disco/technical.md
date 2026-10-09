# Tutorial Disco — a fixed grid with changing values

The preceding floor and wall halls repeat an image in space. Tutorial_Disco keeps the receiving tiles fixed and changes what they display over time. The later colour sequence gives surface values another set of possibilities; the coloured disco returns in tiling.

## Current floor and controls

The map configures standalone_disco as a 12 by 12 floor with 0.8 metre tile spacing and a single walkable collision box. StandaloneDiscoFloor.gd renders 144 flat boxes through a MultiMesh. The separate disco_controls artifact finds that floor within the hall, disables its autonomous pattern cycle, and supplies four monochrome rules: CHECKER, ROWS, DIAGONALS and SNAKE. It paints per-instance colours without changing tile transforms.

The actual checker rule in disco_controls.gd is:

```gdscript
return (x+z+phase)%2
```

PLAY / HOLD stops or resumes this console's phase clock. ONE STEP advances the phase even while held. PATTERN changes the rule and returns its phase to zero. SPEED cycles 0.5, 1.0 and 0.25 seconds between visual updates. These controls do not change the sequencer's tempo.

## A score and a second clock

step_sequencer stores four tracks of sixteen on/off cells in its UI. A track supplies a sound; a step supplies a position in the repeating count. Activating a cell auditions the sound. Playback advances the displayed playhead and requests notes only for active cells, then advances the next-step index. The configured sound preset is 90s_house; displayed track names follow the resolved instruments.

The interval between sixteenth-note steps is 60 / bpm / 4 seconds. Tempo changes how quickly the score is read. The selected cells keep their addresses.

DiscoSequencerBridge connects the locally placed sequencer to this floor. Sounding steps brighten a column indexed by step % grid_width. Sixteen score steps therefore fold onto twelve columns; step indices 0 and 12 select column 0. The monochrome console expires these responses after 0.15 seconds even while its own pattern is held. Its next repaint may replace a flash sooner.

Walking does not write to the score. There are no per-tile foot-contact recorders in the current encounter. A recorded walk would need a separate input and timing representation.

## Sources and shared illustration

Production sources: commons/artifacts/regularity/disco_controls.gd, commons/context/discofloor/StandaloneDiscoFloor.gd, commons/context/discofloor/DiscoSequencerBridge.gd, commons/audio/sequencer/step_sequencer.gd and sequencer_ui.gd. Placement: map_data.json.

The 23 September book figure pairs native captures of CHECKER at phases 0 and 1 from the same selected camera, with the score stopped and the visual clock held. No tile transforms are changed for the figure. The review animation assembles twelve native held ROWS phases at an editorial interval; it is a state comparison, not a real-time audiovisual recording. Labels, layout and resizing are the only image composition.

Focused evidence and scope: doc/book/iterations/2026-09-23-disco-separate-clocks/. Earlier note/address, instrument-label and modulo checks remain in doc/book/iterations/2026-09-19-arrays-review/disco/. Supplied inputs and muted audio do not establish listening quality, headset comfort or learner understanding.

## Retained proposal: the walk becomes a score

The previous technical draft described a different, unimplemented encounter: contact-sensitive tiles recording a walk, then interpreting it as sound, light or neighbour propagation. That proposal remains intact in this iteration's before/commons/maps/Tutorial_Disco/technical.md. It could return after the current distinction between score, clock and body is established. It must not be described as the present floor's behaviour.
