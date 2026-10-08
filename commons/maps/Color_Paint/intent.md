Question: what does a surface keep after a gesture has passed?

Action: watch the automatic painter, take a spray can, aim and hold the trigger, vary distance and duration, then release it and look elsewhere.

Observation: manual and automatic inputs reach the same canvas. A rendered image remains and evolves; individual gestures are not stored as recoverable objects.

Implementation: automatic UV positions come from two timed oscillations. A triggered manual nozzle maps its actual ray-hit canvas to UV coordinates and projects a distance-dependent footprint using the surface proportions. The spray shader adds grainy deposits to a persistent viewport, whose feedback settles and fades the preceding image toward its ground.

Primary encounters: ball_painting_demo and albers_wall_gallery. Handoff: Grid Pallet's current value becomes Paint's evolving image; Walls gives colour an architectural role.
