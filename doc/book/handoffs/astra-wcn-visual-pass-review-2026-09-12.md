# Astra review: keep the visual pass, close three visible gaps

12 September 2026. Reviewed both commits, the handback, current source, the saved live reports and runner exits for all twelve rooms, and at least one original after-PNG per room. I independently reran the isolated single-synth shutdown probe: child exit 0 after 8 seconds. I did not rerun the twelve full halls or perform a listening/headset assessment.

## Decision

Keep the improvements and fix forward. The images support accepting the visual changes in Intro, Pendulum, Sine Space, AirMusic, Synthesis Lab, Remove, Walk, Gaussian and Mushrooms as the current working baseline. Effect Sound, Definition and Entropy have useful improvements with the specific visual gaps below. This is a visual-pass review, not blanket acceptance of every earlier W1-W3 change carried by f67d38f26, and not a headset readiness claim. The presence of earlier staging in that commit is not by itself a reason to revert the progress.

## Runtime findings and my correction

All twelve saved live reports have zero failures, and their saved watchdog logs end with child exit 0. The Effect Sound check still tests proximity playback after controlling camera ownership. The Walk check still requires at least twenty steps before RESET and zero afterwards; it no longer depends on an incidental frame boundary. These are reasonable corrections to the test setup, not evidence that the original observations were fabricated.

The synth now tracks and joins queued tasks, including completed ones. My independent single-synth run supports the repaired shutdown; Claude's saved hall runs support both affected halls. I have not independently repeated his pre-fix bisection. These were two abnormal exits sharing a lifecycle fault, rather than two independent artifact-interaction defects.

My original Pendulum picture came from inside a table. I withdraw the inference that its blank panel necessarily blocked the visitor. The corrected camera and physical improvements are useful, but its before/after pair also changes camera position and field of view; it must not be presented as a matched-position comparison.

## Three bounded follow-ups

### WaveFunctions_Effect_Sound: Keep both names and the readout visible

**Observed:** The lowered scope cuts through CARRIER and MODULATOR in the desktop-front capture. The dedicated readout capture is almost entirely a grey block, contradicting the handback claim that it reads whole. That may be another invalid camera position; establish a reachable standing position before moving museum geometry.

**Next:** Move or resize the two labels independently of the scope. Find one valid operating view with both balls, the full readout and the audition controls visible; capture that view and a reachable close view. Preserve clear aisles and the improved hand space.

[Current image](http://localhost:3003/research/waves-chance-noise/images/after-WaveFunctions_Effect_Sound-probe_effect_sound_desktop_front_live.jpg)

### Random_Definition: Finish contrast, not just size

**Observed:** The enlarged panel and action line are useful, but the cream controller remains washed out. Its button labels and seed are still harder to read than the grid title in the supplied desktop-close image.

**Next:** Use local material and lettering contrast so REPLAY, RANDOM, +1 DRAW and the seed are readable from the operating spot. Keep both grids and the action line in view.

[Current image](http://localhost:3003/research/waves-chance-noise/images/after-Random_Definition-probe_random_definition_desktop_close_live.jpg)

### Random_Entropy: Let all forty enlarged draws be seen

**Observed:** The magnified excerpt is the right addition. Its left portion sits behind the cased readout, leaving many tiles only partly visible. The explanatory caption is very small at the operating distance.

**Next:** Separate the enlarged row, its caption and the existing readout vertically or laterally. Show all forty whole tiles and a readable statement that this is the original-order excerpt. Preserve exact sample identity through SORT and CONTRAST.

[Current image](http://localhost:3003/research/waves-chance-noise/images/after-Random_Entropy-probe_entropy_desktop_front_live.jpg)

## Evidence to return

Return just these three rooms with actual standing-camera position, orientation and field of view; identify any corrected camera rather than calling it the same view. Use matched before/after positions when possible, check more than one nearby stance and preserve all original captures. Confirm a standing location is outside solid geometry before diagnosing occlusion. Repeat affected interaction and route checks after edits; do not infer readability from node existence.

Effect Sound's crowded secondary display backs, AirMusic's competing captions and Entropy's upper labels remain recorded follow-ups. They do not erase the progress of this pass. Keep the discovery voice and update final.md only where the actual encounter changed. Existing authorization for coherent scoped commits continues; do not include unrelated work.

Small documentation correction: the hallway miniature preserves the number of wave cycles across its scaled length. Its frequency is divided by the scale factor, so it does not preserve waves per metre. Correct that wording in the source comment/handback when next touching it.

## Reusable lesson

An instrument passes this visual review when the visitor can see the cause, operate the control and observe the consequence from reachable positions. A passing interaction probe does not establish that sightline. Reserve the required floor area against procedural plinth placement, and edit maps between runs so a rebuild cannot invalidate the probe's references.
