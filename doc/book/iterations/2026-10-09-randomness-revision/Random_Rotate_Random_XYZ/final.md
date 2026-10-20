# What remains in a changing stack

The last room kept adding the results of a throw. Here a contribution can also take something back. Which part of an arrangement can change while its pieces remain?

<!-- @hardware_entropy_decay -->

Along the wall on your right as you come in, a rig holds three shapes that weather together: a box, a sphere and a cylinder, with the same wear pushed to all three at once. The rust rises slowly by itself and faster while you move. Swing your hands, squeeze a grip, turn your head. Scratches follow your hands and fade when you stop; the grime and the rust stay. Nothing in the rig draws a random number. In the headset, a surface can look worn by accident when its grime and rust are a record of how you moved in front of it.

<!-- @ -->

<!-- @random_decay_multimesh -->

Further in, a long display crosses the hall. On your right as you face it stand twenty cubes in a block five wide and four high; on your left, a hundred and twenty prisms in twelve columns of ten. Every piece is the same size. None of them has a body, and the way on passes through the prisms.

The pieces may already be turning when you arrive; after a **RESET** they stand in line for a few seconds before they begin. Each turns in the plane of its stack, a little at a time. Nothing else changes. Their size never changes, and in this room neither does their place or their colour. An arrangement can become less regular without any piece changing place, shrinking, disappearing or becoming a different kind of object.

The demonstration keeps a changing state for each instance. Every piece carries one hidden number that starts at zero and grows by itself, and now and then a random kick lands on a piece and adds to it. The larger the number, the harder that piece is shaken. Its angle has no limit: each small turn is added to the last. A small angular change repeated many times can produce a visibly altered orientation even though no single step seems dramatic. Give it time. The implementation takes a new update on each drawn frame, so how far it turns also depends on the machine drawing the room. Its apparent patience is partly a setting and partly a condition of its execution.

After a minute or two, find the piece that has turned furthest and lay its edge against the line of its neighbours. It has not moved, so its neighbours are still its neighbours. Then find one that has barely turned, and explain that one difference before judging the whole stack.

Left to its defaults, the hidden number also makes each piece drift, sink and darken, so one broad description of disorder can conceal different changes. Here the drift, the sinking and the darkening are switched off, and only turning is left to follow.

Both stacks now run at the same rate. Each piece in either stack follows the same rule: a stack receives kicks in proportion to its number of pieces, so every piece can expect the same share. Outside this room’s comparison, the default settings give the cubes a higher rate than the prisms. A difference produced by that setting would not establish a difference caused by shape. What still differs here is shape, colour, number and spacing, so a difference you think you see is not yet a difference of shape alone.

The panel in front of the display is labelled DECAY. The label names the model's presentation; it is not a measurement of thermodynamic entropy or a complete physical explanation of how a material deteriorates. **TOGGLE** pauses the turning and keeps the time already run; press it again and the turning resumes where it stopped. **RESET** puts every piece back in line and starts the delay over. The renewed view restores a reference for comparison, not the turning that followed it: RESET does not rewind the random draws, so the turns that come after it are new. Note which piece leads before a RESET; a minute or two after it, a different piece will usually lead.

<!-- @ -->

<!-- @RotateGridCubes -->

Behind the stacks, twenty-five cubes make a low square field. The first row lies level; the middle pitches upward; the last lies level again. Nothing keeps turning as you watch. The angle follows a row’s place along half a sine curve. Walk along its side. The same arrangement returns whenever the hall is built. Here your walk supplies the sequence: level, inclined, level again. Rotation can be a rule about place as easily as a record of chance.

![Twenty-five cubes, level at both ends and tilted through the middle, fit behind the changing stacks.](figures/tilt-field-contained.png)

<!-- @ -->

The tutorial holds two cubes beside one another and gives them the same recorded turns. One takes the latest value; the other adds it to what came before. On the first step they agree. Later, the difference belongs to what each cube retains. To give two things the same input is not yet to give them the same history.

Here each piece shows only where its turns have added up to; the turns leave no trail, and RESET wipes even the sum. The random-walk room keeps a trail of one accumulated quantity, position, so there you can separate the next-step rule from the record of earlier steps.
