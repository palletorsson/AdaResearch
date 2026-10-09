# boolean_surfaces: the chapters

## Boolean Verbs

*Boolean_Verbs*

Three objects on one line down the middle of the room. The floor rises to either side twice on the way, giving each object a bay without hiding it from the next. A box and a sphere keep returning. By the third encounter, part of the sphere's shape will belong to a hollow in the box.

Their sizes, offsets and colours vary between these demonstrations. We are learning three operations, rather than changing one setting in an otherwise identical experiment. Keep the pair in mind and follow what each operation keeps: either region, their shared region, or the part of the box outside the sphere.

#### What a solid is here

These bodies do not have to be filled with little pieces of material. Each primitive describes a region: we can ask whether a point belongs to it. The program combines those regions and makes a boundary visible. This is constructive solid geometry, usually shortened to CSG.

There are several agreements inside the word *solid*. These small exhibits have not enabled collision. You can pass through a surface that your eye has already accepted. The region still has an inside and an outside in the calculation; it has not acquired the power to stop your body. Keep that difference with you when the objects become architecture.

#### What can belong together


At the first body, follow the place where the box and sphere meet. Their outside contours survive, but the buried surfaces at the overlap do not belong to the result's visible boundary. The operation keeps every point belonging to either region. That is union: `A ∪ B`.

The sphere enters the construction with this instruction:

```gdscript
csg_sphere.operation = CSGShape3D.OPERATION_UNION
```

Earlier, distance fields let a parameter round the meeting between forms. Here there is no smoothing band. A crease can remain where the boundaries meet, even though the gap has gone. Being connected and being smooth are different accomplishments.

The next hall also shows this union with its operands separated. It still contains both of them. One result, two disconnected components. The word *joining* may have led us to expect a bridge; the operation has only promised to keep what belongs to either body. They can belong to one result without having to touch.

#### What must be shared


The second body keeps only the region belonging to both primitives: `A ∩ B`. Much of the box and sphere has no place in this answer. If the operands were moved far enough apart, the shared region would be empty. Nothing can be a successful result.

Beneath the body, three numbers give the volumes of A, B and the region they share. Estimate what remains before looking down at the panel. The little survivor and its precise-looking number are two ways of meeting the same question.

The instrument tests a lattice of sample points. At each point it asks whether the distance from the sphere's centre is within its radius:

```gdscript
var in_b: bool = dx * dx + dy * dy + dz * dz <= r2
```

It also tests the box, then counts points accepted by both. A forty-eight-by-forty-eight-by-forty-eight lattice makes this an estimate. The visible sphere is faceted, while this test describes an analytic sphere. They share a radius parameter, but they do not spend it in quite the same way.

Move close enough to find a facet. Three decimal places have not made the picture and the measurement identical. We have chosen both how to give the region a surface and how to count it.

#### A face neither of them brought


Follow the place where the sphere enters the third box. The box keeps only what lies outside the sphere: `A − B`. Where the two boundaries meet, the cut exposes a curved wall facing into the hollow. The sphere's outer shape has become something we look into.

```gdscript
csg_sphere.operation = CSGShape3D.OPERATION_SUBTRACTION
_root_csg.add_child(csg_sphere)
var mat := StandardMaterial3D.new()
mat.albedo_color = body_color
_root_csg.material_override = mat
```

The first line names the cut. The last gives the result one material. The cavity wall has not uncovered a buried layer of paint; the program generates its boundary and dresses it in the body's colour. Here it looks as though the box had always been this colour inside.

We could make the new faces announce another origin. For now, stay with this peculiar intimacy: the sphere disappears from view while its contour remains in the other body. Absence has been given a surface.

#### Which body comes first


At the end of the hall, a bench brings the three results close enough to compare without walking between bays. Beside them stand two different remainders. One is labelled `A − B`; the other, `B − A`.

The letters changed places. The box with a bite gives way to what remains of the sphere outside the box. The operation is still subtraction. Its order decides whose region may remain and whose will do the cutting.

Above the bench, a caption calls these "the three verbs" and says "the set is closed". There are three choices in the engine's operation list. But an expression also needs operands, their order and their positions. Its result can become an operand in another expression. A small vocabulary can keep making bodies that the list of names does not describe.

The verbs tempt us into quick judgements: union welcomes, intersection demands agreement, subtraction excludes. Then a cavity interrupts that story. What was removed might be precisely where another body could stand. We need to meet the result before deciding what its keeping or cutting has done.

In the next room, the same families appear in several versions. We will be able to see how much one familiar setting had kept out of sight.

---

## Boolean Gallery

*Boolean_Gallery*

Twenty-four objects in six rows. A familiar shape has company: beside it stand other versions of what it could have been. Two wait on each side of the aisle. To see a whole family, you have to cross the floor.

Each row changes a named setting within one artifact. Some settings alter the shape. Others alter how much of its making becomes visible. These are authored possibilities: somebody chose the values, gave them names and decided which one would meet us first.

In the previous room, a short list of operations opened into many possible bodies. Here the museum has made another selection from those possibilities. Its arrangement can be investigated too.

#### How much of a cut do you want to see?


The first row begins with a box that has a bite taken out of it. Its surface gives no account of the sphere that made the hollow. In the next version, a pale volume occupies the missing region. Something you could look through has become something you can also look at.

Further along, transparent operands let you see the original box and sphere together. At the last version, the expression names their relation. The carved result remains; its surroundings have begun to explain it.

The source gives these four readings a vocabulary:

```gdscript
const WORKINGS: PackedStringArray = ["outcome", "trace", "operands", "expression"]
```

More disclosure need not mean a better encounter every time. The ghost can make a cut legible while making the hollow harder to see. The bare result may let a form surprise us before we know its recipe. Cross back to the first object with what the others have shown you. Its silence has changed.

#### A different way through the row


In the union row, the first pair already overlaps. Beside it, a box and sphere stand apart. The next versions bring them close and then deeply into one another. The route across the gallery is not the order in which one might teach their approach.

That order comes from a catalogue convention: show the familiar default first. In this family the default is called `lobed`. The code also names a progression:

```gdscript
const FUSIONS: PackedStringArray = ["distinct", "necked", "lobed", "single"]
```

Find the separated pair, then the narrow connection, then the broader overlap and the concentric arrangement. Your walk now follows decreasing separation, even though the objects have stayed where they were. A change in your route has made another argument from the same row.

The separated pair still counts as a union. Togetherness here does not require a continuous skin. At the other end, one primitive can hide within the region retained by the other. A single-looking body need not tell us how many operands took part in making it.

A default becomes powerful when it is the only version we ever meet. This row gives it neighbours. The familiar form loses some of its authority to say what the artifact is.

#### The names of agreement


The intersection row keeps only shared space. Compare its broad survivor with the small remainder further along. The names offered for these settings include `unanimous`, `broad`, `narrow` and `token`.

Those words bring a social scene into a geometric one. But the objects have not negotiated. Moving the same operands changes the region they share. An intersection cannot contain more than either operand; it can equal one of them if that one is contained in the other.

The current catalogue puts `broad` first. It is the ordinary answer from which the others appear to depart. Standing several versions together makes that choice visible. The beginning of a row has quietly suggested a centre.

Stay with the small survivor. Does calling it a token overlap help you see it, or tell you too quickly how much it should matter? The amount shared and the value of sharing are different questions.

#### How much can go?


Here the cutter grows in relation to the body. The settings are called `pierced`, `opened`, `severed` and `husk`. As the sphere reaches through more of the box, a hollow opens to the outside and the remaining pieces change their relation.

Each setting repeats the cut in several kinds of display. A painted object stands on a plinth. Another appears beside its transparent operands. A tray gathers specimens. The same operation moves between sculpture, explanation and collection; each arrangement gives your eye a different task.

The cutter's radius is a fraction of the box's size. The sequence borrows those fractions from Fontana Puncture, an earlier work in this museum. A borrowed rule can carry a relation onward while the new surroundings change what we ask of it.

There need not be a preferred amount of removal. A narrow opening might hold your attention; a wider one might admit a body; another cut might undo the enclosure you wanted. The name of the setting cannot choose that purpose for you.

#### A picture that holds the failure still


Amber and blue alternate in a thin band where two drawn faces overlap. The exhibit speaks about surfaces competing for the same depth, the flicker a renderer can produce when it cannot reliably separate them.

This band holds the competition still. Its colours are assigned by the index of each bar:

```gdscript
col = color_a if (i % 2 == 0) else color_b
```

Even, odd, amber, blue. We met that economy in the arrays. Here it draws an explanation of uncertainty using a completely decided pattern.

Across the four copies, the faces separate, nearly meet, overlap or give blue a small lead in depth. The diagram makes the alternatives easy to compare. Its striped band is not a live measure of which surface the renderer favours at your current viewpoint. A picture of a failure and an instance of that failure do different work. We can want the clarity of one without mistaking it for the other.

#### What remains of a removal


The final family places three accounts of a removal beside one another. In the first, the removed cells are absent. In the second, they return at their old size as pale ghosts. In the third, smaller dark marks stay where the removal happened. What survives is shared; the accounts of what went are different.

The work names these accounts `gone`, `ghost` and `scar`. Their difference is calculated after the cut, so changing how an absence is shown need not change which cells survive. The four copies apply this question to different removal rules.

A ghost can restore the outline of an earlier whole. A scar can mark an event without filling the old space. Neither is simply more truthful than the other: each keeps something available and changes what can be seen through it. The family borrows this vocabulary from the earlier Cantor work. The return asks what kind of presence a record should have.

This gallery has kept several versions together long enough for us to move between them. We can revisit the familiar body, follow a different progression, or prefer a result whose making remains partly hidden. Understanding an operation need not settle which of its forms we desire.

In the next hall the negative gets large. A hollow will make a promise that looking alone cannot settle: somewhere to stand.

---

## Boolean Works

*Boolean_Works*

The room gets taller here. A workbench, a catalogue rack, a wall with a door cut through it, a block of rock with a hollow inside. These are the Boolean operations at the size where they begin to promise architecture. When the negative gets big enough to stand in, can you stand in it?

Do not answer from the doorway. Several objects offer an image of an interior. One asks you to enter it. The difference is worth finding with your body before naming it.

#### The work waiting above the table


Three solids turn slowly above a table. Union, intersection, subtraction: the verbs have become a small collection. Their rotation offers each result from another side while the recipe stays fixed.

The workbench suggests a place to take hold of something and change it. In this version, the three presets keep their distance from that possibility. They turn, but you cannot pick them up or build another expression here. Your eye can follow their contours further than your hand can carry them.

There is already more in the algebra than this table shows. Its source includes a recipe for keeping the parts belonging to either operand while removing the overlap:

`(A ∪ B) − (A ∩ B)`

This is symmetric difference. It composes the familiar verbs instead of adding a new primitive operation. The current table shows the three simpler results. The unplaced recipe leaves a specific possibility to develop: a workbench where combining operations becomes something the visitor can do. For now, the table lets us inspect the answers someone else arranged.

#### A cut changes its company


A painted cube stands on a white plinth. Beside it, the same cut is presented with transparent operands and an explanatory board. One asks for attention as a sculpture; the other offers the means of explaining its hollow. A tray gathers further specimens nearby.

Stay with whichever draws you first. Knowing how the sphere was subtracted need not exhaust the pleasure of the curve it left. Conversely, the desire to understand can send you back to a surface you had already admired.

The two presentations share a geometric recipe, but their materials also make decisions about visibility. The painted version draws both sides of its triangles; the operator version keeps ordinary back-face culling. This decides which sides of a triangle may be seen, separately from the geometry of the cut. Comparing the presentations involves more than furniture and colour. The explanation has a way of showing things too.

#### When did the pieces become pieces?


Five spherical bodies and balls to throw recall the earlier force encounters. A sphere coming apart can seem to tell one clear story: impact, then fragments. Here the methods disagree about when those fragments come into existence.

Some bodies are divided into pieces before the impact. Others calculate a division when they are struck. One method uses CSG intersection to make its piece meshes; the others use different constructions. Similar broken silhouettes can follow different histories.

That is a useful neighbour for the Boolean works. The hall does not need every fracture to be subtraction. It needs us to notice when the appearance of a cut has persuaded us that we know how it was made.

#### The hole that was never made


A Menger sponge gives that question a quieter form. Square openings recur inside a cube, and smaller openings repeat in what remains. From a distance it could be a record of patient excavation.

The construction divides a region into twenty-seven positions. It counts how many coordinates of each little position lie in the middle and then makes a choice:

```gdscript
if zeros >= 2:
    continue
```

Those cells are never built. The others can be subdivided again. Nothing has to be removed from a previously filled cube to give this body its holes.

The earlier Boolean difference changed a represented region and generated its new boundary. This work withholds parts of a construction. Both can give us an opening to look through. The image alone does not tell us which history to imagine.

There is something generous in that uncertainty. We can want the hollow before knowing whether to carve it, omit it, or compose the surrounding pieces. Learning another construction gives that desire another way to proceed.

#### Equals room


A wall carries the equation `wall − (door + porthole + window) = room`. There is a doorway, a round bite at the top and an arched opening. Your eye begins arranging a possible passage through them.

Walk toward the uncut part. It does not stop you. This display has no enabled collision, so the wall and its doorway make the same offer to the moving body. The opening matters to the image; the implementation has not made it a necessary crossing.

Go around the end. There is no enclosed room behind this particular wall. The artifact has other configurations with returning walls, but the placement here is a single slab. An equation over its head has supplied a room sooner than the construction has supplied an inside.

The failed promise is worth keeping in view. We can understand the operation, recognise the door and still lack the agreement that would let either one organise our movement. A clear picture can carry a desire for somewhere we cannot yet inhabit.

#### The opening that asks for your body


Go around the stone block to the opening on its left side. Try the solid wall first, then the gap. The wall stops you. At the opening, the museum floor continues into a low, turning hollow. Follow it far enough to lose the view you had from outside. Then turn and find your way back.

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

#### Walk the hollow


Nearby, another rock-like body carries the invitation "CARVE THE FUNCTION, WALK THE HOLLOW". Its crust is assembled from small boxes. Five spherical regions are subtracted from a box-shaped field, and samples near the resulting boundary give it this broken surface.

The signed-distance calculation returns from the previous sequence:

```gdscript
d = maxf(d, -_sd_sphere(p, c, r))
```

Inside uses negative values in this construction. Negating the sphere's field and taking the maximum keeps the region inside the box but outside the cutter. Repeating the operation makes several hollows. Sampling that result into little boxes gives the surface its grain.

The model has no collider. Its carved air also begins above the museum floor; a lower part of the displayed rock separates the hollow from where your feet are. Enlarging the model has not supplied a walk into it. The invitation stays ahead of the place.

Look back toward the burrow. Related operations have produced two different relations to an interior. One offers a surface to examine. The other has been fitted to a body's approach, support and return. The large hollow may make us want another passage; wanting it does not yet give it a floor.

#### A collection within reach


The rack gathers seventy-five small combinations in a three-dimensional array. A handleable scale and repeated frames suggest a collection you could take apart in your hands. The current rack's objects do not retain the normal pickup behavior. Here too, an appearance has offered an action that the implementation withholds.

That makes a precise unfinished task. If handling became possible, we could turn one result away from its neighbours, carry it to another comparison, and bring it back. The collection would acquire another order through a visitor's attention. For now, we move around it while its objects keep their places.

#### What the picture can settle


The amber-and-blue diagram returns at the back wall. It gives a stable image to a competition between surfaces. In the gallery, we could compare its account with the mechanism drawing the stripes. Here it stands among objects whose accounts also need another kind of evidence.

An outside photograph can show an entrance. It cannot establish the route a particular body will find beyond it. The museum's earlier image comparisons scarcely registered the addition of returning walls: from outside, little appeared to change. A visitor might instead find somewhere to be out of sight.

In the burrow, the cutters kept their centres while a changed profile made a walk possible. The old description, *connected*, remained true. We had to ask what connection would mean for the body arriving there.

Keep the signs that overpromise in view. They tell us where the desire for a room arrived before its floor, contact rules or entrance. The next construction can take that desire seriously. Sometimes a different cut lets the body arrive too.

In Swarm Intelligence, many bodies will follow local rules at once. Their movements will make relations that no single body can supply. Carry the question of accommodation with you: what space becomes possible among them?

---
