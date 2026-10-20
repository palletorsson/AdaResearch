# Perception — teach the same sphere

## Learning elements

- Represent two tracked hands with six coordinates.
- Keep one labelled example from one complete, steady take.
- Fit weights to examples; distinguish fitting from fresh testing.
- Separate a learned answer, an acceptance rule and an authored response.
- Save the model and continue with the same PointBody class.

## Already in the museum

Enter the learning bay to the right of the dance space, across the partition. The sphere, controls and room already exist. First try POSE there. We now reconstruct that capability with the PointBody class carried from the earlier lessons. Its mesh and pickup behaviour remain familiar. A narrow ring makes its rotation visible.

The preceding halls introduced selection, loss, clustering and changing network weights. Here those ideas acquire a task you can teach: decide which of three poses you mean. Positions and arrays return from Point and Trace; translation, rotation, scale and colour give the answer a visible effect. The sphere does not learn those effects. We write FLOAT, SPIN and STRETCH; the network learns which label your hand coordinates resemble.

Keep this lesson to POSE. HEIGHT, movement phrases and CHECK remain available in the full museum station, but are later extensions. A held pose contains no movement order. Sequence Memory will ask what we lose by keeping only a mean.

## Run in the supplied museum

Use the Ada Godot project and its existing XR setup. Open res://doc/book/studies/ml-lineage/Perception.tscn and run that scene. The supplied perception_museum.gd opens the actual Perception hall and mounts the learner script at its existing learning anchor. In this lesson preview it hides the full station; ordinary museum visits retain all modes. It does not alter your museum saves.

Place the three complete files below beside that launcher: point_body.gd, pose_learner.gd and pose_study.gd. PointBody is the carried class, printed again so this chapter can be reconstructed. The host uses the supplied RackTemplates.gd to create ten buttons and explicitly connects their signals. The museum supplies camera, lights, tracking and XR Tools pickup. These are declared infrastructure, not a hidden classifier. Desktop can display the lesson; recording your hands requires tracked XR controllers.

## Teach, test, then let it act

1. Face the console and press ALIGN. This keeps one horizontal reference direction until you align again. Hand positions are measured relative to the current head position in that fixed frame, divided by 0.65 metres. This scale is a design choice, not a measurement of your arm length.
2. In TEACH, choose A. A three-second countdown gives you time to move away from the button. Hold a comfortable pose for 0.65 seconds. The program averages the samples into **one** six-number example. Repeat with separate takes and small natural variation. Teach at least three takes for each of A, B and C. Choose visibly different poses; three examples is a minimum for running the exercise, not proof of sufficient data.
3. Press TRAIN. The same starting weights are fitted for 300 full-batch updates. The screen shows loss on the teaching examples. A falling value means a better fit to that sample.
4. TEST asks you to declare A, B or C before recording a fresh take. It displays what you meant and what the model predicted. No weights change. Try slightly different positions and an unfamiliar pose. A high softmax score is not calibrated certainty. Testing mistakes must remain visible rather than quietly entering training.
5. LIVE lets an accepted answer lasting a quarter-second act on the sphere: A floats, B spins, C stretches the visible mesh. Its pickup collider stays spherical. Losing tracking or moving outside the study's three-metre range idles the response. While you hold the sphere, pickup takes priority over scripted motion.
6. SAVE writes user://ada_student_pose_v1.json, separate from the museum's model files. LOAD starts a fresh evaluation session. A new teaching example invalidates the old fitted model and test records; train again. To begin an empty study, restart the scene; the saved file remains until you overwrite it with SAVE.

## Follow the calculation

The features() function returns six values in this order: left x, y, z; right x, y, z. Moving the whole measured arrangement together does not change these relative coordinates. Turning only your hands, swapping left and right, or changing the reference frame can change them. Finger shape, gaze, torso and intention are absent.

The learner is a **6 → 8 → 3** network. Each hidden unit adds six weighted inputs and a bias, then applies tanh. Each output adds eight weighted hidden values and a bias. Softmax turns the outputs into three scores summing to one. All three labels are choices you supplied.

| Stored parameters | Array entries | Count |
| --- | --- | --- |
| Input-to-hidden weights | 0–47 | 48 |
| Hidden biases | 48–55 | 8 |
| Hidden-to-output weights | 56–79 | 24 |
| Output biases | 80–82 | 3 |

There are 83 trainable numbers. Cross-entropy loss is minus the logarithm of the score for the given label. In gradient(), output error is the score minus the supplied target (one for the named class, zero for the others). Each weight's derivative multiplies that error by its input. Passing error through tanh also multiplies by one minus the squared hidden activation. The train_epoch() function averages those derivatives over the examples and subtracts RATE times the mean from the weights. Every derivative uses the old weights before any are updated.

Read the model in this order: add_example, forward, gradient, train_epoch, predict, test_example. Validation and persistence follow the same data contract; they are included so the printed files run without missing helpers.

Acceptance is a separate authored policy: highest score at least 0.70 **and** RMS distance to a teaching example at most 0.32. It can still accept an unfamiliar case or reject an intended one. The host's respond() then chooses a prewritten action. None of these thresholds is a measure of dance quality.
