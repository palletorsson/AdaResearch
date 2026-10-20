# Teach the sphere a two-hand phrase

Inside **ML_Perception**, beside the existing dance, the Teach a sphere station now has **POSE / HEIGHT / PHRASE**. The same sphere carries all three. Each lesson keeps its own dataset and local saved model.

PHRASE pauses the neighbouring dance and hides its airborne preview so that its paths cannot be mistaken for the learned ones. Leaving PHRASE restores that preview. Starting the dance explicitly returns the station to POSE.

The initial **ONE** activity remains below. The next step, [two phrases with A/B/unknown/ambiguous decisions](PHRASE-CHOICES.md), uses the same sphere, capture and timing. Select A or B to teach those separate classes; ONE restores the earlier single-phrase dataset. The two activities have separate local saves.

## Play it

1. Choose **PHRASE → TEACH**. Invent one short movement with both hands. For example: open, lift, sweep forward, return. Keep it comfortable and small enough to repeat.
2. Press **CAPTURE**. The three-second count-in gives time to move away from the button and prepare. When beat 1 lights, perform the phrase for **eight beats at 120 BPM: four seconds**. Both hands leave coloured trails in the air. The quiet click can be switched off with SOUND; the visual beats remain.
3. Repeat CAPTURE at least three times, returning to the same starting pose and using approximately the same timing. Each entire performance is one example. UNDO removes the last teaching take; the maximum is twelve.
4. Press **TRAIN**. The station fits two average timed trajectories from your takes. Small pink and cyan 3D paths beside the console show what it retained. If the takes disagree too much, fitting is refused; remove the accidental take or start again.
5. In **TEST**, press CAPTURE and perform a new take. Read the left and right errors. Test performances never enter training or alter the fitted paths. Try reversing the phrase, swapping hands or leaving one hand still. A test's match count is not an accuracy estimate: the station has not been told which of those trials you intended as a match.
6. Press **TRY** to start another count-in. If the completed movement matches, the sphere replays the fitted phrase between the two hand paths. Its position follows their midpoint; its size follows their separation. A mismatch leaves it waiting. This is a response after recognition, not live copying of the incoming hands.
7. **REPLAY** previews the learned phrase without testing you. The display labels this as a preview. It plays the eight-beat rhythm with the moving hand tips and sphere. It does not generate a new dance.
8. **SAVE / LOAD** keeps complete demonstrations and the fitted model on this device. RESET requires two presses and clears only the phrase session in memory. Saved files remain until overwritten by SAVE. Switching to POSE or HEIGHT preserves their examples and cancels any unfinished phrase capture or replay.

## One-paragraph lesson

Carry the sphere and the two hand points. Record three whole performances of one four-second phrase. Preserve timestamps and left/right identity. Fit a mean path at corresponding moments; inspect what averaging retains or removes. Test a fresh performance without training; reverse the order and hold one hand still. Let a recognised phrase activate the same sphere. Distinguish a remembered sequence, a fitted prototype and an authored response.

## The actual learning

`movement_learner.gd` implements a small **time-aligned prototype model**, not a recurrent neural network. It learns 41 six-coordinate means from complete demonstrations. This is a deliberately inspectable fitted reference, rather than the dance's supplied guide. No training takes are installed in the visitor session.

Every recorded sample contains a timestamp in seconds and `[left.x, left.y, left.z, right.x, right.y, right.z]`. Coordinates are relative to the current head position, in an upright facing frame fixed at the beginning of that take, divided by 0.65 metres. Start facing the console. Moving the head changes the measured relation to the hands; no elbows, fingers or body pose are inferred.

Capture samples at approximately 20 Hz. The raw timestamps remain in the saved take. For fitting and comparison, linear interpolation samples each performance at 41 fixed instants from 0 to 4 seconds. Up to 0.1 seconds before the first sample and 0.05 seconds after the last are represented by their nearest measured endpoint. This is fixed-time resampling, not time warping: a long pause or differently timed motion changes the result.

TRAIN averages each of the six coordinates at each instant. Each hand receives its own distance limit based on the largest leave-one-out RMS distance among the teaching takes, multiplied by 1.5 and increased by 0.025. Authored bounds constrain that limit to 0.14–0.32 normalised units, about 9–21 cm. If any teaching take's leave-one-out distance exceeds 0.32 for either hand, training is refused. These thresholds are interface policies derived partly from the examples, not calibrated probabilities.

A fresh take must pass **both** hands' RMS limits, stay within 2.5 times those limits at every sampled instant, and contain measurable motion from both hands. The minimum per-hand RMS movement around its own mean is 0.07 normalised units, about 4.6 cm. That minimum describes this particular two-hand movement lesson, not the value of stillness or a universal definition of dance. Symmetric or nearly palindromic phrases can resemble their reversal; the tests establish rejection for the tested distinct movement, not every possible phrase.

Each complete take needs 40–100 valid timestamped samples. Missing tracking, invalid coordinates, a frame gap over 0.15 seconds, a gap between stored samples over 0.151 seconds, incomplete duration or unordered timestamps rejects the entire take. We do not fill a lost hand with the last known position. Fitting and recognition are local GDScript computations with bounded data, without a service or runtime Python dependency.

The pink and cyan fitted paths are a bounded miniature for inspection. Capture trails are drawn near the actual hands in the current head-relative frame. The miniature's scale and position, the beat rate, the sphere's midpoint/separation response and the acceptance limits are authored choices. The mean trajectories come from the visitor's examples.

## Records and tests

The phrase saves to `user://ada_two_hand_phrase_v1.json`. It includes complete takes, fitted coordinates, distance limits and readiness. Loading validates the fitted model against its saved examples and begins fresh evaluation. It does not erase the pose or height files. Data is stored only through SAVE.

`python tools/test_movement_learning.py` runs native Godot assertions. It compares the fitted path with an independent mean calculation; tests fresh, reversed, hand-swapped, one-hand-still, retimed and displaced performances; verifies that evaluation does not train; checks local save/load, atomic rejection of corrupt data, actual buttons and supplied XR trackers, cancellation and the same sphere's response.

The synthetic fixture is confined to `tools/probes/movement_fixture.gd`. It is used by tests and clearly labelled museum report captures, not by production artifacts. No test touches the visitor save file. Three examples is an interaction minimum, not a claim of broad recognition accuracy. Human demonstrations, headset comfort, audio timing and device performance remain to be tried.

The earlier pose, height and dance tests must still pass. Museum rendering uses `python tools/run_encounter_probe.py ML_Perception --sequence machinelearning --render --no-bridges --output-tag movement_learning --probe tools/probes/movement_learning_museum.gd`.

## What the model leaves out

An averaged gesture is not an ideal gesture. It can erase a deliberate accent or combine takes into a path nobody actually performed. The visitor can inspect that path, remove a take and change it. A recognised relation says nothing by itself about artistry, voguing competence or cultural belonging.

The model represents one phrase under fixed timing. It does not recognise continuous unsegmented dance, learn many phrase classes, understand meaning or synthesise new movement. The next useful investigation is whether these fixed-time comparisons feel right when people vary their rhythm; that would justify changing the model rather than hiding timing differences behind an accuracy claim.

Mean-based representatives are a basic idea in [centroid classification](https://scikit-learn.org/stable/modules/generated/sklearn.neighbors.NearestCentroid.html); this implementation uses one ordered prototype with separate per-hand rejection policies, not that library's multi-class estimator. [Dynamic time warping](https://dynamictimewarping.github.io/py-api/html/api/dtw.dtw.html) is a possible later way to align differently timed performances. It is not used here.
