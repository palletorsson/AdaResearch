# A controlled difference in a three-dimensional field

CA_SoftRules separated local reaction from neighbour exchange. This hall holds two 11³ volumes under the same update and forcing schedule, changing one cell in B. It prepares Fractal_Recursion by distinguishing locally accumulated form from an explicit instruction to repeat.

The placed `self_organization_ca#study:difference` mounts `difference_study.gd`; its model is `difference_model.gd`. The legacy 64³ showcase remains available without this configuration. This study changes the domain size and uses a reproducible forcing schedule rather than independent calls to the global random generator.

Each volume is a PackedFloat64Array, indexed `x + 11*y + 121*z`. A scattered beginning is the explicitly authored arithmetic sequence `(i*73+i*i*19+17)%10`; a uniform beginning stores four. B starts as an exact copy, then address (5,5,5) receives +1 if ONE CELL is enabled. The scattered centre is seven, so this intervention remains within the allowed range.

The next value combines the previous cell, the mean of its valid 26-neighbour Moore neighbourhood, and an address/update-indexed forcing value. Outside positions are omitted; there is no periodic wrapping. The corner averages seven neighbours. Both arrays are double buffered.

```gdscript
var drive:float=disturbance*sample(i,tick)
var va:float=clampf(a[i]*(1.0-coupling)+sa/neighbours[i].size()*coupling+drive,0.0,9.0)
var vb:float=clampf(b[i]*(1.0-coupling)+sb/neighbours[i].size()*coupling+drive,0.0,9.0)
na[i]=float(int(va)) if integer_storage else va
nb[i]=float(int(vb)) if integer_storage else vb
```

The schedule `sample(i,tick)` uses bounded integer arithmetic and 2,001 possible values from -1 to 1. It is a reproducible forcing construction, not a claim of independent random samples. No state-dependent random draw is consumed in one run alone.

PULL ranges from zero to one in quarters; DRIVE ranges from zero to four in units. SEED, STORE, ONE CELL and these parameter controls reset both fields. REPLAY preserves parameters and reconstructs the beginning. STEP performs one synchronous update; +10 schedules at most one update per eligible display frame with a 0.12-second minimum interval. Slow rendering stretches the wall-clock duration without inserting extra generations. The observation stops at 100 updates.

The readout counts addresses with `abs(a[i]-b[i]) > 0.000001`, reports the maximum and the mean absolute difference, and prints the display gain. Fractional averaging with matched forcing and clipping is non-expansive in the maximum difference for 0 <= PULL <= 1: a convex combination cannot exceed the old maximum difference, and clipping cannot increase it. Finite precision remains part of the implementation. Integer truncation adds discontinuous thresholds. A count of differing addresses is not a Lyapunov exponent or an entropy measurement.

Volumes show every address as a separated cube. Three wall cases show the selected spatial Z slice. The third case and the floor share the same difference texture. Its gain is `1 / max(max_difference, 0.000001)` and is explicitly printed; A and B use a fixed 0..9 palette. Z SLICE and COAT do not advance time or edit stored fields. The museum floor and passage remain solid.

The source's older lambda coupled neighbour pull to disturbance. It is not Langton's rule-table lambda. Neither that dial nor these new measurements classify this finite run as a universal critical regime. For the historical claim and a re-examination, see [Mitchell, Hraber and Crutchfield (1993)](https://csc.ucdavis.edu/~evca/Papers/rev-edge.html).

The four secondary works are retained. The disease preview computes the original full 64³ synchronous transition over 1,024 display frames and keeps its four-cell display stride; it does not show every infected address. The fog uses a configured 12³ preview and shows a labelled central Z slice in the compatibility renderer. Neither secondary is evidence for the primary's matched-run results. Their wider pedagogical and headset reviews remain open.

## Walk through the receiver

This map adds `#slice:walk` to the existing paired study. `walking_slice.gd` reads a recognised player body between the volumes. Eleven depth positions match the original cube centres: local Z = 0.25 + 0.27 × index. Gold frames locate that same plane in both arrays. Small markers remain at the floor image's edges, so the Z locator is not mistaken for a row of the X/Y image.

The receiver calls `select_spatial_slice`, which changes only slice_z and repaints the existing textures. It never calls the console action dispatcher, resets the model, advances an update, consumes a forcing value, or cancels a pending +10 run. The wall cases and floor retain their shared material. The floor image lays the selected X/Y section flat; physical walking in Z selects which section is shown.

The reader recognises XRToolsPlayerBody and the museum's grouped CharacterBody3D, rejects loose rigid bodies, and releases a visitor on exit. A 2.5 cm dead band beyond a row midpoint reduces flicker near an edge. When the visitor leaves, the selected slice stays; the original Z SLICE button remains available. No solid collision or new support is added, and unconfigured studies retain the original behaviour.

At update zero, the intervention is in Z=5 only. Walking from five to six can hide it from the selected image while the paired arrays, update count and global difference count remain unchanged. This differs from integer storage actually removing it on the first uniform, unforced update. The native probe checks both cases separately.


## Complete learner reconstruction — 8 October 2026

`tutorial.md` prints `paired.gd`, `difference.gd` and unchanged `point_body.gd`, maintained under `doc/book/studies/cellular-automata-through-the-hands/CA_EdgeOfChaos`. The existing Day Zero `PointStudy` host supplies player, camera, lighting and XR Tools. The model owns the two fields; the display constructs all study geometry, textures, labels, support and input. The carried class is byte-identical to CA_AgentsCircuits. No prepared study children are required.

The compact model deliberately starts uniform, with DRIVE zero, PULL .25 and integer storage, making the first prediction legible. The installed desk starts scattered with DRIVE one; the lesson explicitly sets the controlled comparison before comparing outcomes. Both store PackedFloat64Arrays. INTEGER means an explicit int conversion before storage, not an integer array type. The supplied forcing schedule matches production exactly but is not presented as independent random sampling.

The first fractional update changes 27 addresses; the peak falls to .75. At generation 20 in the native controlled run, all 1331 addresses exceed the count threshold, the peak is 0.014009955316666, and the display gain is 71.377815089. This run spreads and weakens the difference. The count threshold is 1e-6. A/B colours use a fixed 0..9 range; only the difference image uses its declared reciprocal-maximum gain. The mean of the entire field is not promised to be conserved at the finite boundary, where neighbour counts differ.

The independent edit changes the intervention site to (0,0,0). The first fractional update then affects eight addresses: corner .75, receiving edge at (1,0,0) gets .25/11, receiving interior (1,1,1) gets .25/26. The changed corner itself has seven neighbours; each receiver uses its own neighbour count. No wrapping is introduced.

The installed walking branch now mounts `difference_hand.gd`, with the existing PointBody on a short rail beside the console. Held local Z chooses a slice. The walking receiver yields while it is held. Trigger calls the existing STEP operation, including cancellation of a pending +10 budget. Moving the point calls only select_spatial_slice and preserves that budget. Release invalidates the walker's previous band so a body still standing in the receiver resumes selection immediately, then the point parks at that slice. This changes selection and input priority, not the solver. Unconfigured studies keep their original behaviour.

The compact reconstruction has the same held-point selection and trigger; Enter steps, R replays, I switches storage, C toggles the intervention, P switches pull zero/.25, N toggles drive zero/one, B switches the seed. Parameter keys reset the fields. The installed desk supplies its existing VR controls, wider parameter ranges, walking reader and floor image. Those differences are declared.

All five authored artifact tokens and placements remain unchanged, as does the level floor. The extra generic gate is disabled and entry/exit move to source(9,0)/(9,29). Only this hall's generated plan row is rederived. Native route tests follow the console, body reader and rear gallery before reaching the exit.

Validation: 35 exact-printed-code and 43 museum checks pass in native Godot 4.6. All values in 120 paired source updates across six settings match exactly. The corner transfer runs the actual edited file. Two deliberate defects—different forcing in B and writing B in place—are detected. Checks cover old-array independence, thresholds, full instance transforms, support, texture gain, control resets and limits. Supplied XRTools poses test pickup, selection, trigger and release in a rotated/translated learner study and in the museum. A real CharacterBody overlap tests walking, dead band and hand/body priority. Four routes contain 348 layer-1 capsule and level-floor samples; portal approaches are supported.

Nine native after images and five before images record the real hall. The learner model is temporarily mounted only for its photograph. Final logs contain no SCRIPT ERROR or Parse Error. The source model and wrapper remain byte-identical to the baseline. No physical headset, Quest performance, full portal transfer, independent student acceptance or complete secondary interaction audit is claimed. Existing blank frames and rear billboard labels drawing through the main view remain visible.
