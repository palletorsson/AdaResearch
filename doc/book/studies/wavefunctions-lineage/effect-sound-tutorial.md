# Effect Sound — a phase you can hear

## Learning elements

- Phase modulation: one sine inside another.
- A hand position selecting one parameter.
- Retaining a reference for comparison.
- Supporting construction: a sampled note and its envelope.

At the two desks in the museum, press BASELINE and then HOLD. Keep the blue ball still. Lift the orange ball, let it settle, then press COMPARE. Listen through both notes. The instrument can change six values; begin with one: the depth of phase modulation.

Unit Circle gave an angle two coordinates. Propagation made one point respond to its neighbours. Here we prescribe a signal again. A second sine changes the first sine's phase. The result goes to the speaker instead of moving a body.

**Build:** use the carried point to change modulation depth and compare the result with a saved note. **Investigate:** explain why changing the frequency ratio has no effect at depth zero, then listen with modulation present. Keep the note length, envelopes and encoder fixed during this comparison.

## Carry the point; give it one job

Keep the same `point_body.gd` and `line_skin.gd`. The point is pickable again. Its height selects a phase depth from zero to four radians; its other two coordinates do nothing in this study. The line class draws a small view of the resulting signal.

In your museum working copy, attach `06_phase_note.gd` to an empty, unit-scale `Node3D` in the clear study bay beside the two-desk instrument. Place the root at hall-local `(7, 0, 10)` and turn it 180 degrees around Y to face the entrance. The hall's floor, light, player and XR pickup/trigger routing are supplied by Day Zero. This script creates its own point, display, audio player and sound data; it has no references to pre-existing meshes.

The complete three files are below. Only the first is new. Begin your close reading with `phase_depth()` and the first two lines of `sample_at()`: height selects an amount, and that amount changes phase. `make_note()` stores the resulting samples for playback. Its encoding is supplied support, explained after the experiment; you do not need to redesign it to make another sound. Put all three files together in one folder and keep the single `_ready()` shown.

{CODE}

## Read the operation

Start with `sample_at`. `t` is seconds since the note began. Multiplying frequency by `TAU` changes cycles per second into radians per second. The carrier is 440 Hz. With ratio two, the modulator is 880 Hz.

The modulator is added **inside** the carrier's sine. At depth zero that term vanishes. Increasing it advances and delays the carrier's phase. Adding two completed sine outputs would mix two voices instead: that is a different operation. The museum artifact retains the name FM; the expression we are reading directly modulates phase.

The envelopes give the note its beginning and ending, and let the modulation fade within it. Keep them unchanged so you can hear the effect of depth and ratio. The zero-depth reference still passes through the same envelope and output shaping.

## Make a comparison

Hold the point at one metre above the study root and press the trigger. A and B should match. Raise it to 1.3 metres: predict depth two before reading the label. Press again. A is the stored zero-depth note; B is rendered from the depth at that press. A quarter-second gap separates them. Moving during the pair changes the display and the next choice, but cannot rewrite either captured note. The `busy` condition lets this pair finish before accepting another trigger.

We use the point's **local** height, learned in Coordinates. Rotating or translating the study root therefore carries its reference frame with it. The audio player stays at the study, so moving the control does not also move the sound source.

The scope shows two carrier periods starting at the attack time—about 4.5 milliseconds at 440 Hz. Its 96 segments draw a selected window, not all 26,460 audio samples and not a microphone recording. Let the full note finish before deciding what the picture leaves out.

## Make another relation

Change only `ratio` from `2.0` to `1.5`. Predict the modulator frequency: 660 Hz while the carrier stays at 440. First compare at depth zero, where the ratio cannot affect the note. Then raise the point and compare again. Explain why one edit is silent at zero depth and becomes audible when the modulation contributes. Keep a setting because you want to return to it, even if you cannot name its timbre.

The existing two-ball instrument remains a larger encounter: its blue ball also changes carrier frequency, attack and decay; its orange ball also changes ratio and modulation decay. Its HOLD button can preserve any chosen setting. Our smaller study keeps these fixed so the phase operation can be reconstructed and tested.

## How the note is kept

The supporting code makes a finite recording of the signal you selected. `make_note` brings back Trace's list and loop, now as a packed byte array. It evaluates 26,460 samples for a 0.6-second note. The time step is `1 / 44100` seconds; it is unrelated to the display's frame rate. Each signed 16-bit sample occupies two bytes, so sample `i` starts at byte `i * 2`. `AudioStreamWAV` receives those bytes and their sample rate. Keep this encoder for the later sound lessons.

The two envelopes have different jobs. `exp(-t / 0.25)` makes the modulation fade. The carrier envelope rises over 0.01 seconds and decays with a 0.3-second time constant. After one time constant an exponential retains about 37 percent of its initial value. It has not reached zero. A final 0.02-second fade closes our finite note; the larger museum instrument has a different buffer-ending rule. Both use `tanh` to shape the output.

Bernini returns to spatial composition. We will use angle to place successive profiles through height, then keep that form while a separate clock rotates it. Retain the sound functions too: Cage will reuse them to make a score, and Air Music will give each struck voice its own beginning.

## Carried code

`point_body.gd` — unchanged point, including the XR pickable behaviour already used in Coordinates.

{POINT_CODE}

`line_skin.gd` — unchanged finite cylinder between two positions.

{LINE_CODE}

Implementation references: [Godot AudioStreamWAV](https://docs.godotengine.org/en/stable/classes/class_audiostreamwav.html) and [PackedByteArray](https://docs.godotengine.org/en/stable/classes/class_packedbytearray.html). The museum expression is in `algorithms/wavefunctions/mariocontrol/DualBallFMController.gd`; this study reduces its controls rather than reproducing its whole interface.
