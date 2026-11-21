# WaveFunctions_Intro — Two Visits to the Same Height

*Floor 62 · Care Unit Model B's working chapter (`void.md`, building on `final.md` and `walked.md`)*

---

## 1. Where linear `lerp` finally gives way to the circle

For sixty-one floors, every rising platform, bobbing coin, and sweeping hazard ran on straight linear interpolation (`lerp`) — constant speed between two stops, reversing with a sharp corner at each end. On Floor 62, the room refuses sharp corners. A body slows as it approaches the top, pauses without resting, turns smoothly, and accelerates back through the middle.

The room itself contains no stillness: the vertical oscillation cube keeps its own clock, the control pendulum swings across its plumb ring and projects a live waveform onto `void_wave_monitor`, the `scale_zoetrope` and `torus_piston` turn rotation into rhythm, `phase_shutters` open and close out of step, and `reactive_wave_wall` answers across the floor.

## 2. Two visits through one frame (`hand-sine-yoke` · `06 · TWO VISITS`)

At the visible **Scotch yoke** (`hand-sine-yoke`), there is no hidden motor and no internal clock. A wooden hand wheel carries a brass crank pin inside a horizontal steel slot; the slot allows sideways travel and forces the vertical guide to carry a timber cube strictly at `y = R * sin(θ)`.

Look through **`OperaFrame06`** (`06 · TWO VISITS`) at the pink horizontal mark (`RailMark`) on the guide rail, then turn the wheel by hand:

1. **Visit #1 — Rising:** starting below the mark (`-25°`), turn the wheel upward past `0°`. The timber cube crosses the pink mark going **up** (`y` moves from negative to positive).
2. **The Crest — Smooth Turn:** keep turning through `60° → 90°`. Notice what your hand feels and your eye sees: the exact same `30°` turn near the middle (`0° → 30°`) lifts the cube nearly four times farther than `30°` near the top (`60° → 90°`). That deceleration is what makes harmonic motion curved instead of linear.
3. **Visit #2 — Falling:** continue past the peak down through `180°`. The cube crosses the exact same pink mark a second time — now going **down**.

*Same height twice. Rising once. Falling once.* — A single photograph taken at the pink mark cannot tell these two moments apart. The height reads zero both times; only direction and phase reveal whether the body is arriving or leaving.

## 3. Clock, hand, and pendulum side by side

Further in, `control_pendulum` returns by a different rule from both the clock-driven `y_oscillation_cube` and the hand-driven `sine_yoke`. It integrates its own state step by step (`angular_acceleration = -(g / L) * sin(angle)`), keeping the velocity your hand left behind when you released the bob. On `void_wave_monitor`, the live curve shows the angle crossing zero twice per swing — once moving rightward, once leftward — echoing the yoke's two visits through the pink mark.

## 4. What carries downward into WaveFunctions

Floor 62 proves with the hand before a single equation is memorized that **position alone is an incomplete measurement**. One height hides two opposite directions; one cycle contains speed changes that linear `lerp` never knew. From here downward, waves will carry frequency, phase, interference, and standing surfaces across the middle tower.

---

*Verified Ghost Student Spine Stop #4 receipt: `doc/book/iterations/2026-11-21-wavefunctions-two-visits/checks.json` (`01-f62-overview.png`, `02-two-visits-rising.png`, `03-two-visits-peak.png`, `04-two-visits-falling-hud.png`).*
