# WaveFunctions AirMusic — Technical

## The primary: a row of bars, each with its own note

`ResonatingMetallophone` (`algorithms/wavefunctions/resonance/ResonatingMetallophone.gd`) cuts a row of `ResonatingBar` rigid bodies to a tuning. The shipped `pentatonic` is C4, D4, E4, G4, A4, C5, D5, E5 — eight bars 0.12 m apart as shipped, 0.16 m on the table, because the striker's tip is a 7 cm ball and at 0.12 m one strike rang a neighbour too. Each bar's length comes from its frequency:

```gdscript
	return BAR_LENGTH * sqrt(root / maxf(1.0, freq))
```

the free-bar relation (flexural frequency ∝ h / L²), so the lowest bar keeps `BAR_LENGTH` 0.30 m and the highest is 0.19 m. `#tuning:equal` (17 bars), `just` (10) and `harmonic` (12) re-cut the row over the same range; the count is part of the argument.

## The note

Each bar renders its note once, in `ResonatingBar._generate_resonance_sound`, and plays it from its own `AudioStreamPlayer3D` (unit size 3 m, max distance 20 m):

```gdscript
		var envelope = exp(-t / decay_time)
		var wave = sin(2.0 * PI * frequency * t)
```

`decay_time` is 3 s; the buffer is 2.5 decays long (7.5 s, 8 % of level at its end) and eases out over its last tenth of a second. The visible response follows the same curve —

```gdscript
			current_amplitude = (hit_velocity * max_amplitude) * exp(-resonance_time / decay_factor)
```

— and ends when the sound does. Because every bar has its own player, notes on different bars overlap; a strike on a bar that is still ringing restarts that bar's player and its clock, adding no voice.

## The strike

A bar's `body_entered` (contact monitor on the rigid body) and a `StrikeZone` Area3D no wider than the bar both fire `_on_body_hit`; a body counts as the striker if it or any ancestor is in the "stick" group — the part of the stick that meets a bar is a StaticBody3D at its tip, 1 m from the handle, and its name alone never matched. One strike is counted once within 60 ms. The striker is `grab_long_stick.tscn`, an XR Tools pickable. Held, a pickable is frozen (kinematic), moved by the hand's transform, its collision mask cleared and its layer set to the pick-up layer; the bars listen on that layer as well, so the held striker forms a contact pair. The bar reads the strike's strength from the striker's speed:

```gdscript
		hit_velocity = clamp(velocity_magnitude * 2.0, 0.1, 1.0)
```

where `velocity_magnitude` is the larger of the bodies' `linear_velocity` and, for a held striker that has none, the speed the instrument measures per physics frame and hands over as the stick's `speed` meta. Louder for a faster strike, from −6 dB up to 0 dB.

## The staging

`#stand:table` builds the deck at the origin: a 1.50 × 0.56 m table, top at 0.85 m, with a collider; the bars at 0.875 m, locked on every axis and kept awake; two cradle blocks at the table's left end with the striker lying across them front to back (since the visual pass of 12 September; they stood on the front edge, the striker along the row), a pale emissive rail along the front edge and a dark kerb along the back; the Hz labels and the instruction on the table's front face; the combined wave at 1.35 m and its readout above. Left more than 0.5 m from the cradle and not held for 3 s, the striker is tweened back and frozen at rest; on its way home its tip sweeps across the row, so a returning striker is marked and rings nothing.

## The readout and the sum

`CombinedWaveVisualizer` finds every `ResonatingBar` under the instrument, sums `sin(2π·f·(t + x/2)) · amplitude` over the ringing bars across a metre-wide window, and draws it as a flat ribbon (a one-pixel line strip does not survive a capture); its label lists the voices as `N voices · f Hz level (age s)`, or `silent · strike a bar`.

## Cleanup

Bars, players, table, cradle and labels are children created in `_ready` and freed with the instrument; the museum's streamer frees and rebuilds the hall with an instrument that rings again.

## Where it leads

Every note here is one sinusoid under one decay, and the ribbon draws their sum. The Synthesis Lab builds such sums on purpose; the vocabulary is the additive one — Σ aₙ · sin(2π · fₙ · t) — with each term's amplitude in a hand.
