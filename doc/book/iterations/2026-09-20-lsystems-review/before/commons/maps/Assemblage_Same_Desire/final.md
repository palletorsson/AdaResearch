# Two marks, many paths

<!-- @ten_print_textile -->

When you see a path in this textile, who connected its pieces?

Choose several neighbouring diagonals and follow the line your eye makes through them. At a fork, notice which continuation you choose. Read the same area from the other end. The marks have stayed still; your route through them may change.

Living gave us a witness that could stay while a design changed. Press HOLD here. A second sheet keeps the current marks beside the one we can edit. Now press ALPHABET.

The diagonals become horizontal and vertical bars. Keep looking at the same small group of cells. Has its path survived? Press ALPHABET again. One outcome becomes a large block, the other a small block. What looked like a route may now look like a density, an enclosure or a scattered set of objects.

The choices have not been made again. Each of the sheet's 144 cells still holds the same random sample. The same threshold still selects its outcome. We changed what that outcome draws.

The original diagonal alphabet gives its bar one of two rotations:

```gdscript
bar.rotation.z = (PI * 0.25) if slash else (-PI * 0.25)
```

PI radians is half a turn; a quarter of PI is forty-five degrees. The sign chooses which way the bar leans. The other alphabet uses zero and half of PI, producing a horizontal or vertical bar. The stored choice can pass through either interpretation. Its address in the array does not move.

The grammar rooms taught us to distinguish a sentence from the turtle that reads it. Here we hold a record of choices and give it another set of marks. A picture can change substantially while the decisions remain intact. That does not make its appearance incidental: the marks give us different relations to follow.

Return to the diagonals. Try ODDS. The next setting is 0.75. Some blue marks become warm ones. This time the decisions changed, although the samples did not.

Each new cell originally receives a sample and compares it with the threshold:

```gdscript
var sample := _rng.randf()
var slash := sample < odds
```

ODDS reuses that recorded sample. A value between 0.5 and 0.75 changes sides when the threshold moves from one to the other. A value below 0.5 was already admitted. The screen counts how many cells choose A; a threshold of 0.5 does not require exactly half of a small sheet to choose it.

The difference is now precise. ALPHABET changes the marks while holding the decisions. ODDS changes the decisions while holding the samples. SEED supplies another reproducible set of samples. HOLD lets one resulting sheet remain beside these experiments. RESET returns the editable sheet to its opening state.

Press STEP. The oldest row leaves the bottom; a new row enters at the top. The other eleven rows keep their samples and shift down. The small automatic textile behind the study runs this operation over time. A finite window lets us watch an ongoing process without keeping every mark it has produced. The discarded row may matter to a route we were following. It is no longer in this window.

Walk onto the pattern beyond the desk. The same choices have been drawn across the floor. Follow a diagonal, then cross it. The floor supports both movements. Changing the marks changes what the surface invites you to follow; it does not cut a passage or raise a wall. No collision boundary follows these lines.

That distinction gives us a next experiment we have not built: let a mark become a barrier, then test whether the same array remains traversable. We would need to decide what counts as a connection, construct its collision and check a route. A maze-like image has done none of those things for us.

The paths can be real features of the image without being planned routes. Your reading and the generator's operation are different contributions to the encounter. The pleasure of finding a way through need not disappear when we learn how little the generator knew about it. We gain a place to intervene: in the choices, the marks, their connections, or the body that will approach them.

<!-- @ -->

Stay with the rest of the room. The working loom computes which thread lies above another from a draft; its crossings depend on several related tables. The pattern galleries retain their maker names, including the gallery dedicated to Kristina Torsson. These are other procedures and histories beside the two-mark textile. Sharing a computational medium does not make them interchangeable.

The plaque and tilted scale invite a question about formal limits. Their presence does not turn this textile into a proof of incompleteness. The room can bring practices into conversation while leaving their differences available for study. The same desire is a question we carry between them: what can this way of making open, and where must we learn another way?

Next, generated forms will be compared using a numerical score. Until now a path could matter because we chose to follow it. What changes when a program is asked to decide which result should continue?
