# Mario Cube

An event-driven cube artifact that reacts to NextCube activation or player collision by removing a DarkSphere obstacle and revealing a procedural 7-band rainbow arc. Teaches signal-based event systems and procedural mesh generation.

## How It Works

The cube listens for `next_requested` signals from any NextCube node in the scene, or for direct player collision via physics body detection. Upon first activation, it tweens the DarkSphere to zero scale (shrink-to-vanish animation) and simultaneously reveals a rainbow built from seven half-circle ArrayMesh arcs at increasing radii. Each rainbow band is a unique procedural arc mesh with emissive coloring, animated into view with an elastic scale-in tween.

## Features

- One-shot activation via NextCube signal or player collision
- DarkSphere removal with smooth shrink-to-zero tween (EASE_IN + TRANS_BACK)
- 7-band procedural rainbow arc using ArrayMesh with front and back faces
- Elastic scale-in reveal animation for the rainbow
- Automatic signal discovery via groups and recursive scene tree search
- Clean signal disconnection on exit

## Files

- `mario_cube.gd` — Main script
- `mario_cube.tscn` — Scene file
