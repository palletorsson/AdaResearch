# The inventory before the body

How can one collection of parts become several recognisable structures?

<!-- @MolecularDesigner -->

Choose a recognisable piece in the floating inventory and keep it in view as an assembly begins. Watch it approach a position and acquire relations to other pieces. Stay through another floating phase and a later assembly. Notice whether the same part instance keeps its shape and colour when it takes a new role.

The scene alternates floating and assembling phases, with about ten seconds assigned to each. It moves through authored assemblies drawn from a catalogue that includes bodies, furniture and other structures. Bond lines update between the assigned parts as they move towards their targets.

The source makes the operation inspectable:

```gdscript
var to_target = target_pos - global_position

# Spring force toward target
velocity = (velocity + to_target * dock_spring * delta) * dock_damp
global_position += velocity * delta
```

Here the restoring force returns from the earlier halls. The vector to_target points from a part to its assigned destination. The spring changes velocity and velocity changes position. A moving piece can look as if it has found its place, although another file already supplied the target. dock_damp is applied each frame, which also makes the settling depend on the update rate. The clock remains inside the body we are watching.

There are two distinct descriptions at work. The catalogue defines available kinds of part: shapes, sizes, colours and related properties. An assembly chooses instances, assigns target positions, reapplies shapes from the catalogue, and declares connections. Movement towards those targets is then produced by a damped spring calculation. A recognisable whole results from a specification together with a procedure for approaching it.

This is not a simulation establishing chemical bonds or discovering molecular structures from physical laws. A line between two pieces represents a declared relation. A structure named Molecule or DNAHelix belongs to the exhibit’s authored vocabulary, and the name cannot supply the chemistry that its movement does not calculate.

The rhizome selected neighbours by proximity. Here the assembly already describes where things should end up. Neither method is unrestricted: one inherits a spatial growth rule, the other a catalogue and a target. Understanding those constraints lets us ask for a meaningful variation.

Imagine a body this catalogue makes awkward to describe. Would you need a new kind of part, another connection, or merely different positions for existing pieces? That is a proposed design exercise for a future editable version. The present automatic cycle lets you begin by observing how much changes while the inventory remains available.

<!-- @ -->

The final ledger asks us to record the consequences of those choices. A useful catalogue permits construction while also defining what its builder has to struggle to express.
