Three objects on one line down the middle of the room, and the floor rises to either side of you twice on the way, so each one gets a bay to itself without ever being hidden from the next.

They are the same two solids every time. A box and a sphere, one offset from the other, and nothing else changes down the whole length of the hall — not the size, not the spacing, not the material. What changes is a single word set on the sphere, and that word decides whether you are looking at one thing, at the part two things had in common, or at a hole. This room is the argument that the word is doing more work than the shapes.

## What a solid is here

Before the verbs, the thing they operate on. In this engine a solid is not a lump of material with an inside. It is a surface, and a rule for asking whether a point is on one side of it. Nothing is stored in the middle. The middle is an agreement between two systems — the renderer, which will not draw what faces away from you, and the physics, which will refuse to let you pass — and as long as the two agree, you experience an interior.

This matters because it means none of the three verbs can remove anything. There is nothing in there to remove. What they can do is redraw the boundary so that the same test gives different answers. Every operation in this hall is an operation on a *skin*, and every "inside" you meet is a promise about a region that was never filled in.

## Joining is not stacking

<!-- @csg_union_demo -->

```gdscript
# csg_union_demo.gd:59 — what this room is not
#   blend and the ladder is a continuum. CSG union has no k: it fuses absolutely
#   at first contact, so here `necked` is a CREASE with a discontinuous normal and
#   the ladder is a sequence of topological events. Same four states, two
#   ontologies of joining.
```

Walk to the first body and watch the seam. Two solids meet, and the surfaces where they met are gone — not hidden, not coincident, gone, replaced by one new closed surface that neither of them had before the operation ran.

The comment above is the artifact talking about its own cousins in the metaball chapter, and it is the most important sentence in this hall. Over there, a union takes a parameter `k`, and inside a band of width `k` the two fields blend: there is a genuine *partly*, a state that is neither two nor one. Here there is no `k`. The solids are two, and then at one floating-point value of the offset they are one, and there is no frame in between. The ladder is not a gradient. It is a sequence of events.

Same four states, two ontologies of joining. That is the artifact's phrase, not mine, and it is the whole chapter in six words.

Which makes the first rung of its own ladder awkward. The axis `fusion` runs `distinct, necked, lobed, single`, and at `distinct` the two primitives do not touch at all. The operator still runs. It contributes nothing — the output set is exactly the input set, two solids sitting near each other under a union that has no work to do. The artifact's stated desire is *to show that joining is not stacking*, and a quarter of its primary axis is a stack. The file is honest about it in the only place it can be, a comment at line 42: `TWO DISJOINT SOLIDS, still under OPERATION_UNION`.

## The interior was never there

<!-- @csg_intersection_demo -->

```gdscript
# csg_intersection_demo.gd:341 — the instrument, which is not the object
if dx * dx + dy * dy + dz * dz <= r2:
```

The second body keeps only what both solids claimed. Set the offset far enough and it keeps nothing, and nothing is a lawful answer: the operation succeeded, and the result is empty. It is the one verb whose correct output can be no output.

Standing next to it, on three of its four settings, is a number — the volume of A, of B, and of the two together, printed to three decimals. The artifact calls this measuring itself, and says so: *All three are measured by the SAME instrument on purpose*.

They are not measured by the same instrument as the object. That line above is the measurement: an analytic sphere, a point tested against a radius, forty-eight cubed samples of a perfect mathematical ball. The thing on the table is a `CSGSphere3D` whose tessellation is never set, so it renders at Godot's default twelve segments by six rings — a faceted approximation. And on the setting that shows you what was lost, the ghosts of the discarded material are built at twenty-four by twelve, smoother than the sphere that cut them.

So there are three spheres in this exhibit. The one you see, the one that did the cutting, and the one the number is about, and no two of them are the same shape. The instrument is honest, the object is honest, and they are describing different things — which is not a bug so much as the clearest possible demonstration of what a boundary representation is. The sphere on the plinth has no radius. It has twelve segments and six rings, and *radius* is a story told about them.

## A face neither of them brought

<!-- @csg_difference_demo -->

```gdscript
# csg_difference_demo.gd:236 — the cut, and then the skin
csg_sphere.operation = CSGShape3D.OPERATION_SUBTRACTION
_root_csg.add_child(csg_sphere)
var mat := StandardMaterial3D.new()
mat.albedo_color = body_color
_root_csg.material_override = mat
```

Push the sphere into the box and a face appears that neither solid brought with it. It is the sphere's shape, turned inside out, and it is wearing the box's material — because look at the last line: the material is set once, on the root of the whole operation. There is one skin. There was only ever one skin to give it.

That is not a shortcut in the code. It is what a boundary model leaves you no choice about. The moment you carve, you need a surface for an inside that was never stored, and the only surface available is the outside, relabelled. The cavity wall is not revealed by the cut. It is manufactured at the instant of the cut, out of the material of the thing being cut, and assigned to a solid that did not make it.

Of the three verbs this is the one that shows the mechanism plainly, and it is also the one the heavy hall cannot leave alone: subtraction is the operation this whole chapter keeps returning to, because it is the one where the invention is impossible to hide.

## The set is closed

<!-- @the_argument_of_solids -->

```gdscript
# the_argument_of_solids.gd:130 — the label it hangs in the middle of the room
_tag(Vector3(-0.3, 0.94, -0.05), "the three verbs", "an enum on one property - the set is closed")
```

At the far end, after all three, a bench of small verdicts with captions. It rebuilds the three results from scratch at its own scale so you can read them side by side, and it hangs the line above over the middle of them: three verbs, an enum on one property, the set is closed.

Five lines further down the file it builds a fourth thing the enum cannot name. Its helper for making a verdict takes the operation as a parameter but fixes the operand order — box first, sphere second — so B minus A cannot go through it, and the file hand-rolls a duplicate combiner with the two children swapped to get the picture it wants.

The set is closed, and the closure is a property of the enum, not of the argument. Difference is not commutative; the grammar has one slot for the verb and no slot for the order; so the artifact that exists to say the vocabulary is complete has to step outside the vocabulary to finish its own sentence.

You can count the preference in the file. `OPERATION_UNION` appears once. `OPERATION_INTERSECTION` twice. `OPERATION_SUBTRACTION` six times.

## What the grammar cannot say

Three verbs, and each one turned out to be an argument about the boundary rather than about the solids. Union deletes a surface. Intersection reveals there was never anything behind it. Difference invents one and dresses it in somebody else's skin.

And the foreclosure is the same in all three: the predicate is a yes or a no. There is no `k`. A point is in or it is out, two solids are two or they are one, and the transition between those states does not occupy any time or any space — it happens between one float and the next. Everything this chapter can say about relation, it has to say in a vocabulary with no word for *partly*, no word for *becoming*, and no way to hold a thing that belongs to two sets at once except by making a third set and throwing the question away.

The room next door is where you find out that even the four settings on each of these dials are a claim somebody published, and that the published claim and the object do not always agree.
