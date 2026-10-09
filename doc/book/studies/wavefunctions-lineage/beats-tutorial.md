# A difference in time

## Learning elements

- Adding two signed signals
- Frequency difference and beat period
- A shared start and changing relative phase
- Keeping raw values separate from display gain

At the beat display, bring the two frequency controls close together. A and B move quickly. Their sum grows and shrinks more slowly. At a quiet moment in the lower row, the sources above it can still be moving.

Air Music kept two voices and their playback ages. Here we isolate their relationship: two unit-amplitude sines, started together, at slightly different frequencies. The black PointBody chooses B; the familiar LineSkin draws A, B and their sum. Sky Stairs gave samples solid support. These samples make a visual comparison again. They do not form a floor or produce sound.

## Continue inside the museum

Use the prepared Endless Museum project, with its player, XR pickup, lighting and camera. Save the three scripts below together. Keep `point_body.gd` and `line_skin.gd` unchanged. Attach `11_two_cycles.gd` to an empty Node3D in this hall's learner bay: **hall-local (23, 0, 12), Y rotation 180 degrees, unit scale**. Run the museum scene as before. The program creates its own point, lines and labels; no named scene children are required.

Grab the black point. Its local height previews B between 0.5 Hz below and 0.5 Hz above A. At 1.2 metres, B equals A. Press the held object's established trigger action to apply the preview and restart both waves together. Moving the point alone leaves the current pair running. This keeps the chosen frequency fixed during each observation.

## Two sources, one sum

`values_at()` returns three signed values: A, B and their raw sum. Negative values matter. A positive value and an equal negative value cancel; neither source has disappeared. With unit-amplitude inputs, the raw sum lies between −2 and +2.

{CODE}

Both waves use the same elapsed time and the same added phase at each horizontal position. Two turns of that shared phase fill each row. This is a set of phase-shifted copies of the same comparison, not a simulation of a wave travelling through material. Follow one fixed horizontal position to compare the fast oscillation with its slower envelope.

`plot_position()` applies half gain only when drawing the bottom row. `values_at()` and the numeric readout retain the raw sum. If the bottom row reaches the same height as A, that does not mean their raw amplitudes are equal: the drawing scales differ. The label says `(A+B) / 2` for this reason.

The PointBody signal passes the held object to `on_action()`. We do not need that argument here; the callback simply starts a new comparison. Restarting resets the common clock as well as applying B. Equal frequencies therefore begin aligned in this study. Two equal-frequency sources started with different phases would retain that difference; equal frequency alone does not guarantee reinforcement.

## What changes slowly?

Begin with A = 4 Hz and B = 4.5 Hz. Their phase difference grows by half a turn each second. One second after the shared start, they oppose one another throughout the rows. After two seconds they align again. The large changes in amplitude repeat every two seconds: **0.5 beats per second**.

In general, the beat rate is `abs(A − B)` and the period is its reciprocal. The equal-frequency case needs a separate branch: there is no finite beat period to calculate. In the sum identity, a signed cosine factor changes sign; the visible amplitude follows its absolute size. Count successive loud-looking envelopes, not only positive peaks of that factor.

The existing museum exhibit updates its frequencies continuously as you move its sliders. Our trigger commits a pair and resets its start, making the predicted one-second cancellation easy to repeat. Both displays are visual. A later audible experiment would need an audio source; moving a visible sphere does not create sound.

## The carried pieces

These are the same grabbable sphere and finite-cylinder line renderer. Their full files are included so the reconstruction is complete. The main script applies the black finish and the three row colours.

{POINT_CODE}

{LINE_CODE}

## Predict, change, return

1. Start the default pair. Follow one horizontal position through narrowing and widening. At the narrow moment, inspect both inputs and the raw sum readout.
2. Hold the point at local height 1.45 metres: B previews 4.25 Hz. Trigger. Predict the new period before watching: four seconds, with opposition after two.
3. Move the point to 0.95 metres and trigger. B is now 3.75 Hz. The absolute difference is still 0.25 Hz. The beat period stays four seconds although the faster source has changed.
4. Set the point to 1.2 metres and trigger. Both frequencies are 4 Hz. The sum keeps twice either source's raw value; half gain makes the lower row's excursion match the upper ones.

For an independent variation, set `frequency_a` to `5.0` and the point's initial Y to `1.45`. Before running, predict B = 5.25 Hz and the same four-second envelope period despite the faster sources. The complete `11_faster_pair.gd` variation is included; attach it instead of the original.

Native assertions run the exact printed files. They test the PointBody action callback, local-height mapping in a moved and rotated host, values at known phases, cancellation and reinforcement, the four-second variation, equal frequencies and display gain. Deliberate sign, gain and restart faults must fail. This verifies the program's behaviour, not a reader's understanding or headset comfort.

The red-and-blue paths remain a different comparison: sine and cosine distributed through finite circulating rows. The Lissajous figure gives separate coordinates to oscillations instead of adding them on one axis. Keep these constructions distinct. In Synthesis Lab, we will retain the signed sum and change how much several harmonic components contribute.
