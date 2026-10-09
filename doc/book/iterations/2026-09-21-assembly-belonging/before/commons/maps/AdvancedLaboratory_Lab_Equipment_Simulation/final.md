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

Now leave the joints where they are. Find the turquoise collar beside the left hand. Take it towards the head. The forearm's connection comes with you; the hand stays behind. A small ring marks the joint the loose end can meet. Release it there.

The line that used to end at the hand now ends at the head. The body still has thirteen joints and twelve connections. Not one point needed to move.

Follow the lines with your eyes. With this change to the starting body, you can go from the head through the torso and left shoulder, down to the elbow, and back to the head. A loop has appeared. The hand waits outside that circuit, with no line reaching it. It has not disappeared from the room. It has disappeared from the body's connected part.

The program changes one entry:

```gdscript
pairs[bond_index].y = candidate
```

Here the pair names the two joints a connection joins. Its second entry now names the joint where you let go. A list of positions would miss what happened. To reconstruct this body, we also need to know which points have been made neighbours.

The familiar shape can conceal that change. From far enough away, the isolated sphere may still read as a hand. Come closer and the relation no longer supports the reading. Which account are you following: the outline, the name, or the connection?

You can take the collar back to the hand. You can try another joint. An end released in empty space returns to its previous attachment; this connection still asks for two distinct neighbours. One end has become available to your hand. The other connections remain authored.

In the source, the hand is still called `l_hand`, wherever you put it. A name can survive the proportions that made it seem obvious. How far can this arrangement travel from its familiar outline before you cease to see a body? And how much of that limit belongs to the arrangement, rather than to what you have learned to recognise?

The rhizome gave us passages through connections. Here a connection helps something become legible as a body, and your own body reaches into that description. The catalogue offers spheres, rods and panels. The assembly supplies roles and neighbours. You can revise a position, then a neighbour. The two operations change different parts of the description. What other part would have to become available for the body you want to make?

Eventually a joint meets the edge of its working space. There is still a room around this experiment, a limit someone supplied. The catalogue beside it has spare parts. This body cannot yet take one. Perhaps the next desire is another joint, another connection, more room. The useful question is which operation would let that desire take form.

<!-- @ -->

Leave the pose a little unlike the one you found. A changed joint or connection is kept for the final hall, where the body will stand beside the one it began with. You can leave the room and meet the difference again. What will have survived the journey?
