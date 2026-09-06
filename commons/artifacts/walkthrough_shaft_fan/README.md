# Walk-Through Shaft Fan

An environmental-scale industrial fan spans a circular ventilation shaft. The
visitor walks along the shaft axis and crosses the rotating plane through the
gap between solid, slowly moving blades.

This is the bodily follow-up to `wall_clearance_fan`:

- **Wall-Clearance Fan:** architecture yields to the fan's full swept volume.
- **Walk-Through Shaft Fan:** the architecture remains fixed, so the visitor
  yields to phase and crosses during a temporal opening.

The default seven-blade rotor turns once every 55.6 seconds. A crossing light
changes from `WAIT` to `CROSS` when the nearest blade is more than 17 degrees
from the lower walking lane, producing an approximately 2.4-second window.

The rotor is an `AnimatableBody3D` with collision on its hub and every blade.
It blocks or pushes rather than dealing damage. A front-mounted control panel
adjusts speed and can stop or reset the phase.

QFEP connection: periodic order partitions time into bodily affordances. The
same shaft alternates between passable and impassable without changing shape;
only phase changes. The opening is an interval, not an object.

