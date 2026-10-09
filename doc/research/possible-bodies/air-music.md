# After the strike

[Effect Sound](effect-sound.html) → **AirMusic** → [Synthesis Lab](synthesis-lab.html)

[The primary and its book passage](/necklace/thread?map=WaveFunctions_AirMusic&role=primary) · [Wavefunctions work plan](/research/waves-chance-noise/index.html#WaveFunctions_AirMusic)

Lift the stick away. Something continues without your hand. Strike the same bar again, then try a different one while the first still rings. **What starts over, and what is allowed to continue?**

Claude's eight-bar table, working striker and returning cradle remain the encounter. This review gives its waveform a closer relation to the notes: it now reads a short window of each bar's generated sound at that bar's own playback age. The book follows the metallophone through contact, repetition and overlap.

![Two sounding bars, two ages, and the curve made by adding their source samples](air-music-two-voices.png)

## Keep the notes; change their meeting

The same bar starts its existing player again. A second bar has another player, so its note can begin while the first continues. Try C4, the longest bar, then A4, the fifth bar from the left. Listen through the ending before deciding whether you heard two separate events or one changing sound.

These remote examples use the exact C4 and A4 sample buffers exported from the running instrument. They are constructed comparisons at equal, unit player gain, before spatial audio. They are not recordings of the probe's strikes, which had their own strengths. No normalisation, added effects or clipping is applied.

**Separate.** C4 plays for 7.5 seconds. After a quarter-second gap, A4 plays for 7.5 seconds.

<audio controls preload="metadata" aria-label="C4 and A4 with a gap"><source src="air-music-separate.wav" type="audio/wav">Download the separate notes below.</audio>

**Overlap.** C4 begins, and A4 joins one second later. Their frequencies and buffers stay the same; their meeting changes.

<audio controls preload="metadata" aria-label="C4 and A4 overlapping after one second"><source src="air-music-overlap.wav" type="audio/wav">Download the overlapping notes below.</audio>

[Separate notes](air-music-separate.wav) · [Overlapping notes](air-music-overlap.wav) · [C4 alone](air-music-C4.wav) · [A4 alone](air-music-A4.wav)

## A small window with several beginnings

The curve spans **12 milliseconds**, sampled at 512 points. It adds each playing bar's stored PCM samples after that player's gain. The readout names the voices and their different playback ages. The scale stays fixed as the sound fades; if the sum exceeds the drawing range, the label reports a display limit.

This is a view of the generated sources before distance, the audio bus and the listening equipment. The room and your position still contribute to what reaches you. The picture makes a particular part of that encounter available to inspect.

![The eight bars and striker cradle from the desktop operating position](air-music-table.png)

| Try in the hall | What to notice |
|---|---|
| Strike one bar and lift the stick away. | Contact ends while the response continues. |
| Strike that bar again before it ends. | Another attack, one voice; its age restarts. |
| Strike another bar while the first rings. | Two voices keep different beginnings. |
| Touch the same bar slowly, then quickly. | Strength affects glow and player gain through different mappings. |
| Leave the stick unheld, more than half a metre from its cradle. | After three seconds its return begins; the return does not play the bars. |

## Where the model lets go

The bars look like a material argument about length and pitch. In this implementation the note is chosen first, then length is assigned from frequency. The contact chooses when a stored sine begins and how strongly it plays. A different-looking bar could carry the same stored note.

Its exponential envelope still has about 37 percent of its initial value after three seconds. Mathematically it never reaches zero, yet this note ends at 7.5 seconds, with an extra fade in its final tenth. The program gives the response an ending. We can hear that decision and read the code that makes it.

## Review and next visit

**67 independent desktop checks passed; the engine exited normally.** They cover collision strikes, repeated and overlapping notes, the cradle return, approach routes, cleanup and rebuilding. New checks independently decode PCM, apply player gain, add the windows and compare the sum with the drawn curve. The measured voices had different ages.

All ten placed artifacts remain. The book hero now agrees with the existing primary: `resonating_metallophone`. The revised final and tutorial contain fourteen checked production-code excerpts. The supporting texts distinguish the glow, generated sound and listener's encounter.

Tracked-hand reach, label legibility in the headset and a person's listening observations remain for a later visit. The probe moved the actual striker through its collision path. It did not demonstrate a human hand playing the instrument. Some secondary captions still crowd the wider view.

[Desktop report](air-music-check.json) · [Run receipt](air-music-run.json) · [Audio construction](air-music-audio.json) · [Tutorial](air-music-tutorial.md) · [Technical notes](air-music-technical.md) · [Critical text](air-music-critical.md)

**Next: [Synthesis Lab](synthesis-lab.html).** Here the sum came from separately struck bars. The next bench makes a sum visible: what becomes possible when five harmonic amounts are chosen together, and what does their shared phase leave out?

## Book passage

# After the strike

In Effect Sound we kept a note and changed the rule that made it. Here the hand can leave while its consequence continues.

A stick lies in a cradle at the left end of a table, front to back. Eight metal bars lie along the table beside it, the longest nearest the stick, and a pale rail runs along the table's front edge.

<!-- @resonating_metallophone -->

Take the stick and bring it down on the left-hand bar. Lift it away at once and keep listening. The contact is over; the bar glows and rings, and the plate above the row names one voice, its hertz and its age. The glow fades as the seconds count up. Decide, before the note is gone, whether what you hear is the strike or what the strike began.

Strike the same bar again while it still rings. There is another attack, but no additional voice: this bar starts its existing player again, and its age on the plate returns towards zero. Now strike a shorter bar instead, while the first is still fading. The plate says two voices, each with its own age. The first was not stopped by the second. Try to hear where one ends and the other goes on.

The bar keeps its note as a number and its ring as a curve. Each bar plays a sound it made once at startup:

```gdscript
		var envelope = exp(-t / decay_time)
		var wave = sin(2.0 * PI * frequency * t)
```

a sine at the bar's frequency under an exponential decay. After three seconds its envelope is about 37 percent of its initial value. The glow uses that decay too:

```gdscript
			current_amplitude = (hit_velocity * max_amplitude) * exp(-resonance_time / decay_factor)
```

So this is a synthesised resonance, not the vibration of a metal bar solved from its material. The length is chosen from the note, not the note from the length:

```gdscript
	return BAR_LENGTH * sqrt(root / maxf(1.0, freq))
```

The chosen relation makes length fall with the square root of frequency. This gives the row a visible order before you have struck anything. The program does not compute this note from the metal, the stick's material or the table underneath. Those bodies could change without changing the stored frequency. The resemblance is an arrangement we can inspect.

The stick's speed does reach the bar. A slow touch lands at a fraction of the level a fast one does:

```gdscript
		hit_velocity = clamp(velocity_magnitude * 2.0, 0.1, 1.0)
```

Try the same bar slowly and then quickly, and listen for what the level changes and what it leaves alone. The glow uses the strike value directly; the player maps it into decibels. A much dimmer glow need not mean a proportionally quieter note. The hand has reached two different mappings.

Now the pair. Choose two bars and strike them with a clear gap, letting the first almost finish. Reverse the order. Then shorten the gap until the second enters while the first is still loud. The plate lists both voices with their own playback ages. The ribbon adds a short piece of the two generated notes, and the sum is not a third bar. When one masks the other, let them separate again and try the gap once more.

The eight notes take C, D, E, G and A and continue into the next octave, ending at E5. That is a decision about which pairs are available to you, not a law about which pairs are good. Another cut would offer other pairs; this room offers this one.

Set the stick down more than half a metre from its cradle and leave it alone. After three seconds the return begins. Leave it at rest and listen to the last voice go.

An exponential never quite arrives at zero, but this note does end. The stored sound lasts seven and a half seconds, with a short fade in its final tenth. The model lets go before the mathematical tail does.

Look at the plate's other number: 12 ms. The ribbon has only that much time across its width. It reads samples near each bar's playback position, after that player's gain, before distance and the rest of the audio system. A smooth curve here still joins chosen data points. Moving your head changes what reaches you without rewriting these stored notes.

<!-- @ -->

Every note here is one sinusoid under one decay. The Synthesis Lab adds such sinusoids together on purpose; what the ribbon drew for you as a sum is where that begins.
