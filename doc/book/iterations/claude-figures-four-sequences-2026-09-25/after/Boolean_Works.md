# When the Negative Gets Big

The room gets taller here. A workbench, a catalogue rack, a wall with a door cut through it, a block of rock with a hollow inside. These are the Boolean operations at the size where they begin to promise architecture. When the negative gets big enough to stand in, can you stand in it?

Do not answer from the doorway. Several objects offer an image of an interior. One asks you to enter it. The difference is worth finding with your body before naming it.

## The work waiting above the table

<!-- @csg_compose_workbench -->

Five solids turn slowly above a table. Union, intersection, subtraction, subtraction the other way round, and a fifth with a longer label: the verbs have become a small collection. Their rotation offers each result from another side while the recipe stays fixed.

The workbench suggests a place to take hold of something and change it. In this version, the five presets keep their distance from that possibility. They turn, but you cannot pick them up or build another expression here. Your eye can follow their contours further than your hand can carry them.

The fifth solid is the one the bench in the first hall said the verbs could make without a new name. Its label is its recipe, the parts belonging to either operand with the overlap removed:

`(A ∪ B) − (A ∩ B)`

This is symmetric difference. It composes the familiar verbs instead of adding a new primitive operation; the engine has no button for it, and the table has a solid. Walk round it. From outside it is the union again, because what the recipe removed was the shared region, and the shared region was inside. A solid can carry a hollow it never shows. The table lets us inspect the answers someone else arranged, and one of them is an answer the list of verbs does not name.

![The five benches cut through their middle: union, intersection, the two differences and the symmetric difference](/book-review/doc/book/figures/boolean_surfaces/five-benches-in-section.png)

*The five benches in section, a square and a circle standing for the box and the sphere. The dotted outlines are the operands. In section the fifth shows what its outside never does: the shared region taken out of the joined one.*

## A cut changes its company

<!-- @subtraction_suite -->

A painted cube stands on a white plinth. Beside it, the same cut is presented with transparent operands and an explanatory board. One asks for attention as a sculpture; the other offers the means of explaining its hollow. A tray gathers further specimens nearby.

Stay with whichever draws you first. Knowing how the sphere was subtracted need not exhaust the pleasure of the curve it left. Conversely, the desire to understand can send you back to a surface you had already admired.

The two presentations share a geometric recipe, but their materials also make decisions about visibility. The painted version draws both sides of its triangles; the operator version keeps ordinary back-face culling. This decides which sides of a triangle may be seen, separately from the geometry of the cut. Comparing the presentations involves more than furniture and colour. The explanation has a way of showing things too.

## When did the pieces become pieces?

<!-- @sphere_splitting_showcase -->

Five spherical bodies and balls to throw recall the earlier force encounters. A sphere coming apart can seem to tell one clear story: impact, then fragments. Here the methods disagree about when those fragments come into existence.

Some bodies are divided into pieces before the impact. Others calculate a division when they are struck. One method uses CSG intersection to make its piece meshes; the others use different constructions. Similar broken silhouettes can follow different histories.

That is a useful neighbour for the Boolean works. The hall does not need every fracture to be subtraction. It needs us to notice when the appearance of a cut has persuaded us that we know how it was made.

## The hole that was never made

<!-- @recursive_boolean_cube -->

A Menger sponge gives that question a quieter form. Square openings recur inside a cube, and smaller openings repeat in what remains. From a distance it could be a record of patient excavation.

The construction divides a region into twenty-seven positions. It counts how many coordinates of each little position lie in the middle and then makes a choice:

```gdscript
if zeros >= 2:
    continue
```

Those cells are never built. The others can be subdivided again. Nothing has to be removed from a previously filled cube to give this body its holes.

The earlier Boolean difference changed a represented region and generated its new boundary. This work withholds parts of a construction. Both can give us an opening to look through. The image alone does not tell us which history to imagine.

There is something generous in that uncertainty. We can want the hollow before knowing whether to carve it, omit it, or compose the surrounding pieces. Learning another construction gives that desire another way to proceed.

## Equals room

<!-- @csg_architecture_cavity -->

A wall carries the equation `wall − (door + porthole + window) = room`. There is a doorway, a round bite at the top and an arched opening. Your eye begins arranging a possible passage through them.

Walk toward the uncut part. It does not stop you. This display has no enabled collision, so the wall and its doorway make the same offer to the moving body. The opening matters to the image; the implementation has not made it a necessary crossing.

Go around the end. There is no enclosed room behind this particular wall. The artifact has other configurations with returning walls, but the placement here is a single slab. An equation over its head has supplied a room sooner than the construction has supplied an inside.

The failed promise is worth keeping in view. We can understand the operation, recognise the door and still lack the agreement that would let either one organise our movement. A clear picture can carry a desire for somewhere we cannot yet inhabit.

## The opening that asks for your body

<!-- @boolean_burrow -->

Go around the stone block; the opening is on the end to your right as you arrive, under the sign TRY THE OPENING. Try the solid wall first, then the gap. The wall stops you. At the opening, the museum floor continues into a low, turning hollow. Follow it far enough to lose the view you had from outside. Then turn and find your way back.

Eleven overlapping cuts follow a seeded walk through the block. In the original construction they were spherical. The hollows belonged to one connected arrangement, yet a walking body could stall at a raised lip between them. Two regions can meet without providing the floor that a particular body needs.

The version here keeps those eleven centres and their radius. Upright cylindrical cutters replace the spheres:

```gdscript
column.radius = carver_radius
column.height = carver_radius * 2.0
column.position = at
```

Their bottoms reach just below the museum floor. Their tops leave about 2.3 metres of headroom. The rooms still overlap along the wandering plan, but their floors no longer climb into each join. Another line makes the remaining rock resist the body:

```gdscript
stock.use_collision = walkable and spoil == "rock"
```

The shape of the cut and the rule for contact have to work together. A collider can enforce an opening too small to enter. A generous hollow without collision can make the wall beside it equally passable. Here a body's dimensions have become part of what the room needs to get right.

The spherical version remains possible. It has not become a wrong shape because we wanted a passage. The hollow here has been adapted to one kind of movement. Another body might find a use for its rising floors, or ask for more clearance than we have left.

Inside, the same wall that stopped you from entering through the rock interrupts the view from the aisle. What enclosed the passage can also give it seclusion. The cut has made a place to withdraw into as well as somewhere to pass. Which of those possibilities matters depends on why a body came here.

## Walk the hollow

<!-- @sdf_cavern_room -->

Nearby, another rock-like body carries the invitation "CARVE THE FUNCTION, WALK THE HOLLOW". Its crust is assembled from small boxes. Five spherical regions are subtracted from a box-shaped field, and samples near the resulting boundary give it this broken surface.

The signed-distance calculation returns from the previous sequence:

```gdscript
d = maxf(d, -_sd_sphere(p, c, r))
```

Inside uses negative values in this construction. Negating the sphere's field and taking the maximum keeps the region inside the box but outside the cutter. Repeating the operation makes several hollows. Sampling that result into little boxes gives the surface its grain.

The model has no collider. Its carved air also begins above the museum floor; a lower part of the displayed rock separates the hollow from where your feet are. Enlarging the model has not supplied a walk into it. The invitation stays ahead of the place.

Look back toward the burrow. Related operations have produced two different relations to an interior. One offers a surface to examine. The other has been fitted to a body's approach, support and return. The large hollow may make us want another passage; wanting it does not yet give it a floor.

## A collection within reach

<!-- @booleanvariations -->

The rack gathers seventy-five small combinations in a three-dimensional array. A handleable scale and repeated frames suggest a collection you could take apart in your hands. The rack's objects do not take a hand. Here too, an appearance has offered an action that the implementation withholds, so the collection keeps the order someone gave it, and we move around it while its objects keep their places.

## What the picture can settle

<!-- @coincident_face -->

The amber-and-blue diagram returns at the back wall. It gives a stable image to a competition between surfaces. In the gallery, we could compare its account with the mechanism drawing the stripes. Here it stands among objects whose accounts also need another kind of evidence.

An outside photograph can show an entrance. It cannot establish the route a particular body will find beyond it. From outside, a wall with returning walls looks much like a wall without them; the inside only shows itself to a body that goes round. A visitor might instead find somewhere to be out of sight.

In the burrow, the cutters kept their centres while a changed profile made a walk possible. The old description, *connected*, remained true. We had to ask what connection would mean for the body arriving there.

Keep the signs that overpromise in view. They tell us where the desire for a room arrived before its floor, contact rules or entrance. The next construction can take that desire seriously. Sometimes a different cut lets the body arrive too.

In the next hall many small bodies lay a trace in the ground and follow it. The question moves from what a hollow permits one body to what a shared ground permits many.
