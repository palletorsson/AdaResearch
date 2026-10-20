# A small wedge labyrinth

- The cheese has a symmetric triangular profile with its ridge over the centre of its base. It remains at the far end of the maze; “centre wedge” refers to its shape.
- The wedge orientation is reversed so the broad base rests on the plinth and the narrow ridge is above. Four bottom vertices and two upper vertices verify this for every wall.
- A 5 × 3 maze of 23 grabbable wedge walls sits in front of the mouse. Its physical passages include branches and dead ends. The route lies on the floor.
- One joystick stands upright on the plinth behind the mouse. The large panel and JUMP, HOME and RESTORE buttons are removed. Grip or pointer-drag to steer; release to stop.
- Lifting a wall pauses the mouse. Moving it changes physical access. A fallen mouse returns to the entrance after 0.7 seconds without resetting the walls. Re-enter the hall to restore the original arrangement.
- Mouse and cheese each retain one bare mesh. The mouse uses a capsule movement proxy; the walls and cheese use convex shapes made from their visible vertices.

The reference is Shannon's movable Theseus maze. The current mouse is player-steered and has no search policy, learned route or machine memory. This distinction is recorded in the final and tutorial.

The hall sequence remains blocking → climbing → sculpture → miniature maze → descent. The final, tutorial, technical notes, map summary, intent, inventory and registry description are updated.

Verification: 30 model checks and 11 native hall checks pass. Physical tests traverse the correct route, enter and backtrack from a dead end, open a blocked passage by moving its wall, confirm pointer/grip directions on the upright stick, and check the button-free return after falling. The hall approach and platform crossing remain accessible. VR comfort remains untested.

No commit or push requested.
