# A level body on a sloping journey

**Learning elements**

- Displacement in a named coordinate frame
- Vector interpolation
- A destination and a route to it
- A condition selecting two parts of a journey

Watch the carrier that travels diagonally. Its route slopes; its top stays level. Translation changes position without requiring a turn. At the exit, compare the guided handle's bend with the freer handle's diagonal.

Continue with the travelling box from the previous lesson. Keep its mesh and position change; remove the other two studies and their banks. This time choose a destination and the route. The museum supplies the installed ride. Our reduced study displays its movement without rider physics.

## The complete study

Put an empty `TransformStudy` on clear museum floor, with zero rotation and unit scale, and attach this `lesson.gd`. The positions are local metres. `BoxMesh.size` gives the familiar cube a broad, low shape once; the journey then leaves that shape unchanged.

{{CODE}}

`finish - start` is the displacement: here `(4, 2, 0)`, four metres along X and two upward. Lines introduced the length of such a vector. Its components describe one combined change, not an instruction to finish X before starting Y.

`start.lerp(finish, t)` interpolates all three components together. At `t = 0.5`, the cube is at `(0, 2, 0)`, halfway along the diagonal. Neither rotation nor scale is assigned during the journey. The carrier remains level.

The fraction reaches one after four seconds. Clamping holds the destination even as elapsed time continues. A direct assignment to `finish` would reach the same place immediately and omit the journey.

## Give the same displacement another route

Set `via_corner` to `true`. The first half of the time takes the cube to `corner`, directly above its start. The second half takes it to the same destination as before. The `if` chooses which segment currently supplies the position; multiplying each half's fraction by two stretches it back to the range zero to one.

At two seconds, the direct version is at `(0, 2, 0)`. The corner version is at `(-2, 3, 0)`. At four seconds they agree again. A shared destination does not require a shared journey.

This version gives each segment two seconds. The upward segment is two metres; the horizontal one is four, so their speeds differ. Constant speed along routes of different lengths would need time allocated by distance. We leave that calculation for a later movement study.

## Choose another destination

Keep `via_corner` true and change `finish` to `Vector3(2, 3, 2)`. Predict the new corner and final position. The first leg stays vertical; the second now crosses both X and Z. The body still does not turn to face its travel.

The next hall makes that turn a deliberate choice, with an axis and a centre of its own.
