# Compare what remains uncertain

Random Definition introduced a stored beginning and different uses of the same numbers. Here we choose what an observation records, then test which differences that record can retain. Entropy Types precedes Entropy Workshop: its seven encounters establish distinct questions before the workshop changes and preserves more complex arrangements. Room and final text keep the same order.

Most comparisons remain visible together. Two now have small controls: the door pairs advance together, and the last four tables let us make a guess, draw and change the population. The **48-value seed bench remains the first research pilot**. These studies extend its experiment cycle rather than replacing it.

## The experiment cycle

1. Establish a baseline: record the artifact, parameters, declared outcomes, source revision and relevant seed/state.
2. Predict what changing one condition would do. Include the possibility that a reading will stay unchanged.
3. Make the change; compare the objects and the readings. Record the result, including confusion or an invisible difference.
4. Preserve the configuration and state using the code receipts below, or record the small baseline by hand on the research wall. There is no in-room receipt gallery for these studies.
5. Reset or restore and repeat. Replaying a stored result is different from acquiring a new unpredictable outcome.
6. Reconstruct the small rule independently. Match the baseline before changing it.
7. Use the observation to propose another measurement or alteration to the apparatus. State what it would let us distinguish.

An automated reconstruction checks the implementation. It does not establish that a student can reconstruct it or that the encounter produces a useful question. Those are separate trials.

## Begin with the chair colours

Four groups contain eight full-size chairs each. A and B both have four pink and four black chairs in different places. C has seven pink and one black; D has eight pink. Imagine a uniform draw of one chair ID, returning it, and recording colour. This opening display does not draw a chair; the last encounter will.

Build the counting function before building furniture:

```gdscript
func uncertainty(counts: Array) -> Dictionary:
    var total := 0.0
    for count in counts:
        assert(count >= 0)
        total += count
    assert(total > 0.0)
    var h := 0.0
    var best := 0.0
    for count in counts:
        if count > 0:
            var p := float(count) / total
            h -= p * log(p) / log(2.0)
            best = maxf(best, p)
    return {"shannon": h, "best": best,
            "min": maxf(0.0, -log(best) / log(2.0))}
```

For `[4,4]`, `[7,1]` and `[8,0]`, Shannon entropy is 1, about 0.544 and 0 bits. Changing positions while holding counts fixed leaves this reading unchanged. Change the recorded answer to one of eight equally likely IDs instead: its entropy is 3 bits whatever the colours. The answer space is part of the experiment.

## Seven encounters, seven questions

| Encounter | First comparison | Reconstruction and limit |
| --- | --- | --- |
| Shannon | Same counts in different places; then different colour shares | Rebuild the count function above. No visible-disorder score is used. |
| Boltzmann | Four pink/four black on eight fixed sites; compare four pink on the left with two on each side | Ω(k)=choose(4,k)×choose(4,4−k). Same-colour chairs are interchangeable. Counts 1 and 36 give S/kB=ln Ω of 0 and about 3.584. This finite counting analogy does not measure furniture's thermal entropy. |
| Algorithmic complexity | Grid, one edit, repeated motif, seeded scatter | `Model.chairs(435, group)` reconstructs six-chair groups. Include the seed and generator in a candidate description. Apparent irregularity does not prove a long shortest program; the displayed recipes are not certified minima. |
| Dynamical behaviour | Two nearby starts, halving versus doubling and wrapping | Advance both with STEP; read the two LOW/HIGH histories. Compare them with a separate ensemble of 1,024 starts, described below. |
| Thermodynamic entropy | Five cups on one table, at model times 0, 5, 15, 30, 60 seconds | C₁=400 and C₂=4000 J/K; T₁=353 and T₂=293 K initially; timescale 15 s. Energy C₁T₁+C₂T₂ stays fixed. Each ΔS=C ln(T/T₀); the cup loses entropy and the bath gains more. Animated surfaces all prescribe 25% milk at different mixing stages. They do not calculate heat entropy or simulate diffusion. |
| Conditional entropy | Five panes with different frost and explicit record channels | Eight equiprobable identities: colour × arms × lower back rail. Identity, colour+arms, colour, colour, no detail leave 0,1,2,2,3 bits unresolved. Two different panes deliberately retain the same record. Human visibility through the shader is not measured. |
| Min-entropy | Four sixteen-chair tables: compare the best guess with average uncertainty | Choose a type before DRAW. Uniform ID selection with replacement holds the population fixed. CHANGE ONE alters it. A and B share Hmin=1 but have different Shannon entropy. Rearranging D preserves its certain colour answer. |

## Build a door rule

Use a normalised angle `x` between 0 and 1, mapped onto a quarter turn. A solid and a translucent leaf have the same rule but slightly different starts. Copy this small function into a separate study:

```gdscript
func door_step(x: float, expanding: bool) -> float:
    return fposmod(2.0 * x, 1.0) if expanding else x * 0.5

func history(start: float, steps: int, expanding: bool) -> Array:
    var x := start
    var result: Array = ["H" if x >= 0.5 else "L"]
    for i in steps:
        x = door_step(x, expanding)
        result.append("H" if x >= 0.5 else "L")
    return result
```

The installed solid starts at 0.8; the ghost at 0.8 plus the gap. GAP offers 0, 1/1024, 1/512 (default), 1/128, 1/16 and 0.1. Changing the gap returns to step zero. RESET retains that gap. STEP advances both pairs, stopping at 15; there is no automatic restart. The central passage remains open.

First use gap 0.1 to reconstruct the user's example: halving sends 0.8/0.9 to 0.4/0.45, then 0.2/0.225. The gap halves at every step. Reset to 1/512. Under doubling the gap initially doubles, but wrapping can reduce it; the pair rejoins at step nine. Set gap zero as a control: identical starts stay identical under either rule. No random input is required.

The initial state is already an observation. Step 7 therefore shows **eight symbols**, not seven. Rebuild the ensemble by starting at `(i+0.5)/1024.0` for each `i` from 0 to 1023, generating a LOW/HIGH word, counting identical words, then passing those counts to `uncertainty()`. At eight symbols, record entropy is 1 bit for halving and 8 for doubling. At ten or more symbols, this doubling ensemble reaches 10 bits and stays there: only 1,024 starting states were supplied.

Do not calculate this ensemble reading from the two displayed leaves. They show sensitivity of individual trajectories; the ensemble counts possible records. For an ideal doubling map with a uniform continuum of starts, this binary partition reveals one bit per iteration. The finite midpoint experiment and floating-point implementation do not establish that asymptotic rate. Halving's disappearing distinctions also do not make it a thermodynamic cooling experiment.

Research extension: preserve the step where the pair first appears to separate and the step where it rejoins. Change only the starting gap. Does the retained history distinguish paths that the current angles no longer distinguish?

## Build one guess

Every table contains sixteen miniature chairs. All are drawn under the same category definition, colour and presence of arms; A, C and D simply have no armchairs.

| Table | Pink standard / black standard / black with arms | Best chance | Hmin | Shannon H |
| --- | --- | --- | --- | --- |
| A | 8 / 8 / 0 | 50% | 1 bit | 1 bit |
| B | 8 / 4 / 4 | 50% | 1 bit | 1.5 bits |
| C | 12 / 4 / 0 | 75% | ≈0.415 bits | ≈0.811 bits |
| D | 16 / 0 / 0 | 100% | 0 bits | 0 bits |

Predict PINK, BLACK or (at B) BLACK+ARMS, then press DRAW. A gold ring identifies the selected chair and the strip reports the result. The ID is immediately eligible again, so the selection is with replacement; the counts never decrease. One draw cannot establish a probability from observation.

On A–C, CHANGE ONE converts a black chair to pink. At B it converts an armchair first, until those are exhausted. Both readings then follow the changed inventory. RESET restores the table's original counts, positions and generator seed 435. Each table has its own generator starting at 435; matched draw counts select matched IDs, while their categories can differ. DRAW requires a guess before the first selection; the choice remains active for subsequent draws until changed.

Reconstruct sixteen stable IDs whose category array contains eight 0s, four 1s and four 2s. Draw an ID using a private `RandomNumberGenerator`:

```gdscript
var rng := RandomNumberGenerator.new()
# Set this once at the beginning or when explicitly resetting.
rng.seed = 435
var selected_id := rng.randi_range(0, 15)
var answer: int = categories[selected_id]
# Keep categories unchanged: the selected chair remains available.
```

The displayed readings follow the stipulated uniform-ID category model, not a statistical estimate from these seeded draws. Knowing the source and generator state can predict the next ID. These readings do not demonstrate cryptographic unpredictability. RESET repeats a sequence; it does not obtain new entropy.

Now compare A and B with the count function. Splitting the black half leaves the maximum probability at 1/2, so Hmin stays 1. If the record instead keeps only colour, merge B's black counts and obtain `[8,8]`: Shannon H returns to 1. Preserve which record was used alongside any number.

At D, pick up, turn and place the chairs. Released chairs settle upright on their own tabletop and retain their turn. RESET restores their places; release a held chair first. The colour prediction remains certain. Propose a record that would notice one of the changes just made, without treating spatial change itself as entropy.

## Preserve and reconstruct a state

The active scripts are `door_study.gd`, `one_guess.gd`, `guess_table.gd` and `guess_model.gd` in `commons/artifacts/ordinary_entropies/`. The public last-stop ID remains `entropy_ball_pit` to preserve map placements, but its scene now loads chairs. Earlier `best_guess.gd` ball receipts remain available for historical reconstruction; they are not accepted as chair-table records.

`door_study.capture()` stores the gap index, step, fixed start and observation partition (`door-pairs/1`). `guess_table.capture()` stores sixteen category IDs, original counts, current choice/result, draw count, generator state and chair positions/turns (`one-guess-table/1`). It returns an empty dictionary while a chair is held. Drop the chair before capturing.

In a research script holding a reference named `study` to the door or one table:

```gdscript
var record: Dictionary = study.capture()
assert(not record.is_empty())
var file := FileAccess.open("user://entropy-study.json", FileAccess.WRITE)
assert(file != null)
file.store_string(JSON.stringify(record, "  ", true, true))
file.close()
# Later, using the same artifact and (for chairs) the same baseline table:
var recovered: Variant = JSON.parse_string(
    FileAccess.get_file_as_string("user://entropy-study.json"))
assert(study.restore(recovered))
```

Save the source revision/hash and Godot version beside this file; a receipt does not bundle its generator. The full-precision JSON option preserves pose values. Generator state is stored as a decimal string to avoid rounding a 64-bit integer. Restore validates schema and bounds before changing the installation. Chair pose comparisons allow floating-point tolerance; the next seeded IDs must agree exactly. Compare several further draws after restoring, rather than only the last highlighted chair.

The other five scene wrappers still use `comparison.gd` and control-free `encounter.gd` copies. For those independent reconstructions set `kind`, `setting`, `experiment_seed`, `seconds` or `steps`, then call `rebuild()`. Cups also expose `mixing`, `milk_fraction` and `cup_table_enabled`; glass exposes visual `glass_obscurity` separately from record `setting`. Their earlier capture/restore schemas remain. Returning to a cooling snapshot is a digital reconstruction, not physical reversal.

## Leave a question on the research wall

The independent partition after the first chairs holds a framed explanation, an image slot, a whiteboard and three sticky notes. Pick up the dark or red marker and touch its nib to the board or note. Lift it to break a stroke; use the eraser locally. Move and release a note near the wall to pin it. Writing and pinned positions save locally after a short pause. The image can change without erasing the notes.

Keep a prediction, actual observation and proposed next change together. For doors, record gap and step as well as LOW/HIGH history. For chairs, record the category definition as well as counts. These notes preserve an observation; they do not automatically preserve an apparatus receipt or prove learning.

Current [native evidence and reading trial](../../../doc/book/iterations/2026-10-16-doors-and-one-guess/index.html) separates model tests, installed-room checks and the pending learner/headset trial. Entropy Workshop next tests what these readings omit, through SORT, jars, compartments and material arrangements. The first 48-value seed bench remains the first research pilot.
