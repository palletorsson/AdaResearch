# Trans Introduction — Artifacts
*Transformation: What Stays the Same When Everything Changes · F_order · 7 artifacts*

> Three cubes. Three ways to close a gap.

The map, read through what it holds — its artifacts in the order you meet them:

## Invariants Demo
![Invariants Demo](/scene-catalog/invariants_demo.png)

A triangle with labeled measurements — side lengths, angles, area. Apply translation, rotation, scale, or shear and watch which properties survive. Preserved measurements glow green; changed ones glow red. Each transform has a signature: what it cannot touch defines it.

`invariants_demo`

## Matrix 4x4 Viewer
![Matrix 4x4 Viewer](/scene-catalog/matrix_4x4_viewer.png)

Interactive 4x4 transformation matrix viewer. A wireframe cube is transformed live by sliders controlling translate X/Y/Z, rotate Y, and uniform scale. The 4x4 matrix values update in real time as a color-coded Label3D grid — rotation/scale in cyan, translation in green, homogeneous row in gray.

`matrix_4x4_viewer`

## Homogeneous Coordinates
![Homogeneous Coordinates](/scene-catalog/homogeneous_coordinates.png)

Wall panel explaining why 4x4 matrices are used in 3D. Shows a color-coded 4x4 homogeneous transformation matrix: rotation/scale (blue), translation (green), projection (red), homogeneous row (gray). Demonstrates [x,y,z,1] → [x',y',z',1] via matrix multiplication with a 3D coordinate frame.

`homogeneous_coordinates`

## Rotation Gimbal
![Rotation Gimbal](/scene-catalog/rotation_gimbal.png)

Gimbal lock demonstrator with 3 nested rotation rings (X=red, Y=green, Z=blue). VR sliders control each Euler angle (0-360 degrees). When Y approaches 90 degrees, X and Z rings align and 'GIMBAL LOCK!' flashes — showing why Euler angles lose a degree of freedom and why quaternions matter. Displays live rotation matrix decomposition.

`rotation_gimbal`

## Balance Puzzle
![Balance Puzzle](/scene-catalog/balance_puzzle.png)

JUDGE which translations and rotations preserve stability in a stacked structure.

`balance_puzzle`

## Transform Composition
![Transform Composition](/scene-catalog/transform_composition.png)

Transform composition demonstrator showing that matrix multiplication order matters. A simple house shape undergoes Rotate-then-Translate (blue) vs Translate-then-Rotate (red) — landing in different places. Displays R·T ≠ T·R with live 4x4 matrices. VR sliders control rotation angle and translation distance. Buttons toggle order A, order B, or both. Animated step-through shows intermediate states.

`transform_composition`

## Dark Sphere
![Dark Sphere](/scene-catalog/dark_sphere.png)

USE a neutral sphere as a reference for scale, silhouette, and atmospheric change.

`dark_sphere`
