# Slow Circuits

Playable generative ambient console for `WaveFunctions_Synthesis_Lab`, authored cell (4,6), facing +Z. The artifact is supporting material for the existing visual harmonic bench; it has its own audio state. No existing exhibits were removed.

- PLAY / STOP: lazily prepare the samples, start the score, or fade out.
- NEW SEED: change future chance and pitch choices.
- LFO ROUTE: send the 29-second modulation to filter or stereo pan.
- ENTER ROOM: open Room Memory, the recursive voice experiment after Alvin Lucier, through normal staging.
- DENSITY, RATE, WARMTH, SPACE, DRIFT, LEVEL: physical continuous sliders, with flat text and mounting plates.

The connections are a fixed patch. Only the modulation destination is switchable. The scope reads `AudioEffectCapture` after the effects; it is not an illustrative sine animation.

## Audio and cost

`ambient_patch_audio.gd` can be reused without the console. It schedules three independent clocks, seeded chance and pentatonic pitches, and exposes `start`, `stop`, `set_parameter` and `set_route`.

The existing `AsyncAudioGenerator` worker bakes one Discreet pad and one FM-piano note. Static shared PCM cache contains two resources (roughly 1.1 MB). A short endpoint taper prevents the finite FM sample from cutting off at a nonzero value. Transposing the sample changes pitch and duration together. This version does not synthesize a fresh note per trigger.

Eight finite `AudioStreamPlayer3D` voices use one isolated native-effects bus: low-pass, delay, reverb, panner, hard limiter, output capture. Main-thread work is event-rate scheduling and bounded UI updates, not sample DSP. Saturation skips requests; it does not allocate more players or abruptly steal a voice. Cold arrival creates no effects bus and no sound. Museum process disabling stops playback. Teardown removes only the instrument's own bus. Parameters are clamped to 0–1, feedback remains below unity, and the limiter ceiling is −6 dB before the final bus gain.

## Validation

From the repository root:

```powershell
python doc/reports/ambient-patch-2026-09-22/run_tests.py
python doc/reports/ambient-patch-2026-09-22/run_hall.py ambient after
python doc/reports/ambient-patch-2026-09-22/publish.py
```

The first script captures actual audio and close views. The second uses a private copy of the museum plan and runtime files, checks approach, collision, reach, and real XR Tools grab handling. It does not alter live museum navigation. Quest comfort, sound and frame budget need a headset pass.

## Walk-in room

`res://commons/scenes/ambient_listening_room.tscn` inherits the existing XR Tools rig and contains a 6.4 m round room. The centre remains open. RHYTHM (left) has density/rate and play/seed; TONE (ahead) has warmth/level; SPACE (right) has echo space/drift and the LFO destination button. The actual output waveform is on the front wall.

The shared engine exposes three source positions. The room sets them on opposite sides and behind the listener. In orbit mode the emitters move; their light markers read the same positions. The compact instrument retains its original single location and bus pan mode.

The console now enters Room Memory first. Its AMBIENT ROOM button opens this earlier generative room. The staging loader fades and replaces the current scene. BACK TO HALL or the doorway selects WaveFunctions_Synthesis_Lab through the museum's existing open_at contract. Pending museum edits are flushed before leaving. A direct editor boot uses SceneTree instead.

The headset's tracked height and offset remain authoritative. The room spawns at the entrance and does not impose a seated camera or lock movement. Its desktop fallback uses the existing player and pointer at standing eye height.

Room checks and screenshots: `python doc/reports/ambient-room-2026-09-22/run.py`. Publish after the original audio and hall regression scripts pass: `python doc/reports/ambient-room-2026-09-22/publish.py`. Physical headset validation remains pending.


## Room Memory - clarification of the reference

The user meant Alvin Lucier's *I Am Sitting in a Room* (1969), rather than a literal seating arrangement. `res://commons/scenes/room_memory.tscn` is now the ENTER ROOM destination. The earlier ambient instrument remains accessible through AMBIENT ROOM by the exit.

Walk between VOICE, RETURN and SURFACE stations. RECORD / END captures up to eight seconds from the microphone, only when pressed. DEMO VOICE uses an original, offline synthetic phrase; it is not Lucier's text or recording. The first voice stays in memory for HEAR ORIGINAL. NEXT PASS processes the previous buffer and plays the result. AUTO waits for each playback to end before producing the next, up to 24 passes. RESET returns to pass zero. ABSORB changes damping and reflection strength and resets the experiment, so comparisons begin with the same voice. LEVEL changes monitoring only.

`room_memory_dsp.gd` runs on one background thread with one bounded job at a time. Three damped comb paths use round-trip delays `2 * length / 343`, with the room's 6, 3, 5 metre dimensions. Each returned buffer is peak-normalized to 0.55 and becomes the next input. This is a deliberately simplified resonance model: no ray tracing, source-receiver mode coupling, scattering, doorway leakage, full wave solver or measured impulse response. Moving the listener changes the loudspeaker's 3D playback location relative to the ears, not the filter response. A three-second tail and a fixed window constrain memory and change the result. The on-wall spectrum reads native output analysis.

The microphone bus is muted after capture; it cannot make a live speaker-feedback loop. Recording is session-local, never uploaded or written to disk by the artifact. Android permission is requested only when RECORD is pressed and, after allowing it, the user presses RECORD again. Existing project input and Android manifest settings already enable microphone use. A native `.res` voice asset supports packaged builds; the `.wav` is its authoring source. Voice synthesis used Windows System.Speech with the original phrase: “Listen to this voice. Each return passes through the same room. Which sounds remain?”

Validation: `python doc/reports/room-memory-2026-09-22/run.py`, then `python doc/reports/room-memory-2026-09-22/publish.py`. The microphone bus is tested with known PCM, never by opening the developer's microphone. On-device permission, headset sound, comfort, and frame budget remain pending.

Sources: [Lucier work overview](https://en.wikipedia.org/wiki/I_Am_Sitting_in_a_Room), [Nicolas Collins's album notes](https://www.nicolascollins.com/texts/SittingInARoom.pdf), [Godot microphone recording](https://docs.godotengine.org/en/stable/tutorials/audio/recording_with_microphone.html).
