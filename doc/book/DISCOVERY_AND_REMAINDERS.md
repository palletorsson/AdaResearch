# A path with remainders

Authorial direction from Palle, 2026-09-08. This records the premise of the book and the next writing experiments. Source inspection supports the implementation notes below; no new visitor, headset or load test was performed for this note.

Ada Research teaches how a world becomes computable while letting its reader discover what that computation cannot carry. The working solution is itself available for wonder: a visible body for a point, a line between measurements, a finite record that makes another moment possible. Its usefulness does not settle what it is, whom it serves, or what another use could make of it.

The visitor arrives in a world already running, with a body, expectations and histories the program did not originate. Encoding and decoding continue throughout the encounter. A finer record is another made record; we do not offer an untouched original hidden behind the coarse one. Differences between records can still be measured, useful and consequential.

Time gives the book its path. The spine carries us from the point toward QFEP because a visit cannot pursue every branch. Completing a room means acquiring something usable and becoming able to notice another question. A handoff carries both. Earlier concepts return with different consequences; the reader changes between repetitions. QFEP must remain available to the same questions about assumptions, evidence and remainders as the point that began the journey.

The room text is the shared narrative source for the online tutorial and the book assembled from it. Code belongs inside that narrative: a small passage the reader can run, hear in its repetition, and alter. Every necessary comparison must be described well enough to be imagined on the page, while the tutorial offers the embodied attempt. A proposed interaction must remain labelled as a proposal in both forms.

## What the opening already lets us uncover

| Encounter | What the operation makes possible | A difference to investigate | Where play can go |
| --- | --- | --- | --- |
| Point One's counter | An engine can count its process iterations. | Its count begins before the visitor looks. Equal increments do not establish equal durations. | Compare waiting with counting; later give the same counts different temporal spacing. |
| The point's visible body | A dimensionless position becomes visible and graspable through an artifact. | Radius, collision, appearance and force behaviour were added; three coordinates do not specify them. | Keep a position identifiable while changing how it can be encountered. A change of body can change a permitted action. |
| World and local coordinates | One position can be described relative to different frames. | Different numbers can locate the same point; a rounded caption can stay still while the stored position moves. | Predict which account changes when the point or reference changes. A visitor-controlled moving frame is a proposal until verified. |
| WALK THIS LINE | Paint and language can orient a walk. | This marking does not detect compliance. Instruction, geometry and enforcement are separate constructions. | Follow it backwards or beside it. Notice what the sign changes without a scoring rule. |
| Perspective | A view can convey depth on a surface. | A diagram of convergence, a spatial arrangement and its projected image are different objects of study. | Compare views and identify which relations belong to the construction and which to the viewpoint. |
| The trace | Accepted measurements become a shareable path. | Sampling, movement admission, spatial snapping, storage and printed precision each distinguish different things. Connecting vertices does not recover the unobserved movement. | Make two gestures one recorder cannot distinguish. Give a coarse stroke a use of its own; change the criterion of success. |

These are invitations to discover. They should not become six conclusions announced before the reader acts. A critical opening can be the first disturbance in a room: the counter is already running, the point has acquired a costume, the painted line seems to ask something of the body. Explanation gives the reader a way to work with the disturbance. A subsequent experiment can then change the assumption deliberately.

Sara Ahmed's work offers a precise connection for the line: orientation concerns how bodies inhabit space, what becomes reachable and how repeated directions become ordinary. In [Queer Angles](https://feministkilljoys.com/2014/03/12/queer-angles/), she also attends to the uneven experience of disorientation. Our proposed use is to ask what makes following the stripe feel expected and what changes for someone approaching otherwise. Geometric straightness alone does not establish a claim about sexuality or power. The connection needs an account of bodies, instructions, habits and consequences. See also [Queer Phenomenology](https://www.dukeupress.edu/queer-phenomenology).

## Give each remainder its mechanism

The present counter uses `Engine.get_process_frames()`. A reading around 400 is a visitor's possible observation, not a scripted opening value. It counts process iterations since engine startup, including work that need not produce a displayed image. The panel's optional `arrival` epoch starts at its own `_ready()`; it is not a visitor-entry detector. Source: `commons/visualaid/frame_counter/frame_counter_display.gd`, lines 135 and 370–375; [Engine documentation](https://docs.godotengine.org/en/stable/classes/class_engine.html#class-engine-method-get-process-frames).

The pen scene keeps up to 4096 accepted positions and uses a 5 mm movement threshold. Point Trace's 10, 40 and 80 settings specify millimetres of spatial snapping, not samples per second. The table prints only ten positions, rounded to two decimals. A still printed number, a rejected sample and an evicted point are three different events. Sources: `commons/primitives/point/draw_dot.tscn`, lines 9–10; `draw_dot.gd`, lines 275, 388–420 and 689–697; `commons/maps/Point_Trace/map_data.json`.

There is no single helmet clock that explains all of this. Application processing, physics, tracking and display need their own accounts. Godot distinguishes frame-dependent processing from physics processing; see its [processing documentation](https://docs.godotengine.org/en/stable/tutorials/scripting/idle_and_physics_processing.html). This recorder can add at most one vertex per process call. Fewer observations during a curving gesture may produce longer chords and omit a bend; a straight gesture may remain straight. Additional load producing a jagged trace is a prediction to test, not an observation established here.

The next controlled comparison should replay one known input path through different recording intervals and retain timestamps, sample counts and resulting paths. It can show a sampling consequence without changing the whole headset's performance. An actual load comparison is a separate experiment requiring measured timing. Higher resolution can preserve a difference that matters, while spending time, memory and attention. The question is which difference, for whose purpose, at what cost.

There is also a concrete perspective question to develop in Point Lines. The placed `perspective_lines` artifact constructs finite lines whose endpoints approach selected targets; it does not itself demonstrate parallel world-space lines meeting through projection. Its default `reach:touch` makes the rods physically meet. That is useful as a construction diagram if named accurately. A comparison with actual parallel geometry and changing viewpoint would make the distinction observable. The placed `anamorphic_cross` currently defaults to zero depth separation, so its name alone cannot establish an anamorphic experience. Sources: `commons/primitives/line/perspective_lines.gd`, `commons/artifacts/anamorphic_cross/anamorphic_cross.gd`, and the current Point Lines map.

## Let code carry the rhythm

Use the smallest real operation that changes what the reader just encountered. Preserve the connection to its source and label reductions as reductions. Repetition, conditional admission, pauses, phase and forgetting can carry musical structure; musical language should point to something the code actually does.

For example, the existing pen contains:

```gdscript
if _trail_points.size() > trail_max_points:
    _trail_points.pop_front()
```

This is an excerpt of its capacity rule; the surrounding implementation also maintains sample times. It can appear after the reader has investigated what waiting and continued drawing do to a record. Reading the two lines gives a precise operation to change: making room has a direction, and here it is the beginning that leaves.

A possible passage, to develop against the encounter:

> Draw a loop. Stop your hand and keep looking. Does the record acquire another point during your pause?
>
> Try again with a little tremor. Find how small a movement can be before the count refuses it. Then take the coarser pen and make that refusal useful: can you hold an address steady while your hand keeps moving?
>
> The line has gained a steadiness your hand did not need to supply. What would you ask it to keep if the tremor, this time, were the thing you came to draw?

The first attempt should leave room for surprise. The explanation supplies an operation the reader can use. The variation changes what is valued, and the next room inherits the unresolved difference. This is a writing rhythm to vary, not a fixed set of headings for all 190 rooms.

A repair earns its place by enabling that discovery. A failure is worth retaining when the visitor can investigate its mechanism and consequences. We must keep asking what the room teaches after it passes its checks.
