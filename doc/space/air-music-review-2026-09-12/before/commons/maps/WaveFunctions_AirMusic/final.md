# After the strike

A stick lies in a cradle at the left end of a table, front to back. Eight metal bars lie along the table beside it, the longest nearest the stick, and a pale rail runs along the table's front edge.

<!-- @resonating_metallophone -->

Take the stick and bring it down on the left-hand bar. Lift it away at once and keep listening. The contact is over; the bar glows and rings, and the plate above the row names one voice, its hertz, its level and its age, the level falling as the seconds count up. Decide, before the note is gone, whether what you hear is the strike or what the strike began.

Strike the same bar again while it still rings. Nothing is added; its age on the plate starts from zero. Now strike a shorter bar instead, while the first is still fading. The plate says two voices, each with its own age. The first was not stopped by the second. Try to hear where one ends and the other goes on.

The bar keeps its note as a number and its ring as a curve. Each bar plays a sound it made once at startup:

```gdscript
		var envelope = exp(-t / decay_time)
		var wave = sin(2.0 * PI * frequency * t)
```

a sine at the bar's frequency under an exponential decay, three seconds to fall to a third of itself. The glow follows the same curve:

```gdscript
			current_amplitude = (hit_velocity * max_amplitude) * exp(-resonance_time / decay_factor)
```

So this is a synthesised resonance, not the vibration of a metal bar solved from its material. The length is chosen from the note, not the note from the length:

```gdscript
	return BAR_LENGTH * sqrt(root / maxf(1.0, freq))
```

The relation is the one a free bar would obey, length falling with the square root of frequency, and it is why the row reads as a scale before you have struck anything. What the instrument leaves out is everything else: the partials a real bar adds, the stick's material, the table underneath.

The stick's speed does reach the bar. A slow touch lands at a fraction of the level a fast one does:

```gdscript
		hit_velocity = clamp(velocity_magnitude * 2.0, 0.1, 1.0)
```

Try the same bar slowly and then quickly, and listen for what the level changes and what it leaves alone.

Now the pair. Choose two bars and strike them with a clear gap, letting the first almost finish. Reverse the order. Then shorten the gap until the second enters while the first is still loud. The plate lists both voices with their ages; the ribbon above it draws their sum, and the sum is not a third bar. When one masks the other, let them separate again and try the gap once more.

The eight notes are a pentatonic collection cut into these lengths, C4 to E5 without the fourth and the seventh. That is a decision about which pairs are available to you, not a law about which pairs are good. Another cut would offer other pairs; this room offers this one.

If you set the stick down somewhere else, it finds its way back to the cradle after a few seconds. Leave it there and listen to the last voice go.

<!-- @ -->

Every note here is one sinusoid under one decay. The Synthesis Lab adds such sinusoids together on purpose; what the ribbon drew for you as a sum is where that begins.
