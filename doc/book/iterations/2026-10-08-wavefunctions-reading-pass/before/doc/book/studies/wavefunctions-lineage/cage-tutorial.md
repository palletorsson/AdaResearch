# John Cage — a score kept

## Learning elements

- Choosing from a finite sound vocabulary.
- Keeping an event's time and sound index in a dictionary.
- Reading an ordered event list with a clock and cursor.
- Replaying a record without drawing new choices.

Let the museum's soundscape finish loading. Hear the continuing background, then wait for a separate event. You do not know its next entrance. Its possible sounds have nevertheless been prepared.

Bernini separated a stored form from its movement. Here we separate a score from its performance. Build a six-event study beside the existing soundscape. Make the choices once, keep them, then listen to that record again.

## Carry the sound and the point

Keep `point_body.gd` and `line_skin.gd`. Copy the two sound-making functions from Effect Sound into `note_voice.gd`; their sample calculation is unchanged. Three modulation depths give us three short sounds at the same base pitch. Sound synthesis is carried material here. Choosing and scheduling those sounds is the new work.

In your prepared Endless Museum working copy, put all four files together. Attach `08_chance_score.gd` to an empty, unit-scale `Node3D` at hall-local `(16, 0, 10)`, yaw 180 degrees. This is the entrance study bay. The museum supplies the floor, camera, light, player and XR pickup/trigger routing. The script creates its point, score markers, labels and audio players. Only the point has a pickup collider; the score is a visual display.

Grab the black point. Hold it left of the study's centre and press the trigger to replay. Hold it on the right and press to make a new score and play it. The label names the selected action. Both actions restart the clock. Releasing the sphere keeps it where you leave it. Left and right use the study's **local X**, so turning the whole study does not reverse its own controls.

Read the score before playing. Horizontal position represents seconds from the start; the three rows are sound indices, zero to two. The small cubes are six events. Their labels give their times. The vertical guide moves across the record, and events turn pink as they are dispatched. All six notes sound from one position in the study; the display is a timeline, not an arrangement of six spatial sound sources.

## Complete program

{CODE}

## Choose once

`notes` holds three generated clips. `rng.randi_range(0, notes.size() - 1)` chooses a valid index, including both ends of that range. `randf_range` chooses the wait before an event. This is a small introduction to bounded random choices; distributions and seeds receive their own sequence later.

In `new_score`, `at` begins at zero and **accumulates** the waits. Waits of 1.0, 0.8 and 1.4 seconds produce event times 1.0, 1.8 and 3.2. They do not produce three unrelated delays measured from now. Every wait is positive, so the event list is already in time order.

Each dictionary keeps two named fields: `at` is a time in seconds; `voice` is an address in `notes`. The array keeps their order. This extends Trace's retained list: a record can carry several related values rather than only a position. Neither the row number nor the timestamp contains the sound itself.

The generator runs when the study starts and when you choose NEW. It does not run on every frame. A new draw can repeat an earlier choice; randomness does not promise novelty. The current score survives replay, but only while this study exists. We are not yet writing it to a file.

## Read the record

`replay` stops the players and resets the clock and `cursor`. It leaves `score` and the random generator untouched. `cursor` is the address of the next event, starting at zero. Every frame, `elapsed` grows by `delta`. When an event's stored time has arrived, its player receives the chosen clip and starts.

The `while` matters. A slow frame can cross more than one event time. The loop dispatches every overdue event in order and advances the cursor after each one. An `if` would dispatch only one per frame and could leave overdue events waiting. Six players allow overdue notes to overlap instead of replacing one another in a single player. `event_started` reports the dispatched index; the tests use that signal to inspect what happened.

This is a frame-timed sequencer. If a frame is very late, overdue notes start together. The saved choices and intended times remain the same; the heard timing is not sample-accurate. Effect Sound calculated samples at 44,100 per second. Starting playback from `_process` is a different clock, with frame and audio-buffer delays.

## Predict, replay, change

Read the first event's row and time aloud. Trigger REPLAY. Check its entrance and the moving guide. Replay again: every marker must remain in place, with the same row and timestamp. Then choose NEW. The displayed choices are replaced and the clock starts again. The larger museum soundscape continues independently; it does not share this replay command.

For your own variation, set both `min_interval` and `max_interval` to `1.0`. Predict all six timestamps before running. They should be 1, 2, 3, 4, 5 and 6 seconds, while the selected voices can still differ. Explain what became periodic and what still varies. The download includes this complete variation as `08_equal_intervals.gd`; attach it instead of the main script to compare.

Keep the distinction between selecting an event and starting it. In Air Music, your strike will supply the beginning. The sound can continue after your contact ends.

## Carried code

`note_voice.gd` — Effect Sound's unchanged sample and note functions, gathered into a small reusable helper. `make_note` returns a clip; it does not play it.

{VOICE_CODE}

`point_body.gd` — the point and its existing pickup behaviour.

{POINT_CODE}

`line_skin.gd` — the finite cylinder used for rows and playhead.

{LINE_CODE}

Implementation references: [Godot RandomNumberGenerator](https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html) and [audio synchronisation](https://docs.godotengine.org/en/stable/tutorials/audio/sync_with_audio.html). The installed soundscape is `algorithms/wavefunctions/technoirgameaudio/john_cage_tech_noir.gd`. Its prepared vocabulary and live scheduling are richer and different from this six-event study. Neither this lesson nor that artifact records your breath or performs a particular Cage score.
