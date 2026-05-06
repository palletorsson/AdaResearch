# Vector Normalize Demo

An interactive visualization of vector normalization, showing how dividing a vector by its magnitude produces a unit vector (length 1) pointing in the same direction. A transparent unit sphere makes the concept tangible: the normalized vector always lands exactly on the sphere's surface.

## How It Works

The original vector V is drawn as a faded arrow, and the unit vector V-hat = V / |V| is drawn as a bright green arrow that always terminates on the unit sphere. Three wireframe rings (built from MultiMesh cylinders) outline the sphere along the XY, XZ, and YZ planes for depth perception. The info panel displays the original vector, its magnitude, the normalization formula, and confirms that |V-hat| = 1.000. As the user drags V's endpoint in VR, the unit vector pivots to match the new direction while maintaining unit length.

## Features

- Transparent unit sphere with three wireframe great-circle rings
- Faded original vector and bright unit vector showing direction preservation
- Live info panel with normalization formula and component values
- VR slider to adjust sphere opacity for visual clarity
- Extends the shared vector_scene_base for consistent coordinate axes and styling
- Cached node references for efficient per-frame updates

## Files

- `vector_normalize_demo.gd` -- Main script
- `vector_normalize_demo.tscn` -- Scene file
