# Color Mixing & HSB

RGB decomposes light into three channels. Additive — not pigment, not intuition. Red plus green equals yellow, which no painter would believe. The screen doesn't mix. It stacks intensities.

`mix()` interpolates between two values. Two colors become a gradient — a continuous field of in-between states. Linear by default. Feed it `smoothstep()` and the transition bends. Feed it `sin(UV.x * TAU)` and the gradient repeats, wraps, breathes. A rainbow from arithmetic.

HSB reframes the question. Hue is an angle — a circle, not a line. Saturation measures distance from grey. Brightness measures distance from black. Same color, different coordinate system, different assumptions about what "between" means. RGB asks how much of each primary. HSB asks where on the wheel, how far from center, how close to dark.

Every pixel computes its own color independently. The gradient is not drawn — it is *derived*. Math doesn't represent color. Math *is* color. The screen is proof.