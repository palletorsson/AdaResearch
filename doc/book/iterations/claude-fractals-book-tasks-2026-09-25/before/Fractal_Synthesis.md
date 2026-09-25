# What, exactly, is repeated?

<!-- @cantor_set -->

Can you explain two recursive constructions without using their names?

Start at the interval. Before NEXT, describe one step to another person, or say it quietly to yourself: take an interval, keep two shorter intervals at its ends, and repeat on each survivor. Point to an example of the input, the descendants and the gap. Then identify where the displayed construction stops.

Try the description without pointing. “Shorter” leaves something undecided. How short? At which ends? This desk begins with six metres and keeps thirds. After one cut there are two pieces, each two metres long. Before the second cut, predict both the number of pieces and their combined length. They will not change in the same direction.

Here is the step that actually creates a descendant's size:

```gdscript
var new_length = bar_length / 3.0
```

In `cantor_set.gd`, `perform_iteration()` creates a left bar and a right bar of that length, each centred a third of the parent's length away from its centre. The middle receives no surviving bar. The call preserves the position needed to place its descendants; “repeat” alone would not tell us where they belong.

After three cuts, press HISTORY. The upper rows disappear. Has another third been removed?

The lowest eight pieces stay where they were. Together they retain about 1.778 metres. What disappeared was the visible record of earlier stages. Bring it back, then try GHOST. Pale middles mark the new removals at each row. These markers have no collision bodies and do not re-enter the surviving population. We can change what the drawing lets us examine without undoing the selection rule.

This difference matters to our question about possible bodies. A drawing can omit a history while retaining the state that history produced. It can also make an absence visible without making that place available to stand on. Neither visibility nor omission tells us everything about what the program permits.

The fifth cut is the desk's last. It leaves thirty-two finite pieces. The stopping point gives our attention and this instrument somewhere to stand. It does not establish that further difference is impossible. RESET returns to the uncut beginning; it does not rewind the museum.

<!-- @recursive_tree -->

The red block tree has already branched. Find a fork that seems to end, and follow it backward. What would a call have to remember to place a smaller branch there?

Press STRATA. The blocks change colour according to their recorded branch levels. Press REACH and volumes enclose the extents accumulated through those levels. ENDS adds marks at the deepest recorded blocks. FORM brings the solid reading back. Compare the same fork through these views: none of these buttons grows a new tree.

The source receives a parent, an origin, a number of branches and two depth values. Its stopping condition is small enough to read in one breath:

```gdscript
if current_depth >= max_depth:
    return
```

Later in `recursive_tree.gd`, `generate_branches()` passes the continuation on:

```gdscript
generate_branches(branch, end_point, num_sub, current_depth + 1, max_depth)
```

The surrounding code chooses dimensions, directions and descendant counts with a local random-number generator. This placement starts from seed 12345. The nested calls stop after three branching levels. A seed is one part of that recipe; the generator, draw order and ranges also matter. The desk's changing colours and cages read the resulting geometry without drawing those random choices again.

Try the incomplete description “make several smaller things.” It could describe both desks and reconstruct neither. The intervals need a retained fraction and placement rule. The tree needs inherited origins, directions, dimensions and descendants. A cage around its reach adds another representation: it encloses empty space as well as blocks. It is not a new shelter with solid walls.

We have accumulated ways to make form, and ways to mistake a reading for the form. The queer possibility here is a question we can keep material: which instruction would have to change for another body to have room? Another colour might help us notice a branch. Another branching rule might alter where the branches can go. Those are different interventions, with different consequences.

<!-- @ -->

The collection beyond offers further procedures to compare. Its held examples leave time for looking; the moving works keep their own clocks. We do not need to turn every resemblance into the same law.

The names on these desks arrived late in another sense. Cantor's set is dated 1883, Koch's curve 1904, Sierpinski's triangle 1915, Menger's sponge 1926, and the word that gathers them, *fractal*, 1975. The structure is older than any of them. The Ba-ila settlements of what is now Zambia were built as a ring of enclosures, each enclosure itself a ring, with the chief's ring at the back of the village repeating the whole at a smaller scale, long before a mathematician called the arrangement self-similar,[^1] and the geometric ornament of Islamic architecture repeats a motif inside itself at descending scales for reasons of its own. A rule can be practised for centuries before it is written down. These desks show the written form. They do not show who was already building it.

Carry one explicit rule into the grammar laboratory. There, a string is rewritten before it is read as movement, and the interval you cut five times in the Cantor hall is two letters and two rules: `F` draws a step, `f` walks one without drawing, and every rewrite turns `F` into `FfF` and `f` into `fff`. Read the sentence after five rewrites and the bar's thirty-two pieces and their gaps are already in it, in order, before any turtle has moved; the lab keeps it as the preset called “Cantor”. Its preset called “Koch Curve” is a different Koch from our snowflake, one that replaces `F` with `F+F-F-F+F` and turns ninety degrees, so even a familiar name leaves work for us to do. What does an instruction become when another reader gives it a body?

[^1]: Ron Eglash, *African Fractals: Modern Computing and Indigenous Design* (Rutgers University Press, 1999).
