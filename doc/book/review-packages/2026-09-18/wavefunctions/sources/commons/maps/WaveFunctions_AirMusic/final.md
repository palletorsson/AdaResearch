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
