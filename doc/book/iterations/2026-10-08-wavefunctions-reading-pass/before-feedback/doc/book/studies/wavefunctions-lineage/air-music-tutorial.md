# A note continues after contact

## Learning elements

- Contact as an onset event
- One audio player per voice
- Restarting one voice; overlapping two
- Playback age and decay
- Adding samples from independent voices

In the Cage hall, a kept score supplied the times. Here your hand supplies them. Strike a bar of the existing metallophone, lift the stick away, then strike another. Two notes can continue together. Strike the first again: its age starts over while the second keeps going.

We reconstruct that distinction with two touch bars and the black PointBody you already made. Move the point into one bar, withdraw it, then touch the other. The bars are sensors: they detect entry without blocking the sphere. The museum instrument has a physical stick, speed-sensitive strikes and eight bars. Our study keeps two voices at a fixed level so the new operation is clear.

## Continue inside the museum

Use your Day Zero Endless Museum working copy, with its camera, lighting, player and XR Tools pickup already running. Save the four scripts below together. Keep `point_body.gd` and `line_skin.gd` unchanged. Attach `09_contact_voices.gd` to an empty, unit-scale Node3D in the Air Music learner bay: hall-local position **(13, 0, 14)**, Y rotation **180 degrees**. Run that museum scene as before. Do not attach this study to the existing metallophone.

The script makes the point, two visible bars, contact volumes, players and readout. There are no named scene children to prepare. Grab with the established pickup control and move the point into a bar. No trigger press is needed. Desktop pickup uses the same point; the lesson does not install another player.

## Two voices, two beginnings

The arrays use one shared index: bar 0, player 0 and samples 0 belong together. `body_entered` supplies the contacting body; `bind(i)` adds the bar's index. We accept only this point. The collision mask includes both its normal layer and the layer XR Tools uses while it is held.

`players[index].play()` starts that player's clip from the beginning. Calling it again replaces that voice's current playback. We do not stop the other player. Remaining inside a bar causes no further entry event: leave and return to strike again.

{CODE}

Each audio player owns its playback clock. `ages_now()` reads those clocks once for each drawing frame; `-1` means quiet. The visible study does not invent a second timer and try to keep it synchronized with sound. In conceptual terms, age is the time since this voice's onset. Godot gives us that age through `get_playback_position()`.

`sum_at()` reads each active voice at its own age plus the same small offset, then adds the values. A new strike changes one age, so it changes how the samples meet. The pink line shows 12 milliseconds across its width at a fixed vertical scale. It reads the generated data before spatial attenuation and the audio bus. Moving your head can change what you hear without changing this curve. Playback position is reported at audio-mix intervals; this is an inspectable display, not a sample-accurate oscilloscope.

## Let the note fade

Effect Sound already taught a sampled sine, an envelope and 16-bit encoding. `RingVoice` uses that construction with a longer, plain decaying sine. The previous phase-modulated `NoteVoice` remains available to Cage; we do not change its sound to write this lesson.

{VOICE_CODE}

`exp(-age / DECAY)` falls as age grows. With `DECAY = 0.8`, its value is about 0.37 after 0.8 seconds. That number is a decay time constant, not the note's duration. The finite buffer lasts three seconds. A short attack and final fade soften its edges. The chosen frequency makes the sound; the box's size does not calculate a metal bar's resonance.

`encode_s16()` stores a signed integer for each sample. `read_sample()` reverses that conversion for the display, returning zero before or after the buffer. We cache the bytes once in `samples`, so drawing does not repeatedly fetch whole sound resources. Each voice is bounded by 0.25; two unscaled source voices cannot exceed 0.5 in magnitude. That leaves source headroom. The prepared audio output still determines the listening level.

## The two carried pieces

These are the same point body and finite cylinder renderer. Their complete files are included so this reconstruction has no missing dependency; the black finish is applied by the main script.

{POINT_CODE}

{LINE_CODE}

## Test the distinction

1. Touch the left bar and withdraw. One age should keep increasing after contact ends.
2. Before it finishes, touch the right. There should be two ages. The first must not jump back to zero.
3. Leave the right bar and return to it. Only the right age restarts. Hold the point still inside: it must not keep restarting.
4. Withdraw and wait three seconds. Both labels should read quiet, and the sum should become a straight line.

Now change only the second frequency from `392.0` to `261.63`. Predict what stays separate. Run again, striking the bars with a gap. The two clips now contain the same samples, but their playback ages remain independent. Equal pitch does not require equal phase or simultaneous beginnings. The download includes the complete `09_same_pitch.gd` variation; attach it instead of the original, never alongside it in the same bay.

Native tests extract the exact printed scripts, move the actual sphere collider through both areas, test the held collision layer, reject an unrelated body, check independent restart and compare the displayed sum with stored samples. They also run the same-pitch variation and wait for playback to finish. These assertions check the reconstruction; they do not establish headset comfort or whether a reader can build it unaided.

The original eight-bar instrument remains in the hall. Return to it and try the same sequence with its stick. Keep the two independent voices and their sum for Beats. First, Sky Stairs returns to spatial composition: samples will place solid treads, and the cube will carry weight where a line only drew a path. We will come back to combining waves after that crossing.
