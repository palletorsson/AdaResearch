# One wave inside another

Can one oscillation change the character of another?

<!-- @DualBallFMController -->

Two reading desks stand apart from the racks, in the quiet quarter of the hall. On the blue one hangs the carrier ball; on the orange one, the modulator ball. Press BASELINE on the panel between them and you hear a plain tone: 440 hertz, a ten-millisecond attack, a decay of a second and a half. Nothing else is in it yet. Press HOLD, and that note is kept as A.

Now lift the orange ball a little. The rig plays again as the ball moves, and the beginning of the note is not what you expected: something rougher arrives with the attack and thins out as the note fades. Let it finish. The readout above the panel names what changed and nothing else: `differs: I 0.00→4.00`. Press COMPARE and the room plays A, a quarter of a second of silence, then the note you just made. Keep the blue ball where it is through all of this. The carrier is the thing being changed, and it stays fixed while you listen to the change.

Then vary one modulator dimension at a time. The ball's height is the index: how deep the change goes. Its depth along the desk, toward you, is the modulator's own decay: pull it closer and the roughness lasts into the tail instead of dying at the start, while the note's loudness fades exactly as before. What you are hearing is the changing character separated from the fading level. The ball's third axis, left to right, is the ratio, which decides whether the added partials sit on the carrier's own overtones or between them; move it last, and only after another COMPARE.

What the rig computes, sample by sample, is drawn on the scope above the desks. The modulator is a decaying sinusoid:

```gdscript
var mod_env = exp(-t / mod_decay)
var modulator_freq = carrier_freq * mod_ratio
var modulator = sin(2.0 * PI * modulator_freq * t) * mod_index * mod_env
```

and it enters the carrier's phase, not its output:

```gdscript
var output = sin(2.0 * PI * carrier_freq * t + modulator) * carrier_env
output = tanh(output * 0.8) * 0.5
```

`carrier_env` is a linear attack followed by an exponential decay. The note is synthesised at 44,100 samples per second for 1.2 times the decay, three seconds at most, and the tanh keeps every sample within half of full scale. This is why the label is frequency modulation, or, precisely, phase modulation: nothing is added to the carrier's sound. Its instantaneous frequency is pushed and pulled, faster and further the higher the index and the ratio, and the partials you hear are what a sinusoid sounds like when its phase will not hold still. Two audio outputs mixed together would give you the sum of two tones. This gives you a tone that was in neither input.

<!-- @ -->

Afterwards the colour cube on the shelf is only a sign of the six values, and the scope's four lanes are the same expression drawn out. What the desks leave in the hand is a habit: fix one thing, change one thing, listen through the tail before deciding what you heard. The next room on the route, AirMusic, gives that habit a struck body: a resonance you set off and then have to wait for.
