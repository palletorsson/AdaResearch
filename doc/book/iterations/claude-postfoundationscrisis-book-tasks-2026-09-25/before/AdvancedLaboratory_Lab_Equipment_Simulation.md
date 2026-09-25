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

You could take the collar back to the hand. But there is another way to bring the hand into the body. Leave this end at the head. Find the second turquoise collar beside the elbow and carry it to the waiting hand. Release it there.

Now the hand joins the head directly. Follow the connections again: every joint belongs to the connected body, although the hand has not returned to its old neighbour. The loop has opened. Nothing has been added, and no point has moved.

The hand has come back without going back. Does it still seem to belong at the end of an arm? The drawing offers another relation before we have a familiar name for it.

Both ends of this connection are available to you. Try another pair. An end released in empty space returns to its previous attachment; the connection still asks for two distinct neighbours. The other eleven connections remain authored.

In the source, the hand is still called `l_hand`, wherever you put it. A name can survive the proportions that made it seem obvious. How far can this arrangement travel from its familiar outline before you cease to see a body? And how much of that limit belongs to the arrangement, rather than to what you have learned to recognise?

The rhizome gave us passages through connections. Here a connection helps something become legible as a body, and your own body reaches into that description. The catalogue offers spheres, rods and panels. The assembly supplies roles and neighbours. You can revise a position, then a neighbour. The two operations change different parts of the description. What other part would have to become available for the body you want to make?

Eventually a joint meets the edge of its working space. There is still a room around this experiment, a limit someone supplied. The catalogue beside it has spare parts. This body cannot yet take one. Perhaps the next desire is another joint, another connection, more room. The useful question is which operation would let that desire take form.

Another body waits over a dark mat. You recognise its head, shoulders, hands. Coral rings mark places your hand can take. Pull one wrist.

This elbow comes with it.

The upper arm turns; the shoulder is drawn after it. Your small displacement travels through the body. Keep the hand up and watch the other arm hang. You have given one part a destination, but the remaining parts still have weight. Their arrangement has to answer both.

Let go.

The gesture cannot stay where you left it. Knees fold, a shoulder meets the floor, the head comes to rest. The same invitation — take a hand, move it, release it — has produced another kind of body.

The gold connection could lengthen as far as its workspace allowed. These limbs keep their lengths. Their joints turn, gravity pulls, and contact with the floor changes what can happen next. A relation has acquired a consequence. The little figure may look tired, hurt, absurdly relaxed. None of those states was supplied as an emotion. We meet them in the falling arrangement.

Hang it up again with the small control on the stand. Try a foot. Try holding two parts. How much of the body's apparent intention belongs to the way you are supporting it?

This body has been given a different set of permissions, too. Its joints turn more freely than yours. That freedom can produce a collapse you could not imitate. The model lets us try a body without making that body the measure of every other one.

A chair has legs too.

Find the one held under fine lines. The supports keep its opening pose available long enough to recognise it. Take the coral ring on its back. The supports let go. Pull a little higher: the seat follows, and the legs swing into another arrangement. Release it. For a moment the chair looks as though it is trying to sit down.

The back, seat and four legs are still connected. Their joints have been allowed to turn where you may have expected them to stay fixed. The familiar parts have not been enough to preserve the familiar use.

Across the passage, lift one leg of the table. Watch what happens to the top. Its flatness survives; its promise of being level does not. What else would have to hold before you trusted this arrangement with something you did not want to spill?

The lamp bends and goes on shining. Its light follows the bulb towards the floor. Falling has not broken a circuit here; that consequence was never included. Failure has to be specified too.

Each stand can reassemble its object. Try taking a different part. The same rule for pulling can pass from a wrist to a chair back, from a foot to a table leg. The names offer different expectations before the movement begins. What is the connection actually obliged to keep?

<!-- @ -->

Leave the gold body a little unlike the one you found. A changed joint or connection in that workshop is kept for the final hall, where the body will stand beside the one it began with. You can leave the room and meet the difference again. What will have survived the journey?
