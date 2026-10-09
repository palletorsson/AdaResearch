---
title: "What a rule keeps"
subtitle: "Making the Fractals chapter through hands, rooms, runnable code and a ghost student’s unexpected comparison"
date: "2026-10-08"
author: "Ada Research"
sequence: "fractals"
tags: ["endless-museum", "fractals", "pedagogy", "research-process", "ghost-student"]
thumbnail: "/book-review/doc/book/iterations/2026-10-08-fractal-fork-in-the-hand/images/hand-model.png"
---

Take the black point and turn a fork. Its descendants follow. The other side of the tree stays where it was. An arrangement that looked like a collection of branches becomes a hierarchy you can act upon.

This small encounter helped give our Fractals chapter its direction. We already had a museum full of forms. The task was to discover which operations a visitor could learn through them, which objects could carry those operations onward, and where the writing should let the encounter remain open.

![Black and rose point grips sit on a branching hand model beneath a larger tree in Endless Museum.](/book-review/doc/book/iterations/2026-10-08-fractal-fork-in-the-hand/images/hand-model.png)

*The installed tree study. Turning a fork carries its descendants. The large canopy remains another encounter in the same room.*

The familiar sphere gave us continuity. It had already been a point, something to hold, and something whose positions could be recorded. Here it acquired several jobs. It edited a branch, requested another cut, read a position along a folded path, selected a cell, brought two values together and chose a recipe. Its appearance returned; its responsibilities changed. Each tutorial had to say precisely what the hand was permitted to alter.

That demand changed how we wrote about recursion. A repeated appearance does not tell us how a program produced it. A loop can draw nested frames. A self-call can build a family of joints. A list of intervals can be replaced by another list. We wanted the student to name what was stored, what one step did to it, and what brought that process to a stop.

The seven halls developed different answers. Frames introduced the smaller call and its return. Trees made parenthood consequential. Cantor separated the current intervals from their recorded history. Koch returned to the ordered positions of Trace, this time produced by a replacement rule. Menger selected cells from a volume. The Golden Spiral hall separated a numerical recurrence from the different ways its values and proportions were shown. Synthesis gathered decisions into a recipe that could be kept while another version changed.

![A black point marks a rose Koch path across the museum floor, beside an upright orange construction and a triangular comparison.](/book-review/doc/book/iterations/2026-10-08-koch-the-distance-between/images/floor-fourth.png)

*The same ordered path receives different placements and scales. A distance along the path is not a record of how far the visitor’s hand travelled.*

Working in the room repeatedly complicated an easy sentence. We could say that a path grows longer, but its endpoints might remain the same distance apart. We could say that a sponge has more holes, but whether one becomes a passage depends on the body trying to enter it. We could show more of a construction’s history and make the picture denser without increasing the amount of material that survives in its current state.

These became distinctions worth preserving in both text and code. A small reader and a large room can refer to the same cell without making them interchangeable. A displayed branch can omit how it was generated. A numerical value can stay fixed while another mapping changes its apparent height. The critical writing became more useful when it stayed near these particular acts of showing and withholding.

![A miniature cell study stands beside the full-height Menger structure and its flight entrance.](/book-review/doc/book/iterations/2026-10-08-menger-a-cell-and-a-room/images/cell-and-room.png)

*A cell and a room. The miniature reads a selection; the larger encounter asks what that selection permits a body to do.*

We kept two texts with different work to do. The tutorial prints the complete small construction and names its dependencies. The prepared Endless Museum supplies the player, camera, light and XR support. The student does not rebuild those for every lesson. The reflective text can stay with the room’s larger collection, the bodily encounter and the questions its operations open. An artifact does not need to appear in both tracks to deserve its place in the museum.

The code also had to meet a harder condition than looking plausible on the page. We extracted the printed programs, ran them in Godot and asserted properties that mattered to the lesson: a child stays attached to its parent, a new list leaves its source intact, a saved recipe survives another edit. A screenshot could then show what those properties felt like as an arrangement. It could not replace the checks, and the checks could not decide whether the arrangement was readable.

![A point selects a live interval recipe while a rose row retains a different recipe on a museum table.](/book-review/doc/book/iterations/2026-10-08-synthesis-a-rule-kept/images/comparison.png)

*KEEP preserves a recipe. Both rows contain eight pieces here, but their retained lengths and gaps differ. The count is insufficient to describe either result.*

External feedback helped us see another limit. Following a finished example is not yet the same as making a choice with it. We added an optional task in Synthesis: combine one known construction with one earlier influence, state what receives the influence, predict what changes and what remains, then inspect the result. There was no required silhouette.

We tested that invitation with a fresh ghost student: an AI reader given the full chapter and its prerequisites, without our conversation or the writing agent’s worked example. It brought existing programming and mathematical knowledge. We asked it to name that knowledge, record predictions before execution, and preserve its first submission.

It chose a sine wave sampled by branch depth. Both children at a fork received the same added angle. This changed the tree’s outline while preserving the angle between siblings. With the chosen settings, the offsets over three levels cancelled in the final twigs’ directions, even though their endpoints moved. Native execution confirmed the distinction: some tips shifted by about seventeen centimetres.

Then the images made a further problem visible. The correct relationship was difficult to inspect against the museum’s busy background. From the side, the two planar trees collapsed into narrow profiles. The student chose to keep its generating rule and improve the comparison. It isolated one corresponding twig from each tree in a common frame, at the same scale, and joined their displaced tips.

![A dark comparison card shows parallel rose and cyan twigs with a link between their displaced tips and a reading of 0.166 metres.](/book-review/doc/book/iterations/2026-10-08-fractals-ghost-student/museum-revision/witness.png)

*The ghost student’s revision: change the reader of the construction. These are retained initial records; the card does not pretend to follow later hand edits.*

That was an important moment in the process. The student had a working rule, an explanation and a correct prediction. Observation still gave it a reason to make something else. The additional object served the question it was investigating.

The assessment also found things we should improve. A Golden Spiral comparison figure names Fibonacci-sized squares where the text describes successive cuts of a golden rectangle. Several exercises give away their answers too soon. The distinction between the small learner construction and the museum’s additional controls should be easier to find. These findings are recorded; they have not all been folded back into the chapter.

The testing process had faults of its own. An evaluator assertion used the wrong array type. The student’s separate command-line runner loaded an XR dependency too early, then printed a success message despite compile errors. We retained those attempts and corrected the runners separately. The lesson programs and original composition needed no repair. Accepting a pass required reading the error log as well as the final banner.

The resulting evidence is specific: runnable constructions, tested relationships, native museum views and one capable AI reader’s independent response. It does not yet establish what a beginning student will understand or how every grip will feel in a headset. The imagined recipient remains part of the work, while its needs continue to change.

For now, what the chapter gives us is a way to keep differences available. We can hold the original beside a changed version. We can distinguish a rule from its display and a hole from a passage. We can use a familiar object for another operation without forgetting what changed. The next writing pass returns to Cellular Automata, earlier in the book’s spine, with these demands made clearer: a cell needs a state, an address, neighbours and an explicit account of when its answer becomes available to others.

---

*Work journal, 8 October 2026. All five images are native Godot captures. The final image shows a temporary student construction in the existing museum, not a newly installed permanent artifact.*

*Read the [complete Fractals chapter](/book-review/doc/book/iterations/2026-10-08-fractals-complete-readings/index.html), the [open composition task and editorial return](/book-review/doc/book/iterations/2026-10-08-fractals-a-question-of-your-own/index.html), and the [fresh ghost student’s assessment and execution evidence](/book-review/doc/book/iterations/2026-10-08-fractals-ghost-student/index.html).*
