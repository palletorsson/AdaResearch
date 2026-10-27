# Wheel / cylinder / torus

An open 6.7 m wide motion study on floor59. The pink hand wheel and automatic
drive share one angle. The large wheel's visible pin and 2.3 m connecting rod
constrain a white cylinder to a 1.6 m horizontal stroke through a pink torus.
Red bands mark the moving cylinder. Black steel provides fixed supports.

This is a finite-rod slider crank, not the exact sinusoidal projection of the
earlier Scotch yoke. The rod endpoints determine its pose; there is no independent
oscillation clock. All movement is ideal kinematics, with no force, pressure,
load or pumping claim. The torus has clear space around the cylinder and does
not pretend to be a sealed hydraulic chamber.

RPM, ANGLE, RUN, REVERSE and the production desktop/XR crank are reused from the
one-cube machine. Hand input temporarily overrides the motor. `DiskAndCrank` and
`PlaybackControls` remain separately editable. Original room layouts are retained.

The engine's frame clock still samples the motion. Keeping the pin and rod
exposed makes the encoded geometric constraint inspectable; making the wheel
larger reveals the changing rod angle instead of disguising it as a sine wave.
