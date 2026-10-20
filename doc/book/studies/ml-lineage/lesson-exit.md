## Change something and account for it

In a fresh session, give the same comfortable pose another label. After retraining, does its response follow the new label? Compare that with changing only FLOAT's height in respond(): one change alters the learned mapping; the other alters what we let its answer do. Explain the difference before running either experiment.

Then test a fresh take without pressing TRAIN. Confirm the number of teaching examples and weights stay fixed. Keep mistakes and withheld responses in your account. The in-memory test list retains only the latest 90 records; this small exercise is not a research evaluation archive. Loading a saved model deliberately starts a fresh list.

## Reconstruction check

Run python tools/test_ml_pose_lesson.py from the project root. It extracts these named code blocks into a separate folder, checks all 83 derivatives against numerical differences, fits synthetic examples, tests unseen fixture takes, permutes labels, checks persistence, constructs the point and label from scratch, and exercises real button signals with supplied XR trackers. It also checks interruption, test/training separation and the three visible responses. No production learner is imported to fill a gap.

Those are real Godot assertions using synthetic data. They establish executable behaviour and some invariants, not recognition accuracy across people, headset comfort or accessibility. This is an author-informed reconstruction, not an independent blind reader. Try your own examples in the museum next.

What travels onward is the same point class, a six-coordinate representation, a labelled dataset and a fitted model. Sequence Memory adds a new question: if both hands pass through the same places in a different order, should the answer stay the same?
