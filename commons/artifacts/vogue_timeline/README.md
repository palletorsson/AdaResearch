# Vogue — a phrase of your own

Endless Museum · `ML_Perception` · 11 October 2026.

In the museum map, the dance and the learning station occupy separate bays in a 30 × 16 metre gallery. Walk around the partition through the broad forecourt into the gold-edged **TEACH / TEST / REVISE** area. Pose, height, phrase and CHECK remain lessons on the same sphere. Dance sits at cell (14,6); the map passes `learning_x:11`, `learning_z:-1`, `learning_yaw:0`, `learning_bay:1` to place the carried station at (25,5). Its scene ownership and local save files stay the same. The default compact scene remains available for isolated tests. Current layout evidence: `tools/probes/ml_perception_large.gd`; earlier layout: `tools/probes/ml_learning_spaces.gd`.

The adjacent **Teach a sphere** station now has three local learning lessons on the same object: [pose classification](LEARNING.md), [continuous height regression](HEIGHT.md) and [a short two-hand movement phrase](PHRASE.md). Each uses visitor demonstrations, separate fresh tests and its own saved model. The dance described below retains its separate reference-matching behaviour.

PHRASE can now continue into [two taught phrases](PHRASE-CHOICES.md): choose A and B, demonstrate each, then test new performances. The same sphere replays the recognised phrase. Unfamiliar and ambiguous movements leave it waiting. ONE keeps the earlier single-phrase activity available.

The next step is [CHECK your intention](PHRASE-CHECK.md): declare A/B/neither, perform, compare intention and prediction in a small table. Tests cannot train. Revised models keep separate counts, and earlier results can be exported with their model and full takes.

Follow a 32-beat hand phrase through sixteen poses, then record your own phrase and dance it back. The pink and cyan points carry the earlier point/trace lineage into a timed comparison. The museum's Perception gallery has a wider eastern floor for the installation; the two existing perception exhibits remain. The old computer-vision panorama is scaled to 0.28 so it no longer overlaps this stage.

## Play

Stand by the nearby controls and face the display. **PLAY** calibrates the facing direction and gives four beats to get ready. Pink means your left hand; cyan your right. Two curved paths float in the air at hand height, retaining their full horizontal, vertical and depth coordinates. Each shows the next eight beats. Follow the large moving point with each hand; it pulses on the beat, reaching the smaller markers in time. In tracked play two coloured rings mark the same current target positions. The wall figures preview upcoming poses.

Three small arrows on each curve show the direction of travel. A stationary part of your recording shows no arrow. Each target ring brightens independently when that hand is within tolerance. The nearby LEFT and RIGHT indicators say **IN PLACE** or **FOLLOW**, so you can tell which hand needs to move. IN PLACE reports proximity; a brief pulse marks a pose accepted after the timing and hold requirements. Count-in, recording and tracking loss have their own labels and cannot show a successful match.

The dance lasts about 17 seconds at 112 BPM, then loops. Four eight-beat sections give it a shape:

| Beats | Section | Movement |
| --- | --- | --- |
| 1–8 | FRAME | Frame the face, lift, curve above the head, fan outward. |
| 9–16 | SWEEP | Open, scoop low, offer forward, rise. |
| 17–24 | WEAVE | Asymmetric diagonal, ribbons, crossing paths at different heights and depths, unfold. |
| 25–32 | RETURN | Crown, wide arcs, gather, return to the frame. |

Poses arrive every two beats. Smooth cubic curves carry velocity through the intermediate poses. At the four section anchors the hands settle briefly: 0.24 beats before and after the cue. The eight-beat percussion loop accompanies the full phrase four times. Both hands, the music phase and the preview use the same beat clock.

Your actual hand movements leave brighter, short 3D trails. Both reference paths and measured trails use the same head-relative frame as recognition: height follows your head, facing is fixed when you begin, and REACH scales the reference. During recording, the reference paths disappear so you can make your own phrase. Replay draws its full 3D paths. An idle or untracked preview floats in front of the stage; it is labelled and does not count as a tracked performance.

**RECORD** starts a four-beat count-in, then keeps 32 beats of head-relative hand motion. Completed recordings switch directly to a replay count-in. **MINE** returns to that phrase; **GUIDE** restores the authored prompts. Measured samples retain their original timing and use linear interpolation, so the guide's smoothing does not rewrite your recording. Recordings last for this artifact instance; leaving/unloading the hall loses them. **CLEAR** removes the recording. No recording is made by entering the room or viewing the preview.

**REACH** cycles 0.45 / 0.65 / 0.85 metres. **EASE** changes matching tolerance. **TEMPO** cycles 96 / 112 / 128 BPM and restarts the count-in; **SOUND** mutes the original practice beat. The buttons support hand poking and the museum pointer. Desktop keys Space / R / G / M activate the corresponding commands when near, but recording and recognition require tracked head and controllers. Desktop preview is labelled and never earns matches.

## What is measured

Three tracked positions are used: headset, left controller, right controller. Subtract head position from each hand position, rotate into the upright facing frame captured at the start, and divide by chosen reach. Controller orientation, finger shape, footwork, hips, expression and cultural competence are not measured. The skeleton's elbows and legs are a drawing, not inferred tracking.

At each point in the timeline, measure each hand's distance to its target. A pose requires **both hands separately** inside tolerance for at least 0.12 seconds, within 0.35 beats of a cue. One well-placed hand cannot compensate for the other being outside tolerance. Each cue can be awarded only once. The continuous flow measure uses the root-mean-square distance of both hands, averaged over time as a bounded similarity value. It is not a probability, recognition confidence, or measure of artistic merit.

This is **template matching**, not a trained neural classifier. Recording replaces the reference samples; it does not fit model weights. Lost tracking clears the pending dwell and pauses time and audio. Long frames are capped at 0.1 seconds so a stall cannot award a pose from a single sample.

The sixteen prompts are original hand arrangements for this prototype. They are not names for vogue categories or a claim to teach the dance. Voguing belongs to Black and Latino LGBTQ ballroom histories; see [Smithsonian's account](https://nmaahc.si.edu/explore/stories/brief-history-voguing). A collaboration with ballroom dancers would be the next step for a culturally grounded movement library and practice track.

## Learning and reflection

Carry forward points, local/world frames, stored traces, arrays, interpolation and periodic time. Add timed sample comparison and a distinction between a reference, a metric and a learned model. Change the reference: what previously failed may now match. Change tolerance: more motion can count as similar, but distinctions disappear. Neither result tells us whether the dance mattered.

This is one concrete encounter for the AI critical thread. It lets the player experience successful recognition and its limits, and change an arrangement that produces those results. A future learned recognizer must be tested on genuinely held-out performances and explicit categories; the present prototype must not be renamed a learned system without that work.

## Validation

Run `python tools/test_vogue_timeline.py` from the project root. It tests the production matcher, full 32-beat recording/replay, wrong/swapped inputs, tracking loss, buttons, native XR nodes with supplied tracker poses, and the PCM loop. Geometry assertions check both airborne paths and measured trails, recorded depth, stationary hands, and agreement with target rings after turning, translation and reach changes. All sixteen cues are followed at each supported tempo; curve continuity, anchor holds, distinct hand positions, moving preview windows and beat markers are checked.

The feedback pass also tests forward-pointing arrows, stationary recordings, independent hand distances and ring colours, count-in/paused labels, and rejection of a pose whose average distance passes but one hand is outside tolerance.

Run `python tools/run_encounter_probe.py ML_Perception --sequence machinelearning --render --no-bridges --output-tag vogue_timeline --probe tools/probes/vogue_museum.gd` for actual hall floor checks and rendered guide images. Results are under `ada_run/encounter_pilot/ML_Perception/vogue_timeline/`.

The tests do not establish physical headset comfort, audio latency, bodily fluency or cultural adequacy. Those require playing the encounter. Existing project audio-UID and older computer-vision diagnostics are recorded separately in the review page.
