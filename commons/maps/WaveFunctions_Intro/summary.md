# WaveFunctions Intro — Summary

The Wavefunctions sequence opens with a pendulum you release by hand. It stands on the floor of a 13×22 hall whose one-metre platforms were recovered on 2026-09-10; the raised strip beside it carries a row of pick-up cubes, and the old east wall, now inside the widened room, is a long low platform.

The pendulum is the primary encounter. It is placed as `control_pendulum#reference:plumb#evidence:trace`: a grabbable bob on a 0.6 m rod, a hairline from the pivot to the rest point, a ring at the rest point that brightens at each centre crossing, a label that reads the angle and the signed angular velocity and counts the crossings, and, behind the swing, the angle over the next six seconds predicted with the same update rule from the standard starting angle. The lesson is that the bob visits the centre from opposite directions: the same position is two states.

The pendulum is integrated, not prescribed. Each physics step computes an angular acceleration from -(g/L)·sin(θ), adds it to the velocity, applies the regime's damping, and adds the velocity to the angle. A release converts the hand's last positions into an initial angular velocity along the swing. Around it stand the comparisons: cubes that follow a sine of the clock and hold no velocity, a cube that spins without returning, a cube driven by the pendulum's own signal, and a time trace that records motion.

Within the sequence, this room hands on the centre crossing. The next room, Pendulum, gives the returning movement a spatial record.


## The release, by hand (2026-09-13)

A visitor at a desk can now release the pendulum the way a visitor in a headset does. Right-click the bob to take it, move the view to carry it out to one side, hold still, right-click again to let go. The pendulum hears both clicks through its own pickup and drop handlers, so the angle it starts from is read off where you held the bob and the speed it starts with comes from your hand's last motion. Before this, a desktop carry never reached the pendulum at all.

Released from either side at 0.6 rad, the bob crosses the ring first at about 2.25 rad/s towards the centre and next at about 2.00 rad/s the other way. The two sides mirror each other. A person walking the aisle has a little over a metre of room on either side of the swing, and never less than 0.85 m even at the widest swing the pendulum allows.
