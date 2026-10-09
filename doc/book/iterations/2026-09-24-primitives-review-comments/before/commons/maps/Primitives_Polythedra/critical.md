# A boundary has more than one account

Turn the open trihedron until its missing base faces you. Three visible triangles suggest a corner and an inside. The source gives its physics body a convex hull around all four vertices. That hull closes the opening which the rendering leaves open.

This is a useful place to begin criticism because the disagreement can be located. It belongs to two constructions of the artifact, not to a vague claim that all simulation is false. A mesh answers what to draw; a collision shape participates in deciding what can pass. Which body, which layer and which motion must still be specified before a blocked passage becomes an observation.

## The solid does not choose its purpose

The closed tetrahedron has four vertices, six edges and four faces. The cube has eight, twelve and six. Both give `V - E + F = 2`. That relationship is exact for these geometric boundaries. Its application to a rendered object depends on what we count: square faces, rendering triangles, or a damaged mesh are different descriptions which need checking.

Regularity does not remove remainders from implementation. Nor does a finite list of vertices make every measurement rational: the diagonal of a unit square is already the square root of two. We can count parts exactly while storing their positions with finite precision. Mathematics and its implementation need not be collapsed into the same claim.

The editable pyramid makes this distinction practical. Its handles can move a familiar square-based form into a collapsed or crossing configuration. Updating the points does not certify the result as a valid enclosed solid. The editor continues where a name may cease to fit. That continuation is something to examine, rather than automatically an error to suppress or a liberation to celebrate.

## The same vocabulary, another movement

A triangular prism can supply a wedge. With a low end meeting the floor and a suitable collision surface, forward movement can become ascent. An upright surface can stop that movement. The concrete enclosure develops the extrusion further: a stepped, tapered profile is carried along a length and given a convex collision hull.

These are related constructions, not identical cross-sections. Their uses also depend on arrangement, approach and the movement system. Calling an object a barrier describes a relation to a possible passage. Calling it a slope describes a relation which might support passage. A body still has to encounter those relations.

Smooth and striated space enter this room as a working lens: follow continuity, then locate the divisions which make it possible or interrupt it. The apparently smooth ascent is still produced through a faceted collision surface and discrete movement updates. A repeated barrier line can restrict movement while helping someone orient. An opening can invite movement while failing to support it. The task is to find who benefits, who is stopped, and which alternative the arrangement makes difficult to imagine.

## An instruction is not a collision

The STOP sign has no collision body of its own. The striped barriers in this room do. A visitor who pauses at the word participates in an instruction through reading it; the player's physics body meets a different rule at the concrete. If we call both effects control without distinguishing their mechanisms, we lose the most useful part of the encounter.

The blue arrows add another dependence. Left and right are offered from a face oriented in the room. The mark does not contain a route or check whether it remains usable. An arrow can be legible and misleading. Two arrows can offer a choice whose branches do not serve the same bodies.

The queer possibility here need not take the form of destroying every boundary. It might be a barrier becoming a resting edge, a pause becoming deliberate, or a familiar direction becoming available to another use. Those are proposals to test, not properties secretly guaranteed by the shapes. Ask which change would let someone act differently, and what would have to change in both the visible room and its implementation.

We leave with several accounts still in play: what looks open, what admits a body, what asks us to move, and what we choose to do. The next room will continue before we have exhausted them.

## Implementation anchors

- `commons/primitives/trihedron/grab_trihedron.gd`: three rendered faces and a convex hull collision shape.
- `commons/primitives/pyramid/pyramid_edit.gd`: independently movable apex and base handles.
- `commons/artifacts/concrete_barrier/concrete_barrier.gd`: profile extrusion; optional `blocking` hull, enabled on this room's barriers.
- `commons/artifacts/street_sign/street_sign.gd`: text or geometric arrow variants, without a collision body.
- `commons/scenes/endless_museum.gd`, `_stamp_wedge`: the museum's walkable wedge construction.

The component probe checks physical blocking and ascent with supplied capsule movement. It does not establish full-room accessibility or the experience of a visitor in a headset.
