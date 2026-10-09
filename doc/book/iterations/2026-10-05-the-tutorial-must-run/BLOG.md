# The tutorial must run

*Writing for an imagined student, with code that has to work · 5 October 2026*

The counter was missing its label. On the page, the explanation of a game loop sounded complete: initialise in `_ready()`, update in `_process()`, watch the number change. But the example used an object it had never created. Palle noticed. The lesson asked a beginner to cross a gap that its author had stopped seeing.

That small omission clarified what we needed from the tutorials in Endless Museum. A convincing explanation is only one part of the work. The student must be able to reach the result using the code on the page and the support we have explicitly given them.

The museum already exists. Its rooms, player, lighting and XR systems form a prepared environment. The student encounters finished artifacts there, then builds selected, reduced versions of their own. We do not need to teach the whole museum before making a point. We do need to say which parts the student is borrowing, which they have already made, and which they are making now.

![Pens and their small readouts stand inside the existing Point Trace hall.](trace-hall.png)

*The existing Trace hall, captured on 29 September. It offers more encounters than this lesson teaches. The new student example follows the previously built dot; this capture does not show or verify that new program.*

Our hardest problem has been choosing the object of each lesson. A room may contain several interesting implementations. An AI can explain any of them at length and still miss the intended progression. In Coordinates, we want the student's point to become pickable and to reveal local and world positions. Distance belongs in Lines. Trace keeps the moving point's positions and introduces an array, a condition and a loop. These choices come from the developing curriculum, not simply from whatever source file is largest or easiest to describe.

There are also two written tracks. `final.md` follows the encounter through concrete, poetic and critical reflection. `tutorial.md` gives context, explains the chosen operation and prints the complete small program. Some artifacts belong to both. Some belong to one; others remain part of the field we explore. Keeping those sets distinct gives each text room to do its job.

The continuity becomes material when we preserve the student's code. Point One constructs a visible sphere and its matching collision boundary. Coordinates carries that construction into a pickable body. Lines adds another endpoint and a visible relation between them. Trace removes that second endpoint and keeps successive positions of the original point. Each lesson names what remains, what changes and what is left behind.

We call the saved reconstruction the **ghost student**. It is code for the work an imagined learner should be able to have reached. We execute it with the real engine and the declared libraries. This gives our imagined encounter something that can resist the writing: a missing label, an incorrect coordinate frame, or an explanation whose code does something else.

The ghost is also a limit. Its success is evidence about reconstruction. A person still has to tell us whether the lesson makes sense, whether its pace is tolerable, and whether they can use the idea to make another work.

Before expanding a lesson, we write a compressed brief. Its job is to keep the teaching choice available while the project grows. For Trace:

> **MAKE:** carried dot leaves a trace. **BRING:** tested Lines point, pickup, coordinates, segment helper. **GIVEN:** prepared museum, XR hands, library. **BUILD:** retained local positions; append after minimum distance; loop over neighbours. **CHECK:** pause adds nothing; small moves accumulate; return preserves order; change spacing and predict. **LATER:** timestamps, file saving, Grid transfer, production pen behaviour.

This is short speech for a future collaborator. The learner's explanation needs more room. We explain why an array starts with one position, why its last valid index is its size minus one, and why comparing with the last saved position differs from comparing with the previous frame. Removing those distinctions would make the paragraph shorter and the lesson harder.

The rules we now ask each tutorial to pass are specific:

1. **Choose a capability.** State what the learner will be able to construct, change and explain. Check that it belongs at this point in the sequence. Source code alone cannot make that choice.
2. **Declare the starting state.** Name the previous tested script and the supplied environment. Keep learned code separate from borrowed infrastructure. A continuation must actually continue its predecessor.
3. **Print the working example.** Show the complete small program once, with its small required helpers. Initialise the objects it uses. Downloads supplement the page. An unexplained scene reference must not conceal missing construction.
4. **Execute the printed code.** Extract it without repairing it, compose the declared continuation and run it in Godot. The test may supply the camera and XR library; it must not quietly supply the lesson's missing sphere or label.
5. **Test the claimed behaviour.** Assertions must examine the relation being taught. For Trace, check retained positions, sampling, order and segment endpoints. A screenshot or successful compilation cannot establish all of these.
6. **Challenge the tests.** Introduce a relevant fault and require the ordinary checks to reject it. A test that accepts the broken lesson provides little reassurance about that failure.
7. **Test the experiment too.** Name a small change, ask for a prediction, and provide its complete tested variant. The student should be able to distinguish a changed record from a changed drawing of that record.
8. **Keep evidence attached to its version.** Record the lesson, incoming code, output, dependencies and checks. If a relevant source changes, mark the evidence stale until checked again. Keep the old result as history.

These are different gates, with different kinds of evidence. Focus and readability require editorial judgement. Runtime assertions check bounded behaviour. Explanation and independent use need a learner. We must not turn their different outcomes into one reassuring “perfect tutorial” score.

Trace now has **124 passing native Godot checks**. Its exact printed code continues the tested Lines state. The checks exercise real XR Tools with simulated controllers, including pickup, small accumulated movements, pauses, turns, release and another pickup. They inspect the ordered positions and the segments connecting them. Both complete exercise variants are included. Removing the distance condition causes expected failures; connecting the wrong neighbours does too. The [saved report](../2026-10-05-trace-the-carried-point/student/report-runtime.json) records the results. Source hashes still matched when this article was built.

The number is less important than the questions. Does a pause add a position? Do several small movements eventually cross the threshold? Can returning to an earlier place produce another entry later in the list? Does the displayed segment connect the right two samples? These checks follow what the lesson says the student can observe. Headset comfort, visual quality and human understanding remain untested by this headless run.

Grid makes the next promise precise. We want the student's retained trace to acquire another set of addresses. Keep the original list; derive a version whose positions lie on a grid; compare them while changing the spacing. The array index names a sample in the journey. A grid address names a place in a lattice. Several samples can be assigned the same place. A finer grid cannot recover a movement that Trace never retained.

That is a proposed continuation, not a completed transfer. The current learner trace uses its station's local coordinates and lives with that station. The older museum Grid lesson receives world-coordinate snapshots from the production pens. Those are different starting conditions. We must explicitly bridge them, or first continue inside the same learner station. A familiar-looking line in the next room would not prove that the student's record had arrived there.

This is the useful force of our “type-safe” writing analogy. A node, a saved position, an array index and a grid address can be connected without being treated as the same thing. So can an authorial intention, a test result and a learner's understanding. Naming their edges helps the code travel and keeps the writing accountable.

We are preparing for a student who has not yet arrived, while the tools and conditions of learning continue to change. The short brief holds the current intention. The full tutorial makes it accessible. The executable record lets the next lesson inherit actual work. Each can be revised, but the revision has to tell us what changed. The future student deserves a page whose promises we have tried to keep.

---

*Local research journal, 5 October 2026. This article documents the current method and Trace evidence; it does not certify the whole curriculum. Grid's learner continuation remains to be built.*

[Read Trace beside its reflection](../2026-10-05-primitives-facing-pages/Point_Trace.html) · [Working reconstruction rules](rules.html#rules-for-accepting-the-next-lesson) · [Trace code and evidence](../2026-10-05-trace-the-carried-point/index.html) · [The earlier memory essay](../2026-10-04-memory-that-can-change/index.html) · [Ghost Student](http://localhost:3003/ghost-student?state=point-trace)
