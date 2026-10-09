# WaveFunctions Intro — Summary

The Wavefunctions sequence opens with a pendulum you release by hand. It stands on the floor of a 13×22 hall whose one-metre platforms were recovered on 2026-09-10; the raised strip beside it carries a row of pick-up cubes, and the old east wall, now inside the widened room, is a long low platform.

The pendulum is the primary encounter. It is placed as `control_pendulum#reference:plumb#evidence:trace`: a grabbable bob on a 0.6 m rod, a hairline from the pivot to the rest point, a ring at the rest point that brightens at each centre crossing, a label that reads the angle and the signed angular velocity and counts the crossings, and, behind the swing, the angle over the next six seconds predicted with the same update rule from the standard starting angle. The lesson is that the bob visits the centre from opposite directions: the same position is two states.

The pendulum is integrated, not prescribed. Each physics step computes an angular acceleration from -(g/L)·sin(θ), adds it to the velocity, applies the regime's damping, and adds the velocity to the angle. A release converts the hand's last positions into an initial angular velocity along the swing. Around it stand the comparisons: cubes that follow a sine of the clock and hold no velocity, a cube that spins without returning, a cube driven by the pendulum's own signal, and a time trace that records motion.

Within the sequence, this room hands on the centre crossing. The next room, Pendulum, gives the returning movement a spatial record.
