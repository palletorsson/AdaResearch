# Randomness — ghost-student notebook

Author-informed reconstruction, 9 October 2026. Each changed program is a separate copy; the printed version remains intact.


## 1. Definition

The cube and material return as a grid of requests. I swapped red and blue and made a five-by-five picture. Green, addresses and generator state stayed; adding a discarded draw still shifted the stream. A seed identifies a beginning, not a complete recipe.

Prediction: Swapping red/blue keeps every green channel, grid address and final RNG state. It changes interpretation, not requests.

Checks: 36 baseline + 4 transfer. Both passed.


## 2. Entropy

I supplied four blocks of four symbols. Both that arrangement and a cyclic one measured two bits, but their unlike-neighbour counts were three and fifteen. I can explain the lost order without deriving the formula. Sorting a copy preserved the original.

Prediction: Four blocks of four symbols give counts [4,4,4,4], H=2 and three unlike neighbours. The cyclic arrangement has the same counts/H but fifteen unlike neighbours.

Checks: 31 baseline + 5 transfer. Both passed.


## 3. Remove

I replaced the central-square eligibility rule with the diagonal. Eight addresses were removed once each, then the empty guard spent no draw. Equal treatment within a candidate set does not decide who belongs to that set.

Prediction: Only eight diagonal addresses 0,9,18,27,36,45,54,63 are eligible. All appear exactly once; ninth removal returns -1 without spending a draw.

Checks: 30 baseline + 4 transfer. Both passed.


## 4. 10 PRINT

I changed the threshold from one half to three eighths. The same samples now selected a different subset of marks. Twenty-four is the expected count in sixty-four cells, not a required outcome. This lesson does not promise the fixed counts of the separate comparison artifact.

Prediction: At threshold .375 the expected count is24, not a promise. Samples and RNG match .5; no old slash can become a backslash when the threshold falls.

Checks: 25 baseline + 4 transfer. Both passed.


## 5. Cubes

I allowed every even face to continue. The supplied record 2, 4, 3 now totalled nine before closing. Reaching a display limit remained different from drawing a stopping face. I changed what an outcome permits, not the die.

Prediction: With even faces continuing, [2,4,3] totals9 then closes; the original closes after2. A continuing chain reaching the display cap is limited, not closed by an odd face.

Checks: 32 baseline + 4 transfer. Both passed.


## 6. Rotate

I supplied turns of +12, −4 and −8 degrees. The accumulated cube returned to zero while the assigned cube ended at −8. Replay read the record without drawing again. Transformation now carries a history rather than only an angle.

Prediction: The supplied +12,-4,-8 degree record has final latest=-8 and total=0. Replay rewinds the cursor; it does not draw. Assignment differs from accumulation.

Checks: 29 baseline + 4 transfer. Both passed.


## 7. Walk

I halved the step length and compared the first four moves before a boundary could interfere. Displacements halved. Altering an old trail entry did not steer the next step. The distinction between a current position and its record is doing real work here.

Prediction: From the centre, halving step size halves the first four displacements before any boundary encounter. Editing an old trace entry cannot steer the next move. Held time spends no draw.

Checks: 30 baseline + 4 transfer. Both passed.


## 8. Gaussian

I used eight explicit values, including two outside the displayed interval, and changed to six bins. Counts became 3, 0, 1, 1, 0, 3; two values were clipped. Rebinning kept the raw evidence. A changed histogram is not automatically a changed population.

Prediction: Raw [-.2,0,.05,.49,.5,.99,1,1.3] maps to six bins [3,0,1,1,0,3], with two clipped values. Rebinning preserves all eight raw values and RNG state.

Checks: 30 baseline + 4 transfer. Both passed.


## 9. Mushrooms

I reduced the population to seven and widened its scale interval. The retained members kept their recipe, position and turn; each scale deviation from one doubled. SIZE changed expression without rerolling identities. This is variation within a repertoire, not generation of new recipes.

Prediction: Seven members keep the first seven kinds/yaws/positions. Wider .4..1.6 scale doubles each old deviation from1. SIZE changes expression without redrawing the record.

Checks: 32 baseline + 4 transfer. Both passed.


## 10. Space Geometry

I spread the columns farther apart. Their positions changed while sampled records, generator state and neighbour-gap readings stayed. Separate fixtures gave a checkerboard gap of one and a half-plane split of one fourteenth. A display distance and a field-sampling frequency are different controls.

Prediction: Increasing displayed spacing changes column positions but neither record nor RNG nor neighbour-gap readings. Checkerboard gap=1; a half-plane split gives1/14.

Checks: 27 baseline + 5 transfer. Both passed.


## 11. Examples of Randomness

I requested seven darts at a time. The final partial batch stopped at 256 and matched single-step sampling, including every intermediate estimate. The test checked the area ratio and retained samples, not whether one finite run happened to land near pi.

Prediction: Seven-at-a-time and individual requests produce identical samples and every intermediate estimate after256 values. An over-budget request spends no draw. Numerical closeness to pi is not a pass condition.

Checks: 21 baseline + 4 transfer. Both passed.


## 12. Pheromone

I disabled guidance while retaining deposition. Even a strongly uneven scent field then left the path unchanged. With guidance enabled, a first eastward choice returned toward its deposited scent. Here history can enter the next decision; Walk did not do that. The first uniform-field test was too weak and was replaced.

Prediction: With guidance0, corrupting scent cannot change future path or RNG. Visits still accumulate. With guidance1, equal empty neighbours choose east first; the next attraction returns to deposited scent.

Checks: 31 baseline + 5 transfer. Both passed.


## 13. Space

I kept three layers but set persistence to zero. The two later contributions vanished, and changing their frequency ratio could not change the sum. The raw field matched one layer. Comparing raw values matters because independently stretched displays can disguise changes in magnitude.

Prediction: Three layers with persistence0 preserve three parts, but parts2/3 contribute zero, so raw equals one layer. Changing lacunarity cannot change that zero-weight sum. No new draws.

Checks: 33 baseline + 4 transfer. Both passed.


## 14. Game

I shortened advance notice from 1.2 to 0.3 seconds. A sixty-second comparison retained state transitions, support decisions and deadlines. Only the warning interval changed. A future event can already be scheduled while the visitor still lacks useful notice of it.

Prediction: Shorter notice preserves every deadline, state, height, collider-support decision and RNG state. At600ms before first sinking, old cue is on and new cue off; at300ms both on.

Checks: 33 baseline + 5 transfer. Both passed.
