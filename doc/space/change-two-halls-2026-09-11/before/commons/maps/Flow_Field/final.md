Can local directions produce a picture nobody drew as a whole?

The rectangle sum accumulated sampled contributions across an interval. Here repeated local readings move particles, and their trails make the accumulated result visible. Begin with one path before reading the whole canvas.

<!-- @flow_field_painter -->

Follow one trail through a bend. Predict its next direction from the nearby flow, then watch the particle continue. Notice whether neighbouring particles remain close, separate, or approach similar routes.

Hold SPEED fixed and change SCALE. Look for a change in how directions are organised across the canvas. Then leave SCALE alone and change SPEED. Compare the distance particles travel in a short interval with the shape of the field they are reading.

The painter samples a scalar noise value at a particle's location and converts that value into an angle. Cosine and sine turn the angle into a direction. A small movement along that direction is repeated on the next update, at the particle's new position. The field supplies local instructions; the trail retains a bounded record of the resulting path.

This direction is made from a noise value. It is not the noise function's gradient, which would require measuring how that value changes with position. The distinction matters when deciding what the picture demonstrates.

Use RESET to begin with a fresh particle distribution, or SEED to change the noise field. Keep track of which choice you made. Different paths can result from new starting positions under one field, as well as from a different field.

<!-- @ -->

Watch a particle approach an edge and predict where it will reappear. Opposite edges are connected by wrapping. Leaving the right side returns it on the left, so the edge is a join in this world's rule rather than an opening into unmodelled space.

The streams may recall a fluid, but this painter does not compute pressure, mass or interactions among particles. The resemblance gives you a way to notice the motion; it does not supply the missing physical quantities.

Choose a different boundary rule in thought. A particle might stop, reflect or leave permanently. What pattern would you expect each choice to preserve or disrupt? Those alternatives would require changing the implementation. The current wrapped canvas is one particular world in which the local rule operates.

The next room distinguishes everything that happened along a path from the difference left between its endpoints. Bring one trail whose journey would be poorly described by its final position alone.
