# Current hall: a slow pulse from fast motions

`beat_frequency_demo` is the primary. Its two controls set frequencies from 1 to 10 Hz. The three rows show A, B and half of their raw sum. Close frequencies give a slow envelope; equal frequencies remove the beating in this fixed-phase demonstration. The display is visual only. See [the chapter](final.md) for the encounter and `algorithms/wavefunctions/beat_frequency/beat_frequency_demo.gd` for the implementation.

The secondary `TrigWalkingPath` remains in the room. Its shipped scene creates forty pairs of collidable steps once, adds end platforms, then circulates the two rows in opposite directions. Their heights combine a shared sloping base with sine or cosine. There is no visitor-triggered generation, cross-bridge or linked chart in that source. The other secondary works are `sine_oscillation`, `lissajous_curves` and `wave_interference`; `dark_sphere` remains the reference object. The next hall compares five fixed harmonic frequencies in the Synthesis Lab.

## Archived design proposal

The text below is preserved from an earlier design. Its endless generation, cross-bridge, entrance controls and linked chart are proposals, not descriptions of the current hall. Its code is illustrative, not an extract from the shipped artifact. The current chapter and the source named above take precedence.

---

Concept: Sine and cosine as parallel walking paths — two lanes of steps rising and falling according to trigonometric functions, where each footfall lands on a computed position and the path generates itself ahead.
Sequence role: Eleventh map in Wavefunctions; the penultimate map. After Sky_Stairs' vertical wave climbing, this map returns to horizontal traversal but with both sin and cos visible simultaneously. The dual-path design makes the phase relationship between sine and cosine (90° offset) physically walkable. Connects to the Synthesis Lab's decomposition thesis by showing the two fundamental components side by side; follows Wavefunctions_Sky_Stairs; leads to WaveFunctions_Synthesis_Lab.
Technical angle: TrigWalkingPath generates stepping surfaces at sin(x) and cos(x) positions along a walkable path. The 90° phase offset between the two lanes is visible as one lane peaking while the other crosses zero. Procedural path generation — the path extends as the learner walks, demonstrating that the function is infinite.
Critical angle: Walking sin while seeing cos (or vice versa) makes the phase relationship between the two functions embodied knowledge. The body learns what the equation states: cos(x) = sin(x + π/2). The procedurally generated path — extending ahead, never ending — is the spatial metaphor for periodicity: the wave has no destination, only continuation.
Key artifacts: TrigWalkingPath generates the dual sine/cosine walkable lanes; dark_sphere anchors the space.
Gap: An overlay showing the unit circle rotating as the learner walks — connecting the path position to the angle on the circle — would unify this map with the Unit Circle map's core lesson.
