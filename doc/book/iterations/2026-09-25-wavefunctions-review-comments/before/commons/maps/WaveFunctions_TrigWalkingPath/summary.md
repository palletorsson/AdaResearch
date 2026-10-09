# Current hall: a slow pulse from fast motions

`beat_frequency_demo` is the primary. Its two controls set frequencies from 1 to 10 Hz. The three rows show A, B and half of their raw sum. Close frequencies give a slow envelope; equal frequencies remove the beating in this fixed-phase demonstration. The display is visual only. See [the chapter](final.md) for the encounter and `algorithms/wavefunctions/beat_frequency/beat_frequency_demo.gd` for the implementation.

The secondary `TrigWalkingPath` remains in the room. Its shipped scene creates forty pairs of collidable steps once, adds end platforms, then circulates the two rows in opposite directions. Their heights combine a shared sloping base with sine or cosine. There is no visitor-triggered generation, cross-bridge or linked chart in that source. The other secondary works are `sine_oscillation`, `lissajous_curves` and `wave_interference`; `dark_sphere` remains the reference object. The next hall compares five fixed harmonic frequencies in the Synthesis Lab.

## Archived design proposal

The text below is preserved from an earlier design. Its endless generation, cross-bridge, entrance controls and linked chart are proposals, not descriptions of the current hall. Its code is illustrative, not an extract from the shipped artifact. The current chapter and the source named above take precedence.

---

# WaveFunctions TrigWalkingPath — Summary

Sine and cosine are the same function, offset by ninety degrees. This map makes that offset physical. Two parallel walkways run side by side across the space. The left lane's steps rise and fall according to sin; the right lane follows cos. The learner can walk either lane or hop between them.

Each step is a computed block; the path generates itself a few steps ahead of the walker. A reference panel on one wall shows the two functions on a shared chart, with a marker indicating the walker's current horizontal position. The marker moves as you walk, so the graph and the footing stay synchronised.

At the midpoint, a cross-bridge connects the two lanes so the ninety-degree offset is walkable in one move. Sliders at the entrance adjust frequency and amplitude; raising the frequency compresses the period, shortening the path between peaks. Raising the amplitude deepens the troughs and lifts the crests.

Within the sequence, the walking path is the penultimate map. After Sky Stairs, the verticality returns to ground; after the sound and silence maps, the geometry returns to the foreground. The map trains the body to read sin and cos as paired, displaced, and equivalent before the Synthesis Lab asks you to decompose everything.
