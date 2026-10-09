# Coordinates — the point already in the hall

The tutorial continues from Point One using the existing held black point, basin frame and two cards in Endless Museum. It removes the instruction to instance another point or switch to a separate two-marker scene. No artifacts are added or removed. The old tutorial and implementation note are preserved in `before/`.

The learner changes the held branch's starting position in the same script read in Point One, then changes the existing card's decimal formatting. These are selected edits, not a replacement implementation. The XRToolsPickable relation is named as supplied. The lesson reads two position expressions in the running frame without requiring students to implement its group lookup, rendering or reporting connection.

The source check matters here: the held body's parent-local position is not the frame's LOCAL reading. The frame uses `to_local(pt.global_position)`, including its scale of 1.5. The black arm points towards negative Z. Card formatting changes the report, not the stored position. These distinctions prevent the simplified explanation from teaching a different system.

An independent reader checked the draft against source. 32 native checks passed inside the actual museum, including the half-metre starting edit, supplied pickup/release with a synthetic holder, WORLD/LOCAL reporting, a shifted reference, and the printed formatting edit. Both cards still follow the same point. The two decimal screenshots show the same unchanged position. Images were inspected directly; they are museum renders, not a separate illustration room.

Tests substitute edited scripts in memory at the original placements. The original artifact scripts, map and critical `final.md` are byte-for-byte unchanged from this pass's baseline. Canonical `tutorial.md` and its implementation note are updated. No physical headset or beginner reading test was performed. The engine log retains the existing unresolved audio-bus UID and renderer warnings; these focused checks do not certify the whole project. HTML links and anchors are checked programmatically; browser visual inspection was not performed.

The target, Fontana comparison and other objects remain part of the museum field. Distance belongs to Point Lines, which is next after this lesson has been read.
