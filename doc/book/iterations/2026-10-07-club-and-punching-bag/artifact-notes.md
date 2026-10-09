# A club and a hanging bag

The existing PointBody remains the ball. `impact_club.gd` is a grabbable tool with a 1.5 m shaft and an approximately 1 m driver head. Its rose handle aligns with the controller. While held, its kinematic colliders stay on loose-body/world layers; Jolt contact moves the struck body. On release it becomes dynamic. This does not measure hand strength or apply a fixed hit impulse. A local RETURN CLUB button uses the existing rack recovery and refuses while the tool is held.

The bowling encounter contains one rack on the right of its approach. A second rack belongs to the punching bag, placed beside recoil in VFM_08_Arena. Existing hall size, aisle, exit and tutorial anchor remain.

`punching_bag.gd` makes a 7 kg capsule on a PinJoint3D at the overhead support. The chain-like shaft is a visual massless tether; the joint holds a point rigidly relative to the body. It is not a simulated flexible rope or deforming sack. Gravity and damping produce the return. The actual bag cannot be picked up and detached; a rose grip applies a bounded force instead.

Nearby tracked controllers gain 11 cm kinematic collision mitts. Both collision layer and mask must be enabled for this Jolt interaction. They touch the bag and other loose objects brought into its immediate bay; its own club and force grip are excluded. Mitts vanish and disable collision outside 2.4 m, on tracking loss, or for a large pose jump. Removed controllers remove their mitts. Headset input is left intact. Desktop visitors can use the club or pull grip.

RESET restores the bag, retaining its joint, and refuses while the pull grip is held. RETURN CLUB affects only the tool. Full tutorial.md and final.md have not been rewritten.
