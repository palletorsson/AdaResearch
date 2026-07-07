# Void Crossing — Artifacts
*Vectors & Forces: From Direction to Dynamics · oscillation · 3 artifacts*

> A floor that stops, a gap of nothing, and a far ledge you have to reach. The bridge is not made of stone — it is made of a vector. Step into the force field, aim it with the machine on the near shore, and let one chosen direction carry you and the loose cubes across the void. Here a force stops being a number and becomes a place you walk through.

The map, read through what it holds — its artifacts in the order you meet them:

## Force Cube (a vector you hold)
![Force Cube (a vector you hold)](/scene-catalog/force_cube.png)

A grabbable cube that draws the force you apply as an arrow out of its centre, split into x / y / z components - an embodied force-display prop. The cube IS the tail of the vector: wherever you push it the arrow points, and the three coloured component arrows (red Fx, green Fy, blue Fz) plus a dashed decomposition box show how one push is really three. A faint motion trail follows. DNA: push 0..1 is the force magnitude; seed sets its direction (live, both come from the grabbing hand's motion).

`force_cube`

## Vector Machine (the dial of gravity)
![Vector Machine (the dial of gravity)](/scene-catalog/vector_machine.png)

A console that aims and sizes the one vector ruling every force_field in the room. Three grabbable sliders - PITCH (down to up), YAW (which way across) and FORCE (how hard) - compose a single force vector, drawn live as a big arrow, and pushed straight into every force_field via set_field_vector(). The default is gravity: straight down, 9.8. Tilt it up-and-across and the void next door becomes a bridge.

`vector_machine`

## Force Field Zone (a force made into a place)
![Force Field Zone (a force made into a place)](/scene-catalog/force_field_zone.png)

A 4 m cube of space where one vector replaces gravity. Throw a cube in - or step in yourself - and inside the field the only force is field_vector: point it down and everything falls into the void below; point it up-and-across and the same cube (and the same player) is carried to the far side. RigidBodies inside get gravity_scale 0 and velocity += field·dt; the player_body gets velocity += (field − its gravity)·dt. The wireframe cube, the grid of field-line arrows and the central vector show which way the world pushes. Driven by the vector_machine via group 'force_field'.

`force_field_zone`
