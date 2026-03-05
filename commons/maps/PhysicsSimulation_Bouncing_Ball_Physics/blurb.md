# Bouncing Ball Physics

A ball falls. Gravity pulls it into parabolic arc. It hits a wall and returns — or doesn't. The coefficient of restitution decides. Set it to 1.0 and the ball bounces forever, perfectly elastic, energy looping between kinetic and potential without loss. A closed system. A perpetual machine. A lie.

Drop it below 1.0. Each impact converts ordered motion into heat, sound, deformation — entropy takes its cut. The parabola flattens. The ball dies. This is the simplest possible physics demo: `x(t+dt) = 2x(t) - x(t-dt) + a·dt²`, a wireframe box, and gravity. Spawn dozens. Watch them scatter and settle.

Every bounce is a negotiation between structure and dissipation. At e=1, identity survives impact. At e<1, each collision costs something irreversible. The restitution coefficient is not a parameter — it's a thermodynamic verdict.