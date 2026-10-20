# Sequence Memory — both hands, in order

## Learning elements

- Carry the point sphere and the same six hand coordinates from Perception.
- Store a complete, timestamped movement instead of one averaged pose.
- Resample takes onto common times; fit a two-hand prototype.
- Test order, timing and each hand separately.
- Compare two taught phrases without forcing every take into A or B.
- Distinguish learned memory, a manual memory cell and replay.

## What we carry

Perception gave the point a learned response to a pose. Its short recording ended as six averages. Make a rising movement with both hands, then the same movement descending. Those averages can be the same. The movement is not.

Keep point_body.gd, pose_learner.gd and pose_study.gd from [Perception](../ML_Perception/tutorial.md), unchanged. The new sequence_study.gd **extends pose_study.gd**. Its call to the parent's ready function makes the same pickable PointBody, ring, board and tracking connections. We replace the controls and recording loop; we do not rebuild or explain the sphere again. An existing student pose save is read if present; phrase teaching never alters that model.

The object is continuous as a class and a design. During this study ONE, A/B, tests and replay all use one sphere instance. Reloading a museum hall does not yet transfer the visitor's live node between scenes. The phrase files below preserve learned data locally.

## Where to work

In the ordinary museum, the full phrase station remains in Perception's separate learning bay. In the Sequence Memory hall, inspect the existing gate cell and its transformer diagram. The supplied lesson launcher brings **your printed-code study** into a clear side area in that actual hall; it leaves those exhibits present.

Open res://doc/book/studies/ml-lineage/SequenceMemory.tscn in the Ada project and run it. Its supplied sequence_museum.gd prepares the room. Put the three new files below beside the three carried files. Camera, light, XR tracking, pickup and the RackTemplates button factory remain declared museum infrastructure. Every new learning operation is printed here. Recording needs a tracked head and both controllers; desktop can preview the room.

## One phrase before two

Choose ONE. Invent a comfortable four-second phrase that moves **both** hands. For example: open outward, lift, draw inward and settle. This is your phrase; the model has no supplied dance to copy. Begin from a repeatable arrangement.

Press CAPTURE. Arrange your hands during the three-second count-in. Move on beat 1, continue through eight beats at 120 BPM, and finish at four seconds. A click and the readout mark the time; SOUND toggles the click. STOP discards a pending performance. Lost tracking, a long frame or leaving the station's tracking range discards the whole take.

Each take becomes an array of records. Each record keeps elapsed seconds and the same ordered six values: left x, y, z, then right x, y, z. We still subtract the current head position and divide by 0.65 metres. The horizontal frame is aligned at the start of each take and stays fixed until it ends. This describes hands relative to your moving head; it is not a record of your route across the floor.

Capture at least three separate performances, then TRAIN. Three is an exercise minimum, not evidence of reliable recognition. UNDO removes the latest whole teaching take if you made a mistake. It invalidates the fitted result, so train again.

REPLAY previews the fitted phrase: pink is left, cyan is right. Both paths sit in the air, the tips follow time, and the same sphere follows their midpoint. The display is a bounded miniature; the recogniser uses the unaltered coordinates. The response is authored. It does not mean the system has invented choreography.

Choose TEST, then CAPTURE a **fresh** performance. Testing records an answer without moving the sphere or changing the learned path. TRY records a fresh performance too, but an accepted result then replays the model's path. During capture the learned paths are hidden so the preview does not become the answer you are tracing.

## Why this retains a sequence

The movement learner samples every valid take at 41 common times: 0.0, 0.1, …, 4.0 seconds. When a time falls between recorded samples, sample() interpolates between its two neighbours. A large missing interval is rejected before interpolation.

At each time, fit() averages the six coordinates across the teaching takes. This gives 41 six-number rows. The same mean operation from Perception now happens **separately at each time**. It cannot replace the first moment with the last without changing the model.

This is a learned prototype, not a recurrent neural network. It learns an average path and tolerances directly from examples; there is no backpropagation here. For fixed aligned samples, the coordinate-wise mean minimises summed squared coordinate error. The earlier neural classifier remains available as carried code, but a new kind of observation does not require pretending this prototype has its architecture.

Prediction compares corresponding times and computes a root-mean-square distance **for each hand**, plus its largest single-time error. A good left hand cannot hide a motionless right hand. The code requires a small amount of movement from both hands. That is an explicit two-hand exercise rule, not a universal definition of a phrase.

Limits come from teaching variation. For each take, the code measures its error from the mean of the *other* takes. It widens each hand's limit within fixed bounds, 0.14 to 0.32 coordinate units. Acceptance also caps peak error at 2.5 times that hand's limit. Multiplying distance by 0.65 converts it to metres. Training loss, these limits and the choice to reject are different things.

There is no time warping. The same route at very different moments can be rejected. A deliberate pause is data, not an interruption; missing tracking is an interruption. Conflicting teaching takes can make TRAIN refuse a fit rather than erase the conflict with a huge tolerance.

## Then A and B

ONE keeps its own model. Choose A and teach three complete takes; choose B and teach three more. You could teach the rising phrase as A and its reverse as B. TRAIN now fits both.

TEST and TRY compare the new take with **both** models, regardless of which teaching button was last selected. A/B selection tells the program where to store teaching or which model to preview; it never supplies the answer during inference.

- A or B: an accepted choice.
- UNKNOWN: neither prototype accepts the performance.
- AMBIGUOUS: both accept, but their normalised distances are too close to choose.

The comparison uses the worst hand's RMS distance divided by that model's hand limit. Smaller is closer. A difference below 0.20 with both candidates accepted is ambiguous. These scores are distances, not probabilities. Similar teaching under different names is a useful way to produce an ambiguous result deliberately.

SAVE keeps ONE in user://ada_student_phrase_v1.json or both classes in user://ada_student_phrase_ab_v1.json. LOAD validates the saved examples and fitted data before replacing anything; testing starts fresh. The older pose save is separate. Starting an empty scene keeps files on disk until SAVE overwrites the relevant student file. This small study retains only the latest 60 test results in memory; Synthesis will add a richer evaluation record.

## Read the code in this order

Start with valid_take and resample: what counts as a complete observation? Then follow fit, distances and predict: what does the fitted path keep? Read the two-phrase wrapper only after ONE makes sense. Finally trace begin_phrase → advance_phrase → complete_phrase in the host. It carries one whole take into either teaching or testing, and only TRY enables the response.

The three complete new files follow. The reconstruction test also extracts the three declared carried files from Perception's printed text, so no unprinted helper fills a gap.
