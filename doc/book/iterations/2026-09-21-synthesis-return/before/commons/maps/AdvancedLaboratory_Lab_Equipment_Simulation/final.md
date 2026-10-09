# Where a body is expected

<!-- @MolecularDesigner -->

A hand waits at the end of an arm. Take it a little farther than an arm ought to reach. The elbow stays behind. The slender connection follows, becoming longer. Let go.

The body keeps your alteration.

It stands close to your height, with warm metal joints and just enough between them for you to recognise shoulders, knees, a head. You may already have begun correcting it. Bringing the hand back. Making the two sides agree. Nobody in the room asked for symmetry; perhaps you brought that instruction with you.

Try leaving the hand somewhere else. Move around the body. From one side it is reaching; from another, falling. Lower its head towards the hand. A few displacements make a gesture, and the gesture makes you read the whole arrangement again. The little spheres have no expression. Where did the expression enter?

Across the floor, a larger assembly is finding its places without you. Scattered pieces approach one another. Lines join them. A body appears, or a chair, and later something with more legs. The unused pieces gather along the wall. Stay long enough to see an arrangement loosen and another begin.

One piece carries an amber ring. Follow it. The ring stays with the same carrier, but the shape inside can change. What was a sphere can become a panel. A torso and a seat need not be made from different stuff here; the program gives one instance another mesh and another job. If the next arrangement needs more carriers, it can make them. This inventory has permissions that a cupboard of physical parts would not have.

Yet the apparent freedom has a destination. Before a piece begins to move, its place has been written in the assembly file. The approach uses a restoring force we met earlier:

```gdscript
var to_target = target_pos - global_position

velocity = (velocity + to_target * dock_spring * delta) * dock_damp
global_position += velocity * delta
```

The first line measures the difference between where the piece is and where it is expected. That difference changes its velocity; velocity carries it towards the expected place. There is movement to watch, an approach to wait for. The destination has not been discovered by the moving piece.

A body can look as though it is coming into being while it is coming into agreement with a description.

Return to the joint you moved. Here your hand supplies a different destination. Its position is recorded in the little body's own coordinates:

```gdscript
targets[index] = to_local(handle.global_position)
```

We are back with a point, a local space, a line between points. The first rooms have not been left behind. You now have enough of their operations to move a hand without moving a shoulder, to lengthen a forearm, to put a knee where this figure has never had one. Let go and the pose remains while the other assembly continues its cycle. There is time to walk around what you have done.

There is also a useful resistance to notice. Moving the hand does not pull the elbow after it. The gold connection follows its endpoints, but it does not enforce the length of a bone. This model can hold a gesture your muscles could not sustain. What looks like a limb is, here, a declared relation drawn across a distance.

The body began with thirteen joints and twelve connections. Those connections remain when you stretch it. You have changed its geometry; you have not yet given it another way to connect. To grow an extra arm would require more than moving the existing hand. The desire is easy to feel before the missing operation is easy to name.

In the source, the hand is still called `l_hand`, wherever you put it. A name can survive the proportions that made it seem obvious. How far can this arrangement travel from its familiar outline before you cease to see a body? And how much of that limit belongs to the arrangement, rather than to what you have learned to recognise?

The rhizome gave us passages through connections. Here a connection helps something become legible as a body, and your own body reaches into that description. The catalogue offers spheres, rods and panels. The assembly supplies roles and neighbours. You have been allowed to revise positions. Each permission opens a different part of the question: what bodies are possible?

Eventually a joint meets the edge of its working space. There is still a room around this experiment, a limit someone supplied. You can want another connection, a different part, more room. The useful next question is which of these your desired body needs.

<!-- @ -->

Leave the pose a little unlike the one you found. It stays during this visit; leaving is not yet saving. In the final hall, the ledger will bring us back to what a record can keep. For now there is this small, material difference: the next place you look is one you helped decide.
