# The Conservation of the Irreducible

> A theory note in the apparatus. The criticism lives beside the work; the
> prose is waged, the note may say everything. This one records the argument
> that the Galton-friction artifact walks: that digital bias is not a defect
> to be removed but a conserved quantity to be *located*, and that the machine's
> only real freedom is where to put the pile.
>
> Status: argument, open to refutation. Where a claim is literal physics it is
> marked *rigorous*; where it is transfer-by-analogy it is marked *analogy*.
> The distinction is load-bearing — the room must be able to refuse a resonance.

---

## 1. The method: close reading the machine

The project's thesis — inference is compression is entropy; the queer is the
irreducible (the short seed with a costly run) — is abstract, and abstract
claims do not teach. They become demonstrable only at a **seam**: a place where
the digital substrate fails to perfectly counterfeit the continuous or infinite
thing it is standing in for, and the failure is *legible*. Close reading the
machine means finding those seams and either showing them or letting the player
cross their threshold.

Every seam has one shape. The machine promises the **continuous / infinite /
real**, cannot afford it, and ships the **discrete / finite / cheap** — and the
substitution is invisible until you push past a threshold that was engineered to
sit just out of reach.

## 2. The map of seams

Each is a station a player can cross a threshold at. The crossing is the lesson.

| seam | promised | shipped | cross the threshold by |
|---|---|---|---|
| **randomness** | fair independent chance | a formula chewing a seed | setting the seed twice — the "random" walk traces itself |
| **the line / the drawn point** | a continuous path following the hand | a staircase of samples (space *and* time quantized) | dropping the sample rate, or zooming into the float lattice |
| **color** | the spectrum | 3×8-bit lattice; out-of-gamut clamped, not dimmed | a smooth gradient (banding); a spectral color that has no address |
| **time / physics** | continuous motion | a fixed timestep; between steps nothing exists | a fast event that tunnels through a wall |
| **number** | the real line | floats: dense near zero, sparse far, `0.1+0.2≠0.3` | translating far from the origin — the world jitters |
| **infinity** | endless self-similarity | a depth cap | zooming a fractal to the level where it simply stops |
| **the surface** | a smooth curve | marching-cubes guesses between grid samples | detail finer than the sample spacing — gone |
| **the horizon** | a world that is there | only what is observed is computed (cull / LOD) | looking away and back |

The randomness seam is the built exemplar (`galton_friction`): **the harvest**
(real physics, expensive, lumpy, never repeats) beside **the crank** (pseudo,
cheap, perfect, same seed same bell). The point-that-follows-the-hand is the
next clearest, and it is quantized twice — in space and in time — so the
"digital line" is not a line but a decision to stop looking between the samples.

## 3. The counter-argument (which is the hinge, not the refutation)

Mostly we do not need to think about any of this, and that is true. Every
substitution is engineered to sit **below perception**: 8-bit color is below the
eye's discrimination, 90 Hz is above flicker-fusion, the Mersenne Twister's
period is 2^19937 (no run exhausts it), float precision near the origin is finer
than any headset can display. The craft of the machine is to place each seam one
notch below where you would catch it. A crank bell is genuinely indistinguishable
from a real one for any purpose short of cryptography or philosophy. "Good
enough" is the honest engineering position and it is almost always correct.

The turn: **the machine does not remove the bias, it hides it below perception —
and below perception is exactly where power operates unexamined.** The seed that
owns your "random" walk; the gamut that forecloses colors you will never grieve
because you never met them. Ideology is defined as what you do not have to think
about. So the counter-argument is not the thesis's refutation; it is the
*condition* the thesis is about. The seams that matter are the ones you have to
*choose* to see.

## 4. The dialectic: the bias has a direction

The bias is not aesthetic or accidental. Read the map's third column: formula
for physics, samples for continuity, 24 bits for the spectrum, a depth cap for
infinity, a grid for the continuum. Every substitution flees the same thing —
**computational expense.** "Convenience" and "processing power" are not two
options; they are one axis. Convenience is low cost made into a default.

The precise name for what is expensive is **Kolmogorov complexity**: the length
of the shortest program that produces a thing. Real randomness is *maximal*
Kolmogorov complexity — incompressible, no short description. The true continuum,
infinite depth, the full spectrum: all incompressible, all expensive. So the
machine's bias is exactly **a bias toward the compressible, away from the
incompressible** *(rigorous — this is what "computationally cheaper" means)*.

Which is the thesis restated as a force: **compression is not a tool the machine
uses, it is the slope the machine sits on.** Everything rolls toward the short
description. The irreducible is pushed to the margin not by malice but by
gravity — it costs too much to keep. The bias against complexity *is* compression
as physics.

Dialectically:
- **thesis** — the machine offers you the ideal (a line, a bell, a color).
- **antithesis** — it cannot afford the ideal, so it ships the cheap counterfeit.
- **synthesis** — the counterfeit is tucked below perception and becomes the
  unexamined ground: the ideology of the smooth.

## 5. The law: the conservation of the irreducible

The sharpest question: *does one bias upheld somewhere create bias somewhere
else?* Yes — and it is a law, not a metaphor. Three principles converge:

1. **Computation cannot create entropy** *(rigorous — data-processing
   inequality + Kolmogorov).* A deterministic process cannot increase genuine
   randomness beyond its own description. A PRNG's flood of output has true
   complexity ≈ |seed| + |algorithm| — tiny. The apparent entropy is a **loan
   against the seed**, and the interest is reproducibility. The randomness you
   see is randomness you do not have.
2. **Landauer's principle** *(rigorous — literal thermodynamics).* Erasing one
   bit — making something clean, ordered, certain — costs at least kT·ln2,
   dumped as heat. Local order is bought with global disorder, provably.
3. **No-free-lunch / the bias–variance tradeoff** *(analogy — statistics, not
   thermodynamics, but the shape transfers).* You can relocate inductive bias;
   you cannot remove it. Flatten the error here and it swells there.

Together: **entropy and bias are conserved. You can move them and fake them; you
cannot make them vanish.** Every place the machine hands you something uniform,
fair, smooth, or precise, it has paid by shoving the non-uniformity somewhere you
are not looking — into the seed (randomness), into heat (Landauer), into the
gamut's excluded region (color), into the holes between samples (the line), into
the culled dark (LOD).

The consequence that dissolves the naïve question: the clean crank-bell is **not
less biased** than the lumpy physics-bell. It has *moved* its bias into the seed,
where it is invisible and ownable. The lumpy bell wears its bias on its face; the
clean bell hides its bias in the algorithm. **Same total bias, opposite
honesty.** The choice is never biased vs unbiased. It is **worn bias vs hidden
bias.**

Name for the arc: **the conservation of the irreducible.** You cannot compress
anything for free; the incompressibility you squeeze out *here* reappears
*there* — as heat, as a seed, as a foreclosed region, as a hole between samples.
The bias landscape is a conservation field, and the machine's only freedom is
where to put the pile.

## 6. The ethic

It falls straight out of §5: **prefer the worn; show the seam.** The harvest is
more honest than the crank not because it carries less bias but because its bias
is on the outside. This is the same politics the grid already states
structurally — *the standard says how we meet, never what we are* — now given a
physical law underneath it. An artifact earns its integrity by wearing its
substitutions where the player can see them, not by hiding them below perception
and passing the counterfeit as the real.

This is also the Sieve's third question made rigorous. Q3 asks *what lives in the
dark spot — what the encoding hides.* The conservation law says the dark spot is
never empty: whatever a clean surface refuses to hold has been pushed into it.
To read an artifact is to find where its pile was put.

## 7. How it walks (future work, not yet built)

- **The bias landscape** — a walkable map, one station per seam (§2). Each
  station lets the player *cross the threshold*: slow the clock, zoom the float,
  deepen the fractal, hold the seed. Most stations sit below perception until
  you choose to look — which makes the counter-argument (§3) physical: you have
  to elect to see the seam.
- **The conservation demonstrator** — one artifact where cleaning a thing here
  *visibly* dumps mess there: flatten a histogram and watch banding bloom;
  perfect a bell and watch the seed-lock appear; sharpen one region and watch
  another blur. The player feels §5 instead of reading it.
- **The helmet harvest** — a real `hardware_entropy_decay` bench that imports
  physical entropy from the headset (IMU low bits, camera shot noise, controller
  jitter, clock crossings): the crank's opposite, chance drawn from your own
  tremor, unreproducible and unowned. The blog *The Crank and the Harvest*
  specifies it.

## Provenance — the artifacts that already say this

- `galton_friction` — the harvest / crank, side by side (the built exemplar).
- `coin_toss` — the result read from physics orientation, never a `randf()`; the
  `p = 0.5` lives only on the label. The code honester than the claim.
- `provability_sorter` — rolls `randf() < 0.28` because a working sorter would be
  Turing's forbidden decider: when the honest mechanism is impossible, inject
  randomness and *show the injection*.
- the point / drawn line — the continuous hand quantized in space and time.

Blog: `/blog/2026-07-12-the-crank-and-the-harvest`. Thesis background:
`/blog` on compression and the queer as the irreducible.
