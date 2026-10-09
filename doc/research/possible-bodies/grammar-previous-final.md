# Change the sentence, change the reading

<!-- @lsystem_editor -->

Can you change a drawing without changing the instructions it contains?

Choose a preset in the L-system editor. Leave GEN where it is and move ANGLE. Follow one branch as its direction changes. You have altered how a turning instruction is interpreted while keeping the generated sentence at the same generation.

Now hold ANGLE still and increase GEN by one. Look for added segments and repeated branch arrangements. This time the sentence itself has changed: another round of rewriting has replaced its symbols before the drawing begins.

Choose a branch near the beginning of the drawing as your reference during both changes. An angle adjustment should let you follow corresponding segments through a changed orientation. An added generation can introduce segments that have no one-to-one counterpart at the earlier level. Do not rely only on the bounding outline, which the display fits to its available space. Compare a local fork and the route leading into it. That gives you a more stable basis for distinguishing a changed interpretation from an expanded sentence when both alter the silhouette.

The fractal halls let you follow a construction through its descendants. The Koch preset brings a familiar curve into this room, where the instructions and their interpretation can be considered separately. First, an L-system rewrites a string. Each symbol in the old string is replaced according to the selected rule, with the replacements collected into a new string. Next, a turtle interpreter reads that result as movements, turns and saved positions.

The turtle is a travelling state: it has a position and direction. Drawing symbols move it while leaving a segment; turning symbols change its heading. Brackets save the state and later restore it, allowing a branch to finish before the turtle resumes elsewhere.

Watch the overall size carefully. The drawing is fitted into its display after generation. A more elaborate sentence may therefore occupy roughly the same space as a simpler one. Height alone cannot tell you how much rewriting has occurred.

The current editor offers presets and numerical controls, rather than a place to type any replacement rule. A useful extension would show the unchanged sentence beside two angle settings, then let you alter one replacement and predict its first consequence.

<!-- @ -->

In the next room, the travelling state carries more than position and heading. Branch length will change as the interpreter enters and leaves nested branches.
