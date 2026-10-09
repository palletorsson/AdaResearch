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

## What the room keeps

At the bench, one slider changed how much of a wave was present. Another instrument in the laboratory, Slow Circuits, offers ENTER ROOM. Take this short detour with a voice.

<!-- @ambient_patch -->

A loudspeaker stands inside. At the Voice station, press RECORD / END, say a short phrase, and press again to finish. Eight seconds is the limit. DEMO VOICE offers a synthetic phrase if you prefer. Listen once. Then press HEAR ORIGINAL, let it finish, and hear it again. The instrument plays the same stored recording. Repetition has not yet altered its data.

Press NEXT PASS. Something has acted on the phrase. Listen for a vowel, a consonant, a pause. Press again. Which is easiest to follow now? AUTO continues the returns; HEAR ORIGINAL interrupts them with the recording you began from. The comparison remains available even when the words become difficult to recognize.

The room keeps the result of each pass and makes that result the next input. Leaving out the worker and playback machinery, the operation is:

```gdscript
current = DSP.room_pass(current, absorption).samples
```

The next pass begins with a sound that has already been changed. Compare that with the line used when you press RESET:

```gdscript
current = original.duplicate()
```

A copy can keep the values. A filter acts on them. Here, delayed sound returns into the calculation, reinforcing some frequencies more than others. Repeating the operation makes that unevenness increasingly audible. The voice and the rule participate in what remains.

Alvin Lucier's *I Am Sitting in a Room* begins with a voice recorded and played back into a physical room, then recorded again. The room's resonances become prominent through successive returns. A digital recorder could take part in that physical process too; tape damage is not required for its central effect.[^synthesis-lucier]

Calling everything we hear here *analogue distortion* would hide a distinction we can investigate. In Lucier's physical setup, sound passes through air between a loudspeaker and a microphone. In this virtual room, the first recording enters a numerical model. Three delayed paths use the room's dimensions; damping changes what returns. The visible walls do not, by themselves, act on the sound.[^synthesis-room-model]

Go to SURFACE and move ABSORB. The panels change colour and the experiment returns to the stored voice. Begin the passes again. Keep the same phrase and compare what happens under the changed conditions. Colour and acoustic response have been connected by code. One has not caused the other.

A wall can look like concrete before we have given it any of concrete's acoustic behaviour. What would it mean to give that wall the response of cloth? Or to let a curtain ring? Those rooms are possibilities for another iteration. The current control changes absorption; it does not yet let us exchange a whole material's behaviour. Even this smaller choice makes appearance and action available to question separately.

There are other choices inside the return. Each pass is adjusted to the same peak amplitude. The recording has a fixed length, with a short allowance for its tail. Sound that continues beyond that window is cut away. HEAR ORIGINAL means the first recording this instrument stored; it cannot give us the voice before recording, sampling and preparation. Walking changes where we hear the virtual loudspeaker, while the simplified resonance model stays fixed.

Listen once more to the original. What became difficult to hear has not been deleted from every place. It remains in a buffer we chose to keep. The room's rules shaped one version of the voice; comparison lets us notice their work. Which properties would we carry into another room, and which might we let it change?

<!-- @ -->

Back at the bench, BASELINE restores the five amounts. While HOLD keeps the phase still, the same curve returns to the same place. Let the clock run and those amounts return as a moving shape. Repeating a recipe and repeating an exact instant ask for different things to be kept. Random_Definition takes that question further: what must we retain to bring an unfamiliar result back?


[^synthesis-lucier]: Alvin Lucier, *I Am Sitting in a Room* (1969). Nicolas Collins's [album notes](https://www.dramonline.org/albums/alvin-lucier-i-am-sitting-in-a-room/notes) (1990) describe the result as an encounter between a particular voice and a particular space, and discuss its realization with digital delays or samplers. Collins also attends to Lucier's stutter as a rhythmic contribution. The description of speech becoming less intelligible should not make that difference into a defect we presume the work repairs.

[^synthesis-room-model]: Julius O. Smith III, [“Artificial Reverberation,” *Physical Audio Signal Processing*](https://www.dsprelated.com/freebooks/pasp/Artificial_Reverberation.html), explains how delays and filters model propagation, reflections and absorption, and why a response between a source and receiver depends on their positions. Ada's current three-path model is much simpler: it does not calculate reflections from the visible mesh, an open doorway or a moving microphone. The equation above abbreviates `room_memory_audio.gd` and `room_memory_dsp.gd`; the actual processing runs on a background worker.
