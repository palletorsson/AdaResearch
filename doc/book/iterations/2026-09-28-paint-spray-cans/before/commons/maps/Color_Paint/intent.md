Question: what does a surface keep after a gesture has passed?

Action: watch the automatic painter, take a pigment ball, aim and move across the canvas, then release it and look elsewhere.

Observation: manual and automatic inputs reach the same canvas. A rendered image remains and evolves; individual gestures are not stored as recoverable objects.

Implementation: automatic UV positions come from two timed oscillations. A held manual ball maps its actual ray-hit canvas to UV coordinates using the surface proportions. The brush adds splats into a persistent viewport, whose shader shifts, diffuses and fades the preceding image toward white.

Primary encounters: ball_painting_demo and albers_wall_gallery. Handoff: Grid Pallet's current value becomes Paint's evolving image; Walls gives colour an architectural role.
