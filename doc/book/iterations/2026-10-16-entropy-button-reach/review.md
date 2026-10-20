# When the text says “we press”

Palle questioned whether the button actions in the entropy texts are plausible in VR. This is a response about the encounter's affordances, not evidence that either literary transition has succeeded. It exposes an assumption in the earlier cabinet reading prompt: it supplied the desired action before establishing that the visitor would find a reason or a comfortable way to perform it.

## What a press actually does

The installed museum uses the collision-hand rig in `commons/scenes/base.tscn`. Its controller pointers include area targets and use `trigger_click`. The shared rectangular cap contains an XRTools area button. Hand contact activates it; leaving releases it. A controller ray and trigger dispatch the same action through `interactable_area_button_pointer.gd`. A held contact does not repeat. The cap moves, changes colour and plays a click. Physical hand contact also has a rumble connection; this test does not measure headset feedback.

| Control | Operation |
| --- | --- |
| STEP | Advance both door rules once; retain their LOW/HIGH histories. |
| GAP − / + | Choose a starting difference and restart both pairs. |
| PINK / BLACK / BLACK+ARMS, then DRAW | Keep a prediction; select one chair ID and reveal its category. |
| A LEFT − | Exchange one A on the left with a B on the right. |
| SAME k | Rotate occupants within each tray; the count in each tray stays fixed. |
| KEEP / REPLAY | Write the compartment trial's recorded arrangements and generator states; read that record back. No in-room filename selection is required. |

The compartment spheres are not individually draggable. Saying that we move one by hand would invent an affordance. The guessing study's last all-pink chairs and the four-cube sorting table do support direct handling.

## Faults found and corrected

- Door and guessing controls inherited a source-scene rotation that pointed the cap into the panel. The helper now explicitly faces the cap out. A small part of the old area remained exposed: the old controls were not entirely inert, but their cap and useful contact depth were on the wrong side.
- Guessing buttons were at 0.33 m. Their rail now faces upward at about 0.90 m. A first sloped placement obscured chair details from a lower eye position; it was flattened after inspecting the native render. Chair materials and models are unchanged.
- Door caps were at 0.645 m. They now sit near 1.0 m. The explanation was lifted within its backing so the control strip does not hide its lower lines.
- The compartment cabinet had two front-facing rows at the same height. A front row could intercept a ray intended for SAME k behind it. Both rows now face upward, with flat captions beside the caps. The model and save/replay logic are unchanged.

## What this changes in the writing test

An available action, a discoverable action and a desired action are different observations. The finals currently narrate a possible investigation. They are not transcripts of a headset walk. Their room order and wording stay fixed during this repair.

The next writing pass should earn a change before invoking its control. For the cabinet, a candidate is: “The colours can still change places within each tray. Would the dials notice?” The next sentence can name SAME k once, then attend to what changes. Removing the name alone would hide the mechanism without making the encounter more convincing.

Keep operating instructions in the tutorial. Let the final give space to hesitation, observation and consequences. KEEP and REPLAY need not occur in every imagined visit; retain them when the need to return to a particular arrangement has actually arisen. Direct manipulation is valuable where the object's movement is the inquiry. A precise shared STEP remains useful for comparing two computational rules.

For a fresh headset trial, stop before prompting a control. Record the first intended action, whether its target is found, whether it activates once, and whether the change is seen while operating it. If the visitor does not touch anything, retain what they look at or want to change. That result can revise the apparatus and the text. A successful click alone does not earn the next encounter.

## Evidence limits

The supplied probe tests actual physics overlap on the hand collision layer and XR pointer-event dispatch after a ray hit, rather than emitting the artifact's action signal directly. It checks release and duplicate suppression, and verifies door steps and chair draws change through that path. The cabinet additionally checks all eight targets from an angled approach and exercises A LEFT − and SAME k. KEEP/REPLAY semantics come from source and existing receipt tests, not a new persistence test in this pass.

Native views inspect standing and lower eye heights. These are supplied cameras, not tracked-head or hand evidence. Comfort, discoverability, controller feedback and the reader's desire for the next encounter remain open. The first 48-value bench remains the research pilot.

The final runs pass 300 Types and 30 Workshop checks. [Source hashes and receipts](verification.json) retain the scope and show both finals unchanged.

![Guessing rail from a standing eye position](types/guess-standing.png)

![Lower eye position: the arms remain visible, while flat text is more foreshortened](types/guess-lower-eye.png)

The flat rail improves the view of the chair parts from the lower camera. Its text is foreshortened there; comfortable reading from a seated headset still needs testing.

![Door controls beneath the explanation](types/doors-control.png)

![Cabinet controls face upward in both rows](workshop/cabinet-controls.png)
