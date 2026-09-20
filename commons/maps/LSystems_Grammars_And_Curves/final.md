# When forward goes sideways

<!-- @the_believing_turtle -->

Does an instruction say how it must be obeyed?

Three short lines rise from three origins. Each has read the first F of the same sentence, taking a stride of 0.32 metres. We have kept the travelling state from Growth, but the question has moved: what agreement connects an instruction to a movement?

Press READ F. The blue line goes sideways. Its gold arrow still points up; its white arrow points across. The gold arrow shows the stored heading, the white one the direction the reader will draw. Those two directions no longer agree.

The sentence has not changed. Neither has the stride. This reader takes the direction it was given and exchanges its x and y components. What used to contribute to height now contributes to horizontal distance. Before seeing a whole tree, we can catch the disagreement in a single step.

Now press ANGLE. The middle reader changes from twenty-five to forty-five degrees. Its first line stays upright. Why did this change produce no visible turn? Keep pressing STEP until the sixth symbol. The first two Fs extend the stem; a plus turns the heading; a bracket saves it; another plus turns again; the next F draws. The middle reading has departed from the green reference. An angle matters when an instruction uses it.

All three readers follow:

```text
FF+[+F-F-F]-[-F+F+F]
```

There are twenty symbols and eight drawing instructions. Finish the sentence, finding corresponding forks as you go. When the brackets close, the saved positions and headings return, as they did in Growth. Each drawing has read the same bracket at the same moment. Yet one spreads differently, and another seems to have forgotten which way a tree should stand.

Here is the direction calculation in the believing turtle:

```gdscript
var dir := Vector2(cos(heading), sin(heading))
if sideways:
    dir = Vector2(dir.y, dir.x)
```

The angle called heading supplies the two components of a unit direction. The conditional exchanges them. The next line uses that direction to take a step in the museum's drawing plane:

```gdscript
var nxt := pos + Vector3(dir.x, dir.y, 0.0) * step
```

The third component is zero: these drawings remain planar inside a three-dimensional room. The step multiplies the direction; adding it to the current position gives the next position. This is the vector operation we brought through the earlier halls, now given another reading.

Try to match every blue fork to a green one. The correspondence is unusually dependable. With the same angle, exchanging x and y at every step reflects the entire construction across the diagonal x = y, relative to its origin. It preserves lengths, angles between segments and which branches connect. A reflection can overturn our expectation of uprightness while retaining this much structure. It is not simply a ninety-degree rotation; follow an off-axis branch to see the difference.

Press READ F again. The blue reading returns to the green one's arrangement. The exchange is reversible. Its strangeness has a precise operation we can repeat, inspect and undo.

TREE gives all three readers two complete rewriting generations: 172 symbols, 64 drawn segments. The same local differences accumulate across a larger body. No drawing has been resized to fit its case. Find the first fork again before trying to recognise the whole outline. More detail can obscure a relation we understood one step earlier.

STEP reveals recorded interpreter states, not a calculation suspended between button presses. After the last symbol it returns to the beginning of the reading; RESET also restores the initial angles and forward convention. The original lectern and its smaller studies remain behind this desk, including their unequal step lengths and finite drawing prefixes. They offer another comparison, with different conditions.

Calling this reader a believing turtle gives us a way to attend to its commitments. It does not give the turtle an inner conviction. The commitment is executable: F is assigned a direction through this code. We can change that assignment. We can also ask what the change has left untouched. The branches still have no collision surfaces; a sideways drawing has not yet become somewhere we can stand. That further desire needs another operation.

<!-- @ -->

The floor curves and the volumetric path remain in the collection. Their finite constructions let a sentence visit many grid locations; they do not occupy every point of this room. Beyond them lies Architecture. A step will acquire width, a branch may become a corridor, and a return will have to be considered in relation to a body trying to find its way.
