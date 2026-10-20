# What each instrument keeps

15 October 2026. This trial responds to Palle's full reading of “What chance is allowed to do.” Room and final remain in the same thirteen-stop order, with the doorway between stops seven and eight. The 48-value bench remains the first research pilot.

## Reader evidence

Palle's central observation: “The most interesting recurring action is keeping something while something else disappears.” He identifies the seed's beginning, the book's numbers, the held digit, the measured frame intervals, the Geiger clock's discarded distinctions, the gesture-derived seed and the slot machine's outcome. He reads the prescribed return as the difference between varying inside a rule and changing that rule.

His uncertainties are useful constraints: a saved page can support statistical investigation without establishing physical provenance; appearance, statistical randomness and unpredictability need separating; the gesture-to-seed reduction should be concrete. He proposes revisiting one event through different recording procedures. This is full-text reader evidence, not an observed VR encounter or a controlled comparison between drafts.

## Installed changes

- The live RAND page begins empty. One row arrives from above every 2.5 seconds and existing unheld values slide downward over 0.9 seconds. Touch keeps a cell amber; the stream uses remaining free cells. Touch again releases it. This is an authored simulated stream, not digitisation of the historical RAND table.
- Random Definition opts into `row_stream:true` and `cascade_speed:0.4`. Other uses retain their existing default, and pinned seeded pages remain fully printed and static.
- The final corrects the claim about a saved page, uses the existing HOLD/RANGE frame comparison, explicitly distinguishes three questions about randomness, and describes the gesture encoding. Its preservation motif and the compulsory-return payoff remain. Body length: 782 words.
- Four Final magnet notes and the wall's transition-review description follow the revised text. Existing positions, tags, Tutorial notes, connections and research records are preserved.

## What MOVE / KEEP actually retains

Source inspection of `movement_seed.gd` and `movement_sampler.gd`: samples contain elapsed microseconds, position and quaternion orientation. Positions are rounded at 0.00001 units, quaternion components at 0.000001. Sampling is capped at 60 Hz with actual timestamps, not fabricated catch-up samples. Acceleration is not a directly recorded input. XR poses exclude virtual locomotion; desktop sampling follows the carried object's transform.

The versioned sample record is hashed with SHA-256. Its first unsigned 32 bits are reduced modulo 1000 for the seed. Different records can therefore share a seed. The receipt also retains the fuller samples and hash: the integer is one derived use of a finite, already sampled record, not the complete bodily event.

## Verification and next task

`tests/test_rand_row_stream.gd` passes in headless Godot: top-entry cadence, downward interpolation, held-cell selection, release, reprint, long-frame handling and pinned-page behaviour. Layout verification confirms unchanged positions, no reserved-footprint overlaps, twelve connected walking legs, and the same doorway crossing. `verification.json` and `placement-save.json` retain the installation results. Desktop/VR visual pacing and readability have not been observed.

Next, observe whether the slower entrance makes touching a digit legible without making the whole page tedious. For the text, use one held frame capture at two display ranges, then the same recorded Geiger detections at two clock resolutions. Record what changes and what stays, and whether this creates a question worth pursuing. A repeated movement is a new event; a later gesture comparison should replay one saved sample record through two explicit reduction procedures. That additional control is proposed, not implemented here.

The reader's response supports preservation as a productive connection. It does not establish that every transition succeeds, or that the new definition passage improves the experience. Keep the current editorial judgement provisional and use the next complete reading and encounter to decide.
