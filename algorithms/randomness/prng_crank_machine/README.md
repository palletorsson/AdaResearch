# PRNG Crank Machine

A physical hand-crank pseudo-random number generator that visualizes the **Linear Congruential Generator** (LCG) algorithm step by step. Each crank press triggers an animated computation: multiply the current state by a constant, add an increment, take the result modulo 2^32. The machine reveals that PRNGs are entirely deterministic -- the same seed always produces the same sequence.

This artifact teaches **pseudo-random number generation** and its fundamental property: determinism masquerading as randomness. Unlike true hardware entropy, a PRNG produces a fixed sequence from any given seed. The step-by-step animation exposes the arithmetic that is normally hidden behind a `randf()` call.

## How It Works

1. **LCG Algorithm**: The generator uses the formula `state = (state * a + c) mod m` where:
   - `a` (multiplier) = 1,664,525
   - `c` (increment) = 1,013,904,223
   - `m` (modulus) = 2^32 (implemented via bitwise AND with 0xFFFFFFFF)

   These are the Numerical Recipes LCG constants, chosen to produce a full-period sequence that visits all 2^32 states before repeating.

2. **Step-by-Step Animation**: When the CRANK button is pressed, the computation proceeds through four timed phases (0.6 seconds each):
   - Phase 1: Show `state * a` (multiplication, orange text)
   - Phase 2: Show `... + c` (addition, cyan text)
   - Phase 3: Show `... mod 2^32` (modulus, pink text)
   - Phase 4: Display final result (green text)

3. **Dual Display**: The main screen shows the current state as both a raw integer and a normalized float in [0, 1) (dividing by 2^32). This demonstrates how integer PRNG output is typically converted to floating-point values.

4. **History Panel**: The last 12 generated values are displayed in a scrolling history, showing the sequence. Resetting to the same seed reproduces the identical sequence, visually proving determinism.

5. **Seed Control**: The SEED button randomizes the initial seed (using true randomness from `randi()`), demonstrating that the seed is the only source of variation -- everything else is fixed arithmetic.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `body_width` | float | 0.4 | Width of the machine housing |
| `body_height` | float | 0.5 | Height of the machine housing |
| `body_depth` | float | 0.2 | Depth of the machine housing |
| `pedestal_height` | float | 0.7 | Height of the support pedestal |
| `lcg_multiplier` | int | 1664525 | LCG multiplier constant `a` |
| `lcg_increment` | int | 1013904223 | LCG increment constant `c` |
| `lcg_modulus` | int | 0 | LCG modulus (0 = 2^32 via overflow) |
| `initial_seed` | int | 42 | Starting seed value |
| `color_body` | Color | (0.12, 0.12, 0.15) | Machine housing color |
| `color_accent` | Color | (0.6, 0.4, 0.1) | Brass accent color |
| `color_display_bg` | Color | (0.02, 0.05, 0.02) | Display screen background |
| `color_display_text` | Color | (0.2, 1.0, 0.3) | Green LED display text |
| `color_formula` | Color | (0.8, 0.8, 0.9) | Formula text color |

## Features

- Step-by-step animated LCG computation with color-coded phases
- Dual display: raw integer and normalized [0, 1) float
- Scrolling history of the last 12 generated values
- Seed display and randomize button to demonstrate determinism
- VR push-button controls: CRANK (generate), RESET (return to seed), SEED (new seed)
- Keyboard controls: Space (crank), R (reset)
- Machine aesthetic with brass trim, decorative bolts, and nameplate "LCG-32"
- Formula display showing the LCG equation and parameter values
- Phase-timed animation prevents overlapping cranks

## Files

| File | Description |
|------|-------------|
| `prng_crank_machine.gd` | Main script -- LCG logic, animation phases, machine construction, VR controls |
| `prng_crank_machine.tscn` | Scene file |
