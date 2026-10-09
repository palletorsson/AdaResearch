# Random_Gaussian — Summary

What can many draws reveal that one draw cannot? A long hall in two halves. The north half holds the Gaussian applied elsewhere — a blur shader, a paint splatter, a blur circle — and a dark reference sphere; the south half holds the draws: a walkable mound in the shape of a bell in the south-west, a comparator racking three laws side by side, a Galton board dropping beads through pegs by the south door, and, against the east wall, the primary: a histogram on a dark cabinet with beads raining onto its bars, a plate of six lines under it, and two panels at hand height.

GAUSS is running when the visitor arrives. PAUSE, CLEAR, and a dozen beads make a lopsided picture that the plate counts honestly; BATCH lands a hundred at once and the hump appears with a gap in it. Behind every bar a pale frame stands at the count the law expects for that bin at this many draws, with the mass beyond the display folded into the edge bins. UNIFORM at the same count gives thirty frames of ten and bars wandering round them; EXPON puts the tallest bar at the left edge and a quarter of a percent past the right. CLEAR replays the seed the plate names; NEW SEED names another; BINS re-bins the same draws through sixty and ten and back to thirty without drawing again. The density curve over the bars keeps its own scale and never moves with N.

## Spatial layout

- **Dimensions**: 14 × 22 cells, walls on the perimeter, doors at columns 5–7 on the north and south edges.
- **The north hall**: rows 2–13, floor, with the recovery's nineteen platform cells a metre up along the sides and stepped walls where the sides rise.
- **The south hall**: rows 14–20, floor since this hall was staged; until then it was `0`, which the museum read as holes — a void with a one-cell strip of floor down column 7, the primary half a metre up with its keypad under the floor, and a twenty-metre bell terrain over everything.
- **The route**: north door → the north hall → the south hall's middle → the south door; the sampler's spot is off the middle to the east, the mound to the west.

## Key elements

- **distribution_sampler** (11,19), facing north: the primary. The cabinet (0.95 m), the histogram on top, the keypad and the stand panel outboard on a shoulder at 0.755 m, the readout at 0.90 m between them, ghosts behind the bars, a named seed.
- **distribution_comparator** (5,18): three laws side by side at one sample count.
- **galton_board** (9,20), at one and a half times bench scale: beads through pegs into bins, by the south door.
- **random_bell_curve** (3,17), at a third of its size: a 6 m Gaussian mound, 1.5 m high, walkable.
- **gaussian_random** (10,15): a bell drawn by a generator, north of the visitor's spot.
- **GaussianBlurShader** (3,2), **GaussianPaintSplatter** (8,6), **GaussianBlurCircle** (11,8): the law applied to pixels and marks. **dark_sphere** (7,10): a reference body.

## The encounter

1. Enter from the north; walk the north hall past the applications.
2. Cross into the south hall; the mound on the right, the comparator, the cabinet ahead on the left against the east wall.
3. PAUSE, CLEAR, twelve beads: say what is there. BATCH three times: a hill with a gap.
4. Read the frames behind the bars; find bars over and under.
5. UNIFORM at the same count; EXPON for the fold at the edge; POISSON for a lattice.
6. CLEAR twice with a batch after each: the same histogram. NEW SEED: another. BINS round the cycle: the same draws, three pictures.
7. The Galton board by the door; out.

## Connection to the sequence

Random_Walk separated a step from its sum and from the drawing of the sum; this room gathers many draws into a picture and separates the picture from the law, the sample from its expectation, and the bins from the values. Random_Mushrooms grows a population of forms from draws like these and asks which of its features were allowed to vary.

## Historical context

De Moivre found the bell as the limit of the binomial in 1733; Gauss put it under the errors of astronomy in 1809; Galton built the board in 1873 to make the limit fall into bins by itself; Pearson's chi-square of 1900 is the comparison between a histogram and its expectation made into a number; Box and Muller's transform of 1958 is the two lines in the sampler that turn two uniform draws into one normal one. Quetelet's average man of 1835 is the caution: a frequent region under a model, read as a norm.

## QFEP connection

Constrained entropy: the uniform law spends its draws everywhere, the Gaussian concentrates them, and neither law is visible in one draw. The room's addition is the observer's contract — the count, the bins, the range, the fold at the edge and the normalisation printed beside the picture, so that the shape the many draws make is read as evidence rather than completed in language.

## Sources

- De Moivre, A. (1733). Approximatio ad summam terminorum binomii (a+b)ⁿ in seriem expansi.
- Galton, F. (1889). Natural Inheritance (the quincunx).
- Pearson, K. (1900). "On the criterion that a given system of deviations…" Philosophical Magazine 50.
- Box, G. E. P. and Muller, M. E. (1958). "A Note on the Generation of Random Normal Deviates." Annals of Mathematical Statistics 29.
- `commons/artifacts/distribution_sampler/distribution_sampler.gd`; `commons/maps/Random_Gaussian/field_notes.md`.
