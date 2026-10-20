# Teach a sphere

Built inside the existing `ML_Perception` dance artifact. The dance compares hands with a timed reference. The adjacent station fits a separate, real pose classifier from visitor demonstrations. Neither system judges dance quality.

The console now has **POSE / HEIGHT / PHRASE** lesson selectors. POSE follows the steps below. [HEIGHT](HEIGHT.md) teaches a continuous relation from hand height to sphere height with real linear regression. [PHRASE](PHRASE.md) fits ordered two-hand trajectories from complete four-second performances. The same sphere carries all three; each retains its own examples and saved model.

## Try it in VR

1. Stand at **TEACH A SPHERE**, left of the dance. Face the panel. Headset and both controllers must be tracked.
2. In **TEACH**, press **A**. A three-second countdown lets you arrange both hands. Hold briefly. One completed take becomes one example.
3. Make at least three separate takes each for **A**, **B** and **C**. Choose visibly different arrangements. Move between takes; vary each pose slightly. A is mapped to float, B to spin and C to stretch.
4. Press **TRAIN**. The network fits over 300 updates, two per frame. The curve is measured training loss. No installed pose examples or predetermined classifier answers are used.
5. Training ends in **TEST**. Press the expected label, then perform a fresh take. The screen compares the label and prediction. Test takes never update weights or enter training. Repeated testing and adjusting examples is exploratory evaluation, not an untouched final test.
6. Press **LIVE**. Hold a pose: the sphere responds after 0.25 seconds of stable classification. TEACH can add examples, but doing so invalidates the model's readiness and clears its evaluation record. Train again.
7. **SAVE** writes examples and parameters to this device. **LOAD** restores them and starts a fresh evaluation session. **ALIGN** resets forward direction if you turn. **RESET** needs two presses within four seconds; it clears the running session but leaves the saved file until SAVE overwrites it.

## Actual learning

`pose_learner.gd` implements a 6 → 8 → 3 network: six coordinates, eight tanh units, three softmax outputs. Full-batch gradient descent fits 83 parameters using cross-entropy loss. It includes activation derivatives and computes all gradients before updating weights. Learning rate 0.20, 300 updates, deterministic initial seed 417. Maximum 20 takes per category. No server, Python service or GPU is required at runtime.

Input: `[left.x, left.y, left.z, right.x, right.y, right.z]`. Subtract headset position, rotate into a fixed upright facing frame, divide by 0.65 m. This is independent of the dance's REACH setting. A take averages roughly 0.65 seconds of valid tracking. Excess movement, tracking loss or a frame gap over 0.2 seconds rejects the entire take. Each hold gives one dataset row, not many nearly identical training and test frames.

Softmax outputs are model scores, not calibrated certainty. Live response also requires the strongest score to reach 0.70 and RMS distance across the six coordinates to a training example to be at most 0.32. That distance gate is an explicit policy, not a learned novelty detector or a guarantee against unfamiliar poses. Tracking loss or rejected input idles the sphere.

The output behaviours are authored; the hand-to-category mapping is learned. Save/load retains examples and parameters at `user://ada_hand_poses_v1.json`. It does not save video, infer fingers or capture a full body. Capture only begins when A/B/C is pressed in TEACH or TEST. Loading resets evaluation counts and establishes facing from the current player.

## Verification

Run `python tools/test_pose_learning.py`. Native Godot tests cover all 83 gradients against independent finite differences; loss reduction; held-out synthetic takes; changed-label learning; frozen weights during testing; file roundtrip and rejection of malformed data; real buttons with supplied XR trackers; capture interruption; sphere responses. Tests use `user://ada_pose_test_fixture.json`, never the visitor save file.

Run `python tools/test_vogue_timeline.py` for the existing dance. Run `python tools/run_encounter_probe.py ML_Perception --sequence machinelearning --render --no-bridges --output-tag pose_learning --probe tools/probes/pose_learning_museum.gd` for actual hall loading, floor checks and images. Captures show the empty station and a labelled synthetic rehearsal; they do not demonstrate human recognition accuracy. Synthetic samples are not installed or written to the visitor save.

Headset comfort, tracking noise, device performance and accuracy on different human demonstrations remain to be tried. Three takes per class is an interface minimum, not sufficient-data evidence. Overlapping poses cannot become distinguishable through more training alone if the measured features omit their difference.

## What travels onward

The two hand points become a six-number record; records gain labels; prediction errors alter weights; the result changes a sphere. HEIGHT carries this into continuous control. PHRASE now preserves ordered records and fits one short two-hand movement from whole performances, with fresh tests and a sphere replay after recognition. This artifact does not generate new dances, train vision models or complete the ML tutorial revision.

The player defines and can change A/B/C. Which distinctions did those examples teach, and what does the museum choose to do with the prediction? Better accuracy does not settle the value of a category or its consequence.
