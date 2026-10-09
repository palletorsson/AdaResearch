Three objects on one line down the middle of the room. The floor rises to either side twice on the way, giving each object a bay without hiding it from the next. A box and a sphere keep returning. By the third encounter, part of the sphere's shape will belong to a hollow in the box.

Their sizes, offsets and colours vary between these demonstrations. We are learning three operations, rather than changing one setting in an otherwise identical experiment. Keep the pair in mind and follow what each operation keeps: either region, their shared region, or the part of the box outside the sphere.

## What a solid is here

These bodies do not have to be filled with little pieces of material. Each primitive describes a region: we can ask whether a point belongs to it. The program combines those regions and makes a boundary visible. This is constructive solid geometry, usually shortened to CSG.

There are several agreements inside the word *solid*. These small exhibits have not enabled collision. You can pass through a surface that your eye has already accepted. The region still has an inside and an outside in the calculation; it has not acquired the power to stop your body. Keep that difference with you when the objects become architecture.

## What can belong together

<!-- @csg_union_demo -->

At the first body, follow the place where the box and sphere meet. Their outside contours survive, but the buried surfaces at the overlap do not belong to the result's visible boundary. The operation keeps every point belonging to either region. That is union: `A ∪ B`.

The sphere enters the construction with this instruction:

```gdscript
csg_sphere.operation = CSGShape3D.OPERATION_UNION
```

Earlier, distance fields let a parameter round the meeting between forms. Here there is no smoothing band. A crease can remain where the boundaries meet, even though the gap has gone. Being connected and being smooth are different accomplishments.

The next hall also shows this union with its operands separated. It still contains both of them. One result, two disconnected components. The word *joining* may have led us to expect a bridge; the operation has only promised to keep what belongs to either body. They can belong to one result without having to touch.

## What must be shared

<!-- @csg_intersection_demo -->

The second body keeps only the region belonging to both primitives: `A ∩ B`. Much of the box and sphere has no place in this answer. If the operands were moved far enough apart, the shared region would be empty. Nothing can be a successful result.

Beneath the body, three numbers give the volumes of A, B and the region they share. Estimate what remains before looking down at the panel. The little survivor and its precise-looking number are two ways of meeting the same question.

The instrument tests a lattice of sample points. At each point it asks whether the distance from the sphere's centre is within its radius:

```gdscript
var in_b: bool = dx * dx + dy * dy + dz * dz <= r2
```

It also tests the box, then counts points accepted by both. A forty-eight-by-forty-eight-by-forty-eight lattice makes this an estimate. The visible sphere is faceted, while this test describes an analytic sphere. They share a radius parameter, but they do not spend it in quite the same way.

Move close enough to find a facet. Three decimal places have not made the picture and the measurement identical. We have chosen both how to give the region a surface and how to count it.

## A face neither of them brought

<!-- @csg_difference_demo -->

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

## Which body comes first

<!-- @the_argument_of_solids -->

At the end of the hall, a bench brings the three results close enough to compare without walking between bays. Beside them stand two different remainders. One is labelled `A − B`; the other, `B − A`.

The letters changed places. The box with a bite gives way to what remains of the sphere outside the box. The operation is still subtraction. Its order decides whose region may remain and whose will do the cutting.

Above the bench, a caption calls these "the three verbs" and says "the set is closed". There are three choices in the engine's operation list. But an expression also needs operands, their order and their positions. Its result can become an operand in another expression. A small vocabulary can keep making bodies that the list of names does not describe.

The verbs tempt us into quick judgements: union welcomes, intersection demands agreement, subtraction excludes. Then a cavity interrupts that story. What was removed might be precisely where another body could stand. We need to meet the result before deciding what its keeping or cutting has done.

In the next room, the same families appear in several versions. We will be able to see how much one familiar setting had kept out of sight.
