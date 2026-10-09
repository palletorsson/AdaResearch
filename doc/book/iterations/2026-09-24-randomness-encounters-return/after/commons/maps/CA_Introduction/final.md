# What will the next row do?

The rug is already changing. On the other side of the dividing wall, a board holds one green cell and waits. Two ways of making a pattern occupy the same hall. Begin with the one that has left you time to answer.

We have carried noise a long way: across a sheet, into a volume, around the body and under a foot. A little variation can satisfy the first wish for something organic. Its ease is part of its power. It can also make that first answer so familiar that other possible forms remain in its shadow. Keep the pleasure of the blob. Bring an unfinished question with it.

<!-- @ca_rule_explorer -->

The board waits in the left-hand corridor near the entrance. The newest row sits along its far edge; the rest of the board is room for a past. Three small marks pick out a cell and its two neighbours. Read their states on the side plate, but leave NEXT for a moment. What would you make from these three?

Press STEP. One generation arrives, and the previous row moves towards you. The pink mark stays at the same address. Its state may change. The plate now reads this new generation and predicts the one that could follow it. We have advanced the local machine; the rug has kept its own time.

Begin with Rule 90 and the single seed. STEP once, then again. Follow one of the diagonal edges. Choose CELL to move the witness along the current row, and check a neighbourhood inside the pattern as well as one at its edge. Counting the green cells is tempting. Keep their order too: left, self, right.

The explorer consults its rule through these actual lines:

```gdscript
func _apply_rule(left: bool, center: bool, right: bool) -> bool:
	var neighborhood = (int(left) << 2) | (int(center) << 1) | int(right)
	return (rule >> neighborhood) & 1 == 1
```

Three on/off states make eight possible arrangements. The shifts place them into an index from zero to seven. The rule number stores eight answers, one bit for each arrangement. Reading the selected bit gives this cell's next state.

For Rule 90, compare `100` with `010`. Each contains one occupied cell. The answers differ. A count would have discarded a relation that this rule uses. A neighbourhood is already a decision about what information may matter.

Choose Rule 30 and keep the single seed. Its rows quickly become harder to anticipate by eye. The board still asks the same small question at every position. A more tangled picture has not made the instruction longer. RUN lets the generations arrive automatically; pressing it again holds them, and STEP always leaves this study held after one update.

The update writes a separate row. Here is the loop inside `_advance`, followed by the moment the new row becomes current:

```gdscript
for i in range(cells_x):
    var left = _current_row[(i - 1 + cells_x) % cells_x]
    var center = _current_row[i]
    var right = _current_row[(i + 1) % cells_x]
    new_row[i] = _apply_rule(left, center, right)

_current_row = new_row
```

All the questions go to the old row. An answer written at the left cannot slip into the question being asked at the right. This installation builds that separation into its update step, the same under every rule number. A different update order would be another experiment to specify.

Press SEED. Two adjacent cells now occupy the starting row. The rule has stayed where you left it. Advance again and compare what happens where their consequences meet. Changing the beginning explores something that changing the rule alone could leave unseen. RST returns to the selected beginning and clears the visible history.

Keep stepping until a pattern reaches the boundary. The witness can cross it too: after cell 31 comes cell 0. The modulo operations in the loop join the two ends. What looks like a line on the desk is a ring to the calculation. Twenty-four rows fit on this board; older rows leave the display while their consequences remain in the current state. Once again, the visible past is smaller than the past that brought us here.

<!-- @persian_rug -->

Across the entrance, an opening in the dividing wall leads to the rug. A detail in one quarter has partners across the cloth. Find them before naming the symmetry. The pink border and golden interior are another division to follow. Both can change, but they do not consult identical conditions.

This work has a two-dimensional grid, several states and two sets of local rules. The border and interior decide differently when activity begins, continues or fades. After calculating a generation, the program also mirrors one quarter into the others. In `_enforce_quadrant`, one value is written into three reflected positions (comments between these assignments are omitted):

```gdscript
grid[row_offset + (width - 1 - x)] = val
grid[mirror_row_offset + x] = val
grid[mirror_row_offset + (width - 1 - x)] = val
```

The ornament has several makers: local updates, a chosen boundary, a palette, and this repeated act of copying. The mirror remains at work after the first seed. Knowing that can give us another way to enjoy the rug. We can follow a changing detail while noticing the procedure that makes its companions answer together.

The title invites an association with a textile tradition. These few operations do not account for that tradition, its materials or its makers. They produce this particular computational cloth. Its source offers other stencils and divisions to investigate later; the rug in this hall uses the mirrored quarters and frame.

<!-- @line_network_ca -->

Return to the board's corridor and follow it past the agents painting a shared surface. Further along, a small tangle of coloured lines waits above the floor. Approach it. Another set of lines arrives, then another. The figure unfolds over a few seconds, with time to keep an older connection in sight while new ones appear.

You are watching a saved growth history. The same fixed frame holds its twenty stages, so a line already present stays where it was. Move around it and let one apparent knot separate into lines at different depths. Some space that looked full can open when your viewpoint changes.

Its growth begins with a random walk. During a bounded burst of updates, occupied frontier positions may add a nearby cell. The drawing then connects each newly encountered position to one of its neighbours, if any neighbour has already been recorded. There is a detail worth keeping: the parent in the drawing is selected during the scan. The line does not prove which earlier cell caused the birth.

Chance proposes an addition; stored occupancy constrains where it can occur; the drawing supplies connections and colour. After twenty updates, the history stops and the whole network remains. **REPLAY** lets the same stages return. It repeats what was kept, rather than asking chance for another growth.

The stillness has a limit written into it. Twenty updates were allowed; the shape did not announce that every possibility was exhausted. We can enjoy its resemblance to an organic body while learning to ask what brought this particular body to rest.

We can begin to distinguish forms by the relations that sustain them. The board keeps a row and repeatedly rewrites it. The rug combines local activity with an imposed symmetry. The network retains occupied positions and draws a selected account of their connections. Their resemblance to living things can invite us closer; the code gives us further differences to explore.

<!-- @ -->

Other works remain in the hall. The orb rests on the rug's edge, and a showcase waits at the end of the passage that runs on beyond the rug's room. Past the network, a Rule 110 display stands near the corridor's far end. Let them offer further directions without asking this first encounter to explain them all.

For now, carry three choices: what a cell can hold, which neighbours it can consult, and when its answer becomes available to others. Our next comparison, the structure-growth specimen, makes the neighbourhood three-dimensional and gives disappearance more than one state. What forms need a little longer to go away?
