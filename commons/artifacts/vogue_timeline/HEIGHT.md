# Teach the same sphere an amount

Inside the existing Endless Museum hall **ML_Perception**, choose **HEIGHT** at the Teach a sphere console. **POSE** learns a category; **HEIGHT** learns a continuous output. Both use the same visible sphere. Their datasets and saved files are separate.

[PHRASE](PHRASE.md) adds a third lesson on the same object: ordered two-hand movement over four seconds, fitted from complete performances and tested with fresh takes.

## Try it

1. Choose **HEIGHT**, then **TEACH**. Move the nearby HEIGHT slider to the sphere height you want, from 0.95 to 1.95 metres above the station's floor. The sphere previews that target.
2. Press **CAPTURE**. During the three-second countdown, arrange both hands. Hold their height briefly. One take records one pair: mean hand height relative to your head, and the chosen sphere height. The target is locked during capture.
3. Collect at least three takes at different hand heights. For example: low hands / low sphere, middle hands / middle sphere, high hands / high sphere. The total measured input span must exceed 0.1625 metres. More varied examples are more informative than repeated identical holds.
4. Press **TRAIN**. The system fits a straight line through your pairs over 240 updates. Cyan dots are your targets; the yellow line is the fit. Mean squared error reports how closely that line fits the examples.
5. In **TEST**, set the expected output height and capture a fresh hand height between those already taught. The signed raw prediction error appears in metres. The tests do not update the model. The sphere previews your expected target in TEST; it follows the model in LIVE.
6. Choose **LIVE**. Raise and lower your hands. The same sphere moves continuously along its one-metre rail. Outside your recorded input range, or without tracking, it eases to the idle midpoint. The HEIGHT slider cannot override a live prediction.
7. Return to TEACH to add pairs and train again. Or reset this height session and deliberately reverse the relationship: low hands / high sphere; high hands / low sphere. A negative learned slope makes the sphere descend as your hands rise.
8. **SAVE / LOAD** keeps this height model and its examples on this device. **POSE** returns to the pose classifier with its examples intact. Switching lessons cancels unfinished captures and returns a trained model to TEST. RESET needs two presses and clears only the current lesson's in-memory session.

## What is actually learned

`height_learner.gd` is complete runnable GDScript. It fits slope and intercept with full-batch gradient descent on mean squared error. There is no installed hand-to-height mapping or pretrained visitor dataset.

The input is `(mean(left_hand.y, right_hand.y) - head.y) / 0.65`. Horizontal movement and hand spacing are intentionally omitted. Moving both hands and the headset together preserves this measurement; moving the head alone changes it. This is a choice of feature, not an understanding of the whole pose.

Training centres the recorded inputs and divides by their standard deviation, with a 0.05 lower bound. The model predicts `slope * (input - centre) / spread + intercept`. Targets are normalised from the one-metre display rail to 0–1. Two derivatives are accumulated before either parameter changes. Learning rate 0.10; 240 updates; two updates per rendered frame; at most 30 training pairs. Fitting is local and uses no external service.

Live output is clamped to the display's 0–1 range and withheld outside the recorded input interval. The display eases toward its target. These limits, the output rail and the easing are authored policies; the slope and intercept are learned. Test error uses the raw prediction, before output clamping, and includes outside-range tests. The chart clips the fitted line to its visible bounds. It is not a confidence interval.

A capture averages roughly 0.65 seconds of tracked input. Tracking loss, a frame gap over 0.20 seconds, fewer than eight samples, or standard deviation above 0.08 input units discards the take. These are short held demonstrations, not learned dance sequences. Samples within one hold remain one dataset row.

`user://ada_hand_height_v1.json` stores examples, parameters and input normalisation. Loading starts a fresh evaluation session. The pose classifier uses its separate `ada_hand_poses_v1.json`. No visitor file is read or written by the tests or report captures.

## What this lets us investigate

A straight line is a deliberate limit. It can learn an ascending or descending relationship. It cannot fit a bowl-shaped relationship exactly. Try giving two identical measured hand heights different targets: no amount of training makes that omitted distinction visible to this model. The remaining error makes the limitation inspectable.

The visitor chooses what a movement should do; the software chooses which movement dimensions it can notice. A smaller training error does not decide which mapping is worth making. Repeated tests followed by revised examples are exploratory evaluation, not an untouched final assessment.

## Verification

Run `python tools/test_height_learning.py`. It checks derivatives against finite differences, coefficients against an independent least-squares solution, intermediate held-out inputs, reversed targets, a deliberately unfit curved relationship, save/load validation, unchanged weights during testing, actual slider and button signals with supplied XR trackers, interrupted capture and switching both lessons on one sphere.

Run `python tools/test_pose_learning.py` and `python tools/test_vogue_timeline.py` for the carried classifier and dance. Run `python tools/run_encounter_probe.py ML_Perception --sequence machinelearning --render --no-bridges --output-tag height_learning --probe tools/probes/height_learning_museum.gd` for the actual museum captures. The fitted examples shown in report images are labelled synthetic rehearsals; the production station starts empty.

These tests establish implemented behaviour with controlled inputs. Headset ergonomics, tracking variation and accuracy on visitor demonstrations still need playing. This is an artifact extension, not a claim that the full Machine Learning tutorial sequence has been revised.
