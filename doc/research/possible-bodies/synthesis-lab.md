# The curve continues after its name ends

[AirMusic](air-music.html) → **Synthesis Lab** → [Random Definition](random-definition.html)

[The primary and its book passage](/necklace/thread?map=WaveFunctions_Synthesis_Lab&role=primary) · [Wavefunctions work plan](/research/waves-chance-noise/index.html#WaveFunctions_Synthesis_Lab)

At the bench, the sum is already waiting. A pale curve climbs and falls above five colored rows. None of those rows has the shape of the whole. **Which part would you remove first?**

Claude's five-slider bench, housed readout, clear approaches and miniature hallway remain. This review repairs the names the instrument gives its constructions and brings the book closer to what a visitor can actually do. All 25 placed artifacts remain; `additive_wave_demo` is the one primary the book follows.

![The bench from the desktop operating position, with the sum, five components, controls and readout](synthesis-lab-bench.png)

## Take away, predict, return

Press HOLD and lower the four sliders below H1. The extra rows disappear; a sine remains. H1 ALONE performs that removal together. BASELINE restores the five arrival amounts. Hold a phase and make the same comparison more than once.

![H1 alone: the pale total and the first component remain, drawn at different scales](synthesis-lab-one.png)

Bring H2 back. At the amber mark, predict whether it will raise or lower the total before reading the plate. The slider is a positive amount, but its sine can be negative at that position. Adding a term can lower the result.

The sum uses the same operation across the board:

```gdscript
var value = 0.0
for h in range(harmonic_amplitudes.size()):
    value += harmonic_amplitudes[h] * sin(phase * (h + 1))
return value
```

This bench is visual. It does not play its curves as audio. The continuity with AirMusic is the operation of adding contributions; the constraints have changed. Separate strikes could have separate ages. Here the five rows share one phase, multiplied by the integers one through five.

## The moment a name lets go

Restore BASELINE. Its fifth amount is 0.20. Raise it to 0.22: the sawtooth name remains. Raise it to 0.24: the label becomes Custom Waveform. The construction changed continuously. The name crossed a threshold.

| Setting | Revised label |
|---|---|
| One nonzero harmonic, including a quiet H1 | Pure Sine Wave |
| The arrival five, or all five scaled together | Approximately Sawtooth Wave |
| H4 or H5 moved well away from that recipe | Custom Waveform |
| Positive odd 1/n² terms | Odd 1/n² mix (positive terms) |
| All five zero | Zero waveform |

The old detector sometimes ignored the upper sliders and could misname a quieter lone sine as a triangle. The repaired detector checks every coefficient relative to H1, with a tolerance of 0.025. It names a neighborhood of recipes; it does not turn a finite sum into an ideal discontinuous wave.

The old source preset called `triangle` also reveals a limit: its odd terms are all positive. A triangle in this orientation needs alternating signs. Those coefficients remain available under the existing source configuration, with a more accurate label. A negative amount would require a control beyond the five supplied here.

## Something can leave the picture and remain in the sum

A component below 0.01 disappears from the ladder while the total still includes it. The formula rounds coefficients to one decimal place; the plate uses two. At some marks the sum of visible rows can disagree with the complete total. These are different decisions about what to show, rather than a single disappearance.

![The tilted readout compares the contributions at the mark, their drawn sum, and the full total](synthesis-lab-readout.png)

The ladder also uses a smaller drawing scale than the total and separates the components vertically. Add their values, not their literal heights on the board. The sampled baseline has a rounded rise of about 8.6 cm within a 50 cm cycle. Five smooth terms can suggest a corner without making an exact one. Other amounts can produce larger peaks; 1.58 is this baseline's peak, not a ceiling imposed on every sum.

This gives the question “what bodies are possible?” a specific set of tools: five nonnegative coefficients, integer harmonics and one shared phase. There is room for many unfamiliar shapes inside those constraints. There are also forms that would require another operation. Custom Waveform is a place to begin looking.

## Review and next visit

**110 independent desktop checks passed, with zero failures and engine exit 0.** They include real slider paths, a desktop pointer drag, panel presses, sum-versus-component geometry, readout values, approaches, cleanup and rebuilding. Ten coefficient settings also check the revised names and compare all 256 drawn sum samples with independent arithmetic; the largest error was below 9 × 10⁻⁸.

The book hero now agrees with the existing primary, `additive_wave_demo`. Thirteen production-code excerpts were checked across the revised final and tutorial. A stale `coloredlines` entry was removed from the book and role list; Claude had already removed its placement in the earlier visual pass.

Headset reach and label legibility remain for a later visit. Higher sums extend beyond the dark backing and can approach the upper lettering; that staging limit remains visible in this review. The nearby radio is independent of the bench. No human listening observation is claimed.

[Desktop report](synthesis-lab-check.json) · [Run receipt](synthesis-lab-run.json) · [Tutorial](synthesis-lab-tutorial.md) · [Technical notes](synthesis-lab-technical.md) · [Critical text](synthesis-lab-critical.md)

**Next: [Random Definition](random-definition.html).** BASELINE returns the five amounts without rewinding the clock. Repeating a recipe and repeating an exact instant require different state. The next hall asks what else must be kept for an unfamiliar result to return.

## Book passage

# The sum on the bench

In AirMusic one note could begin while another was already fading. Here a wave is waiting to be taken apart.

A bench stands against the north wall of the laboratory. Above it a dark board carries a pale wave with five coloured rows beneath it, and the wave already has a shape when you arrive: a long slope down and a steep rise, four times across the board, drifting to the left. On the bench, at its right end, five sliders stand in a column, one for each row.

<!-- @additive_wave_demo -->

Read the rows before you touch anything. The top row is one smooth rise and fall per cycle; each row below has more, two, three, four, five, and each is drawn smaller than the one above. None of them looks like the pale wave. Press HOLD on the panel at the left of the bench and the drift stops, so a place on the board stays where it is.

Now take the four lower sliders down, one at a time, and keep your eye on the pale wave while each row leaves the ladder. What remains is the top row, drawn larger: a sine. Press BASELINE and the four return together; press H1 ALONE and they leave together. The shape you arrived at is not one thing with a slope in it. It is five smooth returns added, and the slope belongs to none of them.

Bring the second row back on its own slider and choose a place on the board. The amber line marked *mark* is one such place. Before you raise the third slider, decide what the sum will do there: the third row is at a crest, or crossing its middle, or in a trough, and its slider decides how much of that is admitted. Raise it and read the plate on the bench. Its third line lists each row's value at the mark; the fourth adds them and prints the total drawn beside them. With these five visible rows, their sum agrees with the total. The pale wave is built by this loop:

```gdscript
	var value = 0.0
	for h in range(harmonic_amplitudes.size()):
		value += harmonic_amplitudes[h] * sin(phase * (h + 1))
	return value
```

Row h is a sine at h + 1 times the phase, scaled by its coefficient, and the sum is the running total. There is no separate drawing of "the wave". The pale line is this loop evaluated 256 times across two metres,

```gdscript
const WAVE_POINTS: int = 256
const WAVE_LENGTH: float = 2.0  # Visual length in meters
const NUM_HARMONICS: int = 5
```

with the phase running four cycles across the board and the clock adding the drift you stopped with HOLD:

```gdscript
		var phase = t * TAU * 4.0 + _time * TAU
```

A slider changes exactly one number. When a handle moves, the instrument reads the handle's position back as that row's coefficient:

```gdscript
		harmonic_amplitudes[harmonic_index] = harmonic_sliders[harmonic_index].get_normalized_value()
```

Even the first slider only changes how much of the first return is present. This is a visual instrument; it does not play the curve as sound. No slider changes the fundamental's frequency. The rows use integer multiples of one phase, so the vocabulary here is five amounts. Unlike the separately struck bars, these rows cannot choose separate beginnings. A shifted row or a negative amount would need a control this bench does not offer. BASELINE returns them to the table the room was placed with:

```gdscript
		"sawtooth":
			# Sawtooth: all harmonics, amplitude 1/n
			_set_amplitudes([1.0, 0.5, 0.333, 0.25, 0.2])
```

one over n, all five present, the recipe the label calls a sawtooth. The plate's last line names every coefficient that differs from this table, so you can wander and still know how far you have gone.

With the baseline held, look at the rise. An ideal sawtooth jumps; this one climbs from trough to crest over about nine centimetres of a fifty-centimetre cycle. Its descent ripples where the ideal would be straight. Raise the fifth slider and those ripples change. The baseline peaks near 1.58; other amounts can rise further. Five smooth returns can suggest a corner and cannot make an exact one. From across the room the pale line suggests a sawtooth. At the bench its rounded rise remains available to inspect.

Take the second and fourth rows out and leave the odd three; the label offers a name. Move the fifth a little. At first the name stays. Move further and it gives way to Custom Waveform. The curve has changed continuously; the naming rule crossed a threshold. It checks all five amounts relative to the first, allowing a small difference from a recipe. Custom is a place to continue from.

Then remove the row you think matters least and find where its absence shows. It is not in one place, because each row runs the whole cycle. Near zero, a row disappears before its coefficient reaches zero: the display hides values below 0.01 while the sum still includes them. At some marks the plate can report a difference between the visible rows and the total. Something has left the picture without leaving the calculation.

<!-- @ -->

BASELINE restores the five amounts. While HOLD keeps the phase still, the same curve returns to the same place. Let the clock run and those amounts return as a moving shape. Repeating a recipe and repeating an exact instant ask for different things to be kept. Random_Definition takes that question further: what must we retain to bring an unfamiliar result back?
