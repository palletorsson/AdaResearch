# Two wheels / one belt

An open belt links a 1.1 m pitch-radius pulley and a 0.55 m pulley on fixed
axes 3.2 m apart. One turn of the large wheel produces two turns of the small
wheel, in the same direction. Both accept the existing desktop pointer and
XRTools grip input. Pink spokes and travelling belt marks make the ratio visible.

This is an ideal taut, no-slip transmission. A single displacement determines
both angles and the marks' travel: `R * angle_large = r * angle_small`. Tangent
runs and circular wraps are built from these actual radii. There is no independent
output oscillator, simulated belt tension, load, friction or torque claim.
Geometry is sampled for rendering; the physical size ratio remains exact.

Starts stopped for hand exploration. RUN optionally supplies a common motor;
RPM is the large wheel's speed and the small wheel runs at twice that value.
Hand input on either wheel overrides the motor. ANGLE pauses and selects phase.

The two wheels, belt and bearings stay one coupled editable `DiskAndCrank`
group; `PlaybackControls` can be moved separately. Moving, rotating or uniformly
scaling the complete mechanism preserves its coupling. The static editor export
uses phase zero and the same native meshes. The shared catalogue also supplies
the workbench and tree. No existing floor59 objects are rearranged.
