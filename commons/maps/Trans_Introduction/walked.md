# Trans_Introduction — walked

> R-021, amended: this page is the considered critical tutorial for a map that
> is already walked and working. The ghost drafts from what the map IS — its
> cast, its play, its blurb and intent; Palle rules the voice and the wording.
> Not written from zero, written up from a thing that runs.
>
> PILOT (ruling pending): the dwell register. The walk keeps its walking tempo;
> at three stations it stops, and an inset long-take opens — distilled from the
> map's own thinking files, provenance shown. The page is paced like the map:
> walk → dwell → walk. Each dwell carries its computed reading time (P-6).

## What this map holds (seed)

Three cubes, three ways to close a gap. The cyan cube translates — position changes, the gap is bridged by going somewhere else. The orange cube rotates — a floor becomes a ramp, the gap is bridged by changing alignment, not position. The green cube scales — the gap doesn't get crossed, it gets filled. After static geometry reached its reflective limit in Melencolia, the primitives finally move.

Around the gap, the instruments: `invariants_demo` measures what each transformation cannot touch, `matrix_4x4_viewer` shows all three operations collapsing into sixteen numbers, `homogeneous_coordinates` explains the trick that lets addition live inside multiplication, `rotation_gimbal` demonstrates where turning fails, `transform_composition` proves that order is a variable. The `dark_sphere` holds still so the rest can be seen to change.

## Why it was built (seed)

Concept: The three fundamental transformations — translate, rotate, scale — as three distinct strategies for closing a spatial gap. The first map of the Transformation sequence reframes movement as a structured choice, not a given.
Sequence role: Opens the Transformation sequence. Follows Primitives_Melencolia. Introduces all three transformation types simultaneously so subsequent maps can isolate each one; leads toward the translation maps.
Critical angle: Invariance as identity. Each transformation preserves something the others discard: translation keeps orientation and size, rotation keeps position and size, scale keeps position and orientation. What survives a transformation defines what the transformation is.

## The cast

invariants_demo · matrix_4x4_viewer · homogeneous_coordinates · rotation_gimbal · balance_puzzle · transform_composition · dark_sphere

## The walk

You spawn beside a triangle. The `invariants_demo` sits at the entry like a customs desk: it has already measured its own side lengths, angles, and area, and it is waiting for you to change it so it can report what survived. You don't understand the report yet. The map knows that, and lets you carry the question forward.

> **Dwell — `invariants_demo` · ~55s**
>
> This is the QFEP core of the whole chapter, staged as a triangle and three
> lamps. At startup it records ground truth — side lengths by measure, interior
> angles by dot product, area by cross product — and every transform you apply
> is graded against that record: preserved measurements glow green, changed
> ones glow red. The signatures are exact. Translation: all green. Rotation:
> all green. Uniform scale: angles green, lengths and area red — angles are
> scale-invariant, area grows by the square. Shear: nearly everything red.
> Translation and rotation are rigid; scale is similarity; shear is neither.
> And here the map states its thesis before you have crossed a single gap: a
> transformation is not only a change, it is a *signature of what it cannot
> touch*. The green cells show what the operation is powerless against, and
> that powerlessness is the definition. Move a thing without changing what it
> is — the demo insists this is possible, and shows you precisely which kinds
> of moving keep the promise. Hold onto the red cells too. Some changes do not
> preserve you, and the demo is honest about which.
>
> *distilled from technical.md · intent.md · the turn*

Then the gap. Three cubes wait at its edge, each offering a different contract. The transport cube carries you across — position changes, nothing else. The rotation cube turns — forty-five degrees, and a surface that was floor becomes ramp. The scale cube grows until the void is no longer void. Same gap, three ontologies: being elsewhere, being oriented, being present. Cross it three times if you can; the difference lands in the body, not the notation.

Past the gap, the notation catches up. The `matrix_4x4_viewer` puts sliders under a cube and sixteen live cells under the sliders: MOVE lights one green column, ROTATE fills the cyan 3×3 block, SCALE walks the diagonal. One artifact, two levels of representation, same fact. The `homogeneous_coordinates` panel explains the smuggling — every point becomes (x, y, z, 1), and translation, which is addition, gets to live inside a multiplication. Beside it, the `rotation_gimbal` shows where the clean story cracks.

> **Dwell — `rotation_gimbal` · ~60s**
>
> Three nested rings — X red, Y green, Z blue — each an Euler angle, applied
> in order, the outer ring driving the inner ones. Turn them and the rings
> obey; this is rotation as the interface presents it, three independent
> dials. Then bring Y toward ninety degrees and watch the artifact do the one
> thing the matrix viewer cannot: fail. At the lock threshold the X and Z
> rings collapse into the same plane. Two degrees of freedom merge; any
> rotation there is expressible as a combination of the other two; a freedom
> has vanished, not by bug but by geometry. Gimbal lock is a property of the
> representation, not of rotation itself — quaternions dissolve it by treating
> rotation as one operation instead of three stacked ones, and this map
> deliberately stops short of them, letting you feel *why* they were invented
> instead of handing you their algebra. The critical file reads the rings
> queerly and earns it: if any face can be "up," then upright is a choice, not
> a fact. The gimbal is where the axes' pretense of independence breaks — and
> where orientation is revealed as something maintained, not given.
>
> *distilled from technical.md · critical.md*

The `balance_puzzle` reframes everything you just dialed: here the physics engine negotiates the transforms, pieces translating and rotating under contact forces until the stack finds stability — and then the stack becomes a walker, the same pieces re-expressed as locomotion. You control the threshold, not the path.

> **Dwell — `transform_composition` · ~45s**
>
> Two house shapes, the same rotation and the same translation — applied in
> opposite orders. They land in different places. At small angles the split is
> subtle; at ninety degrees with a long translation the two results stand
> dramatically apart, both matrices displayed live so the numeric divergence
> sits beside the geometric one. The geometry explains itself: rotate-then-
> translate moves along the *rotated* axes; translate-then-rotate swings the
> object around the original origin — it orbits instead of spinning in place.
> Same operations, different order, different result. This is why every
> transform pipeline in the engine fixes a sequence — scale, rotate, translate
> — and that sequence is a convention, not a law. Order is a variable. The
> next map will hand you a workbench and make you set it yourself.
>
> *distilled from technical.md · tutorial.md*

You leave past the `dark_sphere` — slow spin, faint pulse, near-constant. It teaches no fact. It is the invariant in the perceptual register: the thing that does not transform, without which none of the transformations would be legible.

## The turn (critical)

The map's central claim hides in the green cells of the invariants demo: **a transformation is defined by what it cannot touch.** Translation is the operation powerless against orientation and size; rotation the one powerless against shape and position; scale the one powerless against angles. Identity, in this chapter, is not a substance — it is an invariant set. What survives the change is what the thing *is*.

And this is the trans chapter, so say it with the care it deserves. The critical file already reads the three cubes as three politics of the body: translation is the normative mode — go where you're supposed to go; rotation queers orientation — the ramp refuses the binary of floor and wall, upright becomes a choice; scale queers presence — *at what size am I allowed to exist?* The map does not rank these. It asks you to cross the same gap three times and feel that they are different ontological commitments about what a body is.

Read forward through the whole chapter, the invariants demo is the dignity claim: you can be moved, turned, resized — transformed — and remain yourself, and the geometry can say *precisely* which changes keep that promise. Transformation does not destroy identity; it reveals which parts of it were load-bearing all along. That is what the green light means. And the red light is not a threat — it is the honest register that some changes are real, that a body after shear is a different body, and that the question of what survives was never rhetorical.

## Room for improvement

*(Palle: the sequence works and has been walked many times; note here what a
next pass sharpens — a beat that lands soft in the body, a meet that reads
unclear, an artifact whose feature the text over- or under-claims.)*
