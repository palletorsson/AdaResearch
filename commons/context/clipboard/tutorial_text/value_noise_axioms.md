**Value Noise**
Grid-Based Random Interpolation

**Value noise** is the simplest coherent noise: random values at grid points, smoothly interpolated between.

Cheaper than Perlin, but with visible artifacts. The tradeoff between cost and quality.

---

## The Grid of Random Values

**Core concept:** Place random values at integer coordinates, interpolate smoothly.

**Code: 1D Value Noise**

# Hash function: integer → deterministic