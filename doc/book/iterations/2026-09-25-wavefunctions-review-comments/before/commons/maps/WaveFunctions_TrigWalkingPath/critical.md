# Current hall: a slow pulse from fast motions

`beat_frequency_demo` is the primary. Its two controls set frequencies from 1 to 10 Hz. The three rows show A, B and half of their raw sum. Close frequencies give a slow envelope; equal frequencies remove the beating in this fixed-phase demonstration. The display is visual only. See [the chapter](final.md) for the encounter and `algorithms/wavefunctions/beat_frequency/beat_frequency_demo.gd` for the implementation.

The secondary `TrigWalkingPath` remains in the room. Its shipped scene creates forty pairs of collidable steps once, adds end platforms, then circulates the two rows in opposite directions. Their heights combine a shared sloping base with sine or cosine. There is no visitor-triggered generation, cross-bridge or linked chart in that source. The other secondary works are `sine_oscillation`, `lissajous_curves` and `wave_interference`; `dark_sphere` remains the reference object. The next hall compares five fixed harmonic frequencies in the Synthesis Lab.

## Archived design proposal

The text below is preserved from an earlier design. Its endless generation, cross-bridge, entrance controls and linked chart are proposals, not descriptions of the current hall. Its code is illustrative, not an extract from the shipped artifact. The current chapter and the source named above take precedence.

---

# Ninety degrees is a relation — sin and cos, parallelism, and the politics of offset

Sin and cos are the same function displaced by ninety degrees. Every introductory trigonometry text says this; few make it feel physical. This map does. Two parallel walkways run side by side across the space. The left lane's steps rise and fall according to sin; the right lane follows cos. The two lanes are close enough that the learner can step between them at any time.

Luce Irigaray argues that the politics of identity lie in relation rather than in isolation. A subject defined alone, without reference, is an abstraction that erases the relational conditions of its definition. The sine function alone is similarly abstract; it gains its character from its relation to cos and to zero and to the other harmonics it can be composed with. The map stages the relation as a physical parallelism.

Each step along the lanes is a computed block. The path generates itself a few steps ahead of the walker, so the learner always sees a short runway of coming terrain. A reference panel on one wall shows the two functions on a shared chart, with a marker indicating the walker's current horizontal position. The marker moves as the learner walks, and the graph and the footing stay synchronised.

At the midpoint of the walk, a cross-bridge connects the two lanes. Stepping onto the bridge and crossing to the other lane translates the learner by ninety degrees of phase. The learner's elevation changes suddenly — the cos track is either a quarter-cycle ahead or behind the sin track at that point, depending on direction of travel. The move is a quiet demonstration: changing phase is easier on foot than in notation, because the notation writes the offset as an argument to the function while the walk writes it as a single step sideways.

The slider bench at the entrance exposes frequency and amplitude. Raising the frequency compresses the period, shortening the distance between peaks. Raising the amplitude deepens the troughs and lifts the crests. Both sliders affect both lanes identically, because the parameters are shared. What the sliders cannot decouple is the phase relationship: the ninety-degree offset is structural, not parametric, and the map does not pretend otherwise.

Irigaray's insight is political as well as metaphysical. A relation that cannot be dissolved into independent parts is a relation that resists the reduction to separate selves. The sin-cos pair is such a relation. Any attempt to treat sine as primary and cosine as derivative is immediately undermined by the symmetric alternative. The map argues that both functions are equally fundamental, and that the fundamentality is a property of their displacement rather than of either one considered alone.

Within the sequence, TrigWalkingPath is the penultimate map. It trains the body to read sin and cos as paired, displaced, and equivalent before the Synthesis Lab asks the learner to decompose everything into sine components. The pairing is the bridge to the final map's Fourier argument: you cannot decompose into sines without knowing that sine and cosine are the same function staggered.
